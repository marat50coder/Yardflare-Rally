import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/enemy_type.dart';
import '../components/lantern.dart';
import '../yardflare_game.dart';

enum EnemyState { appearing, approaching, scared }

/// An intruder walking from the yard edge toward the coop. Behaviour is driven
/// by its [EnemyKind] data flags.
class Enemy extends PositionComponent with HasGameReference<YardflareGame> {
  final EnemyKind kind;
  final Lantern lane;
  final double speedScale;

  EnemyState state = EnemyState.appearing;
  int hp;
  double _appear = 0;
  double _scareCd = 0;
  double _pause = 0;
  double _pauseCd = 3;
  double _bob = 0;
  bool _boarUsedLantern = false;
  bool facingRight = true;
  late Sprite _sprite;
  Vector2 _spriteSize = Vector2.all(48);

  Enemy({
    required this.kind,
    required this.lane,
    required Vector2 position,
    this.speedScale = 1.0,
  })  : hp = kind.toughness,
        super(position: position, size: Vector2.all(kind.radius * 2), anchor: Anchor.center, priority: 40);

  double get speed => kind.speed * speedScale;
  bool get isScared => state == EnemyState.scared;

  @override
  Future<void> onLoad() async {
    _sprite = game.bank[kind.sprite];
    final src = _sprite.srcSize;
    final aspect = src.x / src.y;
    final h = kind.radius * 2;
    _spriteSize = Vector2(h * aspect, h);
  }

  /// Applies one scare hit. Returns true if the enemy is now fully driven off.
  bool scare({double knockback = 1.0}) {
    if (state == EnemyState.scared || _scareCd > 0) return false;
    _scareCd = 0.35;
    hp--;
    if (hp <= 0) {
      state = EnemyState.scared;
      return true;
    }
    // Tough enemy: brief stun + knockback.
    final away = (position - game.coopPosition);
    if (away.length2 > 0.1) {
      position += away.normalized() * (18 * knockback);
    }
    _pause = 0.5;
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 9;
    if (game.paused) return;
    final scaled = dt * game.timeScale;

    if (_appear < 1) {
      _appear = math.min(1, _appear + dt * 3.5);
    }
    if (_scareCd > 0) _scareCd -= dt;

    if (state == EnemyState.scared) {
      // Flee back to the edge, then vanish.
      final dir = (position - game.coopPosition);
      final v = (dir.length2 > 0.1 ? dir.normalized() : Vector2(0, -1)) * speed * 1.7;
      position += v * dt;
      if (velocityIsOffField()) removeFromParent();
      facingRight = v.x > 0;
      return;
    }

    // Crow keeps draining its lane's lantern while it lives.
    if (kind.drainsLanterns) {
      lane.crowMultiplier = math.max(lane.crowMultiplier, 2.6);
    }

    if (state == EnemyState.appearing && _appear >= 0.6) {
      state = EnemyState.approaching;
    }
    if (state != EnemyState.approaching) return;

    // Raccoon occasionally pauses.
    if (kind.pauses) {
      if (_pause > 0) {
        _pause -= dt;
      } else {
        _pauseCd -= dt;
        if (_pauseCd <= 0) {
          _pause = 0.7;
          _pauseCd = 2.5 + math.Random().nextDouble() * 2;
        }
      }
    }
    if (_pause > 0) return;

    final toCoop = game.coopPosition - position;
    final dist = toCoop.length;
    var moveSpeed = speed;

    // Bright light slows non-flying enemies passing through it.
    if (!kind.flies && lane.isBright) {
      final dLantern = position.distanceTo(lane.position);
      if (dLantern < lane.rechargeRadius * 1.25) moveSpeed *= 0.45;
    }

    // Boar puts out the nearest lantern once when it gets close.
    if (kind.extinguishesLantern && !_boarUsedLantern && dist < 150) {
      _boarUsedLantern = true;
      game.boarExtinguishNear(position);
    }

    if (dist < game.coopReachRadius) {
      game.enemyReachedCoop(this);
      return;
    }

    final dir = toCoop.normalized();
    position += dir * moveSpeed * scaled;
    facingRight = dir.x > 0;
  }

  bool velocityIsOffField() {
    final b = game.size;
    return position.x < -60 || position.y < -60 || position.x > b.x + 60 || position.y > b.y + 60;
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final s = Curves.easeOutBack.transform(_appear.clamp(0.0, 1.0));

    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, _spriteSize.y * 0.4), width: _spriteSize.x * 0.7, height: 10),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final wobble = isScared ? math.sin(_bob * 2) * 0.25 : 0.0;
    canvas.rotate(wobble);
    final bob = math.sin(_bob) * 1.5;
    canvas.translate(0, bob);
    canvas.scale((facingRight ? 1 : -1) * s, s * (isScared ? 0.9 : 1.0));
    final rect = Rect.fromCenter(center: Offset.zero, width: _spriteSize.x, height: _spriteSize.y);
    _sprite.renderRect(canvas, rect);
    canvas.restore();

    // Tough enemy hit pips.
    if (kind.toughness > 1 && !isScared) {
      for (int i = 0; i < kind.toughness; i++) {
        final filled = i < hp;
        canvas.drawCircle(
          Offset(center.dx - (kind.toughness - 1) * 5 + i * 10, center.dy - _spriteSize.y * 0.55),
          3.5,
          Paint()..color = filled ? Colors.redAccent : Colors.white24,
        );
      }
    }
  }
}
