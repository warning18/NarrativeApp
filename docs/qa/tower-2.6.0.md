# The Tower on v2.6.0: the clans court you (and foes ×1.23)

QA, on main v2.6.0 (`48bcab6e`, #1148: gifts from up to three clans on the
oath floors, standing 2/1/-1, the oath at 6, one oath a climb, "Not now" a mark,
foes 1.17 to 1.23). The same 2,000-seed bot batch as [tower-1.1009](tower-1.1009.md)
and [tower-2.4.0](tower-2.4.0.md) (seeds 1 to 2000, 10001 to 12000 as the
check; no unlocks and all unlocks). Full report `tower-2.6.0/tower-batch.md`;
events `tower-2.6.0/event-tally.json`. The live-Tower pin and `qa_tower_sim_test`
(Core's re-banded guards) pass: Core's figures reproduce.

## Against v1.1009 and v2.4.0

| figure | band | v1.1009 | v2.4.0 | v2.6.0 |
|---|---|---|---|---|
| win floor 30, none | 5 to 12% | 14.3% (14.5) | 11.9% (11.6) | **11.3%** (10.8) |
| win floor 30, all | 15 to 25% | 26.9% (26.6) | 23.6% (22.0) | **23.8%** (21.2) |
| median floor (none / all) | 13 to 18 | 19 / 22 | 17 / 21 | 17 / 21 |
| reach floor 20 (none / all) | 20 to 38% | 48.1 / 63.4% | 42.3 / 60.1% | **42.6** / 60.1% |
| reach floor 10 (none / all) | | 89.2 / 96.4% | 89.5 / 96.4% | 87.2 / 96.2% |
| mean floor (none / all) | | 19.3 / 22.1 | 18.3 / 21.5 | 18.2 / 21.5 |
| marks a run (none / all) | | 28.4 / 36.1 | 26.6 / 34.6 | 25.9 / 34.5 |
| floor 10 boss, lost (none / all) | | 5.8 / 2.5% | 5.7 / 2.4% | 6.1 / 2.5% |
| floor 20 boss, lost | | 14.0 / 14.8% | 15.5 / 16.8% | 13.4 / 13.4% |
| floor 25 warden, lost | | 13.6 / 8.6% | 14.8 / 9.6% | 12.3 / 9.9% |
| floor 30 boss, lost | | 27.5 / 19.7% | 21.4 / 19.8% | 24.9 / 19.9% |
| worst ordinary floor, lost (none) | | f17 8.8% | f21 9.7% | **f26 12.4%** (f27 10.3, f24 10.0) |

Core's changelog says 11.3% and 23.8% on its seeds: the same as mine. The top
is kept at the v2.4.0 curve, as promised (the clans' gifts had taken it to 16.0
and 31.2% before the foes went to 1.23). "Reach floor 20" stays 4 points over its
band (42.6%). Two things moved: the first ten floors are a little harder (reach
floor 10: 87.2% against 89.5%) and floor 26 is now the hardest ordinary floor,
12.4%, above the 10% every earlier report held.

## What the clans do (the bot, 2,000 climbs)

- **One oath, and a fifth of the runs go without it.** 1,588 climbs (79.4%)
  swore an oath; **412 (20.6%) never did** (median floor 10, 4.1% reach floor 20,
  0.2% win the top). The runs that swore: median 20, 52.6% reach floor 20, 14.2%
  win the top. In v2.4.0 only one climb in 2,000 never swore. Filed for Core as
  #1153. The top by clan: dominion 13.8%, mire 14.1%, penitents 14.6% (no
  unlocks); with all unlocks the vigil 35.5%, compact 32.6%, crows 32.0%.
- What the bot takes after a won floor: rank-up 48.1%, skill 43.5%, oath 8.4%
  (v2.4.0: oath 41.1%, skill 37.5%, rank-up 21.4%).
- The profession spread is 10.8 to 11.8% (no unlocks), races 9.7 to 13.2%.

## The events (the bot, 2,000 runs each)

| | no unlocks (v2.4.0 → now) | all unlocks (v2.4.0 → now) |
|---|---|---|
| floors that held a parley | 2,899 → 2,895 | 3,353 → 3,402 |
| ...fought by choice | 1,936 → 1,916 | 2,413 → 2,479 |
| runs that bought in a store | 964 → 953 | 669 → 641 |
| bargains signed | 1,628 → 1,641 | 1,976 → 1,980 |

Nothing odd; every run ends. The guard `qa_tower_clan_offers_test` replays 200
climbs card by card: standing comes from the gifts only (0 to 6), an oath is
taken only at standing 6, at most one a run, the refusals pay their marks, and
a save from before the clans' offers loads at standing 0.
