# Race & Profession and A Life Before This One, redone (pictures only)

The user: "Still not good, please update, and avoid squared images." Redone in the direction chosen since: old-iron frames (the material ladder: character creation is the very start, so **wood**), chibi dark medieval, the pixel chips, a readable disabled Start button, empty step slots. Real screens (412 dark `s-dark-412.png`, 412 light `s-light-412.png`, 360 `s-360.png`), driven by a throw-away prototype (`prototype.patch`, never merged; it needs the iron-frame prototype of `docs/ux-shots/iron-frames/` for `FrameBorder`).

## What changed, against the earlier mock-ups
1. **No square images.** Today the four peoples (dwarf, elf, orc, voidkin) are square plates; the callings are already free-standing objects and the human is a banner. The plates are gone: each people is a free-standing emblem like the callings, at 32 (compact) and 48 (card), with a one-pixel rim (dark, or cream for the orc's black antlers so it reads on the dark card). The emblems in `emblems-placeholder/` are **placeholders lifted off the old plates** (the glyph kept, the plate removed); Art is drawing the real non-square race emblems, which drop in under the same names (`assets/visuals/races/<id>.png`). No code change: `PresetMark` already draws whatever the file is.
2. **Cards wear the wood frame** (the 9-slice, tiled edges), the selected card is tinted gold; the cards' padding grows by the frame.
3. **The stat/trait pills are pixel-step chips** (the 1.908 shape), not round pills.
4. **The steps' empty slots are dashed** with stepped corners and a "?" (a place waiting, not a button); a filled step is a pixel-step chip with the emblem.
5. **The disabled Start button is readable**, and a line above it says what is missing: "Still to choose: a people and a calling" / "a people" / "a calling" (text is English here; French goes through `app_strings`).
6. **The life header:** the scene band runs full width, edge to edge, with a soft fade into the page, and no framed picture. On the light theme the age/memory labels were unreadable on the faded parchment (orange on light); they are now a dark brown and the page colour starts lower so the text sits on it.
7. Not in the pictures: the paint-by-hand life bands (Art PR #931) and the light that follows the age (item 5 of my earlier list).

## Files the build would touch
`lib/widgets/race_profession_cards.dart`, `lib/screens/race_profession_screen.dart` (one hint line), `lib/screens/origin_stories_screen.dart` (the header colours and fade), and the emblem files when Art's land. Core's data is untouched. Version slot: after the iron frames (the frames are what the cards wear).
