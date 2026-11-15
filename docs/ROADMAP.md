# Sauti — Roadmap

## Next (post-hackathon)
- Native-speaker review of all Kirundi strings (UI ARB + agent phrasebook + intent keywords).
- Evaluate Kirundi ASR/TTS options (cloud ASR adapter behind `SpeechRecognizer`; community voice datasets).
- Device testing matrix: TalkBack on low-end Android (Android Go), VoiceOver on iOS, Switch Access.
- Crashlytics and Analytics with privacy-first defaults (opt-in, no banking data).
- Per-user rate limits and anomaly detection on `submitTransfer`.
- Verified beneficiary onboarding (OTP / registered-device confirmation).
- Run Firestore rules tests in CI (emulator + Java).

## Later
- Licensed integration with a Burundian bank or mobile-money operator through an authorised API (new `BankRepository` adapter).
- On-device LLM tier (Gemma-class via MediaPipe) once tool calling and latency on mid-range phones are validated.
- USSD / IVR channel reusing the same domain and tool layer, for feature phones.
- Additional languages: Swahili, Kinyarwanda.
- Bill payments and airtime purchase as new permissioned tools (each with draft → authenticate → confirm).
- Shared caregiver access with granular, revocable permissions for elderly users.

## Explicitly out of scope until regulated
- Real money movement, card data handling, credit products.
