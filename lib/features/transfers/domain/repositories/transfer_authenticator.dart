import '../../../../core/error/result.dart';
import '../entities/transfer_authorization.dart';

/// Capabilities of the device authenticator.
final class AuthenticatorAvailability {
  const AuthenticatorAvailability({required this.deviceAuthAvailable});
  final bool deviceAuthAvailable;
}

/// Authenticates the human user before a transfer. Never via voice, never
/// via the AI model, and PINs/passwords are never stored by Sauti.
abstract interface class TransferAuthenticator {
  Future<AuthenticatorAvailability> availability();

  /// Platform biometric / device passcode prompt.
  Future<Result<AuthMethod>> authenticateWithDevice({required String reason});

  /// Typed account-password re-authentication (fallback when no device auth).
  /// The password is passed straight to the auth provider and discarded.
  Future<Result<AuthMethod>> authenticateWithPassword(String password);
}
