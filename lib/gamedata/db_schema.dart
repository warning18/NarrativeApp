import '../combat/skill_vfx.dart';
import '../data/companion_remarks.dart' show remarkTriggerOptions;
import '../data/geography.dart' show BiomePattern, GeoLevel, geoKinds;
import '../data/signs.dart'
    show PatronKind, SignEffectKind, SignSlot, patronIconNames;
import 'field_schema.dart';

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

/// Full asset path for [record]'s visual, or null if the schema has no
/// visual field or the record hasn't set one.
String? visualAssetPath(DbSchema schema, Map<String, dynamic> record) {
  final field = schema.visualAssetField;
  if (field == null) return null;
  final filename = record[field]?.toString() ?? '';
  if (filename.isEmpty) return null;
  return '${visualAssetFolder(schema)}$filename';
}

FieldSchema visualAssetFieldSchema(String schemaId) => FieldSchema(
      key: 'visualAsset',
      label: 'Visual Asset (filename in assets/visuals/$schemaId/)',
      type: FieldType.image,
    );

const List<String> itemTypeOptions = [
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
const List<String> statScalingOptions = [
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
const List<String> skillRarityOptions = [
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
const List<String> enemyIntentOptions = [
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
const List<String> diceTamperOptions = [
  '',
  'hex',
  'silence',
  'curse',
  'mirror'
];

/// The rule words a die face can carry (v1.182, see face_keywords.dart).
const List<String> faceKeywordOptions = [
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

const List<String> questCategoryOptions = ['Main', 'Side', 'Daily', 'Event'];

const List<String> alignmentOptions = ['Good', 'Neutral', 'Evil'];

const List<String> nodeCategoryOptions = [
  'Combat',
  'Event',
  'Shop',
  'Rest',
  'Treasure',
  'Puzzle',
  'Travel',
];

const List<String> nodeDifficultyOptions = ['Normal', 'Hard', 'Elite', 'Boss'];

// Mirrors the MapTheme enum in lib/data/map_themes.dart — kept as plain
// strings here (like every other enum field in this file) rather than
// importing that enum, so the data-editor schema layer stays free of any
// dependency on gameplay code.
const List<String> mapThemeOptions = [
  'ashenStreets',
  'saltRoads',
  'hollowReaches',
  'wildsBeyond',
];

const List<String> skillMoveConditionOptions = [
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
const List<String> statusEffectOptions = ['None', 'Poison', 'Stun', 'Weaken'];

/// Rarity band the spoils chest draws gear from (see loot_box.dart).
const List<String> rarityOptions = ['Common', 'Uncommon', 'Rare'];

/// See `UniqueEffect` in lib/combat/gear_effects.dart.
const List<String> uniqueEffectOptions = [
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
const List<String> affinityAlignmentOptions = ['', 'Good', 'Evil'];

final DbSchema itemsSchema = DbSchema(
  id: 'items',
  label: 'Items & Equipment',
  assetPath: 'assets/gamedata/items.json',
  primaryKeyField: 'id',
  titleField: 'itemName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'id', label: 'ID', type: FieldType.text),
    FieldSchema(key: 'itemName', label: 'Item Name', type: FieldType.text),
    FieldSchema(
        key: 'itemName_fr', label: 'Item Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'itemType',
      label: 'Item Type',
      type: FieldType.enumeration,
      enumOptions: itemTypeOptions,
    ),
    FieldSchema(
        key: 'damage',
        label: 'Damage',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'isEquippable',
      label: 'Equippable',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'equipSlot',
      label: 'Equip Slot',
      type: FieldType.enumeration,
      enumOptions: equipSlotOptions,
    ),
    FieldSchema(
        key: 'attackDamage',
        label: 'Attack Damage',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'armor', label: 'Armor', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
        key: 'fireDmgBonus',
        label: 'Fire Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'windDmgBonus',
        label: 'Wind Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'earthDmgBonus',
        label: 'Earth Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'waterDmgBonus',
        label: 'Water Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'elecDmgBonus',
        label: 'Elec Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'fireResist',
        label: 'Fire Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'windResist',
        label: 'Wind Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'earthResist',
        label: 'Earth Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'waterResist',
        label: 'Water Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'elecResist',
        label: 'Elec Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'voidDmgBonus',
        label: 'Void Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'voidResist',
        label: 'Void Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'iceDmgBonus',
        label: 'Ice Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'iceResist',
        label: 'Ice Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'lightDmgBonus',
        label: 'Light Dmg Bonus',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'lightResist',
        label: 'Light Resist',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'scalingStat',
      label: 'Damage/Armor Scales With',
      type: FieldType.enumeration,
      enumOptions: statScalingOptions,
    ),
    FieldSchema(
        key: 'reqStrength',
        label: 'Requires Strength',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'reqDexterity',
        label: 'Requires Dexterity',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'reqConstitution',
        label: 'Requires Constitution',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'reqIntelligence',
        label: 'Requires Intelligence',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'rarity',
      label: 'Rarity (spoils chest band)',
      type: FieldType.enumeration,
      enumOptions: rarityOptions,
      defaultValue: 'Common',
    ),
    FieldSchema(
      key: 'setId',
      label:
          'Item Set (id in item_sets.json; pieces worn together add bonuses)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'uniqueEffect',
      label: 'Unique Effect',
      type: FieldType.enumeration,
      enumOptions: uniqueEffectOptions,
    ),
    FieldSchema(
      key: 'uniqueValue',
      label:
          'Unique Effect Value (% for lifesteal/crit/dodge, points for thorns/mana)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'lootChapter',
      label:
          'Loot Chapter (earliest chapter a spoils chest drops this; 0 = never)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'alignment',
      label: 'Alignment Affinity (empty = none)',
      type: FieldType.enumeration,
      enumOptions: affinityAlignmentOptions,
    ),
    FieldSchema(
        key: 'alignedAttackBonus',
        label: 'Aligned Attack Bonus (when wielder matches alignment)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'alignedArmorBonus',
        label: 'Aligned Armor Bonus (when wielder matches alignment)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'teachesSpellId',
      label: 'Teaches Spell (Spellbook items: learned on purchase)',
      type: FieldType.reference,
      referenceSchemaId: 'spells',
    ),
    FieldSchema(
        key: 'sellValue',
        label: 'Sell value (overrides two fifths of the cost)',
        type: FieldType.integer),
    FieldSchema(
        key: 'craftedAt',
        label: 'Forged at (shop id)',
        type: FieldType.reference,
        referenceSchemaId: 'shops'),
    FieldSchema(
        key: 'craftGold',
        label: 'Forging cost (gold)',
        type: FieldType.integer),
    FieldSchema(
        key: 'craftMaterials',
        label: 'Forging materials {itemId: count}',
        type: FieldType.json),
    visualAssetFieldSchema('items'),
  ],
);

final DbSchema skillsSchema = DbSchema(
  id: 'skills',
  label: 'Skills',
  assetPath: 'assets/gamedata/skills.json',
  primaryKeyField: 'id',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'id', label: 'ID (Skill Name)', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Skill Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'element',
      label: 'Element',
      type: FieldType.enumeration,
      enumOptions: elementOptions,
    ),
    // The on-screen effect the skill plays in a fight (skill_vfx.dart).
    FieldSchema(
      key: 'vfx',
      label: 'Combat effect',
      type: FieldType.enumeration,
      enumOptions: vfxEnumOptions,
    ),
    FieldSchema(
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    // How many faces of one die the skill may take (dice_faces.dart's
    // skillRarityFaceLimits): common 3, uncommon and rare 2, epic and
    // legendary 1.
    FieldSchema(
      key: 'rarity',
      label:
          'Rarity (faces per die: common 3, uncommon/rare 2, epic/legendary 1)',
      type: FieldType.enumeration,
      enumOptions: skillRarityOptions,
      defaultValue: 'uncommon',
    ),
    FieldSchema(
      key: 'requiredSkillID',
      label: 'Required Skill ID',
      type: FieldType.reference,
      referenceSchemaId: 'skills',
    ),
    FieldSchema(
        key: 'isUnlocked',
        label: 'Unlocked',
        type: FieldType.boolean,
        defaultValue: false),
    FieldSchema(
        key: 'enemyOnly',
        label: 'Enemy only (never offered to the party)',
        type: FieldType.boolean,
        defaultValue: false),
    // v1.162: what an enemy using this skill does with its turn (empty: an
    // attack, or a heal when the skill only heals). See enemy_intent.dart.
    FieldSchema(
      key: 'intent',
      label: 'Enemy intent (attack / heal / guard / charge / rally / tamper)',
      type: FieldType.enumeration,
      enumOptions: enemyIntentOptions,
    ),
    // v1.182: what an enemy using this skill does to the party's dice (see
    // dice_tamper.dart). Hex, Silence and Curse go with intent 'tamper';
    // Mirror is an attack.
    FieldSchema(
      key: 'tamper',
      label: 'Dice tamper (hex / silence / curse / mirror)',
      type: FieldType.enumeration,
      enumOptions: diceTamperOptions,
    ),
    FieldSchema(
        key: 'guardMultiplier',
        label: 'Guard: block as a multiple of the enemy damage',
        type: FieldType.decimal,
        defaultValue: 1.0),
    FieldSchema(
        key: 'chargeMultiplier',
        label: 'Charge: the released blow as a multiple of the move',
        type: FieldType.decimal,
        defaultValue: 2.0),
    FieldSchema(
        key: 'rallyPercent',
        label: 'Rally: damage bonus in % for the enemy and its pack',
        type: FieldType.integer,
        defaultValue: 20),
    FieldSchema(
        key: 'releaseMessage',
        label: 'Charge: line the released blow lands with',
        type: FieldType.text),
    FieldSchema(
        key: 'releaseMessage_fr',
        label: 'Charge: line the released blow lands with (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'enemyBattleMessage',
        label: 'Battle message when an enemy uses it',
        type: FieldType.text),
    FieldSchema(
        key: 'enemyBattleMessage_fr',
        label: 'Battle message when an enemy uses it (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'healAmount',
        label: 'Heal Amount',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'manaGain',
        label: 'Mana Gain (a mana skill: mana added to the pool, plus the '
            'Wisdom bonus)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'damageMod',
        label: 'Damage Mod',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'healthMod',
        label: 'Health Mod',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'isActiveSkill',
      label: 'Active Skill',
      type: FieldType.boolean,
      defaultValue: true,
    ),
    FieldSchema(
      key: 'damageMultiplier',
      label: 'Damage Multiplier',
      type: FieldType.decimal,
      defaultValue: 1.0,
    ),
    FieldSchema(
        key: 'battleMessage', label: 'Battle Message', type: FieldType.text),
    FieldSchema(
        key: 'battleMessage_fr',
        label: 'Battle Message (FR)',
        type: FieldType.text),
    FieldSchema(
      key: 'restrictedRaceID',
      label: 'Reserved For Race',
      type: FieldType.reference,
      referenceSchemaId: 'races',
    ),
    FieldSchema(
      key: 'restrictedProfessionID',
      label: 'Reserved For Profession',
      type: FieldType.reference,
      referenceSchemaId: 'professions',
    ),
    FieldSchema(
      key: 'requiredAlignmentMin',
      label: 'Requires Alignment At Least',
      type: FieldType.integer,
    ),
    FieldSchema(
      key: 'requiredAlignmentMax',
      label: 'Requires Alignment At Most',
      type: FieldType.integer,
    ),
    FieldSchema(
      key: 'alignment',
      label: 'Alignment Affinity (+25% for a matching wielder, -25% opposed)',
      type: FieldType.enumeration,
      enumOptions: affinityAlignmentOptions,
    ),
    FieldSchema(
      key: 'unlockedViaMergeOnly',
      label: 'Unlocked Via Merge Only',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'inflictsStatus',
      label: 'Inflicts Status Effect (on hit)',
      type: FieldType.enumeration,
      enumOptions: statusEffectOptions,
    ),
    FieldSchema(
      key: 'statusDuration',
      label: 'Status Duration (rounds; ignored if no status)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'statusMagnitude',
      label:
          'Status Magnitude (Poison: damage/round, Weaken: % damage reduction)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    visualAssetFieldSchema('skills'),
  ],
);

final DbSchema skillMergesSchema = DbSchema(
  id: 'skillMerges',
  label: 'Skill Merges',
  assetPath: 'assets/gamedata/skill_merges.json',
  primaryKeyField: 'id',
  fields: [
    FieldSchema(key: 'id', label: 'ID', type: FieldType.text),
    FieldSchema(
      key: 'inputSkillIDs',
      label: 'Input Skills (exactly 2)',
      type: FieldType.referenceList,
      referenceSchemaId: 'skills',
    ),
    FieldSchema(
      key: 'resultSkillID',
      label: 'Result Skill',
      type: FieldType.reference,
      referenceSchemaId: 'skills',
    ),
  ],
);

final DbSchema skillTreesSchema = DbSchema(
  id: 'skillTrees',
  label: 'Skill Trees',
  assetPath: 'assets/gamedata/skill_trees.json',
  primaryKeyField: 'branchID',
  titleField: 'branchName',
  fields: [
    FieldSchema(key: 'branchID', label: 'Branch ID', type: FieldType.text),
    FieldSchema(
      key: 'professionId',
      label: 'Profession (a class branch; empty for a heritage branch)',
      type: FieldType.reference,
      referenceSchemaId: 'professions',
    ),
    FieldSchema(
      key: 'raceId',
      label: 'Race (a heritage branch; empty for a class branch)',
      type: FieldType.reference,
      referenceSchemaId: 'races',
    ),
    FieldSchema(
        key: 'order',
        label: 'Order on the tree',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(key: 'branchName', label: 'Branch Name', type: FieldType.text),
    FieldSchema(
        key: 'branchName_fr', label: 'Branch Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'skillIds',
      label:
          'Skills, in the order they are learned (each after the one before it)',
      type: FieldType.referenceList,
      referenceSchemaId: 'skills',
    ),
  ],
);

final DbSchema racesSchema = DbSchema(
  id: 'races',
  label: 'Races',
  assetPath: 'assets/gamedata/races.json',
  primaryKeyField: 'raceID',
  titleField: 'raceName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'raceID', label: 'Race ID', type: FieldType.text),
    FieldSchema(key: 'raceName', label: 'Race Name', type: FieldType.text),
    FieldSchema(
        key: 'raceName_fr', label: 'Race Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'powerMedium',
        label:
            'Power Medium (how this race wears its power: banner, paint, mark, ink)',
        type: FieldType.text),
    FieldSchema(
        key: 'powerMediumFr', label: 'Power Medium (FR)', type: FieldType.text),
    FieldSchema(
      key: 'bonusMaxHealth',
      label: 'Bonus Max Health',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'bonusBaseDamage',
      label: 'Bonus Base Damage',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'bonusBaseArmor',
      label: 'Bonus Base Armor',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'startingGoldBonus',
      label: 'Starting Gold Bonus',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'standardSkillID',
      label: 'Standard Starter Skill',
      type: FieldType.reference,
      referenceSchemaId: 'skills',
    ),
    visualAssetFieldSchema('races'),
  ],
);

final DbSchema professionsSchema = DbSchema(
  id: 'professions',
  label: 'Professions',
  assetPath: 'assets/gamedata/professions.json',
  primaryKeyField: 'professionID',
  titleField: 'professionName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(
        key: 'professionID', label: 'Profession ID', type: FieldType.text),
    FieldSchema(
        key: 'professionName', label: 'Profession Name', type: FieldType.text),
    FieldSchema(
        key: 'professionName_fr',
        label: 'Profession Name (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'bonusMaxHealth',
      label: 'Bonus Max Health',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'bonusBaseDamage',
      label: 'Bonus Base Damage',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'bonusBaseArmor',
      label: 'Bonus Base Armor',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'startingGoldBonus',
      label: 'Starting Gold Bonus',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'startingSkillPoints',
      label: 'Starting Skill Points',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'standardSkillID',
      label: 'Standard Starter Skill',
      type: FieldType.reference,
      referenceSchemaId: 'skills',
    ),
    FieldSchema(
      key: 'preferredScalingStat',
      label: 'Loot Affinity (Scaling Stat)',
      type: FieldType.enumeration,
      enumOptions: statScalingOptions,
    ),
    FieldSchema(
      key: 'startingDiceId',
      label: 'Starting Die (owned and equipped at character creation; '
          'empty = the starter die)',
      type: FieldType.reference,
      referenceSchemaId: 'dice',
    ),
    FieldSchema(
      key: 'manaSkillID',
      label: 'Mana Skill (a caster\'s starting mana skill, set on the '
          'starting die\'s Channeling face; empty = none)',
      type: FieldType.reference,
      referenceSchemaId: 'skills',
    ),
    FieldSchema(
      key: 'startingSpellIds',
      label: 'Starting Spells (known from character creation)',
      type: FieldType.referenceList,
      referenceSchemaId: 'spells',
    ),
    visualAssetFieldSchema('professions'),
  ],
);

final DbSchema diceSchema = DbSchema(
  id: 'dice',
  label: 'Dice (Equipment)',
  assetPath: 'assets/gamedata/dice.json',
  primaryKeyField: 'diceName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'diceName', label: 'Dice Name', type: FieldType.text),
    FieldSchema(
        key: 'diceName_fr', label: 'Dice Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'numberOfFaces',
      label: 'Number of Faces (4-12)',
      type: FieldType.integer,
      defaultValue: 6,
    ),
    FieldSchema(
      key: 'professions',
      label: 'Professions (who may buy and use the die; empty = anyone)',
      type: FieldType.referenceList,
      referenceSchemaId: 'professions',
    ),
    FieldSchema(
      key: 'races',
      label: 'Races (who may buy and use the die; empty = anyone)',
      type: FieldType.referenceList,
      referenceSchemaId: 'races',
    ),
    FieldSchema(
      key: 'faces',
      label:
          'Faces [{faceName, type: $faceTypeOptions, value, linkedSkillID, weight, element: $elementOptions, keywords: $faceKeywordOptions}]',
      type: FieldType.json,
    ),
    visualAssetFieldSchema('dice'),
  ],
);

final DbSchema enemiesSchema = DbSchema(
  id: 'enemies',
  label: 'Enemies (Ground)',
  assetPath: 'assets/gamedata/enemies.json',
  primaryKeyField: 'enemyName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'enemyName', label: 'Enemy Name', type: FieldType.text),
    FieldSchema(
        key: 'enemyName_fr', label: 'Enemy Name (FR)', type: FieldType.text),
    // Who the enemy is, shown under its name on the fight's setup card.
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    // How the enemy turns up on a detour or in a zone, and why it attacks:
    // one line is drawn per encounter (index-matched across languages).
    FieldSchema(
        key: 'encounterText',
        label: 'Encounter Lines',
        type: FieldType.stringList),
    FieldSchema(
        key: 'encounterText_fr',
        label: 'Encounter Lines (FR)',
        type: FieldType.stringList),
    // The line used when this enemy leads a random pack.
    FieldSchema(
        key: 'packText', label: 'Pack Line', type: FieldType.multilineText),
    FieldSchema(
        key: 'packText_fr',
        label: 'Pack Line (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'maxHealth',
        label: 'Max Health',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'damage',
        label: 'Damage',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'guile',
        label: 'Guile (resists Perception telegraphing)',
        type: FieldType.integer,
        defaultValue: 0),
    // v1.162: the party's hits of these elements land ×1.5 / ×½.
    FieldSchema(
      key: 'weakTo',
      label: 'Weak to (elements)',
      type: FieldType.multiEnum,
      enumOptions: elementOptions,
    ),
    FieldSchema(
      key: 'resists',
      label: 'Resists (elements)',
      type: FieldType.multiEnum,
      enumOptions: elementOptions,
    ),
    FieldSchema(
        key: 'packEligible',
        label: 'Pack Eligible (may appear in a random 2-3 enemy pack)',
        type: FieldType.boolean,
        defaultValue: false),
    FieldSchema(
      key: 'hunterAlignment',
      label:
          'Hunter Of (alignment this enemy hunts: Good = stalks Good characters; empty = ordinary enemy)',
      type: FieldType.enumeration,
      enumOptions: affinityAlignmentOptions,
    ),
    FieldSchema(
        key: 'hunterTier',
        label: 'Hunter Tier (1 = from chapter 1, 2 = from chapter 3)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'xpReward',
        label: 'XP Reward',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'goldReward',
        label: 'Gold Reward',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'minChapter',
      label: 'Min Chapter (earliest a random excursion may draw this enemy)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'lootTable',
      label: 'Loot Table [{itemID, dropRate}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'skillMoves',
      label:
          'Skill Moves [{skillID, condition: $skillMoveConditionOptions, requiredElement, chance, healthThreshold, attackCountRequirement, playerPatternThreshold, blockThreshold, priority}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'phases',
      label:
          'Boss Phases [{healthThreshold (%), name, nameFr, message, messageFr, damageMultiplier, healPercent, cleanse, addMoves: [skill moves], replaceMoves}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'biomes',
      label: 'Lives in (biomes)',
      type: FieldType.referenceList,
      referenceSchemaId: 'biomes',
      help: 'The biomes it lives in (biomes.json, v1.197): a champion on a '
          'road through one of them is drawn from those that live there. '
          'None for a foe with no home (a boss of one place, a summoned '
          'thing).',
    ),
    visualAssetFieldSchema('enemies'),
  ],
);

final DbSchema enemyShipsSchema = DbSchema(
  id: 'enemy_ships',
  label: 'Enemy Ships (FTL)',
  assetPath: 'assets/gamedata/enemy_ships.json',
  primaryKeyField: 'shipName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'shipName', label: 'Ship Name', type: FieldType.text),
    FieldSchema(
        key: 'shipName_fr', label: 'Ship Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'displayName', label: 'Display Name', type: FieldType.text),
    FieldSchema(
        key: 'displayName_fr',
        label: 'Display Name (FR)',
        type: FieldType.text),
    FieldSchema(
      key: 'minChapter',
      label: 'Min Chapter (first chapter this ship may sail against you)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'maxHull',
        label: 'Max Hull',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'rooms',
      label:
          'Rooms {helm, guns, bulwark, hold}: system pips per room (helm = 8% evasion each, bulwark = one shield layer each, guns = charge, hold = repairs)',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'weapons',
      label:
          'Weapons [{weaponName, weaponName_fr, damage, chargeTurns, piercesShield, setsFire, roomDamage, ranges}] (ranges: close/medium/long; empty = all)',
      type: FieldType.json,
    ),
    // What the ship does beyond firing (see ship_battle.dart): flee runs
    // for long range when hurt and escapes; marksman keeps its distance and
    // shoots the crew; ram comes alongside and rams once; boarder comes
    // alongside and boards every third round.
    FieldSchema(
      key: 'habit',
      label: 'Battle Habit',
      type: FieldType.enumeration,
      enumOptions: ['none', 'flee', 'marksman', 'ram', 'boarder'],
      defaultValue: 'none',
    ),
    FieldSchema(
      key: 'crew',
      label: 'Crew (repairs made or fires fought per round)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'boardingCrew',
      label:
          'Boarding Crew (enemies.json ids: the pack fought when either side boards; empty = never boards)',
      type: FieldType.referenceList,
      referenceSchemaId: 'enemies',
    ),
    FieldSchema(
      key: 'boardingChance',
      label:
          'Boarding Chance (0-1: odds per enemy turn of boarding while the Eel\'s bulwark is down)',
      type: FieldType.decimal,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'prizePartId',
      label:
          'Prize Part (ship_parts.json id taken aboard when this ship is boarded and won)',
      type: FieldType.reference,
      referenceSchemaId: 'ship_parts',
    ),
    FieldSchema(
      key: 'prizeGold',
      label: 'Prize Gold (from the hold when this ship is boarded and won)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
        key: 'xpReward',
        label: 'XP Reward',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'goldReward',
        label: 'Gold Reward',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'beast',
      label:
          'Sea Beast {waters: [chapters], regen, diveEvery, breach, fleeShare, trophyPartId, omen, sighting, hunt (+ _fr)}: a beast, never a raider (see sea_beasts.dart)',
      type: FieldType.json,
    ),
    visualAssetFieldSchema('enemy_ships'),
  ],
);

final DbSchema shipsSchema = DbSchema(
  id: 'ships',
  label: 'Player Ships',
  assetPath: 'assets/gamedata/ships.json',
  primaryKeyField: 'shipID',
  titleField: 'shipName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'shipID', label: 'Ship ID', type: FieldType.text),
    FieldSchema(key: 'shipName', label: 'Ship Name', type: FieldType.text),
    FieldSchema(
        key: 'shipName_fr', label: 'Ship Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'baseMaxHull',
        label: 'Base Max Hull',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'rooms',
      label:
          'Rooms {helm, guns, bulwark, hold}: base system pips per room, before parts',
      type: FieldType.json,
    ),
    FieldSchema(
        key: 'weaponSlots',
        label: 'Weapon Slots',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'shieldSlots',
        label: 'Shield Slots',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'utilitySlots',
        label: 'Utility Slots',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'sailSlots',
      label: 'Sail Slots (painted sigils aboard at once)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'turnSeconds',
      label:
          'Turn Seconds (time to give a battle turn\'s orders, before parts)',
      type: FieldType.integer,
      defaultValue: 20,
    ),
    visualAssetFieldSchema('ships'),
  ],
);

final DbSchema shipPartsSchema = DbSchema(
  id: 'ship_parts',
  label: 'Ship Parts',
  assetPath: 'assets/gamedata/ship_parts.json',
  primaryKeyField: 'partID',
  titleField: 'partName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'partID', label: 'Part ID', type: FieldType.text),
    FieldSchema(key: 'partName', label: 'Part Name', type: FieldType.text),
    FieldSchema(
        key: 'partName_fr', label: 'Part Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'slotType',
      label: 'Slot Type',
      type: FieldType.enumeration,
      enumOptions: slotTypeOptions,
    ),
    FieldSchema(
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
        key: 'battleActionLabel',
        label: 'Battle Action Label',
        type: FieldType.text),
    FieldSchema(
        key: 'battleActionLabel_fr',
        label: 'Battle Action Label (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'damageAmount',
        label: 'Damage Amount (a weapon: hull damage per shot)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'chargeTurns',
      label: 'Charge Turns (a weapon: turns to ready between shots)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'piercesShield',
      label: 'Pierces Shield (ignores the bulwark\'s layers)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'setsFire',
      label: 'Sets Fire (the room it lands in burns)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'roomDamage',
      label: 'Room Damage (system pips knocked off the room it lands in)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'roomBonus',
      label: 'Room Bonus {helm, guns, bulwark, hold}: pips this part adds',
      type: FieldType.json,
    ),
    // The shot a weapon fires (ship_combat.dart ShipAmmo): it is the
    // weapon's, not picked in battle.
    FieldSchema(
      key: 'ammo',
      label: 'Shot (round, chain: tears the helm, grape: slows repairs, '
          'heated: sets fire)',
      type: FieldType.enumeration,
      enumOptions: const ['round', 'chain', 'grape', 'heated'],
      defaultValue: 'round',
    ),
    FieldSchema(
      key: 'ranges',
      label:
          'Ranges (a weapon\'s reach in a ship battle: close/medium/long; none = all)',
      type: FieldType.multiEnum,
      enumOptions: ['close', 'medium', 'long'],
    ),
    FieldSchema(
      key: 'turnSecondsBonus',
      label: 'Turn Seconds Bonus (seconds this part adds to a battle turn)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'tetherRounds',
      label:
          'Tether Rounds (a weapon: rounds a landed hit holds a sea beast on the line)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'beastGear',
      label:
          'Beast Gear (sold at the Harbor only once a sea beast has been seen)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'trophyOf',
      label:
          'Trophy Of (enemy_ships.json beast id: fitted free once it is slain, hidden until then)',
      type: FieldType.reference,
      referenceSchemaId: 'enemy_ships',
    ),
    visualAssetFieldSchema('ship_parts'),
    FieldSchema(
      key: 'sailPower',
      label:
          'Sail Power (painted sail only: flight, foresight, hearth, windknot, voidmark)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'sailMedium',
      label:
          'Sail Medium (the race whose way it is painted in; matching the character doubles it)',
      type: FieldType.reference,
      referenceSchemaId: 'races',
    ),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
  ],
);

final DbSchema questsSchema = DbSchema(
  id: 'quests',
  label: 'Quests',
  assetPath: 'assets/gamedata/quests.json',
  primaryKeyField: 'questID',
  titleField: 'questName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'questID', label: 'Quest ID', type: FieldType.text),
    FieldSchema(key: 'questName', label: 'Quest Name', type: FieldType.text),
    FieldSchema(
        key: 'questName_fr', label: 'Quest Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'chapter',
        label: 'Chapter',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
      key: 'category',
      label: 'Category',
      type: FieldType.enumeration,
      enumOptions: questCategoryOptions,
    ),
    FieldSchema(key: 'difficulty', label: 'Difficulty', type: FieldType.text),
    FieldSchema(
      key: 'requiredAlignment',
      label: 'Required Alignment',
      type: FieldType.enumeration,
      enumOptions: alignmentOptions,
    ),
    FieldSchema(
      key: 'objectives',
      label:
          'Objectives [{description, type: [Kill, Gather, Talk, Reach], targetEnemyID (or targetEnemyIDs, any of which counts; countFromAccept: only kills after the quest is taken), targetItemID, targetNPCName, targetNPCID (npcs.json id, for Talk gating), locationID, requiredAmount}]',
      type: FieldType.json,
    ),
    FieldSchema(
        key: 'rewardGold',
        label: 'Reward Gold',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'rewardXP',
        label: 'Reward XP',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'rewardItemID',
      label: 'Reward Item ID',
      type: FieldType.reference,
      referenceSchemaId: 'items',
    ),
    FieldSchema(
      key: 'alignmentChange',
      label: 'Alignment Change',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'nextQuestID',
      label: 'Next Quest ID',
      type: FieldType.reference,
      referenceSchemaId: 'quests',
    ),
    FieldSchema(
      key: 'rewardDiceID',
      label: 'Reward Dice ID',
      type: FieldType.reference,
      referenceSchemaId: 'dice',
    ),
    FieldSchema(
      key: 'rewardAllyId',
      label: 'Reward Ally ID',
      type: FieldType.reference,
      referenceSchemaId: 'companions',
    ),
    FieldSchema(
      key: 'grantsBannerPieceId',
      label: 'Grants Banner Piece ID (empty = none)',
      type: FieldType.text,
    ),
    FieldSchema(
        key: 'npcDialogueText',
        label: 'NPC Dialogue Text',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'npcDialogueText_fr',
        label: 'NPC Dialogue Text (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'requiredGold',
        label: 'Required Gold',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'requiredFlags',
        label: 'Required Flags',
        type: FieldType.stringList),
    FieldSchema(
      key: 'questChoices',
      label:
          'Quest Choices [{buttonText, goldModifier, alignmentModifier, flagToAdd, nextEventID, actionType, lockedText}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'turnInChoices',
      label:
          'Turn-in Choices [{choiceText, choiceText_fr, rewardGold, alignmentChange, flag, approvalMods: {companionId|*: n}, resultText, resultText_fr}]',
      type: FieldType.json,
    ),
    visualAssetFieldSchema('quests'),
  ],
);

final DbSchema shopsSchema = DbSchema(
  id: 'shops',
  label: 'Shops',
  assetPath: 'assets/gamedata/shops.json',
  primaryKeyField: 'shopID',
  titleField: 'shopName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'shopID', label: 'Shop ID', type: FieldType.text),
    FieldSchema(key: 'shopName', label: 'Shop Name', type: FieldType.text),
    FieldSchema(
        key: 'shopName_fr', label: 'Shop Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'shopDescription',
        label: 'Shop Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'shopDescription_fr',
        label: 'Shop Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'minChapter',
        label: 'First chapter it can turn up on a detour or expedition',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
        key: 'detourEligible',
        label: 'Can turn up on a detour or expedition (off for house shops)',
        type: FieldType.boolean,
        defaultValue: true),
    FieldSchema(
        key: 'unlockLevel',
        label: 'Unlock Level',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
        key: 'buildCost',
        label: 'Build Cost',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'initialStock',
      label: 'Initial Stock',
      type: FieldType.referenceList,
      referenceSchemaId: 'items',
    ),
    FieldSchema(
      key: 'stockQuantities',
      label: 'Stock Quantities {itemID: quantity} — how many units of each '
          'Initial Stock item this shop has to sell (missing entries default '
          'to 1). Sold-out items stop being purchasable; stock never '
          'replenishes.',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'diceStock',
      label: 'Dice For Sale',
      type: FieldType.referenceList,
      referenceSchemaId: 'dice',
    ),
    FieldSchema(
      key: 'merchantSpecialties',
      label: 'Merchant Specialties',
      type: FieldType.multiEnum,
      enumOptions: itemTypeOptions,
    ),
    FieldSchema(
      key: 'faction',
      label: 'Faction',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
      help: 'The faction the shop belongs to, if any: its prices follow '
          'the character\'s standing with them (+40% Hostile ... -25% '
          'Sworn), and it won\'t trade with someone it hunts.',
    ),
    visualAssetFieldSchema('shops'),
  ],
);

final DbSchema gatesSchema = DbSchema(
  id: 'gates',
  label: 'Gates',
  assetPath: 'assets/gamedata/gates.json',
  primaryKeyField: 'gateID',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'gateID', label: 'Gate ID', type: FieldType.text),
    FieldSchema(
      key: 'isPermanentGate',
      label: 'Permanent Gate',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'possibleMonsters',
      label: 'Possible Monsters',
      type: FieldType.referenceList,
      referenceSchemaId: 'enemies',
    ),
    visualAssetFieldSchema('gates'),
  ],
);

final DbSchema adventureNodesSchema = DbSchema(
  id: 'adventure_nodes',
  label: 'Adventure Node Types',
  assetPath: 'assets/gamedata/adventure_nodes.json',
  primaryKeyField: 'nodeID',
  titleField: 'displayName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'nodeID', label: 'Node ID', type: FieldType.text),
    FieldSchema(
        key: 'displayName', label: 'Display Name', type: FieldType.text),
    FieldSchema(
        key: 'displayName_fr',
        label: 'Display Name (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'flavorText', label: 'Flavor Text', type: FieldType.multilineText),
    FieldSchema(
        key: 'flavorText_fr',
        label: 'Flavor Text (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'category',
      label: 'Category',
      type: FieldType.enumeration,
      enumOptions: nodeCategoryOptions,
    ),
    FieldSchema(
      key: 'difficulty',
      label: 'Difficulty',
      type: FieldType.enumeration,
      enumOptions: nodeDifficultyOptions,
    ),
    FieldSchema(
      key: 'possibleEnemies',
      label: 'Possible Enemies (Combat)',
      type: FieldType.referenceList,
      referenceSchemaId: 'enemies',
    ),
    FieldSchema(
      key: 'possibleEnemyShips',
      label: 'Possible Enemy Ships (Combat, FTL)',
      type: FieldType.referenceList,
      referenceSchemaId: 'enemy_ships',
    ),
    FieldSchema(
      key: 'storyEventID',
      label: 'Story Event ID (Event)',
      type: FieldType.reference,
      referenceSchemaId: storyEventsReferenceId,
    ),
    FieldSchema(
      key: 'shopID',
      label: 'Shop ID (Shop)',
      type: FieldType.reference,
      referenceSchemaId: 'shops',
    ),
    FieldSchema(
        key: 'healPercent',
        label: 'Heal Percent (Rest)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'guaranteedLoot',
      label: 'Guaranteed Loot (Treasure)',
      type: FieldType.referenceList,
      referenceSchemaId: 'items',
    ),
    FieldSchema(
      key: 'goldReward',
      label: 'Gold Reward (Treasure)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    visualAssetFieldSchema('adventure_nodes'),
  ],
);

final DbSchema companionsSchema = DbSchema(
  id: 'companions',
  label: 'Companions',
  assetPath: 'assets/gamedata/companions.json',
  primaryKeyField: 'companionID',
  titleField: 'companionName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(
        key: 'companionID', label: 'Companion ID', type: FieldType.text),
    FieldSchema(
        key: 'companionName', label: 'Companion Name', type: FieldType.text),
    FieldSchema(
        key: 'companionName_fr',
        label: 'Companion Name (FR)',
        type: FieldType.text),
    FieldSchema(
      key: 'raceId',
      label: 'Race',
      type: FieldType.reference,
      referenceSchemaId: 'races',
    ),
    FieldSchema(
      key: 'professionId',
      label: 'Profession',
      type: FieldType.reference,
      referenceSchemaId: 'professions',
    ),
    FieldSchema(
      key: 'signatureDiceId',
      label: 'Signature Die (fixed, never player-swappable)',
      type: FieldType.reference,
      referenceSchemaId: 'dice',
    ),
    FieldSchema(
      key: 'recruitQuestId',
      label: 'Recruit Quest ID',
      type: FieldType.reference,
      referenceSchemaId: 'quests',
    ),
    FieldSchema(
      key: 'requiredHouseId',
      label:
          'Required House ID (empty = joins active party unconditionally, still subject to capacity)',
      type: FieldType.reference,
      referenceSchemaId: 'houses',
    ),
    FieldSchema(
      key: 'critLine',
      label: 'Critical Hit Banter (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'critLineFr',
      label: 'Critical Hit Banter (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'dodgeLine',
      label: 'Dodge Banter (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'dodgeLineFr',
      label: 'Dodge Banter (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'fightStartLine',
      label: 'Fight Start Banter (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'fightStartLineFr',
      label: 'Fight Start Banter (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'packLine',
      label: 'Pack Sighted Banter (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'packLineFr',
      label: 'Pack Sighted Banter (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'koLine',
      label: 'Ally Knocked Out Banter (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'koLineFr',
      label: 'Ally Knocked Out Banter (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'chestLine',
      label: 'Big Chest Banter (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'chestLineFr',
      label: 'Big Chest Banter (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'approvesGood',
      label: 'Approval of a Kind Deed (-3 to 3)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'approvesEvil',
      label: 'Approval of a Cruel Deed (-3 to 3)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'approvesProfit',
      label: 'Approval of Filling the Purse (-3 to 3)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'devotedLine',
      label: 'Devoted Line (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'devotedLineFr',
      label: 'Devoted Line (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'warnLine',
      label: 'Losing Patience Line (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'warnLineFr',
      label: 'Losing Patience Line (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'leaveLine',
      label: 'Walking Out Line (EN)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'leaveLineFr',
      label: 'Walking Out Line (FR)',
      type: FieldType.text,
    ),
    visualAssetFieldSchema('companions'),
  ],
);

final DbSchema housesSchema = DbSchema(
  id: 'houses',
  label: 'Houses (Camp)',
  assetPath: 'assets/gamedata/houses.json',
  primaryKeyField: 'houseID',
  titleField: 'houseName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'houseID', label: 'House ID', type: FieldType.text),
    FieldSchema(key: 'houseName', label: 'House Name', type: FieldType.text),
    FieldSchema(
        key: 'houseName_fr', label: 'House Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'buildCost',
        label: 'Build Cost (Gold)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'partyCapacityBonus',
      label: 'Party Capacity Bonus',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'partyHealthBonus',
      label: 'Party Health Bonus (%, every fight once built)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'partyDamageBonus',
      label: 'Party Damage Bonus (%, every fight once built)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'unlocksShopId',
      label: 'Unlocks Shop',
      type: FieldType.reference,
      referenceSchemaId: 'shops',
    ),
    FieldSchema(
      key: 'requiredFlags',
      label:
          'Required Flags (all must be set to build; a zone\'s rewardFlag gates on clearing that zone)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'requiredAllyId',
      label: 'Required Ally (the house is shown once they have joined)',
      type: FieldType.reference,
      referenceSchemaId: 'companions',
    ),
    visualAssetFieldSchema('houses'),
  ],
);

final DbSchema zonesSchema = DbSchema(
  id: 'zones',
  label: 'Zones (Expeditions)',
  assetPath: 'assets/gamedata/zones.json',
  primaryKeyField: 'zoneID',
  titleField: 'zoneName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'zoneID', label: 'Zone ID', type: FieldType.text),
    FieldSchema(key: 'zoneName', label: 'Zone Name', type: FieldType.text),
    FieldSchema(
        key: 'zoneName_fr', label: 'Zone Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'chapter',
        label: 'Chapter',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
      key: 'expeditionCount',
      label: 'Expeditions In This Zone',
      type: FieldType.integer,
      defaultValue: 3,
    ),
    FieldSchema(
      key: 'mapTheme',
      label: 'Flavor Theme',
      type: FieldType.enumeration,
      enumOptions: mapThemeOptions,
    ),
    FieldSchema(
        key: 'flavorText', label: 'Flavor Text', type: FieldType.multilineText),
    FieldSchema(
        key: 'flavorText_fr',
        label: 'Flavor Text (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'rewardGold',
      label: 'Reward Gold (on zone completion)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'rewardItemId',
      label: 'Reward Item ID',
      type: FieldType.reference,
      referenceSchemaId: 'items',
    ),
    FieldSchema(
      key: 'rewardDiceId',
      label: 'Reward Dice ID',
      type: FieldType.reference,
      referenceSchemaId: 'dice',
    ),
    FieldSchema(
      key: 'rewardAllyId',
      label: 'Reward Ally ID',
      type: FieldType.reference,
      referenceSchemaId: 'companions',
    ),
    FieldSchema(
      key: 'rewardFlag',
      label:
          'Reward Flag (empty = none) — for narrative beats short of a full item/ally, e.g. a story flag',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'tier',
      label: 'Tier (1 = the chapter\'s easiest zone; each tier is 10% harder)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'bossEnemyId',
      label: 'Boss Enemy (fought after the last event; guards the reward)',
      type: FieldType.reference,
      referenceSchemaId: 'enemies',
    ),
    FieldSchema(
      key: 'bossFlavorText',
      label: 'Boss Flavor Text (the boss event\'s narration)',
      type: FieldType.multilineText,
    ),
    FieldSchema(
      key: 'bossFlavorTextFr',
      label: 'Boss Flavor Text (FR)',
      type: FieldType.multilineText,
    ),
    FieldSchema(
      key: 'midpointFlavorText',
      label: 'Midpoint Flavor Text (a beat shown halfway through the zone)',
      type: FieldType.multilineText,
    ),
    FieldSchema(
      key: 'midpointFlavorTextFr',
      label: 'Midpoint Flavor Text (FR)',
      type: FieldType.multilineText,
    ),
    FieldSchema(
      key: 'requiredFlags',
      label:
          'Required Flags (all must be set to begin; another zone\'s rewardFlag gates on that zone)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'recommendedLevel',
      label: 'Recommended Level (shown on the zone card; advice, not a gate)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'isMainZone',
      label:
          'Main Zone (the chapter\'s main quest runs it; never offered as an expedition)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'discoversPlaceIds',
      label:
          'Discovers Places (story node ids: the first at the midpoint, the rest on clearing the zone)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'kind',
      label:
          'Kind (clear: random events; escort: wagons whose load pays; delivery: a parcel with a deadline)',
      type: FieldType.enumeration,
      enumOptions: const ['clear', 'escort', 'delivery'],
    ),
    FieldSchema(
      key: 'deadlineDays',
      label: 'Delivery Deadline (days; default: stages + 2)',
      type: FieldType.integer,
    ),
    FieldSchema(
      key: 'destinationName',
      label: 'Delivery Destination',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'destinationName_fr',
      label: 'Delivery Destination (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'location',
      label: 'Location (geography)',
      type: FieldType.reference,
      referenceSchemaId: 'geography',
      help: 'Where the expedition takes place: a place of geography.json '
          '(v1.197).',
    ),
    visualAssetFieldSchema('zones'),
  ],
);

final DbSchema achievementsSchema = DbSchema(
  id: 'achievements',
  label: 'Achievements',
  assetPath: 'assets/gamedata/achievements.json',
  primaryKeyField: 'achievementID',
  titleField: 'achievementName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(
        key: 'achievementID', label: 'Achievement ID', type: FieldType.text),
    FieldSchema(
        key: 'achievementName',
        label: 'Achievement Name',
        type: FieldType.text),
    FieldSchema(
        key: 'achievementName_fr',
        label: 'Achievement Name (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    visualAssetFieldSchema('achievements'),
  ],
);

final DbSchema npcsSchema = DbSchema(
  id: 'npcs',
  label: 'NPCs',
  assetPath: 'assets/gamedata/npcs.json',
  primaryKeyField: 'npcID',
  titleField: 'npcName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'npcID', label: 'NPC ID', type: FieldType.text),
    FieldSchema(key: 'npcName', label: 'NPC Name', type: FieldType.text),
    FieldSchema(
        key: 'npcName_fr', label: 'NPC Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'chapter',
        label: 'Chapter',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (French)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'requiredFlag',
      label: 'Required Flag (empty = always discoverable)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'dialogueLines',
      label: 'Dialogue Lines',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'dialogueLines_fr',
      label: 'Dialogue Lines (French)',
      type: FieldType.stringList,
    ),
    visualAssetFieldSchema('npcs'),
  ],
);

/// From chapter 3 each chapter is an open loop around the camp (see
/// chapter_loop.dart): its places and expeditions first, then, once
/// enough of them are done, its main quest and a piece of the banner.
final DbSchema chaptersSchema = DbSchema(
  id: 'chapters',
  label: 'Chapters (open loops)',
  assetPath: 'assets/gamedata/chapters.json',
  primaryKeyField: 'chapterID',
  titleField: 'title',
  fields: [
    FieldSchema(key: 'chapterID', label: 'Chapter ID', type: FieldType.text),
    FieldSchema(
        key: 'chapter',
        label: 'Chapter (places and zones with this chapter belong to it)',
        type: FieldType.integer,
        defaultValue: 3),
    FieldSchema(key: 'label', label: 'Label', type: FieldType.text),
    FieldSchema(key: 'label_fr', label: 'Label (FR)', type: FieldType.text),
    FieldSchema(key: 'title', label: 'Title', type: FieldType.text),
    FieldSchema(key: 'title_fr', label: 'Title (FR)', type: FieldType.text),
    FieldSchema(
        key: 'campNodeId',
        label: 'Camp scene (the story stands here while the chapter is open)',
        type: FieldType.text),
    FieldSchema(
      key: 'activityGoal',
      label:
          'Activity goal (expeditions cleared and things done in the chapter\'s places before the main quest opens)',
      type: FieldType.integer,
      defaultValue: 6,
    ),
    FieldSchema(
      key: 'mainQuestNeedsPlaceIds',
      label: 'Places the main quest also needs found',
      type: FieldType.stringList,
    ),
    FieldSchema(
        key: 'mainQuestTitle', label: 'Main quest title', type: FieldType.text),
    FieldSchema(
        key: 'mainQuestTitle_fr',
        label: 'Main quest title (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'mainQuestHint',
        label: 'Main quest hint (shown while it is shut)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'mainQuestHint_fr',
        label: 'Main quest hint (FR)',
        type: FieldType.multilineText),
  ],
);

final DbSchema portsSchema = DbSchema(
  id: 'ports',
  label: 'Ports (Boat)',
  assetPath: 'assets/gamedata/ports.json',
  primaryKeyField: 'portID',
  titleField: 'portName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'portID', label: 'Port ID', type: FieldType.text),
    FieldSchema(key: 'portName', label: 'Port Name', type: FieldType.text),
    FieldSchema(
        key: 'portName_fr', label: 'Port Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'chapter',
        label: 'Chapter (the port appears on the boat\'s chart from here on)',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'zoneIds',
      label: 'Zones reachable from this port',
      type: FieldType.referenceList,
      referenceSchemaId: 'zones',
    ),
    FieldSchema(
      key: 'shopIds',
      label: 'Shops trading at this port',
      type: FieldType.referenceList,
      referenceSchemaId: 'shops',
    ),
    FieldSchema(
      key: 'voyageLength',
      label: 'Voyage Length (days at sea to reach it)',
      type: FieldType.integer,
      defaultValue: 2,
    ),
    // The waters a sea fight on the way here is fought on
    // (sea_battlefield.dart SeaWaters): their colour, waves and drift.
    FieldSchema(
      key: 'waters',
      label: 'Waters (sea fights on the way here)',
      type: FieldType.enumeration,
      enumOptions: const ['open', 'shallows', 'drowned', 'abyss', 'ashen'],
      defaultValue: 'open',
    ),
    FieldSchema(
      key: 'isHome',
      label: 'Home Port (the camp\'s own shore; exactly one)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'requiredFlags',
      label: 'Required Flags (all must be set for the port to appear)',
      type: FieldType.stringList,
    ),
    visualAssetFieldSchema('ports'),
  ],
);

final DbSchema spellsSchema = DbSchema(
  id: 'spells',
  label: 'Spells (Mana)',
  assetPath: 'assets/gamedata/spells.json',
  primaryKeyField: 'spellID',
  titleField: 'spellName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'spellID', label: 'Spell ID', type: FieldType.text),
    FieldSchema(key: 'spellName', label: 'Spell Name', type: FieldType.text),
    // The on-screen effect the spell plays in a fight (skill_vfx.dart).
    FieldSchema(
      key: 'vfx',
      label: 'Combat effect',
      type: FieldType.enumeration,
      enumOptions: vfxEnumOptions,
    ),
    FieldSchema(
        key: 'spellName_fr', label: 'Spell Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'professionID',
      label: 'Profession (only this profession can learn it; empty = anyone)',
      type: FieldType.reference,
      referenceSchemaId: 'professions',
    ),
    FieldSchema(
        key: 'manaCost',
        label: 'Mana Cost',
        type: FieldType.integer,
        defaultValue: 2),
    FieldSchema(
      key: 'effect',
      label: 'Effect',
      type: FieldType.enumeration,
      enumOptions: spellEffectOptions,
    ),
    FieldSchema(
      key: 'target',
      label: 'Target',
      type: FieldType.enumeration,
      enumOptions: spellTargetOptions,
    ),
    FieldSchema(
        key: 'amount',
        label: 'Amount (flat damage added to the caster\'s own / healing / '
            'block; healing and block grow with level)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'damageMultiplier',
        label: 'Damage Multiplier (Damage spells: (caster damage + Amount + '
            'stat/2) x this)',
        type: FieldType.decimal,
        defaultValue: 1.0),
    FieldSchema(
      key: 'scalingStat',
      label: 'Grows With (half the score is added to Amount)',
      type: FieldType.enumeration,
      enumOptions: spellScalingOptions,
    ),
    FieldSchema(
      key: 'element',
      label: 'Element',
      type: FieldType.enumeration,
      enumOptions: elementOptions,
    ),
    FieldSchema(
      key: 'inflictsStatus',
      label: 'Inflicts Status (Damage/Status spells on an enemy)',
      type: FieldType.enumeration,
      enumOptions: statusEffectOptions,
    ),
    FieldSchema(
        key: 'statusDuration',
        label: 'Status Duration (turns)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'statusMagnitude',
        label: 'Status Magnitude (Poison damage / Weaken %)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'battleMessage', label: 'Battle Message', type: FieldType.text),
    FieldSchema(
        key: 'battleMessage_fr',
        label: 'Battle Message (FR)',
        type: FieldType.text),
    visualAssetFieldSchema('spells'),
  ],
);

final DbSchema itemSetsSchema = DbSchema(
  id: 'item_sets',
  label: 'Item Sets',
  assetPath: 'assets/gamedata/item_sets.json',
  primaryKeyField: 'setName',
  fields: [
    FieldSchema(key: 'setName', label: 'Set Name', type: FieldType.text),
    FieldSchema(key: 'setNameFr', label: 'Set Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'itemIds',
      label: 'Item IDs (the pieces of this set)',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'bonuses',
      label:
          'Bonuses [{pieces, attackDamage, armor, critChance, dodgeChance, thorns, lifestealPercent, manaOnHit, description, descriptionFr}]',
      type: FieldType.json,
    ),
  ],
);

/// What the companions say about the player's choices (see
/// lib/data/companion_remarks.dart): one record per companion and trigger,
/// with the lines they pick from.
final DbSchema companionRemarksSchema = DbSchema(
  id: 'companion_remarks',
  label: 'Companion Remarks',
  assetPath: 'assets/gamedata/companion_remarks.json',
  primaryKeyField: 'remarkID',
  titleField: 'remarkID',
  fields: [
    FieldSchema(key: 'remarkID', label: 'Remark ID', type: FieldType.text),
    FieldSchema(
      key: 'companionID',
      label: 'Companion',
      type: FieldType.reference,
      referenceSchemaId: 'companions',
    ),
    FieldSchema(
      key: 'trigger',
      label: 'When they say it',
      type: FieldType.enumeration,
      enumOptions: remarkTriggerOptions,
      help: 'kindApproved / kindDisapproved: a kind deed they like / '
          'dislike. cruelApproved, cruelDisapproved, profitApproved, '
          'profitDisapproved: the same for cruelty and for gold earned. '
          'approved / disapproved: a scene\'s own reaction. checkPassed, '
          'checkFailed, sneakedPast: a check. drink: a drink at the camp. '
          'choice: one story choice, named below.',
    ),
    FieldSchema(
      key: 'choiceKey',
      label: 'Story choice',
      type: FieldType.text,
      help: 'Only with the trigger "choice": a flag the choice sets, or '
          'nodeId#index (the choice\'s place in its scene, counting from 0).',
    ),
    FieldSchema(
      key: 'note',
      label: 'Note for editors',
      type: FieldType.text,
      help: 'What the choice is, so the lines can be read in context.',
    ),
    FieldSchema(
      key: 'lines',
      label: 'Lines',
      type: FieldType.stringList,
      help: 'One is said at a time; all are used before any repeats.',
    ),
    FieldSchema(
      key: 'lines_fr',
      label: 'Lines (French)',
      type: FieldType.stringList,
      help: 'In the same order as the English. « vous » to the player, '
          'nothing that agrees with the player\'s gender. Left empty, the '
          'English is used.',
    ),
  ],
);

/// The factions (see lib/data/factions.dart): the Lantern Dominion and the
/// five clans, the Choir and the Pit, and the tribes. Every one of them
/// offers signs (see lib/data/signs.dart) and keeps the character's
/// standing.
final DbSchema factionsSchema = DbSchema(
  id: 'factions',
  label: 'Factions',
  assetPath: 'assets/gamedata/factions.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Faction ID', type: FieldType.text),
    FieldSchema(
      key: 'kind',
      label: 'Kind',
      type: FieldType.enumeration,
      enumOptions: [for (final k in PatronKind.values) k.name],
      help: 'clan: the Dominion and the five clans, with sub-clans and a '
          'place in the relations table. tribe: met on the way, offers half '
          'as often. otherworld: the Choir and the Pit, who shut each other '
          'out for the life. lost: a dead clan (the Open Hand), with no '
          'standing: a remembrance stage (flags open_hand_1..6), and its '
          'signs come as "Your own hand", a fourth card.',
    ),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'short',
      label: 'Short name',
      type: FieldType.text,
      help: 'One word, for an offer\'s standing preview: Compact, Mire.',
    ),
    FieldSchema(
        key: 'short_fr', label: 'Short name (FR)', type: FieldType.text),
    FieldSchema(key: 'motto', label: 'Motto', type: FieldType.text),
    FieldSchema(key: 'motto_fr', label: 'Motto (FR)', type: FieldType.text),
    FieldSchema(
      key: 'intro',
      label: 'Intro (the first time they come)',
      type: FieldType.multilineText,
    ),
    FieldSchema(
        key: 'intro_fr', label: 'Intro (FR)', type: FieldType.multilineText),
    FieldSchema(
      key: 'greetings',
      label: 'Greetings',
      type: FieldType.stringList,
      help: 'One is said each time after the first.',
    ),
    FieldSchema(
      key: 'greetings_fr',
      label: 'Greetings (FR)',
      type: FieldType.stringList,
      help: '« vous » to the player; in the same order as the English.',
    ),
    FieldSchema(
      key: 'color',
      label: 'Color',
      type: FieldType.text,
      help: 'A hex color, #RRGGBB.',
    ),
    FieldSchema(
      key: 'icon',
      label: 'Icon',
      type: FieldType.enumeration,
      enumOptions: patronIconNames,
      help: 'A Material icon, drawn in code: factions have no image.',
    ),
    FieldSchema(
      key: 'lean',
      label: 'Alignment lean (-1, 0 or 1)',
      type: FieldType.integer,
      defaultValue: 0,
      help: 'How accepting their gift nudges the alignment.',
    ),
    FieldSchema(
      key: 'startStanding',
      label: 'Starting standing (-100 to 100)',
      type: FieldType.integer,
      defaultValue: 0,
      help: 'Where the character stands with them when the story opens.',
    ),
    FieldSchema(
      key: 'subclans',
      label: 'Sub-clans',
      type: FieldType.referenceList,
      referenceSchemaId: 'subclans',
    ),
    FieldSchema(
      key: 'sponsors',
      label: 'Skill branches they sponsor',
      type: FieldType.referenceList,
      referenceSchemaId: 'skillTrees',
    ),
    FieldSchema(
      key: 'objects',
      label: 'Objects [{itemId, minTier}]',
      type: FieldType.json,
      help: 'Items they may give, each from a standing tier (hunted, '
          'hostile, wary, unknown, known, trusted, sworn).',
    ),
    FieldSchema(
      key: 'sworn',
      label: 'Sworn boon {name, name_fr, effects}',
      type: FieldType.json,
      help: 'Given once to the one faction the character is sworn to. '
          'Effects are written as signs\' effects.',
    ),
    FieldSchema(
      key: 'unlockFlag',
      label: 'Unlock flag',
      type: FieldType.text,
      help: 'A story flag that must be set before they offer; empty for '
          'always.',
    ),
    FieldSchema(
      key: 'minAlignment',
      label: 'Lowest alignment score',
      type: FieldType.text,
      help: 'They offer only at this score or above; empty for no limit.',
    ),
    FieldSchema(
      key: 'maxAlignment',
      label: 'Highest alignment score',
      type: FieldType.text,
      help: 'They offer only at this score or below; empty for no limit.',
    ),
  ],
);

/// The clans' sub-clans: the Dominion's eight Houses and the others' (see
/// lib/data/factions.dart). Each keeps a mark on the character.
final DbSchema subclansSchema = DbSchema(
  id: 'subclans',
  label: 'Sub-clans',
  assetPath: 'assets/gamedata/subclans.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Sub-clan ID', type: FieldType.text),
    FieldSchema(
      key: 'clan',
      label: 'Clan',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
    ),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'line', label: 'Who they are', type: FieldType.multilineText),
    FieldSchema(
        key: 'line_fr',
        label: 'Who they are (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'color',
      label: 'Color',
      type: FieldType.text,
      help: 'A hex color, #RRGGBB: their mark on the clan\'s banner.',
    ),
    FieldSchema(
      key: 'lean',
      label: 'Alignment lean (-1, 0 or 1)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(key: 'favour', label: 'Favour', type: FieldType.text),
    FieldSchema(key: 'favour_fr', label: 'Favour (FR)', type: FieldType.text),
  ],
);

/// How the clans stand with each other (see lib/data/factions.dart): not
/// records but three lists -- the seven steps, the pairs as the story
/// opens, and the coast's history. Edited as JSON.
final DbSchema relationsSchema = DbSchema(
  id: 'relations',
  label: 'Clan relations',
  assetPath: 'assets/gamedata/relations.json',
  primaryKeyField: 'id',
  fields: [
    FieldSchema(
      key: 'steps',
      label: 'Steps [{step, name, name_fr, color}]',
      type: FieldType.json,
      help: 'The seven steps, 1 Blood feud to 7 Allies. 6 and 7 make '
          'allies, 1 to 3 rivals.',
    ),
    FieldSchema(
      key: 'pairs',
      label: 'Pairs [{a, b, step, reason, reason_fr}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'history',
      label: 'History [{year, year_fr, name, name_fr, text, text_fr}]',
      type: FieldType.json,
    ),
  ],
);

/// Titles the character can wear (see lib/data/factions.dart).
final DbSchema titlesSchema = DbSchema(
  id: 'titles',
  label: 'Titles',
  assetPath: 'assets/gamedata/titles.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Title ID', type: FieldType.text),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(key: 'line', label: 'Line', type: FieldType.multilineText),
    FieldSchema(
        key: 'line_fr', label: 'Line (FR)', type: FieldType.multilineText),
    FieldSchema(
      key: 'faction',
      label: 'Faction',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
    ),
    FieldSchema(
      key: 'source',
      label: 'Source',
      type: FieldType.text,
      help: 'offer, tier:known, tier:trusted, tier:sworn, '
          'mark:foe:<sub-clan>, quest or intrigue.',
    ),
    FieldSchema(
      key: 'negative',
      label: 'A bad name',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'effects',
      label: 'Effects [{kind, value, ...}]',
      type: FieldType.json,
      help: 'Written as signs\' effects.',
    ),
  ],
);

/// The eight intrigues (see lib/data/factions.dart): shown in Edit Mode's
/// Clans & Politics screen; no scene plays them yet.
final DbSchema intriguesSchema = DbSchema(
  id: 'intrigues',
  label: 'Intrigues',
  assetPath: 'assets/gamedata/intrigues.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Intrigue ID', type: FieldType.text),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'premise', label: 'Premise', type: FieldType.multilineText),
    FieldSchema(
        key: 'premise_fr',
        label: 'Premise (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'factions',
      label: 'Factions involved',
      type: FieldType.referenceList,
      referenceSchemaId: 'factions',
    ),
    FieldSchema(
      key: 'stages',
      label: 'Stages [{stage, chapter, text, text_fr}]',
      type: FieldType.json,
      help: 'Six: Clue, Hook, Turn, Reveal, Crisis, Choice. The story '
          'marks the one reached with the flag intrigue_<id>_stage_<n>.',
    ),
    FieldSchema(
      key: 'outcomes',
      label: 'Outcomes [{name, name_fr, effects}]',
      type: FieldType.json,
      help: 'effects: [{"faction": "vigil", "delta": 25}, {"subclan": '
          '"inquisition", "mark": "foe"}, {"note": "...", "note_fr": '
          '"..."}].',
    ),
  ],
);

/// The politics events (v1.195, see lib/data/politics_events.dart): what
/// happens on the coast whether or not the character is there, told as
/// "News from the coast".
final DbSchema politicsEventsSchema = DbSchema(
  id: 'politicsEvents',
  label: 'Politics events',
  assetPath: 'assets/gamedata/politics_events.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Event ID', type: FieldType.text),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'trigger',
      label: 'Trigger {chapter, day, flag}',
      type: FieldType.json,
      help: 'Every key given must hold: chapter (the chapter reached is at '
          'least it), day (the story\'s day is at least it), flag or flags '
          '(held), notFlags. A list of triggers fires on any. None: only '
          'a story choice\'s "event" or Edit Mode fires it.',
    ),
    FieldSchema(
      key: 'once',
      label: 'Once',
      type: FieldType.boolean,
      defaultValue: true,
    ),
    FieldSchema(
      key: 'variants',
      label: 'Variants [{conditions, effects, news, news_fr}]',
      type: FieldType.json,
      help: 'The first whose conditions hold fires; the last is the '
          'default. conditions: flags, notFlags, chapterAtLeast, '
          'standingAtLeast {faction: n}, standingAtMost, relationAtLeast '
          '{"a|b": step}, relationAtMost, marks {sub-clan: friend}. effects: '
          'a story choice\'s politics (standing, marks, relations, '
          'offerFrom, intrigue, remembrance, event) and flags.',
    ),
  ],
);

/// The signs the factions offer, three at a time (see lib/data/signs.dart).
final DbSchema signsSchema = DbSchema(
  id: 'signs',
  label: 'Signs',
  assetPath: 'assets/gamedata/signs.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Sign ID', type: FieldType.text),
    FieldSchema(
      key: 'patron',
      label: 'Faction',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
    ),
    FieldSchema(
      key: 'slot',
      label: 'Slot',
      type: FieldType.enumeration,
      enumOptions: [for (final s in SignSlot.values) s.name],
      help: 'strike, guard, mend and spell: one held at a time each (a new '
          'one replaces it). passive: any number.',
    ),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'flavour', label: 'Flavour', type: FieldType.multilineText),
    FieldSchema(
        key: 'flavour_fr',
        label: 'Flavour (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'effects',
      label: 'Effects [{kind, value, ...}]',
      type: FieldType.json,
      help: 'Each {"kind": ..., "value": N}; the text shown is written from '
          'these. strikeElement adds "element"; strikeStatus, guardStatus '
          'and spellStatus take "status" (poison, weaken, stun), "chance", '
          '"duration", "magnitude"; strikeKeyword takes "keyword" (cleave, '
          'pierce, growth, pain, steady); mendCleanse\'s value is how many '
          'afflictions it lifts; stat takes "stat" (luck...). Kinds: '
          '${SignEffectKind.values.map((k) => k.name).join(', ')}.',
    ),
    FieldSchema(
      key: 'requiresPatrons',
      label: 'Duo: both factions',
      type: FieldType.referenceList,
      referenceSchemaId: 'factions',
      help: 'A duo sign is offered only once a sign of each is held.',
    ),
    FieldSchema(
      key: 'pact',
      label: 'Pact (the Pit)',
      type: FieldType.json,
      help: '{"curse": "enemyDamagePercent" | "startHealthPercentLoss" | '
          '"goldPercentLoss", "value": N, "fights": 3}: the curse holds '
          'for that many fights, then the gift. Empty for none.',
    ),
  ],
);

/// The world's places (v1.197, see lib/data/geography.dart): continents,
/// countries, zones, locations and districts, each under its parent.
final DbSchema geographySchema = DbSchema(
  id: 'geography',
  label: 'Geography',
  assetPath: 'assets/gamedata/geography.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(
      key: 'id',
      label: 'Place ID',
      type: FieldType.text,
      help: 'The record\'s key; a story node\'s `location` names it.',
    ),
    FieldSchema(
      key: 'level',
      label: 'Level',
      type: FieldType.enumeration,
      enumOptions: [for (final level in GeoLevel.values) level.name],
      help: 'continent, country, zone, location or district: the parent is '
          'always one level up.',
    ),
    FieldSchema(
      key: 'parent',
      label: 'Parent',
      type: FieldType.reference,
      referenceSchemaId: 'geography',
      help: 'The place one level up; none for a continent.',
    ),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(key: 'blurb', label: 'Blurb', type: FieldType.multilineText),
    FieldSchema(
        key: 'blurb_fr', label: 'Blurb (FR)', type: FieldType.multilineText),
    FieldSchema(
      key: 'biome',
      label: 'Biome (zones only)',
      type: FieldType.reference,
      referenceSchemaId: 'biomes',
    ),
    FieldSchema(
      key: 'ruler',
      label: 'Ruler (countries only)',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
      help: 'The faction that rules it; none for a free land.',
    ),
    FieldSchema(
      key: 'kind',
      label: 'Kind (locations only)',
      type: FieldType.enumeration,
      enumOptions: ['', ...geoKinds],
    ),
    FieldSchema(
      key: 'landmark',
      label: 'Landmark',
      type: FieldType.text,
      help: 'The world map\'s landmark id that lies here (world_map.dart), '
          'or empty. A district with several uses Landmarks instead.',
    ),
    FieldSchema(
      key: 'landmarks',
      label: 'Landmarks',
      type: FieldType.stringList,
      help: 'Several landmark ids, one per line.',
    ),
  ],
);

/// The kinds of land a zone can be (v1.197, see lib/data/geography.dart):
/// what lives and grows there, its weather and hazards, and how the
/// Journey map paints it.
final DbSchema biomesSchema = DbSchema(
  id: 'biomes',
  label: 'Biomes',
  assetPath: 'assets/gamedata/biomes.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Biome ID', type: FieldType.text),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(key: 'blurb', label: 'Blurb', type: FieldType.multilineText),
    FieldSchema(
        key: 'blurb_fr', label: 'Blurb (FR)', type: FieldType.multilineText),
    FieldSchema(
      key: 'fauna',
      label: 'Fauna [{name, name_fr, note, note_fr}]',
      type: FieldType.json,
      help: 'Six, each with a short line.',
    ),
    FieldSchema(
      key: 'flora',
      label: 'Flora [{name, name_fr, note, note_fr}]',
      type: FieldType.json,
      help: 'Six, each with a short line.',
    ),
    FieldSchema(
      key: 'weather',
      label: 'Weather [{name, name_fr}]',
      type: FieldType.json,
      help: 'Three.',
    ),
    FieldSchema(
      key: 'hazards',
      label: 'Hazards [{id, name, name_fr, text, text_fr, push, push_fr, '
          'wait, wait_fr}]',
      type: FieldType.json,
      help: 'Two. A road through the land may hold one: text is its scene '
          '(first person), push and wait the two choices.',
    ),
    FieldSchema(
      key: 'palette',
      label: 'Palette {ground, detail, accent, water}',
      type: FieldType.json,
      help: 'Colours as "#RRGGBB", for the Journey map\'s backdrop.',
    ),
    FieldSchema(
      key: 'pattern',
      label: 'Pattern',
      type: FieldType.enumeration,
      enumOptions: [for (final pattern in BiomePattern.values) pattern.id],
      help: 'What the Journey map paints under a place of this land.',
    ),
  ],
);

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
  questsSchema,
  shopsSchema,
  gatesSchema,
  adventureNodesSchema,
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
];
