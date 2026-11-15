import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// DEMO-mode authentication. Credentials are published in the README for
/// judges; nothing here protects real data because no real data exists.
///
/// Only a non-sensitive "demo session active" flag is persisted.
final class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._prefs) {
    if (_prefs.getBool(_sessionKey) ?? false) {
      _user = AppUser(
        id: 'demo-user',
        displayName: _prefs.getString(_nameKey) ?? demoUser.displayName,
        email: _prefs.getString(_emailKey) ?? demoEmail,
        isDemo: true,
      );
    }
  }

  static const demoEmail = 'demo@sauti.app';
  static const demoPassword = 'Sauti2026';
  static const demoUser = AppUser(id: 'demo-user', displayName: 'Ange Uwimana', email: demoEmail, isDemo: true);

  static const _sessionKey = 'demo_session_active';
  static const _nameKey = 'demo_session_name';
  static const _emailKey = 'demo_session_email';

  final SharedPreferences _prefs;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// In demo mode, registered accounts live only for this app session.
  final Map<String, ({String name, String password})> _registered = {};

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  Future<void> _setUser(AppUser? u) async {
    _user = u;
    if (u == null) {
      await _prefs.remove(_sessionKey);
      await _prefs.remove(_nameKey);
      await _prefs.remove(_emailKey);
    } else {
      await _prefs.setBool(_sessionKey, true);
      await _prefs.setString(_nameKey, u.displayName);
      await _prefs.setString(_emailKey, u.email);
    }
    _controller.add(u);
  }

  String? _passwordFor(String email) =>
      email == demoEmail ? demoPassword : _registered[email]?.password;

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) async {
    final e = email.trim().toLowerCase();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_passwordFor(e) != password) return const Err(AuthFailure(FailureCode.authInvalidCredentials));
    final user = e == demoEmail
        ? demoUser
        : AppUser(id: 'demo-user', displayName: _registered[e]!.name, email: e, isDemo: true);
    await _setUser(user);
    return Ok(user);
  }

  @override
  Future<Result<AppUser>> register({required String displayName, required String email, required String password}) async {
    final e = email.trim().toLowerCase();
    if (e == demoEmail || _registered.containsKey(e)) return const Err(AuthFailure(FailureCode.authEmailInUse));
    _registered[e] = (name: displayName.trim(), password: password);
    final user = AppUser(id: 'demo-user', displayName: displayName.trim(), email: e, isDemo: true);
    await _setUser(user);
    return Ok(user);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    // Demo: no email is sent. The UI states this explicitly.
    return const Ok(null);
  }

  @override
  Future<Result<void>> reauthenticate(String password) async {
    final u = _user;
    if (u == null) return const Err(AuthFailure(FailureCode.unauthorized));
    return _passwordFor(u.email) == password
        ? const Ok(null)
        : const Err(AuthFailure(FailureCode.authInvalidCredentials));
  }

  @override
  Future<Result<void>> signOut() async {
    await _setUser(null);
    return const Ok(null);
  }
}
