# A sign for how each clan stands with you (UX mock, for the user to approve)

Picture: `docs/ux-shots/standing-sign-mock.png`. Mock test:
`test/ux_standing_sign_mock_test.dart`. Nothing is built.

## What it is
A small round sign, in the corner of a clan's banner and at the clan's point on the
ring, that shows the clan's **standing step** with the player. It uses the steps
the clan card already shows (`StandingTier`, `standing_tier_*` words) and the
game's own tier colours (`tierColor`); no new numbers, no new thresholds.

| Steps | Sign | Colour |
|---|---|---|
| Sworn | star, double ring | gold |
| Trusted | shield | green |
| Friend, Friendly | heart | green / teal |
| Known | ring | teal |
| Unknown | dot | grey |
| Wary, Unfriendly, Resented | one blade | orange to red |
| Hostile | crossed blades | red |
| Hunted | crossed blades, double ring | dark red |

The signs are 7×7 pixel glyphs on a dark disc with a one-colour rim, hard edges,
like the banners. Shape and colour both carry the step, so it also reads for a
colour-blind player and at 16 px (the smallest size: the ring's crests and the
Throne room's standards at half scale). Full size is 28 px on the offer's banners.

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
2. Trusted uses a shield and not an open hand: at 7×7 the hand read as a plug.
3. The Open Hand clan (no standing of its own until the banner is raised) shows
   no sign until it has a standing.

## Build, if approved
A `StandingSign` widget in `lib/widgets/` (UX), one optional `tier` parameter on
the banner widgets (`ClanFlag`, `ClanPeek`'s crests, the Throne room's standards)
and the compass. The offer's and the ring's crests read the standing from
`PoliticsState.tierOf`. Small: it can go in the next UX PR (v1.554 or later,
after Core's #513 and the clan offer, which touch `offer_dialog.dart`).
