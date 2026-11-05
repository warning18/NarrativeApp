// The Tower's fight, apart from the story (v1.849, tower_fight_session.dart):
// under TowerFightSession.wrap, the fight reads the Tower hero
// (towerSessionOf) and whatever it does to the hero never reaches the
// story save; what it leaves goes back to the run through towerAfterFight.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/clan_crisis.dart' show mainClanOf;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tower_fight_session.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  TowerRun run() => towerStart(
      seed: 3,
      raceId: 'human',
      professionId: 'warrior',
      clanId: 'vigil',
      unlocksOwned: 5,
      data: data);

  test('the session is the Tower hero: its health, dice, potions and clan', () {
    final r = run();
    final hero = towerHeroOf(r, data);
    final s = towerSessionOf(r, data);
    expect(s.maxHealth, hero.maxHealth);
    expect(s.currentHealth, r.health);
    expect(s.level, hero.level);
    expect(s.equippedDiceId, hero.diceId);
    expect(s.ownedDiceIds, containsAll(hero.ownedDice.keys));
    expect(s.potionCount, towerFlask + 5 ~/ towerUnlocksPerPotion);
    expect(s.raceId, 'human');
    expect(s.professionId, 'warrior');
    expect(mainClanOf(s.politics), 'vigil');
    expect(s.gold, 0);
    expect(s.flags, isEmpty);
  });

  testWidgets('a fight under it reads the Tower hero; the story save stays',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    const story = {
      'raceId': 'elf',
      'professionId': 'mage',
      'ownedDiceIds': ['starter_die'],
      'equippedDiceId': 'starter_die',
      'gold': 321,
      'maxHealth': 40,
      'currentHealth': 40,
    };
    SharedPreferences.setMockInitialValues(
        {'player_session': jsonEncode(story)});
    usePhone(tester, const Size(390, 844));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await settleApp(tester);
    final outer =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    final storySession = outer.read(playerSessionProvider);
    final saved = (await tester.runAsync(SharedPreferences.getInstance))!
        .getString('player_session');

    final r = run();
    final fight = TowerFightSession(r, data);
    final floor = towerFloorOf(r, data);
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => fight.wrap(FightScreen(
              enemyId: floor.enemyIds.first,
              enemy: data.enemies[floor.enemyIds.first] as Map<String, dynamic>,
              modifiers: floor.modifiersFor(r.professionId),
            ))));
    await settleApp(tester);
    expect(find.byType(FightScreen), findsOneWidget);

    // Below the scope the hero is the Tower's.
    final inner =
        ProviderScope.containerOf(tester.element(find.byType(FightScreen)));
    expect(inner.read(playerSessionProvider).maxHealth, fight.start.maxHealth);
    expect(inner.read(playerSessionProvider).raceId, 'human');

    // What the fight does to the hero stays in the Tower's session.
    await tester.runAsync(() async {
      final notifier = inner.read(playerSessionProvider.notifier);
      await notifier.consumePotion();
      await notifier.applyCombatResult(hpAfter: 7, goldGain: 50, xpGain: 10);
    });
    expect(fight.healthLeft, 7);
    expect(fight.current.potionCount, fight.start.potionCount - 1);

    // The story's hero and its save are as they were.
    expect(outer.read(playerSessionProvider).gold, storySession.gold);
    expect(outer.read(playerSessionProvider).raceId, 'elf');
    final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
    expect(prefs.getString('player_session'), saved);

    // The result goes back to the run.
    final after = fight.after(r, won: true);
    expect(after.status, TowerStatus.choosing);
    expect(after.health, greaterThanOrEqualTo(7));
    expect(fight.after(r, won: false).status, TowerStatus.dead);
    await navigator.maybePop();
    await settleApp(tester);
  });
}
