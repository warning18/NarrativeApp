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
