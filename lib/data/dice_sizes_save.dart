// Old saves and the dice sizes (docs/proposals/dice-sizes.md §1): a save
// written before the dice took their sizes ([diceDataVersion]) is moved
// once, as it loads, then saved with the new version so it never is again.
//
// - The equipped and owned dice are kept by id, so they don't move.
// - A die that grew (d6 -> d8, d10, d12 or d20, the d7 -> d8) has its new
//   faces after the old ones: every old index stays where it was, and the
//   save needs nothing.
// - A die that shrank to a d4 ([shrunkDiceFaces]) lost its two weakest
//   plain faces. The faces it kept below index 4 stay where they were; the
//   ones past it moved into the dropped slots. A skill the player set on a
//   dropped face goes back to the skill list (it stays learned, only off
//   the die); Hammersmith work on one is refunded in full: gold, iron ore
//   and trophies, by [SmithingCost] ([smithingRefundFor]).
//
// Pure: PlayerSession.fromJson runs [resizedDiceSave] on the raw map.
import '../combat/face_smithing.dart';

/// The dice data's version a save is written with. 1 (or none): the dice
/// before their sizes; 2: the sizes of v1.569.
const int diceDataVersion = 2;

/// The save key holding [diceDataVersion].
const String diceDataVersionKey = 'diceDataVersion';

/// The dice that shrank, each old face index to its new one; an index
/// missing from the map is a face that was dropped.
const Map<String, Map<int, int>> shrunkDiceFaces = {
  'stone_die': {0: 0, 2: 2, 3: 3, 5: 1},
  'berserker_die': {0: 0, 1: 1, 2: 2, 3: 3},
  'shadow_die': {0: 0, 2: 2, 3: 3, 5: 1},
  'twinfang_die': {0: 0, 2: 2, 3: 3, 5: 1},
  'headsman_die': {0: 0, 1: 1, 2: 2, 3: 3},
};

/// The companions whose signature die shrank (companions.json
/// `signatureDiceId`), whose own face picks move with it.
const Map<String, String> shrunkCompanionDice = {'sable': 'shadow_die'};

/// Whether [json] (a raw save) was written by the game before the dice took
/// their sizes. A map without a save version (a session built in code, a
/// test's) is taken as it is.
bool diceResizeDue(Map<String, dynamic> json) =>
    json['saveVersion'] is num &&
    ((json[diceDataVersionKey] as num?)?.toInt() ?? 1) < diceDataVersion;

/// What [upgrade] cost to have done, to be paid back: every Hone (see
/// [honeCost]), the Temper, the inscription and the Recast it holds.
SmithingCost smithingRefundFor(FaceUpgrade upgrade) {
  var gold = 0, iron = 0, trophies = 0;
  for (var i = 0; i < upgrade.hones; i++) {
    final cost = honeCost(i);
    gold += cost.gold;
    iron += cost.iron;
  }
  void add(SmithingCost cost) {
    gold += cost.gold;
    iron += cost.iron;
    trophies += cost.trophies;
  }

  if (upgrade.element != null) add(temperCost);
  if (upgrade.keyword != null) add(inscribeCost);
  if (upgrade.recastType != null) add(recastCost);
  return SmithingCost(gold: gold, iron: iron, trophies: trophies);
}

/// [faces] (face index -> anything, as saved) moved to [dieId]'s new
/// indexes; the entries on dropped faces are passed to [dropped].
Map<String, Object?> _moved(
  String dieId,
  Map<dynamic, dynamic> faces, [
  void Function(Object? value)? dropped,
]) {
  final remap = shrunkDiceFaces[dieId]!;
  final out = <String, Object?>{};
  for (final entry in faces.entries) {
    final index = int.tryParse(entry.key.toString());
    final to = index == null ? null : remap[index];
    if (to != null) {
      out['$to'] = entry.value;
    } else {
      dropped?.call(entry.value);
    }
  }
  return out;
}

/// [ally] (a raw companion save) with their face picks moved, when their
/// signature die shrank ([shrunkCompanionDice]).
Object? _movedAlly(Object? ally) {
  if (ally is! Map) return ally;
  final dieId = shrunkCompanionDice[ally['companionId']?.toString()];
  final picks = ally['diceSkillAssignments'];
  if (dieId == null || picks is! Map) return ally;
  return {
    ...Map<String, dynamic>.from(ally),
    'diceSkillAssignments': _moved(dieId, picks),
  };
}

/// The die id a `diceUpgrades` key names: the die's own id, or
/// `companion:die` (see [dieUpgradesKey]).
String _dieOfUpgradesKey(String key) {
  final colon = key.indexOf(':');
  return colon < 0 ? key : key.substring(colon + 1);
}

/// [json] with its dice moved to their sizes (see the top of this file),
/// and [diceDataVersionKey] set; [json] itself when it isn't due.
Map<String, dynamic> resizedDiceSave(Map<String, dynamic> json) {
  if (!diceResizeDue(json)) return json;
  final out = Map<String, dynamic>.from(json);
  out[diceDataVersionKey] = diceDataVersion;

  // The player's picks, die by die.
  final picks = json['diceSkillAssignments'];
  if (picks is Map) {
    out['diceSkillAssignments'] = {
      for (final entry in picks.entries)
        entry.key.toString():
            shrunkDiceFaces.containsKey(entry.key.toString()) &&
                    entry.value is Map
                ? _moved(entry.key.toString(), entry.value as Map)
                : entry.value,
    };
  }

  // A companion's picks, on their one signature die.
  final allies = json['recruitedAllies'];
  if (allies is List) {
    out['recruitedAllies'] = [
      for (final ally in allies) _movedAlly(ally),
    ];
  }

  // The Hammersmith's work, moved with its face or paid back.
  final upgrades = json['diceUpgrades'];
  var refundGold = 0, refundIron = 0, refundTrophies = 0;
  if (upgrades is Map) {
    out['diceUpgrades'] = {
      for (final entry in upgrades.entries)
        entry.key.toString(): shrunkDiceFaces
                    .containsKey(_dieOfUpgradesKey(entry.key.toString())) &&
                entry.value is Map
            ? _moved(
                _dieOfUpgradesKey(entry.key.toString()), entry.value as Map,
                (work) {
                if (work is! Map) return;
                final refund = smithingRefundFor(
                    FaceUpgrade.fromJson(Map<String, dynamic>.from(work)));
                refundGold += refund.gold;
                refundIron += refund.iron;
                refundTrophies += refund.trophies;
              })
            : entry.value,
    };
  }
  if (refundGold > 0) {
    out['gold'] = ((json['gold'] as num?)?.toInt() ?? 0) + refundGold;
  }
  if (refundIron > 0 || refundTrophies > 0) {
    out['inventoryItemIds'] = [
      ...?(json['inventoryItemIds'] as List?),
      for (var i = 0; i < refundIron; i++) ironOreId,
      for (var i = 0; i < refundTrophies; i++) eliteTrophyId,
    ];
  }
  return out;
}
