// Pictures only (UX_SHOTS=<folder>): the Tower's cards as they are today, the
// real app: floor 5 won (a boon floor: a skill, a die and a spell), the
// spoils taken, then the offer. The shot the part-4 set missed.
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
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  for (final width in [360.0, 320.0]) {
    testWidgets('the Tower cards today $width', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      Directory(shots!).createSync(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      final data = towerDataFromAssets();
      final start = towerStart(
          seed: 5, raceId: 'human', professionId: 'warrior', data: data);
      final at = start.copyWith(floor: 5);
      final offer = towerOfferFor(
        seed: at.seed,
        floor: 5,
        hero: towerHeroView(at, towerHeroOf(at, data)),
        oaths: at.oathsLeft,
        items: data.items,
        dice: data.dice,
        skills: data.skills,
        spells: data.spells,
      );
      expect(offer.length, greaterThanOrEqualTo(2),
          reason: 'floor 5 is a boon floor');
      var run = at.copyWith(status: TowerStatus.choosing, offer: offer);
      // The level-up picks are taken, so the spoils and the cards come next.
      while (towerPendingPicks(run) > 0) {
        final picks =
            towerStatPickOffer(run, data, hero: towerHeroOf(run, data));
        if (picks.isEmpty) break;
        run = towerTakeStatPick(run, data, 0, offer: picks);
      }
      SharedPreferences.setMockInitialValues({
        towerRunPrefsKey: jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 780);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
          key: key, child: const ProviderScope(child: MyApp())));

      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> shoot(String name) async {
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$name.png')
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

      await settle(10);
      await tapKey('menu_tower');
      await tapKey('tower_continue');
      await shoot('today-spoils-${width.toInt()}');
      await tapKey('loot_sheet_take');
      expect(find.byKey(const Key('tower_card_0')), findsOneWidget,
          reason: 'the offer is on screen');
      await shoot('today-cards-${width.toInt()}');
      await tester.tap(find.byKey(const Key('tower_card_2')));
      await settle(6);
      await shoot('today-cards-third-held-${width.toInt()}');
    });
  }
}
