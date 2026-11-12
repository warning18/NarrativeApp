// QA pin of the LIVE Tower (Core's floor events, v1.944): the Tower players
// get is the floor events' version `towerEventsLive` (1 since v1.944: the
// setback, the rival and the shortcut, at the events-on foe scale). The
// balance guard of qa_tower_sim_test.dart holds it inside wide bands; this
// test pins it as numbers, on the same first 500 seeds, so any later drift of
// the live curve (a foe's scale, a floor's extras, the heal between floors)
// shows here even when the bands still hold.
//
// The bot plays the LIVE version (towerEventsLive), so it moves only on the
// day that constant does (2 adds the quiet floors): the test then asks for
// the new numbers, on purpose. (It was named qa_tower_events_off_pin_test.dart
// while the events were off.)
//
// The numbers are the bot's (playTowerRun) on seeds 1 to 500, once
// with no unlocks and once with all of them. When the live curve is changed
// ON PURPOSE, the new numbers go in this file in the same PR (the test prints
// them in its failure message), with the reason.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

/// (won the top, reached floor 20, sum of the floors reached) over seeds 1..500.
typedef _Pin = ({int top, int floor20, int floorSum});

_Pin _measure(TowerProgress progress) {
  final data = towerDataFromAssets();
  var top = 0, floor20 = 0, floorSum = 0;
  for (var seed = 1; seed <= 500; seed++) {
    final run = playTowerRun(
        seed: seed, data: data, progress: progress, events: towerEventsLive);
    if (run.status == TowerStatus.won) top++;
    if (run.floorReached >= 20) floor20++;
    floorSum += run.floorReached;
  }
  return (top: top, floor20: floor20, floorSum: floorSum);
}

void main() {
  // v1.944: the floor events switched on (towerEventsLive 1, the user's
  // call); events off, these were 55 / 242 / 9522 and 145 / 335 / 11294.
  const none = (top: 58, floor20: 231, floorSum: 9358);
  const all = (top: 129, floor20: 334, floorSum: 11203);

  test('the live Tower, no unlocks, is the pinned curve', () {
    final m = _measure(const TowerProgress());
    expect(m, none,
        reason: 'live Tower, no unlocks: top ${m.top}, floor 20 ${m.floor20}, '
            'floor sum ${m.floorSum} (mean ${m.floorSum / 500})');
  });

  test('the live Tower, all unlocks, is the pinned curve', () {
    final m = _measure(towerAllUnlocked);
    expect(m, all,
        reason: 'live Tower, all unlocks: top ${m.top}, floor 20 ${m.floor20}, '
            'floor sum ${m.floorSum} (mean ${m.floorSum / 500})');
  });
}
