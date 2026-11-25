// What a pick's ability does for the hero who takes it, for the pick cards
// (docs/proposals/stat-scale.md §5): "+1 DEX: +1 damage, +2% dodge" for a
// rogue, "+1 DEX: +2% dodge" for a warrior. Pure: the numbers come from
// stat_rules.dart and shop_pricing.dart, the words from app_strings.dart.
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import '../combat/combat_engine.dart' show criticalChanceFor, dodgeChanceFor;
import '../combat/gear_effects.dart';
import '../combat/spells.dart'
    show SpellSpec, wisdomHealBonusFor, wisdomManaBonusFor;
import '../combat/stat_rules.dart';
import '../combat/strike_damage.dart' show strikeDamageFor;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import 'ability_check.dart' show abilityScoreFor, checkBonusFor;
import 'shop_pricing.dart' show charismaDiscountFor, charismaDiscountPerPoint;
import 'signs.dart' show SignEffects, SignRarity;
import 'tower/tower_tables.dart'
    show towerParleyAbilities, towerSetbackAbilities;
import 'training.dart' show statPickOdds;

/// What an ability point does, by kind (see [statPickEffects]).
enum _StatEffectKind {
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
  towerChecks,
}

/// One thing [amount] points of an ability do: its [kind] and how much
/// ([amount] is 0 for a kind without a number: reading foes, rarer picks,
/// story checks; percentages are in points of %).
typedef StatEffect = ({_StatEffectKind kind, num amount});

/// What [amount] points of [stat] do for a hero of [professionId], in the
/// order a card lists them. [tower]: the Tower's pick, where no story check
/// and no shop reads a stat: Strength off the damage stat and Charisma speak
/// of the Tower's checks (its setbacks, its parleys; tower_tables.dart),
/// Intelligence off the damage stat of nothing.
List<StatEffect> statPickEffects(String stat, String? professionId, int amount,
    {bool tower = false}) {
  final damage = damageStatOf(professionId) == stat;
  final checks = tower
      ? (kind: _StatEffectKind.towerChecks, amount: 0)
      : (kind: _StatEffectKind.storyChecks, amount: 0);
  return switch (stat) {
    'strength' => [
        if (damage) (kind: _StatEffectKind.damage, amount: amount),
        if (!damage) checks,
      ],
    'dexterity' => [
        if (damage) (kind: _StatEffectKind.damage, amount: amount),
        (kind: _StatEffectKind.dodge, amount: amount * dodgePerDexterity),
      ],
    'constitution' => [
        (kind: _StatEffectKind.health, amount: amount * healthPerConstitution),
      ],
    'intelligence' => [
        if (damage) (kind: _StatEffectKind.damage, amount: amount),
        if (!damage && !tower) checks,
      ],
    'wisdom' => [(kind: _StatEffectKind.mana, amount: amount)],
    'perception' => [
        if (professionId == 'warrior')
          (kind: _StatEffectKind.block, amount: amount * blockPerPerception),
        if (sharpEyed(professionId)) ...[
          (kind: _StatEffectKind.crit, amount: amount * perceptionCritPerPoint),
          (
            kind: _StatEffectKind.dodge,
            amount: amount * perceptionDodgePerPoint
          ),
        ],
        (kind: _StatEffectKind.readFoes, amount: 0),
      ],
    'luck' => [
        (kind: _StatEffectKind.crit, amount: amount * critPerLuck),
        (kind: _StatEffectKind.rarerPicks, amount: 0),
      ],
    'charisma' when tower => [checks],
    'charisma' => [
        (
          kind: _StatEffectKind.shopPrices,
          amount: amount * charismaDiscountPerPoint * 100
        ),
      ],
    _ => const [],
  };
}

/// The short name of [stat] on a card ("DEX", "FOR").
String _statAbbrevKey(String stat) => switch (stat) {
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
    _StatEffectKind.damage => 'stat_effect_damage',
    _StatEffectKind.health => 'stat_effect_health',
    _StatEffectKind.dodge => 'stat_effect_dodge',
    _StatEffectKind.crit => 'stat_effect_crit',
    _StatEffectKind.block => 'stat_effect_block',
    _StatEffectKind.mana => 'stat_effect_mana',
    _StatEffectKind.readFoes => 'stat_effect_read_foes',
    _StatEffectKind.rarerPicks => 'stat_effect_luckier_picks',
    _StatEffectKind.shopPrices => 'stat_effect_shop_prices',
    _StatEffectKind.storyChecks => 'stat_effect_story_checks',
    _StatEffectKind.towerChecks => 'stat_effect_tower_checks',
  };
  return trFor(language, key).replaceAll('{n}', _number(effect.amount));
}

/// A pick card's line for [amount] points of [stat] in the hands of a hero
/// of [professionId]: "+1 DEX: +1 damage, +2% dodge".
@visibleForTesting
String statPickEffect(
    String stat, String? professionId, int amount, AppLanguage language,
    {bool tower = false}) {
  final effects = statPickEffects(stat, professionId, amount, tower: tower);
  final head = '+$amount ${trFor(language, _statAbbrevKey(stat))}';
  if (effects.isEmpty) return head;
  return '$head: ${effects.map((e) => statEffectText(e, language)).join(', ')}';
}

// ---------------------------------------------------------------------------
// The before -> after preview (v2.10.15): what a pick changes, number by
// number, for the Level Up cards. Each value is the one the fight (or the
// story, or the Tower) reads, worked out on the session as it stands and on
// the session with the pick taken (PlayerSession.withAbilityGains, the very
// step a pick goes through).

/// One number a pick moves: [labelKey] (an app_strings key, stat_preview_*),
/// its value [before] and [after] the pick, and its [unit] ('%' for a
/// chance or a discount, '' for a plain number).
class StatPreviewRow {
  const StatPreviewRow({
    required this.labelKey,
    required this.before,
    required this.after,
    this.unit = '',
  });

  final String labelKey;
  final num before;
  final num after;
  final String unit;

  @override
  String toString() => '$labelKey: $before$unit -> $after$unit';
}

/// What a pick changes ([statPickPreview]): its [rows], only those whose
/// value moves, in the order a card lists them; [noTowerEffect] true for a
/// Tower pick that moves nothing in a fight and that no Tower check reads
/// (Intelligence for a warrior, a ranger or a rogue). Rows empty and
/// [noTowerEffect] false: the stat counts, but this step moves nothing yet
/// (a capped chance, a check bonus between two roundings).
class StatPickPreview {
  const StatPickPreview({required this.rows, required this.noTowerEffect});

  final List<StatPreviewRow> rows;
  final bool noTowerEffect;
}

/// The label of each row (see [statPickPreview]); the Tower's two checks
/// and the story's have their own.
const List<String> statPreviewLabelKeys = [
  'stat_preview_damage',
  'stat_preview_max_health',
  'stat_preview_dodge',
  'stat_preview_crit',
  'stat_preview_block',
  'stat_preview_max_mana',
  'stat_preview_heal',
  'stat_preview_mana',
  'stat_preview_spells',
  'stat_preview_read_foes',
  'stat_preview_story_checks',
  'stat_preview_tower_setback',
  'stat_preview_tower_parley',
  'stat_preview_rare_picks',
  'stat_preview_shop',
  'stat_preview_no_tower_effect',
];

/// What [amount] points of [stat] change for [session]'s hero: see
/// [statPickPreviewOf].
StatPickPreview statPickPreview(
  PlayerSession session,
  String stat,
  int amount, {
  bool tower = false,
  Map<String, dynamic> items = const {},
  Map<String, ItemSet> itemSets = const {},
  SignEffects signs = SignEffects.none,
  Map<String, SpellSpec> spells = const {},
}) =>
    statPickPreviewOf(session, {stat: amount},
        tower: tower,
        items: items,
        itemSets: itemSets,
        signs: signs,
        spells: spells);

/// What a pick of [gains] (ability -> points; an offer's `gains`) changes
/// for [session]'s hero (the story's, or the Tower's: towerSessionOf), each
/// row worked out before and after the pick as the fight works it out
/// (fight_setup.dart, fight_enemy_turn.dart, fight_dice_rules.dart):
///
/// - damage: the strike's damage before the dice ([strikeDamageFor], an
///   element-less strike): base damage (the calling's damage stat), the
///   worn gear's attack and stat scaling, the sets' and perks' attack. Only
///   the damage stat moves it, and a stat a worn item scales with.
/// - max health: the session's, with a health sign ([SignEffects.maxHealthFor];
///   the party bonus a fight's foes bring is left out). Constitution.
/// - dodge: [dodgeChanceFor] (capped) and the gear's, signs' and perks'
///   dodge on top, as a blow reads it. Dexterity; Perception for a ranger
///   or a rogue.
/// - crit: [criticalChanceFor] (capped), the gear's crit and
///   [perceptionCritBonus], at most 50 as a strike reads it. Luck;
///   Perception for a ranger or a rogue.
/// - block: [blockChanceWith], the gear's block on top. A warrior's
///   Perception.
/// - max mana (the session's, perks included, and a mana sign), the heal
///   bonus ([wisdomHealBonusFor]) and the mana bonus ([wisdomManaBonusFor]):
///   Wisdom.
/// - spells: the amount a spell adds for its scaling stat (spellAmountFor:
///   one a 4 points), shown only when the hero knows a spell of [spells]
///   that scales with the stat. Without [spells], no row.
/// - read foes: the Perception the fight's telegraphs read (telegraphTierFor
///   reads it less the foe's guile), the score itself.
/// - checks: [checkBonusFor] the score. Story: every story check reads
///   every ability. Tower: its setbacks read Strength, Dexterity and Wisdom
///   ([towerSetbackAbilities]), its parleys Charisma, Wisdom and Dexterity
///   ([towerParleyAbilities]).
/// - rare picks: the share of the pick odds above Common ([statPickOdds]):
///   Luck, up to its cap.
/// - shop: the Charisma discount ([charismaDiscountFor]), story only (the
///   Tower's merchant ignores Charisma).
///
/// The fight's own values take [items] and [itemSets] (items.json, the
/// sets) for the gear as the fight sums it ([gearEffectsFor] with the
/// session's perks and [signs] laid over it, [signs] also lending its
/// stats); without them the gear adds nothing but the perks. Pure.
StatPickPreview statPickPreviewOf(
  PlayerSession session,
  Map<String, int> gains, {
  bool tower = false,
  Map<String, dynamic> items = const {},
  Map<String, ItemSet> itemSets = const {},
  SignEffects signs = SignEffects.none,
  Map<String, SpellSpec> spells = const {},
}) {
  final before = session;
  final after = session.withAbilityGains(gains);
  final rows = <StatPreviewRow>[];
  void row(String key, num Function(PlayerSession s) value,
      {String unit = ''}) {
    // A chance or a discount to a tenth of a point (1.5 a Luck point).
    num shown(num v) => unit == '%' ? (v * 10).round() / 10 : v;
    final a = shown(value(before));
    final b = shown(value(after));
    if ((a - b).abs() < 1e-9) return;
    rows.add(StatPreviewRow(labelKey: key, before: a, after: b, unit: unit));
  }

  // The hero as the fight builds it (fight_setup.dart): a sign lends its
  // stats; the gear is the sets' and uniques', the perks and signs over it.
  int score(PlayerSession s, String ability) =>
      abilityScoreFor(ability, s) + signs.stat(ability);
  final gear = signs.over(session.perkEffects
      .over(gearEffectsFor(session.equippedItemIds, items, itemSets)));
  final professionId = session.professionId;

  row(
      'stat_preview_damage',
      (s) => strikeDamageFor(
            baseDamage: s.baseDamage + signs.stat(damageStatOf(professionId)),
            equippedItemIds: s.equippedItemIds,
            items: items,
            element: 'None',
            gearAttack: gear.attackDamage,
            strength: score(s, 'strength'),
            dexterity: score(s, 'dexterity'),
            constitution: score(s, 'constitution'),
            intelligence: score(s, 'intelligence'),
            alignmentLabel: s.alignmentLabel,
          ));
  row('stat_preview_max_health', (s) => signs.maxHealthFor(s.maxHealth));
  row(
      'stat_preview_dodge',
      (s) =>
          dodgeChanceFor(score(s, 'dexterity'),
              perception: score(s, 'perception'), professionId: professionId) +
          gear.dodgeChance,
      unit: '%');
  row(
      'stat_preview_crit',
      (s) => min(
          50.0,
          criticalChanceFor(score(s, 'luck')) +
              gear.critChance +
              perceptionCritBonus(professionId, score(s, 'perception'))),
      unit: '%');
  row(
      'stat_preview_block',
      (s) => blockChanceWith(
          professionId, score(s, 'perception'), gear.blockChance),
      unit: '%');
  row('stat_preview_max_mana', (s) => s.maxMana + signs.maxMana);
  row('stat_preview_heal', (s) => wisdomHealBonusFor(score(s, 'wisdom')));
  row('stat_preview_mana', (s) => wisdomManaBonusFor(score(s, 'wisdom')));
  final scaled = {
    for (final id in session.knownSpellIds)
      if (spells[id] case final spell?) spell.scalingStat,
  };
  for (final ability in ['intelligence', 'wisdom', 'strength']) {
    if (!scaled.contains(ability) || !gains.containsKey(ability)) continue;
    row('stat_preview_spells', (s) => max(0, score(s, ability)) ~/ 4);
  }
  row('stat_preview_read_foes', (s) => max(0, score(s, 'perception')));
  for (final ability in gains.keys) {
    if (!tower) {
      row('stat_preview_story_checks',
          (s) => checkBonusFor(abilityScoreFor(ability, s)));
      continue;
    }
    if (towerSetbackAbilities.contains(ability)) {
      row('stat_preview_tower_setback',
          (s) => checkBonusFor(abilityScoreFor(ability, s)));
    }
    if (towerParleyAbilities.contains(ability)) {
      row('stat_preview_tower_parley',
          (s) => checkBonusFor(abilityScoreFor(ability, s)));
    }
  }
  row('stat_preview_rare_picks',
      (s) => 100 - statPickOdds(s.luck)[SignRarity.common]!,
      unit: '%');
  if (!tower) {
    row('stat_preview_shop', (s) => charismaDiscountFor(s.charisma) * 100,
        unit: '%');
  }
  final towerRead = gains.keys.any((a) =>
      towerSetbackAbilities.contains(a) || towerParleyAbilities.contains(a));
  return StatPickPreview(
    rows: rows,
    noTowerEffect: tower && rows.isEmpty && !towerRead,
  );
}
