import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum AccountType { current, savings, mobileWallet }

final class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.maskedNumber,
    required this.type,
    required this.balance,
    required this.availableBalance,
    this.institution = 'Sauti Demo Bank',
  });

  final String id;
  final String name;

  /// Only the last 4 digits are ever held client-side, e.g. "•••• 4821".
  final String maskedNumber;
  final AccountType type;
  final Money balance;
  final Money availableBalance;
  final String institution;

  Account copyWith({Money? balance, Money? availableBalance}) => Account(
        id: id,
        name: name,
        maskedNumber: maskedNumber,
        type: type,
        balance: balance ?? this.balance,
        availableBalance: availableBalance ?? this.availableBalance,
        institution: institution,
      );

  @override
  List<Object?> get props => [id, name, maskedNumber, type, balance, availableBalance, institution];
}
