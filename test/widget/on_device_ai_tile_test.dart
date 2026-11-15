import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti/features/settings/presentation/pages/settings_page.dart';
import 'package:sauti/l10n/app_localizations.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../unit/ai_agent/hybrid_intent_provider_test.dart' show FakeIntentClient;

void main() {
  testWidgets('on-device AI tile offers a one-tap download, then reports ready', (tester) async {
    final client = _DownloadingClient();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: OnDeviceAiTile(client: client)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Download it once'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Download'));
    await tester.pumpAndSettle();
    expect(client.prepared, isTrue);
    expect(find.textContaining('work without internet'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}

final class _DownloadingClient extends FakeIntentClient {
  _DownloadingClient() : super(const {}, state: OnDeviceState.downloadable);
  bool prepared = false;

  @override
  Future<OnDeviceState> prepareOnDevice() async {
    prepared = true;
    return state = OnDeviceState.available;
  }
}
