// Rules 5's early floors say it on the floor screen: a red "Ambush: foes strike
// first" tag under the foes (v2.10.46); later floors do not. With
// UX_SHOTS=<folder> it also saves a picture.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final shotKey = GlobalKey();
  final data = towerDataFromAssets();
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  Future<void> boot(
      WidgetTester tester, TowerRun run, double w, String lang) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'app_language': lang,
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(w, 860);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
            key: shotKey,
            child: const MaterialApp(
                debugShowCheckedModeBanner: false, home: TowerFloorScreen()))));
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  TowerRun rules5(int floor) => towerStart(
          seed: 5,
          raceId: 'human',
          professionId: 'warrior',
          rules: 5,
          data: data)
      .copyWith(floor: floor);

  for (final (w, lang, text) in [
    (412.0, 'en', 'Ambush: foes strike first'),
    (360.0, 'fr', 'Embuscade : les ennemis frappent d’abord'),
  ]) {
    testWidgets('floor 2 of rules 5 wears the Ambush tag ($lang $w)',
        (tester) async {
      await boot(tester, rules5(2), w, lang);
      expect(find.text(text), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (shots != null) {
        await tester.runAsync(() async {
          final b = shotKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/ambush-tag-$lang-${w.toInt()}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }

  testWidgets('a later floor does not', (tester) async {
    await boot(tester, rules5(9), 412, 'en');
    expect(find.text('Ambush: foes strike first'), findsNothing);
  });
}
