# Real pictures of the build for the hand test of 1.863

Drawn from `main` at **v1.863.0**: the Tower by `test/qa_hand_test_shots_tower_test.dart`, the rest by the `v1863-*` sections of `test/qa_hand_test_shots_test.dart` (same harness as `docs/qa/hand-test-1.846`): the real app, its own fonts and icons, 412 x 860, English (the French one is 320 wide), a human warrior unless said otherwise, the stored city plans. Both files draw only with `QA_SHOTS=<folder>` (`QA_SHOTS_ONLY=v1863` for the second). The red ribbon in the top right corner is Flutter's debug banner. Nothing in `lib/` was touched and nothing here is judged.

## The Tower (1.850 to 1.862)

The Tower's fights are not played: the Tower's own launcher (`towerFightLauncherProvider`) is given a fake that wins each floor with the health it began, so the floors, the spoils, the offers, the Level Up and the end are the real screens on the real engine. A run is dealt from a random seed, so the oaths, items and gains in a picture differ from one drawing to the next; what each picture shows does not.

| Item | Picture | What to look at |
|---|---|---|
| Main menu card | `tower-1-main-menu-card` | "The Tower, Thirty floors, no story." under Edit Mode |
| Start screen | `tower-2-start-screen` | the Tower's own start screen |
| Creation (1.862: the main game's Race & Profession screen) | `tower-3-creation-race` (people), `tower-3-creation-callings-padlocked` (Cleric and Ranger padlocked: "Bought with marks: 15 / 25"), `tower-3-creation-picked` (Warrior picked, Climb ready) | no clan told on the cards |
| Floor with the ladder and the Oaths row | `tower-4-floor-1` (the first floor: Oaths "Unsworn"), `tower-6-floor-5-step-1` (floor 6 after three oaths, "Penitents (main)", Mire, Dominion, the ladder at 6 of 30) | the vertical ladder on the left (floors 10, 20, 30 marked), the Oaths row, the foes, the health |
| Spoils sheet (1.861) | `tower-7-spoils-floor-1-with-items` | the chest, "What the spoils change" (potions x0 to x1), the items with their lines, Take |
| An oath card | `tower-7-after-spoils-floor-1` | a clan offers its oath after the first floor: "Swear" or "Leave them all (+1 mark)" |
| A boon floor (floor 5, a warden) | `tower-7-after-spoils-floor-5` | three boon cards (a skill, a die, a spell) and "Leave them all" |
| The Level Up after a floor (1.858) | `tower-8-level-up-after-floor-1`, `tower-8-level-up-picked` | the main game's Level Up screen under the run's hero: three gains, one picked, "Take this pick" |
| Leaving, the end screen, the marks | `tower-9-leave-dialog`, `tower-9-end-screen`, `tower-9-marks-screen` | "You left the Tower on floor 8", the Ash Marks earned, Climb again / Marks / Back; the marks screen lists the unlocks with their price |

## The Skills tree (1.863, the banner version)

| Picture | What to look at |
|---|---|
| `skills-tree-en-412` | the Tree tab of the Skills screen at 412 px, a level 12 cleric: five branches, the clans' banners on each skill, "Mastery" at the end |
| `skills-tree-fr-320` | the same in French at 320 px ("Compétences", "Arbre", "Maîtrise"): the branch descriptions are cut to two lines |

## Mending Light feeds the Watchfire (1.859)

A level 9 cleric at full health (60 / 60), mana 10, in a fight with a Skittish Slum Thug: `watchfire-0-before-cast`, `watchfire-1-after-one-cast`, `watchfire-2-after-two-casts`. The Watchfire is the flame icon under the hero's name; after two casts at full health its number is **20** (the number is read in the test, too: every point healed past full feeds it; the heal sizes are Mending Light's, not a die's).

## The village hubs after the chart change (1.851 and later)

`village-1200-white-wells`, `village-6100-rimewell`, `village-7200-greyhithe`, `village-5100-wracks-end`, `village-6200-highhearth`, `village-3100-emberwick`, `village-3200-akagiri`, `village-5200-kindly-hill`. Compare with `docs/qa/village-hubs-1.851/`: the counts of banners, rows and hand-badge cards are the same on 1.863 as on 1.851 (White Wells 2 banners; Rimewell 6; Greyhithe 5; Wrack's End 9; Highhearth 6; Emberwick 8; Akagiri 6). Kindly Hill (scene 5200) is a room, not a district chart: 7 marks on the room. Scene 1200 is drawn with Lysa and Vica alive (`lysa_survived`, `vica_follow`).

## What I could not render, and why

- **A fight played in the Tower**: the fights of the floors are faked (won at once). The Tower's real fight screen is the story's own (see `docs/qa/hand-test-1.846` for it).
- **The same run twice**: the Tower's creation screen deals a random seed, so the oath names, items and gains differ from drawing to drawing.
- **The Level Up of a second floor, a floor with no spoils, the Tower's top floors (25 and 30)**: not drawn; the run is left on floor 8.
- **The Watchfire's burn at the round's end**: the pictures stop after the casts (the fire is spent as the round turns).
