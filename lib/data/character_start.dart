/// What a race and a profession add up to at the start (v1.198), the sum
/// PlayerSessionNotifier.startNewGame writes: the New Game Defaults
/// (game_config.json) plus each preset's bonuses. The picker shows it
/// before the choice is made.
class StartingTotals {
  const StartingTotals({
    required this.maxHealth,
    required this.baseDamage,
    required this.baseArmor,
    required this.gold,
    required this.luck,
    required this.charisma,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.perception,
  });

  final int maxHealth, baseDamage, baseArmor, gold, luck, charisma;
  final int strength, dexterity, constitution, intelligence, wisdom, perception;

  /// The six abilities by their short l10n key, zeros left out.
  Map<String, int> get abilities => {
        for (final e in {
          'str_abbrev': strength,
          'dex_abbrev': dexterity,
          'con_abbrev': constitution,
          'int_abbrev': intelligence,
          'wis_abbrev': wisdom,
          'per_abbrev': perception,
        }.entries)
          if (e.value != 0) e.key: e.value,
      };
}

int presetBonus(Map<String, dynamic>? preset, String key) =>
    (preset?[key] as num?)?.toInt() ?? 0;

StartingTotals startingTotals({
  required Map<String, dynamic> defaults,
  Map<String, dynamic>? race,
  Map<String, dynamic>? profession,
}) {
  int sum(String key, String bonusKey, int fallback) =>
      ((defaults[key] as num?)?.toInt() ?? fallback) +
      presetBonus(race, bonusKey) +
      presetBonus(profession, bonusKey);
  return StartingTotals(
    maxHealth: sum('maxHealth', 'bonusMaxHealth', 100),
    baseDamage: sum('baseDamage', 'bonusBaseDamage', 10),
    baseArmor: sum('baseArmor', 'bonusBaseArmor', 0),
    gold: sum('gold', 'startingGoldBonus', 0),
    luck: sum('luck', 'bonusLuck', 0),
    charisma: sum('charisma', 'bonusCharisma', 0),
    strength: sum('strength', 'bonusStrength', 0),
    dexterity: sum('dexterity', 'bonusDexterity', 0),
    constitution: sum('constitution', 'bonusConstitution', 0),
    intelligence: sum('intelligence', 'bonusIntelligence', 0),
    wisdom: sum('wisdom', 'bonusWisdom', 0),
    perception: sum('perception', 'bonusPerception', 0),
  );
}

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

/// "Stoneskin" for `dwarf_stoneskin`: the granted skill's id, its
/// preset's own name dropped, the rest in title case.
String grantedSkillName(String skillId, {String? presetId}) {
  final words = skillId.split('_').where((w) => w.isNotEmpty).toList();
  if (presetId != null && words.length > 1 && words.first == presetId) {
    words.removeAt(0);
  }
  return words.map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}
