# Running Sauti's on-device AI on iPhone (Mac guide)

Sauti on iOS uses **Apple's on-device AI first** (Apple Foundation Models) and **Gemini through Firebase AI Logic** as the cloud fallback. Both run inside Apple's `LanguageModelSession`. Every banking action still goes through Sauti's own permissioned tools in Dart.

## What you need

| Item | Version |
|---|---|
| Mac with Apple silicon | M1 or newer (M2 is fine) |
| macOS | 27 |
| Xcode | 27 (includes Swift 6.4 and the iOS 27 simulator) |
| Flutter | 3.50 or newer (Dart 3.14) |
| Apple Intelligence | **On**, in System Settings → Apple Intelligence & Siri. The simulator uses the Mac's model. |

Apple's on-device model supports English and French, but **not Kirundi**. In Kirundi, Sauti uses cloud Gemini (if allowed) or basic mode.

## Step 1: Get the code and packages

```bash
git clone git@github.com:Jitimay/sauti.git   # or: git pull
cd sauti
flutter config --enable-swift-package-manager   # hybrid inference needs Swift Package Manager
flutter pub get
```

## Step 2: First run, on-device only (no Firebase needed)

```bash
open -a Simulator            # choose an iPhone 17 running iOS 27
flutter devices              # find the simulator id
flutter run -d "iPhone 17"
```

The first build downloads the Firebase iOS SDK through Swift Package Manager, which takes a few minutes.

In the app: **Try the demo** → **Talk to Sauti** → type *"How much money do I have?"*.
Under the answer you should see **"On-device AI · private"**. That reply came from Apple's model on the device.

If you see **"Basic mode"** instead, check that Apple Intelligence is on, that its model has finished downloading (System Settings shows the status), and that the app language is English or French.

## Step 3: Add the cloud fallback (Firebase AI Logic)

1. In the [Firebase console](https://console.firebase.google.com/), open your project → **AI Services → AI Logic → Get started**, and choose the **Gemini Developer API**.
2. Add an **iOS app** with bundle ID `com.sauti.sauti`. Copy its values into `config/env.ios.json` (copy `config/env.example.json`; this file is git-ignored).
3. App Check: the simulator can't use App Attest, so use the debug provider:
   ```bash
   flutter run -d "iPhone 17" --dart-define-from-file=config/env.ios.json --dart-define=SAUTI_APP_CHECK_DEBUG=true
   ```
   Copy the **App Check debug token** from the Xcode or terminal log and add it in Firebase → **Security → App Check → Apps → Manage debug tokens**.
4. In Sauti, **Settings → Use cloud AI** must be on.

To test the fallback, switch to **Ikirundi**, or turn Apple Intelligence off: answers then show **"Cloud AI"**.

## How to check it's working

| You do | You should see |
|---|---|
| English question, Apple Intelligence on | "On-device AI · private" |
| Same, with the simulator offline | Still "On-device AI · private" (works offline) |
| Kirundi question, cloud allowed | "Cloud AI" |
| Kirundi question, cloud off or offline | "Basic mode" |
| "Send 20000 BIF to Jean" | A **draft** card, "nothing has been sent". Sending still needs device authentication and pressing Send. |

## If the build fails

Send the **full error text**. The Swift code was written against the Firebase iOS SDK 13.1.1 and Foundation Models APIs, but it has not been compiled on a Mac yet. Common causes:

* `No such module 'FoundationModels'`: Xcode is older than 27.
* Swift Package version conflict for `firebase-ios-sdk`: run `flutter clean && flutter pub get`, then build again.
* `geminiLanguageModel` not found: the cloud fallback needs Xcode 27 (Swift 6.4) and iOS 27. On-device still works without it.

## Where the code is

* Swift bridge: `packages/sauti_hybrid_ai/ios/sauti_hybrid_ai/Sources/sauti_hybrid_ai/SautiHybridAiPlugin.swift`
* Dart plugin API: `packages/sauti_hybrid_ai/lib/sauti_hybrid_ai.dart`
* Sauti provider: `lib/features/ai_agent/data/on_device/hybrid_ai_provider.dart`
* Wiring (iOS only): `lib/app/di/injection.dart`
