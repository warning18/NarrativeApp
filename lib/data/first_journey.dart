// The Journey's first steps in a new game (the user's call, v1.565): the
// first time the party steps out of a building onto the streets in chapter 1
// (out of the Blind Beggar to the proclamation, 250), the Journey opens on
// its map, not on the scene's page, since the party has to move; the
// Journey's tour starts there, once. Taking a way on a town's District view
// walks the party's mark to its pin before the scene opens.
//
// Pure; the Journey reads it.
import 'feature_unlocks.dart' show featureLadderFlag;
import 'geography.dart';

/// The session flag set once the Journey has opened on its map for the
/// party's first step outside.
const String journeyFirstShownFlag = 'journey_first_shown';

/// Whether the scene a way just led to (at [to], in chapter [chapter]) from
/// a scene at [from] opens on the Journey's map instead of its page: a game
/// on the feature ladder (a new game) that has not yet had it, in chapter 1,
/// stepping from a building (inside it or at its doorstep) to a place that
/// is not one (a district, the streets).
bool firstStepOutside({
  required Iterable<String> flags,
  required GeoPlace? from,
  required GeoPlace? to,
  required int chapter,
}) {
  if (chapter > 1) return false;
  if (!flags.contains(featureLadderFlag)) return false;
  if (flags.contains(journeyFirstShownFlag)) return false;
  return from != null && from.isBuilding && to != null && !to.isBuilding;
}

/// Whether the Journey's tour may start on its own: in a new game, only
/// once the map has opened for the first step outside (not on the Blind
/// Beggar's room before it); in a game off the ladder, or past chapter 1,
/// whenever the map shows (the tour itself plays once, see tutorialProvider).
bool journeyTourDue(Iterable<String> flags, {required int chapter}) =>
    chapter > 1 ||
    !flags.contains(featureLadderFlag) ||
    flags.contains(journeyFirstShownFlag);

/// How long the party's mark takes to walk [distance] (plan units, the
/// stored plan is 1000 across) to a way's pin on a town's chart: 0.6 s next
/// door, growing with the distance, 1.2 s from half the town away or more.
/// Under a unit it doesn't walk (zero).
Duration cityWalkDuration(double distance) {
  if (distance < 1) return Duration.zero;
  final share = (distance / 500).clamp(0.0, 1.0);
  return Duration(milliseconds: (600 + 600 * share).round());
}
