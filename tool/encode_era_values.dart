// ignore_for_file: avoid_print

import 'dart:typed_data';

// Encoder side of the torch codec. MUST stay algorithmically identical to
// lib/hatchway/core/feather_codec.dart — any change here requires a matching
// change there, and every byte array in era_hatch_config.dart must be
// regenerated. Round-trip is asserted at the bottom of main().

const List<int> _torchKernel = <int>[
  0x9A, 0x3F, 0xC1, 0x27, 0x8B, 0xD4, 0x66, 0xE0,
  0x1B, 0x7E, 0xA3, 0x59, 0x82, 0xCC, 0x0D, 0xB7, 0x44,
];

const int _fnvOffset = 0x811C9DC5;
const int _fnvPrime = 0x01000193;
const int _mask32 = 0xFFFFFFFF;

Uint8List _growPattern(int span) {
  final out = Uint8List(span);
  for (var i = 0; i < span; i++) {
    var h = _fnvOffset;
    for (var j = 0; j < _torchKernel.length; j++) {
      h = ((h ^ _torchKernel[j]) & _mask32) * _fnvPrime;
      h &= _mask32;
    }
    h = ((h ^ (i + 1)) & _mask32) * _fnvPrime;
    h &= _mask32;
    out[i] = ((h ^ (h >>> 8) ^ (h >>> 16) ^ (h >>> 24)) & 0xFF);
  }
  return out;
}

int _rotateLeft8(int byte, int amount) {
  final r = amount & 7;
  if (r == 0) return byte & 0xFF;
  return ((byte << r) | (byte >>> (8 - r))) & 0xFF;
}

int _rotateRight8(int byte, int amount) {
  final r = amount & 7;
  if (r == 0) return byte & 0xFF;
  return ((byte >>> r) | (byte << (8 - r))) & 0xFF;
}

List<int> seal(String value) {
  final bytes = Uint8List.fromList(value.codeUnits);
  final stream = _growPattern(bytes.length);
  return List<int>.generate(bytes.length, (i) {
    final rot = _torchKernel[i % _torchKernel.length];
    final xored = (bytes[i] ^ stream[i]) & 0xFF;
    return _rotateLeft8(xored, rot);
  });
}

String unseal(List<int> encoded) {
  final stream = _growPattern(encoded.length);
  return String.fromCharCodes(
    List<int>.generate(encoded.length, (i) {
      final rot = _torchKernel[i % _torchKernel.length];
      return (_rotateRight8(encoded[i], rot) ^ stream[i]) & 0xFF;
    }),
  );
}

void main() {
  // Plaintext values for Yardflare Rally. Bump `safari` per project to keep
  // the User-Agent fingerprint from clustering with sibling apps.
  const values = <String, String>{
    'endpoint': 'https://yardflarerally.com/config.php',
    'privacy': 'https://yardflarerally.com/privacy-policy.html',
    'support': 'https://yardflarerally.com/support.html',
    'gcd': 'https://gcdsdk.appsflyer.com/install_data/v5.0/',
    'webkit': '605.1.15',
    'safari': '18.6',
    'safariTail': '604.1',
    'appsFlyerKey': 'Z4xCKFgFBxttFApwyBN9HE',
    'firebaseProjectNumber': '758507237424',
    'oneLinkHost': 'yardflarerally.onelink.me',
  };

  for (final entry in values.entries) {
    final encoded = seal(entry.value);
    print('${entry.key}: <int>[${encoded.join(', ')}]');
    final decoded = unseal(encoded);
    if (decoded != entry.value) {
      throw StateError(
        'Round-trip failed for ${entry.key}: '
        'expected "${entry.value}", got "$decoded"',
      );
    }
  }
  print('VERIFY: every plaintext survived seal→unseal byte-for-byte');
}
