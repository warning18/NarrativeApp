# The clan's offer as cards: three directions (UX-2, pictures only)

The user: "not for the skills themselves but the skill offer from the clans or the levels from the clans (3 cards proposed only)." The skill tree, list and detail stay as they are.

Pictures: `docs/ux-shots/clan-offer/` (360 x 780 at 2x, the game's phone size, dark). Side by side: `compare-offer.png`, `compare-touched.png`, `compare-picked.png` (A | B | C). Per direction `a-`, `b-`, `c-` + `offer`, `touched`, `picked`, and `a-pick.gif`, `b-pick.gif`, `c-pick.gif` (idle, touch, press, picked, the others fall away). The mock is `test/ux_clan_offer_mock_test.dart` (UX_SHOTS=<folder>, UX_DIR=a|b|c); nothing in `lib/` changes.

## What the offer is today (`lib/data/offers.dart`, `lib/widgets/offer_dialog.dart`)
- Three suitors from three different clans (`offerSuitorCount = 3`), each with ONE gift on the table; the character takes one. The Wayfarer (no clan) can take a place (20 %). Fewer than three can come when fewer clans qualify.
- The gift is any of: a skill of a branch the clan sponsors (the first at Unknown, the second at Known, the third at Trusted, the fourth at Sworn), a sign, an object, a title, a Sworn boon, a perk rank (the Wayfarer), a specialisation (and its variants, rank II from Sworn), the clan's die, and the accords: a fusion (two known skills become a third, offered by both clans) and an ascension (a known skill is raised into its epic form, offered by the clan behind it, from Friend).
- The screen today is three clan banners side by side (the picked one takes the wind), the gift's kind and name under each, the first standing it moves, then the compass and words below.
- There is NO tier raise (I to III) in the offer: tiers are raised with essence on the skill's sheet. The closest thing to "a level from a clan" is the **ascension** (`ascendsSkillID`: 10 of them, all epic; for a Mage `mage_pyre_heart` raises Inner Fire, `mage_mending_tide` raises Mending Touch). So the pictures show two NEW SKILL cards and one ASCENSION card. Merges (fusions) are left out as asked. A real offer can also hold a sign, an object or a title in any slot: the cards for those are not drawn here; say if they should be, or if the offer should be limited to skills and ascensions (that is a rule change for Core).

## What the pictures use
A Mage at level 7: the Lantern Dominion (blue, sponsors Evocation) offers Fireball, the Salt Crows (red, Tempest) Frost Nova, the Ashen Penitents (sand, Aegis) the ascension Mending Tide, which raises the Mending Touch the character knows (`sponsors` in factions.json; an ascension is offered by the clan behind the skill it raises). From the data: the clan's name, colour, banner (`clanBannerId`, `PixelBanner`) and its first greeting; the skill's icon, effect line, element and rarity (`applySkillTier`). Standing: +6, the real gain of a taken offer (`_offerStandingGain`). Only the game's tokens: `InkColors`, the three ink fonts, `PixelChipBorder`, the harmonised skill icons, the Apollo palette. No cost gem: nothing in the offer has a price.

## A: Three portrait cards
The clan's banner hangs over the card in its colour, the gift is its seal under the banner, then the name, the kind tag, the effect, element and rarity, the clan's name. The touched card lifts and the line under the cards gives the clan's own words; the picked card lights gold and the other two fall away. All three on screen at once, the nearest to today's three banners. Narrow (106 px): the gift's description is short. Cost: one card widget and the offer row (replaces today's banner row): about 1 PR.

## B: Three stacked rows
Each row: the banner at the left in the clan's colour, the gift's plate, name and tags, the effect, the clan's name and greeting. A tap opens a row (taller banner, the full greeting, what taking it does to the clan and its rivals) and the button names the gift. Reads best on a small phone and in French. Cost: about 1 PR, the cheapest, and room for a row to grow when a gift needs more words (a title, an object).

## C: One big card, swipe
One big card at a time: the banner and the gift's icon side by side on the clan's colour, the clan's words in italics, a gold dot row; the next card peeks at the side. Strongest picture; to compare the three you swipe (one card at a time), and the compass and the words of today's screen have to find a place. Cost: a PageView and the card, about 1 PR plus the swipe tests.

## What each needs from Core
Nothing for the look: the clan, the skill and the ascension are all in the data.
- If the cards must show only skills and ascensions (as the brief says), the offer must be limited to them: today any slot can hold a sign, object, title, spec or die. That is a rule change; as it stands, the three directions show those other gifts as cards of the same shape (an icon, a name, a kind tag), which I can draw next.
- If "level" must mean a tier I to III of a skill, the clans do not offer it today (essence pays it on the sheet): also a rule change.
