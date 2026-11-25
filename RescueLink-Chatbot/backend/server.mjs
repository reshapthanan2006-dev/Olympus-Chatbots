import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';

const intents = ['overview', 'requestHelp'];
const languages = new Set(['en', 'si', 'ta']);
// Keep this complete-question allowlist aligned with the Flutter classifier.
const questionPattern = /^(?:(?:what is|what can i do with|how (?:do i use|does)) rescuelink(?: lk)?(?: work)?|how do i (?:ask for assistance|get started) (?:in|with) rescuelink(?: lk)?|rescuelink lk යනු කුමක්ද|rescuelink lk என்றால் என்ன)\??$/u;

function reply(res, status, intent = null) {
  res.writeHead(status, {
    'content-type': 'application/json',
    'cache-control': 'no-store',
  });
  res.end(JSON.stringify({ intent }));
}

async function readRequest(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req.iterator({ destroyOnReturn: false })) {
    size += chunk.length;
    if (size > 512) {
      req.resume();
      return null;
    }
    chunks.push(chunk);
  }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(chunks)));
}

const modelPattern = /^[a-zA-Z0-9]+(?:[._-][a-zA-Z0-9]+)*$/;
const dnsErrorCodes = new Set(['ENOTFOUND', 'EAI_AGAIN']);
const networkErrorCodes = new Set([
  'ECONNREFUSED',
  'ECONNRESET',
  'EHOSTUNREACH',
  'ENETUNREACH',
  'ETIMEDOUT',
  'EPIPE',
  'UND_ERR_CONNECT_TIMEOUT',
  'UND_ERR_SOCKET',
  'UND_ERR_HEADERS_TIMEOUT',
]);
const tlsErrorCodes = new Set([
  'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
  'CERT_HAS_EXPIRED',
  'DEPTH_ZERO_SELF_SIGNED_CERT',
  'SELF_SIGNED_CERT_IN_CHAIN',
  'ERR_TLS_CERT_ALTNAME_INVALID',
]);

function classifyFetchError(error) {
  const rawCode = error?.cause?.code ?? error?.code;
  const code = typeof rawCode === 'string' && /^[A-Z0-9_]+$/.test(rawCode) ? rawCode : null;
  const name = typeof error?.name === 'string' && /^[A-Za-z0-9_]+$/.test(error.name) ? error.name : 'Error';

  let category = 'fetch';
  if (code && dnsErrorCodes.has(code)) {
    category = 'dns';
  } else if (code && (tlsErrorCodes.has(code) || code.startsWith('ERR_TLS_') || code.startsWith('ERR_SSL_'))) {
    category = 'tls';
  } else if (code && networkErrorCodes.has(code)) {
    category = 'network';
  } else if (code === 'ERR_INVALID_CHAR' || (!code && name === 'TypeError')) {
    category = 'header_or_fetch';
  }

  return code ? `${category}:${name}:${code}` : `${category}:${name}`;
}

export function createHandler({
  apiKey = process.env.GEMINI_API_KEY,
  model = process.env.GEMINI_MODEL,
  fetchGemini = fetch,
  timeoutMs = 2200,
} = {}) {
  const configured = Boolean(apiKey && model && modelPattern.test(model));
  const debug = process.env.RESCUELINK_AI_DEBUG === '1';
  const log = (event) => {
    if (debug) console.info(`[RescueLink AI] ${event}`);
  };

  return async (req, res) => {
    if (req.url !== '/classify') return reply(res, 404);
    if (req.method !== 'POST') return reply(res, 405);
    log('backend request');
    if (debug) res.once('finish', () => log(`backend HTTP ${res.statusCode}`));
    if (req.headers['content-type']?.split(';')[0].trim() !== 'application/json') {
      return reply(res, 415);
    }

    let input;
    try {
      input = await readRequest(req);
    } catch {
      return reply(res, 400);
    }
    const { question, language } = input ?? {};
    if (!input || Object.keys(input).length !== 2 ||
        typeof question !== 'string' || questionPattern.exec(question)?.[0] !== question ||
        !languages.has(language)) {
      return reply(res, 400);
    }
    if (!configured) return reply(res, 503);

    const signal = AbortSignal.timeout(timeoutMs);
    try {
      const upstream = await fetchGemini(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          redirect: 'error',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
          signal,
          body: JSON.stringify({
            systemInstruction: { parts: [{ text:
              'Classify the RescueLink LK FAQ question. Use requestHelp for how to request assistance through the app. Use overview for general questions about the app or getting started. Return only the intent ID as a JSON string.',
            }] },
            contents: [{ parts: [{ text: JSON.stringify({ question, language }) }] }],
            generationConfig: {
              responseMimeType: 'application/json',
              responseJsonSchema: { type: 'string', enum: intents },
            },
          }),
        },
      );
      if (!upstream.ok) {
        log(`Gemini HTTP ${upstream.status}`);
        await upstream.body?.cancel();
        return reply(res, 502);
      }
      const result = await upstream.json();
      const candidate = result?.candidates?.[0];
      const parts = candidate?.content?.parts;
      if (result?.candidates?.length !== 1 || candidate?.finishReason !== 'STOP' ||
          !Array.isArray(parts) || parts.length !== 1 || typeof parts[0]?.text !== 'string') {
        log('Gemini response rejected');
        return reply(res, 502);
      }
      const intent = JSON.parse(parts[0].text);
      if (!intents.includes(intent)) {
        log('Gemini intent rejected');
        return reply(res, 502);
      }
      log('Gemini success');
      return reply(res, 200, intent);
    } catch (error) {
      if (signal.aborted) {
        log('Gemini timeout');
        return reply(res, 504);
      }
      log(
        error instanceof SyntaxError
          ? 'Gemini JSON invalid'
          : `Gemini request failed (${classifyFetchError(error)})`,
      );
      return reply(res, 502);
    }
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT ?? 8787);
  createServer({ requestTimeout: 5000, headersTimeout: 5000 }, createHandler())
    .listen(port, '127.0.0.1');
}
