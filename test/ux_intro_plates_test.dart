// The intro's four plates (v1.904, Art's Version A): the files are there as
// 180 x 320 palette PNGs and the intro draws plates, not the old code scenes.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/intro_art.dart';

void main() {
  test('the four plates are 180x320 palette PNGs', () {
    expect(introPlates.length, 4);
    for (final path in introPlates) {
      final bytes = File(path).readAsBytesSync();
      final h = ByteData.sublistView(bytes, 0, 26);
      expect([h.getUint32(16), h.getUint32(20)], [180, 320], reason: path);
      expect(h.getUint8(25), 3, reason: '$path must be PNG8 (palette)');
    }
  });
}
