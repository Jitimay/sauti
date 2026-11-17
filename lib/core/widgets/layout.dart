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
        SautiMark(size: 40, onDark: onDark),
        const SizedBox(width: 10),
        Text('Sauti',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: onDark ? Colors.white : null,
                  letterSpacing: 0.5,
                )),
      ]);
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
