---
name: pending
description: A short status of open PRs, per-session work and what waits on the user.
---

# pending

1. List open PRs: number, session, provisional version, CI state (8 checks), whether it contains main and whether it conflicts.
2. Order them by version. Name the next one to merge and what it waits for.
3. One line per session: what it is doing, what it waits for.
4. List the decisions that wait on the user.
5. Under 25 lines. No history.

Rules for every Manager skill:
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
