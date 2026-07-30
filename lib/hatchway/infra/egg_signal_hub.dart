import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'nest_vault.dart';

/// Background isolate entry point required by `firebase_messaging`. Empty
/// body: rich media is handled by the NSE, and everything else runs when
/// the app is foregrounded via `onMessageOpenedApp`.
@pragma('vm:entry-point')
Future<void> lbrBackgroundMessage(RemoteMessage _) async {}

/// Push / cold-start hub. Owns the FCM lifecycle, waits for the APNs
/// token to settle, and forwards deep-link URLs from the notification
/// payload to the WebView (or stashes them if the WebView is not up yet).
class TorchRelay {
  TorchRelay(this._safe, {required this.enabled});

  final CoopSafe _safe;
  final bool enabled;
  FirebaseMessaging? _wire;
  Future<void>? _bootstrap;
  Future<bool>? _pendingPermission;
  String? _lastToken;

  void Function(String url)? onDestination;
  void Function(String token)? onTokenChanged;

  String? get token => _lastToken;

  Future<void> boot() => _bootstrap ??= _boot();

  Future<void> _boot() async {
    if (!enabled) return;
    final wire = FirebaseMessaging.instance;
    _wire = wire;
    // Read the initial (cold-start) message BEFORE registering listeners
    // so we do not miss it if listeners fire between here and the wait.
    final initial = await wire.getInitialMessage().timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );
    if (initial != null) {
      final url = _dig(initial.data);
      if (url != null) await _safe.stashPushUrl(url);
    }

    FirebaseMessaging.onBackgroundMessage(lbrBackgroundMessage);
    await wire.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    wire.onTokenRefresh.listen((value) {
      _lastToken = value;
      onTokenChanged?.call(value);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final url = _dig(message.data);
      if (url == null) return;
      final callback = onDestination;
      if (callback == null) {
        _safe.stashPushUrl(url);
      } else {
        callback(url);
      }
    });
    await _waitForApns();
    _lastToken = await wire.getToken();
  }

  /// Walks the FCM payload looking for a URL under any of the common keys.
  /// Recurses into `payload` / `data` sub-maps so the shape matches what
  /// server-side sends in either layout.
  String? _dig(Map<String, dynamic> payload) {
    const keys = <String>['deep_link', 'target', 'url', 'deeplink', 'link'];
    for (final key in keys) {
      final value = payload[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    for (final container in const <String>['payload', 'data']) {
      final nested = payload[container];
      if (nested is Map) {
        final found = _dig(Map<String, dynamic>.from(nested));
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> _waitForApns({int attempts = 6}) async {
    final wire = _wire;
    if (wire == null) return;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final apns = await wire.getAPNSToken();
        if (apns != null && apns.isNotEmpty) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 550));
    }
  }

  Future<bool> canOfferPermission() async {
    if (!enabled || _safe.pushDeniedByOs) return false;
    final wire = _wire;
    if (wire == null) return false;
    final settings = await wire.getNotificationSettings();
    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.denied) {
      await _safe.markPushDeniedByOs();
      return false;
    }
    return status == AuthorizationStatus.notDetermined ||
        status == AuthorizationStatus.provisional;
  }

  Future<bool> askPermission() => _pendingPermission ??=
      _runPermissionRequest().whenComplete(() => _pendingPermission = null);

  Future<bool> _runPermissionRequest() async {
    final wire = _wire;
    if (!enabled || wire == null) return false;
    final response = await wire.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final status = response.authorizationStatus;
    final accepted = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    await _safe.setPushAllowed(accepted);
    if (!accepted && status == AuthorizationStatus.denied) {
      await _safe.markPushDeniedByOs();
    }
    if (accepted) {
      await _waitForApns(attempts: 14);
      _lastToken = await wire.getToken();
      final token = _lastToken;
      if (token != null && token.isNotEmpty) onTokenChanged?.call(token);
    }
    return accepted;
  }
}
