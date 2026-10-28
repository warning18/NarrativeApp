# The Skills tab, three calmer versions (UX mock, nothing built)

The user: "The skills tab is a bit crowdy and too complex at first, so please propose different new or
optimized versions." Pictures only: no build, no version. All four pictures are drawn from the app's
own data and skin (the real skills model, skill tree, icons, clan flags and theme); the first is the
real screen. Mock test: `test/ux_skills_mock_test.dart` (parts in `test/ux_skills_mock_parts.dart`).

| Picture | What it is |
|---|---|
| `docs/ux-shots/skills-today.png` | The real Skills screen, level 1 and mid game (a level 12 warrior), at 320 and 412 px. |
| `docs/ux-shots/skills-a.png` | A: today's tab, with less on it. |
| `docs/ux-shots/skills-b.png` | B: a first page with very little, that grows with the hero. |
| `docs/ux-shots/skills-c.png` | C: a different shape: next skill, paths, the map behind a button. |

## What is crowded today (from the capture)
- At level 1 everything is on the first screen and almost all of it is locked: two purse boxes with
  "0 waiting" and "0 essence" (and a note each), a rules line, four branches of four skills (16
  rings, 16 clan names, 16 flags, 4 Mastery nodes with a label), then two more screens (heritage,
  reputation). On a 320 px phone the four columns clip ("Stonewar d").
- The player cannot learn anything on this screen (v1.194: the clans offer skills), so most of the
  tree is a map of what a clan could one day offer, drawn at full weight.
- Tree and My skills draw the same known skills; Spells is a tab even for a class with no spells
  ("No spells known").
- Learning: an offer arrives (a level, a boss, a quest), three clans suitor it, and a skill is one
  kind of gift among several. Nothing on the tab says this in a way the first-time player can use.

## A. Today, with less on it
Same structure (purse, Tree / My skills / Spells), less on screen:
- **Level 1:** no purse (nothing waits, no essence); only the first skill of each branch drawn, the
  rest as dots; heritage and reputation folded; one screen, no scrolling.
- **Mid game:** one line of two pills (the offer waiting; essence against the cheapest next tier,
  lit when a tier can be raised); known skills and the next one of each branch in full, deeper ones
  dots until they are next; the Spells tab only for a class with spells.
- **Learned:** as today, by a clan's offer; tap a lit skill: who offers it, at what standing.
- **Merges and upgrades:** as today: Raise tier on the skill's sheet; the Craft card at the bottom
  of My skills with the Skillwright.
- Taken off the first screen: the rules line, the purse notes, branch descriptions, clan names on
  locked skills, Mastery labels until a branch is learned.

## B. A first page that grows with the hero
No tabs at first. "Your skills", then "Next from the clans" (the next skill of each branch, who
offers it and at what standing: Unknown, Known, Trusted, Sworn), then "See the whole tree".
- **Level 1:** one known skill and four "next" rows. No essence, spells or merge.
- **Mid game:** the offer banner while one waits; known skills (four, "+3 more"); the essence line
  after the first skill that has tiers, which becomes a purple Raise button when essence is enough;
  "Next from the clans"; the Merge card with the Skillwright; a Spells row for a class with spells.
- **Learned:** by offer; the rows say whom to work toward.
- **Merges and upgrades:** one Raise button and one Merge card, each only when it can be used.
- The whole tree is one tap away, unchanged.

## C. Next skill, paths, map
- A card for the skill first in line (or "an offer is waiting"): its look, effect, who offers it, at
  what standing.
- **Your paths:** one rail per branch, four beads (gold tick known, lit ring next, dot later), the
  Mastery star at the end; a tap opens the branch's four skills (right frame).
- **Your skills:** a grid of icons with tier dots, the essence beside it.
- Buttons at the foot: the map of the whole tree, Merge (with the Skillwright), Spells (a class that
  has them).
- **Level 1:** the card, four paths with one lit bead each, one skill, one button.

## For the manager: what each needs from Core
Nothing for any of the three: they read the session, the skill tree and the clans. Optional, for C:
a way to say which skill a waiting offer carries (the card names the next of the first unfinished
branch). B and C both lean on the standing each depth needs (Unknown, Known, Trusted, Sworn,
`skillIndexCapFor` in offers.dart), which UX reads from the branch index.

## Questions for the user
1. Which of A, B or C?
2. Should the Spells tab (or row) disappear for a class with no spells?
3. For B and C: is "the next skill of each branch" the right thing to show, or should the page name
   only the clan offer that is waiting?
