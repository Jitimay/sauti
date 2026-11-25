import '../../../../core/l10n/app_language.dart';
import '../../../../core/money/money.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../local/intent_parser.dart';

/// The contract between a language model and Sauti when the model cannot call
/// tools itself (Gemini Nano on Android and Chrome): the model only
/// *classifies* the request into this small JSON object. Sauti validates it
/// strictly, runs its own typed tools and renders the reply from templates.
abstract final class IntentSchema {
  static const intents = <String, IntentType>{
    'balance': IntentType.balance,
    'recent_transactions': IntentType.recentTransactions,
    'incoming_payments': IntentType.searchIncoming,
    'search_person': IntentType.searchCounterparty,
    'spending': IntentType.spending,
    'explain_transaction': IntentType.explainTransaction,
    'notifications': IntentType.notifications,
    'received_today': IntentType.receivedToday,
    'recipients': IntentType.beneficiaries,
    'transfer': IntentType.transfer,
    'help': IntentType.help,
    'greeting': IntentType.greeting,
    'thanks': IntentType.thanks,
    'unknown': IntentType.unknown,
  };

  /// OpenAPI-style JSON schema, understood by Gemini (`responseSchema`) and by
  /// Chrome's Prompt API (`responseConstraint`). Flat and small on purpose:
  /// on-device models have a ~4k-token budget.
  static final Map<String, Object?> jsonSchema = {
    'type': 'object',
    'properties': {
      'intent': {'type': 'string', 'enum': intents.keys.toList()},
      'amount': {
        'type': 'integer',
        'description': 'Amount in BIF, only if the user said one.',
      },
      'name': {
        'type': 'string',
        'description': 'Person or recipient name, exactly as the user said it.',
      },
      'count': {
        'type': 'integer',
        'description': 'How many items the user asked for.',
      },
      'category': {
        'type': 'string',
        'enum': TransactionCategory.values.map((c) => c.name).toList(),
      },
      'last_month': {'type': 'boolean'},
      'yesterday': {'type': 'boolean'},
    },
    'required': ['intent'],
  };

  /// Instructions for the classifier. The model never answers the user and
  /// never sees banking data; it only labels the request.
  static String instructions(AppLanguage uiLanguage) => '''
You label requests for Sauti, a voice banking app in Burundi. Users speak English, French or Kirundi.
Return only a JSON object. Never answer the question and never invent data.
intent:
- balance: how much money, account balance
- recent_transactions: last transactions or history
- incoming_payments: who sent money, money received
- search_person: payments to or from a named person (set name)
- spending: how much was spent, optionally by category, last_month
- explain_transaction: explain or ask why about a transaction
- notifications: alerts or messages
- received_today: money received today
- recipients: saved recipients or beneficiaries
- transfer: send or pay money (set amount and name only if said)
- help, greeting, thanks, or unknown
Examples:
"How much money do I have?" -> {"intent":"balance"}
"Envoie 20 000 francs à Jean" -> {"intent":"transfer","amount":20000,"name":"Jean"}
"Rungikira Aline amafaranga ibihumbi 5" -> {"intent":"transfer","amount":5000,"name":"Aline"}
"Combien j'ai dépensé en nourriture le mois dernier ?" -> {"intent":"spending","category":"food","last_month":true}
"Who sent me money yesterday?" -> {"intent":"incoming_payments","yesterday":true}
"Show my last 3 transactions" -> {"intent":"recent_transactions","count":3}
The app answers in ${uiLanguage.nativeName}; you only label.''';

  /// Uses the user's previous request for follow-ups. Past assistant replies
  /// may contain account figures and are outside the classifier's input.
  static String prompt(String userText, {String? previousRequest}) {
    final prev = previousRequest == null || previousRequest.isEmpty
        ? ''
        : 'Previous user request: "${previousRequest.length > 160 ? '${previousRequest.substring(0, 160)}…' : previousRequest}"\n';
    return '${prev}Request: "$userText"\nJSON:';
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  /// Strictly converts model JSON into a [ParsedIntent]. Unknown or malformed
  /// fields are dropped, never trusted:
  ///
  /// * a name must literally appear in what the user said (the model cannot
  ///   invent a recipient);
  /// * when the user said an amount in digits, that amount wins over the
  ///   model's (the model cannot change how much is sent);
  /// * ranges are enforced (count 1–20, amount 1–1,000,000,000).
  static ParsedIntent toIntent(
    Map<String, Object?> json, {
    required String userText,
  }) {
    final type = intents[json['intent']] ?? IntentType.unknown;

    int? intIn(Object? v, int min, int max) {
      final n = switch (v) {
        final int i => i,
        final double d when d == d.truncateToDouble() && d.isFinite =>
          d.toInt(),
        final String s when RegExp(r'^\d{1,12}$').hasMatch(s.trim()) =>
          int.parse(s.trim()),
        _ => null,
      };
      return n == null || n < min || n > max ? null : n;
    }

    String? name;
    final rawName = json['name'];
    if (rawName is String) {
      final n = rawName.trim();
      if (n.isNotEmpty &&
          n.length <= 60 &&
          RegExp(r"^[A-Za-zÀ-ÿ' \-]+$").hasMatch(n) &&
          _fold(userText).contains(_fold(n))) {
        name = n;
      }
    }

    final spoken = IntentParser.extractAmount(userText);
    final modelAmount = intIn(json['amount'], 1, 1000000000);
    final amount =
        spoken ?? (modelAmount == null ? null : Money.bif(modelAmount));

    final category = TransactionCategory.values
        .where((c) => c.name == json['category'])
        .firstOrNull;
    final ref = RegExp(r'#([A-Za-z0-9_-]{2,64})')
        .firstMatch(userText)
        ?.group(1);

    return ParsedIntent(
      type,
      amount: type == IntentType.transfer || type == IntentType.searchIncoming
          ? amount
          : null,
      name: name,
      count: intIn(json['count'], 1, 20),
      category: category,
      monthOffset: json['last_month'] == true ? 1 : 0,
      yesterday: json['yesterday'] == true,
      transactionId: type == IntentType.explainTransaction ? ref : null,
    );
  }
}
