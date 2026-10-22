// Land crossings by who holds the land (wave 16 item 3, docs/proposals/
// wave16-core.md §3): the middle chapters' routes, the road's ruler, the
// band the party's standing puts it in, the draw of one day in three from
// the ruler's events, chapter 7's mild pool, a route whose events are not
// on file, and a save in the middle of a crossing. Wave 17 item 4
// (wave17-core.md §4): chapter 6's crossing of the Grey Sands, which meets
// no ruler while no clan holds the Anchorage, and the cliffs' four events.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chapter_grid_layout.dart'
    show chapterOfNode;
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// An event of the fixture: one sure way through, costing [healthPct].
Map<String, dynamic> _event(String name,
        {String? ruler, String? band, int healthPct = -2}) =>
    {
      'name': name,
      'name_fr': name,
      'text': name,
      'text_fr': name,
      if (ruler != null) 'ruler': ruler,
      if (band != null) 'band': band,
      'choices': [
        {
          'id': 'go',
          'text': 'Go',
          'text_fr': 'Aller',
          'outcome': {'healthPct': healthPct, 'note': 'n', 'note_fr': 'n'},
        },
      ],
    };

/// A small stand-in for land_events.json's wave 16 events (Narrative's
/// file): two fen events and the Mire's and the Dominion's three bands.
final Map<String, LandEvent> _fixture = landEventsFrom({
  'fen_mud': _event('Mud'),
  'fen_lantern': _event('Lantern'),
  for (final clan in ['mire', 'dominion'])
    for (final band in RulerBand.values)
      'ruler_${clan}_${band.name}':
          _event('$clan ${band.name}', ruler: clan, band: band.name),
});

const LandRoute _fen = LandRoute(
  id: 'fen',
  name: 'Fen',
  from: 'cloister',
  to: 'court',
  days: 3,
  rulerOneIn: 3,
  events: {'fen_mud': 2, 'fen_lantern': 1, 'fen_child': 1},
);

void main() {
  final routes = _json('assets/gamedata/land_routes.json');
  final story = _json('assets/Cleaned_Narrative_DAG.json');
  final geography = Geography.parse(
      geography: _json('assets/gamedata/geography.json'),
      biomes: _json('assets/gamedata/biomes.json'));

  group('the middle chapters\' routes', () {
    const expected = {
      'stair_to_court': (4, 'fen', 'cloister', 'court'),
      'reliquary_to_heart': (5, 'frost', 'reliquary', 'heart'),
      'anchorage_to_grave': (6, 'tear', 'anchorage', 'wreck'),
      'lantern_cliffs': (7, 'sea_cliffs', 'camp', 'candlehold'),
    };

    test('run on existing roads, in their chapter and biome', () {
      final roads = {for (final r in worldRoads) r.id: r};
      for (final MapEntry(key: id, value: (chapter, biome, from, to))
          in expected.entries) {
        final route = landRouteFor(routes, id)!;
        expect(route.chapter, chapter, reason: id);
        expect(route.biome, biome, reason: id);
        expect((route.from, route.to), (from, to), reason: id);
        // Chapter 7's cliffs meet no ruler: only Narrative's two mild
        // cliff events (chapter 7 already reads hard).
        expect(route.rulerOneIn, id == 'lantern_cliffs' ? 0 : 3, reason: id);
        for (final road in route.roads) {
          expect(roads[road]?.joins(from), isTrue, reason: '$id: $road');
          expect(roads[road]?.joins(to), isTrue, reason: '$id: $road');
        }
        final prefix = const {
              'fen': 'fen_',
              'frost': 'frost_',
              'tear': 'glass_'
            }[biome] ??
            'cliff_';
        expect(route.events.keys.every((e) => e.startsWith(prefix)), isTrue,
            reason: id);
      }
    });

    test('the routes before them never meet a ruler', () {
      for (final id in [
        'crash_to_sleeper',
        'sleeper_to_wells',
        'camp_to_quarter'
      ]) {
        expect(landRouteFor(routes, id)!.rulerOneIn, 0, reason: id);
      }
    });

    test('chapter 7 draws the four cliff events, each with a sure way', () {
      // The wrecker's lamp and the gulls joined in wave 17, once chapter
      // 7's claimants were fixed (v1.531).
      final cliffs = landRouteFor(routes, 'lantern_cliffs')!;
      expect(cliffs.events, {
        'cliff_salt_wind': 1,
        'cliff_tide_stair': 1,
        'cliff_wrecker_lamp': 1,
        'cliff_gulls': 1,
      });
      expect(cliffs.days, lessThanOrEqualTo(2));
      final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
      for (final id in cliffs.events.keys) {
        final event = events[id];
        expect(event, isNotNull, reason: id);
        expect(event!.isRulers, isFalse, reason: id);
        // A way round that costs at most 2% health, whatever the dice.
        expect(
            event.choices.any(
                (c) => !c.hasCheck && !c.isFight && c.outcome.healthPct >= -2),
            isTrue,
            reason: id);
        // The worst a failed check costs stays under the salt wind's 14%.
        for (final c in event.choices) {
          expect(c.fail.healthPct, greaterThanOrEqualTo(-14), reason: id);
        }
      }
    });

    test('chapter 6 crosses the Grey Sands on Narrative\'s glass events', () {
      final sands = landRouteFor(routes, 'anchorage_to_grave')!;
      expect(sands.roads, ['anchorage_wreck']);
      // The desert kit draws its dunes until the Grey Sands get their own.
      expect(sands.terrain, 'desert');
      // The White Fleet's Grave is on the Grey Sands, the tear's zone.
      expect(geography.placeOfLandmark(sands.to)?.id, 'white_fleet_grave');
      expect(geography.zoneOf('white_fleet_grave')?.biome, sands.biome);
      final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
      expect(sands.events.keys.toSet(), {
        'glass_fulgurite',
        'glass_hull_shelter',
        'glass_drowned_well',
        'glass_tear_pull',
      });
      for (final id in sands.events.keys) {
        expect(events[id], isNotNull, reason: id);
        expect(events[id]!.isRulers, isFalse, reason: id);
        // Mild: chapter 6 is won little more than half the time.
        for (final c in events[id]!.choices) {
          for (final o in [c.outcome, c.success, c.fail]) {
            expect(o.healthPct, greaterThanOrEqualTo(-10), reason: id);
          }
        }
      }
    });

    test('each is named by the choices that leave on it', () {
      const leaving = {
        'stair_to_court': {'4999_camp#0'},
        'reliquary_to_heart': {
          '6010_thread#0',
          '6010_thread#1',
          '6010_thread#2'
        },
        'anchorage_to_grave': {'7001#0'},
        'lantern_cliffs': {'7400#6'},
      };
      final found = <String, Set<String>>{};
      for (final MapEntry(key: nodeId, value: node) in story.entries) {
        final choices = (node as Map)['choices'] as List? ?? const [];
        for (var i = 0; i < choices.length; i++) {
          final choice =
              StoryChoice.fromJson(Map<String, dynamic>.from(choices[i]));
          if (!choice.crossesLand) continue;
          expect(routes, contains(choice.landRouteId), reason: '$nodeId#$i');
          found.putIfAbsent(choice.landRouteId!, () => {}).add('$nodeId#$i');
        }
      }
      for (final MapEntry(key: id, value: ways) in leaving.entries) {
        expect(found[id], ways, reason: id);
      }
      // The chapters' main quests set out on theirs.
      for (final way in ['4999_camp#0', '7001#0', '7400#6']) {
        final [nodeId, at] = way.split('#');
        final choice = StoryChoice.fromJson(Map<String, dynamic>.from(
            (story[nodeId]['choices'] as List)[int.parse(at)]));
        expect(choice.mainQuest, isTrue, reason: way);
      }
    });

    test('a save in the middle keeps the old flow: no beat re-crosses', () {
      // The crossing is drawn at departure and never saved: a save on the
      // leaving scene meets it, a save past it (on the scene it leads to,
      // or anywhere after) never does, since no scene beyond names it.
      const arrivals = {
        'stair_to_court': '5003',
        'reliquary_to_heart': '6003',
        'anchorage_to_grave': '7300',
        'lantern_cliffs': '7500',
      };
      for (final MapEntry(key: id, value: arrival) in arrivals.entries) {
        final seen = <String>{};
        final open = [arrival];
        while (open.isNotEmpty) {
          final nodeId = open.removeLast();
          if (!seen.add(nodeId) || seen.length > 400) continue;
          final node = story[nodeId];
          if (node is! Map) continue;
          for (final raw in node['choices'] as List? ?? const []) {
            final choice = StoryChoice.fromJson(Map<String, dynamic>.from(raw));
            expect(choice.landRouteId, isNot(id), reason: '$id at $nodeId');
            if (chapterOfNode(choice.nextId) == chapterOfNode(arrival)) {
              open.add(choice.nextId);
            }
          }
        }
        expect(seen, isNotEmpty, reason: id);
      }
    });
  });

  group('the road\'s ruler', () {
    test('is who holds the land: a town\'s ruler, else the country\'s', () {
      String ruler(String id, [PoliticsState p = PoliticsState.empty]) =>
          landRouteRuler(landRouteFor(routes, id)!, geography, p);
      // The Drowned Cloister: the Mire's Court is its one held district.
      expect(ruler('stair_to_court'), 'mire');
      // No one holds the Reliquary or the Dead Heart: the Frost Reach's
      // ruler does.
      expect(ruler('reliquary_to_heart'), 'dominion');
      expect(ruler('lantern_cliffs'), 'dominion');
      // The desert has no ruler at all.
      expect(ruler('crash_to_sleeper'), '');
      // Nobody holds the Grey Sands at the start, and the Hollow Cape has
      // no ruler: chapter 6's crossing meets only its biome.
      expect(ruler('anchorage_to_grave'), '');
    });

    test('the Grey Sands meet a ruler only once a clan holds the land', () {
      final sands = landRouteFor(routes, 'anchorage_to_grave')!;
      expect(sands.rulerOneIn, 3);
      final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
      // Unheld: no ruler, so no ruler's events at any band, and the draw is
      // the biome's alone.
      for (final band in RulerBand.values) {
        expect(rulerPool(events, '', band), isEmpty);
      }
      for (var seed = 0; seed < 300; seed++) {
        final drawn = drawCrossing(sands, events.keys,
            random: Random(seed),
            rulers: rulerPool(events, '', RulerBand.neutral));
        expect(drawn, hasLength(sands.days), reason: 'seed $seed');
        expect(drawn.every((id) => id.startsWith('glass_')), isTrue,
            reason: 'seed $seed');
      }
      // The Anchorage's chapel taken (the Penitents and the Dominion both
      // claim it), or the Anchorage itself: its holder rules the road.
      const chapel =
          PoliticsState(control: {'white_anchorage_chapel': 'penitents'});
      expect(landRouteRuler(sands, geography, chapel), 'penitents');
      const town = PoliticsState(control: {'white_anchorage': 'crows'});
      expect(landRouteRuler(sands, geography, town), 'crows');
      final pool = rulerPool(events, 'penitents', RulerBand.hostile);
      expect(pool, isNotEmpty);
      var met = 0;
      for (var seed = 0; seed < 600; seed++) {
        final drawn = drawCrossing(sands, events.keys,
            random: Random(seed), rulers: pool);
        met += drawn.where(pool.contains).length;
      }
      // One day in three, never twice: about 56% of two-day crossings.
      expect(met / 600, inInclusiveRange(0.45, 0.67));
    });

    test('changes hands with the land around it', () {
      final cliffs = landRouteFor(routes, 'lantern_cliffs')!;
      const taken = PoliticsState(control: {'candlehold': 'crows'});
      expect(landRouteRuler(cliffs, geography, taken), 'crows');
      final fen = landRouteFor(routes, 'stair_to_court')!;
      const court = PoliticsState(control: {'hollow_court': 'vigil'});
      expect(landRouteRuler(fen, geography, court), 'vigil');
    });

    test('standing sets the band: Friend and up, Hostile and down', () {
      final bands = {
        for (final tier in StandingTier.values) tier: rulerBandFor(tier),
      };
      expect(bands[StandingTier.sworn], RulerBand.friend);
      expect(bands[StandingTier.trusted], RulerBand.friend);
      expect(bands[StandingTier.friend], RulerBand.friend);
      for (final tier in [
        StandingTier.friendly,
        StandingTier.known,
        StandingTier.unknown,
        StandingTier.wary,
        StandingTier.unfriendly,
        StandingTier.resented,
      ]) {
        expect(bands[tier], RulerBand.neutral, reason: tier.name);
      }
      expect(bands[StandingTier.hostile], RulerBand.hostile);
      expect(bands[StandingTier.hunted], RulerBand.hostile);
      expect(rulerBandFor(standingTierFor(19)), RulerBand.friend);
      expect(rulerBandFor(standingTierFor(-26)), RulerBand.hostile);
    });

    test('the pool is the ruler\'s events at the band', () {
      expect(
          rulerPool(_fixture, 'mire', RulerBand.friend), ['ruler_mire_friend']);
      expect(rulerPool(_fixture, 'dominion', RulerBand.hostile),
          ['ruler_dominion_hostile']);
      expect(rulerPool(_fixture, '', RulerBand.neutral), isEmpty);
      expect(rulerPool(_fixture, 'giants', RulerBand.neutral), isEmpty);
      // The file's keys load onto the event.
      final event = _fixture['ruler_mire_hostile']!;
      expect((event.ruler, event.band, event.isRulers),
          ('mire', RulerBand.hostile, true));
      expect(_fixture['fen_mud']!.isRulers, isFalse);
    });
  });

  group('the draw', () {
    final rulers = rulerPool(_fixture, 'mire', RulerBand.neutral);

    test('one day in three is the ruler\'s, never twice in a crossing', () {
      var days = 0;
      var met = 0;
      for (var seed = 0; seed < 3000; seed++) {
        final drawn = drawCrossing(_fen, _fixture.keys,
            random: Random(seed), rulers: rulers);
        expect(drawn, hasLength(_fen.days), reason: 'seed $seed');
        final ruled = drawn.where((id) => id == 'ruler_mire_neutral').length;
        expect(ruled, lessThanOrEqualTo(1), reason: 'seed $seed');
        expect(
            drawn.where(
                (id) => id.startsWith('ruler_') && id != 'ruler_mire_neutral'),
            isEmpty);
        days += drawn.length;
        met += ruled;
      }
      // A day is the ruler's one time in three, until met: about 70% of
      // three-day crossings meet it once.
      final crossings = met / 3000;
      expect(crossings, inInclusiveRange(0.62, 0.78));
      expect(days, 3 * 3000);
    });

    test('a route that meets no ruler draws as it always did', () {
      const plain = LandRoute(
          id: 'plain',
          name: 'Plain',
          from: 'a',
          to: 'b',
          days: 3,
          events: {'fen_mud': 2, 'fen_lantern': 1});
      for (var seed = 0; seed < 200; seed++) {
        expect(
            drawCrossing(plain, _fixture.keys,
                random: Random(seed), rulers: rulers),
            drawCrossing(plain, _fixture.keys, random: Random(seed)));
      }
    });

    test('events not on file are skipped; with none, only the ruler', () {
      // fen_child is not in the fixture: never drawn.
      for (var seed = 0; seed < 300; seed++) {
        final drawn = drawCrossing(_fen, _fixture.keys,
            random: Random(seed), rulers: rulers);
        expect(drawn, isNot(contains('fen_child')));
      }
      // None of the route's events on file: the ruler, once, or nothing.
      const missing = {'ruler_mire_neutral'};
      expect(drawCrossing(_fen, missing, random: Random(1), rulers: rulers),
          ['ruler_mire_neutral']);
      expect(
          drawCrossing(_fen, const <String>{},
              random: Random(1), rulers: rulers),
          isEmpty);
      // A ruler's event the file lacks is no event.
      expect(
          drawCrossing(_fen, const {'fen_mud'},
              random: Random(2), rulers: const ['ruler_vigil_hostile']),
          ['fen_mud', 'fen_mud', 'fen_mud']);
      // And a headless crossing over a route with nothing on file arrives.
      final result = resolveCrossing(_fen, const {},
          health: 50,
          maxHealth: 100,
          gold: 0,
          modifierFor: (_) => 0,
          random: Random(3),
          rulers: rulers);
      expect((result.arrived, result.health), (true, 50));
      expect(result.events, isEmpty);
    });

    test('chapter 7\'s cliffs stay mild, its ruler met or not', () {
      // Narrative's draft numbers for the first two cliff events, and the
      // Dominion's hostile toll (its worst band).
      final cliffEvents = landEventsFrom({
        'cliff_salt_wind': {
          'name': 'Salt wind',
          'choices': [
            {
              'id': 'edge',
              'check': 'dexterity',
              'dc': 12,
              'success': {'healthPct': -2},
              'fail': {'healthPct': -14},
            },
            {
              'id': 'inland',
              'outcome': {'healthPct': -2, 'days': 1},
            },
          ],
        },
        'cliff_tide_stair': {
          'name': 'Tide stair',
          'choices': [
            {
              'id': 'run',
              'check': 'constitution',
              'dc': 12,
              'success': {'healthPct': -3},
              'fail': {'healthPct': -12},
            },
            {
              'id': 'wait',
              'outcome': {'healthPct': -1, 'days': 1},
            },
          ],
        },
        'ruler_dominion_hostile': {
          'name': 'Writ toll',
          'ruler': 'dominion',
          'band': 'hostile',
          'choices': [
            {
              'id': 'pay',
              'outcome': {'gold': -30},
            },
            {
              'id': 'cells',
              'outcome': {'healthPct': -4, 'days': 1},
            },
          ],
        },
      });
      // With the wrecker's lamp and the gulls as Narrative wrote them
      // (wave 17).
      final all = {
        ...landEventsFrom(_json('assets/gamedata/land_events.json')),
        ...cliffEvents,
      };
      final cliffs = landRouteFor(routes, 'lantern_cliffs')!;
      final hostile = rulerPool(cliffEvents, 'dominion', RulerBand.hostile);
      expect(hostile, ['ruler_dominion_hostile']);
      var worst = 0;
      for (var seed = 0; seed < 500; seed++) {
        final result = resolveCrossing(cliffs, all,
            health: 100,
            maxHealth: 100,
            gold: 0,
            modifierFor: (_) => 2,
            random: Random(seed),
            chapter: 7,
            rulers: hostile);
        expect(result.arrived, isTrue, reason: 'seed $seed');
        worst = max(worst, 100 - result.health);
      }
      expect(worst, lessThanOrEqualTo(8));
    });
  });
}
