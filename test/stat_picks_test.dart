// Stat picks (docs/proposals/stat-picks.md, stat-scale.md, training.dart):
// each level brings one pick of three offers -- the calling, the habit and
// a turn, no two the same ability -- all three at the pick's rarity (Common
// +1, Rare +2, Epic +3, Heroic +4). The session keeps a pick until one is
// taken, an old save's points are its pending picks, and the simulator and
// autoplay take the build's stat.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final paths = trainingPathsFrom(_gamedata('training_paths'));

  group('drawStatPick', () {
    test('three offers, distinct abilities, the first the calling, one rarity',
        () {
      for (var seed = 0; seed < 200; seed++) {
        final offer = drawStatPick(
            paths: paths,
            random: Random(seed),
            professionId: 'warrior',
            raceId: 'human');
        expect(offer, hasLength(3), reason: 'seed $seed');
        expect(offer.map((o) => o.gains.keys.first).toSet(), hasLength(3),
            reason: 'seed $seed');
        expect(
            paths[offer.first.pathId]!
                .leansTo(professionId: 'warrior', raceId: 'human'),
            isTrue,
            reason: 'seed $seed');
        // One rarity for the three, each worth what it gives.
        expect(offer.map((o) => o.tier).toSet(), hasLength(1),
            reason: 'seed $seed');
        for (final o in offer) {
          final stat = o.gains.keys.first;
          expect(paths[o.pathId]!.gains, contains(stat), reason: 'seed $seed');
          expect(trainingStats, containsAll(o.gains.keys));
          expect(o.points, statPickPointsOf(o.tier), reason: 'seed $seed');
          if (!o.rare) expect(o.gains, {stat: 1});
        }
      }
    });

    test('a warrior is offered its damage stat and Constitution across picks',
        () {
      final seen = <String, int>{};
      for (var seed = 0; seed < 300; seed++) {
        for (final o in drawStatPick(
            paths: paths,
            random: Random(seed),
            professionId: 'warrior',
            raceId: 'dwarf')) {
          for (final stat in o.gains.keys) {
            seen[stat] = (seen[stat] ?? 0) + 1;
          }
        }
      }
      for (final stat in ['strength', 'constitution']) {
        expect(seen[stat] ?? 0, greaterThan(30), reason: stat);
      }
      // Base damage, armor and health come from the abilities now.
      for (final stat in ['baseDamage', 'baseArmor', 'maxHealth']) {
        expect(seen[stat], isNull, reason: stat);
      }
    });

    test('the habit is the path taken most', () {
      final offer = drawStatPick(
          paths: paths,
          random: Random(3),
          professionId: 'mage',
          taken: const {'hunter': 4, 'arcanist': 1});
      expect(offer[1].pathId, 'hunter');
    });

    test('the rarities come at 90/8/1.6/0.4, the rarer with a second ability',
        () {
      final count = <SignRarity, int>{};
      var withSecond = 0;
      const n = 6000;
      for (var seed = 0; seed < n; seed++) {
        final offer = drawStatPick(
            paths: paths, random: Random(seed), professionId: 'ranger');
        final tier = offer.first.tier;
        count[tier] = (count[tier] ?? 0) + 1;
        for (final o in offer) {
          final path = paths[o.pathId]!;
          for (final e in o.gains.entries) {
            expect(path.gains, contains(e.key));
          }
          if (o.gains.length == 2) withSecond++;
          // The offer's own ability keeps the larger share.
          expect(
              o.gains.values.first, greaterThanOrEqualTo(o.gains.values.last));
        }
      }
      double share(SignRarity t) => (count[t] ?? 0) / n;
      expect(share(SignRarity.common), closeTo(0.90, 0.02));
      expect(share(SignRarity.rare), closeTo(0.08, 0.015));
      expect(share(SignRarity.epic), closeTo(0.016, 0.008));
      expect(share(SignRarity.heroic), lessThan(0.012));
      expect(withSecond, greaterThan(0));
    });

    test('Luck moves the odds up, to Luck 15', () {
      expect(statPickOdds(0), {
        SignRarity.common: 90,
        SignRarity.rare: 8,
        SignRarity.epic: 1.6,
        SignRarity.heroic: 0.4,
      });
      final lucky = statPickOdds(10);
      expect(lucky[SignRarity.common], 80);
      expect(lucky[SignRarity.rare], closeTo(14, 1e-9));
      expect(lucky[SignRarity.epic], closeTo(4.6, 1e-9));
      expect(lucky[SignRarity.heroic], closeTo(1.4, 1e-9));
      expect(statPickOdds(40), statPickOdds(statPickLuckCap));
      for (final l in [0, 5, 15]) {
        expect(statPickOdds(l).values.fold<double>(0, (a, b) => a + b),
            closeTo(100, 1e-9));
      }
      expect(statPickExpectedPoints(0), closeTo(1.124, 1e-9));
      expect(statPickExpectedPoints(15), closeTo(1.349, 1e-9));
    });

    test('a rarer pick: +2, or +1 and +1; +2 and +1; +2 and +2', () {
      expect(statPickGains('strength', SignRarity.common, second: 'luck'),
          {'strength': 1});
      expect(statPickGains('strength', SignRarity.rare, second: 'luck'),
          {'strength': 2});
      expect(
          statPickGains('strength', SignRarity.rare,
              second: 'luck', split: true),
          {'strength': 1, 'luck': 1});
      expect(statPickGains('strength', SignRarity.epic, second: 'luck'),
          {'strength': 2, 'luck': 1});
      expect(statPickGains('strength', SignRarity.heroic, second: 'luck'),
          {'strength': 2, 'luck': 2});
      // A path of one ability: every point on it.
      expect(statPickGains('constitution', SignRarity.heroic),
          {'constitution': 4});
    });

    test('an offer survives the save', () {
      const o = StatPickOffer(
          pathId: 'hunter',
          gains: {'perception': 2, 'dexterity': 1},
          tier: SignRarity.epic);
      expect(StatPickOffer.fromJson(jsonDecode(jsonEncode(o.toJson()))), o);
      const plain =
          StatPickOffer(pathId: 'juggernaut', gains: {'constitution': 1});
      expect(plain.points, 1);
      expect(plain.rare, isFalse);
      expect(StatPickOffer.fromJson(jsonDecode(jsonEncode(plain.toJson()))),
          plain);
      // One saved before the rarities, as `rare: true`, reads as Rare.
      final legacy = StatPickOffer.fromJson(const {
        'path': 'duelist',
        'gains': {'dexterity': 2},
        'rare': true,
      });
      expect(legacy.tier, SignRarity.rare);
      expect(legacy.rare, isTrue);
    });

    test('statPickFor: the build\'s stat, then Constitution, Dex, Luck', () {
      const offer = [
        StatPickOffer(pathId: 'brawler', gains: {'strength': 1}),
        StatPickOffer(pathId: 'duelist', gains: {'dexterity': 1}),
        StatPickOffer(pathId: 'skirmisher', gains: {'dexterity': 2}),
      ];
      expect(statPickFor(offer, 'strength'), 0);
      // The one giving most of it.
      expect(statPickFor(offer, 'dexterity'), 2);
      // Nothing of the build's stat: the priority list's first offered.
      expect(statPickFor(offer, 'wisdom'), 2);
      const body = [
        StatPickOffer(pathId: 'zealot', gains: {'charisma': 1}),
        StatPickOffer(pathId: 'envoy', gains: {'wisdom': 1}),
        StatPickOffer(pathId: 'juggernaut', gains: {'constitution': 1}),
      ];
      expect(statPickFor(body, 'strength'), 2);
      // Nothing of the list: the calling.
      expect(statPickFor(body, 'strength', priority: const []), 0);
    });

    test('statPickForShares: the ability furthest below its share', () {
      const offer = [
        StatPickOffer(pathId: 'brawler', gains: {'strength': 1}),
        StatPickOffer(pathId: 'warden', gains: {'constitution': 1}),
        StatPickOffer(pathId: 'envoy', gains: {'charisma': 1}),
      ];
      const shares = {'strength': 0.6, 'constitution': 0.4};
      expect(statPickForShares(offer, shares, const {}), 0);
      expect(
          statPickForShares(
              offer, shares, const {'strength': 3, 'constitution': 1}),
          1);
      // None of the build's: the calling.
      expect(statPickForShares(offer, const {'luck': 1.0}, const {}), 0);
    });
  });

  group('the session', () {
    Future<PlayerSessionNotifier> notifierWith(Map<String, dynamic> raw) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson(raw));
      return notifier;
    }

    test('a pick is kept until taken; taking it applies one pick', () async {
      final n = await notifierWith({
        'statPoints': 3,
        'professionId': 'warrior',
        'maxHealth': 20,
        'currentHealth': 16,
        'baseDamage': 3,
      });
      expect(n.state.pendingStatPicks, 3);
      final offer = await n.ensureStatPick(paths, random: Random(4));
      expect(offer, hasLength(3));
      expect(await n.ensureStatPick(paths, random: Random(99)), offer);
      final before = n.state;
      final pick = offer[2];
      expect(await n.takeStatPick(2), isTrue);
      final after = n.state;
      expect(after.statPoints, 2);
      expect(after.pendingStatPicks, 2);
      for (final stat in ['strength', 'constitution']) {
        final was = before.toJson()[stat] as int;
        expect(after.toJson()[stat], was + (pick.gains[stat] ?? 0));
      }
      // Strength is a warrior's damage, Constitution its health.
      expect(
          after.baseDamage, before.baseDamage + (pick.gains['strength'] ?? 0));
      final health = 5 * (pick.gains['constitution'] ?? 0);
      expect(after.maxHealth, before.maxHealth + health);
      expect(after.currentHealth - before.currentHealth, health);
      expect(after.trainingTaken, {pick.pathId: 1});
      expect(after.statPickOffer, isEmpty);
      // The next pick is drawn anew.
      expect(await n.ensureStatPick(paths), hasLength(3));
    });

    test('a rare offer is still one pick', () async {
      final n = await notifierWith({'statPoints': 2, 'dexterity': 3});
      await n.loadSession(n.state.copyWith(statPickOffer: const [
        StatPickOffer(
            pathId: 'brawler', gains: {'strength': 2}, tier: SignRarity.rare),
        StatPickOffer(
            pathId: 'duelist', gains: {'luck': 2}, tier: SignRarity.rare),
        StatPickOffer(
            pathId: 'duelist', gains: {'dexterity': 2}, tier: SignRarity.rare),
      ]));
      expect(await n.takeStatPick(2), isTrue);
      expect(n.state.statPoints, 1);
      expect(n.state.dexterity, 5);
      expect(n.state.trainingTaken, {'duelist': 1});
    });

    test('the default draw is seeded per pick: reopening never rerolls',
        () async {
      final raw = {
        'statPoints': 4,
        'level': 3,
        'professionId': 'rogue',
        'trainingTaken': {'duelist': 2},
      };
      final a = await (await notifierWith(raw)).ensureStatPick(paths);
      final b = await (await notifierWith(raw)).ensureStatPick(paths);
      expect(a, b);
    });

    test('no pick waiting, no offer; a bad index takes nothing', () async {
      final n = await notifierWith({'statPoints': 0});
      expect(await n.ensureStatPick(paths), isEmpty);
      expect(await n.takeStatPick(0), isFalse);
      final m = await notifierWith({'statPoints': 1});
      await m.ensureStatPick(paths);
      expect(await m.takeStatPick(5), isFalse);
      expect(m.state.statPoints, 1);
    });

    test('an old save: points become picks, its training offer is ignored',
        () async {
      // A save from before the picks still carries the training offer it
      // had on the table (three 5-point paths, as the old code wrote it).
      final old = {
        'statPoints': 7,
        'professionId': 'warrior',
        'trainingTaken': {'bruiser': 2},
        'trainingOffer': [
          for (final id in ['bruiser', 'warden', 'envoy'])
            {'path': id, 'gains': paths[id]!.gains, 'points': 5},
        ],
      };
      final s = PlayerSession.fromJson(old);
      expect(s.statPickOffer, isEmpty);
      expect(s.pendingStatPicks, 7);
      expect(s.trainingTaken, {'bruiser': 2});
      expect(s.toJson().containsKey('trainingOffer'), isFalse);
      final n = await notifierWith(old);
      expect(await n.ensureStatPick(paths), hasLength(3));
    });

    test('a level brings one pick and +4 health, no damage by itself',
        () async {
      final n = await notifierWith({
        'level': 1,
        'currentXP': 90,
        'baseDamage': 3,
        'maxHealth': 20,
        'currentHealth': 20,
        'activeQuestIds': ['q_test'],
      });
      await n.applyCombatResult(hpAfter: 10, xpGain: 10);
      expect(n.state.level, 2);
      expect(n.state.baseDamage, 3);
      expect(n.state.maxHealth, 20 + 4);
      expect(n.state.statPoints, 1);
      // Two levels at once from a quest's XP: twice as much.
      await n.completeQuest('q_test', rewardXP: 200 + 300);
      expect(n.state.level, 4);
      expect(n.state.baseDamage, 3);
      expect(n.state.maxHealth, 20 + 3 * 4);
      expect(n.state.statPoints, 3);
    });

    test('the pick on the table survives the save', () async {
      final n = await notifierWith({'statPoints': 2, 'professionId': 'cleric'});
      expect(n.state.toJson().containsKey('statPickOffer'), isFalse);
      final offer = await n.ensureStatPick(paths, random: Random(8));
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('player_session')!)
          as Map<String, dynamic>;
      expect(PlayerSession.fromJson(saved).statPickOffer, offer);
      expect(PlayerSession.fromJson(n.state.toJson()).statPickOffer, offer);
    });
  });

  test('the simulator spends a level as one pick', () {
    final races = _gamedata('races');
    final professions = _gamedata('professions');
    final c = SimCharacter.create(
      raceId: 'voidkin',
      race: races['voidkin'] as Map<String, dynamic>,
      professionId: 'mage',
      profession: professions['mage'] as Map<String, dynamic>,
      gameConfig: _gamedata('game_config'),
      dice: _gamedata('dice'),
      spells: parseSpells(_gamedata('spells')),
    )..trainingPaths = paths;
    int points() =>
        c.strength +
        c.dexterity +
        c.constitution +
        c.intelligence +
        c.wisdom +
        c.perception +
        c.luck +
        c.charisma;
    final before = points();
    final health = c.maxHealth;
    final damage = c.baseDamage;
    expect(c.gainXp(100), isTrue);
    expect(c.level, 2);
    expect(c.trainingTaken.values.fold<int>(0, (a, b) => a + b), 1);
    // One pick, Common to Heroic.
    expect(points() - before, inInclusiveRange(1, 4));
    expect(c.maxHealth, greaterThanOrEqualTo(health + 4));
    // A mage's damage moves only with its Intelligence.
    expect(c.baseDamage - damage, c.pickedPoints['intelligence'] ?? 0);
    expect(c.currentHealth, c.maxHealth);
  });
}
