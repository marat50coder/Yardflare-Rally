import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/powerup_type.dart';
import '../yardflare_game.dart';

/// A power-up floating on the field. Walk over it to add it to your inventory.
class PowerUpPickup extends PositionComponent with HasGameReference<YardflareGame> {
  final PowerUpType type;
  double _life = 0;
  double _bob = 0;
  Paint? _glowPaint;
  double _glowAlphaBucket = -1;

  PowerUpPickup({required Vector2 position, required this.type})
      : super(position: position, size: Vector2.all(46), anchor: Anchor.center, priority: 35);

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 4;
    if (game.paused) return;
    _life += dt;
    final d = game.chicken.position.distanceTo(position);
    if (d < 40) {
      game.collectPowerup(type, position.clone());
      removeFromParent();
      return;
    }
    if (_life > 10) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final info = PowerUpInfo.of(type);
    final center = (size / 2).toOffset();
    final bob = math.sin(_bob) * 3;
    final fade = _life > 8 ? (10 - _life) / 2 : 1.0;
    final c = center.translate(0, bob);

    // Glow disc. The gradient shader is cached and only rebuilt when the
    // fade bucket changes, rather than every single frame. It's built around
    // the local origin and the canvas is translated to the bobbing position
    // instead, so the cache stays valid while the disc gently bobs.
    final alphaBucket = (fade * 20).round() / 20.0;
    if (_glowPaint == null || alphaBucket != _glowAlphaBucket) {
      _glowAlphaBucket = alphaBucket;
      _glowPaint = Paint()
        ..shader = RadialGradient(colors: [
          info.tint.withValues(alpha: 0.6 * alphaBucket),
          info.tint.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: Offset.zero, radius: 26));
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawCircle(Offset.zero, 26, _glowPaint!);
    canvas.restore();
    final sprite = game.bank.maybe(info.icon);
    if (sprite != null) {
      sprite.renderRect(
        canvas,
        Rect.fromCenter(center: c, width: 40, height: 40),
        overridePaint: Paint()..color = Colors.white.withValues(alpha: fade),
      );
    }
  }
}
