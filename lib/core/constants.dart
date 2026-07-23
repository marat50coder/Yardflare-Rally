/// Central place for asset paths and shared gameplay constants.
///
/// Flutter widgets use these paths directly. The Flame game sets its image
/// cache prefix to an empty string so it can load the exact same paths.
class Assets {
  Assets._();

  static const String _base = 'assets';
  static const String _sprites = '$_base/sprites';

  // Branding / screens.
  static const String icon = '$_base/Icon.png';
  static const String gameName = '$_base/Game_Name.webp';
  static const String loadingVertical = '$_base/Vertical_Loading_Screen.webp';
  static const String loadingHorizontal = '$_base/Horizontal_Loading_Screen.webp';

  // Backgrounds (seamless ground textures).
  static const List<String> backgrounds = [
    '$_base/bg1_asset.webp',
    '$_base/bg2_asset.webp',
    '$_base/bg3_asset.webp',
    '$_base/bg4_asset.webp',
    '$_base/bg5_asset.webp',
    '$_base/bg6_asset.webp',
  ];

  // Enemies (row_col from the sheet).
  static const String enemyMouse = '$_sprites/enemy_asset/0_0.png';
  static const String enemyRaccoon = '$_sprites/enemy_asset/0_1.png';
  static const String enemyFox = '$_sprites/enemy_asset/0_2.png';
  static const String enemyBadger = '$_sprites/enemy_asset/0_3.png';
  static const String enemyWolf = '$_sprites/enemy_asset/0_4.png';
  static const String enemyOwl = '$_sprites/enemy_asset/1_0.png';
  static const String enemyBoar = '$_sprites/enemy_asset/1_1.png';
  static const String enemyCrow = '$_sprites/enemy_asset/1_2.png';

  // Lantern charge states (bright -> off -> broken).
  static const List<String> lanternStates = [
    '$_sprites/lanterns_asset/0_0.png', // full bright
    '$_sprites/lanterns_asset/0_1.png', // bright
    '$_sprites/lanterns_asset/0_2.png', // medium
    '$_sprites/lanterns_asset/1_0.png', // low (orange)
    '$_sprites/lanterns_asset/1_1.png', // off (dark)
    '$_sprites/lanterns_asset/1_2.png', // broken/off
  ];

  // Power-up icons.
  static const String puFullIgnite = '$_sprites/amplify_asset/0_0.png';
  static const String puSpeedBoost = '$_sprites/amplify_asset/0_1.png';
  static const String puCoinMagnet = '$_sprites/amplify_asset/0_2.png';
  static const String puSlowTime = '$_sprites/amplify_asset/0_3.png';
  static const String puCoopShield = '$_sprites/amplify_asset/0_4.png';
  static const String puDoubleCoins = '$_sprites/amplify_asset/1_0.png';
  static const String puBonusEgg = '$_sprites/amplify_asset/1_1.png';
  static const String puLanternBuddy = '$_sprites/amplify_asset/1_2.png';
  static const String puShockwave = '$_sprites/amplify_asset/1_3.png';
  static const String puWhistle = '$_sprites/amplify_asset/1_4.png';

  // Coins & eggs.
  static const String coinChicken = '$_sprites/coins_and_eggs_asset/0_0.png';
  static const String coinFeather = '$_sprites/coins_and_eggs_asset/1_0.png';
  static const String eggWhite = '$_sprites/coins_and_eggs_asset/2_0.png';
  static const String eggGold = '$_sprites/coins_and_eggs_asset/3_2.png';
  static const String eggCracked = '$_sprites/coins_and_eggs_asset/2_5.png';
  static const String eggRainbow = '$_sprites/coins_and_eggs_asset/3_0.png';
  static const String eggNest = '$_sprites/coins_and_eggs_asset/2_8.png';

  // Coops per location.
  static const List<String> coops = [
    '$_sprites/coop/0.png',
    '$_sprites/coop/1.png',
    '$_sprites/coop/2.png',
    '$_sprites/coop/3.png',
    '$_sprites/coop/4.png',
  ];

  // Chicken skins 1..11.
  static String chickenSkin(int index) => '$_sprites/chicken/skin$index.png';

  // A few decorations used to dress the yard.
  static const String decorTree = '$_sprites/decorative_objects/1_5.png';
  static const String decorBush = '$_sprites/decorative_objects/1_3.png';
  static const String decorHay = '$_sprites/decorative_objects/1_9.png';
  static const String decorBarrel = '$_sprites/decorative_objects/1_1.png';
  static const String decorRock = '$_sprites/decorative_objects/2_4.png';
  static const String decorFlowers = '$_sprites/decorative_objects/1_7.png';

  // Sounds (played through FlameAudio with an empty prefix).
  static const String sndButton = 'sounds/button_click_asset.mp3';
  static const String sndRun = 'sounds/chicken_run_asset.mp3';
  static const String sndRelight = 'sounds/lighting_a_rustic_lantern_asset.mp3';
  static const String sndLanternFade = 'sounds/lantern_flame_fading_away_asset.mp3';
  static const String sndSpawn = 'sounds/spawn_enemy_asset.mp3';
  static const String sndWarning = 'sounds/warning_asset.mp3';
  static const String sndScare = 'sounds/successfully_scaring_enemy_asset.mp3';
  static const String sndCoin = 'sounds/collecting_a_shiny_gold_coin_asset.mp3';
  static const String sndEggCollect = 'sounds/collecting_an_egg_asset.mp3';
  static const String sndPowerup = 'sounds/ampify_take_asset.mp3';
  static const String sndEggLost = 'sounds/losing_an_egg_asset.mp3';
  static const String sndVictory = 'sounds/victory_win_asset.mp3';
  static const String sndDefeat = 'sounds/defeat_lose_asset.mp3';
  static const String sndWave = 'sounds/start_new_wave_asset.mp3';
  static const String sndUpgrade = 'sounds/buy_upgrade_asset.mp3';

  // Generated ambient music beds.
  static const String musicMenu = 'sounds/music_menu.wav';
  static const String musicGame = 'sounds/music_game.wav';

  /// All image assets pre-cached during loading. Keeps the first frame smooth.
  static List<String> preloadImages() => [
        gameName,
        ...backgrounds,
        enemyMouse, enemyRaccoon, enemyFox, enemyBadger,
        enemyWolf, enemyOwl, enemyBoar, enemyCrow,
        ...lanternStates,
        puFullIgnite, puSpeedBoost, puCoinMagnet, puSlowTime, puCoopShield,
        puDoubleCoins, puBonusEgg, puLanternBuddy, puShockwave, puWhistle,
        coinChicken, coinFeather, eggWhite, eggGold, eggCracked, eggRainbow, eggNest,
        ...coops,
        for (int i = 1; i <= 11; i++) chickenSkin(i),
        decorTree, decorBush, decorHay, decorBarrel, decorRock, decorFlowers,
      ];
}

/// Fixed gameplay tuning shared across levels (per-level values live in configs).
class GameTuning {
  GameTuning._();

  static const double baseChickenSpeed = 210; // px/s at upgrade level 0
  static const double chickenAccel = 1400;
  static const double lanternRechargeRadius = 90;
  static const double baseRechargePerSecond = 55; // % per second nearby
  static const double scareRadius = 74;
  static const double dashScareRadius = 120;
  static const double baseDashCooldown = 3.2; // seconds
  static const double dashDuration = 0.32;
  static const double dashSpeedMultiplier = 3.1;
  static const double coinMagnetBaseRadius = 70;
  static const double restBetweenWaves = 4.0;
  static const double spawnWarningTime = 1.6;
}
