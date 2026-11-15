import '../../../../core/l10n/app_language.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../banking/domain/entities/bank_notification.dart';
import '../../../banking/domain/entities/bank_transaction.dart';

/// Localized sentence templates for the deterministic agent's replies.
/// One subclass per language keeps translations in dedicated resources.
abstract base class AgentPhrasebook {
  const AgentPhrasebook();

  factory AgentPhrasebook.of(AppLanguage l) => switch (l) {
        AppLanguage.english => const EnglishPhrasebook(),
        AppLanguage.french => const FrenchPhrasebook(),
        AppLanguage.kirundi => const KirundiPhrasebook(),
      };

  String get code;
  String money(Money m) => MoneyFormatter.format(m, locale: code);
  String time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String date(DateTime t) => '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

  String cachedPrefix(DateTime asOf);
  String balance(String accountName, Money available);
  String otherAccounts(int n, Money total);
  String recentHeader(int n);
  String noTransactions();
  String txLine(BankTransaction t);
  String spending(Money total, {String? categoryName, required bool lastMonth});
  String spendingTop(String categoryName, Money amount);
  String spendingChange(int percent);
  String explainIncoming(BankTransaction t);
  String explainOutgoing(BankTransaction t, String categoryName);
  String explainRecurring();
  String explainShare(int percent, String categoryName);
  String explainFee(Money fee);
  String noNotifications();
  String notification(BankNotification n);
  String nothingReceivedToday();
  String receivedTodayHeader(int n);
  String incomingSearchNone();
  String beneficiaries(List<String> names);
  String draftReady(String name, Money amount, Money balanceAfter);
  String recipientChoice(String spoken, List<String> names);
  String transferNeedsAmount();
  String transferNeedsRecipient();
  String beneficiaryUnknown(String? spoken);
  String insufficientFunds();
  String invalidAmount();
  String limitExceeded();
  String offlineNoTransfer();
  String offlineNoData();
  String toolRejected();
  String genericError();
  String greeting();
  String thanks();
  String help();
  String unknown();
  String category(TransactionCategory c);
}

// ---------------------------------------------------------------------------

final class EnglishPhrasebook extends AgentPhrasebook {
  const EnglishPhrasebook();
  @override
  String get code => 'en';

  @override
  String cachedPrefix(DateTime asOf) => 'I am offline, so this is saved information from ${time(asOf)}, not live. ';
  @override
  String balance(String accountName, Money available) => 'Your $accountName has ${money(available)} available.';
  @override
  String otherAccounts(int n, Money total) =>
      ' You also have $n other account${n == 1 ? '' : 's'} with ${money(total)}.';
  @override
  String recentHeader(int n) => 'Here ${n == 1 ? 'is your latest transaction' : 'are your last $n transactions'}:';
  @override
  String noTransactions() => 'I found no matching transactions.';
  @override
  String txLine(BankTransaction t) => t.isIncoming
      ? '${money(t.amount)} received from ${t.counterparty} on ${date(t.timestamp)}.'
      : '${money(t.amount)} paid to ${t.counterparty} for ${category(t.category)} on ${date(t.timestamp)}.';
  @override
  String spending(Money total, {String? categoryName, required bool lastMonth}) =>
      '${lastMonth ? 'Last month' : 'This month'} you spent ${money(total)}${categoryName == null ? '' : ' on $categoryName'}.';
  @override
  String spendingTop(String c, Money a) => ' Your biggest expense was $c, at ${money(a)}.';
  @override
  String spendingChange(int p) => p >= 0
      ? ' That is $p% more than the previous month.'
      : ' That is ${-p}% less than the previous month.';
  @override
  String explainIncoming(BankTransaction t) =>
      'On ${date(t.timestamp)} you received ${money(t.amount)} from ${t.counterparty}. It was added to your account.';
  @override
  String explainOutgoing(BankTransaction t, String c) =>
      'On ${date(t.timestamp)} you paid ${money(t.amount)} to ${t.counterparty}. It is categorised as $c.';
  @override
  String explainRecurring() => ' You pay this every month.';
  @override
  String explainShare(int p, String c) => ' It is $p% of your $c spending this month.';
  @override
  String explainFee(Money f) => ' A fee of ${money(f)} was charged.';
  @override
  String noNotifications() => 'You have no notifications.';
  @override
  String notification(BankNotification n) => switch (n.kind) {
        NotificationKind.paymentReceived => 'You received ${money(n.amount!)} from ${n.counterparty}.',
        NotificationKind.transferSent => 'You sent ${money(n.amount!)} to ${n.counterparty}.',
        NotificationKind.security => n.detail == 'new_device_login'
            ? 'Security: a sign-in from a new device was detected.'
            : 'Security alert on your account.',
        NotificationKind.reminder =>
          n.detail == 'utility_bill_due' ? 'Reminder: your utility bill is due soon.' : 'You have a banking reminder.',
      };
  @override
  String nothingReceivedToday() => 'You have not received any money today.';
  @override
  String receivedTodayHeader(int n) => 'Yes, you received $n payment${n == 1 ? '' : 's'} today:';
  @override
  String incomingSearchNone() => 'I found no money received matching that.';
  @override
  String beneficiaries(List<String> names) => 'Your saved recipients are: ${names.join(', ')}.';
  @override
  String draftReady(String name, Money amount, Money after) =>
      'I have prepared a transfer of ${money(amount)} to $name. Nothing has been sent yet. '
      'Please review, then authenticate and confirm on screen. Your balance after would be ${money(after)}.';
  @override
  String recipientChoice(String spoken, List<String> names) =>
      'I found more than one "$spoken": ${names.join(', ')}. Which one do you mean?';
  @override
  String transferNeedsAmount() => 'How much would you like to send? For example: "Send 20,000 BIF to Jean".';
  @override
  String transferNeedsRecipient() => 'Who should receive the money? I can only send to your saved recipients.';
  @override
  String beneficiaryUnknown(String? s) =>
      '${s == null ? 'That person' : '"$s"'} is not among your saved recipients. For your safety I can only send to saved recipients.';
  @override
  String insufficientFunds() => 'You do not have enough available balance for this transfer.';
  @override
  String invalidAmount() => 'That amount is not valid. The minimum transfer is 500 BIF.';
  @override
  String limitExceeded() => 'This amount is above your transfer limit.';
  @override
  String offlineNoTransfer() =>
      'You are offline. Transfers need a live connection and are never queued. Please try again when you are connected.';
  @override
  String offlineNoData() => 'You are offline and I have no saved information for this yet.';
  @override
  String toolRejected() => 'I am not allowed to do that.';
  @override
  String genericError() => 'Something went wrong while getting your information. Nothing was changed. Please try again.';
  @override
  String greeting() => 'Hello! I am Sauti. Ask me about your balance, transactions, spending, or to prepare a transfer.';
  @override
  String thanks() => 'You are welcome.';
  @override
  String help() =>
      'You can say: "How much money do I have?", "Show my last five transactions", "How much did I spend this month?", '
      '"Explain my last transaction", "Read my notifications", or "Send 20,000 BIF to Jean".';
  @override
  String unknown() => 'Sorry, I did not understand. Try "What is my balance?" or say "help".';
  @override
  String category(TransactionCategory c) => switch (c) {
        TransactionCategory.income => 'income',
        TransactionCategory.transfer => 'transfers',
        TransactionCategory.transport => 'transport',
        TransactionCategory.groceries => 'groceries',
        TransactionCategory.utilities => 'utilities',
        TransactionCategory.airtime => 'airtime',
        TransactionCategory.health => 'health',
        TransactionCategory.education => 'education',
        TransactionCategory.fees => 'bank fees',
        TransactionCategory.other => 'other',
      };
}

// ---------------------------------------------------------------------------

final class FrenchPhrasebook extends AgentPhrasebook {
  const FrenchPhrasebook();
  @override
  String get code => 'fr';

  @override
  String cachedPrefix(DateTime asOf) =>
      'Je suis hors ligne : voici les informations enregistrées à ${time(asOf)}, pas en temps réel. ';
  @override
  String balance(String accountName, Money available) => 'Votre $accountName a ${money(available)} disponibles.';
  @override
  String otherAccounts(int n, Money total) =>
      ' Vous avez aussi $n autre${n == 1 ? '' : 's'} compte${n == 1 ? '' : 's'} avec ${money(total)}.';
  @override
  String recentHeader(int n) => n == 1 ? 'Voici votre dernière opération :' : 'Voici vos $n dernières opérations :';
  @override
  String noTransactions() => "Je n'ai trouvé aucune opération correspondante.";
  @override
  String txLine(BankTransaction t) => t.isIncoming
      ? '${money(t.amount)} reçus de ${t.counterparty} le ${date(t.timestamp)}.'
      : '${money(t.amount)} payés à ${t.counterparty} (${category(t.category)}) le ${date(t.timestamp)}.';
  @override
  String spending(Money total, {String? categoryName, required bool lastMonth}) =>
      '${lastMonth ? 'Le mois dernier' : 'Ce mois-ci'}, vous avez dépensé ${money(total)}'
      '${categoryName == null ? '' : ' en $categoryName'}.';
  @override
  String spendingTop(String c, Money a) => ' Votre plus grosse dépense : $c, ${money(a)}.';
  @override
  String spendingChange(int p) =>
      p >= 0 ? ' C\'est $p % de plus que le mois précédent.' : ' C\'est ${-p} % de moins que le mois précédent.';
  @override
  String explainIncoming(BankTransaction t) =>
      'Le ${date(t.timestamp)}, vous avez reçu ${money(t.amount)} de ${t.counterparty}. Le montant a été crédité.';
  @override
  String explainOutgoing(BankTransaction t, String c) =>
      'Le ${date(t.timestamp)}, vous avez payé ${money(t.amount)} à ${t.counterparty}. Catégorie : $c.';
  @override
  String explainRecurring() => ' C\'est un paiement mensuel habituel.';
  @override
  String explainShare(int p, String c) => ' Cela représente $p % de vos dépenses en $c ce mois-ci.';
  @override
  String explainFee(Money f) => ' Des frais de ${money(f)} ont été prélevés.';
  @override
  String noNotifications() => "Vous n'avez aucune notification.";
  @override
  String notification(BankNotification n) => switch (n.kind) {
        NotificationKind.paymentReceived => 'Vous avez reçu ${money(n.amount!)} de ${n.counterparty}.',
        NotificationKind.transferSent => 'Vous avez envoyé ${money(n.amount!)} à ${n.counterparty}.',
        NotificationKind.security => n.detail == 'new_device_login'
            ? 'Sécurité : une connexion depuis un nouvel appareil a été détectée.'
            : 'Alerte de sécurité sur votre compte.',
        NotificationKind.reminder => n.detail == 'utility_bill_due'
            ? 'Rappel : votre facture d\'eau et d\'électricité arrive à échéance.'
            : 'Vous avez un rappel bancaire.',
      };
  @override
  String nothingReceivedToday() => "Vous n'avez reçu aucun argent aujourd'hui.";
  @override
  String receivedTodayHeader(int n) => 'Oui, vous avez reçu $n paiement${n == 1 ? '' : 's'} aujourd\'hui :';
  @override
  String incomingSearchNone() => "Je n'ai trouvé aucun argent reçu correspondant.";
  @override
  String beneficiaries(List<String> names) => 'Vos bénéficiaires enregistrés : ${names.join(', ')}.';
  @override
  String draftReady(String name, Money amount, Money after) =>
      "J'ai préparé un virement de ${money(amount)} à $name. Rien n'a encore été envoyé. "
      'Vérifiez, puis authentifiez-vous et confirmez à l\'écran. Solde après virement : ${money(after)}.';
  @override
  String recipientChoice(String spoken, List<String> names) =>
      "J'ai trouvé plusieurs « $spoken » : ${names.join(', ')}. Lequel voulez-vous dire ?";
  @override
  String transferNeedsAmount() => 'Quel montant voulez-vous envoyer ? Par exemple : « Envoie 20 000 BIF à Jean ».';
  @override
  String transferNeedsRecipient() =>
      "À qui voulez-vous envoyer l'argent ? Je ne peux envoyer qu'à vos bénéficiaires enregistrés.";
  @override
  String beneficiaryUnknown(String? s) =>
      "${s == null ? 'Cette personne' : '« $s »'} ne fait pas partie de vos bénéficiaires. Pour votre sécurité, "
      "je n'envoie qu'aux bénéficiaires enregistrés.";
  @override
  String insufficientFunds() => 'Votre solde disponible est insuffisant pour ce virement.';
  @override
  String invalidAmount() => "Ce montant n'est pas valide. Le minimum est de 500 BIF.";
  @override
  String limitExceeded() => 'Ce montant dépasse votre plafond de virement.';
  @override
  String offlineNoTransfer() =>
      'Vous êtes hors ligne. Les virements exigent une connexion et ne sont jamais mis en attente. Réessayez une fois connecté.';
  @override
  String offlineNoData() => "Vous êtes hors ligne et je n'ai pas encore d'informations enregistrées pour cela.";
  @override
  String toolRejected() => "Je n'ai pas l'autorisation de faire cela.";
  @override
  String genericError() =>
      "Un problème est survenu en récupérant vos informations. Rien n'a été modifié. Veuillez réessayer.";
  @override
  String greeting() =>
      'Bonjour ! Je suis Sauti. Demandez-moi votre solde, vos opérations, vos dépenses, ou de préparer un virement.';
  @override
  String thanks() => 'Avec plaisir.';
  @override
  String help() =>
      'Vous pouvez dire : « Quel est mon solde ? », « Montre mes 5 dernières opérations », « Combien j\'ai dépensé ce mois-ci ? », '
      '« Explique ma dernière opération », « Lis mes notifications » ou « Envoie 20 000 BIF à Jean ».';
  @override
  String unknown() => "Désolé, je n'ai pas compris. Essayez « Quel est mon solde ? » ou dites « aide ».";
  @override
  String category(TransactionCategory c) => switch (c) {
        TransactionCategory.income => 'revenus',
        TransactionCategory.transfer => 'virements',
        TransactionCategory.transport => 'transport',
        TransactionCategory.groceries => 'courses',
        TransactionCategory.utilities => 'eau et électricité',
        TransactionCategory.airtime => 'crédit téléphone',
        TransactionCategory.health => 'santé',
        TransactionCategory.education => 'éducation',
        TransactionCategory.fees => 'frais bancaires',
        TransactionCategory.other => 'autres',
      };
}

// ---------------------------------------------------------------------------

/// Kirundi templates — FIRST DRAFT, pending review by native speakers.
final class KirundiPhrasebook extends AgentPhrasebook {
  const KirundiPhrasebook();
  @override
  String get code => 'rn';

  @override
  String cachedPrefix(DateTime asOf) => 'Nta interineti ihari: aya ni amakuru yabitswe saa ${time(asOf)}, si ay\'ubu. ';
  @override
  String balance(String accountName, Money available) => 'Kuri $accountName ufise ${money(available)}.';
  @override
  String otherAccounts(int n, Money total) => ' Ufise kandi izindi konti $n zirimwo ${money(total)}.';
  @override
  String recentHeader(int n) => 'Ivyakozwe vyawe $n vya vuba:';
  @override
  String noTransactions() => 'Nta vyakozwe ndonse bihuye n\'ivyo usaba.';
  @override
  String txLine(BankTransaction t) => t.isIncoming
      ? 'Wakiriye ${money(t.amount)} biva kwa ${t.counterparty} itariki ${date(t.timestamp)}.'
      : 'Warishe ${money(t.amount)} kuri ${t.counterparty} (${category(t.category)}) itariki ${date(t.timestamp)}.';
  @override
  String spending(Money total, {String? categoryName, required bool lastMonth}) =>
      '${lastMonth ? 'Ukwezi guheze' : 'Uku kwezi'} wakoresheje ${money(total)}${categoryName == null ? '' : ' mu $categoryName'}.';
  @override
  String spendingTop(String c, Money a) => ' Ivyo wakoresheje cane ni $c: ${money(a)}.';
  @override
  String spendingChange(int p) =>
      p >= 0 ? ' Ni $p% kurusha ukwezi guheze.' : ' Ni ${-p}% munsi y\'ukwezi guheze.';
  @override
  String explainIncoming(BankTransaction t) =>
      'Itariki ${date(t.timestamp)} wakiriye ${money(t.amount)} biva kwa ${t.counterparty}. Vyongewe kuri konti yawe.';
  @override
  String explainOutgoing(BankTransaction t, String c) =>
      'Itariki ${date(t.timestamp)} warishe ${money(t.amount)} kuri ${t.counterparty}. Ni mu $c.';
  @override
  String explainRecurring() => ' Uriha ibi buri kwezi.';
  @override
  String explainShare(int p, String c) => ' Ni $p% vy\'ivyo wakoresheje mu $c uku kwezi.';
  @override
  String explainFee(Money f) => ' Hakuweho ${money(f)} y\'amafaranga y\'igikorwa.';
  @override
  String noNotifications() => 'Nta butumwa ufise.';
  @override
  String notification(BankNotification n) => switch (n.kind) {
        NotificationKind.paymentReceived => 'Wakiriye ${money(n.amount!)} biva kwa ${n.counterparty}.',
        NotificationKind.transferSent => 'Warungitse ${money(n.amount!)} kuri ${n.counterparty}.',
        NotificationKind.security => n.detail == 'new_device_login'
            ? 'Umutekano: hari uwinjiye akoresheje telefone nshasha.'
            : 'Hari ikibazo c\'umutekano kuri konti yawe.',
        NotificationKind.reminder => n.detail == 'utility_bill_due'
            ? 'Wibuke: igihe co kuriha amazi n\'umuyagankuba kiregereje.'
            : 'Ufise ubutumwa bwo kukwibutsa.',
      };
  @override
  String nothingReceivedToday() => 'Uyu munsi nta mafaranga wakiriye.';
  @override
  String receivedTodayHeader(int n) => 'Ego, uyu munsi wakiriye amafaranga incuro $n:';
  @override
  String incomingSearchNone() => 'Nta mafaranga wakiriye ndonse ahuye n\'ivyo usaba.';
  @override
  String beneficiaries(List<String> names) => 'Abo ushobora kurungikira ni: ${names.join(', ')}.';
  @override
  String draftReady(String name, Money amount, Money after) =>
      'Nateguye kurungikira $name ${money(amount)}. Nta na kimwe kirarungikwa. '
      'Raba neza, hanyuma wemeze kuri telefone. Uzosigarana ${money(after)}.';
  @override
  String recipientChoice(String spoken, List<String> names) =>
      'Ndonse abantu benshi bitwa "$spoken": ${names.join(', ')}. Ni nde ushaka?';
  @override
  String transferNeedsAmount() => 'Urashaka kurungika angahe? Nk\'akarorero: "Rungikira Jean 20 000 BIF".';
  @override
  String transferNeedsRecipient() => 'Urashaka kurungikira nde? Nshobora kurungikira gusa abo wabitse.';
  @override
  String beneficiaryUnknown(String? s) =>
      '${s ?? 'Uwo muntu'} ntari mu bo wabitse. Kubw\'umutekano wawe, ndungikira gusa abo wabitse.';
  @override
  String insufficientFunds() => 'Amafaranga ufise ntashika ngo urungike ayo.';
  @override
  String invalidAmount() => 'Ayo mafaranga ntibikunda. Make cane ni 500 BIF.';
  @override
  String limitExceeded() => 'Ayo mafaranga arenze urugero rwawe rwo kurungika.';
  @override
  String offlineNoTransfer() =>
      'Nta interineti ihari. Kurungika amafaranga bisaba interineti kandi ntibibikwa ngo bikorwe mu nyuma. Subira ugerageze.';
  @override
  String offlineNoData() => 'Nta interineti ihari kandi nta makuru nabitse kuri ivyo.';
  @override
  String toolRejected() => 'Sindekuriwe gukora ivyo.';
  @override
  String genericError() => 'Hari ikitagenze neza. Nta na kimwe cahindutse. Subira ugerageze.';
  @override
  String greeting() =>
      'Amahoro! Ndi Sauti. Mbaza amafaranga ufise, ivyakozwe, ivyo wakoresheje, canke ko ntegura kurungika amafaranga.';
  @override
  String thanks() => 'Ntaco.';
  @override
  String help() =>
      'Ushobora kuvuga: "Amafaranga mfise ni angahe?", "Ivyakozwe vya vuba", "Nakoresheje angahe uku kwezi?", '
      '"Sobanura ivyakozwe vya nyuma", "Ubutumwa bwanje", canke "Rungikira Jean 20 000 BIF".';
  @override
  String unknown() => 'Ihangane, sinabitahuye. Gerageza "Amafaranga mfise ni angahe?" canke uvuge "imfashanyo".';
  @override
  String category(TransactionCategory c) => switch (c) {
        TransactionCategory.income => 'amafaranga yinjiye',
        TransactionCategory.transfer => 'ayarungitswe',
        TransactionCategory.transport => 'ingendo',
        TransactionCategory.groceries => 'ivyokurya',
        TransactionCategory.utilities => 'amazi n\'umuyagankuba',
        TransactionCategory.airtime => 'ama unite',
        TransactionCategory.health => 'amagara',
        TransactionCategory.education => 'amashure',
        TransactionCategory.fees => 'amafaranga ya banki',
        TransactionCategory.other => 'ibindi',
      };
}
