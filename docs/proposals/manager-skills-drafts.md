# Manager skills: drafts

Drafts of the commands the Manager session repeats by hand. Nothing here is installed. Each block is the body of one skill file (`.claude/skills/<name>/SKILL.md` in a project, or an organization plugin), with the name and the one-line description that go at the top of the file.

A skill is only a saved recipe: the instructions load into the turn and the session follows them with the tools it already has. A skill that needs GitHub or the cross-session `send_message` tool only works in a session that has those tools (the Manager does; the other sessions mostly do not).

Rules shared by all of them:
- Say plainly what was done and what was not. Never report a check that was not run.
- Merge only green PRs, one at a time, in ascending version order; never merge a PR that touches another session's area without it being listed in the PR.
- Never put a model name in a commit, a PR or a file in the repo.
- Write to the user in plain language, no nested numbered lists.

---

## grill-me

**Description:** Put the open decisions to the user as short multiple-choice questions, recommendation first, then send the answers to the right sessions.

1. List the decisions that wait on the user: second-round improvement lists, held items, questions a session asked the Manager that only the user can answer.
2. Pick the four that block the most work. Ask them in one batch: each question stands on its own (the user may see only the question), 2 to 4 options, the recommended option first and marked, the cost of each option in one line.
3. Use multi-select when the options are not exclusive (a list of items to build).
4. Never decide for the user what they were asked; if they skip a question, keep it open and say so.
5. Turn each answer into a brief for the owning session (what, version from the queue, what to show first). Anything that changes how a screen looks goes to the owner as "picture first".
6. End with a plain list of what was sent to whom and what is still open.

## pending

**Description:** A short status of open PRs, per-session work and what waits on the user.

1. List open PRs: number, session, provisional version, CI state (8 checks), whether it contains main and whether it conflicts.
2. Order them by version. Name the next one to merge and what it waits for.
3. One line per session: what it is doing, what it waits for.
4. List the decisions that wait on the user.
5. Under 25 lines. No history.

## verify-pr (argument: PR number)

**Description:** The checks before merging a PR: CI, main, version, changelog, markers, scope, dependencies.

1. Read the PR (state, head sha, mergeable state) and its 8 check runs. Confirm the run belongs to the current head sha.
2. Fetch main and the PR head. Confirm the head contains main, or that a merge with main is clean.
3. `git diff origin/main origin/prN --stat`: only the PR's own files. A kept "ours" side on a shared file (pubspec, changelog) is the usual mistake.
4. The version line in pubspec.yaml and lib/app_info.dart, and the top two CHANGELOG headings, are in order after main's version.
5. `pubspec.yaml` keeps main's dependency blocks (no removed or re-added dependency).
6. Search lib, test, assets, CHANGELOG.md and pubspec.yaml for conflict markers.
7. Docs-only or tests-only PRs have no version bump.
8. If a merge call returns an error (502, 500, a timeout), read the PR state before retrying; never assume it merged.
9. Report pass or fail per item. Merge only if every item passes.

## merge-queue

**Description:** The merge order by version, who has to merge main next, what to renumber.

1. Build the ordered list of open PRs by provisional version.
2. A PR is "next" when its CI is green on a head containing main and the version above main's.
3. For the others: say whether they need a main merge, a renumber or a CI wait.
4. When a PR merges, tell the owner of the next one exactly: merge main into it, the new version and changelog position, marker grep, push, report at 8/8.
5. A collision of two provisional versions is settled by renumbering the one that merges second, and saying so.

## improvements

**Description:** Ask every session for a new round of improvement proposals and collect them.

1. Send each session the same brief: new items only, on its own scope; removing, simplifying and optimizing count most; nothing from earlier lists, merged items or held items; each with what, why, size, risk and what the user would notice; written in a docs-only note on a branch; no code.
2. Collect the 5-line summaries as they come. For a session that cannot send messages, read its branch.
3. Present one list per session in plain words, the recommendation first, then ask with `grill-me`.

## hand-test

**Description:** What to try on the phone for the versions since the last test.

1. List the releases since the user's last hand-test (version range).
2. For each user-visible change: the screen to open and what should look different, in one line. Skip refactors, tests and docs, and say how many were skipped.
3. Put the risky ones first (balance changes, layout changes, orientation).
4. End with the three questions most worth the user's answer.

## feedback (argument: text or screenshot)

**Description:** Record the user's feedback with its screenshot and send it to the session that owns the code.

1. Save the screenshot under `docs/feedback/` with a short name.
2. Classify it by owner (Core, UX, UX-2, Narrative, QA, Cleanup) using the ownership table in CLAUDE.md. If it crosses areas, split it.
3. Send each owner the feedback, the screenshot path and "picture first" when it changes a look.
4. If it is a bug, ask QA for a `qa_` guard.
5. Add it to the feedback-by-category page.

## refresh-board

**Description:** Rebuild the improvements, feedback and roadmap pages from the current state.

1. Read the current proposal notes and the merged versions since the pages were last updated.
2. Update status per item: merged, in progress, held, waiting on the user.
3. Keep the same page address (update in place); tell the user what changed in two lines.

## l3

**Description:** Ask QA for the full regression.

1. Check the last L3 version at the top of `docs/qa/README.md`.
2. Ask QA for the full suite, the simulator batch compared with the last report, the cross-reference audit of all gamedata and a read-through of every screen changed since the last L3.
3. Results go in `docs/qa/` and the L3 version at the top of the README is updated.

## balance

**Description:** Run the simulator guards and report the numbers that matter.

1. Ask Core (or run the simulator tests) for: the boss curve against its targets, the class spread, the naive and competent win rates by chapter, the starter-die keep rate.
2. Compare with the last report; flag any boss outside its band.
3. Never change a balance number from this skill; a change goes to Core with the before/after.
