import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { test } from 'node:test';
import { createHandler } from './server.mjs';

const input = { question: 'rescuelink lk என்றால் என்ன?', language: 'ta' };
const config = { apiKey: 'test-key', model: 'configured-test-model' };

async function classify(handler, body = input) {
  const req = Object.assign(Readable.from([Buffer.from(JSON.stringify(body))]), {
    method: 'POST',
    url: '/classify',
    headers: { 'content-type': 'application/json' },
  });
  const result = {};
  await handler(req, {
    once() {},
    writeHead(status) { result.status = status; },
    end(data) { result.body = JSON.parse(data); },
  });
  return result;
}

function geminiResponse(text, finishReason = 'STOP') {
  return Response.json({ candidates: [{ finishReason, content: { parts: [{ text }] } }] });
}

test('sends only approved request data and returns an allowlisted intent', async () => {
  let calls = 0;
  const handler = createHandler({
    ...config,
    fetchGemini: async (url, options) => {
      calls++;
      assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/models/configured-test-model:generateContent');
      assert.equal(options.headers['x-goog-api-key'], config.apiKey);
      assert.equal(options.redirect, 'error');
      const body = JSON.parse(options.body);
      assert.deepEqual(JSON.parse(body.contents[0].parts[0].text), input);
      assert.deepEqual(body.generationConfig.responseJsonSchema.enum, ['overview', 'requestHelp']);
      return geminiResponse('"overview"');
    },
  });
  assert.deepEqual(await classify(handler), { status: 200, body: { intent: 'overview' } });
  assert.equal(calls, 1);
});

test('rejects extra fields, locations, contact details and SOS before fetching', async () => {
  let calls = 0;
  const handler = createHandler({ ...config, fetchGemini: async () => { calls++; } });
  for (const body of [
    { ...input, location: '6.9271, 79.8612' },
    { ...input, question: `${input.question} 6.9271, 79.8612` },
    { ...input, question: `${input.question} 0771234567` },
    { ...input, question: `${input.question} SOS status` },
    { ...input, question: `${input.question}\n` },
    { ...input, language: 'not-a-language' },
    { ...input, question: 'x'.repeat(600) },
  ]) {
    assert.deepEqual(await classify(handler, body), { status: 400, body: { intent: null } });
  }
  assert.equal(calls, 0);
});

test('rejects unavailable, malformed, truncated or unknown Gemini replies', async () => {
  for (const response of [
    new Response('upstream error', { status: 503 }),
    new Response('malformed response'),
    geminiResponse('unrestricted answer'),
    geminiResponse('"sosNotSent"'),
    geminiResponse('"overview"', 'MAX_TOKENS'),
  ]) {
    const handler = createHandler({ ...config, fetchGemini: async () => response });
    assert.deepEqual(await classify(handler), { status: 502, body: { intent: null } });
  }
});

test('handles missing configuration and upstream timeout', async () => {
  const unconfigured = createHandler({
    ...config,
    apiKey: '',
    fetchGemini: async () => assert.fail('Unexpected upstream request'),
  });
  assert.deepEqual(await classify(unconfigured), { status: 503, body: { intent: null } });

  const handler = createHandler({
    ...config,
    timeoutMs: 10,
    fetchGemini: async (_, { signal }) => {
      // Keep the test loop alive while waiting for the unref'd timeout signal.
      const responseTimer = setTimeout(() => {}, 1000);
      try {
        await new Promise((_, reject) => {
          signal.addEventListener('abort', () => reject(signal.reason), { once: true });
        });
      } finally {
        clearTimeout(responseTimer);
      }
    },
  });
  assert.deepEqual(await classify(handler), { status: 504, body: { intent: null } });
});

test('accepts valid versioned model names including periods', async () => {
  for (const model of ['gemini-3.5-flash-lite', 'gemini-2.5-flash', 'gemini-1.5-pro_002']) {
    let requestedUrl = '';
    const handler = createHandler({
      apiKey: 'test-key',
      model,
      fetchGemini: async (url) => {
        requestedUrl = url;
        return geminiResponse('"overview"');
      },
    });
    assert.deepEqual(await classify(handler), { status: 200, body: { intent: 'overview' } });
    assert.equal(
      requestedUrl,
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    );
  }
});

test('rejects path traversal, slashes, URL injection and invalid model names', async () => {
  for (const model of [
    '',
    '.',
    '..',
    '../models/gemini',
    'gemini..flash',
    '.gemini-3.5-flash',
    'gemini-3.5-flash.',
    'gemini/3.5-flash',
    'gemini\\3.5-flash',
    'gemini-3.5-flash?alt=sse',
    'gemini-3.5-flash#fragment',
    'gemini-3.5-flash:generateContent',
    'gemini-3.5-flash%2f..',
    'gemini 3.5 flash',
    'https://evil.example/model',
  ]) {
    const handler = createHandler({
      apiKey: 'test-key',
      model,
      fetchGemini: async () => assert.fail(`Unexpected upstream request for model: ${model}`),
    });
    assert.deepEqual(await classify(handler), { status: 503, body: { intent: null } });
  }
});

test('logs sanitized error category and code without leaking messages or secrets', async () => {
  const previousDebug = process.env.RESCUELINK_AI_DEBUG;
  const originalInfo = console.info;
  const logs = [];
  process.env.RESCUELINK_AI_DEBUG = '1';
  console.info = (msg) => logs.push(msg);

  try {
    const dnsError = new TypeError('fetch failed: secret-key-123 https://generativelanguage.googleapis.com');
    dnsError.cause = Object.assign(new Error('getaddrinfo ENOTFOUND secret-host'), { code: 'ENOTFOUND' });

    const handler = createHandler({
      ...config,
      fetchGemini: async () => {
        throw dnsError;
      },
    });

    assert.deepEqual(await classify(handler), { status: 502, body: { intent: null } });
    assert.ok(logs.includes('[RescueLink AI] Gemini request failed (dns:TypeError:ENOTFOUND)'));
    assert.equal(logs.some((line) => line.includes('secret-key-123') || line.includes('secret-host')), false);
  } finally {
    console.info = originalInfo;
    if (previousDebug === undefined) {
      delete process.env.RESCUELINK_AI_DEBUG;
    } else {
      process.env.RESCUELINK_AI_DEBUG = previousDebug;
    }
  }
});
