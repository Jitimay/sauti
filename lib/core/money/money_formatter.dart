import 'package:intl/intl.dart';

import 'money.dart';

/// Locale-aware money formatting for display and speech.
abstract final class MoneyFormatter {
  /// e.g. "250,000 BIF" (en) / "250 000 BIF" (fr, rn).
  static String format(Money money, {String locale = 'en', bool signed = false}) {
    final fmt = NumberFormat.decimalPatternDigits(
      locale: _intlLocale(locale),
      decimalDigits: money.currency.exponent,
    );
    final value = money.currency.exponent == 0
        ? money.minorUnits.abs()
        : money.minorUnits.abs() / _scale(money.currency);
    final sign = money.isNegative ? '−' : (signed && money.isPositive ? '+' : '');
    return '$sign${fmt.format(value)} ${money.currency.code}';
  }

  /// Speech-friendly: avoids symbols that TTS engines read badly.
  static String spoken(Money money, {String locale = 'en'}) {
    final fmt = NumberFormat.decimalPattern(_intlLocale(locale));
    final name = switch (money.currency.code) {
      'BIF' => locale == 'en' ? 'Burundian francs' : 'francs burundais',
      _ => money.currency.code,
    };
    final neg = money.isNegative ? (locale == 'en' ? 'minus ' : 'moins ') : '';
    return '$neg${fmt.format(money.wholeUnits.abs())} $name';
  }

  // intl has no Kirundi symbols; French grouping is the regional convention.
  static String _intlLocale(String l) => l == 'rn' ? 'fr' : l;

  static int _scale(Currency c) {
    var r = 1;
    for (var i = 0; i < c.exponent; i++) {
      r *= 10;
    }
    return r;
  }
}
