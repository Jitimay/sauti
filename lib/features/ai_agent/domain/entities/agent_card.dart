import 'package:equatable/equatable.dart';

import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/bank_notification.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../../../banking/domain/entities/beneficiary.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../../../banking/domain/services/spending_analyzer.dart';
import '../../../banking/domain/services/transaction_explainer.dart';
import '../../../../core/money/money.dart';

/// Structured UI produced by tools. Cards are rendered from verified tool
/// output, never from model text, so figures on screen are always real.
sealed class AgentCard extends Equatable {
  const AgentCard();
}

final class BalanceCard extends AgentCard {
  const BalanceCard(this.accounts);
  final Fresh<List<Account>> accounts;
  @override
  List<Object?> get props => [accounts];
}

final class TransactionsCard extends AgentCard {
  const TransactionsCard(this.transactions);
  final Fresh<List<BankTransaction>> transactions;
  @override
  List<Object?> get props => [transactions];
}

final class TransactionDetailCard extends AgentCard {
  const TransactionDetailCard(this.explanation);
  final TransactionExplanation explanation;
  @override
  List<Object?> get props => [explanation];
}

final class SpendingCard extends AgentCard {
  const SpendingCard(this.summary);
  final Fresh<SpendingSummary> summary;
  @override
  List<Object?> get props => [summary];
}

final class NotificationsCard extends AgentCard {
  const NotificationsCard(this.notifications);
  final Fresh<List<BankNotification>> notifications;
  @override
  List<Object?> get props => [notifications];
}

final class BeneficiariesCard extends AgentCard {
  const BeneficiariesCard(this.beneficiaries);
  final List<Beneficiary> beneficiaries;
  @override
  List<Object?> get props => [beneficiaries];
}

/// A prepared, NOT executed transfer. Rendering offers "Review & confirm",
/// which leads to device authentication and explicit confirmation.
final class TransferDraftCard extends AgentCard {
  const TransferDraftCard(this.draft);
  final TransferDraft draft;
  @override
  List<Object?> get props => [draft];
}

final class RecipientChoiceCard extends AgentCard {
  const RecipientChoiceCard({required this.spokenName, required this.candidates, required this.amount});
  final String spokenName;
  final List<Beneficiary> candidates;
  final Money amount;
  @override
  List<Object?> get props => [spokenName, candidates, amount];
}
