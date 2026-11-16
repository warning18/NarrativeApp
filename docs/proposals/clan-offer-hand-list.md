# The clan offer: the hand for new things, the list for levels (UX-2, pictures only)

The user's decision: "Keep the card hand for the Skills, and the list for the levels up." The base card (`docs/ux-shots/clan-card/`) is approved as drawn; the small-cards-with-zoom layout is dropped. The mock is `test/ux_clan_hand_list_test.dart`; nothing in `lib/` changes. Pictures in `docs/ux-shots/clan-hand-list/` (360 x 780 at 2x, dark; `overview.png` shows four of them side by side).

## The hand (new skills): `hand-offer`, `hand-touched`, `hand-picked`, `hand-pick.gif`
The three cards fanned and overlapping; the touched one rises in front and the clan's own words appear above; the button names the gift and the clan in full ("Take Frost Nova from the Salt Crows"). Picked: the card rises and glows gold, the others drop and fade, the button turns to Continue. Real: Fireball (Lantern Dominion), Frost Nova (Salt Crows), Mana Shield (Ashen Penitents) for a Mage at level 7. `cards-full-size.png` is the three cards at their own size.

## The list (levels): `list-offer`, `list-opened`, `list-picked`, `list-pick.gif`
B's three stacked rows on the base card's tokens: the clan's banner at the left, the gift's plate, name, kind tag, "raises Inner Fire", the clan's words. A tap opens a row: the clan's greeting in full, **NOW and AFTER** with the real numbers ("Inner Fire: +1 damage · ×1.4" then "Pyre Heart: +2 damage · ×1.7"), and what taking it does to the clan and its rivals; the button names the gift. Real: Pyre Heart (Dominion, raises Inner Fire), Mending Tide (Penitents, raises Mending Touch), Iron Hide II (a Wayfarer perk rank, no banner: a plain pennant).

## What counts as a level in today's offer (offers.dart)
- the **ascension** (a skill the hero knows becomes its epic form; offered by the clan behind it, from Friend);
- the **perk rank** (the Wayfarer, a perk the hero has, up to its max rank);
- the **specialisation rank II** (a main clan's, from Sworn) and a spec variant upgrade (Trusted).
Everything else is NEW: a skill, a fusion (two skills into a third, but a new skill), a sign, an object, a title, a Sworn boon, a first specialisation, the clan's die.
**Each class has exactly two ascensions** (warrior, mage, rogue, cleric, ranger: 2 each), so an offer of three levels can never be made of ascensions alone: a real offer is mixed, or one with a Wayfarer rank or a spec rank. The list picture shows the best case (2 ascensions + a perk rank).

## The mixed offer: my recommendation (no rule change)
**One screen, one pick: what is new is a card in the hand, what raises something the hero already has is a row under the hand.** Cards 1 to 3, rows 0 to 2 (always three gifts in all, as today). The clan's words, the button and the pick work across the two (touch a card or open a row: the same words line and the same Take button).
- 2 new things + 1 level: two fanned cards, one row under them ("RAISES WHAT YOU HAVE"): `mixed-2cards-1row` (a card touched), `mixed-2cards-1row-opened` (the row opened, 360 x 860: the page scrolls), `mixed-2cards-1row-picked`.
- 1 new thing + 2 levels: one card, two rows: `mixed-1card-2rows`, `mixed-1card-2rows-opened` (360 x 880, scrolls).
- no level: the plain hand (`hand-*`).
Why: the screen never follows a majority that would hide a gift in the wrong shape; a level always opens to show NOW and AFTER (which a card has no room for), a new thing keeps its full card. Cost: the hand and the rows are the two widgets already costed, plus the one screen that holds both: about 1 PR for the hand and the rows, a few lines more for the mixed screen.

## Non-skill gifts
A sign, an object, a title, a Sworn boon, a die, a first specialisation are NEW things: **cards in the hand**, the same template with their own icon, kind tag and effect line (`non-skill-gift-in-hand.png`: the Cinder Compact's Iron Cap between two skills). Only the rank-ups (perk rank, spec rank II) are rows.

## Core
Nothing needed. If the user wants an all-levels or an all-new offer, that is a rule change (Core's); this proposal needs none.
