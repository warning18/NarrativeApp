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
