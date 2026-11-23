// The Tower's dice mid-roll and at rest, before and after (UX_SHOTS=<folder>,
// UX_TAG=before|after): each die at the size a fight's board gives it, then
// the 48 px identity tile of the "Your dice" panel. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/root/fl/sdk/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

List<DieCubeFace> _faces(int n) => [
      for (var i = 0; i < n; i++)
        DieCubeFace(
          glyph: Text('${i + 1}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          color: FaceKind.values[i % 6].color,
        )
    ];

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'after';

  testWidgets('the dice', skip: shots == null, (tester) async {
    await tester.runAsync(_loadFonts);
    // The dice of a Tower run: the starter, the three unlocks, and a d4, a d10.
    const dice = [
      ('starter_die', 6),
      ('flame_die', 8),
      ('tide_die', 8),
      ('tearglass_die', 12),
      ('void_die', 4),
      ('storm_die', 10),
    ];
    final key = GlobalKey();
    Future<void> shot(String name) async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late Uint8List bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name.png').writeAsBytesSync(bytes);
    }

    //SLOWFLAG
    double board(int n) =>
        switch (n) { 4 => 60, 6 => 60, 8 => 70, 10 => 74, 12 => 80, _ => 87 };
    Widget die(String id, int n, double size, {double? roll}) {
      final animation =
          roll == null ? null : AlwaysStoppedAnimation<double>(roll);
      return SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Center(
          child: Die3D(
            faces: _faces(6),
            facets: n == 6 ? null : _faces(n),
            accent: dieSkinOf(id).edge,
            size: size,
            shape: dieShapeOf(n),
            skin: dieSkinOf(id),
            roll: animation,
            rolling: roll != null,
          ),
        ),
      );
    }

    Widget tile(String id, int n) => Padding(
          padding: const EdgeInsets.all(6),
          child: PolyDie(
              shape: dieShapeOf(n),
              size: 48,
              skin: dieSkinOf(id),
              dieId: id,
              still: true,
              glowing: false),
        );

    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        home: Scaffold(
          backgroundColor: const Color(0xFF1B1A22),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              for (final (label, roll) in [
                ('mid-roll', 0.35),
                ('at rest', null)
              ])
                Row(children: [
                  SizedBox(
                      width: 56,
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11))),
                  for (final (id, n) in dice) die(id, n, board(n), roll: roll),
                ]),
              Row(children: [
                const SizedBox(
                    width: 56,
                    child: Text('tiles 48',
                        style: TextStyle(color: Colors.white70, fontSize: 11))),
                for (final (id, n) in dice) tile(id, n),
              ]),
              Row(children: [
                const SizedBox(
                    width: 56,
                    child: Text('solid 48',
                        style: TextStyle(color: Colors.white70, fontSize: 11))),
                for (final (id, n) in dice) die(id, n, 48),
              ]),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await shot('dice-$tag');
  });
}
