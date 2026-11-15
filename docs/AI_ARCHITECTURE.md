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
| **On-device / hybrid inference** | ❌ **Not available.** The source contains no `onDevice`, `InferenceMode` or hybrid API. Hybrid inference exists only in the Firebase **JS Web SDK** (Chrome desktop Prompt API), and even there it has no function calling. |

Default model: `gemini-3.8-flash`, a stable model in the Firebase AI Logic model list at the time of writing. Override it with `--dart-define=SAUTI_AI_MODEL=...`.

## Provider tiers

```
AgentOrchestrator
  ├─ GeminiAiProvider        (cloud LLM, function calling)   — needs Firebase + network + user consent
  ├─ [future] on-device LLM  (AiProviderKind.onDeviceLlm)    — not shipped
  └─ LocalIntentProvider     (deterministic, offline)        — always available, never throws
```

* **Selection:** providers are tried in order. A provider is skipped when `isAvailable()` returns false. The cloud provider is unavailable when Firebase isn't configured, the device is offline, or the user turned cloud AI off in Settings.
* **Failure:** if a provider throws `AiProviderException` (timeout, quota, blocked, invalid response, a tool loop that never converges, or ungrounded figures), the next provider answers and the reply is flagged `usedFallback`. The UI then shows "Cloud AI unavailable — answered on this device".
* **Streaming:** tool progress (`AgentToolStarted`/`Finished`) streams live to the UI. The final reply is held until the provider finishes, so a failing provider never half-answers.

### Why the local engine is not called "on-device AI"

`LocalIntentProvider` is a keyword and slot parser for EN, FR and Kirundi: amounts, recipient names, counts, categories, "yesterday", "last month". It drives **the same typed tools** as Gemini and renders replies from localized templates (`agent_phrasebook.dart`) using typed tool output. It is predictable and testable, but it is not an LLM. It answers "I didn't understand" rather than guessing.

### Future on-device LLM

The `AiProvider` interface is the seam. Candidates to evaluate are Gemma-class models via MediaPipe LLM Inference or a maintained Flutter wrapper. Requirements: tool calling or constrained JSON output, acceptable latency on mid-range Android, and model size. This needs measurement on real devices before adoption.

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
