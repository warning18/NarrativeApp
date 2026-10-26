# A sign for how each clan stands with you (UX mock, for the user to approve)

Picture: `docs/ux-shots/standing-sign-mock.png`. Mock test:
`test/ux_standing_sign_mock_test.dart`. Nothing is built.

## What it is
A small round sign, in the corner of a clan's banner and at the clan's point on the
ring, that shows how the clan stands with the player **at a glance**: green heart,
grey dot, red crossed blades. It reads the steps the clan card already shows
(`StandingTier`, `standingTierFor`) with Core's three-way mapping, and the game's own
step colours (`tierColor`); no new data, no new numbers.

| Reading | Steps | Sign | Colour |
|---|---|---|---|
| Friendly | Friendly, Friend, Trusted, Sworn | heart | green (the Friend step's) |
| Neutral | Wary, Unknown, Known | dot | grey (the Unknown step's) |
| Hostile | Unfriendly, Resented, Hostile, Hunted | crossed blades | red (the Hostile step's) |

The sign is a 7×7 pixel glyph on a dark disc with a one-colour rim, hard edges, like
the banners. Shape and colour both carry the reading, so it works for a colour-blind
player and at 16 px (the smallest size: the ring's crests and the Throne room's
standards at half scale). Full size is 28 px on the offer's banners. The clan card
keeps the exact step word; the sign is the glance.

**A finer option, only if three is too coarse** (shown at the bottom of the picture):
one sign per step (star for Sworn, shield for Trusted, heart for Friend/Friendly, ring
for Known, dot for Unknown, one blade for Wary to Resented, crossed blades for
Hostile, double-ringed for Hunted). I would start with the three-way.

## Where
- **(a) Banners**: the offer sheet's banners, the ring's crests, the Throne room's
  standards (top-right corner, drawn over the banner so it does not move layout).
- **(b) The ring** (`ClanCompass`): the same sign at each crest. The focused clan's
  lines keep their relation colours; the signs are the player's standing, the
  lines are clan-to-clan.

## Open points for the user
1. I read "the radar between clans" as the **ring (`ClanCompass`)**. If it means the
   per-clan five-axis radar (`ClanRadarChart`), the sign would sit on its centre
   or title instead; say so.
2. Friendly is a heart and not an open hand: at 7×7 the hand read as a plug.
3. The Open Hand clan (no standing of its own until the banner is raised) shows
   no sign until it has a standing.

## Build, if approved
A `StandingSign` widget in `lib/widgets/` (UX; it maps the tiers inline, or uses Core's
`standingSignOf(StandingTier)` helper if Core's clan offer PR has it by then), one optional `tier` parameter on
the banner widgets (`ClanFlag`, `ClanPeek`'s crests, the Throne room's standards)
and the compass. The offer's and the ring's crests read the standing from
`PoliticsState.tierOf`. Small: it can go in the next UX PR (v1.554 or later,
after Core's #513 and the clan offer, which touch `offer_dialog.dart`).
