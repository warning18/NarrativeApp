// The detour engine (Wave 11, detour_scenes.dart and detour_pacing.dart):
// detour_scenes.json holds what the engine can play, the pacing keeps to
// the user's rules (D1: never between two scenes of one place; D2: chapter
// 4 gets its share; D8: none in the last chapter; no two in a row; each
// chapter's landmark met once), and in the simulator every chapter from 2
// to 7 gets detours. DETOUR_RUNS=200 prints the full report (see
// docs/simulation/detours.md).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/detour_pacing.dart';
import 'package:narrative_data_app/data/detour_scenes.dart';
import 'package:narrative_data_app/data/expedition_steps.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

const _abilities = {
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'charisma',
  'perception',
  'luck',
};

void main() {
  final scenes = detourScenesFrom(_json('assets/gamedata/detour_scenes.json'));
  final geo = Geography.parse(
    geography: _json('assets/gamedata/geography.json'),
    biomes: _json('assets/gamedata/biomes.json'),
  );
  final enemies = _json('assets/gamedata/enemies.json');
  final raw = _json(StoryRepository.assetPath);
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  group('detour_scenes.json', () {
    test('every scene is whole, in both languages, and plays', () {
      expect(scenes, isNotEmpty);
      for (final scene in scenes.values) {
        final at = 'scene ${scene.id}';
        expect(scene.title, isNotEmpty, reason: at);
        expect(scene.titleFr, isNotEmpty, reason: at);
        expect(scene.rumour, isNotEmpty, reason: at);
        expect(scene.rumourFr, isNotEmpty, reason: at);
        expect(scene.beats.length, inInclusiveRange(1, 4), reason: at);
        if (scene.isLandmark) {
          expect(scene.beats.length, greaterThanOrEqualTo(3), reason: at);
        }
        expect(scene.minChapter, lessThanOrEqualTo(scene.maxChapter),
            reason: at);
        expect(scene.minChapter, greaterThanOrEqualTo(2), reason: at);
        // Where: a biome of biomes.json, or a place of geography.json
        // (preferred, not required, for a landmark).
        expect(scene.where.isEmpty, isFalse, reason: at);
        for (final biome in scene.where.biomes) {
          expect(geo.biomes.containsKey(biome), isTrue,
              reason: '$at: biome $biome');
        }
        for (final place in scene.where.places) {
          expect(geo.place(place), isNotNull, reason: '$at: place $place');
        }
        for (final beat in scene.beats) {
          final b = '$at, beat ${beat.id}';
          expect(writtenStepTypes, contains(beat.type), reason: b);
          expect(beat.text, isNotEmpty, reason: b);
          expect(beat.textFr, isNotEmpty, reason: b);
          for (final choice in beat.choices) {
            final c = '$b, choice ${choice.id}';
            expect(choice.text, isNotEmpty, reason: c);
            expect(choice.textFr, isNotEmpty, reason: c);
            if (choice.check != null) {
              expect(_abilities, contains(choice.check), reason: c);
            }
            for (final foe in choice.fight) {
              expect(enemies.containsKey(foe), isTrue, reason: '$c: $foe');
            }
          }
        }
      }
    });

    test('chapters 2 to 7 each have one landmark, the last chapter none', () {
      for (var chapter = 2; chapter <= 8; chapter++) {
        final landmarks = [
          for (final s in scenes.values)
            if (s.isLandmark && s.opensFor(chapter: chapter, flags: const {}))
              s.id,
        ];
        expect(landmarks.length, chapter <= lastDetourChapter ? 1 : 0,
            reason: 'chapter $chapter: $landmarks');
      }
    });

    test('a scene plays as the story plays an excursion', () {
      final scene = scenes['short_count']!;
      final play = buildDetourScene(scene,
          chapter: 2, random: Random(1), enemies: enemies);
      expect(play.nodes.length, scene.beats.length);
      // The first beat can be backed away from, at no cost.
      final leave = play.nodes.first.choices.last;
      expect(leave.nextId, detourLeaveNextId);
      expect(leave.text, trFor(AppLanguage.en, 'detour_leave_it'));
      expect(play.outcomes[play.firstNodeId]!.length,
          play.nodes.first.choices.length);
      // A check or a fight in it: a watch of the day.
      expect(play.watches, detourSceneWatches);
      // A discovery finds the chapter's gold.
      final find =
          play.nodes[scene.beats.indexWhere((b) => b.type == 'discovery')];
      expect(find.choices.first.goldMod, greaterThan(0));
      // A one-beat stop with no roll costs nothing.
      final stop = scenes.values
          .firstWhere((s) => s.beats.length == 1 && !s.hasCheckOrFight);
      expect(stop.watches, 0);
    });

    test('the draw follows the length shares', () {
      final open = scenes.values.where((s) => !s.isLandmark).toList();
      final random = Random(3);
      final counts = <int, int>{};
      for (var i = 0; i < 4000; i++) {
        final s = drawDetourScene(open, random)!;
        counts[min(3, s.beats.length)] =
            (counts[min(3, s.beats.length)] ?? 0) + 1;
      }
      final present = {for (final s in open) min(3, s.beats.length)};
      final total =
          present.fold<double>(0, (a, l) => a + detourLengthShare[l]!);
      for (final length in present) {
        expect(counts[length]! / 4000,
            closeTo(detourLengthShare[length]! / total, 0.03),
            reason: 'length $length');
      }
    });
  });

  group('the pacing', () {
    const road = DetourRoad(chapter: 3, biome: 'ashlands');
    RoadTurn turn(DetourPacing p, DetourRoad r, {int seed = 0}) => planRoad(
        pacing: p,
        road: r,
        scenes: const {},
        flags: const {},
        random: Random(seed));

    test('no road between two scenes of one place (D1)', () {
      // Two scenes of the camp, then the camp and a place of its chapter.
      final camp = story.nodes.values.firstWhere(
          (n) => n.settlement?.isCamp == true && n.location != null);
      final sameplace = story.nodes.values
          .firstWhere((n) => n.id != camp.id && n.location == camp.location);
      expect(
          detourRoadBetween(story, geo,
              fromNodeId: camp.id, toNodeId: sameplace.id, chapter: 4),
          isNull);
      // A trip from the camp is a road.
      expect(
          detourRoadBetween(story, geo,
              fromNodeId: '4999_camp', toNodeId: '5100', chapter: 4),
          isNotNull);
    });

    test('none in chapter 1 or the last chapter (D8)', () {
      for (final chapter in [1, 8]) {
        var p = const DetourPacing(quiet: 10);
        for (var i = 0; i < 50; i++) {
          final t = turn(p, DetourRoad(chapter: chapter), seed: i);
          expect(t.isDetour, isFalse, reason: 'chapter $chapter');
          p = t.next;
        }
      }
    });

    test('a set piece holds nothing and owes nothing', () {
      final t = turn(const DetourPacing(quiet: 10),
          const DetourRoad(chapter: 3, setPiece: true));
      expect(t.kind, RoadTurnKind.quiet);
      expect(t.next.owed, isFalse);
    });

    test(
        'a crisis owes its detour, paid after the cooldown, lapsing with '
        'the chapter', () {
      var p = const DetourPacing(chapter: 3, quiet: 10);
      // A crisis rolls the odds of a road at rest: some seed owes.
      final crisis = [
        for (var seed = 0; seed < 20; seed++)
          turn(p, const DetourRoad(chapter: 3, crisis: true), seed: seed),
      ].firstWhere((t) => t.kind == RoadTurnKind.owed);
      p = crisis.next.copyWith(cooldown: 1);
      final cooling = turn(p, road);
      expect(cooling.isDetour, isFalse);
      final paid = turn(cooling.next, road);
      expect(paid.isDetour, isTrue);
      expect(paid.paysOwed, isTrue);
      expect(paid.next.owed, isFalse);
      // Owed in chapter 3, gone in chapter 4.
      expect(crisis.next.inChapter(4).owed, isFalse);
    });

    test('never two in a row, and never a long dry spell', () {
      var p = const DetourPacing(chapter: 3);
      var longestDry = 0, dry = 0, detours = 0;
      var last = false;
      for (var i = 0; i < 3000; i++) {
        final t = turn(p, road, seed: i);
        if (t.isDetour) {
          expect(last, isFalse, reason: 'two in a row at road $i');
          detours++;
          dry = 0;
        } else {
          dry++;
          longestDry = max(longestDry, dry);
        }
        last = t.isDetour;
        p = t.next;
      }
      // About one road in five or six (the cooldown's road among them),
      // and no endless dry spell: at 45% a road once the timer has risen,
      // twenty quiet ones in a row (over 3,000 roads) never come.
      expect(detours / 3000, closeTo(0.18, 0.04));
      expect(longestDry, lessThanOrEqualTo(20));
    });

    test('a city\'s streets, a long road and a tight deadline move the odds',
        () {
      expect(detourChanceFor(1, road), closeTo(0.14, 1e-9));
      expect(
          detourChanceFor(
              1, const DetourRoad(chapter: 3, kind: DetourRoadKind.streets)),
          closeTo(0.07, 1e-9));
      expect(detourChanceFor(1, const DetourRoad(chapter: 3, watches: 2)),
          closeTo(0.182, 1e-9));
      expect(detourChanceFor(1, const DetourRoad(chapter: 3, daysToSpare: 1)),
          closeTo(0.042, 1e-9));
      expect(detourChanceFor(99, road), detourPityCap);
    });

    test(
        'the landmark comes on the chapter\'s first free road, wherever '
        'it is', () {
      // A road whose biome no landmark names.
      const elsewhere = DetourRoad(chapter: 5, biome: 'arid_coast');
      var p = const DetourPacing(chapter: 5);
      RoadTurn? met;
      for (var i = 0; i < landmarkDueRoad; i++) {
        final t = planRoad(
            pacing: p,
            road: elsewhere,
            scenes: scenes,
            flags: const {},
            random: Random(100 + i));
        if (t.landmark) met = t;
        p = t.next;
      }
      expect(
          met?.scene?.id, landmarkOf(scenes, chapter: 5, flags: const {})?.id);
      expect(p.met, contains(met!.scene!.id));
      // Met once: never again.
      expect(
          landmarkOf(scenes, chapter: 5, flags: const {}, met: p.met), isNull);
    });

    test('a written scene fits its road; with none, today\'s chain', () {
      const fen = DetourRoad(chapter: 4, biome: 'fen');
      final fits = scenesFitting(scenes, fen, flags: const {});
      expect(fits, isNotEmpty);
      expect(fits.every((s) => s.where.biomes.contains('fen')), isTrue);
      const nowhere = DetourRoad(chapter: 4, biome: 'no_such_biome');
      final turns = [
        for (var seed = 0; seed < 20; seed++)
          planRoad(
              pacing: const DetourPacing(
                  chapter: 4, roads: 5, quiet: 99, met: ['lamp_that_counts']),
              road: nowhere,
              scenes: scenes,
              flags: const {},
              random: Random(seed)),
      ];
      final t = turns.firstWhere((t) => t.isDetour);
      expect(t.scene, isNull);
    });

    test(
        'a scene may name several biomes or places, and need several '
        'flags', () {
      final read = detourScenesFrom({
        'two': {
          'where': {
            'biome': ['fen', 'tear'],
            'place': ['saltmouth_wharf'],
          },
          'requires': {
            'flag': 'met_wren_1',
            'flags': ['camp_founded'],
          },
          'beats': [
            {'id': 'a', 'type': 'event', 'text': 'A.'},
          ],
        },
      })['two']!;
      expect(read.where.fits(biomeId: 'tear'), isTrue);
      expect(read.where.fits(biomeId: 'frost'), isFalse);
      expect(read.where.fits(chain: ['saltmouth_wharf', 'saltmouth']), isTrue);
      expect(read.opensFor(chapter: 3, flags: {'met_wren_1'}), isFalse);
      expect(read.opensFor(chapter: 3, flags: {'met_wren_1', 'camp_founded'}),
          isTrue);
    });

    test('the pacing survives a save', () {
      const p = DetourPacing(
          chapter: 5, roads: 3, quiet: 2, cooldown: 1, owed: true, met: ['a']);
      final back = DetourPacing.fromJson(jsonDecode(jsonEncode(p.toJson())));
      expect(back.toJson(), p.toJson());
    });
  });

  group('in the simulator', () {
    final runs = int.tryParse(Platform.environment['DETOUR_RUNS'] ?? '') ?? 48;
    late List<SimRunSummary> results;

    setUpAll(() {
      Map<String, dynamic> table(String name) =>
          _json('assets/gamedata/$name.json');
      final tables = {
        for (final name in [
          'enemies', 'dice', 'skills', 'items', 'shops', 'races', //
          'professions', 'spells', 'item_sets', 'zones', 'skill_trees',
          'factions', 'signs', 'subclans', 'relations', 'titles', 'geography',
          'biomes', 'quests', 'npcs', 'land_routes', 'land_events', 'houses',
          'expedition_steps', 'training_paths', 'detour_scenes', 'ports',
        ])
          name: table(name),
      };
      final professions = tables['professions']!.keys.toList()..sort();
      const goals = [
        SimStrategy.random,
        SimStrategy.favorGood,
        SimStrategy.favorEvil,
        SimStrategy.maximizeGold,
      ];
      results = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: table('game_config'),
          plan: [
            for (var i = 0; i < runs; i++)
              (
                strategy: goals[i % goals.length],
                raceId: null,
                professionId:
                    professions[(i ~/ goals.length) % professions.length],
              ),
          ],
          seed: 11,
          transcripts: true);
      if (Platform.environment['DETOUR_RUNS'] != null) {
        stdout.writeln(_report(results));
      }
    });

    bool detour(SimRoad r) => r.kind == 'scene' || r.kind == 'chain';

    test(
        'every chapter with roads at rest gets detours, chapter 4 its share, '
        'the last chapter none', () {
      for (var chapter = 2; chapter <= 8; chapter++) {
        final reached =
            results.where((r) => (r.furthestChapter ?? 0) >= chapter).toList();
        double mean(bool Function(SimRoad) f) => reached.isEmpty
            ? 0
            : [
                  for (final r in reached)
                    r.roads.where((x) => x.chapter == chapter && f(x)).length,
                ].reduce((a, b) => a + b) /
                reached.length;
        final detours = mean(detour);
        if (chapter > lastDetourChapter) {
          expect(detours, 0, reason: 'chapter $chapter');
        } else if (mean((x) => x.atRest) >= 1) {
          expect(detours, greaterThanOrEqualTo(0.5),
              reason: 'chapter $chapter');
        }
      }
      // D2: chapter 4's trips and districts roll.
      final four = results.where((r) => (r.furthestChapter ?? 0) >= 4);
      expect(four.where((r) => r.roads.any((x) => x.chapter == 4 && detour(x))),
          isNotEmpty);
    });

    test(
        'each chapter\'s landmark is met in every run that walks a free '
        'road at rest there', () {
      for (var chapter = 2; chapter <= lastDetourChapter; chapter++) {
        final walked = [
          for (final r in results)
            if (r.roads.any((x) =>
                x.chapter == chapter &&
                x.atRest &&
                !const {'road_event', 'hunter', 'temptation'}.contains(x.kind)))
              r,
        ];
        final met = walked
            .where(
                (r) => r.roads.any((x) => x.chapter == chapter && x.landmark))
            .length;
        expect(met, walked.length, reason: 'chapter $chapter');
      }
    });

    test('no road between two scenes of one place, no two encounters in a row',
        () {
      const cooled = {'scene', 'chain', 'familiar'};
      for (final r in results) {
        SimRoad? last;
        for (final road in r.roads) {
          final from = geo.placeOfNode(story.nodeFor(road.from));
          final to = geo.placeOfNode(story.nodeFor(road.to));
          if (from != null && to != null) {
            expect(from.id == to.id, isFalse,
                reason: '${road.from} > ${road.to}');
          }
          if (!road.atRest) continue;
          // The cooldown is the chapter's; a landmark is its promise.
          if (last != null &&
              last.chapter == road.chapter &&
              last.kind != 'quiet' &&
              cooled.contains(road.kind) &&
              !road.landmark) {
            fail('${road.kind} right after ${last.kind} at ${road.to}');
          }
          last = road;
        }
      }
    });

    test('the transcript tells the run, its roads among it', () {
      final told = results.first.transcript;
      expect(told, isNotEmpty);
      expect(told.any((l) => l.startsWith('== Chapter 2')), isTrue);
      expect(
          told.any((l) => l.contains('road:scene') || l.contains('road:chain')),
          isTrue);
    });
  });
}

/// The report of [results]: per chapter, what the roads held.
String _report(List<SimRunSummary> results) {
  final out = StringBuffer()
    ..writeln('runs: ${results.length}')
    ..writeln('| Chapter | Runs | Roads | Detours/run | Runs with one | '
        'Scenes | Chain | Landmark met | Familiar | Hunters | Owed | '
        'Road events |')
    ..writeln('|---|---|---|---|---|---|---|---|---|---|---|---|');
  for (var chapter = 2; chapter <= 8; chapter++) {
    final reached =
        results.where((r) => (r.furthestChapter ?? 0) >= chapter).toList();
    if (reached.isEmpty) continue;
    int count(bool Function(SimRoad) f) => [
          for (final r in reached)
            r.roads.where((x) => x.chapter == chapter && f(x)).length,
        ].fold(0, (a, b) => a + b);
    final roads = count((x) => x.kind != 'owed');
    final detours = count((x) => x.kind == 'scene' || x.kind == 'chain');
    final withOne = reached
        .where((r) => r.roads.any((x) =>
            x.chapter == chapter && (x.kind == 'scene' || x.kind == 'chain')))
        .length;
    final landmark = reached
        .where((r) => r.roads.any((x) => x.chapter == chapter && x.landmark))
        .length;
    String pct(int n) => '${(100 * n / max(1, roads)).toStringAsFixed(1)}%';
    out.writeln('| $chapter | ${reached.length} | '
        '${(roads / reached.length).toStringAsFixed(1)} | '
        '${(detours / reached.length).toStringAsFixed(2)} | '
        '${(100 * withOne / reached.length).round()}% | '
        '${count((x) => x.kind == 'scene')} | ${count((x) => x.kind == 'chain')} | '
        '${(100 * landmark / reached.length).round()}% | '
        '${pct(count((x) => x.kind == 'familiar'))} | '
        '${pct(count((x) => x.kind == 'hunter' || x.kind == 'temptation'))} | '
        '${count((x) => x.kind == 'owed')} | '
        '${pct(count((x) => x.kind == 'road_event'))} |');
  }
  final all = [
    for (final r in results) ...r.roads.where((x) => x.kind != 'owed')
  ];
  final kinds = <String, int>{};
  for (final r in all) {
    kinds[r.kind] = (kinds[r.kind] ?? 0) + 1;
  }
  out.writeln('roads at rest or not: ${all.length}; by kind: $kinds');
  final perRun = [
    for (final r in results)
      r.roads.where((x) => x.kind == 'scene' || x.kind == 'chain').length,
  ]..sort();
  out.writeln('detours per run: mean '
      '${(perRun.reduce((a, b) => a + b) / perRun.length).toStringAsFixed(2)}, '
      'median ${perRun[perRun.length ~/ 2]}, max ${perRun.last}');
  final scenesMet = <String, int>{};
  for (final r in results) {
    for (final x in r.roads) {
      if (x.sceneId != null) {
        scenesMet[x.sceneId!] = (scenesMet[x.sceneId!] ?? 0) + 1;
      }
    }
  }
  out.writeln(
      'scenes met: ${(scenesMet.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => '${e.key} ${e.value}').join(', ')}');
  out.writeln('--- transcript of run 0 ---');
  for (final line in results.first.transcript.take(400)) {
    out.writeln(line);
  }
  return out.toString();
}
