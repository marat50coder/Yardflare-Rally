// ignore_for_file: avoid_print

import 'dart:typed_data';

const List<int> _nestSalt = <int>[
  0x59,
  0x66,
  0x52,
  0x61,
  0x6C,
  0x6C,
  0x79,
  0x21,
  0x32,
  0x36,
  0x6E,
  0x69,
  0x74,
  0x65,
];

Uint8List _buildFeatherStream(int length) {
  final state = List<int>.generate(256, (index) => index);
  var cursor = 0;
  for (var index = 0; index < state.length; index++) {
    cursor =
        (cursor + state[index] + _nestSalt[index % _nestSalt.length]) & 0xff;
    final swap = state[index];
    state[index] = state[cursor];
    state[cursor] = swap;
  }
  final result = Uint8List(length);
  var left = 0;
  var right = 0;
  for (var index = 0; index < length; index++) {
    left = (left + 1) & 0xff;
    right = (right + state[left] + index) & 0xff;
    final swap = state[left];
    state[left] = state[right];
    state[right] = swap;
    result[index] = state[(state[left] + state[right]) & 0xff];
  }
  return result;
}

List<int> fold(String value) {
  final bytes = Uint8List.fromList(value.codeUnits);
  final stream = _buildFeatherStream(bytes.length);
  return List<int>.generate(
    bytes.length,
    (index) => (bytes[index] + stream[index] + (index * 17)) & 0xff,
  );
}

String unfold(List<int> encoded) {
  final stream = _buildFeatherStream(encoded.length);
  return String.fromCharCodes(
    List<int>.generate(
      encoded.length,
      (index) => (encoded[index] - stream[index] - (index * 17)) & 0xff,
    ),
  );
}

void main() {
  // TEMPLATE: fill these, then paste the printed arrays into
  // lib/hatchway/config/era_hatch_config.dart. Change `_nestSalt` in
  // lib/hatchway/core/feather_codec.dart FIRST so the arrays are unique.
  const values = <String, String>{
    'config': 'https://yardflarerally.com/config.php',
    'privacy': 'https://yardflarerally.com/privacy-policy.html',
    'support': 'https://yardflarerally.com/support.html',
    'gcd': 'https://gcdsdk.appsflyer.com/install_data/v5.0/',
    'webkit': '605.1.15',
    'safari': '18.5',
    'safariTail': '604.1',
    'appsFlyerDevKey': 'Z4xCKFgFBxttFApwyBN9HE',
    'firebaseProjectNumber': '758507237424',
    'oneLinkHost': 'yardflarerally.onelink.me',
  };

  for (final entry in values.entries) {
    final encoded = fold(entry.value);
    print('${entry.key}: <int>[${encoded.join(', ')}]');
    if (unfold(encoded) != entry.value) {
      throw StateError('Round-trip failed for ${entry.key}');
    }
  }
  print('VERIFY: all values round-tripped');
}
