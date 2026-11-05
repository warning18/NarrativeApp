# The Tower: a straight climb, planned as a wave (docs only)

The user asked for a new game option on the main menu, added to the main game
later: **the Tower**. The goal is to reach the top. It uses the dice, the
clans and all the game's mechanics, but there is no story: each level gives a
fight and then choices (items and the like). This note plans the work before
anything is built. Nothing in `lib/` or `assets/` changes with it.

## What the user decided (answers of this session)

| Question | Answer |
|---|---|
| How a run begins | **A fresh hero with a few unlocks**: pick race, profession and a clan; a starter kit and dice; nothing is taken from the main save. Tower wins unlock starter options. |
| Length and floors | **30 floors, one fight each, a boss every 10** (floors 10, 20, 30). After each fight the hero picks one of 3 rewards. |
| Death | **The run ends and the hero earns Tower marks.** Marks (earned by floors reached) buy permanent unlocks for later runs. |
| Where it lives | **A main-menu entry with its own save slot.** The story is not touched; a door inside the main game comes later. |

## Rules of the climb (to be confirmed by Core's design note)

- A floor is **one fight** against a foe drawn from the existing enemies by a
  floor budget (stronger and more affixes as the floor rises). The fight uses
  today's engine: dice, skills, spells, clans, affixes, allies.
- After the fight the hero **picks 1 of 3 rewards**: an item, a die or a die
  face, a skill, a spell, a heal, or a clan gift. A reward is never a gold
  amount only.
- **Bosses on 10, 20, 30** use the existing boss records; floor 30 is the top.
- A short **rest or shop floor** is not planned. Gold exists only as far as the
  engine needs it; the choices are the shop.
- **No story**: no scenes, no map, no narration. A floor has a name, a foe and
  a one-line flavour at most.
- The run is **seeded** (the same seed gives the same floors), so the
  simulator can balance it and a run can be shared.
- **Marks and unlocks**: marks are earned on death or victory from the floors
  reached; they unlock starter options (clans, dice, items, a profession).
  The first unlock tree is small (8 to 12 entries).
- **Own save slot**: a run in progress and the marks are saved apart from the
  story save; deleting one never touches the other.

## The wave: phases, owners, versions

Versions are provisional (the manager renumbers at merge). Main is 1.821 when
this note is written; Core's Journey fix takes 1.823. The Tower starts at 1.824.

| Phase | Owner | What | Shows | Version |
|---|---|---|---|---|
| 0a | **Core** | Mechanics note: the run state, the floor generator and budget table, enemy and affix scaling, the reward pools and weights, how clans and dice enter a run, boss floors, marks and the unlock tree, the save, which engine parts the fight reuses and what story context it needs | a note under `docs/proposals/`, with the numbers | none |
| 0b | **UX-2** | Design pictures: the menu entry, the start screen (race, profession, clan, starter kit), a floor, the reward choice, a boss floor, the end of a run (death and victory), the marks and unlocks screen; phone shape, EN and FR | pictures on a branch, then shown to the user | none |
| 0c | **Narrative** | The names: the Tower, its floors' titles (a short list), the bosses' lines, the marks, the unlocks, EN and FR, in the game's voice | a note | none |
| 1 | **Core** | The headless engine: run state, seeded floor generator, reward offers, marks, the save slot; no UI. A test plays a run with a bot | tests | v1.824 |
| 2 | **QA** | `tool/` simulator for the Tower: win rate per floor for the bot over a seed batch, a guard for the top floor reachable, a balance report in `docs/qa/` | report | none (docs and tests) |
| 3 | **UX-2** | The menu entry and the screens wired to the engine: start, floor, rewards, end, marks | a build the user tries | v1.825 |
| 4 | **Core + UX-2** | Bosses at 10, 20, 30 and the marks unlock tree | a build | v1.826 |
| 5 | **Narrative** | The names and short lines in the game's strings | build | v1.827 |
| 6 | **QA** | L3 for the Tower: the bot batch against the report, a read-through of every Tower screen | `docs/qa/` | none |
| 7, later | Core + UX-2 | A door to the Tower inside the main game | not now | |

Merge order is the version order. Phase 0 is docs and pictures only; **nothing
is built until the user has seen the design pictures and Core's note.**

## What the Tower must not touch

- the story save, the quests, the map, the Journey; no scene is read;
- other sessions' open PRs (the manager holds the shared files: `main_menu_screen.dart`
  is one line, the rest are new files);
- any number of the main game: the Tower has its own tables.

## Risks and open points

- The fight screen and `fight_setup` expect a story context (a zone, a stage,
  an enemy record); the Tower must give them one without a scene. Core says in
  phase 0a what is needed.
- "All mechanics" is wide. The first version uses: dice, skills, spells, items,
  clans (gift, power), affixes, allies. Ships, camps and politics are left out
  and named as such.
- Balance: 30 floors with a boss every 10 needs the simulator before the user
  plays it; QA's phase 2 is not optional.
- Size of the unlock tree: kept small on purpose.
- A run takes about 45 minutes; a floor must be quick (one fight, one choice).

## What the manager does

Reads each phase-0 note and the pictures, shows them to the user, reserves the
versions, merges in order, and never lets two sessions touch the menu or the
fight setup at once.
