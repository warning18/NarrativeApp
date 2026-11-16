# The clan card: the base design (UX-2, step 1, pictures only)

The user's pick: A (three upright playing cards at the level-up) "but in the style of B to make like choosing from a card hand". This is the base card only; the touch, the pick and the gif come after the card is approved.

Pictures, `docs/ux-shots/clan-card/` (dark):
- `base-cards-1x.png` (the three cards side by side at real phone pixels, 1 dp = 1 px) and `base-cards-2x.png` (the same at 2x): one template drawn for the Lantern Dominion, the Salt Crows and the Ashen Penitents, with Fireball, Frost Nova and the Mending Tide ascension (a Mage at level 7, the same real gifts as before).
- `hand.png` (the three held as a hand at the level-up, 360 x 780 at 2x: the Salt Crows card touched, it rises out of the fan and comes in front), `hand-left.png`, `hand-right.png` (the other two touched), and `hand-three-touches.png` (the three side by side, half size).
- The mock is `test/ux_clan_card_base_test.dart` (UX_SHOTS=<folder>); nothing in `lib/` changes.

## The card (210 x 346 dp, ratio about 3:5)
From the top: the clan's colour as the frame (a stepped `PixelChipBorder`, 3 dp, a thin inner line); the art, 150 dp: the clan's own banner hanging at the left (the real banner, `clanBannerId`), the gift's icon on its element-tinted plate at the right, the kind of gift in a tag in the corner (NEW SKILL, ASCENSION); the name band in the clan's colour (IM Fell, ink on colour); the effect line at the skill's tier (pixel font) and, for an ascension, "Raises Mending Touch" in gold; two lines of the skill's own words; element and rarity tags; a rule; the clan's greeting in italics; at the foot the clan's name and the standing it gives (+6, the real gain of a taken offer). No price: the offer has none. Touched in hand: the frame goes gold, a glow, the card rises and comes in front.

In the hand a card is 66 % of that (139 x 228 dp), the touched one 84 % (176 x 291 dp, wider than a third of the screen), fanned a few degrees and overlapped by about 40 dp; the three fit the 332 dp between the page's margins.

Tokens: `InkFonts` (display, prose, system), `PixelChipBorder`, the harmonised skill icons on a plate tinted by the skill's element (Apollo), the clan's colour from factions.json, the clan's banner from `assets/visuals/banners`, the Apollo palette for the tags (element, rarity).

## When the gift is not a skill
The same card: the art zone keeps the clan's banner and shows the gift's own icon in the plate (a sign's glyph, the object's item icon, the title's mark, the clan's die), the kind tag changes (SIGN, OBJECT, TITLE, SWORN, PERK, SPEC, DIE), the name band is the gift's name, and the effect and words lines carry what it gives; the clan's words and standing stay the same.

## Cost to build
One `ClanCard` widget and a `ClanHand` (the fan, the touch, the pick): about 1 PR, replacing the banner row of the offer dialog; the compass and the words below it need a place on the screen (above the hand or in a sheet), to settle with the touch and pick pictures. No data change.
