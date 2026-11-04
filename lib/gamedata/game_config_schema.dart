import 'field_schema.dart';

/// The New Game Defaults (game_config.json), one field per key, in the
/// file's order. Each default is the shipped value (v1.761: the editor
/// offered 100 HP and 10 damage, five times the stat scale's 20 and 2, and
/// had no field for the antidotes, the six stats, luck or perception);
/// game_config_schema_test keeps them equal to the file.
final List<FieldSchema> gameConfigFields = [
  FieldSchema(
    key: 'playerLevel',
    label: 'Player Level',
    type: FieldType.integer,
    defaultValue: 1,
  ),
  FieldSchema(
    key: 'gold',
    label: 'Starting Gold',
    type: FieldType.integer,
    defaultValue: 100,
  ),
  FieldSchema(
    key: 'potionCount',
    label: 'Starting Potions',
    type: FieldType.integer,
    defaultValue: 3,
  ),
  FieldSchema(
    key: 'antidoteCount',
    label: 'Starting Antidotes',
    type: FieldType.integer,
    defaultValue: 1,
  ),
  FieldSchema(
    key: 'maxHealth',
    label: 'Max Health',
    type: FieldType.integer,
    defaultValue: 20,
  ),
  FieldSchema(
    key: 'baseDamage',
    label: 'Base Damage',
    type: FieldType.integer,
    defaultValue: 2,
  ),
  FieldSchema(
    key: 'baseArmor',
    label: 'Base Armor',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'luck',
    label: 'Luck',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'charisma',
    label: 'Charisma',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'strength',
    label: 'Strength',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'dexterity',
    label: 'Dexterity',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'constitution',
    label: 'Constitution',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'intelligence',
    label: 'Intelligence',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'wisdom',
    label: 'Wisdom',
    type: FieldType.integer,
    defaultValue: 0,
  ),
  FieldSchema(
    key: 'perception',
    label: 'Perception',
    type: FieldType.integer,
    defaultValue: 1,
  ),
  FieldSchema(
    key: 'maxSkillSlots',
    label: 'Max Skill Slots',
    type: FieldType.integer,
    defaultValue: 3,
  ),
];

const String gameConfigAssetPath = 'assets/gamedata/game_config.json';
const String gameConfigPrefsKey = 'gamedb_game_config';
