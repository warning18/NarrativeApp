# Tower: Level Up gives skills, floors give loot (design, rules 2)

Core's design doc for the user's idea, the Tower only (the story keeps
today's Level Up). The proposal (section "The proposal as approved", below)
was approved with the user's decisions; PR 1 (Core, the rules) builds them
as **rules 2** (`TowerRun.rules`). The screens are UX's PR 2: PR 1 only
wires the floor screen enough for the new tables to be played.

Code: `lib/data/tower/tower_levelup_loot.dart` (XP, nudges, loot, the
moves), `towerOfferFor(levelUp: true)` in `tower_rewards.dart` (the Level Up
table), `TowerRun.rules / xp / levelUps / loot / table` in `tower_run.dart`,
the rules-2 replay in `towerHeroOf`, the bot in `tower_bot.dart`. Tests:
`test/tower_levelup_loot_test.dart`.

## The user's decisions, as built

| Question | Decision | Built |
|---|---|---|
| Difficulty | retune foes and loot to keep today's tops, plus a calling pass | foes ×**0.85** on rules 2 (`towerLootFoeScale`; the prototype's 0.82 re-measured), loot tier **+0 / +1 / +2** by band (`towerLootTierShift`), calling pass `towerLootProfessionScale`: **cleric ×1.05, ranger ×1.02, rogue ×0.97** (on top of `towerProfessionScale`, which rules 1 keeps) |
| Stat nudge | +1 a skill or rank-up taken from Level Up, at most +4 a stat and +10 a climb, the priority rule | `towerNudgeStatOf` (support → CON, WIS if Light/Water; Weaken → PER; a calling's own → its damage stat; Fire/Elec/Void/Ice/Water → INT, Wind → DEX, Earth → STR, Light → WIS; Poison → DEX, Stun → STR; else the damage stat), `towerNudgeOn` (caps `towerNudgeStatCap` 4, `towerNudgeClimbCap` 10, counted in `pickedPoints`). A stall's boon (a Level Up table bought) nudges too. No stat picks on rules 2; race points, bargains and +3 HP a level stay |
| Level Up | three distinct cards: one clan's gift, a skill or rank-up, a die or spell | `towerOfferFor(levelUp: true)`: slot A one clan drawn from the pool (its gift, else a pool skill in its name, with its colour, standing and ripple), B a skill (a rank-up when it lands on no face), C a die or a spell (even odds, the other when one is empty); "always three" fills (`boonFill`), never a repeat (`cardOf`). The clans' tables (floor 1 + 35%) and the boon floors are gone on rules 2 |
| Cadence | 2 XP an ordinary floor, 3 an Elite, 4 a warden or boss; a level every 4 XP | `towerXpFor`, `towerXpStart` 2, `towerXpPerLevel` 4 (the power knob). An Elite is the floor's (or a shortcut's); an Elite the fight rolls on its own pays 2. Floors skipped (rival, shortcut, parley) pay their XP on the landing; their Level Up tables come after the next floor won (a shortcut's landing deals its tables at once) |
| Floor loot | three loot cards, a weighted mix, never the same twice, Pyre 13 and 23 none | `towerLootFor`: the chest roll (`fortuneRollFor` → `tierForRoll` → `finalTierFor`) with the band's shift; each card drawn by weight **gear 50 / bundle 35 / purse 15** (one purse at most; two gear or two bundles happen); gear by `gearWeightsFor` (not owned, not on the table), two bundles a tier (`towerLootBundles`), a purse of **1 / 1 / 2 / 2 / 3** coins by tier, +0 a band (`towerLootPurse`). Left, a mark. Pyre's 13 and 23: no loot table, their Level Ups still |
| Gamble card | later | not in PR 1 |
| Oath | open: keep today's logic behind a flag | `towerOathInLevelUp = false`: as today, dealt on every floor won once due (standing 6, the late oath from floor 15, 18 at Pyre, Early word 3 sooner), in front of that floor's first Level Up table when one is dealt (taken, it takes that level's card, as it took the clans' gifts), else on a table of its own after the loot (taken, nothing lost; refused, a mark). `true`: only in front of a Level Up table |
| Old saves | open: a `TowerRun.rules` field, both paths | `rules` (absent = 1). Rules 1 runs every old path unchanged (the stat picks, the spoils chest, the boons, the clans' tables); new climbs start on `towerRulesLive` = 2 (`tower_providers.dart`). Rules 1 measured identical to main (seeds 1 to 2000) |
| Perks | re-map what referred to removed things | **Keen eye**: the first Level Up table's skills one rarity up (the closer intent: it was the first boon's skill); **Fourth card**: the first two Level Up tables a fourth card (a skill); **Free hand**: the first reroll free, rerolls now on Level Up and loot tables (banish: Level Up cards only); Early word, Old friend, Purse, Deep pockets, Second wind unchanged |

The flow of a floor won on rules 2: the floor's XP, coins and recovery,
then the loot table (`TowerRun.table` loot), then one Level Up table for
each level earned (`levelUp`), then the oath alone when due and not shown
(`oath`), then on (`towerDealTable`, `towerPickRules2`). A reroll redraws
the table on screen (`towerRedrawTable`). The bot takes its Level Up cards
as it takes cards today (an oath, else the clan's card of its best
standing, else a skill, a die, a spell), rerolls a Level Up table with no
skill card once a floor, and takes the loot that improves a slot by the
item score, else the bundle with three potions or fewer in the bag, else
the purse (`towerBotLootChoice`).

## Numbers (seeds 1 to 2000, floor events 2, no perks, the bot's full coins)

`TOWER_OUT=… TOWER_SEEDS=2000 [TOWER_HEAT=3] [TOWER_RULES=1] flutter test
test/qa_tower_sim_test.dart --plain-name batch`. Before: main (v2.10.23),
rules 1 (the branch on rules 1 gives the same numbers, seed for seed).
After: rules 2.

| Heat 0 | none, before | none, after | all, before | all, after |
|---|---|---|---|---|
| top | 11.55% | **13.95%** | 24.65% | **22.70%** |
| median floor | 17 | 20 | 21 | 23 |
| reach floor 20 | 42.0% | 50.1% | 59.0% | 62.1% |
| floor 30 lost (of those reaching it) | 26.0% | 34.0% | 16.4% | 31.6% |
| worst ordinary floor | 10.7% (f28) | 10.7% (f19) | 7.3% (f26) | 8.6% (f19) |
| Level Ups a climb (a climb that wins) | 10.0 (17.0) | 11.8 (17.7) | 11.9 (17.0) | 13.2 (17.7) |
| coins earned a climb (a climb that wins) | 38.9 (80) | 51.3 (93) | 49.4 (80) | 62.8 (95) |

| Heat 3 | none, before | none, after | all, before | all, after |
|---|---|---|---|---|
| top | 3.70% | 4.75% | 11.30% | 11.10% |
| median floor | 14 | 16 | 18 | 20 |
| reach floor 20 | 25.5% | 33.6% | 45.2% | 50.0% |
| floor 30 lost | 43.9% | 49.5% | 31.1% | 42.8% |
| worst ordinary floor | 14.4% (f27) | 14.4% (f19) | 10.6% (f26) | 10.8% (f19) |
| Level Ups a climb | 8.3 | 9.9 | 10.3 | 11.7 |
| coins a climb | 29.2 | 38.7 | 40.4 | 52.0 |

Top for each calling (heat 0):

| | cleric | mage | ranger | rogue | warrior |
|---|---|---|---|---|---|
| every unlock, before | 22.7 | 21.5 | 27.7 | 21.9 | 29.4 |
| every unlock, after | **20.1** | **22.2** | **24.5** | **25.3** | **21.1** |
| no unlocks, before | | 10.6 | | 11.2 | 12.8 |
| no unlocks, after | | 14.2 | | 8.9 | 18.3 |
| Heat 3, every unlock, after | 10.4 | 12.2 | 13.6 | 7.6 | 11.6 |

- With every unlock the callings sit within 5.2 points (the prototype's
  cleric 35.5 / rogue 14.5 fixed by the calling pass).
- **With no unlocks they do not** (rogue 8.9, warrior 18.3). One scale a
  calling cannot level both: the rogue gains most from the unlocks and the
  warrior least (a rogue made easier is the strongest with every unlock).
  A possible cause (not measured): the bot takes the clan's card on every
  Level Up table, so its skills come from the clans of its pool, and with
  no unlocks the pool is the three start clans (Dominion, Mire,
  Penitents). A per-calling knob for the unlocks, or a bot that
  weighs the skill card against the gift, are the next options.
- The tops: no unlocks 2.4 points above today, every unlock 2 below, Heat 3
  on today's. The unlocks matter less on rules 2 (gear comes from the loot
  table for everyone). QA's bands hold (`_topNone` 0.07–0.20, `_topAll`
  0.18–0.32, the median, floor 20, the events-off guard).
- The shape moved as the proposal warned: floor 30 kills about a third of
  those who reach it (today a quarter, a sixth with every unlock).
- Coins: about +12 a climb (×1.3), not the prototype's ×2.7: the purse is
  small and drawn less (15 of 100), and the floors' coins are unchanged.

Retune values tried (1,000 seeds, no calling pass, purse 1 to 5, top none /
all): foes ×0.82 14.8 / 28.4%; ×0.88 8.5 / 17.3%; ×0.94 3.5 / 10.8%. With
the calling pass and the small purse: ×0.83 16.3 / 25.1%; ×0.84 15.2 /
24.1%; ×0.85 13.7 / 22.7%; ×0.86 (2,000 seeds) 11.9 / 20.55%.

## Not done in PR 1

- The gamble card (later, its own PRs).
- The screens (UX's PR 2): the loot cards and the Level Up table are drawn
  by the offer view as it stands, with placeholder words
  (`tower_kind_gear`, `tower_kind_bundle`, `tower_bundle_name`,
  `tower_bundle_text`, `tower_kind_purse`, `tower_purse_name`: Narrative's
  to word). The spoils sheet shows an empty chest before the loot table.
- The rules-1 path is kept; its removal is PR 8 (two releases later).

---

# The proposal as approved

Core's proposal for the user's idea, the Tower only. The story keeps
today's Level Up. Nothing is built yet. The numbers come from the bot
(`playTowerRun`, seeds 1 to 2000, floor events version 2, the same batch
as `test/qa_tower_sim_test.dart`). The prototype was a throwaway edit of
`lib/data/tower/` in a scratch worktree and was not committed. Numbers
marked **(guess)** are first values for the rules PR to tune.

## In one table

| | Today (v2.10.21) | Proposed |
|---|---|---|
| Level Up (17 a climb) | a stat pick: three stat offers (`drawStatPick`), ~1.1 points each | **a card table**: three cards, from skills, rank-ups, dice, spells and **one clan's gift** |
| A skill taken | the skill | the skill **and +1 to its stat** (table below), at most **+4 in one stat and +10 a climb** |
| Floor won | the spoils chest, auto-taken: ~1.7 items a floor (gear and potions), ~50 items a climb | **a loot table**: three cards (**one gear, one consumable bundle, one coin purse**), take one |
| Boon floors (5, 10, 13, 15, 20, 23, 25, 28) | a skill, a die and a spell | gone: their cards are Level Up cards now |
| Clans' tables (floor 1 + 35% of floors) | three clans' gifts | gone: one clan's gift sits on every Level Up table |
| Oath | at standing 6; late oath from floor 15 (18 at Pyre) | the same rules. The oath is a **4th card** on the next table |
| Gamble | none | **1 loot table in 4** shows one card face down. Perception can reveal it |
| Power knob | foes' scale, each floor's extra | **Level Up cadence** (Tower XP a level) and **loot tier for each band** |

## 1. The Level Up table

### 1.1 The cards

Three cards, always distinct (the "Always three" rule of v2.10.18,
reused as is: `cardOf` turns a skill with no free face into a rank-up, and
`boonFill` fills a short table).

| Slot | Draw | Weight inside the slot | Notes |
|---|---|---|---|
| A: the clan's card | one clan of the run's pool, drawn; its gift (`towerClanGiftFor`), else a skill of the pool in its name | n/a | clan colour, standing (+2 to it, +1 to allies, −1 to rivals; −2 at Ash), as today's gifts |
| B: a skill | a skill of the pool at the floor's rarity (`towerRarityStep`), or a rank-up when it lands on no face | n/a | as a boon's skill card |
| C: a die or a spell | 50 / 50 **(guess)**; the other one if the first is empty | die 50, spell 50 | a spell only for a calling with spells; else a die |
| fill | `boonFill` (a skill, then a die, then a spell) | n/a | only when a slot came out empty or repeated |
| oath (when due) | the clan's oath, **in front, as a 4th card** | n/a | taking it skips that level's card, as an oath skips a gift today |

- With no clan in the pool (impossible today: the start pool has three),
  slot A is a second skill.
- Rarity is drawn by floor band (`towerRarityOdds`, unchanged):
  floors 1–10: common 60 / uncommon 35 / rare 5 / epic 0;
  11–20: 25 / 45 / 27 / 3; 21–30: 5 / 35 / 50 / 10. A warden or boss floor
  is one step up.
- Reroll (3, 5, 7 coins) and banish (4 coins, one a table, five a climb)
  work on the Level Up table as they work on today's boon and clan tables.

In the bot's climbs that reach floor 30 the hero takes about the same
number of cards as today: **8.5 skills + 7.6 rank-ups + 1 oath** (today
7.8 + 7.4 + 1). The proposal takes away the 17 stat picks and the auto-taken
chest, not cards.

### 1.2 The skill → stat nudge

skills.json has no `scalingStat` and no tags (all 162 entries have neither). The stat is read
from what every skill does have, the first rule that matches winning:

| Rule | Test | Stat |
|---|---|---|
| a. support | heals, blocks, guards, cleanses or reflects, and `damageMultiplier` ≤ 1.0 | **CON**; **WIS** if Light or Water |
| b. weak point | `inflictsStatus` Weaken | **PER** |
| c. calling's own | `restrictedProfessionID` set | that calling's damage stat (`damageStatOf`) |
| d. element | Fire, Electricity, Void, Ice, Water → **INT**; Wind → **DEX**; Earth → **STR**; Light → **WIS** | as listed |
| e. status | Poison → **DEX**; Stun → **STR** | as listed |
| f. fallback | none of the above | the hero's damage stat |

Coverage over the 133 skills a hero can learn (enemy-only and merge-only
left out): a 28%, b 9%, c 41%, d 12%, **f 10%**: rules a to e place
**90%**. Where the nudges go: INT 23%, DEX 20%, CON 20%, WIS 10%, PER 9%,
STR 8%, fallback 10%.

How much of each calling's pool feeds its own damage stat: warrior 39%
(STR), ranger 52% (DEX), rogue 42% (DEX), mage 53% (INT), cleric 48%
(INT). The rest goes mostly to CON (21–28%), so stats follow the build
and the damage stat takes about half.

- **Size and cap**: +1 a skill or rank-up taken (a die, spell or oath
  gives none). At most **+4 in one stat and +10 a climb** **(guess,
  measured below)**. The cap is counted on the hero (as `pickedPoints` is
  today) and replayed by `towerHeroOf`.
- **Double-dipping with `damageStatOf`**: a nudge goes through
  `addAbilities`, so a point in the calling's damage stat is +1 base
  damage, as any point is today. The cap is the guard: at most **+4 base
  damage a climb** from skills, against **about +11 today** (17 picks ×
  ~1.1 points × the bot's 0.6 share in the damage stat). Taking the base
  damage away from these points was considered and dropped: an INT nudge
  would then do nothing for a mage.
- The cap's weight, measured (foes ×1.0, loot not raised): top with every
  unlock **1.55% at a 3 / 6 cap (2,000 seeds) against 7.8% uncapped (1,000
  seeds)**. The nudge
  is a real knob. Uncapped, it gives back most of the stat picks.

### 1.3 Cadence: the power knob

Today a level is fixed for each floor (`TowerBudget.levelAfter`). Seventeen Level
Ups in a climb, on floors **1, 3, 5, 7, 9, 10, 12, 14, 15, 17, 19, 20, 22, 24,
25, 27, 29**: level 18 at the top, every warden and boss included.

| Floors cleared | 5 | 10 | 15 | 20 | 25 | 29 |
|---|---|---|---|---|---|---|
| Level (today, every run) | 4 | 7 | 10 | 13 | 16 | 18 |

Levels depend only on height, so the bot's runs show it directly. With no
unlocks the median climb ends on floor 17 (level 10–11). With every unlock
it ends on floor 21 (level 13).

**Proposed: Tower XP.** Each floor won pays XP: **ordinary 2, Elite or
shortcut Elite 3, warden 4, boss 4**. A level costs **4 XP**, and the hero
starts with 2. That gives today's table within one level (an Elite gains a
level sooner). The cost of a level is then the one
power knob for skills:

| XP a level | Level Ups a climb | Effect |
|---|---|---|
| 3 | ~23 | richer climb (≈ +6 cards) |
| **4 (proposed)** | **~17 (today's)** | today's pace |
| 5 | ~14 | leaner climb |

A floor met again (a setback) pays no XP, as it pays no level today.
Floors skipped by a rival or a shortcut pay their XP on the landing, as
their picks wait there today.

## 2. Floors give loot

### 2.1 The loot table

After every floor won for the first time (not the top: the climb ends
there): **three cards, take one**. The table's **tier** is today's chest
roll, reused as is (`fortuneRollFor` → `tierForRoll` → `finalTierFor`):
d100 + 2 × Luck + 25 for an Elite or warden + 6 for each extra foe + 8 for each affix.
Thresholds are 40 / 70 / 100 / 125. An Elite is at least Silver and a boss at least
Gold. **New: a tier shift for each band**, the gear knob.

| Card | Wooden | Iron | Silver | Gold | Void |
|---|---|---|---|---|---|
| gear (`gearWeightsFor`, the tier's rarities, the floor's chapter, not owned; 1.5× for the calling's stat) | Common | Common | Common/Uncommon | Uncommon/Rare/Relic | Uncommon/Rare/Relic |
| consumables (guess) | 1 minor potion | minor + antidote | major + minor | 2 major | 2 major + antidote |
| coin purse (guess) | 3 | 4 | 6 | 9 | 12 |

Coins +2 for each band (floors 11–20 +2, 21–29 +4). A potion past the bag's cap
(5, or 6 with Deep pockets) is drunk at once, as today. With no gear left
to give, the gear card is a second consumable bundle.

**Tier shift for each band (the gear knob), proposed: floors 1–10 +0, 11–20 +1,
21–29 +2.** An ordinary floor with one foe and Luck 0 then rolls:

| Floors | Wooden | Iron | Silver | Gold | Void |
|---|---|---|---|---|---|
| 1–10 (+0) | 39% | 30% | 30% | 1% | 0 |
| 11–20 (+1) | 0 | 39% | 30% | 30% | 1% |
| 21–29 (+2) | 0 | 0 | 39% | 30% | 31% |

A climb that reaches the top makes 29 loot choices, where today it is
handed ~50 items. In the prototype the bot ended with **4.7 of the 5 gear
slots worn and about 10 items owned**.

### 2.2 Coins

The coins for each floor (`towerCoinsFor`: 1 / 2 / 3 a band, warden 3 a
band, boss 5 a band, Elite +1 a band) **stay**, and the coin card is on
top. In the bot's climbs the coins earned went from **39 to 105** a climb
(no unlocks; **49 to 162** with every unlock). The bot takes the purse
whenever the gear is no upgrade and the bag holds 3 or more. The stall
gets more use (about 2.3 boons a climb that reaches the top, against 1.6 today).
**Lower the purse to 2 / 3 / 4 / 6 / 8 if QA finds coins pile up (guess).**

### 2.3 Floors with no reward

Pyre (Heat 4+) today takes the boon floors 13 and 23 away and leaves them
empty. Proposed: **floors 13 and 23 give no loot table** (and their coins
still pay; only the table goes). A Level Up due there still comes, since it is
earned by XP. The stall's boon (15 coins) still deals on any floor.

## 3. The gamble card (not simulated)

- **How often**: on **1 loot table in 4** **(guess)**, from floor 2, drawn
  on its own stream (`TowerStream.gamble`, new). One of the three cards
  (drawn) is dealt **face down**. Its face-up card is gone for that table.
- **Picked**: it turns over and applies. No undo, no reroll back, no
  banish. A reroll of the table redraws whether a card is face down.
- **Outcomes (guess)**. The expected value is a little above a normal
  card, with a real downside:

| Band | Weight | Outcome | Example |
|---|---|---|---|
| good | 20 | **hidden cache**: gear two tiers up (Rare or Relic from 11+) | a Relic blade on floor 12 |
| good | 15 | **gold vein**: 3× the table's purse | 18 coins on a Silver table |
| good | 10 | **full bag**: the bag filled to its cap, + 1 antidote | |
| trade-off | 15 | **cursed gear**: gear two tiers up, **−10% max HP while worn**, and it can only come off at a stall (4 coins) | Narrative names it |
| trade-off | 10 | **blood price**: +1 to the damage stat for good, −8% max HP (a bargain's rule) | |
| trade-off | 10 | **heavy purse**: 2× purse, −1 potion | |
| bad | 8 | **cut purse**: half the coins in hand gone (at least 3) | |
| bad | 6 | **spoiled flask**: 2 potions from the bag gone | |
| bad | 6 | **binding curse**: a cursed piece worse than the one worn, **locked on for 3 floors** | Narrative names it |

Bands: good 45, trade-off 35, bad 20. A cursed piece is a new item
record in the Tower's own table (`towerCursedItems`: its base item plus a
`curse` field: `maxHealthShare`, `lockedFloors`), so items.json is not
touched. The run saves `TowerRun.curses` (floor → item, floors left).

- **Perception reveals it.** When the table is dealt, a chance of
  **12% per point of Perception, always at 8 or more** **(guess)**
  (rolled once on the gamble stream) shows the card face up, marked
  "seen through" (an eye on the card, UX's). A revealed card can be taken
  like any card.

| Hero | Perception | Revealed |
|---|---|---|
| human or orc warrior, mage or rogue | 1 | 12% |
| ranger | 2 | 24% |
| elf | 5 | 60% |
| elf ranger | 6 | 72% |
| any hero with +3 PER nudged (Weaken skills, rule b) | +3 | +36 points |

This is a real use for Perception in the Tower: today it is only a warrior's block
and a ranger's or rogue's crit and dodge. PER rises by nudges (rule b: 9%
of the pool, the Weaken skills) and from the start (elf 4, ranger 1).
- The bot will take a gamble only when it is revealed and good (the
  batch reports how often).

## 4. What happens to the rest

| Today | Proposed |
|---|---|
| stat picks in the Tower (`statPicks`, `towerPendingPicks`, `TowerLevelUpSession`, `LevelUpScreen` in a Tower scope) | **gone in the Tower**; the story's Level Up untouched |
| race start points (`towerPeoplePoints`: humans and voidkin +2 in the damage stat) | stay |
| bargain (+1 damage stat, −10% max HP) | stays |
| +3 max HP a level (`levelHealthGain`) | stays |
| Luck | loot fortune (+2 a point on the roll, today's chest rule); the stat pick rarity it moved is gone |
| coins for each floor | stay; + the coin card |
| reroll / banish | on Level Up and loot tables (banish: Level Up cards only) |
| stall (salve 4, bundle 5, boon 15) | unchanged; its boon is a Level Up table bought |
| marks, unlocks, trims, first-win bonuses | unchanged |

**Perks**, one worn a climb:

| Perk | Today | Proposed |
|---|---|---|
| Purse | 5 coins at the start | unchanged |
| Deep pockets | bag 5 → 6 | unchanged |
| Early word | late oath 3 floors sooner | unchanged |
| Old friend | one gift of a clan at the start | unchanged |
| Second wind | +15% HP after a warden or boss | unchanged |
| Keen eye | first boon table's skill one rarity up | **every face-down card is shown** (and the first Level Up's skill one rarity up) |
| Free hand | first reroll of the climb free | unchanged (any table) |
| Fourth card | first two boon tables +1 skill | **first two Level Up tables +1 skill** |

**Heat**:

| Curse | Touches rewards today | Proposed |
|---|---|---|
| Embers ×1.05 foes | no | unchanged |
| Smoke +1 affix on peaks | the chest's fortune +8 an affix | the same, on the loot table's roll |
| Flame recovery .15 → .05, +5% Elites | Elites pay their coin | unchanged; an Elite also pays 3 XP |
| Pyre: boons 13 and 23 empty, late oath 18, ×1.04 foes 11+ | no boon and no clan's table there | **no loot table on 13 and 23**; late oath 18 |
| Ash: ×1.12 foes 11+, a gift −2 to rivals | clans' gifts | the same, on Level Up's clan card |

**Saves mid-climb**: a new field `TowerRun.rules` (absent = 1, new climbs
2). A climb saved on rules 1 finishes on rules 1: `towerHeroOf` already
replays stat picks and spoils, so both paths live in the same functions
behind `run.rules`. The rules-1 path is deleted two releases later, and a
rules-1 climb still open then ends as left (its marks banked).

## 5. Bot batch: today against the prototype

Seeds 1 to 2000, floor events 2, no perks, the bot's full coin policy.
"Top" is the share of climbs that win floor 30.

| Case | Today v2.10.21 | Prototype, today's foes (cap 3 / 6) | **Prototype, retuned** |
|---|---|---|---|
| no unlocks, top | **11.55%** | 0.35% | **11.75%** |
| no unlocks, median floor / reach 20 | 17 / 42.0% | 13 / 18.8% | 19 / 47.6% |
| every unlock, top | **24.65%** | 1.55% | **23.10%** |
| every unlock, median / reach 20 | 21 / 59.0% | 17 / 39.0% | 24 / 66.4% |
| Heat 3, every unlock, top | **11.30%** | 0.50% | **11.10%** |
| Heat 3, no unlocks, top | 3.70% | 0.10% | 3.75% |
| coins earned a climb (none / all) | 39 / 49 | 51 / 90 | 105 / 162 |

**Retuned** = foes ×0.82 on every floor (`towerProfessionScaleOf`), loot tier
+0 / +1 / +2 by band, nudge cap 4 / 10. Two numbers were moved: foes and loot.
The tops land on today's. The shape moves: early floors get easier and the
top boss harder, because the hero no longer grows a stat point every level:

| No unlocks | Today | Retuned |
|---|---|---|
| ordinary-floor death rate for each band (1–10 / 11–20 / 21–29) | 1.5 / 7.0 / 8.9% | 1.0 / 6.4 / 8.4% |
| killed on floor 10 / 20 / 25 / 30 (of those reaching it) | 6.4 / 11.4 / 11.3 / 26.0% | 3.9 / 15.2 / 12.1 / **33.2%** |
| worst ordinary floor | 10.7% (f28) | 9.8% (f26) |

**For each calling** (top %, every unlock; today → retuned): cleric **22.7 → 35.5**,
mage 21.5 → 20.0, ranger 27.7 → 22.6, rogue **21.9 → 14.5**, warrior
29.4 → 23.6. No unlocks: mage 10.6 → 13.0, rogue 11.2 → 9.0, warrior
12.8 → 13.1. The cleric heals better with gear worn than with stat
points, and the rogue loses most from the stat picks (its DEX and Luck).
The rules PR needs a calling pass (`towerProfessionScale`, likely the cleric
×1.10 and the rogue ×0.92, **guess**).

Intermediate runs (1,000 seeds, cap 3 / 6 unless said, top none / all): foes ×0.80 alone 6.0 / 12.5%;
×0.84 alone 3.6 / 9.3%; ×0.84 + loot +0/1/2 5.9 / 13.7%; ×0.84 + loot + cap 4/10
9.8 / 19.2%; ×0.80 + loot + cap 4/10 14.7 / 26.9%. A lower foe scale alone
cannot reach today's top without making floors 1–20 a walk. The late knob
has to be loot (or cadence).

**What the prototype approximates**:
- the gamble card is not played (§3 is unmeasured);
- the bot takes gear when its flat score (damage + armour) beats the piece
  worn, else consumables when the bag holds under 3, else the purse. A
  player choosing gear by set, element or requirement will do better;
- Tower XP is not built: the prototype keeps `levelAfter`, which the XP
  rule reproduces within one level;
- two levels gained on one landing (a skip) give one table, not two;
- perks are not re-mapped (the batch wears none); the loot table has no
  reroll; the bot rerolls a Level Up table with no skill on it;
- the bot takes the clan's card whenever one is on the table (its policy
  today), so it swears an oath in 74% of climbs with no unlocks (today 82%).

## 6. Risks

1. **The shape of the climb.** At equal tops, floor 30 kills 33% of those
   who reach it, against 26% today. The hero's growth now sits in
   cards and gear, and the late floors outgrow it. Fix with cadence (XP 4 →
   3.5 on 21+) or loot, not with the boss's extra.
2. **Spread between callings** (cleric +13, rogue −7 points). It needs a calling pass in the
   rules PR, and QA's guard bands re-centred.
3. **Bot against real play.** QA's #1165 already finds the bot about 19 points
   optimistic for the non-casters. Here two new choices fall to the bot
   (which loot card, the gamble), so the gap may widen either way. Before
   release, the user's own hand test of 5 to 10 climbs, compared with the
   bot's median floor.
4. **Coins inflate** (×2.7). Coins feed the stall's boon, and the stall boon
   is a Level Up table bought for 15 coins. Lower the purse first.
5. **Events read stats.** The setback's test (STR / DEX / WIS) and the parley's
   (CHA / WIS / DEX) lose the stat picks, so more tests fail. The rules PR
   reports their pass rates, and the DCs come down if they fall over 10 points.
6. **Save migration**: two rule sets for two releases (§4); a test holds
   that a rules-1 save still rebuilds the same hero.
7. **UX scope**: the Tower's Level Up stops using the story's
   `LevelUpScreen`. It becomes the card table (`tower_offer_view.dart`, swipe
   cards), the loot table is a second table, and the face-down card needs
   a card back and a reveal. Two tables can come on one floor (loot, then
   Level Up).
8. **Narrative**: names and lines (EN/FR) for the loot cards, the nine
   gamble outcomes, the cursed pieces, two re-worded perks, the Level Up
   table's title.

## 7. PRs, in order

| # | Session | What | Rough size |
|---|---|---|---|
| 1 | **Core** | rules 2: `TowerRun.rules`, Tower XP, Level Up table (`towerLevelUpFor`), nudges (`towerNudgeStatOf`, cap), loot table (`towerLootFor` in place of `towerSpoilsFor` on rules 2), purse, Pyre floors, perks re-mapped, bot, foe and calling retune, string keys (placeholder English), save tests | ~900 lines lib + ~500 test |
| 2 | **UX** (after 1) | Tower Level Up as a card table; loot table cards (gear, bundle, purse); two tables on one floor; perk lines on the door | ~600 lines |
| 3 | **Narrative** (beside 2) | loot card names, Level Up title, Keen eye and Fourth card lines (EN/FR) | strings only |
| 4 | **QA** (after 1) | `qa_tower_sim_test` bands re-centred; a `qa_` guard: three distinct cards, cap respected, rules-1 save rebuilds | ~200 test |
| 5 | **Core** (after 1) | the gamble: `TowerStream.gamble`, outcomes, `towerCursedItems`, `TowerRun.curses`, the PER reveal, bot policy, batch | ~400 lines lib + ~250 test |
| 6 | **Narrative** (beside 5) | the nine outcomes' lines, the cursed pieces' names | strings only |
| 7 | **UX** (after 5); **Art** through the manager if a new card back is wanted | face-down card, reveal, "seen through" eye, curse chip on the hero sheet | ~300 lines |
| 8 | **Core** (two releases after 1) | the rules-1 path deleted | −300 lines |

PRs 1–4 make a playable release without the gamble. PRs 5–7 can follow one
release later.

## 8. Open questions for the user

1. **The nudge's cap**
   - **(a) +1 a skill or rank-up, at most +4 in a stat, +10 a climb (recommended: measured above)**
   - (b) smaller, +3 / +6: the foes must come down further (×0.80), easier early floors
   - (c) no cap: close to today's stat picks; the skills' tables matter less
2. **Where the oath goes**
   - **(a) a 4th card on the next table when it is due; standing 6 and the floor-15 late oath kept (recommended: today's rules)**
   - (b) its own question before the Level Up (swear / not now), so no level's card is lost
   - (c) one of the three Level Up cards, in place of the clan's gift
3. **The loot table's shape**
   - **(a) always one gear, one consumable bundle, one purse (recommended: readable, easy to tune)**
   - (b) three cards drawn by weight (gear 45 / consumables 30 / coins 25), never two alike
4. **The gamble**
   - **(a) 1 table in 4 from floor 2, good 45 / trade-off 35 / bad 20, Perception 12% a point, always at 8 or more, Keen eye shows every card (recommended)**
   - (b) only on warden and boss floors, bigger stakes
   - (c) leave it for later (PRs 1–4 only)
5. **Climbs saved before the change**
   - **(a) finish on the old rules; that code deleted two releases later, an old climb still open then ends as left with its marks (recommended)**
   - (b) carried over: the old stat points kept, the new rules from the next floor
   - (c) ended at once as left, marks banked
6. **How hard the new Tower should be**
   - **(a) today's tops (no unlocks ~12%, every unlock ~25%, Heat 3 ~11%) via foes ×0.82 and loot +1 / +2 tiers on 11–20 / 21–29, then a calling pass (recommended)**
   - (b) the same tops, but via cadence (XP 3.5 on floors 21+) instead of loot: more cards, less gear
   - (c) accept a harder Tower for a while (foes unchanged: top 0.35% / 1.55%)
