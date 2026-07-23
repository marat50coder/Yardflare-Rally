/// The kinds of daily task the game can hand out.
enum DailyTaskType {
  surviveWaves,
  relightLanterns,
  collectCoins,
  scareEnemies,
  noEggLostRun,
  usePowerups,
  levelAllLanternsLit,
}

/// Static definition of a task type.
class DailyTaskDef {
  final DailyTaskType type;
  final int target;
  final int reward;

  const DailyTaskDef(this.type, this.target, this.reward);

  String get description {
    switch (type) {
      case DailyTaskType.surviveWaves:
        return 'Survive $target waves';
      case DailyTaskType.relightLanterns:
        return 'Relight $target lanterns';
      case DailyTaskType.collectCoins:
        return 'Collect $target coins';
      case DailyTaskType.scareEnemies:
        return 'Scare away $target enemies';
      case DailyTaskType.noEggLostRun:
        return 'Finish a run without losing an egg';
      case DailyTaskType.usePowerups:
        return 'Use $target power-ups';
      case DailyTaskType.levelAllLanternsLit:
        return 'Complete a level with all lanterns lit';
    }
  }

  static const List<DailyTaskDef> pool = [
    DailyTaskDef(DailyTaskType.surviveWaves, 10, 120),
    DailyTaskDef(DailyTaskType.relightLanterns, 300, 150),
    DailyTaskDef(DailyTaskType.collectCoins, 1000, 150),
    DailyTaskDef(DailyTaskType.scareEnemies, 100, 130),
    DailyTaskDef(DailyTaskType.noEggLostRun, 1, 140),
    DailyTaskDef(DailyTaskType.usePowerups, 20, 120),
    DailyTaskDef(DailyTaskType.levelAllLanternsLit, 1, 130),
  ];
}

/// A live daily task with progress and claim status.
class DailyTask {
  final DailyTaskType type;
  final int target;
  final int reward;
  int progress;
  bool claimed;

  DailyTask({
    required this.type,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.claimed = false,
  });

  DailyTaskDef get def =>
      DailyTaskDef.pool.firstWhere((d) => d.type == type);

  bool get completed => progress >= target;
  bool get canClaim => completed && !claimed;
  double get ratio => (progress / target).clamp(0.0, 1.0);
  String get description => def.description;

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'target': target,
        'reward': reward,
        'progress': progress,
        'claimed': claimed,
      };

  factory DailyTask.fromJson(Map<String, dynamic> j) => DailyTask(
        type: DailyTaskType.values[(j['type'] as int).clamp(0, DailyTaskType.values.length - 1)],
        target: j['target'] as int,
        reward: j['reward'] as int,
        progress: j['progress'] as int? ?? 0,
        claimed: j['claimed'] as bool? ?? false,
      );
}
