import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/enemy_type.dart';
import '../yardflare_game.dart';

/// A pre-spawn warning shown at a lane edge: a pulsing red marker plus the icon
/// of the enemy about to appear, pointing toward the coop.
class WarningMarker extends PositionComponent with HasGameReference<YardflareGame> {
  final EnemyType enemyType;
  final double angleToCoop;
  double life;
  double _t = 0;

  WarningMarker({
    required Vector2 position,
    required this.enemyType,
    required this.angleToCoop,
    required this.life,
  }) : super(position: position, size: Vector2.all(50), anchor: Anchor.center, priority: 70);

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused) return;
    _t += dt;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final pulse = 0.5 + 0.5 * math.sin(_t * 9);

    // Warning ring.
    canvas.drawCircle(center, 24,
        Paint()..color = AppColors.danger.withValues(alpha: 0.25 + 0.35 * pulse));
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..color = AppColors.danger.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Enemy icon preview.
    final sprite = game.bank.maybe(EnemyKind.of(enemyType).sprite);
    if (sprite != null) {
      sprite.renderRect(canvas, Rect.fromCenter(center: center, width: 30, height: 30));
    }

    // Arrow pointing toward the coop.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleToCoop);
    final path = Path()
      ..moveTo(28, 0)
      ..lineTo(18, -7)
      ..lineTo(18, 7)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.danger.withValues(alpha: 0.6 + 0.4 * pulse));
    canvas.restore();
  }
}
