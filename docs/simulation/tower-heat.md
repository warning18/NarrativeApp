# Tower: Heat, as built (rules PR, v2.9.0)

Core's rules for the Heat levels the user approved (Core's note
`docs/proposals/tower-heat.md`, brief 7 of `tower-briefs-6-7-8-spec.md`).
Five named curses that add up. This PR has the rules, the save fields, the
bot and the marks. It has no screen: UX's picker, chip and curse list
(v2.9.1) wire them, using the fields listed at the end.

## The rules

| Heat | id | Curse added (and every curse below it) | Where |
|---|---|---|---|
| 0 | (plain) | none: the climb as it was, byte for byte | |
| 1 | `embers` | foes ×1.05 on every floor | `towerHeatScaleOf` in `_floorOf` (the floor's `extra`) |
| 2 | `smoke` | +1 forced affix on the wardens and bosses (5, 10, 15, 20, 25, 30) | `towerHeatAffixesOf` in `_floorOf` (`affixes`; a boss gets one, it had none) |
| 3 | `flame` | healing after a floor won 15% → **5%** of max health; Elite chance +.05 on the ordinary floors 11 to 29 | `towerRecoveryShareOf` in `towerAfterFight`; `towerEliteChanceOf` in `_floorOf` |
| 4 | `pyre` | foes ×**1.04** on floors 11 to 30, on top of the factor below (the user's power lever, after option (a)); floors 13 and 23 give **nothing**: no boon, no clans' offer, no oath (boon floors 8 → 6; the user's option (a), after v2.9.0); the late oath from floor 18, not 15 | `towerHeatScaleOf` (`towerHeatPyreFoeScale`); `towerHeatEmptyFloorsOf`, `towerBoonFloorsOf`, `towerPityOathFloorOf` in `towerOfferFor` |
| 5 | `ash` | foes ×**1.12** on floors 11 to 30 (in place of ×1.05 there; Pyre's ×1.04 still on top, ×1.165 in all); a gift takes 2 standing from each rival clan, not 1 | `towerHeatScaleOf`; `towerRivalStandingOf` in `towerClanRipple` |

- **Floors 1 to 10 stay gentle**: Embers' ×1.05 only (Pyre's and Ash's factors start on floor 11), plus Smoke's affix on
  warden 5 and boss 10.
- **Same seed, same tower.** No new random stream. Heat changes thresholds
  on the draws already made, so the foes are the same at every Heat. An
  Elite at Heat 2 is still an Elite at Heat 3. Smoke's affix is drawn after
  the floor's own.
- **Fixed for the climb**: `TowerRun.heat`, set by `towerStart(heat:)`,
  kept by every `copyWith`, saved as `heat` (written only when not 0; a run
  saved before reads 0).
- **Unlock**: `TowerProgress.heatWon` is the highest Heat whose top was won
  (-1 none). `afterRun` raises it on a won run above it. Heat n + 1 opens
  after a win at Heat n (`heatOpen = min(5, heatWon + 1)`). Saved as
  `heatWon` (written only when 0 or more). **A save from before Heat that
  has a win opens Heat 1 at once**: those wins were all at Heat 0, as the
  note says.
- **Marks**: `marksEarned` is raised +25% a level, rounded down
  (`towerMarksOf(..., heat:)`, `towerHeatMarksOf`). The stores' spend comes
  off after. A won run pays 61, 76, 91, 106, 122 or 137 marks before
  refusals.
- **The bot** plays at a given Heat: `playTowerRun(heat:)`,
  `playTowerBatch(heat:)`. QA's batch takes `TOWER_HEAT` (one line in
  `test/qa_tower_sim_test.dart`; the guards still play 0).
- **Daily**: none exists yet. A future daily calls `towerStart` with heat 0.

### Tuned from the note (the two allowed levers)

- **Flame's healing .08 → .05.** At .08, Heat 3 cost 2.8 points (15.4% →
  12.6%), under the 3-point band. At .05 it costs 3.6 (11.8%).
- **Ash's factor 1.10 → 1.12.** At 1.10 (with healing at .08), Heat 5 was
  8.4%, over the 3 to 7% band. At 1.12 it is 6.8%. At 1.14 it was 6.2%,
  with floor 26 killing 13.6% and floor 30 41%, so it buys little and spikes
  two floors. 1.12 kept.

### Off target, left as the note set it (not mine to tune)

- **Embers costs 7.8 points** (25.9% → 18.1%), over the 6-point band. Brief
  7 measured 6.6 on v2.4.0. The ×1.05 is fixed by the note.
- **Smoke costs 2.7**, just under 3 (within noise: about ±0.7 points on
  2,000 seeds, less between two Heats on the same seeds).
- **Pyre costs 0.7** in v2.9.0 (11.8% → 11.1%; 0.0 with no unlocks), far
  under the band. Why: on a floor that is no longer a boon's, the clans'
  offer was dealt instead (35% of floors, three skill gifts that are about
  as good as the boon), and the bot takes the first oath long before floor
  15. The user chose option (a): **Pyre's two floors give nothing at all**
  (`towerHeatEmptyFloorsOf`: no boon, no clans' offer, no oath; built in
  `claude/core-races-trim`). Measured below, see "Pyre (a)".

### Pyre (a): measured, still short of the band

With (a), the bot takes no card on floors 13 and 23 at Heat 4 (it took one
on 95% of its wins of those floors at Heat 3). The step it costs, all
unlocks, seeds 1 to 2000:

| | Heat 3 | Heat 4 | Pyre's step |
|---|---|---|---|
| v2.9.0 (clans' offer in the boon's place) | 11.8% | 11.1% | 0.7 |
| (a), before the race trim | 11.75% | 10.90% | 0.85 |
| (a), with the race trim (`tower-race-trim.md`) | 10.8% | 10.2% | 0.6 |

**(a) does not reach the 3 to 6 point target.** The two floors' cards are
worth under a point of top to the bot: floor 13 is cleared by 71% of runs,
floor 23 by 27%, and one card among the 15 to 20 a run takes moves little.
The other reward levers, measured at Heat 4 on top of (a) and the race
trim (informational, not built):

| Heat 4 variant | Top | Step from Heat 3 (10.8%) |
|---|---|---|
| (a) alone (built) | 10.2% | 0.6 |
| (a) and floor 28 empty too (option b) | 10.0% | 0.8 |
| (a) and the late oath from 22 (option c) | 9.8% | 1.0 |
| floors 13, 18, 23 and 28 empty | 9.8% | 1.0 |
| all eight boon floors empty | 6.0% | 4.8 (floor 26 loses 14.1%) |

Only emptying the early boons (5, 10, 15, 20) moves the top, and that
lands Heat 4 on Ash's level. A 3 to 6 point Pyre needs a power lever.

### Pyre's foe factor (the user's power lever, kept with (a))

The user chose to add stronger foes on floors 11 to 30 at Heat 4 and up,
cumulative like the other curses: Embers' ×1.05 (Ash's ×1.12 at Heat 5)
times Pyre's factor. Target: Pyre 3 to 6 points under Flame with every
unlock, Ash still 3 to 7%, no ordinary floor over about 13% at Heat 4.
Measured with (a) and the race trim, seeds 1 to 2000 (Heat 3: 10.8%
every unlock, 3.35% none):

| Pyre's factor | Heat 4 top (all) | Step | Worst ordinary floor H4 | Heat 5 top (all) | Heat 4 / 5 top (none) |
|---|---|---|---|---|---|
| 1.00 ((a) alone) | 10.2% | 0.6 | f28 9.2% | 6.6% | 3.2 / 1.5% |
| 1.03 | 8.25% | 2.55 | f19 10.0% | 4.85% | 2.2 / 0.9% |
| **1.04 (built)** | **7.35%** | **3.45** | f28 10.9% | **4.6%** | 2.05 / 0.8% |
| 1.05 | 7.15% | 3.65 | f26 11.5% | not run | 1.6% / not run |

1.04 is the smallest factor in the band. Seeds 10001 to 12000 confirm it:
Heat 3 10.15%, Heat 4 5.95% (step 4.2, worst ordinary floor f21 11.5%),
Heat 5 3.8% (worst f27 14.4%); none 4.25 / 2.05 / 1.25%. Ash's ×1.12 is
kept: Heat 5 stays in its band on both seed sets (4.6 and 3.8%), though
near the bottom on the second.

## The numbers (the bot, seeds 1 to 2000, floor events v2, perks none)

All unlocks, with Pyre (a), Pyre's ×1.04 and the race trim
(`tower-race-trim.md`: the dwarf's and the elf's health from the unlocks
cut, so every Heat's top with the unlocks is about 1 to 2 points lower than
in v2.9.0; Heat 0 to 3 are untouched by Pyre):

| Heat | Top | Cost | Reach f20 | Clear f10 | Floor 30 lost (of those reaching it) | Worst ordinary floor | Marks a run | Marks a won run |
|---|---|---|---|---|---|---|---|---|
| 0 | **23.8%** | | 58.8% | 93.2% | 17.2% | f26 7.3% | 34.4 | 59.5 |
| 1 Embers | **16.5%** | 7.3 | 53.1% | 91.4% | 25.7% | f21 9.6% | 39.2 | 74.2 |
| 2 Smoke | **14.1%** | 2.4 | 50.2% | 86.2% | 29.8% | f21 8.8% | 45.0 | 89.2 |
| 3 Flame | **10.8%** | 3.3 | 44.6% | 85.5% | 30.5% | f19 9.9% | 48.2 | 102.1 |
| 4 Pyre | **7.35%** | 3.45 | 40.1% | 85.5% | 36.6% | f28 10.9% | 52.7 | 118.0 |
| 5 Ash | **4.6%** | 2.75 | 34.0% | 85.4% | 38.7% | f26 13.4% | 55.2 | 133.7 |

At Heat 3 by calling: cleric 11.0, mage 10.8, ranger 10.7, rogue 9.8,
warrior 11.8%; at Heat 4: cleric 6.8, mage 8.2, ranger 7.8, rogue 5.7,
warrior 8.3%; at Heat 5: cleric 6.0, mage 5.2, ranger 5.6, rogue 2.5,
warrior 3.8%. Before Pyre's factor ((a) alone) Heat 4 was 10.2% and
Heat 5 6.6% (rogue 4.4%).

As built in v2.9.0 (before Pyre (a) and the race trim):

| Heat | Top | Cost | Reach f20 | Clear f10 | Floor 30 lost (of those reaching it) | Worst ordinary floor | Marks a run | Marks a won run |
|---|---|---|---|---|---|---|---|---|
| 0 | **25.9%** | | 61.8% | 94.1% | 17.1% | f26 7.2% | 35.4 | 59.5 |
| 1 Embers | **18.1%** | 7.8 | 55.8% | 92.6% | 24.4% | f21 8.9% | 40.4 | 74.2 |
| 2 Smoke | **15.4%** | 2.7 | 51.6% | 87.2% | 27.9% | f21 9.1% | 46.0 | 89.1 |
| 3 Flame | **11.8%** | 3.6 | 47.3% | 87.0% | 29.9% | f24 8.9% | 49.5 | 102.1 |
| 4 Pyre | **11.1%** | 0.7 | 45.8% | 87.0% | 31.2% | f28 9.1% | 56.6 | 117.9 |
| 5 Ash | **6.8%** | 4.3 | 40.0% | 86.9% | 40.6% | f26 12.4% | 59.2 | 132.5 |

Target (the note): 24 / 19 / 15 / 11 / 8 / 5%. In v2.9.0 every calling won at least
5% at Heat 3 (cleric 12.0, mage 11.2, ranger 12.1, rogue 10.8, warrior
12.6). At Heat 5 the rogue falls to 4.2% (cleric 7.0, mage 6.0, ranger 9.2,
warrior 7.5). No ordinary floor loses over 13% at Heat 3 or below. The
worst peak is always floor 30's boss. Smoke's affix on warden 5 and boss 10
is what takes "clear floor 10" from 93% to 87% (the note's guess was 92%).

No unlocks (Heat is aimed at players who own them; for reference; Heat 4
and 5 with Pyre (a) and Pyre's ×1.04, the race trim does not touch them):

| Heat | Top | Reach f20 | Clear f10 | Floor 30 lost | Worst ordinary floor | Marks a run |
|---|---|---|---|---|---|---|
| 0 | 11.1% | 42.2% | 82.1% | 26.7% | f26 11.9% | 25.9 |
| 1 | 6.9% | 34.6% | 77.6% | 31.7% | f26 12.1% | 29.1 |
| 2 | 5.5% | 33.3% | 72.7% | 38.3% | f27 14.2% | 34.0 |
| 3 | 3.4% | 26.2% | 68.7% | 42.2% | f29 16.5% | 35.4 |
| 4 | 2.05% | 21.9% | 68.7% | 47.4% | f26 18.2% | 39.1 |
| 5 | 0.8% | 16.6% | 68.7% | 56.8% | f27 27.8% | 41.4 |

Heat 0 is unchanged: the same floors and the same bot runs as before
(`test/tower_heat_test.dart`), and `qa_tower_live_pin_test.dart` passes
untouched.

### Bot against real play

QA's real-fight sample (#1165, `docs/qa/tower-real-fight-2.8.1.md`) found
the bot about 19 points optimistic per fight for warriors and rogues on the
floors it died on. Mages matched within 3 points once the driver cast
spells. So **read the targets lower for real play by non-casters**: a
warrior or rogue player should expect less than the bot's top at every
Heat. Bot fights are the yardstick the Tower's whole curve was set on, so
the steps between Heats (each level's cost) are still the useful
measurement, and the curses compound. Heat 5's rogue (4.2% for the bot) is
the case most likely to feel like a wall (2.5% with Pyre's factor).

## Fields for UX

Everything a picker, a chip, a curse list and the end screen need. All in
`lib/data/tower/` (`tower_tables.dart`, `tower_progress.dart`,
`tower_run.dart`) and `lib/screens/tower/tower_providers.dart`.

**Starting a run at a Heat.** `ref.read(towerProvider.notifier).start(data:,
raceId:, professionId:, heat: h)`. `heat` defaults to 0, so today's start
screen starts the plain climb. If the Heat passed is not open, it starts at
the highest open one. The picker's default is `progress.heatOpen`.

**Reading open levels and the highest won** (from
`ref.watch(towerProvider).value!.progress`, a `TowerProgress`):
- `heatWon`: `int`, -1 none, else 0..5 (the highest Heat whose top was won).
- `heatOpen`: `int` 0..5, the highest a new run may take (the default pick).
  Hide the picker while it is 0.
- `heatsOpen`: `List<int>`, 0..`heatOpen`.
- `isHeatOpen(h)`: `bool`.
- A locked step h (h > `heatOpen`) opens with a win at h - 1:
  `tower_heat_locked` with `{heat}` = the name of Heat h - 1.

**The levels** (`tower_tables.dart`):
- `towerHeatLevels`: `List<TowerHeatLevel>` for 1..5, each with `heat`
  (int), `id` (`'embers'`, `'smoke'`, `'flame'`, `'pyre'`, `'ash'`),
  `nameKey` (`tower_heat_<id>`) and `lineKey` (`tower_heat_<id>_line`).
- `towerHeatLevelOf(h)`: the level, or null for 0.
- `towerHeatPlainKey` / `towerHeatPlainLineKey`: `tower_heat_plain`,
  `tower_heat_plain_line` (step 0).
- `towerHeatMax` = 5.
- `towerHeatCursesOf(h)`: the curse list's rows, lowest first. The last one
  is the curse Heat h added (`tower_heat_curse_new`).
- `towerHeatMarksFactor(h)`: `double` 1.0, 1.25 … 2.25, for `{n}` of
  `tower_heat_marks` and `tower_heat_end`. Show it as `1.25`, with no
  trailing zero for 1.5 and 2.0.

**The run** (`TowerRun`):
- `run.heat`: `int` 0..5 (the chip; none at 0).
- `run.marksEarned` / `run.marks` already carry the multiplier. Don't
  multiply again.
- Each `TowerFloor` (`towerFloorOf(run, data)`) has `heat` and already
  holds its curses (`extra`, `affixes`, `elite`).

**End screen**: a level opened when `run.status == TowerStatus.won`,
`run.heat > before.heatWon` (`before` is the progress read before `end()`;
the progress `end()` returns has `heatWon == run.heat`) and `run.heat <
towerHeatMax`. The level opened is `run.heat + 1`: show `tower_heat_opened`
with `{heat}` = its name. Use `tower_heat_ash_done` on a win at Heat 5.

**Strings** (in `app_strings.dart` after `tower_dice_new`, EN and FR,
Narrative's wording): `tower_heat_plain`, `tower_heat_plain_line`,
`tower_heat_{embers,smoke,flame,pyre,ash}` and `…_line`,
`tower_heat_locked` (`{heat}`), `tower_heat_marks` (`{n}`),
`tower_heat_curses_title`, `tower_heat_curse_new`, `tower_heat_end`
(`{heat}`, `{n}`), `tower_heat_opened` (`{heat}`), `tower_heat_record`,
`tower_heat_ash_done`. Narrative's `tower_heat_chip_label` (`{heat}` alone)
is not added: put the name in directly. The keys follow the level ids, not
Narrative's draft numbers (`tower_heat_1` → `tower_heat_embers`, `tower_heat_0` →
`tower_heat_plain`).

**One screen line to fix when Ash is reachable**:
`tower_offer_view.dart`'s `towerRippleLine` calls
`towerClanRipple(clanId, data.clans)`. At Heat 5 it must pass
`heat: run.heat`, or the gift card reads "Vigil -1" where the rule takes 2.
`towerStandingOf(run, data)` already reads the heat, so the toast is right.
