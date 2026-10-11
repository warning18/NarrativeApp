// What a place is like (v1.242): danger, light, controller, tags and the
// watches a walk takes -- how a place inherits them from the places above it,
// what the rules do with them (road events, the light a fight is fought in,
// the anomalies a kind of place favours, a shop's faction) and that the
// world's real geography.json writes only values the rules know.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/place_traits.dart';
import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/widgets/fight_backdrop.dart';

import 'geography_test.dart' show biomesFixture, geoFixture, node;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The fixture world with traits written on a few places.
Geography _world() {
  final geo = geoFixture();
  void set(String id, Map<String, dynamic> traits) =>
      geo[id] = <String, dynamic>{...(geo[id] as Map), ...traits};
  set('vale', {
    'danger': 0,
    'light': 'dusk',
    'controller': 'dominion',
    'tags': ['wild'],
    'watches': 3,
  });
  set('alster', {
    'danger': 3,
    'tags': ['stronghold', 'ruin'],
    'watches': 4,
  });
  set('lower_town', {
    'light': 'dark',
    'controller': 'crows',
    'tags': ['market']
  });
  set('dunes', {'danger': '2', 'light': 'noon', 'watches': -2});
  return Geography.parse(geography: geo, biomes: biomesFixture());
}

void main() {
  group('a place inherits what the places above it say', () {
    final world = _world();

    test('danger: its own, else the nearest above, else the ordinary', () {
      expect(world.dangerOf('alster'), 3);
      expect(world.dangerOf('lower_town'), 3); // from Alster
      expect(world.dangerOf('stone_bridge'), 3);
      expect(world.dangerOf('vale'), 0);
      expect(world.dangerOf('old'), geoDefaultDanger); // none written
      expect(world.dangerOf('nowhere'), geoDefaultDanger);
      expect(world.dangerOf(null), geoDefaultDanger);
      // Text is read as a number, and a list of places never leaves 0..3.
      expect(world.dangerOf('dunes'), 2);
      expect(world.dangerOf('wells'), 2);
    });

    test('light: its own, else the nearest above, else the day\'s', () {
      expect(world.lightOf('lower_town'), 'dark');
      expect(world.lightOf('alster'), 'dusk'); // Alster says none: its vale's
      expect(world.lightOf('stone_bridge'), 'dusk');
      expect(world.lightOf('old'), '');
      // A light the rules do not know is no light.
      expect(world.lightOf('dunes'), '');
    });

    test('controller falls back to the ruler; heldBy does not', () {
      expect(world.controllerOf('lower_town'), 'crows');
      expect(world.heldBy('lower_town'), 'crows');
      expect(world.controllerOf('alster'), 'dominion'); // the vale's
      expect(world.heldBy('alster'), 'dominion');
      // The Marches are ruled by the Dominion; the Waste by nobody.
      expect(world.controllerOf('marches'), 'dominion');
      expect(world.heldBy('marches'), '');
      expect(world.controllerOf('wells'), '');
      expect(world.heldBy('wells'), '');
    });

    test('tags are the place\'s own and every place above it', () {
      expect(
          world.tagsOf('lower_town'), {'market', 'stronghold', 'ruin', 'wild'});
      expect(world.tagsOf('stone_bridge'), {'stronghold', 'ruin', 'wild'});
      expect(world.tagsOf('vale'), {'wild'});
      expect(world.tagsOf('old'), isEmpty);
      expect(world.tagsOf(null), isEmpty);
    });

    test('watches: its own, else the nearest above, else the fallback', () {
      expect(world.watchesTo('alster', fallback: 2), 4);
      expect(world.watchesTo('lower_town', fallback: 2), 4);
      expect(world.watchesTo('vale', fallback: 2), 3);
      expect(world.watchesTo('old', fallback: 2), 2);
      expect(world.watchesTo(null, fallback: 2), 2);
      // A negative number says nothing.
      expect(world.watchesTo('dunes', fallback: 2), 2);
    });

    test('a scene walks to the watches of its place', () {
      expect(
          world.watchesToNode(node('x', location: 'lower_town'), fallback: 2),
          4);
      expect(world.watchesToNode(node('x', location: 'wells'), fallback: 2), 2);
      expect(world.watchesToNode(null, fallback: 2), 2);
    });
  });

  group('the rules read them', () {
    test('a dangerous place means busier roads and more anomalies', () {
      expect(dangerRoadFactor(0), lessThan(dangerRoadFactor(1)));
      expect(dangerRoadFactor(1), 1);
      expect(dangerRoadFactor(2), lessThan(dangerRoadFactor(3)));
      expect(dangerAnomalyFactor(0), lessThan(1));
      expect(dangerAnomalyFactor(1), 1);
      expect(dangerAnomalyFactor(3), greaterThan(dangerAnomalyFactor(2)));
      // Out of range numbers still answer.
      expect(dangerRoadFactor(-4), dangerRoadFactor(0));
      expect(dangerRoadFactor(9), dangerRoadFactor(3));
    });

    test('the light dims the backdrop by what is missing', () {
      expect(lightLevel(''), 1);
      expect(lightLevel('day'), 1);
      expect(lightLevel('dusk'), greaterThan(lightLevel('night')));
      expect(lightLevel('night'), greaterThan(lightLevel('dark')));
      expect(lightLevel('dark'), greaterThan(0));
      for (final light in geoLights) {
        expect(lightLevel(light), inInclusiveRange(0.0, 1.0));
      }
    });

    test('a shop\'s own faction wins; else the holder of the place', () {
      expect(shopFactionHere('tidekin', 'dominion'), 'tidekin');
      expect(shopFactionHere('', 'dominion'), 'dominion');
      expect(shopFactionHere('', ''), '');
    });

    test('night and the dark make a condition likelier, and Dark likelier', () {
      int count({String light = ''}) {
        var any = 0;
        for (var seed = 0; seed < 2000; seed++) {
          if (rollBattlefieldCondition(
                  enemyCount: 1, random: Random(seed), light: light) !=
              null) {
            any++;
          }
        }
        return any;
      }

      int dark(String light) {
        var n = 0;
        for (var seed = 0; seed < 4000; seed++) {
          final c = rollBattlefieldCondition(
              enemyCount: 1, random: Random(seed), chance: 1, light: light);
          if (c == BattlefieldCondition.dark) n++;
        }
        return n;
      }

      expect(count(light: 'night'), greaterThan(count()));
      expect(count(light: 'dark'), greaterThan(count(light: 'night')));
      // Day and dusk leave the odds as they were.
      expect(count(light: 'day'), count());
      expect(count(light: 'dusk'), count());
      expect(dark('night'), greaterThan(dark('')));
      expect(dark('dark'), greaterThan(dark('night')));
    });

    test('a kind of place favours the anomalies that suit it', () {
      for (final anomaly in fieldAnomalies) {
        for (final tag in anomaly.favouredBy) {
          expect(geoPlaceTags, contains(tag), reason: '${anomaly.id}: $tag');
        }
      }
      final spring = fieldAnomalyById('wellspring')!;
      final stage = spring.stages.first;
      final plain = spring.weightUnder(stage, null);
      expect(plain, greaterThan(0));
      expect(spring.weightUnder(stage, null, tags: {'holy'}), plain * 3);
      expect(spring.weightUnder(stage, null, tags: {'market'}), plain);
    });

    test('a holy place meets its spring far oftener', () {
      int springs(Set<String> tags) {
        var n = 0;
        for (var seed = 0; seed < 3000; seed++) {
          final plan = pickFieldAnomaly(
              stage: FightStage.fields,
              sky: null,
              random: Random(seed),
              tags: tags);
          if (plan?.anomaly.id == 'wellspring') n++;
        }
        return n;
      }

      expect(springs({'holy'}), greaterThan(springs({})));
    });

    test('the chance of an anomaly follows the danger, up to a ceiling', () {
      int met(double factor) {
        var n = 0;
        for (var seed = 0; seed < 3000; seed++) {
          if (rollFieldAnomaly(
                  stage: FightStage.fields,
                  sky: null,
                  random: Random(seed),
                  chanceFactor: factor) !=
              null) {
            n++;
          }
        }
        return n;
      }

      expect(met(0.5), lessThan(met(1)));
      expect(met(1), lessThan(met(1.7)));
      // However dangerous, never more than seven fights in ten.
      expect(met(100), lessThan(3000 * 0.75));
    });

    test('roads to a dangerous place hold events oftener than to a safe one',
        () {
      final story = StoryData({
        for (final n in [
          node('a', location: 'wells'),
          node('safe', location: 'vale'),
          node('deadly', location: 'alster'),
        ])
          n.id: n,
      });
      final world = _world();
      int events(String to) {
        var n = 0;
        for (var at = 0; at < 1500; at++) {
          if (roadEventFor(
                story: story,
                fromNodeId: 'a',
                toNodeId: to,
                historyLength: at,
                chapter: 4,
                world: world,
              ) !=
              null) {
            n++;
          }
        }
        return n;
      }

      final safe = events('safe');
      final deadly = events('deadly');
      expect(deadly, greaterThan(safe), reason: '$deadly vs $safe');
    });
  });

  group('the backdrop dims with the light', () {
    test('paints at every light, on every stage', () {
      for (final stage in FightStage.values) {
        for (final light in [1.0, 0.75, 0.45, 0.15, 0.0]) {
          final recorder = ui.PictureRecorder();
          paintFightBackdrop(ui.Canvas(recorder), const ui.Size(360, 640),
              stage: stage,
              sky: WeatherKind.rain,
              anomalyId: null,
              t: 2,
              level: 0,
              light: light);
          recorder.endRecording().dispose();
        }
      }
    });
  });

  group('geography.json writes only what the rules know', () {
    final geo = _json('assets/gamedata/geography.json');
    final factions = _json('assets/gamedata/factions.json');

    Iterable<MapEntry<String, Map<String, dynamic>>> places() sync* {
      for (final MapEntry(:key, :value) in geo.entries) {
        if (value is Map<String, dynamic>) yield MapEntry(key, value);
      }
    }

    test('danger is 0 to 3', () {
      var written = 0;
      for (final MapEntry(:key, :value) in places()) {
        if (!value.containsKey('danger')) continue;
        written++;
        expect(value['danger'], isA<int>(), reason: key);
        expect(value['danger'], inInclusiveRange(0, geoMaxDanger), reason: key);
      }
      expect(written, greaterThan(10));
    });

    test('light is one of the lights', () {
      var written = 0;
      for (final MapEntry(:key, :value) in places()) {
        if (!value.containsKey('light')) continue;
        written++;
        expect(geoLights, contains(value['light']), reason: key);
      }
      expect(written, greaterThan(3));
    });

    test('a controller is a faction of factions.json', () {
      var written = 0;
      for (final MapEntry(:key, :value) in places()) {
        if (!value.containsKey('controller')) continue;
        written++;
        expect(factions.keys, contains(value['controller']), reason: key);
      }
      expect(written, greaterThan(5));
    });

    test('tags are tags of the codex, with none twice', () {
      var written = 0;
      for (final MapEntry(:key, :value) in places()) {
        if (!value.containsKey('tags')) continue;
        written++;
        final tags = (value['tags'] as List).cast<String>();
        expect(geoPlaceTags, containsAll(tags), reason: key);
        expect(tags.toSet(), hasLength(tags.length), reason: key);
      }
      expect(written, greaterThan(10));
    });

    test('watches are a whole number from 1 to 6', () {
      var written = 0;
      for (final MapEntry(:key, :value) in places()) {
        if (!value.containsKey('watches')) continue;
        written++;
        expect(value['watches'], isA<int>(), reason: key);
        expect(value['watches'], inInclusiveRange(1, 6), reason: key);
      }
      expect(written, greaterThan(3));
    });

    test('the parsed world gives a dark, a safe and a held place', () {
      final world = Geography.parse(
          geography: geo, biomes: _json('assets/gamedata/biomes.json'));
      expect(world.dangerOf('alster_black_hold'), 3);
      expect(world.lightOf('alster_black_hold'), 'dark');
      expect(world.controllerOf('alster_black_hold'), 'dominion');
      expect(world.tagsOf('alster_black_hold'), contains('underground'));
      expect(world.dangerOf('highhearth'), 0);
      expect(world.watchesTo('spire_of_judgment', fallback: 2), 4);
    });
  });
}
