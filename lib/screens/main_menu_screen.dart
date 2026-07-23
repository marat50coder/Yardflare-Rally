import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';
import 'daily_tasks_screen.dart';
import 'endless_screen.dart';
import 'how_to_play_screen.dart';
import 'location_select_screen.dart';
import 'settings_screen.dart';
import 'skins_screen.dart';
import 'upgrades_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    // One-shot staggered entrance for the whole menu.
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))
      ..forward();
    // Make sure the menu music is playing again after returning from a level
    // (leaving gameplay stops all game audio). This call is idempotent, so it
    // is a no-op when the menu track is already playing.
    AudioService.instance.playMusic(Assets.musicMenu);
  }

  @override
  void dispose() {
    _bob.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    return Scaffold(
      body: AnimatedBackdrop(
        child: AnimatedBuilder(
          animation: data,
          builder: (context, _) {
            final endlessUnlocked = data.endlessUnlocked;
            return Column(
              children: [
                _TopBar(
                  coins: data.coins,
                  stars: data.totalStars,
                  onHowTo: () => _open(const HowToPlayScreen()),
                  onSettings: () => _open(const SettingsScreen()),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _EntranceItem(
                          animation: _intro,
                          index: 0,
                          child: _Title(bob: _bob),
                        ),
                        const SizedBox(height: 26),
                        _EntranceItem(
                          animation: _intro,
                          index: 1,
                          child: _PlayButton(
                            pulse: _bob,
                            onTap: () => _open(const LocationSelectScreen()),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EntranceItem(
                          animation: _intro,
                          index: 2,
                          child: PrimaryButton(
                            label: endlessUnlocked ? 'Endless' : 'Endless (Locked)',
                            icon: endlessUnlocked ? Icons.all_inclusive : Icons.lock,
                            color: AppColors.endless,
                            enabled: endlessUnlocked,
                            onPressed: endlessUnlocked
                                ? () => _open(const EndlessScreen())
                                : _showEndlessHint,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EntranceItem(
                          animation: _intro,
                          index: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SmallMenuButton(
                                label: 'Upgrades',
                                icon: Icons.upgrade,
                                color: AppColors.upgrades,
                                onTap: () => _open(const UpgradesScreen()),
                              ),
                              const SizedBox(width: 12),
                              _SmallMenuButton(
                                label: 'Skins',
                                icon: Icons.checkroom,
                                color: AppColors.skins,
                                onTap: () => _open(const SkinsScreen()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EntranceItem(
                          animation: _intro,
                          index: 4,
                          child: _SmallMenuButton(
                            label: 'Daily Tasks',
                            icon: Icons.task_alt,
                            color: AppColors.tasks,
                            wide: true,
                            onTap: () => _open(const DailyTasksScreen()),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEndlessHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finish level 40 to unlock Endless Mode.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Fades + slides a child up into place, staggered by [index], driven by the
/// shared one-shot [animation]. Gives the menu a lively assembled-on-launch feel.
class _EntranceItem extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;
  const _EntranceItem({
    required this.animation,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.11).clamp(0.0, 0.5);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final v = curved.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 28), child: child),
        );
      },
      child: child,
    );
  }
}

/// The bobbing game logo with a soft radial glow behind it.
class _Title extends StatelessWidget {
  final AnimationController bob;
  const _Title({required this.bob});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bob,
      builder: (context, child) {
        final t = bob.value;
        return Transform.translate(
          offset: Offset(0, math.sin(t * math.pi * 2) * 6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.16 + 0.06 * math.sin(t * math.pi * 2)),
                  Colors.transparent,
                ],
                radius: 0.7,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Image.asset(
        Assets.gameName,
        width: math.min(MediaQuery.sizeOf(context).width * 0.82, 350),
      ),
    );
  }
}

/// Top bar: coins on the left; stars, how-to-play and settings on the right.
class _TopBar extends StatelessWidget {
  final int coins;
  final int stars;
  final VoidCallback onHowTo;
  final VoidCallback onSettings;
  const _TopBar({
    required this.coins,
    required this.stars,
    required this.onHowTo,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CoinPill(coins: coins),
          Row(
            children: [
              _StarBadge(stars: stars),
              const SizedBox(width: 10),
              RoundIconButton(
                icon: Icons.question_mark_rounded,
                color: AppColors.help,
                onPressed: onHowTo,
              ),
              const SizedBox(width: 10),
              RoundIconButton(
                icon: Icons.settings,
                onPressed: onSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The hero Play button, wrapped in a gently breathing glow ring.
class _PlayButton extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onTap;
  const _PlayButton({required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = 0.5 + 0.5 * math.sin(pulse.value * math.pi * 2);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.play.withValues(alpha: 0.30 + 0.30 * glow),
                blurRadius: 16 + 14 * glow,
                spreadRadius: 1 + 2 * glow,
              ),
            ],
          ),
          child: child,
        );
      },
      child: PrimaryButton(
        label: 'Play',
        icon: Icons.play_arrow_rounded,
        color: AppColors.play,
        width: 268,
        fontSize: 22,
        iconSize: 28,
        onPressed: onTap,
      ),
    );
  }
}

class _SmallMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool wide;
  const _SmallMenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      icon: icon,
      color: color,
      width: wide ? 260 : 124,
      fontSize: wide ? 19 : 14,
      iconSize: wide ? 24 : 18,
      padding: wide
          ? const EdgeInsets.symmetric(vertical: 15, horizontal: 20)
          : const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      onPressed: onTap,
    );
  }
}

class _StarBadge extends StatelessWidget {
  final int stars;
  const _StarBadge({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 4),
          Text('$stars/120',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
