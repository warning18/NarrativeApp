---
name: refresh-board
description: Rebuild the improvements, feedback and roadmap pages from the current state.
---

# refresh-board

1. Read the current proposal notes and the merged versions since the pages were last updated.
2. Update status per item: merged, in progress, held, waiting on the user.
3. Keep the same page address (update in place); tell the user what changed in two lines.

Rules for every Manager skill:
- Only the Manager session (see CLAUDE.md) merges PRs, renumbers versions or messages other sessions. Any other session that loads this skill only reports what it finds and never merges.
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
