# Skills and level-up as cards: three directions (UX-2, pictures only)

The user's ask: "a card style UI/UX for skills and level up, propose multiple to choose, that should match the actual design system."

Pictures: `docs/ux-shots/skill-cards/` (360 x 780 at 2x, the game's phone size, dark). Side by side: `compare-tree.png`, `compare-detail.png`, `compare-level-up-offer.png`, `compare-level-up-picked.png`. Per direction `a-`, `b-`, `c-` + `tree`, `detail`, `level-up-offer` (a card hovered or opened), `level-up-picked`, and `a-pick.gif`, `b-pick.gif`, `c-pick.gif` (the pick: idle, hover, press, picked, the others fall away). The mock is `test/ux_skill_cards_mock_test.dart` (UX_SHOTS=<folder>, UX_DIR=a|b|c): nothing in `lib/` changes.

What is real: the skills and branches are the Mage's (`skills.json`, `skill_trees.json`), names from `skillDisplayName`, numbers from `applySkillTier` and `tierTable` (tier 0 to 3, +25 % and +0.1 per tier, 2,000 essence to raise tier I to II), the merge is Fireball + Shadow Step = Blazing Shadow (`skill_merges.json`), the clan is the Cinder Compact. Only the game's tokens: `InkColors`, the three ink fonts, `PixelChipBorder`, the harmonised skill icons, the Apollo palette for the element and rarity tints (no colour or font that is not in them).

What a card shows, in all three: the icon on an element-tinted plate, the name, the effect line (numbers at the skill's own tier), element, rarity, the cost gem (`cost` of skills.json), tier pips, a lock when it comes later, and on the level-up a kind tag (LEARN, MERGE, RAISE).

## A: Playing cards (portrait)
A portrait card in the rarity's colour. Tree: two cards per row under each branch's name. Detail: one big card and the tier table. Level-up: three cards side by side, the hovered one lifts, the taken one lights gold and the others fall away. Best for the feeling of choosing a card. Costs most: a new card widget, a new grid for the tree and the offer row; the narrow offer cards (104 px) force small text, long names wrap to two lines. About two PRs.

## B: Ledger rows (wide cards)
A wide row card: plate, name, effect, tags, cost and tier at the right. Tree: rows on a vertical rail (known nodes lit), same as today's top-down order. Detail: the row on top and the tier table in tiles under it. Level-up: three rows stacked, one opens to show the full effect or the merge's two inputs, then "Take". Reads best on a small phone and in French (long words), keeps the list order of the tree; the card feeling is weaker. Cheapest: reuses the Tree and My skills lists as they are, one PR.

## C: Tiles and one big card
A square tile (icon first, the name on a rarity-coloured foot). Tree: one column per branch, tiles joined by a line, all three branches on one screen. Detail: a poster, the icon big on an element glow, stat tiles and the tier strip. Level-up: one big card at a time with the next peeking at the side, dots, swipe to compare, "Take" below. The strongest picture and the clearest tree; the cost is a swipe to compare offers (you see one card at a time) and a PageView. Needs tiles to fit three across at 320 px. About two PRs.

## What each needs from Core
Nothing for the look: every field is in the data (element, rarity, cost, description, tier, the clan that offers, the merge recipe, the essence price).
Two questions, the same for the three directions:
1. The level-up offer today is the clan's gifts (skills, items, perks; `offers.dart`); a merge is done at the Skillwright and a tier is raised with essence on the skill's sheet. The pictures show LEARN, MERGE and RAISE together as the user's brief asked ("offered skills, merges or upgrades"): mixing the three kinds into one offer is a rule change (Core). Without it the offer is LEARN cards only and the other two stay where they are; the directions all still work.
2. The gem shows `cost` of skills.json (2 to 5). If that is not a price the player pays (the tree's learn price is `branchSkillPointCost`, and the clans now give skills), the gem becomes the essence to raise or goes away: Core to say.
