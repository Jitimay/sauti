import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';

enum OrbState { idle, listening, thinking, speaking, confirm, error }

/// The distinctive voice control: a large circular button whose rings convey
/// state. State is ALSO given as text and semantics — never motion alone.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({super.key, required this.state, required this.label, required this.onPressed, this.size = 104});
  final OrbState state;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  bool get _animate => widget.state == OrbState.listening || widget.state == OrbState.thinking || widget.state == OrbState.speaking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(VoiceOrb old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_animate && !reduce) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hc = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final st = StatusColors.of(context);
    final core = hc ? Colors.black : AppColors.navy;
    final ring = switch (widget.state) {
      OrbState.error => st.error,
      OrbState.confirm => st.warning,
      _ => st.accent,
    };
    final icon = switch (widget.state) {
      OrbState.listening => Icons.stop_rounded,
      OrbState.speaking => Icons.volume_off_rounded,
      OrbState.thinking => Icons.more_horiz_rounded,
      OrbState.error => Icons.mic_off_rounded,
      _ => Icons.mic_rounded,
    };
    final s = widget.size;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onPressed != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: s * 1.5,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => CustomPaint(
            painter: _RingsPainter(progress: _c.value, color: ring, active: _animate),
            child: child,
          ),
          child: Center(
            child: Material(
              color: core,
              shape: CircleBorder(side: BorderSide(color: ring, width: hc ? 4 : 3)),
              elevation: hc ? 0 : 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox.square(
                  dimension: s,
                  child: Icon(icon, size: s * 0.42, color: hc ? AppColors.hcAccent : Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.progress, required this.color, required this.active});
  final double progress;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final c = size.center(Offset.zero);
    final base = size.shortestSide / 3;
    for (var i = 0; i < 2; i++) {
      final t = (progress + i * 0.5) % 1.0;
      canvas.drawCircle(
        c,
        base + t * base * 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withValues(alpha: (1 - t) * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress || old.color != color || old.active != active;
}
