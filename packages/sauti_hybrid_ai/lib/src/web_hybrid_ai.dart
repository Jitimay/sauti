import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../sauti_hybrid_ai.dart';

/// Hybrid inference on the web through the Firebase AI Logic JS SDK:
/// Chrome's built-in Gemini Nano (Prompt API) on-device, cloud Gemini as
/// fallback (`InferenceMode.PREFER_ON_DEVICE`).
///
/// FlutterFire already loaded `firebase-app.js` from gstatic (exposed as
/// `window.firebase_core`). The AI module is imported from the *same* SDK
/// version, so both share one module registry and one initialised app,
/// including App Check.
final class WebHybridAi implements HybridAiClient {
  WebHybridAi();

  JSObject? _ai;
  JSObject? _aiModule;
  final Map<String, JSObject> _models = {};

  static final _expectedText = [
    {'type': 'text', 'languages': ['en']},
  ];

  JSObject? get _core => globalContext.getProperty<JSObject?>('firebase_core'.toJS);

  Future<JSObject> _ensureAi() async {
    if (_ai != null) return _ai!;
    final core = _core;
    if (core == null) throw const HybridAiException('unavailable', 'Firebase is not initialised');
    final version = core.getProperty<JSString>('SDK_VERSION'.toJS).toDart;
    final module = await importModule('https://www.gstatic.com/firebasejs/$version/firebase-ai.js'.toJS).toDart;
    final app = core.callMethod<JSObject>('getApp'.toJS);
    final backend = module.getProperty<JSFunction>('GoogleAIBackend'.toJS).callAsConstructor<JSObject>();
    final options = JSObject()
      ..setProperty('backend'.toJS, backend)
      ..setProperty('useLimitedUseAppCheckTokens'.toJS, true.toJS);
    _aiModule = module;
    return _ai = module.callMethod<JSObject>('getAI'.toJS, app, options);
  }

  String _mode(bool onDevice, bool cloud) {
    final modes = _aiModule!.getProperty<JSObject>('InferenceMode'.toJS);
    final key = onDevice && cloud
        ? 'PREFER_ON_DEVICE'
        : onDevice
            ? 'ONLY_ON_DEVICE'
            : 'ONLY_IN_CLOUD';
    return modes.getProperty<JSString>(key.toJS).toDart;
  }

  Future<JSObject> _model({
    required bool onDevice,
    required bool cloud,
    required String cloudModel,
    Map<String, Object?>? schema,
  }) async {
    final ai = await _ensureAi();
    final mode = _mode(onDevice, cloud);
    final key = '$mode|$cloudModel|${schema == null ? '' : schema.hashCode}';
    final cached = _models[key];
    if (cached != null) return cached;
    final params = <String, Object?>{
      'mode': mode,
      'inCloudParams': {
        'model': cloudModel,
        'generationConfig': {
          'temperature': 0,
          'maxOutputTokens': 256,
          if (schema != null) 'responseMimeType': 'application/json',
          'responseSchema': ?schema,
        },
      },
      'onDeviceParams': {
        'createOptions': {'expectedInputs': _expectedText, 'expectedOutputs': _expectedText},
        if (schema != null) 'promptOptions': {'responseConstraint': schema},
      },
    };
    return _models[key] = _aiModule!.callMethod<JSObject>('getGenerativeModel'.toJS, ai, params.jsify());
  }

  Future<OnDeviceState> _onDeviceState() async {
    final lm = globalContext.getProperty<JSObject?>('LanguageModel'.toJS);
    if (lm == null) return OnDeviceState.unavailable;
    try {
      final options = {'expectedInputs': _expectedText, 'expectedOutputs': _expectedText}.jsify();
      final v = await lm.callMethod<JSPromise<JSString>>('availability'.toJS, options).toDart;
      return OnDeviceState.parse(v.toDart);
    } catch (_) {
      return OnDeviceState.unavailable;
    }
  }

  @override
  Future<HybridStatus> status({required String languageCode}) async {
    final state = await _onDeviceState();
    return HybridStatus(
      onDeviceAvailable: state == OnDeviceState.available,
      onDeviceReason: state.name,
      // The on-device model only classifies intent; Sauti renders the reply in
      // the user's language. Language policy lives in the Dart provider.
      onDeviceSupportsLanguage: true,
      cloudAvailable: _core != null,
      onDeviceState: state,
    );
  }

  @override
  Future<HybridJsonResult> generateJson({
    required String instructions,
    required String prompt,
    required Map<String, Object?> schema,
    required bool allowOnDevice,
    required bool allowCloud,
    required String cloudModel,
  }) async {
    if (!allowOnDevice && !allowCloud) throw const HybridAiException('unavailable', 'no inference path allowed');
    try {
      final model = await _model(onDevice: allowOnDevice, cloud: allowCloud, cloudModel: cloudModel, schema: schema);
      final result = await model
          .callMethod<JSPromise<JSObject>>('generateContent'.toJS, '$instructions\n\n$prompt'.toJS)
          .toDart;
      final response = result.getProperty<JSObject>('response'.toJS);
      final text = response.callMethod<JSString>('text'.toJS).toDart;
      final source = response.getProperty<JSAny?>('inferenceSource'.toJS)?.dartify()?.toString().toLowerCase() ?? '';
      return HybridJsonResult(
        json: HybridJsonResult.parseObject(text),
        source: source.contains('device') ? HybridSource.onDevice : HybridSource.cloud,
      );
    } on HybridAiException {
      rethrow;
    } catch (e) {
      throw _classify(e);
    }
  }

  @override
  Future<OnDeviceState> prepareOnDevice() async {
    final state = await _onDeviceState();
    if (state != OnDeviceState.downloadable && state != OnDeviceState.downloading) return state;
    try {
      final model = await _model(onDevice: true, cloud: true, cloudModel: 'gemini-3.5-flash-lite');
      // Triggers Chrome's model download; must run from a user gesture.
      final r = model.callMethod<JSAny?>('initializeDeviceModel'.toJS);
      if (r.isA<JSPromise>()) await (r as JSPromise).toDart;
    } catch (_) {
      // Fall through: report whatever state Chrome is in now.
    }
    return _onDeviceState();
  }

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
  }) =>
      // Chrome's on-device model has no function calling; Sauti uses
      // [generateJson] on the web.
      Future.error(const HybridAiException('unavailable', 'no native tool loop on the web'));

  static HybridAiException _classify(Object e) {
    final m = e.toString();
    final lower = m.toLowerCase();
    if (lower.contains('quota') || lower.contains('429')) return HybridAiException('quota', m);
    if (lower.contains('network') || lower.contains('failed to fetch') || lower.contains('offline')) {
      return HybridAiException('network', m);
    }
    if (lower.contains('blocked') || lower.contains('safety')) return HybridAiException('blocked', m);
    return HybridAiException('unknown', m);
  }
}
