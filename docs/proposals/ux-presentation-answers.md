# UX's answers to Core's presentation contract (docs only)

Core's proposal: `docs/proposals/presentation-contract.md` on `claude/core-presentation`.
Four UX questions, answered from `street_view.dart`, `journey_screen.dart`,
`arrival_sheet.dart` and `journey_banner_pin.dart`. Nothing is built.

## 1. Where the text goes on a street arrival
A **band over the sky**, not at the bottom. The street scene stands its pins at 0.6 to
1.0 of its height (`StreetViewScene.pinAt`), so a bottom band would cover them. The band
is about four lines at the top (`StoryText`, typewriter once) and a tap or a drag opens
the existing `ArrivalSheet` (it already has `arrivalSheetMinShare` 0.35 and a handle).
So it is a sheet that collapses to a band, with the collapsed band as the default.

## 2. How many street pins before the page
`pinAt` and `street_view_test` cover 1 to 8: one row up to 4 pins, two rows above. From
5 on, a pin's cell is `min(84, width / inRow - 2)`.
- **Comfortable: 6** (3 + 3, labels on two lines).
- **Hard maximum: 8** (4 + 4, about 78 px a cell at 320 wide, one-line labels).
- Above 8: the page, or the district rows.

Suggested rule: up to 6 street; 7 to 8 street only when the labels are short; above 8 page.

## 3. A fight way as a street pin
Yes, with no new art. A street pin's child is `streetPinOf`: a `BannerPin` or
`kindDisc(step)`, and `kindDisc` already draws the fight kind (its icon and colour,
`JourneyStepKind.fight`). The district pins keep fights as cards today
(`journey_banner_pin.dart`: "the fights and rolls ... cards, not pins"), so a street
would be the one place a fight is a pin. If it must read as a fight beyond the colour,
UX adds a small crossed-blades badge on the disc (a few lines).

## 4. A hub opens its map, the prose as a header
Drawable with what the district view has: it already has a header line (who holds the
place) and the ways as pins and rows (`WayPinList`). Add a three-line prose header
(`StoryText`) above the rows, that opens the `ArrivalSheet` on a tap. Small. Caveat: the
camp's own hub is the Camp tab, not the map, so the rule fits a town's hub and a camp
scene keeps its tab.

## Related
v1.573 (PR #532, UX) changes `foundDistricts` in `city_districts.dart` (Core's file): a
scene played in the town itself, in no district, finds the first open district, so an
arrival never shows every district fogged. It does not change `partyDistrictProvider`,
so the arrival rules above are unaffected.
