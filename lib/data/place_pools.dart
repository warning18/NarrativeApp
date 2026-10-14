// Detour and expedition lines that fit their place (Wave 7,
// docs/proposals/detours-expeditions.md): detours.json, Narrative's, holds
// pools of lines keyed by a place of geography.json (any level: district,
// location, zone or country), by a biome of biomes.json, and by the four
// map themes. A detour's or an expedition step's line comes from the most
// specific pool that has one of the kind it needs: the place, then each
// place above it, then its zone's biome, then its theme's pool, then the
// theme's lines in map_themes.dart. The file is partial: a place, biome or
// kind it leaves out falls through, and a missing file changes nothing.
import 'geography.dart';
import 'map_themes.dart';
import 'sub_node_engine.dart';

/// The kinds of line a pool holds (ExcursionFlavor's six).
const List<String> placeLineKinds = [
  'shop',
  'enemy',
  'quest',
  'treasure',
  'rest',
  'generic',
];

/// One line, in both languages: for a scene of either [mood] (null: any)
/// from chapter [minChapter] on.
class PlaceLine {
  const PlaceLine({
    required this.en,
    this.fr = '',
    this.mood,
    this.minChapter = 0,
  });

  /// Null for a record that is not a line (no English).
  static PlaceLine? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final en = raw['en']?.toString() ?? '';
    if (en.isEmpty) return null;
    final mood = raw['mood']?.toString();
    return PlaceLine(
      en: en,
      fr: raw['fr']?.toString() ?? '',
      mood: mood == 'calm' || mood == 'tense' ? mood : null,
      minChapter: (raw['minChapter'] as num?)?.toInt() ?? 0,
    );
  }

  final String en;
  final String fr;

  /// `calm` or `tense`: a line that only fits one; null fits both.
  final String? mood;
  final int minChapter;

  /// Whether it fits a scene of [chapter] whose mood [tense] or not.
  bool fits({required int chapter, required bool tense}) =>
      chapter >= minChapter && (mood == null || (mood == 'tense') == tense);
}

/// A pool: lines by kind.
typedef PlacePool = Map<String, List<PlaceLine>>;

PlacePool _poolFrom(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final kind in placeLineKinds)
      if (raw[kind] is List)
        kind: [
          for (final line in raw[kind] as List)
            if (PlaceLine.tryParse(line) case final PlaceLine parsed) parsed,
        ],
  };
}

Map<String, PlacePool> _poolsFrom(Object? raw) => raw is Map
    ? {
        for (final MapEntry(:key, :value) in raw.entries)
          key.toString(): _poolFrom(value),
      }
    : const {};

/// detours.json, parsed.
class PlacePools {
  const PlacePools({
    this.places = const {},
    this.biomes = const {},
    this.themes = const {},
  });

  factory PlacePools.fromJson(Map<String, dynamic> raw) => PlacePools(
        places: _poolsFrom(raw['places']),
        biomes: _poolsFrom(raw['biomes']),
        themes: _poolsFrom(raw['themes']),
      );

  static const PlacePools empty = PlacePools();

  /// Pools by geography id, biome id and map theme name.
  final Map<String, PlacePool> places;
  final Map<String, PlacePool> biomes;
  final Map<String, PlacePool> themes;

  bool get isEmpty => places.isEmpty && biomes.isEmpty && themes.isEmpty;

  /// The lines of [kind] for a scene at [chain] (place ids, the most
  /// specific first, see [placeChainOf]) in [biomeId], of [theme]: those
  /// of the first pool on the way up that has one fitting [chapter] and
  /// [mood] (a scene's mood, see SubNodeEngine.tenseMoods). Empty when no
  /// pool of the file has one: the theme's own Dart lines answer then.
  List<PlaceLine> linesFor(
    String kind, {
    List<String> chain = const [],
    String? biomeId,
    MapTheme theme = defaultMapTheme,
    int chapter = 1,
    String? mood,
  }) {
    final tense = SubNodeEngine.tenseMoods.contains(mood);
    for (final pool in [
      for (final id in chain) places[id],
      biomes[biomeId],
      themes[theme.name],
    ]) {
      final lines = [
        for (final line in pool?[kind] ?? const <PlaceLine>[])
          if (line.fits(chapter: chapter, tense: tense)) line,
      ];
      if (lines.isNotEmpty) return lines;
    }
    return const [];
  }

  /// The flavor a detour or an expedition draws from at that place: each
  /// kind's lines from [linesFor], else [theme]'s own (map_themes.dart).
  /// With an empty file, exactly [flavorFor]([theme]).
  ExcursionFlavor flavorAt({
    List<String> chain = const [],
    String? biomeId,
    MapTheme theme = defaultMapTheme,
    int chapter = 1,
    String? mood,
  }) {
    final fallback = flavorFor(theme);
    if (isEmpty) return fallback;
    (List<String>, List<String>) kind(
        String kind, List<String> en, List<String> fr) {
      final lines = linesFor(kind,
          chain: chain,
          biomeId: biomeId,
          theme: theme,
          chapter: chapter,
          mood: mood);
      if (lines.isEmpty) return (en, fr);
      return (
        [for (final line in lines) line.en],
        [for (final line in lines) line.fr.isEmpty ? line.en : line.fr],
      );
    }

    final shop = kind('shop', fallback.shop, fallback.shopFr);
    final enemy = kind('enemy', fallback.enemy, fallback.enemyFr);
    final quest = kind('quest', fallback.quest, fallback.questFr);
    final treasure = kind('treasure', fallback.treasure, fallback.treasureFr);
    final rest = kind('rest', fallback.rest, fallback.restFr);
    final generic = kind('generic', fallback.generic, fallback.genericFr);
    return ExcursionFlavor(
      shop: shop.$1,
      shopFr: shop.$2,
      enemy: enemy.$1,
      enemyFr: enemy.$2,
      quest: quest.$1,
      questFr: quest.$2,
      treasure: treasure.$1,
      treasureFr: treasure.$2,
      rest: rest.$1,
      restFr: rest.$2,
      generic: generic.$1,
      genericFr: generic.$2,
    );
  }
}

/// [locationId] and every place above it in [geo], the most specific
/// first (a district, its location, its zone, its country, its continent).
/// Just [locationId] when the geography doesn't know it.
List<String> placeChainOf(Geography geo, String? locationId) {
  if (locationId == null || locationId.isEmpty) return const [];
  final path = geo.pathOf(locationId);
  if (path.isEmpty) return [locationId];
  return [for (final place in path.reversed) place.id];
}

/// The biome of [locationId]'s zone in [geo], if it says.
String? placeBiomeOf(Geography geo, String? locationId) {
  final biome = geo.zoneOf(locationId)?.biome ?? '';
  return biome.isEmpty ? null : biome;
}
