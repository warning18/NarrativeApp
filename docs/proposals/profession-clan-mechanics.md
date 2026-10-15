# Clan rules, v4.1: one signature rule per clan, short fights, more skills in play (Core, proposal)

v4.1 updates v4 with three directions from the user:
- **"You don't wear cards, they accumulate like today (cards are basically clans offer)"**, and *"What is the difference between cards and clan offers? They should be the same thing."* There is no difference any more: **the word "card" is gone.** A subclan's twist on its clan's rule is simply one more **gift in that clan's offers**, picked and kept like every gift today.
- **"I don't want too long fights."** Today's fights grow from 7 rounds in chapter 1 to 30 in chapter 7. v4.1 adds **the Tide**, one rule for every fight, which brings the average down from 16.6 rounds to 11 at the same win rate. It also replaces the two clan rules that made fights longer.
- **"You may also propose specifics to improve skill diversity of play."** The data and six specific changes are under *More skills in play*.

Already validated and kept:
- each clan's solo signature rule (v4);
- today's offer system, with the dice built freely by the player;
- passive stat points per level.

Proposal only; nothing is built. **[N]** Narrative, **[UX]** UX.

## At a glance

| Clan | Signature rule | What changes | Risk / reward | Win / rounds with the Tide (today: 54.5% / 16.6, with the Tide alone: 54.5% / 11.2) |
|---|---|---|---|---|
| **Dominion** | **Judgment** | Every third round is a Judgment: your face counts double. The other rounds, your strikes deal 15% less | Two weak rounds for one decisive round | 64.8% / 10.9 |
| **Vigil** | **Open Eyes** (the die as a deck) | Each face comes up once before any comes twice; you **see the next face**; the sixth face of a run, the Verdict, counts half again | No luck, a weak face is certain / you plan every round | 65.2% / 10.7 |
| **Compact** | **Thornplate** | Half of every blow your block and armour stop goes back to the striker; you can't dodge | Poison and spells pass the plate / defence becomes damage | 50.5% / 10.0 |
| **Mire** | **The Rot** | Strikes deal 20% less; each one that lands adds a lasting, stacking poison (5% of the full strike, every turn) | Little burst / every hit keeps working | 53.4% / 11.3 |
| **Crows** | **Blood Price** (the berserk) | Every Attack face is a Pain strike: double damage, 8% of your max health; below half health, strikes deal 25% more | You can bleed out / the heaviest, fastest fights | 65.4% / **9.2** |
| **Penitents** | **The Ash Well** | Each fight starts with 0 mana; Mana faces give double; mana past full **burns** the enemy; spells cost 1 less; mana left after a win heals | A die without Mana faces does nothing / big rounds and healing | 61.5% / 10.0 |
| *Pit* | *Clause in Blood* | A spell you can't afford is paid in health, 5% of your max health per missing mana, while above half | life for power | 54.2% (measured without the Tide) |
| *Choir* | *The Vow* | No potions in a fight; heals heal 50% more, and healing past full strikes the enemy; once a fight, a killing blow leaves you at 1 | no safety net / the Vow holds you once | 58.1% / 11.4 |
| *Open Hand* | *Your Own Hand* | Once a round, reroll the die | — | 59.9% / 10.9 |

**What changed from v4:**
- Vigil's **Long Watch** (block that stays) made the longest fights, 19 rounds. It is dropped.
- The **deck** moves to the Vigil as *Open Eyes*. It already reads the enemy's intent through its Sworn boon, so now it reads its own die too.
- **Dominion** takes **Judgment**: the law strikes on its own beat, and it mirrors the Writ, which silences skill faces every third round.
- The **Ash Well** and the **Vow** turn their surplus into damage, so they end fights instead of stretching them.

## Short fights: the Tide

**Today** (200 simulated runs, all professions):
- Average 16.6 rounds per fight.
- By chapter: 7.3 in chapter 1, 13.3 in chapter 3, 18.7 in chapter 5, **30.3** in chapter 7.
- Bosses: 18.1.
- **One fight in three lasts more than 15 rounds, and one in seven more than 25.**

**The Tide, one rule for every fight:**
- From round 8, the tide rises each round: **your blows +20%, the enemies' +10%**, adding up. At round 10 you hit +60% and they hit +30%.
- The fight screen shows the tide's level beside the round count **[UX]**.
- It needs no change to enemies or numbers elsewhere.

| | Today | With the Tide | Tide at +20% for both sides | Enemies at −25% health from chapter 4 instead |
|---|---|---|---|---|
| Win | 54.5% | **54.5%** | 46.8% | 62.9% |
| Rounds per fight | 16.6 | **11.2** | 10.4 | 14.7 |
| Fights over 25 rounds | 14.5% | **1.1%** | 0% | 11.2% |
| Chapter 7 / bosses | 30.3 / 18.1 | **16.6 / 12.1** | 13.9 / 11.0 | 28.6 / 15.8 |
| Win by profession (cleric / mage / ranger / rogue / warrior) | 74 / 63 / 54 / 49 / 37 | **52 / 62 / 60 / 57 / 42** | 35 / 61 / … | 83 / 73 / 64 / 57 / 43 |

What the comparison shows:
- **The Tide keeps the win rate and cuts long fights.** Fights over 25 rounds go from 1 in 7 to 1 in 100.
- **It narrows the gap between professions.** Today clerics win twice as often as warriors, by outlasting every fight; with the Tide the spread drops from 37 points to 20.
- **Cutting enemy health only helps the early chapters.** Chapter 7 stays at 29 rounds.
- **Every clan rule stays short under the Tide:** 9.2 to 11.4 rounds.

**Target for later tuning:** an average of 10 to 12 rounds, bosses at 12 or fewer, and no fight past 20 except a rare boss. If chapter 7 is still long (16.6) after the Tide, its enemies' health is the next lever.

## More skills in play

**Today** (every skill face rolled, 200 runs):
- 92 different skills come up, but they spread like **only 17 equally used skills**.
- The top 10 take 62% of rolls.
- **39 skills come up under 0.2% of the time**, among them Execute, Meteor, Fireball, Power Strike, Whirlwind, Multi-Shot, Shield Bash, Poison Blade, Iron Will and Second Chance.

| Most rolled | Share of skill rolls |
|---|---|
| Prayer (cleric) | **18.2%** |
| Entropy Touch (voidkin) | 7.3% |
| Celestial Ward | 5.9% |
| Hallowed Sanctuary | 5.2% |
| Channel (mage) | 5.1% |
| Backstab | 5.1% |

**Why:**
1. **The fixed mana face.** Prayer and Channel sit on a fixed face of the starting die, so they take 23% of every skill roll without anyone choosing them.
2. **Most damage skills differ only by their numbers** (damageMod, damageMultiplier). The biggest number wins: Entropy Touch, at ×1.6 +12 with poison, beats Fireball at ×1.5 +5 every time.
3. **The epic skills reach few runs, and late.**
4. **There are only three statuses** (poison, stun, weaken).

**The proposals:**

1. **Free the mana face.** The Channeling face is fixed only until the die holds a second source of mana (a Mana face, or a mana skill set elsewhere). From then on it can take any skill. Evidence: in the runs where mana works differently (the Ash Well, the deck), Prayer falls from 18% to 8–9%, and the spread widens from 17 to 25 equally used skills.

2. **One verb per skill:** each damage skill gets one thing it alone does, built from existing keywords and conditions (face_keywords.dart, statuses), so two skills of similar numbers play differently.

   | Skill | Its verb |
   |---|---|
   | Power Strike | Steady (+2, never misses its number) |
   | Execute | Double against an enemy under 30% health |
   | Whirlwind | Cleave: every enemy takes a share |
   | Fireball | Fire, with half its damage on the others |
   | Meteor | Lands next round, on every enemy, for double |
   | Multi-Shot | Three hits of 40%; each hit counts as a hit (poison, lifesteal, mana on hit) |
   | Backstab | Double against a stunned or weakened enemy |
   | Aimed Shot | Pierce |
   | Hammer Blow | Growth: +2 each time it lands in a fight |
   | Poison Blade | Its poison stacks |
   | Iron Will | Block equal to what it heals |
   | Second Chance | Heals double below a quarter health |
   | Smite | Double against Evil |

   Narrative rewords the skill texts **[N]**. Not simulated: the autoplay picks skills by their numbers.

3. **Each rule lifts different skills**, so each clan's runs play with a different set:

   | Rule | Skills it makes the best picks |
   |---|---|
   | Judgment | the single big hits (Execute, Meteor, Smite) |
   | Open Eyes | a die with no weak face; Steady faces; Shield Bash, timed against a wind-up you see coming |
   | Thornplate | Defend skills (Bulwark Stance, Iron Stance, Stoneskin) and Shield Bash |
   | Rot | many small hits (Multi-Shot, Poison Blade, Entropy Touch) |
   | Blood Price | Berserk Rage, Bloodlust, Reaping Whirl, lifesteal, Second Chance |
   | Ash Well | Channel, Mana Shield, Mana faces, spells |

   **A clan's skill gifts lean on the skills its rule lifts** (v3's lean, now with a reason).

4. **The fresh face.** The first time each face of your die comes up in a fight, it counts half again (damage, block, healing). Six different faces then beat three copies of your best. Measured: 64.1% (+10) without the Tide, and 63.4% / 10.7 rounds with it. The autoplay doesn't rebuild its die for it, so it only shows the strength. **Suggested at +25%.** This one is optional: it overlaps with the rarity limits a die already has.

5. **An epic skill within reach.** From chapter 4, each chapter's first clan offer includes one epic skill of your branches that your die doesn't have yet.

6. **Report it.** The simulator report gains the spread of skills in play (the "17 equally used" number) as a tracked figure, so each change can show it moved. Target: 25 or more.

## How a rule works in play

- **Your patron's rule is yours.** Your patron is the main clan you stand best with, at Friendly (12+) or better. You choose your patron at the camp among the clans that are Friendly, or none to fight by today's rules. The fight screen names the rule under the die **[UX]**.
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
- **A nemesis** loses its rule for you (see below).

### Subclan gifts: the clan's offers, nothing more

- **There is no separate card system.** From **Trusted**, a clan's offers can also bring its subclans' gifts, from the subclans that are your friends (v3's table of how each becomes your friend still holds). Such a gift comes up as one of the offer's three suitors, beside its skills, signs, objects and titles. You take it the same way, and **it stays for the run, like every gift.**
- **What makes it different is only what it does:** it twists the clan's rule. So it works while that clan is your patron, and sleeps if you change patron. Changing patron costs you those gifts' effects; staying loyal pays.

**How stacking stays in check, with no slots:**
1. **Each gift twists a different part of the rule** (its trigger, its payoff, its cost), so three gifts combine into a build instead of multiplying one number.
2. **The rule's caps stay:**
   - the Rot adds 5% per strike;
   - Pain never takes the last point;
   - the deck has six faces;
   - the Tide is the same for everyone.

   No gift lifts a cap.
3. **One of each.** Offered again at Sworn, a gift you hold rises to rank II (+50% to its number), and no further.
4. **Rarity sets how often each comes up**, as for skills:
   - a subclan's first gift is uncommon, from Trusted;
   - its second is rare, from Sworn;
   - the minor patrons' gifts and the Open Hand's are epic.

   At most one of an offer's three suitors is a subclan gift.
5. **When two gifts touch the same number, the second adds half.**

## The six rules

### Dominion: Judgment
- **Rule.** Every third round is a **Judgment**: the face you roll counts double (damage, block, healing). The other two rounds, your strikes deal 15% less.
- **Why you build differently.** Every face must be worth doubling, so a die of big single hits and solid guards beats a die of small tricks. Two quiet rounds, then the law falls.
- **Measured.**
  - With the Tide: 64.8% (+10), 10.9 rounds.
  - Without it: 63.5%, 15.3 rounds.
  - **Suggested:** Judgment at ×1.75 (estimate: +6).
- **Subclan gifts (twists):**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Order | **Knight of the Flame** | warrior | A Judgment strike is Fire and Pierces |
  | Inquisition | **Inquisitor** | mage | A Judgment strike also weakens |
  | Tribunal | **Magistrate** | any | Once a fight, call the Judgment one round early |

### Vigil: Open Eyes (the die as a deck)
- **Rule.**
  - Each roll takes a face that hasn't come up yet in this run of six, and you **see the next face** before it comes.
  - When all six have come up, the deck is shuffled again.
  - The sixth face of a run, the **Verdict**, counts half again.
- **Why you build differently.**
  - Luck can't save you, since a weak face is certain to come up, so you leave no weak face on the die.
  - You plan the round ahead: a Shield Bash next turn, against the wind-up you see coming. A Heal face used early means none until the next run.
- **Measured.**
  - With the Tide: 65.2% (+11), 10.7 rounds.
  - Without it: 64.6%, 14.3 rounds; the deck alone, 58.8%.
  - Much of the gain comes from the even odds: skill faces rise from 38% to 49% of rolls.
  - **Suggested:** Verdict at ×1.25 (estimate: +6).
- **Subclan gifts (twists):**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Last Watch | **Riposte** | warrior | A blow your block stops fully goes back to the striker in full (measured as a rule: 59.4% / 11.2 rounds with the Tide) |
  | Candlebearers | **Ossuary Warden** | cleric | The Verdict also heals you 10% |
  | Stitchers | **Stitcher** | rogue | Once a fight, swap the next two faces of the deck |

### Compact: Thornplate (armour becomes thorns)
- **Rule.** Half of every blow your block, parry and armour stop goes back to the striker. Heavy plate: you can't dodge.
- **Why you build differently.** Defend faces and armour become damage. You want to be hit.
- **The risk.** Poison, spells and enemies that guard, heal or wind up never touch the plate.
- **Measured.**
  - With the Tide: 50.5% (−4), 10.0 rounds, thorns 23% of your damage.
  - Without it: 53.9%, 12.0 rounds. Sending back the whole blow: 61.4%.
  - **Suggested:** two thirds back (estimate: +1 with the Tide).
- **Subclan gifts (twists):**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Quarrymen | **Stonebreaker** | warrior | A blow sent back breaks the striker's guard |
  | Scaffolders | **Trapwright** | ranger | The first blow sent back each fight stuns |
  | Emberwives | **Ember Adept** | mage | Blows sent back are Fire (they set off element reactions) |

### Mire: The Rot
- **Rule.** Your strikes deal 20% less. Each strike that lands adds a lasting poison (5% of the full strike, every turn, all fight), stacking with what is there.
- **Why you build differently.** Many small hits beat one big hit, and early hits beat late ones. Multi-Shot, with its new verb, becomes the Mire's best friend.
- **Measured.**
  - With the Tide: 53.4% (−1), 11.3 rounds, rot 16% of your damage.
  - Without it: 60.1%, 14.6 rounds.
  - At 10% per strike: 66.4% (too strong).
- **Subclan gifts (twists):**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Barkbleeders | **Fever Blade** | rogue | When a rotting enemy falls, its rot passes to the next |
  | Heron's Wake | **Fen Guide** | ranger | A rotting enemy hits 15% softer |
  | Moss Choir | **Moss Singer** | cleric | Each rot tick heals you a fifth of it |

### Crows: Blood Price (the berserk)
- **Rule.** Every Attack face is a Pain strike: it hits for double and costs 8% of your max health (never the last point). Below half health, your strikes deal 25% more.
- **Why you build differently.** Attack faces become the heavy blows. Few Defend faces; lifesteal or one Heal face to ride the line. Low health is where you're strongest.
- **Measured.**
  - With the Tide: 65.4% (+11) and the **shortest fights, 9.2 rounds**; about 97 health paid per fight.
  - Without it: 62.9%, 11.8 rounds.
  - **Suggested:** Pain at ×1.75 under this rule (estimate: +5).
- **Subclan gifts (twists, the user's examples):**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Tar-Hands | **Tar Bleeder** | rogue | The life cost becomes a bleed on the enemy (poison equal to the cost), and you pay half |
  | Brig-Born | **Corsair** | ranger | A kill heals 10% of your max health |
  | Whisper Ledger | **Ledger Knife** | rogue | A Pain strike steals gold; below a quarter health, strikes Pierce |
- **Could also be** the Pit's rule. The Crows would then take *Double or Nothing*: once a round, reroll; the new face counts double, or the turn is lost if the same face comes up. Not simulated.

### Penitents: The Ash Well
- **Rule.**
  - Each fight starts with 0 mana.
  - Mana faces give double.
  - Mana past full **burns** the enemy, for half your strike per point.
  - Spells cost 1 less.
  - Mana left after a win heals you 2% of your max health per point.

  Today mana already comes back mid-fight only through Mana faces and mana skills, as in the user's example. The Well adds the empty start and turns the surplus into damage.
- **Why you build differently.** Two Mana faces are the engine; you spend on spells, burn the surplus, or keep it to heal after.
- **Measured.**
  - With the Tide: 61.5% (+7), 10.0 rounds, but **clerics 96%**: Prayer feeds the Well too well.
  - Without it: 58.7%, 12.1 rounds, and 25 equally used skills instead of 17.
  - **Suggested:** mana skills (Prayer, Channel) don't double, only Mana faces do (estimate: clerics about 75%).
- **Subclan gifts (twists):**

  | Subclan | Gift | For | Twist |
  |---|---|---|---|
  | Ember Sisters | **Ember Sister** | cleric | The burn also cleanses one affliction |
  | Spire-Fallen | **Penitent Knight**, the holy warrior | warrior | Attack faces also give 1 mana |
  | Scorched Choir | **Ash Chorister** | mage | A spell cast from a full Well hits 50% harder |

## The minor patrons, and the Open Hand

- **The Pit: Clause in Blood.** A spell you can't afford is paid in health, while you're above half. 54.2% (+0) without the Tide; few autoplay heroes know spells. Its gift, once its pact is held: **Dark Knight** (warrior), whose blood-paid spells heal you for a share of their damage.
- **The Choir: The Vow.** No potions in a fight; heals heal 50% more, and healing past full strikes the enemy; once a fight, a killing blow leaves you at 1. With the Tide: 58.1% / 11.4 rounds. Its gift, once its vow is held: **Paladin** (warrior or cleric), so that the first time the Vow saves you, it lifts every affliction.
- **The Open Hand: Your Own Hand.**
  - Once a round, reroll the die. With the Tide: 59.9% / 10.9 rounds.
  - It is raised by the banner. Once raised, it can be your patron like a main clan: its passive is +1 to your strongest stat.
  - Its offers can bring back any subclan gift you passed on. The gift works under its own clan's rule.

## Measured: the full table

**Setup:**
- 200 seeded runs per line, 40 per profession, random strategy.
- Rules and the Tide were added through a temporary patch of the fight simulator. It is not committed; it is kept in the Core session's scratchpad as `v4_rule_sim.patch`.
- "Taken" is blows landed on the hero per fight.
- The autoplay doesn't rebuild its die for a rule, so each line shows a player who doesn't adapt.

| Line | Win | Rounds | Taken | Win by profession (cl / ma / ra / ro / wa) |
|---|---|---|---|---|
| Today | 54.5% | 16.6 | 440 | 74 / 63 / 54 / 49 / 37 |
| **Tide** | 54.5% | 11.2 | 432 | 52 / 62 / 60 / 57 / 42 |
| Tide + Judgment | 64.8% | 10.9 | 396 | 65 / 67 / 69 / 70 / 54 |
| Tide + Open Eyes (Verdict ×1.5) | 65.2% | 10.7 | 393 | 70 / 66 / 68 / 68 / 56 |
| Tide + Thornplate | 50.5% | 10.0 | 419 | 55 / 65 / 43 / 44 / 46 |
| Tide + Rot 5% | 53.4% | 11.3 | 427 | 51 / 62 / 57 / 57 / 40 |
| Tide + Blood Price | 65.4% | 9.2 | 333 | 73 / 67 / 67 / 65 / 56 |
| Tide + Ash Well | 61.5% | 10.0 | 318 | 96 / 64 / 60 / 56 / 42 |
| Tide + Vow | 58.1% | 11.4 | 430 | 56 / 63 / 63 / 63 / 46 |
| Tide + Your Own Hand | 59.9% | 10.9 | 417 | 58 / 67 / 66 / 61 / 48 |
| Tide + Riposte (Vigil gift) | 59.4% | 11.2 | 415 | 57 / 65 / 68 / 62 / 46 |
| Tide + fresh face (+50%) | 63.4% | 10.7 | 417 | 58 / 67 / 71 / 68 / 54 |

Without the Tide, for reference:

| Rule | Win | Rounds |
|---|---|---|
| Judgment | 63.5% | 15.3 |
| Open Eyes (Verdict ×1.5) | 64.6% | 14.3 |
| Thornplate | 53.9% | 12.0 |
| Rot | 60.1% | 14.6 |
| Blood Price | 62.9% | 11.8 |
| Ash Well | 58.7% | 12.1 |
| Long Watch (v4, dropped) | 53.4% | 19.0 |

## Kept from v2.1 and v3

How the kept parts tie in:
- Your **patron** gives the rule and the passive stats.
- Subclan gifts come in the clan's offers from **Trusted**.
- A clan that becomes your **nemesis** loses its rule and passive for you until you reconcile, and can't be your patron. Its subclans' gifts stop coming, and the ones you hold sleep.
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

1. **The Tide**, alone first. It is the smallest change with the biggest effect on fight length, and is measured on its own.
2. **Free the mana face, and one verb per skill** (Narrative rewords the skill texts **[N]**). The simulator report tracks the spread of skills in play.
3. **The six rules**, the patron choice at the camp, and a committed per-rule simulator report.
4. **The patron's passive stats per level.**
5. **Subclan gifts** in the clans' offers: the first 18 as above, with names and lines by **[N]**.
6. Power, territory and the nemesis, afterwards.

## Open questions for the user

1. **The Tide:** from round 8, you +20% and enemies +10% per round. Is that the right feel, or should it start earlier or later?
2. **The swap:** the deck goes to the Vigil (Open Eyes) and Judgment to Dominion. Do you agree?
3. **Skill verbs:** go ahead with one verb per damage skill (the 13 above first), and free the mana face?
4. **Rule strength:** at the suggested numbers, a player who doesn't adapt wins up to +6 over today. Should rules be sidegrades, or should loyalty to a clan be rewarded more?
