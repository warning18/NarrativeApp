// The Tower's level-up, the main game's way (v1.857, the user's call): each
// level gained puts the main game's stat pick on the table (three offers,
// one rarity, drawn from the run's seed); the player takes one; the run
// keeps the index and the hero replays it; the floor's cards come after
// (a pick still waiting there goes to the calling); an old save keeps the
// points its levels gave; the main game's Level Up screen takes the picks
// under the Tower hero's own session, the story save untouched.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/providers/tower_level_up_session.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';

void main() {
  final data = towerDataFromAssets();
  TowerRun start(int seed) => towerStart(
      seed: seed, raceId: 'human', professionId: 'warrior', data: data);
  TowerRun won(TowerRun run) =>
      towerAfterFight(run, data, won: true, healthLeft: run.health);

  test('a level gained is a pick on the table: three offers, then taken', () {
    var run = won(start(5));
    expect(towerLevelAfter(run.floorsCleared), 2);
    expect(towerPendingPicks(run), 1);
    final offer = towerStatPickOffer(run, data);
    expect(offer, hasLength(3));
    // Drawn from the run's seed: the same offer every time.
    expect(towerStatPickOffer(run, data), offer);
    final before = towerHeroOf(run, data);
    run = towerTakeStatPick(run, data, 2);
    expect(run.statPicks, [2]);
    expect(towerPendingPicks(run), 0);
    expect(towerStatPickOffer(run, data), isEmpty);
    final after = towerHeroOf(run, data);
    for (final MapEntry(:key, :value) in offer[2].gains.entries) {
      int of(dynamic h) => switch (key) {
            'strength' => h.strength,
            'dexterity' => h.dexterity,
            'constitution' => h.constitution,
            'intelligence' => h.intelligence,
            'wisdom' => h.wisdom,
            'perception' => h.perception,
            'luck' => h.luck,
            _ => h.charisma,
          } as int;
      expect(of(after) - of(before), value, reason: key);
    }
    expect(after.trainingTaken, {offer[2].pathId: 1});
    // No such offer, or no pick waiting: the run as it is.
    expect(towerTakeStatPick(run, data, 0), same(run));
  });

  test('the cards come after the picks; one left waiting goes to the calling',
      () {
    final run = won(start(8));
    final offer = towerStatPickOffer(run, data);
    final picked = towerPick(run, data, null);
    expect(picked.statPicks, [0], reason: 'the calling');
    expect(picked.floor, 2);
    expect(towerHeroOf(picked, data).trainingTaken, {offer[0].pathId: 1});
  });

  test('the save keeps the picks; an old save takes the calling\'s', () {
    final run = towerTakeStatPick(won(start(3)), data, 1);
    final again = TowerRun.fromJson(
        jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
    expect(again.statPicks, [1]);
    expect(towerHeroOf(again, data).strength, towerHeroOf(run, data).strength);
    // A save from before v1.857 (no picks): brought up to date as it loads
    // (v1.867), each pick its levels earned the calling's (offer 0).
    final old = run.toJson()..remove('picks');
    final loaded = TowerRun.fromJson(old);
    expect(loaded.statPicks, [0]);
    expect(towerPendingPicks(loaded), 0);
    expect(loaded.toJson()['picks'], [0]);
  });

  test('the bot takes its picks the story\'s way, and none is left waiting',
      () {
    final run = playTowerRun(seed: 11, data: data);
    expect(towerPendingPicks(run), 0);
    expect(run.statPicks.length,
        greaterThanOrEqualTo(towerLevelAfter(run.floorsCleared - 1) - 1));
  });

  testWidgets('the main game\'s Level Up takes the Tower\'s pick',
      (tester) async {
    const story = '{"raceId":"elf","professionId":"mage","gold":321,'
        '"level":4,"maxHealth":40,"currentHealth":40}';
    SharedPreferences.setMockInitialValues({'player_session': story});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final paths = trainingPathsFrom(jsonDecode(
            File('assets/gamedata/training_paths.json').readAsStringSync())
        as Map<String, dynamic>);
    final run = won(start(5));
    final offer = towerStatPickOffer(run, data);
    final levelUp = TowerLevelUpSession(run, data);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
      child: MaterialApp(
          navigatorKey: nav, home: const Scaffold(body: Text('the floor'))),
    ));
    // Opened the way the floor opens it (tower_floor_screen.dart).
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) =>
            levelUp.wrap(const LevelUpScreen(doneLabelKey: 'tower_continue'))));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byKey(const Key('stat_pick_offer_1')), findsOneWidget);
    // A pick still waiting: no button to leave yet.
    expect(find.byKey(const Key('level_up_done')), findsNothing);
    await tester.tap(find.byKey(const Key('stat_pick_offer_1')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('stat_pick_take')));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(levelUp.run.statPicks, [1]);
    expect(levelUp.pending, 0);
    expect(towerHeroOf(levelUp.run, data).trainingTaken, {offer[1].pathId: 1});
    // The story's own save is as it was: the Tower's picks are not in it.
    final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
    final saved = jsonDecode(prefs.getString('player_session')!) as Map;
    expect(saved['raceId'], 'elf');
    expect(saved['gold'], 321);
    expect(saved['trainingTaken'] ?? const {}, isEmpty);
    // The pick made, a clear button takes the hero back to the climb
    // (v1.909, the user's phone report: only the back arrow did).
    expect(find.byKey(const Key('level_up_done')), findsOneWidget);
    expect(find.text('Continue the climb'), findsOneWidget);
    await tester.tap(find.byKey(const Key('level_up_done')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpScreen), findsNothing);
    expect(find.text('the floor'), findsOneWidget);
  });
}
