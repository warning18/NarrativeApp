---
name: grill-me
description: Put the open decisions to the user as short multiple-choice questions, recommendation first, then send the answers to the right sessions.
---

# grill-me

1. List the decisions that wait on the user: second-round improvement lists, held items, questions a session asked the Manager that only the user can answer.
2. Pick the four that block the most work. Ask them in one batch: each question stands on its own (the user may see only the question), 2 to 4 options, the recommended option first and marked, the cost of each option in one line.
3. Use multi-select when the options are not exclusive (a list of items to build).
4. Never decide for the user what they were asked; if they skip a question, keep it open and say so.
5. Turn each answer into a brief for the owning session (what, version from the queue, what to show first). Anything that changes how a screen looks goes to the owner as "picture first".
6. End with a plain list of what was sent to whom and what is still open.

Rules for every Manager skill:
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
