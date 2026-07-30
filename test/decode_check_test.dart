import 'package:flutter_test/flutter_test.dart';
import 'package:rallygame/hatchway/config/era_hatch_config.dart';

void main() {
  test('encoded byte arrays round-trip to the expected plaintext', () {
    expect(LanternRallyEnv.endpoint, 'https://yardflarerally.com/config.php');
    expect(LanternRallyEnv.privacyUrl,
        'https://yardflarerally.com/privacy-policy.html');
    expect(LanternRallyEnv.supportUrl,
        'https://yardflarerally.com/support.html');
    expect(LanternRallyEnv.gcdBase,
        'https://gcdsdk.appsflyer.com/install_data/v5.0/');
    expect(LanternRallyEnv.webKitVersion, '605.1.15');
    expect(LanternRallyEnv.safariVersion, '18.6');
    expect(LanternRallyEnv.safariTail, '604.1');
    expect(LanternRallyEnv.appsFlyerKey, 'Z4xCKFgFBxttFApwyBN9HE');
    expect(LanternRallyEnv.firebaseProjectNumber, '758507237424');
    expect(LanternRallyEnv.oneLinkHost, 'yardflarerally.onelink.me');
    expect(LanternRallyEnv.storeToken, 'id6792709646');
    expect(LanternRallyEnv.grayCredentialsReady, isTrue);
  });
}
