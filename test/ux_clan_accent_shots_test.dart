// Pictures only (UX_SHOTS=<folder>): the real app at 360 (home menu, a Tower
// floor with the tarot pick, a Tower fight) in today's red, with the rects of
// the elements the clan accent would take (buttons, ribbons: "fill"; the held
// card's frame, seals: "line"). tool/gen_clan_accent_sheets.py recolours those
// and keeps every other red (damage, danger, health) as drawn.
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
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/ink/tower_menu_button.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  for (final scene in ['home', 'floor', 'fight']) {
    testWidgets('clan accent base: $scene', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      final data = towerDataFromAssets();
      var run = towerStart(
          seed: 5, raceId: 'human', professionId: 'warrior', data: data);
      if (scene == 'floor') {
        final at = run.copyWith(floor: 5);
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
        run = at.copyWith(status: TowerStatus.choosing, offer: offer);
        while (towerPendingPicks(run) > 0) {
          final picks =
              towerStatPickOffer(run, data, hero: towerHeroOf(run, data));
          if (picks.isEmpty) break;
          run = towerTakeStatPick(run, data, 0, offer: picks);
        }
      }
      SharedPreferences.setMockInitialValues({
        towerRunPrefsKey: jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 780);
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

      Future<void> tapKey(String k) async {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first);
        await settle(10);
      }

      await settle(12);
      if (scene == 'floor') {
        await tapKey('menu_tower');
        await tapKey('tower_continue');
        await tapKey('loot_sheet_take');
        await settle(18);
        await tester.tap(find.byKey(const Key('tower_card_1')));
        await settle(6);
      } else if (scene == 'fight') {
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
      }
      expect(tester.takeException(), isNull);
      final rects = <String, List<List<double>>>{'fill': [], 'line': []};
      void add(String group, Finder f) {
        for (final e in f.evaluate()) {
          final box = e.renderObject as RenderBox?;
          if (box == null || !box.hasSize || !box.attached) continue;
          final o = box.localToGlobal(Offset.zero);
          rects[group]!
              .add([o.dx, o.dy, o.dx + box.size.width, o.dy + box.size.height]);
        }
      }

      add('fill', find.byType(InkButton));
      add('fill', find.byType(InkTab));
      add('fill', find.byType(TowerMenuButton));
      add('line', find.byType(TowerTarotCard));
      Directory(shots!).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/base-$scene.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        File('$shots/base-$scene.json').writeAsStringSync(jsonEncode(rects));
      });
    });
  }
}
