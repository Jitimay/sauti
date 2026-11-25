import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
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

/// Screen 11: Notifications with circular status icons, amount badges,
/// and "Mark all as read" bottom link.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => NotificationsBloc(sl(), sl())..add(const NotificationsLoadRequested()),
        child: PopScope(
          onPopInvokedWithResult: (_, _) =>
              context.read<DashboardBloc>().add(const DashboardLoadRequested(silent: true)),
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.notificationsTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  tooltip: 'Done',
                  icon: const Icon(Icons.done_all_rounded),
                  onPressed: () {
                    // Mark notifications read
                  },
                ),
              ],
            ),
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
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          children: [
                            Align(alignment: Alignment.centerLeft, child: FreshnessBadge(s.items!)),
                            const SizedBox(height: 12),
                            for (final n in s.items!.data)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Card(
                                  elevation: 0.5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Radii.lg),
                                    side: const BorderSide(color: AppColors.line),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        MergeSemantics(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _NotificationIconBubble(n: n),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            n.text(context),
                                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                                  fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                                                  color: AppColors.ink,
                                                                ),
                                                          ),
                                                        ),
                                                        if (!n.read)
                                                          Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration: const BoxDecoration(
                                                              color: AppColors.blue,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${shortDate(context, n.timestamp)} · ${hhmm(n.timestamp)}',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: AppColors.muted,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.volume_up_rounded, size: 18),
                                              label: Text(l.readAloud, style: const TextStyle(fontSize: 13)),
                                              onPressed: () => context.read<VoiceBloc>().add(SpeechPlaybackStarted(
                                                    n.text(context),
                                                    language: context.read<PreferencesCubit>().state.language,
                                                    rate: context.read<AccessibilityBloc>().state.speechRate,
                                                  )),
                                            ),
                                            if (!n.read)
                                              TextButton.icon(
                                                icon: const Icon(Icons.done_rounded, size: 18),
                                                label: Text(l.markAsRead, style: const TextStyle(fontSize: 13)),
                                                onPressed: () =>
                                                    context.read<NotificationsBloc>().add(NotificationMarkedRead(n.id)),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  for (final n in s.items!.data) {
                                    if (!n.read) {
                                      context.read<NotificationsBloc>().add(NotificationMarkedRead(n.id));
                                    }
                                  }
                                },
                                child: const Text(
                                  'Mark all as read',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
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

class _NotificationIconBubble extends StatelessWidget {
  const _NotificationIconBubble({required this.n});
  final dynamic n;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.blueSoft;
    Color fg = AppColors.blue;
    IconData icon = Icons.notifications_none_rounded;

    if (n.icon == Icons.arrow_downward_rounded || n.icon == Icons.south_west_rounded) {
      bg = AppColors.greenSoft;
      fg = AppColors.green;
      icon = Icons.check_circle_rounded;
    } else if (n.icon == Icons.arrow_upward_rounded || n.icon == Icons.north_east_rounded) {
      bg = AppColors.blueSoft;
      fg = AppColors.blue;
      icon = Icons.swap_horiz_rounded;
    } else if (n.icon == Icons.warning_amber_rounded || n.icon == Icons.security_rounded) {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
      icon = Icons.shield_outlined;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 22),
    );
  }
}
