# Apollo 46-colour palette sample (0 generations, nothing staged, no assets/ change)
Sheet `docs/art/boards/skills-apollo-palette-sample.png`; script `tool/apollo_remap.py` (nearest colour by redmean distance, hard pixels, alpha kept; dithering available as `remap(img, dither=True)` but not needed: no banding).
Effects (key frame of fire, frost, poison, holy/radiance, shadow, steel hit) and 12 skill icons (3 common, 2 uncommon, 3 rare, 2 epic, 2 legendary), today above, remapped below.
- Gains: one consistent, harmonious set of colours across effects, icons and (if adopted) the rest of the art; clean dark ink (#090A14) and a good grey/blue-grey ramp for steel and frost; reds and purples stay separate (A53030/CF573C vs 7A367B/A23E8C); poison and nature greens read well.
- Loses: no saturated bright yellow (the brightest is E8C170, a muted gold), so holy and fire cores go cream/white-grey (EBEDE9) and fire's yellow-white heart flattens; legendary gold is a little duller but still reads as gold next to the grey epic frames; the strongest orange (DA863E) is paler than today's flame orange.

## Palettes compare (second palette, "muted palette", 39 colours; 0 generations)
Sheet `docs/art/boards/skills-palettes-compare.png` (today / Apollo / muted for the same 6 effects and 12 icons, each strip above, plus a "muted + 3 accents" row: F2C14E hot yellow, FFF6E0 near white, A987EA violet). `python3 tool/apollo_remap.py` builds it (`first` builds the Apollo-only sheet); `remap(img, pal='apollo'|'muted'|'muted+accents')`.
What I see, muted palette:
- Loses: no purple or pink, so void and the epic frames turn brown-grey (the void effect becomes a brown cloud, epic void/ring icons lose their violet); no saturated red (fire is gold-brown and the steel hit's red turns brown); no bright yellow, so holy is a flat cream star and the legendary gold becomes olive-tan. Frost loses its blue-white punch (greys).
- Gains: a calm, dark, earthy set that sits very well next to the Tower's stone and old-iron frames and the muted backgrounds; greens turn a natural moss; steel and ink read well.
- Plus 3 accents: hot yellow and near white bring back the holy star, the flame heart and the legendary gold; the violet accent barely appears (today's violets are darker than A987EA, so nearest-colour still picks brown), so void stays brown unless the violet is a darker accent or chosen by rule.
