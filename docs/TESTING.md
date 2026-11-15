# Sauti — Testing

## Latest results (actually executed, 2026-11-15)

| Suite | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` (strict-casts, strict-raw-types) | **No issues found** |
| Unit + BLoC + widget + host integration | `flutter test` | **145 passed, 0 failed** |
| Integration on Android emulator (API 37, arm64) | `flutter test integration_test/app_test.dart -d emulator-5556` | **10/10 scenarios passed** |
| Cloud Functions transfer rules | `cd firebase/functions && npm test` | **6 passed, 0 failed** (TypeScript strict build OK) |
| Firestore rules | `cd firebase/rules-tests && npm test` | **Not executed**: no Java runtime on this machine for the emulator |
| Manual TalkBack / real-device voice | — | **Not executed**: no physical device. Speech and biometrics are faked in automated tests. |

Secret scan (`AIza…`, `private_key`) over `lib/`, `config/`, `functions/src`: 0 hits. `TODO`/`FIXME` in `lib/`: 0.

## What is covered

### Unit tests (`test/unit`)
* **Money**: integer arithmetic, currency mismatch, parser (separators, `20k`, garbage, negatives), locale formatting.
* **Banking domain**: beneficiary resolution (exact, alias, ambiguous, typo, unknown, injection strings), spending analyser (exact demo totals, month-over-month change, empty data), transaction explainer.
* **Simulated bank**: verified receipts, sequential and **concurrent idempotency**, key reuse with a different amount, server-side validation (insufficient funds, limits, min amount, unknown beneficiary, foreign account), offline behaviour, caching decorator (cached marking, local filtering, never caching transfers).
* **Transfers**: state-machine legal and illegal transitions, PrepareTransfer (no money moved, offline refusal, no cached balances), SubmitTransfer (missing, wrong-draft and **expired** authorization; idempotent success; no offline queueing).
* **AI agent**: intent parser (EN/FR/Kirundi), tool registry security (unknown tools, permissions, **malicious arguments**: injected keys, negative/fractional/huge/string amounts, unsaved recipients, invented draft ids, path-like ids), untrusted description fields, audit trail; orchestrator (scenarios 1–4, 7, offline transfer refusal, unknown beneficiary, cloud selection, **cloud unavailable / erroring → fallback**, **hallucinated amount discarded**, non-converging tool loop, forbidden tool request); GroundingGuard; Gemini adapter mapping (declarations, function calls, responses, error mapping, system prompt).
* **Architecture**: domain purity, no Firebase in presentation, no unrestricted rules.

### BLoC tests (`test/bloc`, bloc_test)
TransferBloc (full flow, auth never submits, submit without auth ignored, **5 rapid taps → 1 debit**, cancellation, expiry, declined auth, password fallback, insufficient funds, connectivity loss), AgentBloc (state sequence, confirmation state, dropped concurrent submissions, empty input, clearing), VoiceBloc (recognition, Kirundi unsupported, French override, permission denied, silence, TTS unavailable), AuthBloc (sign-in, wrong password, weak password, enumeration-safe reset, persistence and sign-out), Dashboard, Transaction, Insights, Notifications, and AccessibilityBloc (clamping and persistence).

### Widget tests (`test/widget`)
Login, first-launch flow, dashboard semantics (balance announcement, **DEMO banner exposed to screen readers**), typed assistant, voice task with spoken reply, Kirundi voice fallback notice, full transfer UI (Send disabled until verified), cancellation, manual transfer form, transaction filtering and details, offline banner and cached labels, language switch, text size and high contrast, **200% text scale without overflow**, Flutter accessibility guidelines (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`).

### Integration scenarios (`integration_test/scenarios.dart`)
S1 balance · S2 recent transactions · S3 explain · S4 prepare transfer · S5 cancel · S6 confirm after authentication · S7 connectivity loss · S8 cloud AI unavailable · S9 language change · S10 voice task.
The same file runs on a device (`integration_test/app_test.dart`) and on the host (`test/integration/scenarios_host_test.dart`).

### Server tests
`firebase/functions/src/transfer_rules.test.ts`: input parsing (unknown keys, malformed values), business checks, idempotent replay matching, Burundi day boundary.
`firebase/rules-tests/firestore.rules.test.js` (needs the emulator): owner reads, unauthenticated denial, cross-user denial, no client writes to money state, notification read-flag only, profile whitelist, conversation limits, default deny.

## Fakes used
Automated tests fake only the platform edges: microphone and STT, TTS, biometrics, and connectivity (`test/helpers/test_app.dart`). The composition root, BLoCs, simulated bank, tools and local agent are all real.

## Bugs found by the tests and fixed
* The DEMO banner was hidden from screen readers by route-level `BlockSemantics`.
* Status strip, voice notice and freshness badge overflowed with long (Kirundi) strings.
* `AnimatedSize` with reduced motion caused a layout assertion.
* The intent parser misread "a transfer of" as a recipient and missed accented "à".
* Client/functions region mismatch (found in review).
