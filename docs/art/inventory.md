# Art inventory: what the app shows, how it is made, what PixelLab would cost

Audit by the Art session, 2026-11-10, v1.889 tree. No generation done for it.
PixelLab balance at the audit: **1,331.5 generations** left of 2,000 (refills 2026-11-16, Tier 1).
The user's library: 129 characters in about 25 groups (Hero 26 states + 1, peasant/Mimi/woman groups, Orsolya Keld 9, bandit 6, oni 5+2, goblin shaman 5, scavenger 4, rat 3, noble bouncer 3, Sedge 2, Dices 2, a bear, a 128px ship, a few singles).

Rule of the user: the UX does not change; only the elements drawn inside screens get new art. Banners keep today's style.

## Prices (from PixelLab's help, free to read)

| Tool | Cost | Use |
|---|---|---|
| `create_image_pixen` | 1 per image, up to 512x512 | backgrounds, small icons, quick tries |
| `create_character` standard | 1 at any size (4 or 8 dir) | enemies, NPCs |
| `create_character` pro | 10 (to 85px) | when palette control is needed |
| `create_character_state` | 10 (to 70px) | a variant of a character the user owns |
| `animate_character` template | 1 per direction (about 64px, 8 frames) | idle or walk strips |
| `create_object_pro_flash` | about 5 per image | props, dice, chests |
| `create_1_direction_object` | 10 to 15 (gives 4 to 64 candidates) | icon sets in one go |
| `create_ui_asset` | 10 (up to 256x256) | panels, buttons |
| `create_image_pro` | 10 to 25 | rare hero pieces |
| `pixelart_workbench`, `reduce_colors` (0.1) | free or nearly | clean-up |

## Inventory

"Today" = how it is made now. Cost = a full PixelLab replacement, in generations, with about 1.5 tries per element.

| # | Kind | Today | Count | PixelLab cost | Recommendation |
|---|---|---|---|---|---|
| 1 | Fight backgrounds | Code painters: `fight_backdrop.dart` (783 lines, 5 sceneries), `fight_pixel_stage.dart` | 5 + tower floor | Tower: done (approved). Others about 10 each | **Keep code** for 5 (they react to time of day and weather); tower floor is PixelLab (UX-2 builds it) |
| 2 | World/biome backdrops | Code: `biome_backdrop.dart`, `side_view/*_kit.dart` (6 kits), `street_view/`, `cliff_town_view.dart`, `scene_stage.dart` | 11 biomes | about 100 | **Keep code**: parametric by hour and weather; at most a PixelLab far-hills strip per biome later |
| 3 | Chapter strips | PNG from `tool/gen_chapter_art.py`, 160x56 | 8 | about 15 | **Improve** (pilot candidate): one-off cards, no parametric need |
| 4 | Enemy fight sprites | PNG 48/60px in `assets/visuals/fighters` | 8 of 78 enemies | 78 enemies: 1 (standard) + 8 (idle strip) is about 12 each, so about 900 for all | **Replace, by priority**: bosses and the most met first; wired by the table in `fight_sprites.dart` |
| 5 | Enemy portrait heads | PNG from `tool/gen_fight_heads.py` | 65 heads, 67 files | 0 if cropped from the fight sprites | **Keep**; crop from new sprites later |
| 6 | Enemy list icons | 16x16 PNG, `assets/icons/enemies` | 64 | 1 (pixen) each, about 100 | **Keep** (low value) |
| 7 | NPCs (portraits) | Few PNG; mostly code figures in `scene_stage.dart` | about 80 | 1 standard + clean-up about 3 each, about 250 | **Replace in waves**: key story NPCs first (staged: Orsolya, Lantern-Bearer, Ash Confessor, Sedge) |
| 8 | Companions | Dog strip (107 files); 8 other companions have no art | 9 | about 12 each, about 110 | **Replace** the 8; keep the dog |
| 9 | Heroes by race and profession | One ronin for everyone (`walker/`); race/profession cards 128x128 | 5 races x 5 professions | Staged: Hero group (27 states). Pick 5 + 5 about 100 | **Improve**: choose from the staged states |
| 10 | Dice (cube art) | Code: `die_art.dart` (549 lines), `die_skins.dart`, `die_3d.dart`, `poly_die.dart` | 36 dice, 17 patterns | 5 per die, about 180 | **Keep the painter**: faces show numbers and roll in 3D; PixelLab can't draw them. Pilot one skin to compare only |
| 11 | Buttons and panels | Code: `ink_panel.dart`, `ink_chip.dart`, `sheet_kit.dart`, `ink_sheet.dart` | about 6 families | 10 per panel, with states about 15; about 80 | **Improve**, but only as a 9-slice frame behind the same layouts; pilot panel + button |
| 12 | Banners / standards | PNG 64x128 from `tool/gen_banners.py`; `pixel_banner.dart` | 20 | about 5 each if edited from today's image (edit_image) | **Improve, same style**: re-draw from the current file as reference |
| 13 | Skill icons | 16x16 PNG, `assets/icons/skills` | 157 | 1 (pixen) each or 4 per 10-credit sheet, about 250 | **Keep**; improve only the 20 most seen if the user asks |
| 14 | Item icons | 16x16 PNG, `assets/icons/items` | 132 (items.json: 150) | about 200 | **Keep**; pilot the weapon tiers (50 swords/spears etc. share one look) |
| 15 | Chests | 16x16 PNG, 10 files; `pixel_fx/chest_*.png` | 5 kinds, open/closed | 5 each, about 50 | **Improve** (cheap, visible): good pilot |
| 16 | Shop icons | 16x16 PNG, 14 | 14 | about 20 | **Keep** |
| 17 | Ships (cutaways, hulls, parts) | PNG cutaways 14 files; code hulls (`ship_hull_art.dart`); sea beasts 3 webp | 14 ships, 60 parts | ship 10 to 25 each, about 350 | **Keep code** for parts; **improve** the three sea beasts and enemy ships only on request |
| 18 | Throne room | PNG from `tool/gen_throne_room.py`, 6 pieces | 6 | about 30 | **Keep** |
| 19 | VFX | `pixel_fx` (69 files), `skill_vfx.dart` | n/a | n/a | **Out of scope** |
| 20 | Fonts, music, sounds | `assets/fonts`, narration | n/a | create_font, create_music, create_sound_effect exist | **Out of scope** for now |

APK weight: the whole `assets/visuals` + `assets/icons` is about 3 MB today. An idle-only 60px sprite is about 2 to 4 KB as 8-bit PNG; a walk strip about 10 times that. Sprites should be idle frames only, except heroes and companions.

## Where PixelLab is worth the generations

High value, low cost: enemy sprites for the bosses and the most common enemies (#4), the key NPCs (#7), companions (#8), heroes (#9), banners (#12), chests (#15), chapter strips (#3).
Low value or wrong tool: dice (#10, code is better), parametric backdrops (#1, #2), 16px icons (#6, #13, #14, #16).

## Proposed pilots (picture first, nothing generated yet)

Each is shown next to today's element in a PNG on this branch before any larger batch.

| Category | Pilot | Cost |
|---|---|---|
| Enemies | 2 bosses without art: `iron_golem`, `void_sovereign` (1 standard each, then idle, about 12) | about 25 |
| NPCs | 2: `lysa`, `renn` | about 8 |
| Companions | `kelda`, `sable` | about 25 |
| Heroes | choose from staged states for `warrior` and `mage` (0, already generated) | 0 |
| Banners | `clan_dominion`, `clan_oni` re-drawn from today's file, same style | about 10 |
| Chests | `gold` closed and open, `wooden` closed | about 15 |
| Buttons and panels | one panel and one button with states | 20 |
| Dice | one skin (`flame_die`), pixen faces beside the painter | about 5 |
| Chapter strip | chapters 1 and 4 | about 6 |
Total about 115 generations (under 10% of the balance); no single call is above 30. Needs the user's go.
