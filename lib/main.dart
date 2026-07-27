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

/// Entry point. Warms up the gray-flow services, then mounts the boot screen
/// which runs the attribution → config pipeline and routes to either the
/// WebView (non-organic) or the native Yardflare game (organic / reviewers).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final vault = NestVault();
  final agent = RoostAgent();
  await Future.wait<void>(<Future<void>>[
    vault.initialize(),
    agent.prepare(),
  ]);

  assert(() {
    debugPrint(
      '[YFR.BOOT] credentialsReady=${EraHatchConfig.grayCredentialsReady} '
      'endpoint=${EraHatchConfig.endpoint} '
      'afKeyLen=${EraHatchConfig.appsFlyerKey.length} '
      'fbNum=${EraHatchConfig.firebaseProjectNumber}',
    );
    return true;
  }());

  var productionServicesReady = false;
  if (EraHatchConfig.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      productionServicesReady = true;
    } catch (error) {
      assert(() {
        debugPrint('[YFR.BOOT] Firebase.initializeApp failed: $error');
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
          debugPrint('[YFR.BOOT] AppCheck skipped: $error');
          return true;
        }());
      }
    }
  }

  final probe = AirwayProbe();
  // Attribution + config POST must run even if Firebase failed to init;
  // only push/FCM needs productionServicesReady.
  final notifications = EggSignalHub(vault, enabled: productionServicesReady);
  final attribution = FlightAttribution(agent);
  final coordinator = HatchCoordinator(
    vault: vault,
    probe: probe,
    attribution: attribution,
    exchange: HatchExchange(agent, vault),
    notifications: notifications,
    agent: agent,
    runtimeEnabled: EraHatchConfig.grayCredentialsReady,
  );

  runApp(YardflareApp(hatchCoordinator: coordinator));
}

class YardflareApp extends StatelessWidget {
  const YardflareApp({super.key, this.hatchCoordinator});

  final HatchCoordinator? hatchCoordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yardflare Rally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: BootScreen(hatchCoordinator: hatchCoordinator),
    );
  }
}
