// The Tower's fight, apart from the story (v1.849): FightScreen reads the
// hero from playerSessionProvider, so a Tower floor's fight runs under a
// ProviderScope whose session is the Tower hero's (towerSessionOf), held
// by a detached notifier that never reads or writes the story save. What
// the fight leaves (won, the health left) goes back to the run through
// towerAfterFight.
//
//   final fight = TowerFightSession(run, data);
//   final floor = towerFloorOf(run, data);
//   final won = await Navigator.of(context).push<bool>(MaterialPageRoute(
//     builder: (_) => fight.wrap(FightScreen(
//       enemyId: floor.enemyIds.first,
//       enemy: enemies[floor.enemyIds.first],
//       additionalEnemyIds: floor.enemyIds.skip(1).toList(),
//       additionalEnemies: {...},
//       modifiers: floor.modifiersFor(run.professionId),
//     )),
//   ));
//   run = fight.after(run, won: won ?? false);

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tower/tower_hero.dart';
import '../data/tower/tower_run.dart';
import '../data/tower/tower_session.dart';
import 'player_session_provider.dart';

/// One Tower floor's fight: the hero's session for it, and what it left.
class TowerFightSession {
  TowerFightSession(this.run, this.data) : start = towerSessionOf(run, data);

  final TowerRun run;
  final TowerData data;

  /// The hero as the fight begins.
  final PlayerSession start;

  PlayerSession? _last;

  /// The hero as the fight left it (as it began, before it starts).
  PlayerSession get current => _last ?? start;

  /// The health the fight left the hero.
  int get healthLeft => current.currentHealth;

  /// The potions and antidotes the fight left the hero (v1.860: the bag
  /// carries what is left of the spoils').
  int get potionsLeft => current.potionCount;
  int get antidotesLeft => current.antidoteCount;

  /// [child] (the FightScreen) under the Tower hero's session: every read
  /// of playerSessionProvider below it is the Tower's, every write stays
  /// in it and is never saved.
  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          playerSessionProvider.overrideWith((ref) {
            final notifier = PlayerSessionNotifier.detached(start);
            notifier.addListener((session) => _last = session);
            return notifier;
          }),
        ],
        child: child,
      );

  /// [run] after this fight: [won] (what FightScreen pops) and the health
  /// it left, through towerAfterFight.
  TowerRun after(TowerRun run, {required bool won}) =>
      towerAfterFight(run, data,
          won: won,
          healthLeft: healthLeft,
          potionsLeft: potionsLeft,
          antidotesLeft: antidotesLeft);
}
