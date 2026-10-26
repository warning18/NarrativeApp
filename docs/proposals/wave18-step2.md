# Wave 18, step 2 and after: the list (Core, proposal)

Design only. Written on v1.558, after step 1 (Saltmouth's locks, influence and flips). Nothing here is built. The user picks the order after testing step 1. Each item is one PR unless it says otherwise. The numbers are starting points.

## 1. Attacks by rival clans
- **What:** at each chapter's territory turn (`territoryTurn`), a rival may attack a district its clan doesn't hold. The odds per chapter depend on the attacker's relation step with the holder:

  | Relation | Odds per chapter |
  |---|---|
  | Blood feud | 35% |
  | War | 20% |
  | Hostile | 10% |
  | Tense or warmer | none |

  Only clans with power ≥ 10 attack, and at most one attack per town per chapter.
- **Siege:** an attacked district is under siege for 2 days. `attack_<district>` and `attack_<district>_by_<clan>` are set, the camp errand `"campErrand": "attack"` (already in place) shows the alert, and the `districtAttacked` remark fires.
- **If the party is in the town:** the defence reuses the seat crisis scene (`clan_crisis.dart`): fight the attacker's hunter, pay, or stand aside. That ends the siege with `attack_<district>_defended`, `_joined` or `_ignored`.
- **Elsewhere:** the attack is settled on influence and power, with the attacker's odds kept between 15% and 85%, and arrives as news.
- **A won attack** flips the district through `givePlace` (cause `war`). War spoils and losses are the existing +5 / −8.
- **Simulator:** it plays attacks and a simple defence policy: defend when the holder is the party's main clan or an ally. Measure the flips per run, and how often the boss-balance tables move.

## 2. The other big towns
- **The Ashen Quarter** (5 districts; only Cinder Row (Compact) and the Spire Stair (Dominion) have holders): give the three empty ones holders from factions.json `claims`, plus one lock for Narrative to choose. The town is taken at 3 of 5.
- **The Black Reliquary** (5 districts, none held): the same, once Narrative says which clans belong there.
- **Alster:** it stays quiet, as the user decided.
- **The Lantern Alleys question:** the Mire holds them today. Moving them to the Crows, their only claimant, needs the boss target rechecked. In step 1 the Crows took the town one flip later, and boss_balance's claimant_morrow went out of tolerance (0.54 against 0.40±0.12). Measure it again once Narrative has tagged Saltmouth's quests, then let the user choose.

## 3. Influence pays off: the throne and the Host
- **Influence counts everywhere,** not only while the party is in the town. Step 1 kept it in-town by design.
- **The chapter 7 throne:** each district held by the party's main clan or an ally adds +1 to that clan's claim on the throne (`seatLead` is 25 today), up to +5.
- **The Host:** the final battle's allied strike (the wave 18 candidate on my list) draws from the clans that hold the most districts.
- **Simulator:** it needs a "favour" policy (keep to the main clan at turn-ins). Measure the throne's outcome per run before and after.

## 4. The epilogue map
- At the ending, the world chart shows who holds each town and district, tinted as today by `town_rulers.dart`. A line per big town names its holder and how it was taken (war, influence, seat), read from the clan log `givePlace` already keeps.
- **Core:** a pure `epilogueHoldings(politics, geography)` with a test.
- **UX:** draws the map. **Narrative:** writes the lines.

## 5. Clan roads
- A land route whose two ends are held by one clan becomes that clan's road. On a friendly road, its ruler's events lean friendly. On a hostile one, a toll or an ambush is likelier.
- This extends the land crossings' `landRouteRuler` / `rulerOneIn`, which already pick the ruler of a route's events.
- **Starting numbers:** a ruler's event comes one day in two on its own road (one in three today). Friendly at Friend or better, hostile at Unfriendly or worse.
- **Simulator:** measure the health lost per crossing; it must stay within the step's limits (about 1.5–3.5%).

## 6. Grey the ways into a locked district
- Step 1 refuses only the free walk. Here, `lockedWays()` feeds the story view and the Journey: a way into a locked district shows greyed, with its `lockedText`.
- **One exception:** a way that leads to the scene where the unlocking quest is taken stays open. Tern's Toll is taken inside Tern Row.
- **Card Row's "opens when taken" lock** (`opensOn: accepted`) comes in with it, if Narrative still wants it.
- **Shared screens:** this touches journey_screen.dart and story_player_screen.dart, in as few lines as possible.

## Suggested order
1. Item 6, the greyed ways: small, and it finishes the lock.
2. Item 1, attacks: the user's ask.
3. Item 2, the other towns: data, once Narrative has the clans.
4. Item 3, the payoff.
5. Items 4 and 5, the epilogue map and clan roads: their own small PRs.

## What CI says about step 1
CI's simulator tests check bands; they don't print win rates. Step 1 passed boss_balance, nemesis_quests, clash_balance and qa_clan_power_50 with no band changed. No quest carries a clan yet, so influence never fires in the simulator's runs. The only change the runs see is the new holders. A measured before-and-after needs a simulator batch, once Narrative's tags are in.
