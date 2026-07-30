import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Consumes the cold-start deep link that `SceneDelegate` wrote into
/// `UserDefaults` when the user tapped a notification while the app was
/// killed. The Swift side writes under `flutter.<_dartKey>` (the
/// `flutter.` prefix is added by the shared_preferences bridge — do NOT
/// duplicate it here).
class ColdLinkReader {
  static const String _dartKey = 'lbr_cold_link';

  static Future<String?> consume() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_dartKey)?.trim();
      if (value == null || value.isEmpty) return null;
      await prefs.remove(_dartKey);
      return value;
    } catch (_) {
      return null;
    }
  }
}
