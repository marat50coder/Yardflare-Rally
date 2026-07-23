import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import 'main_menu_screen.dart';

/// First screen. Picks the splash that matches the current orientation, shows a
/// real init-progress bar, then locks to portrait and fades into the menu.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _target = 0.0;
  int _dots = 0;
  Timer? _dotTimer;
  bool _started = false;
  String _stage = 'Loading';

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() => _dots = (_dots + 1) % 4);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // Run after the first frame so MediaQuery / context are ready.
      WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    }
  }

  Future<void> _init() async {
    // Stage 1: saved progress, settings, daily tasks.
    setState(() {
      _stage = 'Loading save data';
      _target = 0.18;
    });
    await GameData.instance.load();
    await Future<void>.delayed(const Duration(milliseconds: 180));

    // Stage 2: audio.
    if (!mounted) return;
    setState(() {
      _stage = 'Loading sound';
      _target = 0.45;
    });
    await AudioService.instance.init();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Stage 3: images (the heavy part).
    if (!mounted) return;
    setState(() {
      _stage = 'Loading art';
      _target = 0.6;
    });
    await _precacheImages();

    // Stage 4: configuration finalise.
    if (!mounted) return;
    setState(() {
      _stage = 'Preparing the yard';
      _target = 0.9;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));

    // Everything is ready -> only now do we hit 100%.
    if (!mounted) return;
    setState(() {
      _stage = 'Ready';
      _target = 1.0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Lock the game to portrait for play.
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (!mounted) return;
    AudioService.instance.playMusic(Assets.musicMenu);
    _goToMenu();
  }

  Future<void> _precacheImages() async {
    final paths = Assets.preloadImages();
    final total = paths.length;
    for (int i = 0; i < total; i++) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(paths[i]), context);
      } catch (_) {}
      setState(() => _target = 0.6 + 0.3 * ((i + 1) / total));
    }
  }

  void _goToMenu() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const MainMenuScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final splash = orientation == Orientation.portrait
        ? Assets.loadingVertical
        : Assets.loadingHorizontal;
    final loadingText = 'Loading${'.' * _dots}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(splash, fit: BoxFit.cover),
          // Bottom scrim for readable text.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 46,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loadingText,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stage,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _ProgressBar(value: _target),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v <= 0 ? 0.001 : v,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentDark, AppColors.accent],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

