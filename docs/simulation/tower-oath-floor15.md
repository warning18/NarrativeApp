# Tower: the floor-15 oath (#1153)

QA's [tower-2.6.0](../qa/tower-2.6.0.md) found a fifth of the climbs never
swore an oath (no unlocks: 20.6%; all unlocks: 28.4%), since the oath needs a
clan at standing 6 and the three start clans are rivals. The user's call on
#1153: **"floor-15 oath only"**. Floors 26 and 27 are not changed.

## The rule

- `towerPityOathFloor = 15` (`lib/data/tower/tower_tables.dart`).
- In `towerOfferFor` (`lib/data/tower/tower_rewards.dart`), on a floor won at
  or above it that is not a boon floor, a climb with no oath sworn and no clan
  at standing 6 is dealt the oath of its highest-standing clan
  (`towerPityOathClan`: ties go to the first clan of the run's pool, which is
  kept in `towerClans` order). It is dealt like a due oath: a card of its own,
  first, beside that floor's clan gifts or alone, and back on every later
  non-boon floor until one is sworn. Refusing it is "Not now" (+1 mark), as for
  a due oath. Still one oath a run.
- It does not wait for a 35% clan floor: it comes on the first eligible floor.
  Floor 15 is itself a boon floor (skill, die, spell; no oath there, as
  before), so **the first such offer comes after floor 16**.
- Nothing new on screen: the existing oath card. The only visible difference is
  that the clan's gift cards on the same table can read a standing under 6/6
  (e.g. "Standing 4/6") beside its oath; no text says why.

## Numbers

The bot, seeds 1 to 2000 each, origin/main (before) against this branch
(after), `TOWER_SEEDS=2000 flutter test test/qa_tower_sim_test.dart --plain-name
batch`. A floor's clear rate is the share of the runs reaching it that win it.
The first oath's floor is the floor of the `clanOath` card taken.

### No unlocks

| figure | before | after |
|---|---|---|
| sworn, all runs | 79.4% | 81.3% |
| sworn, runs reaching floor 20 | 98.0% (n 853) | 100.0% (n 853) |
| median floor of the first oath | 8 | 8 |
| top of the tower (floor 30 won) | 11.30% | 11.15% |
| median floor reached | 17 | 17 |
| reach floor 20 | 42.6% | 42.6% |
| marks a run (mean) | 25.9 | 25.9 |
| clear floor 15 | 92.4% (n 1264) | 92.4% (n 1264) |
| clear floor 16 | 91.2% (n 1168) | 91.2% (n 1168) |
| clear floor 17 | 92.5% (n 1068) | 92.8% (n 1068) |
| clear floor 18 | 93.6% (n 990) | 93.5% (n 993) |
| clear floor 19 | 91.8% (n 929) | 91.7% (n 930) |
| clear floor 20 | 86.6% (n 853) | 86.6% (n 853) |
| clear floor 21 | 90.7% (n 739) | 90.8% (n 739) |
| clear floor 22 | 91.2% (n 671) | 91.1% (n 672) |
| clear floor 23 | 91.1% (n 615) | 90.9% (n 615) |
| clear floor 24 | 90.0% (n 561) | 90.0% (n 560) |
| clear floor 25 | 87.7% (n 505) | 87.5% (n 504) |
| clear floor 26 | 87.6% (n 443) | 87.5% (n 441) |
| clear floor 27 | 89.7% (n 388) | 89.4% (n 386) |
| clear floor 28 | 92.0% (n 348) | 91.6% (n 345) |
| clear floor 29 | 94.1% (n 320) | 94.3% (n 316) |
| clear floor 30 | 75.1% (n 301) | 74.8% (n 298) |

### All unlocks

| figure | before | after |
|---|---|---|
| sworn, all runs | 71.7% | 80.4% |
| sworn, runs reaching floor 20 | 91.0% (n 1202) | 100.0% (n 1212) |
| median floor of the first oath | 11 | 12 |
| top of the tower (floor 30 won) | 23.75% | 24.05% |
| median floor reached | 21 | 21 |
| reach floor 20 | 60.1% | 60.6% |
| marks a run (mean) | 34.5 | 34.5 |
| clear floor 15 | 92.3% (n 1601) | 92.3% (n 1601) |
| clear floor 16 | 95.1% (n 1478) | 95.1% (n 1478) |
| clear floor 17 | 93.8% (n 1405) | 94.6% (n 1406) |
| clear floor 18 | 96.1% (n 1320) | 95.9% (n 1332) |
| clear floor 19 | 94.6% (n 1271) | 94.7% (n 1280) |
| clear floor 20 | 86.6% (n 1202) | 86.1% (n 1212) |
| clear floor 21 | 93.9% (n 1041) | 93.8% (n 1044) |
| clear floor 22 | 93.8% (n 980) | 93.5% (n 981) |
| clear floor 23 | 95.4% (n 920) | 95.3% (n 918) |
| clear floor 24 | 93.6% (n 878) | 94.3% (n 875) |
| clear floor 25 | 90.1% (n 822) | 90.3% (n 825) |
| clear floor 26 | 93.3% (n 741) | 93.4% (n 745) |
| clear floor 27 | 94.6% (n 691) | 94.4% (n 696) |
| clear floor 28 | 96.5% (n 654) | 96.7% (n 657) |
| clear floor 29 | 94.0% (n 631) | 94.6% (n 635) |
| clear floor 30 | 80.1% (n 593) | 80.0% (n 601) |

The bot swears the oath when it is on the table, so every run that wins floor
16 unsworn swears there (no unlocks: 145 runs; all unlocks: 583), and no run
reaches floor 20 unsworn. The curve barely moves: top of the tower -0.15 (none)
and +0.30 points (all), every floor 15 to 30 within a point. The live-Tower pin
(`qa_tower_live_pin_test`, 1000 seeds) moved from 49 / 207 / 9088 to
49 / 208 / 9111 (none) and 125 / 302 / 10775 to 128 / 305 / 10799 (all);
`qa_tower_sim_test`'s bands hold.

## Picture

The table after floor 16 for an unsworn run with the Mire at 4 (two of its
gifts taken), the oath card first, the floor's three gifts below:
`tower-oath-floor15/oath-floor16-en-412.png` (English, 412 px) and
`tower-oath-floor15/oath-floor16-fr-360.png` (French, 360 px), from
`test/tower_clan_offer_shots_test.dart` (the `pity` case, `UX_SHOTS=<folder>`).
