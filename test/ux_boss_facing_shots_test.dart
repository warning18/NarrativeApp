// PICTURES (UX_SHOTS=<folder>): a warden fight (Brine Jack, floor 5) with the
// boss facing the viewer and the hero seen from behind, in stand-in frames.
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
import 'package:narrative_data_app/screens/fight_screen.dart'
    show towerBossFacingMock;
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5, int? floor, int events = 0, double width = 412}) async {
  await tester.runAsync(loadAppFonts);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final data = towerDataFromAssets();
  var run = towerStart(
      seed: seed, raceId: 'human', professionId: 'warrior', data: data);
  if (floor != null) run = run.copyWith(floor: floor, events: events, crest: 0);
  SharedPreferences.setMockInitialValues({
    towerRunPrefsKey: jsonEncode(run.toJson()),
    'tutorial_enabled': false,
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 860);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ProviderScope(child: MyApp())));
  Future<void> settle([int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapKey(String k) async {
    final f = find.byKey(Key(k));
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await settle(10);
  }

  await settle(12);
  final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(
      () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await settle(4);
  await tapKey('menu_tower');
  await tapKey('tower_continue');
  await tapKey('tower_fight');
  await settle(12);
  final enter = find.text('Enter Battle');
  if (enter.evaluate().isNotEmpty) {
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(14);
  }
  return c;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });
  tearDown(() {
    towerBossFacingMock.value = null;
  });

  // PICTURE ONLY: a warden fight (Brine Jack, floor 5) with the boss facing the
  // viewer and the hero seen from behind, in stand-in frames (the High
  // Warden's south and a coated figure's north) until Art's own arrive.
  for (final w in [412.0, 360.0]) {
    testWidgets('boss facing the player at ${w.toInt()}', skip: shots == null,
        (tester) async {
      final boss = await tester.runAsync(() async => decodeImageFromList(File(
              'art/pixellab-enemies2/raw/inquisition_high_warden/Idle/rotations/south.png')
          .readAsBytesSync()));
      final hero = await tester.runAsync(() async => decodeImageFromList(
          File('art/pixellab-pilots/round2/raw/renn_a/Idle/rotations/north.png')
              .readAsBytesSync()));
      towerBossFacingMock.value = (boss: boss!, hero: hero!);
      final key = GlobalKey();
      await _bootFight(tester, key, floor: 5, width: w);
      expect(tester.takeException(), isNull);
      Directory(shots!).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/boss-south-${w.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
