import 'field_schema.dart';

final List<FieldSchema> gameConfigFields = [
  FieldSchema(key: 'playerLevel', label: 'Player Level', type: FieldType.integer, defaultValue: 1),
  FieldSchema(key: 'gold', label: 'Starting Gold', type: FieldType.integer, defaultValue: 100),
  FieldSchema(
    key: 'potionCount',
    label: 'Starting Potions',
    type: FieldType.integer,
    defaultValue: 3,
  ),
  FieldSchema(key: 'maxHealth', label: 'Max Health', type: FieldType.integer, defaultValue: 100),
  FieldSchema(key: 'baseDamage', label: 'Base Damage', type: FieldType.integer, defaultValue: 10),
  FieldSchema(key: 'baseArmor', label: 'Base Armor', type: FieldType.integer, defaultValue: 0),
  FieldSchema(
    key: 'maxSkillSlots',
    label: 'Max Skill Slots',
    type: FieldType.integer,
    defaultValue: 3,
  ),
];

const String gameConfigAssetPath = 'assets/gamedata/game_config.json';
const String gameConfigPrefsKey = 'gamedb_game_config';
