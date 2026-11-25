// The chests (v1.899, v2.5.0): wooden, iron, gold, silver and void are the
// 32 x 32 PixelLab pictures, closed and open (the silver and void ones were
// redrawn at 32 for the chapter chest). All are palette PNGs, and every tier
// has both.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  (int, int, int) header(String path) {
    final data =
        ByteData.sublistView(Uint8List.fromList(File(path).readAsBytesSync()));
    return (data.getUint32(16), data.getUint32(20), data.getUint8(25));
  }

  for (final (tier, size) in [
    ('wooden', 32),
    ('iron', 32),
    ('gold', 32),
    ('silver', 32),
    ('void', 32),
  ]) {
    for (final state in ['closed', 'open']) {
      test('the $tier chest, $state: $size x $size, a palette PNG', () {
        final (w, h, type) = header('assets/icons/chests/${tier}_$state.png');
        expect((w, h), (size, size));
        expect(type, 3);
      });
    }
  }
}
