# "A merge is ready": where the hint shows (UX-2, pictures only)

The user approved surfacing the merges. Core's data (`lib/data/skill_craft.dart`: `craftRecipesFor(...)` gives each recipe with `ready`, `skillCraftOpen(builtHouseIds)` says whether the Skillwright stands) is enough; nothing in `lib/` changes here. The mock is `test/ux_merge_hint_mock_test.dart` (UX_SHOTS=<folder>), real data: the recipe Fireball + Shadow Step -> Blazing Shadow (skill_merges.json), skills.json and houses.json, the story kit's plate and frame (v1.978).

Pictures, `docs/ux-shots/merge-hint/` (360 wide, dark and light):
- **A, on the Skills screen**: `a-skills-built-*` and `a-skills-unbuilt-*`. A plate above the list: "A merge is ready", the two skills, an arrow, the result in its rarity's frame, one line ("Fireball and Shadow Step become Blazing Shadow. Both are spent."), and one button: "Craft at the Skillwright" when it stands, else the line "The Skillwright is not built yet: 350 gold, 3 timber and 2 slag glass at the camp." and "Go to the camp".
- **B, at the camp**: `b-camp-built-*` and `b-camp-unbuilt-*`. The Skillwright's house card turns teal with a "1 merge ready" mark, shows the recipe, and a button: "Craft it" or "Build it first · 350 gold". A dot on the Camp tab says there is something at the camp.

## My pick
**A, with B's dot.** The player thinks about a merge when they read their skills, so the plate belongs on the Skills screen; it shows only while a recipe is ready (the most ready one; "+2 more" when there are several) and it goes when the merge is done. The "not built" variant is the same plate with the cost and a way to the camp. B is the camp's own view of the same news; it is useful when they are already there, and the Camp tab's dot (the camp's badge, `tabBadgesProvider.camp`, already shows a house the player can afford) can carry it for both.

## Cost to build
One PR, small: a `MergeReadyPlate` widget (about 80 lines, on the story kit), shown at the top of `lib/screens/skills/my_skills_view.dart`* when `craftRecipesFor(...).any((r) => r.ready)`, with a test; the camp badge is one condition in `tabBadgesProvider` (Core's) and the camp's house card (`camp_screen.dart`*) gets the mark. No data, no rule, no string except the plate's four lines (EN and FR). (* shared files.) It needs nothing from Art. It builds on the kit (#1077).
