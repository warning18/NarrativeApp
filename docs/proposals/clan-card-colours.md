# Clan colours on the offer card (UX-2, pictures only)

The user keeps v1.975's card and asks for colours that follow the clan, the rarity frames staying as Art made them. The mock is `test/ux_clan_card_colours_test.dart` (UX_SHOTS=<folder>); nothing in `lib/` changes. The effect line is back in every picture (it is the one-line fix of v1.975's card). Real data: the six clans of factions.json (Dominion, Crows, Compact, Mire, Vigil, Penitents) and the Wayfarer, each with a real gift of a different tier (Fireball, Frost Nova, Iron Stance, Multi Shot, Quick Heal, Second Dawn, Keen Eye).

Pictures, `docs/ux-shots/clan-card-colours/`: `compare.png` (today and the directions, one row each, the seven cards across), `cards-<id>-1x.png` (real size) and `-2x.png`, `hand-<id>.png` (a hand of three, Dominion / Mire / Penitents, the Mire card touched), `readability.csv`. Ids: `today`, `1-tint`, `2-backdrop`, `3-accents`, `4-mix`.

| | What changes | Strength | Build cost | New PixelLab pieces |
|---|---|---|---|---|
| 1 Body tint | the body takes a deep shade of the clan's colour (blue, red, rust, green, slate, sand-brown, neutral brown) | strongest at a glance: each card reads as its clan before the name | the smallest: two colours computed from the clan's colour in `ClanCardView` (a gradient instead of the navy); one line per clan if the shades are to be chosen by hand | none |
| 2 Clan backdrop | the art zone is a gradient in the clan's colours with the banner's sign, enlarged and faint, behind the banner and the plate | the subtlest: the sign shows only on a close look; the tier's backdrop stays at half strength | small: a gradient and the banner at scale 3 (done in the mock); the Wayfarer has no sign, so only the gradient | optional: a motif per clan (lantern, anchor, hammer, reed, eye, flame) drawn as a clean backdrop in the Apollo palette would read better than the enlarged banner |
| 3 Accents only | the body stays navy; the clan colour is on a thin inner trim, a heavier rule, the kind tag's outline, the quote marks and the +standing | the quietest: it needs a second look; the trim is hidden by the epic and legendary frames | the smallest after 1 (colours only) | none |
| 4 Mix (1 soft + 3) | a softer body tint with the accents | what I would pick: the clan reads from the body, the accents tie the foot to the name band, and the tint stays dark enough that every frame stands out | the cost of 1 plus 3 | none |

## Readability (WCAG contrast, `readability.csv`)
Worst case over the six clans and the Wayfarer, for every direction: the clan's words (cream) 9.4:1, the effect line (gold) 6.5:1, the +standing 5.6:1, the clan name in its light shade 5.4:1: all above 4.5. The name band's ink is chosen per clan (dark or cream, whichever contrasts more): worst case 4.3:1 on the Wayfarer's brown, 5.0 or more on the others; large text needs 3. The tint is deepest on the Penitents (sand), where it is brightest: still 9.4 for the words.

## The rarity frame against the tint
The frames keep their metals (iron, bronze, silver, gilded, gold). Against the tints they still read: iron and silver sit well on every tint; the bronze of the uncommon frame is close to the Compact's rust and the gold of the epic and legendary frames is close to the Penitents' sand, so those two pairings read the least (the frame's gems and the inner dark line still separate them). A tint at 0.26 (the mix) separates them better than 0.34 (direction 1).

## To decide
One of 1, 2, 3 or the mix; whether the Wayfarer keeps its brown or goes neutral grey. If Art is asked for the motifs (direction 2), say how many (six clans and the Wayfarer's boot) and at what size (a backdrop of 104 x 76 art pixels like the tier backdrops, so seven pieces).
