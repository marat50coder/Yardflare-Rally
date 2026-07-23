import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A fixed on-screen joystick. Reports a direction vector (length 0..1).
class VirtualJoystick extends StatefulWidget {
  final ValueChanged<Vector2> onChanged;
  final double size;
  const VirtualJoystick({super.key, required this.onChanged, this.size = 150});

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knob = Offset.zero;

  double get _radius => widget.size / 2;

  void _update(Offset local) {
    final center = Offset(_radius, _radius);
    var delta = local - center;
    if (delta.distance > _radius) {
      delta = Offset.fromDirection(delta.direction, _radius);
    }
    setState(() => _knob = delta);
    widget.onChanged(Vector2(delta.dx / _radius, delta.dy / _radius));
  }

  void _end() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(Vector2.zero());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: _knob,
                child: Container(
                  width: widget.size * 0.42,
                  height: widget.size * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.accent.withValues(alpha: 0.9),
                      AppColors.accentDark.withValues(alpha: 0.9),
                    ]),
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
