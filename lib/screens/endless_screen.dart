import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';
import 'gameplay_screen.dart';

class EndlessScreen extends StatelessWidget {
  const EndlessScreen({super.key});

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

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
                        child: Text('Endless Mode',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      CoinPill(coins: data.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Image.asset(Assets.coops[3], height: 120),
                          const SizedBox(height: 8),
                          const Text(
                            'Survive as long as you can.\nEnemies grow fiercer every wave.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textDim, fontSize: 15),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 300,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                const Text('Local Records',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(height: 10),
                                _record('Best Wave', '${data.endlessBestWave}', Icons.waves),
                                _record('Best Score', '${data.endlessBestScore}', Icons.emoji_events),
                                _record('Best Time', _fmt(data.endlessBestTime), Icons.timer),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Start Run',
                            icon: Icons.play_arrow_rounded,
                            color: AppColors.safe,
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const GameplayScreen.endless()),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
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

  Widget _record(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDim))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
