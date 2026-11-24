# The Tower as a roguelike: ten briefs

One page per proposal to make the Tower harder in the right places and more
worth "one more run", so the user can decide each one quickly. **Nothing here
is built.** No rule, number or data changes until the user chooses.

Starting point: QA's batch on v1.1009 (`docs/qa/tower-1.1009.md`). The top
(floor 30) is won by **14.3%** of runs with no unlocks and **26.9%** with all
of them. The design's bands (`docs/proposals/tower-mechanics.md` §11, held by
`test/qa_tower_sim_test.dart`'s report) are **5 to 12%** and **15 to 25%**,
a median floor of **13 to 18** (now 19) and floor 20 reached by **20 to 38%**
(now 48%). So the climb is too easy from floor 11 up, and a run offers few
choices: about **6 picks a run** with no unlocks, and **28%** of the skills
taken land on no face of the die.

## Built in v2.4.0 (briefs 1, 2 and 3, the user's choices)

- **1, option B:** floors 11–20 ×1.08, 21–29 ×1.06 (`towerClimbScale`).
- **2, option A:** a skill card that would sit on no face is a **Rank up**
  card for the best skill on the die (`towerRankUpFor`); the tier is
  `applySkillTier`'s, played by the fight screen and by the bot's fights.
- **3, option B:** boons also on floors 13, 23 and 28.

Measured together (the live bot, seeds 1–2000):

| | top none | top all | median | floor 20 | mean floor | cards a run none / all | rank-ups a run |
|---|---|---|---|---|---|---|---|
| before (v2.1.5) | 14.5% | 26.8% | 19 | 48.2% | 19.3 | 6.0 / 8.7 | — |
| **v2.4.0** | **12.9%** | **25.4%** | 17 | 42.3% | 18.3 | 6.9 / 9.9 | 1.5 / 2.0 |

The rank-ups are worth more than this doc's calculation (+1 to +2 points):
both tops end about a point above the design's bands (5–12% and 15–25%).
A follow-up could take brief 1's numbers one step up (for example 11–20
×1.10); not done here, the user chose option B.

The card as it reads (`tower-build-2.4.0/`): English at 412 px, French at
360 px.

## Summary

| # | Proposal | Effect from the sim | Risk | Size | Recommendation |
|---|---|---|---|---|---|
| 1 | A harder climb above floor 10 | top 14.3 → **10.1%** (none), 26.9 → **21.1%** (all); median 19 → 17; floors 1–10 unchanged | low (numbers only) | S | **Option B**: floors 11–20 ×1.08, 21–29 ×1.06 |
| 2 | No dead skill picks | dead skill picks 28% → 0%; top about +1 to +2 points (calculation) | low | M | **Rank up** a skill on the die |
| 3 | More boons in a run | +3 boons: picks 6.0 → 6.8 a run, top 10.1 → 11.2% (with #1) | low | S | **Three more boon floors** (13, 23, 28), after #2 |
| 4 | Boss relics that change the build | not measured (the headless fight has no relics) | medium | L | **One relic of three after each boss** (option A) |
| 5 | A risky door for better loot | as tried (Elite for a plain boon), top **falls** 9.4 → 7.8%: the reward must be bigger | medium | M | **Door from floor 11 only, a relic or a rarer boon behind it** |
| 6 | Coins in the run: reroll, banish, a shop | not measured; marks already buy salves in 49% of runs | low | M | **Tower coins from the spoils**, spent at the merchant |
| 7 | Heat levels for veterans | all unlocks, with #1: top 20 → 15 / 9 / 6% at heat 1 / 2 / 3 | low | M | **Three heat levels**, opened by a win |
| 8 | Daily climb and a best-run record | not a balance change | low | S | **Daily seed + best record** |
| 9 | A second unlock tree | the tree is bought in a median of **7 runs**; then marks buy nothing | low to medium | M | **A second tree of ten**, no raw power |
| 10 | More variety per band | floors 21–29 draw from the same 18 foes; 5 affixes | low | M | **One floor modifier per band**, then new events |

"Needs pictures first" (UX) on 2, 4, 5, 6, 7, 8, 9 and 10. Only #1 and #3 change
nothing the player sees but the numbers.

## How it was measured

| Tag | What |
|---|---|
| **B** (base) | Core's bot (`playTowerRun`, `tower_bot.dart`), floor events version 2 (the live one), seeds **1 to 2000**, once with no unlocks and once with all. It matches QA's batch exactly (14.3% / 26.9%, median 19 / 22). |
| **C** (check) | The same on seeds **10001 to 12000**. |
| **V** (variants) | The same 2,000 seeds with a change made in memory: a temporary multiplier on the floors' extras (`_floorOf` in `tower_floors.dart`), extra boon floors (`towerOfferFor`), an Elite "door" before chosen floors (the bot's loop), or a factor on every floor (heat). Each 2,000 + 2,000 runs took about 60 s. |
| **K** (careers) | 100 careers of 20 runs each (seeds 50000 + 100 × career + run), no unlocks at the start; after each run the bot buys every unlock it can, cheapest first. |

The throwaway harness (`test/zz_tower_briefs_test.dart` and the temporary
hooks in three files of `lib/data/tower/`) was deleted and never committed.

What the figures mean:
- **Top**: share of runs that win floor 30.
- **Bands**: 1–10 is the share of all runs that clear floor 10; 11–20 is the
  share of runs entering floor 11 that clear floor 20; 21–30 is the share of
  runs entering floor 21 that win the top.
- **Run length**: the mean floor reached.
- **Picks**: cards actually chosen in a run (boons and clan oaths). The level-up
  stat picks are not counted.
- **Dead skill pick**: a skill card taken that, once learned, sits on no face
  of the die in play (so it never comes up in a fight).
- A floor's **death rate**: deaths on it over the runs that reached it.

The base, for every brief below:

| | top | 1–10 | 11–20 | 21–30 | median | run length | picks | dead skill picks |
|---|---|---|---|---|---|---|---|---|
| no unlocks | **14.3%** | 84% | 49% | 35% | 19 | 19.3 | 6.0 | 28% (1,746 of 6,287) |
| all unlocks | **26.9%** | 94% | 58% | 50% | 22 | 22.1 | 8.7 | 31% (2,244 of 7,323) |

Death rates on the gates (no unlocks): floor 10 5.8%, 15 6.6%, 20 14.0%,
25 13.6%, **30 27.5%**. The worst ordinary floor is 26 at 8.6% (QA's report
counts refights and names floor 17 at 8.8%; the two counts differ slightly).

---

## 1. A harder climb above floor 10

**For the player.** The first ten floors stay as they are, so a new player
learns in peace. From floor 11 the foes hit a little harder and last a little
longer. Fewer runs reach the top, so a win means more.

**Numbers today.** The Tower's extra on each floor (`towerBudgets` in
`tower_tables.dart`, field `extra`, and the overrides `towerEventsExtras`
{20: .30} and `towerPeacefulExtras` {25: .42, 30: .34}). Floors 11–19: .31,
.31, .33, .33, .50 (warden), .34, .26, .26, .28; floor 20 .30; floors 21–29:
.30, .31, .33, .32, .42 (warden), .30, .31, .31, .30; floor 30 .34. All
foes also carry `towerPeacefulFoeScale` 1.17 (left alone: it would touch
floors 1–10 too).

**Numbers to move (option B).** Floors 11–20 ×1.08, floors 21–29 ×1.06,
floor 30 unchanged:
- floors 11–19: .335, .335, .356, .356, .54, .367, .281, .281, .302;
  floor 20 (`towerEventsExtras`) .324;
- floors 21–29: .318, .329, .350, .339, .445 (`towerPeacefulExtras` 25),
  .318, .329, .329, .318.

**Estimate (V, seeds 1–2000; C for option B).**

| Option | top none | top all | 1–10 | 11–20 | 21–30 | median | floor 20 reached | worst ordinary floor |
|---|---|---|---|---|---|---|---|---|
| today | 14.3% | 26.9% | 84% | 49% | 35% | 19 | 48% | 26: 8.6% |
| A: floors 11–29 ×1.06 | 11.1% | 21.9% | 84% | 42% | 32% | 17 | 42% | 26: 10.3% |
| **B: 11–20 ×1.08, 21–29 ×1.06** | **10.1%** | **21.1%** | 84% | 38% | 32% | 17 | 39% | 17: 10.6% |
| B on the check seeds | 10.2% | 18.9% | 85% | 38% | 32% | 17 | 40% | 26: 11.1% |
| C: the floor 30 boss ×1.12 only | 11.8% | 22.0% | 84% | 49% | 29% | 19 | 48% | 26: 8.6% |
| (B with 11–20 ×1.10) | 9.4% | 20.1% | 84% | 35% | 32% | 17 | 37% | 19: 10.9% |

- Option B brings the top, the median and nearly the floor-20 share into the
  bands, and floors 1–10 do not move at all (84.0% clear floor 10 in both).
- Run length falls from 19.3 to 18.0 floors (none), 22.1 to 21.0 (all).
  Picks fall a little: 6.0 → 5.7, 8.7 → 8.4.
- Option C fixes the top only and turns floor 30 into a wall (40% of
  those who reach it die there, 27.5% today).
- In B, one or two ordinary floors pass the 10% that an ordinary floor may
  kill (17 or 26, about 11%). Shaving those two floors back to ×1.04 should
  fix it; not measured.

**Risk.** Balance: low; one table. The guards of `qa_tower_sim_test.dart`
(QA's file) need new bands: `_topAll` is 23–37% today, and B gives 19–21%.
Saves: none (a run saved mid-climb plays the new extras from its next floor).
No work for UX, Narrative or Art.

**Size.** S.

**Decision.** Where should the Tower get harder?
- A. Floors 11 to 29, ×1.06 (the top in band, floor 20 still reached by 42%).
- **B. Floors 11–20 ×1.08 and 21–29 ×1.06. (Recommended:** every band met,
  the first ten floors untouched, two floors to smooth.)
- C. Only the floor 30 boss (one number, but a 40% wall at the end).

---

## 2. No dead skill picks

**For the player.** When you take a skill and your die has no free Skill face
for it, the card says so and offers "**Rank up** X" instead: one skill already
on your die gets one tier stronger. Every pick shows up in the next fight.

**Numbers today.** Skill cards are the only skill source in a run. With no
unlocks, **28%** of the skills taken land on no face (1,746 of 6,287), 31%
with all unlocks. With more boon floors (brief 3, six more) this rises to
**49%**. The headless fight has no skill tiers; the story's rule
(`applySkillTier`, +25% to the flat number and +0.1 to the multiplier a tier,
tiers 0 to 3) exists.

**Numbers to move.** None in the tables. A rule in `towerOfferFor`
(`tower_rewards.dart`): a skill that would land on no face (as
`simSkillAssignments` places it) becomes a rank-up card for the best skill on
the die. A new run field, the tiers taken (`TowerRun`, new key).

**Estimate.** A calculation, not a run (the headless fight has no tiers).
About 1 dead pick a run (none) and 1.1 (all). A tier makes one face about
15 to 20% stronger; skill faces are 1 to 3 of 6. So about +1 to +2 points
on the top. With brief 3, about 2 to 3 rank-ups a run.

**Risk.** Balance: low (pay it back with brief 1's numbers). Saves: one new
field; old saves read none. UX: the card's label and a tier mark on the face
(**needs pictures first**). Narrative: one line, English and French. Core:
tiers in the headless fight (`sim_combat`), which it lacks.

**Size.** M.

**Decision.** What should a skill that cannot land become?
- **A. "Rank up X", a tier for a skill on the die. (Recommended:** a pick
  that always counts, and a rule the story already has.)
- B. "Swap into face N": the player picks which skill it replaces.
- C. Leave it (a dead pick is a lesson in planning the die).

---

## 3. More boons in a run

**For the player.** More often after a fight, you choose between a skill, a
die and a spell. You shape the hero on the way up instead of five times.

**Numbers today.** `towerBoonFloors` = {5, 10, 15, 20, 25} (`tower_tables.dart`).
Clan oaths come on 35% of the other floors (`towerOathChance`) while a clan is
left. Picks a run: 6.0 (none; 2.8 of them oaths), 8.7 (all; 5.1 oaths).

**Numbers to move.** `towerBoonFloors` to {5, 10, 13, 15, 20, 23, 25, 28}
(option B).

**Estimate (V, seeds 1–2000).**

| | top none | top all | median | picks none / all | dead skill picks |
|---|---|---|---|---|---|
| today | 14.3% | 26.9% | 19 | 6.0 / 8.7 | 28% |
| A: six more (3, 8, 13, 18, 23, 28) | 18.1% | 31.3% | 20 | 9.5 / 12.5 | 49% |
| A with brief 1 (11–20 ×1.10) | 12.2% | 24.3% | 17 | 9.0 / 11.9 | 48% |
| **B: three more (13, 23, 28), with brief 1 B** | **11.2%** | **22.4%** | 17 | 6.8 / 9.7 | 37% |

- A boon is worth less than it looks: six more raise the top by only about 4
  points, because half the extra skills are dead (brief 2).
- B keeps the top in its band with brief 1 and adds a pick in the late
  floors, where builds come together.

**Risk.** Balance: low. Saves: none (a floor set). UX: none (the boon screen
exists). Do brief 2 first, or a third of the new picks are wasted.

**Size.** S.

**Decision.** How many boons should a climb hold?
- A. Six more (one every 2–3 floors): many picks, half dead without brief 2.
- **B. Three more, late (13, 23, 28). (Recommended:** in band with brief 1,
  a pick where the build matters.)
- C. Leave five.

---

## 4. Boss relics that change the build

**For the player.** After each boss (10, 20) and each warden (15, 25), you
pick one **relic** of three. A relic bends a rule rather than adding a number:
"Poison you apply lasts one more turn", "Block left at the end of your turn
hits the foe for half", "A 6 rolled on a Skill face casts it twice". Two or
three relics that agree make "a poison run" or "a shield run".

**Numbers today.** A boss or warden floor gives a boon (skill, die, spell)
one rarity step up, and a Gold chest at least. No item or card changes a
rule; the spoils' gear adds attack and armour only. The headless fight
already plays poison, block, stun, weaken, splash and pierce.

**Numbers to move.** A new table, `towerRelics` (about 12 to 15 relics,
three per build: poison, shield, crit/high rolls, healing, packs), each an
id, a tag and one rule. A run field `relics`. The bosses' boon stays.

**Estimate.** Not measured: the headless fight reads no relics yet, and each
relic is a rule in the fight engine. Expected: a top rise of a few points
for a bot that takes them blindly, more for a player who builds; brief 1's
numbers pay it back. Each relic must be measured alone before it ships.

**Risk.** Balance: medium (rule changes can stack). Saves: one new field.
UX: a relic card, a relic bar in the fight (**needs pictures first**). Art: a
relic icon each (about 15 PixelLab calls). Narrative: names and a line,
English and French. Core: one rule per relic in the fight and the headless
fight.

**Size.** L.

**Decision.** Should a boss give something that changes how you play?
- **A. One relic of three after each boss and warden (4 a run).
  (Recommended:** the clearest build moments, few enough to tune.)
- B. Relics only after the bosses (2 a run): less to build, less to tune.
- C. No relics; brief 2 and 3 only.

---

## 5. A risky door for better loot

**For the player.** On some floors two doors: the plain fight, or a harder
one (an Elite) with a better reward behind it. You choose by your health and
your build.

**Numbers today.** The shortcut (`towerShortcutShare` .15) already offers an
Elite fight, for skipped floors and a card on landing. It is taken in 67% of
the offers and won in 93% of them (QA's tally, 2,000 runs).

**What was tried (V, seeds 1–2000, with brief 1 at 11–20 ×1.10).** Before
floors 3, 8, 13, 18, 23 and 28, the bot fought the floor as an Elite
(`towerShortcutFloor`) for a plain boon when its health was 80% or more.

| Door | top none | top all | 1–10 | deaths on floor 13 |
|---|---|---|---|---|
| none (brief 1) | 9.4% | 20.1% | 84% | under 10.9% (not the worst floor) |
| floors 3, 8, 13, 18, 23, 28 | 8.6% | 18.1% | **78%** | 13.9% |
| floors 13, 18, 23, 28 | 7.8% | 16.7% | 84% | 15.2% |
| floors 13, 18, 23, 28 (brief 1 B) | 8.1% | 17.4% | 84% | 14.4% |

- **An Elite for a plain boon is a bad trade**: taken whenever health
  allows, it lowers the top by 1 to 3 points. The reward must be worth more
  than one boon: a relic (brief 4), or a boon two rarity steps up, plus
  marks.
- Doors on floors 3 and 8 make floors 1–10 harder (84% → 78% clear floor
  10): keep them from floor 11.

**Numbers to move.** A new share, `towerDoorShare`, on ordinary floors 11 to
29 not holding another event; the door's Elite as `towerShortcutFloor`
builds it; its reward a relic (brief 4) or a boon at rarity +2 and +2 marks.

**Risk.** Balance: medium (it tempts; the bot shows the cost). Saves: one
choice field, like `shortcut`. UX: the two doors on the floor screen (**needs
pictures first**). Narrative: one line each.

**Size.** M (S if built on the shortcut card).

**Decision.** What should the harder door give?
- **A. A relic choice (with brief 4). (Recommended:** a real temptation; the
  measured plain boon is not.)
- B. A boon two rarity steps up and +2 marks (no relics needed).
- C. No door: the shortcut is the risk choice.

---

## 6. Coins in the run: reroll, banish, a shop

**For the player.** The spoils give a few **Tower coins** (the run's gold,
gone at the end). At the merchant you spend them: reroll an offer, banish a
skill so it never comes back this run, upgrade a face, buy a boon. Saving
or spending is a choice on every landing.

**Numbers today.** The Tower gives no gold (`towerSpoilsFor` drops it). The
merchant (on 10, 20 and 5% of the floors from 2) sells a salve (3 marks) and
two potions (4 marks) for the **marks the run banks**, so buying costs
unlocks. 977 of 2,000 runs (none) buy something; 685 salves, 920 bundles.
Rerolls and banish do not exist.

**Numbers to move.** The chest's gold (already rolled, `rollLootBox`) kept as
coins; a price list: reroll 3, banish 3, face +1 6, a boon 10 (first values);
the merchant also on the floor after each warden (`towerShopFloors` {5, 10,
15, 20, 25}). The marks' prices stay, or move to coins (option A).

**Estimate.** Not measured (no coins in the bot). By calculation from the
chests' gold, a run would hold enough for about 3 to 5 buys; a boon bought
is worth about 0.7 points of top (brief 3's six boons gave 3.8). Each
reroll and banish cuts dead picks; none adds raw power.

**Risk.** Balance: low (bought boons are the one power source; price them).
Saves: one counter and a banished list. UX: the store panel grows (**needs
pictures first**). Narrative: item lines.

**Size.** M.

**Decision.** What should the shop take in a run?
- **A. Tower coins from the spoils; marks stay for unlocks only.
  (Recommended:** spending never costs the next run.)
- B. Keep marks as the only money, add reroll and banish to the stock.
- C. Leave the store as it is.

---

## 7. Heat levels for veterans

**For the player.** Once you have won the top, you can climb again at Heat
1, 2 or 3: harder foes, more marks, and a mark on the record. A new goal
after the first win.

**Numbers today.** None. A won run earns 61 marks; nothing is harder for
a veteran than for a newcomer except their unlocks.

**Numbers to move.** A run field `heat` (0 to 3), each level ×1.05 on every
foe (on top of `towerPeacefulFoeScale`), and +25% marks a level. Heat 1
opens when the top is won once; heat n+1 when heat n is won.

**Estimate (V, seeds 1–2000, all unlocks, with brief 1 at 11–20 ×1.10).**

| | top | median | clear floor 10 | marks a run |
|---|---|---|---|---|
| heat 0 | 20.1% | 20 | 94% | 32.7 |
| heat 1 (×1.05) | 14.7% | 19 | 92% | 29.9 |
| heat 2 (×1.10) | 8.7% | 17 | 90% | 27.0 |
| heat 3 (×1.15) | 6.3% | 16 | 84% | 24.7 |

Each level costs about 5 points of top; heat 3 with every unlock is about as
hard as today's climb with none. Marks are before the +25% a level.

**Risk.** Balance: low (opt-in). Saves: one field in the run, one in
`TowerProgress` (highest heat won). UX: a heat picker at the start and a mark
on the record (**needs pictures first**). Narrative: three names.

**Size.** M.

**Decision.** How should a veteran get a harder climb?
- **A. Three heat levels, ×1.05 a level, opened by winning the one below.
  (Recommended:** measured, simple, opt-in.)
- B. Heat that also adds rules (an affix more, no flask) instead of a scale:
  more flavour, needs its own batch.
- C. No heat.

---

## 8. Daily climb and a best-run record

**For the player.** Each day, one seed for everyone: the same floors, the
same offers. Your best daily floor and your best run (floor, hero, relics)
are kept on the Tower's front page.

**Numbers today.** A seed already fixes every floor and offer
(`towerRandom`), so the same seed gives the same tower on every device.
`TowerProgress` keeps marks, unlocks, `bestFloor`, `runs`, `wins`; no
record of which hero, no streak, no daily.

**Numbers to move.** The daily seed is the date's number (no server). New
`TowerProgress` fields: the best run (floor, race, calling, clans), the best
daily floor and its date. The daily gives no extra marks (option A), so it
cannot be farmed.

**Estimate.** Not a balance change; nothing to measure. The bot's batch on
seeds 1 to 2000 shows how much one seed varies: the median floor of a seed
is 19 with a wide spread, so a daily is fair only between players on the
same day.

**Risk.** Low. Saves: new fields with defaults. UX: a daily button and a
record card (**needs pictures first**). Narrative: two lines.

**Size.** S.

**Decision.** Should the Tower have a shared daily climb?
- **A. Daily seed and best record, no extra marks. (Recommended:** cheap,
  and a reason to open the Tower every day.)
- B. Best record only.
- C. Neither.

---

## 9. A second unlock tree

**For the player.** After the ten first unlocks, a second set: a second
start die for each calling, a start relic (brief 4), a people's own die, a
fourth clan oath at the start. Marks keep a use.

**Numbers today.** Ten unlocks, 210 marks (`towerUnlocks`). A run earns 28
marks (none) to 36 (all). In 100 careers of 20 runs (K), the bot owns every
unlock after a median of **7 runs** (4 to 10); with brief 1, 8 runs (5 to
11). After that, every mark is banked for nothing. Each unlock also adds 3%
max health (`towerHealthPerUnlock`) and a potion for every 5
(`towerUnlocksPerPotion`).

**Numbers to move.** Ten more entries in `towerUnlocks`, costs 40 to 80
(about 600 marks, 15 to 20 runs). Their power: options only, so the 3% and
the potions stay capped at the first ten (a new field, or count the first
tree only).

**Estimate.** By calculation: 600 marks at about 33 a run is about 18 more
runs before the tree is full. No change to the top if the new entries add
options and not raw power; each new die or relic is measured when it is
made.

**Risk.** Balance: low to medium (each start die must be a side-grade, as
the Tower's own dice faces are, `towerDieFaces`). Saves: the unlock ids are
saved as a set; new ids load as not bought. UX: the tree screen grows
(**needs pictures first**). Narrative: ten names. Art: a few dice.

**Size.** M.

**Decision.** What should marks buy after the first ten?
- **A. A second tree of ten options, no extra health. (Recommended:** a
  reason for 15 to 20 more runs without a stronger hero.)
- B. Cosmetics only (frames, a banner on the record).
- C. Nothing; heat (brief 7) is the late goal.

---

## 10. More variety per band

**For the player.** Each band of ten floors has its own feel. A floor may
carry a modifier you see before the fight ("Fog: the foes' first move is
hidden", "Blood moon: everyone hits harder", "Holy ground: heals are
doubled"), and the late floors bring foes you have not met yet.

**Numbers today.** Foes per band in the pool (`towerPoolOf`, the design's
count): 7, 9, 12, 14, 16, 18, 18, 18. So floors 21 to 29 (bands 6 to 8)
draw from the **same 18 foes**. Five affixes (`EnemyAffix`). Events a run,
from QA's tally (2,000 runs, none): a parley 1.5, a shortcut 1.1, a rival
0.75, a bargain 0.9, a setback and a merchant now and then; about 5 a run
over 19 floors.

**Numbers to move.** A table `towerModifiers` (about 6, two per band,
drawn on 20% of ordinary floors on a new stream after `board`, so no draw
of today moves); per band, a short list of foes that appear only there
(Core's `enemies.json`, `minChapter` and a Tower flag).

**Estimate.** Not measured: each modifier is a fight rule. Built to be
neutral (each one helps and hurts both sides), so the top should not move;
it needs one batch when built.

**Risk.** Balance: low if neutral. Saves: none (drawn from the seed). UX:
a modifier chip on the floor and in the fight (**needs pictures first**).
Narrative: names and lines. Art: maybe a tint per modifier.

**Size.** M (the modifiers), L with new foes.

**Decision.** How should the bands differ?
- **A. Floor modifiers first, two per band. (Recommended:** variety without
  new foes or pictures of foes.)
- B. New late foes first (needs Art).
- C. Leave the bands as they are.

---

## Recommended build order

Most effect for least risk first.

1. **Brief 1, option B** (S). Puts the top, the median and the floor-20
   share in their bands with one table; floors 1 to 10 untouched. QA re-bands
   its guards in the same wave.
2. **Brief 8** (S). Daily seed and record: no balance work, a daily reason
   to come back.
3. **Brief 2** (M). No dead skill picks: every pick counts. Needed before
   any brief that adds picks.
4. **Brief 3, option B** (S). Three late boons, measured in band with brief
   1.
5. **Brief 7** (M). Heat levels: measured, opt-in, the goal after the first
   win.
6. **Brief 6** (M). Coins, reroll and banish: more choice per landing.
7. **Brief 9** (M). A second tree once the first is bought in 7 runs.
8. **Brief 4** (L). Relics: the biggest build change, and the most tuning.
9. **Brief 5** (M), with brief 4's relics as the door's reward.
10. **Brief 10** (M to L). Floor modifiers, then new late foes.

After each step that moves power (2, 3, 4, 5, 6), Core re-runs the 2,000-seed
batch and nudges brief 1's numbers back into the bands.

## What could not be measured

- **Skill tiers** (brief 2): the headless fight has none; a calculation.
- **Relics and floor modifiers** (briefs 4, 10): each is a new fight rule.
- **Coins** (brief 6): the bot never shops with gold; a calculation.
- **The door** (brief 5) was measured with a plain boon only; with a relic
  behind it, it needs brief 4 first.
- **Professions and peoples** were not split in these batches; QA's next
  batch on the chosen numbers should check them.
- The bot takes every boon and door the same way; a real player chooses,
  so dead picks and door losses are likely lower in play.

## Held variant: floors 11–20 ×1.10

Branch `claude/core-tower-x110`, held until the user decides: floors 11 to 20
×1.10 in `towerClimbScale` (was ×1.08); 21 to 29 stay ×1.06, floors 1 to 10
and the top's boss as they were. QA's batch, 2,000 seeds, live floor events
(version 2), the base `claude/core-tower-build` against the variant:

| Measure | Band | ×1.08 (base) | ×1.10 (variant) |
|---|---|---|---|
| Top won, no unlocks | 5–12% | 13.0% | 13.0% |
| Top won, all unlocks | 15–25% | 25.4% | 24.7% |
| Median floor reached, no unlocks | 13–18 | 17 | 17 |
| Reached floor 20, no unlocks | 20–38% | 42.3% | 40.5% |
| Mean floor reached, no unlocks | | 18.35 | 18.15 |

Death rate per floor, no unlocks (deaths on it / runs reaching it; 15, 20
and 25 are the warden and boss floors, not ordinary):

| Floor | 11 | 12 | 13 | 14 | 16 | 17 | 18 | 19 | 21 | 22 | 23 | 24 | 26 | 27 | 28 | 29 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ×1.08 | 6.9 | 6.6 | 6.8 | 5.5 | 7.5 | 9.0 | 7.2 | 7.7 | 9.5 | 7.4 | 8.2 | 9.3 | 9.6 | 8.3 | 6.8 | 7.3 |
| ×1.10 | 7.2 | 6.7 | 7.5 | 5.8 | 8.1 | 9.5 | 7.2 | 9.3 | 8.1 | 7.1 | 7.6 | 9.2 | 8.1 | 7.2 | 6.6 | 6.8 |

Floors 15 / 20 / 25: 9.2 / 15.5 / 14.8% at ×1.08, 9.3 / 18.0 / 14.1% at
×1.10. No ordinary floor is over 10% in either. The variant moves the deaths
forward (floors 16 to 20, the floor-20 boss most) rather than adding them:
the same 259 runs win the top with no unlocks, the all-unlocks top comes back
inside its band, and floor 20 reached falls about 2 points but stays over
its band. QA's in-suite bands (`qa_tower_sim_test.dart`) still hold
unchanged; `qa_tower_live_pin_test.dart` is re-pinned (seeds 1 to 500:
56 / 197 / 8969 and 123 / 290 / 10511).
