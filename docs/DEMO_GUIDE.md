# Sauti — 3-minute demo guide

Everything runs offline-capable on the **simulated bank** in DEMO mode. No credentials or Firebase are needed.

```bash
flutter run                                   # DEMO mode by default
# or with real Gemini cloud AI on top of the simulated bank:
flutter run --dart-define-from-file=config/env.json   # SAUTI_ENV=demo + Firebase options
```

Demo login: **demo@sauti.app / Sauti2026**, or just tap **Try the demo** on the welcome screen.
Demo data (fictitious): balance **250,000 BIF**; this month: +50,000 from Jean, −15,000 transport, −30,000 groceries, −10,000 utilities, −5,000 airtime, +30,000 from Aline.

## Before going on stage

* Turn on TalkBack if you want to show screen-reader support.
* Settings → Accessibility: keep **Read replies aloud** on.
* Pick the voice language your device supports (English or French are safest). Kirundi voice works only if the device has a Kirundi recognizer or TTS voice. Sauti detects this and offers French voice otherwise.

## Script (~3 min)

| Time | Action | What judges see |
|---|---|---|
| 0:00 | Open Sauti → **Try the demo** | The **DEMO** banner, then the dashboard: large balance with a **Live** badge, quick actions and recent activity |
| 0:20 | Tap **Talk to Sauti**, then the orb: *"How much money do I have?"* | Status reads Listening… then Checking your balance…; a spoken answer; a **balance card** rendered from the banking tool |
| 0:45 | *"Explain my last transaction."* | Explanation of the 50,000 BIF from Jean, with a details card |
| 1:05 | *"Send 20,000 BIF to Jean."* | "Transfer prepared — **not sent**" card, and Sauti says nothing has been sent yet |
| 1:25 | **Review & confirm** | Summary is read aloud. **Send** is disabled. Step 1: **Verify it's me** (fingerprint or password). |
| 1:50 | Press **Send 20,000 BIF now** | "Sending…", then the receipt with **Confirmed by the bank** and a reference; the receipt is spoken |
| 2:05 | **Done** | Dashboard shows **230,000 BIF**, live |
| 2:15 | Settings → Demo controls → **Simulate no connection**, then ask *"What is my balance?"* | Offline banner, "saved at HH:mm · not live" labels, and an answer from the on-device assistant |
| 2:35 | *"Send 5,000 BIF to Jean"* (still offline) | "Transfers need a live connection and are never queued" |
| 2:45 | Settings → Accessibility → raise text size, toggle **High contrast**; switch language to **Français** or **Ikirundi** | The whole UI adapts instantly |

## Showing the hybrid AI honestly

* The assistant header shows which engine answered: **Cloud AI** (Gemini) or **On-device assistant**.
* With Firebase configured: normal requests go to Gemini. Toggle **Simulate no connection** and the same questions are answered by the deterministic on-device engine. If the cloud fails mid-request, the reply is labelled "Cloud AI unavailable — answered on this device".
* **There is no on-device LLM.** The Flutter Firebase AI Logic SDK does not support on-device inference (see AI_ARCHITECTURE.md). The on-device engine is a deterministic intent parser, and we say so.

## Backup lines if voice fails on stage

Everything can be typed in the assistant's text box, and the suggestion buttons cover the main requests.
