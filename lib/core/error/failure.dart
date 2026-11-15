/// Domain-level failures. Pure Dart: no Flutter / Firebase imports.
///
/// Every failure carries a stable [code] so the presentation layer can map it
/// to a localized, user-facing message without string matching.
sealed class Failure {
  const Failure(this.code, [this.debugMessage]);

  final FailureCode code;

  /// Developer-facing detail. Never shown to users, never sent to an LLM.
  final String? debugMessage;

  @override
  String toString() => '$runtimeType(${code.name}${debugMessage == null ? '' : ': $debugMessage'})';
}

enum FailureCode {
  network,
  unauthorized,
  authInvalidCredentials,
  authEmailInUse,
  authWeakPassword,
  authUserNotFound,
  authExpired,
  validation,
  invalidAmount,
  limitExceeded,
  insufficientFunds,
  beneficiaryNotFound,
  beneficiaryAmbiguous,
  notFound,
  duplicateRequest,
  transferRejected,
  offlineNotAllowed,
  aiUnavailable,
  toolNotPermitted,
  voiceUnavailable,
  voicePermissionDenied,
  voiceLanguageUnsupported,
  server,
  unexpected,
}

final class NetworkFailure extends Failure {
  const NetworkFailure([String? debug]) : super(FailureCode.network, debug);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.code, [super.debugMessage]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.code, [super.debugMessage]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([String? debug]) : super(FailureCode.notFound, debug);
}

final class TransferFailure extends Failure {
  const TransferFailure(super.code, [super.debugMessage]);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.code, [super.debugMessage]);
}

final class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure(super.code, [super.debugMessage]);
}

final class ServerFailure extends Failure {
  const ServerFailure([String? debug]) : super(FailureCode.server, debug);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String? debug]) : super(FailureCode.unexpected, debug);
}
