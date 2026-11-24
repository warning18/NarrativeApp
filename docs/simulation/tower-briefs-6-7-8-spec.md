# Tower briefs 6, 7 and 8: rule specs (not built)

The rules, numbers, save keys and screens for three briefs of
`docs/simulation/tower-roguelike-briefs.md`, so UX can draw them and Core can
build them later. **Nothing here is built and no number of the game has
moved.** Each spec ends with the decisions left to the user.

Base: the Tower of v2.4.0 (branch `claude/core-tower-build`: briefs 1 B, 2 A
and 3 B built; floor events version 2). Every figure is tagged:

| Tag | Meaning |
|---|---|
| **M** (measured) | Core's live bot (`playTowerRun`, `tower_bot.dart`), seeds 1 to 2000, once with no unlocks ("none") and once with all ("all"), with a temporary in-memory hook where said. The hooks and the harness (`test/zz_spec678_test.dart`, three hooks in `tower_floors.dart`, `tower_rewards.dart`, `tower_bot.dart`, `towerShopFloors` made non-const) were reverted and never committed. |
| **C** (calculation) | Arithmetic on the measured numbers or the tables, not a run. |
| **P** (proposal) | A value chosen here, for the user to confirm. |

The base as measured here (M): the top **13.0%** none / **25.4%** all, median
floor 17 / 21, floor 20 reached by 42% / 60%, marks banked a run 26.8 / 34.8
(the brief's v2.4.0 row; 12.95% rounds to 13.0).

---

## 6. Tower coins: reroll, banish, the merchant

### The rule

- **Tower coins are a separate in-run currency.** They are earned only inside
  a run, shown only inside a run, and **lost when the run ends** (won, dead
  or abandoned). They are **not Ash Marks** and never turn into marks. Ash
  Marks (`TowerProgress.marks`, `tower_marks_name`) stay the one currency that
  lasts between runs, for the unlocks.
- A floor won **for the first time** pays coins with its spoils (the same
  moment `towerAfterFight` drops the chest). A floor met again (setback,
  `towerIsRevisit`) pays none; a parley passed pays none (it gives up the
  spoils); a skipped floor pays none; a shortcut's Elite pays as the floor it
  replaces plus the Elite bonus.
- Coins buy three things:
  1. **Reroll** the cards on the table (a boon's three, or an oath): the
     offer is drawn again. Any table, any floor.
  2. **Banish** one boon card on the table (a skill, a die or a spell, not an
     oath, not a rank-up): it is removed from the table and never offered
     again this run. The table is not refilled (a reroll does that).
  3. **The merchant's stock** (the stall that exists today, floor events PR 4,
     `towerBuy`): the salve and the potion bundle, plus a **boon** (a skill,
     a die and a spell to choose from, as a boon floor's).

### Earning (P, with the measured result)

A fixed table, not the chest's rolled gold: it shows the same number on
every floor of a kind, the player can count ahead, and luck does not move it.

| Floor won | Floors 1–10 | 11–20 | 21–29 |
|---|---|---|---|
| ordinary floor | 1 | 2 | 3 |
| an Elite (a lone foe made Elite, `TowerFloor.elite`, or a shortcut's) | +1 | +2 | +3 |
| warden (5, 15, 25) | 3 | 6 | 9 |
| boss (10, 20) | 5 | 10 | — |
| the top (30) | none: the run ends, coins are lost |

Measured (M, the coins counted beside the live bot's runs, nothing spent):

| | coins a run, mean | median | 90th pct | a won run | merchants met a run | coins in hand at a merchant (median) |
|---|---|---|---|---|---|---|
| none | 37.8 | 32 | 77 | 78 | 1.61 | 16 |
| all | 47.8 | 43 | 80 | 78 | 1.94 | 16 |

The alternative, the chest's own gold ÷ 5 (it is already rolled by
`rollLootBox` and thrown away), measured on the same runs: 43 / 54 coins a
run, about the same, but it swings with the fortune roll (an ordinary floor
of band 1 drops 2 to 13 gold at the 10th–90th percentiles, an Elite of band
2 18 to 66). Chest gold per kind, measured: band 1 ordinary 6.4, Elite 22,
warden 20, boss 21; band 2 ordinary 11, Elite 33, warden 31, boss 28; band 3
ordinary 20, warden 45.

**No cap** on coins held (the run ends them anyway). Max in a run, by the
table: about 120 (C: a run that clears 29 floors with many Elites).

### Spending (P)

| What | Price | Limit |
|---|---|---|
| Reroll the table | **3**, then +2 each further reroll of the same table (3, 5, 7…) | none; the rising price is the limit |
| Banish a card | **4** | one a table; at most **5** a run |
| Merchant: salve (heals 40%, `towerSalveShare`) | **4** coins (today 3 marks) | one a stall (as today) |
| Merchant: potion bundle (2 potions, `towerBundlePotions`) | **5** coins (today 4 marks) | one a stall, needs room in the bag (as today) |
| Merchant: a boon (skill / die / spell, choose one) | **10** | one a stall |

- A sworn clan's merchant halves its prices, rounded up (`towerStockPriceOf`,
  as today); reroll and banish are not the merchant's and keep their price.
- **Option A (recommended): the merchant's whole stock moves to coins**, and
  marks buy unlocks only. Measured today (M): the bot spends 2.2 marks a run
  (none) and 1.1 (all) in the stalls, 48% / 33% of runs buy something; moved
  to coins, a run banks those marks instead (+8% / +3% marks a run, C).
- **Where the merchant stands.** Today: after floors 10 and 20 always
  (`towerShopFloors`) and on 5% of the other floors' landings
  (`towerMerchantShare`); 1.6 a run (none), 1.9 (all) (M). The brief asks
  for the wardens' landings too: `towerShopFloors` {5, 10, 15, 20, 25}.

### Estimate

The bot cannot reroll or banish (it has no notion of a better table), so
those two are **not measured**. What was measured is the one coin buy that
adds power, the merchant's boon at 10 coins, as a proxy: when the bot meets a
merchant with 10 coins in hand it buys it, and the next floor won deals a
boon (skill, die, spell) in place of its usual offer. That is a floor later
than the real stall would (the stall is on the landing), so it slightly
undercounts.

| Variant (M) | boons bought a run none / all | top none | top all | median none / all | marks spent in stalls none / all |
|---|---|---|---|---|---|
| today (no coins) | — | 13.0% | 25.4% | 17 / 21 | 2.2 / 1.1 |
| merchants also after the wardens, no boon | — | 14.8% | 26.1% | 18 / 21 | 4.3 / 2.6 |
| **boon at 10, merchants as today** | 1.38 / 1.70 | **14.5%** | **29.2%** | 18 / 21 | 2.2 / 1.2 |
| boon at 10, merchants after the wardens too | 2.24 / 2.81 | 16.9% | 31.0% | 18 / 22 | 4.3 / 2.7 |

- A bought boon is worth about **+1.1 points** of top with no unlocks and
  **+2.2** with all (C, from the rows above), more than the brief's 0.7.
- At 10 coins with today's merchants, the top goes **above both bands**
  (12% and 25%) by 2.5 and 4 points. With the wardens' merchants too, by 5
  and 6. The wardens' extra merchants alone (more salves, still in marks)
  add 1.8 / 0.7 points.
- So the boon needs paying back: a higher price (15 would buy about one a
  run with today's merchants, C: coins in hand at a merchant have a median
  of 16), or brief 1's numbers one step up (the brief's 11–20 ×1.10 took
  about 0.7 / 1.0 point off). Neither was measured here.

Reroll and banish (C): neither adds raw power, each turns a weak table into
one the build wants. The bot's dead picks were 28% before brief 2; with
rank-ups they are gone, so the main use left is steering a build (a poison
skill instead of a block skill). Expected effect on the top: under a point.

### Data shape

`TowerRun` (`tower_run.dart`), new keys, all absent in an old save (read as
0 / empty, so a run saved before keeps climbing with no coins):

| Field | Type | JSON key | Meaning |
|---|---|---|---|
| `coins` | `int` | `coins` | coins in hand now (earned less spent) |
| `coinsEarned` | `int` | `coinsEarned` | coins earned this run (for the end screen and the record) |
| `rerolls` | `Map<int, int>` | `rerolls` | floor → rerolls bought on its table (the next price, and the draw index) |
| `banished` | `Set<String>` | `banished` | card ids banished (skills, dice, spells), never offered again this run |
| `bought` | (exists) | `bought` | the stall's ids; the new boon id `boon` joins `salve` and `potions` |

- The coins of a floor are added in `towerAfterFight`, beside the spoils
  (`towerCoinsFor(floor)`: a pure function of the floor's kind, band and
  Elite flag; tables `towerCoinsPerBand` {1, 2, 3}, `towerCoinsWarden` 3,
  `towerCoinsBoss` 5, `towerCoinsElite` 1, each × the band).
- A reroll draws from a **new stream** `TowerStream.reroll`, added last to
  the enum (`towerRandom(seed, floor × 16 + n, TowerStream.reroll)`), so no
  draw of today moves and a seed still gives the same tower.
- Banished ids join `TowerHeroView.takenIds` (already "never offered
  twice"), so `towerOfferFor` needs no new branch.
- `TowerProgress` and `towerMarksPrefsKey` are **not touched**: coins never
  reach the lasting record (only `coinsEarned` may go into the best-run
  record of brief 8, as a number).
- The stall's price switch (`towerStockPriceOf`) reads coins in place of
  marks; `TowerEventView.wallet` shows the coins. `TowerRun.marksSpent` stays
  for old saves (a run saved mid-climb with marks spent banks what it banks
  today).

### What the player sees (for UX; needs pictures first)

- **Floor screen, the run's header**: a coin chip with the count ("12"),
  beside the health and the bag. Not on the start screen, the marks screen
  or the end screen's total (coins are not marks).
- **Spoils view** (`tower_spoils_view.dart`): one line "+2 coins" with the
  chest's items, "+3" with a small "Elite" mark when it was one.
- **Card table** (`tower_offer_view.dart`): under the cards, a **Reroll ·
  3** button (the price shown, greyed when short); on each boon card a small
  **Banish · 4** action (a cross in a corner, then a confirm). A banished
  card leaves the table with a short fade.
- **Merchant's stall** (`tower_peaceful_cards.dart`): the wallet line reads
  coins, not marks; a third line, the boon at 10, opening the usual
  choose-one of three. The sworn half price shows as today.
- **End screen**: "Coins left: 9 (lost)" in small type under the marks, so
  the player learns they do not carry over. Optional (decision 6.5).

### Naming (Narrative)

Narrative's draft (`claude/narrative-drafts`, a90a276d,
`docs/narrative/drafts/tower-offers-and-briefs.md` §4) writes the stall's
lines in **marks** ("It costs marks; the Tower does not take silver",
`tower_shop_poor_line` "Not enough marks…", `tower_shop_bought_line`
"Marks counted…"). **That is right for today's stall and wrong under option
A**: once the stall takes coins, those three lines need a coin wording.
Keys Core would need and the draft lacks:

| Key (proposal) | What |
|---|---|
| `tower_coins_name` | the currency's name (placeholder "Tower coins"; Narrative may name it, not "marks") |
| `tower_coins_chip` | the header chip, `{n}` |
| `tower_coins_gained` | the spoils line, "+{n} coins" |
| `tower_coins_lost` | the end screen's "Coins left: {n} (lost)" |
| `tower_reroll` / `tower_reroll_price` | the button and its price `{n}` |
| `tower_banish` / `tower_banish_confirm` | the card action and its confirm |
| `tower_merchant_boon` / `tower_merchant_boon_text` | the stall's third line |
| `tower_shop_poor_line_coins`, `tower_shop_bought_line_coins` | coin versions of the two draft lines (or the draft's lines reworded, same keys) |

`tower_merchant_wallet` (exists) changes only its text, not its key.

### Risks

- The bought boon is the one power source; its price is the lever (see the
  table). Reroll and banish are unmeasured: a player who rerolls every table
  for an epic could gain more than the bot shows.
- Moving the stall to coins makes marks banked a run go up a little
  (measured spend 2.2 / 1.1 marks a run): the unlock tree fills slightly
  faster (brief 9's 7 runs, about the same, C).
- A save mid-run on update: no coins until the next floor won; fine.

### Decisions left to the user

1. **Earning**: the fixed table (recommended, 38 / 48 coins a run) or the
   chest's gold ÷ 5 (43 / 54, swings with luck).
2. **The stall**: option A, everything in coins, marks for unlocks only
   (recommended); B, marks stay for salve and bundle, coins only for reroll,
   banish and the boon.
3. **The boon's price**: 10 (measured: the top +1.5 / +3.8 points, over the
   bands), or 15 with today's merchants (about one a run, C; not measured),
   or 10 with brief 1's numbers raised to pay it back.
4. **More merchants**: as today ({10, 20}, recommended with a boon in the
   stock), or after the wardens too ({5, 10, 15, 20, 25}: +1.8 / +0.7 points
   alone, +3.9 / +5.6 with the boon at 10).
5. **End screen**: show "coins lost", or say nothing.

---

## 7. Heat levels 1–3

### The rule

- A run carries a **heat**, 0 to 3, chosen on the start screen before
  Climb. 0 is today's climb.
- **Heat 1 opens when the top is won once** (at heat 0); **heat n + 1 opens
  when the top is won at heat n**. The highest open is the default pick; any
  lower one can be chosen.
- Each heat multiplies **every floor's extra** (all 30, the bosses and
  wardens too, a shortcut's Elite on top) by a factor, on top of
  `towerClimbScale`, the events' extras and `towerPeacefulFoeScale`: one
  number in `_floorOf` (`tower_floors.dart`). Nothing else changes: same
  floors, same foes, same offers for a seed.
- The marks a run banks are raised **+25% a heat** (rounded down): heat 1
  ×1.25, 2 ×1.5, 3 ×1.75, on the whole of `marksEarned` (the stall's spend
  then comes off, as today; with brief 6 option A there is none).

### The numbers (M, re-measured on v2.4.0)

The factor is linear, as the brief measured it: heat 1 ×1.05, heat 2 ×1.10,
heat 3 ×1.15 (and ×1.20 for comparison). Every unlock is the case that
matters: a player who has won the top usually owns most of the tree.

| All unlocks | top | median floor | clear floor 10 | floor 20 reached | marks a run (before the bonus) | marks a run (with +25%/heat) |
|---|---|---|---|---|---|---|
| heat 0 | **25.4%** | 21 | 94% | 60% | 34.8 | 34.8 |
| heat 1 (×1.05) | **18.8%** | 20 | 92% | 52% | 31.6 | 39.5 |
| heat 2 (×1.10) | **13.0%** | 18 | 90% | 44% | 28.8 | 43.2 |
| heat 3 (×1.15) | **9.4%** | 17 | 85% | 39% | 26.4 | 46.1 |
| (×1.20) | 5.8% | 16 | 79% | 33% | 23.6 | 47.2 |

| No unlocks (for reference) | top | median | clear floor 10 |
|---|---|---|---|
| heat 0 | 13.0% | 17 | 84% |
| heat 1 | 8.8% | 16 | 81% |
| heat 2 | 5.2% | 15 | 77% |
| heat 3 | 3.0% | 14 | 74% |

- Each heat costs about 6, 6 and 4 points of top with every unlock (the
  brief's 5 a level on the older ×1.10 curve; the v2.4.0 climb is a little
  harder, so the same factor bites a little more).
- **Heat 2 with every unlock (13.0%) is today's climb with none (13.0%)**;
  heat 3 (9.4%) is still inside the design's no-unlock band (5–12%).
- Floors 1–10 feel it too: 94% → 85% clear floor 10 at heat 3. A heat that
  touches floors 11–30 only would keep the start gentle; not measured.
- By calling at heat 3, all unlocks (M): cleric 5.7%, mage 11.0%, ranger
  9.7%, rogue 9.6%, warrior 11.1%. The cleric, already the weakest with
  every unlock (17% at heat 0), falls furthest; at ×1.20 it wins 1.6%.
- A won run banks about 59 marks at every heat before the bonus (M; 61 less
  the stall), so 74 / 89 / 104 with it (C).

### Data shape

| Where | Field | Type | JSON key | Default (old save) |
|---|---|---|---|---|
| `TowerRun` | `heat` | `int` 0–3 | `heat` (written only when not 0) | 0 |
| `TowerProgress` | `heatWon` | `int` −1..3, the highest heat whose top was won | `heatWon` | −1, or **0 when `wins` > 0** (a player who has already won opens heat 1 at once) |
| `TowerProgress` | `winsAtHeat` | `List<int>` of 4 (optional) | `winsAtHeat` | `[wins, 0, 0, 0]` |

- `towerHeatOpen(progress)` = `min(3, heatWon + 1)`; heat 0 is always open.
- Tables (`tower_tables.dart`): `towerHeatScale` = [1.0, 1.05, 1.10, 1.15],
  `towerHeatMarks` = .25.
- `towerFloorsFor(seed, enemies, events:, heat:)` passes the heat to
  `_floorOf`; `TowerFloor` keeps it so the fight screen and the bot read the
  same extra. `towerMarksOf` takes the heat.
- `afterRun` raises `heatWon` when `run.status == won && run.heat >
  heatWon`.

### What the player sees (for UX; needs pictures first)

- **Start screen**: under the calling and before Climb, a **heat picker**:
  four steps (0 and the three heats), the locked ones dimmed with "Win the
  top at heat n to open"; each open step shows its name and line, and the
  marks bonus ("Marks +25%"). Hidden entirely until heat 1 opens (a new
  player never sees it).
- **Floor screen**: a small heat chip (flame and its number) in the header
  for the whole run; none at heat 0.
- **Fight screen**: nothing new (the foes are simply stronger).
- **End screen**: "Heat 2 · ×1.5 marks" beside the marks earned; on a win
  at the highest heat open, "Heat 3 is open".
- **The record** (brief 8): the heat of the best run.

### Naming (Narrative)

Narrative's draft §2 names the heats **Embers / Flame / Pyre** (FR Braises /
Flamme / Bûcher), keys `tower_heat_1..3` and `tower_heat_1..3_line`: kept.
One line to fix: `tower_heat_1_line` "Foes fight as they are" reads as no
change, but heat 1 is already harder (×1.05). Suggested sense: "Foes hit a
little harder; marks come a little faster." Keys Core would need and the
draft lacks: `tower_heat_0` (the plain climb's name in the picker),
`tower_heat_locked` ("Win the top at {heat} to open"), `tower_heat_marks`
("Marks +{n}%"), `tower_heat_opened` (the end screen's "{heat} is open"),
`tower_heat_chip` (`{n}`).

### Risks

- Balance: low (opt-in; heat 0 is untouched). The cleric is the outlier at
  high heat.
- Marks: heat pays more marks a run while the tree is not full; once it is
  (brief 9: a median of 7 runs), the bonus buys nothing. The real reward is
  the mark on the record.
- Saves: two fields with defaults, no migration beyond `wins` > 0 → heat 1
  open.

### Decisions left to the user

1. **The factors**: ×1.05 / 1.10 / 1.15 (recommended, measured 18.8 / 13.0 /
   9.4% with every unlock), or a steeper heat 3 (×1.20, 5.8%).
2. **Which floors**: all 30 (measured), or 11–30 only (the start kept
   gentle; not measured).
3. **Marks**: +25% a heat (recommended), or no marks bonus (heat for the
   record only).
4. **A heat picker that can go down**, or always the highest open.

---

## 8. Daily climb and best-run record

### The daily seed

- **Made from the date, offline, the same for everyone**: the player's
  **local calendar date** (yyyymmdd, e.g. 20261124), so two players on the
  same date get the same tower whatever the hour; no server, no clock
  check. `towerDailySeed(date) = (yyyymmdd × 2654435761 + 0x5DA1) &
  0x7fffffff` (P; any fixed mix; `towerRandom` mixes it again). A normal run
  keeps its random seed (`Random().nextInt(1 << 31)`); a clash with a daily
  seed is about 1 in 2 billion.
- **The same hero for everyone**: the day's seed also draws the people and
  the calling (`TowerStream.start`, as the bot draws them), among the
  **start** callings only (warrior, mage, rogue), and the run plays with
  **no unlocks** (`unlocksOwned` 0, no start dice or items) at heat 0. So the
  daily compares players, not trees.
- What is the same for everyone (a seed fixes it, `towerRandom`): the 30
  floors and their foes, the affixes, the offers, the spoils, the events,
  the stat-pick draws. What is not: the fights' own dice (the fight screen
  rolls its own), so two players' runs part from the first fight on.

### Attempts (P)

- **One attempt a day** (recommended): starting the daily marks the date as
  played; a death, a win or leaving ends it. The daily cannot be rerolled by
  quitting (leaving counts as the attempt). A daily in progress is saved like
  any run, in its own key (below), so a normal run can be played beside it.
- **No extra marks**: the daily banks the marks a normal run would (or none:
  decision 8.2), never more, so it cannot be farmed.

### The record (P)

`TowerProgress` gains a best-run record and a daily record:

| Field | Type | JSON key | What |
|---|---|---|---|
| `best` | `TowerRecord?` | `best` | the best normal run: highest floor reached, ties by the higher heat, then the shorter time |
| `bestDaily` | `TowerRecord?` | `bestDaily` | the best daily ever |
| `daily` | `TowerRecord?` | `daily` | today's daily (date included): shown on the start screen while the date is today |
| `dailyStreak` | `int` | `dailyStreak` | days in a row a daily was played (optional) |

`TowerRecord` (new class, its own JSON):

| Field | Type | JSON key |
|---|---|---|
| `floor` | `int` (floor reached, 30 = won) | `floor` |
| `won` | `bool` | `won` |
| `heat` | `int` | `heat` |
| `professionId`, `raceId` | `String` | `profession`, `race` |
| `clanIds` | `List<String>` (main first) | `clans` |
| `seconds` | `int`, time played (fights and screens, paused when the app is in the background) | `seconds` |
| `date` | `String` yyyy-mm-dd, the day the run ended | `date` |
| `seed` | `int` (a normal run's record can be shared and replayed) | `seed` |

- Time: a new `TowerRun.seconds` (`int`, key `seconds`), added by the floor
  and fight screens while they are on screen. An old save reads 0 and its
  record shows no time.
- The daily run is saved under a **third key** `tower_daily_v1` (the run's
  JSON plus its `date`), beside `tower_run_v1` and `tower_marks_v1`
  (`tower_save.dart`); a daily whose date is past is ended as abandoned when
  the app next opens (its record kept, its marks banked per 8.2).
- Old saves: `best` is absent; `bestFloor` (exists) keeps being shown until a
  run writes `best`.

### Estimate (M)

Not a balance change. What was measured is how much one day's tower varies:
100 dates (1 January to 10 April 2026, seed yyyymmdd), each played 20 times
by the bot with a fresh fight stream (the same tower, other dice), no
unlocks, the day's own people and calling:

| | value |
|---|---|
| runs that win the top, all 2,000 | 9.4% |
| a day's top share: median day / 90th pct / best day | 0% / 30% / 70% |
| a day's median floor: worst / 10th pct / median / 90th / best | 9 / 10 / 17 / 29 / 30 |
| share of the floor's spread due to the day's tower and hero (not the dice) | **38%** |
| top by the day's calling | mage 6.9%, warrior 11.0%, rogue 10.2% |

So days differ a lot: on more than half of the days the bot never wins the
top in 20 tries, on a good day 7 in 10. A daily is a fair race only between
players on the same day; comparing one day's floor with another's says
little. That is what the record shows (the date beside the floor), and why a
"best daily" is a weak record (decision 8.4).

### What the player sees (for UX; needs pictures first)

- **Start screen**: a **Daily climb** panel beside Climb: the date, the
  day's people and calling (so the player sees the hero before choosing),
  "One attempt"; once played, the result ("Floor 17 · 24 min") and "Next
  climb tomorrow" (Narrative's `tower_daily_done`, "The stairs reset at
  dawn"; local midnight, see risks).
- **Start screen, the record card** (replacing the "Best floor" line of the
  marks panel, `tower_start_screen.dart`): the best run (floor, or "Top"
  with its heat flame; people, calling, main clan's emblem; time; date), and
  the best daily below it.
- **Floor screen**: a "Daily" chip in the header during a daily, and the
  time played (small, optional).
- **End screen**: "New record" when the run beats `best` (or the daily
  beats `bestDaily`), with the old record struck under it.

### Naming (Narrative)

Narrative's draft §3 has `tower_daily_entry`, `tower_daily_done`,
`tower_record_best_floor`, `tower_record_fastest`, `tower_record_daily`,
plus `tower_record_marks` and `tower_record_streak`. Kept as named. This
spec's record holds floor, heat, hero, clans, time and date: the draft's
"most marks in one climb" and "longest streak of wins" are not in it
(decision 8.3). Keys Core would need and the draft lacks: `tower_daily_button`
(the panel's action), `tower_daily_one_attempt`, `tower_daily_hero` ("Today:
{race} {profession}"), `tower_daily_chip`, `tower_record_new` ("New
record"), `tower_record_time` (`{m}` min), `tower_record_none` (no record
yet). "Dawn" in `tower_daily_done` reads well but the reset is local
midnight.

### Risks

- Low. A player can move the phone's date to replay a daily; offline, that
  cannot be stopped and only cheats their own record (no marks bonus to
  farm).
- The fights are not seeded per player, so "the same tower" is the same
  floors and offers, not the same fights. Seeding the fight screen by the
  day would make two players' first fights identical; not proposed (it would
  touch the story's fight screen).
- A daily in progress at midnight stays playable until it ends (its date is
  saved); only a new daily needs the new date.

### Decisions left to the user

1. **Attempts**: one a day (recommended), or as many as wanted with the best
   kept.
2. **Marks**: the daily banks marks like a run (recommended), or none.
3. **What the record holds**: floor, heat, hero, clans, time, date
   (recommended); add "most marks" and "longest streak" (Narrative's draft
   has the labels).
4. **Best daily ever**: shown (the days vary 0–70% top, so it is mostly the
   luck of the day), or today's daily only.
5. **The daily hero**: drawn by the day among the start callings, no unlocks
   (recommended), or the player's own choice and unlocks (then it is not the
   same climb for everyone).

---

## Relic candidates (brief 4, not approved)

Brief 4 is not chosen and none of these is built or measured. About a dozen
relics, each a placeholder name and one rule, using only what the Tower
already plays (skills and their tiers, dice faces, health, potions, coins,
offers), so Art can base its prompts on them. Each would need its own batch
before it ships.

| # | Name (placeholder) | Effect | Build |
|---|---|---|---|
| 1 | Ember Vial | The flask holds one more potion each fight (`towerFlask` +1). | healing |
| 2 | Pilgrim's Knot | Health back after a floor won: 25% of max (today 15%, `towerRecoveryShare`). | healing |
| 3 | Iron Heart | +15% max health for the rest of the run. | shield |
| 4 | Warden's Plate | Every Defend face of the die in play blocks 2 more. | shield |
| 5 | Loaded Bone | The die's lowest-value face counts 2 more. | high rolls |
| 6 | Whetstone | Every Attack face hits 1 more. | high rolls |
| 7 | Scholar's Ribbon | Taken: every skill on the die rises one tier (`applySkillTier`, up to the max). | skills |
| 8 | Second Face | The first Skill face rolled in each fight casts its skill twice. | skills |
| 9 | Blood Price | +2 to the calling's damage stat, −10% max health. | high rolls |
| 10 | Antidote Charm | Starts each fight with an antidote in hand (the bag's are kept). | healing |
| 11 | Lean Purse | +50% Tower coins from every floor (brief 6). | coins |
| 12 | Haggler's Token | Merchant prices −2 coins (at least 1), rerolls cost 1 less (brief 6). | coins |
| 13 | Fourth Card | Every boon table shows a fourth card (a second skill). | offers |
| 14 | Open Hand | One free reroll of each boon table (brief 6). | offers |

Relics 11, 12 and 14 need brief 6 first; 8 needs a rule in the fight and the
headless fight (`sim_combat`), the others are numbers the run already holds.

---

## What was measured and what was not

Measured (M, the live bot, seeds 1–2000, none and all): coins earned a run
by the proposed table and by the chest's gold; merchants met a run and coins
in hand there; the marks the stalls take today; the merchant's boon at 10
coins (a proxy, one floor late), with the merchants of today and with the
wardens' landings added; heat ×1.05 / 1.10 / 1.15 / 1.20 on every floor
(top, median, floor 10 and 20, marks, by calling); the spread of 100 daily
towers played 20 times each.

Not measured:
- **Reroll and banish** (brief 6): the bot has no way to judge a table; a
  calculation only (under a point of top).
- The merchant's boon was measured as a boon dealt on the next floor won,
  not on the landing itself; the real stall would give it a floor sooner.
- **A heat on floors 11–30 only**, and heat compounding (1.05ⁿ) rather than
  linear (the two differ by under 0.01 at heat 3).
- **Time played** (brief 8): the bot has no clock; the record's time is the
  player's.
- The daily's fairness was measured with the bot's dice; players choose, so
  their spread within a day is likely wider.
- Professions were split for heat only.
