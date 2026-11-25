# Snow on the interface, reworked (picture only)

On the real Tower fight at 412 wide, an 18 s run (a frame every 100 ms; the GIFs play it
in real time). Nothing in the game uses it yet: `ink_snowfall.dart` is a proposal, every
frame a pure function of the time on screen, one painter, 70 flakes at most.

- **Fall**: flakes of three sizes (1, 2, 3 px), a slow sway of 5 to 14 px with a period of 3
  to 6 s, a slight wind to the right; most fall past the panels.
- **Accumulate**: along the top edge of each panel and button a drift builds: smooth
  mounds, thick in the middle and thin at the corners, a 1 px rim highlight and a grey foot,
  no saw-tooth dents; it grows quickly at first and then slows towards its cap (8 px, only
  above the edge, never over text, icons or HP bars).
- **Shed**: when a drift reaches its cap, a chunk (a quarter to two fifths of the edge) breaks
  off at a random place, slides off the edge and falls, with a small puff of flakes where it
  lands; that stretch of the edge then builds again from nothing while the rest keeps its snow.
  The cycles are 7 to 13 s and differ per edge, so edges never pulse together.
- **Light variant** (`snow-light.gif`): 28 flakes, a cap of 5.5 px, cycles 40% longer.
- **Reduced motion** (`snow-reduced-motion.png`): a static light dusting, no flakes, no shedding.
- Not drawn: a tap or a hit-shake on a panel knocks its snow off (the shed with the chunk
  taken from the tap's place).

Files: `snow-normal.gif`, `snow-light.gif`, `snow-strip-normal.png` (8 frames, 0 to 17.5 s),
`snow-closeup-roll-button.png` and `snow-closeup-foe-panel.png` (the same edge every 1.2 s:
the build-up, a shed and the new build-up).

How it differs from today's: today each piece wears its own cap, a cut-out shape that builds
over 30 s and is static, with dents; this is a field: one painter, drifts that shed in chunks,
falling flakes. The edges in the pictures are read from the real screen (the two panels, the
Roll button, the potion button and the tiles at the top).
