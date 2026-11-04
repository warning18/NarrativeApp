// The game database's schemas for the character and their kit: items and
// their sets, skills, skill merges and trees, races, professions, dice,
// spells, titles, signs and the specialisations (see db_schema.dart).
part of 'db_schema.dart';

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
    // Lore (v1.204): a sentence or two in the game's voice, shown in the
    // inventory's detail dialog and the item sheet.
    FieldSchema(
        key: 'description',
        label: 'Description (lore)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'description_fr',
        label: 'Description (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'itemType',
      label: 'Item Type',
      type: FieldType.enumeration,
      enumOptions: _itemTypeOptions,
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
      enumOptions: _statScalingOptions,
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
      enumOptions: _uniqueEffectOptions,
    ),
    FieldSchema(
      key: 'uniqueValue',
      label:
          'Unique Effect Value (% for lifesteal/crit/dodge/thorns, points for mana)',
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
      enumOptions: _affinityAlignmentOptions,
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
    FieldSchema(
        key: 'materialTier',
        label: 'Material tier (1-4, a Material only; see materials.dart)',
        type: FieldType.integer),
    _visualAssetFieldSchema('items'),
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
      enumOptions: _skillRarityOptions,
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
      enumOptions: _enemyIntentOptions,
    ),
    // v1.182: what an enemy using this skill does to the party's dice (see
    // dice_tamper.dart). Hex, Silence and Curse go with intent 'tamper';
    // Mirror is an attack.
    FieldSchema(
      key: 'tamper',
      label: 'Dice tamper (hex / silence / curse / mirror)',
      type: FieldType.enumeration,
      enumOptions: _diceTamperOptions,
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
      enumOptions: _affinityAlignmentOptions,
    ),
    FieldSchema(
      key: 'unlockedViaMergeOnly',
      label: 'Unlocked Via Merge Only',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'fusionOf',
      label: 'Fusion Of (two skills known; offered by the clans behind them)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'subclanId',
      label:
          'Sub-clan (offered once it is your friend, by its clan, in its voice)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'hiddenFlags',
      label: 'Secret: story flags that reveal it (all held)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'hiddenClan',
      label: 'Secret: the clan that teaches it',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'ascendsSkillID',
      label: 'Ascends Skill (the upgrade a clan offers at Friend standing)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'inflictsStatus',
      label: 'Inflicts Status Effect (on hit)',
      type: FieldType.enumeration,
      enumOptions: _statusEffectOptions,
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
    FieldSchema(
      key: 'inflictsStatus2',
      label: 'Second Status Effect (laid beside the first)',
      type: FieldType.enumeration,
      enumOptions: _statusEffectOptions,
    ),
    FieldSchema(
      key: 'statusDuration2',
      label: 'Second Status Duration (rounds)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'statusMagnitude2',
      label: 'Second Status Magnitude',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'statusAll',
      label: 'Status lands on every enemy standing',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'blockAmount',
      label: 'Block the skill raises (as a Defend face)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'reflectStatus',
      label: 'Ward: status laid on an enemy that strikes the block',
      type: FieldType.enumeration,
      enumOptions: _statusEffectOptions,
    ),
    FieldSchema(
      key: 'reflectDuration',
      label: 'Ward Status Duration (rounds)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'reflectMagnitude',
      label: 'Ward Status Magnitude',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'strikes',
      label: 'Blows struck (damage fields are per blow; 1 = one hit)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'splashShare',
      label: 'Share of the damage the other enemies take (0-1)',
      type: FieldType.decimal,
      defaultValue: 0.0,
    ),
    FieldSchema(
      key: 'splashTargets',
      label: 'How many other enemies it reaches (0 = all)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'pierces',
      label: 'Goes through a raised guard and Armored hide',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'damageFromArmor',
      label: 'Extra damage per point of the caster\'s armor',
      type: FieldType.decimal,
      defaultValue: 0.0,
    ),
    FieldSchema(
      key: 'cleanse',
      label: 'Cleanses the caster (Poison, or All)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'healAll',
      label: 'The heal reaches the whole party',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'chargesMomentum',
      label: 'Fills the momentum (next strike is a sure critical)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'bonusRolls',
      label: 'Free rerolls granted next round',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    _visualAssetFieldSchema('skills'),
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
        key: 'tag',
        label: 'Tag (one word on the picker: Sturdy, Quick…)',
        type: FieldType.text),
    FieldSchema(key: 'tag_fr', label: 'Tag (FR)', type: FieldType.text),
    FieldSchema(
        key: 'playstyle',
        label: 'Playstyle (one line, how it plays, ~60 characters)',
        type: FieldType.text),
    FieldSchema(
        key: 'playstyle_fr', label: 'Playstyle (FR)', type: FieldType.text),
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
    _visualAssetFieldSchema('races'),
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
        key: 'tag',
        label: 'Tag (the role on the picker: Bulwark, Caster…)',
        type: FieldType.text),
    FieldSchema(key: 'tag_fr', label: 'Tag (FR)', type: FieldType.text),
    FieldSchema(
        key: 'playstyle',
        label: 'Playstyle (one line, how it plays, ~60 characters)',
        type: FieldType.text),
    FieldSchema(
        key: 'playstyle_fr', label: 'Playstyle (FR)', type: FieldType.text),
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
      enumOptions: _statScalingOptions,
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
    _visualAssetFieldSchema('professions'),
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
          'Faces [{faceName, type: $faceTypeOptions, value, linkedSkillID, weight, element: $elementOptions, keywords: $_faceKeywordOptions}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'clan',
      label: 'Clan (the main clan that gives it, from Trusted; empty = none)',
      type: FieldType.text,
    ),
    _visualAssetFieldSchema('dice'),
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
      enumOptions: _statusEffectOptions,
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
    _visualAssetFieldSchema('spells'),
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
      key: 'storyOnly',
      label: 'Story only',
      type: FieldType.boolean,
      defaultValue: false,
      help: 'Given by the story (a flag), never drawn in an offer.',
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

/// The main clans' specialisations (specialisations.dart): the words
/// (Narrative's) and each one's profession and clan. Not one of
/// [gameDbSchemas]: the rules are in Dart, the file only names them.
final DbSchema specialisationsSchema = DbSchema(
  id: 'specialisations',
  label: 'Specialisations',
  assetPath: 'assets/gamedata/specialisations.json',
  primaryKeyField: 'id',
  fields: [],
);

/// The sub-clans' variants and upgrades of the specialisations, and their
/// rank II (spec_variants.dart). Not one of [gameDbSchemas].
final DbSchema specVariantsSchema = DbSchema(
  id: 'spec_variants',
  label: 'Specialisation Variants',
  assetPath: 'assets/gamedata/spec_variants.json',
  primaryKeyField: 'id',
  fields: [],
);
