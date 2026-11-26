// PICTURES (UX_SHOTS=<folder>, UX_VARIANT=<name>): the real Tower fight at 412
// wide, floor 1 (band 1), as it is built: the floor's door, the pre-fight
// screen and the fight with its snowy panels and its dice board. The plates in
// assets/visuals/tower_ink/ are swapped by the caller (tool script) for each
// version of Art's backgrounds.
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
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final variant = Platform.environment['UX_VARIANT'] ?? 'today';
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  testWidgets('band 1 fight, $variant', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
    final data = towerDataFromAssets();
    final run = towerStart(
      seed: 5,
      raceId: 'human',
      professionId: 'warrior',
      data: data,
    );
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const ProviderScope(child: MyApp()),
      ),
    );
    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shoot(String name) async {
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(shots!).createSync(recursive: true);
        File('$shots/$name-$variant.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    Future<void> tapKey(String k) async {
      final f = find.byKey(Key(k));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await settle(10);
    }

    await settle(12);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await tester.runAsync(
      () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en),
    );
    await settle(4);
    await tapKey('menu_tower');
    await tapKey('tower_continue');
    await shoot('1-floor');
    await tapKey('tower_fight');
    await settle(12);
    await shoot('2-prefight');
    final enter = find.text('Enter Battle');
    if (enter.evaluate().isNotEmpty) {
      await tester.ensureVisible(enter);
      await tester.pump();
      await tester.tap(enter);
      await settle(14);
    }
    await shoot('3-fight');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull);
  });
}
