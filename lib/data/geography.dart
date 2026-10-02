import 'dart:ui' show Color;

import '../models/story_node.dart';
import 'story_repository.dart';
import 'world_map.dart' show landmarkOfScene;

/// The world's places (v1.197), read from assets/gamedata/geography.json
/// and biomes.json: five levels, continent → country → zone → location →
/// district, each place one level under its parent. A zone has a biome
/// (its fauna, flora, weather and hazards, and how the Journey map paints
/// it); a country has a ruler (a factions.json id, or none); a location
/// has a kind. A story node says where it happens with its `location`, a
/// location or a district; the landmarks of world_map.dart each belong to
/// one place too. Pure: the files' records in, places out.

/// A place's level, widest first.
enum GeoLevel { continent, country, zone, location, district }

/// The level named [name] in the files, or null.
GeoLevel? geoLevelNamed(String name) {
  for (final level in GeoLevel.values) {
    if (level.name == name) return level;
  }
  return null;
}

/// What a location is: its icon and how it is listed.
const List<String> geoKinds = [
  'city',
  'town',
  'village',
  'camp',
  'site',
  'wild',
  'sea',
];

/// How the Journey map paints a biome's ground under a place (see
/// BiomeBackdropPainter): [id] as biomes.json writes it.
enum BiomePattern {
  fields('fields'),
  dunes('dunes'),
  saltFlats('salt_flats'),
  waves('waves'),
  ash('ash'),
  terraces('terraces'),
  cliffs('cliffs'),
  reeds('reeds'),
  snow('snow'),
  glass('glass');

  const BiomePattern(this.id);

  final String id;

  /// The pattern biomes.json calls [id]; fields for one it doesn't know.
  static BiomePattern named(String id) {
    for (final pattern in values) {
      if (pattern.id == id) return pattern;
    }
    return fields;
  }
}

String _text(Map<dynamic, dynamic> raw, String key) =>
    raw[key]?.toString().trim() ?? '';

String _either(bool french, String fr, String en) =>
    french && fr.isNotEmpty ? fr : en;

/// One creature, plant or weather of a biome, with its line.
class GeoLine {
  const GeoLine({
    required this.name,
    this.nameFr = '',
    this.note = '',
    this.noteFr = '',
  });

  final String name;
  final String nameFr;
  final String note;
  final String noteFr;

  String nameFor(bool french) => _either(french, nameFr, name);
  String noteFor(bool french) => _either(french, noteFr, note);

  static List<GeoLine> listFrom(Object? raw) => [
        if (raw is List)
          for (final entry in raw)
            if (entry is Map && _text(entry, 'name').isNotEmpty)
              GeoLine(
                name: _text(entry, 'name'),
                nameFr: _text(entry, 'name_fr'),
                note: _text(entry, 'note'),
                noteFr: _text(entry, 'note_fr'),
              ),
      ];
}

/// What a biome's land can throw at the party on the road (see
/// RoadEventKind.hazard): the scene, and its two ways through, pushing on
/// or waiting it out.
class BiomeHazard {
  const BiomeHazard({
    required this.id,
    required this.name,
    this.nameFr = '',
    this.text = '',
    this.textFr = '',
    this.push = '',
    this.pushFr = '',
    this.wait = '',
    this.waitFr = '',
  });

  final String id;
  final String name;
  final String nameFr;

  /// The scene on the road, first person.
  final String text;
  final String textFr;

  /// The two choices' labels.
  final String push;
  final String pushFr;
  final String wait;
  final String waitFr;

  String nameFor(bool french) => _either(french, nameFr, name);

  static List<BiomeHazard> listFrom(Object? raw) => [
        if (raw is List)
          for (final entry in raw)
            if (entry is Map && _text(entry, 'name').isNotEmpty)
              BiomeHazard(
                id: _text(entry, 'id').isEmpty
                    ? _text(entry, 'name').toLowerCase()
                    : _text(entry, 'id'),
                name: _text(entry, 'name'),
                nameFr: _text(entry, 'name_fr'),
                text: _text(entry, 'text'),
                textFr: _text(entry, 'text_fr'),
                push: _text(entry, 'push'),
                pushFr: _text(entry, 'push_fr'),
                wait: _text(entry, 'wait'),
                waitFr: _text(entry, 'wait_fr'),
              ),
      ];
}

/// A biome's four colours, for the Journey map's backdrop.
class BiomePalette {
  const BiomePalette({
    required this.ground,
    required this.detail,
    required this.accent,
    required this.water,
  });

  final Color ground;
  final Color detail;
  final Color accent;
  final Color water;

  /// A palette for a biome that gives none: a plain green land.
  static const BiomePalette plain = BiomePalette(
    ground: Color(0xFF8FA36B),
    detail: Color(0xFF5E7444),
    accent: Color(0xFFC9D6A3),
    water: Color(0xFF4F8FA8),
  );

  /// `#RRGGBB` (or `#AARRGGBB`) as a colour, or null.
  static Color? parseHex(String text) {
    var hex = text.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  static BiomePalette from(Object? raw) {
    if (raw is! Map) return plain;
    Color pick(String key, Color fallback) =>
        parseHex(raw[key]?.toString() ?? '') ?? fallback;
    return BiomePalette(
      ground: pick('ground', plain.ground),
      detail: pick('detail', plain.detail),
      accent: pick('accent', plain.accent),
      water: pick('water', plain.water),
    );
  }
}

/// A kind of land: what lives and grows there, its weather, what it does
/// to travellers, and how it looks.
class Biome {
  const Biome({
    required this.id,
    required this.name,
    this.nameFr = '',
    this.blurb = '',
    this.blurbFr = '',
    this.fauna = const [],
    this.flora = const [],
    this.weather = const [],
    this.hazards = const [],
    this.palette = BiomePalette.plain,
    this.pattern = BiomePattern.fields,
  });

  factory Biome.fromJson(String id, Map<dynamic, dynamic> raw) => Biome(
        id: id,
        name: _text(raw, 'name').isEmpty ? id : _text(raw, 'name'),
        nameFr: _text(raw, 'name_fr'),
        blurb: _text(raw, 'blurb'),
        blurbFr: _text(raw, 'blurb_fr'),
        fauna: GeoLine.listFrom(raw['fauna']),
        flora: GeoLine.listFrom(raw['flora']),
        weather: GeoLine.listFrom(raw['weather']),
        hazards: BiomeHazard.listFrom(raw['hazards']),
        palette: BiomePalette.from(raw['palette']),
        pattern: BiomePattern.named(_text(raw, 'pattern')),
      );

  final String id;
  final String name;
  final String nameFr;
  final String blurb;
  final String blurbFr;
  final List<GeoLine> fauna;
  final List<GeoLine> flora;
  final List<GeoLine> weather;
  final List<BiomeHazard> hazards;
  final BiomePalette palette;
  final BiomePattern pattern;

  String nameFor(bool french) => _either(french, nameFr, name);
  String blurbFor(bool french) => _either(french, blurbFr, blurb);
}

/// One place, at any of the five levels.
class GeoPlace {
  const GeoPlace({
    required this.id,
    required this.level,
    this.parent = '',
    required this.name,
    this.nameFr = '',
    this.blurb = '',
    this.blurbFr = '',
    this.biome = '',
    this.ruler = '',
    this.kind = '',
    this.landmarks = const [],
  });

  /// [raw] as a place, or null when its level is not one of the five.
  static GeoPlace? fromJson(String id, Map<dynamic, dynamic> raw) {
    final level = geoLevelNamed(_text(raw, 'level'));
    if (level == null) return null;
    final landmarks = <String>{
      if (_text(raw, 'landmark').isNotEmpty) _text(raw, 'landmark'),
      if (raw['landmarks'] is List)
        for (final entry in raw['landmarks'] as List)
          if (entry.toString().trim().isNotEmpty) entry.toString().trim(),
    };
    return GeoPlace(
      id: id,
      level: level,
      parent: _text(raw, 'parent'),
      name: _text(raw, 'name').isEmpty ? id : _text(raw, 'name'),
      nameFr: _text(raw, 'name_fr'),
      blurb: _text(raw, 'blurb'),
      blurbFr: _text(raw, 'blurb_fr'),
      // Each only where its level has it.
      biome: level == GeoLevel.zone ? _text(raw, 'biome') : '',
      ruler: level == GeoLevel.country ? _text(raw, 'ruler') : '',
      kind: level == GeoLevel.location ? _text(raw, 'kind') : '',
      landmarks: landmarks.toList(),
    );
  }

  final String id;
  final GeoLevel level;

  /// The place one level up; '' for a continent.
  final String parent;
  final String name;
  final String nameFr;
  final String blurb;
  final String blurbFr;

  /// A zone's biome id.
  final String biome;

  /// A country's ruler: a factions.json id, or '' for none.
  final String ruler;

  /// A location's kind (see [geoKinds]).
  final String kind;

  /// The world_map.dart landmarks that lie here.
  final List<String> landmarks;

  String nameFor(bool french) => _either(french, nameFr, name);
  String blurbFor(bool french) => _either(french, blurbFr, blurb);

  /// Where a story node can happen: a location or a district.
  bool get isSpot => level == GeoLevel.location || level == GeoLevel.district;
}

/// The world's places and biomes, from geography.json and biomes.json.
/// Empty files (or none) make an empty geography: every lookup then finds
/// nothing, and the screens that use it show nothing of it.
class Geography {
  Geography._(this.places, this.biomes)
      : _byLandmark = {
          for (final place in places.values)
            for (final landmark in place.landmarks) landmark: place.id,
        },
        _children = _childrenOf(places);

  /// The records of geography.json and biomes.json, parsed. A record that
  /// is not a place (no level of the five) is left out.
  factory Geography.parse({
    Map<String, dynamic> geography = const {},
    Map<String, dynamic> biomes = const {},
  }) {
    final places = <String, GeoPlace>{};
    for (final entry in geography.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final place = GeoPlace.fromJson(entry.key, raw);
      if (place != null) places[entry.key] = place;
    }
    return Geography._(places, {
      for (final entry in biomes.entries)
        if (entry.value is Map)
          entry.key: Biome.fromJson(entry.key, entry.value as Map),
    });
  }

  /// No places and no biomes.
  static final Geography empty = Geography._(const {}, const {});

  /// Every place by id, in the file's order.
  final Map<String, GeoPlace> places;
  final Map<String, Biome> biomes;
  final Map<String, String> _byLandmark;
  final Map<String, List<String>> _children;

  static Map<String, List<String>> _childrenOf(Map<String, GeoPlace> places) {
    final children = <String, List<String>>{};
    for (final place in places.values) {
      if (place.parent.isEmpty) continue;
      (children[place.parent] ??= []).add(place.id);
    }
    return children;
  }

  bool get isEmpty => places.isEmpty;

  GeoPlace? place(String? id) => id == null || id.isEmpty ? null : places[id];

  /// The continents, in the file's order.
  List<GeoPlace> get continents => [
        for (final place in places.values)
          if (place.level == GeoLevel.continent) place,
      ];

  /// The places one level under [id], in the file's order.
  List<GeoPlace> childrenOf(String id) => [
        for (final child in _children[id] ?? const <String>[])
          if (places[child] != null) places[child]!,
      ];

  /// From the continent down to [id] itself (its parents first); empty
  /// for a place that doesn't exist. A broken chain stops where it breaks.
  List<GeoPlace> pathOf(String? id) {
    final path = <GeoPlace>[];
    final seen = <String>{};
    var at = place(id);
    while (at != null && seen.add(at.id)) {
      path.insert(0, at);
      at = place(at.parent);
    }
    return path;
  }

  /// [id], or the place above it, at [level]; null when there is none.
  GeoPlace? ancestorAt(String? id, GeoLevel level) {
    for (final place in pathOf(id)) {
      if (place.level == level) return place;
    }
    return null;
  }

  GeoPlace? continentOf(String? id) => ancestorAt(id, GeoLevel.continent);
  GeoPlace? countryOf(String? id) => ancestorAt(id, GeoLevel.country);
  GeoPlace? zoneOf(String? id) => ancestorAt(id, GeoLevel.zone);
  GeoPlace? locationOf(String? id) => ancestorAt(id, GeoLevel.location);

  /// The biome of [id]'s zone.
  Biome? biomeOf(String? id) => biomes[zoneOf(id)?.biome];

  /// The place that holds the world_map.dart landmark [landmarkId].
  GeoPlace? placeOfLandmark(String? landmarkId) =>
      landmarkId == null ? null : place(_byLandmark[landmarkId]);

  /// Where [node] happens: its `location` when that names a place; with
  /// no `location` at all (or one this geography doesn't have), the place
  /// of its landmark (see landmarkOfScene). A `location` of '' happens
  /// nowhere (the prologue, the making of the character).
  GeoPlace? placeOfNode(StoryNode? node) {
    if (node == null) return null;
    final location = node.location;
    if (location != null && location.isEmpty) return null;
    return place(location) ?? placeOfLandmark(landmarkOfScene(node.id)?.id);
  }

  /// The places the story has been to: each one where a scene of
  /// [visited] happens, and every place above it.
  Set<String> discoveredPlaces(Iterable<String> visited, StoryData story) {
    final found = <String>{};
    for (final id in {...visited}) {
      final here = placeOfNode(story.nodeFor(id));
      if (here == null || found.contains(here.id)) continue;
      for (final place in pathOf(here.id)) {
        found.add(place.id);
      }
    }
    return found;
  }

  /// The location (a city, a village, a site: never a district) where
  /// [node] happens, if the world knows it.
  GeoPlace? locationOfNode(StoryNode? node) =>
      locationOf(placeOfNode(node)?.id);

  /// Whether going from scene [fromNodeId] to [toNodeId] travels: leaves
  /// one location for another (Alster for the Waste, the camp for a
  /// village). A move between two districts of the same city (the Blind
  /// Beggar to the Stone Bridge, both in Alster) is a walk through its
  /// streets, not a journey: the map stays on the city and the road's
  /// rules don't apply. Where the world doesn't know either scene's
  /// location, a change of landmark decides (see isRoadStep).
  bool travelsBetween(StoryData story, String fromNodeId, String toNodeId) {
    if (fromNodeId == toNodeId) return false;
    final from = locationOfNode(story.nodeFor(fromNodeId));
    final to = locationOfNode(story.nodeFor(toNodeId));
    if (from != null && to != null) return from.id != to.id;
    final a = landmarkOfScene(fromNodeId);
    final b = landmarkOfScene(toNodeId);
    return a != null && b != null && a.id != b.id;
  }

  /// The biome of the land a road from scene [fromNodeId] to [toNodeId]
  /// runs through: the zone it leads to, or the one it leaves from.
  Biome? roadBiome(StoryData story, String fromNodeId, String toNodeId) {
    for (final id in [toNodeId, fromNodeId]) {
      final biome = biomeOf(placeOfNode(story.nodeFor(id))?.id);
      if (biome != null) return biome;
    }
    return null;
  }

  /// The places a story node can happen at (locations and districts), in
  /// the order they lie: continent by continent, down each branch.
  List<GeoPlace> get spots {
    final out = <GeoPlace>[];
    final seen = <String>{};
    void walk(GeoPlace place) {
      if (!seen.add(place.id)) return;
      if (place.isSpot) out.add(place);
      for (final child in childrenOf(place.id)) {
        walk(child);
      }
    }

    for (final continent in continents) {
      walk(continent);
    }
    // Any left out of the tree (a broken chain) still count.
    for (final place in places.values) {
      if (place.isSpot && seen.add(place.id)) out.add(place);
    }
    return out;
  }
}
