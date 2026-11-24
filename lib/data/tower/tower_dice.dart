// The Tower's dice bag: a die gained (an oath's, a die card's, a start
// unlock's) goes to the bag, and the player chooses the one in play
// (TowerRun.dieChoice; the Tower review, tower-mechanics-review.md §1.5).
// Pure: the floor screen's "Your dice" panel reads towerDiceOf and moves the
// run through towerChooseDie and towerMarkDieSeen (TowerController).

import '../../combat/clan_dice.dart';
import '../factions.dart' show ClanData;
import 'tower_hero.dart';
import 'tower_run.dart';
import 'tower_session.dart' show towerPoliticsOf;

/// One die of the bag, as the panel shows it.
class TowerDieView {
  const TowerDieView({
    required this.id,
    required this.faces,
    required this.inPlay,
    required this.resonates,
    required this.isNew,
  });

  /// Its id in dice.json.
  final String id;

  /// Its faces as the Tower rolls them (TowerData.dice: the Tower's own
  /// faces of its three dice unlocks).
  final List<Map<String, dynamic>> faces;

  /// The die the hero rolls.
  final bool inPlay;

  /// The main clan's die, its Resonance lit by the run's standings: in
  /// play, its low faces roll one more (clan_dice.dart).
  final bool resonates;

  /// Owned and not yet seen (TowerRun.seenDieIds): a run saved before the
  /// bag reads as all seen.
  final bool isNew;
}

/// The dice [run]'s hero owns: the one in play first, then the others by
/// id. [clans] are the clans' records for the Resonance (clanDataProvider in
/// the app); the sworn clans' standings are the run's own
/// (towerPoliticsOf), so ClanData.empty reads the main clan's die alike.
List<TowerDieView> towerDiceOf(TowerRun run, TowerData data,
    {ClanData clans = ClanData.empty}) {
  final hero = towerHeroOf(run, data);
  final politics = towerPoliticsOf(run);
  final ids = hero.ownedDice.keys.toList()
    ..sort((a, b) => a == hero.diceId
        ? -1
        : b == hero.diceId
            ? 1
            : a.compareTo(b));
  return [
    for (final id in ids)
      TowerDieView(
        id: id,
        faces: hero.ownedDice[id]!,
        inPlay: id == hero.diceId,
        resonates: resonanceOf(data.dice[id] as Map<String, dynamic>?,
                politics: politics, data: clans) ==
            Resonance.lit,
        isNew: run.dieChoice != null && !run.seenDieIds.contains(id),
      ),
  ];
}

/// [run] with its hero rolling die [dieId] from the next fight on (and the
/// die seen); [run] as it is when the hero does not own it or the run is
/// not between fights (climbing or choosing). A run saved before the bag
/// takes it up here: the dice it owned count as seen.
TowerRun towerChooseDie(TowerRun run, TowerData data, String dieId) {
  if (run.status != TowerStatus.climbing &&
      run.status != TowerStatus.choosing) {
    return run;
  }
  final hero = towerHeroOf(run, data);
  if (!hero.ownedDice.containsKey(dieId)) return run;
  if (run.dieChoice == dieId && run.seenDieIds.contains(dieId)) return run;
  return run.copyWith(
    dieChoice: dieId,
    seenDieIds: {
      ...run.seenDieIds,
      if (run.dieChoice == null) ...hero.ownedDice.keys,
      dieId,
    },
  );
}

/// [run] with die [dieId] seen (no longer new); [run] as it is when it is
/// seen already, or the run was saved before the bag (all seen).
TowerRun towerMarkDieSeen(TowerRun run, String dieId) =>
    run.dieChoice == null || run.seenDieIds.contains(dieId)
        ? run
        : run.copyWith(seenDieIds: {...run.seenDieIds, dieId});
