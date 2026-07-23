import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';

import '../core/constants.dart';
import '../models/enemy_type.dart';

/// Loads and holds every [Sprite] the game needs, keyed by asset path.
class SpriteBank {
  final Map<String, Sprite> _sprites = {};

  Sprite operator [](String path) => _sprites[path]!;
  Sprite? maybe(String path) => _sprites[path];

  Future<void> loadAll(Images images) async {
    final paths = <String>{
      ...Assets.backgrounds,
      ...Assets.lanternStates,
      ...Assets.coops,
      Assets.coinChicken,
      Assets.coinFeather,
      Assets.eggWhite,
      Assets.eggGold,
      Assets.eggCracked,
      Assets.eggRainbow,
      Assets.eggNest,
      Assets.puFullIgnite,
      Assets.puSpeedBoost,
      Assets.puCoinMagnet,
      Assets.puSlowTime,
      Assets.puCoopShield,
      Assets.puDoubleCoins,
      Assets.puLanternBuddy,
      Assets.puShockwave,
      Assets.decorTree,
      Assets.decorBush,
      Assets.decorHay,
      Assets.decorBarrel,
      Assets.decorRock,
      Assets.decorFlowers,
      for (final k in EnemyKind.all.values) k.sprite,
      for (int i = 1; i <= 11; i++) Assets.chickenSkin(i),
    };
    for (final p in paths) {
      _sprites[p] = await Sprite.load(p, images: images);
    }
  }
}
