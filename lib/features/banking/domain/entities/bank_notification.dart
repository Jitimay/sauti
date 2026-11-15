import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum NotificationKind { paymentReceived, transferSent, security, reminder }

/// Notifications are stored as structured facts (kind + parameters) and
/// rendered in the user's language at display/speech time.
final class BankNotification extends Equatable {
  const BankNotification({
    required this.id,
    required this.kind,
    required this.timestamp,
    this.amount,
    this.counterparty,
    this.detail,
    this.read = false,
    this.transactionId,
  });

  final String id;
  final NotificationKind kind;
  final DateTime timestamp;
  final Money? amount;
  final String? counterparty;

  /// Short machine key for reminders/security events, e.g. `new_device_login`.
  final String? detail;
  final bool read;
  final String? transactionId;

  BankNotification markRead() => BankNotification(
        id: id,
        kind: kind,
        timestamp: timestamp,
        amount: amount,
        counterparty: counterparty,
        detail: detail,
        read: true,
        transactionId: transactionId,
      );

  @override
  List<Object?> get props => [id, kind, timestamp, amount, counterparty, detail, read, transactionId];
}
