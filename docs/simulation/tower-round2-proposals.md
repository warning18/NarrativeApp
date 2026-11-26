# Tower, round 2: the gamble card, perks that matter, the stat-pick card

Core's proposals for three of the user's requests (through the manager).
Proposals only: no rule of the game changed in this branch. The numbers come
from a local prototype (`docs/simulation/tower-round2-prototype.patch`,
prototype quality, not for merging) played by Core's bot.

Numbers: Core's bot (`playTowerRun`), seeds 1 to 2000, floor events 2, the
bot's full coins, from main v2.10.31 (f1156826). "f10 / f20 / top" = share
of climbs that reach floor 10, reach floor 20, win floor 30 (in %). "none" =
no unlocks, "all" = every unlock of the tree. The rules-3 baseline was
re-run and matches `tower-difficulty-survival.md` exactly (none 29.2 / 4.2 /
0.15, all 81.5 / 45.0 / 10.5; Heat 3 all top 4.95).

## Recommendations

1. **Ship all three as one new ruleset, rules 4**, for new climbs only. Each
   one changes what a climb is dealt or what a perk gives, so a rules-3
   climb in progress would change under the player. Rules 1, 2 and 3 stay
   as they are (every new knob read behind `rules >= 4`).
2. **A. Gamble card.** On 15% of loot tables and 15% of Level Up tables, one
   of the three cards is dealt face down. Under it: 4 good outcomes and 4 bad
   ones (70 good / 30 bad by weight). Perception 3 or more shows "good" or
   "bad"; Perception 5 or more shows what it is. Taken, it is final. Sim
   effect: small, slightly negative when played blind (as asked: "bad
   choices may appear"), about even when the hint is read. Only one small
   new effect is needed (Hex, a foe buff on the next floor).
3. **B. Perks.** Retune or redesign all eight, so each one alone adds +3.4
   to +9.4 points at floor 10 (today: +0 to +1.2) and +1.1 to +2.6 at
   floor 20. To keep "every unlock" near 10% at the top whatever perk is
   worn, the foes of floors 11 to 30 get 3% more (survival curve × 1.03).
   Result: every unlock with any one perk wins the top 9.3 to 11.3% (target
   8 to 12).
4. **C. Stat-pick card.** On 15% of Level Up tables, the die-or-spell card is
   replaced by "+1 to a stat of your choice". Outside the nudge caps (the
   player chose it; it never does nothing), and it does not count toward
   them. Rare: about 0.4 a climb with no unlocks, 0.9 with all. Small effect
   (+0.9 points at floor 10, +0.5 at the top with every unlock).

## The whole package (rules 4: A + B + C + the 1.03 offset)

| | f5 | f10 | f20 | top | median |
|---|---|---|---|---|---|
| none, rules 3 | 76.2 | 29.2 | 4.2 | 0.15 | 8 |
| none, rules 4 | 75.8 | 28.2 | 3.7 | 0.25 | 8 |
| all, rules 3 | 98.8 | 81.5 | 45.0 | 10.5 | 18 |
| all, rules 4 (no perk) | 98.8 | 81.8 | 44.0 | 9.5 | 18 |
| all, rules 4, any one perk | 98.8 | 81.7 to 84.3 | 44.5 to 50.6 | **9.3 to 11.3** | 18 to 20 |
| none, Heat 3, rules 3 | 71.5 | 20.9 | 1.5 | 0.05 | 6 |
| none, Heat 3, rules 4 | 71.3 | 20.1 | 1.1 | 0.0 | 6 |
| all, Heat 3, rules 3 | 98.3 | 76.0 | 30.4 | 4.95 | 14 |
| all, Heat 3, rules 4 | 98.4 | 76.5 | 29.9 | 3.85 | 14 |

Heat 3 still cuts the top with every unlock by about 60% (9.5 to 3.85; was
10.5 to 4.95).

---

## A. The gamble card

### What the player sees

One card of the three lies face down. Its back reads, by the hero's
Perception (PER):

| PER | The hint |
|---|---|
| 0 to 2 | nothing: "a card face down" |
| 3 or 4 | good or bad ("it feels lucky" / "something is wrong") |
| 5 or more | what it is (e.g. "a better piece of gear", "a wound") |

Picking it shows the confirm ("no change back"); then it turns over and its
outcome is given at once.

### Where and how often

| Table | Chance a table holds one | Dealt a climb (none / all) |
|---|---|---|
| Loot table | 15% | about 1.0 / 2.4 |
| Level Up table | 15% | about 0.35 / 0.85 |
| Both (counted) | | 1.33 / 3.26 |

It replaces one of the three cards, drawn at random (never an oath in
front). Pyre's empty floors deal no loot table, so no loot gamble there. A reroll deals
three face-up cards (the face-down card is the first deal's only). It
cannot be banished (only a skill, a die or a spell can).

### What can be under it

Loot table (weights, out of 100):

| Outcome | Weight | What it does | Engine |
|---|---|---|---|
| Gilded | 35 | the best piece of gear of a loot draw one chest tier up | `towerLootFor` with the tier shift +1 (new `tierBonus`) |
| Twin | 25 | both other cards of the table | `towerTakeLoot` twice |
| Hoard | 10 | 4 / 6 / 8 coins (floors 1-10 / 11-20 / 21-29) | as a purse |
| Dud | 10 | nothing (no mark: the card was taken) | none |
| Wound | 12 | lose 20% of max health now (never below 1) | `run.health` |
| Spill | 8 | lose one potion of the bag (none in the bag: 10% health) | `run.potions` |

Level Up table:

| Outcome | Weight | What it does | Engine |
|---|---|---|---|
| Bright | 35 | a skill card one rarity step up (Keen eye's step), with its nudge | `towerOfferFor(rarityBonus: 1)` |
| Twin | 30 | both other cards, each with its nudge | as two Level Up cards |
| Dud | 15 | the level is spent, no card | as a refused Level Up |
| Wound | 12 | lose 20% of max health now | `run.health` |
| Hex | 8 | the next floor's foes 15% stronger | **new**: one fight modifier |

Hex is the one new effect: a factor on the next floor's foes (the bot's
fight multiplies `zoneMultiplier` by 1.15; the app's fight launcher would
read the same from the run, `TowerFloor.modifiersFor`). If Hex is not
wanted, give its weight to Wound: the numbers below barely move (it was
dealt 44 times in 2,000 climbs).

### Perception in the Tower (the bot's heroes)

PER at the loot table, by band (no unlocks; every unlock is within 2
points):

| Floors | median | 90th percentile | max | PER 3+ | PER 5+ | PER 6+ |
|---|---|---|---|---|---|---|
| 1-10 | 1 | 5 | 8 | 20% | 18% | 2% |
| 11-20 | 2 | 5 | 8 | 42% | 17% | 9% |
| 21-29 | 3 | 7 | 8 | 54% | 20% | 11% |

At the start PER is 1 for every race and calling but the ranger (2) and the
elf (5; an elf ranger 6). It rises with the Weaken skills' nudges and some
gear. So: an elf reads what the card is from floor 1, a non-elf reads
"good / bad" by the middle of the climb, and the stat-pick card (C) is a way
to buy Perception. Thresholds 3 and 5 make that split; 2 and 5 would let
every ranger read "good / bad" from the start (not measured).

With the thresholds 3 / 5, of the gamble cards dealt (no unlocks): no hint
71%, good or bad 5%, the kind 25%.

### How the bot plays it

- Hint good, or a good kind: takes it.
- Hint bad, or a bad kind: leaves it.
- No hint: on a loot table, takes it when none of the face-up cards is a
  gear upgrade (it would have taken a bundle or a purse); on a Level Up
  table, leaves it (it takes the clan's gift, as today).

### Sim effect (the gamble alone, rules 3 otherwise)

| | f10 | f20 | top | | all f10 | all f20 | all top |
|---|---|---|---|---|---|---|---|
| rules 3 | 29.2 | 4.2 | 0.15 | | 81.5 | 45.0 | 10.5 |
| gamble, bot reads the hint | 28.2 | 3.7 | 0.30 | | 80.8 | 44.5 | 10.15 |
| gamble, bot never takes it | 28.9 | 3.8 | 0.25 | | 81.5 | 44.5 | 9.5 |
| gamble, bot always takes it | 26.7 | 2.8 | 0.35 | | 79.2 | 42.0 | 8.9 |
| Heat 3: rules 3 / gamble with hint | 20.9 / 19.9 | 1.5 / 1.2 | 0.05 / 0.10 | | 76.0 / 75.7 | 30.4 / 30.2 | 4.95 / 4.65 |

Taking it blind costs about 2 points at floor 10: the face-down card is
taken in place of the gear the table offered, and a Wound hurts in a climb
where health is everything. Reading the hint brings it back to even. With
60 / 40 weights (tried first) the blind cost was 3.5 points; lowering the
Wound to 12% changed nothing (26.9 at floor 10), so the cost is the lost
gear, not the Wound.

### Data and API sketch (for UX)

- `TowerRewardKind.gamble` (new). The card on the offer is
  `TowerReward(TowerRewardKind.gamble)` with **no id**: the outcome is kept
  apart, in `TowerRun.gambleOutcome` (new, a `TowerGambleOutcome` enum
  name, saved with the run, cleared when the table closes). It is drawn
  when the table is dealt, on a new stream (`TowerStream.gamble`, added
  last so no other draw moves): a reload deals the same card and the same
  outcome. So the screen cannot leak it by printing the card.
- `towerGambleHintOf(TowerRun run, SimCharacter hero)` →
  `TowerGambleHint { none, good, bad, kind }`, and
  `towerGambleOutcomeShown(run, hero)` → the `TowerGambleOutcome` when the
  hint is `kind`, else null. Thresholds `towerGambleHintGood` 3,
  `towerGambleHintKind` 5.
- `towerPick(run, data, index)` on the gamble resolves it and returns the
  run with `TowerRun.lastGamble` (new: the outcome, the cards given, the
  health and the potion lost) for the reveal. What it gave is saved where
  the hero rebuild already reads it: the card(s) in `loot[floor]` /
  `levelUps[floor]` (a Twin's second card in a new `gambles[floor]` list,
  applied by `towerHeroOf` with its nudge), Hex in the same list.
- The pick is final: there is nothing to undo on Core's side. "No change
  back" is the screen's confirm before the pick.
- Outcome names and lines for Narrative: `tower_gamble_<outcome>` and the
  two hint lines (good, bad).

---

## B. Perks that are felt

### Today (rules 3): each perk and each unlock alone

No unlocks but this one, or no unlocks and this perk worn (one slot).
f10 / f20 / top. The "all" case wears no perk (`towerAllUnlocked` has none;
`TOWER_PERKS` adds one).

| Unlock alone | f10 | f20 | top | | Perk alone (none) | f10 | f20 | top | | all + perk: top |
|---|---|---|---|---|---|---|---|---|---|---|
| none | 29.2 | 4.2 | 0.15 | | none | 29.2 | 4.2 | 0.15 | | 10.5 |
| flame_die | 34.0 | 6.2 | 0.55 | | purse | 29.6 | 4.2 | 0.25 | | 11.1 |
| crows | 33.6 | 6.0 | 0.35 | | deep_pockets | 29.4 | 4.7 | 0.15 | | 10.4 |
| shield_t5 | 50.6 | 10.3 | 1.05 | | early_word | 29.2 | 4.2 | 0.15 | | 10.0 |
| cleric | 38.8 | 8.6 | 0.60 | | old_friend | 29.6 | 4.2 | 0.15 | | 10.2 |
| tide_die | 33.5 | 5.5 | 0.50 | | second_wind | 29.9 | 5.0 | 0.40 | | 11.2 |
| vigil | 32.6 | 4.8 | 0.50 | | keen_eye | 30.4 | 4.1 | 0.25 | | 10.7 |
| sword_t4 | 47.6 | 8.7 | 0.85 | | free_hand | 29.1 | 4.3 | 0.15 | | 10.55 |
| ranger | 32.5 | 5.3 | 0.50 | | fourth_card | 29.1 | 4.3 | 0.25 | | 10.45 |
| compact | 33.4 | 6.0 | 0.50 | | | | | | | |
| tearglass_die | 35.1 | 6.0 | 0.40 | | | | | | | |

Every unlock is felt (+3 to +21 at floor 10); no perk is (+1.2 at most).

Why: the climbs end early on rules 3 (median floor 8), and most perks act
late or rarely. Second wind waits for floor 5; Early word's oath for floor
12; Keen eye and Fourth card act on the first one or two Level Up tables,
whose extra skill the bot does not take (it takes the clan's gift, as
today); Free hand is one reroll a climb; coins have little to buy (a
merchant on 5% of landings). What moves a climb is health, potions and
gear.

### The proposal (rules 4)

| Perk | Today | Proposed |
|---|---|---|
| Purse | 5 coins at the start | 15 coins at the start, and a **pedlar**: on any landing, a potion for 4 coins (the bag's cap) |
| Deep pockets | the bag holds 1 potion more | the bag holds 1 more **and the flask holds 2** (one more potion every fight) |
| Early word | the late oath 3 floors sooner | the same, **and 2 potions more in the flask on warden and boss floors** (warned of them) |
| Old friend | one gift of a clan at the start (standing) | the same, **and a piece of gear at the start**: the best of a loot draw two chest tiers up, the friend's gift |
| Second wind | +15% health after a warden or a boss | the same, **and +8% after every other floor** |
| Keen eye | the first Level Up table's skill a rarity step up | the same, **and loot tables one chest tier up on floors 1-10** |
| Free hand | the climb's first reroll free | **the first reroll of each table free on floors 1-10** (the bot rerolls a loot table with no gear upgrade) |
| Fourth card | the first 2 Level Up tables show a 4th card | the same, **and every loot table on floors 1-20 shows a 4th card** |

The prices stay (405 marks). Narrative rewords the eight lines.

Two things tried and dropped: **Tower XP** for Early word (5 XP at the start:
floor 10 29 to 23%, every unlock's top 10.5 to 6.4%: a level sooner makes the
foes grow sooner, `enemyScaledMaxHealth`, more than its card gives), and
**the oath sworn at the start** for Old friend (+0.7 at floor 10: a clan's
die is worth little to the bot). Purse at 25 coins alone gave +0.7 at floor 10:
coins only matter with something to buy, hence the pedlar.

### Each perk alone, rules 4 (the whole package, with the 1.03 offset)

Base: rules 4, no unlocks: 28.2 / 3.7 / 0.25; every unlock, no perk: top 9.5.

| Perk alone | f10 | f20 | top | vs none: f10 / f20 | all + perk: f10 / f20 / top |
|---|---|---|---|---|---|
| Purse | 37.6 | 6.1 | 0.40 | **+9.4 / +2.4** | 82.2 / 45.4 / 10.3 |
| Deep pockets | 36.6 | 6.3 | 0.35 | **+8.4 / +2.6** | 81.8 / 45.5 / 10.25 |
| Early word | 31.6 | 5.2 | 0.35 | **+3.4 / +1.5** | 81.8 / 44.7 / 9.5 |
| Old friend | 35.8 | 5.0 | 0.50 | **+7.6** / +1.3 | 81.7 / 44.5 / 9.25 |
| Second wind | 31.9 | 4.8 | 0.25 | **+3.7** / +1.1 | 83.1 / 47.4 / 11.2 |
| Keen eye | 34.4 | 5.5 | 0.45 | **+6.2 / +1.8** | 83.4 / 47.0 / 9.25 |
| Free hand | 31.7 | 5.7 | 0.35 | **+3.5 / +2.0** | 84.3 / 50.6 / 11.3 |
| Fourth card | 31.6 | 5.5 | 0.45 | **+3.4 / +1.8** | 82.8 / 48.2 / 10.55 |

Every perk alone is now ≥ +3 at floor 10 (target ≥ +3, or ≥ +1.5 at
floor 20). Every unlock with any one perk: 9.25 to 11.3% at the top
(target 8 to 12). The early-health perks (Purse, Deep pockets, Old friend)
help most with no unlocks and least at the top; the loot and late ones
(Second wind, Free hand, Fourth card) the other way.

### The offset

Without it, the package gives every unlock 11.3% with no perk and 11.7 to
13.9% with one (Second wind 13.9, Free hand 13.8). The offset is one knob:
`towerSurvivalScale` × **1.03 from floor 11** (rules 4 only), where the
climbs with unlocks are fought. It costs the no-unlocks climb 0.3 points at
floor 20 and nothing before floor 11.

| rules 4 | none f10 / f20 / top | all top (no perk) | all top (one perk) |
|---|---|---|---|
| no offset | 28.2 / 4.0 / 0.20 | 11.3 | 11.7 to 13.9 |
| × 1.03 from floor 11 | 28.2 / 3.7 / 0.25 | 9.5 | 9.25 to 11.3 |

### Each unlock alone, rules 4

| Unlock alone | f10 | f20 | top | (rules 3 f10 / f20) |
|---|---|---|---|---|
| none | 28.2 | 3.7 | 0.25 | 29.2 / 4.2 |
| flame_die | 34.3 | 5.5 | 0.45 | 34.0 / 6.2 |
| crows | 32.9 | 5.3 | 0.40 | 33.6 / 6.0 |
| shield_t5 | 50.1 | 8.8 | 0.60 | 50.6 / 10.3 |
| cleric | 37.0 | 6.8 | 0.30 | 38.8 / 8.6 |
| tide_die | 33.8 | 5.0 | 0.30 | 33.5 / 5.5 |
| vigil | 33.0 | 4.2 | 0.55 | 32.6 / 4.8 |
| sword_t4 | 46.8 | 7.9 | 0.75 | 47.6 / 8.7 |
| ranger | 31.4 | 4.0 | 0.25 | 32.5 / 5.3 |
| compact | 33.2 | 4.9 | 0.45 | 33.4 / 6.0 |
| tearglass_die | 35.5 | 5.3 | 0.35 | 35.1 / 6.0 |

The unlocks keep their order and their weight (+3 to +22 at floor 10); a
perk now sits among them (Purse and Deep pockets near the start items,
the others near the dice and clans).

### API

No new screen: the perks are read where they are today (`TowerRun.wears`).
New: the pedlar's action, `towerBuyPotion(run)` (Purse worn, a landing,
4 coins, the bag below its cap) and `towerCanBuyPotion(run)`; Old friend's
gear is dealt by `towerStart` (saved in `taken[0]` or a new `startGear`
field, drawn on the run's own stream, so a reload gives the same piece).

---

## C. The stat-pick card

### The proposal

- **Level Up table only**, on 15% of them: the card that would be the die
  or the spell becomes "+1 to a stat of your choice" (the clan's gift and
  the skill stay). About 0.37 a climb with no unlocks, 0.87 with all (one
  in seven Level Ups).
- **Not on the loot table.** Tried at 5% beside it: every unlock's top 10.5
  to 13.45% (long climbs see 20 loot tables or more), for +0.5 more at
  floor 10 with none.
- **Outside the nudge caps, and not counted in them.** The caps (+3 a stat,
  +6 a climb on rules 3) exist so the automatic nudges do not pile up in one
  stat; this card is the player's own choice, and a chosen +1 that does
  nothing would read as a bug. It is rare by design (under 1 a climb), so a
  stat can pass its cap by 1, rarely 2. Saved as its own card
  (`TowerReward(statPick, id: <stat>)` in `levelUps[floor]`), the hero
  rebuild adds it apart from `pickedPoints`, so the nudges' counts do not
  move.
- **Any of the eight stats.** Perception reads the gamble card (A), Luck
  the chest tier, Charisma the parleys: each has a use in the Tower.

### The bot's rule

It takes the card over a clan's gift, a skill, a die or a spell (only an
oath comes first), and puts the point in its calling's damage stat
(`preferredStat`: Strength, Dexterity or Intelligence). Taken 81% of the
times it was dealt with no unlocks (the rest: mostly an oath on the
table, which the bot takes first).

### Sim effect (the card alone, rules 3 otherwise)

| | f10 | f20 | top | all f10 | all f20 | all top |
|---|---|---|---|---|---|---|
| rules 3 | 29.2 | 4.2 | 0.15 | 81.5 | 45.0 | 10.5 |
| Level Up 15% | 30.1 | 5.0 | 0.35 | 82.0 | 46.6 | 11.0 |
| Level Up 15% + loot 5% | 30.6 | 5.0 | 0.40 | 82.4 | 48.5 | 13.45 |
| Heat 3: rules 3 / Level Up 15% | 20.9 / 21.1 | 1.5 / 1.7 | 0.05 / 0.0 | 76.0 / 76.7 | 30.4 / 33.3 | 4.95 / 5.7 |

A stat point given outside a level is worth more than a level's card: it
does not make the foes grow (a Level Up does).

### API

- `TowerRewardKind.statPick` (new); the offer card is
  `TowerReward(TowerRewardKind.statPick)` with no id.
- The pick takes the stat: `towerPick(run, data, index, stat: 'dexterity')`.
  The screen opens its stat choice when the card is picked (a step of the
  card, not a new table), with `statPickPreview` (lib/data/stat_pick_text.dart,
  `tower: true`) for each line. Without a stat (an old caller), the hero's
  damage stat. A stat the hero does not have is refused (`run` returned
  as it is).
- Stored as `TowerReward(statPick, id: stat)` in `levelUps[floor]`;
  `towerApplyReward` adds the point; `towerNudgeOn` gives it no nudge.
- The bot: `towerBotStatChoice(hero)` → `hero.preferredStat`.

---

## QA guards

Measured on the guard seeds (1 to 500) with the whole rules-4 package:

| Guard (`test/qa_tower_sim_test.dart`) | Band | rules 3 today | rules 4 | events off (rules 4) |
|---|---|---|---|---|
| `_medianFloor` (none) | 6 to 10 | 8 | 8 | 8 |
| `_floor20` (none) | 0.02 to 0.08 | 4.4% | 4.0% | 3.0% |
| `_topNone` | 0 to 0.01 | 0.0% | 0.2% | 0.2% |
| `_topAll` | 0.06 to 0.15 | 10.2% | 9.2% | 7.4% |

**No band breaks.** The guards wear no perk, so the perk retune does not
reach them; the offset and the two cards do, inside the bands. What would
move:

- `test/qa_tower_live_pin_test.dart` pins the live rules: with rules 4 live
  its pins are read again (new values, as for rules 3).
- New Core tests for rules 4 (the gamble's deal, outcomes and save; the
  stat-pick card and its stat; each perk's new effect; a rules-3 save
  finishes as before), as `tower_rules3_test.dart` did for rules 3.
- A guard worth adding (QA's call): each perk alone lifts floor 10 by at
  least 2 points over none, so a later change cannot make them invisible
  again.

## Uncertainties

- **Bot, not a player.** The bot always takes the clan's gift on a Level Up
  table, so the Level Up parts of Keen eye and Fourth card, and a Level Up
  gamble without a good hint, are invisible to it; a player may value them.
  The bot rerolls only Level Up tables with no skill: a bot that also
  rerolls loot tables when it can pay lifts every unlock's top from 10.5 to
  14.4% on rules 3 today. A player who rerolls for gear will find the Tower
  easier than these numbers say.
- **The gamble's worth** depends on how the bot values a loot table (gear
  first). The weights are one list; the blind cost (about 2 points at
  floor 10) is the knob to set by hand test.
- **Hex** is only in the bot's fight in the prototype; the app's fight
  needs the same factor.
- **The pedlar** (Purse) is a new action and a new button; without it Purse
  stays weak (15 or 25 coins: +0.4 to +0.7 at floor 10).
- **Perks are measured one at a time** (one slot). With two slots (not
  proposed) the early-health perks would stack.
- **Old friend's gear** is drawn at the start; a start item unlock
  (shield, sword) in the same slot can make it a spare.
- **Noise.** 2,000 seeds: about ±1.0 point at 30%, ±0.7 at 10%, ±0.45 at 4%.
  The perk rows differ from one another by about that much at the top.
- The 1.03 offset also lowers Heat 3 with every unlock (4.95 to 3.85%).

## How it was measured

The prototype patch adds the two cards, the perk variants and a knob for
the offset behind flags, and a scratch harness (`test/zz_props_test.dart`
in the patch) that plays `playTowerRun` over seeds 1 to 2000 for a list of
cases (unlocks, perk, Heat) and writes f5 / f10 / f20 / top, the median,
counts of each card dealt and taken, and the hero's Perception at each loot
table. With every flag off it plays today's climbs (the rules-3 rows above
are the survival doc's numbers, to the 0.05 point).
