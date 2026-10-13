/// The camp's harbour (v1.283.0): the story lands the Rusty Eel on the
/// Ashen Coast hauled up and storm-scarred, and hands over what refitting
/// her costs (a choice's `grantMaterials`); the camp's tour points at the
/// harbour, and until it stands she sails nowhere from the camp. The ship's
/// refit (the Harbor screen) waits on it too.
library;

import 'camp_state.dart' show harborHouseId;
import 'materials.dart';
import 'settlements.dart' show campFoundedFlag;

/// The save format that has the harbour as a thing to build. A save from
/// before it (see [legacyHarbourDue]) that has passed the camp's founding
/// gets the harbour built on load.
const int harbourSaveVersion = 5;

/// Whether the camp stands without its harbour: the story has founded it
/// ([campFoundedFlag]) and [builtHouseIds] has no harbour yet.
bool harbourAwaited({
  required Iterable<String> flags,
  required Iterable<String> builtHouseIds,
}) =>
    flags.contains(campFoundedFlag) && !builtHouseIds.contains(harborHouseId);

/// Whether a save's raw [json] predates the harbour as a work to build
/// ([harbourSaveVersion]) and has passed the camp's founding without it:
/// its harbour is built on load, so an old game is never stopped at a
/// dock it was never asked to build.
bool legacyHarbourDue(Map<String, dynamic> json) =>
    ((json['saveVersion'] as num?)?.toInt() ?? 1) < harbourSaveVersion &&
    harbourAwaited(
      flags: [...?(json['flags'] as List?)?.map((e) => e.toString())],
      builtHouseIds: [
        ...?(json['builtHouseIds'] as List?)?.map((e) => e.toString()),
      ],
    );

/// Whether a voyage from the camp waits on the harbour: it is awaited and
/// the party can build it now ([gold] and the materials in [inventory]
/// cover the harbour's record in [houses]). When it can't (the grant spent
/// on another work, or sold), the Eel sails anyway: the lock points at a
/// harbour the player can build, and never leaves them stranded.
bool voyageWaitsOnHarbour({
  required Iterable<String> flags,
  required Iterable<String> builtHouseIds,
  required int gold,
  required List<String> inventory,
  required Map<String, dynamic> houses,
}) {
  if (!harbourAwaited(flags: flags, builtHouseIds: builtHouseIds)) {
    return false;
  }
  final harbour = houses[harborHouseId];
  if (harbour is! Map<String, dynamic>) return false;
  final cost = (harbour['buildCost'] as num?)?.toInt() ?? 0;
  return gold >= cost &&
      missingMaterials(inventory, materialCountsOf(harbour, 'materialCost'))
          .isEmpty;
}
