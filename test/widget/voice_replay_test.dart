import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti/features/ai_agent/domain/entities/chat_message.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('saved conversation is restored silently; only the new reply is spoken', (t) async {
    final h = TestHarness();
    await h.setUp(voiceFeedback: true);
    await h.conversations.save([
      ChatMessage(id: 'u1', role: ChatRole.user, text: 'Old question', timestamp: testNow),
      ChatMessage(id: 'a1', role: ChatRole.assistant, text: 'Old answer', timestamp: testNow),
    ]);
    await h.pumpApp(t);
    await t.tap(find.text('Assistant'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(t);
    expect(find.text('Old answer'), findsOneWidget);
    expect(h.synthesizer.spoken, isEmpty, reason: 'restoring history must not read it aloud');

    await t.enterText(find.widgetWithText(TextField, 'Type your request'), 'How much money do I have?');
    await t.tap(find.byTooltip('Send'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(t);
    expect(h.synthesizer.spoken, hasLength(1));
    expect(h.synthesizer.spoken.single, contains('250,000 BIF'));
  });
}
