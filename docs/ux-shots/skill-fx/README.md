# Skill effects that touch the interface (picture only)

Basic attack, Fire and Poison fist, each in a subtle and a strong version, on
the real Tower fight at 412 wide. `strip-<skill>-<version>.png` has 8 key
frames (the time is on each); `<skill>-<version>.gif` plays the whole thing
(frames every 40 ms, 412 x 560, no recorder needed: every frame is a pure
function of the time, see `lib/screens/fight/fight_panel_fx.dart`).

Reach: panel (the effect stays in the target panel), cross-panel (an ember
leaves You and crosses the gutter), full screen (tint, shake, embers over the
app bar), kept for crits and big moves. Colours: the Apollo tones (fire,
poison), ink and paper for the slashes; red only for the damage numbers and
the HP bar chunk. No red flash anywhere.

| Skill | Version | Length | What happens |
|---|---|---|---|
| Basic attack | subtle | 300 ms | one paper slash over the foe panel (0 to 90), frame flash (110 to 250), foe panel shifts 1 px, 12% of the HP bar breaks off and falls (110 to 440), "-12" |
| Basic attack | strong (crit) | 520 ms | three slashes, frame flash 110 to 330, panel shifts 2 px, 22% chunk, "-27!", brief paper flash over the whole fight (110 to 300) |
| Fire | subtle | 1.0 s + tick | ember crosses the gutter (0 to 260), You's frame flashes as it leaves, foe frame flashes ember, 18 embers spill over the frame and drift up over the app bar, 10% warm vignette (260 to 780), shift 1 px; burn tick at 1400: 5 small embers, a sliver of bar, "-2" |
| Fire | strong | 1.0 s + tick | bigger ember and trail, 40 embers rising over the app bar, 26% warm vignette, foe panel shifts 2 px and the whole screen 3 px for 200 ms, 20% chunk |
| Poison fist | subtle | 500 ms, then lingers | paper impact star (90 to 240), 11 green drops, green frame flash, 10% chunk; then 3 green drips on the border, a green rim under the bar, and each tick (every 900 ms) pulses the bar green, a 5% chunk, "-3" in green |
| Poison fist | strong | same | bigger star, 22 drops, flash 300 ms, 18% chunk, 6 border drips and 3 bar drips |

Off switches (they exist): the foe panel's shift, the whole-screen shake, the
vignette and the flash follow the tremble setting (`trembleEnabledProvider`)
and the system's reduce-motion; everything follows
`combatEffectsEnabledProvider`. With both off, only the frame flashes, the
particles and the chunk remain (no movement of the screen).

What a real build needs from Core (listed for the Manager, none exists now):
- a damage event with the hit's size, crit flag and the target (the fight
  screen has the numbers; `VfxBurst` carries power and tier but no crit flag),
- a status tick event (burn and poison, each round) with the target and the
  amount, so the lingering drips and tick pulses can follow the real status,
- the HP bar's rectangle, or a key on it: the pictures use its place in the
  foe's plate as it is drawn today (about 36 px under the panel's top).

Limits of these pictures: the hit spot is the lone foe's place on the right of
its panel; a pack of foes would aim at the targeted foe's figure. The foe's
name varies between pictures (the fight picks it at random).

Code: `fight_panel_fx.dart` (new, UX), hooks in `fight_tower_panels.dart`
(keys and the foe panel's shift) and `fight_view.dart` (the layer and the
screen shake). Nothing plays it in a real fight yet (`panelFx` is null).
