# Olympus Chatbots

AI-assisted chatbot prototypes developed by Team Olympus
for the NearFix and RescueLink LK applications in Sri Lanka.

## Project Structure

- NearFix-Chatbot/ - Nearby service assistant
- RescueLink-Chatbot/ - Disaster assistance information assistant

## NearFix Assistant

- Automatic English and Tamil language detection
- Service problem classification
- Support for all 25 Sri Lankan districts
- Location-based demo provider recommendations
- Conversation context handling
- Gemini AI integration
- Offline rule-based fallback

## RescueLink LK Assistant

- English, Tamil and Sinhala language support
- Disaster assistance information
- Multilingual FAQ recognition
- Controlled Gemini AI classification
- Offline safety guidance
- Fixed emergency and SOS status responses

## Technologies

- Flutter and Dart
- Node.js
- Google Gemini API
- Local JSON and FAQ data
- Git and GitHub

## Requirements

- Flutter SDK
- Node.js
- Android Studio or VS Code
- Android emulator or compatible device
- Gemini API key for optional online AI functionality

## Running NearFix Offline

```powershell
cd NearFix-Chatbot
flutter pub get
flutter run
```

## Running RescueLink LK Offline

```powershell
cd RescueLink-Chatbot
flutter pub get
flutter run
```

Run each example from the repository root.

## Online AI Configuration

NearFix uses server/server.js on port 8088.

RescueLink LK uses backend/server.mjs on port 8787.

Configure GEMINI_API_KEY and GEMINI_MODEL in the server
environment. Never hardcode or commit API credentials.

Flutter backend configuration:

- NearFix: NEARFIX_AI_BACKEND_URL
- RescueLink: RESCUELINK_AI_BACKEND_URL

The backends are configured for local development.
Production deployment requires additional security controls.

## Testing Results

| Test | NearFix | RescueLink LK |
|---|---|---|
| Flutter tests | 60 passed | 27 passed |
| Backend tests | 4 passed | 7 passed |
| Live Gemini | Verified | Verified |
| Offline fallback | Verified | Verified |
| Emulator testing | Completed | Completed |

These are the reported prototype development test results.

## Current Limitations

- NearFix provider records are fictional demo data.
- No real bookings or payments are performed.
- RescueLink does not store or submit SOS reports.
- Server acknowledgment does not confirm rescue dispatch.
- Sinhala and Tamil safety translations require fluent review.
- Live AI availability is not guaranteed.

## Future Integration

- Integrate both assistants into their respective Flutter apps.
- Connect NearFix to the real provider database.
- Complete physical-device testing.
- Review disaster safety translations.
- Configure secure production backend infrastructure.

## Development Status

Both standalone chatbot prototypes are implemented and tested.
Final application integration and production readiness are pending.

Developed by Team Olympus.
