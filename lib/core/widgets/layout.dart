import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// Centers content with a max width so screens work from small phones to
/// tablets without stretching lines beyond comfortable reading length.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 640, this.padding = const EdgeInsets.symmetric(horizontal: 20)});
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// The Sauti mark: concentric "sound" rings around a dot.
class SautiMark extends StatelessWidget {
  const SautiMark({super.key, this.size = 56, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final accent = StatusColors.of(context).accent;
    final base = onDark ? Colors.white : Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _MarkPainter(base: base, accent: accent)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.base, required this.accent});
  final Color base, accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    ring
      ..color = base.withValues(alpha: 0.25)
      ..strokeWidth = r * 0.12;
    canvas.drawCircle(c, r * 0.86, ring);
    ring
      ..color = base.withValues(alpha: 0.55)
      ..strokeWidth = r * 0.12;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.58), -2.4, 4.8, false, ring);
    canvas.drawCircle(c, r * 0.26, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.base != base || old.accent != accent;
}

class SautiWordmark extends StatelessWidget {
  const SautiWordmark({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        SautiAfricaLogo(size: 32, onDark: onDark),
        const SizedBox(width: 8),
        Text('Sauti',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: onDark ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )),
      ]);
}

/// Sauti Logo with Africa continent silhouette and green sound wave bars.
class SautiAfricaLogo extends StatelessWidget {
  const SautiAfricaLogo({super.key, this.size = 36, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.1,
      height: size,
      child: CustomPaint(
        painter: _AfricaSoundwavePainter(onDark: onDark),
      ),
    );
  }
}

class _AfricaSoundwavePainter extends CustomPainter {
  _AfricaSoundwavePainter({required this.onDark});
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Simplified Africa continent outline
    final path = Path()
      ..moveTo(w * 0.25, h * 0.15)
      ..lineTo(w * 0.75, h * 0.12)
      ..lineTo(w * 0.90, h * 0.35)
      ..lineTo(w * 0.70, h * 0.55)
      ..lineTo(w * 0.55, h * 0.90)
      ..lineTo(w * 0.40, h * 0.92)
      ..lineTo(w * 0.32, h * 0.65)
      ..lineTo(w * 0.10, h * 0.45)
      ..lineTo(w * 0.12, h * 0.28)
      ..close();

    final fillPaint = Paint()
      ..color = onDark ? Colors.white.withValues(alpha: 0.15) : AppColors.blueSoft
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = onDark ? Colors.white : AppColors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // Soundwave bars inside Africa
    final wavePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final bars = [
      (0.38, 0.40, 0.60),
      (0.48, 0.32, 0.68),
      (0.58, 0.25, 0.75),
      (0.68, 0.35, 0.65),
    ];
    for (final (x, y1, y2) in bars) {
      canvas.drawLine(Offset(w * x, h * y1), Offset(w * x, h * y2), wavePaint);
    }
  }

  @override
  bool shouldRepaint(_AfricaSoundwavePainter old) => old.onDark != onDark;
}

/// Headset AI Companion illustration for Welcome / Onboarding (Screen 2).
class HeadsetAvatarHero extends StatelessWidget {
  const HeadsetAvatarHero({super.key, this.size = 140});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.blueSoft.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric sound circles
          CustomPaint(
            size: Size(size, size),
            painter: _RingsPainter(color: AppColors.blueLight.withValues(alpha: 0.3)),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: const BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.headset_mic_rounded, size: size * 0.34, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawCircle(c, r * 0.75, p);
    canvas.drawCircle(c, r * 0.92, p);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}

/// African Characters Hero Illustration for Welcome Screen (Screen 1).
/// Depicts an African woman holding a smartphone and a blind African man with sunglasses & white mobility cane.
class AfricanCharactersHero extends StatelessWidget {
  const AfricanCharactersHero({super.key, this.width = 300, this.height = 240});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _AfricanCharactersPainter(),
      ),
    );
  }
}

class _AfricanCharactersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Rolling hills & sky backdrop
    final hillPaint1 = Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.4);
    final hillPath1 = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.3, h * 0.62, w * 0.65, h * 0.70)
      ..quadraticBezierTo(w * 0.85, h * 0.75, w, h * 0.65)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath1, hillPaint1);

    final hillPaint2 = Paint()..color = const Color(0xFF15803D).withValues(alpha: 0.8);
    final hillPath2 = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.4, h * 0.72, w * 0.75, h * 0.80)
      ..lineTo(w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath2, hillPaint2);

    // 2. Acacia tree silhouette in the background
    final treeTrunk = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.88, h * 0.78), Offset(w * 0.86, h * 0.58), treeTrunk);
    canvas.drawLine(Offset(w * 0.86, h * 0.64), Offset(w * 0.81, h * 0.54), treeTrunk);
    canvas.drawLine(Offset(w * 0.86, h * 0.64), Offset(w * 0.92, h * 0.53), treeTrunk);

    final treeCanopy = Paint()..color = const Color(0xFF14532D).withValues(alpha: 0.8);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.86, h * 0.52), width: 44, height: 16), treeCanopy);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.80, h * 0.53), width: 32, height: 12), treeCanopy);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.92, h * 0.52), width: 34, height: 14), treeCanopy);

    // 3. African Woman (Left character)
    final skinPaint = Paint()..color = const Color(0xFF5C3317);
    final womanHeadCenter = Offset(w * 0.35, h * 0.40);
    // Yellow headscarf
    final scarfPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(womanHeadCenter, 24, scarfPaint);
    // Face
    canvas.drawOval(Rect.fromCenter(center: Offset(womanHeadCenter.dx, womanHeadCenter.dy + 4), width: 28, height: 32), skinPaint);
    // Headscarf wrap detail
    canvas.drawArc(Rect.fromCircle(center: womanHeadCenter, radius: 24), -2.2, 2.5, false, Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.stroke..strokeWidth = 5);
    // Eyes & smile
    final featurePaint = Paint()..color = Colors.black.withValues(alpha: 0.75)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCenter(center: Offset(womanHeadCenter.dx - 5, womanHeadCenter.dy + 2), width: 6, height: 4), 0, 3.14, false, featurePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(womanHeadCenter.dx + 5, womanHeadCenter.dy + 2), width: 6, height: 4), 0, 3.14, false, featurePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(womanHeadCenter.dx, womanHeadCenter.dy + 10), width: 10, height: 6), 0, 3.14, false, featurePaint);

    // Woman's Yellow Dress
    final dressPaint = Paint()..color = const Color(0xFFFBBF24);
    final dressPath = Path()
      ..moveTo(w * 0.35, h * 0.54)
      ..lineTo(w * 0.20, h * 0.95)
      ..lineTo(w * 0.50, h * 0.95)
      ..close();
    canvas.drawPath(dressPath, dressPaint);

    // Woman holding smartphone
    final phoneHand = Path()
      ..moveTo(w * 0.38, h * 0.65)
      ..lineTo(w * 0.44, h * 0.72)
      ..lineTo(w * 0.40, h * 0.76);
    canvas.drawPath(phoneHand, Paint()..color = skinPaint.color..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Smartphone
    final phoneRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.45, h * 0.72), width: 16, height: 28), const Radius.circular(3));
    canvas.drawRRect(phoneRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.45, h * 0.72), width: 12, height: 22), const Radius.circular(2)), Paint()..color = AppColors.blueLight);

    // 4. African Blind Man (Right character)
    final manHeadCenter = Offset(w * 0.63, h * 0.42);
    // Hair
    canvas.drawCircle(manHeadCenter, 23, Paint()..color = const Color(0xFF1E1B18));
    // Face
    canvas.drawOval(Rect.fromCenter(center: Offset(manHeadCenter.dx, manHeadCenter.dy + 4), width: 30, height: 34), skinPaint);
    // Black sunglasses
    final glassesPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(manHeadCenter.dx - 6, manHeadCenter.dy + 2), width: 11, height: 8), const Radius.circular(3)), glassesPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(manHeadCenter.dx + 6, manHeadCenter.dy + 2), width: 11, height: 8), const Radius.circular(3)), glassesPaint);
    canvas.drawLine(Offset(manHeadCenter.dx - 2, manHeadCenter.dy + 2), Offset(manHeadCenter.dx + 2, manHeadCenter.dy + 2), glassesPaint..strokeWidth = 2);
    // Warm smile
    canvas.drawArc(Rect.fromCenter(center: Offset(manHeadCenter.dx, manHeadCenter.dy + 11), width: 12, height: 6), 0, 3.14, false, Paint()..color = Colors.white..strokeWidth = 2);

    // Man's Green Shirt
    final shirtPaint = Paint()..color = const Color(0xFF16A34A);
    final shirtPath = Path()
      ..moveTo(w * 0.63, h * 0.56)
      ..lineTo(w * 0.48, h * 0.95)
      ..lineTo(w * 0.78, h * 0.95)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Man holding white mobility cane
    final armPath = Path()
      ..moveTo(w * 0.70, h * 0.65)
      ..lineTo(w * 0.76, h * 0.75);
    canvas.drawPath(armPath, Paint()..color = skinPaint.color..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Mobility cane (white with red tip)
    final canePaint = Paint()..color = Colors.white..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.76, h * 0.72), Offset(w * 0.78, h * 0.97), canePaint);
    canvas.drawLine(Offset(w * 0.778, h * 0.94), Offset(w * 0.78, h * 0.97), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 3.5);
  }

  @override
  bool shouldRepaint(_AfricanCharactersPainter old) => false;
}

/// Savannah landscape footer for Screen 1 and Screen 4.
class SavannahFooter extends StatelessWidget {
  const SavannahFooter({super.key, this.height = 100});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _SavannahFooterPainter(),
      ),
    );
  }
}

class _SavannahFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant soft blue/teal hills
    final hill1 = Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.15);
    final p1 = Path()
      ..moveTo(0, h * 0.5)
      ..quadraticBezierTo(w * 0.25, h * 0.2, w * 0.55, h * 0.45)
      ..quadraticBezierTo(w * 0.8, h * 0.65, w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p1, hill1);

    // Foreground lush green hill
    final hill2 = Paint()..color = const Color(0xFF15803D).withValues(alpha: 0.25);
    final p2 = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.45, h * 0.4, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p2, hill2);

    // Acacia silhouette
    final trunk = Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.3)..strokeWidth = 2.5;
    canvas.drawLine(Offset(w * 0.82, h * 0.65), Offset(w * 0.80, h * 0.42), trunk);
    canvas.drawLine(Offset(w * 0.80, h * 0.48), Offset(w * 0.74, h * 0.38), trunk);
    canvas.drawLine(Offset(w * 0.80, h * 0.48), Offset(w * 0.86, h * 0.37), trunk);

    final canopy = Paint()..color = const Color(0xFF15803D).withValues(alpha: 0.4);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.80, h * 0.36), width: 36, height: 12), canopy);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.74, h * 0.37), width: 24, height: 9), canopy);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.86, h * 0.36), width: 26, height: 10), canopy);
  }

  @override
  bool shouldRepaint(_SavannahFooterPainter old) => false;
}

/// Dynamic Soundwave Visualizer for Screen 6 and Screen 7.
class SoundwaveBars extends StatelessWidget {
  const SoundwaveBars({super.key, this.color = AppColors.green, this.barCount = 20, this.height = 48});
  final Color color;
  final int barCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          // Curved wave heights (bell curve distribution)
          final x = (i - barCount / 2).abs() / (barCount / 2);
          final h = height * (0.25 + (1 - x * x) * 0.70);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.2),
            width: 3.5,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

/// A tinted circle holding an icon: the one visual unit for "what kind of
/// thing is this" across lists, actions and cards.
class IconBubble extends StatelessWidget {
  const IconBubble(this.icon, {super.key, this.size = 48, this.color, this.background, this.iconSize});
  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final st = StatusColors.of(context);
    final fg = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: st.isHighContrast ? Colors.black : (background ?? AppColors.navyTint),
        shape: BoxShape.circle,
        border: st.isHighContrast ? Border.all(color: fg, width: 2) : null,
      ),
      child: Icon(icon, size: iconSize ?? size * 0.46, color: fg),
    );
  }
}

/// Initials avatar for people (recipients, senders, the profile).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 48});
  final String name;
  final double size;

  static const _tones = [
    (Color(0xFFE4ECF6), Color(0xFF0F2A4A)),
    (Color(0xFFFCEFD9), Color(0xFF6B4100)),
    (Color(0xFFE4F2E8), Color(0xFF14582E)),
    (Color(0xFFF3E6F0), Color(0xFF6A2A5C)),
    (Color(0xFFE6EEF0), Color(0xFF1F4A55)),
  ];

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final st = StatusColors.of(context);
    final (bg, fg) = _tones[name.hashCode.abs() % _tones.length];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: st.isHighContrast ? Colors.black : bg,
          shape: BoxShape.circle,
          border: st.isHighContrast ? Border.all(color: AppColors.hcText, width: 2) : null,
        ),
        child: Text(
          initials(name),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: st.isHighContrast ? AppColors.hcText : fg,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.34,
              ),
        ),
      ),
    );
  }
}

/// A white rounded group with hairline dividers between children: settings
/// groups, lists of rows.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.padding = EdgeInsets.zero});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: padding,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: 18, endIndent: 18),
              children[i],
            ],
          ]),
        ),
      );
}
