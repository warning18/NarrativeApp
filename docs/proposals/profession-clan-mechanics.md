# Clan rules, v4.2: one signature rule per clan, short fights, more skills in play (Core, proposal)

**v4.2** gives the Vigil a new rule. Your feedback on v4: *"Great, the only one that should be updated again is the Vigil. Can't you find a better mechanic? Like healing yourself, and healing over max life does damage, or something similar."*

- **Accepted, as v4 wrote them:**
  - Dominion: the Writ of Order;
  - Compact: Thornplate;
  - Mire: the Rot;
  - Crows: Blood Price;
  - Penitents: the Ash Well;
  - the Pit, Choir and Open Hand rules.

  The alternative swaps are dropped. v4.1 had moved the deck to the Vigil and given Dominion "Judgment"; that is undone.
- **New:** the Vigil's **Watchfire** (healing past full burns the enemy), with its three subclan gifts.
- **Kept from v4.1, from your later messages:**
  - **"Cards are clan offers":** the word "card" is gone. A subclan's twist is one more gift in its clan's offers.
  - **"No too long fights":** the Tide.
  - **"Skill diversity":** six proposals.
- **Still open with you:**
  - whether a rule turns on from Friendly or only from Trusted;
  - whether a rule is a sidegrade or a reward.

  This document doesn't decide them.

Proposal only; nothing is built. **[N]** marks Narrative's part, **[UX]** UX's.

## At a glance

| Clan | Signature rule | What changes | Risk / reward | Win / rounds (today: 54.5% / 16.6) | With the Tide (alone: 54.5% / 11.2) |
|---|---|---|---|---|---|
| **Dominion** | **The Writ of Order** (the die as a deck) | Each face comes up once before any comes twice; the sixth face of a run, the Verdict, counts half again | No luck, your weakest face is certain / you know what's left | 64.6% / 14.3 | 65.2% / 10.7 |
| **Vigil** | **The Watchfire** | While above half health, you heal 2% of max health each round. Healing past full feeds a Watchfire (up to half your max health) that takes blows first; what's left at the round's end **burns the enemy for double** | Below half health the fire goes out / staying high turns every heal into damage | 63.1% / 17.2 | 62.5% / 11.6 |
| **Compact** | **Thornplate** | Half of every blow your block and armour stop goes back; you can't dodge | Poison and spells pass the plate / defence becomes damage | 53.9% / 12.0 | 50.5% / 10.0 |
| **Mire** | **The Rot** | Strikes deal 20% less; each one that lands adds a lasting, stacking poison (5% of the full strike, every turn) | Little burst / every hit keeps working | 60.1% / 14.6 | 53.4% / 11.3 |
| **Crows** | **Blood Price** (the berserk) | Every Attack face is a Pain strike: double damage, 8% of your max health; below half health, strikes deal 25% more | You can bleed out / the heaviest blows | 62.9% / 11.8 | 65.4% / 9.2 |
| **Penitents** | **The Ash Well** | Each fight starts with 0 mana; Mana faces give double; spells cost 1 less; mana left after a win heals you | A die without Mana faces does nothing / big spell rounds, healing after | 55.4% / 17.2 | not run |
| *Pit* | *Clause in Blood* | A spell you can't afford is paid in health, 5% of max per missing mana, while above half | Life for power | 54.2% / 16.4 | not run |
| *Choir* | *The Vow* | No potions in a fight; heals heal 50% more; once a fight, a killing blow leaves you at 1 | No safety net / the Vow holds you once | 55.9% / 17.1 | not run |
| *Open Hand* | *Your Own Hand* | Once a round, reroll the die | — | 59.5% / 15.7 | 59.9% / 10.9 |

**How the three healing rules stay apart:**
- The **Vigil** heals itself all fight and turns *health* past full into damage.
- The **Choir** heals harder but gives up potions, and its surplus does nothing.
- The **Penitents** turn *mana* left after a win into healing.
- v4.1 had made the Ash Well and the Vow turn their surplus into damage too. That is dropped, so surplus becoming damage stays the Vigil's own.

## Vigil: the Watchfire

**The rule:**
- **Self-healing.** At the start of each round, while you are at half health or more, you heal 2% of your max health.
- **The Watchfire.** Healing past full health (the round's heal, a Heal face, a heal skill) feeds the Watchfire, up to half your max health. It is shown as a flame over your health bar **[UX]**.
- **It guards, then it burns.** The enemies' blows that round hit the Watchfire first. What is left of it at the end of the round **burns the enemy in front of you for double**, and the fire starts again from nothing.
- **The risk.** Below half health the self-healing stops, and the fire goes out with it. You must stay high to keep it.

**Why you build differently:**
- Heal faces and heal skills become attack faces, as long as you're near full.
- You want to stay above half, so Defend faces and Constitution (more max health, more fire) matter. That fits the Vigil's Constitution and Perception leaning.
- Big burst matters less: the fire works every round.

**Measured** (200 runs, the same setup as the others):

| Version | Win | Rounds | Note |
|---|---|---|---|
| **The Watchfire: 2% while above half, burns double** | **63.1% (+8.6)** | **17.2** | **with the Tide: 62.5% / 11.6** |
| Overheal burns, no self-healing (the first version) | 55.1% | 17.0 | the fire hardly lights: about 4 damage per fight |
| Self-healing 5% every round, no burn | 88.3% | 18.6 | far too strong: health also carries between fights |
| 3% while above half, burns double | 69.9% | 16.9 | too strong |
| 3% while above half, burns double, strikes −20% | 59.1% | 19.5 | fights too long |

- **Which version:** the 2% one keeps the win rate near the other accepted rules (Writ of Order +10, Blood Price +8) and adds under a round per fight.
- **Why the fire is a buffer before it is damage:** the Watchfire burns 34 damage per fight and soaks 13 of the enemies' blows, and that leaves the round's own self-healing as the larger part of the rule. Making the burn the larger part is what the gifts below do.
- **Suggested:** keep 2%, and if loyalty is to be a sidegrade (open question), burn half again rather than double.

**Subclan gifts (twists on the rule):**

| Subclan | Gift | For | Twist |
|---|---|---|---|
| Last Watch | **Wall Veteran** | warrior | Defend faces feed the Watchfire too: half their block goes in as healing, so a guard at full health becomes fire |
| Candlebearers | **Ossuary Warden** | cleric | The Watchfire holds up to your full max health (not half), and its burn is Light |
| Stitchers | **Stitcher** | rogue | The Watchfire doesn't burn at the round's end: your next strike carries it instead, all at once |

## Short fights: the Tide

**Today:**
- Average 16.6 rounds per fight: 7.3 in chapter 1, 18.7 in chapter 5, **30.3** in chapter 7, 18.1 for bosses.
- One fight in seven lasts more than 25 rounds.

**The Tide, one rule for every fight:**
- From round 8, the tide rises each round: **your blows +20%, the enemies' +10%**, adding up. At round 10 you hit +60% and they hit +30%.
- The fight screen shows it beside the round count **[UX]**.

| | Today | With the Tide | Tide at +20% for both | Enemies −25% health from chapter 4 instead |
|---|---|---|---|---|
| Win | 54.5% | **54.5%** | 46.8% | 62.9% |
| Rounds per fight | 16.6 | **11.2** | 10.4 | 14.7 |
| Fights over 25 rounds | 14.5% | **1.1%** | 0% | 11.2% |
| Chapter 7 / bosses | 30.3 / 18.1 | **16.6 / 12.1** | 13.9 / 11.0 | 28.6 / 15.8 |
| Win by profession (cl / ma / ra / ro / wa) | 74 / 63 / 54 / 49 / 37 | **52 / 62 / 60 / 57 / 42** | 35 / 61 / … | 83 / 73 / 64 / 57 / 43 |

- **The Tide keeps the win rate, cuts long fights to 1 in 100, and narrows the gap between professions.** Clerics win by outlasting today; with the Tide the spread drops from 37 points to 20.
- **Every accepted rule stays short under the Tide:** 9.2 to 11.6 rounds.
- **Target:** an average of 10 to 12 rounds, bosses at 12 or fewer, and no fight past 20 but a rare boss.

## More skills in play

**Today:**
- 92 skills come up, but they spread like **only 17 equally used skills**. The top 10 take 62% of rolls.
- **39 skills come up under 0.2% of the time**, among them Execute, Meteor, Fireball, Power Strike, Whirlwind, Multi-Shot, Shield Bash, Poison Blade, Iron Will and Second Chance.
- Prayer alone is **18.2%** of skill rolls; Entropy Touch 7.3%, Celestial Ward 5.9%, Channel 5.1%, Backstab 5.1%.

**Why:**
1. Prayer and Channel sit on a **fixed** face of the starting die.
2. Most damage skills differ only by their numbers, so the biggest number wins.
3. The epic skills reach few runs, and late.
4. There are only three statuses.

**The proposals:**
1. **Free the mana face.** It stays fixed only until the die holds a second source of mana, then takes any skill. In the runs where mana works differently, Prayer falls from 18% to 8–9% and the spread widens from 17 to 25 equally used skills.
2. **One verb per skill,** from existing keywords and conditions:

   | Skill | Its verb |
   |---|---|
   | Power Strike | Steady |
   | Execute | Double under 30% enemy health |
   | Whirlwind | Cleave |
   | Fireball | Half its damage to the others |
   | Meteor | Lands next round, on every enemy, for double |
   | Multi-Shot | Three hits of 40%, each counting as a hit |
   | Backstab | Double against a stunned or weakened enemy |
   | Aimed Shot | Pierce |
   | Hammer Blow | Growth |
   | Poison Blade | Its poison stacks |
   | Iron Will | Block equal to its heal |
   | Second Chance | Double below a quarter health |
   | Smite | Double against Evil |

   Narrative rewords the skill texts **[N]**.
3. **Each rule lifts different skills,** and a clan's skill gifts lean on them:

   | Rule | Skills it makes the best picks |
   |---|---|
   | Writ of Order | a die with no weak face; Steady |
   | Watchfire | heal skills (Iron Will, Second Chance, Mending Touch, Prayer) and Defend skills |
   | Thornplate | Bulwark Stance, Iron Stance, Stoneskin, Shield Bash |
   | Rot | Multi-Shot, Poison Blade, Entropy Touch |
   | Blood Price | Berserk Rage, Bloodlust, Reaping Whirl, lifesteal |
   | Ash Well | Channel, Mana Shield, spells |
4. **The fresh face** (optional): the first time each face comes up in a fight it counts more. Measured at +50%: 64.1% without the Tide, 63.4% / 10.7 rounds with it. **Suggested at +25%.**
5. **An epic skill within reach:** from chapter 4, each chapter's first clan offer includes one epic skill of your branches.
6. **Track it:** the simulator report gains the spread of skills in play. Target: 25 or more.

## How a rule works in play

- **Your patron's rule is yours.** Your patron is the main clan you stand best with, chosen at the camp among those that qualify, or none. When a rule turns on (from Friendly or only from Trusted) is open with you.
- **Passive stat points per level, unchanged:**
  - +1 to the patron's first stat at Friendly;
  - +1 to its second stat as well at Trusted;
  - +5 max health at Sworn.

  | Clan | Stats |
  |---|---|
  | Dominion | Strength, Charisma |
  | Vigil | Constitution, Perception |
  | Compact | Constitution, Strength |
  | Mire | Dexterity, Luck |
  | Crows | Strength, Dexterity |
  | Penitents | Wisdom, Intelligence |
- **A nemesis** loses its rule for you.

### Subclan gifts: the clan's offers, nothing more

- From **Trusted**, a clan's offers can also bring its subclans' gifts, from the subclans that are your friends (v3's table still holds). You pick one like any gift, and **it stays for the run.**
- What makes it different is only what it does: it twists the clan's rule. So it works while that clan is your patron, and sleeps otherwise.

**How stacking stays in check, with no slots:**
1. Each gift twists a different part of the rule (trigger, payoff, cost).
2. The rule's caps stay, and no gift lifts one:
   - the Watchfire holds at most half your max health;
   - the Rot adds 5% per strike;
   - Pain never takes the last point;
   - the deck has six faces.

   The Ossuary Warden is the one gift that names a new cap for its rule, and it does so on purpose.
3. One of each: a gift you hold that comes back at Sworn rises to rank II (+50% to its number), and no further.
4. Rarity:
   - a subclan's first gift is uncommon, from Trusted;
   - its second is rare, from Sworn;
   - the minor patrons' and the Open Hand's are epic.

   At most one of an offer's three suitors is a subclan gift.
5. When two gifts touch the same number, the second adds half.

## The other rules (as accepted in v4)

### Dominion: the Writ of Order
- **Rule.** Each roll takes a face that hasn't come up yet in this run of six; when all six have come up, the deck is shuffled again. The sixth face of a run, the **Verdict**, counts half again.
- **Why you build differently.** A weak face is certain to come up, so you leave none on the die. You plan around what's left and where the Verdict falls.
- **Measured.**
  - 64.6% (+10), 14.3 rounds; with the Tide, 65.2% / 10.7.
  - The deck alone wins 58.8%. Much of the gain is the even odds: skill faces rise from 38% to 49% of rolls.
  - **Suggested:** Verdict at ×1.25.
- **Subclan gifts:**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Order | **Knight of the Flame** | warrior | The Verdict strikes with Fire and Pierce |
  | Inquisition | **Inquisitor** | mage | You see the next face of the deck; the Verdict weakens |
  | Tribunal | **Magistrate** | any | Once a fight, send the face you drew to the bottom of the run and draw again |
- **Alternative, not the default: Judgment.** Every third round is a Judgment: the face you roll counts double (damage, block, healing). The other two rounds, your strikes deal 15% less.
  - Measured: 63.5%, 15.3 rounds; with the Tide, 64.8% / 10.9.
  - It fits the Dominion's law, and it mirrors the Writ that silences skill faces every third round.
  - If chosen, its gifts are Knight of the Flame (a Judgment strike is Fire and Pierces), Inquisitor (a Judgment strike weakens) and Magistrate (call the Judgment a round early).

### Compact: Thornplate
- **Rule.** Half of every blow your block, parry and armour stop goes back to the striker; you can't dodge.
- **Measured.**
  - 53.9% (−1), 12.0 rounds, thorns 29% of your damage.
  - With the Tide: 50.5% / 10.0.
  - Sending back the whole blow: 61.4%.
- **Subclan gifts:**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Quarrymen | **Stonebreaker** | warrior | A blow sent back breaks the striker's guard |
  | Scaffolders | **Trapwright** | ranger | The first blow sent back each fight stuns |
  | Emberwives | **Ember Adept** | mage | Blows sent back are Fire |

### Mire: the Rot
- **Rule.** Strikes deal 20% less; each one that lands adds a lasting, stacking poison (5% of the full strike, every turn).
- **Measured.**
  - 60.1% (+6), 14.6 rounds, rot 26% of your damage.
  - With the Tide: 53.4% / 11.3.
- **Subclan gifts:**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Barkbleeders | **Fever Blade** | rogue | A falling enemy's rot passes to the next |
  | Heron's Wake | **Fen Guide** | ranger | A rotting enemy hits 15% softer |
  | Moss Choir | **Moss Singer** | cleric | Each rot tick heals you a fifth of it |

### Crows: Blood Price (the berserk)
- **Rule.** Every Attack face is a Pain strike: it hits for double and costs 8% of your max health (never the last point). Below half health, strikes deal 25% more.
- **Measured.**
  - 62.9% (+8), 11.8 rounds, 119 health paid per fight.
  - With the Tide: 65.4% / 9.2.
  - **Suggested:** Pain at ×1.75.
- **Subclan gifts:**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Tar-Hands | **Tar Bleeder** | rogue | The life cost becomes a bleed on the enemy, and you pay half |
  | Brig-Born | **Corsair** | ranger | A kill heals 10% of your max health |
  | Whisper Ledger | **Ledger Knife** | rogue | A Pain strike steals gold; below a quarter health, strikes Pierce |

### Penitents: the Ash Well
- **Rule.**
  - Each fight starts with 0 mana.
  - Mana faces give double.
  - Spells cost 1 less.
  - Mana left after a win heals you 2% of max health per point.

  Today mana already comes back mid-fight only through Mana faces and mana skills, as in your example. The Well adds the empty start.
- **Measured.** 55.4% (+1), 17.2 rounds. The autoplay keeps one Mana face; with two, an estimated +3 to +6 for casters.
- **Subclan gifts:**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Ember Sisters | **Ember Sister** | cleric | Mana past full becomes block |
  | Spire-Fallen | **Penitent Knight**, the holy warrior | warrior | Attack faces also give 1 mana; mana left after a win heals double |
  | Scorched Choir | **Ash Chorister** | mage | A spell cast from a full Well hits 50% harder |

### The minor patrons, and the Open Hand
- **The Pit: Clause in Blood.** A spell you can't afford is paid in health while above half. 54.2%. Its gift, once its pact is held: **Dark Knight** (warrior), whose blood-paid spells heal for a share of their damage.
- **The Choir: The Vow.** No potions in a fight; heals heal 50% more; once a fight, a killing blow leaves you at 1. 55.9%. Its gift, once its vow is held: **Paladin**, so that when the Vow saves you, it lifts every affliction.
- **The Open Hand: Your Own Hand.** Once a round, reroll the die. 59.5%; with the Tide, 59.9% / 10.9.
  - It is raised by the banner.
  - Its passive is +1 to your strongest stat.
  - Its offers can bring back any subclan gift you passed on.

## Who each rule suits

How each rule moves the win rate for each profession and race against today's game, without the Tide (200 runs). Today's rates:
- by profession: cleric 74, mage 63, ranger 54, rogue 49, warrior 37;
- by race: elf 51, human 50, voidkin 58, dwarf 58, orc 52.

| Rule | Suits best | Suits least |
|---|---|---|
| Writ of Order | rogue +16, cleric +13; elf +13, dwarf and orc +12 | mage +5; voidkin +7 |
| Watchfire | ranger +12, rogue +11, warrior +9; dwarf +15 | cleric +3; elf, human and voidkin +6 |
| Thornplate | cleric +15, warrior +6; orc +4 | ranger −14, rogue −6 (no dodge); voidkin −5, human −2 |
| Rot | cleric +17, ranger +7, warrior +6; elf +10 | mage −2; voidkin +1 |
| Blood Price | cleric +14, warrior +12; orc +12, elf +11 | mage +5; dwarf +6, human +7 |
| Ash Well | small for all with the autoplay's single Mana face: cleric +2, mage +3 | rogue, warrior ±0 |
| Clause in Blood | ±1 for all (few spells known) | — |
| The Vow | rogue +5, warrior +3; human +5 | cleric, mage ±0 |
| Your Own Hand | rogue +8, warrior +6, ranger +5; elf and voidkin +6 | cleric +3, mage +4 |

- **Clerics gain under most rules:** their long, sustained fights let a rule's effect add up.
- **Warriors**, the weakest profession today, gain most under Blood Price (+12) and the Watchfire (+9).
- **Thornplate costs the dodging professions** (ranger, rogue).

## Measured: the full table

**Setup:**
- 200 seeded runs per line, 40 per profession, random strategy.
- Rules and the Tide were added through a temporary patch of the fight simulator, kept in the Core session's scratchpad as `v4_rule_sim.patch` and never committed.
- The autoplay doesn't rebuild its die for a rule, so each line shows a player who doesn't adapt.

| Line | Win | Rounds | Win by profession (cl / ma / ra / ro / wa) |
|---|---|---|---|
| Today | 54.5% | 16.6 | 74 / 63 / 54 / 49 / 37 |
| Tide | 54.5% | 11.2 | 52 / 62 / 60 / 57 / 42 |
| Writ of Order (Verdict ×1.5) | 64.6% | 14.3 | 87 / 68 / 64 / 65 / 46 |
| Watchfire | 63.1% | 17.2 | 77 / 69 / 66 / 60 / 46 |
| Thornplate | 53.9% | 12.0 | 88 / 64 / 40 / 42 / 43 |
| Rot 5% | 60.1% | 14.6 | 91 / 61 / 60 / 53 / 43 |
| Blood Price | 62.9% | 11.8 | 88 / 68 / 61 / 56 / 49 |
| Ash Well | 55.4% | 17.2 | 76 / 66 / 55 / 49 / 37 |
| Clause in Blood | 54.2% | 16.4 | 74 / 62 / 54 / 49 / 37 |
| The Vow | 55.9% | 17.1 | 74 / 62 / 54 / 54 / 40 |
| Your Own Hand | 59.5% | 15.7 | 77 / 67 / 59 / 57 / 43 |
| Tide + Writ of Order | 65.2% | 10.7 | 70 / 66 / 68 / 68 / 56 |
| Tide + Watchfire | 62.5% | 11.6 | 56 / 67 / 71 / 67 / 53 |
| Tide + Thornplate | 50.5% | 10.0 | 55 / 65 / 43 / 44 / 46 |
| Tide + Rot | 53.4% | 11.3 | 51 / 62 / 57 / 57 / 40 |
| Tide + Blood Price | 65.4% | 9.2 | 73 / 67 / 67 / 65 / 56 |
| Tide + Your Own Hand | 59.9% | 10.9 | 58 / 67 / 66 / 61 / 48 |

## Kept from v2.1 and v3

How the kept parts tie in:
- Your **patron** gives the rule and the passive stats.
- Subclan gifts come in the clan's offers from Trusted.
- A **nemesis** loses its rule and passive for you until you reconcile, can't be your patron, and its subclans' gifts stop coming. The ones you hold sleep.
- Taking a clan's gifts raises its **power**.
- **Alignment** stays separate.

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

1. **The Tide**, alone first, measured on its own.
2. **Free the mana face, and one verb per skill** (Narrative rewords the texts **[N]**). The simulator report tracks the spread of skills in play.
3. **The six rules**, the patron choice at the camp, and a committed per-rule simulator report.
4. **The patron's passive stats per level.**
5. **Subclan gifts** in the clans' offers: the first 18 above, named by **[N]**.
6. Power, territory and the nemesis, afterwards.

## Open questions for the user

1. **The Watchfire:** does it play the way you meant?
2. **When a rule turns on:** from Friendly, or only from Trusted? (Open.)
3. **Sidegrade or reward?** At the measured numbers, a rule wins up to +10 over today. (Open.)
4. **The Tide:** from round 8, you +20% and enemies +10% per round. Is that the right feel?
5. **Skills:** free the mana face, and one verb per damage skill (the 13 above first)?
