import '../../../../core/money/money.dart';

/// Business limits for transfers. Enforced client-side for UX and again on
/// the server (simulated bank / Cloud Function) for security.
final class TransferPolicy {
  const TransferPolicy({
    required this.minimum,
    required this.perTransferLimit,
    required this.dailyLimit,
    required this.flatFee,
    this.authorizationValidity = const Duration(minutes: 2),
  });

  static const bifDefault = TransferPolicy(
    minimum: Money.bif(500),
    perTransferLimit: Money.bif(2000000),
    dailyLimit: Money.bif(5000000),
    flatFee: Money.bif(0),
  );

  final Money minimum;
  final Money perTransferLimit;
  final Money dailyLimit;
  final Money flatFee;

  /// How long a successful device authentication authorizes submission.
  final Duration authorizationValidity;
}
