// Stat picks (docs/proposals/stat-picks.md, training.dart): each stat point
// is a pick of three one-point offers -- the calling, the habit and a turn,
// no two the same gain -- the turn now and then a rare two-point offer. The
// session keeps a pick until one is taken, an old save's points are its
// pending picks, and the simulator and autoplay take the build's stat.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
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
    test('three one-point offers, distinct gains, the first the calling', () {
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
        for (final o in offer) {
          final lead = paths[o.pathId]!.leadGain;
          expect(o.gains.keys.first, lead.key, reason: 'seed $seed');
          if (o.rare) {
            expect(o.points, 2);
            continue;
          }
          expect(o.points, 1);
          expect(o.gains, {lead.key: lead.value});
        }
        // Only the turn is ever rare.
        expect(offer[0].rare || offer[1].rare, isFalse);
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

    test('about one pick in eight brings a rare two-point turn', () {
      var rare = 0, doubled = 0, two = 0;
      const n = 4000;
      for (var seed = 0; seed < n; seed++) {
        final offer = drawStatPick(
            paths: paths, random: Random(seed), professionId: 'ranger');
        final turn = offer.last;
        if (!turn.rare) continue;
        rare++;
        expect(turn.points, 2);
        final path = paths[turn.pathId]!;
        if (turn.gains.length == 1) {
          doubled++;
          final lead = path.leadGain;
          expect(turn.gains, {lead.key: 2 * lead.value});
        } else {
          two++;
          expect(turn.gains, hasLength(2));
          for (final e in turn.gains.entries) {
            expect(path.gains, contains(e.key));
            expect(e.value, trainingUnitOf(e.key));
          }
        }
      }
      expect(rare / n, inInclusiveRange(0.09, 0.15));
      // Half and half, loosely.
      expect(doubled, greaterThan(rare ~/ 4));
      expect(two, greaterThan(rare ~/ 4));
    });

    test('an offer survives the save', () {
      const o = StatPickOffer(
          pathId: 'hunter',
          gains: {'perception': 1, 'dexterity': 1},
          rare: true);
      expect(StatPickOffer.fromJson(jsonDecode(jsonEncode(o.toJson()))), o);
      const plain =
          StatPickOffer(pathId: 'juggernaut', gains: {'maxHealth': 10});
      expect(plain.points, 1);
      expect(StatPickOffer.fromJson(jsonDecode(jsonEncode(plain.toJson()))),
          plain);
    });

    test('statPickFor takes the build\'s stat, the rare one first', () {
      const offer = [
        StatPickOffer(pathId: 'brawler', gains: {'strength': 1}),
        StatPickOffer(pathId: 'duelist', gains: {'dexterity': 1}),
        StatPickOffer(
            pathId: 'skirmisher', gains: {'dexterity': 2}, rare: true),
      ];
      expect(statPickFor(offer, 'strength'), 0);
      expect(statPickFor(offer, 'dexterity'), 2);
      expect(statPickFor(offer, 'wisdom'), 0);
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
        'maxHealth': 100,
        'currentHealth': 80,
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
      for (final stat in ['maxHealth', 'strength', 'constitution']) {
        final was = before.toJson()[stat] as int;
        expect(after.toJson()[stat], was + (pick.gains[stat] ?? 0));
      }
      expect(after.currentHealth - before.currentHealth,
          pick.gains['maxHealth'] ?? 0);
      expect(after.trainingTaken, {pick.pathId: 1});
      expect(after.statPickOffer, isEmpty);
      // The next pick is drawn anew.
      expect(await n.ensureStatPick(paths), hasLength(3));
    });

    test('a rare offer is still one pick', () async {
      final n = await notifierWith({'statPoints': 2, 'dexterity': 3});
      await n.loadSession(n.state.copyWith(statPickOffer: const [
        StatPickOffer(pathId: 'brawler', gains: {'strength': 1}),
        StatPickOffer(pathId: 'duelist', gains: {'luck': 1}),
        StatPickOffer(pathId: 'duelist', gains: {'dexterity': 2}, rare: true),
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

    test('the old ways of spending leave no stale pick', () async {
      final n = await notifierWith({'statPoints': 6, 'professionId': 'mage'});
      await n.ensureStatPick(paths, random: Random(1));
      await n.spendStatPoint(stat: 'wisdom');
      expect(n.state.statPickOffer, isEmpty);
      await n.ensureStatPick(paths, random: Random(1));
      await n.ensureTraining(paths, random: Random(1));
      expect(await n.takeTraining(0), isTrue);
      expect(n.state.statPoints, 0);
      expect(n.state.statPickOffer, isEmpty);
      expect(await n.ensureStatPick(paths), isEmpty);
    });

    test('an old save: points become picks, a full build card is dropped',
        () async {
      final old = {
        'statPoints': 7,
        'professionId': 'warrior',
        'trainingTaken': {'bruiser': 2},
        'trainingOffer': [
          for (final id in ['bruiser', 'warden', 'envoy'])
            TrainingChoice(pathId: id, gains: paths[id]!.gains, points: 5)
                .toJson(),
        ],
      };
      final s = PlayerSession.fromJson(old);
      expect(s.trainingOffer, isEmpty);
      expect(s.statPickOffer, isEmpty);
      expect(s.pendingStatPicks, 7);
      expect(s.trainingTaken, {'bruiser': 2});
      final n = await notifierWith(old);
      expect(await n.ensureStatPick(paths), hasLength(3));

      // A small offer (a Tome's point) is kept as it was.
      final small = PlayerSession.fromJson({
        'statPoints': 1,
        'trainingOffer': [
          const TrainingChoice(
                  pathId: 'envoy', gains: {'charisma': 1}, points: 1)
              .toJson(),
        ],
      });
      expect(small.trainingOffer, hasLength(1));
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

  test('the simulator spends a level as five picks of the build\'s stat', () {
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
    final intelligence = c.intelligence;
    final health = c.maxHealth;
    expect(c.gainXp(100), isTrue);
    expect(c.level, 2);
    expect(c.trainingTaken.values.fold<int>(0, (a, b) => a + b), 5);
    // A voidkin mage's one calling is the arcanist, whose lead gain is
    // Intelligence: every pick has it.
    expect(c.intelligence, greaterThanOrEqualTo(intelligence + 5));
    expect(c.maxHealth, greaterThanOrEqualTo(health + 20));
    expect(c.currentHealth, c.maxHealth);
  });
}
