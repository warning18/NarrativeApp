// QA pin of the LIVE Tower (Core's floor events, v1.944): the Tower players
// get is the floor events' version `towerEventsLive` (1 since v1.944: the
// setback, the rival and the shortcut, at the events-on foe scale). The
// balance guard of qa_tower_sim_test.dart holds it inside wide bands; this
// test pins it as numbers, on the same first 500 seeds, so any later drift of
// the live curve (a foe's scale, a floor's extras, the heal between floors)
// shows here even when the bands still hold.
//
// The bot plays the LIVE version (towerEventsLive, and towerRulesLive since
// Core's rules PR), so it moves only on the
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
        seed: seed,
        data: data,
        progress: progress,
        events: towerEventsLive,
        rules: towerRulesLive);
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
  // The cleric's peak scale (towerProfessionPeakScale 1.08 on the
  // wardens' and bosses' floors, was 1.28; docs/simulation/
  // tower-cleric-retune.md; the cleric is an unlock, so no unlocks is
  // unchanged): all unlocks were 116 / 302 / 10758.
  // The race trim (towerPeopleHealthPerUnlock: the dwarf .015 and the elf
  // .01 of health an unlock, was .03; docs/simulation/tower-race-trim.md;
  // health from the unlocks only, so no unlocks is unchanged): all
  // unlocks were 124 / 308 / 10862.
  // v2.10.0 (Tower coins, docs/simulation/tower-coins.md, the user's call):
  // the stall takes coins, not marks, and the bot spends them
  // (TowerBotCoins.full: the stall's boon at 15, a reroll of a boon table
  // with no skill); no perk worn. On top of v2.9.4 (race trim, Pyre) these
  // were 51 / 205 / 9083 and 106 / 294 / 10548; before the race trim,
  // 59 / 209 / 9208 and 140 / 317 / 11037.
  // Distinct cards on a table (the user's "3 times the same reward"): a
  // clan's rank-up names the next best skill on the die when the best is
  // on the table already; the bot takes the clan card of the highest
  // standing, now and then a lesser rank-up: these were 59 / 209 / 9208
  // and 128 / 309 / 10812. Always three (a short table filled: a clan's
  // other gift, else a die or a spell): 53 / 209 / 9174 and
  // 121 / 305 / 10771 before.
  // Rules 2 (Core's rules PR, docs/simulation/tower-levelup-loot.md, the
  // user's calls): the live Tower plays Tower XP and the Level Up card
  // table (a clan's gift, a skill or rank-up, a die or spell; +1 to a
  // skill's stat, at most +4 a stat and +10 a climb), the loot table in
  // place of the spoils chest, no boon floors nor clans' tables, the foes
  // ×0.85 and the calling pass (towerLootFoeScale,
  // towerLootProfessionScale). On rules 1 these were 53 / 210 / 9176 and
  // 119 / 305 / 10754.
  // Rules 3 (Core's PR, docs/simulation/tower-difficulty-survival.md, the
  // user's call: a survival climb, for new climbs only): no Tower XP at the
  // start and a level costing 5, 6, 6, 7 ..., the nudges at most +3 a stat
  // and +6 a climb, the loot's tier shift 0 / 0 / +1, 10% health back
  // after a floor, the foes' survival curve by floor (towerSurvivalScale)
  // and a new calling pass, 5.33 times the health an unlock. On rules 2
  // these were 66 / 253 / 10117 and 109 / 307 / 11127.
  // The oath its own step on rules 3 (Core's PR, the user's call: "Its own
  // Yes/No screen"; never on a Level Up table, never a level spent): with
  // every unlock 51 / 217 / 8991 before.
  // Rules 4 live (the gamble card, the stat pick, the redesigned perks; the
  // foes of floors 11 to 30 3% more): Core's #1214 numbers.
  // Rules 5 live (docs/simulation/tower-early-floors.md, the user's call:
  // on floors 1 to 3 the foes strike first, their damage times the unlock
  // health factor to the power .9, their health ×.85, 25% health back):
  // on rules 4 these were 1 / 19 / 3983 and 43 / 214 / 9013.
  const none = (top: 0, floor20: 15, floorSum: 4144);
  const all = (top: 40, floor20: 210, floorSum: 8889);

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
