# Firebase setup

Sauti runs fully **without Firebase** in DEMO mode. Firebase is needed for:
cloud AI (Gemini via Firebase AI Logic), and LIVE (sandbox) mode with Firebase Auth, Firestore and Cloud Functions.

> Nothing here contains real project ids or keys. Use your own project.

## 1. Create the project

1. Create a Firebase project in the [console](https://console.firebase.google.com/). Cloud Functions needs the **Blaze** plan, which is pay-as-you-go and has a free tier. **This is the only paid component.**
2. Enable:
   * **Authentication** → Email/Password.
   * **Cloud Firestore** (production mode, region close to users, e.g. `europe-west1`).
   * **Firebase AI Logic** → Gemini Developer API.
   * **App Check** → Play Integrity (Android), App Attest (iOS), reCAPTCHA v3 (web).
3. Add apps:
   * Android, package `com.sauti.sauti`. Add the SHA-256 signing fingerprint for Play Integrity.
   * iOS, bundle `com.sauti.sauti`.
   * Web (optional).

## 2. Provide client configuration

Sauti reads Firebase **client** options from `--dart-define` instead of committed files:

```bash
cp config/env.example.json config/env.json   # git-ignored
# fill FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID, ...
flutter run --dart-define-from-file=config/env.json
```

Find the values under Project settings → Your apps. Android and iOS have **different** `FIREBASE_APP_ID` values, so keep one env file per platform (for example `config/env.android.json` and `config/env.ios.json`).

* `SAUTI_ENV=demo` with Firebase options: simulated bank **plus** real Gemini cloud AI.
* `SAUTI_ENV=live`: Firebase Auth, Firestore and Functions sandbox bank. The app refuses to start if options are missing.

FlutterFire CLI (`flutterfire configure`) can be used instead if you prefer generated `firebase_options.dart`. In that case, adapt `bootstrap.dart` to use `DefaultFirebaseOptions.currentPlatform`.

## 3. App Check

* Release builds use Play Integrity or App Attest automatically.
* Debug: run with `--dart-define=SAUTI_APP_CHECK_DEBUG=true`, copy the debug token from the device log, and register it under App Check → Manage debug tokens.
* After verifying traffic, **enforce** App Check for Firestore, Cloud Functions and Firebase AI Logic in the console.

## 4. Deploy rules, indexes and functions

```bash
npm i -g firebase-tools
cd firebase
cp .firebaserc.example .firebaserc     # set your project id
(cd functions && npm install && npm test)
firebase deploy --only firestore:rules,firestore:indexes,functions
```

The functions are deployed in `europe-west1`. If you change the region in `functions/src/index.ts`, pass the same value with `--dart-define=SAUTI_FUNCTIONS_REGION=...`.

On a live user's first sign-in, `FirebaseBankRepository` calls `provisionSandboxAccount`, which creates a **fictitious** sandbox account (250,000 BIF and two beneficiaries). It is idempotent.

## 5. Emulators (local)

```bash
cd firebase && firebase emulators:start     # requires Java 21+
```

Point the app at the emulators with `useFirestoreEmulator` and `useFunctionsEmulator` in a debug-only branch if needed (not wired by default).

## Platform notes

| Platform | Status |
|---|---|
| Android | Supported. minSdk 23, `FlutterFragmentActivity` (needed by local_auth). |
| iOS | Supported. Microphone, speech and Face ID usage strings are in `Info.plist`; iOS 15+. |
| Web | Builds. Voice depends on the browser's Web Speech API; biometric auth is unavailable, so password fallback is used. |
