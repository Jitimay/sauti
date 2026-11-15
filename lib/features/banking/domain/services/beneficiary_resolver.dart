import 'package:equatable/equatable.dart';

import '../entities/beneficiary.dart';

sealed class BeneficiaryResolution extends Equatable {
  const BeneficiaryResolution();
  @override
  List<Object?> get props => [];
}

final class BeneficiaryResolved extends BeneficiaryResolution {
  const BeneficiaryResolved(this.beneficiary);
  final Beneficiary beneficiary;
  @override
  List<Object?> get props => [beneficiary];
}

final class BeneficiaryAmbiguous extends BeneficiaryResolution {
  const BeneficiaryAmbiguous(this.candidates);
  final List<Beneficiary> candidates;
  @override
  List<Object?> get props => [candidates];
}

final class BeneficiaryUnknown extends BeneficiaryResolution {
  const BeneficiaryUnknown(this.spokenName);
  final String spokenName;
  @override
  List<Object?> get props => [spokenName];
}

/// Resolves a spoken/typed name to exactly one *saved* beneficiary.
///
/// Never creates or guesses a recipient: unknown names fail, and several
/// plausible matches are returned as ambiguous for the user to choose.
final class BeneficiaryResolver {
  const BeneficiaryResolver();

  BeneficiaryResolution resolve(String spokenName, List<Beneficiary> saved) {
    final q = normalize(spokenName);
    if (q.isEmpty) return BeneficiaryUnknown(spokenName);

    final exact = saved.where((b) => _names(b).any((n) => n == q)).toList();
    if (exact.length == 1) return BeneficiaryResolved(exact.single);
    if (exact.length > 1) return BeneficiaryAmbiguous(exact);

    // Token match: "jean" matches "Jean Ndayishimiye" but also "Jean-Claude …".
    final partial = saved.where((b) {
      return _names(b).any((n) => n.split(' ').contains(q) || n.startsWith('$q '));
    }).toList();
    if (partial.length == 1) return BeneficiaryResolved(partial.single);
    if (partial.length > 1) return BeneficiaryAmbiguous(partial);

    // Small typo tolerance on whole names only (distance ≤ 1 for ≥ 4 chars).
    final fuzzy = saved.where((b) {
      return _names(b).any((n) => n.split(' ').any((tok) => tok.length >= 4 && _lev(tok, q) <= 1));
    }).toList();
    if (fuzzy.length == 1) return BeneficiaryAmbiguous(fuzzy); // always confirm typo matches
    if (fuzzy.length > 1) return BeneficiaryAmbiguous(fuzzy);
    return BeneficiaryUnknown(spokenName);
  }

  Iterable<String> _names(Beneficiary b) => [b.name, ...b.aliases].map(normalize);

  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r"[^a-z0-9' ]"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static int _lev(String a, String b) {
    if (a == b) return 0;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final cur = <int>[i + 1];
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        cur.add([cur[j] + 1, prev[j + 1] + 1, prev[j] + cost].reduce((x, y) => x < y ? x : y));
      }
      prev = cur;
    }
    return prev.last;
  }
}
