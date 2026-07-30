import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../hatchway/core/hatch_models.dart';
import '../hatchway/hatch_coordinator.dart';
import '../hatchway/pages/empty_air_page.dart';
import '../hatchway/pages/feather_invitation.dart';
import '../hatchway/pages/roost_portal.dart';
import 'loading_screen.dart';

/// Splash / boot screen — the loading experience AND the gray/white
/// routing point. It plays the loading art (orientation-aware) while
/// [WardenRouter.decide] runs the attribution → config pipeline, then
/// routes to the WebView (gray) or the white part (organic).
///
/// TEMPLATE NOTES:
/// - Do NOT push another loading screen from the white part — this IS
///   the splash. Route the white part straight to its first screen.
/// - To make the progress bar reflect real work, precache your game
///   assets in [_assetsToLoad]; the bar advances as each finishes.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key, this.router});

  final WardenRouter? router;

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  // TEMPLATE: add your game's asset paths here to precache them during
  // boot, e.g. 'assets/mascot/hero.png'. Empty in the template.
  final List<String> _assetsToLoad = <String>[];

  int _loaded = 0;
  double _routerProgress = 0;
  NightHold? _hold;
  bool _started = false;
  bool _navigating = false;
  late final DateTime _bootStarted;
  Timer? _hardDeadline;
  static const Duration _minSplash = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    _bootStarted = DateTime.now();
    // Loading screen supports both orientations.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Safety net: navigate even if something hangs.
    _hardDeadline = Timer(const Duration(seconds: 8), () {
      if (mounted && !_navigating) {
        setState(() => _loaded = _assetsToLoad.length);
        _maybeNavigate();
      }
    });
  }

  @override
  void dispose() {
    _hardDeadline?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _kickoff();
    }
  }

  Future<void> _kickoff() async {
    await Future.wait<void>(<Future<void>>[
      _preloadAll(),
      _askRouter(),
    ]);
    _maybeNavigate();
  }

  Future<void> _preloadAll() async {
    for (final asset in _assetsToLoad) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (_) {}
      if (!mounted) return;
      if (_loaded < _assetsToLoad.length) setState(() => _loaded++);
    }
    _hardDeadline?.cancel();
    _maybeNavigate();
  }

  Future<void> _askRouter() async {
    final router = widget.router;
    if (router == null) {
      _hold = const HomeHold();
      _routerProgress = 1;
      return;
    }
    try {
      _hold = await router.decide(
        onProgress: (value) {
          if (mounted) setState(() => _routerProgress = value.clamp(0.0, 1.0));
        },
      );
    } catch (_) {
      _hold = const HomeHold();
    }
    if (mounted) setState(() => _routerProgress = 1);
  }

  void _maybeNavigate() async {
    if (_navigating || _hold == null || _loaded < _assetsToLoad.length) {
      return;
    }
    final elapsed = DateTime.now().difference(_bootStarted);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }
    if (!mounted || _navigating) return;
    _navigating = true;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    await _openHold(_hold!);
  }

  Future<void> _openHold(NightHold hold) async {
    final router = widget.router;

    // Organic / gate disabled → white part (the real Yardflare game).
    if (hold is HomeHold || router == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoadingScreen()),
      );
      return;
    }

    if (hold is DarkHold) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SilentCoopPage(
            scout: router.scout,
            retryBuilder: (_) => BootScreen(router: router),
          ),
        ),
      );
      return;
    }

    if (hold is WebHold) {
      Widget portalBuilder(BuildContext _) => LanternPortal(
        url: hold.url,
        coldLaunch: hold.coldLaunch,
        safe: router.safe,
        scout: router.scout,
        torches: router.torches,
        agent: router.agent,
      );

      void openPortal() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: portalBuilder),
        );
      }

      if (router.safe.shouldShowPushInvite &&
          await router.torches.canOfferPermission()) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TorchInvitation(
              safe: router.safe,
              torches: router.torches,
              nextBuilder: portalBuilder,
            ),
          ),
        );
      } else {
        openPortal();
      }
    }
  }

  double get _progress {
    final assetProgress =
        _assetsToLoad.isEmpty ? 1.0 : _loaded / _assetsToLoad.length;
    return (assetProgress * 0.35 + _routerProgress * 0.65).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final asset = isLandscape
        ? 'assets/Horizontal_Loading_Screen.webp'
        : 'assets/Vertical_Loading_Screen.webp';
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFF0A1020)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLandscape ? 18 : 54),
                child: _LoadingBar(
                  progress: _progress,
                  width: isLandscape ? screenW * 0.42 : screenW * 0.74,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress, required this.width});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6E3A1D), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      widthFactor: value <= 0 ? 0.001 : value,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF8A2E),
                              Color(0xFFFFCB47),
                              Color(0xFF7EE05B),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LoadingLabel(),
      ],
    );
  }
}

/// "Loading" with three dots that animate in sequence.
class _LoadingLabel extends StatefulWidget {
  @override
  State<_LoadingLabel> createState() => _LoadingLabelState();
}

class _LoadingLabelState extends State<_LoadingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final phase = (_ctrl.value * 3).floor() % 3;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Loading',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: i <= phase ? 1.0 : 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
