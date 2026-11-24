// The main menu in ink, a still (UX_SHOTS=<folder>), picture first: the ink
// ground, the wide frame buttons, today's waving banner kept as it is. Two
// grounds behind the banner: bare, and with a pale glow so its dark cloth
// reads. 360 and 320 wide. Pictures only; nothing is built from this.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_images.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/wind_banner.dart';

import 'support/fonts.dart';

Widget _row(IconData icon, String title, String? sub) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkPaperPanel(
        padding: const EdgeInsets.fromLTRB(46, 14, 22, 12),
        child: Row(children: [
          Icon(icon, color: inkOnPaper),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 18,
                        color: inkOnPaper)),
                if (sub != null)
                  Text(sub,
                      style: const TextStyle(
                          fontFamily: InkFonts.system,
                          fontSize: 10,
                          color: inkSlate)),
              ],
            ),
          ),
        ]),
      ),
    );

Widget _menu({required bool glow}) => Scaffold(
      backgroundColor: inkBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                decoration: glow
                    ? const BoxDecoration(
                        gradient: RadialGradient(
                            radius: 0.62,
                            colors: [Color(0xFF39454A), Color(0x0005060A)]))
                    : null,
                child: const WindBanner(id: titleBannerId, scale: 1),
              ),
            ),
            const SizedBox(height: 14),
            const Text('The Grey Shroud',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 36,
                    height: 1,
                    color: inkPaper)),
            const SizedBox(height: 10),
            const Text(
                'A tale of dice, debts and a shroud that should not exist',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    color: inkGrey)),
            const SizedBox(height: 28),
            InkButton(
                label: 'New Game', primary: true, height: 52, onPressed: () {}),
            const SizedBox(height: 14),
            _row(Icons.folder_outlined, 'Load', 'No saved game yet'),
            _row(Icons.settings_outlined, 'Settings', null),
            _row(Icons.edit_note, 'Edit Mode',
                'Story editor, map, data and test tools'),
            _row(Icons.fort_outlined, 'The Tower', 'Thirty floors, no story.'),
            const SizedBox(height: 8),
            const Text('v1.1008.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: InkFonts.system, fontSize: 11, color: inkGrey)),
          ]),
        ),
      ),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('the main menu in ink, a still', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    await tester.runAsync(InkImages.preload);
    for (final width in [360.0, 320.0]) {
      for (final glow in [false, true]) {
        final key = GlobalKey();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(RepaintBoundary(
            key: key, child: MaterialApp(home: _menu(glow: glow))));
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/menu-ink-${glow ? 'b-glow' : 'a-bare'}-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
