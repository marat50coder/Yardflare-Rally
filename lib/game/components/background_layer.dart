import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../yardflare_game.dart';
import 'lantern.dart';

/// Draws the ground texture, a night tint and a few decorations. Static, so it
/// sits at the very back.
class BackgroundLayer extends PositionComponent with HasGameReference<YardflareGame> {
  final int backgroundIndex;
  final List<_Decor> _decor = [];

  // The night tint is a full-screen gradient that never actually changes
  // once the field size is known, so it is built once and cached instead of
  // re-allocating a shader on every single frame.
  Paint? _tintPaint;

  BackgroundLayer({required this.backgroundIndex}) : super(priority: -20);

  @override
  Future<void> onLoad() async {
    size = game.size;
    _buildDecor();
    _buildTint();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
    if (isMounted) {
      _buildDecor();
      _buildTint();
    }
  }

  void _buildTint() {
    if (size.x <= 0 || size.y <= 0) return;
    _tintPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0A1428).withValues(alpha: 0.35),
          const Color(0xFF060A18).withValues(alpha: 0.72),
        ],
        stops: const [0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
  }

  void _buildDecor() {
    _decor.clear();
    final rng = math.Random(backgroundIndex * 97 + 13);
    final sprites = [
      Assets.decorTree,
      Assets.decorBush,
      Assets.decorHay,
      Assets.decorBarrel,
      Assets.decorRock,
      Assets.decorFlowers,
    ];
    // Place decorations only in the corners so they never hide gameplay.
    final spots = <Vector2>[
      Vector2(size.x * 0.10, size.y * 0.10),
      Vector2(size.x * 0.90, size.y * 0.12),
      Vector2(size.x * 0.08, size.y * 0.90),
      Vector2(size.x * 0.92, size.y * 0.88),
      Vector2(size.x * 0.5, size.y * 0.05),
    ];
    for (final s in spots) {
      _decor.add(_Decor(sprites[rng.nextInt(sprites.length)], s, 44 + rng.nextDouble() * 20));
    }
  }

  @override
  void render(Canvas canvas) {
    final bg = game.bank[Assets.backgrounds[backgroundIndex.clamp(0, Assets.backgrounds.length - 1)]];
    // Cover the whole screen.
    final src = bg.srcSize;
    final scale = math.max(size.x / src.x, size.y / src.y);
    final w = src.x * scale;
    final h = src.y * scale;
    bg.renderRect(canvas, Rect.fromCenter(center: (size / 2).toOffset(), width: w, height: h));

    // Night tint (radial: lighter around the middle where the coop glows).
    // Cached in _buildTint(); only rebuilt when the field is resized.
    if (_tintPaint == null) _buildTint();
    if (_tintPaint != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _tintPaint!);
    }

    // Decorations.
    for (final d in _decor) {
      final sprite = game.bank.maybe(d.sprite);
      if (sprite == null) continue;
      final a = sprite.srcSize.x / sprite.srcSize.y;
      sprite.renderRect(
        canvas,
        Rect.fromCenter(center: d.pos.toOffset(), width: d.size * a, height: d.size),
      );
    }
  }
}

class _Decor {
  final String sprite;
  final Vector2 pos;
  final double size;
  _Decor(this.sprite, this.pos, this.size);
}

/// Draws the danger lanes from each lantern's edge to the coop. Green = safe,
/// red & pulsing = dark and dangerous.
class LaneLayer extends PositionComponent with HasGameReference<YardflareGame> {
  double _t = 0;
  // Lane geometry only depends on lantern/coop positions, which are fixed for
  // the whole level, so the quadrilateral Path per lane is built once instead
  // of being re-allocated (with fresh moveTo/lineTo calls) every frame.
  final Map<int, Path> _pathCache = {};
  final Paint _fillPaint = Paint();
  final Paint _stripeFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _stripeStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  LaneLayer() : super(priority: -10);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  Path? _pathFor(Lantern lantern, Offset coop) {
    final cached = _pathCache[lantern.laneIndex];
    if (cached != null) return cached;
    final edge = lantern.spawnPoint.toOffset();
    final dir = (coop - edge);
    final len = dir.distance;
    if (len < 1) return null;
    final perp = Offset(-dir.dy / len, dir.dx / len);
    const halfW = 26.0;
    final path = Path()
      ..moveTo(edge.dx + perp.dx * halfW, edge.dy + perp.dy * halfW)
      ..lineTo(edge.dx - perp.dx * halfW, edge.dy - perp.dy * halfW)
      ..lineTo(coop.dx - perp.dx * halfW * 0.4, coop.dy - perp.dy * halfW * 0.4)
      ..lineTo(coop.dx + perp.dx * halfW * 0.4, coop.dy + perp.dy * halfW * 0.4)
      ..close();
    _pathCache[lantern.laneIndex] = path;
    return path;
  }

  @override
  void render(Canvas canvas) {
    final coop = game.coopPosition.toOffset();
    for (final lantern in game.lanterns) {
      final path = _pathFor(lantern, coop);
      if (path == null) continue;
      final charge = lantern.charge;
      final danger = 1 - charge;
      final baseColor = Color.lerp(const Color(0xFF7CB342), const Color(0xFFE53935), danger)!;

      final baseAlpha = 0.10 + danger * 0.22;
      _fillPaint.color = baseColor.withValues(alpha: baseAlpha);
      canvas.drawPath(path, _fillPaint);

      // Moving danger stripes when the lane is dark.
      if (danger > 0.5) {
        final pulse = 0.5 + 0.5 * math.sin(_t * 4);
        _stripeFillPaint.color = const Color(0xFFE53935).withValues(alpha: 0.12 * pulse * danger);
        canvas.drawPath(path, _stripeFillPaint);
        _stripeStrokePaint.color = const Color(0xFFFF7043).withValues(alpha: 0.5 * danger);
        canvas.drawPath(path, _stripeStrokePaint);
      }
    }
  }
}
