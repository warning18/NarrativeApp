// Training at level-up (Wave 7, training.dart): every path is worth a
// level's five points; an offer is three different paths, the first
// leaning to the character's profession or people; fewer than five points
// bring a small offer; taking a choice applies its gains and spends its
// points, and an old save's points become offers.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final paths = trainingPathsFrom(
      jsonDecode(File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);

  test('ten paths, each worth five points, named in both languages', () {
    expect(paths, hasLength(10));
    for (final p in paths.values) {
      expect(trainingPointsOf(p.gains), trainingFullPoints, reason: p.id);
      expect(p.gains.keys.every(trainingStats.contains), isTrue, reason: p.id);
      for (final e in p.gains.entries) {
        expect(e.value % trainingUnitOf(e.key), 0, reason: '${p.id} ${e.key}');
      }
      expect(p.name, isNotEmpty);
      expect(p.nameFr, isNotEmpty, reason: p.id);
      expect(p.blurb, isNotEmpty, reason: p.id);
      expect(p.blurbFr, isNotEmpty, reason: p.id);
    }
  });

  test('an offer is three different paths, the first the calling', () {
    for (var seed = 0; seed < 50; seed++) {
      final offer = drawTraining(
          paths: paths,
          points: 5,
          random: Random(seed),
          professionId: 'mage',
          raceId: 'orc');
      expect(offer, hasLength(trainingChoiceCount));
      expect(offer.map((c) => c.pathId).toSet(), hasLength(3));
      expect(
          paths[offer.first.pathId]!
              .leansTo(professionId: 'mage', raceId: 'orc'),
          isTrue,
          reason: 'seed $seed');
      for (final c in offer) {
        expect(c.points, trainingFullPoints);
        expect(c.gains, paths[c.pathId]!.gains);
      }
    }
  });

  test('the habit is the path taken most', () {
    final offer = drawTraining(
        paths: paths,
        points: 5,
        random: Random(1),
        professionId: 'mage',
        taken: {'envoy': 3});
    expect(offer.map((c) => c.pathId), contains('envoy'));
  });

  test('fewer than five points bring a small offer; none bring none', () {
    final small = drawTraining(paths: paths, points: 2, random: Random(3));
    expect(small, hasLength(3));
    for (final c in small) {
      expect(c.points, 1);
      expect(c.small, isTrue);
      expect(c.gains, hasLength(1));
      expect(trainingPointsOf(c.gains), 1);
    }
    expect(drawTraining(paths: paths, points: 0, random: Random(3)), isEmpty);
  });

  test('a choice survives the save', () {
    const c = TrainingChoice(
        pathId: 'bruiser',
        gains: {'baseDamage': 1, 'maxHealth': 20},
        points: 3);
    expect(TrainingChoice.fromJson(jsonDecode(jsonEncode(c.toJson()))), c);
  });

  group('the session', () {
    Future<PlayerSessionNotifier> notifierWith(Map<String, dynamic> raw) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson(raw));
      return notifier;
    }

    test('taking a full offer applies its gains and spends five points',
        () async {
      final n = await notifierWith(
          {'statPoints': 7, 'professionId': 'warrior', 'maxHealth': 100});
      final offer = await n.ensureTraining(paths, random: Random(4));
      expect(offer, hasLength(3));
      // Drawn once: asking again keeps it.
      expect(await n.ensureTraining(paths, random: Random(99)), offer);
      final before = n.state;
      final choice = offer[1];
      expect(await n.takeTraining(1), isTrue);
      final after = n.state;
      expect(after.statPoints, 2);
      expect(
          after.maxHealth - before.maxHealth, choice.gains['maxHealth'] ?? 0);
      expect(after.currentHealth - before.currentHealth,
          choice.gains['maxHealth'] ?? 0);
      expect(after.strength - before.strength, choice.gains['strength'] ?? 0);
      expect(after.trainingTaken, {choice.pathId: 1});
      expect(after.trainingOffer, isEmpty);

      // The two points left are small offers; taken, they count no path.
      final small = await n.ensureTraining(paths, random: Random(5));
      expect(small.every((c) => c.small), isTrue);
      expect(await n.takeTraining(0), isTrue);
      expect(n.state.statPoints, 1);
      expect(n.state.trainingTaken, {choice.pathId: 1});
    });

    test('a waiting offer of the wrong size is drawn anew', () async {
      final n = await notifierWith({'statPoints': 5});
      final full = await n.ensureTraining(paths, random: Random(1));
      expect(full.first.small, isFalse);
      await n.loadSession(n.state.copyWith(statPoints: 1));
      final small = await n.ensureTraining(paths, random: Random(1));
      expect(small.first.small, isTrue);
    });

    test('no points, no offer; a bad index takes nothing', () async {
      final n = await notifierWith({'statPoints': 0});
      expect(await n.ensureTraining(paths), isEmpty);
      expect(await n.takeTraining(0), isFalse);
    });
  });
}
