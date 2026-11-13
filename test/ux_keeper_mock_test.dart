// A mock-up, not the game (UX_SHOTS=<folder>): the shop's keeper strip today
// (the shop's sign) beside the strip with the keeper standing at its left, for
// four shops, light and dark. The figures are stand-ins cut from the
// inventory's workbench frames (art/pixellab-npc-inventory).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'support/fonts.dart';

const _keepers = [
  (
    'weaponsmith_forge',
    'Orrin Vell',
    'k36',
    'Steel for honest coin. Every blade here was asked for before it was forged.'
  ),
  (
    'apothecary_row',
    'Sister Ysolde',
    'k50',
    'Fever-bark from the Courts, boiled honest. Tell me what hurts, not what you want.'
  ),
  (
    'anchorage_chandlery',
    'The Wreck-Wright',
    'k38',
    'What the sea gave back, made fit to use again. The Admiralty counts every sale.'
  ),
  (
    'wayfarer_caravan',
    'Old Pell',
    'k41',
    'Bought off the last road, sold on this one. Six things today; tomorrow the mules decide.'
  ),
];

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('keeper mock', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    for (final dark in [false, true]) {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget text(BuildContext c, String name, String line) => Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('“$line”',
                  style: Theme.of(c)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
              Text(name.toUpperCase(),
                  style: Theme.of(c).textTheme.labelSmall?.copyWith(
                      color: Theme.of(c).colorScheme.primary,
                      letterSpacing: 0.8)),
            ]),
          );
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: buildAppTheme(
              dark ? const ColorScheme.dark() : const ColorScheme.light()),
          home: Scaffold(
            body: Builder(builder: (c) {
              return ListView(padding: const EdgeInsets.all(16), children: [
                for (final (id, name, fig, line) in _keepers) ...[
                  Text('TODAY', style: Theme.of(c).textTheme.labelSmall),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShopPixelIcon(id, size: 48),
                          const SizedBox(width: 10),
                          text(c, name, line),
                        ]),
                  ),
                  Text('PROPOSED', style: Theme.of(c).textTheme.labelSmall),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 4),
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Theme.of(c).dividerColor)),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 74,
                            height: 102,
                            child: Image.file(File('/tmp/pm/$fig.png'),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none),
                          ),
                          const SizedBox(width: 12),
                          text(c, name, line),
                        ]),
                  ),
                ],
              ]);
            }),
          ),
        ),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      late List<int> bytes;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/keeper-mock-${dark ? 'dark' : 'light'}.png')
          .writeAsBytesSync(bytes);
    }
  });
}
