# Sauti

**Technology without barriers.**

Sauti is an AI banking agent for Burundi and the wider African market, built for blind and visually impaired people, people with limited hand mobility, elderly users, people with limited digital literacy, and anyone who would rather talk to their bank in Kirundi, French or English than navigate menus.

You say what you want: *"How much money do I have?"*, *"Explain my last transaction"*, *"Send 20,000 BIF to Jean"*. Sauti works out the intent, calls **permission-controlled banking tools**, and answers in plain speech. It is not a chatbot that makes things up: every figure comes from a tool, and **money only moves after you verify on your device and press Send yourself**.

> **DEMO build:** the default build uses a clearly labelled **simulated bank** with fictitious data. No real money is involved.

---

## Features

| Area | What works |
|---|---|
| AI banking agent | Voice and text input; spoken replies; conversation history; listening, thinking and tool-running indicators; structured cards; error recovery |
| Hybrid AI | Gemini via **Firebase AI Logic** with typed function calling, plus a **deterministic on-device engine** (offline). Automatic fallback; a grounding guard against invented figures. |
| Tools | `get_account_balance`, `get_recent_transactions`, `search_transactions`, `get_transaction_details`, `explain_transaction`, `calculate_monthly_spending`, `list_beneficiaries`, `prepare_transfer`, `confirm_transfer`, `get_notifications` |
| Transfers | Saved recipients only, then a draft, then device biometric/passcode (or typed password), then an explicit **Send**, then a bank-verified receipt. State machine, idempotency, limits, cancel, no offline queueing. |
| Banking | Dashboard, accounts, transaction history with search and filters, details, spending insights (deterministic, integer money), notifications |
| Accessibility | Screen-reader semantics on every screen, text scaling up to 200% on top of the OS setting, high-contrast theme, simplified mode, reduced motion, 56dp touch targets, never colour-only, voice speed control. Voice is never required. |
| Languages | English, Français, Ikirundi for the UI and agent replies. Kirundi voice support is detected at runtime, with a fallback. |
| Offline | Encrypted last-known snapshot, labelled **"saved at HH:mm · not live"**. The local agent keeps working. Transfers are blocked. |
| Security | Restrictive Firestore rules; server-side transfers in Cloud Functions (auth, App Check, idempotency); secure storage; no secrets in source |

## Screenshots

_Add screenshots from `flutter run` here (dashboard, assistant with balance card, transfer confirmation, receipt, high-contrast mode, Kirundi UI)._

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
| `FIREBASE_*` | empty | Firebase client options. If empty, cloud AI is disabled and the on-device engine is used. |
| `SAUTI_APP_CHECK_DEBUG` | `false` | Use App Check debug providers (debug builds only) |

```bash
flutter run --dart-define-from-file=config/env.json
```

### Firebase setup

See **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)**: project creation, App Check, and deploying rules and functions.

## Running tests

```bash
flutter analyze
flutter test                                          # unit + bloc + widget + host-run integration scenarios
flutter test integration_test/app_test.dart -d <device-id>   # same 10 scenarios on a device/emulator
(cd firebase/functions && npm install && npm test)    # server transfer rules
(cd firebase/rules-tests && npm install && npm test)  # Firestore rules (needs Java 21+ for the emulator)
```

The latest results are in **[docs/TESTING.md](docs/TESTING.md)**.

## Known limitations

* **No on-device LLM.** The Flutter Firebase AI Logic SDK (`firebase_ai` 5.1.0) has no on-device inference. The offline tier is a deterministic intent engine, labelled as such.
* **Kirundi voice** depends on the device's speech engines and was **not verified** on a device with Kirundi voices. Text and French-voice fallbacks are built in. Kirundi translations are a first draft pending native-speaker review.
* **Simulated or sandbox banking only.** No licensed bank integration exists. `BankRepository` is the seam for one.
* **Live mode was not exercised end-to-end.** No Firebase project or credentials were available while building. The Firebase code compiles and is unit-tested at its boundaries, but Gemini, App Check, Firestore and Functions have not been run against a real project.
* **Firestore rules tests** are written but could not be executed here (no Java runtime for the emulator).
* Crashlytics and Analytics are not integrated yet (see docs/SECURITY.md and ROADMAP.md).

## Documentation

[Architecture](docs/ARCHITECTURE.md) · [AI architecture](docs/AI_ARCHITECTURE.md) · [Security](docs/SECURITY.md) · [Firebase setup](docs/FIREBASE_SETUP.md) · [Testing](docs/TESTING.md) · [Demo guide](docs/DEMO_GUIDE.md) · [Roadmap](docs/ROADMAP.md) · [Implementation plan](IMPLEMENTATION_PLAN.md)
