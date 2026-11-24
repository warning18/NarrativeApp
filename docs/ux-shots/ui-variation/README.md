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

## Accumulation (second round: snow that builds, a tap that knocks it off)

Pictures in `accumulation/`: `snow-accumulation.png`, `sand-accumulation.png`,
`ash-accumulation.png`, `rain-accumulation.png` (a button and a panel at 0, 10, 30 and 60 s),
`snow-knock.png` (before, the tap, 0.2 s, 0.5 s, 12 s later) and `snow-accumulation.gif`
(360 wide, 8 s: 60 s of snow at x7.5 and a tap at 5.6 s). Made by
`test/ux_weather_accumulation_test.dart`.

What changed from the first round: the cap is a soft irregular drift (a profile thin at the
ends and thickest toward the windward side, lumps from a few seeded sines, never a repeating
scallop), a lit top over a shaded under-edge, a few loose flakes on top. Sand is the same drift
with ripple lines; ash is a dark drift with a few embers.

How it would work (all code):

- Level: 0 to 1 and `level = seconds on screen / secondsToHeavy(fall)`, with
  `secondsToHeavy = 30 / fall` (fall clamped to 0.3 to 1: 30 s in the hardest fall, 100 s in a
  light one). The cap height is `12 px x level` at most, so it stops at its maximum and never
  reaches the label's room (the label sits inside the box, the cap on its top edge).
- One ticker per screen, not per button: a `WeatherClock` (an InheritedNotifier above the
  screen, one `Ticker` that advances a `ValueNotifier<double>` for seconds on screen). Every cap
  is a `CustomPaint(repaint: clock)` so nothing rebuilds. The level is quantised to 1/32 so a
  cap re-lays its path only about 32 times between nothing and heavy, then not at all. A path
  is about 140 points: a tenth of a millisecond.
- A tap: that piece starts a 450 ms `AnimationController` (only alive while it knocks): the cap
  drops about 20 px fading, a puff of flakes (size by the level it had) flies off, then the
  piece's own level restarts from zero at the screen's clock (it stores `knockedAt`).
- Leaving and coming back: a `weatherAccumProvider` (Riverpod, in memory) keeps
  `(kind, level, savedAt)` per screen; on return `level -= away / 120 s`, floored at 0, so it is
  roughly where it was and never resets on a rebuild or a frame.
- Reduce motion (`MediaQuery.disableAnimations`): a fixed medium cap (level 0.5), no growth, no
  ticker, no falling; a tap does nothing visible.
- Rain: wetness builds over about 8 s at full fall (the piece darkens, a glossy streak fades
  in), drips start once it is wet through (wetness above 0.6) and lengthen. In the build only
  the fill darkens, not the label (here the label dims with the piece; that is the mock).
- Weight: one ticker per screen, caps repaint only on a quantised level change, so an idle screen
  in full snow costs nothing after the cap is heavy.

Art for the caps (the code shape stands in until then; sizes as before): 3 to 4 painted snow
cap profiles in two widths (S), 2 to 3 sand drifts (S), 2 ash drifts (S), a puff sprite strip
for the knock (S).
