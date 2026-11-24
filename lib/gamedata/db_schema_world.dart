// The game database's schemas for the world: zones, ports, the factions,
// sub-clans and their relations, the geography and its biomes, land routes
// and their events, and the detours' files (see db_schema.dart).
part of 'db_schema.dart';

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
      enumOptions: _mapThemeOptions,
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
      key: 'rewardMaterials',
      label: 'Reward materials {itemId: count} (on zone completion)',
      type: FieldType.json,
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
    _visualAssetFieldSchema('zones'),
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
    _visualAssetFieldSchema('ports'),
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
        key: 'stands_for',
        label: 'Stands for',
        type: FieldType.text,
        help: 'What the clan wants of the character, in a few words.'),
    FieldSchema(
        key: 'stands_for_fr', label: 'Stands for (FR)', type: FieldType.text),
    FieldSchema(
      key: 'ruling',
      label: 'How it is ruled',
      type: FieldType.multilineText,
      help: 'Shown on the clan card, as written (records.dart rulingFor).',
    ),
    FieldSchema(
        key: 'ruling_fr',
        label: 'How it is ruled (FR)',
        type: FieldType.multilineText),
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
      key: 'power',
      label: 'Starting power (0 to 100)',
      type: FieldType.integer,
      defaultValue: 0,
      help: 'How strong the clan is when the story opens (clan_power.dart): '
          'Minor under 25, Rising, Dominant from 50, Ascendant from 75.',
    ),
    FieldSchema(
      key: 'seat',
      label: 'Seat',
      type: FieldType.reference,
      referenceSchemaId: 'geography',
      help: 'The place the clan gives up last; its first claim back when it '
          'has fallen.',
    ),
    FieldSchema(
      key: 'brokenNews',
      label: 'Broken news (its nemesis hunt broken)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'brokenNews_fr',
      label: 'Broken news (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'riskStat',
      label: 'Risky gift: curse stat',
      type: FieldType.enumeration,
      enumOptions: [
        'strength',
        'dexterity',
        'constitution',
        'intelligence',
        'wisdom',
        'perception',
        'luck',
        'charisma',
      ],
      help: 'The ability a risky gift\'s curse lowers (risky_gifts.dart); '
          'unset: the clan never offers a risky gift.',
    ),
    FieldSchema(
      key: 'riskyOffer',
      label: 'Risky gift: what they say',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'riskyOffer_fr',
      label: 'Risky gift: what they say (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'templeName',
      label: 'Temple: the name of its temples',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'templeName_fr',
      label: 'Temple: the name of its temples (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'blessingName',
      label: 'Temple: the name of its temple blessing',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'blessingName_fr',
      label: 'Temple: the name of its temple blessing (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'templeLine',
      label: 'Temple: what its temple keeper says',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'templeLine_fr',
      label: 'Temple: what its temple keeper says (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'templeLineHunted',
      label: 'Temple: its temple keeper refusing a Hunted character',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'templeLineHunted_fr',
      label: 'Temple: its temple keeper refusing a Hunted character (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'blessingGrants',
      label: 'Temple: one line of what its blessing grants',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'blessingGrants_fr',
      label: 'Temple: one line of what its blessing grants (FR)',
      type: FieldType.text,
    ),
    FieldSchema(
      key: 'gender_fr',
      label: 'French gender and number',
      type: FieldType.enumeration,
      enumOptions: ['m', 'f', 'mp', 'fp'],
      help: 'For the French words that agree with the name ("est tombée", '
          '"tiennent").',
    ),
    FieldSchema(
      key: 'nameTo_fr',
      label: 'French name after "à"',
      type: FieldType.text,
      help: '"au Dominion de la Lanterne", "aux Corneilles de Sel".',
    ),
    FieldSchema(
      key: 'claims',
      label: 'Claims, in order',
      type: FieldType.referenceList,
      referenceSchemaId: 'geography',
      help: 'The places the clan reaches for as its power grows.',
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
      key: 'host',
      label: 'Host contingent {effects, line, line_fr}',
      type: FieldType.json,
      help: 'What they bring to the last battles when they come with the '
          'Host (as its banner or an ally, see throne.dart). Effects are '
          'written as signs\' effects.',
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
      enumOptions: ['', ...geoKinds, ...geoBuildingKinds],
    ),
    FieldSchema(
      key: 'water',
      label: 'Water (locations only): a river through it, or a shore',
      type: FieldType.enumeration,
      enumOptions: ['', 'river', 'shore'],
    ),
    FieldSchema(
      key: 'glyph',
      label: 'Glyph (districts only): drawn on the Journey map',
      type: FieldType.enumeration,
      enumOptions: ['', ...geoGlyphs],
    ),
    FieldSchema(
      key: 'stage',
      label: 'Fight stage (v1.241)',
      type: FieldType.enumeration,
      enumOptions: ['', for (final stage in FightStage.values) stage.name],
      help: 'How a fight here looks and which ground anomalies it can meet. '
          'Empty: the stage of the land (its zone\'s biome); a place inside '
          'a building (a prison, a crypt, a cathedral) is a hall. The '
          'nearest one up the chain applies.',
    ),
    FieldSchema(
      key: 'danger',
      label: 'Danger (v1.242)',
      type: FieldType.enumeration,
      enumOptions: ['', for (var i = 0; i <= geoMaxDanger; i++) '$i'],
      help: '0 safe, 1 ordinary, up to $geoMaxDanger deadly. The roads to a '
          'dangerous place hold events more often, and a fight there meets '
          'a ground anomaly more often. Empty: the place above it says, and '
          'with none, 1.',
    ),
    FieldSchema(
      key: 'light',
      label: 'Light (v1.242)',
      type: FieldType.enumeration,
      enumOptions: ['', ...geoLights],
      help: 'The light a fight here is fought in: night and dark make the '
          'Dark battlefield likelier and dim the backdrop. Empty: the place '
          'above it says, and with none, the day\'s.',
    ),
    FieldSchema(
      key: 'controller',
      label: 'Controller (v1.242)',
      type: FieldType.reference,
      referenceSchemaId: 'factions',
      help: 'The faction that holds this place. Its shops here price by '
          'the standing with it. Empty: the place above it says, and with '
          'none, the country\'s ruler.',
    ),
    FieldSchema(
      key: 'tags',
      label: 'Tags (v1.242)',
      type: FieldType.multiEnum,
      enumOptions: geoPlaceTags,
      help: 'What kind of place it is. A holy place favours a spring or '
          'the light, a haunted one an eclipse, a ruin falling stone. A '
          'place has its own tags and those of the places above it.',
    ),
    FieldSchema(
      key: 'watches',
      label: 'Watches to walk here (v1.242)',
      type: FieldType.integer,
      defaultValue: 0,
      help: 'Watches a walk to this place takes (four make a day, each '
          'costs the road\'s ration). 0: the place above it says, and with '
          'none, 2.',
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
    FieldSchema(
      key: 'doorstep',
      label: 'Doorstep scenes (buildings only, v1.542)',
      type: FieldType.stringList,
      help: 'Story scene ids, one per line, whose location is this building '
          'but which play outside it, in the street at its door. The '
          'Journey opens them on the district\'s streets at the building, '
          'not in its room.',
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

/// Land expeditions' routes (land_crossing.dart): a long land route
/// played like a voyage, an event a day.
final DbSchema landRoutesSchema = DbSchema(
  id: 'land_routes',
  label: 'Land Routes',
  assetPath: 'assets/gamedata/land_routes.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Route ID', type: FieldType.text),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(
        key: 'from',
        label: 'From (a world_roads.dart place id)',
        type: FieldType.text),
    FieldSchema(
        key: 'to',
        label: 'To (a world_roads.dart place id)',
        type: FieldType.text),
    FieldSchema(
        key: 'roads',
        label: 'Roads (world_roads.dart ids, in order)',
        type: FieldType.stringList),
    FieldSchema(
        key: 'days',
        label: 'Days (an event a day)',
        type: FieldType.integer,
        defaultValue: 3),
    FieldSchema(key: 'biome', label: 'Biome', type: FieldType.text),
    FieldSchema(
      key: 'terrain',
      label: 'Terrain (the side view\'s scene kit)',
      type: FieldType.enumeration,
      enumOptions: landTerrains,
    ),
    FieldSchema(
        key: 'chapter',
        label: 'Chapter (its checks are one harder a chapter after the first)',
        type: FieldType.integer,
        defaultValue: 1),
    FieldSchema(
      key: 'events',
      label: 'Events {land event id: draw weight}',
      type: FieldType.json,
    ),
    FieldSchema(
        key: 'rulerOneIn',
        label: 'Ruler one day in (the road\'s ruler\'s events; 0: never)',
        type: FieldType.integer,
        defaultValue: 0),
  ],
);

/// Land expeditions' events (land_crossing.dart): what the party meets on
/// a crossing, and what each way through costs or gives in health (a
/// percent of the party's maximum), gold and days.
final DbSchema landEventsSchema = DbSchema(
  id: 'land_events',
  label: 'Land Events',
  assetPath: 'assets/gamedata/land_events.json',
  primaryKeyField: 'id',
  titleField: 'name',
  fields: [
    FieldSchema(key: 'id', label: 'Event ID', type: FieldType.text),
    FieldSchema(key: 'name', label: 'Name', type: FieldType.text),
    FieldSchema(key: 'name_fr', label: 'Name (FR)', type: FieldType.text),
    FieldSchema(key: 'text', label: 'Text', type: FieldType.multilineText),
    FieldSchema(
        key: 'text_fr', label: 'Text (FR)', type: FieldType.multilineText),
    FieldSchema(
      key: 'choices',
      label:
          'Choices [{id, text, text_fr, check, dc, outcome | success, fail}]',
      type: FieldType.json,
      help: 'An outcome is {healthPct, gold, days, note, note_fr}.',
    ),
    FieldSchema(
        key: 'ruler',
        label: 'Ruler (a factions.json id; empty: a biome event)',
        type: FieldType.text),
    FieldSchema(
      key: 'band',
      label: 'Band (standing with the ruler)',
      type: FieldType.enumeration,
      enumOptions: ['', 'friend', 'neutral', 'hostile'],
    ),
  ],
);

/// Detour and expedition lines by place, biome and theme
/// (place_pools.dart). Narrative's file, and optional: missing, it loads
/// empty and every line comes from map_themes.dart. Not one of
/// [gameDbSchemas]: its top level is pools, not records.
final DbSchema detoursSchema = DbSchema(
  id: 'detours',
  label: 'Detours',
  assetPath: 'assets/gamedata/detours.json',
  primaryKeyField: 'id',
  fields: [],
);

/// Each zone's written road (expedition_steps.dart): `{"steps": [...]}` by
/// zone id. Narrative's file, and optional: a zone it leaves out keeps
/// its drawn events. Not one of [gameDbSchemas] until the file exists.
final DbSchema expeditionStepsSchema = DbSchema(
  id: 'expedition_steps',
  label: 'Expedition Steps',
  assetPath: 'assets/gamedata/expedition_steps.json',
  primaryKeyField: 'id',
  fields: [],
);

/// The detours' scenes (detour_scenes.dart): a scene's beats by scene id.
/// Narrative's file, and optional: missing, every detour is today's chain.
/// Not one of [gameDbSchemas]: a scene holds beats, not fields.
final DbSchema detourScenesSchema = DbSchema(
  id: 'detour_scenes',
  label: 'Detour Scenes',
  assetPath: 'assets/gamedata/detour_scenes.json',
  primaryKeyField: 'id',
  fields: [],
);
