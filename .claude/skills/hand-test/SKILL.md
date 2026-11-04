---
name: hand-test
description: What to try on the phone for the versions since the last test.
---

# hand-test

1. List the releases since the user's last hand-test (version range).
2. For each user-visible change: the screen to open and what should look different, in one line. Skip refactors, tests and docs, and say how many were skipped.
3. Put the risky ones first (balance changes, layout changes, orientation).
4. End with the three questions most worth the user's answer.

Rules for every Manager skill:
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
