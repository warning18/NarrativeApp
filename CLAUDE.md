# Working in this repository

Several Claude sessions work on this app at the same time, each on its own
branch. The rules below keep them from overwriting each other. Read them
before starting a change.

## The team

| Session | Branch | Job |
|---|---|---|
| **Manager** | `ccr-76229db7-131ulj` | splits tasks, merges PRs, assigns versions, owns this file, CI and releases |
| **Core** (game mechanics) | `claude/apk-workflow-issue-24c8hx` | rules, numbers and state |
| **UX** (design and UX) | `claude/eager-pascal-y847vf` | how things look, move and read |
| **Narrative** (story and content) | `claude/narrative` | what the game says: story, quests, characters, dialogue |
| **QA** (testing) | `claude/qa` | finds what broke: tests, simulator, PR reviews |

The manager is the Claude Code session `session_01SfVpQUmQNXErL5fGsy7HU9`.
Sessions reach it with the `send_message` tool of the `claude-code-remote`
MCP server.

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

**QA owns:**
- new test files named `test/qa_*_test.dart`, and `docs/qa/`
- GitHub issues labelled `qa`, and reviews on open PRs.
- QA never edits `lib/` or another session's tests. A failing or wrong test
  goes to the session that owns the code, as an issue or a PR review.

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

- One open PR per session at a time.
- Before opening a PR, merge `origin/main` into your branch and run
  `dart format --output=none --set-exit-if-changed .`, `flutter analyze` and
  the tests for what you changed.
- **Don't merge your own PR.** When CI is green, send the manager the PR
  number. The manager merges PRs one at a time, in order, and renumbers the
  version if another PR merged first. QA reviews PRs before they merge, at
  the level the manager sets (below).

## QA levels

CI already runs the format check, `flutter analyze` and the whole test suite
(including the simulator tests and the `qa_` guards) on every PR. QA doesn't
run those again. It adds what CI can't see, at one of four levels. The
manager picks the level when it sends QA a PR. QA may raise it, and says why.

| Level | When | What QA does |
|---|---|---|
| **L0: CI only** | docs-only or test-only PRs, art/asset-only PRs, text fixes with no new keys | nothing; the manager merges on green CI |
| **L1: diff review** (default) | a PR within one session's area | reads the diff for bugs, ownership breaches, missing French, a wrong version or changelog; one short review |
| **L2: feature check** | a PR that touches a shared screen, combat rules, save data or providers, more than one session's area, or over ~800 changed lines | L1, plus runs the affected flow in a widget test or the simulator, checks that old saves still load, and checks the new screens' text in both languages |
| **L3: full regression** | every 10th release, before a release the user plans to share, after a big refactor, or on request | full 100-run simulator batch compared with the last report, a cross-reference audit of all gamedata, a read-through of every screen changed since the last L3; results go in `docs/qa/` |

An L3 is never done on an ordinary PR. QA keeps the version of the last L3 at
the top of `docs/qa/README.md`.
- After your PR merges, restart your branch from the fresh `main` before
  starting the next change.
- Resolve merge conflicts by keeping both sides' work; never take "ours"
  wholesale on a file another session owns. Never force-push over commits
  you didn't write. Resetting your own branch to `main` is fine only when
  everything on it is already merged.
