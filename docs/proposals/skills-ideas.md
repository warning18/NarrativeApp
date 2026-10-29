# Skills tab: three new ideas (UX pictures, nothing built)

The user keeps today's tab and asked for **three other designs, totally different** from A, B, C, A2, A3,
A4 and from each other. None is a tree, a rail or a grid. Each is drawn on the real skills data (the
model, the standing with each clan, the offer depth, the icons), at **level 1 and mid game, 412 and
320 px**, and today's tab is next to them. No version; the build waits for the user's pick.
Mock test: `test/ux_skills_ideas_mock_test.dart` (widgets in `test/ux_skills_ideas_parts.dart`).

| Picture | What it is |
|---|---|
| `docs/ux-shots/skills-ideas-compare-412.png`, `-320.png` | Today's tab and the three ideas side by side, mid game. |
| `docs/ux-shots/skills-ideas-1-stars.png` | 1. The star chart, level 1 and mid game, 412 and 320. |
| `docs/ux-shots/skills-ideas-2-decks.png` | 2. A hand and the clans' decks. |
| `docs/ux-shots/skills-ideas-3-doll.png` | 3. The paper doll. |

The rule behind all three is today's: a clan offers a skill once you stand high enough with it.

## 1. The star chart
Each branch is a constellation: a star for each skill and a crown star for Mastery, four constellations
on one night sky that fits the screen. A star lights gold when you learn the skill; the **ringed star is
the next, bright when its clan can offer it now**; the lines light up to the last known star. A card
under the sky reads the focused constellation's next star (name, what it does, who offers it and at what
standing); a tap on a constellation changes the focus.
- **Costs:** it shows state, not detail (the name and effect are one tap away); the star shapes are drawn
  by branch position, so a class with more than four branches needs another cell.
- **Needs from Core:** nothing.

## 2. A hand and the clans' decks
What you know is a **hand** of cards, fanned at the top. What you can still learn is a **deck for each
clan's branch**, in the clan's colour with its flag and a count of cards left. When the clan can deal the
top card now it is turned up with a gold edge; otherwise it stays face down and says the standing it
waits for ("Trusted").
- **Costs:** the order inside a branch is not shown, only the top card and a count; the lightest idea of
  the three (nothing scrolls at 412 px).
- **Needs from Core:** nothing.

## 3. The paper doll
The hero's outline, each branch **hung on a part of the body** (off hand, sword hand, head, feet) with a
string. A socket shows the deepest skill known there, the branch, its clan and standing and four beads;
it **glows when its clan can offer the next skill now**, and a card under the doll lists what is ready to
be taught.
- **Costs:** the branch is tied to a part by its position, so the slot names fit the warrior best; the
  doll takes the most height (a screen at 412 px, a little more at 320).
- **Needs from Core:** nothing to ship it; to name the slots right for every class, an optional `slot` on
  each branch in `skill_trees.json` (Core's file), else the four names by order.

## What none of them changes
The info sheet, Raise tier, Merge and Craft, the My skills and Spells tabs, the essence pill and the
waiting-offer pill stay as today; only the Tree tab's body changes.
