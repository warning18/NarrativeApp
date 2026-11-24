// The Tower's level-up, the main game's way (v1.857, the user's call): the
// Level Up screen (level_up_screen.dart) reads the hero from
// playerSessionProvider, so it runs under a ProviderScope whose session is
// the Tower hero's (towerSessionOf: its picks waiting, the Tower's own pick
// on the table), held by a detached notifier that never touches the story
// save. Each pick the player takes is written to the run (towerTakeStatPick)
// and the run's next pick put on the table in its place.
//
//   final levelUp = TowerLevelUpSession(run, data);
//   await Navigator.of(context).push(MaterialPageRoute(
//     builder: (_) => levelUp.wrap(const LevelUpScreen())));
//   run = levelUp.run; // save it
//
// Open it when towerPendingPicks(run) > 0 (after a floor that gains a
// level); towerPick waits until every pick is taken.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tower/tower_hero.dart';
import '../data/tower/tower_run.dart';
import '../data/tower/tower_session.dart';
import 'player_session_provider.dart';

/// One visit to the level-up: the run as its picks leave it.
class TowerLevelUpSession {
  TowerLevelUpSession(TowerRun run, this.data) : _run = run;

  final TowerData data;
  TowerRun _run;

  /// The run with every pick taken so far.
  TowerRun get run => _run;

  /// The picks still waiting.
  int get pending => towerPendingPicks(_run);

  /// [child] (the Level Up screen) under the Tower hero's session.
  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          playerSessionProvider.overrideWith((ref) {
            final start = towerSessionOf(_run, data);
            final notifier = PlayerSessionNotifier.detached(start);
            var taken = {...start.trainingTaken};
            notifier.addListener((session) {
              // A pick taken clears the table and counts its path.
              if (session.statPickOffer.isNotEmpty) return;
              final offer = towerStatPickOffer(_run, data);
              final index = offer.indexWhere((o) =>
                  (session.trainingTaken[o.pathId] ?? 0) >
                  (taken[o.pathId] ?? 0));
              if (index < 0) return;
              _run = towerTakeStatPick(_run, data, index);
              taken = {...session.trainingTaken};
              final next = towerStatPickOffer(_run, data);
              if (next.isNotEmpty) notifier.putStatPick(next);
            }, fireImmediately: false);
            return notifier;
          }),
        ],
        child: child,
      );
}
