import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/upgrade_type.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';
import '../core/constants.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      RoundIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Upgrades',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      CoinPill(coins: data.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    children: UpgradeType.values
                        .map((t) => _UpgradeCard(type: t))
                        .toList(),
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

class _UpgradeCard extends StatelessWidget {
  final UpgradeType type;
  const _UpgradeCard({required this.type});

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    final info = UpgradeInfo.of(type);
    final level = data.upgradeLevel(type);
    final maxed = level >= info.maxLevel;
    final cost = info.costForLevel(level + 1);
    final canAfford = data.coins >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(info.icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(info.description,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(info.maxLevel, (i) {
                    return Container(
                      width: 16,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i < level ? AppColors.accent : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  maxed ? 'Maxed out' : 'Next: ${info.effectLabel(level + 1)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.safe),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          maxed
              ? const _MaxBadge()
              : GestureDetector(
                  onTap: canAfford
                      ? () {
                          if (data.buyUpgrade(type)) {
                            AudioService.instance.sfx(Assets.sndUpgrade, volume: 0.8);
                          }
                        }
                      : null,
                  child: Opacity(
                    opacity: canAfford ? 1 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.accentDark]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(Assets.coinChicken, width: 20, height: 20),
                          const SizedBox(height: 2),
                          Text('$cost',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MaxBadge extends StatelessWidget {
  const _MaxBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.safe.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.safe),
      ),
      child: const Text('MAX',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.safe)),
    );
  }
}
