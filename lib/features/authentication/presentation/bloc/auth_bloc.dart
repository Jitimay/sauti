import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/auth_validators.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// ---- Events ----
sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class AuthenticationStatusChanged extends AuthEvent {
  const AuthenticationStatusChanged(this.user);
  final AppUser? user;
  @override
  List<Object?> get props => [user];
}

final class SignInRequested extends AuthEvent {
  const SignInRequested(this.email, this.password);
  final String email;
  final String password;
  @override
  List<Object?> get props => [email]; // never include password in props/logs
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested(this.displayName, this.email, this.password);
  final String displayName;
  final String email;
  final String password;
  @override
  List<Object?> get props => [displayName, email];
}

final class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

final class AuthFormReset extends AuthEvent {
  const AuthFormReset();
}

// ---- State ----
enum AuthenticationStatus { unknown, authenticated, unauthenticated }

enum AuthFormStatus { idle, submitting, success, failure }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthenticationStatus.unknown,
    this.user,
    this.form = AuthFormStatus.idle,
    this.failure,
    this.resetEmailSent = false,
  });

  final AuthenticationStatus status;
  final AppUser? user;
  final AuthFormStatus form;
  final FailureCode? failure;
  final bool resetEmailSent;

  AuthState copyWith({
    AuthenticationStatus? status,
    AppUser? Function()? user,
    AuthFormStatus? form,
    FailureCode? Function()? failure,
    bool? resetEmailSent,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user != null ? user() : this.user,
        form: form ?? this.form,
        failure: failure != null ? failure() : this.failure,
        resetEmailSent: resetEmailSent ?? this.resetEmailSent,
      );

  @override
  List<Object?> get props => [status, user, form, failure, resetEmailSent];
}

// ---- Bloc ----
final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthenticationStatusChanged>(_onStatus);
    on<SignInRequested>(_onSignIn, transformer: droppable());
    on<RegisterRequested>(_onRegister, transformer: droppable());
    on<PasswordResetRequested>(_onReset, transformer: droppable());
    on<SignOutRequested>(_onSignOut, transformer: droppable());
    on<AuthFormReset>((e, emit) => emit(state.copyWith(form: AuthFormStatus.idle, failure: () => null, resetEmailSent: false)));
    _sub = _repo.authStateChanges().listen((u) => add(AuthenticationStatusChanged(u)));
  }

  final AuthRepository _repo;
  late final StreamSubscription<AppUser?> _sub;

  void _onStatus(AuthenticationStatusChanged e, Emitter<AuthState> emit) => emit(state.copyWith(
        status: e.user == null ? AuthenticationStatus.unauthenticated : AuthenticationStatus.authenticated,
        user: () => e.user,
      ));

  Future<void> _submit(Emitter<AuthState> emit, Future<Result<Object?>> Function() action) async {
    emit(state.copyWith(form: AuthFormStatus.submitting, failure: () => null));
    final r = await action();
    switch (r) {
      case Ok():
        emit(state.copyWith(form: AuthFormStatus.success));
      case Err(:final failure):
        emit(state.copyWith(form: AuthFormStatus.failure, failure: () => failure.code));
    }
  }

  Future<void> _onSignIn(SignInRequested e, Emitter<AuthState> emit) async {
    final invalid = AuthValidators.email(e.email) ?? (e.password.isEmpty ? FailureCode.validation : null);
    if (invalid != null) {
      return emit(state.copyWith(form: AuthFormStatus.failure, failure: () => FailureCode.authInvalidCredentials));
    }
    await _submit(emit, () => _repo.signIn(email: e.email, password: e.password));
  }

  Future<void> _onRegister(RegisterRequested e, Emitter<AuthState> emit) async {
    final invalid = AuthValidators.displayName(e.displayName) ??
        AuthValidators.email(e.email) ??
        AuthValidators.password(e.password);
    if (invalid != null) return emit(state.copyWith(form: AuthFormStatus.failure, failure: () => invalid));
    await _submit(emit, () => _repo.register(displayName: e.displayName, email: e.email, password: e.password));
  }

  Future<void> _onReset(PasswordResetRequested e, Emitter<AuthState> emit) async {
    final invalid = AuthValidators.email(e.email);
    if (invalid != null) return emit(state.copyWith(form: AuthFormStatus.failure, failure: () => invalid));
    emit(state.copyWith(form: AuthFormStatus.submitting, failure: () => null));
    final r = await _repo.sendPasswordReset(e.email);
    // Same message whether or not the account exists (prevents enumeration).
    emit(r.isOk || r.failureOrNull?.code == FailureCode.authUserNotFound
        ? state.copyWith(form: AuthFormStatus.success, resetEmailSent: true)
        : state.copyWith(form: AuthFormStatus.failure, failure: () => r.failureOrNull!.code));
  }

  Future<void> _onSignOut(SignOutRequested e, Emitter<AuthState> emit) async {
    final r = await _repo.signOut();
    if (r case Err(:final failure)) emit(state.copyWith(failure: () => failure.code));
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
