# Figures round 2: plan (prepared, nothing generated)

Source for every figure: `Hero - Starter_basic_hero` (state `de5e44f4-1c9d-4043-96cf-eed8d324a086`, 48x48, 8 directions, side view). Method: `create_character_state` with a look line from Narrative. Cost: 10 generations per state (a 48x48 character is always 10), then 1 per walk direction (east, west).

Order: 1. six shopkeepers (Blind Beggar's stall, Shieldwrights' Hall, Smugglers' Vault, Hammersmith Forge, Sharpweave Den, Wayfarer Caravan). 2. six companions (Maren, Liora, Vess, Grosh, Tobin, Malrik). 3. later: the most common enemies.

Test: 1 keeper + 2 companions, 3 states = 30 generations, no walks. All 12 states = 120, with walks east and west = 144.

Known risk: a state keeps the source's face and body (it is a variant of the same person). Races far from the hero (elf, voidkin, orc) may stay too human; if the test shows it, the fallback is `create_character` with the hero's size/view/outline/shading and the hero as reference image, at a higher cost.

Sheet for the test: real size and 2x, next to Starter_basic_hero and the Stair-Chandler (#36).

## Narrative's look lines (verbatim, 15 November)
Only what the story states is marked "stated"; the rest is a brief from role and clan, not canon. "Not like" = clash to avoid. In this text "#4", "#10", "#12" are item numbers of this list; #20, #35 and other two-digit numbers are PixelLab state numbers.

KEEPERS
1. keeper_blind_beggar_stall, the cellar-boy (stated: a boy who left the Blind Beggar with a barrow of the tavern's cellar, sells it on the wharf, "belongs to no one"). Human, about 13, thin. Stained tavern apron over a grey shirt, rolled sleeves, a flat cap; earth browns, off-white. Prop: a barrow of dark bottles. Not like: Tam (boy of ~12, lamp-boy, Rimewell), a Crow (#42), any cloak.
2. keeper_shieldwrights_hall, Hesta Brann (stated: a woman, quarry-born, Compact-sworn; judges a buyer by what they can lift). Human, 40s, broad and strong, dark hair tied back. Sleeveless leather apron, rolled sleeves over bare forearms, stone dust; slate grey, one ember-orange sash (Compact). Prop: a round shield half carved. Not like: Dagny (item 4), the Wreck-Wright #49, Ysolde #50, Tallis #53, Imra #20; no green, no hat.
3. keeper_smugglers_vault, "The Keyholder" of the camp's Vault (stated: follows the Crusade's supply ships, counter in a dry cellar; a Salt Crow). A lean man, 40s, pale from the cellar. Shirtsleeves and a black waistcoat, a green eyeshade, a ring of keys at the belt; black, salt grey, brass. Prop: one iron key held up. Not like: the Wharf Keyholder (a woman in a good coat), the Crow #42 (dark brown cloak), Aurel Vane (white mask).
4. keeper_hammersmith_forge, Dagny Ironhand (stated: an Anvil-Deaf smith, a woman; makes a buyer lift the piece before she names a price). Stocky, 40s, iron-grey braids, soot on the face, leather wraps over her ears (the Anvil-Deaf lose their hearing at the anvil). Soot black, ember orange. Prop: a hammer and tongs. Not like: Hesta (item 2), the High Warden's red cape (#23).
5. keeper_sharpweave_den, Needle (stated: the Whisper Ledger's contact behind a door with no sign; sells the finest edges; sex not stated). A slight person, 30s, nimble, a high collar, close dark clothes; charcoal and plum. Prop: a roll of needles that is also a roll of blades. Not like: the Crow #42 and the hooded mercenary #32 (no cloak, no hood), Aurel Vane's white mask.
6. keeper_wayfarer_caravan, Old Pell (stated: an old muleteer, his train never stops in one town). Human, 60s, weathered, bald under a wool cap, white stubble. A long dusty coat and a scarf; dust brown, faded red. Prop: a mule's lead rope. Not like: Old Harker #35, the sign-painter #34, a straw hat (#49/#50).

COMPANIONS (race marks: human = a sewn banner, elf = a painted sigil, dwarf = a cut mark on steel, orc = ash-ink under scars, voidkin = left by the tear)
7. maren: human cleric, Sister Maren, ex-Inquisition. Slight, early 30s, brown hair under a white veil, white and amber trim. Prop: a small lamp. Not like: Ysolde #50, Imra #20, Tallis #53 (green dresses), Aurel Vane's white mask: no mask, no green.
8. liora: elf ranger (stated: kept watch over the camp from forty feet up). Lean, 20s, pale, long gold hair, pointed ears, a painted sigil on one forearm. Forest-green and ash-grey leathers, bare head. Prop: a longbow. Not like: the Wreck-Wright #49 (also blonde: so no hat, no skirt).
9. vess: voidkin mage (stated: came out of the dark with you; hears voices). Thin, grey-violet skin, white hair, a deep purple hood and long robe. Prop: a lantern with a dim violet light. Not like: the hooded mercenary #32 (Vess is robed, not armoured), Aurel Vane, the reflections.
10. grosh: orc warrior, bare-headed (stated: "GROSH SMASH FIRST"). Huge, 20s, green skin, tusks, black hair, ash-ink scars on bare forearms. A patched hide jerkin. Prop: a heavy maul. Not like: Malrik (item 12), #30 gambeson/axe, #32 hooded mercenary.
11. tobin: dwarf cleric, Brother Tobin (stated: kept vigil for the cloister's dead; a creased letter on his knee). Stout, old, grey beard, a brown cowl with a rope belt and a steel buckle cut with a mark. Prop: a vigil lamp or the folded letter. Not like: the Stair-Chandler #36 (Tobin shorter, grey-bearded, cowled and belted), Old Harker #35, Old Wick #39.
12. malrik: orc rogue, Malrik Sarn, hooded (stated: takes half of what is dropped; a small black book). Lean for an orc, 40s, small tusks, ash-ink scars. A dark-green hood (3C4A2E) and short cloak over dark leather. Prop: the small black book. Not like: the Crow #42 (a brown-cloaked man), the hooded mercenary #32, Grosh (item 10).

Enemies for the round after (not started; needs the user's OK): void_hound, cultist_acolyte, void_wisp, hollow_reflection, drowned_pilgrim, catacomb_ghoul, inquisition_penitent, unmade_knight, smuggler_captain, bone_sexton, tear_spawn, void_manifestation.

Test (cleared, 30 gens, no walks): items 4, 8, 10.

## Test result (15 November, 30 gens, balance 796.5)
States made from Starter_basic_hero, 48x48, 8 directions, PNG8 64x64 (feet on row 55) in `art/pixellab-figures-round2/<name>/<direction>.png`. Sheets: `docs/art/boards/figures-round2-test-1x.png`, `-2x.png` (Starter_basic_hero, Stair-Chandler, Dagny, Liora, Grosh; south and east at 2x).
| Name | State id | Prompt (look line, item) |
|---|---|---|
| keeper_hammersmith_dagny | `cad5b4c4-28c0-48bc-9acb-f1a249acce5f` | item 4 |
| companion_liora | `d84b42f5-6a87-4055-b626-785175fd0de1` | item 8 |
| companion_grosh | `cdd2b8a4-5e77-4081-9f15-8e3ed7fea951` | item 10 |
The elf and the orc read as their races (pointed ears, gold hair; green skin, tusks); the states did not stay too human. No walks yet.
