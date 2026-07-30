import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/era_hatch_config.dart';
import 'roost_agent.dart';

/// Debug-only trace helper. Wrapped in `assert(() {})` so the closure body
/// AND every string literal it composes are stripped from release builds.
/// Never call `debugPrint` bare — the string ships in release and clusters
/// the app with siblings that emit the same tag.
void lbrTrace(String Function() build) {
  assert(() {
    debugPrint(build());
    return true;
  }());
}

/// AppsFlyer wiring: fires ATT, initialises the SDK, and stitches the
/// callbacks (`onInstallConversionData`, `onAppOpenAttribution`,
/// `onDeepLinking`) into one flat payload that `SignalExchange` POSTs to
/// the config endpoint verbatim.
class TrackerRelay {
  TrackerRelay(this._agent);

  final HerderAgent _agent;
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _installBag;
  Map<String, dynamic>? _reopenBag;
  Map<String, dynamic>? _deepLinkBag;
  Future<void>? _bootstrap;
  final Completer<void> _installReady = Completer<void>();
  final Completer<void> _deepLinkReady = Completer<void>();

  Future<void> start() => _bootstrap ??= _start();

  Future<void> _start() async {
    if (!LanternRallyEnv.grayCredentialsReady) {
      _completeEmpty();
      return;
    }
    try {
      await _promptTrackingIfNeeded();
      final sdk = AppsflyerSdk(
        AppsFlyerOptions(
          afDevKey: LanternRallyEnv.appsFlyerKey,
          appId: LanternRallyEnv.iosStoreId,
          showDebug: kDebugMode,
          timeToWaitForATTUserAuthorization: 4,
        ),
      );
      _sdk = sdk;
      sdk.onInstallConversionData(_absorbInstall);
      sdk.onAppOpenAttribution((raw) => _reopenBag = _flatten(raw));
      sdk.onDeepLinking((result) {
        final event = result.deepLink?.clickEvent;
        if (event != null) _deepLinkBag = Map<String, dynamic>.from(event);
        if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
      });
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (error) {
      lbrTrace(() => '[LBR.FLIGHT] initialization failed: $error');
      _completeEmpty();
    }
  }

  Future<void> _promptTrackingIfNeeded() async {
    if (!Platform.isIOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 320));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  Future<void> _absorbInstall(dynamic raw) async {
    try {
      final received = _flatten(raw);
      final status = received['status']?.toString().toLowerCase();
      // AppsFlyer emits {status:failure,...,data:"Request failed"} when it
      // cannot reach its servers (VPN blackhole, network drop). Never merge
      // that error map into the payload — it would poison the config body.
      final failed = status == 'failure' ||
          (received['af_status'] == null && received.containsKey('status'));
      lbrTrace(
        () => '[LBR.FLIGHT] conversion status=$status '
            'af_status=${received['af_status']} keys=${received.keys.toList()}',
      );
      if (failed) {
        _installBag = <String, dynamic>{};
      } else if (received['af_status'] == 'Organic') {
        // Small wait, then re-fetch via GCD — the SDK sometimes reports an
        // install as Organic that the GCD server later reclassifies.
        await Future<void>.delayed(
          const Duration(seconds: LanternRallyEnv.organicRecheckSeconds),
        );
        _installBag = await _fetchGcd() ?? received;
      } else {
        _installBag = received;
      }
    } catch (error) {
      lbrTrace(() => '[LBR.FLIGHT] conversion parse error: $error');
      _installBag = <String, dynamic>{};
    } finally {
      if (!_installReady.isCompleted) _installReady.complete();
    }
  }

  Map<String, dynamic> _flatten(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final map = Map<String, dynamic>.from(raw);
    final payload = map['payload'];
    return payload is Map ? Map<String, dynamic>.from(payload) : map;
  }

  Future<Map<String, dynamic>?> _fetchGcd() async {
    final uid = await appsFlyerId();
    if (uid == null || uid.isEmpty) return null;
    try {
      // iOS GCD lookup uses the numeric App Store id, not the bundle id.
      final base = LanternRallyEnv.gcdBase;
      final separator = base.contains('?') ? '&' : '?';
      final uri = Uri.parse(
        '$base${separator}app_id=${LanternRallyEnv.iosStoreId}&device_id=$uid',
      );
      final response = await _agent
          .get(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer ${LanternRallyEnv.appsFlyerKey}',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> awaitSignals({
    Duration installTimeout = const Duration(seconds: 8),
  }) async {
    await start();
    await Future.wait<void>(<Future<void>>[
      _installReady.future.timeout(installTimeout, onTimeout: () {}),
      _deepLinkReady.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      ),
    ]);
  }

  Future<String?> appsFlyerId() async {
    try {
      return await _sdk?.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> compose({
    required String locale,
    String? pushToken,
  }) async {
    // Build the config body as a FLAT object (no nested attribution key).
    // Field names below are the backend contract — never rename.
    final body = <String, dynamic>{};
    if (_installBag != null) body.addAll(_installBag!);
    if (_reopenBag != null) {
      _reopenBag!.forEach((key, value) => body.putIfAbsent(key, () => value));
    }
    if (_deepLinkBag != null) {
      _deepLinkBag!.forEach(
        (key, value) => body.putIfAbsent(key, () => value),
      );
    }

    body['af_id'] = await appsFlyerId() ?? body['af_id'] ?? '';
    body['bundle_id'] = LanternRallyEnv.bundleId;
    body['os'] = 'iOS';
    body['store_id'] = LanternRallyEnv.storeToken;
    body['locale'] = locale;
    final firebaseProject = LanternRallyEnv.firebaseProjectNumber;
    if (pushToken != null &&
        pushToken.isNotEmpty &&
        firebaseProject.isNotEmpty) {
      body['push_token'] = pushToken;
      body['firebase_project_id'] = firebaseProject;
    }

    if (Platform.isIOS) {
      try {
        final att = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (att == TrackingStatus.authorized) {
          final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
          if (idfa.isNotEmpty && !idfa.startsWith('00000000-')) {
            body['sub_id_10'] = idfa;
          }
        }
      } catch (_) {}
    }
    lbrTrace(() => '[LBR.FLIGHT] payload ${jsonEncode(body)}');
    return body;
  }

  void _completeEmpty() {
    if (!_installReady.isCompleted) _installReady.complete();
    if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
  }
}
