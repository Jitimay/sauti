// End-to-end scenarios shared by the device runner (integration_test/app_test.dart)
// and the host runner (test/integration/scenarios_host_test.dart).
//
// They drive the real app (real composition root, real BLoCs, real simulated
// bank, real local agent) with fakes only for microphone/TTS/biometrics and
// connectivity, so results are deterministic on any device.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti/features/ai_agent/domain/providers/ai_provider.dart';

import '../test/helpers/test_app.dart';

Finder _filled(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is FilledButton));

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).first);
  await settle(t);
}

Future<void> _openAssistant(WidgetTester t) async {
  await t.tap(find.text('Assistant'));
  await settle(t);
}

Future<void> _ask(WidgetTester t, String text) async {
  await t.enterText(find.widgetWithText(TextField, 'Type your request'), text);
  await t.tap(find.byTooltip('Send'));
  await settle(t);
}

void runScenarios() {
  late TestHarness h;
  setUp(() => h = TestHarness());

  testWidgets('S1 — user checks account balance', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'How much money do I have?');
    expect(find.textContaining('250,000 BIF available'), findsOneWidget);
  });

  testWidgets('S2 — user asks for recent transactions', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'Show me the last five transactions');
    expect(find.textContaining('Here are your last 5 transactions'), findsOneWidget);
  });

  testWidgets('S3 — user asks Sauti to explain a transaction', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'Explain my last transaction');
    expect(find.textContaining('you received 50,000 BIF from Jean Ndayishimiye'), findsOneWidget);
  });

  testWidgets('S4 — user prepares a transfer (nothing sent)', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'Send 20,000 BIF to Jean');
    expect(find.text('Transfer prepared — not sent'), findsOneWidget);
    expect(h.appliedTransfers, 0);
  });

  testWidgets('S5 — user cancels a transfer', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'Send 20,000 BIF to Jean');
    await t.tap(find.text('Review & confirm'));
    await settle(t);
    await _scrollTo(t, find.text('Cancel transfer'));
    await t.tap(find.text('Cancel transfer'));
    await settle(t);
    expect(find.text('Transfer cancelled. No money was sent.'), findsOneWidget);
    expect(h.appliedTransfers, 0);
  });

  testWidgets('S6 — user confirms a transfer after authentication', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'Send 20,000 BIF to Jean');
    await t.tap(find.text('Review & confirm'));
    await settle(t);
    await _scrollTo(t, find.text("Verify it's me"));
    await t.tap(find.text("Verify it's me"));
    await settle(t);
    await _scrollTo(t, find.text('Send 20,000 BIF now'));
    await t.tap(_filled('Send 20,000 BIF now'));
    await settle(t);
    expect(find.text('Confirmed by the bank'), findsOneWidget);
    expect(h.appliedTransfers, 1);
    await t.tap(find.text('Done'));
    await settle(t);
    expect(find.text('230,000 BIF'), findsOneWidget, reason: 'dashboard shows the new live balance');
  });

  testWidgets('S7 — user loses connectivity', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    h.network.set(false);
    await settle(t);
    expect(find.text('You are offline. Showing saved information.'), findsOneWidget);
    await _openAssistant(t);
    await _ask(t, 'What is my balance?');
    expect(find.textContaining('not live'), findsWidgets);
    await _ask(t, 'Send 5000 BIF to Jean');
    expect(find.textContaining('never queued'), findsOneWidget);
    expect(h.appliedTransfers, 0);
  });

  testWidgets('S8 — AI cloud provider unavailable → deterministic fallback', (t) async {
    // Demo build has no Firebase: the orchestrator must still answer locally.
    await h.setUp();
    await h.pumpApp(t);
    await _openAssistant(t);
    await _ask(t, 'How much did I spend this month?');
    expect(find.textContaining('This month you spent 60,000 BIF'), findsOneWidget);
    final last = (await h.conversations.load()).last;
    expect(last.provider, AiProviderKind.localDeterministic);
  });

  testWidgets('S9 — user changes application language', (t) async {
    await h.setUp();
    await h.pumpApp(t);
    await t.tap(find.text('Settings'));
    await settle(t);
    await t.tap(find.text('Language'));
    await settle(t);
    await t.tap(find.text('Français'));
    await settle(t);
    await t.tap(find.text('Assistant'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextField, 'Écrivez votre demande'), 'Quel est mon solde ?');
    await t.tap(find.byTooltip('Envoyer'));
    await settle(t);
    expect(find.textContaining('disponibles'), findsOneWidget);
  });

  testWidgets('S10 — user completes a banking task using voice', (t) async {
    await h.setUp(voiceFeedback: true);
    h.recognizer.nextUtterance = 'Send 20,000 BIF to Jean';
    await h.pumpApp(t);
    await _openAssistant(t);
    await t.tap(find.bySemanticsLabel('Start speaking'));
    await settle(t);
    expect(find.text('Transfer prepared — not sent'), findsOneWidget);
    expect(h.synthesizer.spoken.last, contains('Nothing has been sent yet'));
    expect(h.appliedTransfers, 0, reason: 'voice can prepare but never send');
  });
}
