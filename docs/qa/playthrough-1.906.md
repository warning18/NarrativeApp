# Playthrough: the Tower and chapter 1 (v1.906)

QA, on main v1.906. The user asked: "Review also game mechanics and do some
playthrough." Two parts: the Tower, then the start of chapter 1. All pictures
are at 412 wide, dark theme, English, from the real app driven by a widget test
(real fonts, real fights); the curated set is in `playthrough-1.906/`.

How to rerun (tests are inert without the variable):

```
QA_PLAY=<folder> flutter test test/qa_tower_playthrough_test.dart   # QA_PLAY_FLOORS, _RACE, _CALLING
QA_PLAY=<folder> flutter test test/qa_chapter1_playthrough_test.dart
```

Each writes numbered pictures, `_trace.txt` (every `FINDING` and `STUCK` line)
and `_overflow.txt` (every "overflowed" error; both runs: none).

## Findings

| # | What | Where | Severity | Owner | Status |
|---|---|---|---|---|---|
| 1 | **Beating a warden/boss on a Tower floor never ends the fight**: the clans' offer dialog (after floor 5, 10, ...) waits for an offer the Tower session never has, spinner forever, back is blocked, the run cannot go on. | `fight_rewards.dart` (`bossBeaten` → `showOfferIfWaiting`), `offer_dialog.dart` | **Blocker** | Core | #949, fixed by Core's #948 (v1.910) with its own guard `test/tower_warden_win_test.dart`. My 5-floor guard is red on main and green with the fix; it joins once #948 is in. |
| 2 | Level Up in the Tower has no Continue button, only the back arrow. | Level Up screen | Medium | Core | already known; Continue button in #948 |
| 3 | A die changes its look between the roll and the rest. | fight dice | Low | UX | already known (#902, v1.893) |
| 4 | Balance drift: top (win floor 30) with no unlocks is **12.2%**, above the design's 5 to 12% band (was 10.2% in the 1.888 report); with all unlocks 22.6% (band 15 to 25%, was 19.1%). Median floor 17, floor 20 at 36.2%: both in band. | `lib/data/tower/` | Low | Core | issue filed |
| 5 | Race gap: top rate runs from **7.3% (human, voidkin)** to **17.6% (elf)**. A pick of race changes the odds more than a pick of calling. | Tower sim, by race | Low | Core | same issue as 4 |
| 6 | The story's "spare or finish him?" question (`MercyDialog`) shows in a Tower fight against a hunter. The Tower has no story, so the question has no stakes. | `fight_rewards.dart` `_settleHunter`, `mercy_dialog.dart` | Low | Core | issue filed |
| 7 | A health potion can be used at full health (it is spent for nothing). | Tower fight | Low | Core | noted here |
| 8 | Fight screen before the battle: the lower half of the phone is empty (below "Enter Battle"). | `ch1-18` | Low | UX | noted here |
| 9 | A pale rectangle at the top right of the fight screen after the last hit (next to the "-2" number): looks like an oversized hit-effect frame. | `ch1-19` | Low | UX | noted here |
| 10 | After a fight, the first-time tip "New: Spoils chest" can sit on top of the spoils and the Return button. It dismisses with OK, nothing else breaks. | chapter 1, first fight | Info | none | ok |

No overflow, no unreadable text, no dead end other than finding 1, in 5 Tower
floors (win, loss, end, marks) and in chapter 1 from the menu to scene 250.

## The Tower, by the batch (1 to 2000 seeds, none / all unlocks)

Against `l3-1.888.0/data/tower-batch.md`. Full report: `playthrough-1.906/tower-batch.md`.

| measure | band | 1.888 none | 1.906 none | 1.888 all | 1.906 all |
|---|---|---|---|---|---|
| median floor | 13 to 18 | 17 | 17 | | 19 |
| reach floor 20 | 20 to 38% | 35.4% | 36.2% | 45.9% | 46.9% |
| win floor 30 | 5 to 12% / 15 to 25% | 10.2% | **12.2%** | 19.1% | 22.6% |
| marks a run (mean) | | 26.9 | 27.9 | 31.0 | 32.5 |

The sim is a naive bot that never refuses a card, so it measures the deck and
the numbers, not a player. The seeds 10001 to 12000 agree (top 13.2% none).

## The Tower, by hand (real UI, floors 1 to 5)

Door, race and calling, floor stands, real fights, spoils, oaths and boons,
Level Up, a loss, leaving, the end and the marks: all reachable and readable.
The climb stops at the floor 5 warden (finding 1). Pictures: `tower-*.png`.

## Chapter 1, the start

Menu, New Game, the creation inside the story (people, calling, the confirm
dialog, the character sheet, the name, the memories), the casino scene (the
Blind Beggar and the dice), the map with its three choices, the first fight
(the bouncer, then a bandit), the spoils chest, back to the map, scene 250.
Pictures: `ch1-*.png`. Notes for readers of the pictures:

- The creation takes six taps and two dialogs before the first line of story.
  Nothing is stuck, but the Start button of the creation is below the fold on
  a small phone, and the character sheet's Continue and the memories'
  "Begin story" button need a scroll. Worth knowing, not a bug.
- On the map, tapping a step selects it, tapping it again goes; the hint text
  under the map says so. A driver that taps twice undoes its own pick.
- The dice, the icons and the new intro read well at 412 dark.

Not covered: the casino's later variants (125) and fights after scene 250.
