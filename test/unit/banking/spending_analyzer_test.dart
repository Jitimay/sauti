import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/features/banking/data/demo/demo_seed.dart';
import 'package:sauti/features/banking/domain/entities/bank_transaction.dart';
import 'package:sauti/features/banking/domain/services/spending_analyzer.dart';
import 'package:sauti/features/banking/domain/services/transaction_explainer.dart';

import '../../helpers/fakes.dart';

void main() {
  final txs = DemoSeed(testNow).transactions();
  const analyzer = SpendingAnalyzer();

  test('monthly totals match the demo ledger exactly', () {
    final s = analyzer.monthly(txs, month: testNow);
    // 15,000 transport + 30,000 groceries + 10,000 utilities + 5,000 airtime
    expect(s.totalSpent, const Money.bif(60000));
    expect(s.totalReceived, const Money.bif(80000));
    expect(s.topCategory!.category, TransactionCategory.groceries);
    expect(s.net, const Money.bif(20000));
  });

  test('compares with previous month', () {
    final s = analyzer.monthly(txs, month: testNow);
    // Previous month outgoing: 12,000 + 42,000 + 9,500 + 25,000 = 88,500
    expect(s.previousPeriodSpent, const Money.bif(88500));
    expect(s.changePercent, -32);
  });

  test('category filter', () {
    final s = analyzer.monthly(txs, month: testNow, onlyCategory: TransactionCategory.transport);
    expect(s.totalSpent, const Money.bif(15000));
  });

  test('empty data yields zero, null change', () {
    final s = analyzer.monthly(const [], month: testNow);
    expect(s.totalSpent.isZero, isTrue);
    expect(s.changePercent, isNull);
    expect(s.topCategory, isNull);
  });

  test('explainer detects recurring payments and fee', () {
    final regideso = txs.firstWhere((t) => t.id == 't104');
    final e = const TransactionExplainer().explain(regideso, txs);
    expect(e.isRecurring, isTrue);
    expect(e.fee, const Money.bif(200));
    expect(e.categoryShareOfMonthPercent, 100);
  });
}
