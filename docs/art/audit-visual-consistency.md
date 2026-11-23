# Visual consistency audit of the bundled art (Art, 23 November 2026)

Scope: `assets/visuals/` and `assets/icons/` as bundled (965 PNGs, 1.8 MB on disk: 1738 KB visuals, 80 KB icons, none over 21 KB), not the raw exports. 0 generations. Method: `art/pixellab-audit/audit.py` measures every file (size, bytes, colours, share of pixels exactly in Apollo or in the muted set, integer upscale, outline share, light); data in `art/pixellab-audit/audit.json`. Boards: `docs/art/boards/audit-heads.png`. Three passes below, then tests, then ranked proposals.

## Pass 1 to 3, what survives
**Pass 1 (find), pass 2 (verify against the pictures), pass 3 (seams).**

1. **Heads that are not faces (verified on `audit-heads.png`).** About 18 of the 80 `assets/visuals/heads/*.png` show only a hat, a hood or a blob: `cultist_acolyte`, `dock_overseer`, `frost_kept_giant`, `hollow_reflection`, `horn_taker`, `inquisition_auxiliary`, `inquisition_soldier`, `inquisition_warden`, `iron_golem`, `smuggler_captain`, `slum_thug`, `street_bandit`, `strand_colossus`, `void_wisp`, `void_stalker`, `void_sovereign`, `void_manifestation`, `hollow_court_zealot`. They are crops of the low top-down fighter sprites, which show the top of the head. A head avatar of a hat is the most visible flaw of the set.
2. **Missing art, by cross-reference of the data to the files.**
   - 14 of 78 enemies have no icon in `assets/icons/enemies`: `brine_jack`, `purifier_vell`, `knell_keeper`, `rime_bailiff`, `glass_shepherd`, `claimant_morrow`, `claimant_tallis`, `tear_herald`, `den_bouncer`, `den_looter`, `sore_loser`, `wreck_scavenger`, `aurel_vane`, `brother_clement` (only 11 of 78 have a fighter sprite, 65 a head).
   - 5 of 162 skills have no icon: `hex_of_ill_luck`, `edict_of_silence`, `rotting_mark`, `glass_reflection`, `shroud_reflection`; 2 of 134 items: `boss_trophy`, `fate_coin` (the code-drawn pixel icons may cover some: not checked against `lib/utils/pixel_icons`).
   - 64 of 80 NPCs (`npcs.json`) have no portrait in `heads` (only 16 match by id); which of them speak on screen is for Narrative to rank.
3. **Mixed pixel scales (measured).** Heads: 46 are 2x upscaled, 3 are 4x, 31 are native (16 px to 32 px wide), so one avatar strip mixes chunky 2 dp and fine 1 dp pixels. `pixel_fx`: 37 of 70 files are 2x. Fighter sprites 48 px (14), 60 px (5), 64 px (7). Companions 64 (56 files), 88 (40), 92 (8). The hero sprite 42x47 (walker) against 48x48 (heroes) and 136 px for the ink test. Icons are consistently 16 px (skills' gems 32). Dice exist at 40 and 44 px; the game loads only the 40 (`inventory_parts.dart:650`), so the five `die_*_bone_44.png` are unused.
4. **Palettes (share of pixels exactly in Apollo).** Skills 100 %, banners 100 %. `pixel_fx`: 31 of 70 files at 100 %, 39 under 90 %: `die_*` (10), `el_*` (8), `vfx_*` (8), `kw_*` (6), `chest_*` (4), `campfire`, `moment_seal`, `throne_flame` (0 % in each): these effects were not remapped when the user chose Apollo for skill effects. Items (131), enemy icons (64), shops (14), chests (10): about 0 % Apollo and about 0 % in the muted set, so they use a third palette of their own. The world plates and portraits are in neither set (the muted palette is the target by the user's rule, not a measured fact). The 7 clan backdrops are intentionally not Apollo.
5. **Outlines.** Every icon and sprite has a dark outline (median 100 % of edge pixels dark). The exceptions are by design: the 16 px glyphs, `professions` (5) and `races` (5) badges, and two enemy icons (`frost_kept_giant`, `strand_colossus`) which have none. Cards and effects are lineless.
6. **Light direction (checked, nothing reliable found).** An automatic test flagged 82 icons lit from the bottom right; I viewed 40 of them: they are white angels, dark-topped shields and books, so they are false positives. I make no finding on light direction except that the 40 viewed icons look lit from the top left.
7. **Sizes and bytes.** Fine: 922 PNG8, 43 RGBA (41 are item icons, none over 3 KB); no oversized file; dimensions match the sizes in the READMEs.
8. **Seams (pass 3).** The art is in UX's folders, the lists of missing ids in Core's data and Narrative's, and the head crops are made by a tool (`tool/gen_fight_heads.py`, UX's): every fix is a hand-over through the Manager. Code-drawn pixel icons (`lib/utils/pixel_icons`) are not in this audit.

## Tests (three runs)
Flutter is not installed in the Art session, so the Dart asset tests were not run. I ported the two asset guards to Python (`art/pixellab-audit/asset_checks.py`: `qa_assets_declared_test`'s folder declaration and the source-only list, `icon_sizes_test`'s 32 px limit over 387 icons): three runs, 0.027 s, 0.023 s, 0.020 s, the same PASS each time (no flaky test).

## Ranked proposals (impact x cost)
1. **Real faces for the hat-only heads** (about 18). Needs pictures first, M: remake the avatars at the same scale as the others, from the fighters' west frames or a PixelLab portrait; 1 to 2 generations each, 18 to 36 in all. UX owns the crop tool.
2. **Icons for the missing figures** (14 enemies, 5 skills, 2 items = 21). Quick win once the palette is decided, S: 16 px icons, 2 seeds each = 42 generations (skills in Apollo; enemies and items in whichever palette the user picks).
3. **Apollo remap of the 39 off-palette `pixel_fx` files.** Needs pictures first, S, 0 generations: a nearest-colour remap, shown before and after in one sheet.
4. **One palette for items, enemies, shops and chests** (about 250 icons). Needs the user's choice (Apollo or keep), S to M, 0 generations by remap.
5. **A scale table** (heads 1x or 2x, fighters 48, companions 64 or 88, one hero size). Needs the user's choice, M, 0 generations to unify heads and effects by resampling at 1x.
6. **NPC portraits for the story's speakers** (up to 64 without one). Needs the user's choice and Narrative's ranking, L: the top 20 would be 40 generations.
7. **Delete the five unused 44 px dice** (Cleanup's, quick win, S).

Cost per wave of generations: A (1 + 3 + 4 + 5 + 7) 0 to 36; B (2) 42; C (6, top 20) 40.
