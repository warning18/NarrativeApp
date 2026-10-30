// The party's dice between rolls (the user's lock rules, v1.662): a first
// tap selects a die (and shows its target), a second tap locks it; a locked
// die can be released again only until the next roll is triggered, after
// which the round's locks are frozen; a locked die is not rerolled. A new
// round clears it all.
//
// The rules lock and unlock dice too (a Steady face, a Luck nudge, a Hex):
// they work on [locked] directly, frozen or not. The freeze binds the
// player's release only.

/// What a tap on a die did.
enum DieTap { selected, locked, none }

class DieLocks {
  /// The members whose die is kept through the next reroll.
  final Set<String> locked = {};

  /// The locks the last roll froze: they can't be released this round.
  final Set<String> frozen = {};

  /// The member whose die was tapped since the last roll (its target
  /// shows); null after a roll.
  String? selected;

  /// A tap on [id]'s die: selects it, or locks it when it is the one
  /// selected already. A locked die stays locked (a double tap releases
  /// it, see [release]).
  DieTap tap(String id) {
    if (selected != id) {
      selected = id;
      return DieTap.selected;
    }
    if (locked.contains(id)) return DieTap.none;
    locked.add(id);
    return DieTap.locked;
  }

  /// Whether [id]'s lock can be released: locked, and not frozen by a roll.
  bool canRelease(String id) => locked.contains(id) && !frozen.contains(id);

  /// Releases [id]'s lock (a double tap); false when it can't.
  bool release(String id) {
    if (!canRelease(id)) return false;
    locked.remove(id);
    return true;
  }

  /// A roll was triggered: the locks it kept are frozen for the round, and
  /// the next tap selects afresh.
  void rolled() {
    frozen
      ..clear()
      ..addAll(locked);
    selected = null;
  }

  /// A new round: nothing selected, locked or frozen.
  void clear() {
    locked.clear();
    frozen.clear();
    selected = null;
  }
}
