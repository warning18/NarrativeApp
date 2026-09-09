import 'field_schema.dart';

class DbSchema {
  DbSchema({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.primaryKeyField,
    required this.fields,
    this.titleField,
  });

  final String id;
  final String label;
  final String assetPath;
  final String primaryKeyField;
  final String? titleField;
  final List<FieldSchema> fields;
}

const List<String> itemTypeOptions = [
  'Weapon',
  'Armor',
  'Potion',
  'Scroll',
  'Ship',
  'Material',
  'Quest',
  'Artifact',
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
];

const List<String> faceTypeOptions = ['Attack', 'Defend', 'Skill', 'Heal', 'Empty'];

const List<String> slotTypeOptions = ['Weapon', 'Shield', 'Utility'];

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

final DbSchema itemsSchema = DbSchema(
  id: 'items',
  label: 'Items & Equipment',
  assetPath: 'assets/gamedata/items.json',
  primaryKeyField: 'id',
  titleField: 'itemName',
  fields: [
    FieldSchema(key: 'id', label: 'ID', type: FieldType.text),
    FieldSchema(key: 'itemName', label: 'Item Name', type: FieldType.text),
    FieldSchema(
      key: 'itemType',
      label: 'Item Type',
      type: FieldType.enumeration,
      enumOptions: itemTypeOptions,
    ),
    FieldSchema(key: 'damage', label: 'Damage', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
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
    FieldSchema(key: 'attackDamage', label: 'Attack Damage', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'armor', label: 'Armor', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'fireDmgBonus', label: 'Fire Dmg Bonus', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'windDmgBonus', label: 'Wind Dmg Bonus', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'earthDmgBonus', label: 'Earth Dmg Bonus', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'waterDmgBonus', label: 'Water Dmg Bonus', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'elecDmgBonus', label: 'Elec Dmg Bonus', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'fireResist', label: 'Fire Resist', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'windResist', label: 'Wind Resist', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'earthResist', label: 'Earth Resist', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'waterResist', label: 'Water Resist', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'elecResist', label: 'Elec Resist', type: FieldType.integer, defaultValue: 0),
  ],
);

final DbSchema skillsSchema = DbSchema(
  id: 'skills',
  label: 'Skills',
  assetPath: 'assets/gamedata/skills.json',
  primaryKeyField: 'id',
  fields: [
    FieldSchema(key: 'id', label: 'ID (Skill Name)', type: FieldType.text),
    FieldSchema(
      key: 'element',
      label: 'Element',
      type: FieldType.enumeration,
      enumOptions: elementOptions,
    ),
    FieldSchema(key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'requiredSkillID',
      label: 'Required Skill ID',
      type: FieldType.reference,
      referenceSchemaId: 'skills',
    ),
    FieldSchema(key: 'isUnlocked', label: 'Unlocked', type: FieldType.boolean, defaultValue: false),
    FieldSchema(key: 'description', label: 'Description', type: FieldType.multilineText),
    FieldSchema(key: 'healAmount', label: 'Heal Amount', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'damageMod', label: 'Damage Mod', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'healthMod', label: 'Health Mod', type: FieldType.integer, defaultValue: 0),
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
    FieldSchema(key: 'battleMessage', label: 'Battle Message', type: FieldType.text),
  ],
);

final DbSchema diceSchema = DbSchema(
  id: 'dice',
  label: 'Dice',
  assetPath: 'assets/gamedata/dice.json',
  primaryKeyField: 'diceName',
  fields: [
    FieldSchema(key: 'diceName', label: 'Dice Name', type: FieldType.text),
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
  ],
);

final DbSchema enemiesSchema = DbSchema(
  id: 'enemies',
  label: 'Enemies (Ground)',
  assetPath: 'assets/gamedata/enemies.json',
  primaryKeyField: 'enemyName',
  fields: [
    FieldSchema(key: 'enemyName', label: 'Enemy Name', type: FieldType.text),
    FieldSchema(key: 'maxHealth', label: 'Max Health', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'damage', label: 'Damage', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'xpReward', label: 'XP Reward', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'goldReward', label: 'Gold Reward', type: FieldType.integer, defaultValue: 0),
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
  ],
);

final DbSchema enemyShipsSchema = DbSchema(
  id: 'enemy_ships',
  label: 'Enemy Ships (FTL)',
  assetPath: 'assets/gamedata/enemy_ships.json',
  primaryKeyField: 'shipName',
  fields: [
    FieldSchema(key: 'shipName', label: 'Ship Name', type: FieldType.text),
    FieldSchema(key: 'maxHull', label: 'Max Hull', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'maxShield', label: 'Max Shield', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'weaponDamage', label: 'Weapon Damage', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'xpReward', label: 'XP Reward', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'goldReward', label: 'Gold Reward', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'skillMoves',
      label:
          'Skill Moves [{skillID, condition: $skillMoveConditionOptions, requiredElement, chance, healthThreshold, attackCountRequirement, playerPatternThreshold, blockThreshold, priority}]',
      type: FieldType.json,
    ),
  ],
);

final DbSchema shipsSchema = DbSchema(
  id: 'ships',
  label: 'Player Ships',
  assetPath: 'assets/gamedata/ships.json',
  primaryKeyField: 'shipID',
  titleField: 'shipName',
  fields: [
    FieldSchema(key: 'shipID', label: 'Ship ID', type: FieldType.text),
    FieldSchema(key: 'shipName', label: 'Ship Name', type: FieldType.text),
    FieldSchema(key: 'baseMaxHull', label: 'Base Max Hull', type: FieldType.integer, defaultValue: 0),
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
    FieldSchema(key: 'weaponSlots', label: 'Weapon Slots', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'shieldSlots', label: 'Shield Slots', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'utilitySlots', label: 'Utility Slots', type: FieldType.integer, defaultValue: 0),
  ],
);

final DbSchema shipPartsSchema = DbSchema(
  id: 'ship_parts',
  label: 'Ship Parts',
  assetPath: 'assets/gamedata/ship_parts.json',
  primaryKeyField: 'partID',
  titleField: 'partName',
  fields: [
    FieldSchema(key: 'partID', label: 'Part ID', type: FieldType.text),
    FieldSchema(key: 'partName', label: 'Part Name', type: FieldType.text),
    FieldSchema(
      key: 'slotType',
      label: 'Slot Type',
      type: FieldType.enumeration,
      enumOptions: slotTypeOptions,
    ),
    FieldSchema(key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'battleActionLabel', label: 'Battle Action Label', type: FieldType.text),
    FieldSchema(
      key: 'cooldownTurns',
      label: 'Cooldown Turns',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(key: 'damageAmount', label: 'Damage Amount', type: FieldType.integer, defaultValue: 0),
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
  ],
);

final DbSchema questsSchema = DbSchema(
  id: 'quests',
  label: 'Quests',
  assetPath: 'assets/gamedata/quests.json',
  primaryKeyField: 'questID',
  titleField: 'questName',
  fields: [
    FieldSchema(key: 'questID', label: 'Quest ID', type: FieldType.text),
    FieldSchema(key: 'questName', label: 'Quest Name', type: FieldType.text),
    FieldSchema(key: 'chapter', label: 'Chapter', type: FieldType.integer, defaultValue: 1),
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
          'Objectives [{description, type: [Kill, Gather, Talk, Reach], targetEnemyID, targetItemID, targetNPCName, locationID, requiredAmount}]',
      type: FieldType.json,
    ),
    FieldSchema(key: 'rewardGold', label: 'Reward Gold', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'rewardXP', label: 'Reward XP', type: FieldType.integer, defaultValue: 0),
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
    FieldSchema(key: 'npcDialogueText', label: 'NPC Dialogue Text', type: FieldType.multilineText),
    FieldSchema(key: 'requiredGold', label: 'Required Gold', type: FieldType.integer, defaultValue: 0),
    FieldSchema(key: 'requiredFlags', label: 'Required Flags', type: FieldType.stringList),
    FieldSchema(
      key: 'questChoices',
      label:
          'Quest Choices [{buttonText, goldModifier, alignmentModifier, flagToAdd, nextEventID, actionType, lockedText}]',
      type: FieldType.json,
    ),
  ],
);

final DbSchema shopsSchema = DbSchema(
  id: 'shops',
  label: 'Shops',
  assetPath: 'assets/gamedata/shops.json',
  primaryKeyField: 'shopID',
  titleField: 'shopName',
  fields: [
    FieldSchema(key: 'shopID', label: 'Shop ID', type: FieldType.text),
    FieldSchema(key: 'shopName', label: 'Shop Name', type: FieldType.text),
    FieldSchema(key: 'shopDescription', label: 'Shop Description', type: FieldType.multilineText),
    FieldSchema(key: 'unlockLevel', label: 'Unlock Level', type: FieldType.integer, defaultValue: 1),
    FieldSchema(key: 'buildCost', label: 'Build Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'initialStock',
      label: 'Initial Stock',
      type: FieldType.referenceList,
      referenceSchemaId: 'items',
    ),
    FieldSchema(
      key: 'merchantSpecialties',
      label: 'Merchant Specialties',
      type: FieldType.multiEnum,
      enumOptions: itemTypeOptions,
    ),
  ],
);

final DbSchema gatesSchema = DbSchema(
  id: 'gates',
  label: 'Gates',
  assetPath: 'assets/gamedata/gates.json',
  primaryKeyField: 'gateID',
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
  ],
);

final DbSchema adventureNodesSchema = DbSchema(
  id: 'adventure_nodes',
  label: 'Adventure Node Types',
  assetPath: 'assets/gamedata/adventure_nodes.json',
  primaryKeyField: 'nodeID',
  titleField: 'displayName',
  fields: [
    FieldSchema(key: 'nodeID', label: 'Node ID', type: FieldType.text),
    FieldSchema(key: 'displayName', label: 'Display Name', type: FieldType.text),
    FieldSchema(key: 'flavorText', label: 'Flavor Text', type: FieldType.multilineText),
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
    FieldSchema(key: 'healPercent', label: 'Heal Percent (Rest)', type: FieldType.integer, defaultValue: 0),
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
  ],
);

final List<DbSchema> gameDbSchemas = [
  itemsSchema,
  skillsSchema,
  diceSchema,
  enemiesSchema,
  enemyShipsSchema,
  shipsSchema,
  shipPartsSchema,
  questsSchema,
  shopsSchema,
  gatesSchema,
  adventureNodesSchema,
];
