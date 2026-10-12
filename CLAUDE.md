# Working in this repository

Two Claude sessions work on this app at the same time, each on its own
branch, and both merge into `main`. The rules below keep them from
overwriting each other. Read them before starting a change.

## Who owns what

| Session | Branch | Owns |
|---|---|---|
| **Core** (game mechanics) | `claude/apk-workflow-issue-24c8hx` | rules, numbers and state |
| **UX** (design and UX) | `claude/eager-pascal-y847vf` | how things look, move and read |

**Core owns:**
- `lib/combat/` (except `skill_vfx.dart`), `lib/data/`, `lib/gamedata/`,
  `lib/models/`, `lib/providers/`
- `assets/gamedata/*.json` (skills, items, clans, enemies...), including
  *adding* skills, items or clans
- the logic files of the fight: `lib/screens/fight/fight_rounds.dart`,
  `fight_dice_rules.dart`, `fight_queries.dart`, `fight_models.dart`,
  `fight_rewards.dart`, `fight_ground.dart`, `fight_goals.dart`
- Journey, world roads, geography, the playthrough simulator, `docs/simulation/`

**UX owns:**
- `lib/widgets/`, `lib/theme/`, `lib/utils/pixel_icons/`, `lib/utils/face_style.dart`
- every visual effect: `lib/combat/skill_vfx.dart`, `lib/widgets/combat_vfx.dart`,
  `lib/widgets/pixel_vfx.dart`, `lib/screens/fight/fight_effects.dart`,
  `lib/screens/vfx_gallery_screen.dart`
- the art generators in `tool/gen_*.py` and the assets they produce
- layout-only screen work (spacing, cards, tabs, art, animation)

**Shared files.** `lib/screens/*.dart` and `lib/screens/fight/fight_view.dart`,
`fight_screen.dart`, `fight_cards.dart`, `fight_setup.dart` belong to whoever
is changing the screen's *behaviour* (Core) or its *look* (UX). Before you edit
one, check that the other branch has no open PR touching it
(`git fetch origin && git diff --stat origin/main...origin/<other-branch>`).
If it has, finish your PR after theirs merges, or keep your change to new
widgets or helpers in your own files and touch the shared file in as few lines
as possible.

**Crossing over.** If the work needs a change in the other session's area
(a new skill for an effect, a new field for a screen), make the smallest change
that unblocks you and say so in the PR description under "Touches the other
session's area". Don't restyle Core's screens from the Core session, and don't
change rules or balance numbers from the UX session.

## Versions, changelog and releases

Every push to `main` publishes a GitHub Release tagged with the version in
`pubspec.yaml`. Two PRs that ship the same version mean the second one
overwrites the first release and the in-app updater never sees it.

- Bump `pubspec.yaml`, `lib/app_info.dart` and add the `CHANGELOG.md` entry
  **last, right before opening the PR**, after `git fetch origin main` and
  merging `origin/main` into your branch. Take the next version after
  `origin/main` **and after any open PR from the other branch**
  (check `git show origin/<other-branch>:pubspec.yaml | grep ^version`).
- Never squash-merge a PR whose version is not greater than `main`'s. If the
  other session merged first, merge `origin/main` in, renumber, push, wait for CI.
- A PR with only docs or test changes doesn't bump the version.

## Keeping branches in step

- One open PR per session at a time. Merge it (or close it) before starting
  the next one, then restart the branch from the fresh `main`.
- Before opening a PR, and again before merging it: `git fetch origin main`
  and merge `origin/main` into the branch. Resolve conflicts by keeping both
  sides' work; never take "ours" wholesale on a file the other session owns.
- Never force-push over commits you didn't write. Resetting your own branch to
  `main` is fine only when everything on it is already merged.
- `lib/l10n/app_strings.dart` is edited by both sessions: add new strings next
  to the strings of the feature they belong to, never reorder or reformat
  other blocks.
