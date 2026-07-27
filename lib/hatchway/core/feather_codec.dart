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

String unfoldFeathers(List<int> encoded) {
  if (encoded.isEmpty) return '';
  final stream = _buildFeatherStream(encoded.length);
  final plain = Uint8List(encoded.length);
  for (var index = 0; index < encoded.length; index++) {
    plain[index] = (encoded[index] - stream[index] - (index * 17)) & 0xff;
  }
  return String.fromCharCodes(plain);
}
