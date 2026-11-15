import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/app_config.dart';
import 'app.dart';
import 'di/injection.dart';

/// Initialises Firebase (only when configured), App Check, DI, then runs.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final firebaseReady = await _initFirebase(config);

  try {
    await configureDependencies(config: config, firebaseReady: firebaseReady);
  } on StateError catch (e) {
    runApp(_ConfigErrorApp(message: e.message));
    return;
  }
  runApp(const SautiApp());
}

Future<bool> _initFirebase(AppConfig config) async {
  final fb = config.firebase;
  if (fb == null) return false;
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: fb.apiKey,
        appId: fb.appId,
        messagingSenderId: fb.messagingSenderId,
        projectId: fb.projectId,
        storageBucket: fb.storageBucket,
        iosBundleId: fb.iosBundleId,
        authDomain: fb.authDomain,
      ),
    );
    // App Check: attests that requests (Firestore, Functions, AI Logic) come
    // from this genuine app. Debug providers only in debug builds when asked.
    final debug = kDebugMode && config.appCheckDebug;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: debug ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
      providerApple: debug ? const AppleDebugProvider() : const AppleAppAttestProvider(),
      providerWeb: kIsWeb ? ReCaptchaV3Provider(const String.fromEnvironment('RECAPTCHA_SITE_KEY')) : null,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase initialisation failed: ${e.runtimeType}');
    return false;
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(message, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
            ),
          ),
        ),
      );
}
