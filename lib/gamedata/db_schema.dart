import '../combat/field_anomaly.dart' show FightStage;
import '../combat/skill_vfx.dart';
import '../data/companion_remarks.dart' show remarkTriggerOptions;
import '../data/land_crossing.dart' show landTerrains;
import '../data/geography.dart'
    show
        BiomePattern,
        GeoLevel,
        geoBuildingKinds,
        geoGlyphs,
        geoKinds,
        geoLights,
        geoMaxDanger,
        geoPlaceTags;
import '../data/ship_forms.dart' show HullKind;
import '../data/ship_looks.dart' show allShipLookPatterns, shipLookCategories;
import '../data/signs.dart'
    show PatronKind, SignEffectKind, SignSlot, patronIconNames;
import 'field_schema.dart';

// The schema class, the shared option lists and [gameDbSchemas] are here;
// the schemas themselves are in four parts, by what they describe.
part 'db_schema_gear.dart';
part 'db_schema_foes.dart';
part 'db_schema_story.dart';
part 'db_schema_world.dart';

class DbSchema {
  DbSchema({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.primaryKeyField,
    required this.fields,
    this.titleField,
    this.visualAssetField,
  });

  final String id;
  final String label;
  final String assetPath;
  final String primaryKeyField;
  final String? titleField;
  final List<FieldSchema> fields;

  /// Key of the [FieldType.image] field (if any) holding the filename of
  /// this record's visual asset, expected to live under
  /// [visualAssetFolder].
  final String? visualAssetField;
}

/// Folder each record of [schema] should store its visual assets in, e.g.
/// `assets/visuals/items/`. Declared per-collection in pubspec.yaml so
/// images dropped in are bundled without further wiring.
String visualAssetFolder(DbSchema schema) => 'assets/visuals/${schema.id}/';

FieldSchema _visualAssetFieldSchema(String schemaId) => FieldSchema(
      key: 'visualAsset',
      label: 'Visual Asset (filename in assets/visuals/$schemaId/)',
      type: FieldType.image,
    );

const List<String> _itemTypeOptions = [
  'Weapon',
  'Armor',
  'Potion',
  'Charm',
  'Tome',
  'Scroll',
  'Ship',
  'Material',
  'Quest',
  'Artifact',
  'Spellbook',
];

/// The ability score an equippable item's flat attackDamage/armor scales
/// with -- e.g. a staff scales with Intelligence, a sword with Strength.
/// Empty means the item doesn't scale (most Armor-slot pieces).
const List<String> _statScalingOptions = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
];

const List<String> equipSlotOptions = [
  'Head',
  'Top',
  'Weapon',
  'Bottom',
  'Foot',
];

/// A skill's rarity: how many faces of one die it may take.
const List<String> _skillRarityOptions = [
  'common',
  'uncommon',
  'rare',
  'epic',
  'legendary',
];

const List<String> elementOptions = [
  'None',
  'Fire',
  'Wind',
  'Earth',
  'Water',
  'Electricity',
  'Void',
  'Ice',
  'Light',
];

// 'Empty' is intentionally excluded: no die face may be empty in play, so
// the Data tab only offers face types that are actually usable in combat.
const List<String> _enemyIntentOptions = [
  '',
  'attack',
  'heal',
  'guard',
  'charge',
  'rally',
  'tamper',
];

/// What an enemy skill does to the party's dice (v1.182, see
/// dice_tamper.dart); empty for none.
const List<String> _diceTamperOptions = [
  '',
  'hex',
  'silence',
  'curse',
  'mirror'
];

/// The rule words a die face can carry (v1.182, see face_keywords.dart).
const List<String> _faceKeywordOptions = [
  'cleave',
  'pierce',
  'growth',
  'echo',
  'pain',
  'steady',
];

const List<String> faceTypeOptions = [
  'Attack',
  'Defend',
  'Skill',
  'Heal',
  'Mana',
];

/// What a spell (spells.json) does when cast -- see `lib/combat/spells.dart`.
const List<String> spellEffectOptions = [
  'Damage',
  'Heal',
  'Block',
  'Status',
  'Cleanse',
];

/// Whom a spell is cast on: one enemy, every enemy, one party member, the
/// whole party, or the caster alone.
const List<String> spellTargetOptions = [
  'Enemy',
  'AllEnemies',
  'Ally',
  'Party',
  'Self',
];

/// The ability score a spell's amount grows with (half the score is added
/// to it) -- empty for a flat spell.
const List<String> spellScalingOptions = [
  '',
  'intelligence',
  'wisdom',
  'strength'
];

const List<String> slotTypeOptions = ['Weapon', 'Shield', 'Utility', 'Sail'];

/// How rare a ship part is, lowest first (ship_parts.json `rarity`).
const List<String> shipPartRarityOptions = [
  'common',
  'uncommon',
  'rare',
  'epic',
  'legendary',
];

const List<String> _questCategoryOptions = ['Main', 'Side', 'Daily', 'Event'];

const List<String> _alignmentOptions = ['Good', 'Neutral', 'Evil'];

// Mirrors the MapTheme enum in lib/data/map_themes.dart — kept as plain
// strings here (like every other enum field in this file) rather than
// importing that enum, so the data-editor schema layer stays free of any
// dependency on gameplay code.
const List<String> _mapThemeOptions = [
  'ashenStreets',
  'saltRoads',
  'hollowReaches',
  'wildsBeyond',
];

const List<String> _skillMoveConditionOptions = [
  'Always',
  'Chance',
  'OnPlayerPotion',
  'OnLowHealth',
  'AfterBasicAttacks',
  'OnHitByElement',
  'OnRepeatedPlayerAction',
  'OnPlayerHighBlock',
];

// Mirrors StatusEffectType in lib/combat/status_effect.dart, plus 'None'
// for "this skill doesn't inflict a status" — the common case.
const List<String> _statusEffectOptions = ['None', 'Poison', 'Stun', 'Weaken'];

/// Rarity band the spoils chest draws gear from (see loot_box.dart). A
/// Relic (v1.204) is a Rare with a story: the Shroud, a saint's bones, a
/// crown -- drawn with the Rares and read on the signs' scale as heroic.
const List<String> rarityOptions = ['Common', 'Uncommon', 'Rare', 'Relic'];

/// The icon keys a person's `kind` may take in npcs.json (v1.204, see
/// npcKindIcon in game_icons.dart and people_codex.dart).
const List<String> _npcKindOptions = [
  'inquisitor',
  'soldier',
  'merchant',
  'elder',
  'smuggler',
  'healer',
  'scholar',
  'kin',
  'sailor',
  'penitent',
  'noble',
  'beast',
  'child',
  'keeper',
];

/// See `UniqueEffect` in lib/combat/gear_effects.dart.
const List<String> _uniqueEffectOptions = [
  '',
  'lifesteal',
  'thorns',
  'secondWind',
  'manaOnHit',
  'critChance',
  'dodgeChance',
];

/// An item's or skill's alignment affinity -- empty for none. Matching
/// gear/skills are stronger for that alignment; opposed gear can't be
/// worn and opposed skills are weaker (see ally_state.dart's
/// meetsItemAlignment/alignmentGearBonusFor and combat_engine.dart's
/// alignmentSkillMultiplier).
const List<String> _affinityAlignmentOptions = ['', 'Good', 'Evil'];

final List<DbSchema> gameDbSchemas = [
  itemsSchema,
  itemSetsSchema,
  skillsSchema,
  skillMergesSchema,
  skillTreesSchema,
  diceSchema,
  enemiesSchema,
  enemyShipsSchema,
  shipsSchema,
  shipPartsSchema,
  shipLooksSchema,
  questsSchema,
  shopsSchema,
  racesSchema,
  professionsSchema,
  companionsSchema,
  companionRemarksSchema,
  housesSchema,
  achievementsSchema,
  zonesSchema,
  portsSchema,
  chaptersSchema,
  npcsSchema,
  spellsSchema,
  factionsSchema,
  subclansSchema,
  relationsSchema,
  titlesSchema,
  intriguesSchema,
  signsSchema,
  politicsEventsSchema,
  geographySchema,
  biomesSchema,
  landRoutesSchema,
  landEventsSchema,
];
