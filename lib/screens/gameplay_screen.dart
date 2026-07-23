import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../data/levels_data.dart';
import '../game/game_session_config.dart';
import '../game/systems/hud_state.dart';
import '../game/yardflare_game.dart';
import '../models/level_config.dart';
import '../models/level_result.dart';
import '../models/powerup_type.dart';
import '../models/save_state.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import '../widgets/common.dart';
import '../widgets/game_overlays.dart';
import '../widgets/virtual_joystick.dart';

/// Origin + current touch point for the floating drag-to-move joystick visual.
class _DragVisual {
  final Offset origin;
  final Offset current;
  const _DragVisual(this.origin, this.current);
}

class GameplayScreen extends StatefulWidget {
  final LevelConfig? level;
  final bool endless;
  const GameplayScreen({super.key, this.level}) : endless = false;
  const GameplayScreen.endless({super.key})
      : level = null,
        endless = true;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> with WidgetsBindingObserver {
  late final YardflareGame _game;
  late final HudState _hud;

  bool _paused = false;
  bool _handled = false;
  LevelResult? _result;
  bool _won = false;
  int _earnedStars = 0;
  int _earnedCoins = 0;

  // Drag-to-move floating joystick. Kept in a ValueNotifier (instead of
  // driving setState on the whole screen) because pan-update events fire at
  // native touch-sampling rate during all movement -- rebuilding the entire
  // screen (including the GameWidget and HUD) on every one of those events
  // was a major source of jank. Only the small joystick visual listens here.
  final ValueNotifier<_DragVisual?> _dragVisual = ValueNotifier(null);
  static const double _dragRadius = 92;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final config = widget.endless
        ? GameSessionConfig.endless()
        : GameSessionConfig.fromLevel(widget.level!);
    _game = YardflareGame(
      config: config,
      onFinished: _onFinished,
      onVibrate: _vibrate,
    );
    _hud = _game.hud;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dragVisual.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_paused && _result == null) {
      _openPause();
    }
  }

  void _vibrate(int intensity) {
    if (!GameData.instance.vibration) return;
    switch (intensity) {
      case 0:
        HapticFeedback.selectionClick();
        break;
      case 1:
        HapticFeedback.mediumImpact();
        break;
      default:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  void _onFinished(LevelResult result, bool won) {
    if (_handled) return;
    _handled = true;
    _game.setPaused(true);

    final data = GameData.instance;
    if (widget.endless) {
      _earnedCoins = result.coinsCollected;
      data.addCoins(_earnedCoins);
      data.updateEndless(_game.currentWave, _game.score, _game.survivalTime.round());
    } else {
      final level = widget.level!;
      _earnedStars = won ? result.computeStars(level) : 0;
      _earnedCoins = result.computeCoins(level);
      data.recordLevel(level.id, _earnedStars, _earnedCoins);
    }

    setState(() {
      _result = result;
      _won = won;
    });
  }

  // ---------------- Navigation ----------------
  void _toMenu() {
    // Stop the game music/SFX deterministically before returning to the menu.
    // Relying solely on the Flame game's onRemove() is not reliable on every
    // platform (especially while the engine is paused), which left the game
    // track playing over the menu. The menu restarts its own music on entry.
    AudioService.instance.stopMusic();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _retry() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => widget.endless
          ? const GameplayScreen.endless()
          : GameplayScreen(level: widget.level),
    ));
  }

  void _next() {
    final nextId = (widget.level?.id ?? 0) + 1;
    final data = GameData.instance;
    if (nextId <= 40 && data.isLevelUnlocked(nextId)) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameplayScreen(level: LevelsData.byId(nextId)),
      ));
    } else {
      _toMenu();
    }
  }

  // ---------------- Pause ----------------
  void _openPause() {
    if (_result != null) return;
    setState(() => _paused = true);
    _game.setPaused(true);
  }

  void _resume() {
    setState(() => _paused = false);
    _game.setPaused(false);
  }

  // ---------------- Input ----------------
  void _onPanStart(DragStartDetails d) {
    if (_paused || _result != null) return;
    _dragVisual.value = _DragVisual(d.localPosition, d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final origin = _dragVisual.value?.origin;
    if (origin == null) return;
    var delta = d.localPosition - origin;
    if (delta.distance > _dragRadius) {
      delta = Offset.fromDirection(delta.direction, _dragRadius);
    }
    _dragVisual.value = _DragVisual(origin, origin + delta);
    _game.setMoveInput(Vector2(delta.dx / _dragRadius, delta.dy / _dragRadius));
  }

  void _onPanEnd(_) {
    _dragVisual.value = null;
    _game.setMoveInput(Vector2.zero());
  }

  @override
  Widget build(BuildContext context) {
    final controlMode = GameData.instance.controlMode;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_result != null) {
          _toMenu();
        } else if (_paused) {
          _resume();
        } else {
          _openPause();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1020),
        body: Stack(
          children: [
            // Game + drag input.
            if (controlMode == ControlMode.drag)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onPanCancel: () => _onPanEnd(null),
                  child: RepaintBoundary(child: GameWidget(game: _game)),
                ),
              )
            else
              Positioned.fill(child: RepaintBoundary(child: GameWidget(game: _game))),

            // Floating drag joystick visual. Isolated in its own listener so
            // panning doesn't rebuild the whole screen every frame.
            if (controlMode == ControlMode.drag)
              ValueListenableBuilder<_DragVisual?>(
                valueListenable: _dragVisual,
                builder: (context, drag, _) {
                  if (drag == null) return const SizedBox.shrink();
                  return Stack(children: [
                    _floatingCircle(drag.origin, 46, 0.18),
                    _floatingCircle(drag.current, 26, 0.5),
                  ]);
                },
              ),

            SafeArea(
              child: Column(
                children: [
                  _TopHud(hud: _hud, onPause: _openPause, endless: widget.endless),
                  _ActivePowerupsBar(hud: _hud),
                  const Spacer(),
                  _BottomControls(
                    hud: _hud,
                    controlMode: controlMode,
                    onDash: _game.requestDash,
                    onJoystick: _game.setMoveInput,
                    onUsePowerup: _game.usePowerup,
                  ),
                ],
              ),
            ),

            // Tutorial prompt.
            _TutorialPrompt(hud: _hud),
            // Transient banner.
            _BannerView(hud: _hud),

            if (_paused) _buildPauseOverlay(),
            if (_result != null) _buildResultOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _floatingCircle(Offset pos, double r, double alpha) {
    return Positioned(
      left: pos.dx - r,
      top: pos.dy - r,
      child: IgnorePointer(
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: alpha),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  // ---------------- Overlays ----------------
  Widget _buildPauseOverlay() {
    final data = GameData.instance;
    return OverlayPanel(
      title: 'Paused',
      children: [
        StatRow(label: 'Wave', value: '${_hud.wave.value}', icon: Icons.waves),
        StatRow(label: 'Score', value: '${_hud.score.value}', icon: Icons.emoji_events),
        StatRow(label: 'Coins this run', value: '${_hud.coins.value}', icon: Icons.monetization_on),
        StatRow(label: 'Power-ups held', value: '${_hud.inventory.value.length}', icon: Icons.bolt),
        if (widget.endless)
          StatRow(label: 'Best wave', value: '${data.endlessBestWave}', icon: Icons.star)
        else
          StatRow(label: 'Best stars', value: '${data.starsFor(widget.level!.id)}/3', icon: Icons.star),
        overlayButton('Resume', Icons.play_arrow_rounded, _resume, color: AppColors.safe),
        overlayButton('Restart', Icons.refresh, _retry, color: AppColors.panelLight),
        overlayButton('Quit to Menu', Icons.home, _toMenu, color: AppColors.panelLight),
      ],
    );
  }

  Widget _buildResultOverlay() {
    final result = _result!;
    if (widget.endless) {
      return _endlessOverlay(result);
    }
    if (_won) {
      return _victoryOverlay(result);
    }
    return _gameOverOverlay(result);
  }

  Widget _victoryOverlay(LevelResult result) {
    final level = widget.level!;
    final objectiveMet = _earnedStars >= 3;
    return OverlayPanel(
      title: 'Level Complete!',
      titleColor: AppColors.safe,
      children: [
        AnimatedStars(stars: _earnedStars),
        const SizedBox(height: 14),
        StatRow(label: 'Eggs saved', value: '${result.eggsRemaining}/${result.startingEggs}', icon: Icons.egg),
        StatRow(label: 'Enemies scared', value: '${result.enemiesScared}', icon: Icons.pest_control),
        StatRow(label: 'Best combo', value: 'x${result.maxCombo}', icon: Icons.local_fire_department),
        StatRow(label: 'Coins earned', value: '+$_earnedCoins', icon: Icons.monetization_on, valueColor: AppColors.coin),
        const Divider(color: Colors.white24, height: 22),
        ObjectiveTile(label: 'Complete the level', met: true),
        ObjectiveTile(label: 'Save ${level.star2EggsKept}+ eggs', met: _earnedStars >= 2),
        ObjectiveTile(label: level.objective.label, met: objectiveMet),
        if (level.id < 40)
          overlayButton('Next Level', Icons.arrow_forward, _next, color: AppColors.safe),
        overlayButton('Retry', Icons.refresh, _retry, color: AppColors.panelLight),
        overlayButton('Menu', Icons.home, _toMenu, color: AppColors.panelLight),
      ],
    );
  }

  Widget _gameOverOverlay(LevelResult result) {
    return OverlayPanel(
      title: 'So Close!',
      titleColor: AppColors.danger,
      children: [
        const Text('The coop was raided, but you fought well.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim)),
        const SizedBox(height: 14),
        StatRow(label: 'Waves survived', value: '${result.wavesCompleted}/${result.totalWaves}', icon: Icons.waves),
        StatRow(label: 'Enemies scared', value: '${result.enemiesScared}', icon: Icons.pest_control),
        StatRow(label: 'Coins earned', value: '+$_earnedCoins', icon: Icons.monetization_on, valueColor: AppColors.coin),
        const SizedBox(height: 8),
        const Text('Tip: upgrade Lantern Burn Time and Movement Speed to hold on longer.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.accent, fontSize: 12)),
        overlayButton('Retry', Icons.refresh, _retry, color: AppColors.safe),
        overlayButton('Upgrades', Icons.upgrade, () {
          _toMenu();
        }, color: AppColors.accentDark),
        overlayButton('Menu', Icons.home, _toMenu, color: AppColors.panelLight),
      ],
    );
  }

  Widget _endlessOverlay(LevelResult result) {
    final data = GameData.instance;
    return OverlayPanel(
      title: 'Endless Over',
      titleColor: AppColors.accent,
      children: [
        StatRow(label: 'Wave reached', value: '${_game.currentWave}', icon: Icons.waves),
        StatRow(label: 'Score', value: '${_game.score}', icon: Icons.emoji_events),
        StatRow(label: 'Time', value: _formatTime(_game.survivalTime.round()), icon: Icons.timer),
        StatRow(label: 'Coins earned', value: '+$_earnedCoins', icon: Icons.monetization_on, valueColor: AppColors.coin),
        const Divider(color: Colors.white24, height: 22),
        StatRow(label: 'Best wave', value: '${data.endlessBestWave}', icon: Icons.star),
        StatRow(label: 'Best score', value: '${data.endlessBestScore}', icon: Icons.star),
        StatRow(label: 'Best time', value: _formatTime(data.endlessBestTime), icon: Icons.star),
        overlayButton('Retry', Icons.refresh, _retry, color: AppColors.safe),
        overlayButton('Menu', Icons.home, _toMenu, color: AppColors.panelLight),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ---------------- HUD widgets ----------------
class _TopHud extends StatelessWidget {
  final HudState hud;
  final VoidCallback onPause;
  final bool endless;
  const _TopHud({required this.hud, required this.onPause, required this.endless});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(
                  ValueListenableBuilder<int>(
                    valueListenable: hud.eggs,
                    builder: (_, eggs, _) => ValueListenableBuilder<int>(
                      valueListenable: hud.maxEggs,
                      builder: (_, maxEggs, _) => _iconText(Assets.eggWhite, '$eggs'),
                    ),
                  ),
                ),
                _chip(ValueListenableBuilder<int>(
                  valueListenable: hud.coins,
                  builder: (_, v, _) => _iconText(Assets.coinChicken, '$v'),
                )),
                _chip(ValueListenableBuilder<int>(
                  valueListenable: hud.wave,
                  builder: (_, w, _) => ValueListenableBuilder<int>(
                    valueListenable: hud.waveTotal,
                    builder: (_, total, _) => _labelText(
                        Icons.waves, endless ? 'Wave $w' : 'Wave $w/$total'),
                  ),
                )),
                _chip(ValueListenableBuilder<int>(
                  valueListenable: hud.lit,
                  builder: (_, lit, _) => ValueListenableBuilder<int>(
                    valueListenable: hud.lanternTotal,
                    builder: (_, total, _) => _labelText(
                        Icons.light_mode, '$lit/$total',
                        color: lit == total ? AppColors.safe : AppColors.accent),
                  ),
                )),
                _chip(ValueListenableBuilder<int>(
                  valueListenable: hud.score,
                  builder: (_, v, _) => _labelText(Icons.emoji_events, '$v'),
                )),
                _chip(ValueListenableBuilder<int>(
                  valueListenable: hud.combo,
                  builder: (_, c, _) => c > 1
                      ? _labelText(Icons.local_fire_department, 'x$c', color: AppColors.danger)
                      : const SizedBox.shrink(),
                )),
              ],
            ),
          ),
          const SizedBox(width: 6),
          RoundIconButton(icon: Icons.pause, onPressed: onPause, size: 42),
        ],
      ),
    );
  }

  Widget _chip(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  Widget _iconText(String asset, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 20, height: 20),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      );

  Widget _labelText(IconData icon, String text, {Color color = Colors.white}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
        ],
      );
}

class _ActivePowerupsBar extends StatelessWidget {
  final HudState hud;
  const _ActivePowerupsBar({required this.hud});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivePowerupView>>(
      valueListenable: hud.activePowerups,
      builder: (_, list, _) {
        if (list.isEmpty) return const SizedBox(height: 0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: list.map((a) {
              final info = PowerUpInfo.of(a.type);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: info.tint.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(info.icon, width: 20, height: 20),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 34,
                      child: LinearProgressIndicator(
                        value: a.ratio,
                        minHeight: 5,
                        backgroundColor: Colors.white24,
                        color: info.tint,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BottomControls extends StatelessWidget {
  final HudState hud;
  final ControlMode controlMode;
  final VoidCallback onDash;
  final ValueChanged<Vector2> onJoystick;
  final ValueChanged<int> onUsePowerup;

  const _BottomControls({
    required this.hud,
    required this.controlMode,
    required this.onDash,
    required this.onJoystick,
    required this.onUsePowerup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (controlMode == ControlMode.joystick)
            VirtualJoystick(onChanged: onJoystick)
          else
            const SizedBox(width: 4),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PowerupButtons(hud: hud, onUse: onUsePowerup),
              const SizedBox(height: 12),
              _DashButton(hud: hud, onDash: onDash),
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerupButtons extends StatelessWidget {
  final HudState hud;
  final ValueChanged<int> onUse;
  const _PowerupButtons({required this.hud, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PowerUpType>>(
      valueListenable: hud.inventory,
      builder: (_, inv, _) {
        if (inv.isEmpty) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(inv.length, (i) {
            final info = PowerUpInfo.of(inv[i]);
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  AudioService.instance.button();
                  onUse(i);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: info.tint, width: 2),
                    boxShadow: [BoxShadow(color: info.tint.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(info.icon),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _DashButton extends StatelessWidget {
  final HudState hud;
  final VoidCallback onDash;
  const _DashButton({required this.hud, required this.onDash});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: hud.dashProgress,
      builder: (_, progress, _) {
        final ready = progress >= 1.0;
        return GestureDetector(
          onTap: ready ? onDash : null,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                (ready ? AppColors.accent : AppColors.panelLight).withValues(alpha: 0.95),
                (ready ? AppColors.accentDark : AppColors.panel).withValues(alpha: 0.95),
              ]),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
              boxShadow: ready
                  ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 14)]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt, color: Colors.white, size: 34),
                    Text('DASH',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TutorialPrompt extends StatelessWidget {
  final HudState hud;
  const _TutorialPrompt({required this.hud});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: hud.tutorial,
      builder: (_, text, _) {
        if (text == null) return const SizedBox.shrink();
        return Align(
          alignment: const Alignment(0, -0.55),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(text),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerView extends StatefulWidget {
  final HudState hud;
  const _BannerView({required this.hud});

  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView> {
  String _text = '';
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.hud.bannerTick.addListener(_onTick);
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {
      _text = widget.hud.banner.value;
      _visible = true;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    widget.hud.bannerTick.removeListener(_onTick);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.28),
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          child: Text(
            _text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.accent,
              shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

