# A sign for how strong each clan is (UX mock, for the user to approve)

Picture: `docs/ux-shots/power-sign-mock.png`. Mock test:
`test/ux_power_sign_mock_test.dart`. Nothing is built. It sits beside the standing
sign (`standing-sign.md`) and is drawn so the two are never confused.

## What it is
The clan card's power tier (`powerTierFor` in `clan_power.dart`, the four names the
card already shows): **Minor** (below 25), **Rising** (25–49), **Dominant** (50–74),
**Ascendant** (75 and up). No new numbers, no new thresholds.

**Recommended: rank chevrons on a flat plate at the banner's foot**, gold, one to
four chevrons lit (the unlit ones stay dim, so the scale is always visible), like a
rank insignia. Ascendant also gilds the plate's rim.

| | Standing sign | Power sign |
|---|---|---|
| Shape | round disc | flat plate, chevrons |
| Place | top corner | foot of the banner |
| Colour | green / grey / red | gold (never red or green) |
| Reads as | friend or foe | big or small |

**On the ring** the crest also grows with its tier (about 80 / 95 / 110 / 128 %), and
an Ascendant crest gets a gold frame, so the ring reads as a map of who is big even
before the plates are read. This is the ring-only part and can be dropped if it
crowds the ring.

**Option B (shown once, beside the offer banners)**: four small bars under the hem,
one lit per tier. It takes no room on the banner's art, but it reads weaker than
chevrons below 34 px.

## Where
The same places as the standing sign: the offer sheet's banners, the ring's crests,
the Throne room's standards. Clans with no power (`hasPower` false, e.g. the Open
Hand until raised) show no plate. A nemesis keeps its red mark (`nemesisRed`) on the
card; the sign stays gold.

## Open points for the user
1. Chevrons or bars? I recommend chevrons.
2. Should the crest growing on the ring stay, or is the plate enough?
3. At full size the plate covers the banner's lower art; at the offer's size I would
   shrink it to the 34 px recipe (about 14 × 13) if the art matters more.

## Build, if approved
A `PowerPlate` widget in `lib/widgets/` (UX), one optional power tier on the same
banner wrapper the standing sign uses, and the compass's crest scale. The tier comes
from `powerOf` and `powerTierFor` (the clan card already calls them), so no Core
change. It rides in the same UX PR as the standing sign.
