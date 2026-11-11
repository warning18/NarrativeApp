# Tower mechanics review (Core)

The user: "Review also game mechanics", Tower mode first. This review
covers the loop as played today, the dice in fights, and the bugs found.
Each finding gives what is wrong, the evidence, a severity, a proposed fix
and its cost. They are ranked at the end. **Proposal only: no code or
numbers change until the user picks.**

**Method.**
- Measured on main at v1.906 with the Tower bot (`playTowerRun`, the
  headless fight `simulateSimFight`), plus local variants of its choices.
- Runs: 2,000 seeds with no unlocks ("none") and with all unlocks ("all").
  The per-clan, per-unlock and per-die batches used 500 to 1,000 seeds.
- The die figures are exact sums over each die's faces.
- Every claim about the code was checked at the line cited.
- QA's real-UI playthrough of v1.906 is folded in §4.

## 0. Already fixed (PR #948, v1.910)

- **A warden or boss won locked the run.** After floor 5's warden (and 10,
  15…), "Victory! Return" stayed disabled under an endless spinner, so no
  run could pass floor 5 in the real app. Found by QA. Two causes, both
  fixed:
  - A Tower fight queued the story's clan offer.
  - The offer dialog read the root's session, not the caller's.
- **The Level Up had no way back but the arrow** (the user's phone report).
  It now ends on "Continue the climb".

## 1. The loop as played today

### 1.1 Difficulty curve

| | none | all |
|---|---|---|
| Runs won (top floor cleared) | 12.2% | 22.6% |
| Median floor reached | 17 | 19 |
| Reach floor 20 | 36.2% | 46.9% |

Death rate per floor entered (none):

| Floors | Death rate |
|---|---|
| 1–7 | 0–1.6% |
| 8–14 | 3–8% |
| 15 (warden) | **10.8%** |
| 17 (first chapter-5 floor) | **16.5%** |
| 20 (boss) | **20.2%** |
| 21–29 | 6–9% |
| 25 (warden) | **19.5%** |
| 10 (boss) | 3.0% |
| **30 (final boss)** | **0.8%** (none), **0.0%** (all) |

- **Health entering a floor** averages 0.86–1.00 of max on every floor.
  Below 50% it happens at most 6% of the time; below 30% never.
- **What that means:**
  - Deaths are one-fight spikes (17, 20, 25), not attrition.
  - The climb's end is a formality: the final boss's extra is 0.26
    (`tower_tables.dart:268`).

### 1.2 Healing between floors

- **How much is healed:**
  - 30% of max health after each floor (`tower_tables.dart:8`,
    `tower_run.dart:523-528`), plus the max health gained from levels.
  - Potions over the bag cap are drunk at once.
- **The bag** is full (5) on 47% (none) / 57% (all) of floor entries, so
  the overflow heals often.
- **Spoils** give about 1.8 items a chest, mostly potions (0.66 a floor)
  and antidotes. The bot never uses an antidote.

### 1.3 The three cards (boons, floors 5–25)

- **Only boon floors deal three cards:** always one skill, one die and
  one spell. Every other floor offers an oath or nothing
  (`tower_rewards.dart:187-204`).
- **Win rate when the bot always takes one kind:**

  | Always takes | none | all |
  |---|---|---|
  | the spell | **13.7%** | **26.2%** |
  | the skill (the bot today) | 12.2% | 22.6% |
  | refuses (+1 mark) | 9.8% | 18.5% |
  | the die | **8.8%** | **17.1%** |

- **What that means:**
  - **The die card is worse than refusing.** It is a dead pick (§1.5 and
    §2.1 say why).
  - The spell is the best card.
  - Skills get a rarity step; dice and spells have no rarity at all.
  - The plain-fight rarity branch is never reached, because every boon
    floor is a warden or boss floor (`tower_rewards.dart:86-100`).

### 1.4 Oaths

- **How often:**
  - An oath is offered on floor 1 every time.
  - After that, on non-boon floors, 20% (none) / 31% (all), not the 35%
    meant. With no unlocks the pool of 3 clans is empty by about floor 9.
- **Never swearing:**

  | | Never swears | Always swears (bot) |
  |---|---|---|
  | none | **23.4%** | 12.2% |
  | none, mage only | **53.0%** | 10.7% |
  | all | **2.3%** | 22.6% |

  - Refusals also pay marks: 40.1 a run against 27.9.
  - With all unlocks, refusing loses, because one oath die (below) carries
    the run.
- **Swearing a clan from the start (all):** the Dominion 30.0%; the other
  five 22.7–23.2%.
- **The cause is the die swap (§1.5).** The oath matters through the die it
  brings, not through the clan.

### 1.5 The die swap (bug, high)

- **What happens:** every die gained (an oath, a die card, a start unlock)
  is equipped at once if `simDieValue` rates it higher (`_takeDie` and
  `rollBestDie`, `tower_hero.dart:224-229`).
  - The app equips the same die (`tower_session.dart:55`:
    `equippedDiceId: hero.diceId`).
  - The Tower has **no screen to choose a die** (nothing in
    `lib/screens/tower/`).
  - `sim_combat.dart:255` itself says that value "overrates some dice".
- **Evidence:**
  - A mage loses the apprentice die on floor 1. Repro: seed 14, human
    mage, no unlocks: apprentice die on floor 1, the Dominion's lantern die
    from floor 2, dead on floor 15. With oaths refused, the same seed wins.
  - Runs that end on the lantern die win 31.6% (all). Runs that end on the
    court (Mire) die win 0%, flame 0.7%, the Vigil's 1.6%, the Ossuary's
    0%.
  - Bot's die choice against the profession die:

    | | Profession die | Bot's choice |
    |---|---|---|
    | Mage fights | 99.6% | 95.5% |
    | Cleric fights | 96.2% | 92.4% |

- **Fix, recommended (a):** a die gained goes to the bag; the hero keeps
  the die it rolls. The floor screen gets "Your dice" to swap between
  fights. The bot swaps only on a `dieTrial` (the story's measured choice).
  - Cost: Core 1 PR (rule, bot), UX 1 small (the picker), then a re-band of
    the Tower's numbers.
- **Fix, cheaper (b):** keep auto-equip, but on `dieTrial` instead of
  `simDieValue`.
  - Cost: Core 1 PR. The player still has no say.

### 1.6 Level-ups

- **What a level gives:** one stat pick and +3 max health
  (`stat_rules.dart:19,23`). There are 17 picks to level 18.
- **Pick rarity:** 87% common, 9% rare, 2.3% epic, 0.6% heroic, about 20
  stat points a run.
- **Max health (none)** at floors 1 / 10 / 20 / 30: mage 15 / 35 / 58 / 81,
  warrior 29 / 50 / 75 / 99.
- **Effect on win rate:**

  | Picks | none | all |
  |---|---|---|
  | none taken | 0.1% | 1.4% |
  | the first offer always | 5.8% | – |
  | the bot's build picks | 12.2% | 22.6% |

- **Verdict: healthy, and the loop's strongest lever.** A level is felt.
  The auto-pick (offer 0) is half as good as a thought-out pick, which
  rewards the player for choosing.

### 1.7 Professions and races

- **Professions (all):** warrior 26.9%, mage 25.2%, cleric 24.8%, rogue
  21.4%, ranger 15.0%.
- **Races (none):** elf 17.6%, dwarf 17.5%, orc 11.1%, voidkin 8.3%, human
  7.3%. That is a **2.4× spread**; with all unlocks it is 30.0% (elf)
  against 14.6% (human).

### 1.8 Marks and unlocks

- **Marks a run:** none, mean 27.9, median 25 (p10 10, p90 61); all, mean
  32.5.
- **The ten unlocks** cost 210 in all. A player buying the cheapest each
  time owns **all ten after a median 7 runs** (max 12). Median run of
  purchase:

  | Run | Unlocks |
  |---|---|
  | 1 | flame die, the Crows |
  | 2 | shield, cleric |
  | 3 | tide die |
  | 4 | the Vigil, sword |
  | 5 | ranger |
  | 6 | the Compact |
  | 7 | tearglass die |

- **Each unlock alone** (baseline 11.7%, ±1 point; includes its +4%
  health):

  | Unlock | Win rate change |
  |---|---|
  | sword | +2.8 |
  | shield, the Vigil, cleric | +2.3 each |
  | flame die | +1.4 |
  | tide die | +1.3 |
  | tearglass die | +1.2 |
  | ranger | +0.9 |
  | the Crows | +0.4 |
  | the Compact | +0.1 |

- **Verdict:** the meta is short and flat. Everything is bought in about
  a week of play, and no unlock changes a run much. The dice unlocks are
  worth least (§2.1).

### 1.9 What the balance batch does not measure (bug, high for trust)

- **No clan standing.** The bot passes none to the fight
  (`tower_bot.dart:58-72`); the app does (22/23, `tower_session.dart:66`).
  The main clan's Resonance and Sworn boons are missing from every number.
  - Proof: swearing the Compact and swearing the Crows from the start give
    **identical runs on all 1,000 seeds**. Their dice (cinder, tally) are
    never rolled.
- **No affixes.** Floors 11–29 carry 1–2 each in the app; the sim gets
  none (`sim_combat.dart:64`).
- **Approximations:** the Elite is a ×1.35 multiplier; no rerolls, no
  momentum (§2.2, §2.3); antidotes unused.
- **QA's sample of real fights:** the headless fight wins 68% where the
  real one wins 43% (`docs/qa/tower-real-fight-sample.md`).
- **Fix:** pass the standing, affixes and the Elite to `simulateSimFight`
  in the bot, then re-band the guards in `qa_tower_sim_test.dart`.
  - Cost: Core 1 PR. The Tower's win bands will move (likely down on
    floors 11+).
  - **This should come first:** every tuning after it rests on it.

## 2. The dice in fights

### 2.1 Odds per die: the bigger dice are weaker (high)

- **How faces count** (`combat_engine.dart`):
  - Attack and Skill faces grow with the hero: Attack = base damage +
    value (:296); Skill = (base damage + mod) × multiplier (heavy attack
    ×1.4 + 1).
  - Defend blocks its flat value (:307). Heal heals value + Wisdom (:430).
  - So Defend and Heal faces stay at 1–5 while Attack and Skill faces grow
    every level.

Expected damage per roll at base damage 4 (sd in brackets):

| Group | Dice |
|---|---|
| Small skill dice | shadow d4 7.7 (1.8), stone d4 6.5, twinfang d4 6.4, berserker d4 6.1, storm d10 6.1 |
| Middle | starter d6 4.7 (2.6), flame d8 5.2 (3.9), lantern d6 5.1, court d8 5.0 |
| Big mixed dice | tide d8 4.2, tearglass d12 3.3 (3.5), tempest d12 2.7, gambler d20 2.7, chorus d12 2.4, sage d10 2.4, tally d12 2.0 |

- **Every d10–d20 except storm** puts 45–60% of its weight on flat Defend,
  Heal or Mana faces. Expected block is 0.2–0.7 and heal 0–1.6 a roll on
  any die.
- **Fight win rate by die** (all professions, the bot's fights on floors 1
  to 30, full health):

  | Die | Win rate | Rounds |
  |---|---|---|
  | starter | 98.3% | 6.1 |
  | storm | 97.9% | 6.1 |
  | berserker | 96.8% | 5.7 |
  | lantern | 96.6% | 6.3 |
  | the bot's own choice | 95.0% | 6.9 |
  | tide | 92.5% | 8.0 |
  | flame | 86.6% | 8.5 |
  | gambler | 86.6% | 9.3 |
  | sage | 82.8% | 9.6 |
  | tearglass | 82.1% | 9.4 |
  | cinder | 81.4% | 8.7 |
  | tally | 80.9% | 10.1 |

  On floor 30: tearglass 13%, tally 33%, the starter die 100%.
- **The Tower's dice unlocks** (flame, tide, tearglass) are all worse than
  the free starter die. Tearglass, the top of the die line (40 marks), is
  among the weakest dice in the game's top floors.
- **Caveat:** the sim places skills only on open Skill faces; the game
  allows them on any face at 70% power (`docs/simulation/starter-die.md`).
  The big dice look somewhat worse here than in a player's hands.
- **Fixes:**
  - **(a) Defend and Heal grow with the hero.** For example, Defend adds
    base armor and Heal adds a third of the level, as Attack adds base
    damage. This mends every die at once, in the story too.
    - Cost: Core 1 PR (rule), re-measure both the story's and the Tower's
      simulators. Medium risk: it touches every fight in the game.
  - **(b) Retune the faces of the big dice only:** fewer flat faces, bigger
    values.
    - Cost: Core 1 PR (data). Lower risk; the story's balance of those dice
      moves too.
  - **(c) Tower only:** rework the three Tower dice so each is a real
    side-grade of the starter die.
    - Cost: Core 1 small PR (data). Lowest risk, narrowest fix.
  - **My reading:** (c) now for the Tower; (a) or (b) as a story-wide pass
    later.

### 2.2 Rerolls and keeps (medium; a measuring gap)

- **In the real fight:** 3 rolls a round, one budget for the party
  (`fight_numbers.dart:8`). Keeping a die is free; the third roll is
  forced (`fight_rounds.dart:48-130`).
- **In the bot and Quick Resolve:** the sim rerolls only an empty face
  (`sim_fight_party_turn.dart:187`). No die has one, so the Tower bot
  **never rerolls**. Quick Resolve takes the first roll
  (`fight_quick.dart:62`).
- **What a good reroll is worth** (best of 3, optimal threshold):
  - small skill dice +8–18%;
  - big mixed dice +47–64% (tearglass +47%, gambler +55%, sage +64%).
- **What that means:** a player who rerolls well closes much of the gap
  between die sizes. The measured numbers are of a player who never does.
- **Fix:** a threshold reroll in the sim (re-roll a face below the die's
  mean, twice at most).
  - Cost: Core 1 PR in the simulator. It changes no rule but every
    measured band (story and Tower).

### 2.3 Momentum, or surge (low; nearly dead)

- **How it works:**
  - +1 a hit landed, capped at 3 (`fight_rounds.dart:477`,
    `fight_screen.dart:195`).
  - −1 for every enemy hit that wounds the hero (`enemy_intent.dart:157`).
  - Spent as a guaranteed ×1.5 crit.
- **Not in the sim.** A Markov sketch gives:
  - a solo foe that wounds 70% of rounds: one surge per about 20 rounds,
    about 3% of damage;
  - 90% of rounds: one per 176;
  - any fight with two or more foes: about zero.
- **Tower fights last** 2–20 rounds, so the player rarely sees one. Only
  the ranger's Hawk Mark and the Battle Rhythm perk lift it.
- **Fix:** lose 1 only when a hit takes more than a tenth of max health,
  or keep half on a hit taken.
  - Cost: Core 1 small PR. Small risk; a gain for the player.

### 2.4 Nothing breaks a fight

- No fight hit the 80-round cap.
- The longest was 36 rounds (sage die, seed 31, floor 20, claimant
  Morrow).
- No loops, unkillable foes or one-shot spikes were found.

## 3. Rough edges

1. **Start dice skip the profession.** `_takeDie` / `towerFreshHero`
   (`tower_hero.dart:100-104`) give every hero the flame (mage) and tide
   (cleric) dice, even while cleric is locked. The boon cards do check
   (`tower_rewards.dart:150`).
   - Fix: check the profession, or make the dice unlocks profession-free
     by design and say so.
   - Cost: a few lines.
2. **The oath chance reads 35% but plays as 20%** with no unlocks: the
   pool of three clans runs out.
   - Fix: offer a clan already sworn as a renewal (a boon), or count the
     chance only over clans left.
   - Cost: small.
3. **Faces named as blanks are skills.** "Blank Facet" (tearglass), "Open
   Grave", "Open Watch" and "Wild Card" cast Heavy Attack (10 damage at
   base damage 6).
   - Fix: rename them (Narrative), or make them what they say.
   - Cost: text only.
4. **The plain-fight rarity branch is dead code** (`towerRarityOdds`), and
   dice and spells have no rarity.
   - Fix: give the three cards one rarity roll.
   - Cost: small.
5. **Antidotes pile up unused in the bot;** the bag cap then drinks
   potions early. The real player decides.
   - Fix: none needed in the rules; the bot should use antidotes.

## 4. QA's playthrough findings

From QA's v1.906 playthrough (`docs/qa/playthrough-1.906.md`, PR #954):

- **The floor 5 lock (#949):** fixed in #948 (§0).
- **The Level Up's way back:** fixed in #948 (§0).
- **"Spare or finish" in the Tower (#956).** Beating a hunter opened the
  story's mercy dialog, which has no stakes in the Tower (no bounty, no
  alignment, no road back).
  - Fixed in #948: a Tower hunter falls like any foe.
- **Balance drift (#955).** Winning floor 30 with no unlocks is 12.2%,
  above the design band of 5–12% (it was 10.2% at v1.888; 13.2% on seeds
  10001–12000). With all unlocks it is 22.6%, inside the band of 15–25%
  (was 19.1%).
  - This matches §1.1 and §1.7: the same numbers, measured independently.
  - It does not change the ranking. Re-banding after #2 (the batch measures
    a different game) will move these numbers more than the drift. A
    retune of the late floors (#5) or a race nudge (#8) closes both.
- **A potion can be drunk at full health** (minor). Nothing stops it, and
  the charge is wasted. In the story too.
  - Fix: disable the potion when health is full.
  - Cost: a few lines (Core, fight logic); the button's look is unchanged.

## 5. Ranking

| # | Finding | Severity | Fix | Cost |
|---|---|---|---|---|
| 1 | Floor-5 lock (#949), Level Up way back, mercy question in the Tower (#956) | blocker | fixed | #948 |
| 2 | The batch measures a different game (no standing, affixes, rerolls; 68% vs 43%) | high | standing, affixes and threshold rerolls in the bot; re-band | Core 1–2 PRs |
| 3 | Auto die swap decides runs (mage 11% → 53% by never swearing) | high | a die gained goes to the bag; "Your dice" on the floor screen | Core 1 + UX 1 small |
| 4 | Big dice and the three Tower dice are worse than the starter die; the die card is worse than refusing | high | (c) rework the Tower dice now; (a)/(b) story-wide later | Core 1 small (c) |
| 5 | No attrition; spikes on 17/20/25; floor 30 trivial (0.8%), floor 10 easy (3%) | medium | heal 30% → 20%, smooth 17, raise the final boss's extra | Core 1 PR (numbers), after #2 |
| 6 | Boon cards unbalanced (spell > skill > refuse > die) | medium | one rarity roll for all three; the die card after #4 | Core 1 small |
| 7 | Refusing oaths farms marks and, for a mage, wins | medium | goes with #3; refusal pays 1 mark only on boon floors | small |
| 8 | Race spread 2.4× (human, voidkin weak); QA #955 measured the same | medium | Tower-only race starts (health, a stat) | Core 1 small |
| 9 | Meta short and flat (all in ~7 runs, each 0–3 points) | low–medium | more unlocks, or tiers (floor-starts, ascension) | Core 1–2 + UX |
| 10 | Momentum nearly dead | low | lose it only on a heavy hit | Core 1 small |
| 11 | Start dice skip the profession; oath 35% plays as 20%; "blank" faces are skills; dead rarity branch | low | §3 | small each |
| 12 | A potion can be drunk at full health (QA) | low | disable it at full health | a few lines |

**Order I'd propose:**
1. #2 first, so every later number is the real game's.
2. Then #3 and #4 together: the dice are the root of the oath and card
   imbalances.
3. Then #5 and #6 on the new numbers.
4. #8–#11 when convenient.

The story's own fights share #4 (a/b), #10 and the reroll gap; I'd run the
story simulator on any of those before shipping.
