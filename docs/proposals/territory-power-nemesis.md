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

## Addendum: the user's answers

The user's answers to the open questions:
1. **Starting power:** kept as drafted.
2. **Seats can fall.** A clan can lose every place, its seat included.
3. **The nemesis is wider than one clan:** good and evil hunt too, so a character is nearly always hunted a little.
4. **Reinforcements:** gentle, within +5 points.

### A. The crisis, and the fall of your clan

**Your main clan** is the one you are sworn to, or else your patron (`statPatron`: the best standing at Friendly or better).

**The crisis.** When a chapter change would take your main clan's **seat** (its last place, or its named seat), the change is held back and a crisis scene comes first, on the next road at rest. The clan asks for your help:

| Choice | Cost | If it works | If it fails, or you refuse |
|---|---|---|---|
| **Defend the seat** | A fight at the seat against the attacker's hunter, tier by chapter, with the reinforcements rule on your side | The seat holds. The attacker loses 10 power; your clan gains 5 power and 5 standing. | The seat falls. |
| **Pay** | Gold (40 × chapter) or materials (3 timber and 2 cut stone, or what the clan's buildings use) | The seat holds this chapter. The attacker takes a lesser place of your clan instead, if it has one. | — |
| **Refuse** | Your clan's standing −10 | — | The seat falls. |

A clan that is not your main clan falls with no crisis: a news line, and the change in the clan log.

**The fall.** A clan with no place left is **fallen**:
- its power drops to 0;
- it offers nothing;
- its hunters leave the roads.

It can rise again: quests and gifts for it still raise its power, and at 25 it retakes its first claim, starting with its seat.

If the fallen clan is your main clan, a scene forces a choice:

- **a) Bend the knee to the winner.** You swear to the clan that took the seat.
  - Your standing with the winner rises to at least Friendly (20); you are sworn to it.
  - Your standing with the fallen clan drops to Resented (−20 at most). Its gifts you hold work at half, as the existing Resented rule does.
  - The winner takes a tithe: 20% of your gold, once.
  - Loyalty drift then runs on the winner, as for any oath.
- **b) Stay of a fallen clan.** You keep faith, and are clanless until you raise a banner of your own:
  - **no oath:** you can't swear to another clan while fallen, and no clan's passive stats come to you;
  - **its gifts keep working at full:** you keep its ways;
  - **the winner becomes your nemesis**, whatever its power;
  - **the fallen clan's survivors** sometimes come to you as suitors on roads: its offers, at the Friendly rate;
  - **tie to the Open Hand.** Raising your own banner (`banner_raised`, the existing path) ends the state, and the fallen clan **pledges** to your Host (`PoliticsState.pledged`). If the banner is already raised when the clan falls, it pledges at once. The clan rising again also ends the state.

The crisis and the fall come in their own PR (PR 2b below). PR 1 lets seats fall, with no crisis yet: a news line only.

### B. The alignment hunters, and how all hunters combine

**Today** (alignment_events.dart):
- demons hunt a Good character, and angels an Evil one;
- odds start at 6% a road at rest at alignment ±20, +0.15% a point past it, capped at 15%;
- a Neutral character is never hunted, only tempted (10%);
- 2 hunters per side (tier 1 and tier 2).

**Proposed:**

- **A neutral character is hunted lightly by both sides.** Under ±20, the odds are 2% + 0.2% a point (2% at 0, 6% at the border, joining today's curve). The side is drawn by the lean: at 0, either side; at +15, mostly the evil forces. Temptations stay. At ±20 and beyond, nothing changes.
- **Who hunts.** The angels and demons stay. An enemy may carry both `hunterClan` and `hunterAlignment`, so a clan's own hunters can hunt by alignment too. Core's draft, for Narrative to confirm:
  - **good orders hunting an Evil character:** the Vigil's candle-bearer, the masked penitent, an inquisition soldier;
  - **evil forces hunting a Good character:** the cultist acolyte, the Hollow Court zealot, a void stalker.
- **How they combine.** One ambush per road at most, under one cooldown (5 rolls), rolled in this order:
  1. a betrayal that is due (mercy);
  2. the clan hunters: the nemesis at 8%, plus each Hostile or Hunted rival of your oath (#306), capped at 15%;
  3. the alignment hunters, by the curve above, capped at 15%.

  Mercy and betrayal apply to all of them. A nemesis's hunter can't be spared when it is the same fighter that betrayed you.

**Measured** (200 runs, hunters per run, by final alignment; the neutral curve was tried locally and not committed):

| Final alignment | Runs | Today: alignment hunters | Proposed: alignment hunters | Clan hunters (#306) | Betrayals |
|---|---|---|---|---|---|
| Neutral (under ±20) | 22 | 0.00 | **1.05** | 1.41 | 0.14 |
| Leaning (±20 to ±49) | 38 | 0.68 | **1.82** | 1.16 | 0.16 |
| Strong (±50 and past) | 140 | 2.21 | **2.60** | 1.01 | 0.05 |

- Every alignment is now hunted: about **2.5 to 3.7 hunters a run** out of about 60 roads at rest.
- Leaning and strong characters gain hunters too: the leaning ones spend part of the run neutral, where today no one hunts them.
- **The nemesis adds** about one hunter a run, by estimate, when there is one. PR 2 measures it.

### What Narrative needs to write (English and French)

1. **The crisis:** one scene template per clan, or one shared template with {clan}, {attacker} and {seat}; the three choices (defend, pay, refuse); and the lines for held, paid and fallen.
2. **The fall:** the news line ("{clan} has fallen: {winner} holds {seat}"), and the choice scene.
3. **Bending the knee:** the oath to the winner (one line per winner, or a template) and the clan log line.
4. **The fallen-clan state:** its label and short description on the clan tab; the survivors' suitor line; the line when the banner is raised and the clan pledges.
5. **The alignment hunters:** neutral ambush lines for each side ("you have not chosen, and both sides have noticed"); confirm the six hunters drafted above; battle cries for any that lack one.
6. **Places changing hands:** taken, war, and seat fallen. Already listed above.

### PRs, updated

1. **PR 1, power and territory state.** Seats can fall (a news line, no crisis). The simulator reports how often a seat falls.
2. **PR 2, the nemesis and the alignment hunters' new curve.** Simulator: hunters per run by alignment (table above), and with a nemesis.
3. **PR 2b, the crisis and the fall.** Defend, pay or refuse; bend the knee, or stay of a fallen clan, tied to the Open Hand. Narrative's texts come in when ready (English placeholders until then).
4. **PRs 3 to 5** as before: reinforcements, offers and the throne, nemesis quests and champions.
