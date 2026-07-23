import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/levels_data.dart';
import '../models/level_config.dart';
import '../models/location.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';
import 'gameplay_screen.dart';

class LevelMapScreen extends StatefulWidget {
  final GameLocation location;
  const LevelMapScreen({super.key, required this.location});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  void _play(LevelConfig level) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameplayScreen(level: level)))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    final levels = LevelsData.forLocation(widget.location.id);
    return Scaffold(
      body: AnimatedBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  RoundIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.location.name,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  ),
                  CoinPill(coins: data.coins),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(18),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: levels.length,
                itemBuilder: (context, i) {
                  final level = levels[i];
                  final unlocked = data.isLevelUnlocked(level.id);
                  final stars = data.starsFor(level.id);
                  return _LevelNode(
                    level: level,
                    unlocked: unlocked,
                    stars: stars,
                    color: widget.location.themeColor,
                    onTap: unlocked ? () => _play(level) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final LevelConfig level;
  final bool unlocked;
  final int stars;
  final Color color;
  final VoidCallback? onTap;

  const _LevelNode({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBoss = level.special == SpecialCondition.miniBoss ||
        level.special == SpecialCondition.finalChallenge;
    return Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.15)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBoss ? AppColors.danger : color.withValues(alpha: 0.7),
                width: isBoss ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBoss)
                  const Icon(Icons.whatshot, color: AppColors.danger, size: 18)
                else
                  const SizedBox(height: 18),
                Text('${level.indexInLocation}',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                if (unlocked)
                  StarRow(stars: stars, size: 14)
                else
                  const Icon(Icons.lock, size: 16, color: AppColors.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
