import 'dart:typed_data';

// ══════════════════════════════════════════════════════════════════════════
// Torch codec — byte-level obfuscator for URLs / keys shipped inside the app.
//
// Algorithm family: **position-driven FNV-1a keystream + XOR + variable
// bitwise rotation**. Deliberately dissimilar from RC4 (no permutation
// table, no cursor swap loop) so the compiled bytes look nothing like a
// sibling app's cipher. If you touch anything below, regenerate every
// encoded byte array via `tool/encode_era_values.dart` and confirm the
// VERIFY block round-trips byte-for-byte.
// ══════════════════════════════════════════════════════════════════════════

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
    // Blend the byte position (1-based so the first byte isn't identity).
    h = ((h ^ (i + 1)) & _mask32) * _fnvPrime;
    h &= _mask32;
    // Fold 32 → 8 bits by XOR-ing all four bytes together.
    out[i] = ((h ^ (h >>> 8) ^ (h >>> 16) ^ (h >>> 24)) & 0xFF);
  }
  return out;
}

int _rotateRight8(int byte, int amount) {
  final r = amount & 7;
  if (r == 0) return byte & 0xFF;
  return ((byte >>> r) | (byte << (8 - r))) & 0xFF;
}

/// Reads back a plaintext string from an encoded byte array. Every URL /
/// key in `LanternRallyEnv` runs through this at cold start.
String openLantern(List<int> encoded) {
  if (encoded.isEmpty) return '';
  final stream = _growPattern(encoded.length);
  final decoded = Uint8List(encoded.length);
  for (var i = 0; i < encoded.length; i++) {
    final rot = _torchKernel[i % _torchKernel.length];
    // Undo the left-rotation applied by the encoder, then XOR out the
    // position-driven keystream. Result is the original character byte.
    decoded[i] = (_rotateRight8(encoded[i], rot) ^ stream[i]) & 0xFF;
  }
  return String.fromCharCodes(decoded);
}
