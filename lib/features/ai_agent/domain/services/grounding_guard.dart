import '../entities/tool_call.dart';

/// Detects money figures in model text that are not backed by tool output
/// or the user's own words — a guard against hallucinated balances/amounts.
final class GroundingGuard {
  const GroundingGuard();

  static final _amount = RegExp(
    r'(\d{1,3}(?:[ ,.  ]\d{3})+|\d{3,})\s*(?:BIF|FBU|Fbu|francs?|amafaranga)',
    caseSensitive: false,
  );
  static final _amountAfter = RegExp(
    r'(?:BIF|FBU|amafaranga)\s*(\d{1,3}(?:[ ,.  ]\d{3})+|\d{3,})',
    caseSensitive: false,
  );

  Set<int> _mentioned(String text) => {
        for (final m in [..._amount.allMatches(text), ..._amountAfter.allMatches(text)])
          int.parse(m.group(1)!.replaceAll(RegExp(r'[ ,.  ]'), '')),
      };

  static void _collect(Object? v, Set<int> out) {
    switch (v) {
      case final int i:
        out.add(i);
      case final double d when d == d.truncateToDouble():
        out.add(d.toInt());
      case final Map<Object?, Object?> m:
        for (final e in m.values) {
          _collect(e, out);
        }
      case final List<Object?> l:
        for (final e in l) {
          _collect(e, out);
        }
    }
  }

  /// Returns the unsupported amounts (empty = grounded).
  Set<int> ungroundedAmounts(String modelText, {required String userText, required List<ToolExecutionRecord> records}) {
    final mentioned = _mentioned(modelText);
    if (mentioned.isEmpty) return const {};
    final known = <int>{..._mentioned(userText)};
    for (final m in RegExp(r'\d[\d ,.]*\d|\d').allMatches(userText)) {
      final n = int.tryParse(m.group(0)!.replaceAll(RegExp(r'[ ,.]'), ''));
      if (n != null) known.add(n);
    }
    for (final r in records.where((r) => r.ok)) {
      _collect(r.modelPayload, known);
    }
    // Allow simple sums/differences of two known figures (e.g. "you spent 45,000 in total").
    final base = known.toList();
    for (var i = 0; i < base.length && i < 60; i++) {
      for (var j = i; j < base.length && j < 60; j++) {
        known
          ..add(base[i] + base[j])
          ..add((base[i] - base[j]).abs());
      }
    }
    return mentioned.difference(known);
  }
}
