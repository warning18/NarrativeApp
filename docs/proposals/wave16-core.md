# Wave 16 on the rules side (Core, proposal)

Design only: nothing here is in the game yet. Written on v1.499.

Wave 15 gave the camp its roll houses, the risky gifts and the temple. Wave 16 should make what is already there count for more, not add a new system. Below are four items, each 1 to 3 PRs. Two need no work from Narrative or UX at all, so they fit beside UX's list without crowding it. The user picks; the order at the end is my advice.

## 1. The simulator plays the seat crisis and keeps to its patron

**What the player gets.** Nothing on screen. The clan numbers we tune by become the ones a player actually lives.

**Why now.** `docs/simulation/sim-gaps.md` leaves two gaps open:
- **No seat crisis.** `SimGrowth.chapterReached` takes the patron's seat at once, where the app first plays `clan_crisis.dart`. So patron falls run high (QA: 9 of 50 runs).
- **Gifts from every clan.** The picking rule takes gifts from any clan, not only the patron's, so unbacked clans rise more than with a real player (QA's finding 4 in `docs/qa/clan-power-50.md`).

Clan power that moves (queued) will be tuned against these numbers. They should be right before it lands.

**The rules.**
- Seat crisis: the simulated player defends when its party can win the fight (the same estimate as `preferredSuitor` uses), pays when the gold is there, else refuses.
- Gifts: keep to the patron and its allies, plus one other clan's card when it fills an empty die face.

**Size.** S: 1 PR (`sim_growth.dart`, `sim_rolls.dart`, the sim tests, then QA's 50-run clan study re-run).

**From Narrative.** Nothing. **From UX.** Nothing.

**Risks.** No game number moves. The clan tables in `docs/simulation/` and `qa_sim_tables_test` shift; I expect fewer patron falls and the Vigil and Penitents a few points lower at the end. No save change.

## 2. Warding the road: Banish turns away a hunter

**What the player gets.** The Warding Cairn's Banish can also ward the roads: spend charges to keep a clan's hunters (or the nemesis's) off the party for a few roads.

**Why now.** Banish is the weakest of the three roll powers. It only removes one card for a few draws, and the simulator spends it on stat picks only, never on an offer (`sim_rolls.dart`), so its offer side is unmeasured. Meanwhile every run meets 3 to 4 hunters (`docs/simulation/nemesis-hunters.md`), and the nemesis is the Dominion in 183 of 200 runs. A ward gives the player an answer to the hunt they can plan for.

**The rules.**
- A new Banish target: a hunting clan (a rival at Hostile or Hunted, or the nemesis). 1 / 2 / 3 charges ward it for 3 / 6 / 9 roads at rest.
- While warded, that clan's roll in `rival_hunters.dart` (8% a road at Hunted, `rivalHunterChanceHunted`) is skipped. The alignment hunters and betrayals are not wardable.
- No standing change: you hid from them, you did not make peace.
- The simulator wards the nemesis when it has 2 charges or more.

**Size.** S to M: 1 PR for the rules and the simulator, 1 small UX PR.

**From Narrative.** Two lines, EN and FR: the ward set ("The cairn hides your trail from {clan}.") and the ward running out. **From UX.** A "Ward the road" choice on the Banish card (the camp tray, or the clan's row), and a small "warded, N roads" mark on the Journey.

**Risks.** Fewer hunter fights means a little less XP and loot; I'd check the 400-run attempt win moves by under 1 point. The nemesis quests' champions (`nemesis_quests_test`) are untouched. Save: the ward is one more `RollBan` kind (`on: road`), so old saves load with none.

## 3. Land crossings for the middle chapters, by who holds the land

**What the player gets.** More of the long roads play as side-view crossings, and what happens on them depends on the clan that holds the land: a Dominion toll, a Crow ambush, a Vigil checkpoint that lets a friend through.

**Why now.** The crossing screen, the walking party, the walk remarks and the encounter figures are all built (v1.474 to v1.480), but `land_routes.json` has only **3 routes**: two in chapter 1 (the crash) and one in chapter 3 (`camp_to_quarter`). Chapters 4 to 8 have none. And since v1.495 every town knows its ruler (`town_rulers_provider.dart`); the road between them does not.

**The rules.**
- 3 to 4 new routes in chapters 4, 5 and 7 (frost, fen, sea cliffs), on existing roads, named by a `landRouteId` on the leaving choice (as `crash_to_sleeper` is).
- Each route draws 1 event in 3 from its ruler's pool: a new `ruler` key on an event in `land_events.json`. Your standing with that clan sets the outcome band (Friend and up: let through or helped; Hostile and down: the hard version).
- Health is still the hull, scaled by chapter, as in `docs/proposals/land-expeditions.md`.

**Size.** M: 3 PRs. Core's routes and rules (1), Narrative's events (1), UX's backdrops for the new biomes (1).

**From Narrative.** About 6 ruler events (one per main clan) and 3 to 4 biome events per route, EN and FR, with their choices. The crossings' beats where a story scene is fixed on a day. **From UX.** Side-view backdrops for frost, fen and sea cliffs (the desert and ashlands ones exist), and the ruler's colour on the crossing's header (the town tints of v1.495).

**Risks.** Crossings cost health before the chapter's fights; chapter 7 already reads hard (§4), so its route stays mild. The fixed beats must not skip a scene the story needs (`story_graph_integrity`). A save in the middle of a crossing's scenes keeps the old flow, as with the crash. Once clan power moves, the ruler of a road can change mid-run, which is the point.

## 4. The chapter curve: chapters 2 and 7

**What the player gets.** Chapter 2 is gentle again, and the chapter 7 claimants stop being the wall of the run.

**Why now.** QA's L3 on v1.489 (`docs/qa/l3-1.489.0.md`, observation 2): chapter 2 fell from 90% to 84% of encounters won, chapter 7 from 64% to 56%. The claimants are still the spike the difficulty review named (`docs/simulation/difficulty-review.md`, point 4), and `clash_balance_test`'s chapter-7 gap is fragile (0.06 to 0.14 as Vane moves between 74 and 82). v1.497 and v1.499 moved the professions, so I re-measure first.

**The rules.**
- Chapter 2: lower the enemy health floor a little (`enemyHealthFloorByChapter`, 2.12 → about 1.95) if it still sits under 88%.
- Chapter 7: give the slow classes a breath before the Lantern Hall. A temple at Candlehold's gates with Mending at the chapter's price, rather than a cut to the claimants, keeps their band and lets the blessing (v1.490) do its job.

**Size.** S: 1 PR, numbers and one temple pin.

**From Narrative.** Nothing, unless the gates' temple wants its own keeper line (one line, EN and FR). **From UX.** Nothing: the temple pin and sheet exist.

**Risks.** Boss bands (Claimant Morrow was raised to 121 for the blessing), `clash_balance_test`, and the chapter table of the next L3. No save change.

## Order

1. **Simulator: seat crisis and patron gifts** (S). It goes first because it changes no game number and makes every later measure honest.
2. **The chapter curve** (S). Pure numbers; best done on clean simulator data.
3. **Warding the road** (S to M).
4. **Land crossings by ruler** (M). Last, because it is the largest and it reads best once clan power moves.

**If only two fit: the simulator (§1) and the land crossings (§3).** The simulator costs nobody but Core and is what clan power that moves will be measured by. The crossings are what the player sees the most: it fills chapters 4 to 8 with a screen that is already built and gives the ruling clans a face on the road. Warding the road (§2) is the cheap third if UX has room for one small card.

Already queued: clan power that moves (waits on the user's lever choice).
