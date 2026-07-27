import 'package:flutter_test/flutter_test.dart';

import 'package:rallygame/main.dart';

void main() {
  test('root app widget constructs', () {
    expect(const YardflareApp(), isA<YardflareApp>());
  });
}
