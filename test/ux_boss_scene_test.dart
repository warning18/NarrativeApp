// The boss scene (Art's south frames for the bosses and wardens, north frames
// for the heroes): every boss and warden of the Tower has its frame and every
// hero its own, files declared in assets, the scene shows on a boss floor and
// not on an ordinary one. With UX_SHOTS=<folder> it saves a real floor-20 fight
// at 412 and 360 wide.
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
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/fight/fight_boss_scene.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart'
    show heroWalkName;

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

  test('every boss and warden has its south frame, every hero its north', () {
    final ids = {
      ...towerBosses.values,
      for (final pool in towerWardens.values) ...pool,
    };
    expect(ids.length, 20);
    for (final id in ids) {
      expect(bossSouthAsset(id), isNotNull, reason: id);
      expect(File(bossSouthAsset(id)!).existsSync(), isTrue, reason: id);
    }
    // No frame listed for a foe the Tower never makes a boss.
    expect(bossSouthIds.difference(ids), isEmpty);
    for (final name in heroNorthNames) {
      expect(File(heroNorthAsset(name)!).existsSync(), isTrue, reason: name);
    }
    // Every people and calling wears a figure that has a north frame.
    for (final race in ['human', 'dwarf', 'orc', 'elf', 'voidkin']) {
      for (final job in ['warrior', 'mage', 'rogue', 'cleric', 'ranger']) {
        expect(heroNorthAsset(heroWalkName(race, job)), isNotNull,
            reason: '$race $job');
      }
    }
    expect(bossSouthAsset('harbor_rat'), isNull);
  });

  for (final (floor, w, scene) in [
    (1, 412.0, false),
    (20, 412.0, true),
    (20, 360.0, true),
    (5, 412.0, true),
  ]) {
    testWidgets('floor $floor at ${w.toInt()}: the boss scene is $scene',
        (tester) async {
      final key = GlobalKey();
      await _bootFight(tester, key, floor: floor, width: w);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('boss_scene_foe')),
          scene ? findsOneWidget : findsNothing);
      expect(find.byKey(const Key('boss_scene_hero')),
          scene ? findsOneWidget : findsNothing);
      if (shots == null || floor == 5) return;
      Directory(shots).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/boss-scene-floor$floor-${w.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
