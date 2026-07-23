import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// An expanding, fading ring (used for relights, shockwaves, dashes).
class RingEffect extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double duration;
  final double strokeWidth;
  double _t = 0;

  RingEffect({
    required Vector2 position,
    required this.color,
    this.maxRadius = 90,
    this.duration = 0.5,
    this.strokeWidth = 4,
  }) : super(position: position, anchor: Anchor.center, priority: 80);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    final r = maxRadius * Curves.easeOut.transform(p);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = color.withValues(alpha: (1 - p) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1 - p * 0.5),
    );
  }
}

class _Dot {
  Vector2 pos;
  Vector2 vel;
  double size;
  _Dot(this.pos, this.vel, this.size);
}

/// A small burst of coloured dots that fly outward and fade.
class BurstEffect extends PositionComponent {
  final Color color;
  final int count;
  final double speed;
  final double duration;
  final List<_Dot> _dots = [];
  double _t = 0;

  BurstEffect({
    required Vector2 position,
    required this.color,
    this.count = 8,
    this.speed = 120,
    this.duration = 0.5,
  }) : super(position: position, anchor: Anchor.center, priority: 80) {
    final rng = math.Random();
    for (int i = 0; i < count; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final sp = speed * (0.5 + rng.nextDouble());
      _dots.add(_Dot(Vector2.zero(), Vector2(math.cos(a), math.sin(a)) * sp, 2.0 + rng.nextDouble() * 3));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (final d in _dots) {
      d.pos += d.vel * dt;
      d.vel *= math.pow(0.05, dt).toDouble();
    }
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / duration).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withValues(alpha: a);
    for (final d in _dots) {
      canvas.drawCircle(d.pos.toOffset(), d.size, paint);
    }
  }
}

/// A fading dot left behind by the dashing chicken.
class TrailDot extends PositionComponent {
  final Color color;
  double _t = 0;
  final double duration;
  TrailDot({required Vector2 position, this.color = const Color(0xFFFFE08A), this.duration = 0.35})
      : super(position: position, anchor: Anchor.center, priority: 25);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    canvas.drawCircle(Offset.zero, 10 * (1 - p),
        Paint()..color = color.withValues(alpha: (1 - p) * 0.5));
  }
}

/// A short floating text popup (score / bonus feedback).
class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  final double duration;
  double _t = 0;

  // The text is re-laid-out only when its fade alpha crosses into a new coarse
  // bucket (~a dozen steps over the whole lifetime). This keeps the smooth
  // fade while avoiding a per-frame canvas.saveLayer() -- allocating an
  // offscreen buffer every frame for every popup was a real jank source when
  // several appeared at once (relights, coins, scares).
  late TextPainter _tp;
  int _alphaBucket = -1;

  FloatingText({
    required Vector2 position,
    required this.text,
    this.color = Colors.white,
    this.duration = 0.9,
  }) : super(position: position, anchor: Anchor.center, priority: 90) {
    _rebuild(1.0);
  }

  void _rebuild(double alpha) {
    _tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Colors.black54.withValues(alpha: alpha * 0.55), offset: const Offset(0, 1), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 26 * dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / duration).clamp(0.0, 1.0);
    final bucket = (a * 12).round();
    if (bucket != _alphaBucket) {
      _alphaBucket = bucket;
      _rebuild(bucket / 12);
    }
    _tp.paint(canvas, Offset(-_tp.width / 2, -_tp.height / 2));
  }
}
