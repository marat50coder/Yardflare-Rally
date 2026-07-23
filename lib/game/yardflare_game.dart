import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/enemy_type.dart';
import '../models/level_config.dart';
import '../models/level_result.dart';
import '../models/powerup_type.dart';
import '../models/daily_task.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import 'components/background_layer.dart';
import 'components/chicken.dart';
import 'components/coin.dart';
import 'components/coop.dart';
import 'components/lantern.dart';
import 'components/powerup_pickup.dart';
import 'components/warning_marker.dart';
import 'effects/effects.dart';
import 'enemies/enemy.dart';
import 'game_session_config.dart';
import 'sprite_bank.dart';
import 'systems/hud_state.dart';

enum GamePhase { intro, tutorial, prepare, wave, rest, finished }

class _PendingSpawn {
  final int laneIndex;
  final EnemyType type;
  double timer;
  _PendingSpawn(this.laneIndex, this.type, this.timer);
}

class _ActivePowerup {
  final PowerUpType type;
  double remaining;
  final double total;
  _ActivePowerup(this.type, this.remaining, this.total);
}

/// The complete Flame game: chicken, lanterns, enemies, waves, power-ups,
/// combos, scoring and the interactive tutorial.
class YardflareGame extends FlameGame {
  YardflareGame({
    required this.config,
    required this.onFinished,
    required this.onVibrate,
  });

  final GameSessionConfig config;
  final void Function(LevelResult result, bool won) onFinished;
  final void Function(int intensity) onVibrate; // 0 light,1 medium,2 strong

  final SpriteBank bank = SpriteBank();
  final AudioService audio = AudioService.instance;
  final HudState hud = HudState();

  final math.Random _rng = math.Random();

  late Chicken chicken;
  late Coop coop;
  final List<Lantern> lanterns = [];

  bool _ready = false;
  double elapsed = 0;
  double survivalTime = 0;

  Vector2 moveInput = Vector2.zero();

  // Phase / wave state.
  GamePhase phase = GamePhase.intro;
  double _phaseTimer = 0;
  int currentWave = 0;
  int wavesCompleted = 0;
  double _spawnTimer = 0;
  final List<_PendingSpawn> _pending = [];

  // Scoring / stats.
  int score = 0;
  int sessionCoins = 0;
  int combo = 0;
  int maxCombo = 0;
  int enemiesScared = 0;
  int lanternsRelit = 0;
  int coinsForObjective = 0;
  int powerupsUsed = 0;
  bool usedShield = false;
  int eggs = 0;
  int startingEggs = 0;

  // Power-up effects.
  final List<_ActivePowerup> _active = [];
  final List<PowerUpType> _inventory = [];
  bool shieldActive = false;
  double _coinMultiplier = 1;
  double _magnetMultiplier = 1;
  bool _buddyActive = false;
  double timeScale = 1;

  // Daily-task accumulators (flushed once at the end to avoid frequent writes).
  int _dtRelight = 0, _dtCoins = 0, _dtScare = 0, _dtPowerups = 0;

  double get coopReachRadius => 44;
  Vector2 get coopPosition => coop.position;
  double get coinMagnetRadius => config.coinMagnetRadius * _magnetMultiplier;

  Rect get playBounds {
    final top = _playTop;
    final bottom = _playBottom;
    return Rect.fromLTRB(28, top, size.x - 28, bottom);
  }

  double get _playTop => 92;
  double get _playBottom => size.y - 150;

  @override
  Color backgroundColor() => const Color(0xFF0A1020);

  @override
  Future<void> onLoad() async {
    images.prefix = '';
    await bank.loadAll(images);

    add(BackgroundLayer(backgroundIndex: config.level?.backgroundIndex ?? 5));
    add(LaneLayer());

    _layoutField();

    coop = Coop(position: _coopCenter(), coopIndex: _coopIndex());
    add(coop);

    _buildLanterns();

    chicken = Chicken(
      position: coop.position + Vector2(0, 70),
      baseSpeed: config.chickenSpeed,
      dashCooldown: config.dashCooldown,
      skinId: config.selectedSkin,
    );
    add(chicken);

    startingEggs = config.startingEggs;
    eggs = startingEggs;

    hud.eggs.value = eggs;
    hud.maxEggs.value = startingEggs;
    hud.coins.value = 0;
    hud.waveTotal.value = config.endless ? 0 : config.waveCount;
    hud.lanternTotal.value = lanterns.length;
    hud.endless.value = config.endless;
    hud.combo.value = 0;
    hud.score.value = 0;

    // Start music.
    audio.playMusic(Assets.musicGame);

    _ready = true;
    if (config.isTutorial && !GameData.instance.tutorialDone) {
      _startTutorial();
    } else {
      _enterPrepare();
    }
  }

  // ---------------- Layout ----------------
  double _rx = 100, _ry = 100;

  void _layoutField() {
    final centerY = (_playTop + _playBottom) / 2;
    _rx = size.x * 0.36;
    _ry = (_playBottom - _playTop) * 0.34;
    _fieldCenter = Vector2(size.x / 2, centerY);
  }

  Vector2 _fieldCenter = Vector2.zero();
  Vector2 _coopCenter() => _fieldCenter.clone();
  int _coopIndex() => config.locationId.clamp(0, Assets.coops.length - 1);

  void _buildLanterns() {
    lanterns.clear();
    final n = config.lanternCount;
    final rectInset = Rect.fromLTRB(30, _playTop + 4, size.x - 30, _playBottom + 40);
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / n);
      final dir = Vector2(math.cos(angle) * _rx, math.sin(angle) * _ry);
      final lanternPos = _fieldCenter + dir;
      final unit = dir.normalized();
      final spawn = _rayToRect(_fieldCenter, unit, rectInset);
      // Wind affects a couple of lanterns in windy levels.
      double windMult = 1.0;
      if (config.special == SpecialCondition.wind && i.isEven) windMult = 1.7;
      final lantern = Lantern(
        laneIndex: i,
        laneAngle: angle,
        spawnPoint: spawn,
        position: lanternPos,
        decayRate: config.decayRate,
        rechargeRadius: GameTuning.lanternRechargeRadius,
        charge: 1.0,
        windMultiplier: windMult,
      );
      lanterns.add(lantern);
      add(lantern);
    }
  }

  Vector2 _rayToRect(Vector2 origin, Vector2 dir, Rect rect) {
    double t = double.infinity;
    if (dir.x.abs() > 1e-6) {
      final tx = (dir.x > 0 ? rect.right - origin.x : rect.left - origin.x) / dir.x;
      if (tx > 0) t = math.min(t, tx);
    }
    if (dir.y.abs() > 1e-6) {
      final ty = (dir.y > 0 ? rect.bottom - origin.y : rect.top - origin.y) / dir.y;
      if (ty > 0) t = math.min(t, ty);
    }
    if (!t.isFinite) t = 100;
    return origin + dir * t;
  }

  // ---------------- Update loop ----------------
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready || paused || phase == GamePhase.finished) return;

    // Clamp dt so a hitch never teleports anything.
    dt = math.min(dt, 0.05);
    elapsed += dt;
    if (phase == GamePhase.wave || phase == GamePhase.rest || phase == GamePhase.prepare) {
      survivalTime += dt;
    }

    // Query the live enemies exactly once per frame and reuse the list across
    // the systems below. children.query<Enemy>() allocates + filters on every
    // call, and it was previously being run several times each frame.
    _enemyCache
      ..clear()
      ..addAll(children.query<Enemy>());

    _updatePowerups(dt);
    _recharge(dt);
    _scareNearby();
    _updateBuddy(dt);
    _updatePhase(dt);
    _updateHud();
  }

  final List<Enemy> _enemyCache = [];

  void _recharge(double dt) {
    final rate = config.rechargePerSecond / 100.0;
    for (final l in lanterns) {
      if (chicken.position.distanceTo(l.position) <= l.rechargeRadius) {
        final becameFull = l.addCharge(rate * dt);
        if (becameFull) _onPerfectRelight(l);
      }
    }
  }

  void _updateBuddy(double dt) {
    if (!_buddyActive) return;
    Lantern? darkest;
    for (final l in lanterns) {
      if (darkest == null || l.charge < darkest.charge) darkest = l;
    }
    if (darkest != null && darkest.charge < 1.0) {
      final becameFull = darkest.addCharge((config.rechargePerSecond / 100.0) * 1.2 * dt);
      if (becameFull) _onPerfectRelight(darkest, buddy: true);
    }
  }

  void _scareNearby() {
    final radius = chicken.isDashing ? GameTuning.dashScareRadius : GameTuning.scareRadius;
    for (final e in _enemyCache) {
      if (e.isScared) continue;
      if (chicken.position.distanceTo(e.position) <= radius + e.kind.radius * 0.4) {
        final off = e.scare(knockback: chicken.isDashing ? 1.8 : 1.0);
        if (off) _onEnemyScared(e);
      }
    }
  }

  // ---------------- Phase machine ----------------
  void _enterPrepare() {
    phase = GamePhase.prepare;
    currentWave++;
    _phaseTimer = 3.0;
    hud.wave.value = currentWave;
    hud.phase.value = 'Wave $currentWave';
    hud.showBanner('Wave $currentWave');
    audio.sfx(Assets.sndWave, volume: 0.7);
  }

  void _enterWave() {
    phase = GamePhase.wave;
    _phaseTimer = _currentWaveDuration();
    _spawnTimer = 1.0;
    hud.phase.value = 'Defend!';
    _maybeSpawnBoss();
  }

  /// Mini-boss levels send in a guaranteed Boar on their final wave.
  void _maybeSpawnBoss() {
    final isFinalWave = currentWave == config.waveCount;
    final boss = (config.special == SpecialCondition.miniBoss && isFinalWave) ||
        (config.special == SpecialCondition.finalChallenge && isFinalWave);
    if (!boss || lanterns.isEmpty) return;
    final lane = _rng.nextInt(lanterns.length);
    final spawn = lanterns[lane].spawnPoint;
    final toCoop = coopPosition - spawn;
    add(WarningMarker(
      position: spawn,
      enemyType: EnemyType.boar,
      angleToCoop: math.atan2(toCoop.y, toCoop.x),
      life: GameTuning.spawnWarningTime + 0.6,
    ));
    _pending.add(_PendingSpawn(lane, EnemyType.boar, GameTuning.spawnWarningTime + 0.6));
    hud.showBanner('Mini-Boss: Boar!');
    audio.sfx(Assets.sndWarning, volume: 0.7);
    onVibrate(2);
  }

  double _currentWaveDuration() {
    if (config.endless) return config.waveDuration + math.min(currentWave * 0.6, 20);
    return config.waveDuration;
  }

  void _enterRest() {
    phase = GamePhase.rest;
    wavesCompleted++;
    _phaseTimer = GameTuning.restBetweenWaves;
    hud.phase.value = 'Rest';

    // Wave clear reward.
    final reward = 12 + currentWave * 2;
    sessionCoins += reward;
    hud.coins.value = sessionCoins;
    _spawnFloatingText(coop.position - Vector2(0, 70), '+$reward', _coinCol);
    hud.showBanner('Wave $currentWave cleared!  +$reward');

    if (config.endless && currentWave % 5 == 0) {
      final bonus = 60 + currentWave * 3;
      sessionCoins += bonus;
      hud.coins.value = sessionCoins;
      hud.showBanner('Milestone! +$bonus coins');
    }

    // Chance to drop a power-up as a reward between waves.
    if (config.powerups.isNotEmpty && _rng.nextDouble() < 0.7) {
      _dropRandomPowerup();
    }
    chicken.celebrate();
  }

  void _updatePhase(double dt) {
    switch (phase) {
      case GamePhase.tutorial:
        _updateTutorial(dt);
        break;
      case GamePhase.prepare:
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) _enterWave();
        break;
      case GamePhase.wave:
        _phaseTimer -= dt;
        hud.waveTimeLeft.value = math.max(0, _phaseTimer);
        _updateSpawns(dt);
        // Only pay for the live enemy query in the rare frame where the wave is
        // otherwise ready to end, so it stays accurate for enemies spawned this
        // same frame while avoiding a per-frame allocation during the wave.
        if (_phaseTimer <= 0 && _pending.isEmpty &&
            children.query<Enemy>().every((e) => e.isScared)) {
          _onWaveCleared();
        }
        break;
      case GamePhase.rest:
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          if (!config.endless && currentWave >= config.waveCount) {
            _win();
          } else {
            _enterPrepare();
          }
        }
        break;
      case GamePhase.intro:
      case GamePhase.finished:
        break;
    }
  }

  void _onWaveCleared() {
    if (!config.endless && currentWave >= config.waveCount) {
      wavesCompleted++;
      _win();
      return;
    }
    _enterRest();
  }

  // ---------------- Spawning ----------------
  void _updateSpawns(double dt) {
    final s = dt * timeScale;
    // Resolve pending (already-warned) spawns.
    for (final p in List<_PendingSpawn>.from(_pending)) {
      p.timer -= s;
      if (p.timer <= 0) {
        _spawnEnemy(p.laneIndex, p.type);
        _pending.remove(p);
      }
    }

    _spawnTimer -= s;
    if (_spawnTimer > 0) return;

    final interval = _currentSpawnInterval();
    _spawnTimer = interval * (0.8 + _rng.nextDouble() * 0.4);

    // Hard cap on simultaneous intruders. Without this, a long or struggling
    // endless run can pile up hundreds of live components, which balloons the
    // per-frame cost until the app hitches and Android's watchdog kills it
    // (ANR). New spawns simply wait until the field thins out again.
    final liveEnemies = _enemyCache.length + _pending.length;
    if (liveEnemies >= _maxLiveEnemies) return;

    final batch = _spawnBatchSize();
    for (int i = 0; i < batch; i++) {
      _scheduleSpawn();
    }
  }

  static const int _maxLiveEnemies = 26;

  double _currentSpawnInterval() {
    if (config.endless) {
      return math.max(0.7, config.spawnInterval - currentWave * 0.06);
    }
    return config.spawnInterval;
  }

  int _spawnBatchSize() {
    if (config.endless) return 1 + (currentWave ~/ 4).clamp(0, 3) + (_rng.nextDouble() < 0.3 ? 1 : 0);
    final base = currentWave >= config.waveCount ? 2 : 1;
    return base + (_rng.nextDouble() < 0.25 ? 1 : 0);
  }

  void _scheduleSpawn() {
    // Pick a lane weighted by how dark it is (darker = more likely).
    final weights = <double>[];
    double sum = 0;
    for (final l in lanterns) {
      final w = 0.15 + (1 - l.charge) * 1.6;
      weights.add(w);
      sum += w;
    }
    double r = _rng.nextDouble() * sum;
    int lane = 0;
    for (int i = 0; i < weights.length; i++) {
      r -= weights[i];
      if (r <= 0) {
        lane = i;
        break;
      }
    }

    final type = _pickEnemyType();
    final kind = EnemyKind.of(type);
    final spawn = lanterns[lane].spawnPoint;
    final toCoop = coopPosition - spawn;
    final angle = math.atan2(toCoop.y, toCoop.x);
    add(WarningMarker(
      position: spawn,
      enemyType: type,
      angleToCoop: angle,
      life: GameTuning.spawnWarningTime,
    ));
    audio.sfx(Assets.sndWarning, volume: 0.4);
    onVibrate(0);
    hud.showBanner('${kind.name} incoming!');

    _pending.add(_PendingSpawn(lane, type, GameTuning.spawnWarningTime));

    // Mice arrive as a little group.
    if (kind.spawnsInGroups) {
      final extra = 1 + _rng.nextInt(2);
      for (int i = 0; i < extra; i++) {
        _pending.add(_PendingSpawn(lane, type, GameTuning.spawnWarningTime + 0.4 * (i + 1)));
      }
    }
  }

  EnemyType _pickEnemyType() {
    List<EnemyType> pool = List<EnemyType>.from(config.enemies);
    if (config.endless) {
      pool = _endlessPool();
    }
    // Weight: tougher/elite enemies are rarer.
    final weights = <double>[];
    double sum = 0;
    for (final t in pool) {
      final k = EnemyKind.of(t);
      double w = 1.0;
      if (k.elite) w = 0.4;
      if (k.miniBoss) w = 0.25;
      if (k.toughness > 1) w *= 0.7;
      weights.add(w);
      sum += w;
    }
    double r = _rng.nextDouble() * sum;
    for (int i = 0; i < pool.length; i++) {
      r -= weights[i];
      if (r <= 0) return pool[i];
    }
    return pool.last;
  }

  List<EnemyType> _endlessPool() {
    final w = currentWave;
    final pool = <EnemyType>[EnemyType.mouse, EnemyType.raccoon, EnemyType.fox];
    if (w >= 3) pool.add(EnemyType.badger);
    if (w >= 4) pool.add(EnemyType.owl);
    if (w >= 6) pool.add(EnemyType.crow);
    if (w >= 8) pool.add(EnemyType.wolf);
    if (w >= 11) pool.add(EnemyType.boar);
    return pool;
  }

  void _spawnEnemy(int lane, EnemyType type) {
    if (lane < 0 || lane >= lanterns.length) return;
    final kind = EnemyKind.of(type);
    final l = lanterns[lane];
    var pos = l.spawnPoint.clone();
    // Owls "fly" partway in.
    if (kind.flies) {
      pos = pos + (coopPosition - pos) * 0.35;
    }
    final scale = config.endless ? (1 + currentWave * 0.012).clamp(1.0, 1.7) : 1.0;
    add(Enemy(kind: kind, lane: l, position: pos, speedScale: scale.toDouble()));
    audio.sfx(Assets.sndSpawn, volume: 0.5);
  }

  // ---------------- Interactions ----------------
  void _onPerfectRelight(Lantern l, {bool buddy = false}) {
    if (!buddy) {
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      hud.combo.value = combo;
    }
    lanternsRelit++;
    _dtRelight++;
    final mult = _comboMultiplier();
    final gained = (15 * mult).round();
    score += gained;
    audio.sfx(Assets.sndRelight, volume: 0.7);
    add(RingEffect(position: l.position, color: _safeCol, maxRadius: 70, duration: 0.45));
    add(BurstEffect(position: l.position, color: _accentCol, count: 10, speed: 110));
    _spawnFloatingText(l.position - Vector2(0, 30),
        combo > 1 && !buddy ? 'Perfect! x$combo' : 'Perfect!', _accentCol);
  }

  double _comboMultiplier() => (1 + combo * 0.1).clamp(1.0, 3.0);

  void _onEnemyScared(Enemy e) {
    enemiesScared++;
    _dtScare++;
    final mult = _comboMultiplier();
    score += (e.kind.scoreReward * mult).round();
    audio.sfx(Assets.sndScare, volume: 0.7);
    add(BurstEffect(position: e.position, color: Colors.white, count: 8, speed: 120));
    _spawnFloatingText(e.position - Vector2(0, 20), '+${e.kind.scoreReward}', Colors.white);
    // Drop coins.
    final coins = e.kind.coinReward;
    for (int i = 0; i < coins; i++) {
      final v = Vector2(_rng.nextDouble() * 2 - 1, _rng.nextDouble() * 2 - 1) * 80;
      add(Coin(position: e.position.clone(), value: 1, initialVelocity: v));
    }
  }

  void enemyReachedCoop(Enemy e) {
    if (e.isScared) return;
    if (shieldActive) {
      shieldActive = false;
      add(RingEffect(position: coop.position, color: const Color(0xFF5B8CFF), maxRadius: 110, duration: 0.5));
      audio.sfx(Assets.sndScare, volume: 0.6);
      _spawnFloatingText(coop.position - Vector2(0, 80), 'Blocked!', const Color(0xFF8FB4FF));
      e.scare();
      _refreshActivePowerupHud();
      return;
    }
    eggs--;
    hud.eggs.value = eggs;
    coop.hitReaction();
    combo = 0;
    hud.combo.value = 0;
    audio.sfx(Assets.sndEggLost, volume: 0.9);
    onVibrate(1);
    chicken.hurt();
    _spawnFloatingText(coop.position - Vector2(0, 70), '-1 Egg', _dangerCol);
    e.removeFromParent();
    if (eggs <= 0) {
      _lose();
    }
  }

  void boarExtinguishNear(Vector2 pos) {
    Lantern? nearest;
    double best = double.infinity;
    for (final l in lanterns) {
      final d = l.position.distanceTo(pos);
      if (d < best) {
        best = d;
        nearest = l;
      }
    }
    if (nearest != null) {
      nearest.extinguish();
      add(BurstEffect(position: nearest.position, color: Colors.grey, count: 12, speed: 90));
      audio.sfx(Assets.sndLanternFade, volume: 0.8);
      onVibrate(0);
    }
  }

  void collectCoin(int value, Vector2 pos) {
    final gained = (value * _coinMultiplier).round();
    sessionCoins += gained;
    coinsForObjective += gained;
    _dtCoins += gained;
    hud.coins.value = sessionCoins;
    audio.sfx(Assets.sndCoin, volume: 0.5);
    add(BurstEffect(position: pos, color: _coinCol, count: 5, speed: 70, duration: 0.35));
  }

  void collectPowerup(PowerUpType type, Vector2 pos) {
    if (_inventory.length >= 4) return;
    _inventory.add(type);
    hud.inventory.value = List<PowerUpType>.from(_inventory);
    audio.sfx(Assets.sndPowerup, volume: 0.7);
    _spawnFloatingText(pos - Vector2(0, 20), PowerUpInfo.of(type).name, PowerUpInfo.of(type).tint);
  }

  void _dropRandomPowerup() {
    if (config.powerups.isEmpty) return;
    final type = config.powerups[_rng.nextInt(config.powerups.length)];
    final angle = _rng.nextDouble() * math.pi * 2;
    final pos = _fieldCenter + Vector2(math.cos(angle), math.sin(angle)) * (_ry * 0.7);
    add(PowerUpPickup(position: pos, type: type));
  }

  // ---------------- Power-ups ----------------
  void usePowerup(int index) {
    if (index < 0 || index >= _inventory.length) return;
    final type = _inventory.removeAt(index);
    hud.inventory.value = List<PowerUpType>.from(_inventory);
    _activatePowerup(type);
    powerupsUsed++;
    _dtPowerups++;
  }

  void _activatePowerup(PowerUpType type) {
    final info = PowerUpInfo.of(type);
    audio.sfx(Assets.sndPowerup, volume: 0.9);
    switch (type) {
      case PowerUpType.fullIgnite:
        for (final l in lanterns) {
          l.igniteFull();
          add(RingEffect(position: l.position, color: _accentCol, maxRadius: 60, duration: 0.5));
        }
        break;
      case PowerUpType.shockwave:
        add(RingEffect(position: coop.position, color: const Color(0xFFFF8A3D), maxRadius: math.max(size.x, size.y), duration: 0.6, strokeWidth: 8));
        for (final e in children.query<Enemy>()) {
          if (!e.isScared) {
            final off = e.scare(knockback: 2);
            if (off) _onEnemyScared(e);
          }
        }
        onVibrate(1);
        break;
      case PowerUpType.coopShield:
        shieldActive = true;
        usedShield = true;
        break;
      case PowerUpType.slowTime:
        _addTimed(type, info.duration * config.powerupDurationMult);
        break;
      case PowerUpType.doubleCoins:
        _coinMultiplier = 2;
        _addTimed(type, info.duration * config.powerupDurationMult);
        break;
      case PowerUpType.coinMagnet:
        _magnetMultiplier = 3.2;
        _addTimed(type, info.duration * config.powerupDurationMult);
        break;
      case PowerUpType.speedBoost:
        chicken.speedMultiplier = 1.65;
        _addTimed(type, info.duration * config.powerupDurationMult);
        break;
      case PowerUpType.lanternBuddy:
        _buddyActive = true;
        _addTimed(type, info.duration * config.powerupDurationMult);
        break;
    }
    _refreshActivePowerupHud();
  }

  void _addTimed(PowerUpType type, double duration) {
    _active.removeWhere((a) => a.type == type);
    _active.add(_ActivePowerup(type, duration, duration));
  }

  void _updatePowerups(double dt) {
    // slow-time affects world; recompute each frame.
    timeScale = _active.any((a) => a.type == PowerUpType.slowTime) ? 0.5 : 1.0;

    var changed = false;
    for (final a in List<_ActivePowerup>.from(_active)) {
      a.remaining -= dt;
      if (a.remaining <= 0) {
        _active.remove(a);
        _revert(a.type);
        changed = true;
      }
    }
    if (changed || _active.isNotEmpty) _refreshActivePowerupHud();
  }

  void _revert(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleCoins:
        _coinMultiplier = 1;
        break;
      case PowerUpType.coinMagnet:
        _magnetMultiplier = 1;
        break;
      case PowerUpType.speedBoost:
        chicken.speedMultiplier = 1;
        break;
      case PowerUpType.lanternBuddy:
        _buddyActive = false;
        break;
      default:
        break;
    }
  }

  void _refreshActivePowerupHud() {
    final views = _active
        .map((a) => ActivePowerupView(a.type, a.remaining, a.total))
        .toList();
    hud.activePowerups.value = views;
  }

  // ---------------- HUD ----------------
  void _updateHud() {
    int lit = 0;
    for (final l in lanterns) {
      if (l.isLit) lit++;
    }
    hud.lit.value = lit;
    hud.score.value = score;
    hud.dashProgress.value = chicken.dashProgress;
  }

  void _spawnFloatingText(Vector2 pos, String text, Color color) {
    add(FloatingText(position: pos, text: text, color: color));
  }

  // ---------------- Dash / trail (called by chicken) ----------------
  void onChickenDash(Vector2 pos) {
    add(RingEffect(position: pos, color: Colors.white, maxRadius: 60, duration: 0.3));
    audio.sfx(Assets.sndRun, volume: 0.5);
    onVibrate(0);
  }

  void spawnDashTrail(Vector2 pos) {
    if (children.query<TrailDot>().length < 24) {
      add(TrailDot(position: pos));
    }
  }

  // ---------------- Input from Flutter ----------------
  void setMoveInput(Vector2 input) {
    if (input.length > 1) input = input.normalized();
    moveInput = input;
  }

  void requestDash() {
    if (paused || phase == GamePhase.finished) return;
    chicken.tryDash();
  }

  void setPaused(bool value) {
    if (value) {
      pauseEngine();
      audio.pauseMusic();
    } else {
      resumeEngine();
      audio.resumeMusic();
    }
  }

  // ---------------- Tutorial ----------------
  int _tutStep = 0;
  double _tutTimer = 0;
  double _tutMoved = 0;
  Vector2 _tutLastPos = Vector2.zero();
  bool _tutSpawnedIntruder = false;

  void _startTutorial() {
    phase = GamePhase.tutorial;
    _tutStep = 0;
    _tutLastPos = chicken.position.clone();
    // Dim one lantern so the player has something to relight.
    if (lanterns.isNotEmpty) lanterns.first.charge = 0.35;
    _showTutorialStep();
  }

  static const List<String> _tutTexts = [
    'Drag anywhere to move your chicken',
    'Stay near a lantern to relight it',
    'A dark path lets enemies sneak in',
    'Get close or tap Dash to scare enemies',
    'Never let them reach your eggs!',
    'Grab coins to buy upgrades later',
  ];

  void _showTutorialStep() {
    hud.tutorial.value = _tutTexts[_tutStep];
  }

  void _updateTutorial(double dt) {
    _tutTimer += dt;
    // Freeze most lanterns during the tutorial so it stays calm.
    for (int i = 1; i < lanterns.length; i++) {
      lanterns[i].charge = 1.0;
    }
    _recharge(dt);

    switch (_tutStep) {
      case 0:
        _tutMoved += chicken.position.distanceTo(_tutLastPos);
        _tutLastPos = chicken.position.clone();
        if (_tutMoved > 160) _advanceTutorial();
        break;
      case 1:
        if (lanterns.isNotEmpty && lanterns.first.charge >= 0.99) _advanceTutorial();
        break;
      case 2:
        if (!_tutSpawnedIntruder) {
          _tutSpawnedIntruder = true;
          _tutTimer = 0;
          // send a slow mouse down the first lane.
          final l = lanterns.isNotEmpty ? lanterns.first : null;
          if (l != null) {
            l.charge = 0.0;
            add(Enemy(kind: EnemyKind.of(EnemyType.mouse), lane: l, position: l.spawnPoint.clone()));
          }
        }
        if (_tutTimer > 2.2) _advanceTutorial();
        break;
      case 3:
        if (enemiesScared >= 1) {
          _tutTimer = 0;
          _advanceTutorial();
        }
        break;
      case 4:
        if (_tutTimer > 2.4) {
          _tutTimer = 0;
          // spawn a coin to collect.
          add(Coin(position: chicken.position + Vector2(40, -40), value: 3));
          _advanceTutorial();
        }
        break;
      case 5:
        // Coins collected during a run reset _tutMoved usage; detect via sessionCoins.
        if (sessionCoins > 0 || _tutTimer > 6) {
          _finishTutorial();
        }
        break;
    }
  }

  void _advanceTutorial() {
    _tutStep++;
    _tutTimer = 0;
    if (_tutStep < _tutTexts.length) {
      _showTutorialStep();
    }
  }

  void _finishTutorial() {
    hud.tutorial.value = null;
    GameData.instance.markTutorialDone();
    // restore lanterns and begin the real (gentle) waves.
    for (final l in lanterns) {
      l.charge = 1.0;
    }
    for (final e in children.query<Enemy>()) {
      e.removeFromParent();
    }
    currentWave = 0;
    _enterPrepare();
  }

  // ---------------- End of game ----------------
  void _win() {
    if (phase == GamePhase.finished) return;
    phase = GamePhase.finished;
    hud.tutorial.value = null;
    audio.sfx(Assets.sndVictory, volume: 0.9);
    onVibrate(2);
    chicken.celebrate();
    _flushDailyTasks(won: true);
    onFinished(_buildResult(true), true);
  }

  void _lose() {
    if (phase == GamePhase.finished) return;
    phase = GamePhase.finished;
    hud.tutorial.value = null;
    audio.sfx(Assets.sndDefeat, volume: 0.9);
    onVibrate(2);
    _flushDailyTasks(won: false);
    onFinished(_buildResult(false), false);
  }

  LevelResult _buildResult(bool won) {
    final allLit = lanterns.every((l) => l.isLit);
    return LevelResult(
      won: won,
      wavesCompleted: wavesCompleted,
      totalWaves: config.endless ? currentWave : config.waveCount,
      startingEggs: startingEggs,
      eggsRemaining: eggs,
      coinsCollected: sessionCoins,
      enemiesScared: enemiesScared,
      lanternsRelit: lanternsRelit,
      maxCombo: maxCombo,
      allLanternsLitAtEnd: allLit,
      usedShield: usedShield,
    );
  }

  void _flushDailyTasks({required bool won}) {
    final data = GameData.instance;
    data.addTaskProgress(DailyTaskType.surviveWaves, wavesCompleted);
    data.addTaskProgress(DailyTaskType.relightLanterns, _dtRelight);
    data.addTaskProgress(DailyTaskType.collectCoins, _dtCoins);
    data.addTaskProgress(DailyTaskType.scareEnemies, _dtScare);
    data.addTaskProgress(DailyTaskType.usePowerups, _dtPowerups);
    if (won && eggs >= startingEggs) {
      data.addTaskProgress(DailyTaskType.noEggLostRun, 1);
    }
    if (won && lanterns.every((l) => l.isLit)) {
      data.addTaskProgress(DailyTaskType.levelAllLanternsLit, 1);
    }
  }

  @override
  void onRemove() {
    audio.stopMusic();
    hud.dispose();
    super.onRemove();
  }
}

// Convenience colour aliases used inside the game (kept short at call sites).
const _coinCol = Color(0xFFFFD24B);
const _accentCol = Color(0xFFFFC64B);
const _safeCol = Color(0xFF8BC34A);
const _dangerCol = Color(0xFFE74C3C);
