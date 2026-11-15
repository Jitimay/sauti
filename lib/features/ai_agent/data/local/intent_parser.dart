import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../banking/domain/entities/bank_transaction.dart';

enum IntentType {
  balance,
  recentTransactions,
  searchIncoming,
  searchCounterparty,
  spending,
  explainTransaction,
  notifications,
  receivedToday,
  beneficiaries,
  transfer,
  help,
  greeting,
  thanks,
  unknown,
}

final class ParsedIntent extends Equatable {
  const ParsedIntent(
    this.type, {
    this.amount,
    this.name,
    this.count,
    this.category,
    this.monthOffset = 0,
    this.yesterday = false,
    this.transactionId,
  });

  final IntentType type;
  final Money? amount;
  final String? name;
  final int? count;
  final TransactionCategory? category;
  final int monthOffset;
  final bool yesterday;

  /// Explicit reference like "#t104" (from the transaction details screen).
  final String? transactionId;

  @override
  List<Object?> get props => [type, amount, name, count, category, monthOffset, yesterday, transactionId];
}

/// Deterministic, offline, multilingual (EN / FR / Kirundi) intent parser.
///
/// Keyword-based by design: predictable, auditable and testable. It is not
/// an LLM and does not pretend to understand arbitrary phrasing; unknown
/// requests get an honest "I didn't understand" with suggestions.
/// Kirundi vocabulary is a first draft pending native-speaker review.
final class IntentParser {
  const IntentParser();

  static String _norm(String s) => ' ${s.toLowerCase().replaceAll(RegExp('[éèêë]'), 'e').replaceAll(RegExp('[àâä]'), 'a').replaceAll(RegExp('[îï]'), 'i').replaceAll(RegExp('[ôö]'), 'o').replaceAll(RegExp('[ùûü]'), 'u').replaceAll('ç', 'c').replaceAll('’', "'").replaceAll(RegExp(r'[?!.;:]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()} ';

  static bool _any(String t, List<String> keys) => keys.any(t.contains);

  static const _transferVerbs = [
    ' send ', ' transfer ', ' pay ', ' envoie ', ' envoyer ', ' envoyez ', ' transfere ', ' transferer ', ' virement ',
    ' payer ', ' paie ', ' rungika ', ' rungikira ', ' rungikire ', ' ndungikira ', ' ohereza ', ' riha ',
  ];
  static const _explain = [
    ' explain ', ' why ', ' expliqu', ' pourquoi ', ' sobanur', ' kubera iki ', ' tell me about ', ' parle-moi de ',
    ' last payment ', ' dernier paiement ', ' derniere operation ', ' ivyakozwe vya nyuma ',
  ];
  static const _spending = [
    ' spend ', ' spent ', ' spending ', ' depense', ' nakoresheje ', ' ndakoresheje ', ' nakoresheje', ' vyakoreshejwe ',
    ' ivyo nakoresheje ', ' dakoresha ',
  ];
  static const _notifications = [
    ' notification', ' alert', ' message', ' ubutumwa ', ' amatangazo ', ' notifs ',
  ];
  static const _received = [' receive', ' received ', ' recu ', ' recu', ' nakiriye ', ' narungikiwe ', ' nahawe '];
  static const _today = [' today ', " aujourd'hui ", ' aujourdhui ', ' uyu munsi ', ' none '];
  static const _whoSent = [
    ' who sent ', ' who paid ', " qui m'a ", ' qui ma ', ' ninde yandungikiye ', ' ninde yampaye ', ' ninde yarungitse ',
  ];
  // Bare "ejo" means both yesterday and tomorrow in Kirundi, so only the
  // unambiguous "ejo hashize" counts.
  static const _yesterday = [' yesterday ', ' hier ', ' ejo hashize '];

  /// "ma paie" (my salary) is a noun, not the verb "paie" (pay).
  static final _salaryNoun = RegExp(r' (?:ma|ta|sa|la|une|votre|notre|leur) paie ');
  static const _transactions = [
    ' transaction', ' history ', ' historique ', ' operation', ' mouvements ', ' ivyakozwe ', ' amahererezo ', ' statement ',
    ' releve ',
  ];
  static const _balance = [
    ' balance', ' how much money ', ' how much do i have ', ' how much have i got ', ' solde ', ' combien ai-je ',
    " combien j'ai ", ' combien ai je ', " qu'est-ce qui me reste ", ' angahe ', ' mfise ', ' nsigaranye ',
    ' amafaranga yanje ', ' konti yanje ',
  ];
  static const _beneficiaries = [' beneficiar', ' recipient', ' contacts ', ' destinataire', ' abo nshobora kurungikira '];
  static const _help = [' help ', ' aide ', ' what can you ', ' que peux-tu ', ' que sais-tu ', ' imfashanyo ', ' mfasha '];
  static const _greeting = [
    ' hello ', ' hi ', ' hey ', ' bonjour ', ' salut ', ' bonsoir ', ' amahoro ', ' bwakeye ', ' mwaramutse ', ' mwiriwe ',
  ];
  static const _thanks = [' thank', ' merci ', ' murakoze ', ' urakoze '];
  static const _lastMonth = [' last month ', ' mois dernier ', ' mois passe ', ' ukwezi guheze ', ' ukwezi gushize '];

  static const Map<TransactionCategory, List<String>> _categories = {
    TransactionCategory.transport: [' transport', ' taxi', ' moto', ' bus ', ' itike ', ' ingendo '],
    TransactionCategory.groceries: [' groceries', ' grocery', ' food ', ' courses ', ' nourriture', ' marche ', ' ibifungurwa ', ' ivyokurya '],
    TransactionCategory.utilities: [' utilit', ' electricit', ' water ', ' eau ', ' regideso', ' umuyagankuba ', ' amazi '],
    TransactionCategory.airtime: [' airtime', ' credit telephone', ' unites ', ' forfait', ' ama unite '],
    TransactionCategory.health: [' health', ' sante ', ' hopital', ' clinic', ' clinique', ' amagara ', ' ivuriro '],
    TransactionCategory.education: [' school', ' ecole', ' education', ' minerval', ' amashure '],
    TransactionCategory.fees: [' fee', ' frais ', ' charge', ' amafaranga y\'ivyakozwe '],
  };

  static const Map<String, int> _numberWords = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'un': 1, 'une': 1, 'deux': 2, 'trois': 3, 'quatre': 4, 'cinq': 5, 'sept': 7, 'huit': 8, 'neuf': 9, 'dix': 10,
    'rimwe': 1, 'kabiri': 2, 'gatatu': 3, 'kane': 4, 'gatanu': 5, 'gatandatu': 6, 'indwi': 7, 'umunani': 8,
    'icenda': 9, 'cumi': 10, 'tatu': 3, 'tanu': 5,
  };

  ParsedIntent parse(String input) {
    final t = _norm(input).replaceAll(_salaryNoun, ' salaire ');
    if (t.trim().isEmpty) return const ParsedIntent(IntentType.unknown);

    final amount = extractAmount(input);
    final category = _category(t);
    final monthOffset = _any(t, _lastMonth) ? 1 : 0;

    if (_any(t, _transferVerbs) && !_any(t, _whoSent) && !_any(t, _received)) {
      return ParsedIntent(IntentType.transfer, amount: amount, name: extractRecipient(input));
    }
    if (_any(t, _explain)) {
      final ref = RegExp(r'#([A-Za-z0-9_-]{2,64})').firstMatch(input)?.group(1);
      return ParsedIntent(IntentType.explainTransaction, transactionId: ref);
    }
    if (_any(t, _whoSent)) {
      return ParsedIntent(IntentType.searchIncoming, amount: amount, yesterday: _any(t, _yesterday));
    }
    if (_any(t, _received) && _any(t, _today)) return const ParsedIntent(IntentType.receivedToday);
    if (_any(t, _spending) || (category != null && !_any(t, _transactions))) {
      return ParsedIntent(IntentType.spending, category: category, monthOffset: monthOffset);
    }
    if (_any(t, _notifications)) return ParsedIntent(IntentType.notifications, count: _count(t));
    if (_any(t, _received)) {
      return ParsedIntent(IntentType.searchIncoming, amount: amount, yesterday: _any(t, _yesterday));
    }
    if (_any(t, _transactions)) return ParsedIntent(IntentType.recentTransactions, count: _count(t));
    if (_any(t, _balance) || (t.contains(' amafaranga ') && t.contains(' angahe '))) {
      return const ParsedIntent(IntentType.balance);
    }
    if (_any(t, _beneficiaries)) return const ParsedIntent(IntentType.beneficiaries);
    if (_any(t, _help)) return const ParsedIntent(IntentType.help);
    if (_any(t, _thanks)) return const ParsedIntent(IntentType.thanks);
    if (_any(t, _greeting)) return const ParsedIntent(IntentType.greeting);
    return const ParsedIntent(IntentType.unknown);
  }

  TransactionCategory? _category(String t) {
    for (final e in _categories.entries) {
      if (_any(t, e.value)) return e.key;
    }
    return null;
  }

  int? _count(String t) {
    final m = RegExp(r' (?:last|dernier(?:e?s)?|derniere?s?|les) (\d{1,2}) ').firstMatch(t) ??
        RegExp(r' (\d{1,2}) (?:last |dernier|derniere|transaction|operation|notification)').firstMatch(t);
    if (m != null) return int.parse(m.group(1)!).clamp(1, 20);
    for (final e in _numberWords.entries) {
      if (t.contains(' ${e.key} ')) return e.value;
    }
    return null;
  }

  /// Extracts an amount in BIF. Handles "20000", "20,000", "20 000", "20.000",
  /// "20k", "20 mille", "20 thousand", "ibihumbi 20". Returns null if none.
  static Money? extractAmount(String text) {
    final t = text.toLowerCase();
    final ibihumbi = RegExp(r'ibihumbi\s+(\d{1,6})').firstMatch(t);
    if (ibihumbi != null) return Money.bif(int.parse(ibihumbi.group(1)!) * 1000);
    final k = RegExp(r'(?<![\d,.])(\d{1,6})\s*(?:k|mille|thousand)\b').firstMatch(t);
    if (k != null) return Money.bif(int.parse(k.group(1)!) * 1000);
    // Choose the largest number mentioned (so "last 5" is not read as an amount).
    int? best;
    for (final m in RegExp(r'(?<!\d)(\d{1,3}(?:[ ,.\u00A0\u202F]\d{3})+|\d+)(?!\d)').allMatches(t)) {
      final v = int.tryParse(m.group(1)!.replaceAll(RegExp(r'[ ,.\u00A0\u202F]'), ''));
      if (v != null && (best == null || v > best)) best = v;
    }
    return best == null || best < 100 ? null : Money.bif(best);
  }

  /// Extracts the recipient name from a transfer request.
  static String? extractRecipient(String input) {
    final s = input.replaceAll(RegExp(r'[?!.]'), ' ').trim();
    final patterns = [
      RegExp(r"(?:^|\s)(?:to|for|à|a|pour|chez|kuri|ku|kwa)\s+([A-Za-zÀ-ÿ'\-]+(?:\s+[A-Z][A-Za-zÀ-ÿ'\-]+)?)", caseSensitive: false),
      RegExp(r"(?:^|\s)(?:rungikira|rungikire|ndungikira|ohereza|riha|envoie|envoyer|send|pay|transfer|transfère)\s+([A-Za-zÀ-ÿ'\-]+)", caseSensitive: false),
    ];
    const stop = {
      'me', 'moi', 'the', 'le', 'la', 'les', 'de', 'du', 'des', 'money', 'argent', 'amafaranga', 'bif', 'fbu', 'francs',
      'please', 'stp', 'now', 'maintenant', 'mon', 'ma', 'my', 'un', 'une', 'transfer', 'virement', 'payment',
      'paiement', 'of', 'transfert',
    };
    for (final p in patterns) {
      // The last preposition match is the recipient ("a transfer of 20 000 to Jean").
      String? found;
      for (final m in p.allMatches(s)) {
        final words = m.group(1)!.split(RegExp(r'\s+')).where((w) => !stop.contains(w.toLowerCase())).toList();
        if (words.isNotEmpty && !RegExp(r'^\d').hasMatch(words.first)) found = words.join(' ');
      }
      if (found != null) return found;
    }
    return null;
  }
}
