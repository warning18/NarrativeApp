# Clan rules, v4: one signature rule per clan, for a hero alone (Core, proposal)

v4 replaces v3. The user's direction:

> "Since the game may be played solo can you propose other ways? Example in Slice & Dice mana could be replenished only by the dice falling on the mana face, armor could become thorn and hit back the enemy. The berserk style could make heavy blow but lose life on certain faces that would allow to trigger more powerful blow but increase risk etc."

So each of the six main clans gets **one signature rule**. The rule changes how a resource or a die face works for **one hero**, and nothing in it needs a party.

What stays as already validated:
- today's offers;
- a die you build freely;
- the passive stat points per level;
- the subclan cards, recast here as **twists on the clan's rule**.

This is a proposal only; nothing is built. **[N]** marks Narrative's part (names and lines), **[UX]** UX's (how it shows).

## At a glance

| Clan | Signature rule | What changes | The risk | The reward | Simulated win (baseline 54.5%) |
|---|---|---|---|---|---|
| **Dominion** | **The Writ of Order** | Your die is a deck: every face comes up once before any comes twice. The sixth face of each run, the **Verdict**, counts half again | No luck: your weakest face is certain to come up | You know what's left, and the Verdict lands on schedule | 64.6% (the deck alone: 58.8%) |
| **Vigil** | **The Long Watch** | Block you don't spend stays, up to half your max health; Defend faces block 3×; your strikes deal 15% less | Slow fights; a healer or a guard-breaker outlasts you | A wall that grows every round | 53.4%, the longest fights (19.0 rounds) |
| **Compact** | **Thornplate** | Half of every blow your block and armour stop goes back to the striker; heavy plate: you can't dodge | Poison and spells pass through plate; no lucky dodge | Defend faces and armour become your damage | 53.9%, the shortest fights (12.0 rounds); thorns deal 29% of your damage |
| **Mire** | **The Rot** | Your strikes deal 20% less, but each one that lands adds a lasting, stacking poison (5% of the full strike, every turn, all fight) | Little burst; a boss's cleansing phase wipes the rot | Long fights turn in your favour | 60.1%; rot deals 26% of your damage |
| **Crows** | **Blood Price** (the berserk) | Every Attack face is a Pain strike: double damage, costing 8% of your max health; below half health your strikes deal 25% more | You can bleed yourself out | The heaviest blows in the game | 62.9%, 11.8 rounds; 119 health paid per fight |
| **Penitents** | **The Ash Well** | Mana no longer carries between fights: you start each fight at 0. Mana faces give double; spells cost 1 less; mana left after a win heals you | A die without Mana faces leaves you with nothing | Big spell rounds and healing after every fight | 55.4% (the autoplay doesn't add Mana faces; see below) |
| *Pit* (minor) | *Clause in Blood* | Cast a spell you can't afford by paying 5% of your max health per missing mana, while you're above half health | Life for power | Spells whenever you need them | 54.2% |
| *Choir* (minor) | *The Vow* | No potions in a fight; heals heal 50% more; once a fight, a killing blow leaves you at 1 health | No safety net from the bag | The vow holds you up once | 55.9% |
| *Open Hand* | *Your Own Hand* | Once a round, reroll the die | — | Your own luck | 59.5% |

**About mana today:** the user's example is already the rule in a fight. Mana comes back only through a Mana face or a mana skill (Channel, Prayer). It carries over between fights and refills on a rest (spells.dart `maxManaFor`). So the Penitents' rule goes one step further: the well starts empty in every fight.

## How a rule works in play

- **Your patron's rule is yours.** Your patron is the main clan you stand best with, at Friendly (12+) or better. Its rule is on in every fight, and the fight screen names it under the die **[UX]**.
- **You choose it at the camp.** When two or more clans are Friendly, you pick which one is your patron there. You can also pick none, to fight by today's rules.
- **Passive stat points per level** come from the same patron, unchanged from v3:
  - +1 to its first stat at Friendly;
  - +1 to its second stat as well at Trusted;
  - +5 max health at Sworn.

  The stats lean toward the rule:

  | Clan | Stats | Why |
  |---|---|---|
  | Dominion | Strength, Charisma | |
  | Vigil | Constitution, Perception | |
  | Compact | Constitution, Strength | Constitution means more health to stop blows with |
  | Mire | Dexterity, Luck | |
  | Crows | Strength, Dexterity | |
  | Penitents | Wisdom, Intelligence | Wisdom feeds the Mana face's bonus |
- **Cards** come from Trusted, from the subclans you are friends with (the v3 table of how each subclan becomes your friend still holds). Each card **twists the patron's rule**. You wear one card, or two at Sworn, and change them at the camp.
- **A nemesis** loses its rule and its cards for you (see below).

## The six rules

### Dominion: The Writ of Order (the die as a deck)
- **Rule.** Each roll takes a face that hasn't come up yet in this run of six. When all six have come up, the deck is shuffled again. The sixth face of a run is the **Verdict**: it counts half again (damage, block, healing, mana).
- **Why you build differently.**
  - Luck can't save you: a weak face is certain to come up once in every six rounds. So you don't leave a weak face on the die.
  - You plan around what's left, and around where the Verdict falls. A Heal face used early means no healing until the next run.
  - A die's weights stop mattering. A rare face comes up as often as any other.
- **Measured.**
  - The deck alone wins 58.8% (+4).
  - With the Verdict at ×1.5 it wins 64.6% (+10) and ends fights faster (14.3 rounds against 16.6).
  - Much of the gain comes from the even odds: skill faces rise from 38% to 49% of rolls, because their weights no longer hold them back.
  - **Suggested:** a Verdict of ×1.25 (estimate: about +6).
- **Cards (twists):**

  | Subclan | Card | For | Twist |
  |---|---|---|---|
  | Order | **Knight of the Flame** | warrior | The Verdict strikes with Fire and Pierce |
  | Inquisition | **Inquisitor** | mage | You see the next face of the deck; the Verdict weakens its target |
  | Tribunal | **Magistrate** | any | Once a fight, send the face you drew to the bottom of the run and draw again |
- **Could also be:** Vigil's rule (the watch keeps its order). If so, Dominion takes the Vigil rule below.

### Vigil: The Long Watch (block that stays)
- **Rule.**
  - Block you don't spend stays to the next round, up to half your max health.
  - Defend faces block three times their number.
  - Your strikes deal 15% less.
- **Why you build differently.** Two or three Defend faces become a wall that grows every round, and Second Chance and Iron Will hold it. You win by still standing.
- **Measured.** It wins 53.4% (−1) and makes the longest fights (19.0 rounds).
  - A first version, with block that stays but no ×3 and strikes 25% weaker, won only 45.0%. Block on today's dice (5 to 10) is small next to an enemy's blow.
  - The autoplay keeps one Defend face in six. A player who builds three would win more; estimate +3 to +5.
- **Cards (twists):**

  | Subclan | Card | For | Twist |
  |---|---|---|---|
  | Last Watch | **Wall Veteran** | warrior | A strike can spend the held block, adding it to the blow |
  | Candlebearers | **Ossuary Warden** | cleric | At the start of each round, the held block heals you a tenth of itself |
  | Stitchers | **Stitcher** | rogue | Healing past full becomes held block |

### Compact: Thornplate (armour becomes thorns)
- **Rule.**
  - Half of every blow your block, parry and armour stop goes back to the striker.
  - Heavy plate: you can't dodge.
- **Why you build differently.** Defend faces and armour are now your damage. You want to be hit, so Attack faces matter less and armour pieces matter more.
- **The risk.**
  - Poison, spells and enemies that guard, heal or wind up don't touch the plate.
  - No dodge means no lucky escapes.
- **Measured.**
  - It wins 53.9% (−1) and makes the shortest fights of the six (12.0 rounds). Thorns deal 29% of your damage.
  - Sending back the full blow wins 61.4% (+7), with thorns at 43% of your damage.
  - Warriors gain most: 37% → 43%.
- **Cards (twists):**

  | Subclan | Card | For | Twist |
  |---|---|---|---|
  | Quarrymen | **Stonebreaker** | warrior | A blow sent back breaks the striker's guard |
  | Scaffolders | **Trapwright** | ranger | The first blow sent back each fight stuns |
  | Emberwives | **Ember Adept** | mage | Blows sent back are Fire (they set off element reactions) |
- **Could also be:** Vigil's rule (armour fits the Watch too). If so, the Compact takes **Tempering** instead: every face starts 3 lower and gains 2 each time it comes up in a fight (the forge warms up). It is measured at 55.8% (+1) with no change in fight length. As a rule it is milder and feels less different.

### Mire: The Rot (statuses that stack)
- **Rule.**
  - Your strikes deal 20% less.
  - Each strike that lands adds a lasting poison: 5% of the full strike, every turn, for the whole fight, stacking with the poison already there.
- **Why you build differently.**
  - Many small hits beat one big one, and early hits beat late ones.
  - Defend and Heal faces keep you up while the rot works, and potions matter.
- **The risk.**
  - Little burst.
  - A boss phase that cleanses wipes the stack.
  - Packs spread your hits thin.
- **Measured.**
  - At 5%: it wins 60.1% (+6) and the rot deals 26% of your damage.
  - At 10%: 66.4%, rot 36%.
  - At 15% with strikes 30% weaker: 68.6%, rot 47%.
  - Stacking compounds fast, so 5% is the ceiling.
- **Cards (twists):**

  | Subclan | Card | For | Twist |
  |---|---|---|---|
  | Barkbleeders | **Fever Blade** | rogue | When a rotting enemy falls, its rot passes to the next |
  | Heron's Wake | **Fen Guide** | ranger | A rotting enemy hits 15% softer (weaken) |
  | Moss Choir | **Moss Singer** | cleric | Each rot tick heals you a fifth of it |

### Crows: Blood Price (the berserk)
- **Rule.**
  - Every Attack face is a Pain strike: it hits for double and costs 8% of your max health, never the last point. This is the existing Pain keyword (face_keywords.dart).
  - Below half health, your strikes deal 25% more.
- **Why you build differently.**
  - Attack faces become the heavy blows. Few Defend faces; one Heal face, or lifesteal, to ride the line.
  - Low health is where you are strongest: risk for power, as the user described.
- **Measured.**
  - It wins 62.9% (+8) in 11.8 rounds per fight, paying 119 health per fight.
  - With +50% below half health and a 10% heal on a kill: 68.5%.
  - With no low-health bonus: 58.2%.
  - Warriors gain most: 37% → 48%.
  - **Suggested:** keep the +25% and move the heal on a kill to a card (estimate: +5).
- **Cards (twists, the user's own examples):**

  | Subclan | Card | For | Twist |
  |---|---|---|---|
  | Tar-Hands | **Tar Bleeder** | rogue | The life cost becomes a bleed on the enemy (poison equal to the cost), and you pay only half |
  | Brig-Born | **Corsair** | ranger | A kill heals 10% of your max health |
  | Whisper Ledger | **Ledger Knife** | rogue | A Pain strike steals gold (the Crow's Price twice); below a quarter health, strikes Pierce |
- **Could also be:** the Pit's rule (prices, life for power), or Vigil's through its orc heritage (Berserk Rage). If the Pit takes it, the Crows take **Double or Nothing**: once a round, reroll; the new face counts double, but if the same face comes up again, the turn is lost. Not simulated; estimate +3 to +6 with a careful reroll.

### Penitents: The Ash Well (mana from the die alone)
- **Rule.**
  - Mana no longer carries over between fights: each fight starts at 0.
  - Mana faces and mana skills give double.
  - Spells cost 1 less, never under 1.
  - After a win, each point of mana left heals you 2% of your max health.
- **Why you build differently.**
  - Two Mana faces are the engine.
  - You choose between spending the well on spells and keeping it to heal afterwards.
  - A warrior under the Penitents turns the well into healing.
- **The risk.** Slow first rounds, and a die without Mana faces makes the rule a loss.
- **Measured.** 55.4% (+1), 17.2 rounds.
  - The autoplay's die doesn't change for the rule: it keeps the profession's Mana face, which is 9% of rolls.
  - Estimate for a die with two Mana faces: +3 to +6 for casters, about +0 for others.
- **Cards (twists):**

  | Subclan | Card | For | Twist |
  |---|---|---|---|
  | Ember Sisters | **Ember Sister** | cleric | Mana past full becomes block |
  | Spire-Fallen | **Penitent Knight**, the holy warrior | warrior | Attack faces also give 1 mana; mana left after a win heals double |
  | Scorched Choir | **Ash Chorister** | mage | A spell cast from a full well hits 50% harder |
- **Could also be:** the Choir's rule (vows and light). If so, the Penitents take the Vow.

## The minor patrons, and the Open Hand

- **The Pit: Clause in Blood.** A spell you can't afford is paid in health: 5% of your max health per missing mana, while you're above half. It is measured at 54.2% (+0), with only 5 health paid per fight: the autoplay's heroes know few spells. Its card is **Dark Knight** (warrior): a spell paid in blood also heals you for a share of its damage.
- **The Choir: The Vow.** No potions in a fight; heals heal 50% more; once a fight, a killing blow leaves you at 1 health. It is measured at 55.9% (+1). Its card is **Paladin** (warrior or cleric): the first time the Vow saves you, it also lifts every affliction.
- The minor patrons' vows and pacts stay as they are, aside. A minor patron can be your patron only once you hold its vow or pact.
- **The Open Hand: Your Own Hand.** Once a round, reroll the die: the reroll of Slice & Dice.
  - It is measured at 59.5% (+5). Rerolling away Defend, Heal and Mana faces while above 60% health shifts the rolls from 20% Defend to 13%, and from 38% Skill to 45%.
  - It is raised by the banner, as the story tells it. Once raised, it can be your patron like a main clan: its passive is +1 to your strongest stat.
  - Its cards are any subclan card you have already been offered: your own hand.

## Measured: each rule against today's game

**Setup:**
- 200 seeded runs per rule, 40 per profession, random strategy, with the rule always on.
- The rule was added through a temporary patch of the fight simulator (sim_combat.dart). It is not committed.
- "Damage taken" counts blows landed on the hero per fight, all fights included.

| Rule | Win | Rounds per fight | Damage taken per fight | Rule's share of damage | Warrior / cleric win | Rolls (Attack / Defend / Skill / Mana) |
|---|---|---|---|---|---|---|
| Baseline (today) | 54.5% | 16.6 | 440 | — | 37 / 74 | 31 / 20 / 38 / 9 |
| Writ of Order, Verdict ×1.5 | 64.6% | 14.3 | 360 | — | 46 / 87 | 26 / 16 / 49 / 7 |
| Writ of Order, deck alone | 58.8% | 15.4 | 400 | — | 43 / 78 | 26 / 16 / 49 / 8 |
| Long Watch (block ×3 kept, strikes −15%) | 53.4% | **19.0** | 445 | — | 35 / 67 | 31 / 20 / 38 / 9 |
| Long Watch (block kept, strikes −25%) | 45.0% | 19.1 | 467 | — | 30 / 60 | same |
| Thornplate, half back | 53.9% | **12.0** | 370 | thorns 29% | 43 / 88 | same |
| Thornplate, all back | 61.4% | 10.5 | 325 | thorns 43% | 52 / 94 | same |
| Tempering (Compact's alternative) | 55.8% | 16.2 | 409 | — | 35 / 80 | same |
| Rot 5%, strikes −20% | 60.1% | 14.6 | 373 | poison 26% | 43 / 91 | same |
| Rot 10%, strikes −20% | 66.4% | 13.0 | 329 | poison 36% | 53 / 96 | same |
| Blood Price (+25% below half health, kill heals 5%) | 62.9% | **11.8** | 312, plus 119 paid | — | 49 / 88 | same |
| Blood Price (+50%, kill heals 10%) | 68.5% | 11.9 | 314, plus 122 paid | — | 57 / 89 | same |
| Ash Well | 55.4% | 17.2 | 441 | — | 37 / 76 | same |
| Clause in Blood (Pit) | 54.2% | 16.4 | 436, plus 5 paid | — | 37 / 74 | same |
| The Vow (Choir) | 55.9% | 17.1 | 428 | — | 40 / 74 | same |
| Your Own Hand (Open Hand) | 59.5% | 15.7 | 422 | — | 43 / 77 | 35 / 13 / 45 / 6 |

**What it shows:**
- **The rules make the clans play differently,** which v3's leanings could not: fights run from 11.8 to 19.0 rounds, against 15.7 to 19.1 for the clans in v3, around 16.6 today.
  - Thorns or rot carry a third of the damage.
  - The berserk pays a quarter of its health per fight.
  - The Watch fights longest.
- **The autoplay doesn't rebuild its die for a rule:** the rolls stay 31/20/38/9 except under the deck and the reroll. So these numbers show a player who doesn't adapt. One who builds for the rule (three Defend faces for the Watch, two Mana faces for the Ash Well, all Attack for the berserk) does better. That is the point of the rule, so the targets leave room for it.
- **The weakest profession gains most.** Warriors gain under every damage rule (Blood Price, Thornplate, Rot): 37% → 43–57%.
- **Suggested numbers:** within about +6 of today for a player who doesn't adapt:

  | Rule | Suggested numbers |
  |---|---|
  | Writ of Order | Verdict ×1.25 |
  | Long Watch | block ×3 kept, strikes −15% |
  | Thornplate | half back |
  | Rot | 5% |
  | Blood Price | +25% below half, no heal on a kill |
  | Ash Well | as written |

To rerun the measurement, apply the patch in the Core session's scratchpad (`v4_rule_sim.patch` and `zz_rule_report_test.dart`, run with `RUNS=200 RULES=none,deck,...`). They will become a committed simulator option when the rules are built.

## Kept from v2.1 and v3

How the kept parts tie in:
- Your **patron** gives the rule and the passive stats.
- Cards need **Trusted**.
- A clan that becomes your **nemesis** loses its rule, its passive and its cards for you until you reconcile, and can't be your patron.
- Taking a clan's offers and cards raises its **power**.
- **Alignment** stays separate; clans only nudge it, as gifts do now.

### Clan power and territory

#### Power

Each clan gets a **power** value (0–100) in `PoliticsState`, beside standing. Standing is how the clan sees *you*; power is how strong *it* is.

| Source | Power |
|---|---|
| A gift taken from it | +2 (legendary +4) |
| A quest done for it (quests carry a faction) | +5 |
| A zone cleared that it claims | +5 |
| A subclan boon earned | +5 |
| A betrayal against it | -10 |
| Politics events (variants shift standing today; they would shift power too) | ±5 to 15 |

| Tier | Power | Unlocks |
|---|---|---|
| Minor | 0–24 | common gifts |
| Rising | 25–49 | rare gifts; takes its first claim |
| Dominant | 50–74 | legendary gifts; takes more claims; its house in a town it holds (later hook) |
| Ascendant | 75+ | its throne claim weighs more at the ch7 decision (throne.dart) |

#### Territory

- **The starting map.** `geography.json` already gives 12 places a `controller`:
  - Dominion: the Spire, Candlehold, its lantern hall, Alster's Black Hold;
  - Crows: the Wharf, Card Row, Alster's lower town;
  - Compact: Emberwick;
  - minor patrons: oni at Akagiri, Kindly Hill, the giants at Highhearth, the Tide-Kin on Tern Row.
- **Taking places.** `PoliticsState.control` (place id → clan) overrides that map as clans take places.
  - Each clan gets ordered **claims** in factions.json (the Mire: Kindly Hill, the Drowned Cloister, the Hollow Court).
  - When a clan's power crosses a tier, it takes its next claim.
  - The former holder loses the place, their relation drops a step, and a news line says so ("The Mire Courts hold the Drowned Cloister now"). **[N]**
- **What control does now:** in a held place, its clan's gifts are likelier in offers and its shops charge its standing price. The visuals are a later hook.
- **The radar** (#264) gains the clan's **power** (a ring or a bar) and the **places it holds** (a count, and the list on the clan tab). **[UX]**
- **Politics events** (26 in politics_events.json) gain:
  - a `trigger.power` condition (`{"faction": "dominion", "minPower": 50}`);
  - `effects.power` and `effects.control`.
  - The existing events keep working.

### Neglect and the nemesis

A clan the player keeps turning away from does not just fade.

- **Neglect.** Each chapter in which the player takes no gift and does no quest for a main clan costs it 5 power. Rivals then take its places as their tiers rise. That is a clan losing power.
- **Nemesis.** A clan becomes the player's nemesis when:
  - the player's standing with it falls to **Hostile** (−26 or lower), by refusing it, betraying it or serving its feuds;
  - it is still **Rising or stronger** (power 25+).

  There is at most one nemesis, the strongest such clan. A nemesis:
  - **hunts the party.** Its ambushes come on roads, detours and expeditions, through the alignment hunters' system (`buildHunterAmbushNode`). Its foes carry its own mechanic against you: Sentence on your attacks, Rot on your party, your gold stolen.
  - **contests your places.** It moves against the clans you back.
  - **offers nothing.** No gifts while it is your nemesis.
- **Ending it.**
  - **Reconcile:** raise standing back above Wary, through a costly quest or gift it asks for.
  - **Break it:** a nemesis quest, its champion as a boss, which drops its power by a tier and ends the hunt. That is a **[N]** story beat per clan, six of them.
- **The radar** shows a nemesis in red. **[UX]**

## Order of work (once the user validates)

1. **The rule switch and the six rules:** in the fight, the simulator and the Choose Patron line at the camp. The rules reuse what exists:
   - the Pain keyword;
   - block;
   - poison stacking (a new `stack` flag on poison);
   - thorns (`gear.thorns`, now fed by stopped damage);
   - the die roll (deck and reroll);
   - mana at the fight's start.
   - Plus a committed per-rule simulator report.
2. **The patron's passive stats per level.**
3. **Cards** as rule twists. The first 18 are the ones above; **[N]** writes their names and lines, **[UX]** designs the card and the deck.
4. Power, territory and the nemesis, afterwards.

## Open questions for the user

1. **Who gets which rule?** Default: the berserk goes to the Crows, the thorns to the Compact, and the deck to Dominion. The alternatives:
   - the berserk to the Pit (the Crows take Double or Nothing);
   - the thorns to the Vigil (the Compact takes Tempering);
   - the deck to the Vigil.
2. **When is the rule on?** From Friendly with your patron, chosen at the camp, with "none" allowed. Or only from Trusted, so early runs stay as today?
3. **How strong?** At the suggested numbers, a player who doesn't adapt wins up to +6 over today. Should a rule be a sidegrade, or should committing to a clan be rewarded more?
