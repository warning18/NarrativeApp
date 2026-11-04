// The game database's schemas for the foes and the ships: enemies, enemy
// ships, the player's ships, their parts and their looks (see
// db_schema.dart).
part of 'db_schema.dart';

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
    // v1.212: the faction whose doctrine (see lib/combat/doctrine.dart) the enemy fights
    // under; empty for beasts, uniques and the tear's things.
    FieldSchema(
      key: 'faction',
      label: 'Faction (fights under its doctrine)',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
    ),
    // v1.215: how the enemy answers what the party does (see
    // lib/combat/enemy_response.dart).
    FieldSchema(
      key: 'reaction',
      label: 'Reaction (answers the party)',
      type: FieldType.enumeration,
      enumOptions: ['', 'counter', 'press', 'hunt_healer'],
      help: 'counter: a heavy blow provokes a harder reply. press: a round '
          'of Defend faces from everyone makes it press. hunt_healer: it '
          'turns on whoever heals.',
    ),
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
    // Wave 16: the fight opens on this foe's entrance card (bosses always
    // do, see hasEntranceCard).
    FieldSchema(
        key: 'entranceCard',
        label: 'Entrance card (the fight opens on this foe; bosses always do)',
        type: FieldType.boolean,
        defaultValue: false),
    FieldSchema(
      key: 'hunterAlignment',
      label:
          'Hunter Of (alignment this enemy hunts: Good = stalks Good characters; empty = ordinary enemy)',
      type: FieldType.enumeration,
      enumOptions: _affinityAlignmentOptions,
    ),
    FieldSchema(
        key: 'hunterTier',
        label: 'Hunter Tier (1 = from chapter 1, 2 = from chapter 3)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'hunterClan',
        label:
            'Hunts for clan (a rival of the clan you swore to sends it, see rival_hunters.dart; empty = none)',
        type: FieldType.text),
    FieldSchema(
        key: 'hunterOnly',
        label: 'Hunter only (never an ordinary random draw)',
        type: FieldType.boolean,
        defaultValue: false),
    FieldSchema(
        key: 'battleCry',
        label: 'Battle Cry (a hunter\'s)',
        type: FieldType.text),
    FieldSchema(
        key: 'alignment',
        label:
            'Alignment (a rival hunter\'s, -100 evil to 100 good: sets the betrayal chance when spared)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'battleCry_fr', label: 'Battle Cry (FR)', type: FieldType.text),
    FieldSchema(
        key: 'championClan',
        label: 'Champion of (a clan\'s nemesis champion, nemesis.dart)',
        type: FieldType.text),
    FieldSchema(
        key: 'arrival',
        label: 'Arrival (a champion\'s road scene; {name} for its name)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'arrival_fr',
        label: 'Arrival (FR)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'wayForce',
        label: 'Way in by force (a champion\'s road choice)',
        type: FieldType.text),
    FieldSchema(
        key: 'wayForce_fr',
        label: 'Way in by force (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'wayGuile',
        label: 'Way in by guile (a champion\'s road choice)',
        type: FieldType.text),
    FieldSchema(
        key: 'wayGuile_fr',
        label: 'Way in by guile (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'wayMercy',
        label: 'Way in by mercy (a champion\'s road choice)',
        type: FieldType.text),
    FieldSchema(
        key: 'wayMercy_fr',
        label: 'Way in by mercy (FR)',
        type: FieldType.text),
    FieldSchema(
        key: 'defeat',
        label: 'Defeat (logged when it falls)',
        type: FieldType.multilineText),
    FieldSchema(
        key: 'defeat_fr', label: 'Defeat (FR)', type: FieldType.multilineText),
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
          'Skill Moves [{skillID, condition: $_skillMoveConditionOptions, requiredElement, chance, healthThreshold, priority}]',
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
    _visualAssetFieldSchema('enemies'),
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
    // Wave 17: the sea fight opens on this ship's entrance card. Left
    // empty, shipHasEntranceCard decides (every beast, and the raiders of
    // chapter 4 on); true or false here overrides it.
    FieldSchema(
      key: 'entranceCard',
      label:
          'Entrance card (empty: beasts and chapter 4+ raiders get one; true/false overrides)',
      type: FieldType.boolean,
    ),
    _visualAssetFieldSchema('enemy_ships'),
  ],
);

final DbSchema shipsSchema = DbSchema(
  id: 'ships',
  label: 'Player Ships',
  assetPath: 'assets/gamedata/ships.json',
  primaryKeyField: 'shipID',
  titleField: 'hullName',
  visualAssetField: 'visualAsset',
  fields: [
    FieldSchema(key: 'shipID', label: 'Ship ID', type: FieldType.text),
    FieldSchema(key: 'shipName', label: 'Ship Name', type: FieldType.text),
    FieldSchema(
        key: 'shipName_fr', label: 'Ship Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'hullName',
      label: 'Hull Name (the class: Sloop, Brig, Galleon...)',
      type: FieldType.text,
    ),
    FieldSchema(
        key: 'hullName_fr', label: 'Hull Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'hullCost',
      label: 'Hull Cost (gold to build her on this hull at the Harbor, once)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'unlockChapter',
      label:
          'Unlock Chapter (the story chapter from which the shipwright builds it; 0 = always)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'flying',
      label:
          'Flying (a flying boat: storms and raiders pass beneath her keel on a voyage)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'kind',
      label: 'Kind (how she is drawn from above)',
      type: FieldType.enumeration,
      enumOptions: [for (final kind in HullKind.values) kind.name],
      defaultValue: 'hull',
    ),
    FieldSchema(
      key: 'length',
      label: 'Length (drawn, of the battle box\'s width)',
      type: FieldType.decimal,
      defaultValue: 1.0,
    ),
    FieldSchema(
      key: 'beam',
      label: 'Beam (drawn, of the battle box\'s width)',
      type: FieldType.decimal,
      defaultValue: 0.24,
    ),
    FieldSchema(
      key: 'outline',
      label:
          'Outline {u0, a, b, tipw, bowtip}: where she is widest, how full stern and bow are, how wide transom and stem',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'sailPlan',
      label: 'Sail Plan [{kind: square|gaff|lateen, at: 0-1, size}] per mast',
      type: FieldType.json,
    ),
    FieldSchema(
        key: 'jibs',
        label: 'Jibs (headsails on the bowsprit)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
        key: 'oars',
        label: 'Oars (a side)',
        type: FieldType.integer,
        defaultValue: 0),
    FieldSchema(
      key: 'castles',
      label:
          'Castles [[from, to], ...] along the hull: raised stern and bow decks',
      type: FieldType.json,
    ),
    FieldSchema(
      key: 'beak',
      label: 'Beak (a long bowsprit and a spritsail, as on a galleon)',
      type: FieldType.boolean,
      defaultValue: false,
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
    _visualAssetFieldSchema('ships'),
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
      key: 'hullBonus',
      label: 'Hull Bonus (hull points this part adds to the ship)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'family',
      label:
          'Family (parts that are versions of one another share it; the Harbor groups them and the ship draws the family\'s fitting)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'tier',
      label: 'Version (1 is the first of its family, higher is a better one)',
      type: FieldType.integer,
      defaultValue: 1,
    ),
    FieldSchema(
      key: 'rarity',
      label: 'Rarity (colours the part in the Harbor)',
      type: FieldType.enumeration,
      enumOptions: shipPartRarityOptions,
      defaultValue: 'common',
    ),
    FieldSchema(
      key: 'unlockChapter',
      label:
          'Unlock Chapter (the story chapter from which the shipwright offers it; 0 = always)',
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
    _visualAssetFieldSchema('ship_parts'),
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

final DbSchema shipLooksSchema = DbSchema(
  id: 'ship_looks',
  label: 'Ship Looks',
  assetPath: 'assets/gamedata/ship_looks.json',
  primaryKeyField: 'lookID',
  titleField: 'lookName',
  fields: [
    FieldSchema(key: 'lookID', label: 'Look ID', type: FieldType.text),
    FieldSchema(key: 'lookName', label: 'Look Name', type: FieldType.text),
    FieldSchema(
        key: 'lookName_fr', label: 'Look Name (FR)', type: FieldType.text),
    FieldSchema(
      key: 'category',
      label: 'Category (what of the ship it dresses)',
      type: FieldType.enumeration,
      enumOptions: shipLookCategories,
    ),
    FieldSchema(
        key: 'cost', label: 'Cost', type: FieldType.integer, defaultValue: 0),
    FieldSchema(
      key: 'rarity',
      label: 'Rarity (colours the look in the Harbor)',
      type: FieldType.enumeration,
      enumOptions: shipPartRarityOptions,
      defaultValue: 'common',
    ),
    FieldSchema(
      key: 'unlockChapter',
      label:
          'Unlock Chapter (the story chapter from which the shipwright offers it; 0 = always)',
      type: FieldType.integer,
      defaultValue: 0,
    ),
    FieldSchema(
      key: 'isDefault',
      label:
          'Is Default (the look a category wears until another is chosen; free, always owned)',
      type: FieldType.boolean,
      defaultValue: false,
    ),
    FieldSchema(
      key: 'trophyOf',
      label:
          'Trophy Of (enemy_ships.json beast id: given free once it is slain, hidden until then)',
      type: FieldType.reference,
      referenceSchemaId: 'enemy_ships',
    ),
    FieldSchema(
      key: 'color',
      label:
          'Color ("#RRGGBB": hull paint = the hull, sail = the cloth, figurehead = the carving, ensign = the cloth; empty = the ship\'s own)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'color2',
      label:
          'Color 2 (hull = the deck, sail = the pattern, figurehead = the eye, ensign = the device)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'color3',
      label: 'Color 3 (hull = the trim, sail = the edge)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'pattern',
      label:
          'Pattern (sail: how the cloth is worked; figurehead: what is carved; ensign: the flag\'s shape)',
      type: FieldType.enumeration,
      enumOptions: allShipLookPatterns,
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
