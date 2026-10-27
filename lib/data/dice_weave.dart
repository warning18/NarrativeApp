// The built d12 (docs/proposals/dice-sizes.md §3): the tally die, twelve
// plain numbered faces the player fills as skills are learned. It comes
// two ways: as the reward of the Candle Count (chapter 5, quests.json
// `rewardDiceID`), or recut at the camp's Skillwright from two d8s the
// player owns, both spent (PlayerSessionNotifier.weaveDice).
import 'skill_craft.dart' show skillCraftOpen;

/// The built d12's id (dice.json).
const String tallyDieId = 'tally_die';

/// The size of the dice the Skillwright recuts into the tally die.
const int weaveInputFaces = 8;

/// The faces of [die] (a dice.json record).
int dieFaceCount(Map<String, dynamic>? die) =>
    (die?['faces'] as List?)?.length ??
    (die?['numberOfFaces'] as num?)?.toInt() ??
    0;

/// The dice of [owned] the Skillwright can recut: the d8s, in the order
/// owned.
List<String> weavableDice(Iterable<String> owned, Map<String, dynamic> dice) =>
    [
      for (final id in owned)
        if (id != tallyDieId &&
            dieFaceCount(dice[id] as Map<String, dynamic>?) == weaveInputFaces)
          id,
    ];

/// Whether [first] and [second] can be recut into the tally die now: the
/// Skillwright stands ([builtHouseIds]), the two are different d8s the
/// player owns, and the tally die isn't owned yet.
bool canWeaveDice(
  String first,
  String second, {
  required Iterable<String> owned,
  required Iterable<String> builtHouseIds,
  required Map<String, dynamic> dice,
}) {
  if (!skillCraftOpen(builtHouseIds) || first == second) return false;
  if (owned.contains(tallyDieId)) return false;
  final weavable = weavableDice(owned, dice);
  return weavable.contains(first) && weavable.contains(second);
}
