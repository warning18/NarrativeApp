# Working in this repository

Several Claude sessions work on this app at the same time, each on its own
branch. The rules below keep them from overwriting each other. Read them
before starting a change.

## The team

| Session | Branch | Job |
|---|---|---|
| **Manager** | `ccr-76229db7-131ulj` | splits tasks, merges PRs, assigns versions, owns this file, CI and releases |
| **Core** (game mechanics) | `claude/core` | rules, numbers and state |
| **UX** (design and UX) | `claude/eager-pascal-y847vf` | how things look, move and read |
| **Narrative** (story and content) | `claude/narrative` | what the game says: story, quests, characters, dialogue |
| **QA** (testing) | `claude/qa` | keeps the tests fast and finds what broke: tests, simulator, L3 on request |
| **Cleanup** (code health) | `claude/cleanup` | removes dead code, applies analyzer-proven lint fixes, privatises file-only names; no behaviour change (waves 1, 2, 2b of `docs/qa/code-cleanup-plan.md`) |

The manager is the Claude Code session `session_01SfVpQUmQNXErL5fGsy7HU9`.
Sessions reach it with the `send_message` tool of the `claude-code-remote`
MCP server. A session without that tool writes what it needs in its PR
description, or in a note under `docs/proposals/` on its branch, and the
manager reads it there.

Core moved to a new session on branch `claude/core` (v1.268); the old
branch `claude/apk-workflow-issue-24c8hx` is retired. Its handoff note is
`docs/handoff/core.md`.

## Who owns what

**Core owns:**
- `lib/combat/` (except `skill_vfx.dart`), `lib/data/`, `lib/gamedata/`,
  `lib/models/`, `lib/providers/`, `lib/tutorial/`
- the systems data in `assets/gamedata/`: skills, skill trees and merges,
  spells, dice, items and sets, enemies, ships and parts, shops, races,
  professions, titles, zones, geography, biomes, gates, signs, game config,
  and the systems with lore attached: factions (clans), sub-clans, houses,
  relations, ports, adventure nodes. Adding a skill, item, enemy or clan is
  Core's job.
- the logic files of the fight: `lib/screens/fight/fight_rounds.dart`,
  `fight_dice_rules.dart`, `fight_queries.dart`, `fight_models.dart`,
  `fight_rewards.dart`, `fight_ground.dart`, `fight_goals.dart`
- Journey, world roads, geography, the playthrough simulator, `docs/simulation/`

**UX owns:**
- `lib/widgets/`, `lib/theme/`, `lib/utils/pixel_icons/`, `lib/utils/face_style.dart`
- every visual effect: `lib/combat/skill_vfx.dart`, `lib/widgets/combat_vfx.dart`,
  `lib/widgets/pixel_vfx.dart`, `lib/screens/fight/fight_effects.dart`,
  `lib/screens/vfx_gallery_screen.dart`
- the art generators in `tool/gen_*.py`, `tools/`, and `assets/visuals/`, `assets/icons/`
- layout-only screen work (spacing, cards, tabs, art, animation)

**Narrative owns:**
- `assets/Cleaned_Narrative_DAG.json`, `assets/narration/`
- the story data in `assets/gamedata/`: `quests.json`, `chapters.json`,
  `npcs.json`, `companions.json`, `companion_remarks.json`, `intrigues.json`,
  `politics_events.json`, `achievements.json`
- `docs/chapter-flow-roadmap.md`, `docs/quest-progress-tracking.md`
- the wording (English and French) of names, descriptions and lore anywhere
  in `assets/gamedata/`. Narrative may fix the text fields of Core's files; it
  never changes their numbers.
- Core still sets the numbers inside Narrative's files (quest rewards,
  standing thresholds) and may add the fields a new system needs.

**Cleanup owns:**
- the waves 1, 2 and 2b of `docs/qa/code-cleanup-plan.md`: mechanical lint
  fixes, deleting code nothing uses (with its tests), unused strings and
  assets, privatising names used in one file.
- It never changes behaviour, a number, a string's text or a layout, and
  never touches a file another session has an open PR on. Wave 3a is QA's,
  3b UX's, 3c Core's; the big-file splits (4) and performance (5) go to the
  owner of each file.

**QA owns:**
- new test files named `test/qa_*_test.dart`, and `docs/qa/`
- GitHub issues labelled `qa`, and the speed of the test suite.
- QA never edits `lib/`. QA may make another session's test faster (fewer
  runs, a shared fixture, a smaller pump) but never weakens what it checks;
  it lists those files in its PR. A failing or wrong test goes to the
  session that owns the code, as an issue.

**Shared files.** `lib/screens/*.dart` and `lib/screens/fight/fight_view.dart`,
`fight_screen.dart`, `fight_cards.dart`, `fight_setup.dart` belong to whoever
is changing the screen's *behaviour* (Core) or its *look* (UX). Before you edit
one, check that no other branch has an open PR touching it
(`git fetch origin && git diff --stat origin/main...origin/<other-branch>`).
If one has, finish your PR after it merges, or keep your change to new
widgets or helpers in your own files and touch the shared file in as few lines
as possible.

`lib/l10n/app_strings.dart` is edited by everyone: add new strings next to
the strings of the feature they belong to, and never reorder or reformat
other blocks. Narrative may reword any string, but never renames its key.

## Requests that cross areas

If you're asked for something that needs work outside your area, don't do
the other session's part. Do your own part (or nothing, if yours depends on
theirs) and send the rest to the manager with `send_message`: what was asked,
what you'll do, and what you need from whom. The manager briefs the other
session and decides the order. Tell the user you've done this.

If a change in the other session's area is a few lines and blocks you (a new
field, a new string key), make it, and list it in the PR description under
"Touches another session's area".

## Versions, changelog and releases

Every push to `main` publishes a GitHub Release tagged with the version in
`pubspec.yaml`. Two PRs that ship the same version mean the second one
overwrites the first release and the in-app updater never sees it.

- The manager reserves version numbers. Use the one the manager gave you; if
  you don't have one, ask before opening the PR.
- Bump `pubspec.yaml`, `lib/app_info.dart` and add the `CHANGELOG.md` entry
  **last, right before opening the PR**, after `git fetch origin main` and
  merging `origin/main` into your branch.
- A PR with only docs or test changes doesn't bump the version.

## Pull requests and merging

- Sessions work in parallel. A session may have up to two open PRs, each
  on its own branch (for example `claude/core` and `claude/core-2`); one
  that needs the other's code says so and merges after it.
- Before opening a PR, merge `origin/main` into your branch and run
  `dart format --output=none --set-exit-if-changed .`, `flutter analyze` and
  **only the test files for what you changed** (`flutter test test/a_test.dart
  test/b_test.dart`). Leave the full suite to CI: it runs on four runners
  in parallel and is much cheaper there. When CI fails, run just the
  failing file locally.
- **Don't merge your own PR.** When CI is green, send the manager the PR
  number. The manager merges green PRs one at a time, as they come, and
  renumbers the version if another PR merged first.
- **No review pass.** The user tests releases by hand and sends feedback;
  nobody reviews a PR's diff before it merges. Keep each PR focused and its
  description short: what changed, what to test, which files of another
  session it touches.
- After your PR merges, restart your branch from the fresh `main` before
  starting the next change.
- Resolve merge conflicts by keeping both sides' work; never take "ours"
  wholesale on a file another session owns. Never force-push over commits
  you didn't write. Resetting your own branch to `main` is fine only when
  everything on it is already merged.

## QA

CI runs the format check, `flutter analyze` and the whole test suite
(including the simulator tests and the `qa_` guards) on every PR. There is
no per-PR QA review: the user reviews releases by hand.

QA's jobs:
- **Keep the suite fast.** Profile it (`flutter test --reporter json`), cut
  the slowest tests' cost without weakening what they check, and drop
  duplicates. Report the suite's time before and after in each PR.
- **One full regression (L3) on request**, or before a release the user
  plans to share: the simulator batch compared with the last report, a
  cross-reference audit of all gamedata, and a read-through of every screen
  changed since the last L3. Results go in `docs/qa/`, and the version of
  the last L3 goes at the top of `docs/qa/README.md`.
- **A `qa_` guard** when the user's feedback finds a bug, so it can't come
  back.
