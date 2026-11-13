# Tower three NPCs: exported frames (0 generations, nothing wired)
The user's order: the Tower three first. Exported from the account's PixelLab characters by the free download of each status (`/mcp/characters/<id>/download?states=<id>`, no cost; balance unchanged 849.5): 64x64 native, transparent, **PNG8 (31 colours + a transparent index)**, side view, all eight directions.
| NPC | status (inventory #) | default file (**east**, facing right toward the card text, as UX-2 asked; the front is `<name>_south.png`) | all directions |
|---|---|---|---|
| the Stair-Chandler | #36 "Fatter with bigger b": a stout bearded man in a brown cloak and a blue coat | `art/pixellab-npc-export/stair_chandler.png` (+ `stair_chandler_south.png`) | `art/pixellab-npc-export/stair_chandler/<direction>.png` |
| the Tally-Clerk | #37 "Older librarian": grey hair and beard, green vest, a stack of books | `art/pixellab-npc-export/tally_clerk.png` (+ `tally_clerk_south.png`) | `art/pixellab-npc-export/tally_clerk/<direction>.png` |
| the parley guardian | #47 "Another passant hat": an officer in a blue coat and cap with a crest | `art/pixellab-npc-export/parley_guardian.png` (+ `parley_guardian_south.png`) | `art/pixellab-npc-export/parley_guardian/<direction>.png` |
Directions: south, south-east, east, north-east, north, north-west, west, south-west (so a front card uses `south`, a three-quarter `south-east` or `south-west`, a side view `east` or `west`). Sheet: `docs/art/boards/npc-export-tower-three.png` (every direction at 2x). The raw ZIPs are in `art/pixellab-npc-export/raw/` (no animations exist for these three statuses).
Honest notes: they are 64x64, bigger than the 48x48 hero and the 42x47 side-view ronin: UX-2 chooses the scale on the cards; the shop and bargain plates have no figure, so the NPC stands in front of the plate.

**Which I would pick:** east for the layout UX-2 described (the figure beside the card text, facing right toward it); south reads richer (the book stack, the crest on the officer's coat and the faces are visible) if a card ever shows the figure centred. **A lit lantern or candle in the Stair-Chandler's hand** (Narrative's idea): by hand (0 generations): a small lit lantern drawn into the east and south frames; or PixelLab, a new state of #36 holding a lantern: 10 generations for all 8 directions (a 64x64 state costs 10), picture first.

## The Stair-Chandler's lantern (the user chose "drawn by hand", 0 generations)
`art/pixellab-npc-export/stair_chandler_lantern_south-west.png` (the frame UX-2 uses: three-quarter, facing left toward the card text), `..._west.png` and `..._south.png`: the same 64x64 canvas, PNG8, transparent index 31, feet still on the same row; a small lit lantern (iron frame, a warm cream and yellow glow from the Apollo yellows) drawn into the frame, held out on a forearm (south-west and west); drawn by `art/pixellab-npc-export/lantern_gen.py` from the raw rotations. Sheet: `docs/art/boards/npc-stair-chandler-lantern.png` (before and after, 2x and card size). **Honest reading:** south-west and west read as a man holding up a lit lantern at 2x; at the card size (64 px high) it is a nine-pixel glowing lantern at his side: it reads as a lit lantern, small; **south does not read** (the lantern floats beside the leg without a hand on it): do not use it. If the hand version is not enough, the PixelLab version is a new state of #36 holding a lantern: 10 generations for all 8 directions.

## The PixelLab lantern state (the user's choice; 10 generations; supersedes the hand-drawn one)
A new state "Stair-Chandler lantern" of #36 (id `b9c876a8-a200-44c3-a9c7-cc7a2d0d17ac`, `create_character_state`, edit "holding a small lit iron lantern in one hand, held out at his side at hip height ... the same man, same face, same beard, same clothes", `use_color_palette_from_reference`, seed 7). **Cost 10 generations on the first try** (balance 849.5 to 839.5). All 8 directions: `art/pixellab-npc-export/stair_chandler_lantern_<direction>.png` (south, south-east, east, north-east, north, north-west, west, south-west), 64x64 PNG8, transparent index 31, the figure on the same rows as before (rows 7 to 55). The man is unchanged (face, beard, clothes), the lantern hangs from one hand in every direction. By hand I only brightened the lantern's glass panes to the Apollo yellows (E8C170 and FFF6E0): PixelLab drew them peach and cream. The first hand-drawn files are kept as `stair_chandler_hand_lantern_{south-west,west,south}.png`. Sheet: `docs/art/boards/npc-stair-chandler-lantern-pixellab.png` (before and after, 8 directions at 2x, the south-west at 2x and at the card size next to the hand-drawn one). Raw: `art/pixellab-npc-export/lantern_state/`. Honest note: the lantern is small at the card size (about 7 pixels high, a lit speck at his side); the lantern in the south-west frame hangs at his left, away from the card text.

## Keepers and faces (the user: "yes to shopkeepers and faces for people"; free, 0 generations)
Exported by status, all 8 directions each, PNG8, 64x64, transparent index 31, **feet on row 55 in every frame** (a 48x48 hero status is centred on the 64x64 canvas and shifted so its feet stand on row 55 like the others; its native frames are in `native48/`). Folder per status in `art/pixellab-npc-export/<folder>/<direction>.png` (south, south-east, east, north-east, north, north-west, west, south-west); sheet `docs/art/boards/npc-export-keepers.png`; list in `keepers_export.json`. UX-2 copies east to `<npc id>.png` and south to `<npc id>_south.png`.
| # | folder | what |
|---|---|---|
| 20 | `20_paysant_woman_same_as_warlord_a_bi` | woman, feathered hat and green dress |
| 35 | `35_young_peasant_same_with_no_book_bu` | old grey-haired man, green vest |
| 42 | `42_young_peasant_change_clothes_for_h` | man in a dark brown cloak |
| 38 | `38_young_peasant_longer_bear_skinnier` | bearded man, blue and green vest |
| 50 | `50_paysant_woman_change_face_and_hair` | red-haired woman, green dress |
| 29 | `29_male_peasant_change_the_spear_for` | helmet and spear |
| 53 | `53_paysant_woman_idle` | brown-haired woman, green dress |
| 49 | `49_paysant_woman_same_style_but_other` | blonde, straw hat, blue skirt |
| 34 | `34_young_peasant_thinner_body_and_tal` | thin man, brown vest |
| 36 | `36_young_peasant_fatter_with_bigger_b` | the stout bearded man (the Stair-Chandler's body; the lantern state is separate) |
| 39 | `39_young_peasant_medieval_style_peasa` | ragged peasant |
| 2 | `02_hero_no_weapon_cheaper_eq` | dwarf with helm and shield (48x48 padded) |
| 6 | `06_hero_dwarf_warrior` | dwarf in heavy armour (48x48 padded) |
| 41 | `41_young_peasant_same_style_but_diffe` | bearded man, green vest (Hesk Morrow) |
Note: #29, #50, #53, #49, #20 are from the two groups drawn from slightly above ("spots only": standing facing the player, never walking): use south or the three-quarter frames.

## Male - Peasant enemies (the user and Narrative's check; free, 0 generations)
#23, #25, #30, #31, #32, #33, #18, all 8 directions, PNG8 64x64, transparent index 31, same folder scheme; UX-2 takes **west** for the fight sprite and **south** for portraits. Sheet `docs/art/boards/npc-export-male-peasant-enemies.png`. These come from a group drawn from slightly above ("spots only"): the west frame is the closest to a side view available. The feet stand on rows 55 to 56 (native frames, not shifted; a weapon tip reaches row 57 in #33's north-east and north-west).
| # | folder | what |
|---|---|---|
| 23 | `23_male_peasant_same_with_a_sword_an` | knight with sword, shield and a red cape |
| 25 | `25_male_peasant_same_with_a_cape` | helmet, cape and a pole-arm |
| 30 | `30_male_peasant_add_a_gambison_and_a` | gambison and an axe |
| 31 | `31_male_peasant_change_the_helmet_st` | helmet and a staff |
| 32 | `32_male_peasant_mercenary_style_with` | heavy hooded mercenary |
| 33 | `33_male_peasant_mercenary_same_style` | mercenary with a spear |
| 18 | `18_male_peasant_hunter_style` | hunter in furs |
