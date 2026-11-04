// The three sea beast sprites (WebP since v1.720): each loads, is 840 px wide,
// and keeps its soft halo (a pixel that is neither clear nor solid). A
// palette-quantized PNG flattens that halo into a hard-edged ellipse, so this
// is the guard against going back to one.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/sea_battlefield.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final beast in TopBeast.values) {
    test('${beast.name}: loads whole and keeps its soft edge', () async {
      expect(beast.asset, endsWith('.webp'));
      final bytes = File(beast.asset).readAsBytesSync();
      final image = await tester(bytes);
      expect(image.width, 840);
      final data = (await image.toByteData())!;
      var soft = 0;
      for (var i = 3; i < data.lengthInBytes; i += 4) {
        final a = data.getUint8(i);
        if (a > 0 && a < 255) soft++;
      }
      expect(soft, greaterThan(2000), reason: 'the halo must stay soft');
    });
  }
}

Future<ui.Image> tester(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  return (await codec.getNextFrame()).image;
}
