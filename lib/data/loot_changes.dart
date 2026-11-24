// What each reward of a loot changes (v1.830, the user's design C for the
// spoils sheet, docs/proposals/loot-dialog-designs.md): for a fight's
// gold and items, a chest's, a voyage's or any other loot handed to
// PlayerSessionNotifier.applyCombatResult, one line per thing a reward
// changes, its value before and after: gold 126 -> 144, Antidote x1 -> x2,
// rolls a round 3 -> 4. The numbers come from the code that applies the
// loot (lootGrantOf, the fight's rolls and potion heal), so the sheet can
// never say something taking the loot doesn't do.

import 'dart:math';

import '../combat/fight_numbers.dart' show maxRollsPerTurn, potionHealAmount;
import '../providers/player_session_provider.dart';

/// What a line of a reward changes.
enum LootChangeKind {
  /// The gold carried.
  gold,

  /// Healing potion charges (what the fight's Potion button reads).
  potions,

  /// Antidote charges.
  antidotes,

  /// Copies of the item [LootChange.subjectId] carried in the bag (a charm,
  /// a material, a trophy, anything that is not worn).
  bagItem,

  /// Dice rolls a round in the next fight the charm is armed for (the
  /// Gambler's Knucklebone).
  rollsPerRound,

  /// The hero's health: a potion drunk from the chest.
  health,

  /// A spell learnt ([LootChange.subjectId] is its id; before 0, after 1).
  spell,

  /// Stat points to spend (a Tome of Insight).
  statPoints,

  /// Clan offers waiting (a Tome of Mastery).
  offers,

  /// Nothing the sheet can count: a piece of gear (it goes in the bag, to
  /// wear), or a spellbook whose spell is known already.
  nothing,
}

/// One thing a reward changes, before and after it is taken.
class LootChange {
  const LootChange({
    required this.kind,
    required this.before,
    required this.after,
    this.subjectId,
  });

  final LootChangeKind kind;

  /// The item or the spell the line is about ([LootChangeKind.bagItem],
  /// [LootChangeKind.spell]); null for the others.
  final String? subjectId;
  final int before;
  final int after;

  @override
  bool operator ==(Object other) =>
      other is LootChange &&
      other.kind == kind &&
      other.subjectId == subjectId &&
      other.before == before &&
      other.after == after;

  @override
  int get hashCode => Object.hash(kind, subjectId, before, after);

  @override
  String toString() =>
      'LootChange(${kind.name}${subjectId == null ? '' : ' $subjectId'}: '
      '$before -> $after)';
}

/// One reward of the loot and what it changes: [id] is the item's id, or
/// [goldRewardId] for the gold. [changes] is never empty; a reward with
/// nothing to count has one [LootChangeKind.nothing] line.
class LootRewardChanges {
  const LootRewardChanges(this.id, this.changes);

  final String id;
  final List<LootChange> changes;

  /// Whether the sheet has a number to show for it.
  bool get visible => changes.any((c) => c.kind != LootChangeKind.nothing);
}

/// The id of the gold reward in [lootChanges].
const String goldRewardId = 'gold';

/// Dice rolls a round for [session] in a fight: the rule's, and Steady
/// Hands' (fight_setup.dart reads the same).
int rollsPerRoundOf(PlayerSession session) =>
    maxRollsPerTurn + session.perkEffects.extraRolls;

/// The rolls a round a charm adds to the fight it is armed for
/// (fight_setup.dart's _applyArmedCharms); 0 for any other item.
int charmExtraRolls(String itemId) => itemId == 'charm_fourth_roll' ? 1 : 0;

/// The health after [drinks] potions drunk from the chest, each healing
/// [potionHealAmount] and [potionBonus] more (fight_rewards.dart).
int healthAfterDrinks({
  required int health,
  required int maxHealth,
  required int drinks,
  int potionBonus = 0,
}) =>
    min(maxHealth, health + drinks * (potionHealAmount + potionBonus));

/// What each reward of a loot changes for [session]: [gold] first (when
/// any), then [itemIds] in their order, each line starting where the
/// rewards before it left the same value (two antidotes: x1 -> x2, then
/// x2 -> x3). [items] is items.json. [drinkItemIds] are the potions the
/// player drinks from the chest: each heals once ([health], [maxHealth]
/// and [potionBonus] are the fight's) and spends one of its charges;
/// with [keepWounds] (a chain with no healing) they are kept as charges.
/// A level-up refills health on its own; this does not show it.
List<LootRewardChanges> lootChanges(
  PlayerSession session, {
  int gold = 0,
  List<String> itemIds = const [],
  Map<String, dynamic> items = const {},
  List<String> drinkItemIds = const [],
  int? health,
  int? maxHealth,
  int potionBonus = 0,
  bool keepWounds = false,
}) {
  final out = <LootRewardChanges>[];
  if (gold != 0) {
    out.add(LootRewardChanges(goldRewardId, [
      LootChange(
          kind: LootChangeKind.gold,
          before: session.gold,
          after: session.gold + gold),
    ]));
  }
  var potions = session.potionCount;
  var antidotes = session.antidoteCount;
  var statPoints = session.statPoints;
  var offers = session.pendingOffers.length;
  var hp = health ?? session.currentHealth;
  final hpMax = maxHealth ?? session.maxHealth;
  final rolls = rollsPerRoundOf(session);
  final known = [...session.knownSpellIds];
  final bag = <String, int>{};
  int carriedCount(String id) => bag[id] ??=
      session.inventoryItemIds.where((carried) => carried == id).length;
  final drinksLeft = [...drinkItemIds];

  for (final id in itemIds) {
    final grant = lootGrantOf([id], items, knownSpellIds: known);
    final changes = <LootChange>[];
    if (grant.potions > 0 || grant.antidotes > 0) {
      if (!keepWounds && grant.potions > 0 && drinksLeft.remove(id)) {
        // Drunk from the chest: one potion's heal; the fight grants its
        // charges and spends one (consumePotion), so a Major Potion (two
        // charges) still leaves one.
        final healed = healthAfterDrinks(
            health: hp, maxHealth: hpMax, drinks: 1, potionBonus: potionBonus);
        changes.add(
            LootChange(kind: LootChangeKind.health, before: hp, after: healed));
        hp = healed;
        final kept = grant.potions - 1;
        if (kept > 0) {
          changes.add(LootChange(
              kind: LootChangeKind.potions,
              before: potions,
              after: potions + kept));
          potions += kept;
        }
      } else if (grant.potions > 0) {
        changes.add(LootChange(
            kind: LootChangeKind.potions,
            before: potions,
            after: potions + grant.potions));
        potions += grant.potions;
      }
      if (grant.antidotes > 0) {
        changes.add(LootChange(
            kind: LootChangeKind.antidotes,
            before: antidotes,
            after: antidotes + grant.antidotes));
        antidotes += grant.antidotes;
      }
    }
    if (grant.statPoints > 0) {
      changes.add(LootChange(
          kind: LootChangeKind.statPoints,
          before: statPoints,
          after: statPoints + grant.statPoints));
      statPoints += grant.statPoints;
    }
    if (grant.offers.isNotEmpty) {
      changes.add(LootChange(
          kind: LootChangeKind.offers,
          before: offers,
          after: offers + grant.offers.length));
      offers += grant.offers.length;
    }
    for (final spell in grant.spellsLearned) {
      changes.add(LootChange(
          kind: LootChangeKind.spell, subjectId: spell, before: 0, after: 1));
      known.add(spell);
    }
    for (final carried in grant.carried) {
      final item = items[carried] as Map<String, dynamic>?;
      if (item?['isEquippable'] == true) continue;
      final before = carriedCount(carried);
      changes.add(LootChange(
          kind: LootChangeKind.bagItem,
          subjectId: carried,
          before: before,
          after: before + 1));
      bag[carried] = before + 1;
      final extra = charmExtraRolls(carried);
      if (extra > 0) {
        changes.add(LootChange(
            kind: LootChangeKind.rollsPerRound,
            before: rolls,
            after: rolls + extra));
      }
    }
    if (changes.isEmpty) {
      changes.add(
          const LootChange(kind: LootChangeKind.nothing, before: 0, after: 0));
    }
    out.add(LootRewardChanges(id, changes));
  }
  return out;
}
