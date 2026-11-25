# Tower: coins and the marks shop, as built (rules PR, v2.10.0)

Core's rules for what the user approved in `docs/proposals/tower-coins.md`
(Core's note) and brief 6 of `tower-briefs-6-7-8-spec.md`: **Tower coins**
for one climb (earned in it, spent in it, lost at its end) and, after the
unlock tree, a **marks shop**: eight perks (one worn a climb), five banner
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
| the stall's boon | 15 coins | one a stall | `towerBuy(run, data, 'boon')`, then `towerTakeStallBoon` |

- **The stall takes coins only** (brief 6 option A, the note's decision 6):
  marks are never spent in a climb. A sworn clan's merchant halves its three
  prices, rounded up (salve 2, bundle 3, boon 8). Reroll and banish keep
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

### Perks (marks, after the tree, one worn)

Bought once with marks **once the ten unlocks are all bought** (the note's
"shop after the tree"; the task left it open, so it is required). A perk
bought is worn at once while the slot is free. **One slot** whatever is
owned (the user's decision of 25 November 2026; the first build had two). A
save from the two-slot build wearing two keeps the first
(`towerWornPerks`).
Perks give no health (only the ten unlocks do). Worn at every Heat. Chosen
at the door (`TowerProgress.worn`), fixed for the climb (`TowerRun.perks`).

| Perk (id) | Price | Effect as built | Lever |
|---|---|---|---|
| Purse (`purse`) | 40 | 5 coins in hand at the start | `towerPurseCoins` |
| Deep pockets (`deep_pockets`) | 40 | the bag holds 6 potions, not 5 (the chest's overflow, the setback's potion and the bundle all read it) | `towerBagCapOf(run)` |
| Early word (`early_word`) | 45 | the late oath 3 floors sooner: floor 12, not 15 (15, not 18, at Pyre) | `towerEarlyWordFloors` |
| Old friend (`old_friend`) | 50 | one clan of the run's pool starts as if it had given one gift (+2, its allies +1, its rivals −1 or −2 at Ash); the clan is chosen at the door (`friend`), else the pool's clan the seed points to | `TowerRun.friend`, `towerStandingCardsOf` |
| Second wind (`second_wind`) | 50 | +15% of max health back after a warden or a boss won, on top of the floor's recovery | `towerSecondWindShare` |
| Keen eye (`keen_eye`) | 55 | the first boon table's (floor 5) skill one rarity step up (dice and spells draw no rarity) | `towerKeenEyeSteps` |
| Free hand (`free_hand`) | 55 | the climb's first reroll costs nothing (that table's next costs 5) | `towerRerollPriceOf` |
| Fourth card (`fourth_card`) | 70 | the first two boon tables (floors 5, 10) show a fourth card, a second skill (or its rank-up), rerolls of them too | `towerFourthCardTables` |

Eight perks, **405 marks**: the note's prices +10 each (the user's
decision; the trims and the bonuses unchanged). Fourth card and Old friend
are kept as they are (the user's decision), though the bot gains nothing
from them (below).

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
- Everything: the tree 210 + perks 405 + trims 50 = **665 marks**.

### Deviations from the note, and why

1. **One perk slot, the perks +10 marks, the boon at the note's 15** (the
   user's decisions of 25 November 2026). The first build wore two perks
   and raised the boon to 20 to keep the top with the two strongest under
   QA's band (32.2% at 15, 31.9% at 20). With one slot the best single perk
   (Keen eye) leaves 30.3% at 15, inside it, so the boon is back at 15.
   **The Heat targets are read without perks** (the user's decision): no
   Heat retune (below).
2. **The stall's boon is not in `TowerEventView.stock`** but its own line
   (`TowerEventView.boon`), so today's stall screen does not show a line it
   cannot open yet.
3. Four stall strings change their **text** (keys kept) to coins:
   `tower_merchant_wallet` and `tower_merchant_body` (Narrative's wording,
   the body from §G of `tower-heat-and-coins-wording.md`: it names the boon
   and says the coins end with the climb), `tower_merchant_price`,
   `tower_merchant_price_one` ("{n} coins", "{n} coin", kept by Narrative).
   `tower_perks_hint` changes its text for the one slot (Core's, Narrative
   to reword).
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
marks. QA's batch wears one perk (`TOWER_PERKS=<id>`; of a list, the first
known id only).

### Coins a run (Heat 0, boon 15, no perk)

| | earned, mean | median | 90th pct | a won run | left at the end (lost) | spent | boons bought | rerolls | salves | bundles |
|---|---|---|---|---|---|---|---|---|---|---|
| none | 39.4 | 33 | 80 | 80 | 19.8 | 19.5 | 0.73 | 2.26 | 0.33 | 0.38 |
| all | 51.6 | 52 | 82 | 80 | 27.3 | 24.2 | 0.99 | 3.06 | 0.27 | 0.12 |
| all, Keen eye | 53.4 | 56 | 82 | 80 | 28.3 | 25.0 | 1.07 | 2.99 | 0.24 | 0.11 |

A won run ends with 41 (none) to 43 (all) coins unspent: floors 21 to 29 pay 3 a floor
and no merchant stands after floor 20 save the 5% draw. That is the end
tally's "coins left (lost)". The boon at 15 (was 20) is bought a third more
often (0.99 a run with every unlock, was 0.75).

### The top at Heat 0, coins and one perk

QA's band for the top with every unlock: 18 to 32%.

| Variant | top none | top all | median none / all | reach f20 none / all | marks a run none / all |
|---|---|---|---|---|---|
| v2.9.0, before coins (`tower-heat.md`) | 11.1% | 25.9% | 17 / 22 | 42.2 / 61.8% | 25.9 / 35.4 |
| stall in coins, salve and bundle only (`stall`) | 11.1% | 25.9% | 17 / 22 | 42.1 / 61.8% | 28.6 / 36.8 |
| **(a) coins only, boon 15 (built)** | **12.3%** | **28.0%** | 17 / 22 | 42.8 / 62.9% | 29.0 / 37.4 |
| **(b) + Keen eye, the best perk** | **13.5%** | **30.3%** | 18 / 23 | 45.1 / 65.5% | 30.0 / 38.6 |
| (b) + Free hand, the second | 12.7% | 29.4% | 18 / 23 | 43.5 / 64.0% | 29.2 / 38.0 |
| the two-slot build: boon 20, Keen eye + Second wind | 14.8% | 31.9% | 18 / 24 | 45.3 / 66.2% | 30.4 / 39.1 |

Both inside the band, with 1.7 points of room under its top for the best
perk. The coins' power is the boon and the rerolls: +1.2 / +2.1 points.

Each perk alone (boon 15, Heat 0; coins only: 12.3% / 28.0%):

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

Noise is about ±0.7 points on 2,000 seeds (less between variants on the
same seeds). Fourth card and Old friend measure at or under zero for the
bot: it takes a skill first and the first gift its best clan offers, so a
fourth skill card or a head start with a seed-picked clan rarely changes its
pick. A player who chooses the friend clan and reads a fourth card should do
better. Both kept as they are (the user's decision).

### Heat 3 and 5 (boon 15)

**The Heat targets are read without perks** (the user's decision): the
"no perk" column is the one held against them. No Heat retune.

| Heat | no perk, none / all | Keen eye, none / all | Free hand, none / all | v2.9.0 all (no coins) | the note's target |
|---|---|---|---|---|---|
| 0 | 12.3 / **28.0%** | 13.5 / 30.3% | 12.7 / 29.4% | 25.9% | 24% |
| 3 Flame | 3.8 / **12.6%** | 4.2 / 13.7% | 3.7 / 12.7% | 11.8% | 11% |
| 5 Ash | 1.7 / **7.3%** | 2.2 / 10.0% | 1.6 / 7.8% | 6.8% | 5% (band 3-7) |

Without perks Heat 3 is 1.6 points over its target and Heat 5 0.3 over its
band's top (inside the noise); both moved up by the coins (+0.8 and +0.5 on
v2.9.0), not by Heat. Per calling at Heat 5, every unlock, no perk: cleric
10.2, mage 6.2, ranger 8.3, rogue 3.9, warrior 8.3% (Keen eye: 14.1, 9.0,
11.7, 6.1, 9.3%).

### Pace

Careers of the bot (a scratch harness, not committed, like the spec's):
40 careers from a fresh record, seeds 100001 on, each climb's marks banked
with its bonus, then the tree bought cheapest first, the perks in the order
Keen eye, Free hand, Second wind, Purse, Deep pockets, Early word, Fourth
card, Old friend, then the trims; the best owned worn (one). Median, with
the 10th to 90th percentile.

| | Heat 0 only | climbing Heat (the highest open each climb) |
|---|---|---|
| tree full (210) | climb 6 (5-9) | 6 (4-8) |
| first perk | 8 (6-10) | 7 (5-10) |
| **everything (665)** | **18** (16-21) | **15** (12-18) |
| marks a climb, mean | 37.7 | 47.4 |
| the two-slot build (585), everything | 16 (14-18) | 14 (11-16) |

Target 15 to 25: inside both ways (climbing Heat at its floor). The first
perk comes one to two climbs after the tree (target 1-2): the cheapest is
now 40. The bot's marks a climb are higher than the note's 26 to 35 because
the stall's marks are now banked and the bot wears its perk; real play by
warriors and rogues earns fewer (below), so a player's pace should be
slower.

### Bot against real play

QA's real-fight sample (#1165, `docs/qa/tower-real-fight-2.8.1.md`): the bot
is about **19 points optimistic** per fight for warriors and rogues on the
floors it died on (mages within 3 once they cast). Read every top here lower
for a non-caster player, and the pace slower. The steps between variants
(what the coins and each perk add) are the useful measurement.

### The live pin

`qa_tower_live_pin_test.dart` (QA's) re-pinned on purpose: the bot plays the
coins (`full`, no perk) on the live Tower, seeds 1 to 500: none 51 / 205 /
9083 before coins, 54 / 210 / 9159 with the boon at 20 → **59 / 209 / 9208**;
all 124 / 308 / 10862, 141 / 316 / 11053 → **140 / 317 / 11037** (top,
floor 20, floor sum). With `TowerBotCoins.stall` the climb plays as it did
with marks (the table above). QA's guards (`qa_tower_sim_test.dart`, 500
seeds, no perk) hold their bands.

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
  `TowerStockKind.boon`): `price` (15, 8 sworn), `amount` (3 cards),
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
  `progress.perks.contains(id)`, worn `progress.worn` (`List<String>`, **one
  at most**: `towerPerkSlots` is 1); `progress.canBuyPerk(id)`; buy
  `notifier.buyPerk(id)` (worn at once when the slot is free; a later one
  is owned, not worn). Prices 40 to 70 (`perk.cost`). Locked until
  `progress.treeFull`: `tower_tree_full` once it is.
- Looks: `towerTrims` (`id`, `cost`, `nameKey` `tower_trim_<id>`) and
  `towerAshTrim` (never sold: `tower_trim_ash`); owned
  `progress.trimsOwned`; shown `progress.trim` (`String?`);
  `progress.canBuyTrim(id)`; buy `notifier.buyTrim(id)` (shown at once);
  show `notifier.showTrim(id)` or `showTrim(null)`.
- Strings: `tower_marks_tab_unlocks`, `tower_marks_tab_perks`,
  `tower_marks_tab_looks`, `tower_perk_owned`, `tower_perk_worn`,
  `tower_perk_worn_n` (`{n}`; with one slot `tower_perk_worn` is enough),
  `tower_perks_hint` (now "One perk is worn on a climb, chosen at the
  door.": Core's text for the one slot, Narrative to reword),
  `tower_tree_full`.

**The door's perk slot** (beside the Heat picker; hide it while
`progress.perks` is empty): **one slot** (`towerPerkSlots` = 1; draw
`towerPerkSlots` slots rather than a fixed count); `progress.wornPerks` is
what the next climb wears (empty or one id). Change it with
`notifier.wearPerks([id])` (of a longer list only the first owned id is
kept) or `notifier.toggleWorn(id)` (put on in place of the one worn, or
taken off when it is the one worn). Old friend's clan:
pass it to `notifier.start(..., friend: clanId)` (one of `progress.clans`);
without it, the seed picks one; the run's is `run.friend`. Strings
`tower_door_perks`, `tower_door_slot` (`{n}`, still fine: "Slot 1"). The run's perks:
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
