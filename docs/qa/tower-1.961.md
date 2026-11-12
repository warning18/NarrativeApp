# The Tower on v1.961: the shortcut fix confirmed

QA, on main v1.961 (Core's fix: a shortcut on a pack floor makes the pack
Elite instead of adding a foe, and the events-on foe scale goes from 1.14 to
1.16; the user approved it). The same 2,000-seed bot batch as
`tower-1.944.md` (seeds 1 to 2000; 10001 to 12000 as the check), plus the
events report with the shortcuts counted per floor. Reports:
`tower-1.961/tower-batch.md`, `tower-1.961/event-tally.json`.

**Every figure Core gave reproduces.** The live-Tower pin
(`qa_tower_live_pin_test.dart`, re-set by Core to 55 / 220 / 9,247 and 126 /
320 / 10,963) and the balance guards of `qa_tower_sim_test.dart` pass together
(7 tests).

| figure | Core | QA (v1.961) | v1.944 (before) |
|---|---|---|---|
| floor 21, lost | 8.6% | **8.6%** | 10.7% |
| floor 22, lost | 8.8% | **8.8%** | 10.4% |
| worst ordinary floor, lost | | **8.8%** (floor 22; then 21 at 8.6%, 23 at 8.3%) | 10.7% (floor 21) |
| win floor 30, no unlocks | about 13.2% | **13.2%** (check seeds 13.1%) | 13.5% |
| win floor 30, all unlocks | about 24.9% | **24.9%** (24.6%) | 25.3% |
| floor 10 / 20 / 30 boss, lost | 6.3 / 13.6 / 26.2% | **6.3 / 13.6 / 26.2%** | 5.7 / 13.5 / 24.6% |
| wardens 5 / 15 / 25, lost | | 1.1 / 7.6 / 13.5% | 1.2 / 7.5 / 13.7% |
| shortcuts lost, floors 11 to 19 | about 16% | **15.9%** (50 of 315 taken) | |
| shortcuts lost, floors 21 to 29 | about 11% | **10.6%** (16 of 151) | 38.6% on v1.960 (61 of 158) |
| climbs ending on a lost shortcut, no unlocks | about 3.8% | **3.8%** (76 of 2,000) | 6.1% |
| climbs ending on a lost shortcut, all unlocks | about 4.5% | **4.5%** (91 of 2,000) | 9.3% |

Also: median floor 18 (was 19; in the design band 13 to 18), floor 20
reached by 45.2% (was 47.0%), mean floor 18.7 (was 18.9); with all unlocks
median 22, floor 20 62.5%, mean 21.9, the floor 30 boss lost 23.5% (was
21.3%).

What it says:

- **The fix does what it was for.** The two floors over 10% (21 and 22) are
  now at 8.6% and 8.8%; no ordinary floor is over 10% any more. They are
  still the hardest two ordinary floors (22 first, 21 second, then 23 at
  8.3%), but 1.5 to 2 points down.
- **A shortcut on the deep floors is no longer a coin.** Lost shortcuts on
  floors 21 to 29 fell from 38.6% to 10.6%; the share of climbs that end on
  one, from 6.1% to 3.8% (none) and from 9.3% to 4.5% (all unlocks). The
  shortcut is still riskier than a plain floor: 15.9% lost on 11 to 19.
- **The price is in the bosses and the top.** The floor 10 boss is a little
  harder (5.7% to 6.3% lost) and the floor 30 boss a point and a half harder
  (24.6% to 26.2%; all unlocks 21.3% to 23.5%); the top moves from 13.5% to
  13.2% (none) and from 25.3% to 24.9% (all). Reaching floor 20 is 1.8 points
  rarer (the foe scale 1.16). The median floor is back inside the band.
- The count is the bot's (it declines a shortcut when hurt; a player may
  not), and the setback is counted from failed tests only, as in
  `tower-1.944.md`.
