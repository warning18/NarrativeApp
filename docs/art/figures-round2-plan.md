# Figures round 2: plan (prepared, nothing generated)

Source for every figure: `Hero - Starter_basic_hero` (state `de5e44f4-1c9d-4043-96cf-eed8d324a086`, 48x48, 8 directions, side view). Method: `create_character_state` with a look line from Narrative. Cost: 10 generations per state (a 48x48 character is always 10), then 1 per walk direction (east, west).

Order: 1. six shopkeepers (Blind Beggar's stall, Shieldwrights' Hall, Smugglers' Vault, Hammersmith Forge, Sharpweave Den, Wayfarer Caravan). 2. six companions (Maren, Liora, Vess, Grosh, Tobin, Malrik). 3. later: the most common enemies.

Test: 1 keeper + 2 companions, 3 states = 30 generations, no walks. All 12 states = 120, with walks east and west = 144.

Known risk: a state keeps the source's face and body (it is a variant of the same person). Races far from the hero (elf, voidkin, orc) may stay too human; if the test shows it, the fallback is `create_character` with the hero's size/view/outline/shading and the hero as reference image, at a higher cost.

Sheet for the test: real size and 2x, next to Starter_basic_hero and the Stair-Chandler (#36).
