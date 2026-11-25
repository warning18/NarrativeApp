// The Level Up screen's art (v2.10.19): the plate turns with the level, the
// hero stands in it, every card's numbers are the ones statPickPreviewOf
// works out (never typed in), a pick nothing reads in the Tower says so, an
// offer not picked keeps its colour, the Take button stays at the foot, and
// both versions of the stats area (bars, radar) draw.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/stat_pick_text.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/tower_level_up_session.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/widgets/level_up_art.dart';

void main() {
  test('the plate turns with the level, the same one when reopened', () {
    expect(levelUpPlateAsset(3), endsWith('plate_shrine.png'));
    expect(levelUpPlateAsset(4), endsWith('plate_anvil.png'));
    expect(levelUpPlateAsset(5), endsWith('plate_yard.png'));
    expect(levelUpPlateAsset(6), levelUpPlateAsset(3));
    expect(levelUpHeroAsset('mage'), endsWith('hero_mage.png'));
    expect(levelUpHeroAsset('ronin'), endsWith('hero_warrior.png'));
    expect(levelUpStatAsset('luck'), endsWith('stat_luck.png'));
    expect(levelUpValueText(-2), '−2');
    expect(levelUpValueText(7), '7');
  });

  for (final view in LevelUpStatsView.values) {
    testWidgets('the stats area draws as ${view.name}, the pick over it',
        (tester) async {
      const before = {
        'strength': 1,
        'dexterity': 10,
        'constitution': -2,
        'intelligence': 3,
        'wisdom': -1,
        'perception': 1,
        'luck': 2,
        'charisma': 0,
      };
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LevelUpStatsArea(
              view: view,
              before: before,
              after: Map.of(before)..['dexterity'] = 11,
              label: (k) => k.substring(0, 3).toUpperCase(),
            ),
          ),
        ),
      ));
      expect(
          find.byKey(Key(view == LevelUpStatsView.list
              ? 'stat_pick_list'
              : 'stat_pick_radar')),
          findsOneWidget);
      // A negative reads with a real minus sign, the pick as before -> after.
      expect(find.text('−2'), findsWidgets);
      expect(
          find.textContaining('10 → 11').evaluate().isNotEmpty ||
              find.textContaining('10→11').evaluate().isNotEmpty,
          isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'the Tower\'s Level Up: numbers from the preview, plainly no '
      'effect, offers not dimmed, Take at the foot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = towerDataFromAssets();
    final paths = trainingPathsFrom(jsonDecode(
            File('assets/gamedata/training_paths.json').readAsStringSync())
        as Map<String, dynamic>);
    final run = towerAfterFight(
        towerStart(
            seed: 5, raceId: 'human', professionId: 'warrior', data: data),
        data,
        won: true,
        healthLeft: 30);
    final offer = towerStatPickOffer(run, data);
    final hero = towerSessionOf(run, data);
    final levelUp = TowerLevelUpSession(run, data);
    await tester.pumpWidget(ProviderScope(
      overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
      child: MaterialApp(
        home: levelUp.wrap(
            const LevelUpScreen(doneLabelKey: 'tower_continue', tower: true)),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byKey(const Key('level_up_plate')), findsOneWidget);
    expect(find.byKey(const Key('level_up_hero')), findsOneWidget);
    expect(find.byKey(const Key('level_up_ribbon')), findsOneWidget);
    // The Take button is at the foot from the start, off until a pick.
    final take = find.byKey(const Key('stat_pick_take'));
    expect(take, findsOneWidget);
    expect(tester.widget<FilledButton>(take).onPressed, isNull);
    for (var i = 0; i < offer.length; i++) {
      final card = find.byKey(Key('stat_pick_offer_$i'));
      expect(card, findsOneWidget);
      // Never dimmed, picked or not.
      expect(find.descendant(of: card, matching: find.byType(Opacity)),
          findsNothing);
      final preview = statPickPreviewOf(hero, offer[i].gains, tower: true);
      if (preview.rows.isNotEmpty) {
        for (final r in preview.rows) {
          expect(
              find.descendant(
                  of: card,
                  matching: find.byKey(Key('stat_pick_row_${r.labelKey}'))),
              findsOneWidget,
              reason: '${offer[i].gains} ${r.labelKey}');
        }
      } else if (preview.noTowerEffect) {
        expect(
            find.descendant(
                of: card, matching: find.text('No effect in the Tower')),
            findsOneWidget);
      }
    }
    await tester.tap(find.byKey(const Key('stat_pick_offer_0')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<FilledButton>(take).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
