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
  // A pack's shortcut an Elite pack, no foe added, the events' foes 1.16
  // (Core's events-on review): these were 58 / 231 / 9358 and
  // 129 / 334 / 11203.
  // v1.963: the floors without a fight switched on (towerEventsLive 2, the
  // user's option 2: their foes 1.17, floors 25 and 30 .42 and .34): these
  // were 55 / 220 / 9247 and 126 / 320 / 10963.
  // v1.993: the clan gift dice's new faces (the Tower deals them too):
  // these were 66 / 240 / 9609 and 144 / 323 / 11140.
  // Wave 5 (simulator truth): the bot values a die with its keywords and
  // its fights play Growth (docs/simulation/sim-truth.md): these were
  // 65 / 240 / 9623 and 144 / 323 / 11175.
  // v2.4.0 (the Tower briefs 1 to 3, docs/simulation/
  // tower-roguelike-briefs.md): floors 11 to 29 harder (towerClimbScale),
  // a dead skill card a rank-up, three more boon floors: these were
  // 65 / 239 / 9607 and 143 / 323 / 11169.
  // Held variant (claude/core-tower-boss106): the floor-30 boss ×1.06 (was
  // ×1.0, towerClimbScale): these were 57 / 208 / 9160 and
  // 127 / 309 / 10750.
  // The clans' offers (docs/simulation/tower-clan-offers.md, Core's PR,
  // the user's calls): up to three clans' skill gifts on the oath's
  // floors, the oath at standing 6, one a run; no Tower number moved,
  // the bot takes 3 to 4 more skills a run: these were 50 / 208 / 9160 and
  // 122 / 309 / 10750.
  // The user's payback B (the Tower's foes 1.17 to 1.23,
  // towerPeacefulFoeScale): these were 70 / 235 / 9545 and
  // 161 / 333 / 11240.
  // The floor-15 oath (#1153, towerPityOathFloor): these were
  // 49 / 207 / 9088 and 125 / 302 / 10775.
  // #1147 (a skill ranked up keeps its face): these were
  // 49 / 208 / 9111 and 128 / 305 / 10799.
  const none = (top: 51, floor20: 205, floorSum: 9083);
  const all = (top: 116, floor20: 302, floorSum: 10758);

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
