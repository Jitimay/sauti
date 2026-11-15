import 'money.dart';

/// Parses user- or model-supplied amounts into [Money] without floating point.
///
/// Accepts "20000", "20,000", "20 000", "20.000" (as thousands separators for
/// zero-exponent currencies), "20k", and "20000 BIF". Returns null on anything
/// ambiguous rather than guessing.
abstract final class MoneyParser {
  static final _thousandsK = RegExp(r'^(\d+)\s*k$', caseSensitive: false);

  static Money? parse(String raw, {Currency currency = Currency.bif}) {
    var s = raw.trim().toUpperCase();
    s = s.replaceAll(currency.code, '').replaceAll('FBU', '').replaceAll('FRANCS', '').trim();
    if (s.isEmpty) return null;

    final k = _thousandsK.firstMatch(s);
    if (k != null) {
      final v = int.tryParse(k.group(1)!);
      return v == null ? null : Money(v * 1000 * _scale(currency), currency);
    }

    if (currency.exponent == 0) {
      // No minor units: every separator is a thousands separator.
      final digits = s.replaceAll(RegExp(r'[\s,.  ]'), '');
      if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
      final v = int.tryParse(digits);
      return v == null ? null : Money(v, currency);
    }

    // Two-decimal currencies: accept "12.50" or "12,50" with optional thousands spaces.
    final cleaned = s.replaceAll(RegExp(r'[\s  ]'), '');
    final m = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$').firstMatch(cleaned);
    if (m == null) return null;
    final whole = int.parse(m.group(1)!);
    final frac = (m.group(2) ?? '').padRight(currency.exponent, '0');
    return Money(whole * _scale(currency) + (frac.isEmpty ? 0 : int.parse(frac)), currency);
  }

  static int _scale(Currency c) {
    var r = 1;
    for (var i = 0; i < c.exponent; i++) {
      r *= 10;
    }
    return r;
  }
}
