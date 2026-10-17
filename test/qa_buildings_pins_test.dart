// QA: the places a scene stands in, and the town pins on a city plan.
//   - A scene's `location` is a place of geography.json. When it is a building
//     (level `building`), the building has a kind the Journey can lay out
//     (one of geoBuildingKinds, so a RoomKind of its own, not the plain
//     fallback), a name, and every `spot` the scene and its choices name is a
//     spot of that building's plan (RoomPlan.ofBuilding).
//   - A town's service pins (city_plans.json `services`, wave 14) stand inside
//     the plan's 1000 x 1000 square, in a district of the plan, with a kind
//     and an id of their own.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/room_plan.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final geography = _json('assets/gamedata/geography.json');
  final story = _json('assets/Cleaned_Narrative_DAG.json');

  Map<String, dynamic>? place(String id) =>
      geography[id] is Map<String, dynamic>
          ? geography[id] as Map<String, dynamic>
          : null;

  test('every scene that names a location names a place of the geography', () {
    final found = <String>[];
    for (final node in story.entries) {
      final location = (node.value as Map)['location']?.toString() ?? '';
      if (location.isEmpty) continue;
      if (place(location) == null) {
        found.add('scene ${node.key}: location "$location" is not a place');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('every building a scene stands in has a kind with a plan', () {
    final found = <String>[];
    final seen = <String>{};
    for (final node in story.entries) {
      final id = (node.value as Map)['location']?.toString() ?? '';
      final record = place(id);
      if (record == null || record['level'] != 'building') continue;
      if (!seen.add(id)) continue;
      final kind = record['kind']?.toString() ?? '';
      if (!geoBuildingKinds.contains(kind)) {
        found.add('building $id (scene ${node.key}): kind "$kind" is not one '
            'of geoBuildingKinds');
      } else if (RoomKind.of(kind) == RoomKind.plain) {
        found.add('building $id: kind "$kind" has no RoomKind');
      }
      if ((record['name']?.toString() ?? '').isEmpty) {
        found.add('building $id has no name');
      }
      if ((record['name_fr']?.toString() ?? '').isEmpty) {
        found.add('building $id has no French name');
      }
    }
    expect(seen, isNotEmpty);
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('every spot a scene or its choices name is a spot of its building', () {
    final found = <String>[];
    final plans = <String, RoomPlan>{};
    for (final entry in story.entries) {
      final node = entry.value as Map<String, dynamic>;
      final id = node['location']?.toString() ?? '';
      final record = place(id);
      if (record == null || record['level'] != 'building') continue;
      final plan = plans.putIfAbsent(
          id,
          () => RoomPlan.ofBuilding(
              id, record['kind']?.toString() ?? '', record['name'].toString()));
      void check(String where, Object? spot) {
        final name = spot?.toString() ?? '';
        if (name.isNotEmpty && !plan.has(name)) {
          found.add('scene ${entry.key} $where: spot "$name" is not a spot '
              'of $id (${plan.anchors.keys.join(', ')})');
        }
      }

      check('', node['spot']);
      for (final (i, choice)
          in ((node['choices'] as List?) ?? const []).indexed) {
        check('choice $i', (choice as Map)['spot']);
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the town service pins stand inside their plan, in a district of it',
      () {
    final plans = _json('assets/gamedata/city_plans.json');
    final found = <String>[];
    var pins = 0;
    for (final plan in plans.entries) {
      final record = plan.value as Map<String, dynamic>;
      final districts = ((record['districts'] as Map?) ?? const {}).keys;
      final ids = <String>{};
      for (final pin in (record['services'] as List?) ?? const []) {
        pins++;
        final p = pin as Map<String, dynamic>;
        final id = p['id']?.toString() ?? '';
        final where = '${plan.key}: pin "$id"';
        if (id.isEmpty || !ids.add(id)) found.add('$where: no id, or twice');
        if ((p['kind']?.toString() ?? '').isEmpty) found.add('$where: no kind');
        final at = p['at'];
        if (at is! List ||
            at.length != 2 ||
            at.any((v) => v is! num || v < 0 || v > 1000)) {
          found.add('$where: at $at is not inside the 1000 x 1000 square');
        }
        final district = p['district']?.toString() ?? '';
        if (district.isNotEmpty && !districts.contains(district)) {
          found.add('$where: district "$district" is not one of the plan\'s');
        }
      }
    }
    // The pins came with wave 14; on a tree without them there is nothing
    // to check yet.
    if (pins == 0) {
      markTestSkipped('no town service pins in city_plans.json yet');
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
