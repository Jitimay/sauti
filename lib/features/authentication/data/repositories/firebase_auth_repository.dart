import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// LIVE-mode authentication via Firebase Authentication (email/password).
/// Firebase persists the session securely per platform.
final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final fb.FirebaseAuth _auth;

  static AppUser? _map(fb.User? u) => u == null
      ? null
      : AppUser(
          id: u.uid,
          displayName: u.displayName ?? (u.email ?? '').split('@').first,
          email: u.email ?? '',
          isDemo: false,
        );

  static Failure _failure(fb.FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'invalid-email' => const AuthFailure(FailureCode.authInvalidCredentials),
        'user-not-found' => const AuthFailure(FailureCode.authUserNotFound),
        'email-already-in-use' => const AuthFailure(FailureCode.authEmailInUse),
        'weak-password' => const AuthFailure(FailureCode.authWeakPassword),
        'requires-recent-login' || 'user-token-expired' => const AuthFailure(FailureCode.authExpired),
        'network-request-failed' => const NetworkFailure(),
        _ => AuthFailure(FailureCode.unexpected, e.code),
      };

  Future<Result<T>> _guard<T>(Future<T> Function() f) async {
    try {
      return Ok(await f());
    } on fb.FirebaseAuthException catch (e) {
      return Err(_failure(e));
    } catch (e) {
      return Err(UnexpectedFailure(e.runtimeType.toString()));
    }
  }

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) => _guard(() async {
        final c = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
        return _map(c.user)!;
      });

  @override
  Future<Result<AppUser>> register({required String displayName, required String email, required String password}) =>
      _guard(() async {
        final c = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        await c.user!.updateDisplayName(displayName.trim());
        await c.user!.reload();
        return _map(_auth.currentUser)!;
      });

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<Result<void>> reauthenticate(String password) => _guard(() async {
        final u = _auth.currentUser;
        if (u == null || u.email == null) {
          throw fb.FirebaseAuthException(code: 'user-not-found');
        }
        await u.reauthenticateWithCredential(fb.EmailAuthProvider.credential(email: u.email!, password: password));
      });

  @override
  Future<Result<void>> signOut() => _guard(_auth.signOut);
}
