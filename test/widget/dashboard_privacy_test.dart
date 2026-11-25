import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('Balance visibility toggle also hides the screen-reader amount', (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = TestHarness();
    await harness.setUp();
    await harness.pumpApp(tester);

    final spokenBalance = find.semantics.byLabel(RegExp(r'Available balance: 250,000 Burundian francs'));
    expect(spokenBalance, findsOne);
    expect(find.text('250,000 BIF'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Hide balance'));
    await settle(tester);
    expect(spokenBalance, findsNothing);
    expect(find.text('250,000 BIF'), findsNothing);

    tester.semantics.tap(find.semantics.byLabel('Show balance'));
    await settle(tester);
    expect(spokenBalance, findsOne);
    expect(find.text('250,000 BIF'), findsOneWidget);
    semantics.dispose();
  });
}
