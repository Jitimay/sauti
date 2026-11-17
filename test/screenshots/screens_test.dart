// Renders every main screen with real fonts into test/screenshots/goldens/
// for design review and Devpost screenshots. Skipped in the normal suite:
//   SAUTI_SCREENSHOTS=1 flutter test test/screenshots --update-goldens
@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti/app/app.dart';
import 'package:sauti/core/l10n/app_language.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

const _fontsDir = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final file = File(f);
    if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

Future<void> loadFonts() async {
  final sdk = Platform.environment['SAUTI_FONTS_DIR'] ?? _fontsDir;
  await _load('Roboto', [for (final w in ['Regular', 'Medium', 'Bold', 'Light']) '$sdk/Roboto-$w.ttf']);
  await _load('MaterialIcons', ['$sdk/MaterialIcons-Regular.otf']);
  final assets = Directory('assets/fonts');
  if (assets.existsSync()) {
    final byFamily = <String, List<String>>{};
    for (final f in assets.listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
      final name = f.uri.pathSegments.last.split('-').first;
      byFamily.putIfAbsent(name, () => []).add(f.path);
    }
    for (final e in byFamily.entries) {
      await _load(e.key, e.value);
    }
  }
}

final _off = Platform.environment['SAUTI_SCREENSHOTS'] == null;

void main() {
  setUpAll(loadFonts);

  Future<void> shoot(WidgetTester t, String name) async {
    debugDisableShadows = false; // show real shadows, not test outlines
    addTearDown(() => debugDisableShadows = true);
    await settle(t);
    await expectLater(find.byType(SautiApp), matchesGoldenFile('goldens/$name.png'));
  }

  void go(WidgetTester t, String route) {
    final ctx = t.element(find.byType(Scaffold).last);
    GoRouter.of(ctx).go(route);
  }

  Future<void> say(WidgetTester t, String text) async {
    await t.enterText(find.byType(TextField).last, text);
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(t);
  }

  testWidgets('signed-out', skip: _off, (t) async {
    final h = TestHarness();
    await h.setUp(signedIn: false);
    await h.pumpApp(t);
    await shoot(t, '01_welcome');
    go(t, '/login');
    await shoot(t, '02_login');
  });

  testWidgets('first run', skip: _off, (t) async {
    final h = TestHarness();
    await h.setUp(signedIn: false, language: null, onboarded: false);
    await h.pumpApp(t);
    await shoot(t, '00_language');
  });

  testWidgets('signed-in', skip: _off, (t) async {
    final h = TestHarness();
    await h.setUp();
    await h.pumpApp(t);
    await shoot(t, '03_dashboard');
    go(t, '/assistant');
    await shoot(t, '04_assistant_empty');
    await say(t, 'How much money do I have?');
    await say(t, 'Send 20000 to Jean');
    await shoot(t, '05_assistant_chat');
    go(t, '/activity');
    await shoot(t, '06_activity');
    go(t, '/settings');
    await shoot(t, '07_settings');
    go(t, '/settings/accessibility');
    await shoot(t, '08_accessibility');
    go(t, '/home');
    await settle(t);
    unawaited(GoRouter.of(t.element(find.byType(Scaffold).last)).push('/insights'));
    await shoot(t, '09_insights');
    GoRouter.of(t.element(find.byType(Scaffold).last)).go('/home');
    await settle(t);
    unawaited(GoRouter.of(t.element(find.byType(Scaffold).last)).push('/transfer'));
    await shoot(t, '10_transfer');
  });

  testWidgets('high contrast + large text', skip: _off, (t) async {
    final h = TestHarness();
    await h.setUp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings.highContrast', true);
    await h.pumpApp(t);
    await shoot(t, '12_dashboard_hc');
    go(t, '/assistant');
    await settle(t);
    await say(t, 'Send 20000 to Jean');
    await shoot(t, '13_assistant_hc');
  });

  testWidgets('text 160%', skip: _off, (t) async {
    final h = TestHarness();
    await h.setUp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('settings.textScale', 1.6);
    await h.pumpApp(t);
    await shoot(t, '14_dashboard_160');
  });

  testWidgets('kirundi dashboard', skip: _off, (t) async {
    final h = TestHarness();
    await h.setUp(language: AppLanguage.kirundi);
    await h.pumpApp(t);
    await shoot(t, '11_dashboard_rn');
  });
}
