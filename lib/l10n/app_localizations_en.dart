// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sauti';

  @override
  String get tagline => 'Technology without barriers.';

  @override
  String get demoBanner => 'DEMO · simulated bank · no real money';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get loading => 'Loading…';

  @override
  String get offlineBanner => 'You are offline. Showing saved information.';

  @override
  String cachedAt(String time) {
    return 'Saved at $time · not live';
  }

  @override
  String get liveData => 'Live';

  @override
  String get failureNetwork =>
      'No connection. Please check your internet and try again.';

  @override
  String get failureUnauthorized =>
      'You are not allowed to do this. Please sign in again.';

  @override
  String get failureInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get failureEmailInUse => 'An account already exists with this email.';

  @override
  String get failureWeakPassword =>
      'Use at least 8 characters with letters and numbers.';

  @override
  String get failureUserNotFound => 'No account found with this email.';

  @override
  String get failureAuthExpired => 'Verification expired. Please verify again.';

  @override
  String get failureValidation => 'Please check the information you entered.';

  @override
  String get failureInvalidAmount => 'Enter a valid amount (minimum 500 BIF).';

  @override
  String get failureLimitExceeded =>
      'This amount is above your transfer limit.';

  @override
  String get failureInsufficientFunds => 'Not enough available balance.';

  @override
  String get failureBeneficiaryNotFound =>
      'This person is not one of your saved recipients.';

  @override
  String get failureBeneficiaryAmbiguous =>
      'More than one recipient matches. Please choose.';

  @override
  String get failureNotFound => 'Not found.';

  @override
  String get failureDuplicate => 'This transfer was already submitted.';

  @override
  String get failureTransferRejected =>
      'The bank rejected this transfer. No money was sent.';

  @override
  String get failureOfflineNotAllowed =>
      'You are offline. Transfers need a live connection and are never queued.';

  @override
  String get failureAiUnavailable => 'The assistant is unavailable right now.';

  @override
  String get failureToolNotPermitted => 'That action is not permitted.';

  @override
  String get failureVoiceUnavailable =>
      'Voice input is not available on this device.';

  @override
  String get failureVoicePermission =>
      'Microphone permission is needed for voice. You can still type.';

  @override
  String get failureVoiceLanguage =>
      'Voice is not available in this language on this device.';

  @override
  String get failureServer => 'The service had a problem. Nothing was changed.';

  @override
  String get failureUnexpected => 'Something went wrong. Nothing was changed.';

  @override
  String get onboardingTitle1 => 'Bank by talking';

  @override
  String get onboardingBody1 =>
      'Ask Sauti about your balance, payments and spending, in your own words.';

  @override
  String get onboardingTitle2 => 'Safe by design';

  @override
  String get onboardingBody2 =>
      'Sauti never sends money on its own. You always verify and confirm on screen.';

  @override
  String get onboardingTitle3 => 'Made for everyone';

  @override
  String get onboardingBody3 =>
      'Large text, high contrast, screen reader support and voice — or simply type.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String onboardingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change it later in Settings.';

  @override
  String get welcomeTitle => 'Your bank, in your voice';

  @override
  String get welcomeBody =>
      'Check balances, understand payments and prepare transfers by simply asking.';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get tryDemo => 'Try the demo';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String demoCredentialsHint(String email, String password) {
    return 'Demo account: $email / $password';
  }

  @override
  String get useDemoCredentials => 'Fill in demo account';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get fullName => 'Full name';

  @override
  String get nameInvalid => 'Enter your name.';

  @override
  String get passwordRules =>
      'At least 8 characters, with letters and numbers.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerDemoNote =>
      'Demo mode: accounts you create are saved in this browser and use simulated data. No real bank is involved.';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetBody => 'Enter your email and we will send you a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetSent =>
      'If an account exists for this email, a reset link has been sent.';

  @override
  String get resetDemoNote => 'Demo mode: no email is actually sent.';

  @override
  String greetingName(String name) {
    return 'Hello, $name';
  }

  @override
  String get availableBalance => 'Available balance';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get seeAll => 'See all';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get actionSend => 'Send money';

  @override
  String get actionHistory => 'History';

  @override
  String get actionInsights => 'Insights';

  @override
  String get actionAccounts => 'Accounts';

  @override
  String get talkToSauti => 'Talk to Sauti';

  @override
  String get talkToSautiHint => 'Opens the voice assistant';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String unreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new notifications',
      one: '1 new notification',
      zero: 'No new notifications',
    );
    return '$_temp0';
  }

  @override
  String get noTransactionsYet => 'No transactions yet.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get filterAll => 'All';

  @override
  String get filterIncoming => 'Money in';

  @override
  String get filterOutgoing => 'Money out';

  @override
  String get searchTransactions => 'Search by name';

  @override
  String get received => 'Received';

  @override
  String get paid => 'Paid';

  @override
  String txSemanticIn(String amount, String name, String date) {
    return 'Received $amount from $name, $date';
  }

  @override
  String txSemanticOut(String amount, String name, String date) {
    return 'Paid $amount to $name, $date';
  }

  @override
  String get transactionDetailsTitle => 'Transaction details';

  @override
  String get detailAmount => 'Amount';

  @override
  String get detailDate => 'Date';

  @override
  String get detailCategory => 'Category';

  @override
  String get detailCounterparty => 'With';

  @override
  String get detailReference => 'Reference';

  @override
  String get detailFee => 'Fee';

  @override
  String get detailStatus => 'Status';

  @override
  String get recurringPayment => 'This is a recurring monthly payment.';

  @override
  String shareOfCategory(int percent, String category) {
    return '$percent% of your $category spending this month.';
  }

  @override
  String get askSautiExplain => 'Ask Sauti to explain';

  @override
  String get categoryIncome => 'Income';

  @override
  String get categoryTransfer => 'Transfers';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryAirtime => 'Airtime';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryFees => 'Bank fees';

  @override
  String get categoryOther => 'Other';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusFailed => 'Failed';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountTypeCurrent => 'Current account';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get accountTypeWallet => 'Mobile wallet';

  @override
  String accountNumber(String number) {
    return 'Account $number';
  }

  @override
  String get balanceLabel => 'Balance';

  @override
  String get transferTitle => 'Send money';

  @override
  String get chooseRecipient => 'Choose a recipient';

  @override
  String get amountLabel => 'Amount (BIF)';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get reviewTransfer => 'Review transfer';

  @override
  String get savedRecipientsOnly =>
      'For your safety, you can only send to saved recipients.';

  @override
  String get confirmTitle => 'Confirm transfer';

  @override
  String get confirmTo => 'To';

  @override
  String get confirmFrom => 'From';

  @override
  String get confirmFee => 'Fee';

  @override
  String get confirmTotal => 'Total';

  @override
  String get confirmBalanceAfter => 'Balance after';

  @override
  String get notSentYet => 'Nothing has been sent yet.';

  @override
  String get stepVerify => 'Step 1 · Verify it\'s you';

  @override
  String get stepConfirm => 'Step 2 · Confirm and send';

  @override
  String get authenticateButton => 'Verify it\'s me';

  @override
  String authReason(String amount, String name) {
    return 'Confirm it\'s you to send $amount to $name';
  }

  @override
  String get usePassword => 'Use my password instead';

  @override
  String get passwordFallbackHint =>
      'Type your Sauti password. It is checked once and never stored. Never say it aloud.';

  @override
  String get verifyPassword => 'Verify password';

  @override
  String get verified => 'Identity verified';

  @override
  String get authExpiresHint =>
      'For your security, verification expires after 2 minutes.';

  @override
  String sendNow(String amount) {
    return 'Send $amount now';
  }

  @override
  String get cancelTransfer => 'Cancel transfer';

  @override
  String get transferCancelled => 'Transfer cancelled. No money was sent.';

  @override
  String get sending => 'Sending… please keep the app open.';

  @override
  String get deviceAuthUnavailable =>
      'Device verification is not available. Please use your password.';

  @override
  String get receiptTitle => 'Transfer complete';

  @override
  String get receiptVerified => 'Confirmed by the bank';

  @override
  String get receiptReference => 'Reference';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptNewBalance => 'New balance';

  @override
  String receiptSpoken(String amount, String name, String reference) {
    return 'Your transfer of $amount to $name is confirmed by the bank. Reference $reference.';
  }

  @override
  String get transferFailedTitle => 'Transfer not completed';

  @override
  String get transferUnknownBody =>
      'We could not confirm the result. Check your history before trying again — retrying is safe and will not send twice.';

  @override
  String get insightsTitle => 'Spending insights';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get totalSpent => 'Spent';

  @override
  String get totalReceived => 'Received';

  @override
  String spentMoreThanLast(int percent) {
    return '$percent% more than the previous month';
  }

  @override
  String spentLessThanLast(int percent) {
    return '$percent% less than the previous month';
  }

  @override
  String get byCategory => 'By category';

  @override
  String get noSpending => 'No spending in this period.';

  @override
  String categoryShareSemantic(String category, String amount, int percent) {
    return '$category: $amount, $percent% of spending';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'You have no notifications.';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get unread => 'Unread';

  @override
  String notifPaymentReceived(String amount, String name) {
    return 'You received $amount from $name.';
  }

  @override
  String notifTransferSent(String amount, String name) {
    return 'You sent $amount to $name.';
  }

  @override
  String get notifSecurityNewDevice =>
      'Security: sign-in from a new device detected.';

  @override
  String get notifSecurityGeneric => 'Security alert on your account.';

  @override
  String get notifReminderBill => 'Reminder: your utility bill is due soon.';

  @override
  String get notifReminderGeneric => 'You have a banking reminder.';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get assistantTitle => 'Sauti assistant';

  @override
  String get typeMessage => 'Type your request';

  @override
  String get send => 'Send';

  @override
  String get startListening => 'Start speaking';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get stateIdle => 'Tap the microphone and speak, or type below.';

  @override
  String get stateListening => 'Listening…';

  @override
  String get stateProcessing => 'Thinking…';

  @override
  String get stateResponding => 'Speaking…';

  @override
  String get stateAwaitingConfirmation => 'Waiting for your confirmation';

  @override
  String get stateError => 'Something went wrong. You can try again or type.';

  @override
  String toolRunning(String what) {
    return 'Checking $what…';
  }

  @override
  String get toolWhatBalance => 'your balance';

  @override
  String get toolWhatTransactions => 'your transactions';

  @override
  String get toolWhatSpending => 'your spending';

  @override
  String get toolWhatBeneficiaries => 'your recipients';

  @override
  String get toolWhatTransfer => 'the transfer details';

  @override
  String get toolWhatNotifications => 'your notifications';

  @override
  String get repeat => 'Repeat';

  @override
  String get stopSpeaking => 'Stop speaking';

  @override
  String get clearConversation => 'Clear conversation';

  @override
  String get historyTitle => 'Conversation history';

  @override
  String get historyEmpty => 'No conversations yet.';

  @override
  String get historyPrivacyNote =>
      'Stored only on this device, encrypted. Amounts in cards are not stored.';

  @override
  String get providerCloud => 'Cloud AI';

  @override
  String get providerLocal => 'Basic mode';

  @override
  String get providerOnDeviceAi => 'On-device AI · private';

  @override
  String get fallbackNotice =>
      'Preferred AI unavailable — answered by a backup';

  @override
  String get tryAsking => 'Try asking';

  @override
  String get suggestionBalance => 'How much money do I have?';

  @override
  String get suggestionExplain => 'Explain my last transaction';

  @override
  String get suggestionSend => 'Send 20,000 BIF to Jean';

  @override
  String get suggestionSpending => 'How much did I spend this month?';

  @override
  String get suggestionNotifications => 'Read my notifications';

  @override
  String get reviewAndConfirm => 'Review & confirm';

  @override
  String get draftCardTitle => 'Transfer prepared — not sent';

  @override
  String get chooseRecipientCard => 'Who do you mean?';

  @override
  String sendToThisPerson(String amount, String name) {
    return 'Send $amount to $name';
  }

  @override
  String voiceLanguageUnsupported(String language) {
    return 'Voice input in $language is not available on this device. You can type, or use French voice.';
  }

  @override
  String get useFrenchVoice => 'Use French voice';

  @override
  String get noSpeechHeard =>
      'I didn\'t hear anything. Tap the microphone and try again.';

  @override
  String ttsUnavailable(String language) {
    return 'No voice for $language on this device. Replies are shown as text.';
  }

  @override
  String get you => 'You';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileSection => 'Profile';

  @override
  String get languageSetting => 'Language';

  @override
  String get accessibilitySetting => 'Accessibility';

  @override
  String get cloudAiSetting => 'Use cloud AI (Gemini)';

  @override
  String get cloudAiDescription =>
      'Sends minimal, anonymised banking facts to Google\'s Gemini via Firebase to understand free-form requests. Off: Sauti uses its on-device assistant.';

  @override
  String get naturalVoiceSetting => 'Natural voice (Gemini)';

  @override
  String get naturalVoiceDescription =>
      'Replies are read aloud by Gemini via Firebase. Answers from the on-device AI always use the phone\'s own voice, so they never leave the device. Off: the phone\'s voice is always used.';

  @override
  String get cloudAiNotConfigured =>
      'Cloud AI is not configured in this build. Sauti uses its on-device assistant.';

  @override
  String get demoControls => 'Demo controls';

  @override
  String get simulateOffline => 'Simulate no connection';

  @override
  String get simulateOfflineDescription =>
      'Shows how Sauti behaves offline: cached data is labelled and transfers are blocked.';

  @override
  String get signOut => 'Sign out';

  @override
  String get aboutSection => 'About';

  @override
  String get environmentDemo => 'Environment: DEMO (simulated bank)';

  @override
  String get environmentLive => 'Environment: Firebase sandbox';

  @override
  String get accessibilityTitle => 'Accessibility';

  @override
  String get textSize => 'Text size';

  @override
  String textSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastDescription =>
      'Stronger colours and borders for low vision.';

  @override
  String get voiceFeedback => 'Read replies aloud';

  @override
  String get speechSpeed => 'Speech speed';

  @override
  String get speechSlow => 'Slow';

  @override
  String get speechNormal => 'Normal';

  @override
  String get speechFast => 'Fast';

  @override
  String get simplifiedMode => 'Simplified mode';

  @override
  String get simplifiedModeDescription =>
      'Fewer items on screen and larger buttons.';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get previewText => 'Preview: your balance is 250,000 BIF.';

  @override
  String get navHome => 'Home';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navActivity => 'Activity';

  @override
  String get navSettings => 'Settings';

  @override
  String get kirundiDraftNote =>
      'Kirundi translations are a first draft under review by native speakers.';

  @override
  String get onDeviceAiSetting => 'Private on-device AI (Gemini Nano)';

  @override
  String get onDeviceAiReady =>
      'Ready. Your requests are understood on this phone and work without internet.';

  @override
  String get onDeviceAiDownloadable =>
      'Available for this device. Download it once (Wi-Fi recommended) to keep your requests on the phone.';

  @override
  String get onDeviceAiDownloading => 'Downloading the on-device model…';

  @override
  String get onDeviceAiUnavailable =>
      'Not supported on this device. Sauti uses cloud AI or basic mode instead.';

  @override
  String get onDeviceAiDownload => 'Download';
}
