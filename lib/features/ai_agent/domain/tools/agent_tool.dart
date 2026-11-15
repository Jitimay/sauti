import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../entities/agent_card.dart';
import '../entities/tool_spec.dart';

/// Thrown by [AgentTool.parse] when model/engine-supplied args are invalid.
final class ToolArgumentException implements Exception {
  const ToolArgumentException(this.code, this.message);
  final FailureCode code;
  final String message;
  @override
  String toString() => 'ToolArgumentException(${code.name}: $message)';
}

/// Drafts created during this conversation. Tools that reference a draft can
/// only reference one that the app itself created — never a model-invented ID.
final class SessionDraftStore {
  final Map<String, TransferDraft> _drafts = {};
  void put(TransferDraft d) => _drafts[d.id] = d;
  TransferDraft? get(String id) => _drafts[id];
  TransferDraft? get latest => _drafts.values.lastOrNull;
  Set<String> get ids => _drafts.keys.toSet();
  void remove(String id) => _drafts.remove(id);
  void clear() => _drafts.clear();
}

final class ToolContext {
  const ToolContext({
    required this.caller,
    required this.language,
    required this.granted,
    required this.drafts,
  });

  final ToolCaller caller;
  final AppLanguage language;
  final Set<ToolPermission> granted;
  final SessionDraftStore drafts;
}

/// A typed, validated, permissioned agent capability.
///
/// [I] is the parsed input; [O] is the typed output.
abstract base class AgentTool<I, O> {
  const AgentTool();

  ToolSpec get spec;

  /// Strictly parses untrusted args. Must reject unknown keys and wrong types.
  I parse(Map<String, Object?> args);

  Future<Result<O>> execute(I input, ToolContext context);

  /// Data-minimised projection safe to share with a cloud model.
  Map<String, Object?> toModelPayload(O output);

  AgentCard? toCard(O output) => null;

  // ---- Shared strict parsing helpers ----

  void rejectUnknown(Map<String, Object?> args) {
    final allowed = spec.params.map((p) => p.name).toSet();
    final unknown = args.keys.where((k) => !allowed.contains(k));
    if (unknown.isNotEmpty) {
      throw ToolArgumentException(FailureCode.validation, 'unknown argument(s): ${unknown.join(', ')}');
    }
  }

  String? optString(Map<String, Object?> args, String key, {int maxLength = 80}) {
    final v = args[key];
    if (v == null) return null;
    if (v is! String) throw ToolArgumentException(FailureCode.validation, '$key must be a string');
    final s = v.trim();
    if (s.length > maxLength) throw ToolArgumentException(FailureCode.validation, '$key too long');
    return s.isEmpty ? null : s;
  }

  String reqString(Map<String, Object?> args, String key, {int maxLength = 80}) =>
      optString(args, key, maxLength: maxLength) ??
      (throw ToolArgumentException(FailureCode.validation, '$key is required'));

  /// Accepts ints, integral doubles (JSON numbers), or digit strings.
  int? optInt(Map<String, Object?> args, String key, {int? min, int? max}) {
    final v = args[key];
    if (v == null) return null;
    final int n;
    if (v is int) {
      n = v;
    } else if (v is double && v == v.truncateToDouble() && v.isFinite) {
      n = v.toInt();
    } else if (v is String && RegExp(r'^\d{1,12}$').hasMatch(v.trim())) {
      n = int.parse(v.trim());
    } else {
      throw ToolArgumentException(FailureCode.validation, '$key must be an integer');
    }
    if ((min != null && n < min) || (max != null && n > max)) {
      throw ToolArgumentException(FailureCode.validation, '$key out of range');
    }
    return n;
  }

  T? optEnum<T extends Enum>(Map<String, Object?> args, String key, List<T> values) {
    final s = optString(args, key, maxLength: 40);
    if (s == null) return null;
    return values.where((v) => v.name == s).firstOrNull ??
        (throw ToolArgumentException(FailureCode.validation, '$key has invalid value'));
  }
}
