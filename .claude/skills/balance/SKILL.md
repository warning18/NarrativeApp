---
name: balance
description: Run the simulator guards and report the numbers that matter.
---

# balance

1. Ask Core (or run the simulator tests) for: the boss curve against its targets, the class spread, the naive and competent win rates by chapter, the starter-die keep rate.
2. Compare with the last report; flag any boss outside its band.
3. Never change a balance number from this skill; a change goes to Core with the before/after.

Rules for every Manager skill:
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
