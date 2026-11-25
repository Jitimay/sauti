import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rn'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sauti'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Technology without barriers.'**
  String get tagline;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'DEMO · simulated bank · no real money'**
  String get demoBanner;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing saved information.'**
  String get offlineBanner;

  /// No description provided for @cachedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved at {time} · not live'**
  String cachedAt(String time);

  /// No description provided for @liveData.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveData;

  /// No description provided for @failureNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please check your internet and try again.'**
  String get failureNetwork;

  /// No description provided for @failureUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to do this. Please sign in again.'**
  String get failureUnauthorized;

  /// No description provided for @failureInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get failureInvalidCredentials;

  /// No description provided for @failureEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get failureEmailInUse;

  /// No description provided for @failureWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with letters and numbers.'**
  String get failureWeakPassword;

  /// No description provided for @failureUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get failureUserNotFound;

  /// No description provided for @failureAuthExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification expired. Please verify again.'**
  String get failureAuthExpired;

  /// No description provided for @failureValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the information you entered.'**
  String get failureValidation;

  /// No description provided for @failureInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount (minimum 500 BIF).'**
  String get failureInvalidAmount;

  /// No description provided for @failureLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'This amount is above your transfer limit.'**
  String get failureLimitExceeded;

  /// No description provided for @failureInsufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Not enough available balance.'**
  String get failureInsufficientFunds;

  /// No description provided for @failureBeneficiaryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This person is not one of your saved recipients.'**
  String get failureBeneficiaryNotFound;

  /// No description provided for @failureBeneficiaryAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'More than one recipient matches. Please choose.'**
  String get failureBeneficiaryAmbiguous;

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get failureNotFound;

  /// No description provided for @failureDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This transfer was already submitted.'**
  String get failureDuplicate;

  /// No description provided for @failureTransferRejected.
  ///
  /// In en, this message translates to:
  /// **'The bank rejected this transfer. No money was sent.'**
  String get failureTransferRejected;

  /// No description provided for @failureOfflineNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Transfers need a live connection and are never queued.'**
  String get failureOfflineNotAllowed;

  /// No description provided for @failureAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assistant is unavailable right now.'**
  String get failureAiUnavailable;

  /// No description provided for @failureToolNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'That action is not permitted.'**
  String get failureToolNotPermitted;

  /// No description provided for @failureVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this device. Use the text box below to type your request.'**
  String get failureVoiceUnavailable;

  /// No description provided for @failureMicrophoneCapture.
  ///
  /// In en, this message translates to:
  /// **'Your browser could not start the microphone. Check the input device in your sound settings, then try again or type below.'**
  String get failureMicrophoneCapture;

  /// No description provided for @failureSpeechService.
  ///
  /// In en, this message translates to:
  /// **'Your browser’s speech recognition service is unavailable. Try another browser or type below.'**
  String get failureSpeechService;

  /// No description provided for @failureVoicePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access in your browser or device settings, then try again. You can still type.'**
  String get failureVoicePermission;

  /// No description provided for @failureVoiceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Voice is not available in this language on this device.'**
  String get failureVoiceLanguage;

  /// No description provided for @failureServer.
  ///
  /// In en, this message translates to:
  /// **'The service had a problem. Nothing was changed.'**
  String get failureServer;

  /// No description provided for @failureUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Nothing was changed.'**
  String get failureUnexpected;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Bank by talking'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Ask Sauti about your balance, payments and spending, in your own words.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Safe by design'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Sauti never sends money on its own. You always verify and confirm on screen.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Made for everyone'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Large text, high contrast, screen reader support and voice — or simply type.'**
  String get onboardingBody3;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings.'**
  String get languageSubtitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your bank, in your voice'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Check balances, understand payments and prepare transfers by simply asking.'**
  String get welcomeBody;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get tryDemo;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @demoCredentialsHint.
  ///
  /// In en, this message translates to:
  /// **'Demo account: {email} / {password}'**
  String demoCredentialsHint(String email, String password);

  /// No description provided for @useDemoCredentials.
  ///
  /// In en, this message translates to:
  /// **'Fill in demo account'**
  String get useDemoCredentials;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get nameInvalid;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with letters and numbers.'**
  String get passwordRules;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: accounts you create are saved in this browser and use simulated data. No real bank is involved.'**
  String get registerDemoNote;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a reset link.'**
  String get resetBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link has been sent.'**
  String get resetSent;

  /// No description provided for @resetDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: no email is actually sent.'**
  String get resetDemoNote;

  /// No description provided for @greetingName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greetingName(String name);

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @showBalance.
  ///
  /// In en, this message translates to:
  /// **'Show balance'**
  String get showBalance;

  /// No description provided for @hideBalance.
  ///
  /// In en, this message translates to:
  /// **'Hide balance'**
  String get hideBalance;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send money'**
  String get actionSend;

  /// No description provided for @actionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get actionHistory;

  /// No description provided for @actionInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get actionInsights;

  /// No description provided for @actionAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get actionAccounts;

  /// No description provided for @talkToSauti.
  ///
  /// In en, this message translates to:
  /// **'Talk to Sauti'**
  String get talkToSauti;

  /// No description provided for @talkToSautiHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the voice assistant'**
  String get talkToSautiHint;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new notifications} =1{1 new notification} other{{count} new notifications}}'**
  String unreadNotifications(int count);

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterIncoming.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get filterIncoming;

  /// No description provided for @filterOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get filterOutgoing;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchTransactions;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @txSemanticIn.
  ///
  /// In en, this message translates to:
  /// **'Received {amount} from {name}, {date}'**
  String txSemanticIn(String amount, String name, String date);

  /// No description provided for @txSemanticOut.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount} to {name}, {date}'**
  String txSemanticOut(String amount, String name, String date);

  /// No description provided for @transactionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetailsTitle;

  /// No description provided for @detailAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get detailAmount;

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get detailCategory;

  /// No description provided for @detailCounterparty.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get detailCounterparty;

  /// No description provided for @detailReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get detailReference;

  /// No description provided for @detailFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get detailFee;

  /// No description provided for @detailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// No description provided for @recurringPayment.
  ///
  /// In en, this message translates to:
  /// **'This is a recurring monthly payment.'**
  String get recurringPayment;

  /// No description provided for @shareOfCategory.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your {category} spending this month.'**
  String shareOfCategory(int percent, String category);

  /// No description provided for @askSautiExplain.
  ///
  /// In en, this message translates to:
  /// **'Ask Sauti to explain'**
  String get askSautiExplain;

  /// No description provided for @categoryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryIncome;

  /// No description provided for @categoryTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get categoryTransfer;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryAirtime.
  ///
  /// In en, this message translates to:
  /// **'Airtime'**
  String get categoryAirtime;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryFees.
  ///
  /// In en, this message translates to:
  /// **'Bank fees'**
  String get categoryFees;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountTypeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current account'**
  String get accountTypeCurrent;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile wallet'**
  String get accountTypeWallet;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account {number}'**
  String accountNumber(String number);

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceLabel;

  /// No description provided for @transferTitle.
  ///
  /// In en, this message translates to:
  /// **'Send money'**
  String get transferTitle;

  /// No description provided for @chooseRecipient.
  ///
  /// In en, this message translates to:
  /// **'Choose a recipient'**
  String get chooseRecipient;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (BIF)'**
  String get amountLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @reviewTransfer.
  ///
  /// In en, this message translates to:
  /// **'Review transfer'**
  String get reviewTransfer;

  /// No description provided for @savedRecipientsOnly.
  ///
  /// In en, this message translates to:
  /// **'For your safety, you can only send to saved recipients.'**
  String get savedRecipientsOnly;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm transfer'**
  String get confirmTitle;

  /// No description provided for @confirmTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get confirmTo;

  /// No description provided for @confirmFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get confirmFrom;

  /// No description provided for @confirmFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get confirmFee;

  /// No description provided for @confirmTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get confirmTotal;

  /// No description provided for @confirmBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get confirmBalanceAfter;

  /// No description provided for @notSentYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been sent yet.'**
  String get notSentYet;

  /// No description provided for @stepVerify.
  ///
  /// In en, this message translates to:
  /// **'Step 1 · Verify it\'s you'**
  String get stepVerify;

  /// No description provided for @stepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Step 2 · Confirm and send'**
  String get stepConfirm;

  /// No description provided for @authenticateButton.
  ///
  /// In en, this message translates to:
  /// **'Verify it\'s me'**
  String get authenticateButton;

  /// No description provided for @authReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to send {amount} to {name}'**
  String authReason(String amount, String name);

  /// No description provided for @usePassword.
  ///
  /// In en, this message translates to:
  /// **'Use my password instead'**
  String get usePassword;

  /// No description provided for @passwordFallbackHint.
  ///
  /// In en, this message translates to:
  /// **'Type your Sauti password. It is checked once and never stored. Never say it aloud.'**
  String get passwordFallbackHint;

  /// No description provided for @verifyPassword.
  ///
  /// In en, this message translates to:
  /// **'Verify password'**
  String get verifyPassword;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get verified;

  /// No description provided for @authExpiresHint.
  ///
  /// In en, this message translates to:
  /// **'For your security, verification expires after 2 minutes.'**
  String get authExpiresHint;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} now'**
  String sendNow(String amount);

  /// No description provided for @cancelTransfer.
  ///
  /// In en, this message translates to:
  /// **'Cancel transfer'**
  String get cancelTransfer;

  /// No description provided for @transferCancelled.
  ///
  /// In en, this message translates to:
  /// **'Transfer cancelled. No money was sent.'**
  String get transferCancelled;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending… please keep the app open.'**
  String get sending;

  /// No description provided for @deviceAuthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device verification is not available. Please use your password.'**
  String get deviceAuthUnavailable;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer complete'**
  String get receiptTitle;

  /// No description provided for @receiptVerified.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by the bank'**
  String get receiptVerified;

  /// No description provided for @receiptReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get receiptReference;

  /// No description provided for @receiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptDate;

  /// No description provided for @receiptNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance'**
  String get receiptNewBalance;

  /// No description provided for @receiptAmountTo.
  ///
  /// In en, this message translates to:
  /// **'{amount} sent to {name}'**
  String receiptAmountTo(String amount, String name);

  /// No description provided for @receiptSpoken.
  ///
  /// In en, this message translates to:
  /// **'Your transfer of {amount} to {name} is confirmed by the bank. Reference {reference}.'**
  String receiptSpoken(String amount, String name, String reference);

  /// No description provided for @transferFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer not completed'**
  String get transferFailedTitle;

  /// No description provided for @transferUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm the result. Check your history before trying again — retrying is safe and will not send twice.'**
  String get transferUnknownBody;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending insights'**
  String get insightsTitle;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get totalSpent;

  /// No description provided for @totalReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get totalReceived;

  /// No description provided for @spentMoreThanLast.
  ///
  /// In en, this message translates to:
  /// **'{percent}% more than the previous month'**
  String spentMoreThanLast(int percent);

  /// No description provided for @spentLessThanLast.
  ///
  /// In en, this message translates to:
  /// **'{percent}% less than the previous month'**
  String spentLessThanLast(int percent);

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @noSpending.
  ///
  /// In en, this message translates to:
  /// **'No spending in this period.'**
  String get noSpending;

  /// No description provided for @categoryShareSemantic.
  ///
  /// In en, this message translates to:
  /// **'{category}: {amount}, {percent}% of spending'**
  String categoryShareSemantic(String category, String amount, int percent);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications.'**
  String get noNotifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @notifPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'You received {amount} from {name}.'**
  String notifPaymentReceived(String amount, String name);

  /// No description provided for @notifTransferSent.
  ///
  /// In en, this message translates to:
  /// **'You sent {amount} to {name}.'**
  String notifTransferSent(String amount, String name);

  /// No description provided for @notifSecurityNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Security: sign-in from a new device detected.'**
  String get notifSecurityNewDevice;

  /// No description provided for @notifSecurityGeneric.
  ///
  /// In en, this message translates to:
  /// **'Security alert on your account.'**
  String get notifSecurityGeneric;

  /// No description provided for @notifReminderBill.
  ///
  /// In en, this message translates to:
  /// **'Reminder: your utility bill is due soon.'**
  String get notifReminderBill;

  /// No description provided for @notifReminderGeneric.
  ///
  /// In en, this message translates to:
  /// **'You have a banking reminder.'**
  String get notifReminderGeneric;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Sauti assistant'**
  String get assistantTitle;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your request'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Start speaking'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get stopListening;

  /// No description provided for @stateIdle.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and speak, or type below.'**
  String get stateIdle;

  /// No description provided for @stateMicrophoneAccess.
  ///
  /// In en, this message translates to:
  /// **'Waiting for microphone access…'**
  String get stateMicrophoneAccess;

  /// No description provided for @stateListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get stateListening;

  /// No description provided for @stateProcessing.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get stateProcessing;

  /// No description provided for @stateResponding.
  ///
  /// In en, this message translates to:
  /// **'Speaking…'**
  String get stateResponding;

  /// No description provided for @stateAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your confirmation'**
  String get stateAwaitingConfirmation;

  /// No description provided for @stateError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. You can try again or type.'**
  String get stateError;

  /// No description provided for @toolRunning.
  ///
  /// In en, this message translates to:
  /// **'Checking {what}…'**
  String toolRunning(String what);

  /// No description provided for @toolWhatBalance.
  ///
  /// In en, this message translates to:
  /// **'your balance'**
  String get toolWhatBalance;

  /// No description provided for @toolWhatTransactions.
  ///
  /// In en, this message translates to:
  /// **'your transactions'**
  String get toolWhatTransactions;

  /// No description provided for @toolWhatSpending.
  ///
  /// In en, this message translates to:
  /// **'your spending'**
  String get toolWhatSpending;

  /// No description provided for @toolWhatBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'your recipients'**
  String get toolWhatBeneficiaries;

  /// No description provided for @toolWhatTransfer.
  ///
  /// In en, this message translates to:
  /// **'the transfer details'**
  String get toolWhatTransfer;

  /// No description provided for @toolWhatNotifications.
  ///
  /// In en, this message translates to:
  /// **'your notifications'**
  String get toolWhatNotifications;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @muteVoice.
  ///
  /// In en, this message translates to:
  /// **'Mute voice'**
  String get muteVoice;

  /// No description provided for @unmuteVoice.
  ///
  /// In en, this message translates to:
  /// **'Unmute voice'**
  String get unmuteVoice;

  /// No description provided for @stopSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Stop speaking'**
  String get stopSpeaking;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get clearConversation;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get historyEmpty;

  /// No description provided for @historyPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Stored only on this device, encrypted. Amounts in cards are not stored.'**
  String get historyPrivacyNote;

  /// No description provided for @providerCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI'**
  String get providerCloud;

  /// No description provided for @providerLocal.
  ///
  /// In en, this message translates to:
  /// **'Basic mode'**
  String get providerLocal;

  /// Badge: the reply was produced by an on-device language model (e.g. Apple Intelligence); data stayed on the device.
  ///
  /// In en, this message translates to:
  /// **'On-device AI · private'**
  String get providerOnDeviceAi;

  /// No description provided for @fallbackNotice.
  ///
  /// In en, this message translates to:
  /// **'Preferred AI unavailable — answered by a backup'**
  String get fallbackNotice;

  /// No description provided for @tryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get tryAsking;

  /// No description provided for @suggestionBalance.
  ///
  /// In en, this message translates to:
  /// **'How much money do I have?'**
  String get suggestionBalance;

  /// No description provided for @suggestionExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain my last transaction'**
  String get suggestionExplain;

  /// No description provided for @suggestionSend.
  ///
  /// In en, this message translates to:
  /// **'Send 20,000 BIF to Jean'**
  String get suggestionSend;

  /// No description provided for @suggestionSpending.
  ///
  /// In en, this message translates to:
  /// **'How much did I spend this month?'**
  String get suggestionSpending;

  /// No description provided for @suggestionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Read my notifications'**
  String get suggestionNotifications;

  /// No description provided for @reviewAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Review & confirm'**
  String get reviewAndConfirm;

  /// No description provided for @draftCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer prepared — not sent'**
  String get draftCardTitle;

  /// No description provided for @chooseRecipientCard.
  ///
  /// In en, this message translates to:
  /// **'Who do you mean?'**
  String get chooseRecipientCard;

  /// No description provided for @sendToThisPerson.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} to {name}'**
  String sendToThisPerson(String amount, String name);

  /// No description provided for @voiceLanguageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Voice input in {language} is not available on this device. You can type your request below.'**
  String voiceLanguageUnsupported(String language);

  /// No description provided for @useFrenchVoice.
  ///
  /// In en, this message translates to:
  /// **'Use French voice'**
  String get useFrenchVoice;

  /// No description provided for @noSpeechHeard.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t hear anything. Tap the microphone and try again.'**
  String get noSpeechHeard;

  /// No description provided for @ttsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech playback in {language} is unavailable right now. You can read the reply on screen.'**
  String ttsUnavailable(String language);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @accessibilitySetting.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilitySetting;

  /// No description provided for @cloudAiSetting.
  ///
  /// In en, this message translates to:
  /// **'Use cloud AI (Gemini)'**
  String get cloudAiSetting;

  /// No description provided for @cloudAiDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows Google Gemini to process your requests, recent conversation, and selected banking details. Turning it off keeps AI replies on this device.'**
  String get cloudAiDescription;

  /// No description provided for @naturalVoiceSetting.
  ///
  /// In en, this message translates to:
  /// **'Natural voice (Gemini)'**
  String get naturalVoiceSetting;

  /// No description provided for @naturalVoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Online replies can be sent to Gemini via Firebase for natural speech. Replies from private on-device AI use the device voice.'**
  String get naturalVoiceDescription;

  /// No description provided for @cloudAiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI is not configured in this build. Sauti uses its on-device assistant.'**
  String get cloudAiNotConfigured;

  /// No description provided for @demoControls.
  ///
  /// In en, this message translates to:
  /// **'Demo controls'**
  String get demoControls;

  /// No description provided for @simulateOffline.
  ///
  /// In en, this message translates to:
  /// **'Simulate no connection'**
  String get simulateOffline;

  /// No description provided for @simulateOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows how Sauti behaves offline: cached data is labelled and transfers are blocked.'**
  String get simulateOfflineDescription;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @environmentDemo.
  ///
  /// In en, this message translates to:
  /// **'Environment: DEMO (simulated bank)'**
  String get environmentDemo;

  /// No description provided for @environmentLive.
  ///
  /// In en, this message translates to:
  /// **'Environment: Firebase sandbox'**
  String get environmentLive;

  /// No description provided for @accessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityTitle;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String textSizeValue(int percent);

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Stronger colours and borders for low vision.'**
  String get highContrastDescription;

  /// No description provided for @voiceConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Read replies aloud?'**
  String get voiceConsentTitle;

  /// No description provided for @voiceConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Sauti can speak your replies, including banking details that people nearby may hear. You can change this in Accessibility settings.'**
  String get voiceConsentBody;

  /// No description provided for @voiceConsentDecline.
  ///
  /// In en, this message translates to:
  /// **'Keep replies quiet'**
  String get voiceConsentDecline;

  /// No description provided for @voiceConsentAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow spoken replies'**
  String get voiceConsentAllow;

  /// No description provided for @voiceFeedback.
  ///
  /// In en, this message translates to:
  /// **'Read replies aloud'**
  String get voiceFeedback;

  /// No description provided for @speechSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speech speed'**
  String get speechSpeed;

  /// No description provided for @speechSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get speechSlow;

  /// No description provided for @speechNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speechNormal;

  /// No description provided for @speechFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get speechFast;

  /// No description provided for @simplifiedMode.
  ///
  /// In en, this message translates to:
  /// **'Simplified mode'**
  String get simplifiedMode;

  /// No description provided for @simplifiedModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Fewer items on screen and larger buttons.'**
  String get simplifiedModeDescription;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @previewText.
  ///
  /// In en, this message translates to:
  /// **'Preview: your balance is 250,000 BIF.'**
  String get previewText;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @kirundiDraftNote.
  ///
  /// In en, this message translates to:
  /// **'Kirundi translations are a first draft under review by native speakers.'**
  String get kirundiDraftNote;

  /// No description provided for @onDeviceAiSetting.
  ///
  /// In en, this message translates to:
  /// **'Private on-device AI (Gemini Nano)'**
  String get onDeviceAiSetting;

  /// No description provided for @onDeviceAiReady.
  ///
  /// In en, this message translates to:
  /// **'Ready. Your requests are understood on this phone and work without internet.'**
  String get onDeviceAiReady;

  /// No description provided for @onDeviceAiDownloadable.
  ///
  /// In en, this message translates to:
  /// **'Available for this device. Download it once (Wi-Fi recommended) to keep your requests on the phone.'**
  String get onDeviceAiDownloadable;

  /// No description provided for @onDeviceAiDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading the on-device model…'**
  String get onDeviceAiDownloading;

  /// No description provided for @onDeviceAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this device. Sauti uses cloud AI or basic mode instead.'**
  String get onDeviceAiUnavailable;

  /// No description provided for @onDeviceAiDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get onDeviceAiDownload;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'rn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'rn':
      return AppLocalizationsRn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
