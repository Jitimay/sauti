import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/agent_bloc.dart';

/// Read-only transcript grouped by day, stored encrypted on device.
class ConversationHistoryPage extends StatelessWidget {
  const ConversationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final messages = context.select<AgentBloc, List<ChatMessage>>((b) => b.state.messages);
    final st = StatusColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          IconButton(
            tooltip: l.clearConversation,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: messages.isEmpty ? null : () => context.read<AgentBloc>().add(const AgentConversationCleared()),
          ),
        ],
      ),
      body: messages.isEmpty
          ? EmptyView(message: l.historyEmpty, icon: Icons.forum_outlined)
          : ResponsiveBody(
              child: ListView(children: [
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: st.muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.historyPrivacyNote, style: Theme.of(context).textTheme.bodySmall)),
                ]),
                const SizedBox(height: 8),
                for (var i = 0; i < messages.length; i++) ...[
                  if (i == 0 || !_sameDay(messages[i - 1].timestamp, messages[i].timestamp))
                    SectionHeader(shortDate(context, messages[i].timestamp)),
                  MergeSemantics(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(messages[i].role == ChatRole.user ? Icons.person_rounded : Icons.graphic_eq_rounded),
                      title: Text(messages[i].role == ChatRole.user ? l.you : l.appName,
                          style: Theme.of(context).textTheme.labelLarge),
                      subtitle: Text(messages[i].text, style: Theme.of(context).textTheme.bodyLarge),
                      trailing: Text(hhmm(messages[i].timestamp), style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                ],
              ]),
            ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
