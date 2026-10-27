# A clan at a glance: power and familiarity on one banner (proposal, nothing built)

Picture: `docs/ux-shots/clan-glance-mock.png`. Mock test:
`test/ux_clan_glance_mock_test.dart`. Nothing is built.

The user asked for one update to understand a clan's **power** and the player's
**familiarity** (standing) with it at a glance. Two marks on the same banner,
each reading the tiers the clan card already shows (`StandingTier`,
`PowerTier`): no new data, no new numbers.

| Mark | Says | How |
|---|---|---|
| The disc, top-right corner | how it stands with you | heart (friendly), dot (neutral), crossed blades (hostile); Core's three-way reading of the steps, the game's own step colours; shape and colour both carry it |
| The cloth | how strong it is | the banner is a dark silhouette that fills with its own colours from the foot, a quarter for each of Minor, Rising, Dominant, Ascendant, with a gold hairline at the level |

The two cannot be confused: the disc has a shape and sits in the corner, the
cloth is the banner itself, and neither uses the other's colours (the cloth
never turns green or red). The clan card and the Clans list keep the exact
words ("Friend", "Dominant") one tap away, and the list rows show them beside
the banner.

## Where
Offer banners (128 px), Throne room standards (64 px), the ring's crests
(34 px), the ring itself, the Clans list's rows. Nothing changes layout: the
disc is drawn over the corner.

## What I chose, and why
- The standing disc is the design the user liked (earlier mock, `claude/ux-mocks`).
  It was marked "dropped" in a relay as repeating the banners and the ring; this
  puts it back, paired with power, since the user now wants both at a glance.
- Power is the cloth that fills (B of the last redraw): it needs no extra mark and
  reads at every size. Its cost: a **weak clan's banner shows mostly as a dark
  silhouette**, which is the point of the gauge but loses its colours. If that is
  too much, the redraw's other two ways are an I to IV plate at the foot (exact,
  quiet) or size and aura (loudest, best on the ring only).

## Build, if approved
`PowerCloth` and `StandingSign` widgets in `lib/widgets/` (UX); one optional tier
on `ClanFlag`; the compass and the Clans list take the two tiers from
`PoliticsState.tierOf` and `powerOf`/`powerTierFor` (the clan card already calls
them), so no Core change. About a day, one PR, one test.
