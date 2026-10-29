import 'dart:ui' show Color;

/// The Eel's looks (ship_looks.json), v1.226: what the shipwright paints,
/// stitches and carves, and nothing it changes in a battle. Four
/// categories, each with one free default that is always worn until
/// another is chosen; the rest are bought at the Harbor, and a figurehead
/// from a slain beast is fitted free (see [lookOffered]).
///
/// Each look names its colours (`color`, `color2`, `color3`, "#RRGGBB") and
/// a `pattern`, which the ship's painter reads (see ship_dress.dart):
/// - hull: the hull, the deck and the trim; pattern is unused;
/// - sail: the cloth, the pattern's colour and the edge; pattern is how
///   the cloth is worked (plain, stripes, patches, diamonds);
/// - figurehead: the carving and its eye; pattern is what is carved;
/// - ensign: the cloth and its device; pattern is the flag's shape.
const List<String> shipLookCategories = [
  'hull',
  'sail',
  'figurehead',
  'ensign'
];

/// What each category's `pattern` may be, in the editor's picker.
const Map<String, List<String>> shipLookPatterns = {
  'hull': ['plain'],
  'sail': ['plain', 'stripes', 'patches', 'diamonds'],
  'figurehead': [
    'none',
    'gull',
    'eel',
    'siren',
    'wolf',
    'skull',
    'lion',
    'dragon',
    'maw',
    'horn',
    'eye',
  ],
  'ensign': [
    'pennant',
    'swallowtail',
    'wave',
    'streamers',
    'checkered',
    'skull',
    'crown',
    'void',
  ],
};

/// Every pattern any category uses, once, for the data editor's field.
List<String> get allShipLookPatterns => {
      for (final patterns in shipLookPatterns.values) ...patterns,
    }.toList();

/// One look off its ship_looks.json record.
class ShipLook {
  const ShipLook({
    required this.id,
    required this.category,
    required this.name,
    required this.cost,
    required this.rarity,
    required this.unlockChapter,
    required this.isDefault,
    required this.trophyOf,
    required this.color,
    required this.color2,
    required this.color3,
    required this.pattern,
    required this.description,
  });

  factory ShipLook.fromRecord(String id, Map<String, dynamic> record) =>
      ShipLook(
        id: id,
        category: record['category']?.toString() ?? '',
        name: record['lookName']?.toString() ?? id,
        cost: (record['cost'] as num?)?.toInt() ?? 0,
        rarity: record['rarity']?.toString() ?? 'common',
        unlockChapter: (record['unlockChapter'] as num?)?.toInt() ?? 0,
        isDefault: record['isDefault'] == true,
        trophyOf: record['trophyOf']?.toString() ?? '',
        color: hexColor(record['color']),
        color2: hexColor(record['color2']),
        color3: hexColor(record['color3']),
        pattern: record['pattern']?.toString() ?? '',
        description: record['description']?.toString() ?? '',
      );

  final String id;
  final String category;
  final String name;
  final int cost;
  final String rarity;
  final int unlockChapter;
  final bool isDefault;

  /// A sea beast whose slaying gives this look for nothing.
  final String trophyOf;
  final Color? color;
  final Color? color2;
  final Color? color3;
  final String pattern;
  final String description;
}

/// "#RRGGBB" as a colour; null for an empty or malformed string.
Color? hexColor(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(text)) return null;
  return Color(0xFF000000 | int.parse(text.substring(1), radix: 16));
}

/// Every look on file, by id, in file order.
Map<String, ShipLook> shipLooksFrom(Map<String, dynamic> records) => {
      for (final entry in records.entries)
        if (entry.value is Map<String, dynamic>)
          entry.key: ShipLook.fromRecord(
              entry.key, entry.value as Map<String, dynamic>),
    };

/// The default look of [category]: the one the data marks, else the first.
ShipLook? _defaultLookOf(Map<String, ShipLook> looks, String category) {
  ShipLook? first;
  for (final look in looks.values) {
    if (look.category != category) continue;
    first ??= look;
    if (look.isDefault) return look;
  }
  return first;
}

/// The look worn in [category]: the one [chosen] names if it is on file,
/// owned (or a default) and of that category, else the category's default.
ShipLook? wornLook(
  Map<String, ShipLook> looks,
  String category,
  Map<String, String> chosen,
  Iterable<String> owned,
) {
  final id = chosen[category];
  final look = id == null ? null : looks[id];
  if (look != null &&
      look.category == category &&
      (look.isDefault || owned.contains(id))) {
    return look;
  }
  return _defaultLookOf(looks, category);
}

/// Whether [look] is on offer: a trophy once its beast is slain (or the
/// look already owned), the rest from their chapter on. [slain] holds the
/// beasts the crew has killed.
bool lookOffered(
  ShipLook look, {
  required int chapter,
  required Set<String> slain,
  required Iterable<String> owned,
}) {
  if (look.isDefault || owned.contains(look.id)) return true;
  if (look.trophyOf.isNotEmpty) return slain.contains(look.trophyOf);
  return chapter >= look.unlockChapter;
}
