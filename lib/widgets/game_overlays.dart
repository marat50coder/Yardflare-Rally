import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'common.dart';

/// A dark modal card used by all in-game overlays.
class OverlayPanel extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Widget> children;
  const OverlayPanel({
    super.key,
    required this.title,
    required this.children,
    this.titleColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.panelLight, AppColors.panel],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    shadows: const [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated 3-star display for the level-complete screen.
class AnimatedStars extends StatefulWidget {
  final int stars;
  const AnimatedStars({super.key, required this.stars});

  @override
  State<AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<AnimatedStars> with TickerProviderStateMixin {
  late final List<AnimationController> _c;

  @override
  void initState() {
    super.initState();
    _c = List.generate(
      3,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)),
    );
    for (int i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 250 * i + 150), () {
        if (mounted) _c[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < widget.stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: filled
              ? ScaleTransition(
                  scale: CurvedAnimation(parent: _c[i], curve: Curves.elasticOut),
                  child: Icon(Icons.star_rounded,
                      color: AppColors.accent, size: i == 1 ? 66 : 54),
                )
              : Icon(Icons.star_rounded,
                  color: Colors.white.withValues(alpha: 0.15), size: i == 1 ? 66 : 54),
        );
      }),
    );
  }
}

/// A simple label/value stat row.
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  const StatRow({super.key, required this.label, required this.value, this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: AppColors.textDim), const SizedBox(width: 8)],
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 15))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: valueColor ?? AppColors.textLight)),
        ],
      ),
    );
  }
}

/// A small pill showing whether an objective was met.
class ObjectiveTile extends StatelessWidget {
  final String label;
  final bool met;
  const ObjectiveTile({super.key, required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.radio_button_unchecked,
              color: met ? AppColors.safe : AppColors.textDim, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: met ? AppColors.textLight : AppColors.textDim))),
        ],
      ),
    );
  }
}

/// Convenience for a full-width overlay button.
Widget overlayButton(String label, IconData icon, VoidCallback onTap, {Color color = AppColors.accent}) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: PrimaryButton(label: label, icon: icon, color: color, width: 300, onPressed: onTap),
  );
}
