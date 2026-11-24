// Where a stat comes from (docs/proposals/stat-scale.md §7b), for the
// Character radar's popin: "Strength 9 -- race +1, profession +2, picks +4,
// patron +1...".
//
// The rows of [statBreakdown] add up to the stat as the next fight starts
// with it (see [StatBreakdownTotals]):
//
// - **kept** rows add up to the number the session stores (what the
//   Character page's radar and header show): the New Game Defaults
//   (`base`), the race and the profession, the floor that keeps a starting
//   armor at 0 (`floor`), the levels (`level`: max health), the perks
//   (`perk`: Vigor's max health), and the ledger (stat_ledger.dart:
//   `origin`, `pick`, `tome`, `patron`); then `earlier`, whatever these
//   don't explain -- a save from before the ledger (v1.459), Edit Mode's
//   stat editor. `earlier` is signed: below 0 when something lowered the
//   stat that nothing records (an old save's rescale, an edit), so the kept
//   rows always add up to the stored number.
// - **lent** rows are what a fight lends on top (fight_setup.dart): the
//   gear worn (`gear`: base damage and armor, an item or a set by its id),
//   the perks that act like gear (`perk`: damage, armor), the held signs
//   (`sign`), the title worn and every bad title (`title`), and the Sworn
//   boon (`sworn`). The party's bonus against an enemy (a boss beaten
//   before, a house built) depends on the fight and is left out.
//
// Pure: [statBreakdownProvider] (stat_breakdown_provider.dart) feeds it the
// tables.
import '../combat/gear_effects.dart';
import '../combat/stat_rules.dart' show damageStatOf, levelHealthGain;
import '../models/ally_state.dart'
    show alignmentGearBonusFor, equipmentBonusFor;
import '../providers/player_session_provider.dart' show PlayerSession;
import 'character_start.dart' show presetBonus;
import 'factions.dart' show ClanData;
import 'offers.dart' show clanEffectsFor;
import 'perks.dart' show perkEffectsFor;
import 'signs.dart';
import 'stat_ledger.dart';

export 'stat_ledger.dart' show breakdownStats;

/// One row of a stat's breakdown: [amount] points from [kind] (see the file
/// comment), [id] naming it (the race id, the path id, the clan id, the
/// item id... '' when there is nothing to name). [lent] for what a fight
/// lends on top of the stored number.
class StatSource {
  const StatSource({
    required this.kind,
    this.id = '',
    required this.amount,
    this.lent = false,
  });

  final String kind;
  final String id;
  final int amount;
  final bool lent;

  @override
  bool operator ==(Object other) =>
      other is StatSource &&
      other.kind == kind &&
      other.id == id &&
      other.amount == amount &&
      other.lent == lent;

  @override
  int get hashCode => Object.hash(kind, id, amount, lent);

  @override
  String toString() =>
      'StatSource($kind${id.isEmpty ? '' : ':$id'} ${amount >= 0 ? '+' : ''}$amount${lent ? ', lent' : ''})';
}

/// The two numbers a breakdown adds up to.
extension StatBreakdownTotals on List<StatSource> {
  /// The stat the session stores (the Character page's number): the kept
  /// rows.
  int get storedTotal =>
      fold<int>(0, (sum, r) => r.lent ? sum : sum + r.amount);

  /// The stat a fight starts with: every row.
  int get fightTotal => fold<int>(0, (sum, r) => sum + r.amount);

  /// The rows of [kind].
  List<StatSource> ofKind(String kind) => [
        for (final r in this)
          if (r.kind == kind) r
      ];
}

/// The New Game Defaults' fallback for [stat] when game_config.json has
/// none: the ones PlayerSessionNotifier.startNewGame uses.
int _defaultFor(String stat) => switch (stat) {
      'maxHealth' => 20,
      'baseDamage' => 2,
      _ => 0,
    };

/// The race's or profession's bonus field for [stat].
String _bonusField(String stat) =>
    'bonus${stat[0].toUpperCase()}${stat.substring(1)}';

/// The session's stored value of [stat] (see [breakdownStats]).
int storedStatOf(PlayerSession s, String stat) => switch (stat) {
      'strength' => s.strength,
      'dexterity' => s.dexterity,
      'constitution' => s.constitution,
      'intelligence' => s.intelligence,
      'wisdom' => s.wisdom,
      'perception' => s.perception,
      'luck' => s.luck,
      'charisma' => s.charisma,
      'maxHealth' => s.maxHealth,
      'baseDamage' => s.baseDamage,
      'baseArmor' => s.baseArmor,
      _ => throw ArgumentError.value(stat, 'stat', 'not a breakdown stat'),
    };

/// Where [stat] (one of [breakdownStats]) of [s] comes from, as rows whose
/// kept ones add up to the stored number and all of them to the fight's
/// (see the file comment and [StatBreakdownTotals]). Rows of 0 are left
/// out; the kept rows come first, base to earlier, then the lent ones.
///
/// [races], [professions], [gameConfig] (its New Game Defaults) and
/// [items] are the raw tables; [itemSets] the parsed sets
/// (parseItemSets); [signs] the parsed signs (parseSigns) and [clans] the
/// titles and the clans' Sworn boons. Without [signs] and [clans] no sign,
/// title or Sworn row is shown.
List<StatSource> statBreakdown(
  PlayerSession s,
  String stat, {
  required Map<String, dynamic> races,
  required Map<String, dynamic> professions,
  required Map<String, dynamic> gameConfig,
  required Map<String, dynamic> items,
  Map<String, ItemSet> itemSets = const {},
  Map<String, SignDef> signs = const {},
  ClanData clans = ClanData.empty,
}) {
  if (!breakdownStats.contains(stat)) {
    throw ArgumentError.value(stat, 'stat', 'not a breakdown stat');
  }
  final kept = <StatSource>[];
  void keep(String kind, String id, int amount) {
    if (amount != 0) kept.add(StatSource(kind: kind, id: id, amount: amount));
  }

  // The hero as made (character_start.dart).
  final race = races[s.raceId] as Map<String, dynamic>?;
  final profession = professions[s.professionId] as Map<String, dynamic>?;
  final base = (gameConfig[stat] as num?)?.toInt() ?? _defaultFor(stat);
  final fromRace = presetBonus(race, _bonusField(stat));
  final fromProfession = presetBonus(profession, _bonusField(stat));
  keep('base', '', base);
  keep('race', s.raceId, fromRace);
  keep('profession', s.professionId, fromProfession);
  // A starting armor is never below 0 (startingArmor).
  final made = base + fromRace + fromProfession;
  if (stat == 'baseArmor' && made < 0) keep('floor', '', -made);

  // The levels: max health only (stat_rules.dart).
  if (stat == 'maxHealth') {
    final startLevel = (gameConfig['playerLevel'] as num?)?.toInt() ?? 1;
    keep('level', '', (s.level - startLevel) * levelHealthGain);
    // Vigor's ranks, added to the max as each was taken.
    for (final e in s.perkRanks.entries) {
      keep('perk', e.key, perkEffectsFor({e.key: e.value}).maxHealth);
    }
  }

  // The ledger, kind by kind.
  for (final kind in ledgerKinds) {
    for (final e in s.statSources.entries) {
      final parts = ledgerKeyParts(e.key);
      if (parts.kind != kind) continue;
      keep(kind, parts.id, e.value[stat] ?? 0);
    }
  }

  // Whatever the rest doesn't explain.
  keep('earlier', '', storedStatOf(s, stat) - kept.storedTotal);

  return [
    ...kept,
    ..._lentRows(s, stat,
        items: items, itemSets: itemSets, signs: signs, clans: clans),
  ];
}

/// The lent rows of [stat] (see the file comment), as fight_setup.dart and
/// fight_queries.dart add them.
List<StatSource> _lentRows(
  PlayerSession s,
  String stat, {
  required Map<String, dynamic> items,
  required Map<String, ItemSet> itemSets,
  required Map<String, SignDef> signs,
  required ClanData clans,
}) {
  final rows = <StatSource>[];
  void lend(String kind, String id, int amount) {
    if (amount != 0) {
      rows.add(StatSource(kind: kind, id: id, amount: amount, lent: true));
    }
  }

  // Gear: an item's damage or armor (with its alignment's), a set's tiers.
  if (stat == 'baseDamage' || stat == 'baseArmor') {
    final damage = stat == 'baseDamage';
    for (final id in s.equippedItemIds) {
      final aligned = alignmentGearBonusFor([id], items, s.alignmentLabel);
      lend(
          'gear',
          id,
          damage
              ? equipmentBonusFor([id], items, 'attackDamage') +
                  aligned.damageBonus
              : equipmentBonusFor([id], items, 'armor') + aligned.armorBonus);
    }
    for (final active in activeSetsFor(s.equippedItemIds, itemSets)) {
      var amount = 0;
      for (final tier in active.activeTiers) {
        amount += damage ? tier.attackDamage : tier.armor;
      }
      lend('gear', active.set.id, amount);
    }
    for (final e in s.perkRanks.entries) {
      final perk = perkEffectsFor({e.key: e.value});
      // Iron Hide's armor is a block chance since v1.461, not armor.
      lend('perk', e.key, damage ? perk.attackDamage : 0);
    }
  }

  // The signs, the titles and the Sworn boon, each on its own, then the
  // rounding of a shared percentage evened out against them all together.
  final parts = <(String, String, SignEffects)>[
    for (final h in s.heldSigns)
      (
        'sign',
        h.signId,
        signEffectsFor([h], signs, alignment: s.alignmentScore)
      ),
    for (final id in s.heldTitleIds)
      if (clans.titles[id] case final title?)
        if (id == s.activeTitleId || title.negative)
          ('title', id, _extraEffects(title.effects, signs, s)),
    if (s.politics.swornFactionId case final sworn
        when sworn.isNotEmpty && s.swornBoonIds.contains(sworn))
      if (clans.faction(sworn)?.sworn?.effects case final effects?)
        ('sworn', sworn, _extraEffects(effects, signs, s)),
  ];
  if (parts.isEmpty) return rows;
  final stored = storedStatOf(s, stat);
  int lentBy(SignEffects e) => switch (stat) {
        'maxHealth' => e.maxHealthFor(stored) - stored,
        'baseDamage' => e.stat(damageStatOf(s.professionId)),
        'baseArmor' => e.armor,
        _ => e.stat(stat),
      };
  final all = signEffectsFor(s.heldSigns, signs,
      alignment: s.alignmentScore,
      extra: clanEffectsFor(
        activeTitleId: s.activeTitleId,
        heldTitleIds: s.heldTitleIds,
        swornBoonIds: s.swornBoonIds,
        swornFactionId: s.politics.swornFactionId,
        data: clans,
      ));
  final amounts = [for (final (_, _, e) in parts) lentBy(e)];
  final rest = lentBy(all) - amounts.fold<int>(0, (a, b) => a + b);
  if (rest != 0) {
    final last = amounts.lastIndexWhere((a) => a != 0);
    amounts[last < 0 ? amounts.length - 1 : last] += rest;
  }
  for (final (i, (kind, id, _)) in parts.indexed) {
    lend(kind, id, amounts[i]);
  }
  return rows;
}

SignEffects _extraEffects(List<SignEffect> effects, Map<String, SignDef> signs,
        PlayerSession s) =>
    signEffectsFor(const [], signs,
        alignment: s.alignmentScore, extra: effects);
