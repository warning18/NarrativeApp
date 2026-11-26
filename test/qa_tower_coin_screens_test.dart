// QA guard (v2.10.2, the Tower's coin and marks-shop screens): on the phones
// that are hardest on a layout (320 x 568 French at 1.3x text, 360 x 740
// English at 1.3x, 412 x 860 at 1x) the coin chip, the table's Reroll and
// Banish (and the confirm), the stall, the marks screen's Perks tab, the
// door's perk slot and the end tally draw no overflow, and every control the
// player must press is whole on the screen: inside its width, and at least
// 40 px high to tap. Real fonts, the app's theme. UX's own test
// (ux_tower_coins_screens_test) holds what the buttons do; this one holds
// how they fit.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_marks_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

final _data = towerDataFromAssets();

TowerRun _table() =>
    towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: _data)
        .copyWith(
            floor: 5,
            coins: 20,
            status: TowerStatus.choosing,
            offer: const [
          TowerReward(TowerRewardKind.skill, id: 'second_wind'),
          TowerReward(TowerRewardKind.skill, id: 'shadow_step'),
          TowerReward(TowerRewardKind.skill, id: 'void_blast'),
        ]);

final _full = TowerProgress(
    marks: 214,
    bestFloor: 23,
    runs: 9,
    wins: 3,
    unlocked: {for (final u in towerUnlocks) u.id},
    perks: const {'purse', 'early_word', 'fourth_card'},
    worn: const ['purse']);

void main() {
  const configs = [
    (Size(320, 568), AppLanguage.fr, 1.3),
    (Size(360, 740), AppLanguage.en, 1.3),
    (Size(412, 860), AppLanguage.en, 1.0),
  ];

  testWidgets('the Tower\'s coin screens fit the small phones', (tester) async {
    await tester.runAsync(loadAppFonts);
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);

    Future<void> settle([int n = 10]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final (size, lang, scale) in configs) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} ${lang.name} '
          '${scale}x';
      usePhone(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      Future<ProviderContainer> open(Widget screen,
          {Map<String, Object> prefs = const {}}) async {
        SharedPreferences.setMockInitialValues(
            {'app_language': lang.name, 'tutorial_enabled': false, ...prefs});
        await tester.runAsync(() async {
          final p = await SharedPreferences.getInstance();
          await p.clear();
          for (final e in {
            'app_language': lang.name,
            'tutorial_enabled': false,
            ...prefs
          }.entries) {
            final v = e.value;
            if (v is bool) await p.setBool(e.key, v);
            if (v is String) await p.setString(e.key, v);
          }
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);
        await c.read(appLanguageProvider.notifier).setLanguage(lang);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
                key: UniqueKey(),
                theme: buildAppTheme(
                    c.read(appPaletteProvider).schemeFor(Brightness.light)),
                home: screen)));
        await settle();
        return c;
      }

      /// The page scrolled back to its top (a lazy list drops what it left).
      Future<void> toTop() async {
        final lists = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        if (lists.evaluate().isEmpty) return;
        for (var i = 0; i < 8; i++) {
          await tester.drag(lists.first, const Offset(0, 600));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      /// [key] is whole on the screen: inside the width, and, when it is a
      /// control ([tappable]), 40 px high at least. It is scrolled to first.
      Future<void> whole(String key, String where,
          {bool tappable = true}) async {
        final f = find.byKey(Key(key));
        final lists = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        for (var i = 0;
            i < 30 && f.evaluate().isEmpty && lists.evaluate().isNotEmpty;
            i++) {
          await tester.drag(lists.first, const Offset(0, -200));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(f, findsWidgets, reason: '$tag $where: no "$key"');
        await tester.ensureVisible(f.first);
        await tester.pump(const Duration(milliseconds: 200));
        final r = tester.getRect(f.first);
        expect(r.left, greaterThanOrEqualTo(-0.5),
            reason: '$tag $where: "$key" runs off the left');
        expect(r.right, lessThanOrEqualTo(size.width + 0.5),
            reason: '$tag $where: "$key" runs off the right');
        if (tappable) {
          expect(r.height, greaterThanOrEqualTo(40),
              reason: '$tag $where: "$key" is ${r.height} px high');
        }
      }

      // The table: chip, Reroll, Banish and its confirm.
      await open(const TowerFloorScreen(),
          prefs: {towerRunPrefsKey: jsonEncode(_table().toJson())});
      final level = find.byType(LevelUpScreen);
      if (level.evaluate().isNotEmpty) {
        Navigator.of(tester.element(level)).pop();
        await settle();
      }
      final take = find.text(lang == AppLanguage.fr ? 'Prendre' : 'Take');
      if (take.evaluate().isNotEmpty) {
        await tester.tap(take.first);
        await settle();
      }
      await whole('tower_coin_chip', 'the table', tappable: false);
      await whole('tower_reroll', 'the table');
      // Banish works on the card in hand: none is until one is tapped.
      await tester.tap(find.byKey(const Key('tower_card_0')));
      await settle();
      await whole('tower_banish', 'the table');
      await tester.tap(find.byKey(const Key('tower_banish')));
      await settle();
      await whole('tower_banish_yes', 'the banish confirm');
      await tester.tap(find.byKey(const Key('tower_banish_yes')));
      await settle();

      // The marks screen's Perks and trims tabs.
      await open(const TowerMarksScreen(),
          prefs: {towerMarksPrefsKey: jsonEncode(_full.toJson())});
      await whole('tower_marks_tab_1', 'the marks tabs');
      await tester.tap(find.byKey(const Key('tower_marks_tab_1')));
      await settle();
      for (final p in towerPerks) {
        await whole('tower_perk_${p.id}', 'the Perks tab');
      }
      await toTop();
      await whole('tower_marks_tab_2', 'the marks tabs');
      await tester.tap(find.byKey(const Key('tower_marks_tab_2')));
      await settle();
      await whole('tower_trim_ash', 'the trims tab');

      // The door's perk slot.
      await open(const TowerStartScreen(),
          prefs: {towerMarksPrefsKey: jsonEncode(_full.toJson())});
      await whole('tower_door_slot_0', 'the door');

      // The end tally, with coins left and a first-win bonus.
      final over = _table().copyWith(status: TowerStatus.dead, floor: 23);
      await open(TowerEndScreen(run: over, progress: _full, firstWinBonus: 20));
      await whole('tower_end_banked', 'the end tally', tappable: false);
      await whole('tower_end_first_win', 'the end tally', tappable: false);

      // The stall: a merchant's landing with coins in hand.
      TowerRun? stall;
      for (var seed = 1; seed < 400 && stall == null; seed++) {
        final run = towerStart(
            seed: seed,
            raceId: 'human',
            professionId: 'warrior',
            events: towerEventsLive,
            data: _data);
        final on =
            run.copyWith(floor: 10, health: 40, status: TowerStatus.climbing);
        final landing = towerPick(
            towerAfterFight(on, _data, won: true, healthLeft: 40), _data, null);
        if (towerStoreKindOf(landing) == TowerEventKind.merchant) {
          stall = landing.copyWith(coins: 30, health: 5);
        }
      }
      expect(stall, isNotNull, reason: 'no merchant landing in 400 seeds');
      await open(const TowerFloorScreen(),
          prefs: {towerRunPrefsKey: jsonEncode(stall!.toJson())});
      final lvl = find.byType(LevelUpScreen);
      if (lvl.evaluate().isNotEmpty) {
        Navigator.of(tester.element(lvl)).pop();
        await settle();
      }
      for (final id in const ['salve', 'potions', 'boon']) {
        await whole('tower_stall_buy_$id', 'the stall');
      }
    }
    expect(overflows, isEmpty, reason: 'overflows: ${overflows.join('\n')}');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
