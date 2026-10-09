// The world's geography as data (v1.197): every story node, expedition
// zone and enemy has a place in assets/gamedata/geography.json (continent,
// country, zone, location, district) or a home among the biomes of
// assets/gamedata/biomes.json, and every landmark of the world map has
// exactly one home in it. Read as plain JSON, so it does not depend on the
// engine's own classes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/world_map.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

const _levels = [
  'continent',
  'country',
  'zone',
  'location',
  'district',
  'building',
];
const _kinds = {'city', 'town', 'village', 'camp', 'site', 'wild', 'sea'};
const _buildingKinds = {
  'den', 'tavern', 'inn', 'house', 'hall', 'keep', 'temple', 'shop', //
  'warehouse', 'cellar', 'cave', 'tower',
};
const _patterns = {
  'fields', 'dunes', 'salt_flats', 'waves', 'ash', 'terraces', //
  'cliffs', 'reeds', 'snow', 'glass',
};
const _biomeIds = {
  'temperate', 'desert', 'arid_coast', 'sea', 'ashlands', 'volcanic', //
  'sea_cliffs', 'fen', 'frost', 'tear',
};

/// French typography: a non-breaking space (or a narrow one) before
/// ; : ! ? and inside « ».
String? _frenchTypo(String text) {
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    final before = i > 0 ? text[i - 1] : '';
    if (';:!?»'.contains(c) && before != ' ' && before != ' ') {
      return 'no non-breaking space before "$c" at $i';
    }
    if (c == '«') {
      final after = i + 1 < text.length ? text[i + 1] : '';
      if (after != ' ' && after != ' ') {
        return 'no non-breaking space after "«" at $i';
      }
    }
  }
  return null;
}

void main() {
  final geo = _json('assets/gamedata/geography.json');
  final biomes = _json('assets/gamedata/biomes.json');
  final story = _json('assets/Cleaned_Narrative_DAG.json');
  final zones = _json('assets/gamedata/zones.json');
  final enemies = _json('assets/gamedata/enemies.json');
  final factions = _json('assets/gamedata/factions.json');

  Map<String, dynamic> place(String id) => geo[id] as Map<String, dynamic>;

  List<String> landmarksOf(Map<String, dynamic> record) => [
        if (record['landmark'] is String &&
            (record['landmark'] as String).isNotEmpty)
          record['landmark'] as String,
        ...((record['landmarks'] as List?) ?? const []).cast<String>(),
      ];

  /// [id] and every place above it, most specific first.
  List<String> pathOf(String id) {
    final path = <String>[];
    var at = id;
    while (at.isNotEmpty && geo.containsKey(at) && !path.contains(at)) {
      path.add(at);
      at = place(at)['parent'] as String? ?? '';
    }
    return path;
  }

  bool isPlaceToStand(String id) =>
      geo.containsKey(id) &&
      const {'location', 'district', 'building'}.contains(place(id)['level']);

  group('geography.json', () {
    test('each place sits one level under its parent, up to a continent', () {
      expect(geo, isNotEmpty);
      for (final MapEntry(:key, :value) in geo.entries) {
        final record = value as Map<String, dynamic>;
        final level = _levels.indexOf(record['level'] as String? ?? '');
        expect(level, isNot(-1), reason: '$key: level ${record['level']}');
        final parent = record['parent'] as String?;
        if (level == 0) {
          expect(parent, '', reason: '$key: a continent has no parent');
          continue;
        }
        expect(geo.containsKey(parent), isTrue,
            reason: '$key: parent "$parent"');
        expect(_levels.indexOf(place(parent!)['level'] as String), level - 1,
            reason: '$key: parent "$parent" is not one level up');
        final path = pathOf(key);
        expect(path.length, level + 1, reason: '$key: $path');
        expect(place(path.last)['level'], 'continent', reason: key);
      }
    });

    test(
        'a biome only on zones, a ruler only on countries, a kind only on '
        'locations', () {
      for (final MapEntry(:key, :value) in geo.entries) {
        final record = value as Map<String, dynamic>;
        final level = record['level'];
        expect(record.containsKey('biome'), level == 'zone', reason: key);
        expect(record.containsKey('ruler'), level == 'country', reason: key);
        expect(record.containsKey('kind'),
            level == 'location' || level == 'building',
            reason: key);
        if (level == 'zone') {
          expect(biomes.containsKey(record['biome']), isTrue,
              reason: '$key: biome ${record['biome']}');
        }
        if (level == 'country') {
          final ruler = record['ruler'] as String;
          expect(ruler.isEmpty || factions.containsKey(ruler), isTrue,
              reason: '$key: ruler $ruler');
        }
        if (level == 'location') {
          expect(_kinds, contains(record['kind']), reason: key);
        }
        if (level == 'building') {
          expect(_buildingKinds, contains(record['kind']), reason: key);
        }
      }
    });

    test('every landmark of the world map has exactly one home', () {
      final ids = worldMapLandmarks.map((l) => l.id).toSet();
      final homes = <String, List<String>>{};
      for (final MapEntry(:key, :value) in geo.entries) {
        for (final landmark in landmarksOf(value as Map<String, dynamic>)) {
          expect(ids, contains(landmark), reason: '$key: $landmark');
          (homes[landmark] ??= []).add(key);
        }
      }
      for (final id in ids) {
        expect(homes[id], hasLength(1), reason: '$id: ${homes[id]}');
      }
    });

    test('names and blurbs in both languages, with French typography', () {
      for (final MapEntry(:key, :value) in geo.entries) {
        final record = value as Map<String, dynamic>;
        for (final field in ['name', 'name_fr', 'blurb', 'blurb_fr']) {
          final text = record[field] as String? ?? '';
          expect(text.trim(), isNotEmpty, reason: '$key.$field');
          if (field.endsWith('_fr')) {
            expect(_frenchTypo(text), isNull, reason: '$key.$field');
            expect(text, isNot(contains("'")), reason: '$key.$field');
          }
        }
      }
    });
  });

  group('places in the story', () {
    test('every node stands at a location or a district', () {
      for (final MapEntry(:key, :value) in story.entries) {
        final location = (value as Map<String, dynamic>)['location'];
        expect(location, isA<String>(), reason: '$key has no location');
        expect(isPlaceToStand(location as String), isTrue,
            reason: '$key: "$location"');
      }
    });

    test('a landmark\'s scenes happen at its home or somewhere inside it', () {
      final homeOf = <String, String>{
        for (final MapEntry(:key, :value) in geo.entries)
          for (final landmark in landmarksOf(value as Map<String, dynamic>))
            landmark: key,
      };
      for (final landmark in worldMapLandmarks) {
        final home = homeOf[landmark.id];
        expect(home, isNotNull, reason: landmark.id);
        for (final scene in landmark.scenes) {
          final location =
              (story[scene] as Map<String, dynamic>)['location'] as String;
          expect(pathOf(location), contains(home),
              reason: '${landmark.id}: $scene stands at $location');
        }
      }
    });

    test('the ledger is read where the Court let the party out', () {
      // 6001 and 6002 follow the flight out of the Hollow Court without
      // a break, and name the Black Reliquary as three days off (v1.201.2):
      // placed there, the chase was scored as a journey into the frost.
      for (final scene in ['6001', '6002']) {
        expect(
            (story[scene] as Map<String, dynamic>)['location'], 'hollow_court',
            reason: scene);
      }
      // The gate guard is fought below the gate, before the market.
      expect((story['2021'] as Map<String, dynamic>)['location'],
          'saltmouth_landward_gate');
    });

    test('every expedition zone happens at a location or a district', () {
      for (final MapEntry(:key, :value) in zones.entries) {
        final location = (value as Map<String, dynamic>)['location'];
        expect(location, isA<String>(), reason: key);
        expect(isPlaceToStand(location as String), isTrue,
            reason: '$key: "$location"');
      }
    });

    test('every enemy lists the biomes it lives in', () {
      for (final MapEntry(:key, :value) in enemies.entries) {
        final homes = (value as Map<String, dynamic>)['biomes'];
        expect(homes, isA<List<dynamic>>(), reason: key);
        for (final biome in homes as List) {
          expect(biomes.containsKey(biome), isTrue, reason: '$key: $biome');
        }
      }
    });
  });

  group('biomes.json', () {
    test('the ten biomes, each with its fauna, flora, weather and hazards', () {
      expect(biomes.keys.toSet(), _biomeIds);
      final hazardIds = <String>{};
      for (final MapEntry(:key, :value) in biomes.entries) {
        final biome = value as Map<String, dynamic>;
        expect(biome['fauna'], hasLength(6), reason: '$key fauna');
        expect(biome['flora'], hasLength(6), reason: '$key flora');
        expect(biome['weather'], hasLength(3), reason: '$key weather');
        expect(biome['hazards'], hasLength(2), reason: '$key hazards');
        expect(_patterns, contains(biome['pattern']), reason: key);
        final palette = biome['palette'] as Map<String, dynamic>;
        for (final colour in ['ground', 'detail', 'accent', 'water']) {
          expect(palette[colour], matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
              reason: '$key palette $colour');
        }
        for (final hazard
            in (biome['hazards'] as List).cast<Map<String, dynamic>>()) {
          expect(hazardIds.add(hazard['id'] as String), isTrue,
              reason: '$key: hazard ${hazard['id']} twice');
        }
      }
    });

    test('every text in both languages, with French typography', () {
      void check(
          String where, Map<String, dynamic> entry, List<String> fields) {
        for (final field in fields) {
          for (final name in [field, '${field}_fr']) {
            final text = entry[name] as String? ?? '';
            expect(text.trim(), isNotEmpty, reason: '$where.$name');
            if (name.endsWith('_fr')) {
              expect(_frenchTypo(text), isNull, reason: '$where.$name');
              expect(text, isNot(contains("'")), reason: '$where.$name');
            }
          }
        }
      }

      for (final MapEntry(:key, :value) in biomes.entries) {
        final biome = value as Map<String, dynamic>;
        check(key, biome, ['name', 'blurb']);
        for (final list in ['fauna', 'flora']) {
          for (final entry
              in (biome[list] as List).cast<Map<String, dynamic>>()) {
            check('$key.$list.${entry['name']}', entry, ['name', 'note']);
            expect((entry['note'] as String).length, lessThanOrEqualTo(90),
                reason: '$key.$list.${entry['name']}: a note is one line');
          }
        }
        for (final entry
            in (biome['weather'] as List).cast<Map<String, dynamic>>()) {
          check('$key.weather', entry, ['name']);
        }
        for (final entry
            in (biome['hazards'] as List).cast<Map<String, dynamic>>()) {
          check('$key.${entry['id']}', entry, ['name', 'text', 'push', 'wait']);
        }
      }
    });
  });
}
