import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/hatch_models.dart';

/// Local persistence bag for the gray flow — the last routing decision,
/// the cached target URL, push-permission state, and the one-shot push
/// deep-link buffer. Keys are prefixed uniquely per project.
class CoopSafe {
  // Namespace prefix — never share with a sibling app.
  static const String _routeKey = 'lbr.roost.route';
  static const String _expiryKey = 'lbr.roost.expiry';
  static const String _inviteKey = 'lbr.roost.invite.after';
  static const String _grantedKey = 'lbr.roost.push.granted';
  static const String _osBlockedKey = 'lbr.roost.push.os_blocked';
  static const String _cachedUrlKey = 'lbr.roost.secure.dest';
  static const String _pendingUrlKey = 'lbr.roost.secure.pending';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  PortalRoute get route => PortalRoute.parse(_prefs.getString(_routeKey));

  Future<void> saveRoute(PortalRoute value) =>
      _prefs.setString(_routeKey, value.storageValue);

  Future<String?> savedUrl() async {
    try {
      return await _secure.read(key: _cachedUrlKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheUrl(String url, int? expiresAt) async {
    try {
      await _secure.write(key: _cachedUrlKey, value: url);
      if (expiresAt != null) {
        await _prefs.setInt(_expiryKey, expiresAt);
      }
    } catch (_) {}
  }

  bool get cachedUrlExpired {
    final expiry = _prefs.getInt(_expiryKey);
    return expiry == null ||
        DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiry;
  }

  Future<void> stashPushUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    try {
      await _secure.write(key: _pendingUrlKey, value: trimmed);
    } catch (_) {}
  }

  Future<String?> consumePushUrl() async {
    try {
      final value = await _secure.read(key: _pendingUrlKey);
      if (value != null) await _secure.delete(key: _pendingUrlKey);
      return value;
    } catch (_) {
      return null;
    }
  }

  bool get pushAllowed => _prefs.getBool(_grantedKey) ?? false;
  bool get pushDeniedByOs => _prefs.getBool(_osBlockedKey) ?? false;

  Future<void> setPushAllowed(bool value) =>
      _prefs.setBool(_grantedKey, value);

  Future<void> markPushDeniedByOs() => _prefs.setBool(_osBlockedKey, true);

  bool get shouldShowPushInvite {
    if (pushAllowed || pushDeniedByOs) return false;
    final after = _prefs.getInt(_inviteKey);
    return after == null ||
        DateTime.now().millisecondsSinceEpoch ~/ 1000 >= after;
  }

  Future<void> snoozePushInvite(int epochSeconds) =>
      _prefs.setInt(_inviteKey, epochSeconds);
}
