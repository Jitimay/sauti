import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/features/banking/domain/entities/transfer.dart';
import 'package:sauti/features/transfers/domain/entities/transfer_authorization.dart';
import 'package:sauti/features/transfers/domain/entities/transfer_stage.dart';
import 'package:sauti/features/transfers/domain/usecases/prepare_transfer.dart';

import '../../helpers/fakes.dart';

void main() {
  group('TransferStateMachine', () {
    const m = TransferStateMachine();

    test('happy path is legal', () {
      var s = TransferStage.idle;
      for (final next in [
        TransferStage.drafting,
        TransferStage.awaitingAuthentication,
        TransferStage.authenticating,
        TransferStage.awaitingConfirmation,
        TransferStage.submitting,
        TransferStage.completed,
      ]) {
        s = m.transition(s, next);
      }
      expect(s, TransferStage.completed);
    });

    test('cannot skip authentication or confirmation', () {
      expect(m.canTransition(TransferStage.awaitingAuthentication, TransferStage.submitting), isFalse);
      expect(m.canTransition(TransferStage.drafting, TransferStage.submitting), isFalse);
      expect(m.canTransition(TransferStage.authenticating, TransferStage.submitting), isFalse);
      expect(() => m.transition(TransferStage.idle, TransferStage.completed), throwsStateError);
    });

    test('completed is terminal; submitting cannot be cancelled', () {
      expect(m.canTransition(TransferStage.completed, TransferStage.cancelled), isFalse);
      expect(m.canTransition(TransferStage.submitting, TransferStage.cancelled), isFalse);
    });
  });

  group('PrepareTransfer', () {
    late TestStack s;
    setUp(() => s = TestStack());

    Future<TransferDraft> draft({int amount = 20000, String name = 'Jean'}) async {
      final r = await s.prepareTransfer(beneficiaryName: name, amount: Money.bif(amount));
      return (r.valueOrNull! as TransferPrepared).draft;
    }

    test('creates a draft without moving money', () async {
      final d = await draft();
      expect(d.beneficiary.name, 'Jean Ndayishimiye');
      expect(d.balanceAfter, const Money.bif(230000));
      expect(s.simulated.appliedTransfers, 0);
    });

    test('rejects unknown recipient, invalid amount, insufficient funds', () async {
      expect((await s.prepareTransfer(beneficiaryName: 'Pierre', amount: const Money.bif(1000))).failureOrNull?.code,
          FailureCode.beneficiaryNotFound);
      expect((await s.prepareTransfer(beneficiaryName: 'Jean', amount: const Money.bif(-5))).failureOrNull?.code,
          FailureCode.invalidAmount);
      expect((await s.prepareTransfer(beneficiaryName: 'Jean', amount: const Money.bif(250001))).failureOrNull?.code,
          FailureCode.insufficientFunds);
    });

    test('refuses offline (never against cached balances)', () async {
      await s.bank.getAccounts(); // populate cache
      s.network.set(false);
      final r = await s.prepareTransfer(beneficiaryName: 'Jean', amount: const Money.bif(1000));
      expect(r.failureOrNull?.code, FailureCode.offlineNotAllowed);
    });

    test('SubmitTransfer requires a valid authorization bound to the draft', () async {
      final d = await draft();
      expect((await s.submitTransfer(d, null)).failureOrNull?.code, FailureCode.authExpired);

      final wrongDraft = TransferAuthorization(
          draftIdempotencyKey: 'other', method: AuthMethod.accountPassword, grantedAt: testNow, validFor: const Duration(minutes: 2));
      expect((await s.submitTransfer(d, wrongDraft)).failureOrNull?.code, FailureCode.authExpired);

      final auth = TransferAuthorization(
          draftIdempotencyKey: d.idempotencyKey,
          method: AuthMethod.accountPassword,
          grantedAt: testNow,
          validFor: const Duration(minutes: 2));
      s.clock.advance(const Duration(minutes: 3));
      expect((await s.submitTransfer(d, auth)).failureOrNull?.code, FailureCode.authExpired, reason: 'expired');
      expect(s.simulated.appliedTransfers, 0);
    });

    test('SubmitTransfer succeeds with fresh authorization and is idempotent', () async {
      final d = await draft();
      final auth = TransferAuthorization(
          draftIdempotencyKey: d.idempotencyKey,
          method: AuthMethod.deviceBiometricOrPasscode,
          grantedAt: testNow,
          validFor: const Duration(minutes: 2));
      final r1 = await s.submitTransfer(d, auth);
      final r2 = await s.submitTransfer(d, auth);
      expect(r1.valueOrNull!.newBalance, const Money.bif(230000));
      expect(r2.valueOrNull, r1.valueOrNull);
      expect(s.simulated.appliedTransfers, 1);
    });

    test('SubmitTransfer offline never queues', () async {
      final d = await draft();
      s.network.set(false);
      final auth = TransferAuthorization(
          draftIdempotencyKey: d.idempotencyKey, method: AuthMethod.accountPassword, grantedAt: testNow, validFor: const Duration(minutes: 2));
      expect((await s.submitTransfer(d, auth)).failureOrNull?.code, FailureCode.offlineNotAllowed);
      s.network.set(true);
      expect(s.simulated.appliedTransfers, 0);
    });
  });
}
