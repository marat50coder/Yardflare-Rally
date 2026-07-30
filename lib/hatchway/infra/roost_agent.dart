import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import '../config/era_hatch_config.dart';

/// HTTP wrapper that forges a Mobile Safari `User-Agent` for every
/// outbound request AND exposes the same string for the WebView. The two
/// MUST match — the partner backend cross-checks them to keep session
/// continuity between the config POST and the WKWebView load.
class HerderAgent extends http.BaseClient {
  final http.Client _wire = http.Client();
  static const String _fallbackIos = '18.6';
  static const int _minIosMajor = 18;
  String? _cachedUa;

  Future<void> prepare() async {
    try {
      if (!Platform.isIOS) {
        _cachedUa = _dressAsSafari(_fallbackIos);
        return;
      }
      final info = await DeviceInfoPlugin().iosInfo;
      _cachedUa = _dressAsSafari(_pickIosLabel(info.systemVersion));
    } catch (_) {
      _cachedUa = _dressAsSafari(_fallbackIos);
    }
  }

  String get userAgent => _cachedUa ??= _dressAsSafari(_fallbackIos);

  String _pickIosLabel(String reported) {
    final parts = reported
        .split('.')
        .map(int.tryParse)
        .whereType<int>()
        .take(3)
        .toList(growable: false);
    if (parts.isEmpty) return _fallbackIos;
    final major = parts.first;
    if (major < _minIosMajor) return _fallbackIos;
    return parts.join('.');
  }

  // GAME THEME CATEGORY: crash (no `appid/appname` suffix appended).
  String _dressAsSafari(String iosLabel) {
    final cpu = iosLabel.replaceAll('.', '_');
    final webKit = LanternRallyEnv.webKitVersion;
    final safari = LanternRallyEnv.safariVersion;
    final tail = LanternRallyEnv.safariTail;
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS $cpu like Mac OS X) '
        'AppleWebKit/$webKit (KHTML, like Gecko) '
        'Version/$safari Mobile/15E148 Safari/$tail';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _wire.send(request);
  }

  @override
  void close() => _wire.close();
}
