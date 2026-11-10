// The inventory die tile (1.902): d4/d6/d8/d12/d20 carry a bone 3D body at
// 40 and 44 px; d10 has none and keeps its flat tile.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/inventory_parts.dart';

void main() {
  const shapes = ['d4', 'd6', 'd8', 'd12', 'd20'];

  test('every bone body exists at 40 and 44 px as a palette PNG', () {
    for (final s in shapes) {
      for (final px in [40, 44]) {
        final f = File('assets/visuals/dice/die_${s}_bone_$px.png');
        expect(f.existsSync(), isTrue, reason: f.path);
        final h = ByteData.sublistView(f.readAsBytesSync(), 0, 26);
        expect([h.getUint32(16), h.getUint32(20)], [px, px], reason: f.path);
        expect(h.getUint8(25), 3, reason: '${f.path} must be PNG8 (palette)');
      }
    }
  });

  testWidgets('bodies for 4/6/8/12/20 faces, none for d10 or small tiles',
      (tester) async {
    for (final n in [4, 6, 8, 12, 20]) {
      expect(InventoryDieTile.boneBody(n, 44), isNotNull, reason: 'd$n');
    }
    expect(InventoryDieTile.boneBody(10, 44), isNull);
  });
}
