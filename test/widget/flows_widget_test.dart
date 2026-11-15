import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti/core/l10n/app_language.dart';

import '../helpers/test_app.dart';

Finder filledButton(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is FilledButton));

Future<void> scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).first);
  await settle(t);
}

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness());

  testWidgets('Login: wrong password shows error; demo credentials sign in', (t) async {
    await h.setUp(signedIn: false);
    await h.pumpApp(t);
    expect(find.text('Your bank, in your voice'), findsOneWidget);
    await t.tap(find.text('Sign in'));
    await settle(t);

    await t.enterText(find.widgetWithText(TextField, 'Email'), 'demo@sauti.app');
    await t.enterText(find.widgetWithText(TextField, 'Password'), 'wrong-pass1');
    await t.tap(filledButton('Sign in'));
    await t.pump(const Duration(milliseconds: 400));
    await settle(t);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);

    await t.tap(find.text('Fill in demo account'));
    await t.tap(filledButton('Sign in'));
    await t.pump(const Duration(milliseconds: 400));
    await settle(t);
    expect(find.text('Hello, Ange'), findsOneWidget);
  });

  testWidgets('First launch: language → onboarding → welcome', (t) async {
    await h.setUp(signedIn: false, language: null, onboarded: false);
    await h.pumpApp(t);
    expect(find.text('Choose your language'), findsOneWidget);
    await t.tap(find.text('Français'));
    await settle(t);
    expect(find.text('La banque, en parlant'), findsOneWidget);
    await t.tap(find.text('Passer'));
    await settle(t);
    expect(find.text('Essayer la démo'), findsOneWidget);
  });

  testWidgets('Dashboard exposes a single, meaningful balance semantics node', (t) async {
    final sem = t.ensureSemantics();
    await h.setUp();
    await h.pumpApp(t);
    expect(find.bySemanticsLabel(RegExp(r'Available balance: 250,000 Burundian francs')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'DEMO')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Received 50,000 BIF from Jean Ndayishimiye')), findsOneWidget);
    sem.dispose();
  });

  testWidgets('Assistant (typed): balance question answered with tool card', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Assistant'));
    await settle(t);
    await t.tap(find.text('“How much money do I have?”'));
    await settle(t);
    expect(find.textContaining('Your Compte courant has 250,000 BIF available'), findsOneWidget);
    expect(find.text('On-device assistant'), findsWidgets);
  });

  testWidgets('Scenario 10: complete a banking task by voice, reply is spoken', (t) async {
    await h.setUp(voiceFeedback: true);
    h.recognizer.nextUtterance = 'How much money do I have?';
    await h.pumpApp(t);
    await t.tap(find.text('Assistant'));
    await settle(t);
    await t.tap(find.bySemanticsLabel('Start speaking'));
    await settle(t);
    final convo = await h.conversations.load();
    expect(convo.first.text, 'How much money do I have?'); // recognized speech became the request
    expect(convo.last.text, contains('250,000 BIF'));
    expect(h.synthesizer.spoken.single, contains('250,000 BIF'));
  });

  testWidgets('Kirundi voice unsupported → notice with French fallback', (t) async {
    await h.setUp(language: AppLanguage.kirundi);
    await h.pumpApp(t);
    await t.tap(find.text('Umufasha'));
    await settle(t);
    await t.tap(find.bySemanticsLabel('Tangura kuvuga'));
    await settle(t);
    expect(find.textContaining('Ikirundi'), findsWidgets);
    expect(find.text("Koresha ijwi ry'igifaransa"), findsOneWidget);
  });

  testWidgets('Scenarios 4 & 6: voice-free transfer via agent → authenticate → send → receipt', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Assistant'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextField, 'Type your request'), 'Send 20,000 BIF to Jean');
    await t.tap(find.byTooltip('Send'));
    await settle(t);
    expect(find.text('Transfer prepared — not sent'), findsOneWidget);
    expect(h.appliedTransfers, 0);

    await t.tap(find.text('Review & confirm'));
    await settle(t);
    expect(find.text('Confirm transfer'), findsOneWidget);
    final send = filledButton('Send 20,000 BIF now');
    await scrollTo(t, find.text('Send 20,000 BIF now'));
    expect(t.widget<FilledButton>(send).onPressed, isNull, reason: 'send disabled before verification');

    await scrollTo(t, find.text("Verify it's me"));
    await t.tap(find.text("Verify it's me"));
    await settle(t);
    expect(find.text('Identity verified'), findsOneWidget);
    expect(h.appliedTransfers, 0, reason: 'authentication alone never sends');

    await scrollTo(t, find.text('Send 20,000 BIF now'));
    await t.tap(send);
    await settle(t);
    expect(find.text('Transfer complete'), findsOneWidget);
    expect(find.text('Confirmed by the bank'), findsOneWidget);
    expect(find.text('230,000 BIF'), findsOneWidget);
    expect(h.appliedTransfers, 1);
  });

  testWidgets('Scenario 5: cancelling on the confirmation screen sends nothing', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Assistant'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextField, 'Type your request'), 'Send 20000 to Jean');
    await t.tap(find.byTooltip('Send'));
    await settle(t);
    await t.tap(find.text('Review & confirm'));
    await settle(t);
    await scrollTo(t, find.text('Cancel transfer'));
    await t.tap(find.text('Cancel transfer'));
    await settle(t);
    expect(find.text('Transfer cancelled. No money was sent.'), findsOneWidget);
    expect(h.appliedTransfers, 0);
  });

  testWidgets('Manual transfer form (non-voice path)', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Send money'));
    await settle(t);
    await t.tap(find.text('Aline Irakoze'));
    await scrollTo(t, find.widgetWithText(TextField, 'Amount (BIF)'));
    await t.enterText(find.widgetWithText(TextField, 'Amount (BIF)'), '15 000');
    await scrollTo(t, find.text('Review transfer'));
    await t.tap(find.text('Review transfer'));
    await settle(t);
    expect(find.text('Confirm transfer'), findsOneWidget);
    expect(find.text('Aline Irakoze'), findsOneWidget);
  });

  testWidgets('Transaction list filters and opens details', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Activity'));
    await settle(t);
    await t.tap(find.text('Money in'));
    await settle(t);
    expect(find.text('Marché Central'), findsNothing);
    expect(find.text('Jean Ndayishimiye'), findsOneWidget);
    await t.tap(find.text('Jean Ndayishimiye'));
    await settle(t);
    expect(find.text('Transaction details'), findsOneWidget);
  });

  testWidgets('Scenario 7: losing connectivity shows banner and cached labels', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    expect(find.text('Live'), findsOneWidget);
    h.network.set(false);
    await settle(t);
    expect(find.text('You are offline. Showing saved information.'), findsOneWidget);
    await t.tap(find.text('Activity'));
    await settle(t);
    expect(find.textContaining('not live'), findsWidgets);
  });

  testWidgets('Scenario 9: changing language updates the whole UI', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Settings'));
    await settle(t);
    await t.tap(find.text('Language'));
    await settle(t);
    await t.tap(find.text('Français'));
    await settle(t);
    expect(find.text('Réglages'), findsWidgets);
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('Accessibility: text size and high contrast apply app-wide', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Settings'));
    await settle(t);
    await t.tap(find.text('Accessibility'));
    await settle(t);
    await t.tap(find.byTooltip('Text size +'));
    await settle(t);
    await t.tap(find.byTooltip('Text size +'));
    await settle(t);
    expect(find.text('130%'), findsWidgets);
    final ctx = t.element(find.text('130%').first);
    expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(13, 0.01));

    await t.tap(find.text('High contrast'));
    await settle(t);
    expect(Theme.of(t.element(find.text('High contrast'))).colorScheme.surface, Colors.black);
  });

  testWidgets('Dynamic text scaling at 200% does not overflow the dashboard', (t) async {
    await h.setUp();
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await h.pumpApp(t, size: const Size(360, 740));
    expect(t.takeException(), isNull);
    expect(find.textContaining('250,000'), findsOneWidget);
  });

  testWidgets('Touch targets meet Android tap-target guideline on key screens', (t) async {
    final sem = t.ensureSemantics();
    await h.setUp();
    await h.pumpApp(t);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await t.tap(find.text('Assistant'));
    await settle(t);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    sem.dispose();
  });

  testWidgets('Text contrast guideline on dashboard', (t) async {
    final sem = t.ensureSemantics();
    await h.setUp();
    await h.pumpApp(t);
    await expectLater(t, meetsGuideline(textContrastGuideline));
    sem.dispose();
  });
}
