# Tower: coins and the marks shop, as built (rules PR, v2.10.0)

Core's rules for what the user approved in `docs/proposals/tower-coins.md`
(Core's note) and brief 6 of `tower-briefs-6-7-8-spec.md`: **Tower coins**
for one climb (earned in it, spent in it, lost at its end) and, after the
unlock tree, a **marks shop**: eight perks (two worn a climb), five banner
trims (no power) and the first-win bonuses. This PR has the rules, the save
fields, the bot and the strings. The coin chip, the Reroll and Banish
buttons, the stall's boon line, the three-tab shop, the perk slots on the
door and the end tally are UX's (v2.10.1), using the fields at the end.
Read with `tower-heat.md`.

Playable without UX's screens: coins are earned and the stall (salve,
bundle) takes them now, on today's stall screen (its wallet line reads
coins). Reroll, banish, the stall's boon and the marks shop have no screen
yet, so the player cannot reach them until v2.10.1.

## The rules

### Coins earned (brief 6's table, as specced)

| Floor won | 1-10 | 11-20 | 21-29 |
|---|---|---|---|
| ordinary | 1 | 2 | 3 |
| Elite (`TowerFloor.elite`, a shortcut's Elite or Elite pack) | +1 | +2 | +3 |
| warden (5, 15, 25) | 3 | 6 | 9 |
| boss (10, 20) | 5 | 10 | — |
| the top (30) | none: the climb ends, its coins with it | | |

- Paid in `towerAfterFight` with the spoils, on a floor won **for the first
  time** (`towerCoinsFor(towerFloorOf(run, data))`). A floor met again, a
  parley passed and a floor skipped pay none. A lone foe's own Elite roll in
  the fight (not the floor's) pays no bonus: the run never sees it.
- **Heat multiplies marks, never coins.** Flame's extra Elites (Heat 3+) do
  pay their Elite bonus, as any Elite.
- No cap. `TowerRun.coins` (in hand) and `TowerRun.coinsEarned` (the tally;
  Purse's start coins are not "earned").
- **Lost at the end**: `TowerProgress.afterRun` banks the marks only. The
  ended run keeps its `coins` for the end tally ("coins left: n (lost)").

### Coins spent

| Buy | Price | Limit | Function |
|---|---|---|---|
| reroll a table | 3, then +2 each further reroll of that table (3, 5, 7…) | none | `towerReroll` |
| banish a card | 4 | one a table, 5 a run | `towerBanish` |
| salve (40% health) | 4 coins (was 3 marks) | one a stall | `towerBuy(run, data, 'salve')` |
| potion bundle (2) | 5 coins (was 4 marks) | one a stall, room in the bag | `towerBuy(run, data, 'potions')` |
| the stall's boon | **20** coins (the note's 15, raised: below) | one a stall | `towerBuy(run, data, 'boon')`, then `towerTakeStallBoon` |

- **The stall takes coins only** (brief 6 option A, the note's decision 6):
  marks are never spent in a climb. A sworn clan's merchant halves its three
  prices, rounded up (salve 2, bundle 3, boon 10). Reroll and banish keep
  their price. `TowerRun.marksSpent` stays for a run saved mid-climb before
  this version (it banks what it would have).
- **Reroll**: any table with a card that is not an oath (an oath alone is not
  rerolled). The table is drawn again on a new stream, `TowerStream.reroll`
  (`floor × 16 + n`), so no draw of the climb moves and a seed still gives
  the same tower. A boon floor redraws its skill, die and spell; a clans'
  table redraws its gifts. **The oaths on the table stay**, first. The cards
  just shown are kept off the new table while other cards are left. Cards
  taken or banished never come back.
- **Banish**: a skill, a die or a spell (a clan's gift skill too); never an
  oath or a rank-up. Off the table, not refilled (a reroll does that), never
  offered again this run (`TowerRun.banished` joins
  `TowerHeroView.takenIds`).
- **The stall's boon**: three cards as a boon floor's (a skill or its
  rank-up, a die, a spell), drawn on `TowerStream.reroll` at `floor × 16 +
  15`, at the store floor's rarity. They wait on `TowerRun.stallOffer`; the
  card taken goes to `TowerRun.stallBoons[storeFloor]` and is replayed by
  `towerHeroOf` after that floor's own card. Leaving the stall (or the next
  fight) with the boon not chosen gives its first card, so a climb never
  stalls.

### Perks (marks, after the tree, two worn)

Bought once with marks **once the ten unlocks are all bought** (the note's
"shop after the tree"; the task left it open, so it is required). A perk
bought is worn at once while a slot is free. Two slots whatever is owned.
Perks give no health (only the ten unlocks do). Worn at every Heat. Chosen
at the door (`TowerProgress.worn`), fixed for the climb (`TowerRun.perks`).

| Perk (id) | Price | Effect as built | Lever |
|---|---|---|---|
| Purse (`purse`) | 30 | 5 coins in hand at the start | `towerPurseCoins` |
| Deep pockets (`deep_pockets`) | 30 | the bag holds 6 potions, not 5 (the chest's overflow, the setback's potion and the bundle all read it) | `towerBagCapOf(run)` |
| Early word (`early_word`) | 35 | the late oath 3 floors sooner: floor 12, not 15 (15, not 18, at Pyre) | `towerEarlyWordFloors` |
| Old friend (`old_friend`) | 40 | one clan of the run's pool starts as if it had given one gift (+2, its allies +1, its rivals −1 or −2 at Ash); the clan is chosen at the door (`friend`), else the pool's clan the seed points to | `TowerRun.friend`, `towerStandingCardsOf` |
| Second wind (`second_wind`) | 40 | +15% of max health back after a warden or a boss won, on top of the floor's recovery | `towerSecondWindShare` |
| Keen eye (`keen_eye`) | 45 | the first boon table's (floor 5) skill one rarity step up (dice and spells draw no rarity) | `towerKeenEyeSteps` |
| Free hand (`free_hand`) | 45 | the climb's first reroll costs nothing (that table's next costs 5) | `towerRerollPriceOf` |
| Fourth card (`fourth_card`) | 60 | the first two boon tables (floors 5, 10) show a fourth card, a second skill (or its rank-up), rerolls of them too | `towerFourthCardTables` |

Eight perks, 325 marks.

### Looks and bonuses

- **Five trims** at 10 marks each (`moth`, `stitch`, `brass`, `bone`,
  `lamp`), after the tree, no power. The one shown is `TowerProgress.trim`.
  The **Ash trim** (`ash`) is owned once Heat 5's top is won
  (`heatWon == 5`), never sold.
- **First-win bonuses** (marks, once each, not raised by Heat): the first win
  of the top **+30** (necessarily at Heat 0); the first win at each Heat 1
  to 5 **+20**. A win above `heatWon` is that Heat's first (Heat n opens
  only with a win at n − 1), so no new save field. A save from before Heat
  with a win (read as `heatWon` 0) is not paid the +30 again.
- Everything: the tree 210 + perks 325 + trims 50 = **585 marks**.

### Deviations from the note, and why

1. **The boon costs 20, not 15.** The note's own rule: with the two
   strongest perks (Keen eye and Second wind) the top with every unlock was
   **32.2%** at 15, over QA's 18 to 32% band. At 20 it is **31.9%**. The
   other lever, one perk slot, leaves 30.3% (Keen eye alone, boon 15); not
   taken, since the user approved two slots. The foe scale is untouched.
2. **The stall's boon is not in `TowerEventView.stock`** but its own line
   (`TowerEventView.boon`), so today's stall screen does not show a line it
   cannot open yet.
3. Four stall strings change their **text** (keys kept) to coins:
   `tower_merchant_wallet` (Narrative's wording), `tower_merchant_body`,
   `tower_merchant_price`, `tower_merchant_price_one` (Core's placeholders:
   "paid in Tower coins", "{n} coins", "{n} coin"; Narrative to reword).
4. `TowerRun.banished` is a map floor → id (the spec's set), to hold "one a
   table"; `banishedIds` is the set.

## The numbers

The bot (`playTowerRun`), seeds 1 to 2000, floor events 2 (live), "none" no
unlocks, "all" every unlock. The bot's coins (`TowerBotCoins.full`): at a
stall the salve under 60% health, then the boon when the coins are there
(its card picked as a boon floor's), then the bundle at 3 potions or fewer;
one reroll of a boon table that deals no skill (the bot takes a skill first);
it never banishes (it has no notion of a card it does not want).
`TowerBotCoins.stall` buys the salve and the bundle only, as it did with
marks.

### Coins a run (Heat 0, boon 20, no perk)

| | earned, mean | median | 90th pct | a won run | left at the end (lost) | spent | boons bought | rerolls | salves | bundles |
|---|---|---|---|---|---|---|---|---|---|---|
| none | 39.3 | 33 | 79 | 80 | 20.3 | 19.0 | 0.53 | 2.26 | 0.33 | 0.41 |
| all | 51.4 | 52 | 82 | 80 | 27.5 | 23.9 | 0.75 | 3.08 | 0.27 | 0.12 |

A won run ends with 38 (none) to 42 (all) coins unspent: floors 21 to 29 pay 3 a floor
and no merchant stands after floor 20 save the 5% draw. That is the end
tally's "coins left (lost)".

### The top at Heat 0, coins and perks

| Variant | top none | top all | median none / all | reach f20 none / all | marks a run none / all |
|---|---|---|---|---|---|
| v2.9.0, before coins (`tower-heat.md`) | 11.1% | 25.9% | 17 / 22 | 42.2 / 61.8% | 25.9 / 35.4 |
| stall in coins, salve and bundle only (`stall`) | 11.1% | 25.9% | 17 / 22 | 42.1 / 61.8% | 28.6 / 36.8 |
| (a) coins, boon at 15 | 12.3% | 28.0% | 17 / 22 | 42.8 / 62.9% | 29.0 / 37.4 |
| **(a) coins, boon at 20 (built)** | **11.9%** | **27.5%** | 17 / 22 | 42.9 / 62.5% | 29.0 / 37.3 |
| (b) + Keen eye and Second wind, boon 15 | 14.6% | **32.2%** | 19 / 24 | 45.8 / 67.1% | 30.4 / 39.3 |
| **(b) + Keen eye and Second wind, boon 20 (built)** | **14.8%** | **31.9%** | 18 / 24 | 45.3 / 66.2% | 30.4 / 39.1 |

- Moving the stall to coins leaves the climb as it was (the same top, the
  same median) and banks the marks the stalls took: +10% / +4% a run.
- The coins' power is the boon (and the rerolls): +0.8 / +1.6 points at 20.
- The note guessed 26-27% for the coins and 29-32% with two perks: 27.5%
  and 31.9%.

Each perk alone (boon 15, all unlocks: Heat 0's 28.0% without):

| Perk | top none | top all | change, all |
|---|---|---|---|
| Keen eye | 13.5% | 30.3% | +2.3 |
| Free hand | 12.7% | 29.4% | +1.4 |
| Second wind | 13.0% | 29.3% | +1.3 |
| Purse | 13.2% | 29.2% | +1.2 |
| Deep pockets | 12.8% | 28.2% | +0.2 |
| Early word | 12.3% | 28.2% | +0.2 |
| Fourth card | 12.7% | 27.4% | −0.6 |
| Old friend | 12.6% | 26.8% | −1.2 |

Pairs, all unlocks: Keen eye + Second wind 32.2% (boon 15) / 31.9% (20);
Keen eye + Free hand 30.6% / 29.8%; Keen eye + Purse 30.9% (15). Noise is
about ±0.7 points on 2,000 seeds (less between variants on the same seeds).
Fourth card and Old friend measure at or under zero for the bot: it takes a
skill first and the first gift its best clan offers, so a fourth skill card
or a head start with a seed-picked clan rarely changes its pick. A player
who chooses the friend clan and reads a fourth card should do better.

### Heat 3 and 5 with perks (boon 20)

| Heat | no perk, none / all | Keen eye + Second wind, none / all | v2.9.0 all (no coins) | the note's target |
|---|---|---|---|---|
| 0 | 11.9 / 27.5% | 14.8 / **31.9%** | 25.9% | 24% |
| 3 Flame | 3.8 / 12.4% | 4.5 / **15.2%** | 11.8% | 11% |
| 5 Ash | 1.7 / 7.0% | 2.4 / **10.1%** | 6.8% | 5% (band 3-7) |

The note asks for the Heat targets **with two perks**: Heat 3 sits 4 points
over its target and Heat 5 is over its 3 to 7% band. Heat's levers are not
this PR's (open question below). Per calling at Heat 5 with the two perks:
cleric 13.8, mage 9.0, ranger 11.2, rogue 7.1, warrior 9.3%.

### Pace

Careers of the bot (a scratch harness, not committed, like the spec's):
40 careers from a fresh record, seeds 100001 on, each climb's marks banked
with its bonus, then the tree bought cheapest first, the perks in the order
Keen eye, Second wind, Free hand, Purse, Deep pockets, Early word, Fourth
card, Old friend, then the trims; the best two owned worn.

| | Heat 0 only | climbing Heat (the highest open each climb) |
|---|---|---|
| tree full (210) | climb 6 (4-9) | 6 (4-9) |
| first perk | 7 | 7 |
| **everything (585)** | **16** (14-18) | **14** (11-16) |
| marks a climb, mean | 38.6 | 45.3 |

Target 15 to 25: inside at Heat 0, a climb under it when climbing Heat. The
first perk comes one climb after the tree (target 1-2). The bot's marks a
climb are higher than the note's 26 to 35 because the stall's marks are now
banked and the bot wears its perks; real play by warriors and rogues earns
fewer (below), so a player's pace should be slower.

### Bot against real play

QA's real-fight sample (#1165, `docs/qa/tower-real-fight-2.8.1.md`): the bot
is about **19 points optimistic** per fight for warriors and rogues on the
floors it died on (mages within 3 once they cast). Read every top here lower
for a non-caster player, and the pace slower. The steps between variants
(what the coins and each perk add) are the useful measurement.

### The live pin

`qa_tower_live_pin_test.dart` (QA's) re-pinned on purpose: the bot plays the
coins (`full`, no perk) on the live Tower, seeds 1 to 500: none 51 / 205 /
9083 → **54 / 210 / 9159**, all 124 / 308 / 10862 → **141 / 316 / 11053**
(top, floor 20, floor sum). With `TowerBotCoins.stall` the climb plays as it
did with marks (the table above). QA's guards (`qa_tower_sim_test.dart`,
500 seeds, no perk) hold their bands.

## Fields for UX

Everything a coin chip, the Reroll and Banish buttons, the stall's boon
line, the three-tab shop, the perk slots on the door and the end tally need.
All in `lib/data/tower/` (`tower_coins.dart`, `tower_run.dart`,
`tower_progress.dart`, `tower_events.dart`) and
`lib/screens/tower/tower_providers.dart`
(`ref.read(towerProvider.notifier)`).

**The coin chip** (floor header): `run.coins` (`int`). Show it from the
first floor. Strings `tower_coins_name`, `tower_coins_chip` (`{n}`).

**The spoils line**: the coins a floor paid are
`towerCoinsFor(towerFloorOf(runBefore, data))` (the run before
`towerAfterFight`), or the difference of `run.coins`. Elite:
`floor.elite || floor.elitePack`. String `tower_coins_gained` (`{n}`).

**The card table** (`run.status == TowerStatus.choosing`):
- Reroll: shown when `towerCanReroll(run)`; price `towerRerollPriceOf(run)`
  (0 with Free hand's free one); greyed when it is over `run.coins`. Tap:
  `notifier.reroll(data: data)`. Strings `tower_reroll`, `tower_reroll_price`
  (`{n}`).
- Banish: on card `i` when `towerCanBanish(run, i)` (it checks the kind, one
  a table, five a run, the coins); price `towerBanishPrice`. Tap, confirm,
  then `notifier.banish(i)`. Strings `tower_banish`, `tower_banish_confirm`.
  Left this run: `towerBanishesPerRun - run.banished.length`.
- The table may hold **four** cards (Fourth card on floors 5 and 10).

**The stall** (`towerEventOf(run, data)` with `kind == merchant` and
`storeOpen`):
- `view.wallet` is now **coins** (`run.coins`); `view.stock` the salve and
  the bundle as before, prices in coins.
- `view.boon` (`TowerStockView`, id `towerStallBoonId` = `'boon'`, kind
  `TowerStockKind.boon`): `price` (20, 10 sworn), `amount` (3 cards),
  `bought`, `affordable`. Buy: `notifier.buyAtStall('boon', data: data)`
  (the salve and the bundle too: `buyAtStall('salve' | 'potions', ...)`).
  The three cards are then `run.stallOffer` (`List<TowerReward>`, drawn like
  a boon floor's): show them as the card table; take one with
  `notifier.takeStallBoon(i)`. Leave (`towerLeaveStore`) with them unchosen
  gives the first.
- Strings: `tower_merchant_boon`, `tower_merchant_boon_text` (the existing
  `tower_merchant_<id>` pattern), and Narrative's `tower_stall_coins_only`,
  `tower_stall_salve`, `tower_stall_salve_line`, `tower_stall_potions`,
  `tower_stall_potions_line`, `tower_stall_boon`, `tower_stall_boon_line`
  for the captions of the new sheet. `tower_merchant_wallet` and
  `tower_merchant_price(_one)` already read coins.
- The bag's cap is `towerBagCapOf(run)` (6 with Deep pockets).
  `tower_offer_view.dart`'s `bagFull: run.potions >= towerBagCap` should read
  `towerBagCapOf(widget.run)`.

**The marks screen's three tabs** (`progress = ref.watch(towerProvider)
.value!.progress`):
- Unlocks: as today (`towerUnlocks`, `progress.canBuy`, `notifier.buy`).
- Perks: `towerPerks` (`List<TowerPerk>`: `id`, `cost`, `nameKey`
  `tower_perk_<id>`, `lineKey` `tower_perk_<id>_line`); owned
  `progress.perks.contains(id)`, worn `progress.worn` (`List<String>`, two at
  most, in slot order); `progress.canBuyPerk(id)`; buy
  `notifier.buyPerk(id)` (worn at once when a slot is free). Locked until
  `progress.treeFull`: `tower_tree_full` once it is.
- Looks: `towerTrims` (`id`, `cost`, `nameKey` `tower_trim_<id>`) and
  `towerAshTrim` (never sold: `tower_trim_ash`); owned
  `progress.trimsOwned`; shown `progress.trim` (`String?`);
  `progress.canBuyTrim(id)`; buy `notifier.buyTrim(id)` (shown at once);
  show `notifier.showTrim(id)` or `showTrim(null)`.
- Strings: `tower_marks_tab_unlocks`, `tower_marks_tab_perks`,
  `tower_marks_tab_looks`, `tower_perk_owned`, `tower_perk_worn`,
  `tower_perk_worn_n` (`{n}`), `tower_perks_hint`, `tower_tree_full`.

**The door's perk slots** (beside the Heat picker; hide them while
`progress.perks` is empty): two slots, `towerPerkSlots`;
`progress.wornPerks` is what the next climb wears. Change them with
`notifier.wearPerks([a, b])` or `notifier.toggleWorn(id)`. Old friend's clan:
pass it to `notifier.start(..., friend: clanId)` (one of `progress.clans`);
without it, the seed picks one; the run's is `run.friend`. Strings
`tower_door_perks`, `tower_door_slot` (`{n}`). The run's perks:
`run.perks`, `run.wears(id)`.

**The end tally** (`before` = the progress read before `end()`):
- floors `run.floorsCleared`, wardens and bosses won (from it with
  `towerBudgetOf(f).kind`), refusals `run.refused.length`, Heat
  `run.heat` with `towerHeatMarksFactor(run.heat)`;
- first-win bonus `before.firstWinBonusOf(run)` (`int`, 0 none: show
  `tower_end_first_win` when not 0);
- banked `run.marks + before.firstWinBonusOf(run)` (what `end()` adds);
- coins left `run.coins` (`tower_end_coins_lost`, `{n}`; lost);
- next perk: `after.nextPerk` (`TowerPerk?`) and
  `max(0, nextPerk.cost - after.marks)` for `tower_perk_next` (`{perk}`,
  `{n}`), once `after.treeFull`; `after.marksToBuyAll` is the whole shop
  still to buy.
- Strings `tower_end_fell` (`{n}`), `tower_end_floors`, `tower_end_wardens`,
  `tower_end_bosses`, `tower_end_refusals`, `tower_end_heat` (`{heat}`,
  `{n}`), `tower_end_first_win`, `tower_end_banked`, `tower_end_coins_lost`.

**Strings** (in `app_strings.dart` after `tower_heat_ash_done`, EN and FR,
Narrative's wording from `tower-heat-and-coins-wording.md` §C-F and the coin
keys of `tower-offers-and-briefs.md` §4). Narrative's `tower_coins_lost` is
not added (it repeats `tower_end_coins_lost`).
