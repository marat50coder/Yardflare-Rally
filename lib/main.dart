import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'hatchway/config/era_hatch_config.dart';
import 'hatchway/hatch_coordinator.dart';
import 'hatchway/infra/airway_probe.dart';
import 'hatchway/infra/egg_signal_hub.dart';
import 'hatchway/infra/flight_attribution.dart';
import 'hatchway/infra/hatch_exchange.dart';
import 'hatchway/infra/nest_vault.dart';
import 'hatchway/infra/roost_agent.dart';
import 'screens/boot_screen.dart';

/// Entry point. Warms up the gray-flow services, then mounts the boot
/// screen which runs the attribution → config pipeline and routes to
/// either the WebView (non-organic) or the native Yardflare game
/// (organic / reviewers).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final safe = CoopSafe();
  final agent = HerderAgent();
  await Future.wait<void>(<Future<void>>[
    safe.initialize(),
    agent.prepare(),
  ]);

  assert(() {
    debugPrint(
      '[LBR.BOOT] credentialsReady=${LanternRallyEnv.grayCredentialsReady} '
      'endpoint=${LanternRallyEnv.endpoint} '
      'afKeyLen=${LanternRallyEnv.appsFlyerKey.length} '
      'fbNum=${LanternRallyEnv.firebaseProjectNumber}',
    );
    return true;
  }());

  var productionServicesReady = false;
  if (LanternRallyEnv.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      productionServicesReady = true;
    } catch (error) {
      assert(() {
        debugPrint('[LBR.BOOT] Firebase.initializeApp failed: $error');
        return true;
      }());
    }
    if (productionServicesReady) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (error) {
        // App Check must never block FCM / gray routing.
        assert(() {
          debugPrint('[LBR.BOOT] AppCheck skipped: $error');
          return true;
        }());
      }
    }
  }

  final scout = PastureScout();
  // Attribution + config POST must run even if Firebase failed to init;
  // only push / FCM needs productionServicesReady.
  final torches = TorchRelay(safe, enabled: productionServicesReady);
  final tracker = TrackerRelay(agent);
  final router = WardenRouter(
    safe: safe,
    scout: scout,
    tracker: tracker,
    relay: SignalExchange(agent, safe),
    torches: torches,
    agent: agent,
    runtimeEnabled: LanternRallyEnv.grayCredentialsReady,
  );

  runApp(YardflareApp(router: router));
}

class YardflareApp extends StatelessWidget {
  const YardflareApp({super.key, this.router});

  final WardenRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yardflare Rally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: BootScreen(router: router),
    );
  }
}
