// QA guard: a picture under assets/ that fits 256 colours is stored as a
// palette PNG, not as RGBA (UX round 2, v1.783; `tool/png8.py`).
//
// The art is pixel art in a few flat tones, but the generators and editors
// save it as 32-bit RGBA, four bytes a pixel. A palette PNG holds the same
// pixels in about a fifth less. When this fails, run `python3 tool/png8.py`
// (needs Pillow) from the repository root and commit the pictures it rewrites.
//
// A picture is flagged when all three hold: its colour type is not 3
// (palette; IHDR byte 25), it is at least [_tinyBytes] (below that the header
// is most of the file and a palette is not smaller: `png8.py` leaves those
// alone), and it decodes to 256 colours or fewer. A picture with more colours
// (soft glows) may stay RGBA.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _tinyBytes = 1000;

/// IHDR colour type of a PNG (byte 25), or null when [bytes] is not a PNG.
int? pngColourType(Uint8List bytes) {
  const sig = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 26) return null;
  for (var i = 0; i < sig.length; i++) {
    if (bytes[i] != sig[i]) return null;
  }
  return bytes[25];
}

Future<int> colourCount(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba =
      data!.buffer.asUint32List(data.offsetInBytes, data.lengthInBytes ~/ 4);
  final seen = <int>{};
  for (final p in rgba) {
    seen.add(p);
    if (seen.length > 256) break;
  }
  frame.image.dispose();
  codec.dispose();
  return seen.length;
}

void main() {
  testWidgets('no picture that fits 256 colours is stored as RGBA', (t) async {
    final pngs = Directory('assets')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(pngs, isNotEmpty);

    final flagged = <String>[];
    await t.runAsync(() async {
      for (final f in pngs) {
        final bytes = f.readAsBytesSync();
        final type = pngColourType(bytes);
        if (type == null || type == 3 || bytes.length < _tinyBytes) continue;
        if (await colourCount(bytes) <= 256) {
          flagged.add('${f.path} (${bytes.length} bytes, colour type $type)');
        }
      }
    });
    expect(flagged, isEmpty,
        reason: 'These pictures fit 256 colours but are stored as RGBA. '
            'Run `python3 tool/png8.py` and commit the result:\n'
            '${flagged.join('\n')}');
  });
}
