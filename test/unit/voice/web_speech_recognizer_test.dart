@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/voice/data/web_speech_recognizer.dart';
import 'package:sauti/features/voice/domain/speech_recognizer.dart';
import 'package:web/web.dart' as web;

void main() {
  test('allows the microphone before starting recognition and keeps only the final result', () async {
    final permission = Completer<bool>();
    final engine = JSObject() as web.SpeechRecognition;
    var starts = 0;
    engine.setProperty('abort'.toJS, (() {}).toJS);
    engine.setProperty(
      'start'.toJS,
      (() {
        starts++;
        for (final (text, isFinal) in [
          ('How much', false),
          ('How much money do I have?', true),
        ]) {
          final alternative = {'transcript': text}.jsify() as JSObject;
          final result = {'length': 1, 'isFinal': isFinal}.jsify() as JSObject
            ..setProperty('item'.toJS, ((JSNumber _) => alternative).toJS);
          final results = {'length': 1}.jsify() as JSObject
            ..setProperty('item'.toJS, ((JSNumber _) => result).toJS);
          final event = {'resultIndex': 0, 'results': results}.jsify();
          engine
              .getProperty<JSFunction>('onresult'.toJS)
              .callAsFunction(null, event);
        }
      }).toJS,
    );

    final recognizer = WebSpeechRecognizer(
      requestMicrophone: () => permission.future,
      createEngine: () => engine,
    );
    final english = await recognizer.resolveLocale(AppLanguage.english);
    expect(english.localeId, 'en-US');
    expect(
      (await recognizer.resolveLocale(AppLanguage.french)).localeId,
      'fr-FR',
    );
    expect(
      (await recognizer.resolveLocale(AppLanguage.kirundi)).supported,
      isFalse,
    );

    final events = recognizer.listen(localeId: english.localeId!).toList();
    await Future<void>.delayed(Duration.zero);
    expect(starts, 0);
    permission.complete(true);
    expect(await events, const [
      RecognitionPartial('How much'),
      RecognitionFinal('How much money do I have?'),
    ]);
    expect(starts, 1);
    expect(engine.lang, 'en-US');
  });

  test('denying microphone access never creates a speech engine', () async {
    final recognizer = WebSpeechRecognizer(
      requestMicrophone: () async => false,
      createEngine: () => throw StateError('Unexpected engine creation'),
    );
    expect(
      await recognizer.listen(localeId: 'en-US').single,
      const RecognitionError(RecognitionErrorKind.permissionDenied),
    );
  });

  test('an immediate no-speech error retries exactly once before reporting silence', () async {
    var attempts = 0;
    final recognizer = WebSpeechRecognizer(
      requestMicrophone: () async => true,
      createEngine: () {
        attempts++;
        final engine = JSObject() as web.SpeechRecognition;
        engine.setProperty('abort'.toJS, (() {}).toJS);
        engine.setProperty(
          'start'.toJS,
          (() {
            engine
                .getProperty<JSFunction>('onerror'.toJS)
                .callAsFunction(null, {'error': 'no-speech'}.jsify());
          }).toJS,
        );
        return engine;
      },
    );
    expect(
      await recognizer.listen(localeId: 'en-US').single,
      const RecognitionError(RecognitionErrorKind.noMatch, 'no-speech'),
    );
    expect(attempts, 2);
  });

  test('web listens past the native initial silence timeout', () async {
    final started = Completer<void>();
    final engine = JSObject() as web.SpeechRecognition;
    var stops = 0;
    engine.setProperty('abort'.toJS, (() {}).toJS);
    engine.setProperty(
      'start'.toJS,
      (() {
        engine
            .getProperty<JSFunction?>('onstart'.toJS)
            ?.callAsFunction(null, JSObject());
        started.complete();
      }).toJS,
    );
    engine.setProperty(
      'stop'.toJS,
      (() {
        stops++;
        engine
            .getProperty<JSFunction>('onend'.toJS)
            .callAsFunction(null, JSObject());
      }).toJS,
    );
    final recognizer = WebSpeechRecognizer(
      requestMicrophone: () async => true,
      createEngine: () => engine,
    );

    final result = recognizer
        .listen(
          localeId: 'en-US',
          silenceTimeout: const Duration(milliseconds: 10),
          maxDuration: const Duration(milliseconds: 160),
        )
        .single;
    await started.future;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(stops, 0);
    expect(await result, const RecognitionError(RecognitionErrorKind.noMatch));
    expect(stops, 1);
  });

  for (final (code, kind) in [
    ('not-allowed', RecognitionErrorKind.permissionDenied),
    ('language-not-supported', RecognitionErrorKind.languageUnsupported),
    ('audio-capture', RecognitionErrorKind.microphoneUnavailable),
    ('service-not-allowed', RecognitionErrorKind.serviceUnavailable),
    ('network', RecognitionErrorKind.network),
  ]) {
    test('browser error $code reaches the app as ${kind.name}', () async {
      final engine = JSObject() as web.SpeechRecognition;
      engine.setProperty('abort'.toJS, (() {}).toJS);
      engine.setProperty(
        'start'.toJS,
        (() {
          engine
              .getProperty<JSFunction>('onerror'.toJS)
              .callAsFunction(null, {'error': code}.jsify());
        }).toJS,
      );
      final recognizer = WebSpeechRecognizer(
        requestMicrophone: () async => true,
        createEngine: () => engine,
      );
      expect(
        await recognizer.listen(localeId: 'en-US').single,
        RecognitionError(kind, code),
      );
    });
  }
}
