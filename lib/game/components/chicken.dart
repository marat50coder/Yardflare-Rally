import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../yardflare_game.dart';

/// The player-controlled chicken. Handles smooth movement, facing, dashing and
/// all the little squash-and-stretch life that makes it feel alive.
class Chicken extends PositionComponent with HasGameReference<YardflareGame> {
  Vector2 velocity = Vector2.zero();
  bool facingRight = true;

  double baseSpeed;
  double speedMultiplier = 1.0; // set by speed-boost power-up

  double dashCooldown;
  double _dashCdTimer = 0;
  double _dashTimer = 0;
  double _hurt = 0;
  double _happy = 0;
  double _trailTimer = 0;
  double _bob = 0;

  late Sprite _sprite;
  Vector2 _spriteSize = Vector2.all(64);

  Chicken({
    required Vector2 position,
    required this.baseSpeed,
    required this.dashCooldown,
    required int skinId,
  }) : _skinId = skinId,
        super(position: position, size: Vector2.all(64), anchor: Anchor.center, priority: 60);

  final int _skinId;

  bool get isDashing => _dashTimer > 0;
  double get dashProgress => (1 - (_dashCdTimer / dashCooldown)).clamp(0.0, 1.0);
  bool get dashReady => _dashCdTimer <= 0;

  @override
  Future<void> onLoad() async {
    _sprite = game.bank[Assets.chickenSkin(_skinId)];
    final src = _sprite.srcSize;
    final aspect = src.x / src.y;
    const h = 66.0;
    _spriteSize = Vector2(h * aspect, h);
  }

  void setSkin(int skinId) {
    _sprite = game.bank[Assets.chickenSkin(skinId)];
    final src = _sprite.srcSize;
    final aspect = src.x / src.y;
    const h = 66.0;
    _spriteSize = Vector2(h * aspect, h);
  }

  void tryDash() {
    if (!dashReady || isDashing) return;
    Vector2 dir = velocity.length2 > 1 ? velocity.normalized() : Vector2(facingRight ? 1 : -1, 0);
    if (game.moveInput.length2 > 0.01) dir = game.moveInput.normalized();
    _dashTimer = GameTuning.dashDuration;
    _dashCdTimer = dashCooldown;
    velocity = dir * baseSpeed * speedMultiplier * GameTuning.dashSpeedMultiplier;
    game.onChickenDash(position.clone());
  }

  void hurt() => _hurt = 0.5;
  void celebrate() => _happy = 1.2;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused) return;

    if (_dashCdTimer > 0) _dashCdTimer = math.max(0, _dashCdTimer - dt);
    if (_hurt > 0) _hurt = math.max(0, _hurt - dt);
    if (_happy > 0) _happy = math.max(0, _happy - dt);
    _bob += dt * 6;

    if (_dashTimer > 0) {
      _dashTimer -= dt;
      // dash keeps its velocity; slight decay at the end.
      _trailTimer += dt;
      if (_trailTimer > 0.03) {
        _trailTimer = 0;
        game.spawnDashTrail(position.clone());
      }
    } else {
      final input = game.moveInput;
      final target = input * (baseSpeed * speedMultiplier);
      final diff = target - velocity;
      final maxDelta = GameTuning.chickenAccel * dt;
      if (diff.length > maxDelta) {
        velocity += diff.normalized() * maxDelta;
      } else {
        velocity = target;
      }
    }

    position += velocity * dt;

    // Facing.
    if (velocity.x.abs() > 6) facingRight = velocity.x > 0;

    // Footsteps.
    if (velocity.length > baseSpeed * 0.4) {
      game.audio.footstep(game.elapsed);
    }

    // Keep inside the play field.
    final b = game.playBounds;
    position.x = position.x.clamp(b.left, b.right);
    position.y = position.y.clamp(b.top, b.bottom);
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();

    // Soft shadow.
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, _spriteSize.y * 0.42), width: _spriteSize.x * 0.7, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    final speedRatio = (velocity.length / (baseSpeed * speedMultiplier)).clamp(0.0, 1.0);
    // Squash & stretch: stretch along motion when fast / dashing.
    double sx = 1 + 0.12 * speedRatio + (isDashing ? 0.18 : 0);
    double sy = 1 - 0.08 * speedRatio - (isDashing ? 0.10 : 0);
    // Idle bob.
    if (speedRatio < 0.1) {
      sy += 0.03 * math.sin(_bob);
      sx -= 0.02 * math.sin(_bob);
    }
    if (_happy > 0) {
      final j = math.sin(_happy * 18).abs();
      sy += 0.15 * j;
      sx += 0.05 * j;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(facingRight ? sx : -sx, sy);
    final drawRect = Rect.fromCenter(center: Offset.zero, width: _spriteSize.x, height: _spriteSize.y);
    _sprite.renderRect(canvas, drawRect);
    canvas.restore();

    // Hurt flash.
    if (_hurt > 0) {
      final a = (_hurt * 1.6).clamp(0.0, 0.6);
      canvas.drawCircle(center, _spriteSize.y * 0.5,
          Paint()..color = Colors.red.withValues(alpha: a)..blendMode = BlendMode.srcATop);
    }

    // Dash aura.
    if (isDashing) {
      canvas.drawCircle(center, _spriteSize.y * 0.55,
          Paint()..color = Colors.white.withValues(alpha: 0.15));
    }
  }
}
