# UX: where the work stands

For the manager (read here because UX has no `send_message`). #212 (1.282) is merged.

## PR 1: [#217](https://github.com/warning18/NarrativeApp/pull/217), v1.286.0+322 (the version the manager gave): material icons and chips only

Nine pixel icons for the building materials (`tool/gen_material_icons.py` writes `assets/icons/items/material_*.png`; the borrow list in `ItemIcons` is gone, the boss trophy keeps its own), and the material chips on the camp's build cards (the cost beside gold as each material's icon and count: `2` held, `1/2` in red when short; the status tag says "need materials"). It reads Core's `materialCost` and `missingMaterials`. Touches only `camp_town_section.dart` (UX's), `item_icons.dart`, one new string key (`town_materials`, EN + FR). Tests: `camp_town_section_test.dart`.

## PR 2: v1.288.0+324, after Core's 1.287 is on main (saved on the branch's history, tag `ux-prep` locally)

The skill choice sheet (C, board 9 approved) on Core's `faceSkillChoice`; places heard of on the full map (H: "?" marks, Set out by their expedition, Mark as goal; Narrative owes the reason lines); the land crossing in the desert side view on a shared side-view engine (`lib/widgets/side_view/`, with a sea kit not yet wired); the building screen (G, board 10) if the user's three questions are answered. Notes for each are in the branch history's `docs/proposals/ux-next-pr.md`.

## Questions for the user: the building screen (board 10, https://claude.ai/artifact/HvLA3w9MU1hh1NtDKgSK8R)

The board draws the camp's Town tab as four sections (the Sea, the Company, the Workshops, the Great Works) with one card per house, state tags (Ready, Missing, Built, a locked silhouette), the material chips, and a sheet on a missing card that says what is missing and where it comes from. Nothing is built until these are answered:

1. **Locked houses:** show them as dashed silhouettes with one reason ("Chapter 5", "When Kelda joins"), as on the board, or hide them until they come? (Silhouettes promise what is ahead; hiding keeps the surprise and a shorter list.)
2. **Finished sections:** fold a section once all its houses are built (the Company in the board's example), so the screen stays short as the camp grows? Or always show every house?
3. **Where a missing thing comes from, on the sheet:** plain text (the expeditions and shops by name), or links (an expedition name opens the camp's expedition list, a shop name opens its page)? Links are more work and more to keep right when a zone or shop changes.

My recommendation: silhouettes, fold finished sections, plain text first (links later if wanted).
