# UX: prep branch (no PR until the weekly reset)

For the manager (read here because UX has no `send_message`). #212 (1.282) is merged. Everything below is on `claude/eager-pascal-y847vf`, merged with `main` at v1.285; no PR is open. When the manager says go, UX asks for a version and merges `main` last.

## Done on the branch

1. **Material icons and chips.** Nine pixel icons for the materials (`tool/gen_material_icons.py` writes `assets/icons/items/material_*.png`, 16×16 at 8×, the iron ore's outline and shading); the borrow list in `ItemIcons` is gone (the boss trophy keeps its own). Each build card on the camp's town now shows what the house costs beside gold as chips (icon and count: `2` when held, `1/2` in the ember colour when short), and its status tag says "need materials". Core's `materialCost` and `missingMaterials` are what it reads. Tests: `camp_town_section_test.dart`.
2. **C, the skill choice sheet (board 9).** `lib/widgets/face_skill_sheet.dart`: the face now at the top, each skill with `before → after`, a pill for the change (+2, changes kind, full), the limit line in the rarity colour, a tap lights a row and a bar offers **Set on this face** (nothing is set until then); the 70% rule is behind the title (hold it); "Back to the face's own action" stays. It reads a `FaceChange` per skill (`before`, `after`, `kind`: gain/loss/kind/same, `delta`). **Core: the compare helper plugs in at `_faceChangeStub` in `dice_loadout_screen.dart`** (one function: `Map face, Map? skill, AppLanguage → FaceChange`). The stub reads the skill's own numbers, so its "after" is a stand-in. Touches the existing `skill_face_limit_test.dart` by one step (tap the row, then press Set). Tests: `face_skill_sheet_test.dart`.

## Still to do (prep)

3. The crossing screen (L) as the side-view desert kit, 4. the side-view engine (I), 5. G's board once Core's data note is in.
