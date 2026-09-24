import 'dart:math';

/// The spoils chest every won fight drops, replacing the old per-enemy
/// loot-table roll (an enemy's `lootTable` now only steers WHICH gear a
/// chest tends to hold -- see [LootContext.signatureItemIds]). Its tier
/// comes from one visible "fortune roll" (see [fortuneRollFor]) so the
/// player learns what raises it: Luck, an Elite or boss kill, a pack, a
/// clean or quick fight, a crit on the killing blow, affixed enemies, and
/// a bad-luck streak. Everything here is pure and seeded so it's
/// unit-testable and portable to the playthrough simulator.
enum ChestTier { wooden, iron, silver, gold, voidTier }

/// Fortune-roll thresholds, checked lowest to highest -- a roll below the
/// first is Wooden.
const int ironThreshold = 40;
const int silverThreshold = 70;
const int goldThreshold = 100;
const int voidThreshold = 125;

/// Points per Luck on the fortune roll, for the player and for the best
/// ally respectively.
const int luckFortuneWeight = 2;
const int allyLuckFortuneWeight = 1;
const int eliteFortuneBonus = 25;
const int packFortuneBonusPerExtraEnemy = 6;
const int flawlessFortuneBonus = 8;
const int swiftFortuneBonus = 8;
const int swiftRoundLimit = 2;
const int criticalFinishFortuneBonus = 8;
const int affixFortuneBonusEach = 8;
const int pityFortuneBonusPerStreak = 15;

/// Base gold per tier before chapter scaling; each chest then rolls
/// +/-30% around it.
const Map<ChestTier, int> chestBaseGold = {
  ChestTier.wooden: 2,
  ChestTier.iron: 4,
  ChestTier.silver: 8,
  ChestTier.gold: 14,
  ChestTier.voidTier: 28,
};

String chestTierLabelKey(ChestTier tier) => switch (tier) {
      ChestTier.wooden => 'chest_tier_wooden',
      ChestTier.iron => 'chest_tier_iron',
      ChestTier.silver => 'chest_tier_silver',
      ChestTier.gold => 'chest_tier_gold',
      ChestTier.voidTier => 'chest_tier_void',
    };

/// The asset id (also the icon file stem) for [tier].
String chestTierAssetName(ChestTier tier) => switch (tier) {
      ChestTier.wooden => 'wooden',
      ChestTier.iron => 'iron',
      ChestTier.silver => 'silver',
      ChestTier.gold => 'gold',
      ChestTier.voidTier => 'void',
    };

ChestTier? chestTierFromName(String? name) {
  if (name == null) return null;
  for (final tier in ChestTier.values) {
    if (chestTierAssetName(tier) == name || tier.name == name) return tier;
  }
  return null;
}

ChestTier _maxTier(ChestTier a, ChestTier b) => a.index >= b.index ? a : b;

ChestTier _shiftTier(ChestTier tier, int steps) => ChestTier
    .values[(tier.index + steps).clamp(0, ChestTier.values.length - 1)];

/// One line of the fortune roll's visible breakdown.
class FortuneModifier {
  const FortuneModifier(this.labelKey, this.value);

  /// l10n key naming the factor ("fortune_luck", ...).
  final String labelKey;
  final int value;
}

/// Everything about the fight and the party that steers a chest.
class LootContext {
  const LootContext({
    required this.chapter,
    this.playerLuck = 0,
    this.bestAllyLuck = 0,
    this.isElite = false,
    this.hasBossOrUnique = false,
    this.enemyCount = 1,
    this.flawless = false,
    this.rounds = 99,
    this.finalBlowCritical = false,
    this.fullTelegraphRead = false,
    this.firstKill = false,
    this.pityStreak = 0,
    this.affixCount = 0,
    this.conditionBonus = 0,
    this.tierFloor,
    this.tierShift = 0,
    this.preferredScalingStat = '',
    this.alignmentLabel = 'Neutral',
    this.ownedItemIds = const [],
    this.recentLootIds = const [],
    this.signatureItemIds = const [],
  });

  final int chapter;
  final int playerLuck;
  final int bestAllyLuck;
  final bool isElite;

  /// Any defeated enemy was a `soloOnlyEnemyIds` boss/unique -- the chest
  /// is never below Gold.
  final bool hasBossOrUnique;
  final int enemyCount;

  /// Nobody was knocked out and no potion was drunk.
  final bool flawless;
  final int rounds;
  final bool finalBlowCritical;

  /// The party read at least one enemy at the full telegraph tier this
  /// fight -- Perception finds the hidden pouch: one extra slot.
  final bool fullTelegraphRead;

  /// Any defeated enemy type had never been beaten before -- the chest is
  /// never below Iron, and that enemy's signature drops weigh more.
  final bool firstKill;

  /// Consecutive Wooden chests so far (see PlayerSession.lootPityStreak).
  final int pityStreak;

  /// Affixed enemies defeated.
  final int affixCount;

  /// From `conditionFortuneBonus` in battlefield_condition.dart.
  final int conditionBonus;

  /// A hard floor on the tier (a hunt's guaranteed Gold, a hunter's Silver)
  /// applied after every other floor.
  final ChestTier? tierFloor;

  /// Tier steps applied after floors -- negative for a chest a Skittish
  /// enemy fled with part of.
  final int tierShift;

  /// The player's profession's `preferredScalingStat`, for the loot
  /// affinity reweight (see professionLootAffinityBonus in
  /// combat_engine.dart).
  final String preferredScalingStat;

  /// 'Good' / 'Neutral' / 'Evil' -- gear of the opposite alignment never
  /// drops (it couldn't be equipped), matching gear drops twice as often.
  final String alignmentLabel;

  /// Every item the party already carries or wears -- never dropped
  /// again.
  final List<String> ownedItemIds;

  /// The last few chest drops -- weighted down so the same item doesn't
  /// come up fight after fight.
  final List<String> recentLootIds;

  /// The defeated enemies' own `lootTable` item ids -- weighted up.
  final List<String> signatureItemIds;
}

class LootBoxResult {
  const LootBoxResult({
    required this.tier,
    required this.roll,
    required this.modifiers,
    required this.gold,
    required this.itemIds,
    required this.extraSlot,
    this.floorApplied,
  });

  final ChestTier tier;

  /// The final fortune roll including every modifier.
  final int roll;
  final List<FortuneModifier> modifiers;
  final int gold;
  final List<String> itemIds;
  final bool extraSlot;

  /// The floor that lifted the rolled tier, if any (Elite, boss, first
  /// kill, hunt).
  final ChestTier? floorApplied;

  /// Whether the chest was at or above the tier that should feel like an
  /// event (Gold).
  bool get isBigChest => tier.index >= ChestTier.gold.index;
}

/// The fortune-roll modifiers for [context], in display order. Pure: the
/// same context always gives the same list.
List<FortuneModifier> fortuneModifiersFor(LootContext context) {
  final mods = <FortuneModifier>[];
  final luck = context.playerLuck * luckFortuneWeight +
      context.bestAllyLuck * allyLuckFortuneWeight;
  if (luck != 0) mods.add(FortuneModifier('fortune_luck', luck));
  if (context.isElite) {
    mods.add(const FortuneModifier('fortune_elite', eliteFortuneBonus));
  }
  if (context.enemyCount > 1) {
    mods.add(FortuneModifier('fortune_pack',
        (context.enemyCount - 1) * packFortuneBonusPerExtraEnemy));
  }
  if (context.flawless) {
    mods.add(const FortuneModifier('fortune_flawless', flawlessFortuneBonus));
  }
  if (context.rounds <= swiftRoundLimit) {
    mods.add(const FortuneModifier('fortune_swift', swiftFortuneBonus));
  }
  if (context.finalBlowCritical) {
    mods.add(const FortuneModifier(
        'fortune_critical_finish', criticalFinishFortuneBonus));
  }
  if (context.affixCount > 0) {
    mods.add(FortuneModifier(
        'fortune_affixes', context.affixCount * affixFortuneBonusEach));
  }
  if (context.conditionBonus != 0) {
    mods.add(FortuneModifier('fortune_condition', context.conditionBonus));
  }
  if (context.pityStreak > 0) {
    mods.add(FortuneModifier(
        'fortune_pity', context.pityStreak * pityFortuneBonusPerStreak));
  }
  return mods;
}

/// [d100] (1-100) plus every modifier.
int fortuneRollFor(LootContext context, int d100) {
  var total = d100;
  for (final mod in fortuneModifiersFor(context)) {
    total += mod.value;
  }
  return total;
}

ChestTier tierForRoll(int roll) {
  if (roll < ironThreshold) return ChestTier.wooden;
  if (roll < silverThreshold) return ChestTier.iron;
  if (roll < goldThreshold) return ChestTier.silver;
  if (roll < voidThreshold) return ChestTier.gold;
  return ChestTier.voidTier;
}

/// The floor [context] imposes on the rolled tier, if any -- the highest
/// of: Iron for a first kill, Silver for an Elite, Gold for a boss, and
/// any explicit [LootContext.tierFloor].
ChestTier? tierFloorFor(LootContext context) {
  ChestTier? floor;
  void raise(ChestTier tier) {
    floor = floor == null ? tier : _maxTier(floor!, tier);
  }

  if (context.firstKill) raise(ChestTier.iron);
  if (context.isElite) raise(ChestTier.silver);
  if (context.hasBossOrUnique) raise(ChestTier.gold);
  if (context.tierFloor != null) raise(context.tierFloor!);
  return floor;
}

/// The final tier: the rolled tier, lifted to any floor, then shifted.
ChestTier finalTierFor(LootContext context, ChestTier rolled) {
  final floor = tierFloorFor(context);
  final floored = floor == null ? rolled : _maxTier(rolled, floor);
  return _shiftTier(floored, context.tierShift);
}

/// Slots a chest of [tier] holds (before the Perception extra slot).
int slotCountFor(ChestTier tier, Random random) => switch (tier) {
      ChestTier.wooden => 1,
      ChestTier.iron => 1 + random.nextInt(2),
      ChestTier.silver => 2,
      ChestTier.gold => 2 + random.nextInt(2),
      ChestTier.voidTier => 3,
    };

/// Gold for a chest of [tier] in [chapter].
int chestGoldFor(ChestTier tier, int chapter, Random random,
    {bool isElite = false}) {
  final base = chestBaseGold[tier] ?? 0;
  final variance = 0.7 + random.nextDouble() * 0.6;
  var gold = (base * variance * (1 + 0.25 * (chapter - 1))).round();
  if (isElite) gold = (gold * 1.5).round();
  return max(1, gold);
}

enum _SlotKind { goldPouch, consumable, gear, charm, tome }

/// Which kind of thing each slot of a [tier] chest holds, weighted per
/// tier. The Void chest's first slot is always a rare (gear or tome).
_SlotKind _rollSlotKind(ChestTier tier, int slotIndex, Random random) {
  final r = random.nextDouble();
  switch (tier) {
    case ChestTier.wooden:
      return r < 0.4 ? _SlotKind.consumable : _SlotKind.goldPouch;
    case ChestTier.iron:
      return r < 0.7 ? _SlotKind.consumable : _SlotKind.gear;
    case ChestTier.silver:
      if (r < 0.45) return _SlotKind.consumable;
      if (r < 0.85) return _SlotKind.gear;
      return _SlotKind.charm;
    case ChestTier.gold:
      if (r < 0.45) return _SlotKind.gear;
      if (r < 0.7) return _SlotKind.consumable;
      if (r < 0.92) return _SlotKind.charm;
      return _SlotKind.tome;
    case ChestTier.voidTier:
      if (slotIndex == 0) return r < 0.75 ? _SlotKind.gear : _SlotKind.tome;
      if (r < 0.4) return _SlotKind.gear;
      if (r < 0.65) return _SlotKind.consumable;
      if (r < 0.88) return _SlotKind.charm;
      return _SlotKind.tome;
  }
}

/// Rarities a [tier] chest's gear slot may draw from.
Set<String> gearRaritiesFor(ChestTier tier, {bool rareOnly = false}) {
  if (rareOnly) return const {'Rare'};
  return switch (tier) {
    ChestTier.wooden || ChestTier.iron => const {'Common'},
    ChestTier.silver => const {'Common', 'Uncommon'},
    ChestTier.gold => const {'Uncommon', 'Rare'},
    ChestTier.voidTier => const {'Uncommon', 'Rare'},
  };
}

String _rarityOf(Map<String, dynamic> item) =>
    item['rarity']?.toString().isNotEmpty == true
        ? item['rarity'].toString()
        : 'Common';

int _lootChapterOf(Map<String, dynamic> item) =>
    (item['lootChapter'] as num?)?.toInt() ?? 0;

bool _alignmentAllows(Map<String, dynamic> item, String alignmentLabel) {
  final itemAlignment = item['alignment']?.toString() ?? '';
  if (itemAlignment.isEmpty) return true;
  if (itemAlignment == 'Good' && alignmentLabel == 'Evil') return false;
  if (itemAlignment == 'Evil' && alignmentLabel == 'Good') return false;
  return true;
}

/// Weighted candidate list of gear ids a chest of [tier] may drop, with
/// every reweight applied: the defeated enemies' own signature drops
/// (x3, x6 on a first kill), the last few drops (x0.5), profession
/// affinity (x1.5), matching alignment (x2). Items already owned, of the
/// opposite alignment, outside the chapter window, or of the wrong rarity
/// never appear. Exposed for tests.
Map<String, double> gearWeightsFor(
  LootContext context,
  Map<String, dynamic> items,
  ChestTier tier, {
  bool rareOnly = false,
  Set<String> alreadyInChest = const {},
}) {
  final rarities = gearRaritiesFor(tier, rareOnly: rareOnly);
  final weights = <String, double>{};
  for (final entry in items.entries) {
    final item = entry.value as Map<String, dynamic>;
    if (item['isEquippable'] != true) continue;
    final lootChapter = _lootChapterOf(item);
    if (lootChapter <= 0) continue;
    // A rare stays eligible for the rest of the game once introduced;
    // common/uncommon gear ages out two chapters later so a chapter-5
    // chest never hands over a rusty shortsword.
    final isRare = _rarityOf(item) == 'Rare';
    if (lootChapter > context.chapter) continue;
    if (!isRare && lootChapter < context.chapter - 1) continue;
    if (!rarities.contains(_rarityOf(item))) continue;
    if (context.ownedItemIds.contains(entry.key)) continue;
    if (alreadyInChest.contains(entry.key)) continue;
    if (!_alignmentAllows(item, context.alignmentLabel)) continue;
    var weight = 10.0;
    if (context.signatureItemIds.contains(entry.key)) {
      weight *= context.firstKill ? 6 : 3;
    }
    if (context.recentLootIds.contains(entry.key)) weight *= 0.5;
    if (context.preferredScalingStat.isNotEmpty &&
        item['scalingStat']?.toString() == context.preferredScalingStat) {
      weight *= 1.5;
    }
    final itemAlignment = item['alignment']?.toString() ?? '';
    if (itemAlignment.isNotEmpty && itemAlignment == context.alignmentLabel) {
      weight *= 2;
    }
    weights[entry.key] = weight;
  }
  return weights;
}

String? _pickWeighted(Map<String, double> weights, Random random) {
  if (weights.isEmpty) return null;
  var total = 0.0;
  for (final w in weights.values) {
    total += w;
  }
  var r = random.nextDouble() * total;
  for (final entry in weights.entries) {
    r -= entry.value;
    if (r <= 0) return entry.key;
  }
  return weights.keys.last;
}

Map<String, double> _idsOfType(
    Map<String, dynamic> items, String itemType, LootContext context) {
  final weights = <String, double>{};
  for (final entry in items.entries) {
    final item = entry.value as Map<String, dynamic>;
    if (item['itemType']?.toString() != itemType) continue;
    if (!_alignmentAllows(item, context.alignmentLabel)) continue;
    weights[entry.key] = _rarityOf(item) == 'Rare' ? 1 : 4;
  }
  return weights;
}

/// Consumable weights per tier -- a Wooden chest only ever holds a minor
/// potion; a Gold chest is as likely to hold a major one.
Map<String, double> _consumableWeightsFor(
    ChestTier tier, Map<String, dynamic> items) {
  Map<String, double> only(Map<String, double> wanted) => {
        for (final e in wanted.entries)
          if (items.containsKey(e.key)) e.key: e.value,
      };
  return switch (tier) {
    ChestTier.wooden => only({'potion_minor': 1}),
    ChestTier.iron => only({'potion_minor': 7, 'antidote': 3}),
    ChestTier.silver =>
      only({'potion_minor': 5, 'antidote': 2.5, 'potion_major': 2.5}),
    ChestTier.gold ||
    ChestTier.voidTier =>
      only({'potion_major': 6, 'antidote': 2, 'potion_minor': 2}),
  };
}

/// Rolls the whole chest for a won fight. [items] is the items db.
LootBoxResult rollLootBox(
  LootContext context,
  Map<String, dynamic> items,
  Random random,
) {
  final modifiers = fortuneModifiersFor(context);
  final roll = fortuneRollFor(context, 1 + random.nextInt(100));
  final rolled = tierForRoll(roll);
  final tier = finalTierFor(context, rolled);
  final floor = tierFloorFor(context);
  final floorApplied =
      floor != null && floor.index > rolled.index ? floor : null;

  var gold =
      chestGoldFor(tier, context.chapter, random, isElite: context.isElite);
  final slotCount =
      slotCountFor(tier, random) + (context.fullTelegraphRead ? 1 : 0);
  final itemIds = <String>[];
  final chestGear = <String>{};

  for (var slot = 0; slot < slotCount; slot++) {
    var kind = _rollSlotKind(tier, slot, random);
    for (var attempt = 0; attempt < 3; attempt++) {
      switch (kind) {
        case _SlotKind.goldPouch:
          gold += chestGoldFor(ChestTier.wooden, context.chapter, random);
          attempt = 3;
          continue;
        case _SlotKind.consumable:
          final id = _pickWeighted(_consumableWeightsFor(tier, items), random);
          if (id != null) {
            itemIds.add(id);
            attempt = 3;
            continue;
          }
          kind = _SlotKind.goldPouch;
          continue;
        case _SlotKind.gear:
          final id = _pickWeighted(
            gearWeightsFor(context, items, tier,
                rareOnly: tier == ChestTier.voidTier && slot == 0,
                alreadyInChest: chestGear),
            random,
          );
          if (id != null) {
            itemIds.add(id);
            chestGear.add(id);
            attempt = 3;
            continue;
          }
          // No eligible gear left (everything owned already, or the
          // rarity band is empty this chapter) -- fall back to a tome
          // for a big chest, a consumable otherwise, never to nothing.
          kind = tier.index >= ChestTier.gold.index
              ? _SlotKind.tome
              : _SlotKind.consumable;
          continue;
        case _SlotKind.charm:
          final id = _pickWeighted(_idsOfType(items, 'Charm', context), random);
          if (id != null) {
            itemIds.add(id);
            attempt = 3;
            continue;
          }
          kind = _SlotKind.consumable;
          continue;
        case _SlotKind.tome:
          final id = _pickWeighted(_idsOfType(items, 'Tome', context), random);
          if (id != null) {
            itemIds.add(id);
            attempt = 3;
            continue;
          }
          kind = _SlotKind.consumable;
          continue;
      }
    }
  }

  return LootBoxResult(
    tier: tier,
    roll: roll,
    modifiers: modifiers,
    gold: gold,
    itemIds: itemIds,
    extraSlot: context.fullTelegraphRead,
    floorApplied: floorApplied,
  );
}

/// The pity streak to persist after a chest of [tier]: one more Wooden
/// chest extends it, anything Silver or better resets it, Iron leaves it
/// alone.
int nextPityStreak(int current, ChestTier tier) => switch (tier) {
      ChestTier.wooden => current + 1,
      ChestTier.iron => current,
      _ => 0,
    };

/// The last-[keep] drops list to persist after [dropped] joined it.
List<String> nextRecentLootIds(List<String> current, List<String> dropped,
    {int keep = 3}) {
  final merged = [...current, ...dropped];
  return merged.length <= keep ? merged : merged.sublist(merged.length - keep);
}
