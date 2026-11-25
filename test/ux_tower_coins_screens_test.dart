// Tower coins on their screens (v2.10.1): the chip, Reroll and Banish on the
// card table, the marks screen's Perks tab, the door's perk slots and the end
// tally. Pictures with UX_SHOTS=<folder> (412 EN, 360 FR).
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
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_marks_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

final _data = towerDataFromAssets();

TowerRun _table({int coins = 20, int heat = 0}) => towerStart(
            seed: 5,
            raceId: 'human',
            professionId: 'warrior',
            data: _data,
            heat: heat)
        .copyWith(
            floor: 5,
            coins: coins,
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
    perks: const {'purse', 'early_word'},
    worn: const ['purse']);

String _prog(TowerProgress p) => jsonEncode(p.toJson());

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// The Level Up a cleared floor owes, closed (the table is under it).
Future<void> _noLevelUp(WidgetTester t) async {
  final level = find.byType(LevelUpScreen);
  if (level.evaluate().isNotEmpty) {
    Navigator.of(t.element(level)).pop();
    await _settle(t);
  }
}

Future<ProviderContainer> _open(WidgetTester t, Widget screen,
    {Map<String, Object> prefs = const {},
    Size size = const Size(400, 2400)}) async {
  SharedPreferences.setMockInitialValues(prefs);
  usePhone(t, size);
  final c = ProviderContainer();
  addTearDown(c.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
      container: c, child: MaterialApp(home: screen)));
  await _settle(t);
  return c;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('the table: coin chip, Reroll and Banish spend coins', (t) async {
    final c = await _open(t, const TowerFloorScreen(),
        prefs: {towerRunPrefsKey: jsonEncode(_table().toJson())});
    await _noLevelUp(t);
    // The spoils sheet first, then the cards.
    final take = find.text('Take');
    if (take.evaluate().isNotEmpty) {
      await t.tap(take.first);
      await _settle(t);
    }
    await _noLevelUp(t);
    expect(find.byKey(const Key('tower_coin_chip')), findsOneWidget);
    expect(find.byKey(const Key('tower_reroll')), findsOneWidget);
    await t.tap(find.byKey(const Key('tower_reroll')));
    await _settle(t);
    expect(c.read(towerProvider).value!.run!.coins, lessThan(20));
    final after = c.read(towerProvider).value!.run!.coins;
    await t.tap(find.byKey(const Key('tower_banish')));
    await _settle(t);
    await t.tap(find.byKey(const Key('tower_banish_yes')));
    await _settle(t);
    expect(c.read(towerProvider).value!.run!.coins, lessThan(after));
    expect(c.read(towerProvider).value!.run!.banished, isNotEmpty);
  });

  testWidgets('the marks screen: Perks tab buys and wears', (t) async {
    final c = await _open(t, const TowerMarksScreen(),
        prefs: {towerMarksPrefsKey: _prog(_full)});
    expect(find.byKey(const Key('tower_tree_full')), findsOneWidget);
    await t.tap(find.byKey(const Key('tower_marks_tab_1')));
    await _settle(t);
    expect(find.text('Worn'), findsOneWidget);
    await t.tap(find.byKey(const Key('tower_perk_early_word')));
    await _settle(t);
    expect(c.read(towerProvider).value!.progress.worn,
        isNot(equals(const ['purse'])));
    await t.tap(find.byKey(const Key('tower_marks_tab_2')));
    await _settle(t);
    expect(find.byKey(const Key('tower_trim_ash')), findsOneWidget);
  });

  testWidgets('the door: perk slots appear with an owned perk', (t) async {
    await _open(t, const TowerStartScreen(),
        prefs: {towerMarksPrefsKey: _prog(const TowerProgress())});
    expect(find.byKey(const Key('tower_door_slot_0')), findsNothing);
    await _open(t, const TowerStartScreen(),
        prefs: {towerMarksPrefsKey: _prog(_full)});
    expect(find.byKey(const Key('tower_door_slot_0')), findsOneWidget);
    expect(find.byKey(const Key('tower_door_slot_1')), findsNothing);
  });

  testWidgets('the end tally', (t) async {
    final run = _table().copyWith(status: TowerStatus.dead, floor: 23);
    await _open(
        t, TowerEndScreen(run: run, progress: _full, firstWinBonus: 20));
    expect(find.byKey(const Key('tower_end_banked')), findsOneWidget);
    expect(find.byKey(const Key('tower_end_first_win')), findsOneWidget);
    expect(find.textContaining('Coins left: 20'), findsOneWidget);
  });

  Future<void> shot(WidgetTester t, String name, double w, Widget screen,
      {Map<String, Object> prefs = const {},
      double h = 900,
      AppLanguage lang = AppLanguage.en,
      Future<void> Function()? act}) async {
    SharedPreferences.setMockInitialValues(
        {...prefs, 'app_language': lang.name});
    final key = GlobalKey();
    t.view.physicalSize = Size(w, h);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: key, child: ProviderScope(child: MaterialApp(home: screen))));
    await _settle(t);
    await act?.call();
    expect(t.takeException(), isNull, reason: name);
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await r.toImage(pixelRatio: 2);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
  }

  testWidgets('Tower coins pictures', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (c) async => 1);
    for (final (w, lang, l) in [
      (412.0, AppLanguage.en, 'en'),
      (360.0, AppLanguage.fr, 'fr')
    ]) {
      final n = w.toInt();
      await shot(t, 'table-$n-$l', w, const TowerFloorScreen(),
          prefs: {towerRunPrefsKey: jsonEncode(_table(coins: 12).toJson())},
          h: 1300,
          lang: lang, act: () async {
        await _noLevelUp(t);
        final take = find.text(lang == AppLanguage.en ? 'Take' : 'Prendre');
        if (take.evaluate().isNotEmpty) {
          await t.tap(take.first);
          await _settle(t);
        }
        await _noLevelUp(t);
      });
      await shot(t, 'perks-$n-$l', w, const TowerMarksScreen(),
          prefs: {towerMarksPrefsKey: _prog(_full)},
          h: 1100,
          lang: lang, act: () async {
        await t.tap(find.byKey(const Key('tower_marks_tab_1')));
        await _settle(t);
      });
      await shot(t, 'door-$n-$l', w, const TowerStartScreen(),
          prefs: {towerMarksPrefsKey: _prog(_full.copyWith(heatWon: 2))},
          h: 1500,
          lang: lang);
      await shot(
          t,
          'end-$n-$l',
          w,
          TowerEndScreen(
              run: _table(coins: 9, heat: 3)
                  .copyWith(status: TowerStatus.dead, floor: 23),
              progress: _full,
              firstWinBonus: 20),
          h: 1300,
          lang: lang);
    }
  });
}
