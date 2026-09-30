// Chapter conditions (v1.181): each chapter from 2 to 6 draws one
// condition from the run's seed (a quarantine, a fair, contested roads,
// the weather at sea, a rival company...), and it shifts the road's
// numbers for that chapter.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chapter_conditions.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('drawing the conditions', () {
    List<ChapterConditionId> run(int seed) => [
          for (var c = 2; c <= 6; c++)
            chapterConditionFor(seed: seed, chapter: c)!.id,
        ];

    test('a run always meets the same conditions', () {
      expect(run(42), run(42));
      expect(chapterConditionFor(seed: 7, chapter: 4),
          same(chapterConditionFor(seed: 7, chapter: 4)));
    });

    test('five different conditions a run; none outside chapters 2 to 6', () {
      for (var seed = 1; seed < 200; seed++) {
        expect(run(seed).toSet(), hasLength(5), reason: 'seed $seed');
        expect(chapterConditionFor(seed: seed, chapter: 1), isNull);
        expect(chapterConditionFor(seed: seed, chapter: 7), isNull);
      }
    });

    test('each condition only in the chapters it fits', () {
      for (var seed = 1; seed < 500; seed++) {
        for (var c = 2; c <= 6; c++) {
          final condition = chapterConditionFor(seed: seed, chapter: c)!;
          expect(condition.chapters, contains(c),
              reason: '${condition.nameEn} in chapter $c, seed $seed');
        }
      }
      ChapterCondition of(ChapterConditionId id) =>
          chapterConditions.firstWhere((c) => c.id == id);
      expect(of(ChapterConditionId.stormSeason).chapters, isNot(contains(2)));
      expect(of(ChapterConditionId.tideFair).chapters, {3, 4});
    });

    test('every condition turns up, and runs differ', () {
      final seen = <ChapterConditionId>{};
      final runs = <String>{};
      for (var seed = 1; seed < 400; seed++) {
        final r = run(seed);
        seen.addAll(r);
        runs.add(r.join(','));
      }
      expect(seen, ChapterConditionId.values.toSet());
      expect(runs.length, greaterThan(300));
    });

    test('an old save without a seed draws from its character', () {
      int seed(int runSeed) => conditionSeedFor(
          runSeed: runSeed,
          characterName: 'Ada',
          raceId: 'elf',
          professionId: 'ranger',
          cycle: 0);
      expect(seed(0), seed(0));
      expect(seed(0), isNot(0));
      expect(seed(12345), 12345);
    });

    test('a save keeps its seed; an old one reads 0', () {
      final old = PlayerSession.fromJson(const {});
      expect(old.runSeed, 0);
      final session = old.copyWith(runSeed: 99);
      expect(PlayerSession.fromJson(session.toJson()).runSeed, 99);
    });
  });

  group('what the conditions change', () {
    ChapterCondition of(ChapterConditionId id) =>
        chapterConditions.firstWhere((c) => c.id == id);

    test('prices', () {
      final quarantine = of(ChapterConditionId.quarantine);
      final fair = of(ChapterConditionId.tideFair);
      expect(conditionedPrice(100, quarantine.shopPrice), 125);
      expect(conditionedPrice(100, fair.shopPrice), 80);
      expect(conditionedPrice(0, 2), 0);
      expect(conditionedPrice(1, 0.5), 1);
      expect(
          conditionedPrice(
              provisionPrice(3), of(ChapterConditionId.leanSeason).rationPrice),
          2 * provisionPrice(3));
      expect(percentChange(1.25), '+25');
      expect(percentChange(0.8), '−20');
    });

    test('every condition changes something, and says so in both languages',
        () {
      for (final c in chapterConditions) {
        final changes = c.shopPrice != 1 ||
            c.rationPrice != 1 ||
            c.roadEventOdds != 1 ||
            c.championShare != 0.4 ||
            c.stormShift != 0 ||
            c.expeditionPay != 1;
        expect(changes, isTrue, reason: c.nameEn);
        for (final text in [
          c.nameEn,
          c.nameFr,
          c.effectEn,
          c.effectFr,
          c.arrivalEn,
          c.arrivalFr
        ]) {
          expect(text.trim(), isNotEmpty, reason: c.nameEn);
        }
        expect(c.championShare + c.shrineShare, lessThanOrEqualTo(1));
      }
    });

    test('contested roads hold more events, mostly champions', () {
      final raw = _json('assets/Cleaned_Narrative_DAG.json');
      final story = StoryData({
        for (final entry in raw.entries)
          entry.key: StoryNode.fromJson(
              entry.key, entry.value as Map<String, dynamic>),
      });
      final roads = [
        for (final node in story.nodes.values)
          for (final choice in node.choices)
            if (!choice.isEnding && isRoadStep(node.id, choice.nextId))
              (from: node.id, to: choice.nextId),
      ];
      final contested = of(ChapterConditionId.contestedRoads);
      int events({ChapterCondition? condition, RoadEventKind? kind}) {
        var n = 0;
        for (final road in roads) {
          for (var at = 0; at < 30; at++) {
            final event = roadEventFor(
              story: story,
              fromNodeId: road.from,
              toNodeId: road.to,
              historyLength: at,
              chapter: 4,
              oddsFactor: condition?.roadEventOdds ?? 1,
              championShare: condition?.championShare ?? 0.4,
              shrineShare: condition?.shrineShare ?? 0.3,
            );
            if (event != null && (kind == null || event == kind)) n++;
          }
        }
        return n;
      }

      expect(events(condition: contested), greaterThan(events() * 1.3));
      expect(events(condition: contested, kind: RoadEventKind.champion),
          greaterThan(events(kind: RoadEventKind.champion) * 2));
    });

    test('storm season brings storms; fair winds keep them away', () {
      final ships = _json('assets/gamedata/enemy_ships.json');
      int storms(double shift) {
        var n = 0;
        for (var seed = 0; seed < 400; seed++) {
          n += buildVoyage(
                  random: Random(seed),
                  length: 4,
                  enemyShips: ships,
                  chapter: 4,
                  stormShift: shift)
              .where((e) => e.kind == SeaEventKind.storm)
              .length;
        }
        return n;
      }

      final base = storms(0);
      expect(storms(of(ChapterConditionId.stormSeason).stormShift),
          greaterThan(base * 1.5));
      expect(storms(of(ChapterConditionId.fairWinds).stormShift),
          lessThan(base * 0.5));
    });
  });
}
