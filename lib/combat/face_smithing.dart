import 'face_keywords.dart';

/// Face smithing at the Hammersmith (v1.182): the party's dice become a
/// build of their own. Each face of a die can be worked on, the work kept
/// on the die (a companion's signature die, or one the player owns) for
/// good:
///
/// - [SmithingWork.hone]: +[honeStep] to an Attack, Defend or Heal face,
///   up to [maxHones] times.
/// - [SmithingWork.temper]: an element on an Attack face.
/// - [SmithingWork.inscribe]: a keyword (see face_keywords.dart), one per
///   face; inscribing another replaces it.
/// - [SmithingWork.recast]: an Attack, Defend or Heal face turned into
///   another of the three, its number kept up to the die's best face of
///   the new type (see [recastValue]; a Temper goes with the Attack).
enum SmithingWork { hone, temper, inscribe, recast }

/// What a Hone adds, and how many a face takes.
const int honeStep = 2;
const int maxHones = 3;

/// The face types a Hone and a Recast work on.
const List<String> smithableBasicTypes = ['Attack', 'Defend', 'Heal'];

/// The elements a Temper can give an Attack face, spelled as the rest of
/// the game spells them (see elementFieldPrefixes).
const List<String> temperElements = [
  'Fire',
  'Ice',
  'Light',
  'Void',
  'Earth',
  'Wind',
  'Water',
  'Electricity',
];

/// A Temper's element as a save may hold it: v1.182 to v1.186 sold
/// Electricity as 'Elec', which nothing else in the game reads.
String? _temperElementNamed(String? name) =>
    name == 'Elec' ? 'Electricity' : name;

/// The pack items the Hammersmith takes for the work: iron for a Hone and a
/// Temper, a trophy (an Elite Mark, or a boss's Champion's Trophy) for an
/// inscription.
const String ironOreId = 'material_iron_ore';
const String bossTrophyId = 'boss_trophy';
const String eliteTrophyId = 'elite_trophy';

/// A trophy counts in this order when an inscription takes one.
const List<String> trophyItemIds = [eliteTrophyId, bossTrophyId];

/// The work done on one face.
class FaceUpgrade {
  const FaceUpgrade({
    this.hones = 0,
    this.element,
    this.keyword,
    this.recastType,
  });

  static const FaceUpgrade none = FaceUpgrade();

  /// Hones applied ([honeStep] each).
  final int hones;

  /// A Temper's element, on an Attack face.
  final String? element;

  /// An inscribed keyword.
  final FaceKeyword? keyword;

  /// The basic type a Recast turned the face into.
  final String? recastType;

  bool get isEmpty =>
      hones == 0 && element == null && keyword == null && recastType == null;

  FaceUpgrade copyWith({
    int? hones,
    String? element,
    bool clearElement = false,
    FaceKeyword? keyword,
    String? recastType,
  }) =>
      FaceUpgrade(
        hones: hones ?? this.hones,
        element: clearElement ? null : element ?? this.element,
        keyword: keyword ?? this.keyword,
        recastType: recastType ?? this.recastType,
      );

  Map<String, dynamic> toJson() => {
        if (hones > 0) 'hones': hones,
        if (element != null) 'element': element,
        if (keyword != null) 'keyword': keyword!.name,
        if (recastType != null) 'recastType': recastType,
      };

  factory FaceUpgrade.fromJson(Map<String, dynamic> json) {
    final element = _temperElementNamed(json['element']?.toString());
    return FaceUpgrade(
      hones: ((json['hones'] as num?)?.toInt() ?? 0).clamp(0, maxHones),
      element: temperElements.contains(element) ? element : null,
      keyword: faceKeywordNamed(json['keyword']?.toString() ?? ''),
      recastType: smithableBasicTypes.contains(json['recastType']?.toString())
          ? json['recastType'].toString()
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FaceUpgrade &&
      other.hones == hones &&
      other.element == element &&
      other.keyword == keyword &&
      other.recastType == recastType;

  @override
  int get hashCode => Object.hash(hones, element, keyword, recastType);
}

/// A die's worked faces, by face index (as a string, like the dice skill
/// assignments).
typedef DieUpgrades = Map<String, FaceUpgrade>;

/// Where the work on a die is kept in the session's `diceUpgrades`: under
/// the die's id for one of the player's own dice, under `companion:die`
/// for a companion's signature die. The Weaponsmith sells Kelda's Iron Die
/// too (and Maren's and Sable's dice are sold elsewhere), so the player's
/// copy and the companion's are worked apart.
String dieUpgradesKey(String dieId, {String? companionId}) =>
    companionId == null ? dieId : '$companionId:$dieId';

/// [faces] (a die's dice.json faces) with [upgrades] worked in: a Recast
/// face takes its new type (and [recastValue]), a Hone adds to its number,
/// a Temper sets its element and an inscription joins its keywords. The
/// records returned are new maps; [faces] is left as it was. A face the
/// work doesn't fit (a dice.json change since) keeps what still fits.
List<Map<String, dynamic>> smithedFaces(
  List<Map<String, dynamic>> faces,
  DieUpgrades? upgrades,
) {
  if (upgrades == null || upgrades.isEmpty) return faces;
  return [
    for (var i = 0; i < faces.length; i++)
      _smithedFace(faces[i], upgrades[i.toString()], faces),
  ];
}

/// The number a face of [value] keeps when recast to [type] on a die of
/// [faces] (its dice.json records): its own, but never more than the die's
/// best [type] face, so a Recast changes what a face does and not what it
/// is worth (a Heal 18 or a Guard 13 was tuned as a heal or a guard, and
/// is no Attack 18 or 13). A die with no [type] face keeps the number.
int recastValue(int value, String type, List<Map<String, dynamic>> faces) {
  int? best;
  for (final face in faces) {
    if (face['type'] != type) continue;
    final number = (face['value'] as num?)?.toInt() ?? 0;
    if (best == null || number > best) best = number;
  }
  return best == null || value < best ? value : best;
}

Map<String, dynamic> _smithedFace(Map<String, dynamic> face,
    FaceUpgrade? upgrade, List<Map<String, dynamic>> dieFaces) {
  if (upgrade == null || upgrade.isEmpty) return face;
  final out = Map<String, dynamic>.from(face);
  final type = out['type']?.toString() ?? '';
  if (upgrade.recastType != null && smithableBasicTypes.contains(type)) {
    out['type'] = upgrade.recastType;
    out['value'] = recastValue(
        (out['value'] as num?)?.toInt() ?? 0, upgrade.recastType!, dieFaces);
    if (upgrade.recastType != 'Attack') out['element'] = 'None';
  }
  final newType = out['type']?.toString() ?? '';
  if (upgrade.hones > 0 && smithableBasicTypes.contains(newType)) {
    out['value'] =
        ((out['value'] as num?)?.toInt() ?? 0) + upgrade.hones * honeStep;
  }
  if (upgrade.element != null && newType == 'Attack') {
    out['element'] = upgrade.element;
  }
  final keyword = upgrade.keyword;
  if (keyword != null && keywordFitsFaceType(keyword, newType)) {
    out['keywords'] = [
      ...faceKeywordsOf(face).map((k) => k.name),
      if (!faceKeywordsOf(face).contains(keyword)) keyword.name,
    ];
  }
  out['smithed'] = true;
  return out;
}

/// What a piece of work costs: gold, and pack items by id.
class SmithingCost {
  const SmithingCost({required this.gold, this.iron = 0, this.trophies = 0});

  final int gold;
  final int iron;

  /// Trophies of any kind (see [trophyItemIds]).
  final int trophies;
}

/// The next Hone costs more each time: 80 gold and an iron ore, then 160
/// and two, then 240 and three.
SmithingCost honeCost(int honesSoFar) =>
    SmithingCost(gold: 80 * (honesSoFar + 1), iron: honesSoFar + 1);

const SmithingCost temperCost = SmithingCost(gold: 150, iron: 2);
const SmithingCost inscribeCost = SmithingCost(gold: 250, trophies: 1);
const SmithingCost recastCost = SmithingCost(gold: 120);

/// The cost of [work] on a face already worked as [current].
SmithingCost smithingCostFor(SmithingWork work, FaceUpgrade current) =>
    switch (work) {
      SmithingWork.hone => honeCost(current.hones),
      SmithingWork.temper => temperCost,
      SmithingWork.inscribe => inscribeCost,
      SmithingWork.recast => recastCost,
    };

/// Whether [work] can be done on [face] (its dice.json record) already
/// worked as [current]: a Hone on a basic face below [maxHones], a Temper
/// on an Attack face (as it stands after a Recast), an inscription on any
/// face a keyword fits (see [keywordFitsFaceType]), a Recast on a basic
/// face. A fixed signature face of a companion's die (a Skill face) takes
/// only an inscription.
bool canSmith(SmithingWork work, Map<String, dynamic> face,
    [FaceUpgrade current = FaceUpgrade.none]) {
  final baseType = face['type']?.toString() ?? '';
  final type =
      current.recastType != null && smithableBasicTypes.contains(baseType)
          ? current.recastType!
          : baseType;
  switch (work) {
    case SmithingWork.hone:
      return smithableBasicTypes.contains(type) && current.hones < maxHones;
    case SmithingWork.temper:
      return type == 'Attack' && temperableElements(face, current).isNotEmpty;
    case SmithingWork.inscribe:
      return FaceKeyword.values.any((k) => keywordFitsFaceType(k, type));
    case SmithingWork.recast:
      return smithableBasicTypes.contains(baseType);
  }
}

/// The elements a Temper can give [face] worked as [current]: every one
/// but the element the face strikes with already, its own (a Fire strike
/// isn't paid for to strike with Fire) or a Temper's.
List<String> temperableElements(Map<String, dynamic> face,
    [FaceUpgrade current = FaceUpgrade.none]) {
  final own = face['element']?.toString() ?? 'None';
  return [
    for (final element in temperElements)
      if (element != own && element != current.element) element,
  ];
}

/// The keywords that can be inscribed on [face] worked as [current]: those
/// that fit its type and that it doesn't carry already.
List<FaceKeyword> inscribableKeywords(Map<String, dynamic> face,
    [FaceUpgrade current = FaceUpgrade.none]) {
  final baseType = face['type']?.toString() ?? '';
  final type =
      current.recastType != null && smithableBasicTypes.contains(baseType)
          ? current.recastType!
          : baseType;
  final own = faceKeywordsOf(face);
  return [
    for (final keyword in FaceKeyword.values)
      if (keywordFitsFaceType(keyword, type) &&
          !own.contains(keyword) &&
          keyword != current.keyword)
        keyword,
  ];
}

/// The string keys of a piece of work's name and rules line.
String smithingWorkLabelKey(SmithingWork work) => 'smith_${work.name}';
String smithingWorkDescriptionKey(SmithingWork work) =>
    'smith_${work.name}_desc';

/// Parses the session's `diceUpgrades` (die key, see [dieUpgradesKey] →
/// face index → work).
Map<String, DieUpgrades> parseDiceUpgrades(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, DieUpgrades>{};
  for (final entry in raw.entries) {
    final faces = entry.value;
    if (faces is! Map) continue;
    final parsed = <String, FaceUpgrade>{};
    for (final face in faces.entries) {
      if (face.value is! Map) continue;
      final upgrade =
          FaceUpgrade.fromJson(Map<String, dynamic>.from(face.value as Map));
      if (!upgrade.isEmpty) parsed[face.key.toString()] = upgrade;
    }
    if (parsed.isNotEmpty) out[entry.key.toString()] = parsed;
  }
  return out;
}

/// The session's `diceUpgrades` as JSON.
Map<String, dynamic> diceUpgradesToJson(Map<String, DieUpgrades> upgrades) => {
      for (final die in upgrades.entries)
        die.key: {
          for (final face in die.value.entries) face.key: face.value.toJson(),
        },
    };
