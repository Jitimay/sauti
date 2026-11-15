# SAUTI — Implementation Plan

_Created 2026-11-15. Living document: the checklist at the bottom is updated as phases complete._

## 1. Phase 1 findings (repository inspection)

| Question | Finding |
|---|---|
| What exists? | Nothing for Sauti. `~/Documents/codes` contains three unrelated projects (`am_tips`, `amtips_web`, `amtips-admin`) which are **left untouched**. Sauti was created fresh in `~/Documents/codes/sauti` via `flutter create --empty`. |
| What is missing? | Everything: app code, Firebase project, `firebase_options`, Firebase CLI (`firebase`), FlutterFire CLI, Cloud Functions, rules, tests, docs. |
| Toolchain | Flutter **3.50.0** stable, Dart **3.14.0**, Node available, Java available. Note: in Flutter 3.50 Material lives in the `material_ui` package (`import 'package:material_ui/material_ui.dart'`). |
| Firebase credentials | **Unavailable.** No project ID, no `google-services.json` / `GoogleService-Info.plist`. → Firebase integration is built behind interfaces and activated only when options are supplied via `--dart-define`. Demo mode is the default and fully functional. |

### Firebase AI Logic — what the current Flutter SDK actually supports (verified in `firebase_ai` 5.1.0 source)

- `FirebaseAI.googleAI()` (Gemini Developer API) and `FirebaseAI.agentPlatform()` backends.
- `generativeModel(model:, tools:, toolConfig:, systemInstruction:, generationConfig:)`.
- Function calling: `FunctionDeclaration(name, description, parameters: {..Schema..})`, `Tool.functionDeclarations`, `response.functionCalls`, `Content.functionResponse(name, map)`, `ChatSession`.
- App Check integration (`useLimitedUseAppCheckTokens`).
- Platforms: Android, iOS, macOS, Web.
- **No on-device / hybrid inference in the Flutter SDK.** Hybrid on-device inference exists only in the Firebase **JS Web SDK** (Chrome desktop Prompt API, and even there no function calling). A grep of the Flutter package for `onDevice|InferenceMode|hybrid` returns nothing.
- Stable model IDs (Firebase docs, today): `gemini-3.8-flash`, `gemini-3.5-flash-lite`, `gemini-4-*`. Sauti defaults to `gemini-3.8-flash`, overridable by `--dart-define=SAUTI_AI_MODEL=...`.

**Consequence for the "hybrid" architecture:** Sauti uses honest tiers:
1. **Cloud LLM** — Gemini via Firebase AI Logic, with typed function calling (when Firebase is configured, the device is online, and the user has not disabled cloud AI).
2. **On-device deterministic agent** — a local multilingual intent engine (rule-based NLU in Dart, EN/FR/Kirundi keywords + amount/name extraction) that drives the *same* tool registry. It is not an LLM and is never presented as one.
3. A slot for a future on-device LLM (`AiProvider` interface); candidates documented in `docs/AI_ARCHITECTURE.md`. No fake adapter is shipped.

### Voice — verified packages

- `speech_to_text` 7.5.0: platform recognizers, `SpeechListenOptions(localeId, listenFor, pauseFor, onDevice, partialResults)`, `locales()`.
- `flutter_tts` 4.2.5: `setLanguage`, `setSpeechRate`, `speak`, `stop`, `isLanguageAvailable`, start/completion handlers.
- `permission_handler` for mic permission; `local_auth` 3.0.2 (`authenticate(localizedReason:, biometricOnly:)`) for device authentication before transfers.
- **Kirundi (`rn-BI`)**: support depends on the device recognizer/TTS engine and is **not assumed**. At runtime Sauti checks `locales()` / `isLanguageAvailable`; when absent it says so, offers French voice, and keeps text input available. Not claimed as working until tested on a device.

## 2. Architecture

Clean Architecture, feature-first, `presentation → domain ← data`. Domain is pure Dart (no Flutter / Firebase imports, enforced by a test that scans imports).

```
lib/
  app/        bootstrap, DI (get_it), router (go_router), theme, app widget
  core/       config, errors (Failure/Result), money, connectivity, l10n helpers, widgets
  features/
    authentication/   Demo + Firebase auth repos, AuthBloc, welcome/login/register/reset
    banking/          BankRepository contract, entities (Account, Transaction, Beneficiary,
                      Notification), simulated bank (demo) + Firestore/Functions bank (live),
                      cached snapshot store
    dashboard/        DashboardBloc + page
    accounts/         AccountBloc + page
    transactions/     TransactionBloc, list/details pages
    transfers/        TransferBloc (state machine), prepare/confirm/receipt pages
    financial_insights/ spending analytics (pure Dart) + InsightsBloc + page
    notifications/    NotificationsBloc + page
    ai_agent/         AiProvider, providers (cloud Gemini, local intent), ToolRegistry + tools,
                      AgentOrchestrator, ResponseComposer, AgentBloc, assistant/history pages
    voice/            SpeechRecognizer / SpeechSynthesizer contracts + adapters, VoiceBloc
    settings/         language, accessibility (AccessibilityBloc / SettingsCubit), profile
firebase/   firestore.rules, firestore.indexes.json, functions/ (TypeScript), rules tests
```

### Key decisions

| Decision | Why |
|---|---|
| **No freezed/injectable/build_runner** | Equatable + hand-written immutable classes and explicit `get_it` registration keep the build simple and reviewable; codegen adds tooling risk on a brand-new SDK (Flutter 3.50) without real value at this size. |
| `Money` value object in **integer minor units** (BIF has no minor unit → exponent 0) | No floating point in monetary logic. Currency-aware formatting via `intl`. |
| `Result<T>` (Success / Err(Failure)) at repository and use-case boundaries | Explicit error handling; no exceptions crossing into BLoCs. |
| LLM never executes transfers | `prepare_transfer` only creates a draft. `confirm_transfer` is registered with `ToolPermission.userGestureOnly`: the registry rejects it when invoked by a model. Submission happens only from the Transfer UI after `local_auth` + explicit button press. |
| Tool args are untrusted | Each tool has a typed input parser that rejects unknown fields, wrong types, negative/zero/oversized amounts, unresolvable beneficiaries. Amounts are re-validated by the bank layer. |
| Idempotency | Draft carries a UUID idempotency key; the bank (simulated and Cloud Function) returns the original receipt for a repeated key and never double-debits. BLoC ignores submit while `submitting` (`droppable` transformer). |
| Data minimisation for cloud AI | Tool results sent to Gemini are reduced projections (no account numbers, no user IDs, no auth tokens). PINs/passwords never enter the agent pipeline. |
| Environment boundary | `SAUTI_ENV=demo` (default) wires `SimulatedBankRepository` + `DemoAuthRepository`, and a persistent **DEMO** banner is shown on every screen. `SAUTI_ENV=live` wires Firebase repos; refuses to start if Firebase options are missing. |
| Offline | `connectivity_plus` + demo "simulate offline" switch. Last good snapshot stored in `flutter_secure_storage`, displayed with a **Cached · updated HH:mm** badge. Transfers are blocked offline and never queued. |
| Localization | `flutter gen-l10n` ARB files (en, fr, rn). Material/Cupertino have no `rn` localizations → a fallback delegate maps `rn` to French for framework widgets only. Kirundi strings are a first draft and flagged for native-speaker review. |

## 3. Packages

Runtime: flutter_bloc, bloc, bloc_concurrency, equatable, go_router, get_it, intl, uuid, shared_preferences, flutter_secure_storage, connectivity_plus, speech_to_text, flutter_tts, permission_handler, local_auth, firebase_core, firebase_auth, cloud_firestore, cloud_functions, firebase_app_check, firebase_ai, material_ui, flutter_localizations.
Dev: flutter_test, bloc_test, mocktail, integration_test, flutter_lints.
Not used (deliberately): dio (no non-Firebase HTTP backend yet), hive/isar (snapshot cache is tiny), crashlytics/analytics (need a configured project; integration points documented — add with privacy defaults when a project exists).

## 4. Risks

1. **No Firebase project** → live mode, Cloud Functions, App Check and Gemini cannot be executed end-to-end here. Mitigation: interfaces + demo mode + documented setup; rules tested in emulator if the emulator can be downloaded.
2. **Kirundi voice** likely unsupported by stock recognizers/TTS. Mitigation: runtime detection, clear fallback, text input always available.
3. **No on-device LLM in Flutter Firebase SDK.** Mitigation: deterministic local agent; honest labelling.
4. **Flutter 3.50 / material_ui split** is new; some packages may lag. Mitigation: verify by building early.
5. **LLM tool misuse / prompt injection** (e.g. transaction descriptions containing instructions). Mitigation: permissioned registry, untrusted-arg validation, model can't confirm, descriptions are passed as data.
6. **No physical device attached** → TalkBack and real speech tests may not be executable in this session; flagged in the test report.

## 5. Implementation sequence & checklist

- [x] Phase 1: inspection, research, this plan
- [x] Phase 2: foundation: config, DI, router, theme (standard + high contrast), l10n (EN/FR/RN, 256 keys), errors, Money, core widgets
- [x] Phase 3: auth (demo + Firebase), banking domain, simulated bank, caching decorator, dashboard, accounts, transactions, with tests
- [x] Phase 4: AI agent: provider abstraction, Gemini adapter, local deterministic engine, typed tool registry, orchestrator, grounding guard, AgentBloc, assistant UI, with tests
- [x] Phase 5: voice ports and adapters, VoiceBloc, Kirundi detection and fallback, accessibility settings, semantics, with tests
- [x] Phase 6: transfer state machine, device/password authentication, idempotent submission, verified receipts, insights, explanations, with tests
- [x] Phase 7: Firestore rules and indexes, Cloud Functions (submitTransfer, provisionSandboxAccount), App Check wiring, offline cache, rules tests (written; emulator not runnable here)
- [x] Phase 8: full analyze/test, integration scenarios (host + Android emulator), docs, demo guide

### Deviations from the original prompt (and why)

| Prompt item | Decision |
|---|---|
| freezed / injectable / json_serializable | Not used: Equatable + explicit DI + hand-written mappers; avoids codegen on a brand-new SDK. |
| dio | Not used: no non-Firebase HTTP backend exists yet. |
| hive / Isar | Not needed: the snapshot cache is a small JSON document in secure storage. |
| Crashlytics / Analytics | Deferred: they need a configured project. Privacy defaults are documented in SECURITY.md. |
| On-device LLM adapter | Not shipped: unsupported by the Flutter SDK. A deterministic local engine was built instead, honestly labelled. |
| Firestore `conversations` collection | Rules exist; the app keeps conversations **on-device, encrypted** by default (data minimisation). |
