# UX: where the work stands

For the manager (read here because UX has no `send_message`). #212 (1.282) is merged.

## PR 1: [#217](https://github.com/warning18/NarrativeApp/pull/217), v1.286.0+322 (the version the manager gave): material icons and chips only

Nine pixel icons for the building materials (`tool/gen_material_icons.py` writes `assets/icons/items/material_*.png`; the borrow list in `ItemIcons` is gone, the boss trophy keeps its own), and the material chips on the camp's build cards (the cost beside gold as each material's icon and count: `2` held, `1/2` in red when short; the status tag says "need materials"). It reads Core's `materialCost` and `missingMaterials`. Touches only `camp_town_section.dart` (UX's), `item_icons.dart`, one new string key (`town_materials`, EN + FR). Tests: `camp_town_section_test.dart`.

## PR 2: v1.288.0+324, after Core's 1.287 is on main (saved on the branch's history, tag `ux-prep` locally)

The skill choice sheet (C, board 9 approved) on Core's `faceSkillChoice`; places heard of on the full map (H: "?" marks, Set out by their expedition, Mark as goal; Narrative owes the reason lines); the land crossing in the desert side view on a shared side-view engine (`lib/widgets/side_view/`, with a sea kit not yet wired); the building screen (G, board 10) if the user's three questions are answered. Notes for each are in the branch history's `docs/proposals/ux-next-pr.md`.
