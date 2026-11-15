import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../error/failure.dart';
import '../l10n/l10n_ext.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: context.l10n.loading,
          liveRegion: true,
          child: const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});
  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = StatusColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(failure is NetworkFailure ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                size: 48, color: s.error),
            const SizedBox(height: 12),
            Text(failure.code.message(context.l10n),
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(context.l10n.retry)),
            ],
          ]),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: StatusColors.of(context).muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 0, 8),
        child: Row(children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}
