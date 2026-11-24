# Ink pieces with variation and with weather (pictures only, nothing ships)

Six sheets at 360 wide, made by `test/ux_ui_variation_weather_test.dart`
(`UX_SHOTS=<dir> flutter test test/ux_ui_variation_weather_test.dart`):

- `ink-variation.png`: five pieces (red skew button, paper frame button, black + paper line
  button, ink panel, torn banner tab) under six seeds each.
- `ink-weather-rain.png`, `-snow`, `-dust` (sand and dust), `-fog`, `-ash` (ash and embers):
  the same five pieces, clear / light / heavy.

## Variation: what a seed picks (all code)

A seed (a button's key or a panel's id hashed to an int) always gives the same look; neighbours
differ. In the pictures: the red (red, rust, dried-blood brown, faded red), the paper (paper,
warm grey, cold grey, ochre-tinged), a tilt of 1 to 3 degrees either way, a tear pattern on the
right edge, a chipped corner, a folded corner, a burn mark, a stain, ink splatter, a pin or wax
dot. A clan or rarity accent (ink-blue, epic violet, heroic ochre) stays a thin edge or corner.

| Part | Code or Art | Size |
|---|---|---|
| Tint, tilt, stains, splatter, pin, fold, burn, chip | Code | none |
| Tear on a plain strip or red block | Code (a seeded jagged clip) | none |
| Tear on the paper frame and the brush frame | Art | M: 4 to 6 tear masks (the wide frame's own torn edge is Art's already; masks vary it) |
| Stains and splatters | Art (better than blobs) | M: 4 to 6 stain / splatter overlays, one with a burn |
| Drier or thicker brush stroke, chipped paint | Art | S: 3 to 4 brush-edge variants for the frame and the slash |
| Wax dot / pin | Code (circles); Art for a real wax blot | S |

## Weather: what is read, and what is drawn

Where the game knows the weather today:

- `skyHereProvider` (lib/providers/climate_provider.dart) gives a `SkyHere?`; `.today()` is a
  `WeatherSample` with `kind` (`WeatherKind`: clear, cloud, fog, rain, snow, dust, ash), `fall`
  (0 to 1, how hard it rains, snows or blows) and the wind. It is null in an excursion or
  where the party has no landmark: that reads as clear.
- The fight header already reads `WeatherEffects.of(kind)` (fight_ground.dart: "City road · Rain").
- The Tower has no sky: its bands are snowy by design (the painted scenes), so the Tower would
  pass a fixed value per band (snow, `fall` about 0.4 / 0.7 / 1.0 for bands 1 / 2 / 3).
- Maps has `chart_weather` for the chart itself.
- No field is missing. One small provider would carry `(kind, fall)` to the UI: `skyHereProvider`
  mapped, with the Tower's override. `cloud` and `clear` draw nothing.

What is drawn (all code, painted over the piece; the weather is inside the piece's tilt):

| Weather | Look | Rule so it stays readable |
|---|---|---|
| Rain | darker, a glossy streak, ink bled along the foot, drips off the bottom edge (count and length by `fall`) | drips hang outside the box; the streak is a faint overlay |
| Snow | snow piled on the top edge, frost at the corners | the cap sits above the top edge, never over the label |
| Sand and dust | a sand drift on the top edge, dust in the lower corners | same: outside the label's room |
| Fog | a faded veil, thicker toward the foot, the piece slightly lighter | contrast of the label is kept (veil capped at about 0.5) |
| Ash and embers | soot along the top, burnt specks and a few embers | specks stay in the margins |

Reduce motion: every picture is still. If the drips run or the glossy streak sweeps, that
animation is off under `MediaQuery.disableAnimations` and the still is shown.

Art for weather (optional, the code version works as is):

| Item | Size |
|---|---|
| Snow caps in 3 to 4 shapes (the top edge) | S |
| Frost corners, 2 shapes | S |
| Sand drift in 2 to 3 shapes | S |
| Drip and drop sprites | S |
| Soot / ember specks sheet | S |
