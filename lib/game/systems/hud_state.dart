import 'package:flutter/foundation.dart';

import '../../models/powerup_type.dart';

/// A running power-up effect shown on the HUD with a countdown.
class ActivePowerupView {
  final PowerUpType type;
  final double remaining;
  final double total;
  const ActivePowerupView(this.type, this.remaining, this.total);
  double get ratio => total <= 0 ? 0 : (remaining / total).clamp(0.0, 1.0);
}

/// All the reactive values the Flutter HUD binds to. The game writes, the HUD
/// reads. Using separate [ValueNotifier]s keeps rebuilds tiny.
class HudState {
  final ValueNotifier<int> eggs = ValueNotifier(0);
  final ValueNotifier<int> maxEggs = ValueNotifier(0);
  final ValueNotifier<int> coins = ValueNotifier(0);
  final ValueNotifier<int> wave = ValueNotifier(0);
  final ValueNotifier<int> waveTotal = ValueNotifier(0);
  final ValueNotifier<int> lit = ValueNotifier(0);
  final ValueNotifier<int> lanternTotal = ValueNotifier(0);
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<double> dashProgress = ValueNotifier(1); // 1 = ready
  final ValueNotifier<double> waveTimeLeft = ValueNotifier(0);
  final ValueNotifier<String> phase = ValueNotifier('');
  final ValueNotifier<String?> tutorial = ValueNotifier(null);
  final ValueNotifier<List<ActivePowerupView>> activePowerups = ValueNotifier([]);
  final ValueNotifier<List<PowerUpType>> inventory = ValueNotifier([]);
  final ValueNotifier<bool> endless = ValueNotifier(false);
  final ValueNotifier<int> bannerTick = ValueNotifier(0);
  final ValueNotifier<String> banner = ValueNotifier('');

  void showBanner(String text) {
    banner.value = text;
    bannerTick.value++;
  }

  void dispose() {
    for (final n in [
      eggs, maxEggs, coins, wave, waveTotal, lit, lanternTotal, score,
      combo, dashProgress, waveTimeLeft,
    ]) {
      n.dispose();
    }
    phase.dispose();
    tutorial.dispose();
    activePowerups.dispose();
    inventory.dispose();
    endless.dispose();
    bannerTick.dispose();
    banner.dispose();
  }
}
