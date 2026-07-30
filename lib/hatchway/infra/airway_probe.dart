import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reachability probe. Uses `connectivity_plus` for the cheap "is there ANY
/// interface" check and a bounded DNS lookup for the real "can we actually
/// reach the internet" question (VPN + captive portal false positives).
class PastureScout {
  final Connectivity _link = Connectivity();
  static const Duration _dnsTimeout = Duration(milliseconds: 2600);
  static const Duration _retryDelay = Duration(milliseconds: 220);
  static const List<String> _anchors = <String>[
    'www.wikipedia.org',
    'www.microsoft.com',
  ];
  int _preferredAnchor = 0;

  Future<bool> hasInterface() async {
    try {
      final status = await _link.checkConnectivity();
      return status.any((value) => value != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Single-anchor-with-fallback probe. Keeps the last-successful host in
  /// `_preferredAnchor` so subsequent probes hit it first (cheaper DNS on
  /// warm cache). If the preferred host misses, we try the other one; if
  /// that also fails we do ONE short retry with a small backoff so a
  /// transient DNS blip does not flip us to offline.
  Future<bool> canReachNetwork() async {
    if (!await hasInterface()) return false;
    for (var attempt = 0; attempt < 2; attempt++) {
      final ordered = <String>[
        _anchors[_preferredAnchor],
        _anchors[(_preferredAnchor + 1) % _anchors.length],
      ];
      for (var i = 0; i < ordered.length; i++) {
        if (await _resolves(ordered[i])) {
          _preferredAnchor =
              (_preferredAnchor + (i == 0 ? 0 : 1)) % _anchors.length;
          return true;
        }
      }
      if (attempt == 0) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    return false;
  }

  Future<bool> _resolves(String host) async {
    try {
      final records = await InternetAddress.lookup(host).timeout(_dnsTimeout);
      return records.any((record) => record.rawAddress.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  Stream<List<ConnectivityResult>> get changes => _link.onConnectivityChanged;
}
