// The world's places (v1.197): five levels from continent to district, a
// biome for each zone, a place for each scene, and what the story has
// found of them. Built on fixtures: the real geography.json and
// biomes.json are checked by geography_content_test.dart.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/gamedata/game_db_repository.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';
import 'package:narrative_data_app/utils/story_export.dart';

/// A small world: two continents, three countries, a city with two
/// districts, a village and a site, and the sea.
Map<String, dynamic> geoFixture() => {
      'old': {'level': 'continent', 'parent': '', 'name': 'The Old Land'},
      'seas': {
        'level': 'continent',
        'parent': '',
        'name': 'The Seas',
        'name_fr': 'les Mers'
      },
      'marches': {
        'level': 'country',
        'parent': 'old',
        'ruler': 'dominion',
        'biome': 'desert', // not a zone: no biome
        'name': 'The Marches',
        'name_fr': 'les Marches',
      },
      'waste': {
        'level': 'country',
        'parent': 'old',
        'ruler': '',
        'name': 'The Waste'
      },
      'narrow': {'level': 'country', 'parent': 'seas', 'name': 'Narrow Sea'},
      'vale': {
        'level': 'zone',
        'parent': 'marches',
        'biome': 'temperate',
        'ruler': 'dominion', // not a country: no ruler
        'name': 'The Vale',
      },
      'dunes': {
        'level': 'zone',
        'parent': 'waste',
        'biome': 'desert',
        'name': 'The Dunes'
      },
      'water': {
        'level': 'zone',
        'parent': 'narrow',
        'biome': 'sea',
        'name': 'Open Water'
      },
      'alster': {
        'level': 'location',
        'parent': 'vale',
        'kind': 'city',
        'name': 'Alster',
        'landmark': '',
      },
      'lower_town': {
        'level': 'district',
        'parent': 'alster',
        'kind': 'town', // not a location: no kind
        'name': 'The Lower Town',
        'name_fr': 'la Basse-Ville',
        'landmarks': ['beggar', 'alley'],
        'landmark': 'hovel',
      },
      'stone_bridge': {
        'level': 'district',
        'parent': 'alster',
        'name': 'The Stone Bridge',
        'landmark': 'bridge',
      },
      'wells': {
        'level': 'location',
        'parent': 'dunes',
        'kind': 'village',
        'name': 'The White Wells',
      },
      'wreck': {
        'level': 'location',
        'parent': 'dunes',
        'kind': 'site',
        'name': 'The Wreck',
      },
      'storm': {
        'level': 'location',
        'parent': 'water',
        'kind': 'sea',
        'name': 'The Storm',
        'landmark': 'storm',
      },
      // Not places: skipped.
      'planet': {'level': 'planet', 'parent': '', 'name': 'The World'},
      'broken': 'not a record',
    };

Map<String, dynamic> hazardJson(String id) => {
      'id': id,
      'name': id.toUpperCase(),
      'name_fr': '$id (fr)',
      'text': 'I met the $id.',
      'text_fr': 'Je rencontrai le $id.',
      'push': 'Push through the $id',
      'push_fr': 'Traverser',
      'wait': 'Wait out the $id',
      'wait_fr': 'Attendre',
    };

Map<String, dynamic> biomeJson(String name, String pattern,
        {List<String> hazards = const []}) =>
    {
      'name': name,
      'name_fr': '$name (fr)',
      'blurb': 'A $name land.',
      'fauna': [
        for (var i = 0; i < 6; i++)
          {'name': '$name beast $i', 'note': 'It lives.', 'note_fr': 'Il vit.'}
      ],
      'flora': [
        for (var i = 0; i < 6; i++) {'name': '$name plant $i'}
      ],
      'weather': [
        for (var i = 0; i < 3; i++) {'name': '$name sky $i'}
      ],
      'hazards': [for (final id in hazards) hazardJson(id)],
      'palette': {
        'ground': '#C9A86A',
        'detail': '#9C7B45',
        'accent': 'not a colour',
        'water': '#804F8FA8'
      },
      'pattern': pattern,
    };

Map<String, dynamic> biomesFixture() => {
      'temperate': biomeJson('Temperate', 'fields', hazards: ['flood', 'fog']),
      'desert': biomeJson('Desert', 'dunes', hazards: ['sandstorm', 'heat']),
      'sea': biomeJson('Sea', 'nowhere'),
    };

Geography fixture() =>
    Geography.parse(geography: geoFixture(), biomes: biomesFixture());

StoryNode node(String id, {String? location}) => StoryNode(
      id: id,
      description: 'Scene $id',
      choices: const [],
      location: location,
    );

StoryData storyFixture() => StoryData({
      for (final n in [
        node('0', location: ''), // the prologue: nowhere
        node('n_alley', location: 'lower_town'),
        node('260'), // no location: its landmark's place (the bridge)
        node('w1', location: 'wells'),
        node('lost', location: 'nope'), // unknown, and on no landmark
        node('at_sea', location: 'storm'),
      ])
        n.id: n,
    });

List<String> ids(List<GeoPlace> places) => [for (final p in places) p.id];

/// A table whose file is not there.
class _Missing extends GameDbRepository {
  _Missing(super.schema);

  @override
  Future<Map<String, dynamic>> loadRecords() async =>
      throw StateError('${schema.assetPath} is missing');
}

/// A table still loading until [complete] is called.
class _Pending extends GameDbRepository {
  _Pending(super.schema);

  final Completer<Map<String, dynamic>> _records = Completer();

  void complete(Map<String, dynamic> records) => _records.complete(records);

  @override
  Future<Map<String, dynamic>> loadRecords() => _records.future;
}

/// A table that holds [records].
class _Fixed extends GameDbRepository {
  _Fixed(super.schema, this.records);

  final Map<String, dynamic> records;

  @override
  Future<Map<String, dynamic>> loadRecords() async => records;
}

void main() {
  group('parsing', () {
    test('every level is read; what is not a place is left out', () {
      final geo = fixture();
      expect(geo.places.length, 14);
      expect(geo.place('planet'), isNull);
      expect(geo.place('broken'), isNull);
      expect(geo.place('alster')!.level, GeoLevel.location);
      expect(geo.place('lower_town')!.level, GeoLevel.district);
      expect(ids(geo.continents), ['old', 'seas']);
      expect(ids(geo.childrenOf('old')), ['marches', 'waste']);
      expect(ids(geo.childrenOf('alster')), ['lower_town', 'stone_bridge']);
    });

    test('each field only where its level has it', () {
      final geo = fixture();
      expect(geo.place('marches')!.ruler, 'dominion');
      expect(geo.place('marches')!.biome, isEmpty);
      expect(geo.place('vale')!.biome, 'temperate');
      expect(geo.place('vale')!.ruler, isEmpty);
      expect(geo.place('alster')!.kind, 'city');
      expect(geo.place('lower_town')!.kind, isEmpty);
      // landmark and landmarks are both read.
      expect(geo.place('lower_town')!.landmarks,
          unorderedEquals(['beggar', 'alley', 'hovel']));
    });

    test('names in either language, English when French is missing', () {
      final geo = fixture();
      expect(geo.place('lower_town')!.nameFor(true), 'la Basse-Ville');
      expect(geo.place('lower_town')!.nameFor(false), 'The Lower Town');
      expect(geo.place('alster')!.nameFor(true), 'Alster');
    });

    test('a biome: its lines, hazards, palette and pattern', () {
      final geo = fixture();
      final desert = geo.biomes['desert']!;
      expect(desert.fauna, hasLength(6));
      expect(desert.flora, hasLength(6));
      expect(desert.weather, hasLength(3));
      expect(desert.hazards.map((h) => h.id), ['sandstorm', 'heat']);
      expect(desert.hazards.first.pushFr, 'Traverser');
      expect(desert.fauna.first.noteFor(true), 'Il vit.');
      expect(desert.flora.first.noteFor(true), isEmpty);
      expect(desert.pattern, BiomePattern.dunes);
      expect(desert.palette.ground, const Color(0xFFC9A86A));
      expect(desert.palette.water, const Color(0x804F8FA8));
      // A colour it cannot read: the plain one.
      expect(desert.palette.accent, BiomePalette.plain.accent);
      // A pattern it does not know: fields.
      expect(geo.biomes['sea']!.pattern, BiomePattern.fields);
      expect(BiomePattern.named('salt_flats'), BiomePattern.saltFlats);
      expect(BiomePattern.values.map((p) => p.id), [
        'fields',
        'dunes',
        'salt_flats',
        'waves',
        'ash',
        'terraces',
        'cliffs',
        'reeds',
        'snow',
        'glass'
      ]);
    });

    test('the tables load into the geography; missing files make an empty one',
        () async {
      Future<Geography> load(
          GameDbRepository places, GameDbRepository biomes) async {
        final container = ProviderContainer(overrides: [
          gameDbRepositoryProvider(geographySchema).overrideWithValue(places),
          gameDbRepositoryProvider(biomesSchema).overrideWithValue(biomes),
        ]);
        addTearDown(container.dispose);
        await container
            .read(gameDbProvider(geographySchema).notifier)
            .whenLoaded();
        await container
            .read(gameDbProvider(biomesSchema).notifier)
            .whenLoaded();
        return container.read(geographyProvider);
      }

      final loaded = await load(_Fixed(geographySchema, geoFixture()),
          _Fixed(biomesSchema, biomesFixture()));
      expect(loaded.places.length, 14);
      expect(loaded.biomes.length, 3);
      final missing =
          await load(_Missing(geographySchema), _Missing(biomesSchema));
      expect(missing.isEmpty, isTrue);
      expect(missing.biomes, isEmpty);
      final half = await load(
          _Missing(geographySchema), _Fixed(biomesSchema, biomesFixture()));
      expect(half.isEmpty, isTrue);
      expect(half.biomes.length, 3);
      // Both files are Data tab collections.
      expect(gameDbSchemas, containsAll([geographySchema, biomesSchema]));
    });

    test('the places alone are not the world: empty until the biomes are in',
        () async {
      // A cold start loads the two files one after the other (v1.201.2):
      // between them the places are known and the biomes are not, and a
      // geography made of that would roll a road with no hazard on it.
      final biomes = _Pending(biomesSchema);
      final container = ProviderContainer(overrides: [
        gameDbRepositoryProvider(geographySchema)
            .overrideWithValue(_Fixed(geographySchema, geoFixture())),
        gameDbRepositoryProvider(biomesSchema).overrideWithValue(biomes),
      ]);
      addTearDown(container.dispose);
      await container
          .read(gameDbProvider(geographySchema).notifier)
          .whenLoaded();
      expect(container.read(geographyProvider).isEmpty, isTrue);
      biomes.complete(biomesFixture());
      await container.read(gameDbProvider(biomesSchema).notifier).whenLoaded();
      final loaded = container.read(geographyProvider);
      expect(loaded.places.length, 14);
      expect(loaded.biomes.length, 3);
    });

    test('no files make an empty geography that finds nothing', () {
      final geo = Geography.parse();
      expect(geo.isEmpty, isTrue);
      expect(Geography.empty.isEmpty, isTrue);
      expect(geo.pathOf('alster'), isEmpty);
      expect(geo.placeOfNode(node('260')), isNull);
      expect(geo.discoveredPlaces(['260'], storyFixture()), isEmpty);
      expect(geo.roadBiome(storyFixture(), 'n_alley', 'w1'), isNull);
    });
  });

  group('paths', () {
    test('from the continent down to the place', () {
      final geo = fixture();
      expect(ids(geo.pathOf('lower_town')),
          ['old', 'marches', 'vale', 'alster', 'lower_town']);
      expect(ids(geo.pathOf('old')), ['old']);
      expect(geo.pathOf('nope'), isEmpty);
      expect(geo.pathOf(null), isEmpty);
      expect(geo.zoneOf('lower_town')!.id, 'vale');
      expect(geo.countryOf('wells')!.id, 'waste');
      expect(geo.continentOf('storm')!.id, 'seas');
      expect(geo.locationOf('stone_bridge')!.id, 'alster');
      expect(geo.zoneOf('marches'), isNull);
      expect(geo.biomeOf('lower_town')!.id, 'temperate');
      expect(geo.biomeOf('wells')!.id, 'desert');
      expect(geo.biomeOf('old'), isNull);
    });

    test('a broken chain stops where it breaks; a loop ends', () {
      final geo = Geography.parse(geography: {
        'orphan': {'level': 'location', 'parent': 'missing', 'name': 'O'},
        'a': {'level': 'zone', 'parent': 'b', 'name': 'A'},
        'b': {'level': 'country', 'parent': 'a', 'name': 'B'},
      });
      expect(ids(geo.pathOf('orphan')), ['orphan']);
      expect(ids(geo.pathOf('a')), ['b', 'a']);
      expect(ids(geo.spots), ['orphan']);
    });

    test('the places a scene can happen at, branch by branch', () {
      expect(ids(fixture().spots),
          ['alster', 'lower_town', 'stone_bridge', 'wells', 'wreck', 'storm']);
    });
  });

  group('scenes', () {
    test('a scene happens at its location, else at its landmark\'s place', () {
      final geo = fixture();
      final story = storyFixture();
      expect(geo.placeOfNode(story.nodeFor('n_alley'))!.id, 'lower_town');
      expect(geo.placeOfNode(story.nodeFor('w1'))!.id, 'wells');
      // No location: scene 260 is on the Stone Bridge (world_map.dart).
      expect(geo.placeOfNode(story.nodeFor('260'))!.id, 'stone_bridge');
      // '' happens nowhere, even on a landmark (the prologue is at the
      // Blind Beggar).
      expect(geo.placeOfNode(story.nodeFor('0')), isNull);
      expect(geo.placeOfNode(story.nodeFor('lost')), isNull);
      expect(geo.placeOfNode(null), isNull);
      expect(geo.placeOfLandmark('beggar')!.id, 'lower_town');
      expect(geo.placeOfLandmark('hovel')!.id, 'lower_town');
      expect(geo.placeOfLandmark('nowhere'), isNull);
    });

    test('what is found: each place reached and every land above it', () {
      final geo = fixture();
      final story = storyFixture();
      expect(geo.discoveredPlaces(['0', 'n_alley', 'w1', 'w1'], story), {
        'old',
        'marches',
        'vale',
        'alster',
        'lower_town',
        'waste',
        'dunes',
        'wells',
      });
      expect(geo.discoveredPlaces(['0', 'lost'], story), isEmpty);
      // Not the Stone Bridge, nor the Wreck, before they are reached.
      final found = geo.discoveredPlaces(['n_alley', 'at_sea'], story);
      expect(found, isNot(contains('stone_bridge')));
      expect(found, containsAll(['seas', 'narrow', 'water', 'storm']));
    });

    test('a journey leaves the location; a walk between districts does not',
        () {
      final geo = fixture();
      final story = storyFixture();
      // The alley and the bridge are two districts of Alster: no journey.
      expect(geo.travelsBetween(story, 'n_alley', '260'), isFalse);
      expect(geo.travelsBetween(story, '260', 'n_alley'), isFalse);
      // Alster to the Wells, the Wells to the sea: a journey.
      expect(geo.travelsBetween(story, 'n_alley', 'w1'), isTrue);
      expect(geo.travelsBetween(story, 'w1', 'at_sea'), isTrue);
      expect(geo.travelsBetween(story, 'w1', 'w1'), isFalse);
      // A scene the world can't place goes by its landmark: 'lost' is
      // on none, 260 and 270 are on different ones, 100 and 105 the same.
      expect(geo.travelsBetween(story, 'w1', 'lost'), isFalse);
      expect(Geography.empty.travelsBetween(story, '260', '270'), isTrue);
      expect(Geography.empty.travelsBetween(story, '100', '105'), isFalse);
      // Scene 0 happens nowhere, so the bridge from it goes by landmark:
      // the Blind Beggar to the Stone Bridge.
      expect(geo.travelsBetween(story, '0', '260'), isTrue);
    });

    test(
        'a road runs through the land it leads to, else the one it leaves; '
        'out of a city, through the city\'s own land (v1.209)', () {
      final geo = fixture();
      final story = storyFixture();
      // Out of Alster (a city in the Vale) for the Wells: the Vale's
      // land, not the Dunes the road leads to.
      expect(geo.roadBiome(story, 'n_alley', 'w1')!.id, 'temperate');
      expect(geo.roadBiome(story, '260', 'w1')!.id, 'temperate');
      // From the Wells (a village): the land the road leads to.
      expect(geo.roadBiome(story, 'w1', 'n_alley')!.id, 'temperate');
      expect(geo.roadBiome(story, 'w1', 'at_sea')!.id, 'sea');
      // ...or the one it leaves when the way ahead is on no land.
      expect(geo.roadBiome(story, 'w1', 'lost')!.id, 'desert');
      expect(geo.roadBiome(story, 'n_alley', 'lost')!.id, 'temperate');
      // A walk between two districts of the city stays in its land.
      expect(geo.roadBiome(story, 'n_alley', '260')!.id, 'temperate');
      // Out of the city onto the water: a crossing, the sea's.
      expect(geo.roadBiome(story, 'n_alley', 'at_sea')!.id, 'sea');
      expect(geo.roadBiome(story, '0', 'lost'), isNull);
      // Nowhere to the Wells: the Dunes.
      expect(geo.roadBiome(story, '0', 'w1')!.id, 'desert');
    });
  });

  group('a scene\'s place in the story file', () {
    test('read, written back, and kept as written', () {
      final placed = StoryNode.fromJson(
          'a', const {'description': 'd', 'location': 'wells', 'choices': []});
      expect(placed.location, 'wells');
      expect(placed.toJson()['location'], 'wells');
      // Written where the story file keeps it: after the taxonomy.
      final keys = StoryNode.fromJson('t', const {
        'description': 'd',
        'context_taxonomy': {'ui_theme': 'docks'},
        'location': 'wells',
        'automations': {'script_trigger': 's'},
        'choices': [],
      }).toJson().keys.toList();
      expect(keys.indexOf('location'), keys.indexOf('context_taxonomy') + 1);
      final nowhere = StoryNode.fromJson(
          'b', const {'description': 'd', 'location': '', 'choices': []});
      expect(nowhere.location, '');
      expect(nowhere.toJson()['location'], '');
      final unsaid =
          StoryNode.fromJson('c', const {'description': 'd', 'choices': []});
      expect(unsaid.location, isNull);
      expect(unsaid.toJson().containsKey('location'), isFalse);
    });

    test('the editor\'s field: typed, emptied, untouched', () {
      expect(locationFromEditorText(' wells ', null), 'wells');
      expect(locationFromEditorText('', 'wells'), '');
      expect(locationFromEditorText('  ', ''), '');
      expect(locationFromEditorText('', null), isNull);
    });

    test('the light export says where each scene happens', () {
      final export =
          jsonDecode(storyLightExport(storyFixture())) as Map<String, dynamic>;
      final nodes = (export['nodes'] as List).cast<Map<String, dynamic>>();
      Map<String, dynamic> of(String id) =>
          nodes.firstWhere((n) => n['id'] == id);
      expect(of('w1')['location'], 'wells');
      expect(of('0').containsKey('location'), isFalse);
      expect(of('260').containsKey('location'), isFalse);
    });
  });
}
