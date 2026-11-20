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
    final hc = StatusColors.of(context).isHighContrast;
    return Scaffold(
      backgroundColor: hc ? Colors.black : AppColors.blue,
      body: Container(
        decoration: hc ? null : const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.blueLight, AppColors.blue, AppColors.blueDeep],
            stops: [0.0, 0.5, 1.0],
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
                      const SizedBox(height: 20),
                      // Top bar: logo + Firebase badge
                      Row(children: [
                        const _SautiLogoWhite(),
                        const Spacer(),
                        _FirebaseBadge(),
                      ]),
                      const Spacer(),
                      // Hero illustration
                      const Center(child: _HeroIllustration()),
                      const SizedBox(height: 32),
                      // Headline
                      Semantics(
                        header: true,
                        child: Text(
                          l.welcomeTitle,
                          style: text.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.welcomeBody,
                        style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
                      ),
                      const SizedBox(height: 10),
                      // Feature bullets
                      _Bullet(icon: Icons.account_balance_wallet_rounded, text: 'Check your balance'),
                      _Bullet(icon: Icons.send_rounded, text: 'Send money'),
                      _Bullet(icon: Icons.help_outline_rounded, text: 'Get explanations'),
                      _Bullet(icon: Icons.more_horiz_rounded, text: 'And much more...'),
                      const Spacer(),
                      const SizedBox(height: 24),
                      // CTA buttons
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: hc ? AppColors.hcAccent : Colors.white,
                          foregroundColor: hc ? Colors.black : AppColors.blue,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: submitting
                            ? null
                            : isDemo
                                ? () => context.read<AuthBloc>().add(
                                    const SignInRequested(DemoAuthRepository.demoEmail, DemoAuthRepository.demoPassword))
                                : () => context.push(Routes.login),
                        child: Text(
                          isDemo ? l.tryDemo : l.signIn,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          side: BorderSide(color: Colors.white.withValues(alpha: hc ? 1 : 0.6), width: hc ? 2 : 1.5),
                        ),
                        onPressed: () => context.push(Routes.login),
                        child: Text(isDemo ? l.signIn : l.createAccount),
                      ),
                      if (isDemo) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          onPressed: () => context.push(Routes.register),
                          child: Text(l.createAccount),
                        ),
                      ],
                      const SizedBox(height: 20),
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(icon, color: AppColors.green, size: 20),
      const SizedBox(width: 10),
      Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
    ]),
  );
}

class _SautiLogoWhite extends StatelessWidget {
  const _SautiLogoWhite();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    const SautiMark(size: 36, onDark: true),
    const SizedBox(width: 10),
    Text('Sauti',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        )),
  ]);
}

class _FirebaseBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.local_fire_department_rounded, color: AppColors.amber, size: 16),
      const SizedBox(width: 5),
      Text('Powered by Firebase',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
    ]),
  );
}

/// Hero: concentric sound rings with a mic, Africa silhouette behind.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();
  @override
  Widget build(BuildContext context) {
    final hc = StatusColors.of(context).isHighContrast;
    return ExcludeSemantics(
      child: SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _HeroPainter(hc: hc),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: hc ? null : [
                  BoxShadow(color: AppColors.green.withValues(alpha: 0.5), blurRadius: 32, spreadRadius: 4),
                ],
              ),
              child: const Icon(Icons.mic_rounded, size: 40, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.hc});
  final bool hc;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
    for (final (f, a) in [(0.95, 0.10), (0.75, 0.16), (0.55, 0.22)]) {
      canvas.drawCircle(c, r * f, ring..color = Colors.white.withValues(alpha: a));
    }
    // Two green arcs — the "sound travelling outward"
    final arc = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = AppColors.green.withValues(alpha: 0.7);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.65), -0.8, 1.0, false, arc);
    arc.color = AppColors.green.withValues(alpha: 0.4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.82), 2.5, 0.8, false, arc);
  }
  @override
  bool shouldRepaint(_HeroPainter old) => old.hc != hc;
}
