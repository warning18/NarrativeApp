// Detour and expedition lines that fit their place (place_pools.dart): a
// line comes from the most specific pool up the place's chain, then its
// biome, then its theme's pool, then the theme's Dart lines; mood and
// chapter narrow a pool; an empty file changes nothing. And, once
// Narrative's detours.json exists, every key is a real place, biome or
// theme and every line has both languages.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_themes.dart';
import 'package:narrative_data_app/data/place_pools.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final geo = Geography.parse(
    geography: _json('assets/gamedata/geography.json'),
    biomes: _json('assets/gamedata/biomes.json'),
  );

  // A district of Saltmouth, its town, and a biome.
  final pools = PlacePools.fromJson({
    'version': 1,
    'places': {
      'saltmouth_card_row': {
        'shop': [
          {'en': 'Card-row stall.', 'fr': 'Étal des cartes.'},
        ],
      },
      'saltmouth': {
        'shop': [
          {'en': 'Saltmouth stall.', 'fr': 'Étal de Saltmouth.'},
        ],
        'enemy': [
          {'en': 'A tense knife.', 'fr': 'Un couteau.', 'mood': 'tense'},
          {'en': 'Frost knife.', 'fr': 'Couteau de givre.', 'minChapter': 5},
        ],
      },
    },
    'biomes': {
      'arid_coast': {
        'rest': [
          {'en': 'Shade of a salt-pan.', 'fr': ''},
        ],
      },
    },
    'themes': {
      'saltRoads': {
        'generic': [
          {'en': 'A salt road.', 'fr': 'Une route du sel.'},
        ],
      },
    },
  });

  test('the chain runs from the place up, the most specific first', () {
    final chain = placeChainOf(geo, 'saltmouth_card_row');
    expect(chain.first, 'saltmouth_card_row');
    expect(chain, contains('saltmouth'));
    expect(chain.indexOf('saltmouth'), greaterThan(0));
    expect(placeBiomeOf(geo, 'saltmouth_card_row'), isNotNull);
    expect(placeChainOf(geo, null), isEmpty);
    expect(placeChainOf(geo, 'nowhere'), ['nowhere']);
  });

  test('each kind comes from the nearest pool that has it', () {
    final chain = placeChainOf(geo, 'saltmouth_card_row');
    final biome = placeBiomeOf(geo, 'saltmouth_card_row');
    final flavor = pools.flavorAt(
        chain: chain, biomeId: biome, theme: MapTheme.saltRoads, chapter: 2);
    // The district's own stall, not the town's.
    expect(flavor.shop, ['Card-row stall.']);
    expect(flavor.shopFr, ['Étal des cartes.']);
    // The theme's JSON pool for the generic lines.
    expect(flavor.generic, ['A salt road.']);
    // Nothing in the file for treasure: the theme's Dart lines.
    expect(flavor.treasure, flavorFor(MapTheme.saltRoads).treasure);
    // A biome line without French reads its English in French.
    if (biome == 'arid_coast') {
      expect(flavor.rest, ['Shade of a salt-pan.']);
      expect(flavor.restFr, ['Shade of a salt-pan.']);
    }
  });

  test('mood and chapter narrow a pool; none fitting falls through', () {
    final chain = placeChainOf(geo, 'saltmouth');
    final calm2 = pools.linesFor('enemy', chain: chain, chapter: 2);
    expect(calm2, isEmpty, reason: 'tense only, and frost from chapter 5');
    final tense2 =
        pools.linesFor('enemy', chain: chain, chapter: 2, mood: 'action');
    expect(tense2.map((l) => l.en), ['A tense knife.']);
    final calm5 = pools.linesFor('enemy', chain: chain, chapter: 5);
    expect(calm5.map((l) => l.en), ['Frost knife.']);
  });

  test('an empty file is exactly the theme', () {
    for (final theme in MapTheme.values) {
      expect(
          identical(PlacePools.empty.flavorAt(theme: theme), flavorFor(theme)),
          isTrue);
    }
  });

  test('detours.json, once written, names real places in both languages', () {
    final file = File('assets/gamedata/detours.json');
    if (!file.existsSync()) return;
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final places = (raw['places'] as Map?) ?? const {};
    final biomes = (raw['biomes'] as Map?) ?? const {};
    final themes = (raw['themes'] as Map?) ?? const {};
    for (final key in places.keys) {
      expect(geo.places.containsKey(key), isTrue, reason: 'place $key');
    }
    for (final key in biomes.keys) {
      expect(geo.biomes.containsKey(key), isTrue, reason: 'biome $key');
    }
    for (final key in themes.keys) {
      expect(MapTheme.values.map((t) => t.name), contains(key),
          reason: 'theme $key');
    }
    for (final (scope, group) in [
      ('places', places),
      ('biomes', biomes),
      ('themes', themes),
    ]) {
      for (final MapEntry(:key, :value) in group.entries) {
        for (final MapEntry(key: kind, value: lines)
            in (value as Map).entries) {
          expect(placeLineKinds, contains(kind), reason: '$scope.$key.$kind');
          for (final line in lines as List) {
            final m = line as Map;
            expect(m['en']?.toString() ?? '', isNotEmpty,
                reason: '$scope.$key.$kind');
            expect(m['fr']?.toString() ?? '', isNotEmpty,
                reason: '$scope.$key.$kind: ${m['en']}');
            expect([null, 'calm', 'tense'], contains(m['mood']),
                reason: '$scope.$key.$kind: ${m['en']}');
          }
        }
      }
    }
  });
}
