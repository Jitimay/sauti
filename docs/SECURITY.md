# Sauti — Security

## Threat model (summary)

| Threat | Mitigation | Where |
|---|---|---|
| AI executes or fakes a transfer | Tools can only draft. Submission requires a UI-created `TransferAuthorization`. Receipts come only from the bank. `confirm_transfer` never sends. | `banking_tools.dart`, `submit_transfer.dart`, `transfer_bloc.dart` |
| Prompt injection via transaction text | Third-party text (descriptions, counterparty names, notification details) is sent as `*_untrusted`; the system prompt tells the model to ignore instructions in it; strict tool args; server re-validation | `banking_tools.dart`, `sauti_system_prompt.dart` |
| Malicious or misleading tool arguments (negative, fractional or huge amounts, injected account ids, unknown recipients) | Strict parsers reject unknown keys and bad types or ranges. Recipients must be saved beneficiaries. The bank re-checks everything. | `agent_tool.dart`, `beneficiary_resolver.dart`, `simulated_bank_repository.dart`, `functions/src/transfer_rules.ts` |
| Hallucinated balances | `GroundingGuard` discards cloud replies containing figures not backed by tools; cards are rendered from tool output | `grounding_guard.dart` |
| Duplicate submission (double tap, retry, network glitch) | `droppable` transformer, state machine, and an idempotency key enforced by the bank (in-flight dedupe plus stored receipt) | `transfer_bloc.dart`, `simulated_bank_repository.dart`, `functions/src/index.ts` |
| Stale authorization | Authorization bound to the draft's idempotency key and valid for 2 minutes; expiry forces re-authentication | `transfer_authorization.dart` |
| Offline replay or queueing of money movement | Transfers refuse to run offline or against cached balances. Nothing is queued. | `prepare_transfer.dart`, `submit_transfer.dart` |
| Unknown outcome reported as success | Unknown errors map to `UnexpectedFailure`; the UI says the result could not be confirmed and that retrying is safe (same key) | `firebase_bank_repository.dart`, `transfer_confirm_page.dart` |
| Spoken PINs or passwords | Never requested. Authentication uses the device biometric/passcode prompt, or a typed, obscured account password that is checked by the auth provider and then cleared. The system prompt refuses PINs. | `device_transfer_authenticator.dart`, `transfer_confirm_page.dart` |
| Cross-user data access | Firestore rules restrict reads to `users/{uid}`; all money state is server-written only | `firebase/firestore.rules` |
| Forged clients and API abuse | App Check: Play Integrity or App Attest, `enforceAppCheck` on callables. Callables and AI Logic use limited-use tokens; `consumeAppCheckToken` plus an explicit `alreadyConsumed` check rejects replayed tokens | `bootstrap.dart`, `firebase_bank_repository.dart`, `functions/src/index.ts` |
| Data at rest on device | Offline snapshot and conversation are stored in `flutter_secure_storage` (Keystore/Keychain) and cleared on sign-out. Firestore's unencrypted disk cache is disabled in live mode and reads go to the server, so the encrypted snapshot is the only offline copy. Android backup is disabled. Settings in SharedPreferences are non-sensitive. | `bank_snapshot_store.dart`, `secure_conversation_repository.dart`, `injection.dart`, `app.dart` |
| Secrets in source | None. Firebase client options come from `--dart-define`; there are no service accounts; `config/env.json` is git-ignored | `app_config.dart`, `.gitignore` |
| Account enumeration via password reset | Same message whether or not the account exists | `auth_bloc.dart` |
| Logging PII | The tool audit log records only name, caller, outcome and duration. Auth events never include passwords, even in `props`. | `tool_registry.dart`, `auth_bloc.dart` |
| Confusing demo with real money | Persistent DEMO banner (also exposed to screen readers), "DEMO" references, fictitious data only | `status_banners.dart`, `demo_seed.dart` |

## Data minimisation for cloud AI

Sent to Gemini: the user's words, recent conversation **text**, tool names and schemas, and minimised tool payloads (account name/type/available amount; transactions with opaque id, direction, amount, counterparty, category, date, and description marked untrusted; beneficiary names).
Never sent: account numbers, user id, email, auth tokens, passwords, PINs, device identifiers.
Users can turn cloud AI off in Settings; Sauti then uses only the on-device engine.

## Firestore rules

See `firebase/firestore.rules`. Default deny. Owners can read their own subtree. Accounts, transactions, beneficiaries and transfer requests are write-denied for clients. Notifications allow only `read: true`. Profile writes use whitelisted fields with size limits. Tests: `firebase/rules-tests/firestore.rules.test.js` (needs the emulator, see TESTING.md).

## Known gaps (to address before any real-money use)

* **Device authentication is enforced by the app, not the server.** `submitTransfer` verifies Firebase Auth and App Check, but receives no proof that the user just passed the biometric/passcode prompt. Before real money, bind it server-side, e.g. a per-device key in Keystore/Secure Enclave that requires biometric unlock and signs a server-issued challenge, or require a recent `auth_time` for password re-authentication.

* The simulated and sandbox bank are not a licensed core-banking integration. A real provider needs its own security review, PSD-style consent and regulatory approval (BRB in Burundi).
* No server-side rate limiting beyond App Check yet; add per-user quotas on `submitTransfer`.
* Beneficiary creation is intentionally not implemented. It needs out-of-band verification (e.g. OTP to a registered device).
* Firebase Crashlytics and Analytics are not integrated yet. When they are added, disable collection by default and exclude all banking data.
* Root/jailbreak detection, certificate pinning and screenshot protection on sensitive screens are not implemented.
