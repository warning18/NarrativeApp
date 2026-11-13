// The heads of the story's people (UX_SHOTS=<folder>): each one's head in the
// scene vignette (its place on the journey screens), light and dark. Drawn
// only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/head_avatar.dart';
import 'package:narrative_data_app/widgets/scene_vignette.dart';

import 'support/fonts.dart';

const _people = <(String, String)>[
  ('keeper_weaponsmith_forge', 'Orrin Vell'),
  ('keeper_arcane_bazaar', 'Imra of the Smoke'),
  ('keeper_apothecary_row', 'Sister Ysolde'),
  ('keeper_arcane_academy', 'Magister Corvane'),
  ('keeper_ossuary_relics', 'Hask'),
  ('keeper_last_lantern', 'Wickwarden Tallis'),
  ('keeper_anchorage_chandlery', 'The Wreck-Wright'),
  ('keeper_black_market_docks', 'A Crow with no name'),
  ('old_harker', 'Old Harker'),
  ('sign_painter', 'The sign-painter'),
  ('joss_harrow', 'Joss Harrow'),
  ('wick_sweeper', 'Old Wick'),
  ('dorran_quill', 'Dorran Quill'),
  ('tamsin_brask', 'Tamsin Brask'),
];

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  test('every person with a head has the file', () {
    for (final (id, _) in _people) {
      if (id == 'tamsin_brask') continue; // no figure: keeps its letter
      expect(File(headAssetOf(id)).existsSync(), isTrue, reason: id);
    }
  });

  testWidgets('the people\'s heads', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 2400);
    addTearDown(tester.view.reset);
    for (final dark in [false, true]) {
      final key = GlobalKey();
      final scheme = AppPalette.stitchedInk
          .schemeFor(dark ? Brightness.dark : Brightness.light);
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(scheme),
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: scheme.surface,
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final (id, name) in _people)
                  SceneVignette(
                    heroName: 'Kaito',
                    prompt: 'What do you say to $name?',
                    faced: SceneFaced(id: id, name: name, role: 'role'),
                  ),
                Wrap(children: [
                  for (final (id, name) in _people)
                    HeadAvatar(id: id, name: name, size: 22),
                ]),
              ]),
            ),
          ),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late List<int> bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/heads-${dark ? 'dark' : 'light'}.png')
          .writeAsBytesSync(bytes);
    }
  });
}
