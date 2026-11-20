# Sauti — Video Demo Description & Narration Script

> **Target Hackathon:** [#BuildHybridAI 2026](https://firebasehybridaihackathon.devpost.com/) (Google Firebase & Devpost)  
> **Target Video Length:** 2:45 – 3:00 minutes  
> **Recommended Resolution:** 1080p or 4K (60fps)  
> **Live Demo URL:** [https://sauti-hybrid-ai.web.app](https://sauti-hybrid-ai.web.app)  

---

## 1. YouTube Video Metadata (Copy & Paste)

### Title Options
* **Option 1 (Recommended):** `Sauti — Accessible Voice Banking with Firebase Hybrid AI (#BuildHybridAI 2026)`
* **Option 2:** `Sauti: Private, On-Device AI Banking Agent for Africa | Firebase Hybrid AI Hackathon`
* **Option 3:** `Sauti — Voice-First AI Banking with Gemini Nano & Firebase AI Logic`

---

### Description Box (Ready to Copy into YouTube)

```text
Sauti ("Voice" in Swahili) is an accessible, voice-first AI banking agent built for Burundi and East Africa — submitted to the #BuildHybridAI 2026 Google Firebase Hackathon on Devpost.

Millions of blind, low-vision, elderly, or low-literacy users are locked out of mobile banking. They are often forced to hand their phones and secret PINs to strangers. Sauti changes that: talk to your bank in Kirundi, French, or English, completely hands-free, with private on-device AI.

🏆 Devpost Submission: https://devpost.com/software/sauti
🌐 Live Web Demo: https://sauti-hybrid-ai.web.app (Try Demo: demo@sauti.app / Sauti2026)
📂 GitHub Repository: https://github.com/your-username/sauti

---

⏱️ TIMESTAMPS / CHAPTERS:
0:00 - The Problem: Financial Exclusion in Africa
0:28 - Welcome Screen & Accessible Design
0:50 - Live Balance Query (Gemini TTS & Voice Feedback)
1:18 - Explaining Transactions (Data-Grounded Insights)
1:42 - Safety First: The AI Never Moves Money
2:05 - Biometric Step-Up & Server-Verified Receipt
2:26 - Offline Hybrid Mode & Data Freshness Badging
2:45 - Architecture: Firebase AI Logic & Clean Flutter

---

✨ KEY HIGHLIGHTS & INNOVATIONS:
• Hybrid AI with Firebase AI Logic: Runs on-device first via Gemini Nano on Android (firebase-ai-ondevice) and desktop Chrome 139+ (Firebase AI JS SDK), Apple Foundation Models on iOS, with intelligent fallback to Cloud Gemini 3.8 Flash.
• Strict Financial Guardrails: The AI only creates drafts. Money moves ONLY after local device authentication (biometric/passcode) and manual user confirmation.
• GroundingGuard: Deterministic protection against LLM hallucinations. All figures come from typed banking tools.
• End-to-End Voice Privacy: Private on-device model responses are never routed to cloud TTS.
• Extreme Accessibility: Atkinson Hyperlegible Next typography, 56dp minimum touch targets, WCAG AAA high-contrast theme, and scaling up to 200%.
• Built for Spotty Connectivity: Encrypted offline snapshot in Keychain/Keystore + deterministic offline Basic Mode.

Built during the #BuildHybridAI hackathon (Nov 15–30, 2026) with Flutter 3.50, Firebase AI Logic, Firebase Cloud Functions, Firestore, and App Check.

#Firebase #Gemini #HybridAI #Flutter #Accessibility #Fintech #GeminiNano #BuildHybridAI
```

---

## 2. Full Narration Script & Screen Directions (3 Minutes)

This script is synchronized second-by-second for screen recording and voiceover.

```
+-----------------------------------------------------------------------------------------+
| [0:00 - 0:28] THE HOOK & THE HUMAN PROBLEM                                              |
| Screen: Real-world photos/illustration of rural/urban Burundi, then the Welcome Screen. |
+-----------------------------------------------------------------------------------------+
[Visual: Start on the Welcome screen. Show the Sauti logo, sound wave rings, and the
'Powered by Firebase' badge. The UI is crisp and clean.]

NARRATOR (Voiceover, warm & clear):
"In East Africa, banking happens on mobile phones. But for millions of people—blind and 
visually impaired individuals, the elderly, or those with limited literacy—banking apps 
are a wall of tiny text, complex menus, and English-only forms.

Too often, people are forced to surrender their phone and their secret PIN to a stranger 
just to check their balance or send money.

This is Sauti—'Voice' in Swahili. Sauti is an AI-powered voice banking agent that lets 
anyone talk to their bank in Kirundi, French, or English. Simple, dignified, and 
private."

+-----------------------------------------------------------------------------------------+
| [0:28 - 0:50] 1-TAP DEMO & THE ASSISTANT EXPERIENCE                                     |
| Screen: Tap 'Try the demo'. Lands on Dashboard with balance 250,000 BIF.                |
| Tap the 'Talk to Sauti' microphone orb.                                                 |
+-----------------------------------------------------------------------------------------+
[Visual: Tap 'Try the demo'. The dashboard appears with a clear 'DEMO: Simulated bank' 
banner and a balance card of 250,000 BIF. Tap the central glowing voice orb.]

NARRATOR:
"Let's tap 'Try the demo'. Everything here runs with zero friction. We tap the microphone 
to speak."

USER (Recorded voice):
"How much money do I have?"

[Visual: The voice orb pulses with amber/green sound rings. Status displays 'Listening...', 
then 'Checking your balance...'. Sauti answers in natural, fluent voice.]

SAUTI (Gemini TTS Voice - Aoede):
"You have 250,000 Burundian francs available across your accounts."

[Visual: A structured 'Balance Card' pops into the chat, showing '250,000 BIF · Live'. 
Show the top badge: 'Cloud AI' or 'On-device AI · private'.]

NARRATOR:
"Notice two things: Sauti speaks with warm, natural Gemini TTS audio, and renders a 
structured, accessible card. Every single figure is fetched directly from permissioned 
banking tools—the model never guesses a balance."

+-----------------------------------------------------------------------------------------+
| [0:50 - 1:18] FINANCIAL EXPLANATION & ACCESSIBILITY                                    |
| Screen: Tap mic or type 'Explain my last transaction'.                                  |
+-----------------------------------------------------------------------------------------+
USER (Voice):
"Explain my last transaction."

[Visual: Voice orb pulses. The tool 'explain_transaction' runs. A card appears: 
'+50,000 BIF from Jean Ndayishimiye'.]

SAUTI (TTS):
"Yesterday, you received 50,000 BIF from Jean Ndayishimiye. This is your second transfer 
from Jean this month."

NARRATOR:
"Third-party descriptions are marked untrusted to prevent prompt injection. Our 
GroundingGuard checks every word to ensure zero hallucinations."

+-----------------------------------------------------------------------------------------+
| [1:18 - 2:05] TRANSFER SAFETY: THE AI NEVER MOVES MONEY                                 |
| Screen: User asks to send money. Sauti creates a DRAFT ONLY.                            |
+-----------------------------------------------------------------------------------------+
USER (Voice):
"Send 20,000 francs to Jean."

[Visual: Sauti displays 'Transfer prepared — not sent' with Jean's details and fee: 
'20,000 BIF + 200 BIF fee'. Tap 'Review & confirm'.]

SAUTI (TTS):
"I have prepared a transfer of 20,000 BIF to Jean Ndayishimiye. Nothing has been sent yet. 
Please review and verify on your screen."

NARRATOR:
"This is our most critical safety innovation: in Sauti, the AI is structurally forbidden 
from executing transactions. It can only prepare a draft.

To send money, the user taps 'Review & confirm'. The screen displays an explicit breakdown. 
Notice the Send button is disabled until the user verifies their identity."

[Visual: Tap 'Verify it\'s me'. Fingerprint prompt pops up. Biometric passes.]

NARRATOR:
"We authenticate using the device biometric sensor or passcode. This generates a 
short-lived, 2-minute authorization token bound to this exact draft's idempotency key. 
Now, the user presses 'Send 20,000 BIF now'."

[Visual: Tap Send button. Status shows 'Sending...', then 'Confirmed by the bank' receipt 
with reference #SAUTI-SBX-9941. Balance updates on Dashboard to 230,000 BIF.]

NARRATOR:
"The transaction is executed atomically in Cloud Functions with App Check replay 
protection. The bank confirms it, and the balance updates immediately."

+-----------------------------------------------------------------------------------------+
| [2:05 - 2:30] OFFLINE HYBRID INFERENCE & INCLUSIVE THEMES                               |
| Screen: Settings -> Demo Controls -> 'Simulate no connection'.                          |
+-----------------------------------------------------------------------------------------+
[Visual: Navigate to Settings. Toggle 'Simulate no connection'. An offline status bar appears. 
Open Assistant and ask 'What is my balance?'.]

NARRATOR:
"Connectivity in Africa can be patchy. We simulate going completely offline. 
Watch what happens when we ask for our balance again."

SAUTI (TTS / Device voice):
"You have 230,000 BIF, saved at 12:25. This is offline data and may not be current."

NARRATOR:
"The on-device assistant answers instantly from an encrypted local snapshot stored in the 
device Keystore. Offline data is always clearly labelled. Transfers are safely blocked."

[Visual: Quickly toggle High Contrast Mode and slide Text Scale to 200%. Show how the 
entire UI adapts smoothly without a single overflow.]

NARRATOR:
"And for accessibility: one tap turns on a certified high-contrast theme, and text scales 
up to 200% with Braille Institute Atkinson Hyperlegible fonts."

+-----------------------------------------------------------------------------------------+
| [2:30 - 3:00] THE ARCHITECTURE & CONCLUSION                                             |
| Screen: Architecture diagram slide, GitHub repo, live URL.                              |
+-----------------------------------------------------------------------------------------+
[Visual: Show the Architecture diagram featuring:
  • Android: Gemini Nano via firebase-ai-ondevice
  • Chrome: Prompt API via Firebase AI JS SDK
  • iOS: Apple Foundation Models + geminiLanguageModel
  • Cloud: Gemini 3.8 Flash + Gemini TTS
  • Backend: Cloud Functions v2 + App Check]

NARRATOR:
"Behind the scenes, Sauti utilizes Firebase AI Logic's hybrid mode across Chrome, Android, 
and iOS, backed by Firebase App Check, Firestore, and Cloud Functions. 180 automated tests 
guarantee domain purity and reliability.

Sauti proves that cutting-edge hybrid AI isn't just about chatbots—it's about opening the 
doors of the modern economy to everyone, without barriers.

Try it live right now at sauti-hybrid-ai.web.app. Thank you."

[Visual: End card with Live URL, GitHub Link, and #BuildHybridAI 2026 logo.]
```

---

## 3. Production & Recording Checklist

Before hitting record:
1. **Resolution:** Set emulator or browser window to `1920x1080` or `1280x720` (16:9 ratio).
2. **Audio Levels:** Normalize voiceover to `-14 LUFS` to `-16 LUFS`. Make sure the Gemini TTS speech clips are clearly audible over any background music.
3. **Cursor Visibility:** If recording web, make sure mouse clicks have a subtle visual ripple effect.
4. **Clean Demo State:** Clear browser cache and local storage so the recording starts crisp on the welcome screen.
5. **No Long Pauses:** Snip out any 3–4 second network delays so the video maintains an energetic, confident rhythm.
