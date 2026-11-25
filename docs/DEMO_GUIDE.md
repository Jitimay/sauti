# Sauti | Judge demo guide

Open the [hosted demo](https://sauti-hybrid-ai.web.app). Choose English and complete onboarding if prompted. Select **Try the demo**, or use `demo@sauti.app` / `Sauti2026`. The demo uses fictitious accounts and funds.

## Reproduce the balance question across inference modes

Use “How much money do I have?” for every run. Keep the balance card and inference badge visible.

| Run | Setup | Expected result |
|---|---|---|
| **Cloud** | Go online in a browser environment where Chrome's local model is unavailable. Enable **Use cloud AI (Gemini)** in Settings. | A balance card and **Cloud AI** badge on the Firebase-configured build. |
| **On-device** | Open eligible desktop Chrome and follow the [Firebase hybrid setup requirements](https://firebase.google.com/docs/ai-logic/hybrid/web/get-started). Go to **Settings → Private on-device AI (Gemini Nano)**. Select **Download** when offered. Wait for **Ready** before asking the question. | A balance card and **On-device AI · private** badge. |
| **Offline** | While still online, load the dashboard and run the on-device query once. Leave the page open, disconnect, and repeat the query. | The saved balance with a cache timestamp. The inference label reports the mode used. **Basic mode** means the deterministic intent engine answered. |

Use the app’s balance card and status indicators as evidence. The demo connectivity toggle can exercise the cached banking path. Disconnect the device or use browser network controls when demonstrating actual offline inference.

If Chrome reports the model as unavailable, check that the device meets the Firebase guide’s browser, hardware, storage, and flags requirements. Confirm the device model is ready before recording an on-device result. If speech recognition or playback is unavailable, continue by typing. Speech support depends on the browser and the selected language.

## Transfer review and accessibility

1. Reconnect and ask “Send 20,000 francs to Jean.” Confirm that the assistant returns a draft with the recipient, amount, and fee.
2. Open the review screen and check the authentication step. The browser can use the demo account password. Submit only if you want to test a debit in the simulated bank.
3. Repeat the balance task with the keyboard and available screen reader. Try **Settings → Accessibility** for text size and high contrast, or switch to **Ikirundi** in language settings.

## Run from source

```bash
flutter pub get
flutter run -d chrome
```

This starts the simulated bank and deterministic Basic mode without Firebase credentials. To enable Gemini, supply your own Firebase project configuration and configure web App Check as described in [Firebase setup](FIREBASE_SETUP.md).

```bash
flutter run -d chrome --dart-define-from-file=config/env.json
```

Keep `SAUTI_ENV=demo` to use the simulated bank with the configured AI providers. See the [recording script](VIDEO_DESCRIPTION.md) for the timed walkthrough.
