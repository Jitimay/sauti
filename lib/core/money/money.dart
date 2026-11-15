import 'package:equatable/equatable.dart';

/// ISO-4217 currency with its minor-unit exponent.
///
/// BIF has no minor unit (exponent 0). Amounts are always stored as integer
/// minor units — floating point is never used for money.
final class Currency extends Equatable {
  const Currency._(this.code, this.exponent);

  final String code;
  final int exponent;

  static const bif = Currency._('BIF', 0);
  static const usd = Currency._('USD', 2);
  static const eur = Currency._('EUR', 2);

  static const _all = {'BIF': bif, 'USD': usd, 'EUR': eur};

  static Currency fromCode(String code) {
    final c = _all[code.toUpperCase()];
    if (c == null) throw ArgumentError.value(code, 'code', 'Unsupported currency');
    return c;
  }

  @override
  List<Object?> get props => [code];
}

/// Immutable money value in integer minor units.
final class Money extends Equatable implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  const Money.bif(int amount) : this(amount, Currency.bif);

  factory Money.zero(Currency currency) => Money(0, currency);

  final int minorUnits;
  final Currency currency;

  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money(-minorUnits, currency);

  Money abs() => Money(minorUnits.abs(), currency);

  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >=(Money other) => compareTo(other) >= 0;
  bool operator <=(Money other) => compareTo(other) <= 0;

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  /// Major-unit integer part (for display / speech only).
  int get wholeUnits => minorUnits ~/ _pow10(currency.exponent);

  static Money sum(Iterable<Money> values, Currency currency) =>
      values.fold(Money.zero(currency), (a, b) => a + b);

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Currency mismatch: ${currency.code} vs ${other.currency.code}');
    }
  }

  static int _pow10(int e) {
    var r = 1;
    for (var i = 0; i < e; i++) {
      r *= 10;
    }
    return r;
  }

  @override
  List<Object?> get props => [minorUnits, currency];

  @override
  String toString() => '${currency.code} $minorUnits(minor)';
}
