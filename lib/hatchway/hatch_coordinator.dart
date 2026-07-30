import 'dart:async';
import 'dart:io';

import 'config/era_hatch_config.dart';
import 'core/hatch_models.dart';
import 'infra/airway_probe.dart';
import 'infra/egg_signal_hub.dart';
import 'infra/flight_attribution.dart';
import 'infra/hatch_exchange.dart';
import 'infra/launch_route_reader.dart';
import 'infra/nest_vault.dart';
import 'infra/roost_agent.dart';

/// Orchestrates the boot pipeline: cold-start push → connectivity → APNs
/// bootstrap → AppsFlyer wait → config POST → routing decision. Emits
/// `NightHold` variants that the boot screen inspects to pick the next
/// page.
class WardenRouter {
  WardenRouter({
    required this.safe,
    required this.scout,
    required this.tracker,
    required this.relay,
    required this.torches,
    required this.agent,
    required this.runtimeEnabled,
  });

  final CoopSafe safe;
  final PastureScout scout;
  final TrackerRelay tracker;
  final SignalExchange relay;
  final TorchRelay torches;
  final HerderAgent agent;
  final bool runtimeEnabled;

  bool get enabled =>
      runtimeEnabled && LanternRallyEnv.grayCredentialsReady;

  Future<NightHold>? _pending;

  /// De-duplicates only *concurrent* calls (boot screen may build twice at
  /// startup). The cache is cleared once the pipeline finishes so a later
  /// retry from the offline screen re-runs the whole pipeline instead of
  /// replaying a cached `DarkHold` forever.
  Future<NightHold> decide({required void Function(double) onProgress}) =>
      _pending ??= _resolve(onProgress: onProgress)
          .whenComplete(() => _pending = null);

  Future<NightHold> _resolve({required void Function(double) onProgress}) async {
    if (!enabled) {
      assert(() {
        // ignore: avoid_print
        print(
          '[LBR.WARD] gate disabled '
          'runtime=$runtimeEnabled creds=${LanternRallyEnv.grayCredentialsReady}',
        );
        return true;
      }());
      onProgress(1);
      return const HomeHold();
    }

    assert(() {
      // ignore: avoid_print
      print('[LBR.WARD] resolve start route=${safe.route}');
      return true;
    }());

    torches.onTokenChanged = _refreshWithToken;

    // Cold-start push URL is consumed FIRST — before connectivity check,
    // before attribution — otherwise a slow network hides the pushed URL
    // behind an offline screen or the plain config URL.
    final coldLink = await ColdLinkReader.consume();
    if (coldLink != null) {
      await safe.saveRoute(PortalRoute.web);
      await safe.consumePushUrl();
      unawaited(_dispatchInBackground());
      onProgress(1);
      return WebHold(coldLink, coldLaunch: true);
    }

    onProgress(0.12);
    switch (safe.route) {
      case PortalRoute.unset:
        return _resolveFirstLaunch(onProgress);
      case PortalRoute.web:
        return _resolveReturningWeb(onProgress);
      case PortalRoute.game:
        return _resolveReturningGame(onProgress);
    }
  }

  Future<NightHold> _resolveFirstLaunch(
    void Function(double) progress,
  ) async {
    if (!await scout.hasInterface()) {
      assert(() {
        // ignore: avoid_print
        print('[LBR.WARD] first: no interface → offline');
        return true;
      }());
      return const DarkHold(returnToGame: false);
    }
    progress(0.28);
    try {
      await torches.boot();
    } catch (_) {
      // Push bootstrap failures never block the gate.
    }
    if (!await scout.canReachNetwork()) {
      assert(() {
        // ignore: avoid_print
        print('[LBR.WARD] first: dns probe failed → offline');
        return true;
      }());
      return const DarkHold(returnToGame: false);
    }
    progress(0.48);
    await tracker.awaitSignals();
    progress(0.72);
    final reply = await _askConfig();
    progress(1);
    assert(() {
      // ignore: avoid_print
      print(
        '[LBR.WARD] first: config hasDest=${reply.hasDestination} '
        'url=${reply.url}',
      );
      return true;
    }());
    if (reply.hasDestination) {
      await safe.saveRoute(PortalRoute.web);
      return WebHold(reply.url!);
    }
    await safe.saveRoute(PortalRoute.game);
    return const HomeHold();
  }

  Future<NightHold> _resolveReturningWeb(
    void Function(double) progress,
  ) async {
    if (!await scout.hasInterface()) {
      return const DarkHold(returnToGame: false);
    }
    // Pending push URL takes precedence — a tap that landed while the app
    // was already alive should still steer the returning session.
    final pending = await safe.consumePushUrl();
    if (pending != null && pending.isNotEmpty) {
      progress(1);
      return WebHold(pending);
    }
    final cached = await safe.savedUrl();
    if (cached != null && !safe.cachedUrlExpired) {
      progress(1);
      return WebHold(cached);
    }

    await Future.wait<void>(<Future<void>>[
      torches.boot(),
      tracker.start(),
    ]);
    if (!await scout.canReachNetwork()) {
      return const DarkHold(returnToGame: false);
    }
    progress(0.62);
    await tracker.awaitSignals(installTimeout: const Duration(seconds: 5));
    final reply = await _askConfig();
    progress(1);
    if (reply.hasDestination) return WebHold(reply.url!);
    if (cached != null) return WebHold(cached);
    return const DarkHold(returnToGame: false);
  }

  Future<NightHold> _resolveReturningGame(
    void Function(double) progress,
  ) async {
    if (!await scout.hasInterface()) {
      progress(1);
      return const HomeHold();
    }
    await Future.wait<void>(<Future<void>>[
      torches.boot(),
      tracker.start(),
    ]);
    if (!await scout.canReachNetwork()) {
      progress(1);
      return const HomeHold();
    }
    progress(0.55);
    await tracker.awaitSignals();
    final reply = await _askConfig();
    progress(1);
    if (!reply.hasDestination) return const HomeHold();
    await safe.saveRoute(PortalRoute.web);
    return WebHold(reply.url!);
  }

  Future<RelayReply> _askConfig({String? token}) async {
    final body = await tracker.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? torches.token,
    );
    return relay.request(body);
  }

  Future<void> _dispatchInBackground() async {
    try {
      await Future.wait<void>(<Future<void>>[
        torches.boot(),
        tracker.awaitSignals(),
      ]);
      await _askConfig();
    } catch (_) {}
  }

  Future<void> _refreshWithToken(String token) async {
    try {
      await _askConfig(token: token);
    } catch (_) {}
  }
}
