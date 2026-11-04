---
name: verify-pr
description: The checks before merging a PR: CI, main, version, changelog, markers, scope, dependencies.
---

# verify-pr

Argument: PR number

1. Read the PR (state, head sha, mergeable state) and its 8 check runs. Confirm the run belongs to the current head sha.
2. Fetch main and the PR head. Confirm the head contains main, or that a merge with main is clean.
3. `git diff origin/main origin/prN --stat`: only the PR's own files. A kept "ours" side on a shared file (pubspec, changelog) is the usual mistake.
4. The version line in pubspec.yaml and lib/app_info.dart, and the top two CHANGELOG headings, are in order after main's version.
5. `pubspec.yaml` keeps main's dependency blocks (no removed or re-added dependency).
6. Search lib, test, assets, CHANGELOG.md and pubspec.yaml for conflict markers.
7. Docs-only or tests-only PRs have no version bump.
8. If a merge call returns an error (502, 500, a timeout), read the PR state before retrying; never assume it merged.
9. Report pass or fail per item. Merge only if every item passes.

Rules for every Manager skill:
- Only the Manager session (see CLAUDE.md) merges PRs, renumbers versions or messages other sessions. Any other session that loads this skill only reports what it finds and never merges.
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
