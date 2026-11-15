import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits the current user (or null) immediately, then on every change.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<Result<AppUser>> signIn({required String email, required String password});

  Future<Result<AppUser>> register({required String displayName, required String email, required String password});

  Future<Result<void>> sendPasswordReset(String email);

  /// Re-verifies the password of the *current* user (used to authorize
  /// transfers when device biometrics are unavailable). Never stores it.
  Future<Result<void>> reauthenticate(String password);

  Future<Result<void>> signOut();
}
