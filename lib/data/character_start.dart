/// A starting character's base armor: what its race and profession add to
/// the defaults, never below 0. Frail pairs (an Orc Mage: -2 and -2) start
/// at 0 instead of showing a negative armor that reads as a bug.
int startingArmor(int sum) => sum < 0 ? 0 : sum;

int presetBonus(Map<String, dynamic>? preset, String key) =>
    (preset?[key] as num?)?.toInt() ?? 0;

/// A preset's non-zero bonuses as (l10n key, value) pairs: the body first
/// (HP, damage, armour, gold, luck, charisma), then the abilities.
List<MapEntry<String, int>> presetBonuses(Map<String, dynamic> preset,
    {bool withOffers = false}) {
  const keys = [
    ('bonusMaxHealth', 'hp_label'),
    ('bonusBaseDamage', 'damage_label'),
    ('bonusBaseArmor', 'arm_abbrev'),
    ('startingGoldBonus', 'gold_field_label'),
    ('bonusLuck', 'luck_label'),
    ('bonusCharisma', 'charisma_label'),
    ('bonusStrength', 'str_abbrev'),
    ('bonusDexterity', 'dex_abbrev'),
    ('bonusConstitution', 'con_abbrev'),
    ('bonusIntelligence', 'int_abbrev'),
    ('bonusWisdom', 'wis_abbrev'),
    ('bonusPerception', 'per_abbrev'),
    ('startingSkillPoints', 'offer_bonus_label'),
  ];
  return [
    for (final (field, label) in keys)
      if (presetBonus(preset, field) != 0 &&
          (withOffers || field != 'startingSkillPoints'))
        MapEntry(label, presetBonus(preset, field)),
  ];
}

/// The die every profession without a `startingDiceId` starts with.
const String starterDiceId = 'starter_die';

/// The starter die's face indexes reserved for the player's profession and
/// race standard skills (see assets/gamedata/dice.json's starter_die).
/// Every profession's starting die keeps them at the same indexes.
const int starterDieProfessionFaceIndex = 4;
const int starterDieRaceFaceIndex = 5;

/// The apprentice die's Channeling face, where a caster's mana skill sits
/// from the start (see `manaSkillID` in professions.json).
const int startingDieManaFaceIndex = 1;

/// A new character's numbers (R5 of core-improvements.md): the New Game
/// Defaults ([defaults], game_config.json or its override) plus the
/// race's and the profession's bonuses. One rule for the game
/// (`PlayerSessionNotifier.startNewGame`) and the simulator
/// (`SimCharacter.create`).
({
  int maxHealth,
  int baseDamage,
  int baseArmor,
  int luck,
  int charisma,
  int strength,
  int dexterity,
  int constitution,
  int intelligence,
  int wisdom,
  int perception,
  int gold,
}) newCharacterTotals(Map<String, dynamic> defaults, Map<String, dynamic> race,
    Map<String, dynamic> profession) {
  int total(String key, String bonusKey, {int fallback = 0}) =>
      ((defaults[key] as num?)?.toInt() ?? fallback) +
      presetBonus(race, bonusKey) +
      presetBonus(profession, bonusKey);
  return (
    maxHealth: total('maxHealth', 'bonusMaxHealth', fallback: 20),
    baseDamage: total('baseDamage', 'bonusBaseDamage', fallback: 2),
    baseArmor: startingArmor(total('baseArmor', 'bonusBaseArmor')),
    luck: total('luck', 'bonusLuck'),
    charisma: total('charisma', 'bonusCharisma'),
    strength: total('strength', 'bonusStrength'),
    dexterity: total('dexterity', 'bonusDexterity'),
    constitution: total('constitution', 'bonusConstitution'),
    intelligence: total('intelligence', 'bonusIntelligence'),
    wisdom: total('wisdom', 'bonusWisdom'),
    perception: total('perception', 'bonusPerception'),
    gold: total('gold', 'startingGoldBonus'),
  );
}

/// The one die a new character of [profession] starts with: its own
/// `startingDiceId` (a Mage's or Cleric's apprentice die, with its Focus
/// and Channeling faces) or the starter die.
String startingDiceIdFor(Map<String, dynamic> profession) {
  final id = profession['startingDiceId']?.toString() ?? '';
  return id.isEmpty ? starterDiceId : id;
}

/// The spells a new character of [profession] knows.
List<String> startingSpellIdsFor(Map<String, dynamic> profession) =>
    (profession['startingSpellIds'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
    const [];

/// The skills a new character of [race] and [profession] knows: the
/// profession's standard skill, a caster's mana skill (`manaSkillID`:
/// Channel for a Mage, Prayer for a Cleric) and the race's standard
/// skill. Nothing from another class: the generic Heavy Blow every open
/// Skill face falls back to is the only skill everyone shares.
List<String> starterSkillsFor(
    Map<String, dynamic> race, Map<String, dynamic> profession) {
  final ids = [
    profession['standardSkillID']?.toString() ?? '',
    profession['manaSkillID']?.toString() ?? '',
    race['standardSkillID']?.toString() ?? '',
  ];
  return [
    for (final id in ids.toSet())
      if (id.isNotEmpty) id,
  ];
}

/// Where the starter skills sit on the starting die: the profession's
/// technique on the Profession Technique face, the race's on the
/// Heritage Technique face, and a caster's mana skill on the apprentice
/// die's Channeling face.
Map<String, String> starterFaceAssignments(
    Map<String, dynamic> race, Map<String, dynamic> profession) {
  final professionSkillId = profession['standardSkillID']?.toString() ?? '';
  final manaSkillId = profession['manaSkillID']?.toString() ?? '';
  final raceSkillId = race['standardSkillID']?.toString() ?? '';
  return {
    if (manaSkillId.isNotEmpty)
      startingDieManaFaceIndex.toString(): manaSkillId,
    if (professionSkillId.isNotEmpty)
      starterDieProfessionFaceIndex.toString(): professionSkillId,
    if (raceSkillId.isNotEmpty) starterDieRaceFaceIndex.toString(): raceSkillId,
  };
}
