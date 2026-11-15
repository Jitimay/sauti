import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('signed-in demo user lands on the dashboard with DEMO banner and live balance', (t) async {
    final h = TestHarness();
    await h.setUp();
    await h.pumpApp(t);
    expect(find.textContaining('DEMO'), findsOneWidget);
    expect(find.text('250,000 BIF'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
  });
}
