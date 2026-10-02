// Chapter 1's fights (v1.196): the choice flags that shape them (no
// healing in a chain, a lesson, the lucky die), what they do to a fight's
// modifiers and to the session, and their balance in the playthrough
// simulator: the first fight easy on every path, the chains escalating,
// the charge at the Inquisitor-General very hard but winnable.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the choice flags', () {
    test('survive a round trip, and are off unless set', () {
      final choice = StoryChoice.fromJson(const {
        'text': 'Put the bouncer down',
        'next_id': '106',
        'triggerEnemyId': 'den_bouncer',
        'noHeal': true,
        'tutorialFight': true,
        'luckyDieReveal': true,
      });
      expect(choice.noHeal, isTrue);
      expect(choice.tutorialFight, isTrue);
      expect(choice.luckyDieReveal, isTrue);
      final again = StoryChoice.fromJson(choice.toJson());
      expect(again.noHeal, isTrue);
      expect(again.tutorialFight, isTrue);
      expect(again.luckyDieReveal, isTrue);
      final plain = StoryChoice.fromJson(const {'text': 'x', 'next_id': 'y'});
      expect(
          plain.noHeal || plain.tutorialFight || plain.luckyDieReveal, isFalse);
      expect(plain.toJson().keys,
          isNot(anyOf(contains('noHeal'), contains('tutorialFight'))));
    });

    test('reach the fight as its modifiers, with the loss branch', () {
      final modifiers = EncounterModifiers.fromChoice(const StoryChoice(
        text: 'Rob the dice table',
        nextId: '110',
        triggerEnemyId: 'street_bandit',
        loseNextId: '115',
        noHeal: true,
      ));
      expect(modifiers.keepWounds, isTrue);
      expect(modifiers.lossContinues, isTrue);
      expect(modifiers.tutorial, isFalse);
      expect(modifiers.isDefault, isFalse);
      final lesson = EncounterModifiers.fromChoice(const StoryChoice(
        text: 'x',
        nextId: 'y',
        triggerEnemyId: 'den_bouncer',
        tutorialFight: true,
        luckyDieReveal: true,
      ));
      expect(lesson.tutorial, isTrue);
      expect(lesson.luckyDieReveal, isTrue);
      expect(lesson.lossContinues, isFalse);
      // A sneak gone wrong keeps its ambush even with a loss branch.
      final caught = EncounterModifiers.fromChoice(const StoryChoice(
        text: 'x',
        nextId: 'y',
        triggerEnemyId: 'slum_thug',
        forcedCondition: 'ambush',
        loseNextId: 'z',
      ));
      expect(caught.forcedCondition, BattlefieldCondition.ambush);
      expect(caught.lossContinues, isTrue);
      // A zone's tier stamped on keeps them.
      final stamped = modifiers.copyWith(chapter: 1, difficultyMultiplier: 1.2);
      expect(stamped.keepWounds, isTrue);
      expect(stamped.lossContinues, isTrue);
    });

    test('the lucky die: a first wound that never fells, then its sign', () {
      // The blow is the enemy's own, capped at a fifth of the player's
      // health, and always leaves them standing.
      expect(
          luckyDieOpeningBlow(
              enemyDamage: 8, playerHealth: 100, playerMaxHealth: 100),
          8);
      expect(
          luckyDieOpeningBlow(
              enemyDamage: 60, playerHealth: 100, playerMaxHealth: 100),
          20);
      expect(
          luckyDieOpeningBlow(
              enemyDamage: 8, playerHealth: 3, playerMaxHealth: 100),
          2);
      expect(
          luckyDieOpeningBlow(
              enemyDamage: 8, playerHealth: 1, playerMaxHealth: 100),
          0);
      expect(luckyDieStrike(50), 20);
      expect(luckyDieStrike(1), 1);
    });
  });

  group('a chain with no healing', () {
    Future<PlayerSessionNotifier> notifierWith(PlayerSession session) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(session);
      return notifier;
    }

    test('a level-up does not refill health; outside a chain it does',
        () async {
      final session = baseSession().copyWith(currentHealth: 40);
      final chained = await notifierWith(session);
      expect(
          await chained.applyCombatResult(
              hpAfter: 40, xpGain: 100, keepWounds: true),
          isTrue);
      expect(chained.state.currentHealth, 40);
      expect(chained.state.level, 2);
      final free = await notifierWith(session);
      await free.applyCombatResult(hpAfter: 40, xpGain: 100);
      expect(free.state.currentHealth, free.state.maxHealth);
    });
  });

  test('old saves on removed chapter 1 scenes land on what replaced them', () {
    final dag = _json('assets/Cleaned_Narrative_DAG.json');
    for (final id in [
      '151', '151_forge', '151_vess', '280', '281', '281_scarred', //
      '896', '897', '898', '899_paid', '965_mercy', '965_vengeance',
    ]) {
      expect(dag.containsKey(id), isFalse, reason: id);
      expect(dag.containsKey(liveNodeId(id)), isTrue, reason: id);
    }
  });

  test('the starting die is the lucky charm', () {
    expect(dieDisplayName('starter_die'), 'Lucky Die');
    expect(dieDisplayName('starter_die', language: AppLanguage.fr),
        'Dé porte-bonheur');
    expect(dieDisplayName('gambler_die'), 'Gambler Die');
  });

  group('balance, in the playthrough simulator', () {
    final races = _json('assets/gamedata/races.json');
    final professions = _json('assets/gamedata/professions.json');
    final gameConfig = _json('assets/gamedata/game_config.json');
    final dice = _json('assets/gamedata/dice.json');
    final skills = _json('assets/gamedata/skills.json');
    final items = _json('assets/gamedata/items.json');
    final enemies = _json('assets/gamedata/enemies.json');
    final spells = parseSpells(_json('assets/gamedata/spells.json'));
    final story = {
      for (final e in _json('assets/Cleaned_Narrative_DAG.json').entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    final combos = [
      for (final race in races.keys)
        for (final prof in professions.keys) (race, prof),
    ];
    const trials = 12;

    SimCharacter make(String race, String prof) => SimCharacter.create(
          raceId: race,
          race: races[race] as Map<String, dynamic>,
          professionId: prof,
          profession: professions[prof] as Map<String, dynamic>,
          gameConfig: gameConfig,
          dice: dice,
          spells: spells,
        );

    MapEntry<String, Map<String, dynamic>> foe(String id, {double hp = 1}) {
      final raw = Map<String, dynamic>.from(enemies[id] as Map);
      raw['maxHealth'] = ((raw['maxHealth'] as num) * hp).round();
      return MapEntry(id, raw);
    }

    // A fight that keeps its wounds, as a chain's link does: a level-up
    // does not heal, and a loss ends the walk.
    bool fight(SimCharacter c, List<String> ids, Random r, {double hp = 1}) {
      final won = simulateSimFight(
        character: c,
        enemies: [for (final id in ids) foe(id, hp: hp)],
        chapter: 1,
        skills: skills,
        items: items,
        random: r,
      ).won;
      if (!won) return false;
      final left = c.currentHealth;
      c.gainXp(ids.fold<int>(
          0, (sum, id) => sum + ((enemies[id] as Map)['xpReward'] as int)));
      c.currentHealth = min(left, c.maxHealth);
      return true;
    }

    // The first fight, the lucky die's: the enemy's blow, then its sign.
    bool lesson(SimCharacter c, String id, Random r) {
      c.currentHealth -= luckyDieOpeningBlow(
          enemyDamage: (enemies[id] as Map)['damage'] as int,
          playerHealth: c.currentHealth,
          playerMaxHealth: c.maxHealth);
      return fight(c, [id], r, hp: 1 - luckyDieStrikeShare);
    }

    test('the first fight is easy on every path, for everyone', () {
      for (final first in story['105']!.choices) {
        final id = first.allTriggerEnemyIds.single;
        expect(storyOnlyEnemyIds, contains(id));
        for (final (race, prof) in combos) {
          var wins = 0;
          for (var t = 0; t < trials; t++) {
            if (lesson(make(race, prof), id, Random(t * 31 + prof.length))) {
              wins++;
            }
          }
          expect(wins, greaterThanOrEqualTo(trials - 1),
              reason: '$id against a $race $prof');
        }
      }
    });

    test('each chain escalates: its last link is a gamble', () {
      for (final hub in ['110', '120']) {
        final links = [
          for (final c in story[hub]!.choices)
            if (c.triggersCombat) c.allTriggerEnemyIds,
        ];
        final reached = List<int>.filled(links.length, 0);
        var walks = 0;
        for (final (race, prof) in combos) {
          for (var t = 0; t < trials; t++) {
            final c = make(race, prof);
            final r = Random(t * 17 + race.length * 3 + prof.length);
            if (!lesson(c, 'den_bouncer', r)) continue;
            walks++;
            for (var i = 0; i < links.length; i++) {
              if (!fight(c, links[i], r)) break;
              reached[i]++;
            }
          }
        }
        final rates = [for (final n in reached) n / walks];
        expect(rates.first, greaterThan(0.9), reason: '$hub: $rates');
        expect(rates.last, inInclusiveRange(0.2, 0.75), reason: '$hub: $rates');
        for (var i = 1; i < rates.length; i++) {
          expect(rates[i], lessThanOrEqualTo(rates[i - 1]),
              reason: '$hub: $rates');
        }
      }
    });

    test('the charge at Vane is very hard, but winnable', () {
      final charge = story['400']!.choices.singleWhere((c) => c.triggersCombat);
      final vane = charge.allTriggerEnemyIds.single;
      expect(soloOnlyEnemyIds, contains(vane));
      var wins = 0, tries = 0;
      final winners = <String>{};
      for (final (race, prof) in combos) {
        for (var t = 0; t < trials; t++) {
          final c = make(race, prof);
          final r = Random(t * 7 + race.length + prof.length * 5);
          // The quickest way to the house: the stake and the first fight.
          if (!lesson(c, 'sore_loser', r)) continue;
          tries++;
          if (fight(c, [vane], r)) {
            wins++;
            winners.add(prof);
          }
        }
      }
      final rate = wins / tries;
      expect(rate, inInclusiveRange(0.1, 0.4), reason: 'won $rate');
      expect(winners.length, greaterThanOrEqualTo(4),
          reason: 'winnable by most professions: $winners');
    });
  });
}
