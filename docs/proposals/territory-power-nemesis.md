# Territory, power and the nemesis (Core, plan for v5.2 step 6)

This plan builds on the proposal's sections "Clan power and territory" and "Neglect and the nemesis" (profession-clan-mechanics.md v5.2), and on what the game has today.

## What exists today

- **14 places have a holder.** `geography.json` writes a `controller` on them:
  - Dominion (5): Candlehold, its lantern hall, the Spire of Judgment, Alster's Black Hold, the Spire Stair.
  - Crows (3): Alster's lower town, the Wharf, Card Row.
  - Compact (2): Emberwick, Cinder Row.
  - Minor holders: the oni at Akagiri, the Kindly at Kindly Hill, the giants at Highhearth, the Tide-Kin at Tern Row.
  - The Vigil, the Mire and the Penitents hold nothing.
- **The holder is already read in two places:**
  - `Geography.heldBy` sets the shop's standing price in `shop_detail_screen`;
  - it is shown in `geography_widgets`.
- **Hunting already works.** Hunted shuts a clan's shop, and the rival hunters (#306) hunt a *sworn* character from the rivals at Hostile or Hunted.
- **Not there yet:**
  - none of the 43 quests carries a clan;
  - politics events only trigger on `chapter` and `flag`, and only change standing, relations, marks, flags and intrigues;
  - there is no power, no live territory and no nemesis.

## 1. Territory

- **Base map and live state.** The `controller` values stay as the starting map. A new `PoliticsState.control` (place id → clan) records changes, and is saved and loaded like the other fields.
  - `holderOf(place, geography, politics)` replaces `heldBy` wherever the game reads a holder: shops, the map widget, offers and fights.
- **Claims.** In `factions.json`, each main clan gets an ordered list of 2 or 3 places it claims.
  - Core drafts the lists from the geography, and Narrative checks they fit the story.
  - Some claims are another clan's places (the Mire: Kindly Hill first). Others are places no one holds yet, so the Vigil, the Mire and the Penitents can gain a foothold.
- **How places change hands**, checked at each chapter change, at most one change per clan per chapter:
  - **Power:** when a clan's power crosses into a higher tier, it takes its next claim, if the holder is weaker in power.
  - **Wars:** two clans whose relation is at war contest one place. The one with more power takes one of the other's places if it leads by 15 or more. The nemesis contests your patron's places first (§3).
  - **Story beats:** politics events gain `effects.control` (give a place to a clan) and `effects.power`, plus a `trigger.power` condition (`{"faction": "dominion", "minPower": 50}`). Existing events are unchanged.
  - **A clan's seat never falls** (Candlehold, and each clan's home once it has one), so no clan is wiped off the map.
- **What a change does:**
  - the old holder's relation with the new one drops a step;
  - a news line goes out ("The Mire Courts hold Kindly Hill now"), and the clan log records it.

## 2. Power

- **What it is.** A value from 0 to 100 per main clan in `PoliticsState.power`. Standing is how the clan sees *you*; power is how strong *it* is. Starting values go in `factions.json`; my draft is Dominion 60, Crows 45, Compact 40, Vigil 30, Penitents 25, Mire 25.
- **Tiers:**

  | Tier | Power |
  |---|---|
  | Minor | 0–24 |
  | Rising | 25–49 |
  | Dominant | 50–74 |
  | Ascendant | 75+ |

- **What moves it:**

  | Source | Change |
  |---|---|
  | A gift taken from it | +2 (legendary +4) |
  | A quest done for it | +5 (quests gain a `faction` field) |
  | A fight won in a place it holds or claims | +1, up to +5 a chapter |
  | A subclan boon earned | +5 |
  | Each place it holds, each chapter | +1 |
  | Betraying it, or breaking it as your nemesis | −10, or down one tier |
  | Politics events | ±5 to 15 |
  | Neglect: a chapter with no gift and no quest for it | −5, never below 20 under its start |

- **What it gates:**
  - **Rising:** rare gifts, and its first claim.
  - **Dominant:** legendary gifts, and more claims.
  - **Ascendant:** its claim weighs more at the chapter-7 throne decision (`throne.dart`: power breaks the tie before standing).

## 3. The nemesis

- **Who.** At most one: the strongest clan (power 25+) you stand at Hostile or Hunted with.
  - It stays your nemesis until your standing climbs back to Wary, so it doesn't flicker at the border.
  - This works whether or not you are sworn. Today's rival hunters only hunt a sworn character.
- **What it does:**
  - **It hunts you, reusing the rival hunters.** It sends its fighters (`hunterClan`) at the Hunted odds (8% a road at rest). This shares the 15% cap and the alignment hunters' cooldown, so a road still holds at most one ambush. Mercy and betrayal work as today.
  - **It contests your places.** In wars, it targets the places of your patron (sworn, or best standing) first.
  - **It offers nothing.** That is already true at Hostile.
  - **Its gifts you hold sleep.** That is already true at Hunted; at Hostile they work at half.
- **How it ends:**
  - **Reconcile:** climb back to Wary.
  - **Break it:** its nemesis quest, with its champion as a boss. Winning costs the clan a tier of power and ends the hunt, and it cannot be your nemesis again for 2 chapters. This needs a story beat per clan (6), from Narrative, and 6 champion bosses: Core sets their numbers on the boss curve, Narrative names them.
- **Deferred:** the proposal's "its foes carry its own mechanic against you" (Sentence, Rot, stolen gold) is a later step, once the rest is measured.

## 4. Effects on play

- **Reinforcements** (deferred from step 4) become one more context rule, stacking on the Tide like the others. Where the fight's place is held:
  - by a clan you stand Friend or better with: from round 8, allies strike for a share of the foe's max health each round;
  - by a clan that hunts you, or by your nemesis: from round 8, enemy allies strike the party.

  The proposal measured allies at 5% a round as far too strong (cleric 98%, others +5 to +21). I will start at 2–3% and tune to within +5 points per profession. Bosses are excluded, as with the other foe rules.
- **Shops:** already priced by the holder's standing. They follow the live holder, so a town your nemesis takes stops trading with you.
- **Offers:** in a place a clan holds, its suitor is likelier (×1.5 weight), and power tiers gate gift rarity (§2).
- **Town tinting** belongs here, and is UX's job: the map tints a place by its live holder.
- **Clan houses** (a Dominant clan's house in a town it holds, bringing its suitor) belong later, as a hook once power has run in the release for a while. They are not in this step.

## 5. What the player sees, and what's needed

**The player sees:**
- news lines when a place changes hands;
- the clan log;
- a notice when a nemesis rises or ends;
- the nemesis's hunters on the roads, with their battle cries;
- reinforcements in fights, with a log line;
- shop prices and offers changing with the holder.

**Narrative:**
- check the 6 claim lists;
- word the news templates in English and French (place taken, war, nemesis rises, nemesis ends);
- tag the 43 quests with their clan, or confirm Core's guess from the giver's faction;
- write 6 nemesis quests, each with a champion (name, description, battle cry);
- write 2 or 3 politics-event variants that move places at story beats.

**UX:**
- power on the clan radar (a bar or a ring);
- the places a clan holds, as a count on the radar and a list on its tab;
- the nemesis in red;
- map tint by the live holder;
- the reinforcement banner in fights.

## 6. PRs, each measured

1. **Power and territory state** (no fight change).
   - `power`, `control`, claims, `holderOf`, the power sources, neglect, claims taken at tier crossings, wars, `effects.power`, `effects.control`, `trigger.power`, and news with placeholder text.
   - Shops and the map widget switch to `holderOf`: a line each in shared or UX files.
   - **Simulator:** each clan's power over the 7 chapters by route (sworn to each clan, unsworn), and places changed per run. The aim is that the map moves without collapsing: 2 to 6 changes a run.
2. **The nemesis.**
   - Selection, the hysteresis band, hunting through the rival-hunter roll, the war target, notices, and the break hook (a flag the quest sets).
   - **Simulator:** how often a run has a nemesis, ambushes per run, and win% with and without it.
3. **Reinforcements:** the context rule, live hooks, and a per-profession sim table (allies, enemies, off). Target: within +5 points.
4. **Offers and the throne:** the held-place suitor weight, power gating rarity, and power weighing in `throne.dart`. **Simulator:** the offer mix by tier.
5. **Nemesis quests and champions**, once Narrative's texts are in: 6 champion bosses checked against the boss curve (`boss_balance_test`).

UX's work on the radar, the map tint and the territory list can start after PR 1, which gives them `power`, `holderOf` and the claims to read.

## Open questions for the user

1. **Starting power:** Dominion strongest (60) down to the Mire and Penitents (25)?
2. **Seats never fall:** is that right, or can a clan be driven off the map entirely?
3. **The nemesis without an oath:** a character sworn to no clan can still make one their nemesis. Agree?
4. **Reinforcements:** gentle (+2 to +5) as planned, or a bigger swing in held lands?
