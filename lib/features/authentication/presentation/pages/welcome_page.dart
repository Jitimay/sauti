import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../data/repositories/demo_auth_repository.dart';
import '../bloc/auth_bloc.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highContrast = StatusColors.of(context).isHighContrast;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 52 : 24,
                    vertical: wide ? 44 : 28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1080 : 440),
                      child: wide
                          ? Row(
                              children: [
                                const Expanded(
                                  child: _WelcomeContent(wide: true),
                                ),
                                const SizedBox(width: 52),
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 1.05,
                                    child: _VoiceArtwork(
                                      highContrast: highContrast,
                                      outline: scheme.outline,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const _WelcomeContent(wide: false),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDemo = sl<AppConfig>().isDemo;
    final submitting = context.select<AuthBloc, bool>(
      (b) => b.state.form == AuthFormStatus.submitting,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highContrast = StatusColors.of(context).isHighContrast;

    void openDemo() => context.read<AuthBloc>().add(
      const SignInRequested(
        DemoAuthRepository.demoEmail,
        DemoAuthRepository.demoPassword,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SautiMark(size: 36),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l.appName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: wide ? 40 : 24),
        Semantics(
          header: true,
          child: Text(
            l.welcomeTitle,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: wide ? 54 : 40,
              height: 1.08,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.welcomeBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (!wide) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 168,
            child: _VoiceArtwork(
              highContrast: highContrast,
              outline: scheme.outline,
            ),
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting
                ? null
                : isDemo
                ? openDemo
                : () => context.push(Routes.login),
            child: Text(
              isDemo ? l.tryDemo : l.signIn,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                context.push(isDemo ? Routes.login : Routes.register),
            child: Text(
              isDemo ? l.signIn : l.createAccount,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (isDemo) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => context.push(Routes.register),
              child: Text(l.createAccount, textAlign: TextAlign.center),
            ),
          ),
        ],
      ],
    );
  }
}

class _VoiceArtwork extends StatelessWidget {
  const _VoiceArtwork({required this.highContrast, required this.outline});

  final bool highContrast;
  final Color outline;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: highContrast ? Colors.black : const Color(0xFF152953),
        gradient: highContrast
            ? null
            : const RadialGradient(
                center: Alignment(0.25, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFF274989),
                  Color(0xFF152953),
                  Color(0xFF101E3F),
                ],
              ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: highContrast ? Border.all(color: outline, width: 2) : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 220;
          final markSize = compact ? 120.0 : 260.0;
          final iconSize = compact ? 25.0 : 46.0;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SautiMark(size: markSize, onDark: true),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: highContrast
                        ? Colors.black
                        : const Color(0xFF244D91),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: highContrast ? outline : const Color(0xFF75BDB8),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 10 : 20),
                    child: Icon(
                      Icons.mic_rounded,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
