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
