# Gear sets: making them reachable

The user's decision (proposal 9 of [combinations-review.md](combinations-review.md)):
spread the existing set pieces where players meet them, so that a normal run
can complete a set. Target: about 15 to 35% of typical runs. No new items, no
text, no change to the sets' bonuses or the pieces' stats.

## Batch

**GS989**: v1.989.0 (main 2b9a273d), `simulatePlaythroughs`, typical (T) and
competent (C) policies, seeds 1..100, one run per seed, the 25 race x
profession pairs x 4 goals (the B976 plan, see
`difficulty-review-1.914/story_runs_test.dart.txt`). Throwaway harness
`test/zz_sets_test.dart`, now deleted. It reads the build before every fight
(`onFight`) and the final gear.

- **Owned**: the piece was in the worn gear, the owned gear or the pack
  (loot and rewards, read through a temporary, uncommitted hook that added
  the pack to the `onFight` save) at any fight, or worn at the end.
- **Worn**: the most pieces of the set worn at once at any fight or at the end.

## Where the pieces were (before)

| Set | Piece | Slot | Obtainable at v1.989 |
|---|---|---|---|
| Harbourwatch | cutlass | Weapon | Wreck-Wrights' Chandlery (White Anchorage, ch6+) |
| | coat | Top | Chandlery; Lantern Dominion gift (known) |
| | lantern | Head | Chandlery; Lantern Dominion gift (known) |
| Hollow Court | blade | Weapon | Smugglers' Vault (ch3+, 300 g) |
| | mantle | Top | Ossuary Trade (ch5+, 320 g) |
| | seal | Head | Smugglers' Vault; drops: Inquisitor 30%, Brother Clement 30%, Teind Rider 15%, Knell Keeper 12% |

The Chandlery is reached in 23 to 34 runs of 100, by chapter 6, when the
Harbourwatch pieces are weaker than what is worn. The Ossuary in 10 to 23.

## Placements

All loot-table entries in `assets/gamedata/enemies.json`; shops, gifts and
quest rewards unchanged.

| Piece | Where | Rate | Why |
|---|---|---|---|
| harborwatch_cutlass | `dock_overseer` (Fisherman's Row boss, ch2) | 40% | the watch's steel on the docks |
| harborwatch_lantern | `smuggler_captain` (Lantern Docks boss, ch2) | 40% | the Lantern Docks |
| harborwatch_coat | `plague_hound` (Tanner's Court boss, ch2; the hound "stalking the harbour") | 30% | fought about twice a run |
| hollow_court_mantle | `hollow_court_inquisitor` (Drowned Stair boss, ch4) | 35% | the Court's own robes, beside its seal |
| hollow_court_blade | `hollow_court_zealot` (Drowned Stair, ch4) | 25% | the Court's zealots; fought in 87 of 100 runs |

## Results (GS989)

| | T before | T after | C before | C after |
|---|---|---|---|---|
| Runs owning a whole set | **0** | **18** | **0** | **26** |
| ... Harbourwatch | 0 | 13 | 0 | 7 |
| ... Hollow Court | 0 | 6 | 0 | 21 |
| Harbourwatch owned 0/1/2/3 pieces | 96/4/0/0 | 14/41/32/13 | 97/2/1/0 | 17/40/36/7 |
| Hollow Court owned 0/1/2/3 | 0/99/1/0 | 0/51/43/6 | 5/72/23/0 | 1/36/42/21 |
| Harbourwatch worn at most 0/1/2/3 | 96/4/0/0 | 71/29/0/0 | 99/1/0/0 | 60/30/10/0 |
| Hollow Court worn at most 0/1/2/3 | 0/99/1/0 | 0/99/1/0 | 5/75/20/0 | 1/66/33/0 |
| Runs wearing a whole set | 0 | 0 | 0 | 0 |
| Fight win %, whole run | 92.9 | 92.8 | 93.8 | 94.4 |
| Runs that reach an ending | 100 | 100 | 100 | 100 |

Pieces owned, per 100 runs (T / C after): cutlass 43 / 48, coat 53 / 45,
lantern 48 / 40, blade 33 / 52, mantle 22 / 32, seal 100 / 99.

The win rate does not move beyond noise (the new drops shift each run's
random stream): sets do not make runs easier.

## Why no run wears a whole set

Every run of the batch wears the **Void Banner** (the chapter 1 heirloom,
`q_retrieve_banner`) in the Top slot from chapter 1 to the end, and both sets
have a Top piece.

- The typical player wears a piece only when its flat attack plus armour
  beats the worn one's: banner 4, Harbourwatch coat 2, Hollow Court mantle 3.
- The competent player weighs sets (`simBestLoadout`): the banner is worth
  6.0 (`simLoadoutValue`), the mantle with the third piece's bonus 5.2, the
  coat with its third piece's bonus about 3.3. So it wears two pieces (the
  blade and the seal, or the cutlass and the lantern) and keeps the banner.

No placement changes this. It would take a change to the banner, to the
sets' numbers, or to how the simulator values lifesteal and crit, which are
outside this change. A player who values lifesteal may still wear the whole
Hollow Court set.
