import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import 'game_data.dart';

/// Thin wrapper around FlameAudio that respects the player's sound/music
/// settings and prevents the same short sound from stacking up.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool _ready = false;
  String? _currentMusic;
  double _lastStep = 0;

  // Rapidly creating audio players (one per FlameAudio.play call) is a common
  // source of frame hitches on mobile. We throttle each individual sound so the
  // same clip never gets spawned many times within a few dozen milliseconds
  // (e.g. a batch of enemies all firing "spawn"/"warning" on the same frame).
  final Map<String, int> _lastPlayedMs = {};
  static const int _defaultThrottleMs = 55;

  // A self-healing global rate cap across *all* sounds. Spawning too many
  // platform audio players in a short burst (very common in late endless
  // waves) can overwhelm the native audio subsystem, causing frame hitches or
  // even an ANR/crash. Using a sliding window means the cap can never get
  // stuck (unlike a live "active player" counter that leaks if a completion
  // event is missed).
  final List<int> _recentPlayMs = [];
  static const int _globalWindowMs = 400;
  static const int _globalMaxInWindow = 8;

  Future<void> init() async {
    // Use an empty prefix so we can reference files by their real project path.
    FlameAudio.audioCache.prefix = '';
    try {
      await FlameAudio.audioCache.loadAll(_allSfx);
      _ready = true;
    } catch (e) {
      debugPrint('Audio preload failed: $e');
    }
  }

  static const List<String> _allSfx = [
    Assets.sndButton,
    Assets.sndRun,
    Assets.sndRelight,
    Assets.sndLanternFade,
    Assets.sndSpawn,
    Assets.sndWarning,
    Assets.sndScare,
    Assets.sndCoin,
    Assets.sndEggCollect,
    Assets.sndPowerup,
    Assets.sndEggLost,
    Assets.sndVictory,
    Assets.sndDefeat,
    Assets.sndWave,
    Assets.sndUpgrade,
  ];

  bool get _soundOn => GameData.instance.sound;
  bool get _musicOn => GameData.instance.music;

  void sfx(String path, {double volume = 0.9, int throttleMs = _defaultThrottleMs}) {
    if (!_ready || !_soundOn) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedMs[path];
    if (last != null && now - last < throttleMs) return;

    // Global burst limit (self-healing sliding window).
    _recentPlayMs.removeWhere((t) => now - t > _globalWindowMs);
    if (_recentPlayMs.length >= _globalMaxInWindow) return;

    _lastPlayedMs[path] = now;
    _recentPlayMs.add(now);
    FlameAudio.play(path, volume: volume);
  }

  void button() => sfx(Assets.sndButton, volume: 0.7);

  /// Footsteps are throttled so running never spawns overlapping clips.
  void footstep(double gameTime) {
    if (gameTime - _lastStep < 0.32) return;
    _lastStep = gameTime;
    sfx(Assets.sndRun, volume: 0.35);
  }

  Future<void> playMusic(String path) async {
    if (_currentMusic == path && FlameAudio.bgm.isPlaying) return;
    _currentMusic = path;
    if (!_musicOn) return;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(path, volume: 0.45);
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  Future<void> stopMusic() async {
    _currentMusic = null;
    _lastPlayedMs.clear();
    _recentPlayMs.clear();
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_musicOn || _currentMusic == null) return;
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  /// Re-evaluate music after the setting changes.
  Future<void> applyMusicSetting() async {
    if (_musicOn) {
      if (_currentMusic != null) {
        await FlameAudio.bgm.stop();
        await FlameAudio.bgm.play(_currentMusic!, volume: 0.45);
      }
    } else {
      await FlameAudio.bgm.stop();
    }
  }
}
