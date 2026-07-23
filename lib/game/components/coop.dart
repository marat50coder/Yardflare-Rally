import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../yardflare_game.dart';

/// The coop at the centre of the yard. Shows the coop sprite, the eggs it still
/// holds and a shield bubble when the Coop Shield power-up is active.
class Coop extends PositionComponent with HasGameReference<YardflareGame> {
  final int coopIndex;
  double _shake = 0;
  double _shieldPulse = 0;

  Coop({required Vector2 position, required this.coopIndex})
      : super(position: position, size: Vector2(150, 120), anchor: Anchor.center, priority: 50);

  void hitReaction() => _shake = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    _shieldPulse += dt * 4;
    if (_shake > 0) _shake = math.max(0, _shake - dt);
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final shakeX = _shake > 0 ? math.sin(_shake * 60) * 4 * _shake : 0.0;

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, size.y * 0.42), width: size.x * 0.8, height: 22),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    final sprite = game.bank[Assets.coops[coopIndex.clamp(0, Assets.coops.length - 1)]];
    final src = sprite.srcSize;
    final aspect = src.x / src.y;
    final h = size.y;
    final w = h * aspect;
    sprite.renderRect(canvas, Rect.fromCenter(center: center.translate(shakeX, 0), width: w, height: h));

    // Eggs in front of the coop.
    final eggs = game.eggs;
    final shown = math.min(eggs, 8);
    final eggSprite = game.bank[Assets.eggWhite];
    for (int i = 0; i < shown; i++) {
      final col = i % 4;
      final row = i ~/ 4;
      final ex = center.dx - 30 + col * 20 + shakeX;
      final ey = center.dy + size.y * 0.33 + row * 14;
      eggSprite.renderRect(canvas, Rect.fromCenter(center: Offset(ex, ey), width: 16, height: 20));
    }

    // Shield bubble.
    if (game.shieldActive) {
      final pulse = 0.5 + 0.5 * math.sin(_shieldPulse);
      final r = size.x * 0.6;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF5B8CFF).withValues(alpha: 0.15 + 0.1 * pulse),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF8FB4FF).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}
