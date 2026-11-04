// The game database's schemas for the story: quests, shops, companions,
// houses, achievements, NPCs, chapters, the companions' remarks, the
// intrigues and the politics events (see db_schema.dart).
part of 'db_schema.dart';

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
      enumOptions: _questCategoryOptions,
    ),
    FieldSchema(key: 'difficulty', label: 'Difficulty', type: FieldType.text),
    FieldSchema(
      key: 'requiredAlignment',
      label: 'Required Alignment',
      type: FieldType.enumeration,
      enumOptions: _alignmentOptions,
    ),
    FieldSchema(
      key: 'objectives',
      label:
          'Objectives [{description, type: [Kill, Gather, Talk, Reach], targetEnemyID (or targetEnemyIDs, any of which counts; countFromAccept: only kills after the quest is taken), targetItemID, targetNPCName, targetNPCID (npcs.json id, for Talk gating), requiredAmount}]',
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
          'Quest Choices [{buttonText, goldModifier, alignmentModifier, nextEventID, lockedText}]',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'turnInChoices',
      label:
          'Turn-in Choices [{choiceText, choiceText_fr, rewardGold, alignmentChange, flag, approvalMods: {companionId|*: n}, resultText, resultText_fr, politics: {standing: {faction: n}, marks: {subclan: friend|foe}} (applied once at turn-in, v1.204)}]',
      type: FieldType.json,
    ),
    FieldSchema(
        key: 'detourEligible',
        label:
            'Can be offered by a random detour or expedition (off for a quest with its own giver in a town, v1.204)',
        type: FieldType.boolean,
        defaultValue: true),
    _visualAssetFieldSchema('quests'),
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
      enumOptions: _itemTypeOptions,
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
    FieldSchema(
      key: 'stockPool',
      label: 'Stock Pool (a wandering shop draws its shelf from these)',
      type: FieldType.referenceList,
      referenceSchemaId: 'items',
    ),
    FieldSchema(
        key: 'stockDraw',
        label: 'Stock Draw — how many of the pool are on the shelf each '
            'chapter (0: the whole pool)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(key: 'keeperName', label: 'Keeper', type: FieldType.text),
    FieldSchema(
        key: 'keeperName_fr', label: 'Keeper (FR)', type: FieldType.text),
    FieldSchema(
        key: 'keeperLine',
        label: 'Keeper\'s line (Unknown or Known standing, or no faction)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLine_fr',
        label: 'Keeper\'s line (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLineWary',
        label: 'Keeper\'s line when Wary or Hostile',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLineWary_fr',
        label: 'Keeper\'s line when Wary or Hostile (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLineTrusted',
        label: 'Keeper\'s line when Trusted',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLineTrusted_fr',
        label: 'Keeper\'s line when Trusted (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLineSworn',
        label: 'Keeper\'s line when Sworn',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'keeperLineSworn_fr',
        label: 'Keeper\'s line when Sworn (FR)',
        type: FieldType.multilineText),
    _visualAssetFieldSchema('shops'),
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
    _visualAssetFieldSchema('companions'),
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
    FieldSchema(
      key: 'category',
      label: 'Category (the building screen\'s section)',
      type: FieldType.enumeration,
      enumOptions: ['sea', 'company', 'workshops', 'greatWorks'],
      help:
          'Left empty, it is read from what the house gives (camp_works.dart).',
    ),
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
        key: 'materialCost',
        label: 'Build materials {itemId: count}',
        type: FieldType.json),
    FieldSchema(
      key: 'companionHealthBonus',
      label:
          'Companion Health Bonus (%, companions only, every fight once built)',
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
      key: 'unlocksCraft',
      label: 'Unlocks Craft a Skill (the Skillwright)',
      type: FieldType.boolean,
    ),
    FieldSchema(
      key: 'unlocksRiskyGifts',
      label: 'Unlocks risky gifts (the Parley Tent, risky_gifts.dart)',
      type: FieldType.boolean,
    ),
    FieldSchema(
      key: 'rollPower',
      label: 'Roll power (camp_rolls.dart)',
      type: FieldType.enumeration,
      enumOptions: ['reroll', 'banish', 'raise'],
      help: 'The power it gives over the stat pick and the clans\' offer: '
          'reroll the set, banish a card for some draws, raise a card.',
    ),
    FieldSchema(
      key: 'requiredFlags',
      label:
          'Required Flags (all must be set to build; a zone\'s rewardFlag gates on clearing that zone)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'unlockedByFlags',
      label:
          'Unlocked By Flags (any one set opens it, whatever the required flags)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'requiredAllyId',
      label: 'Required Ally (the house is shown once they have joined)',
      type: FieldType.reference,
      referenceSchemaId: 'companions',
    ),
    _visualAssetFieldSchema('houses'),
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
    _visualAssetFieldSchema('achievements'),
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
    // The People codex (v1.204, see people_codex.dart): who they are and
    // where they are met.
    FieldSchema(key: 'role', label: 'Role', type: FieldType.text),
    FieldSchema(key: 'role_fr', label: 'Role (FR)', type: FieldType.text),
    FieldSchema(
      key: 'faction',
      label: 'Faction (a factions.json or subclans.json id, or empty)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'placeId',
      label: 'Place (a geography.json location or district id)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'kind',
      label: 'Kind (icon)',
      type: FieldType.enumeration,
      enumOptions: _npcKindOptions,
    ),
    FieldSchema(
        key: 'want', label: 'What they want', type: FieldType.multilineText),
    FieldSchema(
        key: 'want_fr',
        label: 'What they want (FR)',
        type: FieldType.multilineText),
    FieldSchema(
      key: 'metNodes',
      label: 'Met in scenes (node ids: visiting one reveals them)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'metFlags',
      label: 'Met by flags (holding one reveals them)',
      type: FieldType.stringList,
    ),
    FieldSchema(
      key: 'shopId',
      label: 'Shop kept (finding it reveals them)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'requiredFlag',
      label:
          'Required Flag (legacy records only, with no metNodes/metFlags/shopId: empty = always discoverable)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'states',
      label:
          'What passed between you [{flag, andFlags, unlessFlags, conditions, line, line_fr}], shown in order when held',
      type: FieldType.json,
      help: 'flag held, andFlags all held, unlessFlags none held. '
          'conditions (optional, v1.210): a politicsIf map (standingAtLeast '
          '{faction: n}, standingAtMost, marks {sub-clan: friend}, claim, '
          'rungAtLeast...) that must hold too; flag may then be "" (no flag '
          'needed).',
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
    _visualAssetFieldSchema('npcs'),
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
    FieldSchema(
        key: 'recommendedLevel',
        label:
            'Recommended level (shown before setting out for this chapter; empty for none)',
        type: FieldType.integer),
    FieldSchema(
        key: 'recommendedLevelNote',
        label: 'Recommended level note (said when the party is under it)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'recommendedLevelNote_fr',
        label: 'Recommended level note (FR)',
        type: FieldType.multilineText),
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
      label: 'Stages [{stage, chapter, text, text_fr, npcId}]',
      type: FieldType.json,
      help: 'Six: Clue, Hook, Turn, Reveal, Crisis, Choice. The story '
          'marks the one reached with the flag intrigue_<id>_stage_<n>. '
          'npcId (optional, v1.210): the person at that stage, an npcs.json '
          'id; shown beside the stage once reached and on their page.',
    ),
    FieldSchema(
      key: 'outcomes',
      label: 'Outcomes [{name, name_fr, effects, npcId}]',
      type: FieldType.json,
      help: 'effects: [{"faction": "vigil", "delta": 25}, {"subclan": '
          '"inquisition", "mark": "foe"}, {"note": "...", "note_fr": '
          '"..."}]. npcId (optional, v1.210): the person the outcome turns '
          'on, an npcs.json id.',
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
