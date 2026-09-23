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
const List<String> spellScalingOptions = ['', 'intelligence', 'wisdom'];

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
    FieldSchema(
      key: 'element',
      label: 'Element',
      type: FieldType.enumeration,
      enumOptions: elementOptions,
    ),
    FieldSchema(
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
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
        key: 'description',
        label: 'Description',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'healAmount',
        label: 'Heal Amount',
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
        key: 'description',
        label: 'Description',
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
        key: 'description',
        label: 'Description',
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
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'numberOfFaces',
      label: 'Number of Faces (4-12)',
      type: FieldType.integer,
      defaultValue: 6,
    ),
    FieldSchema(
      key: 'faces',
      label:
          'Faces [{faceName, type: $faceTypeOptions, value, linkedSkillID, weight, element: $elementOptions}]',
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
        key: 'maxHull',
        label: 'Max Hull',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'maxShield',
        label: 'Max Shield',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'weaponDamage',
        label: 'Weapon Damage',
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
      key: 'skillMoves',
      label:
          'Skill Moves [{skillID, condition: $skillMoveConditionOptions, requiredElement, chance, healthThreshold, attackCountRequirement, playerPatternThreshold, blockThreshold, priority}]',
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
        key: 'baseMaxHull',
        label: 'Base Max Hull',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'baseMaxShield',
      label: 'Base Max Shield',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'shieldRegenPerTurn',
      label: 'Shield Regen / Turn',
      type: FieldType.integer,
      defaultValue: 0,
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
      key: 'cooldownTurns',
      label: 'Cooldown Turns',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
        key: 'damageAmount',
        label: 'Damage Amount',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'shieldRestoreAmount',
      label: 'Shield Restore Amount',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'maxShieldBonus',
      label: 'Max Shield Bonus',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'hullRepairAmount',
      label: 'Hull Repair Amount',
      type: FieldType.integer,
      defaultValue: 0,
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
          'Objectives [{description, type: [Kill, Gather, Talk, Reach], targetEnemyID, targetItemID, targetNPCName, targetNPCID (npcs.json id, for Talk gating), locationID, requiredAmount}]',
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
        key: 'shopDescription',
        label: 'Shop Description',
        type: FieldType.multilineText),
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
        key: 'flavorText', label: 'Flavor Text', type: FieldType.multilineText),
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
        key: 'description',
        label: 'Description',
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
      label: 'Main Zone (the chapter\'s headline zone)',
      type: FieldType.boolean,
      defaultValue: false,
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
        key: 'description',
        label: 'Description',
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

final List<DbSchema> gameDbSchemas = [
  itemsSchema,
  itemSetsSchema,
  skillsSchema,
  skillMergesSchema,
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
  housesSchema,
  achievementsSchema,
  zonesSchema,
  portsSchema,
  npcsSchema,
  spellsSchema,
];
