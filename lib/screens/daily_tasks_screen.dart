import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/daily_task.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';

class DailyTasksScreen extends StatelessWidget {
  const DailyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    return Scaffold(
      body: AnimatedBackdrop(
        child: AnimatedBuilder(
          animation: data,
          builder: (context, _) {
            final tasks = data.dailyTasks;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      RoundIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Daily Tasks',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      CoinPill(coins: data.coins),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'New tasks every day. Complete them while you play to claim coins.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) => _TaskCard(index: i, task: tasks[i]),
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

class _TaskCard extends StatelessWidget {
  final int index;
  final DailyTask task;
  const _TaskCard({required this.index, required this.task});

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.claimed
              ? AppColors.safe.withValues(alpha: 0.5)
              : (task.completed ? AppColors.accent : Colors.white12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: task.ratio,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    color: task.completed ? AppColors.safe : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${task.progress}/${task.target}',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                    const Spacer(),
                    Image.asset(Assets.coinChicken, width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text('${task.reward}',
                        style: const TextStyle(color: AppColors.coin, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _claimButton(context, data),
        ],
      ),
    );
  }

  Widget _claimButton(BuildContext context, GameData data) {
    if (task.claimed) {
      return const Icon(Icons.check_circle, color: AppColors.safe, size: 34);
    }
    final canClaim = task.canClaim;
    return Opacity(
      opacity: canClaim ? 1 : 0.5,
      child: GestureDetector(
        onTap: canClaim
            ? () {
                data.claimTask(index);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canClaim
                  ? [AppColors.safe, Color.lerp(AppColors.safe, Colors.black, 0.3)!]
                  : [AppColors.panelLight, AppColors.panel],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Claim',
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }
}
