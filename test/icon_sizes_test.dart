// The icons are stored at the size they are drawn on, 16x16 (the skills' gems
// 32x32), and enlarged by PixelIcon with no smoothing. At 128x128 each took 64
// KB of decoded memory for 256 pixels of art and the app shipped them eight
// times larger than needed (v1.767). This guard keeps a big picture from
// coming back into assets/icons.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every icon is at most 32x32', () {
    final tooBig = <String>[];
    var count = 0;
    for (final f in Directory('assets/icons').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.png')) continue;
      count++;
      final header = ByteData.sublistView(
          Uint8List.fromList(f.readAsBytesSync().sublist(0, 24)));
      final w = header.getUint32(16);
      final h = header.getUint32(20);
      if (w > 32 || h > 32) tooBig.add('${f.path} ${w}x$h');
    }
    expect(count, greaterThan(300));
    expect(tooBig, isEmpty,
        reason: 'store an icon at its own size, not enlarged: $tooBig');
  });
}
