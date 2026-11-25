# Sauti

Sauti is a voice and text banking assistant designed for people with low vision in Burundi. Ask “How much money do I have?” to hear your balance and see it in a card. When the connection drops, the app labels the last saved balance with its timestamp. The interface supports Kirundi, French, and English.

The demo uses a **simulated bank** with fictitious data. Sauti can draft a transfer for a saved recipient. The user reviews the amount and fee, authenticates, and presses Send.

---

## Features

| Area | What works |
|---|---|
| Hybrid AI | On eligible desktop Chrome, Firebase AI Logic uses Gemini Nano to interpret requests. Typed banking tools fetch the data used in local replies. Cloud Gemini handles requests when the local model is unavailable and cloud AI is enabled. A deterministic **Basic mode** covers common requests without a model. |
| Banking | Balances, searchable transaction history, spending insights, notifications, and reviewable transfer drafts. Transfers require a connection. |
| Accessibility | Voice and text input, read-aloud replies, screen-reader semantics, high contrast, text-size controls, and reduced motion. |
| Voice | Cloud Gemini text-to-speech for supported English and French replies, with device voice fallback. Private on-device replies use device speech. |
| Firebase sandbox | Firebase Auth and App Check, owner-restricted Firestore rules, and Cloud Functions for sandbox transfer validation and execution. |

## Live demo

Open the web demo and select **Try the demo**, or sign in with the fictitious credentials `demo@sauti.app` / `Sauti2026`. Ask “How much money do I have?” and compare the response badge on a Chrome device with Gemini Nano ready and an online browser without it. [Hosted demo](https://sauti-hybrid-ai.web.app) · [Judge walkthrough and Chrome setup](docs/DEMO_GUIDE.md)

## Architecture

Clean Architecture, feature-first, with BLoC, get_it and go_router. The domain layer is pure Dart, and a test enforces it. Details and a Mermaid diagram: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**.

```
lib/
  app/         bootstrap, DI (composition root), router, theme
  core/        Money, Result/Failure, config, connectivity, l10n helpers, shared widgets
  features/
    authentication/  banking/  dashboard/  accounts/  transactions/  transfers/
    financial_insights/  notifications/  ai_agent/  voice/  settings/
  l10n/        app_en.arb  app_fr.arb  app_rn.arb
firebase/      firestore.rules, indexes, Cloud Functions (TypeScript), rules tests
integration_test/  10 end-to-end scenarios
test/          unit/, bloc/, widget/, integration/ (host runner), helpers/
docs/          ARCHITECTURE, AI_ARCHITECTURE, SECURITY, FIREBASE_SETUP, TESTING, DEMO_GUIDE, ROADMAP
```

## Tech stack

Flutter 3.50 / Dart 3.14, `material_ui` (Material 3), flutter_bloc, bloc_concurrency, equatable, go_router, get_it, intl, uuid, shared_preferences, flutter_secure_storage, connectivity_plus, speech_to_text, flutter_tts, permission_handler, local_auth, firebase_core, firebase_auth, cloud_firestore, cloud_functions, firebase_app_check, firebase_ai. Tests use flutter_test, bloc_test, mocktail and integration_test. Backend: Firebase Cloud Functions v2 (TypeScript, Node 22).

## Getting started

Prerequisites: Flutter 3.50+ and an Android emulator or device (or an iOS simulator, or Chrome).

```bash
cd sauti
flutter pub get
flutter run                 # DEMO mode, no Firebase needed
```

### Demo credentials

| Email | Password |
|---|---|
| `demo@sauti.app` | `Sauti2026` |

Or tap **Try the demo** on the welcome screen. The demo guide is in [docs/DEMO_GUIDE.md](docs/DEMO_GUIDE.md).

### Environment configuration

All configuration is passed with `--dart-define`. See `config/env.example.json` and copy it to the git-ignored `config/env.json`.

| Variable | Default | Meaning |
|---|---|---|
| `SAUTI_ENV` | `demo` | `demo` = simulated bank; `live` = Firebase sandbox bank |
| `SAUTI_AI_MODEL` | `gemini-3.8-flash` | Gemini model used through Firebase AI Logic |
| `SAUTI_FUNCTIONS_REGION` | `europe-west1` | Must match the deployed functions |
| `FIREBASE_*` | empty | Firebase client options. Configure these and web App Check to exercise Firebase AI Logic in Chrome. |
| `SAUTI_APP_CHECK_DEBUG` | `false` | Use App Check debug providers (debug builds only) |
| `SAUTI_APP_CHECK_DEBUG_TOKEN` | empty | A debug token registered in the Firebase console, for judging/test builds only. Revoke it afterwards. |

```bash
flutter run --dart-define-from-file=config/env.json
```

### Firebase setup

See **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)**: project creation, App Check, and deploying rules and functions.

## Running tests

```bash
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <device-id>   # 10 e2e scenarios on a device
(cd firebase/functions && npm install && npm test)    # server transfer rules
(cd firebase/rules-tests && npm install && npm test)  # Firestore rules (needs Java 21+)
```

## Known limitations

* **Chrome on-device inference** requires eligible desktop Chrome with the local model ready. [Firebase setup requirements](https://firebase.google.com/docs/ai-logic/hybrid/web/get-started)
* **Android and iOS** have hybrid inference implementations that still need testing on eligible physical devices.
* **Kirundi speech** depends on the device's speech engines. The user can switch to French voice or continue by typing. Kirundi translations are pending fluent-speaker review.
* **Banking** uses a simulated bank or a Firebase sandbox. A real bank integration and server-verifiable transfer approval are future work. [Security notes](docs/SECURITY.md)

## Documentation

[Architecture](docs/ARCHITECTURE.md) · [AI architecture](docs/AI_ARCHITECTURE.md) · [Security](docs/SECURITY.md) · [Firebase setup](docs/FIREBASE_SETUP.md) · [Testing](docs/TESTING.md) · [Demo guide](docs/DEMO_GUIDE.md) · [Video demo script](docs/VIDEO_DESCRIPTION.md) · [Roadmap](docs/ROADMAP.md) · [Implementation plan](IMPLEMENTATION_PLAN.md) · [Hackathon submission](docs/SUBMISSION.md)

## License

Apache License 2.0. See [LICENSE](LICENSE).
