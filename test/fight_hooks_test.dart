// The fight's hooks for UX's panels and skill effects (Core, plumbing only):
// the Tower's rival flag, and the hit and status-tick events the fight
// publishes (fight_events.dart, docs/simulation/fight-hooks.md). One fight
// in this file, as the other fight tests do.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/skill_vfx.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart'
    show towerEventsLive;
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_events_provider.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_fight_launcher.dart';

import 'fight_qa694_harness.dart' show loadApp;
import 'skill_fight_harness.dart'
    show gamedata, pumpUntil, settle, shows, tapWhenEnabled;
import 'support/pump.dart';

void main() {
  test('a Tower rival floor sets the rival flag, the other floors do not', () {
    final data = towerDataFromAssets();
    TowerRun? rival;
    TowerRun? other;
    for (var seed = 1; seed <= 40 && (rival == null || other == null); seed++) {
      final start = towerStart(
          seed: seed,
          raceId: 'human',
          professionId: 'warrior',
          events: towerEventsLive,
          data: data);
      for (var floor = 1; floor <= 12; floor++) {
        final run = start.copyWith(floor: floor);
        final kind = towerEventKindOf(run);
        if (kind == TowerEventKind.rival) rival ??= run;
        if (kind == null) other ??= run;
      }
    }
    expect(rival, isNotNull, reason: 'no rival floor in the first seeds');
    expect(other, isNotNull);
    expect(towerFightIsRival(rival!), isTrue);
    expect(towerFightIsRival(other!), isFalse);
    // The same floors with the events off hold no rival.
    expect(towerFightIsRival(rival.copyWith(events: 0)), isFalse);
  });

  testWidgets('a strike, a foe move and the poison ticks are published',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // The hero's one face: the rogue's Poison Blade (an Earth skill that
    // poisons); the thug's one move: a plague bite (it poisons too).
    SharedPreferences.setMockInitialValues({
      'combat_dice_speed': 'quad',
      'gamedb_dice': jsonEncode({
        ...gamedata('dice.json'),
        'hooks_die': {
          'diceName': 'hooks_die',
          'numberOfFaces': 1,
          'faces': [
            {
              'faceName': 'Blade',
              'type': 'Skill',
              'value': 6,
              'element': 'None',
              'linkedSkillID': 'rogue_poison_blade',
            },
          ],
        },
      }),
    });
    usePhone(tester, const Size(600, 1600));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await loadApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['hooks_die'],
          'equippedDiceId': 'hooks_die',
          'maxHealth': 400,
          'currentHealth': 400,
        })));
    final hits = <FightHitEvent>[];
    final ticks = <FightStatusTickEvent>[];
    final events = container.read(fightEventsProvider);
    final subs = <StreamSubscription<Object>>[
      events.hits.listen(hits.add),
      events.ticks.listen(ticks.add),
    ];
    addTearDown(() {
      for (final s in subs) {
        s.cancel();
      }
    });
    final thug = {
      ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
      'skillMoves': [
        {
          'skillID': 'plague_bite',
          'condition': 'Always',
          'requiredElement': 'None',
          'chance': 100,
          'healthThreshold': 0,
          'priority': 5,
        },
      ],
    };
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'slum_thug',
                  enemy: thug,
                  modifiers: const EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay),
                )));
    await loadApp(tester);
    await tester.tap(find.text('Enter Battle'));
    await settle(tester);
    await pumpUntil(tester, () => shows('Roll Dice'));

    for (var round = 0;
        round < 4 &&
            !(ticks.any((t) => t.target.isFoe) &&
                ticks.any((t) => t.target.isPlayer));
        round++) {
      await tapWhenEnabled(tester, 'Roll Dice');
      await pumpUntil(tester, () => shows('Confirm'));
      await tapWhenEnabled(tester, 'Confirm');
      await pumpFor(tester, 40);
      await settle(tester);
      await pumpUntil(tester, () => shows('Roll Dice'));
    }

    // The hero's strike: on the one foe, its skill and element, its tier
    // the one its power gives, and its crit the engine's roll.
    final strikes = hits.where((h) => h.kind == FightHitKind.strike).toList();
    expect(strikes, isNotEmpty);
    final strike = strikes.first;
    expect(strike.target, const FightTarget(FightSide.foe, 0, 'enemy_0'));
    expect(strike.source, const FightTarget(FightSide.party, 0, 'player'));
    expect(strike.amount, greaterThan(0));
    expect(strike.skillId, 'rogue_poison_blade');
    expect(strike.element, 'Earth');
    expect(strike.tier, vfxTierFor(strike.power));
    expect(strike.round, 1);
    expect(strike.blows, 1);

    // The thug's bite on the hero.
    final bites = hits.where((h) => h.kind == FightHitKind.foeMove).toList();
    expect(bites, isNotEmpty);
    expect(bites.first.target.isPlayer, isTrue);
    expect(bites.first.source, const FightTarget(FightSide.foe, 0, 'enemy_0'));
    expect(bites.first.skillId, 'plague_bite');
    expect(bites.first.crit, isFalse);

    // Both poisons ticked, as poison, with their amounts.
    final foeTick = ticks.firstWhere((t) => t.target.isFoe);
    expect(foeTick.target.id, 'enemy_0');
    expect(foeTick.status, StatusEffectType.poison);
    expect(foeTick.statusId, 'poison');
    expect(foeTick.amount, greaterThan(0));
    final heroTick = ticks.firstWhere((t) => t.target.isPlayer);
    expect(heroTick.statusId, 'poison');
    expect(heroTick.amount, greaterThan(0));
    expect(heroTick.round, greaterThan(1));

    // The ticks are the two skills' poison magnitudes (skills.json).
    final skills = gamedata('skills.json');
    expect(foeTick.amount,
        (skills['rogue_poison_blade'] as Map)['statusMagnitude'] as int);
    expect(heroTick.amount,
        (skills['plague_bite'] as Map)['statusMagnitude'] as int);
    expect(tester.takeException(), isNull);
  });

  test('a hub with no listener publishes nothing and costs nothing', () {
    final events = FightEvents();
    expect(events.hasHitListener, isFalse);
    // Nobody listens: dropped, no error.
    events.hit(const FightHitEvent(
        kind: FightHitKind.strike,
        target: FightTarget(FightSide.foe, 0, 'enemy_0'),
        amount: 3,
        power: 1.5,
        crit: true,
        element: 'Fire',
        round: 1));
    final got = <FightHitEvent>[];
    final sub = events.hits.listen(got.add);
    expect(events.hasHitListener, isTrue);
    events.hit(const FightHitEvent(
        kind: FightHitKind.strike,
        target: FightTarget(FightSide.foe, 0, 'enemy_0'),
        amount: 3,
        power: 1.5,
        crit: true,
        element: 'Fire',
        round: 1));
    // Synchronous: there at once.
    expect(got.single.tier, VfxTier.mighty);
    sub.cancel();
    events.dispose();
  });
}
