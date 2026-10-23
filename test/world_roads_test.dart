// The world's fixed roads (v1.246): every landmark is on a road, the roads
// lead everywhere, and every branch of the story that moves the party from
// one landmark to another follows a road, so the map can walk it there.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final ids = {for (final l in worldMapLandmarks) l.id};

  test('roads and stops have unique ids and join real landmarks', () {
    expect({for (final r in worldRoads) r.id}.length, worldRoads.length);
    final stops = [for (final r in worldRoads) ...r.stops];
    expect({for (final s in stops) s.id}.length, stops.length,
        reason: 'a stop belongs to one road only');
    for (final road in worldRoads) {
      expect(ids, contains(road.a), reason: road.id);
      expect(ids, contains(road.b), reason: road.id);
      expect(road.a, isNot(road.b), reason: road.id);
      expect(road.stops, isNotEmpty, reason: '${road.id} passes nothing');
    }
    // One road between two landmarks.
    final pairs = [
      for (final r in worldRoads) ([r.a, r.b]..sort()).join('|'),
    ];
    expect(pairs.toSet().length, pairs.length);
  });

  test('every stop is named in both languages, with French spacing', () {
    for (final stop in [for (final r in worldRoads) ...r.stops]) {
      expect(stop.nameEn.trim(), isNotEmpty, reason: stop.id);
      expect(stop.nameFr.trim(), isNotEmpty, reason: stop.id);
      expect(RegExp(r'[^ ][;:!?]').hasMatch(stop.nameFr), isFalse,
          reason: '${stop.id}: a non-breaking space before ; : ! ?');
    }
  });

  test('a road that touches the sea is sailed', () {
    final atSea = {
      for (final l in worldMapLandmarks)
        if (l.atSea) l.id,
    };
    for (final road in worldRoads) {
      if (atSea.contains(road.a) || atSea.contains(road.b)) {
        expect(road.kind, RoadKind.sea, reason: road.id);
      }
    }
  });

  test('every landmark leads to every other along the roads', () {
    for (final a in ids) {
      expect(roadsAt(a), isNotEmpty, reason: '$a is on no road');
      for (final b in ids) {
        expect(roadRoute(a, b), isNotNull, reason: 'no way from $a to $b');
      }
    }
  });

  test('a route walks its roads and names the stops in order', () {
    final route = roadRoute('alster', 'wells')!;
    // Alster - the wreck - the sleeper's face - the White Wells: the sea
    // road out of Alster, then the Dune Cairn and the Dry Wadi.
    expect(route.places, ['alster', 'crash', 'sleeper', 'wells']);
    expect(route.stops.last.id, 'dry_wadi');
    // The way back meets the same stops the other way round.
    final back = roadRoute('wells', 'alster')!;
    expect([for (final s in back.stops) s.id],
        [for (final s in route.stops.reversed) s.id]);
    expect(roadRoute('camp', 'camp')!.isEmpty, isTrue);
    // The longer road with two stops is read from either end.
    final up = roadBetween('alster', 'crash')!;
    expect([for (final s in up.stopsFrom('alster')) s.id],
        ['harbour_chain', 'painted_sails']);
    expect([for (final s in up.stopsFrom('crash')) s.id],
        ['painted_sails', 'harbour_chain']);
  });

  test('every branch of the story between two landmarks follows a road', () {
    final raw =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final nodes = {
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    final off = <String>{};
    for (final node in nodes.values) {
      final from = landmarkOfScene(node.id);
      if (from == null) continue;
      for (final choice in node.choices) {
        for (final next in [
          choice.nextId,
          choice.failNextId,
          choice.loseNextId,
        ]) {
          final to = next == null ? null : landmarkOfScene(next);
          if (to == null || to.id == from.id) continue;
          if (roadBetween(from.id, to.id) == null) {
            off.add('${from.id} -> ${to.id} (${node.id} -> $next)');
          }
        }
      }
    }
    expect(off, isEmpty, reason: 'branches off the roads: $off');
  });
}
