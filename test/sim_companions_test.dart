// The competent player's companions in the simulator (sim_companions.dart):
// recruited as the game allows, seated by the pick rule, swapped for a
// better one, fighting with their signature die, walking out at the leave
// line, every step logged; and the naive player, the CI bands' measure,
// unchanged.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_companions.dart';
import 'package:narrative_data_app/data/sim_policy.dart';
import 'package:narrative_data_app/data/sim_quests.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final _companions = _table('companions');
final _races = _table('races');
final _professions = _table('professions');
final _gameConfig = _table('game_config');
final _dice = _table('dice');
final _skills = _table('skills');
final _houses = _table('houses');

SimParty _party({Map<String, dynamic>? companions, int level = 10}) => SimParty(
      companions: companions ?? _companions,
      races: _races,
      professions: _professions,
      gameConfig: _gameConfig,
      dice: _dice,
      skills: _skills,
      houses: _houses,
    )..levelIs(level);

StoryData _story() {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  return StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
}

// sim-tables-ok: specialisations: the frozen run's tuple and hash (S1 of
// docs/qa/chapter1-core.md) were pinned on the world before these five; Core
// replaces the pin with property checks, and the world goes with it.
final _runTables = simTables(without: {
  'specialisations',
  'spec_variants',
  'skill_merges',
  'detour_scenes',
  'ports'
});

SimRunSummary _warriorRun(SimPolicy policy) => simulatePlaythroughs(
      _story(),
      tables: _runTables,
      gameConfig: _gameConfig,
      plan: const [
        (strategy: SimStrategy.random, raceId: null, professionId: 'warrior'),
      ],
      seed: 7,
      policy: policy,
    ).single;

/// The same stable hash as sim_competent_test.dart.
int _stableHash(Iterable<String> parts) {
  var h = 0x811c9dc5;
  for (final unit in parts.join('\n').codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xffffffff;
  }
  return h;
}

void main() {
  group('recruiting', () {
    test('a companion joins once, and never after leaving', () {
      final p = _party();
      expect(p.recruit('vess', chapter: 1, cause: 'quest q'), isTrue);
      expect(p.recruit('vess', chapter: 1, cause: 'quest q'), isFalse);
      expect(p.recruit('nobody', chapter: 1, cause: 'quest q'), isFalse);
      p.lose('vess', chapter: 2, cause: 'taken');
      expect(p.lost, {'vess'});
      expect(p.recruit('vess', chapter: 3, cause: 'quest q'), isFalse);
    });

    test("Kelda sits only once Kelda's Hall stands", () {
      final p = _party();
      p.recruit('kelda', chapter: 2, cause: 'quest q_ch2_keldas_stand');
      expect(p.roster.keys, ['kelda']);
      expect(p.active, isEmpty);
      p.housesBuilt(['keldas_hall'], chapter: 3);
      expect(p.active, ['kelda']);
      expect(p.log.last.kind, 'pick');
    });

    test(
        "the recruit quests' own gates: Tobin for the good, Malrik for the "
        'evil', () {
      final log = SimQuestLog(_table('quests'));
      bool can(String id, String label) =>
          log.canTake(id, flags: {}, gold: 0, alignmentLabel: label);
      expect(can('q_ch4_tobins_vigil', 'Good'), isTrue);
      expect(can('q_ch4_tobins_vigil', 'Evil'), isFalse);
      expect(can('q_ch5_malriks_cut', 'Evil'), isTrue);
      expect(can('q_ch5_malriks_cut', 'Good'), isFalse);
      // Handing a recruit quest in names its companion.
      log.accept('q_ch3_marens_penance',
          step: 1, flags: {}, gold: 0, alignmentLabel: 'Neutral');
      final pay = log.complete('q_ch3_marens_penance',
          step: 2, bias: SimTurnInBias.any, random: Random(1));
      expect(pay.allyId, 'maren');
    });
  });

  group('the pick rule', () {
    test('two seats go to the two worth most in a fight', () {
      // Three companions more than a point apart, so no tie rule decides
      // (Liora and Vess, a d8 since the dice sizes, are within one).
      final p = _party();
      for (final id in ['vess', 'sable', 'maren']) {
        p.recruit(id, chapter: 3, cause: 'quest');
      }
      expect(p.capacity, 2);
      final ranked = ['vess', 'sable', 'maren']
        ..sort((a, b) => p.valueOf(b).compareTo(p.valueOf(a)));
      expect(p.active.toSet(), ranked.take(2).toSet());
      // A third seat (the Barracks Annex) seats the third.
      p.housesBuilt(['barracks_annex'], chapter: 4);
      expect(p.capacity, 3);
      expect(p.active, hasLength(3));
    });

    test('a tie goes to the higher approval, then to the alignment fit', () {
      Map<String, dynamic> twin(int good, int evil) => {
            ...(_companions['liora'] as Map<String, dynamic>),
            'requiredHouseId': '',
            'approvesGood': good,
            'approvesEvil': evil,
          };
      final p = _party(companions: {
        'a': twin(-2, 2),
        'b': twin(2, -2),
        'c': twin(0, 0),
      });
      for (final id in ['a', 'b', 'c']) {
        p.recruit(id, chapter: 2, cause: 'quest', alignment: 50);
      }
      // Equal values and approval: the good player's seats go to the ones
      // who like good deeds most (b, then c).
      expect(p.active, ['b', 'c']);
      expect(p.log.where((e) => e.reason.contains('tie within 1')), isNotEmpty);
      // a, trusted more, wins its seat back on approval.
      p.roster['a']!.approval = 10;
      p.arrange(chapter: 3, alignment: 50);
      expect(p.active.first, 'a');
    });

    test('a better companion joining a full party takes the weakest seat', () {
      final p = _party();
      p.recruit('vess', chapter: 2, cause: 'quest');
      p.recruit('sable', chapter: 2, cause: 'quest');
      expect(p.active, hasLength(2));
      final weakest =
          p.active.reduce((a, b) => p.valueOf(a) <= p.valueOf(b) ? a : b);
      expect(p.valueOf('maren'), greaterThan(p.valueOf(weakest)));
      p.recruit('maren', chapter: 3, cause: 'quest q_ch3_marens_penance');
      final swap = p.log.lastWhere((e) => e.kind == 'swap');
      expect(swap.companionId, 'maren');
      expect(swap.other, weakest);
      expect(p.active, contains('maren'));
      expect(p.active, isNot(contains(weakest)));
      expect(swap.line, startsWith('Ch3 swap: maren in, $weakest out ('));
    });
  });

  group('in a fight', () {
    test('a companion rolls their signature die and casts its skills', () {
      final p = _party(level: 5)..recruit('maren', chapter: 3, cause: 'q');
      final allies = p.fightAllies();
      expect(allies.single.id, 'maren');
      final c = SimCharacter.create(
        raceId: 'human',
        race: _races['human'] as Map<String, dynamic>,
        professionId: 'warrior',
        profession: _professions['warrior'] as Map<String, dynamic>,
        gameConfig: _gameConfig,
        dice: _dice,
        spells: const {},
      );
      // A dummy that cannot be beaten in time and hits for nothing: the
      // die gets every round.
      simulateSimFight(
        character: c,
        enemies: [
          const MapEntry('dummy', {'maxHealth': 100000, 'damage': 0}),
        ],
        chapter: 3,
        skills: _skills,
        items: const {},
        random: Random(5),
        maxRounds: 40,
        allies: allies,
      );
      final maren = allies.single;
      final signature =
          dieSignatureSkillIds(_dice['holy_die'] as Map<String, dynamic>)
              .toSet();
      expect(maren.facesPlayed.values.fold<int>(0, (a, b) => a + b), 40);
      expect(maren.skillsCast, isNotEmpty);
      expect(signature, containsAll(maren.skillsCast.keys));
      expect(maren.damageDealt, greaterThan(0));
      p.afterFight(allies, won: false);
      expect(p.skillsCast['maren'], isNotEmpty);
    });

    test('a knocked-out companion is back at 30% after a won fight', () {
      final p = _party()..recruit('vess', chapter: 1, cause: 'q');
      final allies = p.fightAllies();
      allies.single.currentHealth = 0;
      p.afterFight(allies, won: true);
      expect(p.knockouts, {'vess': 1});
      expect(p.roster['vess']!.health,
          (allies.single.maxHealth * simReviveHealthFraction).round());
      p.rest();
      expect(p.roster['vess']!.health, isNull);
    });
  });

  group('approval', () {
    test('a companion pushed to the leave line walks out, the bench steps in',
        () {
      final p = _party();
      // Grosh dislikes good deeds; Maren loves them.
      p.recruit('grosh', chapter: 3, cause: 'quest');
      p.recruit('maren', chapter: 3, cause: 'quest');
      p.recruit('vess', chapter: 3, cause: 'quest');
      expect(p.active, containsAll(['grosh', 'maren']));
      final benched = p.roster.keys.firstWhere((id) => !p.active.contains(id));
      final benchedBefore = p.roster[benched]!.approval;
      var deeds = 0;
      while (p.roster.containsKey('grosh') && deeds < 20) {
        p.react(chapter: 4, cause: 'choice at x', alignmentMod: 3);
        deeds++;
      }
      expect(p.departed, {'grosh'});
      expect(p.active, isNot(contains('grosh')));
      expect(p.active, hasLength(2));
      // The bench did not see the deeds.
      expect(p.roster[benched]!.approval, benchedBefore);
      final leave = p.log.singleWhere((e) => e.kind == 'leave');
      expect(p.roster.containsKey('grosh'), isFalse);
      expect(leave.line, startsWith('Ch4 leave: grosh (approval -1'));
      expect(leave.line, endsWith('after choice at x; $benched steps in)'));
      expect(p.log.where((e) => e.kind == 'wary').map((e) => e.companionId),
          contains('grosh'));
      expect(p.log.where((e) => e.kind == 'devoted').map((e) => e.companionId),
          contains('maren'));
      expect(p.recruit('grosh', chapter: 5, cause: 'quest'), isFalse);
    });

    test("a scene's approvalMods and the story taking one", () {
      final p = _party()
        ..recruit('vess', chapter: 2, cause: 'q')
        ..recruit('liora', chapter: 2, cause: 'q');
      p.react(chapter: 2, cause: 'c', approvalMods: {'vess': 4, '*': -1});
      expect(p.roster['vess']!.approval, startingApproval + 4);
      expect(p.roster['liora']!.approval, startingApproval - 1);
      p.lose('*', chapter: 2, cause: 'taken at x');
      expect(p.lost, hasLength(1));
      expect(p.log.last.kind, 'lost');
    });
  });

  group('whole runs (seed 7, one warrior)', () {
    late SimRunSummary naive;
    late SimRunSummary competent;
    setUpAll(() {
      naive = _warriorRun(SimPolicy.naive);
      competent = _warriorRun(SimPolicy.competent);
    });

    test('naive with companions.json loaded: Vica only (v1.601)', () {
      // sim_competent_test.dart's pin (re-pinned at v1.577, v1.578 and v1.602 with it).
      expect((
        naive.raceId,
        naive.finalLevel,
        naive.finalGold,
        naive.fightsWon,
        naive.fightsLost,
        naive.offers,
        naive.steps,
        naive.furthestChapter,
      ), (
        'dwarf',
        15,
        1172,
        21,
        74,
        28,
        259,
        8
      ));
      expect(_stableHash(naive.choicesTaken), 2866742764);
      // The naive player recruits no one; the story gives it Vica (v1.601).
      expect(
          naive.companionLog
              .where((e) => e.kind == 'recruit')
              .map((e) => e.companionId),
          ['vica']);
      expect(naive.companions, ['vica']);
    });

    test('the competent player recruits, and logs every step with a reason',
        () {
      final log = competent.companionLog;
      expect(log.where((e) => e.kind == 'recruit'), isNotEmpty);
      for (final event in log) {
        expect(event.reason, isNotEmpty);
        expect(event.line, startsWith('Ch${event.chapter} ${event.kind}'));
      }
      // Every recruit came from its own quest, handed in; Vica from the
      // story (v1.601).
      final done = {
        for (final q in competent.questRecords)
          if (q.completedAtStep != null) q.questId,
      };
      for (final event in log.where((e) => e.kind == 'recruit')) {
        if (event.companionId == 'vica') {
          expect(event.reason, 'the story');
          continue;
        }
        expect(done, contains(event.reason.replaceFirst('quest ', '')));
      }
      expect(competent.companions, isNotEmpty);
    });
  });
}
