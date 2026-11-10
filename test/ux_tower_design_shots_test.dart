// PROTOTYPE pictures of the Tower interface design (TOWER_LOOK=a|b, UX_SHOTS=<folder>); on the design branch only, not for merge.
// The Tower's screens on real data (UX_SHOTS=<folder>): the menu entry, the
// start screen (as it opens and with a pick), the marks and the end of a run
// (a death and a win), at 360 px in French and 412 px in English. Drawn only
// with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/main_menu_screen.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'dart:convert';
import 'package:narrative_data_app/screens/tower/tower_marks_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/pump.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart';

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
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final look = Platform.environment['TOWER_LOOK'] ?? 'none';
  towerLook = look == 'a' ? TowerLookOption.a : look == 'b' ? TowerLookOption.b : TowerLookOption.none;
  testWidgets('the Tower screens', (tester) async {
    await tester.runAsync(_loadFonts);
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

    Future<void> settle() async {
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    const run = TowerRun(
      seed: 1,
      raceId: 'human',
      professionId: 'warrior',
      floor: 17,
      health: 0,
      status: TowerStatus.dead,
    );
    for (final (lang, width, tag) in [
      (AppLanguage.fr, 360.0, 'fr360'),
      (AppLanguage.en, 412.0, 'en412'),
    ]) {
      Future<void> open(Widget screen,
          {Map<String, Object> prefs = const {}}) async {
        SharedPreferences.setMockInitialValues(
            {'app_language': lang.name, ...prefs});
        usePhone(tester, Size(width, 780));
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(appLanguageProvider.notifier).setLanguage(lang);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                key: UniqueKey(), // a screen pushed before is dropped
                theme: buildAppTheme(container
                    .read(appPaletteProvider)
                    .schemeFor(look == 'b' ? Brightness.dark : Brightness.light)),
                home: screen),
          ),
        ));
        await settle();
      }

      await open(const MainMenuScreen());
      await shot('1-menu-$tag');
      await open(const TowerStartScreen(), prefs: {
        'tower_marks_v1': '{"marks":12,"bestFloor":17,"runs":4,"wins":0}'
      });
      await shot('2-start-$tag');
      // Climb opens the main game's creation screen, the unbought callings
      // padlocked.
      await tester.tap(find.byKey(const Key('tower_climb')));
      await settle();
      await shot('3a-create-peoples-$tag');
      await tester.tap(find.byKey(const Key('choice_card_human')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('rp_next')));
      await settle();
      await shot('3b-create-callings-$tag');
      await tester.tap(find.byKey(const Key('choice_card_warrior')));
      await tester.pump(const Duration(milliseconds: 600));
      await shot('3c-create-picked-$tag');
      await open(const TowerMarksScreen(),
          prefs: {'tower_marks_v1': '{"marks":12,"unlocked":["flame_die"]}'});
      await shot('4-marks-$tag');
      Map<String, Object> saved(TowerRun r) =>
          {'tower_run_v1': jsonEncode(r.toJson())};
      Future<void> settleLong() async {
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // A floor that gained a level opens the Level Up first: drawn once,
      // then closed so the cards behind it show.
      var levelShot = false;
      Future<void> pastLevelUp() async {
        final screen = find.byType(LevelUpScreen);
        if (screen.evaluate().isEmpty) return;
        if (!levelShot) {
          levelShot = true;
          await tester.pump(const Duration(milliseconds: 600));
          await shot('12-levelup-$tag');
        }
        Navigator.of(tester.element(screen)).pop();
        await settleLong();
      }

      // The spoils sheet of a won floor, drawn then taken: the boon or
      // oath comes after it.
      Future<void> spoils(String? name) async {
        final take = find.byKey(const Key('loot_sheet_take'));
        if (take.evaluate().isEmpty) return;
        await tester.pump(const Duration(milliseconds: 600));
        if (name != null) await shot(name);
        await tester.tap(take);
        await settleLong();
      }

      final mid =
          run.copyWith(floor: 7, health: 31, status: TowerStatus.climbing);
      await open(const TowerFloorScreen(), prefs: saved(mid));
      await settleLong();
      await shot('7-floor-$tag');
      await open(const TowerFloorScreen(),
          prefs: saved(mid.copyWith(floor: 10, health: 40)));
      await settleLong();
      await shot('8-boss-$tag');
      // A warden floor: its foe wears marks, now one readable chip each.
      await open(const TowerFloorScreen(),
          prefs: saved(mid.copyWith(floor: 22, health: 40)));
      await settleLong();
      await shot('8b-affixes-$tag');
      // The cards of a won floor: the offer the engine draws for it.
      await open(const TowerFloorScreen(), prefs: saved(mid));
      await settleLong();
      final data = await tester.runAsync(() => ProviderScope.containerOf(
              tester.element(find.byType(TowerFloorScreen)))
          .read(towerDataProvider.future));
      final won = towerAfterFight(mid, data!, won: true, healthLeft: 22);
      await open(const TowerFloorScreen(), prefs: saved(won));
      await settleLong();
      await pastLevelUp();
      await spoils('13-spoils-floor7-$tag');
      // A boon floor: its spoils, then one of a skill, a die and a spell.
      final boonRun = towerAfterFight(mid.copyWith(floor: 5), data,
          won: true, healthLeft: 22);
      await open(const TowerFloorScreen(), prefs: saved(boonRun));
      await settleLong();
      await pastLevelUp();
      await spoils('14-spoils-boon-$tag');
      await shot('15-boon-$tag');
      await open(const TowerFloorScreen(), prefs: saved(won));
      await settleLong();
      await pastLevelUp();
      await spoils(null);
      await shot('9-cards-$tag');
      // The first floor won offers a clan's oath (Core's rule).
      final first =
          run.copyWith(floor: 1, health: 38, status: TowerStatus.climbing);
      final oathOffer = towerAfterFight(first, data, won: true, healthLeft: 30);
      await open(const TowerFloorScreen(), prefs: saved(oathOffer));
      await settleLong();
      await pastLevelUp();
      await spoils('16-spoils-floor1-$tag');
      // The card in hand is the oath.
      final oathAt =
          oathOffer.offer.indexWhere((r) => r.kind == TowerRewardKind.clanOath);
      await tester.tap(find.byKey(Key('tower_card_$oathAt')));
      await tester.pump(const Duration(milliseconds: 600));
      await shot('10-oath-$tag');
      // A run sworn to two clans, on its eighth floor.
      final sworn = mid.copyWith(floor: 8, health: 29, taken: {
        1: const TowerReward(TowerRewardKind.clanOath, id: 'dominion'),
        4: const TowerReward(TowerRewardKind.clanOath, id: 'mire'),
      });
      await open(const TowerFloorScreen(), prefs: saved(sworn));
      await settleLong();
      await pastLevelUp();
      await shot('11-sworn-$tag');
      await open(const TowerEndScreen(
          run: run,
          progress: TowerProgress(marks: 28, bestFloor: 17, runs: 5)));
      await shot('5-end-death-$tag');
      await open(TowerEndScreen(
          run: run.copyWith(floor: 30, status: TowerStatus.won, health: 40),
          progress:
              const TowerProgress(marks: 91, bestFloor: 30, runs: 6, wins: 1)));
      await shot('6-end-win-$tag');
    }
  }, skip: shots == null);
}
