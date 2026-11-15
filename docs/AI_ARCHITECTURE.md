# Sauti — AI Architecture

## What the Flutter Firebase AI Logic SDK actually supports (verified 2026-11-15)

Verified by reading the source of `firebase_ai` **5.1.0**, the version installed in this project:

| Capability | Status in Flutter SDK |
|---|---|
| Gemini Developer API backend (`FirebaseAI.googleAI()`) | ✅ Used |
| Agent Platform backend (`FirebaseAI.agentPlatform()`) | ✅ Available |
| Function calling (`FunctionDeclaration`, `Tool.functionDeclarations`, `response.functionCalls`, `Content.functionResponses`) | ✅ Used |
| System instructions, `GenerationConfig`, `ToolConfig` | ✅ Used |
| App Check tokens (`useLimitedUseAppCheckTokens`) | ✅ Used |
| **On-device / hybrid inference** | ❌ **Not in the Flutter SDK.** The source contains no `onDevice`, `InferenceMode` or hybrid API. Sauti therefore uses the native Firebase SDKs through its own plugin (below). |

## Hybrid inference on iOS (native plugin)

`packages/sauti_hybrid_ai` is a local Flutter plugin (Swift Package Manager only, which hybrid requires). It uses Firebase iOS SDK 13.x, the version pinned by `firebase_core`:

* **On-device:** Apple Foundation Models `SystemLanguageModel.default` (iOS 26+, Apple Intelligence on). Works offline, data stays on the device, supports English and French (not Kirundi).
* **Cloud fallback:** `FirebaseAI.firebaseAI(backend: .googleAI(), useLimitedUseAppCheckTokens: true).geminiLanguageModel(name:)` (iOS 27+). Firebase 13.0 removed the interim `HybridModel`/`GenerativeModelSession` API, so this is the current Firebase AI Logic path on Apple platforms.
* Both run in one Apple `LanguageModelSession(model:tools:instructions:)`. Sauti's `ToolSpec`s become Foundation Models tools with dynamic schemas, and the session's tool calls are forwarded to Dart, where the `ToolRegistry` validates and executes them. No banking logic lives in Swift.
* **Routing:** on-device when the model is ready and supports the language. Cloud only when the user allows cloud AI, the device is online and Firebase is configured. Cloud fallback inside the native call happens only if no tool has run yet, so side effects (a prepared draft) are never repeated.
* A compact system prompt (`sauti_compact_prompt.dart`) fits Apple's ~4k-token context.

| | Android (Gemini Nano) | Web (Chrome) | iOS (Apple FM) |
|---|---|---|---|
| On-device function calling | ❌ | ❌ | ✅ |
| On-device structured output | ✅ | ✅ | ✅ |
| Sauti status | planned | planned | built (Dart tested; Swift needs Xcode 27) |

Default model: `gemini-3.8-flash`, a stable model in the Firebase AI Logic model list at the time of writing. Override it with `--dart-define=SAUTI_AI_MODEL=...`.

## Provider tiers

```
AgentOrchestrator
  ├─ HybridAiProvider        (iOS: Apple on-device model → Gemini fallback;
  │                           native tool loop via ToolExecutor)            — iOS only
  ├─ GeminiAiProvider        (cloud LLM, function calling)   — needs Firebase + network + user consent
  └─ LocalIntentProvider     ("Basic mode": deterministic, offline) — always available, never throws
```

Each reply records which engine produced it (`servedBy`) and the UI labels it: **On-device AI · private**, **Cloud AI**, or **Basic mode**. The grounding guard applies to every language model, on-device or cloud.

* **Selection:** providers are tried in order. A provider is skipped when `isAvailable()` returns false. The cloud provider is unavailable when Firebase isn't configured, the device is offline, or the user turned cloud AI off in Settings.
* **Failure:** if a provider throws `AiProviderException` (timeout, quota, blocked, invalid response, a tool loop that never converges, or ungrounded figures), the next provider answers and the reply is flagged `usedFallback`. The UI then shows "Preferred AI unavailable — answered by a backup".
* **Streaming:** tool progress (`AgentToolStarted`/`Finished`) streams live to the UI. The final reply is held until the provider finishes, so a failing provider never half-answers.

### Why basic mode is not called "on-device AI"

`LocalIntentProvider` ("Basic mode" in the UI) is a keyword and slot parser for EN, FR and Kirundi: amounts, recipient names, counts, categories, "ejo hashize", "last month". It drives **the same typed tools** as the language models and renders replies from localized templates (`agent_phrasebook.dart`) using typed tool output. It is predictable and testable, but it is not an LLM. It answers "I didn't understand" rather than guessing. It exists for the phones most Sauti users have: no on-device model and often no signal.

### Next on-device platforms

Android (Gemini Nano through the Firebase AI Logic Android SDK) and Web (Chrome built-in AI through the Firebase JS SDK) go in the same plugin. Neither supports on-device function calling, so there the on-device model will use structured output (intent and slots as JSON) and Sauti's tools will run deterministically.

## Tool system

| Tool | Permission | Notes |
|---|---|---|
| `get_account_balance` | readAccounts | Returns name, type and available balance. No account numbers. |
| `get_recent_transactions` | readTransactions | limit 1–20 |
| `search_transactions` | readTransactions | counterparty, direction, category, amount, `on_date`, `days_back`, limit |
| `get_transaction_details` | readTransactions | id validated against `^[A-Za-z0-9_-]+$` |
| `explain_transaction` | readTransactions | Deterministic facts: recurring, fee, share of category spending |
| `calculate_monthly_spending` | readTransactions | Deterministic totals and comparison with the previous month |
| `list_beneficiaries` | readBeneficiaries | Names only |
| `prepare_transfer` | prepareTransfer | **Creates a draft only.** Saved beneficiaries only. |
| `confirm_transfer` | prepareTransfer | Re-shows the confirmation UI for a session-created draft. **Never sends money.** |
| `get_notifications` | readNotifications | filter: `all`, `unread` or `received_today` |

Every tool has a typed input parser that rejects unknown keys, wrong types, out-of-range numbers and malformed ids. It also has a typed output, a data-minimised `toModelPayload`, an optional UI card, and a permission. `ToolRegistry` checks caller permissions (`userGestureOnly` tools are never offered to an AI), validates arguments, executes, and appends an audit record with tool, caller, outcome and duration. Arguments are never logged.

## Safety measures against hallucination and prompt injection

1. **Cards come from tools, not text.** Balances, transactions and drafts on screen are rendered from typed tool output.
2. **GroundingGuard.** If cloud text mentions a money figure (e.g. "9,999,999 BIF", or a bare grouped number like "999,999") that does not appear in that turn's tool payloads or the user's own words (simple sums and differences are allowed), the reply is discarded and the deterministic engine answers instead. Drafts created by the abandoned attempt are discarded too. Limitation: amounts spelled out in words are not detected.
3. **Untrusted fields.** Third-party text is sent as `description_untrusted`, `counterparty_untrusted` and `detail_untrusted`, and the system prompt tells the model never to follow instructions inside `*_untrusted` fields.
4. **No secrets in prompts.** Passwords, PINs, tokens, user ids and account numbers never enter `AiRequest`. The system prompt tells the model to refuse PINs and passwords.
5. **Server re-validation.** Even a valid draft is re-checked by the bank (simulated or Cloud Function) at submission.

## System prompt

See `lib/features/ai_agent/data/cloud/sauti_system_prompt.dart`. It enforces: the selected language, short speech-friendly sentences, tools for every fact, no invented data, no arithmetic by the model, cached-data disclosure, draft-only transfers ("nothing has been sent yet"), no success claims, no PINs, and staying in scope.

## Voice is a separate component

Speech recognition (`SpeechRecognizer`), speech synthesis (`SpeechSynthesizer`) and inference (`AiProvider`) are independent ports, so any of them can be swapped (for example, a cloud Kirundi ASR) without touching the others.

* **Kirundi** recognition and voice output are **detected at runtime, never assumed**. If the device has no `rn` recognizer, Sauti says so and offers French voice input. The UI and replies stay in Kirundi, and text input is always available. If no Kirundi TTS voice exists, replies are shown as text with a notice. **Not tested on a device with Kirundi voices; none were available.**
* The microphone is never left open: each session is capped at 15 s, with a 3 s silence timeout. Starting to listen interrupts speech output (barge-in).
