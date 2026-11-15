import 'package:material_ui/material_ui.dart';

import '../../features/banking/domain/entities/account.dart';
import '../../features/banking/domain/entities/bank_notification.dart';
import '../../features/banking/domain/entities/bank_transaction.dart';
import '../../l10n/app_localizations.dart';
import '../error/failure.dart';
import '../money/money.dart';
import '../money/money_formatter.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get langCode => Localizations.localeOf(this).languageCode;
  String money(Money m, {bool signed = false}) => MoneyFormatter.format(m, locale: langCode, signed: signed);
}

extension FailureL10n on FailureCode {
  String message(AppLocalizations l) => switch (this) {
        FailureCode.network => l.failureNetwork,
        FailureCode.unauthorized => l.failureUnauthorized,
        FailureCode.authInvalidCredentials => l.failureInvalidCredentials,
        FailureCode.authEmailInUse => l.failureEmailInUse,
        FailureCode.authWeakPassword => l.failureWeakPassword,
        FailureCode.authUserNotFound => l.failureUserNotFound,
        FailureCode.authExpired => l.failureAuthExpired,
        FailureCode.validation => l.failureValidation,
        FailureCode.invalidAmount => l.failureInvalidAmount,
        FailureCode.limitExceeded => l.failureLimitExceeded,
        FailureCode.insufficientFunds => l.failureInsufficientFunds,
        FailureCode.beneficiaryNotFound => l.failureBeneficiaryNotFound,
        FailureCode.beneficiaryAmbiguous => l.failureBeneficiaryAmbiguous,
        FailureCode.notFound => l.failureNotFound,
        FailureCode.duplicateRequest => l.failureDuplicate,
        FailureCode.transferRejected => l.failureTransferRejected,
        FailureCode.offlineNotAllowed => l.failureOfflineNotAllowed,
        FailureCode.aiUnavailable => l.failureAiUnavailable,
        FailureCode.toolNotPermitted => l.failureToolNotPermitted,
        FailureCode.voiceUnavailable => l.failureVoiceUnavailable,
        FailureCode.voicePermissionDenied => l.failureVoicePermission,
        FailureCode.voiceLanguageUnsupported => l.failureVoiceLanguage,
        FailureCode.server => l.failureServer,
        FailureCode.unexpected => l.failureUnexpected,
      };
}

extension CategoryL10n on TransactionCategory {
  String label(AppLocalizations l) => switch (this) {
        TransactionCategory.income => l.categoryIncome,
        TransactionCategory.transfer => l.categoryTransfer,
        TransactionCategory.transport => l.categoryTransport,
        TransactionCategory.groceries => l.categoryGroceries,
        TransactionCategory.utilities => l.categoryUtilities,
        TransactionCategory.airtime => l.categoryAirtime,
        TransactionCategory.health => l.categoryHealth,
        TransactionCategory.education => l.categoryEducation,
        TransactionCategory.fees => l.categoryFees,
        TransactionCategory.other => l.categoryOther,
      };

  IconData get icon => switch (this) {
        TransactionCategory.income => Icons.south_west_rounded,
        TransactionCategory.transfer => Icons.swap_horiz_rounded,
        TransactionCategory.transport => Icons.two_wheeler_rounded,
        TransactionCategory.groceries => Icons.shopping_basket_rounded,
        TransactionCategory.utilities => Icons.bolt_rounded,
        TransactionCategory.airtime => Icons.phone_android_rounded,
        TransactionCategory.health => Icons.local_hospital_rounded,
        TransactionCategory.education => Icons.school_rounded,
        TransactionCategory.fees => Icons.receipt_long_rounded,
        TransactionCategory.other => Icons.more_horiz_rounded,
      };
}

extension StatusL10n on TransactionStatus {
  String label(AppLocalizations l) => switch (this) {
        TransactionStatus.completed => l.statusCompleted,
        TransactionStatus.pending => l.statusPending,
        TransactionStatus.failed => l.statusFailed,
      };
}

extension AccountTypeL10n on AccountType {
  String label(AppLocalizations l) => switch (this) {
        AccountType.current => l.accountTypeCurrent,
        AccountType.savings => l.accountTypeSavings,
        AccountType.mobileWallet => l.accountTypeWallet,
      };
}

extension NotificationL10n on BankNotification {
  String text(BuildContext context) {
    final l = context.l10n;
    return switch (kind) {
      NotificationKind.paymentReceived => l.notifPaymentReceived(context.money(amount!), counterparty ?? ''),
      NotificationKind.transferSent => l.notifTransferSent(context.money(amount!), counterparty ?? ''),
      NotificationKind.security => detail == 'new_device_login' ? l.notifSecurityNewDevice : l.notifSecurityGeneric,
      NotificationKind.reminder => detail == 'utility_bill_due' ? l.notifReminderBill : l.notifReminderGeneric,
    };
  }

  IconData get icon => switch (kind) {
        NotificationKind.paymentReceived => Icons.south_west_rounded,
        NotificationKind.transferSent => Icons.north_east_rounded,
        NotificationKind.security => Icons.shield_outlined,
        NotificationKind.reminder => Icons.event_note_rounded,
      };
}

/// Locale-aware short date formatting without depending on intl locale data
/// for Kirundi.
String shortDate(BuildContext context, DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return context.langCode == 'en' ? '$dd/$mm/${d.year}' : '$dd.$mm.${d.year}';
}

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
