import 'package:equatable/equatable.dart';

enum ToolParamType { string, integer, enumeration }

/// Provider-neutral parameter schema; adapters translate it (e.g. to
/// Firebase AI `Schema`).
final class ToolParam extends Equatable {
  const ToolParam({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
    this.enumValues = const [],
    this.minimum,
    this.maximum,
  });

  final String name;
  final ToolParamType type;
  final String description;
  final bool required;
  final List<String> enumValues;
  final int? minimum;
  final int? maximum;

  @override
  List<Object?> get props => [name, type, description, required, enumValues, minimum, maximum];
}

enum ToolPermission {
  readAccounts,
  readTransactions,
  readBeneficiaries,
  readNotifications,
  prepareTransfer,

  /// Can never be invoked by an AI model or intent engine — only by a direct
  /// user gesture in the UI.
  userGestureOnly,
}

/// Who is asking for a tool to run.
enum ToolCaller { cloudModel, onDeviceModel, localEngine, user }

final class ToolSpec extends Equatable {
  const ToolSpec({
    required this.name,
    required this.description,
    required this.params,
    required this.permission,
  });

  final String name;
  final String description;
  final List<ToolParam> params;
  final ToolPermission permission;

  @override
  List<Object?> get props => [name, description, params, permission];
}
