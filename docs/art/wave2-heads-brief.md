# Brief: new head avatars for the 14 foes that have no face (ready to start on a yes; nothing generated)

Reference for every prompt: **"Hero - Starter_basic_hero"** (state id `de5e44f4-1c9d-4043-96cf-eed8d324a086`, 48x48 side view), the user's standing rule for new people. Background: `docs/art/wave2-palettes.md` (the current heads are crops of 16 px top-down blobs: a hat with no face).

## Screens that show them
The avatar from `assets/visuals/heads/<id>.png` is drawn by `lib/widgets/head_avatar.dart` on: the fight (turn rail, board and the foe pick card: `fight_board_view.dart`, `fight_view.dart`, `fight_actions.dart`, `fight_pick_card.dart`), the Tower ladder (`tower_ladder.dart`), scene vignettes and the NPC detail page (`npc_detail_screen.dart`) for the people among them (Renn, Gorm).

## Two ways to make them
- **A (recommended): a head-only portrait per foe**, img2img from Starter_basic_hero's head (`create_image_pixflux`, about 32 x 28 px, the same pixel scale as the 2x avatars), 1 generation per try, 2 tries each = **28 generations**. Output replaces `assets/visuals/heads/<id>.png`; UX wires it. Ink or Apollo palette by remap, free.
- **B: a full 48 px state of Starter_basic_hero per foe** (`create_character_state`, 10 generations each, 8 directions) = **140 generations**; gives a full fighter sprite too, which these foes lack, and a head by crop. Worth it only for the foes that will get a fight sprite (the people: Renn, the exorcist, the captain, the thug, the soldiers, the zealot, the acolyte).

## Prompts (the look; Starter_basic_hero is the base, so each says what to change)
| id | name and kind | prompt (a head and shoulders, side view, facing left) |
|---|---|---|
| `cultist_acolyte` | a novice of the void cults (person) | a young novice in a plain dark purple hood, pale frightened face, a small violet mark on the brow |
| `dock_overseer` | Renn, the Inquisition's customs officer (person) | a lean man in his 40s in a brown officer's cap, narrow suspicious face, a ledger strap on the shoulder |
| `frost_kept_giant` | Gorm of Highhearth (giant) | a huge grey-bearded giant, frost on the brow and beard, heavy furs, small eyes |
| `hollow_reflection` | your own shape worn back at you (void) | the hero's own face drawn grey and glassy with empty white eyes, a crack across it |
| `horn_taker` | the Spire's senior exorcist (person) | a stern priest in a red-trimmed cowl, a broken horn hung at the neck |
| `inquisition_auxiliary` | a levied local in a tabard (person) | a plain worried villager in an inquisition tabard and an open leather cap |
| `inquisition_soldier` | a drilled, armoured soldier (person) | a helmed soldier in grey plate with a red cord, a hard clean-shaven face |
| `smuggler_captain` | a captain who runs the cordon (person) | a weathered woman or man in a salt-stained captain's hat, a scar, a half smile |
| `slum_thug` | a slum tough for hire (person) | a broken-nosed thug with a shaved head and a leather collar |
| `strand_colossus` | three keels and a chapel of glass fused (construct) | a head of fused ship timber and pale glass shards with one dim lantern eye |
| `void_wisp` | a mote of the tear's cold light (void) | a floating pale violet flame with a faint face, no body |
| `void_stalker` | a hunter out of the tear (void) | a gaunt long-skulled hunter in a dark hood with two bright violet eyes |
| `void_manifestation` | the tear in a borrowed shape (void) | a head made of many half-faces folded together, violet and black |
| `hollow_court_zealot` | a zealot of the Hollow Court (person) | a kneeling-posture zealot in a dark hood with a pale face and closed eyes |

## Order and cost
Start with 4 of the people (Renn, the exorcist, the captain, the zealot) as a test: 8 generations at A. Then the rest. Palette: Apollo for the story set, the ink greys and deep reds for the Tower, both by free remap.
