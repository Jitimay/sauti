import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';

/// Shown while the persisted session is restored.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: Semantics(
            label: '${context.l10n.appName}. ${context.l10n.tagline}',
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SautiMark(size: 96, onDark: true),
              const SizedBox(height: 20),
              Text(context.l10n.appName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(context.l10n.tagline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
            ]),
          ),
        ),
      );
}
