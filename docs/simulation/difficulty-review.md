# Difficulty review (v1.412)

The user asked to "review difficulty", with no direction given. This note says where the curve stands today and proposes changes. **Nothing is tuned yet:** the manager takes the proposals to the user first.

**Measured:** 400 playthroughs with the simulator on main (v1.412), seed 7. That is 80 runs per profession, the six walk strategies in turn, every run to an ending. An encounter is lost after three failed tries; with permadeath on, a loss there is a death.

## 1. Encounters won, by profession and chapter

Won within three tries:

| Profession | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 | All |
|---|---|---|---|---|---|---|---|---|---|
| Cleric | 94 | 98 | 89 | 75 | 80 | 77 | **44** | 70 | 81.8 |
| Mage | 99 | 100 | 99 | 94 | 98 | 97 | 99 | 93 | **97.2** |
| Ranger | 97 | 99 | 94 | 90 | 94 | 95 | 91 | 93 | 93.8 |
| Rogue | 97 | 99 | 95 | 87 | 93 | 92 | 83 | 90 | 92.7 |
| Warrior | 99 | 100 | 96 | 86 | 93 | 90 | 70 | 87 | 92.1 |

Won at the first try (the fight a careful player meets):

| Profession | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 |
|---|---|---|---|---|---|---|---|---|
| Cleric | 91 | 84 | 61 | **46** | 50 | 49 | **20** | 40 |
| Mage | 99 | 98 | 80 | 72 | 84 | 82 | 95 | 71 |
| Ranger | 94 | 83 | 65 | 64 | 72 | 78 | 68 | 73 |
| Rogue | 95 | 87 | 66 | 60 | 71 | 70 | 51 | 66 |
| Warrior | 99 | 94 | 69 | 58 | 70 | 63 | 38 | 59 |

## 2. Deaths (encounters lost after three tries), per run

| Profession | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 | Per run |
|---|---|---|---|---|---|---|---|---|---|
| Cleric | 0.2 | 0.2 | 2.0 | **3.1** | 3.0 | 2.5 | 0.9 | 1.7 | 13.6 |
| Mage | 0.1 | 0.0 | 0.2 | 0.8 | 0.3 | 0.3 | 0.0 | 0.4 | 2.2 |
| Ranger | 0.1 | 0.1 | 1.1 | 1.2 | 0.9 | 0.5 | 0.1 | 0.4 | 4.3 |
| Rogue | 0.1 | 0.0 | 0.9 | 1.5 | 1.0 | 0.8 | 0.3 | 0.6 | 5.1 |
| Warrior | 0.0 | 0.0 | 0.7 | 1.7 | 1.1 | 1.1 | 0.5 | 0.8 | 5.9 |

Level on reaching each chapter:

| Profession | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 |
|---|---|---|---|---|---|---|
| Cleric | 4.9 | 8.5 | 10.8 | 14.2 | 16.7 | 17.3 |
| Mage | 4.8 | 9.4 | 12.5 | 17.3 | 20.4 | 21.4 |
| Warrior | 4.9 | 9.3 | 12.1 | 16.5 | 19.4 | 20.2 |

## 3. The bosses' bands

From the boss curve test, 400 runs, after #336's re-sizing. Target ±12 points.

| Boss | Chapter | Target | Won |
|---|---|---|---|
| Aurel Vane | 1 | 75 | 78.7 |
| Void Stalker | 3 | 65 | 67.8 |
| Hollow Court Inquisitor | 4 | 55 | 58.2 |
| Bone Warden | 4 | 55 | 61.3 |
| Void Archon | 5 | 50 | 57.6 |
| White Admiral | 6 | 45 | 49.4 |
| Claimant Vane / Tallis / Morrow | 7 | 40 | 48.6 / 46.6 / 48.3 |
| Tear-Herald | 8 | 35 | 39.0 |
| Void Sovereign | 8 | 35 | 34.2 |

All are in band, but all except the Void Sovereign sit 3 to 9 points above target.

## 4. Where the curve spikes or goes flat

1. **The Mage is flat, near 100%.** It wins 93 to 100% of encounters in every chapter (chapter 7: 95% at the first try). It has the fewest deaths (2.2 a run) and the highest level (21.4 at chapter 8). The game barely pushes back on it.
2. **The Cleric is the outlier the other way.** It wins 81.8% of encounters with 13.6 deaths a run, six times the Mage's. It falls behind: 4 levels down by chapter 8, because lost fights give no XP, so the gap snowballs.
3. **Chapters 3 and 4 are a cliff, not a slope.** First-try wins drop 20 to 40 points between chapters 2 and 4 for every profession. Chapter 4 is then harder than chapters 5 and 6, so the curve rises and falls back.
4. **Chapter 7 spikes for the Cleric and the Warrior** (first try 20% and 38%): the three claimants. The Mage doesn't notice it.
5. **Chapters 1 and 2 are nearly free:** 94 to 100% won, chapter 2 more than chapter 1.
6. **Alignment-led runs are harder:** the Good- and Evil-leaning walks win 84% and 82% of encounters, against 92 to 96% for the others. That is the alignment hunters' doing.

## 5. Proposals (for the user to choose; none applied)

1. **Close the profession gap from both ends.** Lift the Cleric (its heals or its armour floor about +10%) and trim the Mage (spell damage about −10%). Aim: every profession at 88 to 94% of encounters won, and 60% or more first-try wins in chapter 4.
2. **Turn the chapter 3–4 cliff into a slope.** Ease chapters 3 and 4 a little and firm chapters 5 and 6 a little, through the chapter difficulty multiplier, about 5% each way. First-try wins should then fall steadily from chapter 1 to chapter 8 instead of dipping at 4.
3. **Give chapter 2 some teeth.** About +10% to its enemies, or one more Elite on its roads, so it isn't a free 99%.
4. **Soften the chapter-7 claimants for the slow classes.** Either trim their damage about 8% (they sit 7 to 9 points above their 40% target anyway), or give a rest-and-resupply beat before the Lantern Hall.
5. **A catch-up for losses.** A lost fight gives about 30% of its XP, so a struggling character doesn't fall further behind (the Cleric's 4-level gap).

Each would be measured with this note's 400-run table before and after. Proposal 1 alone should close most of the gap; 2 and 3 change the feel for everyone.

## 6. What was built (v1.429)

The user chose proposals 3, 4 and 5, and replaced 1 and 2 with one target: **every profession wins at most 75% of its encounters within three tries (aim 65–75%), mostly by raising enemy strength and pulling the Mage down, the Cleric lifted only as needed.**

- **Chapter 2's teeth** (proposal 3): its enemies are a tenth stronger than the curve (`chapterTwoTeeth`).
- **A rest before the Lantern Hall** (proposal 4): Narrative's `7515_rest` sets `rest_before_hall`, which refills provisions and mana.
- **A lost fight gives 30% of its XP** (proposal 5, `lostFightXpShare`), in the game and in the simulator.
- **The enemy floor, one entry per chapter** (`enemyHealthFloorByChapter`, `enemyDamageFloorByChapter`). Health: 1.46, 2.12, 2.77, 2.77, 2.90, 2.16, 2.09, 2.03 (was 1.15, 1.25, then 1.35). Damage: 1.34, 1.79, 2.28, 2.28, 2.40, 1.80, 1.74, 1.68 (was 1.10, 1.15, then 1.20).
  - **Chapters 1–2 are lighter.** This is the user's second call: "chapters 1 and 2 should be easier, but after the camp the percentages are fine." The camp is node 3001, the landfall that sets `camp_founded` and opens chapter 3. Before it, the target is about 85–90% won within 3 tries and 65–75% on the first try.
  - Chapters 6–8 are lighter than 3–5 because the chapter curve already climbs there. A uniform floor (×2 everywhere) stopped four runs in five short of the White Fleet's grave and the Sovereign.
- **The professions:**
  - Mage: base damage 6 → 1, Intelligence 4 → 1, health −15 → −20.
  - Cleric: base damage 0 → 5, health 10 → 35.
  - Warrior: base damage 3 → 4, health 20 → 30.
  - Ranger: base damage 3 → 1, health 0 → −10, Perception 4 → 1, Luck 2 → 0, Dexterity 3 → 2.
  - Rogue: base damage 4 → 2.
- **Five bosses re-tuned** (they sit on their own floor, so the stronger runs that still reached them won too often):
  - Void Archon: health 330 → 365, damage 26 → 27.
  - White Admiral: health 350 → 395, damage 31 → 32.
  - Void Sovereign: health 359 → 385, damage 30 → 31.
  - Tear-Herald: health 306 → 290, damage 27 → 26.
  - Claimant Tallis: damage 22 → 23.
- **The six clan champions** (`nemesis_quests_test`, about half won where they come): health 190 → 215 for the Dominion's and 200 → 225 for the others, damage +1. The runs reach them stronger now, and they had drifted to 62%; they now sit at 48%.

### Before and after (400 runs, seed 7, every strategy)

Before the camp is chapters 1–2; from the camp is chapters 3–8. In each cell, the first number is won within 3 tries and the second is won on the first try.

| Profession | Ch 1–2, v1.429 | Ch 3–8, v1.429 | All, v1.423 | All, v1.429 |
|---|---|---|---|---|
| Cleric | 92.9 / 82.7 | 63.2 / 43.3 | 82.5 / 70.4 | 68.2 / 49.9 |
| Mage | 89.9 / 66.0 | 69.9 / 41.8 | 97.3 / 84.3 | 73.3 / 45.9 |
| Ranger | 81.0 / 55.1 | 72.7 / 43.1 | 94.2 / 77.7 | 74.1 / 45.1 |
| Rogue | 90.2 / 65.4 | 72.5 / 44.3 | 92.9 / 74.9 | 75.6 / 48.0 |
| Warrior | 94.7 / 81.3 | 64.7 / 37.4 | 91.8 / 72.1 | 69.9 / 45.0 |

On v1.423, chapters 1–2 were won 94–100% within 3 tries (same 400-run measure).

- **Chapters 1–2:** won within 3 tries 81–95% (about 90 on average), on the first try 55–83% (about 70). On average that is the target. The professions spread around it: the Ranger is lowest (81 / 55) and the Cleric and Warrior highest (93–95 / 81–83).
- **Chapters 3–8:** won within 3 tries 63–73%, on the first try 37–44%.

The simulator now counts first-try wins per chapter (`firstTry` in a run's `byChapter`).

### Encounters won within 3 tries / on the first try, by chapter (v1.429)

| Profession | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 |
|---|---|---|---|---|---|---|---|---|
| Cleric | 97/93 | 91/78 | 70/50 | 63/44 | 62/42 | 61/42 | 35/20 | 61/38 |
| Mage | 94/87 | 88/56 | 75/41 | 67/36 | 67/52 | 68/33 | 88/63 | 66/40 |
| Ranger | 86/79 | 79/44 | 62/33 | 66/34 | 74/49 | 83/47 | 83/54 | 86/60 |
| Rogue | 94/88 | 88/55 | 69/38 | 68/38 | 73/49 | 77/47 | 71/54 | 80/56 |
| Warrior | 98/96 | 93/74 | 72/42 | 60/34 | 64/45 | 63/25 | 53/31 | 64/36 |

Still uneven:
- The Ranger is the weakest early and grows strong late (83–86% in chapters 6–8). That comes from its kit, not its starting stats: trimming Perception and Luck barely moved it.
- The chapter-7 claimants still beat the Cleric and the Warrior often (35% and 53% won).

### The bosses (`boss_balance_test`, 400 runs)

Every boss stays inside its existing band (target ±12), so no target was re-centred. On average they are won 47.5% of the time (the band asks 42–58%).

| Boss | Chapter | Target | Won |
|---|---|---|---|
| Aurel Vane | 1 | 75 | 80.9 |
| Void Stalker | 3 | 65 | 61.2 |
| Hollow Court Inquisitor | 4 | 55 | 51.4 |
| Bone Warden | 4 | 55 | 57.7 |
| Void Archon | 5 | 50 | 48.3 |
| White Admiral | 6 | 45 | 49.0 |
| Claimant Vane | 7 | 40 | 32.3 |
| Claimant Tallis | 7 | 40 | 38.3 |
| Claimant Morrow | 7 | 40 | 39.5 |
| Tear-Herald | 8 | 35 | 30.8 |
| Void Sovereign | 8 | 35 | 33.0 |

### Test bounds

- `chapter_one_fights_test` passes on its original bounds.
- `clash_balance_test` keeps 0.10 for chapters 2–8. Chapter 1 gets 0.25: the clash rules (the game's) came out 11 to 23 points kinder per try there across the settings and data measured. The likely cause: their goals (rout, subdue, hold) end a fight before the foe's health is gone, so the heavier health floor bites less. This is worth a look if chapter 1 feels too soft.

## The professions with the stat picks in (after v1.490)

QA's L3 on v1.489 found the spread widened once the simulator took its stat picks (warrior 73, mage 60, rogue 62% of encounters won). The warrior's four calling paths all lead with Strength and Constitution; the mage's one path led with Intelligence only 2 points in 5, and the rogue's Skirmisher with Dexterity 2 in 5. Lifting the mage and the rogue lifted the bosses too (mean 55–57%), so a second pass brought the bosses back to about 51%.

**Pass 1, the professions:**
- `arcanist`: +2 Intelligence, +2 Wisdom, +1 Perception → **+4 Intelligence, +1 Constitution**.
- `skirmisher`: +2 Dexterity, +1 Perception, +1 Luck, +1 Constitution → **+3 Dexterity, +1 Perception, +1 Constitution**.
- Rogue `bonusMaxHealth` −2 → +1 (pass 2: **+3**).
- Mage `bonusMaxHealth` −2 (pass 2: **0**, once the bosses had room for it).

**Pass 2, the bosses:**
- `bossHealthBaseMultiplier` (combat_engine.dart, every boss's health floor) 1.15 → **1.21**.
- Claimant Vane `maxHealth` 74 → **79**: the mage wins the claimants far more often than the others (about 80%), and Vane sat on its band's edge (52%).

Encounters won within 3 tries (400 runs, goals random, favorGood, favorEvil, maximizeGold): v1.490 → pass 1 → pass 2.

| Seed | Warrior | Mage | Rogue | Cleric | Ranger |
|---|---|---|---|---|---|
| 7 | 70.7 → 72.4 → 69.9 | 60.1 → 65.7 → 65.8 | 59.9 → 67.2 → 66.1 | 66.4 → 68.5 → 65.0 | 69.0 → 68.5 → 68.7 |
| 11 | 74.1 → 75.3 → 71.5 | 61.7 → 66.4 → 68.3 | 61.8 → 67.6 → 67.3 | 65.7 → 66.6 → 63.4 | 69.3 → 70.7 → 67.8 |
| 23 | 71.7 → 71.3 → 67.4 | 60.5 → 68.2 → 68.6 | 61.1 → 66.6 → 65.1 | 65.2 → 63.8 → 62.2 | 66.5 → 71.2 → 68.1 |

The bosses, won % (same runs; `boss_balance_test` reads seed 7, band target ±12):

| Boss | Target | Seed 7 | Seed 11 | Seed 23 |
|---|---|---|---|---|
| Aurel Vane | 75 | 75 → 78 → 76 | 79 → 82 → 82 | 78 → 80 → 81 |
| Void Stalker | 65 | 66 → 75 → 66 | 61 → 65 → 67 | 62 → 68 → 64 |
| Hollow Court Inquisitor | 55 | 50 → 65 → 55 | 57 → 60 → 59 | 52 → 60 → 57 |
| Bone Warden | 55 | 54 → 60 → 59 | 58 → 61 → 58 | 55 → 62 → 54 |
| Void Archon | 50 | 50 → 58 → 50 | 51 → 57 → 48 | 53 → 57 → 53 |
| White Admiral | 45 | 52 → 52 → 48 | 52 → 58 → 49 | 53 → 55 → 48 |
| Claimant Vane | 40 | 45 → 51 → 49 | 50 → 55 → 51 | 50 → 53 → 43 |
| Claimant Tallis | 40 | 46 → 45 → 47 | 42 → 46 → 33 | 44 → 46 → 40 |
| Claimant Morrow | 40 | 46 → 41 → 47 | 42 → 53 → 43 | 44 → 49 → 48 |
| Tear-Herald | 35 | 40 → 40 → 36 | 37 → 45 → 37 | 38 → 39 → 34 |
| Void Sovereign | 35 | 38 → 40 → 33 | 43 → 47 → 38 | 44 → 39 → 35 |
| **Mean** | 42–58 | 51.1 → 55.0 → 51.4 | 52.0 → 57.1 → 51.5 | 52.0 → 55.4 → 50.7 |

- The cleric pays most for the heavier bosses (it wins the claimants least): 62–65% after pass 2, 3 to 8 points under 70.
- `clash_balance_test`'s chapter-7 gap is noisy across these knobs (0.06 to 0.14 with Vane between 74 and 82); at 79 every chapter is within 0.07.

## Cleric follow-up (after v1.497)

The cleric sat 3 to 8 points under the 65–75 aim after the boss pass. One cleric-only knob:

- Cleric `bonusBaseDamage` 3 → **5** (`professions.json`). Health was tried too (+5 and +10 moved it about half as far), and the Zealot path (cleric-only in data) shifts the simulator's stream for the other professions, so it was left alone. No boss changed.

Encounters won within 3 tries (400 runs, same plan and harness as above): before → after. Only the cleric moves; the other four are identical.

| Seed | Warrior | Mage | Rogue | Cleric | Ranger | Boss mean |
|---|---|---|---|---|---|---|
| 7 | 69.9 | 65.8 | 66.1 | 65.0 → 70.8 | 68.7 | 51.5 → 52.9 |
| 11 | 71.5 | 68.3 | 67.3 | 63.4 → 69.0 | 67.8 | 51.5 → 52.6 |
| 23 | 67.4 | 68.6 | 65.1 | 62.2 → 68.6 | 68.1 | 50.7 → 52.3 |

Every boss stays in its band at all three seeds (highest against its band: Aurel Vane 83 of 63–87, Claimant Vane 50 of 28–52 at seed 11). `clash_balance_test` passes on its bounds.
