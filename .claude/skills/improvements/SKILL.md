---
name: improvements
description: Ask every session for a new round of improvement proposals and collect them.
---

# improvements

1. Send each session the same brief: new items only, on its own scope; removing, simplifying and optimizing count most; nothing from earlier lists, merged items or held items; each with what, why, size, risk and what the user would notice; written in a docs-only note on a branch; no code.
2. Collect the 5-line summaries as they come. For a session that cannot send messages, read its branch.
3. Present one list per session in plain words, the recommendation first, then ask with `grill-me`.

Rules for every Manager skill:
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
