# RescueLink Gemini classifier proxy

Run `node backend/server.mjs` with Node.js 22 or later. Set `GEMINI_API_KEY` and `GEMINI_MODEL` in the server environment. Use a model ID that supports structured JSON output, without the `models/` prefix. The proxy listens on `127.0.0.1:8787` by default. Override the port with `PORT`.

Set the full endpoint for Flutter with `--dart-define=RESCUELINK_AI_BACKEND_URL=https://your-backend.example/classify`. Use an HTTPS gateway with access and rate controls for remote deployment. The app permits plain HTTP only on loopback. Omitting the define keeps the assistant offline.

Run the backend tests with `node --test backend/server.test.mjs`. Tests use mocked Gemini responses.
