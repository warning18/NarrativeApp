# Why the starter die is kept to the end (B1 + B2)

The user: "Dive balance and finding so that starter die is not kept until
the end." This note gives the cause with numbers, the smallest fix, and a
bounded before/after.

**Shipped in v1.759:** the dice change of §4, exactly as tabled, with the
numbers of §5. The rangers' follow-up (§6.1) shipped in v1.761 (§8). The
simulator's reach (§6.2) is with the user.

**Method.** I ran 50 runs: every race × profession pair, twice, with seed 11
and the competent policy (the same method as the +15% pass). I also ran the
same 50 with the naive policy, which is the policy the CI bands use.

To see what a die is worth, I valued it by `simDieValue`: the average worth
of a roll, in the simulator's units, with 3 base damage. The value was
computed two ways:

- **sim** is how the simulator fills a die today. It puts learned skills on
  open Skill faces only (`isOpenSkillFace`).
- **game** is what the game itself lets a player do (`isAssignableFace`). A
  skill can go on any face that isn't fixed. On a plain face it casts at 70%
  (`channeledPower`), and the copy limits apply.

The scratch code is not committed. It adds env switches to the simulator,
logs each die trial, shop and buy, and adds two test files. The fix patch is
kept in the scratchpad.

## 1. What happens today

In the base batch (competent, 50 runs), the starter die is still rolled at
the end in **28 of 50** runs:

| Profession | Starter kept at the end | What the others end on |
|---|---|---|
| Warrior | **10 / 10** | nothing |
| Ranger | **9 / 10** | lantern (a clan die) 1 |
| Rogue | **9 / 10** | lantern 1 |
| Mage | 0 / 10 | apprentice, vigil, arcane |
| Cleric | 0 / 10 | apprentice, court, cinder |

Mages and clerics leave the starter early. Warriors, rangers and rogues never
do.

## 2. The cause: the starter is the best skill die in the game

Skills are where a die's worth lies once a few are learned. A skill casts at
full power only on a **Skill** face; on a plain face it casts at 70%. So what
a die is worth late in the game comes down to one number: how much of its
roll weight lands on Skill faces the player can fill.

The free starter die has **38%** of its weight on such faces: three Skill
faces at 0.6 each on a d6. That beats **30 of the 35 dice**, among them
every warrior and ranger die for sale:

| Die | Share of weight on fillable Skill faces | Price | Who may roll it |
|---|---|---|---|
| shadow, twinfang | 60% | 115, 105 | rogue |
| stone | 58% | 95 | dwarf |
| apprentice | 42% | 60 | mage, cleric |
| **starter** | **38%** | 0 | everyone |
| void | 34% | 120 | everyone |
| arcane / flame / tide | 27% / 26% / 23% | 130 / 110 / 110 | mage / mage / cleric |
| iron / bulwark | **22% / 21%** | 90 / 100 | warrior |
| storm | **17%** | 100 | ranger |
| holy | 17% | 105 | cleric |
| the big dice (tempest, chorus, gambler, sage) | 5–14% | 125–200 | everyone |

This matches who keeps the starter. Rogues have shadow and twinfang, which
beat it, but the simulator can't reach the shop that sells them (§3).
Warriors and rangers have nothing for sale that beats it.

**Value against the starter.** This is the game's own fill, for a player who
knows their profession's best 1, 2 or 4 skills. It covers the dice they can
buy:

| Profession | Die (price, where) | 1 skill | 2 skills | 4 skills |
|---|---|---|---|---|
| Warrior | iron (90, weaponsmith_forge, port, ch2) | +0.05 | −0.09 | +0.44 |
| Warrior | bulwark (100, hammersmith_forge, house, ch3) | −0.21 | +0.45 | +0.48 |
| Ranger | storm (100, black_market_docks, port, ch2) | −0.72 | −0.26 | −0.72 |
| Mage | flame (110, arcane_bazaar, ch2) | −0.73 | −0.77 | −0.64 |
| Mage | arcane (130, arcane_bazaar, ch2) | −0.18 | −0.40 | −1.15 |
| Cleric | holy (105, wayfarer_caravan, road event) | +0.20 | +0.54 | −0.37 |
| Cleric | tide (110, anchorage_chandlery, ch6) | −0.61 | −0.32 | −0.66 |
| Rogue | shadow (115, sharpweave_den, house, ch3) | +2.48 | +2.12 | +1.09 |

A typical gap between two dice is 0.5. The simulator's own fill rates each
profession die 0.5 to 1.9 lower again than the game's fill. So the simulator
undervalues them as well.

The one die that beats the starter for everyone is **void_die** (+0.2 to
+2.3, 120 gold). It is sold only in smugglers_vault, a house shop.

## 3. Things the simulator misses

These gaps don't make the game worse, but they hide some of the dice:

1. **Port shops are never visited.** These are `ports.json` `shopIds`,
   including weaponsmith_forge, black_market_docks and shieldwrights_hall.
2. **House shops are never visited.** These are arcane_academy,
   hammersmith_forge, sharpweave_den and smugglers_vault.
3. **wayfarer_caravan is never visited.** It is a road event
   (`road_events.dart`), and it is the only seller of holy_die.
4. **Each shop is visited once**, often at level 2–3 with 1–47 gold, so a
   100-gold die is never affordable.
5. **Skills go on open Skill faces only**, while the game allows any face
   that isn't fixed.

As a test, I let the simulator visit every port and house shop
(`SIM_ALL_SHOPS`). The starter is then kept in **18 of 50** runs instead of
28. Rogues all move to shadow_die (10/10). Warriors (8/10) and rangers
(10/10) still keep it, which confirms that the dice, not the reach, are the
cause for them.

## 4. The smallest fix: give each profession's shop die the starter's share

**Proposed (data only, `dice.json`, 7 dice).** On each profession die sold in
a shop:

- turn one plain face into an open Skill face (weight 0.6, like the
  starter's "Profession Technique");
- raise the weakest signature faces to 0.5–0.6.

| Die | Face turned into an open Skill face | Signature weights | Skill share |
|---|---|---|---|
| iron | Heal 3 "Battlefield Bandage" | shield_bash 0.4 → 0.6 | 22% → 38% |
| bulwark | Defend 2 | stance 0.5 → 0.6, shield_bash 0.4 → 0.6 | 21% → 43% |
| storm | Heal 2 (and a Defend 2 weighted 1.0 → 0.6) | multi_shot 0.3 → 0.6, heavy 0.5 → 0.6 | 17% → 39% |
| holy | Defend 2 | smite 0.5 → 0.6, revive 0.3 → 0.5 | 17% → 38% |
| tide | Defend 2 | holy_light, purify, heavy → 0.6 | 23% → 39% |
| flame | Defend 1 | meteor 0.3 → 0.5, heavy 0.5 → 0.6 | 26% → 41% |
| arcane | Heal 2 | (none) | 27% → 36% |

Prices, shops, drop rates, the starter die, the clan dice and void_die are
unchanged. `void_banner` is not touched.

Two companions roll these dice as their signature die: Kelda (iron) and
Maren (holy). A companion doesn't set skills, so on their die the new open
face casts Heavy Blow, in place of a Heal 3 (Kelda) or a Defend 2 (Maren).
The batches below include them.

Value against the starter afterwards (game fill, 1 / 2 / 4 skills):

- iron +0.51 / +0.51 / +0.89
- bulwark +0.21 / +0.71 / +0.70
- holy +0.84 / +0.94 / +0.04
- flame +0.38 / +0.32 / −0.05
- storm +0.02 / +0.21 / −0.41
- tide and arcane are about even early.

Each profession now has a die that beats the starter once it is bought,
except the ranger at 4 skills (§6).

## 5. Before and after (50 runs, seed 11)

Fight win rate here is fights won ÷ fights fought over the whole run.

| Batch | Starter kept at the end | Fight win rate |
|---|---|---|
| Competent, simulator as is: before | 28 / 50 | 91.9% |
| Competent, simulator as is: after the fix | 26 / 50 | 93.3% (**+1.4**) |
| Competent, every shop reached: before | 18 / 50 | 95.6% |
| Competent, every shop reached: after the fix | **11 / 50** | 97.1% (**+1.5**) |
| Same, with one revisit per chapter: before | 18 / 50 | 94.8% |
| Same, with one revisit per chapter: after | **11 / 50** | 96.3% (**+1.5**) |
| Naive (the CI bands): before | 30 / 50 | 38.3% |
| Naive (the CI bands): after the fix | 30 / 50 | 38.3% (**±0**) |

With every shop reached, warriors go from 8/10 keeping the starter to 1/10:
8 of them buy the iron die in chapter 2. The fix moves fight win rates by
**+1.5 points at most**, under the 3-point limit. The naive simulator never
buys a die, so the CI bands don't move.

## 6. Still open, for the manager

1. **Rangers** still keep the starter (10/10 with every shop). The storm die
   is a d10: even with a fourth Skill face its many plain faces dilute it
   (−0.41 at 4 skills). The simulator also meets it only once, at level 2–3
   with under 50 gold. A ranger-specific pass (reshape storm, or sell
   huntsman_die, which nobody sells today) is a second, small PR, if wanted.
2. **The simulator's reach (§3)** is a fidelity fix, not a game change, but
   it **moves the naive bands by more than 3 points**: with every shop
   reached, naive goes from 38.3% to 44.6% (+6.3). So it comes back to the
   manager before I build it. It would also make the competent numbers read
   closer to the real game.

## 7. What the user would notice

A warrior who walks into the weaponsmith in chapter 2 finds an iron die
that is now plainly better than the starter. It has three faces to set
skills on, at full power, plus Attack 2 faces. The same holds for the
bulwark, holy and flame dice. Nothing changes for a player who keeps
the starter.

## 8. The rangers' follow-up (v1.761)

**What.** After v1.759 the storm die still trailed the starter once a
ranger knows four skills (−0.41). A ranger's best skills are strong
(trap_set, precision_thrust and lucky_strike score 4.0–4.5), so the die's
weak plain faces dragged it down: Defend 2 and Heal 2, at 1.6 and 1.4
against 7 or more for a skill face.

**The change:**
- Two more of the storm die's faces become open Skill faces: Wind Step
  (Defend 2) and Catch Your Breath (Heal 2). That puts 50% of its weight on
  Skill faces, against the starter's 38% and the shadow die's 60%.
- The storm die is also sold at **anchorage_chandlery** (a port, chapter
  6). Its only seller until now was the black market in chapter 2, where
  the simulated ranger arrives at level 2–3 with 1–47 gold and never buys
  it.

Value against the starter, under the game's fill:

| Skills known | v1.759 | v1.761 |
|---|---|---|
| 1 | +0.02 | **+0.86** |
| 2 | +0.21 | **+0.77** |
| 4 | −0.41 | **+0.25** |

**Before and after** (50 runs, seed 11, against v1.759):

| Batch | Starter kept to the end | Rangers on the storm die | Fight win rate |
|---|---|---|---|
| Competent, as it plays | 26 → 24 of 50 | 0 → 2 of 10 | 93.3% → 93.3% (±0) |
| Competent, every shop reached and revisited (scratch) | 11 → 10 of 50 | 0 → 1 of 10 | 96.3% → 96.3% (±0) |
| Naive (the CI bands) | 30 → 30 of 50 | 0 → 0 | 38.3% → 38.3% (±0) |

Every simulated ranger who reaches the chandlery with the gold buys the
storm die and passes its trial. Few reach it, because the simulator
seldom walks to that port. That is the reach gap of §3, which is with the
user.
