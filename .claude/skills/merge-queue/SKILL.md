---
name: merge-queue
description: The merge order by version, who has to merge main next, what to renumber.
---

# merge-queue

1. Build the ordered list of open PRs by provisional version.
2. A PR is "next" when its CI is green on a head containing main and the version above main's.
3. For the others: say whether they need a main merge, a renumber or a CI wait.
4. When a PR merges, tell the owner of the next one exactly: merge main into it, the new version and changelog position, marker grep, push, report at 8/8.
5. A collision of two provisional versions is settled by renumbering the one that merges second, and saying so.

Rules for every Manager skill:
- Only the Manager session (see CLAUDE.md) merges PRs, renumbers versions or messages other sessions. Any other session that loads this skill only reports what it finds and never merges.
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
