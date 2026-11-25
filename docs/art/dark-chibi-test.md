# Darker chibi test (user, 25 November 2026): "more Elden Ring like" mood

Mood only (grim dark fantasy: worn, weathered, ominous; muted desaturated tones, deep shadows, one strong rim or glow light), no copying of any game's designs. Darker palette `art/pixellab-icons-v2/palette_dark.py` (same hues, saturation x0.7, value x0.8, shadows x0.65, plus three near-black tones): swatches `docs/art/boards/chibi-palette-dark.png`. Prompt prefix in `wavedark_ids.py` (`M`), the palette forced.

## Test (12 generations; balance after: 1230 with 5b)
8 icons: 4 foes (inquisition_high_warden, plague_hound, bone_warden, void_hound), 2 shopfronts (weaponsmith_forge, apothecary_row), 2 chests (iron_closed, iron_open); 2 **stall elements** (stall_forge, stall_apothecary, 96 x 64, transparent) and their 2 list icons (32 px). Sheet `docs/art/boards/icons-dark-test.png`: current (top) | darker (bottom), and the stalls as composites (background, then an NPC, then the stall) on a Tower plate and on a street plate, with two different NPCs. Files `art/pixellab-icons-v2/final_wavedark/`.

## The shop as an element: what UX needs
- Stall: 96 x 64 PNG, transparent ground, drawn straight from the front: two posts and an awning on top, a counter across the bottom with wares and a trade sign. The space between the posts above the counter is **transparent** (made in code from the stall's near-black interior, `dark_test.py hollow()`), so the background and the NPC show through.
- Layer order: background -> shopkeeper NPC -> stall.
- Anchors (stall coordinates): the opening is about x 14..82, y 8..40; the counter top is at about y 40; put a 48 px NPC horizontally centred (x 48) with its feet at about y 52 (12 px under the counter top, hidden by the counter); the stall's bottom edge sits on the ground line of the plate.
- Sizes: stall 96 x 64 (scale 2x on a 180 px wide plate), NPC 48 x 48 as the characters are; the 32 px icon is separate, for lists.
- One stall per shop trade; the NPC and the background change freely.

## What I see
The darker foes, chests and shops read as moodier (muted, deep shadows, a cold or ember rim) and stay readable at 32 px, but they get murkier and less distinct from each other, and small details (a shop's sign) are harder to read. The stalls work as an element: the NPC stands behind the counter on both plates. They were made with the dark palette; the NPCs in the composite are the current (lighter) heroes.
