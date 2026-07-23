import 'daily_task.dart';

enum ControlMode { joystick, drag }

/// The complete, serializable player profile persisted between launches.
///
/// Every field has a safe default so a missing or corrupted save simply falls
/// back to a fresh profile instead of crashing.
class SaveState {
  bool tutorialDone;
  int coins;

  /// level id (1..40) -> stars earned (0..3).
  Map<int, int> levelStars;

  List<int> unlockedSkins;
  int selectedSkin;

  /// UpgradeType.index -> level owned.
  Map<int, int> upgradeLevels;

  int endlessBestWave;
  int endlessBestScore;
  int endlessBestTime; // seconds

  // Daily tasks.
  String dailyDate; // yyyy-mm-dd the tasks belong to
  List<DailyTask> dailyTasks;

  // Settings.
  bool music;
  bool sound;
  bool vibration;
  ControlMode controlMode;

  SaveState({
    this.tutorialDone = false,
    this.coins = 0,
    Map<int, int>? levelStars,
    List<int>? unlockedSkins,
    this.selectedSkin = 1,
    Map<int, int>? upgradeLevels,
    this.endlessBestWave = 0,
    this.endlessBestScore = 0,
    this.endlessBestTime = 0,
    this.dailyDate = '',
    List<DailyTask>? dailyTasks,
    this.music = true,
    this.sound = true,
    this.vibration = true,
    this.controlMode = ControlMode.drag,
  })  : levelStars = levelStars ?? {},
        unlockedSkins = unlockedSkins ?? [1],
        upgradeLevels = upgradeLevels ?? {},
        dailyTasks = dailyTasks ?? [];

  int get highestUnlockedLevel {
    int maxCompleted = 0;
    levelStars.forEach((level, stars) {
      if (stars > 0 && level > maxCompleted) maxCompleted = level;
    });
    return (maxCompleted + 1).clamp(1, 40);
  }

  bool isLevelUnlocked(int id) => id <= highestUnlockedLevel;
  bool get endlessUnlocked => (levelStars[40] ?? 0) > 0;
  int get totalStars =>
      levelStars.values.fold(0, (sum, s) => sum + s);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'tutorialDone': tutorialDone,
        'coins': coins,
        'levelStars': levelStars.map((k, v) => MapEntry(k.toString(), v)),
        'unlockedSkins': unlockedSkins,
        'selectedSkin': selectedSkin,
        'upgradeLevels': upgradeLevels.map((k, v) => MapEntry(k.toString(), v)),
        'endlessBestWave': endlessBestWave,
        'endlessBestScore': endlessBestScore,
        'endlessBestTime': endlessBestTime,
        'dailyDate': dailyDate,
        'dailyTasks': dailyTasks.map((t) => t.toJson()).toList(),
        'music': music,
        'sound': sound,
        'vibration': vibration,
        'controlMode': controlMode.index,
      };

  factory SaveState.fromJson(Map<String, dynamic> j) {
    Map<int, int> parseIntMap(dynamic raw) {
      final out = <int, int>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          final key = int.tryParse(k.toString());
          final val = (v is num) ? v.toInt() : int.tryParse(v.toString());
          if (key != null && val != null) out[key] = val;
        });
      }
      return out;
    }

    List<int> parseIntList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => (e as num).toInt()).toList();
      }
      return [1];
    }

    int parseInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool parseBool(dynamic v, bool fallback) => v is bool ? v : fallback;

    final skins = parseIntList(j['unlockedSkins']);
    if (!skins.contains(1)) skins.add(1);

    final tasks = <DailyTask>[];
    final rawTasks = j['dailyTasks'];
    if (rawTasks is List) {
      for (final t in rawTasks) {
        if (t is Map) {
          tasks.add(DailyTask.fromJson(Map<String, dynamic>.from(t)));
        }
      }
    }

    return SaveState(
      tutorialDone: parseBool(j['tutorialDone'], false),
      coins: parseInt(j['coins'], 0),
      levelStars: parseIntMap(j['levelStars']),
      unlockedSkins: skins,
      selectedSkin: parseInt(j['selectedSkin'], 1),
      upgradeLevels: parseIntMap(j['upgradeLevels']),
      endlessBestWave: parseInt(j['endlessBestWave'], 0),
      endlessBestScore: parseInt(j['endlessBestScore'], 0),
      endlessBestTime: parseInt(j['endlessBestTime'], 0),
      dailyDate: j['dailyDate'] is String ? j['dailyDate'] as String : '',
      dailyTasks: tasks,
      music: parseBool(j['music'], true),
      sound: parseBool(j['sound'], true),
      vibration: parseBool(j['vibration'], true),
      controlMode: ControlMode.values[
          parseInt(j['controlMode'], ControlMode.drag.index)
              .clamp(0, ControlMode.values.length - 1)],
    );
  }
}
