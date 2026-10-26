# Wave 18 on the rules side: locked districts and clan-held districts (Core, proposal)

Design only: nothing here is in the game yet. Written on v1.548. No simulator run behind it; the numbers are starting points to measure.

The user asked for two things: (3) districts that stay locked until a side quest opens them, and (4) districts held by clans, where quests build a clan's influence, wins flip a district and then the town, and rivals attack. Both extend what exists. Neither needs a new system.

## What already exists

- **Districts are places with holders.** `geography.json` has 17 towns with districts (`level: district`, `parent`). A district can carry its own `controller`. `holderOf` (`lib/data/clan_power.dart`) reads it, else the town's.
- **Live holders.** `PoliticsState.control` (`lib/data/factions.dart`) records places that changed hands. `givePlace` already does everything a flip needs: the news, the clan log, a relation step down between old and new holder, and the fall of a clan left with nothing.
- **Clans already reach for districts.** Most `claims` in `factions.json` are districts (the Crows: Lantern Alleys, the High Quay; the Compact: the Ash Market, the Yard). `territoryTurn` plays claims and wars at each chapter's turn, with `warSpoils` (+5), `warLoss` (−8), `seatLead` (25), and the regroup of a fallen clan (`fallenRegroup` 5 a chapter, up to 20).
- **A town's ruler from its districts.** `lib/data/town_rulers.dart`: a town with no holder of its own takes the clan that holds most of its districts (a tie is neutral). The maps already tint by it.
- **Defending a place.** `lib/data/clan_crisis.dart`: a seat about to fall waits as a crisis, and a scene lets you defend it (a fight with the attacker's hunter), pay, or refuse. The simulator plays it (`docs/simulation/sim-gaps.md`).
- **Politics events** (`politics_events.json`, `lib/data/politics_events.dart`) already have `control` and `power` effects (`wrack_vote_result`, `conclave_counts` give districts), and `powerAtLeast` and `relationAtMost` conditions.
- **Quests move clans.** A turn-in whose `politics` raise a main clan's standing by 5 or more gives it `questPower` (+5) (`applyStoryPolitics`). The simulator applies the same politics.
- **Found districts.** `foundDistricts` and `walkToDistrict` (`lib/data/city_districts.dart`, `foundDistrictsProvider` in `lib/providers/city_provider.dart`): found through a scene played or a `district_found:<id>` flag; the rest are fogged. `wayDistricts` knows which district each story way leads into.
- **Gating by flags.** `lib/data/zone_gating.dart` (`requiredFlags`, `unlockedByFlags`) already gates zones and houses. Quests set `<quest>_accepted` flags, and `PlayerSession.completedQuestIds` records quests done. `unlockQuestId` on a story choice starts a quest; the scene it stands in gives each quest its district.

**Two gaps.** Only 2 of the 15 side quests of chapters 2 and 3 have a turn-in that moves a clan's standing (`q_ch2_unpaid_scaffold`, `q_ch3_glass_from_the_terraces`), so influence can't be read from standing alone. And in the four big towns, 14 of 21 districts have no holder.

## 3. Locked districts

**Data.** On a district in `geography.json`:
- `"lock": {"quest": "q_ch2_informants_tip", "opensOn": "done"}`. `opensOn` is `accepted` (the `_accepted` flag) or `done` (`completedQuestIds`).
- optional `"unlockedByFlags"`, read by the zone helpers, for a story beat that opens it another way.
- `lockedText` / `lockedText_fr` (Narrative): the hint on the plan ("The alley men don't know you yet").

**Rules** (`city_districts.dart`):
- `districtLocked(geo, id, flags, completedQuestIds)`.
- A locked district is never found: walking in is refused, and `foundDistricts` leaves it out even if a flag says found.
- The story ways into it (`wayDistricts`) show as locked, not hidden, so the player sees what the quest will open.
- `story_graph_integrity` checks that the quest exists, is unlocked outside the district, and that no spine scene or Main quest unlock stands inside it.
- The simulator walks the same rule (its quest log already knows accepted and done).

**Smallest version.** One district: **Saltmouth's Lantern Alleys**, opened when *The Informant's Tip* is done. Its three ways from the wharf hub (the Bazaar, the Apothecary, Vess) are its only entries, and no Main quest stands there. (Card Row would be circular: Sable's own quest plays inside it, so there `opensOn: accepted` is the only sensible rule.)

**How long a lock lasts.** Until its quest reaches its stage. No timeout. If the quest can no longer be taken (its chapter is over), the district stays locked: the cost of skipping it.

**Size.** S: 1 Core PR. Narrative: the lock texts and the choice of districts. UX: a lock on the plan and the greyed way.

## 4. Clan-held districts in the big towns

The big towns: **Saltmouth** (6 districts, 10 side quests in chapter 2), **Ashen Quarter** (5, 3 side quests), **Black Reliquary** (5), **Alster** (5, chapter 1 only).

**Data.**
- `geography.json`: a `controller` on every district of the four towns (Narrative checks the fit). A draft for Saltmouth: the Wharf and Card Row Crows (as now), Tern Row Tide-Kin (as now), the Yard Compact, the Landward Gate Dominion, the Lantern Alleys Mire. For the Ashen Quarter: the Gate Vigil, the Ash Market Crows, Cinder Row Compact, the Wall of Names Penitents (their seat, held by no one today), the Spire Stair Dominion. No clan starts at the town threshold.
- `quests.json` (Core adds the fields, Narrative picks the clan): `"district"` (defaults to the district of the scene that unlocks it) and `"influence": {"crows": 15}` on the quest or on each turn-in choice.
- `PoliticsState.influence`: district → clan → 0..100. Like `power`, an entry is stored only once it moves; the holder reads its start value otherwise. Old saves load with nothing moved.
- `PoliticsState.sieges`: district → the day the attack ends.
- Politics events and story choices gain an `influence` effect (`{"saltmouth_yard": {"compact": 10}}`) beside `control`.

**Rules.**
- **Influence.** A quest done in a district adds its `influence` there. A story choice or event may too. A quest that raises a main clan's standing by 5 or more and names no influence gives that clan the default (reusing the `questPower` hook in `applyStoryPolitics`).
- **District flip.** At once, at the turn-in: when a clan's influence in a district is at least the holder's plus the flip margin, the district goes to it through `givePlace` (cause `influence`). The news, the log and the relation step come for free.
- **Town flip.** A clan holding the town threshold of its districts takes the town itself (`givePlace` on the town, cause `town`). Below it, `town_rulers.dart`'s "most districts" rule stays. A clan that drops below the threshold loses the town back to no holder.
- **Seats don't flip by influence.** The Crows' Wharf and the Penitents' Wall of Names fall only to war or the crisis, as today.
- **Attacks.** Once a chapter per big town, a main clan with a foothold there (a district held or claimed) may attack a district of a rival holder, with odds by relation step. In the town the party stands in, it plays as the crisis scene (defend: a fight with the attacker's hunter). Elsewhere it resolves on the numbers and comes as news. While an attack is on, the district is besieged: locked, as in §3.
- **Resolution off-screen.** The attacker wins at 50% + (its influence − the holder's) / 2 + (its power − the holder's) / 4, kept within 15–85%.

**Starting numbers.**

| Lever | Value |
|---|---|
| Holder's start influence in its district | 20 |
| A side quest done | +15 (a Main quest +25) |
| Default for a quest with a clan standing raise of 5+ | +10 |
| Flip margin | holder + 15 (so 3 side quests, or a Main and a side) |
| Town threshold | 4 of 6 districts in Saltmouth, 3 of 5 elsewhere (60%) |
| Attack odds a chapter, by relation step | Blood feud (1) 35%, War (2) 20%, Hostile (3) 10%, Tense (4) and up 0 |
| Attack won (defended or on the numbers) | district flips; attacker +10 influence, +2 power |
| Attack beaten | attacker −10 influence there, −3 power; holder +10 influence |
| Siege lock | 2 days, or until defended |

Aim, measured in the 50-run clan study: 1 to 2 district flips by quests a run, under 1.5 by attacks, the town flip in 15 to 30% of runs, and the existing war moves (1.6 a run) unchanged.

**Smallest version that plays.** Saltmouth only, without attacks: every district held, `influence` on its 10 side quests, district and town flips, the news. That is 1 Core PR (rules, data, simulator, a `qa_` guard on the flips) once Narrative has tagged the quests. Attacks come in a second PR, on Saltmouth and the Ashen Quarter, with the crisis scene reused.

**From Narrative.** The clan each of the 10 Saltmouth quests serves; the start holders (checked); news lines for a district flip, a town flip and an attack (EN and FR). **From UX.** Influence on the district card (a bar per clan), the besieged mark, the town tint changing.

## Open questions for the user

1. **Lock or hide?** Do locked districts show on the plan with a lock (my advice) or stay fogged until opened?
2. **Accepted or done?** Does a lock open when you take the quest or when you finish it? Card Row only works with "taken".
3. **Do you go back?** The big towns are each played in one chapter (Saltmouth in 1 and 2, the Ashen Quarter in 3). Should influence also pay off later (a return visit, the chapter 7 throne, the Host), or only while you are there?
4. **Your choice or the quest's?** Should a quest's influence always go to a fixed clan, or to the clan you favour at the turn-in (21 quests have turn-in choices)?
5. **Alster.** Include it (chapter 1, the tutorial town), or keep the start quiet?
6. **What a flip changes.** Today a holder changes shop prices, reinforcements and offers. Should a flipped district also change its enemies or services?

## 5. Improvement ideas

- Give every quest a `clan` and a `district` in `quests.json`: 13 of 15 side quests in chapters 2–3 have no turn-in that moves a clan, so most side work leaves the clans untouched.
- Spread Saltmouth's side quests: 7 of its 10 start on the Wharf; Tern Row, the Alleys and Card Row get one or none.
- Fill or lock the empty districts: the Reliquary's Last Lantern has no scene, the Frost Line one, the Stone Bridge and Cinder Row two. They are blank spots on the plan.
- Have the simulator play the fall's scene (bend the knee or stay): it is the last gap in `sim-gaps.md`, and influence flips will make falls more common.
- Add a `power` and a `relation` trigger to politics events (planned in `territory-power-nemesis.md`, never built): today all 28 events fire on a chapter or a flag, so the coast never reacts to a clan rising.
