// Pictures of the real intro (lib/screens/intro_screen.dart), one per beat,
// drawn only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_intro_build_shots_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/intro_screen.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(
          ByteData.view(File('assets/fonts/$f').readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the intro pictures are drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the intro, beat by beat', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(420, 746);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RepaintBoundary(key: key, child: const IntroScreen()),
      ),
    ));
    var at = 0.0;
    for (final (name, second) in const [
      ('1', 1.5),
      ('2', 3.5),
      ('3', 5.5),
      ('4', 7.5),
      ('5', 9.5),
      ('6', 11.4),
      ('7', 13.0),
      ('8', 14.3),
    ]) {
      while (at < second) {
        // The banner's pixels decode off the frame clock.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
        at += 0.1;
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/intro-build-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
