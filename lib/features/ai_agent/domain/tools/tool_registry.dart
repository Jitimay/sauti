import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../entities/tool_call.dart';
import '../entities/tool_spec.dart';
import 'agent_tool.dart';

/// Central gate between AI output and banking capabilities.
///
/// For every request it: (1) resolves a registered tool, (2) checks the
/// caller is allowed to invoke it, (3) strictly validates arguments, (4)
/// executes via domain use cases, (5) logs an audit record without secrets.
final class ToolRegistry {
  ToolRegistry(List<AgentTool<dynamic, dynamic>> tools, {this._logger = const PrintLogger()})
      : _tools = {for (final t in tools) t.spec.name: t} {
    assert(_tools.length == tools.length, 'duplicate tool names');
  }

  final Map<String, AgentTool<dynamic, dynamic>> _tools;
  final AppLogger _logger;
  final List<ToolExecutionRecord> _audit = [];

  /// Read-only audit trail for this session (most recent last).
  List<ToolExecutionRecord> get auditTrail => List.unmodifiable(_audit);

  /// Specs a given caller may see. Gesture-only tools are never offered to AI.
  List<ToolSpec> specsFor(ToolCaller caller, Set<ToolPermission> granted) => _tools.values
      .map((t) => t.spec)
      .where((s) => _permitted(s.permission, caller, granted))
      .toList(growable: false);

  bool _permitted(ToolPermission p, ToolCaller caller, Set<ToolPermission> granted) {
    if (p == ToolPermission.userGestureOnly) return caller == ToolCaller.user;
    return granted.contains(p);
  }

  Future<ToolExecutionRecord> execute(ToolCallRequest request, ToolContext context) async {
    final sw = Stopwatch()..start();
    ToolExecutionRecord done(ToolExecutionStatus s, {Map<String, Object?>? payload, Object? output, Failure? failure, tool}) {
      final rec = ToolExecutionRecord(
        request: request,
        status: s,
        modelPayload: payload ?? {'status': s.name, if (failure != null) 'error': failure.code.name},
        output: output,
        card: output == null || tool == null ? null : (tool as AgentTool).toCard(output),
        failure: failure,
        duration: sw.elapsed,
      );
      _audit.add(rec);
      // Log tool name, caller and outcome only — never arguments (may hold PII).
      _logger.info('tool', '${request.name} by ${context.caller.name} → ${s.name}'
          '${failure == null ? '' : ' (${failure.code.name})'} in ${sw.elapsedMilliseconds}ms');
      return rec;
    }

    final tool = _tools[request.name];
    if (tool == null) {
      return done(ToolExecutionStatus.rejected,
          failure: const PermissionFailure(FailureCode.toolNotPermitted, 'unknown tool'));
    }
    if (!_permitted(tool.spec.permission, context.caller, context.granted)) {
      return done(ToolExecutionStatus.rejected,
          failure: const PermissionFailure(FailureCode.toolNotPermitted, 'caller not permitted'));
    }

    final dynamic input;
    try {
      input = tool.parse(request.args);
    } on ToolArgumentException catch (e) {
      return done(ToolExecutionStatus.rejected, failure: ValidationFailure(e.code, e.message));
    }

    try {
      final Result<dynamic> result = await tool.execute(input, context);
      return switch (result) {
        Ok(:final value) => done(
            ToolExecutionStatus.succeeded,
            payload: {'status': 'ok', ...tool.toModelPayload(value)},
            output: value,
            tool: tool,
          ),
        Err(:final failure) => done(ToolExecutionStatus.failed, failure: failure),
      };
    } catch (e) {
      return done(ToolExecutionStatus.failed, failure: UnexpectedFailure('tool threw ${e.runtimeType}'));
    }
  }
}
