// The fate coin (docs/proposals/dice-sizes.md §3, call 3): a one-use
// consumable with two faces, heads and tails, bought in town shops (30
// gold) or found among the Wayfarer's common objects. Flipped on a check
// outside fights, it rolls that check once more and is spent.
//
// Wired into three rolls, each offering the coin when the hero carries
// one: the land crossing's failed d20 check (land_crossing_screen.dart),
// the camp fate's failed check (the thief's Perception, the peace's
// Charisma; camp_fate_dialog.dart), and a forge roll that came out Flawed
// (shop_trade_sheets.dart), which the coin forges once more.
import 'dart:math';

import 'ability_check.dart';
import 'forge_roll.dart';

/// The coin's item id (items.json).
const String fateCoinId = 'fate_coin';

/// The coin's two faces.
enum FateCoinFace { heads, tails }

/// Whether [inventory] (the pack's item ids) holds a fate coin.
bool carriesFateCoin(Iterable<String> inventory) =>
    inventory.contains(fateCoinId);

/// [inventory] with one fate coin spent; null when it holds none.
List<String>? withFateCoinSpent(List<String> inventory) {
  final at = inventory.indexOf(fateCoinId);
  if (at < 0) return null;
  return [...inventory]..removeAt(at);
}

/// The coin flipped on [random]: the face it lands on, which the check's
/// second roll follows whatever it shows.
FateCoinFace flipFateCoin(Random random) =>
    random.nextBool() ? FateCoinFace.heads : FateCoinFace.tails;

/// Whether the coin may be offered on [check]: a check that failed. A
/// passed check needs no second chance.
bool fateCoinWorthFlipping(AbilityCheckResult check) => !check.success;

/// [check] rolled once more with [random]: a new d20, the same ability,
/// modifier and DC.
AbilityCheckResult rerolledCheck(AbilityCheckResult check, Random random) =>
    AbilityCheckResult(
      ability: check.ability,
      roll: random.nextInt(20) + 1,
      modifier: check.modifier,
      dc: check.dc,
    );

/// Whether the coin may be offered on a forge [roll]: a Flawed piece, the
/// forge's failed check.
bool fateCoinWorthFlippingForge(ForgeRoll roll) =>
    roll.tier == ForgeTier.flawed;

/// [roll] forged once more with [random]: a new d20, the same modifiers.
ForgeRoll reforgedRoll(ForgeRoll roll, Random random) =>
    rerolledForge(roll, random);
