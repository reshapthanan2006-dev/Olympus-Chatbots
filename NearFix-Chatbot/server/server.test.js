const test = require('node:test');
const assert = require('node:assert/strict');

const {
  callGeminiApi,
  getGeminiModel,
  SYSTEM_PROMPT,
  DEFAULT_GEMINI_MODEL,
} = require('./server');

test('SYSTEM_PROMPT removes four-town restriction and supports all 25 Sri Lankan districts', () => {
  assert.doesNotMatch(
    SYSTEM_PROMPT,
    /Approved towns\/areas:\s*Jaffna,\s*Nallur,\s*Chavakachcheri,\s*Point Pedro/i,
  );
  assert.match(SYSTEM_PROMPT, /throughout Sri Lanka/i);
  assert.match(SYSTEM_PROMPT, /25 districts/i);
  assert.match(SYSTEM_PROMPT, /intent="follow_up"/);
});

test('getGeminiModel defaults and validates versioned model names with periods securely', () => {
  const prevModel = process.env.GEMINI_MODEL;
  try {
    delete process.env.GEMINI_MODEL;
    assert.equal(getGeminiModel(), DEFAULT_GEMINI_MODEL);

    process.env.GEMINI_MODEL = 'gemini-2.5-pro.001';
    assert.equal(getGeminiModel(), 'gemini-2.5-pro.001');

    for (const badModel of ['../evil', 'gemini..flash', 'gemini/flash', 'gemini?key=1', '']) {
      process.env.GEMINI_MODEL = badModel;
      if (badModel === '') {
        assert.equal(getGeminiModel(), DEFAULT_GEMINI_MODEL);
      } else {
        assert.throws(() => getGeminiModel(), /Invalid GEMINI_MODEL/);
      }
    }
  } finally {
    if (prevModel === undefined) {
      delete process.env.GEMINI_MODEL;
    } else {
      process.env.GEMINI_MODEL = prevModel;
    }
  }
});

test('callGeminiApi sends x-goog-api-key header, omits key from URL, and uses GEMINI_MODEL', async () => {
  const prevModel = process.env.GEMINI_MODEL;
  process.env.GEMINI_MODEL = 'gemini-2.5-flash.002';

  let capturedUrl = null;
  let capturedOptions = null;

  const mockFetch = async (url, options) => {
    capturedUrl = url;
    capturedOptions = options;
    return {
      ok: true,
      status: 200,
      json: async () => ({
        candidates: [
          {
            content: {
              parts: [
                {
                  text: JSON.stringify({
                    intent: 'follow_up',
                    language: 'en',
                    service_id: null,
                    faq_id: null,
                    reply: 'Processing location.',
                    clarification_needed: false,
                    clarification_type: null,
                    confidence: 0.95,
                  }),
                },
              ],
            },
          },
        ],
      }),
    };
  };

  try {
    const result = await callGeminiApi(
      'fake-secret-key-123',
      {
        message: 'Colombo',
        current_stage: 'area',
        current_service_id: 'mechanic',
        current_area: 'ShouldNotAppear',
        language: 'en',
      },
      mockFetch,
    );

    assert.equal(
      capturedUrl,
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash.002:generateContent',
    );
    assert.doesNotMatch(capturedUrl, /fake-secret-key-123/);
    assert.doesNotMatch(capturedUrl, /\?key=/);
    assert.equal(capturedOptions.headers['x-goog-api-key'], 'fake-secret-key-123');
    assert.doesNotMatch(capturedOptions.body, /ShouldNotAppear/);
    assert.equal(result.intent, 'follow_up');
  } finally {
    if (prevModel === undefined) {
      delete process.env.GEMINI_MODEL;
    } else {
      process.env.GEMINI_MODEL = prevModel;
    }
  }
});

test('callGeminiApi throws without leaking API key on HTTP error', async () => {
  const mockFetch = async () => ({
    ok: false,
    status: 403,
  });

  await assert.rejects(
    () =>
      callGeminiApi(
        'secret-key-should-not-leak',
        { message: 'What is NearFix?', current_stage: 'service', language: 'en' },
        mockFetch,
      ),
    (err) => {
      assert.match(err.message, /HTTP 403/);
      assert.doesNotMatch(err.message, /secret-key-should-not-leak/);
      return true;
    },
  );
});
