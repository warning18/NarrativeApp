// The nameplate with a long foe name, its group emblem, two marks and a boss
// rank, at 320 and 360 wide, EN and FR (UX_SHOTS=<folder>). Pictures only.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/game_icons.dart';
import 'package:narrative_data_app/widgets/enemy_groups.dart';
import 'package:narrative_data_app/widgets/fight_block.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('long names with marks', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    const names = [
      (
        'Cassian Oriel, Regent of the Lantern',
        'Cassian Oriel, Régent de la Lanterne'
      ),
      ('High Lantern-Bearer Orsolya Keld', 'Haute Porte-Lanterne Orsolya Keld'),
      ('Harbour Rat', 'Rat du port'),
    ];
    for (final w in [320.0, 360.0]) {
      final slot = (w - 24 - 8) / 2 + 4;
      final key = GlobalKey();
      tester.view.physicalSize = Size(w, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget block(String n, int i) => SizedBox(
          width: slot,
          height: 86,
          child: FightBlock(
            name: n,
            plateColor: enemyGroups['dominion']!.color,
            group: enemyGroups['dominion'],
            rank: i == 0 ? FightRank.boss : FightRank.normal,
            marks: [
              FightMark(
                  icon: elementIcon('Light'),
                  text: '×3',
                  weak: true,
                  lit: i == 1),
              FightMark(icon: elementIcon('Fire'), text: '×3', weak: true),
              if (i != 2)
                FightMark(icon: elementIcon('Ice'), text: '×½', weak: false),
            ],
            head: const SizedBox(),
            bar: const SizedBox(height: 10),
          ));
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light)),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                for (var fr = 0; fr < 2; fr++)
                  for (var i = 0; i < names.length; i++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child:
                                block(fr == 0 ? names[i].$1 : names[i].$2, i))),
              ]),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/marks-${w.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
