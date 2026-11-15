/// Build-time configuration, supplied with `--dart-define`.
///
/// No secrets live in source. Firebase *client* options are public
/// identifiers, but they are still provided per environment rather than
/// committed. See docs/FIREBASE_SETUP.md and `config/env.example.json`.
enum AppEnvironment { demo, live }

final class FirebaseClientConfig {
  const FirebaseClientConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.storageBucket,
    this.iosBundleId,
    this.authDomain,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? storageBucket;
  final String? iosBundleId;
  final String? authDomain;
}

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.aiModel,
    this.firebase,
    this.appCheckDebug = false,
    this.appCheckDebugToken = '',
    this.functionsRegion = 'europe-west1',
  });

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('SAUTI_ENV', defaultValue: 'demo');
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const bundle = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const model = String.fromEnvironment('SAUTI_AI_MODEL', defaultValue: 'gemini-3.8-flash');
    const appCheckDebug = bool.fromEnvironment('SAUTI_APP_CHECK_DEBUG');
    const appCheckDebugToken = String.fromEnvironment('SAUTI_APP_CHECK_DEBUG_TOKEN');
    const region = String.fromEnvironment('SAUTI_FUNCTIONS_REGION', defaultValue: 'europe-west1');

    final hasFirebase = apiKey.isNotEmpty && appId.isNotEmpty && sender.isNotEmpty && project.isNotEmpty;
    return AppConfig(
      environment: env == 'live' ? AppEnvironment.live : AppEnvironment.demo,
      aiModel: model,
      appCheckDebug: appCheckDebug,
      appCheckDebugToken: appCheckDebugToken,
      functionsRegion: region,
      firebase: hasFirebase
          ? FirebaseClientConfig(
              apiKey: apiKey,
              appId: appId,
              messagingSenderId: sender,
              projectId: project,
              storageBucket: bucket.isEmpty ? null : bucket,
              iosBundleId: bundle.isEmpty ? null : bundle,
              authDomain: authDomain.isEmpty ? null : authDomain,
            )
          : null,
    );
  }

  final AppEnvironment environment;
  final String aiModel;
  final FirebaseClientConfig? firebase;
  final bool appCheckDebug;

  /// A debug token registered in the Firebase console (App Check → Manage
  /// debug tokens). Only for judging/test builds handed to people whose
  /// devices cannot be registered one by one; revoke it in the console
  /// afterwards. Never set it for a production release.
  final String appCheckDebugToken;

  /// Must match the region in firebase/functions/src/index.ts.
  final String functionsRegion;

  bool get isDemo => environment == AppEnvironment.demo;
  bool get isFirebaseConfigured => firebase != null;
}
