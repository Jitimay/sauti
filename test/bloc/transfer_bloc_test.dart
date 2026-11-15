import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/features/banking/domain/usecases/banking_usecases.dart';
import 'package:sauti/features/transfers/domain/entities/transfer_stage.dart';
import 'package:sauti/features/transfers/presentation/bloc/transfer_bloc.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  late TestStack s;
  late FakeAuthenticator auth;

  TransferBloc build() => TransferBloc(
        prepare: s.prepareTransfer,
        submit: s.submitTransfer,
        beneficiaries: ListBeneficiaries(s.bank),
        authenticator: auth,
        clock: s.clock,
      );

  setUp(() {
    s = TestStack();
    auth = FakeAuthenticator();
  });

  const draftEvent = TransferDraftRequested(beneficiaryId: 'demo-ben-jean', amount: Money.bif(20000));

  blocTest<TransferBloc, TransferState>(
    'initial state is idle with no receipt',
    build: build,
    verify: (b) {
      expect(b.state.stage, TransferStage.idle);
      expect(b.state.receipt, isNull);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'Scenario 6: draft → authenticate → explicit send → verified receipt',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferSubmitted());
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.completed);
      expect(b.state.receipt!.newBalance, const Money.bif(230000));
      expect(s.simulated.appliedTransfers, 1);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'authentication alone never submits',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.awaitingConfirmation);
      expect(s.simulated.appliedTransfers, 0);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'submit without authentication is ignored',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferSubmitted());
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.awaitingAuthentication);
      expect(s.simulated.appliedTransfers, 0);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'duplicate submissions (rapid taps) execute exactly once',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 5; i++) {
        b.add(const TransferSubmitted());
      }
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.completed);
      expect(s.simulated.appliedTransfers, 1);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'Scenario 5: cancellation sends nothing',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferCancelled());
      b.add(const TransferSubmitted());
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.cancelled);
      expect(s.simulated.appliedTransfers, 0);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'expired authorization forces re-authentication',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
      await Future<void>.delayed(Duration.zero);
      s.clock.advance(const Duration(minutes: 5));
      b.add(const TransferSubmitted());
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.awaitingAuthentication);
      expect(b.state.failure?.code, FailureCode.authExpired);
      expect(s.simulated.appliedTransfers, 0);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'declined device auth returns to awaitingAuthentication with failure',
    build: () {
      auth.approve = false;
      return build();
    },
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.awaitingAuthentication);
      expect(b.state.failure, isA<AuthFailure>());
    },
  );

  blocTest<TransferBloc, TransferState>(
    'password fallback: wrong password rejected, right password verifies',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferPasswordSubmitted('wrong'));
      await Future<void>.delayed(Duration.zero);
      expect(b.state.stage, TransferStage.awaitingAuthentication);
      b.add(const TransferPasswordSubmitted('Sauti2026'));
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) => expect(b.state.stage, TransferStage.awaitingConfirmation),
  );

  blocTest<TransferBloc, TransferState>(
    'insufficient funds fails at draft time',
    build: build,
    act: (b) => b.add(const TransferDraftRequested(beneficiaryId: 'demo-ben-jean', amount: Money.bif(999999))),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.failed);
      expect(b.state.failure?.code, FailureCode.insufficientFunds);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'connectivity lost before send → failure, never queued',
    build: build,
    act: (b) async {
      b.add(draftEvent);
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferAuthenticationRequested('reason'));
      await Future<void>.delayed(Duration.zero);
      s.network.set(false);
      b.add(const TransferSubmitted());
    },
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.stage, TransferStage.failed);
      expect(b.state.failure?.code, FailureCode.offlineNotAllowed);
      expect(b.state.receipt, isNull);
      s.network.set(true);
      expect(s.simulated.appliedTransfers, 0);
    },
  );
}
