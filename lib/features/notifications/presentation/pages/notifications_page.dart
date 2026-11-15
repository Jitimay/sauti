import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../settings/presentation/bloc/accessibility_bloc.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';
import '../../../voice/presentation/bloc/voice_bloc.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => NotificationsBloc(sl(), sl())..add(const NotificationsLoadRequested()),
        child: PopScope(
          onPopInvokedWithResult: (_, _) =>
              context.read<DashboardBloc>().add(const DashboardLoadRequested(silent: true)),
          child: Scaffold(
            appBar: AppBar(title: Text(context.l10n.notificationsTitle)),
            body: Column(children: [
              const OfflineBanner(),
              Expanded(
                child: BlocBuilder<NotificationsBloc, NotificationsState>(builder: (context, s) {
                  final l = context.l10n;
                  return switch (s.status) {
                    ViewStatus.failure => ErrorView(
                        failure: s.failure!,
                        onRetry: () => context.read<NotificationsBloc>().add(const NotificationsLoadRequested())),
                    ViewStatus.empty => EmptyView(message: l.noNotifications, icon: Icons.notifications_none_rounded),
                    ViewStatus.success => ResponsiveBody(
                        child: ListView(children: [
                          const SizedBox(height: 8),
                          Align(alignment: Alignment.centerLeft, child: FreshnessBadge(s.items!)),
                          const SizedBox(height: 8),
                          for (final n in s.items!.data)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    MergeSemantics(
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Icon(n.icon, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            if (!n.read)
                                              Text(l.unread.toUpperCase(),
                                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                                            Text(n.text(context),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                    fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text('${shortDate(context, n.timestamp)} ${hhmm(n.timestamp)}',
                                                style: Theme.of(context).textTheme.bodySmall),
                                          ]),
                                        ),
                                      ]),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(spacing: 8, children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.volume_up_rounded),
                                        label: Text(l.readAloud),
                                        onPressed: () => context.read<VoiceBloc>().add(SpeechPlaybackStarted(
                                              n.text(context),
                                              language: context.read<PreferencesCubit>().state.language,
                                              rate: context.read<AccessibilityBloc>().state.speechRate,
                                            )),
                                      ),
                                      if (!n.read)
                                        TextButton.icon(
                                          icon: const Icon(Icons.done_rounded),
                                          label: Text(l.markAsRead),
                                          onPressed: () => context.read<NotificationsBloc>().add(NotificationMarkedRead(n.id)),
                                        ),
                                    ]),
                                  ]),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    _ => const LoadingView(),
                  };
                }),
              ),
            ]),
          ),
        ),
      );
}
