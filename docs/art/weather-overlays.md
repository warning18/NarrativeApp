# Weather overlays for the UI (24 November, pictures only, nothing wired)

For the user's "weather on the UI" request: snow, sand and ash that sit on the top edge of a button or a panel. `art/pixellab-weather/final/`, transparent PNG8, 1 px = 1 dp. Each pile's bottom row is flat: put the file's bottom edge on the element's top edge (overlap by about 1 px).

| Piece | Files | Widths (px) | Heights (px) | Palette |
|---|---|---|---|---|
| Snow, 4 stages | `snow_{dusting,light,medium,heavy}_{340,300,90}.png` | 340 (a panel, about 340), 300 (a wide button), 90 (a small button) | 30, 30, 32, 32 (340 px version; the narrower ones are shorter at the ends) | paper white EBEDE9, cold greys C7CFCC A8B5B2 |
| Sand and dust, 4 stages | `sand_{dusting,light,medium,heavy}_{340,300,90}.png` | same | 30, 30, 27, 20 (340 px version) | ochre and warm grey from Apollo: 884B2B AD7757 C09473 D7B594 E7D5B3, greys 819796 577277; no gold |
| Ash and soot, 2 stages | `ash_{dusting,heavy}_{340,300,90}.png` | same | 8 and 16 | dark greys 151D28 to 577277 |
| Frost corners, 2 | `frost_corner_a.png`, `frost_corner_b.png` | 48 x 48 | | top-left corner; mirror it for the other corners |
Sheet: `docs/art/boards/weather-overlays-1x.png` and `-2x.png` (each stage on a dark panel strip at 340 and 90 wide, the frost corners on a panel corner).

## How and cost: 24 generations
- Snow and sand: PixelLab master drifts at 340 px (`create_image_pixen`, transparent, `gen.py`), 4 stages x 2 seeds each (16 in all). The model drew a dark ground under each pile, so `build.py` keeps only the snow (light pixels) or the sand (warm pixels), seats the pile on a flat base, and cuts the 300 and 90 px widths from the middle of the master with the ends tapered by hand, so each pile is thick in the middle and thin at the ends. Seed 1 is used (`pick.json` can change that); sand was snapped to the ochre palette above.
- Ash and the frost corners: 4 + 4 generations were spent on PixelLab tries, and they did not work (the ash read as dark rubble; the frost corners came out as blobs and a worm). The ash dusting and the frost corners in `final/` are therefore **drawn in code** (`code_pieces.py`), not by PixelLab.

## Honest notes
- The snow dusting and light stages read as thin ridges, with sharper peaks than the "soft drift" asked for; medium and heavy are softer and wavier. The sand heavy stage is low (the extraction removed most of its dark body). A second round of tries at these would be about 8 generations.
- The 300 and 90 px widths are crops of the one master, so the shape repeats across the widths of a stage.
- Loose flakes are in the snow masters only.
