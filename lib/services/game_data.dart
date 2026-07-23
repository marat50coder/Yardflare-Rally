import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_task.dart';
import '../models/save_state.dart';
import '../models/skin.dart';
import '../models/upgrade_type.dart';

/// Central persisted game state. A single [ChangeNotifier] the whole UI listens
/// to. Handles safe loading, defaults and corruption recovery.
class GameData extends ChangeNotifier {
  GameData._();
  static final GameData instance = GameData._();

  static const _key = 'yardflare_save_v1';

  SharedPreferences? _prefs;
  SaveState _state = SaveState();

  SaveState get state => _state;
  int get coins => _state.coins;
  ControlMode get controlMode => _state.controlMode;
  bool get music => _state.music;
  bool get sound => _state.sound;
  bool get vibration => _state.vibration;
  int get selectedSkin => _state.selectedSkin;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_key);
    if (raw == null || raw.isEmpty) {
      _state = SaveState();
    } else {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _state = SaveState.fromJson(decoded);
        } else {
          _state = SaveState();
        }
      } catch (_) {
        // Corrupted save -> start clean rather than crash.
        _state = SaveState();
      }
    }
    // Joystick control has been retired; everyone plays with drag-to-move now,
    // so normalise any previously-saved joystick preference.
    if (_state.controlMode == ControlMode.joystick) {
      _state.controlMode = ControlMode.drag;
    }
    _refreshDailyTasks();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_key, jsonEncode(_state.toJson()));
    } catch (_) {
      // Ignore write failures; the in-memory state stays valid.
    }
  }

  void _save() {
    notifyListeners();
    _persist();
  }

  // ---------------- Coins ----------------
  void addCoins(int amount) {
    if (amount <= 0) return;
    _state.coins += amount;
    _save();
  }

  bool trySpend(int amount) {
    if (amount <= 0 || _state.coins < amount) return false;
    _state.coins -= amount;
    _save();
    return true;
  }

  // ---------------- Levels ----------------
  int starsFor(int levelId) => _state.levelStars[levelId] ?? 0;

  bool isLevelUnlocked(int id) => _state.isLevelUnlocked(id);
  // Endless mode is always available now (no longer gated behind clearing
  // level 40), so it can be played from the start.
  bool get endlessUnlocked => true;
  int get totalStars => _state.totalStars;

  /// Records a finished level. Coins are added and the best star count kept.
  void recordLevel(int levelId, int stars, int coinsEarned) {
    final prev = _state.levelStars[levelId] ?? 0;
    if (stars > prev) _state.levelStars[levelId] = stars;
    _state.coins += coinsEarned;
    _save();
  }

  // ---------------- Skins ----------------
  bool isSkinUnlocked(int id) => _state.unlockedSkins.contains(id);

  bool buySkin(ChickenSkin skin) {
    if (isSkinUnlocked(skin.id)) return false;
    if (!trySpend(skin.cost)) return false;
    _state.unlockedSkins.add(skin.id);
    _state.selectedSkin = skin.id;
    _save();
    return true;
  }

  void selectSkin(int id) {
    if (!isSkinUnlocked(id)) return;
    _state.selectedSkin = id;
    _save();
  }

  // ---------------- Upgrades ----------------
  int upgradeLevel(UpgradeType type) => _state.upgradeLevels[type.index] ?? 0;

  bool buyUpgrade(UpgradeType type) {
    final info = UpgradeInfo.of(type);
    final current = upgradeLevel(type);
    if (current >= info.maxLevel) return false;
    final cost = info.costForLevel(current + 1);
    if (!trySpend(cost)) return false;
    _state.upgradeLevels[type.index] = current + 1;
    _save();
    return true;
  }

  // ---------------- Endless ----------------
  void updateEndless(int wave, int score, int timeSeconds) {
    var changed = false;
    if (wave > _state.endlessBestWave) {
      _state.endlessBestWave = wave;
      changed = true;
    }
    if (score > _state.endlessBestScore) {
      _state.endlessBestScore = score;
      changed = true;
    }
    if (timeSeconds > _state.endlessBestTime) {
      _state.endlessBestTime = timeSeconds;
      changed = true;
    }
    if (changed) _save();
  }

  int get endlessBestWave => _state.endlessBestWave;
  int get endlessBestScore => _state.endlessBestScore;
  int get endlessBestTime => _state.endlessBestTime;

  // ---------------- Settings ----------------
  void setMusic(bool v) {
    _state.music = v;
    _save();
  }

  void setSound(bool v) {
    _state.sound = v;
    _save();
  }

  void setVibration(bool v) {
    _state.vibration = v;
    _save();
  }

  void setControlMode(ControlMode m) {
    _state.controlMode = m;
    _save();
  }

  // ---------------- Tutorial ----------------
  bool get tutorialDone => _state.tutorialDone;
  void markTutorialDone() {
    if (_state.tutorialDone) return;
    _state.tutorialDone = true;
    _save();
  }

  // ---------------- Daily tasks ----------------
  List<DailyTask> get dailyTasks => _state.dailyTasks;

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _refreshDailyTasks() {
    final today = todayKey();
    if (_state.dailyDate == today && _state.dailyTasks.length == 3) return;
    _state.dailyDate = today;
    _state.dailyTasks = pickDailyTasks(today);
  }

  /// Deterministically choose 3 distinct tasks for a given date string.
  static List<DailyTask> pickDailyTasks(String dateKey) {
    final seed = dateKey.codeUnits.fold<int>(7, (a, b) => a * 31 + b);
    final rng = Random(seed);
    final pool = List<DailyTaskDef>.from(DailyTaskDef.pool);
    pool.shuffle(rng);
    return pool
        .take(3)
        .map((d) => DailyTask(type: d.type, target: d.target, reward: d.reward))
        .toList();
  }

  void addTaskProgress(DailyTaskType type, int amount) {
    if (amount <= 0) return;
    var changed = false;
    for (final task in _state.dailyTasks) {
      if (task.type == type && !task.completed) {
        task.progress = min(task.target, task.progress + amount);
        changed = true;
      }
    }
    if (changed) _save();
  }

  bool claimTask(int index) {
    if (index < 0 || index >= _state.dailyTasks.length) return false;
    final task = _state.dailyTasks[index];
    if (!task.canClaim) return false;
    task.claimed = true;
    _state.coins += task.reward;
    _save();
    return true;
  }

  // ---------------- Reset ----------------
  Future<void> resetProgress() async {
    _state = SaveState();
    _refreshDailyTasks();
    notifyListeners();
    await _persist();
  }
}
