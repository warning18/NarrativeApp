# Design proposal: chests

Board: `boards/chests.png`. Pilots: wooden, gold closed and open (3 images).

## Shared rules
- Five tiers, one material hue each: wooden `#6E4A28 #4E2E18`, iron `#52565C #3C3F44`, silver `#7B7F86 #D0D4DC`, gold `#E0B030 #9A6A3C`, void `#6A3AA0 #2A1E3A #1A1226`. Dark outline `#0A0807`, 1 px. Light from the top-left.
- Each tier has a **closed** and an **open** image on the same canvas, same camera (front, slightly raised), so the swap does not jump.
- Open state shows the inside glow in the tier's accent; the burst effect stays in `pixel_fx` (code).

## Options (board A, B, C)
A 16x16 (today, same wiring); **B 32x32**; C 48x48.

## Recommendation
**B, 32x32**: at 16 px a generator adds nothing. At 32 px we get plank lines, a lock and a rim light, and UX-2 only changes the frame size where it draws the icon (it draws at the same on-screen size). Cost: object tool about 5 per image; 3 pilot images about 15.
