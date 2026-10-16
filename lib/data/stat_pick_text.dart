// What a pick's ability does for the hero who takes it, for the pick cards
// (docs/proposals/stat-scale.md §5): "+1 DEX: +1 damage, +2% dodge" for a
// rogue, "+1 DEX: +2% dodge" for a warrior. Pure: the numbers come from
// stat_rules.dart and shop_pricing.dart, the words from app_strings.dart.
import '../combat/stat_rules.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'shop_pricing.dart' show charismaDiscountPerPoint;

/// What an ability point does, by kind (see [statPickEffects]).
enum StatEffectKind {
  damage,
  health,
  dodge,
  crit,
  block,
  mana,
  readFoes,
  rarerPicks,
  shopPrices,
  storyChecks,
}

/// One thing [amount] points of an ability do: its [kind] and how much
/// ([amount] is 0 for a kind without a number: reading foes, rarer picks,
/// story checks; percentages are in points of %).
typedef StatEffect = ({StatEffectKind kind, num amount});

/// What [amount] points of [stat] do for a hero of [professionId], in the
/// order a card lists them.
List<StatEffect> statPickEffects(
    String stat, String? professionId, int amount) {
  final damage = damageStatOf(professionId) == stat;
  return switch (stat) {
    'strength' => [
        if (damage) (kind: StatEffectKind.damage, amount: amount),
        if (!damage) (kind: StatEffectKind.storyChecks, amount: 0),
      ],
    'dexterity' => [
        if (damage) (kind: StatEffectKind.damage, amount: amount),
        (kind: StatEffectKind.dodge, amount: amount * dodgePerDexterity),
      ],
    'constitution' => [
        (kind: StatEffectKind.health, amount: amount * healthPerConstitution),
      ],
    'intelligence' => [
        if (damage) (kind: StatEffectKind.damage, amount: amount),
        if (!damage) (kind: StatEffectKind.storyChecks, amount: 0),
      ],
    'wisdom' => [(kind: StatEffectKind.mana, amount: amount)],
    'perception' => [
        if (professionId == 'warrior')
          (kind: StatEffectKind.block, amount: amount * blockPerPerception),
        if (sharpEyed(professionId)) ...[
          (kind: StatEffectKind.crit, amount: amount * perceptionCritPerPoint),
          (
            kind: StatEffectKind.dodge,
            amount: amount * perceptionDodgePerPoint
          ),
        ],
        (kind: StatEffectKind.readFoes, amount: 0),
      ],
    'luck' => [
        (kind: StatEffectKind.crit, amount: amount * critPerLuck),
        (kind: StatEffectKind.rarerPicks, amount: 0),
      ],
    'charisma' => [
        (
          kind: StatEffectKind.shopPrices,
          amount: amount * charismaDiscountPerPoint * 100
        ),
      ],
    _ => const [],
  };
}

/// The short name of [stat] on a card ("DEX", "FOR").
String statAbbrevKey(String stat) => switch (stat) {
      'strength' => 'str_abbrev',
      'dexterity' => 'dex_abbrev',
      'constitution' => 'con_abbrev',
      'intelligence' => 'int_abbrev',
      'wisdom' => 'wis_abbrev',
      'perception' => 'per_abbrev',
      'luck' => 'luck_abbrev',
      'charisma' => 'cha_abbrev',
      _ => stat,
    };

String _number(num n) {
  final rounded = (n * 10).round() / 10;
  return rounded == rounded.roundToDouble() ? '${rounded.round()}' : '$rounded';
}

/// One effect in words: "+2% dodge", "reads foes better".
String statEffectText(StatEffect effect, AppLanguage language) {
  final key = switch (effect.kind) {
    StatEffectKind.damage => 'stat_effect_damage',
    StatEffectKind.health => 'stat_effect_health',
    StatEffectKind.dodge => 'stat_effect_dodge',
    StatEffectKind.crit => 'stat_effect_crit',
    StatEffectKind.block => 'stat_effect_block',
    StatEffectKind.mana => 'stat_effect_mana',
    StatEffectKind.readFoes => 'stat_effect_read_foes',
    StatEffectKind.rarerPicks => 'stat_effect_luckier_picks',
    StatEffectKind.shopPrices => 'stat_effect_shop_prices',
    StatEffectKind.storyChecks => 'stat_effect_story_checks',
  };
  return trFor(language, key).replaceAll('{n}', _number(effect.amount));
}

/// A pick card's line for [amount] points of [stat] in the hands of a hero
/// of [professionId]: "+1 DEX: +1 damage, +2% dodge".
String statPickEffect(
    String stat, String? professionId, int amount, AppLanguage language) {
  final effects = statPickEffects(stat, professionId, amount);
  final head = '+$amount ${trFor(language, statAbbrevKey(stat))}';
  if (effects.isEmpty) return head;
  return '$head: ${effects.map((e) => statEffectText(e, language)).join(', ')}';
}

/// The line of a whole offer ([gains], ability -> points), one ability
/// after the other: "+2 STR: +2 damage · +1 CON: +5 health".
String statPickOfferEffect(
        Map<String, int> gains, String? professionId, AppLanguage language) =>
    [
      for (final MapEntry(:key, :value) in gains.entries)
        statPickEffect(key, professionId, value, language),
    ].join(' · ');
