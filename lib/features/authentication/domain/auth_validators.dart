import '../../../core/error/failure.dart';

/// Pure input validation shared by the BLoC and tests.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static FailureCode? email(String v) => _email.hasMatch(v.trim()) ? null : FailureCode.validation;

  /// ≥ 8 chars with at least one letter and one digit.
  static FailureCode? password(String v) =>
      v.length >= 8 && RegExp('[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v)
          ? null
          : FailureCode.authWeakPassword;

  static FailureCode? displayName(String v) => v.trim().length >= 2 ? null : FailureCode.validation;
}
