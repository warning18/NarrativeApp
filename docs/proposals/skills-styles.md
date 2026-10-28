# Skills tab: three more styles of A

The user prefers **A** (today's tab with less on it, the tree kept), shown in
[skills-a.png](../ux-shots/skills-a.png) (today: `skills-today.png`). Here are
three other ways to draw it. All keep the tree as the main thing, all read the
real skills model, the real icons and the app's theme, at 412 px and 320 px,
at level 1 and mid game (human warrior, level 12, one offer waiting, 2600
essence, the Compact friendly).

| | Picture | The idea | What it costs |
|---|---|---|---|
| **A2** | [skills-a2.png](../ux-shots/skills-a2.png) | One branch open at a time. The open branch is a short list (icon, name, what it does or who offers it and at what standing); the others are one line with four beads. | The three trees are no longer side by side; a tap opens another. |
| **A3** | [skills-a3.png](../ux-shots/skills-a3.png) | A's columns, plus a bar that never scrolls away (the offer waiting, or the next one and who makes it; the essence pill). Deeper skills are grey shapes labelled with the standing a clan asks. | About 48 px of permanent bar; four nodes per column on the first screen. |
| **A4** | [skills-a4.png](../ux-shots/skills-a4.png) | The standing grid (my own idea). Branches across, the standing each depth asks down the side, the clan and your standing with it above each column; the rows a clan can offer now are lit. It draws the rule of the game: a clan offers a skill once you stand high enough with it. | A new way to read the tree: cells rather than a chain. |

## My lean

A4 explains why a skill is out of reach in one look, and sends the player to
the clans screen; A2 is the safest at 320 px (full-width names). A3 is the
smallest change from A. They combine: A2's rails with A4's header is
possible if the user likes both.

## Spells tab

The Spells tab (and the Spells row on the other versions) is hidden for a class
with no spells, as the manager relayed. It was already so in A; nothing here
needs more.

## Needs from other sessions

Nothing. The standing is read from the session's politics (`tierOf`) and the
depth a standing allows from `skillIndexCapFor`; both exist.

## Files

- `test/ux_skills_styles_parts.dart`, `test/ux_skills_styles_mock_test.dart`:
  the drawing, built only with `UX_SHOTS=docs/ux-shots flutter test
  test/ux_skills_styles_mock_test.dart`.
- No version bump (docs and a mock test only).
