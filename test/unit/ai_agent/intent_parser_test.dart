import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/features/ai_agent/data/local/intent_parser.dart';
import 'package:sauti/features/banking/domain/entities/bank_transaction.dart';

void main() {
  const p = IntentParser();
  IntentType t(String s) => p.parse(s).type;

  test('balance in EN / FR / Kirundi', () {
    expect(t('How much money do I have?'), IntentType.balance);
    expect(t("What's my balance"), IntentType.balance);
    expect(t('Quel est mon solde ?'), IntentType.balance);
    expect(t('Amafaranga mfise ni angahe?'), IntentType.balance);
  });

  test('recent transactions with count', () {
    final i = p.parse('Show me the last five transactions');
    expect(i.type, IntentType.recentTransactions);
    expect(i.count, 5);
    expect(p.parse('Montre mes 3 dernières opérations').count, 3);
  });

  test('transfer extracts amount and recipient', () {
    for (final s in [
      'Send 20,000 BIF to Jean',
      'Send 20000 to Jean please',
      'Prepare a transfer of 20 000 BIF to Jean.',
      'Envoie 20 000 BIF à Jean',
      'Rungikira Jean 20000',
      'send 20k to Jean',
    ]) {
      final i = p.parse(s);
      expect(i.type, IntentType.transfer, reason: s);
      expect(i.amount, const Money.bif(20000), reason: s);
      expect(i.name, 'Jean', reason: s);
    }
  });

  test('transfer without amount or recipient', () {
    expect(p.parse('Send money to Jean').amount, isNull);
    expect(p.parse('Send 5000 BIF').name, isNull);
  });

  test('who sent me money', () {
    final i = p.parse('Who sent me 30,000 BIF?');
    expect(i.type, IntentType.searchIncoming);
    expect(i.amount, const Money.bif(30000));
    expect(p.parse('Who sent me money yesterday?').yesterday, isTrue);
    expect(t("Qui m'a envoyé de l'argent hier ?"), IntentType.searchIncoming);
  });

  test('spending with category and period', () {
    final i = p.parse('How much did I spend on transport this month?');
    expect(i.type, IntentType.spending);
    expect(i.category, TransactionCategory.transport);
    expect(p.parse('Combien ai-je dépensé le mois dernier ?').monthOffset, 1);
    expect(t('Nakoresheje angahe uku kwezi?'), IntentType.spending);
  });

  test('explain, notifications, received today', () {
    expect(t('Explain my last transaction'), IntentType.explainTransaction);
    expect(t('Why was I charged this amount?'), IntentType.explainTransaction);
    expect(t('Read my latest notifications'), IntentType.notifications);
    expect(t('Did I receive any money today?'), IntentType.receivedToday);
    expect(t('Tell me about my last payment'), isNot(IntentType.unknown));
  });

  test('small talk and unknown', () {
    expect(t('Bonjour'), IntentType.greeting);
    expect(t('Murakoze'), IntentType.thanks);
    expect(t('help'), IntentType.help);
    expect(t('What is the capital of France'), IntentType.unknown);
    expect(t(''), IntentType.unknown);
  });

  test('"last 5" is not mistaken for an amount', () {
    expect(IntentParser.extractAmount('last 5 transactions'), isNull);
  });
}
