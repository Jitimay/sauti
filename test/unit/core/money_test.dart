import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/core/money/money_formatter.dart';
import 'package:sauti/core/money/money_parser.dart';

void main() {
  group('Money', () {
    test('adds and subtracts in integer minor units', () {
      expect(const Money.bif(250000) - const Money.bif(20000), const Money.bif(230000));
      expect(Money.sum([const Money.bif(1), const Money.bif(2)], Currency.bif), const Money.bif(3));
    });

    test('rejects mixed currencies', () {
      expect(() => const Money.bif(1) + const Money(1, Currency.usd), throwsArgumentError);
    });

    test('compares', () {
      expect(const Money.bif(10) > const Money.bif(9), isTrue);
      expect(const Money.bif(10) <= const Money.bif(10), isTrue);
    });

    test('USD whole units truncate minor units', () {
      expect(const Money(1999, Currency.usd).wholeUnits, 19);
    });
  });

  group('MoneyParser', () {
    test('parses BIF separators as thousands', () {
      for (final s in ['20000', '20,000', '20 000', '20.000', '20000 BIF', '20 000 FBu', '20k']) {
        expect(MoneyParser.parse(s), const Money.bif(20000), reason: s);
      }
    });

    test('rejects garbage and negative', () {
      expect(MoneyParser.parse('abc'), isNull);
      expect(MoneyParser.parse('-500'), isNull);
      expect(MoneyParser.parse(''), isNull);
    });

    test('parses two-decimal currency without floats', () {
      expect(MoneyParser.parse('12.5', currency: Currency.usd), const Money(1250, Currency.usd));
      expect(MoneyParser.parse('12,05', currency: Currency.usd), const Money(1205, Currency.usd));
    });
  });

  group('MoneyFormatter', () {
    test('formats per locale', () {
      expect(MoneyFormatter.format(const Money.bif(250000)), '250,000 BIF');
      expect(MoneyFormatter.format(const Money.bif(250000), locale: 'fr'), contains('250'));
      expect(MoneyFormatter.format(const Money.bif(250000), locale: 'fr'), endsWith(' BIF'));
      expect(MoneyFormatter.format(const Money.bif(-500)), '−500 BIF');
      expect(MoneyFormatter.format(const Money.bif(500), signed: true), '+500 BIF');
    });

    test('Kirundi uses French grouping', () {
      expect(MoneyFormatter.format(const Money.bif(1000), locale: 'rn'),
          MoneyFormatter.format(const Money.bif(1000), locale: 'fr'));
    });
  });
}
