import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import 'agent_card.dart';

/// A request (from a model or the local engine) to run a tool. Arguments are
/// untrusted until parsed and validated by the tool.
final class ToolCallRequest extends Equatable {
  const ToolCallRequest({required this.id, required this.name, required this.args});
  final String id;
  final String name;
  final Map<String, Object?> args;
  @override
  List<Object?> get props => [id, name, args];
}

enum ToolExecutionStatus { succeeded, rejected, failed }

/// Audit record for one tool execution.
final class ToolExecutionRecord extends Equatable {
  const ToolExecutionRecord({
    required this.request,
    required this.status,
    required this.modelPayload,
    required this.duration,
    this.output,
    this.card,
    this.failure,
  });

  final ToolCallRequest request;
  final ToolExecutionStatus status;

  /// Data-minimised result that may be shared with an AI model.
  final Map<String, Object?> modelPayload;

  /// Typed output for local composition (never serialized to a model).
  final Object? output;
  final AgentCard? card;
  final Failure? failure;
  final Duration duration;

  bool get ok => status == ToolExecutionStatus.succeeded;

  @override
  List<Object?> get props => [request, status, modelPayload, output, card, failure, duration];
}
