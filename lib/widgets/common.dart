import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/audio_service.dart';

/// A chunky, tappable primary button used across all menus.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool enabled;
  final double width;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppColors.accent,
    this.enabled = true,
    this.width = 260,
    this.fontSize = 19,
    this.iconSize = 24,
    this.padding = const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    return Opacity(
      opacity: active ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: active
              ? () {
                  AudioService.instance.button();
                  onPressed!();
                }
              : null,
          child: Container(
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, Color.lerp(color, Colors.black, 0.28)!],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: iconSize),
                  SizedBox(width: iconSize < 24 ? 6 : 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      shadows: const [
                        Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round icon button (back, close, settings...).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.panelLight,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          AudioService.instance.button();
          onPressed();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

/// A small pill showing the player's coin balance.
class CoinPill extends StatelessWidget {
  final int coins;
  const CoinPill({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coin.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Assets.coinChicken, width: 22, height: 22),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: AppColors.coin,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of up to three stars.
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarRow({super.key, required this.stars, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.accent : AppColors.textDim,
            size: size,
          ),
        );
      }),
    );
  }
}

/// A full-screen night gradient scaffold used by all menu screens.
class NightScaffold extends StatelessWidget {
  final Widget child;
  const NightScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.nightGradient),
        child: SafeArea(child: child),
      ),
    );
  }
}
