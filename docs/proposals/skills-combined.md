# Skills tab: A4 with A2 rails (UX picture, nothing built)

The user's pick from [skills-styles.md](skills-styles.md): "A4 with A2 rails". That exact combination was
not drawn, so here it is: [skills-a42.png](../ux-shots/skills-a42.png), on the real skills data, at level 1
and mid game, 412 and 320 px. Mock test: `test/ux_skills_combined_mock_test.dart` (parts in
`test/ux_skills_combined_parts.dart`). No version; the build waits for the user's yes (v1.607.0+643).

## What it is
- **A4's idea:** the rule of the game is that a clan offers a skill once you stand high enough with it.
  Each branch says which clan stands behind it and what standing you have with it, and each depth says
  the standing it asks (Unknown, Known, Trusted, Sworn). The rows the clan can offer now are **lit**.
- **A2's shape:** one branch open at a time, as a short list; the others are one line with four beads
  (known filled, the next ringed). A tap on a rail opens it and folds the open one.
- **The open branch**, row by row: the standing in the left gutter, the skill's icon, its name and what
  it does if known; the next one named and either "The clan can offer it now" (lit) or "Next, at
  'trusted'"; deeper ones stay "Further on", "Needs 'sworn'".
- A branch no clan sponsors says "no clan" (Stoneward).

## The pictures
- **Level 1:** Unknown or Wary with every clan, so only the top row of the open branch is lit; the rails
  show at once which clan stands behind each branch.
- **Mid game, 412:** Bulwark open, Friendly with the Compact: two rows lit, Iron Stance waits for
  "trusted". **320:** Vanguard open (Wary with the Dominion: only the top row).

## Cost
The grid across is gone: the three branches' rows are not side by side, only one open at a time (as in
A2). A4's lit grid was the clearer picture of the rule; this keeps the rule and the room.

## Needs from other sessions
Nothing: standing is read from the session's politics (`tierOf`), the depth it allows from
`skillIndexCapFor`. The build would be a new tree view under `lib/screens/skills/` plus the strings.
