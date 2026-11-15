import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/ai_agent/data/repositories/secure_conversation_repository.dart';
import 'package:sauti/features/ai_agent/domain/entities/agent_card.dart';
import 'package:sauti/features/ai_agent/domain/entities/chat_message.dart';
import 'package:sauti/features/ai_agent/presentation/bloc/agent_bloc.dart';
import 'package:sauti/features/authentication/data/repositories/demo_auth_repository.dart';
import 'package:sauti/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:sauti/features/voice/domain/speech_recognizer.dart';
import 'package:sauti/features/voice/presentation/bloc/voice_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  group('AgentBloc', () {
    late TestStack s;
    late InMemoryConversationRepository history;
    AgentBloc build() =>
        AgentBloc(orchestrator: s.orchestrator, history: history, clock: s.clock, newId: testId, drafts: s.drafts);
    setUp(() {
      s = TestStack();
      history = InMemoryConversationRepository();
    });

    blocTest<AgentBloc, AgentState>(
      'goes processing → executingTool → idle with a grounded reply',
      build: build,
      act: (b) => b.add(const AgentMessageSubmitted('How much money do I have?', language: AppLanguage.english)),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<AgentState>().having((x) => x.phase, 'phase', AgentPhase.processing),
        isA<AgentState>().having((x) => x.provider, 'provider', isNotNull),
        isA<AgentState>().having((x) => x.phase, 'phase', AgentPhase.executingTool),
        isA<AgentState>().having((x) => x.phase, 'phase', AgentPhase.processing),
        isA<AgentState>()
            .having((x) => x.phase, 'phase', AgentPhase.idle)
            .having((x) => x.messages.last.text, 'text', contains('250,000 BIF')),
      ],
      verify: (_) async => expect((await history.load()).length, 2),
    );

    blocTest<AgentBloc, AgentState>(
      'transfer request ends in awaitingConfirmation with a draft card',
      build: build,
      act: (b) => b.add(const AgentMessageSubmitted('Send 20000 BIF to Jean', language: AppLanguage.english)),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.phase, AgentPhase.awaitingConfirmation);
        expect(b.state.messages.last.cards.single, isA<TransferDraftCard>());
        expect(s.simulated.appliedTransfers, 0);
      },
    );

    blocTest<AgentBloc, AgentState>(
      'concurrent submissions: extra messages while busy are dropped',
      build: build,
      act: (b) {
        b
          ..add(const AgentMessageSubmitted('balance', language: AppLanguage.english))
          ..add(const AgentMessageSubmitted('balance again', language: AppLanguage.english));
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.messages.where((m) => m.role == ChatRole.user).length, 1),
    );

    blocTest<AgentBloc, AgentState>(
      'empty input is ignored',
      build: build,
      act: (b) => b.add(const AgentMessageSubmitted('   ', language: AppLanguage.english)),
      expect: () => <AgentState>[],
    );

    blocTest<AgentBloc, AgentState>(
      'clearing the conversation wipes history and drafts',
      build: build,
      act: (b) async {
        b.add(const AgentMessageSubmitted('Send 20000 BIF to Jean', language: AppLanguage.english));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        b.add(const AgentConversationCleared());
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) async {
        expect(b.state.messages, isEmpty);
        expect(s.drafts.latest, isNull);
        expect(await history.load(), isEmpty);
      },
    );
  });

  group('VoiceBloc', () {
    late FakeRecognizer stt;
    late FakeSynthesizer tts;
    setUp(() {
      stt = FakeRecognizer();
      tts = FakeSynthesizer();
    });

    blocTest<VoiceBloc, VoiceState>(
      'listening yields partial then a single recognized utterance',
      build: () => VoiceBloc(stt, tts),
      setUp: () => stt.nextUtterance = 'How much money do I have?',
      act: (b) => b.add(const VoiceListeningStarted(AppLanguage.english)),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.status, VoiceStatus.idle);
        expect(b.state.recognized?.text, 'How much money do I have?');
        expect(b.state.recognized?.seq, 1);
      },
    );

    blocTest<VoiceBloc, VoiceState>(
      'Kirundi voice unsupported → explicit error, no session opened',
      build: () => VoiceBloc(stt, tts),
      act: (b) => b.add(const VoiceListeningStarted(AppLanguage.kirundi)),
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.error, RecognitionErrorKind.languageUnsupported);
        expect(b.state.unsupportedLanguage, AppLanguage.kirundi);
        expect(stt.sessions, 0);
      },
    );

    blocTest<VoiceBloc, VoiceState>(
      'French override recognizes while UI stays Kirundi',
      build: () => VoiceBloc(stt, tts),
      setUp: () => stt.nextUtterance = 'Quel est mon solde',
      act: (b) => b.add(const VoiceListeningStarted(AppLanguage.kirundi, overrideLanguage: AppLanguage.french)),
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.recognized?.language, AppLanguage.french),
    );

    blocTest<VoiceBloc, VoiceState>(
      'microphone permission denied',
      build: () => VoiceBloc(FakeRecognizer(permission: false), tts),
      act: (b) => b.add(const VoiceListeningStarted(AppLanguage.english)),
      wait: const Duration(milliseconds: 20),
      verify: (b) => expect(b.state.error, RecognitionErrorKind.permissionDenied),
    );

    blocTest<VoiceBloc, VoiceState>(
      'silence → noMatch error',
      build: () => VoiceBloc(stt, tts),
      act: (b) => b.add(const VoiceListeningStarted(AppLanguage.english)),
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.error, RecognitionErrorKind.noMatch),
    );

    blocTest<VoiceBloc, VoiceState>(
      'speaks when a voice exists; reports when not',
      build: () => VoiceBloc(stt, tts),
      act: (b) async {
        b.add(const SpeechPlaybackStarted('Hello', language: AppLanguage.english, rate: 0.5));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const SpeechPlaybackStarted('Amahoro', language: AppLanguage.kirundi, rate: 0.5));
      },
      wait: const Duration(milliseconds: 30),
      verify: (b) {
        expect(tts.spoken, ['Hello']);
        expect(b.state.ttsUnavailableFor, AppLanguage.kirundi);
      },
    );
  });

  group('AuthBloc', () {
    late DemoAuthRepository repo;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = DemoAuthRepository(await SharedPreferences.getInstance());
    });

    blocTest<AuthBloc, AuthState>(
      'starts unauthenticated, signs in with demo credentials',
      build: () => AuthBloc(repo),
      act: (b) async {
        await Future<void>.delayed(Duration.zero);
        b.add(const SignInRequested(DemoAuthRepository.demoEmail, DemoAuthRepository.demoPassword));
      },
      wait: const Duration(milliseconds: 400),
      verify: (b) {
        expect(b.state.status, AuthenticationStatus.authenticated);
        expect(b.state.user?.isDemo, isTrue);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'wrong password → failure, still unauthenticated',
      build: () => AuthBloc(repo),
      act: (b) => b.add(const SignInRequested(DemoAuthRepository.demoEmail, 'nope')),
      wait: const Duration(milliseconds: 400),
      verify: (b) {
        expect(b.state.status, AuthenticationStatus.unauthenticated);
        expect(b.state.failure, FailureCode.authInvalidCredentials);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'registration validates password strength',
      build: () => AuthBloc(repo),
      act: (b) => b.add(const RegisterRequested('Ange', 'ange@example.com', 'short')),
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.failure, FailureCode.authWeakPassword),
    );

    blocTest<AuthBloc, AuthState>(
      'password reset reports success without revealing account existence',
      build: () => AuthBloc(repo),
      act: (b) => b.add(const PasswordResetRequested('unknown@example.com')),
      wait: const Duration(milliseconds: 50),
      verify: (b) => expect(b.state.resetEmailSent, isTrue),
    );

    blocTest<AuthBloc, AuthState>(
      'session persists across restarts and sign-out clears it',
      build: () => AuthBloc(repo),
      act: (b) async {
        b.add(const SignInRequested(DemoAuthRepository.demoEmail, DemoAuthRepository.demoPassword));
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final restored = DemoAuthRepository(await SharedPreferences.getInstance());
        expect(restored.currentUser, isNotNull);
        b.add(const SignOutRequested());
      },
      wait: const Duration(milliseconds: 100),
      verify: (b) async {
        expect(b.state.status, AuthenticationStatus.unauthenticated);
        expect(DemoAuthRepository(await SharedPreferences.getInstance()).currentUser, isNull);
      },
    );
  });
}
