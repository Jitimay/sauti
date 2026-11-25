import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n_ext.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status_banners.dart';
import '../theme/app_colors.dart';
import 'routes.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final destinations = [
      _Destination(Icons.home_rounded, l.navHome, branch: 0),
      _Destination(Icons.receipt_long_rounded, l.navActivity, branch: 2),
      _Destination(
        Icons.mic_rounded,
        l.navAssistant,
        branch: 1,
        prominent: true,
      ),
      _Destination(Icons.insights_rounded, l.navInsights),
      _Destination(Icons.settings_outlined, l.navSettings, branch: 3),
    ];

    Widget item(_Destination destination, {required bool wide}) {
      final index = destination.branch;
      final selected = index == shell.currentIndex;
      return _NavItem(
        destination: destination,
        wide: wide,
        selected: selected,
        onTap: index == null
            ? () => context.push(Routes.insights)
            : () => shell.goBranch(index, initialLocation: selected),
      );
    }

    final colors = StatusColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                _DesktopNavigation(
                  children: [
                    for (final destination in destinations)
                      item(destination, wide: true),
                  ],
                ),
              Expanded(
                child: Column(
                  children: [
                    const OfflineBanner(),
                    Expanded(child: shell),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : Material(
                  color: scheme.surface,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: colors.line)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final destination in destinations)
                              Expanded(child: item(destination, wide: false)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(
    this.icon,
    this.label, {
    this.branch,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final int? branch;
  final bool prominent;
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        width: 224,
        decoration: BoxDecoration(
          border: BorderDirectional(end: BorderSide(color: colors.line)),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 28),
                child: Row(
                  children: [
                    const SautiMark(size: 36),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.l10n.appName,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.wide,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool wide;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    final accentIcon = destination.prominent && (!wide || selected);
    final icon = Icon(
      destination.icon,
      size: 22,
      color: accentIcon ? scheme.onPrimary : foreground,
    );
    final label = Text(
      destination.label,
      textAlign: wide ? TextAlign.start : TextAlign.center,
      maxLines: wide ? null : 2,
      overflow: wide ? null : TextOverflow.ellipsis,
      style: (wide ? theme.textTheme.titleSmall : theme.textTheme.labelSmall)
          ?.copyWith(
            color: foreground,
            fontSize: wide ? null : 12,
            letterSpacing: 0,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
    );
    final radius = BorderRadius.circular(Radii.sm);

    return Semantics(
      button: true,
      selected: selected,
      child: Ink(
        decoration: BoxDecoration(
          color: wide && selected && !status.isHighContrast
              ? scheme.primaryContainer
              : null,
          border: wide && selected && status.isHighContrast
              ? Border.all(color: scheme.primary)
              : null,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          focusColor: scheme.primary.withValues(alpha: 0.22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: wide
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        if (accentIcon)
                          Ink(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: radius,
                            ),
                            child: icon,
                          )
                        else
                          SizedBox(width: 32, height: 32, child: icon),
                        const SizedBox(width: 10),
                        Expanded(child: label),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 7,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Ink(
                          width: 44,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accentIcon
                                ? scheme.primary
                                : selected && !status.isHighContrast
                                ? scheme.primaryContainer
                                : null,
                            border:
                                selected && status.isHighContrast && !accentIcon
                                ? Border.all(color: scheme.primary)
                                : null,
                            borderRadius: radius,
                          ),
                          child: icon,
                        ),
                        const SizedBox(height: 4),
                        label,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
