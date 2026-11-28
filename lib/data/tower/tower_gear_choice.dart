// The Tower's gear choice (rules 2 and up): the player decides whether the
// loot card's piece of gear is worn.
//
// Off ([towerGearChoiceLive] false), a loot card's gear is worn when it
// scores at least the piece in its slot (towerGearScore), as before. On,
// a loot card that gives gear (a gear card, a gamble's Gilded, a Twin whose
// first card is gear) leaves the run waiting on TowerRun.pendingGear: the
// floor's next table is not dealt and towerPick does nothing until
// [towerEquip] (worn, even when worse; the piece it replaces is off) or
// [towerDiscard] (never worn). The choice is saved by floor in
// TowerRun.gearKept, so towerHeroOf replays it; a floor without one wears
// its gear by the automatic rule, so every run saved before replays as it
// was. Old friend's start gear, rules 1's spoils and a Twin's second card
// stay automatic.
//
// The bot (towerBotGear) equips exactly when the automatic rule would wear
// the piece, so a batch played with the choice on matches one played off.

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'tower_hero.dart';
import 'tower_levelup_loot.dart' show towerAfterTable;
import 'tower_run.dart';
import 'tower_tables.dart' show TowerTableKind;

/// The gear choice in the app: on since the replace step's screen (v2.10.46).
const bool towerGearChoiceLive = true;

/// Tests and the simulator only: the gear choice on (true) or off (false)
/// whatever [towerGearChoiceLive] says; null, as it says.
@visibleForTesting
bool? towerGearChoiceOverride;

/// Whether a loot card's gear waits for the player's choice.
bool get towerGearChoiceOn => towerGearChoiceOverride ?? towerGearChoiceLive;

/// [run] with its waiting piece of gear (TowerRun.pendingGear) worn in its
/// slot, whatever its score (the piece it replaces is off and lost), then
/// on as towerPick goes on after a loot card: the floor's Level Up tables,
/// its oath, or the next floor. [run] as it is when nothing waits.
TowerRun towerEquip(TowerRun run, TowerData data) => _chosen(run, data, true);

/// [run] with its waiting piece of gear dropped (never worn), then on as
/// [towerEquip]. [run] as it is when nothing waits.
TowerRun towerDiscard(TowerRun run, TowerData data) =>
    _chosen(run, data, false);

TowerRun _chosen(TowerRun run, TowerData data, bool equip) {
  final pending = run.pendingGear;
  if (pending == null || run.status != TowerStatus.choosing) return run;
  final next = run.copyWith(
    clearPendingGear: true,
    gearKept: {...run.gearKept, pending.floor: equip},
  );
  return towerAfterTable(
      run, next, data, towerHeroOf(next, data), TowerTableKind.levelUp);
}

/// One stat of the gear comparison ([TowerGearCompare.rows]): its key in
/// items.json, the worn piece's value (0 with none worn) and the new one's.
/// [higherIsBetter] false for a requirement (req*).
class TowerGearStat {
  const TowerGearStat(this.key, this.worn, this.offered,
      {this.higherIsBetter = true});

  final String key;
  final num worn;
  final num offered;
  final bool higherIsBetter;
}

/// The new piece of gear against the one worn in its slot
/// ([towerGearCompareOf]).
class TowerGearCompare {
  const TowerGearCompare({
    required this.itemId,
    required this.slot,
    required this.wornId,
    required this.better,
    required this.rows,
    required this.scalingStat,
    required this.wornScalingStat,
  });

  /// The new piece.
  final String itemId;

  /// Its equip slot.
  final String slot;

  /// The piece worn in [slot] now; null when none is.
  final String? wornId;

  /// The new piece scores at least the worn one (towerGearScore), or none is
  /// worn: what the automatic rule would wear, and the bot equips.
  final bool better;

  /// attackDamage, damage and armor always; each element's DmgBonus and
  /// Resist, and each req* stat, when either piece has it.
  final List<TowerGearStat> rows;

  /// The stat each piece scales with (items.json's scalingStat); '' none.
  final String scalingStat;
  final String wornScalingStat;
}

/// [itemId] against the piece [run]'s hero wears in its slot. While gear
/// waits (TowerRun.pendingGear), the hero is as it stood before the floor's
/// loot, so the comparison is the one the choice is made on.
TowerGearCompare towerGearCompareOf(
    TowerRun run, TowerData data, String itemId) {
  final hero = towerHeroOf(run, data);
  final item = (data.items[itemId] as Map?) ?? const {};
  final slot = item['equipSlot']?.toString() ?? '';
  final wornId = slot.isEmpty ? null : hero.equippedBySlot[slot];
  final worn = wornId == null ? const {} : (data.items[wornId] as Map?) ?? {};
  num n(Map m, String key) => (m[key] as num?) ?? 0;
  final keys = <String>{
    for (final m in [worn, item])
      for (final MapEntry(:key, :value) in m.entries)
        if (key is String &&
            (key.endsWith('DmgBonus') || key.endsWith('Resist')) &&
            value is num &&
            value != 0)
          key,
  }.toList()
    ..sort();
  final reqs = <String>{
    for (final m in [worn, item])
      for (final MapEntry(:key, :value) in m.entries)
        if (key is String &&
            key.startsWith('req') &&
            value is num &&
            value != 0)
          key,
  }.toList()
    ..sort();
  return TowerGearCompare(
    itemId: itemId,
    slot: slot,
    wornId: wornId,
    better: wornId == null ||
        towerGearScore(itemId, data) >= towerGearScore(wornId, data),
    rows: [
      for (final key in ['attackDamage', 'damage', 'armor', ...keys])
        TowerGearStat(key, n(worn, key), n(item, key)),
      for (final key in reqs)
        TowerGearStat(key, n(worn, key), n(item, key), higherIsBetter: false),
    ],
    scalingStat: item['scalingStat']?.toString() ?? '',
    wornScalingStat: worn['scalingStat']?.toString() ?? '',
  );
}

/// The bot's gear choice: the waiting piece equipped exactly when the
/// automatic rule would wear it ([TowerGearCompare.better]), else
/// discarded. [run] as it is when nothing waits.
TowerRun towerBotGear(TowerRun run, TowerData data) {
  final pending = run.pendingGear;
  if (pending == null) return run;
  return towerGearCompareOf(run, data, pending.itemId).better
      ? towerEquip(run, data)
      : towerDiscard(run, data);
}
