import 'package:equatable/equatable.dart';

final class Beneficiary extends Equatable {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.maskedAccount,
    required this.institution,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String maskedAccount;
  final String institution;

  /// Alternative names the user may say ("Maman", "Jean-Paul").
  final List<String> aliases;

  @override
  List<Object?> get props => [id, name, maskedAccount, institution, aliases];
}
