import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/location.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';
import 'level_map_screen.dart';

class LocationSelectScreen extends StatelessWidget {
  const LocationSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    return Scaffold(
      body: AnimatedBackdrop(
        child: AnimatedBuilder(
          animation: data,
          builder: (context, _) {
            return Column(
              children: [
                _Header(title: 'Choose a Location'),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: GameLocation.all.length,
                    itemBuilder: (context, i) {
                      final loc = GameLocation.all[i];
                      final unlocked = data.isLevelUnlocked(loc.firstLevelId);
                      int stars = 0;
                      for (int id = loc.firstLevelId; id <= loc.lastLevelId; id++) {
                        stars += data.starsFor(id);
                      }
                      return _LocationCard(
                        location: loc,
                        unlocked: unlocked,
                        stars: stars,
                        onTap: unlocked
                            ? () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => LevelMapScreen(location: loc)))
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          CoinPill(coins: GameData.instance.coins),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final GameLocation location;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  const _LocationCard({
    required this.location,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Card(
        color: location.themeColor.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: location.themeColor.withValues(alpha: 0.7), width: 2),
        ),
        margin: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Image.asset(Assets.coops[location.coopIndex], height: 74),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(location.tagline,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                          const SizedBox(width: 4),
                          Text('$stars / 30',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          Text('Levels ${location.firstLevelId}-${location.lastLevelId}',
                              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(unlocked ? Icons.chevron_right : Icons.lock,
                    color: unlocked ? AppColors.textLight : AppColors.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
