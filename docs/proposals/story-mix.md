# The story side, the mix with darker frames (UX-2, pictures only)

The user picked the mix (C's quiet type for reading, A's frames for weight, B's plates and gems for state) on one condition: "try to fit the colour palette for frames, they are too light." The mock is `test/ux_story_mix_test.dart` (UX_SHOTS=<folder>, UX_FRAMES=muted|deep|weighted); nothing in `lib/` changes.

Pictures, `docs/ux-shots/story-mix/`:
- `overview-dark.png`, `overview-light.png`: the six screens (scene, NPC, chapter title, quests, character, clans) with three frame strengths, one row each.
- `<strength>-<screen>-<dark|light>.png`: every screen alone, 360 x 780.
- `frames-dark.png`, `frames-light.png`: the five tiers as Art made them (top), muted (middle) and deep (bottom).

## Weight decides the frame
- **Ordinary** panels have none: the reading screens (scene, NPC, chapter) are the page; the state screens (quests, character, clans) are pixel plates (the fight blocks' nameplate, no metal). The scene band, the portraits and the chapter picture get the quiet frame (the common one, deep).
- **Weight** gets the rich metal: a choice that touches a clan (bronze), a reward or an item by its rarity (bronze, silver with the blue gem, gilded, gold), nothing else.
- The clans screen is new in this set: a plate per clan (its colour, emblem, banner and backdrop, its motto, standing and the week's change). The backdrops are Art's; they are low contrast on purpose, so the picture stays a quiet strip.

## The frames: a darker re-tone of Art's pieces (0 generations)
Art's frames read pale because their light tones are the top of the ramps: iron 577277 with 819796 and EBEDE9 highlights, silver C7CFCC and EBEDE9, bronze DA863E, gold E8C170 and FFF6E0. A remap inside the Apollo palette (docs/art/palette-apollo.md) steps each light tone down its ramp and leaves the shadows; it is a colour-to-colour swap, with no generation and no new shape. I made the two strengths with `docs/ux-shots/story-mix/remap_frames.py` (the tables are in it; output `frames/muted` and `frames/deep`, PNG8, 104 x 172 like the originals):

| piece | original | muted (one step) | deep (two steps) |
|---|---|---|---|
| frame_common (iron) | 577277 394A50, highlights EBEDE9 A8B5B2 | 394A50 202E37, highlights 577277 | 202E37 151D28, highlights 394A50 |
| frame_uncommon (bronze) | 884B2B DA863E 602C2C, spark FFF6E0 | 884B2B BE772B 4D2B32, spark DE9E41 | 602C2C 884B2B 411D31, spark BE772B |
| frame_rare (silver, blue gem) | 819796 C7CFCC 394A50, glints EBEDE9, gem 73BED3 | 577277 819796 394A50, glints A8B5B2, gem 4F8FBA | 394A50 577277 202E37, glints 819796, gem 3C5E8B |
| frame_epic (gilded, purple gems) | DE9E41 E8C170 884B2B, glints EBEDE9 | BE772B DE9E41 602C2C, glints C7CFCC | 884B2B BE772B 602C2C, glints 819796 |
| frame_legendary (gold, sun crown) | E8C170 BE772B FFF6E0 EBEDE9 | DE9E41 884B2B E8C170 DE9E41 | BE772B 884B2B DE9E41 BE772B |

**My pick, "weighted"**: `deep` for the common frame (so a quiet frame almost vanishes into the page) and `muted` for the other four (so the rich metals keep their colour but lose the pale edges). In the overview it is the bottom row. The panels, plates and gems are code (PixelChipBorder) and stay as they are.

**What I would ask Art for**: the five frames re-toned that way, as `frame_<tier>_dim.png` (deep for common, muted for the others) beside the originals in `art/pixellab-cards/final/`, PNG8, same size; the 5 plates and 5 backdrops of the cards are not touched. The remap script is a starting point (Art can hand-tune the gem and the crown); no generation needed. The offer cards of v1.975 keep the pale originals unless the user asks otherwise (a card in a hand is rare and meant to shine).

## Build plan (5 PRs, as agreed)
1. **The kit** (v1.977.0): `lib/widgets/story_panel.dart`: the 9-slice frame (`Framed`: an image-nine painter, the corners kept at 2 dp an art pixel times a band scale, the middle empty), `Plate` (the nameplate over a pixel-cornered panel) and `Gem`, sharing its pieces with `fight_block.dart`; the dimmed frames in `assets/visuals/cards/` once Art delivers (until then the kit uses the originals through a colour filter, no filter in the final). A test for the nine-slice sizes, one for the plate and gem, and a widget gallery picture. No screen changes.
2. **The reading screens** (scene and choices, NPC, chapter title): `lib/screens/story_player_screen.dart`*, `story_player/story_choice_widgets.dart`*, `lib/widgets/story_text.dart`, `npc_detail_screen.dart`*, `home_shell.dart`* (the title).
3. **Quests and journal**: `journal_screen.dart`*, `quest_tracker.dart`, `quest_turn_in.dart`.
4. **Character and inventory**: `character_screen.dart`*, `inventory_screen.dart`*.
5. **Clans**: `clans_politics_screen.dart`*.
(* = shared files: check for open PRs and keep to few lines in each.) Each PR is a change of look only; no rule, number or text changes.

## Needs from Core and Narrative (Manager is asking)
- A choice's clan and weight, read from its existing standing and alignment effects, else a `clan` field per choice.
- A quest's clan: a `clan` field on a quest.
