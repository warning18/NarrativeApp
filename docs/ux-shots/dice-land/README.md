# The dice land on the floor (v2.10.16)

Replaces today's throw wherever the dice board rolls (the Tower and the story fights, one
die or several). Each die falls from above the board on a short arc with a shadow on the
floor that grows and sharpens, touches the floor with a puff of dust or snow, bounces once
or twice (about 26 px, then 7 px), tumbles a face or two, rocks and settles flat on its face
with a contact shadow. 880 ms in all (the dice speed setting scales it), several dice start
55 ms apart and land in a scatter on their own seats, never on top of one another.
No dark disc and no black ellipse.

Reduced motion (`*-reduced`): a drop of about 200 ms and a settle, no bounce, no dust, the die
does not tumble. (The roll's controller used to run 20 times faster by itself with reduced
motion, so the die was already at rest; it now keeps the 200 ms.)

Files: `strip-d6-normal.png` / `strip-d6-reduced.png` (a single d6 on the real Tower board at
412, the time on each frame), `strip-3dice-normal.png` / `strip-3dice-reduced.png` (three dice
on the same floor, with the same plan, shadow, dust and dice: the Tower has one die, so they
are laid out in a test), `d6-*.gif`, `3dice-*.gif`.
