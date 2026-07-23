import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../yardflare_game.dart';

/// A collectible coin. Drifts to a resting spot, then can be magnet-pulled to
/// the chicken and collected.
class Coin extends PositionComponent with HasGameReference<YardflareGame> {
  final int value;
  Vector2 velocity;
  double _life = 0;
  double _bob = 0;
  bool _magnet = false;

  Coin({required Vector2 position, required this.value, Vector2? initialVelocity})
      : velocity = initialVelocity ?? Vector2.zero(),
        super(position: position, size: Vector2.all(26), anchor: Anchor.center, priority: 30);

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    _bob += dt * 6;
    if (game.paused) return;

    // initial pop scatter slows down quickly.
    if (velocity.length2 > 1 && !_magnet) {
      position += velocity * dt;
      velocity *= math.pow(0.02, dt).toDouble();
    }

    final chicken = game.chicken;
    final toChicken = chicken.position - position;
    final dist = toChicken.length;
    if (dist < game.coinMagnetRadius || _magnet) {
      _magnet = true;
      final pull = 380 + (game.coinMagnetRadius - dist).clamp(0.0, 400.0);
      position += toChicken.normalized() * pull * dt;
    }
    if (dist < 26) {
      game.collectCoin(value, position.clone());
      removeFromParent();
      return;
    }
    if (_life > 14) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final bob = math.sin(_bob) * 2;
    final fade = _life > 12 ? (14 - _life) / 2 : 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 12), width: 16, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.2 * fade),
    );
    final sprite = game.bank[Assets.coinChicken];
    final rect = Rect.fromCenter(center: center.translate(0, bob), width: size.x, height: size.y);
    final paint = Paint()..color = Colors.white.withValues(alpha: fade);
    sprite.renderRect(canvas, rect, overridePaint: paint);
  }
}
