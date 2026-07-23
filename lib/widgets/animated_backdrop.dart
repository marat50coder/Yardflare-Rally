import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A calm, living night backdrop: drifting fireflies over the night gradient.
/// Used behind menu screens without overwhelming the foreground.
class AnimatedBackdrop extends StatefulWidget {
  final Widget child;
  final int fireflyCount;
  const AnimatedBackdrop({super.key, required this.child, this.fireflyCount = 18});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Firefly> _flies;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _flies = List.generate(widget.fireflyCount, (_) => _Firefly.random(rng));
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.nightGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _FireflyPainter(_flies, _c.value),
            ),
          ),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

class _Firefly {
  final double x, y, speed, radius, phase;
  _Firefly(this.x, this.y, this.speed, this.radius, this.phase);
  factory _Firefly.random(math.Random r) => _Firefly(
        r.nextDouble(),
        r.nextDouble(),
        0.3 + r.nextDouble() * 0.7,
        1.5 + r.nextDouble() * 2.5,
        r.nextDouble() * math.pi * 2,
      );
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> flies;
  final double t;
  _FireflyPainter(this.flies, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flies) {
      final dx = (f.x + math.sin(t * math.pi * 2 * f.speed + f.phase) * 0.05) * size.width;
      final dy = ((f.y + t * f.speed) % 1.0) * size.height;
      final glow = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * math.pi * 4 + f.phase));
      canvas.drawCircle(
        Offset(dx, dy),
        f.radius * (1 + glow),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.15 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(dx, dy),
        f.radius,
        Paint()..color = AppColors.accent.withValues(alpha: 0.7 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter old) => true;
}
