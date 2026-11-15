import 'package:equatable/equatable.dart';

enum AuthMethod { deviceBiometricOrPasscode, accountPassword }

/// Proof that the *user* (not the AI) authenticated on this device for a
/// specific draft. Short-lived and bound to the draft's idempotency key.
final class TransferAuthorization extends Equatable {
  const TransferAuthorization({
    required this.draftIdempotencyKey,
    required this.method,
    required this.grantedAt,
    required this.validFor,
  });

  final String draftIdempotencyKey;
  final AuthMethod method;
  final DateTime grantedAt;
  final Duration validFor;

  bool isValidAt(DateTime now, String idempotencyKey) =>
      idempotencyKey == draftIdempotencyKey && now.isBefore(grantedAt.add(validFor)) && !now.isBefore(grantedAt);

  @override
  List<Object?> get props => [draftIdempotencyKey, method, grantedAt, validFor];
}
