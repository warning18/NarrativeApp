# Skill effects that touch the interface (v2.10.12)

Basic attack, Fire and the poison fist, each in a subtle and a strong version,
on the real Tower fight at 412 wide, played from the fight's own events
(`fightEventsProvider`): a hit carries its crit flag, tier, skill and element;
a poison tick has its own event. `strip-<skill>-<version>.png`: 8 key frames
(the time is on each). `<skill>-<version>.gif`: the whole effect (a frame every
40 ms). `rival-real-412.png`: a real rival floor (seed 1, floor 2), the two
fighters side by side (v2.10.9's layout, now switched on by Core's flag).

Reach: panel (the effect stays in the target's panel), cross-panel (an ember
leaves You and crosses the gutter), full screen (tint, shake, embers over the
app bar), kept for crits and strong Fire. Colours: Apollo tones (fire, poison),
ink and paper for the slashes; red only for the damage numbers and the HP bar
chunk, never as a flash.

| Effect | Plays when | Length | What happens |
|---|---|---|---|
| Basic, subtle | any hit with no element or poison, normal or light tier | 440 ms | a paper slash over the foe, frame flash (110 to 250), panel shifts 1 px, 12% of the bar breaks off and falls, the number floats |
| Basic, strong | a crit, or a strong or mighty hit | 560 ms | three slashes, flash to 330, shift 2 px, 22% chunk; a crit also flashes paper over the whole fight (110 to 300) |
| Fire, subtle | a Fire skill or spell | 900 ms | ember crosses the gutter (0 to 260), You's frame flashes as it leaves, foe frame flashes, 18 embers spill over the frame and drift up over the app bar, 10% warm vignette, 1 px shift |
| Fire, strong | a strong or mighty Fire hit | 1.1 s | bigger ember, 40 embers, 26% vignette, 2 px shift and a 3 px screen shake for 200 ms |
| Poison fist | a skill that inflicts Poison | 560 ms | paper impact star, green splash, green frame flash, chunk |
| Poison, lingering | while a fighter has poison | continuous | green drips on the frame and under the bar, a green rim under the bar; each poison tick pulses the bar green with a small chunk and a green number |
| Foe's blow on You | a foe's move | as Basic | the same plain blow on the You panel, 1 px shift of that panel |

Off switches: the panel shift, the screen shake, the tint and the flash follow
the tremble setting and the system's reduce-motion; the effects as a whole
follow the combat-effects setting. With tremble or reduce-motion off, only the
frame flashes, the particles and the bar chunk remain (nothing moves, nothing
tints).

Notes: the engine has no burn status, so Fire plays on its impact only (no
burn-tick embers). Spells and foes' moves never crit, so only a party strike
can flash the screen. Hit spot: a lone foe stands on the right of its panel; a
pack aims at the targeted foe's share of the width. The HP bar's place is read
from the fighter's card (its plate's foot).
