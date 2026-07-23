import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/skin.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

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
                        child: Text('Chicken Skins',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      CoinPill(coins: data.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: ChickenSkin.all.length,
                    itemBuilder: (context, i) {
                      final skin = ChickenSkin.all[i];
                      final unlocked = data.isSkinUnlocked(skin.id);
                      final selected = data.selectedSkin == skin.id;
                      return _SkinCard(
                        skin: skin,
                        unlocked: unlocked,
                        selected: selected,
                        onTap: () => _handleTap(context, skin, unlocked, selected),
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

  void _handleTap(BuildContext context, ChickenSkin skin, bool unlocked, bool selected) {
    final data = GameData.instance;
    if (unlocked) {
      if (!selected) data.selectSkin(skin.id);
    } else {
      if (data.coins >= skin.cost) {
        data.buySkin(skin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough coins. Need ${skin.cost}.'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }
}

class _SkinCard extends StatelessWidget {
  final ChickenSkin skin;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (selected ? AppColors.accent : AppColors.panelLight).withValues(alpha: 0.35),
              AppColors.panel.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white12,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: unlocked ? 1 : 0.45,
                    child: Image.asset(skin.sprite),
                  ),
                  if (!unlocked)
                    const Icon(Icons.lock, color: Colors.white70, size: 30),
                ],
              ),
            ),
            Text(skin.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    if (selected) {
      return const Text('Equipped', style: TextStyle(color: AppColors.safe, fontWeight: FontWeight.w700));
    }
    if (unlocked) {
      return const Text('Tap to equip', style: TextStyle(color: AppColors.textDim, fontSize: 12));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(Assets.coinChicken, width: 18, height: 18),
        const SizedBox(width: 4),
        Text('${skin.cost}',
            style: const TextStyle(color: AppColors.coin, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
