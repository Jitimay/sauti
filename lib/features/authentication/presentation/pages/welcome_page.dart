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
    final l = context.l10n;
    final isDemo = sl<AppConfig>().isDemo;
    final submitting = context.select<AuthBloc, bool>((b) => b.state.form == AuthFormStatus.submitting);
    final text = Theme.of(context).textTheme;
    final st = StatusColors.of(context);
    final hc = st.isHighContrast;
    return Scaffold(
      backgroundColor: hc ? Colors.black : AppColors.navy,
      body: Container(
        decoration: hc
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.navyLight, AppColors.navy, AppColors.navyDeep],
                  stops: [0, 0.45, 1],
                ),
              ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: ResponsiveBody(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 24),
                      const Align(alignment: Alignment.centerLeft, child: SautiWordmark(onDark: true)),
                      const Spacer(),
                      const Center(child: _VoiceIllustration()),
                      const Spacer(),
                      Semantics(
                        header: true,
                        child: Text(l.welcomeTitle, style: text.headlineLarge?.copyWith(color: Colors.white, fontSize: 36)),
                      ),
                      const SizedBox(height: 14),
                      Text(l.welcomeBody, style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.86))),
                      const SizedBox(height: 32),
                      if (isDemo) ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: hc ? AppColors.hcAccent : AppColors.amber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(60),
                          ),
                          onPressed: submitting
                              ? null
                              : () => context.read<AuthBloc>().add(
                                  const SignInRequested(DemoAuthRepository.demoEmail, DemoAuthRepository.demoPassword)),
                          icon: const Icon(Icons.play_arrow_rounded, size: 26),
                          label: Text(l.tryDemo),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          side: BorderSide(color: Colors.white.withValues(alpha: hc ? 1 : 0.5), width: hc ? 2 : 1.5),
                        ),
                        onPressed: () => context.push(Routes.login),
                        child: Text(l.signIn),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () => context.push(Routes.register),
                        child: Text(l.createAccount),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Concentric "sound" rings around a microphone: the product in one picture.
class _VoiceIllustration extends StatelessWidget {
  const _VoiceIllustration();

  @override
  Widget build(BuildContext context) {
    final st = StatusColors.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 220,
        child: CustomPaint(
          painter: _WelcomeRings(accent: st.accent),
          child: Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: st.accent,
                shape: BoxShape.circle,
                boxShadow: st.isHighContrast
                    ? null
                    : [BoxShadow(color: st.accent.withValues(alpha: 0.45), blurRadius: 36, spreadRadius: 2)],
              ),
              child: const Icon(Icons.mic_rounded, size: 42, color: AppColors.navyDeep),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeRings extends CustomPainter {
  _WelcomeRings({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (f, a, w) in [(0.98, 0.08, 2.0), (0.80, 0.14, 2.0), (0.62, 0.22, 2.5)]) {
      canvas.drawCircle(c, r * f, p
        ..color = Colors.white.withValues(alpha: a)
        ..strokeWidth = w);
    }
    // Two amber arcs: the voice "travelling" outwards.
    p
      ..color = accent
      ..strokeWidth = 4;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.62), -0.9, 1.1, false, p);
    p.color = accent.withValues(alpha: 0.55);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.80), 2.3, 0.9, false, p);
  }

  @override
  bool shouldRepaint(_WelcomeRings old) => old.accent != accent;
}
