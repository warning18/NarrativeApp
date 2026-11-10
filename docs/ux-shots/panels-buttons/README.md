# Panels A and buttons C (v1.901 candidate): first real screens

Painted in code from the Art pack's spec (`art/pixellab-pilots/final/panels/spec.json`), no antialiasing, corner tokens kept (button 4 dp, card 4 dp, InkPanel 10 dp), sizes and text unchanged.
- `real-screens-en412.png`, `real-screens-fr360.png`: before (1.899) over after, five real screens (the fight's Reroll/Confirm, the hub's cards, a street scene, Skills, Character).
- `zoom-before-after-en412.png`: crops, before | after, of the buttons, the fight buttons, and the Skills cards.
- `tower-after-en412.png`: the Tower in the night theme with the A panels and C buttons (menu, start, floor, boss, oath, spoils).
What changes: every FilledButton, ElevatedButton and OutlinedButton gets the C frame (a 2 dp dark outline, a light edge top-left, a shade bottom-right; swapped pressed, flat disabled); every Card and InkPanel gets the A frame (an outer ink line, an inner seam line 6 dp inside, a stitch in each corner; gold inside when lit). Panels that are plain Containers (the menu's list tiles, some cards) are unchanged for now.
