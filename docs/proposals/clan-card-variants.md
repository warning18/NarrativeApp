# Other designs for the clan offer card (UX-2, pictures only)

The user asked for other designs of the card shipped in v1.975. Same content (banner, gift icon, name, tags, effect, clan words, clan name, +6), the same five PixelLab rarity frames and the same fanned hand; the composition changes. Real data (a common, a rare and a legendary skill from three clans: Heavy Attack / Cinder Compact, Fireball / Lantern Dominion, Second Dawn / Ashen Penitents). The mock is `test/ux_clan_card_variants_test.dart` (UX_SHOTS=<folder>); nothing in `lib/` changes.

Pictures, `docs/ux-shots/clan-card-variants/`: `compare.png` (today and the four, one row each), `cards-<id>-1x.png` (real size, 1 dp = 1 px) and `-2x.png`, `hand-<id>.png` (the level-up screen, the middle card touched). Ids: `today`, `a-fullart`, `b-tarot`, `c-seal`, `d-compact` (+ `cards-d-compact-touched-2x.png`).

| | Idea | What changes | Cost to build | New PixelLab pieces |
|---|---|---|---|---|
| A Full-art | the whole face is the picture; text on a dark band at the foot | big banner and gift on the backdrop, name 24 dp, effect, tags, two lines of words | about the size of v1.975 (one card widget, same hand) | none |
| B Tarot | the clan is a header; the gift stands in an arch; the name on a scroll | header band with the clan's name and its sign at both ends, an arch window, a ribbon for the name | a little more: an arch clip and a ribbon painter (both done in the mock) | optional: an arch window and a scroll ribbon in the tier metals, so the arch and the scroll wear the tier too |
| C Seal | a letter from the clan: the gift on top, the words in a larger hand, a wax seal with the clan's sign | no banner on the card; a code-drawn pixel seal with the emblem | the same as A | recommended: a wax seal in the five tiers or one per clan colour (the code one is plain) |
| D Compact | fewer lines, larger type: icon, name, two tags; the effect and the words only when touched | a short banner at the corner, a panel rising over the foot when touched | a little less than v1.975 (fewer lines) plus the panel; the touch state already exists | none |

Notes: every card keeps the 210 x 346 box, so the hand, the rows and the touch stay as they are. A and D put the name larger (24 and 30 dp); B and C keep the clan's colour as a band or a seal rather than on the name. D hides what v1.975 shows at rest (the clan's words and the effect), which matters for a player choosing among three at a glance.
