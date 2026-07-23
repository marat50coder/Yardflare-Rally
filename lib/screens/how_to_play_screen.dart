import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';

/// A friendly, illustrated rundown of the core game loop. Opened from the (?)
/// button in the main menu.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  static const List<_Step> _steps = [
    _Step(
      icon: Icons.pan_tool_rounded,
      color: AppColors.play,
      title: 'Move',
      body: 'Drag anywhere on the screen to guide your chicken around the yard.',
    ),
    _Step(
      icon: Icons.local_fire_department_rounded,
      color: AppColors.accent,
      title: 'Keep lanterns lit',
      body: 'Stay near a lantern to refuel its flame. A bright lane keeps intruders out.',
    ),
    _Step(
      icon: Icons.bolt_rounded,
      color: AppColors.skins,
      title: 'Scare intruders',
      body: 'Get close, or tap Dash, to spook enemies away before they reach the coop.',
    ),
    _Step(
      icon: Icons.egg_rounded,
      color: AppColors.danger,
      title: 'Protect the eggs',
      body: 'Every intruder that slips through steals an egg. Lose them all and it\'s over.',
    ),
    _Step(
      icon: Icons.monetization_on_rounded,
      color: AppColors.coin,
      title: 'Grab coins & power-ups',
      body: 'Collect coins to buy upgrades and skins, and trigger power-ups for a boost.',
    ),
    _Step(
      icon: Icons.waves_rounded,
      color: AppColors.upgrades,
      title: 'Survive the waves',
      body: 'Clear every wave to complete the level and earn up to three stars.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text('How to Play',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                itemCount: _steps.length,
                itemBuilder: (context, i) => _StepCard(
                  step: _steps[i],
                  index: i,
                  animation: _intro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _StepCard extends StatelessWidget {
  final _Step step;
  final int index;
  final Animation<double> animation;
  const _StepCard({required this.step, required this.index, required this.animation});

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final v = curved.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset((1 - v) * 40, 0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: step.color.withValues(alpha: 0.55), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  step.color.withValues(alpha: 0.85),
                  step.color.withValues(alpha: 0.35),
                ]),
                boxShadow: [
                  BoxShadow(color: step.color.withValues(alpha: 0.4), blurRadius: 8),
                ],
              ),
              child: Icon(step.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: step.color,
                      )),
                  const SizedBox(height: 4),
                  Text(step.body,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: AppColors.textDim,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
