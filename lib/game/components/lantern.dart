import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../yardflare_game.dart';

/// A perimeter lantern. While lit it keeps its lane safer (fewer spawns and it
/// slows enemies passing through its glow). Charge slowly drains over time.
class Lantern extends PositionComponent with HasGameReference<YardflareGame> {
  final int laneIndex;
  final double laneAngle; // direction from coop toward this lantern
  final Vector2 spawnPoint; // where enemies appear for this lane

  double charge; // 0..1
  double decayRate; // per second
  double windMultiplier; // >1 fades faster (wind / crow)
  double crowMultiplier; // temporary extra drain from crows
  final double rechargeRadius;

  bool wasFull; // used to detect a fresh full relight
  double _flicker = 0;

  // The warm ground-glow gradient is rebuilt only when its radius/alpha move
  // meaningfully (bucketed), instead of allocating a fresh RadialGradient +
  // Shader on every single frame the lantern is lit.
  Paint? _glowPaint;
  double _glowRadiusBucket = -1;
  double _glowAlphaBucket = -1;

  Lantern({
    required this.laneIndex,
    required this.laneAngle,
    required this.spawnPoint,
    required Vector2 position,
    required this.decayRate,
    required this.rechargeRadius,
    this.charge = 1.0,
    this.windMultiplier = 1.0,
  })  : crowMultiplier = 1.0,
        wasFull = true,
        super(position: position, size: Vector2.all(74), anchor: Anchor.center);

  bool get isLit => charge > 0.02;
  bool get isBright => charge > 0.55;
  bool get isCritical => charge > 0.02 && charge < 0.25;

  int get spriteIndex {
    if (charge > 0.85) return 0;
    if (charge > 0.65) return 1;
    if (charge > 0.45) return 2;
    if (charge > 0.2) return 3;
    if (charge > 0.02) return 4;
    return 5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _flicker += dt * 8;
    if (game.paused) return;
    final drain = decayRate * windMultiplier * crowMultiplier * game.timeScale;
    charge = (charge - drain * dt).clamp(0.0, 1.0);
    // crow drain decays back to normal on its own.
    if (crowMultiplier > 1.0) {
      crowMultiplier = math.max(1.0, crowMultiplier - dt * 0.6);
    }
    // Hysteresis: only re-arm the "Perfect Relight" trigger once the charge
    // has meaningfully decayed, not on every frame's tiny decay tick while a
    // chicken parked in range keeps topping it straight back up to 1.0.
    if (charge < 0.97) wasFull = false;
  }

  /// Adds charge from a nearby chicken. Returns true if it just became full.
  bool addCharge(double amount) {
    if (charge >= 1.0) return false;
    charge = (charge + amount).clamp(0.0, 1.0);
    if (charge >= 1.0 && !wasFull) {
      wasFull = true;
      return true;
    }
    return false;
  }

  void igniteFull() {
    final wasNotFull = charge < 1.0;
    charge = 1.0;
    wasFull = true;
    if (wasNotFull) {
      // treat as a relight for feedback but not perfect-combo abuse
    }
  }

  void extinguish() {
    charge = 0.0;
    wasFull = false;
  }

  Color get _ringColor {
    if (charge > 0.6) return AppColors.safe;
    if (charge > 0.3) return AppColors.accent;
    return AppColors.danger;
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final glow = charge;

    // Warm ground glow when lit.
    if (glow > 0.02) {
      final flick = 1 + 0.05 * math.sin(_flicker);
      final radius = (46 + glow * 34) * flick;
      // Round to coarse buckets so tiny per-frame flicker/decay jitter
      // doesn't force a brand new gradient shader every frame.
      final radiusBucket = (radius / 2).round() * 2.0;
      final alphaBucket = (glow * 20).round() / 20.0;
      if (_glowPaint == null || radiusBucket != _glowRadiusBucket || alphaBucket != _glowAlphaBucket) {
        _glowRadiusBucket = radiusBucket;
        _glowAlphaBucket = alphaBucket;
        _glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE08A).withValues(alpha: 0.55 * alphaBucket),
              const Color(0xFFFFB347).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radiusBucket));
      }
      canvas.drawCircle(center, radiusBucket, _glowPaint!);
    }

    // Critical pulse ring.
    if (isCritical) {
      final pulse = 0.5 + 0.5 * math.sin(_flicker * 1.5);
      final paint = Paint()
        ..color = AppColors.danger.withValues(alpha: 0.35 + 0.35 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, 40, paint);
    }

    // Lantern sprite.
    final sprite = game.bank[Assets.lanternStates[spriteIndex]];
    sprite.render(canvas, position: Vector2.zero(), size: size);

    // Circular charge indicator above the lantern.
    final ringRect = Rect.fromCircle(center: Offset(center.dx, center.dy - 44), radius: 15);
    canvas.drawArc(ringRect, 0, math.pi * 2,
        false, Paint()..color = Colors.black.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 4);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      math.pi * 2 * charge,
      false,
      Paint()
        ..color = _ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Smoke wisp when fully out.
    if (charge <= 0.02) {
      final t = _flicker * 0.5;
      for (int i = 0; i < 3; i++) {
        final off = (t + i) % 3;
        final p = Offset(center.dx + math.sin((t + i) * 1.3) * 5, center.dy - 20 - off * 12);
        canvas.drawCircle(p, 4 - off, Paint()..color = Colors.grey.withValues(alpha: 0.25 * (1 - off / 3)));
      }
    }
  }
}
