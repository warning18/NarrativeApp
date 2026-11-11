# The Tower on v1.922: the peoples fix, by the batch

QA, on main v1.922 (Core's #993: the Tower start for humans and voidkin).
The 2,000-seed batch (seeds 1 to 2000, 10001 to 12000 as the check) against
the v1.920 batch of `tower-1.920.md`. Full report: `tower-1.922/tower-batch.md`.

## The point of the change: the race gap closed

Win floor 30, no unlocks, by race:

| race | v1.920 | v1.922 |
|---|---|---|
| elf | 24.2% | 16.5% |
| human | 7.8% | **13.7%** |
| dwarf | 16.4% | 11.7% |
| voidkin | 4.7% | **11.6%** |
| orc | 14.8% | 9.7% |
| spread (lowest to highest) | 4.7% to 24.2% | **9.7% to 16.5%** |

Median floor by race is 17 to 20 (was 14 to 20); human and voidkin are now
mid-pack, not last. The cost moved the gap to the other end: orc is now the
lowest (9.7%) and elf still the highest, a 6.8-point spread (was 19.5).

## The curve overall (all races, no unlocks unless noted)

| figure | v1.920 | v1.922 | design band |
|---|---|---|---|
| median floor | 17 | **19** | 13 to 18 |
| reach floor 20 | 41.5% | **47.2%** | 20 to 38% |
| win floor 30 | 13.6% | **12.6%** | 5 to 12% |
| win floor 30, all unlocks | 28.8% | **26.8%** | 15 to 25% |
| mean floor | 18.1 | 18.9 | |
| floor 10 boss, lost | 9.0% | **5.9%** | |
| floor 20 boss, lost | 11.9% | **13.6%** | |
| floor 30 boss, lost | 22.8% | **25.4%** | |
| worst ordinary floor, lost | 8.2% (floor 27) | **10.6%** (floor 28) | |

Seeds 10001 to 12000 agree (top 12.8% none, 26.4% all; median 18).

Two things to read from it:

- **The people fix made the middle easier.** The start of humans and voidkin
  went up (option B), so the Tower reads easier up to floor 20 (reach floor 20
  from 41.5% to 47.2%, floor 10 boss easier) while the top moved down a little
  (13.6% to 12.6%) and the late bosses and floors are harder (floor 28 loses
  10.6%, the floor 30 boss 25.4%). By the design's bands the median and floor
  20 are above their bands; Core re-set the CI bands at #960 and #920, this
  table uses the design's.
- **The shape.** The climb is flatter at the start and spikier at the end:
  the worst ordinary floor is now late (28), and the top boss is the
  hardest figure of the table. That matches Core's wish for peaks, but the
  floor 28 to 30 stretch deserves a look if the target is "no ordinary floor
  over 10%".

The real-fight driver was not rerun (it measures a floor under the player,
not the batch; see `tower-1.920.md`).
