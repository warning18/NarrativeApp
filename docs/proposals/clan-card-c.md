# The clan card, design C made small, zoom on tap (UX-2, step 1, pictures only)

The user: "Design C but smaller card that zoom when clicking on them." This replaces the fan (`clan-card-base.md`).

Pictures, `docs/ux-shots/clan-card-c/` (dark; `-1x` real phone pixels, `-2x` at 2x):
- `level-up-*`: the level-up screen with the three small cards in view at once, no swiping.
- `zoomed-dominion-*`, `zoomed-crows-*`, `zoomed-penitents-*`: one tapped and zoomed to C's big card over the others (dimmed behind a scrim), with its full text, "Take <gift> from <clan>" and a close mark (tapping outside also puts it back).
- `small-cards-*`: the three small cards at their own size.
- The mock is `test/ux_clan_card_c_test.dart`; nothing in `lib/` changes.

Small card 106 x 206 dp (three across the 332 dp between the margins): the clan's banner and the gift's icon on the clan's colour, the kind tag, the name band, the effect line, element and rarity, the clan and the standing it gives (+6). The clan's words and the description come with the zoom. Zoomed card 262 x 410 dp: the same card at big size with the description, the clan's greeting in italics, the full clan name, and under it the button and "Tap outside to put it back". No price. Real data: factions.json (colour, banner, greeting), the Mage's skills, the Mending Tide ascension.

A gift that is not a skill (a sign, an object, a title, a Sworn boon, a die) fills the same card: the clan's banner stays, the plate shows the gift's own icon, the kind tag and the name band change, and the effect line says what it gives.

Cost: a `ClanCard` small and big plus the zoom overlay (a scrim, a scale-in, tap outside to close): about 1 PR, replacing the banner row of the offer dialog. No data change.
