---
name: l3
description: Ask QA for the full regression.
---

# l3

1. Check the last L3 version at the top of `docs/qa/README.md`.
2. Ask QA for the full suite, the simulator batch compared with the last report, the cross-reference audit of all gamedata and a read-through of every screen changed since the last L3.
3. Results go in `docs/qa/` and the L3 version at the top of the README is updated.

Rules for every Manager skill:
- Only the Manager session (see CLAUDE.md) merges PRs, renumbers versions or messages other sessions. Any other session that loads this skill only reports what it finds and never merges.
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
