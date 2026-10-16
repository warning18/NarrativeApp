# Stat scale, damage stats and pick rarity (proposal)

Core, after the user's feedback on the level-up picks screen (v1.449).
Design only: nothing here is in the game yet.

What the user asked:

1. *(parked, UX)* the stat list becomes an ability radar later.
2. "Reward can be common, rare, epic etc depending on your luck."
3. "Each profession has a base damage improved by a specific stat. Ranger
   and rogue: more dexterity, also better at perception, and dex increases
   dodge too. Warrior: strength for damage, constitution increases HP,
   perception block rate? Mage: int increases damage, wisdom mana size.
   Cleric same as mage."
4. "Could you also reduce the stats scale, so each upgrade seems to count?"

---

## 0. What the game does today (v1.449)

| Stat | What it does in a fight today | Elsewhere |
|---|---|---|
| Base damage | Added to every Attack face and skill. Starts at 10 + race + profession (11 to 21), **+1 each level**, +1 per damage pick. | |
| Max health | 100 + race + profession (65 to 155), **+20 each level**, +10 per health pick, +2 a level from a sworn patron. | |
| Armor | Flat cut on every blow taken. Start + gear, +1 per armor pick. | |
| Strength, Dexterity, Constitution, Intelligence | **Nothing directly.** Only through gear: an item that "scales" with the stat adds half the stat to its damage or armor. Int and Wis also add half to the spells that scale with them. | Story checks (d20 + the stat), item requirements |
| Dexterity | Dodge = 5% + 1.5% per point, max 30% (reached at Dex 17). | |
| Luck | Critical hit = 5% + 1.5% per point, max 35%. Better sign rarity, loot. | |
| Wisdom | +half Wis on heals, +1 mana per 3 Wis on mana faces, shorter statuses. | |
| Int / Wis | Mana pool = 4 + half of the higher one. | |
| Perception | How much of the enemy's next move you can read. No block. | Checks |
| Charisma | Nothing in a fight. | −2% shop prices per point (max −20%), talk checks, gates |

**A pick** is one of three offers: +1 to an ability, +10 health, +1 damage or
+1 armor. 5 picks a level. Only the third offer can be "rare" (12%): +2, or
two stats at +1. That is 5 × 1.12 ≈ **5.6 points a level**.

**The scale is already big.** In the simulator, by level 10 the main stat
of a build is near 30 (Str 29, Dex 28 to 31, Wis 28), and 55 to 60 by
level 20. Health is 350 to 440 at level 10. So "+1 Str" moves a number of 29
and does nothing you can see, and "+10 health" moves 412. Story checks are
d20 + the stat against 10 to 16, so a main stat of 29 never fails one.

**Enemies** grow with the hero's level (+12% health and +8% damage per
level), with each chapter (+15% health per chapter, damage half as fast,
chapter 2 a tenth harder), and with a per-chapter floor (×1.46 health in
chapter 1, up to ×2.9 in chapter 5; bosses ×1.10). Any change to the
hero's growth has to move the enemies' per-level growth with it: that is
the knob used below.

---

## 1. Pick rarity: common, rare, epic, heroic

The tiers reuse the names of the signs (Common, Rare, Epic, Heroic).

**One roll per pick, for all three cards.** The pick's tier is drawn once,
and the three offers all show it ("Rare pick: +2"). The player still picks
the stat they want, so luck never fights the build, and the value of a pick
is exactly the tier's.

| Tier | What each card gives | Base odds (Luck 0) |
|---|---|---|
| Common | +1 to one stat | 90% |
| Rare | +2: the stat twice, or the stat and a second at +1 | 8% |
| Epic | +3: the stat +2 and a second +1 | 1.6% |
| Heroic | +4: the stat +2 and a second +2 | 0.4% |

**Luck:** each point of Luck moves 1% from Common up the tiers: 0.6% to
Rare, 0.3% to Epic, 0.1% to Heroic, up to Luck 15 (the signs' Luck cap).
At Luck 15 the odds are 75 / 17 / 6.1 / 1.9.

Expected points per pick, and per level for each option of section 3
(A: 5 picks a level, B: 2, C: 1):

| Luck | Per pick | A (5 picks) | B (2 picks) | C (1 pick) |
|---|---|---|---|---|
| 0 | 1.12 | 5.6 | 2.2 | 1.12 |
| 3 | 1.17 | 5.8 | 2.3 | 1.17 |
| 5 | 1.20 | 6.0 | 2.4 | 1.20 |
| 8 | 1.24 | 6.2 | 2.5 | 1.24 |
| 10 | 1.27 | 6.4 | 2.5 | 1.27 |
| 15 (cap) | 1.35 | 6.7 | 2.7 | 1.35 |

At Luck 0 a pick is worth what it is today (1.12). In the simulator,
whose builds carry a little Luck, the tiers came out 88% / 9% / 2.4% /
0.7%.

---

## 2. One damage stat per profession, and what each ability does

| Profession | Damage stat | Also leans on |
|---|---|---|
| Warrior | Strength | Constitution (health), Perception (block) |
| Ranger | Dexterity (damage **and** dodge) | Perception (reads, starts higher) |
| Rogue | Dexterity (damage **and** dodge) | Luck (crits), Perception |
| Mage | Intelligence | Wisdom (mana) |
| Cleric | Intelligence, as the user said (see the open question: Wisdom measured better) | Wisdom (mana) |

What each ability does in a fight (the same for everyone unless said):

- **Str / Dex / Int**: damage, for the professions above. For the others, no
  damage: Int still adds to Int spells, Dex still gives dodge.
- **Constitution**: max health.
- **Dexterity**: dodge, for everyone (capped at 30%).
- **Perception**: reads the enemy's next move, as today. For a warrior also
  a **block chance**: a blocked blow loses half its damage (capped at 30%).
- **Wisdom**: mana pool size (instead of "the higher of Int and Wis"), and
  it still adds to heals.
- **Intelligence**: spell damage (spells use the hero's damage, so a mage's
  Int counts twice: strike and spell).
- **Luck**: critical hits (as today) and pick rarity (section 1).
- **Charisma**: shop prices, talk checks, as today. No fight effect.

**Base damage becomes its own row on the card, but no longer grows by
itself.** Recommended: keep "base damage" as the number each hero starts
with (race + profession, as now), drop its +1 per level, and add the damage
stat on top: *damage = base damage + every point of the damage stat gained
since the hero was made*. The starting Str of an orc warrior is already in
their base damage, so a new hero hits exactly as today; from then on every
point is +1 (or +2, by option). The same holds for health and Constitution.
Picks no longer offer "+10 health", "+1 damage" or "+1 armor": those path
gains become +1 Con, +1 damage stat and +1 Con. Gear stops scaling with a
stat (that was the only way Str counted, and it would count twice).

---

## 3. A smaller scale: three options, measured

All three use sections 1 and 2. They differ in the size of the fight's
numbers and in how many picks a level brings.

| | A. Points that count | B. Fewer, bigger picks | C. Small numbers (recommended) |
|---|---|---|---|
| Fight numbers | as today | as today | **everything ÷5**: health, damage, armor, dice faces, heals, enemies |
| Picks a level | 5 | 2 | 1 |
| Damage stat +1 | +1 damage | +2 damage | +1 damage (= 5 today) |
| Con +1 | +10 health | +25 health | +5 health |
| Dex +1 | +1.5% dodge | +2% dodge | +2% dodge |
| Per +1 (warrior) | +1% block | +2% block | +3% block |
| Wis +1 | +½ mana | +1 mana | +1 mana |
| Each level | +20 health | +20 health | +4 health |
| Enemies per level (health / damage) | +17% / +9% (today 12 / 8) | +16% / +8% | +16% / +8% |
| A level-10 main stat | 18 to 43 | 10 to 20 | 6 to 13 |
| A level-10 hero's health | 390 to 520 | 440 to 610 | 74 to 102 |

Why C is ÷5 and not ÷10: the dice faces are worth 5 or 6. At ÷10 a face
would be 0.5, so all the dice would have to be redesigned. At ÷5 a face is 1
and the starting base damage 3 or 4: a hit reads "4", and "+1 damage" is a
quarter of it.

Why fewer picks: the game's damage grows about +2.4 a level today (the
level's +1 and about one damage pick in five). At ÷5 that is half a point a
level. Five picks of "+1 damage" a level would be ten times today's growth.
**A smaller scale and five picks a level can't both be had**: each pick
counts only if there are fewer of them. C trades five small picks for one
pick that you notice, and rarity makes that one pick more of an event.

### How it was measured

The playthrough simulator, 400 runs, seed 7, every story strategy and the
specialisations, with the training paths (so the picks are used). The
picks follow a simple build plan: the stat furthest below its share
(warrior: Str 60% / Con 30% / Per 10%; rogue: Dex 70 / Luck 15 / Con 15;
ranger: Dex 70 / Con 30; mage: Int 50 / Wis 30 / Con 20; cleric: Int 40 /
Wis 40 / Con 20, or Wis 70 / Con 30 when Wisdom is the cleric's damage
stat). The bosses were measured a second time the way
`test/boss_balance_test.dart` does (four strategies, no specialisations).
The ÷5 of option C was played by rounding every number of the fight to a
step of 5. That is close to the real ÷5 game but not the same thing: the
skills' small modifiers are not rounded.

Targets: about 70% of encounters won within 3 tries (65 to 75, no
profession over 75), chapters 1 and 2 easier until the camp (about 90%
within 3 and 70% at the first try), and each boss within ±12 points of its
band (mean 42 to 58).

| Run | Within 3 / first try | Ch 1–2 | Ch 3–8 | Professions (within 3) | Bosses: mean, out of band |
|---|---|---|---|---|---|
| **Today (main)** | **73.6 / 48.8** | **88.6 / 70.0** | **70.5 / 44.4** | 69.5 – 76.6 | **50.5, 0 of 11** |
| A, enemies as today | 85.7 / 60.3 | 92.0 / 74.3 | 84.5 / 57.8 | 72.8 – 90.4 | – |
| A, enemies +19% / +11% | 68.1 / 42.6 | 89.0 / 68.0 | 63.5 / 36.9 | 54.5 – 76.9 | 38.5, 5 |
| A, enemies +17% / +9% | 76.6 / 50.0 | 90.4 / 71.7 | 73.9 / 45.7 | 64.7 – 85.0 | 54.0, 1 |
| B, enemies as today | 83.9 / 56.7 | 92.5 / 74.3 | 82.3 / 53.4 | 69.7 – 89.5 | 66.2, 9 |
| B, +17% / +10% | 72.0 / 45.0 | 89.5 / 69.3 | 68.3 / 39.7 | 57.6 – 80.7 | 44.4, 2 |
| B, +16% / +8%, Dex 2%, Wis cleric | 80.6 / 53.2 | 89.8 / 70.8 | 78.8 / 49.8 | 76.4 – 84.4 | 53.3, 1 |
| C, enemies as today | 79.8 / 52.8 | 89.5 / 69.8 | 77.9 / 49.4 | 65.5 – 86.6 | 64.6, 9 |
| C, +15% / +8% | 75.9 / 48.4 | 87.7 / 66.8 | 73.4 / 44.5 | 60.0 – 83.6 | 56.9, 2 |
| C, +15% / +8%, Dex 2%, Wis cleric | 77.2 / 49.6 | 86.3 / 65.6 | 75.3 / 46.3 | 70.2 – 83.0 | 53.2, 0 |
| **C, +16% / +8%, Dex 2%, Wis cleric** | **74.3 / 47.0** | **86.0 / 64.8** | **71.8 / 43.2** | **68.8 – 80.1** | **52.7, 0** |

What the runs say:

- **Making the abilities count makes every hero stronger** (+6 to +12
  points with the enemies as today). Today about half of a build's points
  go into a main stat that does nothing. Each option needs the enemies'
  growth per level raised from +12% to +16 or +17% health.
- **The spread between professions widens.** Dex gives a rogue or a ranger
  both damage and dodge, and they come out on top (80 to 85). A cleric on
  Int comes out at the bottom (54 to 65): its starting Int is 0. With
  Wisdom as the cleric's damage stat, it moves back to the middle (69 to 76).
- **A** reaches the targets with the enemies at +17% but leaves the numbers
  big (main stat 25 to 43 at level 10), so it does not answer feedback (4).
  Its spread is the widest (65 to 85).
- **B** keeps today's fight numbers and halves the abilities. It needs
  about +18% enemy health per level to come down from 80.6 to about 72.
  One more run would settle it.
- **C** is on target overall (74.3), in chapters 3 to 8 (71.8), and on every
  boss (mean 52.7, none out of band). Left to fix: chapters 1 and 2 are a
  little hard (86 / 65 instead of 90 / 70), so lower those chapters'
  enemy floor by about 5%, and the rogue is at 80 (lower its Dex dodge
  to +1.5% or its Luck share). The mage is the weakest at 69: rounding to
  fives costs the apprentice die its small numbers. That is one or two
  more runs, done when the option is built.

### Level 2 and level 10 heroes, per option

Averages from the simulator (every race). "Damage" is the hero's own damage
with gear, before the face is added (a face adds 5, or 1 in C). Block is the
warrior's block chance. The main stat is in brackets.

**Today**

| | L2 health | L2 damage | L2 dodge | L2 crit | L2 mana | L10 health | L10 damage | L10 dodge | L10 crit | L10 mana | L10 main |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior | 167 | 19 | 7% | 5% | 5 | 412 | 41 | 8% | 6% | 5 | Str 29 |
| Ranger | 116 | 16 | 13% | 5% | 5 | 347 | 35 | 30% | 9% | 6 | Dex 28 |
| Rogue | 128 | 16 | 17% | 12% | 5 | 353 | 35 | 30% | 15% | 5 | Dex 31 |
| Mage | 115 | 16 | 7% | 6% | 6 | 382 | 33 | 10% | 8% | 13 | Int 18 |
| Cleric | 171 | 19 | 7% | 6% | 7 | 439 | 34 | 9% | 6% | 18 | Wis 28 |

**A** (enemies +17% / +9%, cleric on Int)

| | L2 health | L2 damage | L2 dodge | L2 crit | L2 mana | L2 block | L10 health | L10 damage | L10 dodge | L10 crit | L10 mana | L10 block | L10 main |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior | 177 | 19 | 7% | 5% | 4 | 2% | 518 | 50 | 8% | 6% | 4 | 7% | Str 36 |
| Ranger | 129 | 17 | 15% | 5% | 5 | – | 469 | 49 | 31% | 8% | 5 | – | Dex 37 |
| Rogue | 134 | 18 | 18% | 13% | 4 | – | 402 | 54 | 31% | 24% | 5 | – | Dex 43 |
| Mage | 115 | 16 | 7% | 6% | 5 | – | 392 | 39 | 9% | 7% | 13 | – | Int 25 |
| Cleric | 179 | 19 | 7% | 6% | 7 | – | 492 | 37 | 9% | 6% | 16 | – | Int 18 |

**B** (enemies +16% / +8%, Dex +2% dodge, cleric on Wis)

| | L2 health | L2 damage | L2 dodge | L2 crit | L2 mana | L2 block | L10 health | L10 damage | L10 dodge | L10 crit | L10 mana | L10 block | L10 main |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior | 181 | 19 | 7% | 5% | 4 | 4% | 598 | 44 | 8% | 6% | 5 | 9% | Str 17 |
| Ranger | 127 | 17 | 14% | 5% | 6 | – | 525 | 41 | 30% | 8% | 7 | – | Dex 16 |
| Rogue | 133 | 17 | 18% | 12% | 4 | – | 447 | 46 | 30% | 17% | 5 | – | Dex 20 |
| Mage | 110 | 16 | 7% | 6% | 6 | – | 442 | 33 | 11% | 7% | 12 | – | Int 10 |
| Cleric | 185 | 20 | 8% | 6% | 9 | – | 608 | 45 | 9% | 6% | 21 | – | Wis 17 |

**C** (numbers ÷5, enemies +16% / +8%, Dex +2% dodge, cleric on Wis):
recommended

| | L2 health | L2 damage | L2 dodge | L2 crit | L2 mana | L2 block | L10 health | L10 damage | L10 dodge | L10 crit | L10 mana | L10 block | L10 main |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Warrior | 32 | 4 | 7% | 5% | 4 | 6% | 100 | 11 | 8% | 5% | 5 | 11% | Str 12 |
| Ranger | 24 | 3 | 13% | 5% | 6 | – | 86 | 10 | 24% | 7% | 7 | – | Dex 10 |
| Rogue | 25 | 4 | 17% | 12% | 4 | – | 78 | 11 | 28% | 15% | 5 | – | Dex 13 |
| Mage | 21 | 3 | 7% | 5% | 6 | – | 74 | 8 | 10% | 7% | 10 | – | Int 6 |
| Cleric | 34 | 4 | 7% | 6% | 9 | – | 102 | 10 | 9% | 5% | 14 | – | Wis 10 |

In C a level-2 warrior with 32 health and a hit of 4 + 1 meets a chapter-1
thug with 15 to 20 health hitting for 3 or 4. "+1 Str" takes the hit from
5 to 6, and "+1 Con" takes health from 32 to 37.

---

## 4. Old saves

Converted once, on load, then saved (a version number on the save says it
is done). Nothing is lost that the player can count on:

- **Abilities**: the start (race + profession, from the tables) is kept, and
  what was gained since is scaled to the new pick rate. Option C:
  *new = start + round((now − start) ÷ 5)*. Option B: ÷2.5. Option A: kept as is.
- **Unspent picks stay.** Option C: *picks waiting = round up(unspent ÷ 5)*,
  so 1 to 5 unspent become 1 pick and none is lost to rounding. B: ÷2.5,
  rounded up. A: kept.
- **Health, damage, armor** are worked out again with the new rules from the
  level and the converted abilities, then ÷5 for C. Current health keeps its
  share of the maximum (a hero at 60% stays at 60%).
- Gear, enemies and dice change in the data files, so nothing in the save
  needs converting for them. A fight in progress isn't saved, so none is
  cut off.
- The training paths taken (their counts) are kept: they only steer which
  offers come.

---

## 5. What the pick cards say

The card names the stat and what +1 does **for this hero**. With a rare or
better pick, each part is multiplied ("+2 Dex: +2 damage, +4% dodge").

**Option C (recommended)**

| Stat | Warrior | Ranger / Rogue | Mage | Cleric (Wis) |
|---|---|---|---|---|
| Strength | +1 Str: +1 damage | +1 Str: checks, heavy gear | +1 Str: checks, heavy gear | +1 Str: checks, heavy gear |
| Dexterity | +1 Dex: +2% dodge | +1 Dex: +1 damage, +2% dodge | +1 Dex: +2% dodge | +1 Dex: +2% dodge |
| Constitution | +1 Con: +5 health | +1 Con: +5 health | +1 Con: +5 health | +1 Con: +5 health |
| Intelligence | +1 Int: Int spells, checks | +1 Int: Int spells, checks | +1 Int: +1 damage, +1 spell damage | +1 Int: Int spells, checks |
| Wisdom | +1 Wis: +1 mana | +1 Wis: +1 mana | +1 Wis: +1 mana | +1 Wis: +1 damage, +1 mana |
| Perception | +1 Per: +3% block, read foes | +1 Per: read foes | +1 Per: read foes | +1 Per: read foes |
| Luck | +1 Luck: +1.5% crit, luckier picks | same | same | same |
| Charisma | +1 Cha: −2% shop prices | same | same | same |

**Option A**: damage stat "+1 damage"; Con "+10 health"; Dex "+1.5% dodge";
warrior Per "+1% block"; Wis "+1 mana every 2 points".
**Option B**: damage stat "+2 damage"; Con "+25 health"; Dex "+2% dodge";
warrior Per "+2% block"; Wis "+1 mana".

When dodge or block is at its cap, the card says so ("+2% dodge (at most
30%)") and the draw prefers other stats.

---

## 6. Recommendation and open questions

**Recommended: C.** Fight numbers ÷5, **one pick a level** with the four
rarity tiers, +1 damage stat = +1 damage, +1 Con = +5 health, Dex +2% dodge,
warrior Per +3% block, Wis +1 mana, and enemies growing +16% health / +8%
damage a level. It is the only option that makes the numbers small (health
21 to 34 at level 2, about 75 to 100 at level 10, main stat about 12 by
level 10, hits of 4 to 11). It is also on target overall (74.3% within 3
tries), after the camp (71.8%) and on all 11 bosses. Left to fix when it is
built: chapters 1 and 2 about 5% easier, the rogue a little weaker. Story
checks (DC 10 to 16) become real choices for the main stat again.

If one pick a level feels too few, **B** is the fallback (2 picks, today's
fight numbers), at +18% enemy health per level.

Open questions for the user:

1. **One pick a level** (C) instead of five: fine? It is the price of each
   pick counting.
2. **Cleric's damage stat**: the user said Int, "same as mage". Measured, an
   Int cleric is the weakest hero (starting Int 0, and its Wisdom then only
   gives mana). We suggest **Wisdom** for the cleric's damage and mana.
3. **Perception's block**: warrior only (as asked), or a smaller block for
   everyone and a bigger one for the warrior? And should Per give the rogue
   or ranger something in a fight (a crit bonus), since "better at
   perception" today only reads telegraphs?
4. **Mana**: from Wisdom only (as asked), so a mage must split Int and Wis.
   Or keep "the higher of the two"?
5. Should rarity also show on the card's frame (UX), like the signs?

---

## 7. A stat's popin: what it does and where it comes from (later wave)

For UX's later popin when a stat is tapped on the Character radar.

### (a) What each ability does (scheme C)

| Ability | Warrior | Ranger / Rogue | Mage | Cleric |
|---|---|---|---|---|
| Strength | Raises your damage (+1 a point). | Story checks, heavy gear. | Story checks, heavy gear. | Story checks, heavy gear. |
| Dexterity | Dodge (+2% a point, max 30%). | Raises your damage (+1) and your dodge (+2%). | Dodge. | Dodge. |
| Constitution | Max health (+5 a point). | same | same | same |
| Intelligence | Int spells, story checks. | same as warrior | Raises your damage and spell damage (+1). | same as warrior |
| Wisdom | Mana pool (+1), heals. | same | same | Raises your damage (+1) and mana (+1). |
| Perception | Block chance (+3%, max 30%), reading foes' moves. | Reading foes' moves. | same as ranger | same as ranger |
| Luck | Critical hits (+1.5%, max 35%), rarer picks. | same | same | same |
| Charisma | Cheaper shops (−2%, max −20%), talk checks. | same | same | same |

### (b) A breakdown per source

Core can expose:

```dart
List<({String source, String id, int amount})> statBreakdown(
  PlayerSession s,
  String stat, {
  required Map<String, dynamic> races,
  required Map<String, dynamic> professions,
  required Map<String, dynamic> gameConfig,
  required Map<String, dynamic> items,
  SignEffects signs = SignEffects.none, // held signs + titles + Sworn boons
});
```

`source` is one of `base`, `race`, `profession`, `origin`, `patron`,
`picks`, `level`, `gear`, `signs`, `titles`, `earlier`, and `id` names it
(the race id, the clan id, the item id…). The rows add up to the number
shown.

Where each source adds today, and whether it can be read back:

| Source | Where it adds | Recorded today? |
|---|---|---|
| Game default | `game_config.json` (startingTotals, `lib/data/character_start.dart:46`) | yes (table) |
| Race, profession | `bonus*` fields, the same function | yes (`raceId`, `professionId` + tables) |
| Level | +20 health, +1 damage a level (`_applyXp`, `player_session_provider.dart:4862`) | yes (from `level`) |
| Gear | stats only through scaling and requirements: `equipmentScalingBonusFor` (`ally_state.dart:258`) for damage/armor | yes (worn items) |
| Signs, titles, Sworn boons | lent for a fight only: `_signs.stat(...)` (`fight_setup.dart:372`, `signs.dart:1386`); titles and boons go in through `clanEffectsFor` (`offers.dart:1562`) | yes (worked out again from held signs and titles) |
| Patron clan | +1 a level to the clan's stats, +2 health when sworn (`_withPatronGains`, `player_session_provider.dart:4895`; `patron_stats.dart:26`) | **no**: only a line on the clan log, and the patron can change |
| Picks | `takeStatPick` (`player_session_provider.dart:2511`) | **no**: only `trainingTaken`, a count per path, not per stat |
| Origin memories | `applyOriginMemories` (`player_session_provider.dart:4729`) | **no**: only the flags |
| Old free points, training offers | `spendStatPoint` (`:4654`), `takeTraining` | **no** |

To give the full list, Core would add a small ledger to the session:
`Map<String, Map<String, int>> statSources` (source → stat → amount),
written by picks, patron gains and origin memories as they happen.
For an old save, whatever the recorded sources don't explain shows as one
row, "earlier" ("from before v1.4xx"). This is Core's work in the same PR
as the rescale, since that PR rewrites every one of these places anyway.

---

## 8. Code references

- Picks and rarity today: `lib/data/training.dart:38` (`trainingUnitOf`, 10
  health per point), `:258` (`levelDamageGain = 1`), `:261`
  (`statPickRareChance = 0.12`), `:309` (`drawStatPick`: the rare offer is
  the third, "the turn"), `:388` (`statPickFor`, the simulator's policy).
  Path gains: `assets/gamedata/training_paths.json` (damage, health and
  armor gains included).
- Session: `lib/providers/player_session_provider.dart:4862` (`_applyXp`:
  +5 points, +20 health, +1 damage a level), `:2480` (`ensureStatPick`),
  `:2511` (`takeStatPick`), `:814` (`maxMana`).
- Fight formulas: `lib/combat/combat_engine.dart:208` (crit, max 35),
  `:213` (dodge, max 30), `:282` (Attack = base damage + face), `:294`
  (Defend = the face's block, no stat), `:751` (Perception and telegraphs).
  `lib/combat/spells.dart:41` (mana 4 + higher of Int/Wis ÷2), `:47` (Wis
  mana bonus), `:204`/`:218` (spells + stat ÷2). `lib/models/ally_state.dart:258`
  and `:279` (gear scaling, stat ÷2). `lib/data/shop_pricing.dart:8`
  (Charisma −2%).
- Rarity names: `lib/data/signs.dart:35` (`SignRarity`), `:46` (odds
  62/27/9/2), `:55` (`luckRarityCap = 15`).
- Enemy scaling: `lib/combat/combat_engine.dart:832` (`scaledMaxHealth`,
  +12% a level), `:836` (`scaledDamage`, +8%), `:859` (chapter floors),
  `:881` (boss floor), `:946` (chapter curve). `scaledMaxHealth` also
  grows heal and block spells (`spells.dart:224`) and is used for road
  hazards, camp and voyage foes: the enemies' new slope needs its own
  function, not a change to this one.
- Simulator: `lib/data/sim_combat.dart` (`SimCharacter.gainXp`,
  `takeStatPicks`, `casterDamage`, `armor`, the enemy build in the fight,
  the dodge roll), `lib/data/sim_growth.dart` (`_patronGains`).
- Story check DCs: `assets/Cleaned_Narrative_DAG.json` `checkDC` 10 to 16;
  `SubNodeEngine.detourCheckDc` (`lib/data/expedition_steps.dart:246`).
- Measurement: a scratch patch to `sim_combat.dart` and `sim_growth.dart`
  (environment knobs: picks per level, value per point, step, enemy slope),
  not committed. The harness is the scratch `zz_tune_test.dart` with
  `training_paths` added, and a second run per option with
  `boss_balance_test.dart`'s plan.
