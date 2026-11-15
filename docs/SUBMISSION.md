# #BuildHybridAI 2026 — Sauti submission kit

Deadline: **Nov 30, 2026, 2:00 PM PT** (Dec 1, 00:00 in Bujumbura). Commits after that are not evaluated.

Everything below is a draft for the Devpost form. Items marked **⚠ verify** describe behaviour that must be checked on real hardware before submitting. Remove or soften any claim you could not demonstrate.

---

## 1. Devpost text

**Tagline:** Talk to your bank in Kirundi, French or English. A private, on-device AI banking agent for people who can't use banking apps.

### Inspiration

Most people in Burundi bank on a phone, but banking apps assume you can read small text, navigate menus and type. Blind and visually impaired people, elderly users, people with limited hand mobility and people with limited literacy get locked out, or have to hand their phone and their PIN to someone else. Connectivity is also patchy, and sending your financial life to a server isn't always acceptable.

### What it does

Sauti ("voice" in Kiswahili) is a voice-first banking agent. You say *"How much money do I have?"*, *"Who sent me money yesterday?"*, *"How much did I spend on food last month?"* or *"Send 20,000 francs to Jean"*. Sauti answers aloud in plain language.

* **Hybrid AI with Firebase AI Logic, on-device first:**
  * Android: Gemini Nano through the hybrid SDK.
  * Chrome: built-in Gemini Nano through the JS SDK.
  * iOS: Apple Foundation Models, with Firebase's `GeminiLanguageModel` as cloud fallback.

  Every reply carries a badge: **On-device AI · private**, **Cloud AI** or **Basic mode**.
* **The AI never moves money.** It can only prepare a draft. You confirm on screen, authenticate with your fingerprint or passcode, and press **Send**. A receipt appears only after the bank confirms.
* **The AI never invents numbers.** On Android and Chrome, Gemini Nano only labels the request as a small JSON intent. Sauti's typed tools fetch the data and its templates write the reply, so every figure comes from the bank. A grounding guard checks LLM-written replies, on-device or cloud.
* **Accessible from the first screen:**
  * screen-reader labels everywhere;
  * text up to 200%;
  * high contrast, reduced motion and a simplified mode;
  * 56 dp touch targets;
  * voice is never required.
* **Works offline:** on-device AI, an encrypted snapshot labelled "saved at HH:mm · not live", and a deterministic basic mode. Transfers are refused offline and never queued.
* **Three languages:** English, French and Ikirundi, for the interface and the spoken replies.

### How we built it (how Firebase AI Logic is used)

Flutter app, Clean Architecture, BLoC. The AI layer is an `AgentOrchestrator` that tries providers in order, and every provider goes through one permissioned `ToolRegistry`. The registry validates arguments strictly, enforces permissions, and keeps an audit log without personal data.

| Tier | Firebase AI Logic usage | Code |
|---|---|---|
| On-device, Android | `Firebase.ai(...).generativeModel(onDeviceConfig = OnDeviceConfig(InferenceMode.PREFER_ON_DEVICE))`, `FirebaseAIOnDevice.checkStatus()/download()`, `response.inferenceSource` | `packages/sauti_hybrid_ai/android/.../SautiHybridAiPlugin.kt` |
| On-device, Chrome | `getGenerativeModel(ai, { mode: PREFER_ON_DEVICE, onDeviceParams: { promptOptions: { responseConstraint } }, inCloudParams })`, `initializeDeviceModel()`, `inferenceSource` | `packages/sauti_hybrid_ai/lib/src/web_hybrid_ai.dart` |
| On-device, iOS | Apple `LanguageModelSession` with `SystemLanguageModel`, then `FirebaseAI.firebaseAI(...).geminiLanguageModel(name:)`, with Sauti's tools bridged in | `packages/sauti_hybrid_ai/ios/.../SautiHybridAiPlugin.swift` |
| Cloud | `FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true).generativeModel(tools: …)` with typed function calling | `lib/features/ai_agent/data/cloud/gemini_ai_provider.dart` |

Other Firebase products used:
* **App Check:** Play Integrity / App Attest / reCAPTCHA, limited-use tokens, replay protection on callables.
* **Authentication.**
* **Firestore:** restrictive rules; money state is server-written only.
* **Cloud Functions:** server-side transfers with idempotency, limits and ownership checks.

### Challenges

* The Flutter `firebase_ai` package has no hybrid API, so we wrote a small native plugin per platform. Each one routes every tool call back into the same Dart registry.
* On-device models on Android and Chrome can't call functions and have a ~4k-token budget. We turned that into a safety feature: the model labels the request, and Sauti answers from typed data.
* Kirundi is barely supported by speech engines and on-device models, so Sauti detects support at runtime and degrades honestly to text input, French voice, the cloud agent or basic mode.

### Accomplishments

* One agent and one tool registry across three on-device engines, the cloud and an offline mode.
* Transfers are designed so that no model output can move money.
* 166 app tests plus 6 plugin tests, an architecture test that keeps the domain layer pure, and accessibility guideline tests.

### What we learned / What's next

* Native-speaker review of the Kirundi phrases, and a Kirundi speech-recognition partner.
* Field tests with blind users and elderly users in Bujumbura.
* A licensed bank integration behind the existing `BankRepository` seam (regulator: BRB).
* Server-side step-up authentication.

---

## 2. Built during the submission period (required for existing work)

The repository was created on **Nov 15, 2026**, after the Nov 11 start, and everything in it was built during the contest period. See `git log`.

* **Nov 15:** app, simulated bank, AI agent and tools, voice, accessibility, transfers, Firebase rules and functions, tests.
* **Nov 15:** security fixes, then iOS hybrid inference.
* **Nov 15–?:** Android and Chrome hybrid inference, on-device model management, App Check judging token, offline cache fixes, submission docs.

**Pre-existing code and tools disclosure:**
* Flutter `flutter create` template.
* Open-source packages listed in `pubspec.yaml`.
* **AI coding assistant:** Claude Code (Anthropic) was used to write and review code and docs. *(Edit to reflect the tools you actually used.)*

---

## 3. Testing instructions for judges

**Demo login:** `demo@sauti.app` / `Sauti2026`, or tap **Try the demo**. The bank is simulated, with fictitious data; no real money is involved.

* **Web (fastest):** `https://<your-project>.web.app`
  * Cloud AI works in any browser.
  * On-device needs desktop Chrome 139+ with `chrome://flags/#prompt-api-for-gemini-nano-multimodal-input` enabled. Then go to Settings → *Private on-device AI* → **Download**, and ask a question. The badge shows *On-device AI · private*.
* **Android:** install `sauti-judging.apk` (link). On-device needs a phone supported by ML Kit's Prompt API (Gemini Nano). Then go to Settings → *Private on-device AI* → **Download**. Switch on airplane mode and ask *"How much money do I have?"*.
* **iOS:** TestFlight link (if available). On-device needs Apple Intelligence on iOS 26+; the Gemini fallback needs iOS 27+.

Things to try:
1. Ask in English or French. Try *"Envoie 20 000 francs à Jean"* and see that nothing is sent until you authenticate and press **Send**.
2. Turn on TalkBack or VoiceOver and complete a balance check by voice.
3. Settings → Language → Ikirundi.

---

## 4. Demo video script (≤ 3:00, English or English subtitles, public on YouTube)

| Time | Shot | Voice-over |
|---|---|---|
| 0:00–0:20 | A blind user's hands on a phone, TalkBack speaking | "In Burundi, banking apps lock out people who can't read small screens. Sauti lets them just talk to their bank." |
| 0:20–0:50 | Online: "How much money do I have?" → spoken answer, **Cloud AI** badge, then Settings → Download Gemini Nano | "Sauti uses Firebase AI Logic hybrid inference: Gemini in the cloud, Gemini Nano on the phone." |
| 0:50–1:25 | **Airplane mode on.** Same question, then "How much did I spend on food last month?" → **On-device AI · private** | "Offline, Gemini Nano understands the request on the phone. It only labels the intent; Sauti's tools fetch the numbers, so the AI can't invent your balance." |
| 1:25–2:05 | Online: "Send 20,000 to Jean" → draft card → fingerprint → **Send** → receipt | "The AI can only prepare a transfer. You confirm, authenticate and press Send. The receipt comes from the bank." |
| 2:05–2:30 | Kirundi UI; 200% text; high contrast | "Kirundi, French, English. Text up to 200%, high contrast, and voice is never required." |
| 2:30–2:50 | Quick split: Android, Chrome, iPhone badges | "The same agent runs on Android, Chrome and iOS, on-device first." |
| 2:50–3:00 | Logo + "Technology without barriers" | — |

**⚠ verify** each shot on real hardware before recording. Don't fake the on-device badge.

---

## 5. Pre-submission checklist

- [ ] Repo public, **Apache-2.0 LICENSE visible in the About section** (GitHub detects `LICENSE`).
- [ ] Firebase project: AI Logic (Gemini Developer API) enabled, App Check registered (Android, iOS, Web), Firestore rules and functions deployed (`docs/FIREBASE_SETUP.md`).
- [ ] App Check debug token created in the console for judging builds, and **revoked after judging**.
- [ ] Judging APK: `flutter build apk --release --dart-define-from-file=config/env.json` (with `FIREBASE_*` and `SAUTI_APP_CHECK_DEBUG_TOKEN`).
- [ ] Web hosted: `flutter build web --dart-define-from-file=config/env.json && firebase deploy --only hosting`.
- [ ] ⚠ verify on a Gemini Nano Android phone: Download → airplane mode → *On-device AI · private*.
- [ ] ⚠ verify in Chrome with the Prompt API flag.
- [ ] ⚠ verify on iOS (Apple Intelligence device) if you claim the iOS path; otherwise present iOS as "builds, not demonstrated".
- [ ] Video uploaded, public, ≤ 3:00, English.
- [ ] Devpost: platforms selected (Android + Web, plus iOS only if verified), repo URL, video URL, testing instructions, AI-tools disclosure.
