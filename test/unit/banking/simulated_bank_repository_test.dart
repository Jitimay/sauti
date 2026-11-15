import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/error/result.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/features/banking/data/demo/demo_seed.dart';
import 'package:sauti/features/banking/domain/entities/data_freshness.dart';
import 'package:sauti/features/banking/domain/entities/transaction_query.dart';
import 'package:sauti/features/banking/domain/entities/transfer.dart';

import '../../helpers/fakes.dart';

TransferRequest req(String key, {int amount = 20000, String ben = 'demo-ben-jean', String acc = DemoSeed.mainAccountId}) =>
    TransferRequest(idempotencyKey: key, fromAccountId: acc, beneficiaryId: ben, amount: Money.bif(amount));

void main() {
  late TestStack s;
  setUp(() => s = TestStack());

  test('demo balance is 250,000 BIF and live', () async {
    final r = await s.simulated.getAccounts();
    final fresh = r.valueOrNull!;
    expect(fresh.source, DataSource.live);
    expect(fresh.data.first.availableBalance, const Money.bif(250000));
  });

  test('transfer debits once and returns verified receipt', () async {
    final r = await s.simulated.submitTransfer(req('k1'));
    final receipt = r.valueOrNull!;
    expect(receipt.newBalance, const Money.bif(230000));
    expect(receipt.beneficiaryName, 'Jean Ndayishimiye');
    final acc = (await s.simulated.getAccounts()).valueOrNull!.data.first;
    expect(acc.availableBalance, const Money.bif(230000));
    final latest = (await s.simulated.getTransactions(const TransactionQuery(limit: 1))).valueOrNull!.data.first;
    expect(latest.id, receipt.transactionId);
  });

  test('idempotency: sequential retry returns same receipt without double debit', () async {
    final a = await s.simulated.submitTransfer(req('k1'));
    final b = await s.simulated.submitTransfer(req('k1'));
    expect(b.valueOrNull, a.valueOrNull);
    expect(s.simulated.appliedTransfers, 1);
  });

  test('idempotency: concurrent duplicates execute once', () async {
    final results = await Future.wait([for (var i = 0; i < 5; i++) s.simulated.submitTransfer(req('same'))]);
    expect(results.every((r) => r.isOk), isTrue);
    expect(s.simulated.appliedTransfers, 1);
  });

  test('idempotency key reuse with a different amount is rejected', () async {
    await s.simulated.submitTransfer(req('k1'));
    final r = await s.simulated.submitTransfer(req('k1', amount: 30000));
    expect(r.failureOrNull?.code, FailureCode.duplicateRequest);
  });

  test('server-side validation: insufficient funds, limits, bad amounts, unknown beneficiary, foreign account', () async {
    expect((await s.simulated.submitTransfer(req('a', amount: 300000))).failureOrNull?.code, FailureCode.insufficientFunds);
    expect((await s.simulated.submitTransfer(req('b', amount: 0))).failureOrNull?.code, FailureCode.invalidAmount);
    expect((await s.simulated.submitTransfer(req('c', amount: 499))).failureOrNull?.code, FailureCode.invalidAmount);
    expect((await s.simulated.submitTransfer(req('d', amount: 3000000))).failureOrNull?.code, FailureCode.limitExceeded);
    expect((await s.simulated.submitTransfer(req('e', ben: 'attacker'))).failureOrNull?.code, FailureCode.beneficiaryNotFound);
    expect((await s.simulated.submitTransfer(req('f', acc: 'someone-else'))).failureOrNull?.code, FailureCode.unauthorized);
    expect(s.simulated.appliedTransfers, 0);
  });

  test('offline: every call fails with NetworkFailure, nothing applied', () async {
    s.network.set(false);
    expect((await s.simulated.getAccounts()).failureOrNull, isA<NetworkFailure>());
    expect((await s.simulated.submitTransfer(req('k'))).failureOrNull, isA<NetworkFailure>());
    expect(s.simulated.appliedTransfers, 0);
  });

  test('caching decorator serves explicitly-marked cached data offline', () async {
    await s.bank.getAccounts();
    await s.bank.getTransactions(const TransactionQuery(limit: 50));
    s.network.set(false);
    final acc = await s.bank.getAccounts();
    expect(acc.valueOrNull!.isCached, isTrue);
    expect(acc.valueOrNull!.asOf, testNow);
    final txs = await s.bank.getTransactions(const TransactionQuery(text: 'regideso', limit: 10));
    expect(txs.valueOrNull!.isCached, isTrue);
    expect(txs.valueOrNull!.data, isNotEmpty);
    expect(txs.valueOrNull!.data.every((t) => t.counterparty == 'REGIDESO'), isTrue);
  });

  test('caching decorator without snapshot propagates NetworkFailure', () async {
    s.network.set(false);
    expect((await s.bank.getAccounts()).failureOrNull, isA<NetworkFailure>());
  });

  test('caching decorator never caches transfers', () async {
    await s.bank.getAccounts();
    s.network.set(false);
    final r = await s.bank.submitTransfer(req('x'));
    expect(r, isA<Err<TransferReceipt>>());
  });
}
