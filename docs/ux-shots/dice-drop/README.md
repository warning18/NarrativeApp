# A throw that lands on the ground (picture only)

The die comes in from above along a short arc, a shadow on the stone floor grows and
sharpens as it falls, it touches the floor with a puff of dust or snow, bounces once or
twice with decreasing height, tumbles a face or two, rocks and settles flat on its final
face with a contact shadow. The Tower fight has one die, so the 3-dice rolls are on the
same floor plate, with the same plan, shadow, dust and Die3D (a test harness).

Two versions, a frame every 40 ms (the GIFs play them):
- **dropped** (`*-drop`): fall 230 ms, first bounce about 26 px, second about 7 px,
  settled by 880 ms.
- **dropped, stronger bounce** (`*-dropStrong`): fall 210 ms, first bounce about 50 px,
  second about 12 px, a longer settle; still 880 ms in all.

Files: `strip-d6-*.png` (a single d6 on the real Tower fight board, 412 wide),
`strip-3dice-*.png` (three dice landing in a scatter, not stacking), and
`d6-*.gif`, `3dice-*.gif`.

Timing: total 880 ms (the controller's; the speed setting scales it as it does now).
Three dice start 55 ms apart. The faces stay readable when it stops: the turn ends
exactly on the picked face, front.

Reduce-motion (not drawn, planned): a short drop of about 200 ms and a settle, no
bounces and no dust; the instant roll stays for "still".

Code: `DiceThrowPlan.drop` (`dice_throw.dart`), `DiceGroundPainter` (`dice_ground.dart`),
the style switch `diceThrowStyle` (default `today`, the throw in the game is unchanged),
and three lines in the fight board and the roll's duration. The old black ellipse shadow
and the disc of v2.10.14 do not appear here.
