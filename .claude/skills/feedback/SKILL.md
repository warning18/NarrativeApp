---
name: feedback
description: Record the user's feedback with its screenshot and send it to the session that owns the code.
---

# feedback

Argument: text or screenshot

1. Save the screenshot under `docs/feedback/` with a short name.
2. Classify it by owner (Core, UX, UX-2, Narrative, QA, Cleanup) using the ownership table in CLAUDE.md. If it crosses areas, split it.
3. Send each owner the feedback, the screenshot path and "picture first" when it changes a look.
4. If it is a bug, ask QA for a `qa_` guard.
5. Add it to the feedback-by-category page.

Rules for every Manager skill:
- Only the Manager session (see CLAUDE.md) merges PRs, renumbers versions or messages other sessions. Any other session that loads this skill only reports what it finds and never merges.
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.
