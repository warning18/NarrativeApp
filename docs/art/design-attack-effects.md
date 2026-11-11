# Basic attack, die-landing and hit animations: a proposal (picture first, nothing wired)

Sheet: `docs/art/boards/attack-fx-pilot.png` (today | proposal). Strips: `art/pixellab-attackfx/strips/`, GIFs `gif/`, generator `attackfx_gen.py`. **The user approved the full set of 11: all drawn, hand-drawn in code, 0 generations.** Strips: die_strike, die_ward, die_bloom, die_arcs (mana), die_miasma (poison, light: the code bubbles keep the motion), die_shock (stun), die_drain (weaken, light), die_fizzle (blank, light: the shake stays code), hit_slash, hit_heavy (a second crescent lands two frames later), hit_crit (gold starburst, 48x48). Same look as the skill strips: 5 colours + ink, hard edges, no glow, whole-pixel scaling.

## How it works today
`lib/widgets/die_3d.dart` plays, when a die lands, a code burst (`DieFx`: strike, ward, bloom, arcs, miasma, shock, drain, fizzle) and, on top, the pixel strips `die_<fx>`, `el_<element>`, `kw_<word>`, `die_surge`, `die_curse`, `die_glint` from `assets/visuals/pixel_fx/` (40x40, 8 frames, thin dithered masks). Hits on enemies use the `vfx` styles (`vfx_*.png`, 48x48).

## What the pilot shows
- **die_strike** (attack): hot core, eight spikes, a ring that thins to embers. Reads much bolder than today's dotted ring.
- **die_ward** (block): a hexagon that opens solid, goes hollow and breaks into three arcs.
- **die_bloom** (heal): a green orb, a cream core, three plus-sparkles rising and fading.
- **hit_slash** (basic attack hit, 48x48): a crescent that sweeps and thins away.
Colours are fixed in the pilot; the code can still tint by the `el_` strip or by the 4-step luminance ramp used for the skill strips.

## Strip or code, and the layering
| Effect | Proposal | Why |
|---|---|---|
| Basic hit | **strip** `hit_slash`, on the target at the hit frame | the code only shakes and flashes the target today |
| Heavy hit | **strip**: two crossed crescents, bigger, ember colour; code adds a longer shake | same drawing language |
| Crit | **strip**: gold starburst (the strike's burst, larger) over the hit, plus the existing `die_glint` | a crit should read from a distance |
| Attack face (strike) | **strip** (piloted) | |
| Block / guard face (ward) | **strip** (piloted); code keeps one thin outer pulse | |
| Heal face (bloom) | **strip** (piloted); code keeps the rising motes (they travel) | |
| Mana (arcs) | **strip**: two blue rings and four motes; code keeps the orbit | |
| Poison (miasma) | **keep the code bubbles** (they drift and pop); optional green strip under them | motion is the point |
| Stun (shock) | **strip**: yellow zigzags around a star; code keeps the jitter | |
| Weaken (drain) | **keep the code spiral**, add a small red down-chevron strip | |
| Blank / miss (fizzle) | **keep code** (shake and grey puffs); a 4-frame grey puff strip is optional | the shake is the feedback |
**Layering:** strip under the code burst (the burst keeps travelling motes and shake), same trigger, 8 frames at 90 ms (0.72 s, inside the 900 ms burst). Element tint and rule-word marks (`el_`, `kw_`) stay as they are and play above.

## Cost
Hand-drawn in code, all of it: **0 generations** for the 8 die strips + basic hit + heavy hit + crit (11 strips; 4 are done). PixelLab is not worth it for abstract 40 px effects (the skill pilot showed the same). If the user wants a more painted hit, 2 generations per style.

## Next
If the user likes the pilot: the other 7 strips (strike/ward/bloom/slash done), a sheet, then UX-2 wires them in `die_3d.dart` / `combat_vfx.dart`.
