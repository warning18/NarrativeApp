// PICTURES ONLY (UX_SHOTS=<folder>): the user's "shop a bit bigger or the
// character smaller when combined": three shops (a 48 px keeper, two 64 px
// keepers) at 360 wide in today's size, (a) the stall 1.25x and (b) the keeper
// 0.8x about its feet.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/shop_layers.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('shop sizes', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    const w = 328.0; // a 360 screen less the 16 px gutters
    const ids = [
      'weaponsmith_forge',
      'blind_beggar_stall',
      'shieldwrights_hall'
    ];
    const rows = [
      ('Today', 1.0, 1.0),
      ('(a) stall x1.25', 1.25, 1.0),
      ('(b) keeper x0.8', 1.0, 0.8),
    ];
    final key = GlobalKey();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(3 * w + 3 * 12 + 24 + 12, 3 * 200.0 + 3 * 60);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: inkDeep,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: inkDeep,
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, ss, ks) in rows) ...[
                      Text(label,
                          style: const TextStyle(
                              fontFamily: InkFonts.display,
                              fontSize: 16,
                              color: inkPaper)),
                      const SizedBox(height: 6),
                      Row(children: [
                        for (final id in ids) ...[
                          SizedBox(
                              width: w,
                              child: ShopLayers(id,
                                  stallScale: ss, keeperScale: ks)),
                          const SizedBox(width: 12),
                        ],
                      ]),
                      const SizedBox(height: 14),
                    ],
                  ]),
            ),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await r.toImage(pixelRatio: 1.5);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/shop-sizes-360.png')
          .writeAsBytesSync(b!.buffer.asUint8List());
    });
  });
}
