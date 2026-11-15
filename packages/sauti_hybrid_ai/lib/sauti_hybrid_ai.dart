/// Native hybrid inference bridge.
///
/// iOS: Apple Foundation Models (`SystemLanguageModel`, on-device) first, then
/// Gemini through Firebase AI Logic (`GeminiLanguageModel`) as cloud fallback.
/// Both run inside Apple's `LanguageModelSession`, which drives the tool loop
/// itself and calls back into Dart for every tool ([HybridToolHandler]).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Which engine produced a reply.
enum HybridSource { onDevice, cloud }

/// What the native side can do right now.
final class HybridStatus {
  const HybridStatus({
    required this.onDeviceAvailable,
    required this.onDeviceReason,
    required this.onDeviceSupportsLanguage,
    required this.cloudAvailable,
  });

  factory HybridStatus.fromMap(Map<Object?, Object?> m) => HybridStatus(
        onDeviceAvailable: m['onDevice'] == true,
        onDeviceReason: (m['onDeviceReason'] as String?) ?? 'unknown',
        onDeviceSupportsLanguage: m['onDeviceSupportsLanguage'] == true,
        cloudAvailable: m['cloud'] == true,
      );

  static const unsupported = HybridStatus(
    onDeviceAvailable: false,
    onDeviceReason: 'unsupportedPlatform',
    onDeviceSupportsLanguage: false,
    cloudAvailable: false,
  );

  /// Apple Intelligence model is ready on this device.
  final bool onDeviceAvailable;

  /// `available`, `deviceNotEligible`, `appleIntelligenceNotEnabled`,
  /// `modelNotReady`, `unsupportedOS`, ...
  final String onDeviceReason;

  /// The on-device model supports the requested language.
  final bool onDeviceSupportsLanguage;

  /// Gemini via Firebase AI Logic can be used (iOS 27+, Firebase configured).
  final bool cloudAvailable;
}

/// Provider-neutral tool description sent to the native side.
final class HybridToolSpec {
  const HybridToolSpec({required this.name, required this.description, required this.params});
  final String name;
  final String description;
  final List<HybridToolParam> params;

  Map<String, Object?> toMap() => {
        'name': name,
        'description': description,
        'params': [for (final p in params) p.toMap()],
      };
}

enum HybridParamType { string, integer, enumeration }

final class HybridToolParam {
  const HybridToolParam({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
  });

  final String name;
  final HybridParamType type;
  final String description;
  final bool required;
  final List<String> enumValues;
  final int? minimum;
  final int? maximum;

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type.name,
        'description': description,
        'required': required,
        'enumValues': enumValues,
        'minimum': ?minimum,
        'maximum': ?maximum,
      };
}

final class HybridResult {
  const HybridResult({required this.text, required this.source});
  final String text;
  final HybridSource source;
}

/// Error from the native side. [code] is one of `unavailable`,
/// `contextTooLarge`, `blocked`, `unsupportedLanguage`, `quota`, `network`,
/// `toolLoop`, `unknown`.
final class HybridAiException implements Exception {
  const HybridAiException(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'HybridAiException($code${message == null ? '' : ': $message'})';
}

/// Executes a tool by name with JSON arguments; returns the JSON payload for
/// the model. Must not throw: report errors inside the payload.
typedef HybridToolHandler = Future<Map<String, Object?>> Function(String name, Map<String, Object?> args);

/// The bridge contract (faked in tests).
abstract interface class HybridAiClient {
  Future<HybridStatus> status({required String languageCode});

  Future<HybridResult> respond({
    required String instructions,
    required String prompt,
    required List<HybridToolSpec> tools,
    required String languageCode,
    required bool allowOnDevice,
    required bool allowCloud,
    required String cloudModel,
    required HybridToolHandler onToolCall,
  });
}

/// Method-channel client. One instance per app.
final class SautiHybridAi implements HybridAiClient {
  SautiHybridAi({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('sauti/hybrid_ai') {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  final MethodChannel _channel;
  final Map<int, HybridToolHandler> _handlers = {};
  int _nextRequestId = 0;

  @override
  Future<HybridStatus> status({required String languageCode}) async {
    try {
      final m = await _channel.invokeMapMethod<Object?, Object?>('status', {'language': languageCode});
      return m == null ? HybridStatus.unsupported : HybridStatus.fromMap(m);
    } on MissingPluginException {
      return HybridStatus.unsupported;
    } on PlatformException {
      return HybridStatus.unsupported;
    }
  }

  /// Runs one request. The native session may call [onToolCall] any number
  /// of times before returning the final text.
  @override
  Future<HybridResult> respond({
    required String instructions,
    required String prompt,
    required List<HybridToolSpec> tools,
    required String languageCode,
    required bool allowOnDevice,
    required bool allowCloud,
    required String cloudModel,
    required HybridToolHandler onToolCall,
  }) async {
    final id = _nextRequestId++;
    _handlers[id] = onToolCall;
    try {
      final m = await _channel.invokeMapMethod<Object?, Object?>('respond', {
        'requestId': id,
        'instructions': instructions,
        'prompt': prompt,
        'tools': [for (final t in tools) t.toMap()],
        'language': languageCode,
        'allowOnDevice': allowOnDevice,
        'allowCloud': allowCloud,
        'cloudModel': cloudModel,
      });
      final text = m?['text'];
      if (text is! String || text.trim().isEmpty) throw const HybridAiException('unknown', 'empty response');
      return HybridResult(text: text, source: m?['servedBy'] == 'cloud' ? HybridSource.cloud : HybridSource.onDevice);
    } on PlatformException catch (e) {
      throw HybridAiException(e.code, e.message);
    } on MissingPluginException {
      throw const HybridAiException('unavailable', 'plugin not registered');
    } finally {
      _handlers.remove(id);
    }
  }

  Future<Object?> _onNativeCall(MethodCall call) async {
    if (call.method != 'executeTool') throw MissingPluginException(call.method);
    final args = (call.arguments as Map<Object?, Object?>?) ?? const {};
    final handler = _handlers[args['requestId']];
    final name = args['name'];
    if (handler == null || name is! String) {
      return jsonEncode({'status': 'rejected', 'error': 'no_active_request'});
    }
    Map<String, Object?> parsed;
    try {
      final raw = args['arguments'];
      final decoded = raw is String && raw.trim().isNotEmpty ? jsonDecode(raw) : const <String, Object?>{};
      parsed = decoded is Map ? decoded.cast<String, Object?>() : const {};
    } on FormatException {
      return jsonEncode({'status': 'rejected', 'error': 'arguments_not_json'});
    }
    return jsonEncode(await handler(name, parsed));
  }
}
