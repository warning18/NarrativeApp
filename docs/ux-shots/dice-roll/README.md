# The dice thrown and rolling (v2.10.20)

User feedback on v2.10.16: the dice dropped on their face too fast. They are now thrown and roll, 1.7 s at normal speed (the speed setting still scales it): each die turns over its edges two full turns or more, fast at first and slowing over the last turn, then a final rock and rest. Shadow on the floor and a puff at each contact are kept. Reduce motion stays a short drop and settle.

A single d6 on the real Tower fight board at 412 wide, one GIF and one strip (a frame every 150 ms, with its time) per throw:

1. `roll-1-from-left`: from the left, a low throw, rolling right.
2. `roll-2-from-right`: from the right, a low throw, rolling left.
3. `roll-3-drop-and-roll`: dropped from above with a bounce, then rolling a full turn sideways.
4. `roll-4-diagonal`: from the bottom-left corner, tossed away, bouncing up the board.
5. `roll-5-wall-bounce`: a hard throw that hits the side edge, bounces back and rolls.

`roll-3-dice-mixed`: three dice thrown together, each in a different way (left, drop, edge). The game picks the ways at random each roll, the dice of one throw always different.

Made by `test/ux_dice_roll_shots_test.dart` with `UX_SHOTS=<dir>`.
