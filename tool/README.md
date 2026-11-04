# tool/ and tools/

Python scripts that make or check the game's data. Run from the repository
root. The art generators need Pillow (`python3 -m venv .venv && .venv/bin/pip
install pillow`); nothing in the app reads a script.

## Art generators (write into `assets/`)

Each one was run into a clean checkout (Pillow 13.0.0, Python 3) and wrote the
**same bytes as the files in the repository** (before `png8.py`: see below) (no file changed, none added), so
the checked-in pictures are what the script makes. Run one again only if you
change its recipe, and commit the pictures with it.

| Script | Writes | Notes |
|---|---|---|
| `tool/gen_banners.py [sheet.png]` | `assets/visuals/banners/` (20) | the Shroud's pieces, the title standard, the clans' banners; an optional contact sheet |
| `tool/gen_chapter_art.py` | `assets/visuals/chapters/chapter_1..8.png` | the quest-complete card's strips |
| `tool/gen_fight_fx.py` | `assets/visuals/pixel_fx/vfx_*.png` (36) | skill and spell effect strips, recoloured to the element at run time |
| `tool/gen_pixel_fx.py` | `assets/visuals/pixel_fx/die_*`, `el_*`, `kw_*`, `moment_*`, `campfire`, `chest_*` | the small animations; same folder as the one above, different files |
| `tool/gen_throne_room.py` | `assets/visuals/throne/`, `pixel_fx/throne_flame.png` | the Lantern Throne room |
| `tool/gen_skill_icons.py [outdir]` | `assets/icons/skills/` (the 20 skills added in 1.245) | |
| `tools/gen_skill_card_icons.py` | `assets/icons/skills/` (the 40 clan-card icons) | reads `assets/gamedata/skills.json`; same folder as `gen_skill_icons.py` |
| `tool/gen_hunter_icons.py` | `assets/icons/enemies/` (rival hunters, nemesis champions) | |
| `tool/gen_material_icons.py [outdir]` | `assets/icons/items/material_*.png` | the nine building materials |
| `tool/gen_fight_heads.py` | `assets/visuals/heads/` (67) | crops of the sprites in `assets/icons/enemies`, `assets/visuals/walker` and the dog's `Fight_-_Attack` frames (read, not shipped) |

`assets/visuals/sea_beasts/` and the companion, ship, city and fighter art
have no script here: the pictures themselves are the source.

## Storing the pictures (after any generator)

`python3 tool/png8.py` stores every picture under `assets/` that fits 256 colours
as an 8-bit palette PNG, with nothing lost: a rewrite is kept only if it reads
back as the same RGBA pixels and is smaller. The generators above save RGBA, so
run it after one: `python3 tool/gen_banners.py && python3 tool/png8.py && git
status assets` shows no change when the recipe did not. `--dry-run` says what it
would do; `--check` lists the pictures that should be palette PNGs and are not
(exit 1), for a guard. A picture with more than 256 colours is left alone.

## Checks (read the repository, write nothing)

`qa_unused.py` (declarations nothing uses), `qa_unused_assets.py`,
`qa_unused_fields.py`, `qa_unused_strings.py`, `qa_duplicates.py`,
`qa_size.py`, `qa_xref_audit.py`, `qa_new_tables_audit.py`, `qa_dart_scan.py`:
the QA session's audits; `docs/qa/` says what each reports.

## Other

`shard_tests.py`, `shard_weights_from_report.py`: how CI splits the test files
over its four runners. `clan_power_report.py`: the clans' power table.
`city_plans/`, `fmg_chart/`: inputs and generated tables for the city plans
and the world chart.
