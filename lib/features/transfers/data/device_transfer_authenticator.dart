import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../authentication/domain/repositories/auth_repository.dart';
import '../domain/entities/transfer_authorization.dart';
import '../domain/repositories/transfer_authenticator.dart';

/// Device biometric/passcode via local_auth, with typed account-password
/// re-authentication as fallback. No PIN is ever spoken or stored.
final class DeviceTransferAuthenticator implements TransferAuthenticator {
  DeviceTransferAuthenticator(this._localAuth, this._auth);

  final LocalAuthentication _localAuth;
  final AuthRepository _auth;

  @override
  Future<AuthenticatorAvailability> availability() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      return AuthenticatorAvailability(deviceAuthAvailable: supported);
    } catch (_) {
      return const AuthenticatorAvailability(deviceAuthAvailable: false);
    }
  }

  @override
  Future<Result<AuthMethod>> authenticateWithDevice({required String reason}) async {
    try {
      final ok = await _localAuth.authenticate(localizedReason: reason, biometricOnly: false);
      return ok
          ? const Ok(AuthMethod.deviceBiometricOrPasscode)
          : const Err(AuthFailure(FailureCode.authInvalidCredentials, 'device auth declined'));
    } on PlatformException catch (e) {
      return Err(AuthFailure(FailureCode.unexpected, 'local_auth: ${e.code}'));
    } catch (e) {
      return Err(AuthFailure(FailureCode.unexpected, 'local_auth: ${e.runtimeType}'));
    }
  }

  @override
  Future<Result<AuthMethod>> authenticateWithPassword(String password) async {
    final r = await _auth.reauthenticate(password);
    return r.map((_) => AuthMethod.accountPassword);
  }
}
