    import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sauti/hybrid_ai');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// Simulates the native side calling `executeTool` on Dart.
  Future<String> nativeCallsTool(int requestId, String name, String argsJson) async {
    final reply = await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall('executeTool', {'requestId': requestId, 'name': name, 'arguments': argsJson})),
      null,
    );
    return codec.decodeEnvelope(reply!)! as String;
  }

  test('status maps native fields; missing plugin means unsupported', () async {
    final client = SautiHybridAi();
    expect((await client.status(languageCode: 'en')).onDeviceReason, 'unsupportedPlatform');

    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'status');
      expect((call.arguments as Map)['language'], 'fr');
      return {'onDevice': true, 'onDeviceReason': 'available', 'onDeviceSupportsLanguage': true, 'cloud': false};
    });
    final s = await client.status(languageCode: 'fr');
    expect(s.onDeviceAvailable, isTrue);
    expect(s.onDeviceSupportsLanguage, isTrue);
    expect(s.cloudAvailable, isFalse);
  });

  test('respond round-trips native tool calls to the Dart handler', () async {
    final client = SautiHybridAi();
    final seen = <String, Map<String, Object?>>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map;
      expect(call.method, 'respond');
      expect((args['tools'] as List).single, containsPair('name', 'get_account_balance'));
      final payload = jsonDecode(await nativeCallsTool(args['requestId'] as int, 'get_account_balance', '{"x":1}'));
      return {'text': 'Balance: ${(payload as Map)['amount']}', 'servedBy': 'onDevice'};
    });

    final r = await client.respond(
      instructions: 'i',
      prompt: 'p',
      tools: const [HybridToolSpec(name: 'get_account_balance', description: 'd', params: [])],
      languageCode: 'en',
      allowOnDevice: true,
      allowCloud: false,
      cloudModel: 'm',
      onToolCall: (name, args) async {
        seen[name] = args;
        return {'amount': 250000};
      },
    );
    expect(r.text, 'Balance: 250000');
    expect(r.source, HybridSource.onDevice);
    expect(seen['get_account_balance'], {'x': 1});
  });

  test('tool calls for unknown requests and malformed JSON are rejected, not thrown', () async {
    SautiHybridAi();
    expect(jsonDecode(await nativeCallsTool(999, 'get_account_balance', '{}')), {'status': 'rejected', 'error': 'no_active_request'});

    final client = SautiHybridAi();
    messenger.setMockMethodCallHandler(channel, (call) async {
      final id = (call.arguments as Map)['requestId'] as int;
      final reply = await nativeCallsTool(id, 'x', 'not json');
      return {'text': reply, 'servedBy': 'cloud'};
    });
    final r = await client.respond(
      instructions: 'i',
      prompt: 'p',
      tools: const [],
      languageCode: 'en',
      allowOnDevice: true,
      allowCloud: true,
      cloudModel: 'm',
      onToolCall: (name, args) async => fail('must not run'),
    );
    expect(jsonDecode(r.text), {'status': 'rejected', 'error': 'arguments_not_json'});
    expect(r.source, HybridSource.cloud);
  });

  test('native errors surface as HybridAiException with the native code', () async {
    final client = SautiHybridAi();
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'contextTooLarge', message: 'too long');
    });
    await expectLater(
      client.respond(
        instructions: 'i',
        prompt: 'p',
        tools: const [],
        languageCode: 'en',
        allowOnDevice: true,
        allowCloud: false,
        cloudModel: 'm',
        onToolCall: (name, args) async => const {},
      ),
      throwsA(isA<HybridAiException>().having((e) => e.code, 'code', 'contextTooLarge')),
    );
  });

  test('generateJson parses the native reply, even wrapped in prose', () async {
    final client = SautiHybridAi();
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'generateJson');
      final a = call.arguments as Map;
      expect(a['allowOnDevice'], isTrue);
      expect(jsonDecode(a['schema'] as String), containsPair('type', 'object'));
      return {'text': 'Sure: ```json\n{"intent":"balance"}\n```', 'servedBy': 'onDevice'};
    });
    final r = await client.generateJson(
      instructions: 'i',
      prompt: 'p',
      schema: const {'type': 'object'},
      allowOnDevice: true,
      allowCloud: true,
      cloudModel: 'm',
    );
    expect(r.json, {'intent': 'balance'});
    expect(r.source, HybridSource.onDevice);
    expect(() => HybridJsonResult.parseObject('no json here'), throwsA(isA<HybridAiException>()));
  });

  test('status reports the download state; prepareOnDevice returns the new state', () async {
    final client = SautiHybridAi();
    messenger.setMockMethodCallHandler(channel, (call) async => switch (call.method) {
          'status' => {'onDevice': false, 'onDeviceState': 'downloadable', 'cloud': true},
          'prepareOnDevice' => 'available',
          _ => null,
        });
    expect((await client.status(languageCode: 'en')).onDeviceState, OnDeviceState.downloadable);
    expect(await client.prepareOnDevice(), OnDeviceState.available);
  });
}
