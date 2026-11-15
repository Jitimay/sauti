// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Sauti';

  @override
  String get tagline => 'La technologie sans barrières.';

  @override
  String get demoBanner => 'DÉMO · banque simulée · aucun argent réel';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get close => 'Fermer';

  @override
  String get done => 'Terminé';

  @override
  String get loading => 'Chargement…';

  @override
  String get offlineBanner =>
      'Vous êtes hors ligne. Informations enregistrées affichées.';

  @override
  String cachedAt(String time) {
    return 'Enregistré à $time · pas en direct';
  }

  @override
  String get liveData => 'En direct';

  @override
  String get failureNetwork =>
      'Pas de connexion. Vérifiez internet et réessayez.';

  @override
  String get failureUnauthorized => 'Action non autorisée. Reconnectez-vous.';

  @override
  String get failureInvalidCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get failureEmailInUse => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get failureWeakPassword =>
      'Au moins 8 caractères, avec lettres et chiffres.';

  @override
  String get failureUserNotFound => 'Aucun compte avec cet e-mail.';

  @override
  String get failureAuthExpired =>
      'La vérification a expiré. Vérifiez à nouveau.';

  @override
  String get failureValidation => 'Vérifiez les informations saisies.';

  @override
  String get failureInvalidAmount =>
      'Saisissez un montant valide (minimum 500 BIF).';

  @override
  String get failureLimitExceeded => 'Ce montant dépasse votre plafond.';

  @override
  String get failureInsufficientFunds => 'Solde disponible insuffisant.';

  @override
  String get failureBeneficiaryNotFound =>
      'Cette personne n\'est pas un bénéficiaire enregistré.';

  @override
  String get failureBeneficiaryAmbiguous =>
      'Plusieurs bénéficiaires correspondent. Choisissez.';

  @override
  String get failureNotFound => 'Introuvable.';

  @override
  String get failureDuplicate => 'Ce virement a déjà été soumis.';

  @override
  String get failureTransferRejected =>
      'La banque a refusé ce virement. Aucun argent n\'a été envoyé.';

  @override
  String get failureOfflineNotAllowed =>
      'Hors ligne. Les virements exigent une connexion et ne sont jamais mis en attente.';

  @override
  String get failureAiUnavailable =>
      'L\'assistant est indisponible pour le moment.';

  @override
  String get failureToolNotPermitted => 'Action non autorisée.';

  @override
  String get failureVoiceUnavailable =>
      'La saisie vocale n\'est pas disponible sur cet appareil.';

  @override
  String get failureVoicePermission =>
      'L\'accès au micro est nécessaire pour la voix. Vous pouvez écrire.';

  @override
  String get failureVoiceLanguage =>
      'La voix n\'est pas disponible dans cette langue sur cet appareil.';

  @override
  String get failureServer =>
      'Le service a rencontré un problème. Rien n\'a changé.';

  @override
  String get failureUnexpected => 'Un problème est survenu. Rien n\'a changé.';

  @override
  String get onboardingTitle1 => 'La banque, en parlant';

  @override
  String get onboardingBody1 =>
      'Demandez à Sauti votre solde, vos paiements et vos dépenses, avec vos mots.';

  @override
  String get onboardingTitle2 => 'Sécurisé par conception';

  @override
  String get onboardingBody2 =>
      'Sauti n\'envoie jamais d\'argent seule. Vous vérifiez et confirmez toujours à l\'écran.';

  @override
  String get onboardingTitle3 => 'Pour tout le monde';

  @override
  String get onboardingBody3 =>
      'Grand texte, contraste élevé, lecteur d\'écran et voix — ou écrivez simplement.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String onboardingStep(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get languageTitle => 'Choisissez votre langue';

  @override
  String get languageSubtitle => 'Vous pourrez la changer dans les Réglages.';

  @override
  String get welcomeTitle => 'Votre banque, avec votre voix';

  @override
  String get welcomeBody =>
      'Consultez vos soldes, comprenez vos paiements et préparez des virements en demandant simplement.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get tryDemo => 'Essayer la démo';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String demoCredentialsHint(String email, String password) {
    return 'Compte démo : $email / $password';
  }

  @override
  String get useDemoCredentials => 'Remplir le compte démo';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get emailInvalid => 'Saisissez une adresse e-mail valide.';

  @override
  String get passwordRequired => 'Saisissez votre mot de passe.';

  @override
  String get fullName => 'Nom complet';

  @override
  String get nameInvalid => 'Saisissez votre nom.';

  @override
  String get passwordRules =>
      'Au moins 8 caractères, avec lettres et chiffres.';

  @override
  String get registerTitle => 'Créez votre compte';

  @override
  String get registerDemoNote =>
      'Mode démo : les nouveaux comptes durent le temps de la session et utilisent des données simulées.';

  @override
  String get resetTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetBody =>
      'Saisissez votre e-mail, nous vous enverrons un lien.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetSent =>
      'Si un compte existe pour cet e-mail, un lien a été envoyé.';

  @override
  String get resetDemoNote =>
      'Mode démo : aucun e-mail n\'est réellement envoyé.';

  @override
  String greetingName(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get availableBalance => 'Solde disponible';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get actionSend => 'Envoyer';

  @override
  String get actionHistory => 'Historique';

  @override
  String get actionInsights => 'Analyses';

  @override
  String get actionAccounts => 'Comptes';

  @override
  String get talkToSauti => 'Parler à Sauti';

  @override
  String get talkToSautiHint => 'Ouvre l\'assistant vocal';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String unreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles notifications',
      one: '1 nouvelle notification',
      zero: 'Aucune nouvelle notification',
    );
    return '$_temp0';
  }

  @override
  String get noTransactionsYet => 'Aucune opération pour l\'instant.';

  @override
  String get transactionsTitle => 'Opérations';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterIncoming => 'Entrées';

  @override
  String get filterOutgoing => 'Sorties';

  @override
  String get searchTransactions => 'Rechercher par nom';

  @override
  String get received => 'Reçu';

  @override
  String get paid => 'Payé';

  @override
  String txSemanticIn(String amount, String name, String date) {
    return 'Reçu $amount de $name, $date';
  }

  @override
  String txSemanticOut(String amount, String name, String date) {
    return 'Payé $amount à $name, $date';
  }

  @override
  String get transactionDetailsTitle => 'Détails de l\'opération';

  @override
  String get detailAmount => 'Montant';

  @override
  String get detailDate => 'Date';

  @override
  String get detailCategory => 'Catégorie';

  @override
  String get detailCounterparty => 'Avec';

  @override
  String get detailReference => 'Référence';

  @override
  String get detailFee => 'Frais';

  @override
  String get detailStatus => 'Statut';

  @override
  String get recurringPayment => 'C\'est un paiement mensuel récurrent.';

  @override
  String shareOfCategory(int percent, String category) {
    return '$percent % de vos dépenses $category ce mois-ci.';
  }

  @override
  String get askSautiExplain => 'Demander à Sauti d\'expliquer';

  @override
  String get categoryIncome => 'Revenus';

  @override
  String get categoryTransfer => 'Virements';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryGroceries => 'Courses';

  @override
  String get categoryUtilities => 'Eau et électricité';

  @override
  String get categoryAirtime => 'Crédit téléphone';

  @override
  String get categoryHealth => 'Santé';

  @override
  String get categoryEducation => 'Éducation';

  @override
  String get categoryFees => 'Frais bancaires';

  @override
  String get categoryOther => 'Autres';

  @override
  String get statusCompleted => 'Effectuée';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusFailed => 'Échouée';

  @override
  String get accountsTitle => 'Comptes';

  @override
  String get accountTypeCurrent => 'Compte courant';

  @override
  String get accountTypeSavings => 'Épargne';

  @override
  String get accountTypeWallet => 'Portefeuille mobile';

  @override
  String accountNumber(String number) {
    return 'Compte $number';
  }

  @override
  String get balanceLabel => 'Solde';

  @override
  String get transferTitle => 'Envoyer de l\'argent';

  @override
  String get chooseRecipient => 'Choisissez un bénéficiaire';

  @override
  String get amountLabel => 'Montant (BIF)';

  @override
  String get noteLabel => 'Note (facultatif)';

  @override
  String get reviewTransfer => 'Vérifier le virement';

  @override
  String get savedRecipientsOnly =>
      'Pour votre sécurité, vous ne pouvez envoyer qu\'aux bénéficiaires enregistrés.';

  @override
  String get confirmTitle => 'Confirmer le virement';

  @override
  String get confirmTo => 'À';

  @override
  String get confirmFrom => 'Depuis';

  @override
  String get confirmFee => 'Frais';

  @override
  String get confirmTotal => 'Total';

  @override
  String get confirmBalanceAfter => 'Solde après';

  @override
  String get notSentYet => 'Rien n\'a encore été envoyé.';

  @override
  String get stepVerify => 'Étape 1 · Vérifiez votre identité';

  @override
  String get stepConfirm => 'Étape 2 · Confirmer et envoyer';

  @override
  String get authenticateButton => 'Vérifier mon identité';

  @override
  String authReason(String amount, String name) {
    return 'Confirmez votre identité pour envoyer $amount à $name';
  }

  @override
  String get usePassword => 'Utiliser mon mot de passe';

  @override
  String get passwordFallbackHint =>
      'Saisissez votre mot de passe Sauti. Il est vérifié une fois et jamais conservé. Ne le dites jamais à voix haute.';

  @override
  String get verifyPassword => 'Vérifier le mot de passe';

  @override
  String get verified => 'Identité vérifiée';

  @override
  String get authExpiresHint =>
      'Pour votre sécurité, la vérification expire après 2 minutes.';

  @override
  String sendNow(String amount) {
    return 'Envoyer $amount maintenant';
  }

  @override
  String get cancelTransfer => 'Annuler le virement';

  @override
  String get transferCancelled =>
      'Virement annulé. Aucun argent n\'a été envoyé.';

  @override
  String get sending => 'Envoi en cours… gardez l\'application ouverte.';

  @override
  String get deviceAuthUnavailable =>
      'La vérification par l\'appareil n\'est pas disponible. Utilisez votre mot de passe.';

  @override
  String get receiptTitle => 'Virement effectué';

  @override
  String get receiptVerified => 'Confirmé par la banque';

  @override
  String get receiptReference => 'Référence';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptNewBalance => 'Nouveau solde';

  @override
  String receiptSpoken(String amount, String name, String reference) {
    return 'Votre virement de $amount à $name est confirmé par la banque. Référence $reference.';
  }

  @override
  String get transferFailedTitle => 'Virement non effectué';

  @override
  String get transferUnknownBody =>
      'Résultat non confirmé. Vérifiez l\'historique avant de réessayer — réessayer n\'enverra pas deux fois.';

  @override
  String get insightsTitle => 'Analyse des dépenses';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get lastMonth => 'Le mois dernier';

  @override
  String get totalSpent => 'Dépensé';

  @override
  String get totalReceived => 'Reçu';

  @override
  String spentMoreThanLast(int percent) {
    return '$percent % de plus que le mois précédent';
  }

  @override
  String spentLessThanLast(int percent) {
    return '$percent % de moins que le mois précédent';
  }

  @override
  String get byCategory => 'Par catégorie';

  @override
  String get noSpending => 'Aucune dépense sur cette période.';

  @override
  String categoryShareSemantic(String category, String amount, int percent) {
    return '$category : $amount, $percent % des dépenses';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'Vous n\'avez aucune notification.';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get unread => 'Non lu';

  @override
  String notifPaymentReceived(String amount, String name) {
    return 'Vous avez reçu $amount de $name.';
  }

  @override
  String notifTransferSent(String amount, String name) {
    return 'Vous avez envoyé $amount à $name.';
  }

  @override
  String get notifSecurityNewDevice =>
      'Sécurité : connexion depuis un nouvel appareil.';

  @override
  String get notifSecurityGeneric => 'Alerte de sécurité sur votre compte.';

  @override
  String get notifReminderBill =>
      'Rappel : votre facture d\'eau et d\'électricité arrive à échéance.';

  @override
  String get notifReminderGeneric => 'Vous avez un rappel bancaire.';

  @override
  String get readAloud => 'Lire à voix haute';

  @override
  String get assistantTitle => 'Assistant Sauti';

  @override
  String get typeMessage => 'Écrivez votre demande';

  @override
  String get send => 'Envoyer';

  @override
  String get startListening => 'Commencer à parler';

  @override
  String get stopListening => 'Arrêter l\'écoute';

  @override
  String get stateIdle => 'Touchez le micro et parlez, ou écrivez ci-dessous.';

  @override
  String get stateListening => 'À l\'écoute…';

  @override
  String get stateProcessing => 'Réflexion…';

  @override
  String get stateResponding => 'Je parle…';

  @override
  String get stateAwaitingConfirmation => 'En attente de votre confirmation';

  @override
  String get stateError => 'Un problème est survenu. Réessayez ou écrivez.';

  @override
  String toolRunning(String what) {
    return 'Vérification : $what…';
  }

  @override
  String get toolWhatBalance => 'votre solde';

  @override
  String get toolWhatTransactions => 'vos opérations';

  @override
  String get toolWhatSpending => 'vos dépenses';

  @override
  String get toolWhatBeneficiaries => 'vos bénéficiaires';

  @override
  String get toolWhatTransfer => 'les détails du virement';

  @override
  String get toolWhatNotifications => 'vos notifications';

  @override
  String get repeat => 'Répéter';

  @override
  String get stopSpeaking => 'Arrêter la lecture';

  @override
  String get clearConversation => 'Effacer la conversation';

  @override
  String get historyTitle => 'Historique des conversations';

  @override
  String get historyEmpty => 'Aucune conversation pour l\'instant.';

  @override
  String get historyPrivacyNote =>
      'Stocké uniquement sur cet appareil, chiffré.';

  @override
  String get providerCloud => 'IA cloud';

  @override
  String get providerLocal => 'Assistant sur l\'appareil';

  @override
  String get fallbackNotice =>
      'IA cloud indisponible — réponse sur l\'appareil';

  @override
  String get tryAsking => 'Essayez de demander';

  @override
  String get suggestionBalance => 'Combien d\'argent ai-je ?';

  @override
  String get suggestionExplain => 'Explique ma dernière opération';

  @override
  String get suggestionSend => 'Envoie 20 000 BIF à Jean';

  @override
  String get suggestionSpending => 'Combien ai-je dépensé ce mois-ci ?';

  @override
  String get suggestionNotifications => 'Lis mes notifications';

  @override
  String get reviewAndConfirm => 'Vérifier et confirmer';

  @override
  String get draftCardTitle => 'Virement préparé — non envoyé';

  @override
  String get chooseRecipientCard => 'De qui parlez-vous ?';

  @override
  String sendToThisPerson(String amount, String name) {
    return 'Envoyer $amount à $name';
  }

  @override
  String voiceLanguageUnsupported(String language) {
    return 'La saisie vocale en $language n\'est pas disponible sur cet appareil. Écrivez, ou utilisez la voix en français.';
  }

  @override
  String get useFrenchVoice => 'Utiliser la voix en français';

  @override
  String get noSpeechHeard =>
      'Je n\'ai rien entendu. Touchez le micro et réessayez.';

  @override
  String ttsUnavailable(String language) {
    return 'Aucune voix pour $language sur cet appareil. Les réponses s\'affichent en texte.';
  }

  @override
  String get you => 'Vous';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get profileSection => 'Profil';

  @override
  String get languageSetting => 'Langue';

  @override
  String get accessibilitySetting => 'Accessibilité';

  @override
  String get cloudAiSetting => 'Utiliser l\'IA cloud (Gemini)';

  @override
  String get cloudAiDescription =>
      'Envoie des informations bancaires minimales à Gemini (Google) via Firebase. Désactivé : Sauti utilise son assistant sur l\'appareil.';

  @override
  String get cloudAiNotConfigured =>
      'L\'IA cloud n\'est pas configurée dans cette version. Sauti utilise son assistant sur l\'appareil.';

  @override
  String get demoControls => 'Contrôles de démo';

  @override
  String get simulateOffline => 'Simuler l\'absence de connexion';

  @override
  String get simulateOfflineDescription =>
      'Montre le comportement hors ligne : données en cache signalées, virements bloqués.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get aboutSection => 'À propos';

  @override
  String get environmentDemo => 'Environnement : DÉMO (banque simulée)';

  @override
  String get environmentLive => 'Environnement : bac à sable Firebase';

  @override
  String get accessibilityTitle => 'Accessibilité';

  @override
  String get textSize => 'Taille du texte';

  @override
  String textSizeValue(int percent) {
    return '$percent %';
  }

  @override
  String get highContrast => 'Contraste élevé';

  @override
  String get highContrastDescription =>
      'Couleurs et bordures renforcées pour la basse vision.';

  @override
  String get voiceFeedback => 'Lire les réponses à voix haute';

  @override
  String get speechSpeed => 'Vitesse de lecture';

  @override
  String get speechSlow => 'Lent';

  @override
  String get speechNormal => 'Normal';

  @override
  String get speechFast => 'Rapide';

  @override
  String get simplifiedMode => 'Mode simplifié';

  @override
  String get simplifiedModeDescription =>
      'Moins d\'éléments à l\'écran et des boutons plus grands.';

  @override
  String get reduceMotion => 'Réduire les animations';

  @override
  String get previewText => 'Aperçu : votre solde est de 250 000 BIF.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navActivity => 'Activité';

  @override
  String get navSettings => 'Réglages';

  @override
  String get kirundiDraftNote =>
      'Les traductions en kirundi sont un premier jet en cours de relecture.';
}
