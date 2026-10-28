# Changelog

All notable changes to this project are documented here, generated from the
repository's pull-request history (each entry corresponds to one merged PR
and the version it bumped `pubspec.yaml` to). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

History before v1.23.1 predates per-PR versioning in this repository and
isn't reconstructable from git history alone.

## [1.597.0+633]

- **Core: the difficulty pass** (docs/proposals/difficulty-pass.md, without the
  companion change the user turned down).
- **Smaller numbers on both sides:**
  - a level brings +3 health instead of +4, and a point of Constitution +3
    instead of +5;
  - common foes have 10% less health from chapter 2 on;
  - bosses' health floor is 1.21 → 1.13.
- **The die that matches the foe is worth swapping in:** a hit on a weakness
  does ×2 instead of ×1.5, and the fight card says so.
- **A potion heals 8 instead of 6.**
- **Chapter 1 plays as before.** Aurel Vane has 29 health instead of 22, to
  keep its 75%.
- **Re-sized so the boss curve and the professions' spread hold:**
  - Void Stalker 34 → 38 health;
  - White Admiral 72 → 62;
  - warrior +9 starting health, rogue +6, ranger +3;
  - cleric +4 damage instead of +5.
- **A new simulator profile, "stubborn":** companions, but the starter die and
  the starting gear for the whole run. It shows what the gear and the dice
  are worth.
- **Measured** (10 runs per profile, chapters 3–8, won at the first try):
  - naive player 0.40 → 0.42;
  - stubborn 0.80 → 0.81;
  - competent 0.96 → 0.99.
- **The 45–55% target for the stubborn player is not reached:** two or three
  companions still win the fight whatever die the hero rolls. The proposal's
  §7 has two options for the user.

## [1.595.0+631]

- **UX: the Dice tab in the inventory.** When you own more than one die, the
  inventory has a Dice tab: the die in your hand lit gold (its own look, name,
  "d6 · 6 faces · Bone"), the other dice below it with one Equip button each,
  and a die made for another class dimmed with a padlock and who it is for.
  Equip swaps the die in hand at once. The Dice tile in the slots goes to the
  tab, and a tap on a die opens the dice screen (the ring of face slots) on
  that die. `DiceLoadoutScreen` takes an optional `initialDieId` for it.

## [1.594.0+630]

- **UX: the inventory with tabs.** The bag has a tab for each kind it holds
  (All, Gear, Charms, Potions, Materials, Books, Quest), each with its count;
  the last tab and sort are remembered, and a quiet sort button (Newest,
  Rarity, Name) sits under them. The six slots are small tiles with their own
  icons, the die by its name (no more "starter_die"), and an empty slot lit
  when something in the bag fits it. Each row says one quiet line ("Rare ·
  goes on the Head"), shows up to three stat chips with the change against the
  piece worn, and has one labelled button (Equip, Take off, Read); a gold dot
  marks what came since the last visit. A tap opens the piece against the worn
  one as before; a long press on a gear row starts the manual compare. The
  title reads "Inventory". The new pieces are in
  `lib/widgets/inventory_parts.dart`.

## [1.593.0+629]

- **UX: the Forge sheet with tabs and the forging moment.** The Forge opens on
  tabs for the slots it has recipes for (Head, Body, Legs, Feet), a gold dot on
  a tab where something can be forged now, one line for the roll with its odds
  behind a tap, the ore hint behind (i), the smith's line, and a compact card
  for each piece whose button says what it lacks ("Short of 1 iron ore"). The
  forging is four beats: the strike, the d20 landing, the tier, the piece
  (tap to skip to the last; reduced motion shows the last at once), with
  "Forge another" when it can be paid again. `lib/widgets/forge_sheet.dart`
  and `forge_moment.dart` replace the sheet in `shop_trade_sheets.dart`.

## [1.592.0+628]

What the forge sheet needs, ready for UX's forge tabs. Nothing on screen changes yet.

- **The sheet's numbers:** a piece about to be forged now comes with everything the sheet shows:
  - the bonuses on the roll, each with its label, value and source (a dwarf hero +2; standing with the clan holding the forge's place, +1 or −1);
  - their total;
  - the chance of each result (Flawed, Sound, Fine, Masterwork) on the forge's d20;
  - the piece's main number and resale price as listed and after each result;
  - the result a given d20 face gives.
- **The camp's Bone-Caster's Hut on the forge:** while the hut stands and has a Reroll charge, it can roll a forged piece once more. That spends one charge; the piece takes the new result, with the same bonuses.

## [1.591.0+627]

Fourteen more buildings of Saltmouth have names, so the district view shows where each scene happens: at the Landward Gate (the salt road's end, the courier's place in line, the grain wagon, the shadow by the gate, the salt wagon), on Tern Row (Renn's toll post, the suspended toll), on the Wharf (the purse on the boards, the rotten gutter, the storm drain ladder, the thugs' lantern, Vane's tally) and at the Yard (the Rusty Eel's slip, the Rusty Eel at her berth). English and French.

## [1.590.0+626]

Lysa's turn in the chair chapel of the Reliquary Quarter (her death, her rescue, the oath, the mercy, the sacrifice, and Clement's refusal) opens as a full page, as the story's turn for her, not as a room.

## [1.589.0+625]

The street view now follows Narrative's scene tags.

- **Tagged scenes:** a scene tagged as played in the street, with a building of the town's plan, plays at that building's door. The party stands at its door on the plan, the district view shows that building's street, and the scene opens in the street view.
- **Concerned now:** the toll on Alster's Stone Bridge (260), the drill on the High Quay (890_trainer) and the shipyard gate on the Smugglers' Wharf (2010).
- **Untagged scenes:** a scene without a tag keeps the doorstep lists as before, such as the family house's street (300).

## [1.588.0+624]

A hub opens as its map and a scene at a doorstep as its street, with the scene's words as a band over them.

### Added
- **The scene band** (`scene_band.dart`): three lines of the scene's prose over the top of a hub's map, four over the sky of a street (a scene played at a building's doorstep), with the place's name above them. A tap, or a drag down, opens the whole scene in the arrival sheet; Continue folds it back to the band. It shows where Core's view rule (`viewOf`) says the scene opens as its map or its street.
- **A street scene is the street, not the sheet:** arriving at a doorstep no longer opens the sheet over the street; its band does, on a tap, with the choices acted out there.
- Tests: `scene_band_test.dart`. Pictures in `docs/ux-shots/scene-band-*.png`.
- Not yet: a tagged scene's street from `scene.building` (Core's part: the street still comes from the scene's doorstep).

## [1.587.0+623]

Three approach scenes of the first chapters open as the street before their building, as the user asked: the toll on the Stone Bridge, the drill on the quay approach and the Wharf's approach. The cells of the Black Hold, the chapter 3 ceremony and the fall in the cathedral open as full pages. The rest of the first three chapters follow the default rule.

## [1.586.0+622]

The district view as places, map first: the map has the room, its pins carry no words, a tap shows the place, and the list of places rises when the map is fully zoomed.

### Added
- **The list is places** (`district_places.dart`): in a scene with two places or more, the list under the district's map has a row per place (the party's own place first, "Here"; the story's main place with its flag; a way out under its own title; a shut place greyed with its reason), with how many things there are to do there. A scene with one place keeps its ways as the list.
- **Go to a place:** a tap on a row (or Go on a pin's card) walks the party's mark to the place (a tap skips the walk) and shows that place's ways, with a way back to the list. `Here` and a way out do not walk; a way out with one way to take opens it at once.
- **Map first:** no list until the map is fully zoomed. The pins carry no words and the story's building names are off the plan; a tap on a pin shows a small card (the place's name, how many things, Go; a second tap folds it). A "Places · N" handle at the foot of the map zooms it to its full zoom (the list rises, the handle reads "Map" and folds it back); a pinch to full zoom does the same.
- **The arrival:** on arriving in a district the map eases in 25% and centres on the party's mark in 0.6 s (a jump with reduced motion; not on the Town view a move to another district frames).
- Fixed: a chart built after a camera shot replayed it (`CityChartCamera.pending`).
- Tests: `district_places_test.dart`, `district_places_view_test.dart`; `test/district_places_steps.dart` holds the steps. Pictures in `docs/ux-shots/places-build-*.png`.

## [1.585.0+621]

Tern's Toll can be finished by talking Renn down, not only by fighting him. The quest now asks the player to deal with the overseer, and either way ends it.

## [1.583.0+619]

The first-launch intro: the Great Shroud burning, six embers, the ashen city, down to the Blind Beggar, the old bone die falling and stopping on a six, the title over it, a slow fade into the game.

### Added
- **The intro** (`intro_screen.dart`, `intro_art.dart`): 15 seconds over eight beats. The Shroud burns over Alster, leaves six embers (one falls toward the city), the calm streets wait with the Inquisition's white ships far off (no shell yet), the camera pushes down to the Blind Beggar, the bone die falls, bounces and rolls to the middle, slows and stops on a six (the first shell lands only then), the title rises over it and the room fades into the game. Narrative's four lines (set A) write themselves over it, in order, English and French.
- **Plays once**, at the first New Game (the `intro_seen` flag); a tap goes to the last beat, a second tap ends it. With reduced motion it shows the title over the die, then the last line.
- **Replay the intro** in Settings, under the tutorial's replay.
- Tests: `test/intro_screen_test.dart` (the lines in order, tap to skip, reduced motion, the flag, the Settings row); `test/flutter_test_config.dart` keeps the intro off elsewhere. Pictures of every beat in `docs/ux-shots/intro-build/`; the earlier storyboards A to C are kept under `docs/proposals/` as history.

## [1.582.0+618]

Seven buildings of the Smugglers' Wharf have names, so the district view and the ways show where things happen: Vane's barrel, Vane's guard corner, the wet boards, the loading crane, the old customs house (Liora's skiff), the wharf steps, and the shipyard gate. English and French.

## [1.581.0+617]

The Smugglers' Wharf lists fewer things at once. The harbor master's jobs come one at a time, in the order of their quests; the two stairs off the wharf (the Lantern Alleys, Tern Row) are one row that goes when both are seen; the three ways past Vane are one row. Every scene, quest and reward is still there; the first view of the Wharf shows five entries instead of eleven.

## [1.580.0+616]

The groundwork for the district view as places, its camera, and the view each scene opens in. Nothing on screen changes yet: UX builds the places list, the labels-off map and the arrival ease on top of this.

- **Places:** each way of a scene in a town now has a place where it is taken.
  - It is the party's own place ("here") for things done on the spot: fights, checks, payments and decisions.
  - It is a building of the town's plan for a way to a scene there.
  - It is a way out for a road, gate or harbour.
  - A way whose building was only a stand-in now counts as "here" rather than a random building.
  - Story data can set a choice's place directly with the new `place` field.
- **The district list:** it groups the ways by place, with a count. "Here" comes first, then the places holding the main story, then the rest, then the ways out; a place that is shut comes last.
- **The party's place:** the game now remembers which place the party has walked to within a district. It is not saved: a game picked back up opens on the list.
- **Arrivals:** a new arrival is signalled each time the party arrives in a district.
- **The camera:** the Journey can now set the district map's zoom and centre.
  - The arrival shot is the district 25% closer, centred on the party, over 0.6 s.
  - The map reports when it reaches its full zoom.
- **The view each scene opens in:** page, sheet over the map, street, room, the place's map, or ending.
  - The rule follows the approved presentation contract: town and camp scenes on their map, chapter beats on the page, scenes inside buildings in the room, scenes at a door in the street (unless they continue a main scene there), other main scenes on the page and side scenes in a sheet.
  - A two-page scene's first page opens in the view of its second.
  - Narrative's `scene` block (`view`, `weight`) wins over the rule and is kept when the scene is saved.

## [1.577.0+613]

Three scenes of chapter 1 are told in two pages: the Blind Beggar's evening, then the wall coming in; the walk to the family house, then the cannonball; the Lark lifting off, then the guns. A Continue on the calm page; the choices come with the shock. English and French.

## [1.576.0+612]

A clan at a glance: its standing with you as a disc, its power as the cloth.

### Added
- **The standing disc** (`standing_sign.dart`): a small disc at the top-right corner of a clan's banner, one design for each of the eleven standing steps, each in the game's own colour for it (the clan card's), so the shape carries the level too: a skull (Hunted), crossed blades (Hostile), one blade (Resented), a frown (Unfriendly), a watching eye (Wary), a dot (Unknown), a ringed dot (Known), a hollow heart (Friendly), a heart (Friend), a shield (Trusted), a crowned heart (Sworn). Hunted and Sworn wear a double rim.
- **The power cloth** (`clan_glance.dart`): the banner is dark above the level of the clan's power tier and in its own colours below it, a quarter for each of Minor, Rising, Dominant and Ascendant, with a gold hairline at the level (none when full). Clans with no power of their own keep their banner whole.
- Both marks read the tiers the clan card already shows (`PoliticsState.tierOf`, `powerTierFor`): no new numbers. They stand on the offer's banners, the clan card's banner (the long press), the ring's crests (the cloth fills the round crest from its foot; the disc is at its top-left, clear of the number), the Throne room's standards (a clan's, not a piece of the Shroud) and the Clans screen's cards.

### Tests
- New `test/clan_glance_test.dart`: every step has its own distinct shape (also mirrored) and its own colour, the sign draws for each tier, the cloth fills a quarter a tier with its hairline, a clan's banner wears both marks, the disc alone without the cloth, a faction not on file keeps its banner. The offer, compass, throne and clans tests are unchanged and pass.
- Pictures of the real screens: `docs/ux-shots/clan-glance-offer.png`, `clan-glance-ring.png`; the discs: `standing-discs-mock.png` (PR #534).

## [1.575.0+611]

The fate coin now also works at the camp's fire and at the forge.

- **At the camp:** when a check fails at the fire (catching the thief, making peace in a quarrel) and the pack holds a fate coin, the game offers it. Flipped, the coin is spent and the check is rolled once more.
- **At the forge:** a piece that comes out Flawed offers the coin too. Flipped, the forge's d20 rolls again with the same bonuses, and the piece takes the new result (Sound, Fine or Masterwork, or Flawed again).
- The land crossing's coin is unchanged.

## [1.574.0+610]

Arriving in a town never leaves its whole plan fogged.

### Fixed
- **A town's first district is found on arrival** (`city_districts.dart`, `foundDistricts`): at the White Wells (and every town with districts) the scene the party arrives at is in the town itself, in none of its districts, so the Town view showed every district as "?" with nothing to start from and the player had to guess which to enter. Now a scene played in the town itself finds the first open district of geography.json's order (the Pool at the White Wells), named on the plan and in the list, with its ways; it stays found as the party walks on. A scene in a district finds that district only, as before. A locked district is never the one found.

### Tests
- New `test/town_arrival_test.dart` (every town with a town-level scene opens on its first open district, the White Wells' Pool, a walked-into district joins it, a district scene is unchanged) and `test/ux_arrival_shot_test.dart` (the real screen as a picture with `UX_SHOTS`, `docs/ux-shots/town-arrival.png`).

## [1.573.0+609]

The dice loadout shows a die as a ring of slots, one per face.

- **The ring:** every face of the selected die is a round slot on a ring, the first at the top and the rest clockwise. A d4 has 4 slots and a d20 has 20. The middle names the size (d8) and how many faces hold a skill (3/8 with a skill).
- **Slot size:** slots shrink as the die grows, so a d20 still fits a 320 px phone. Below 70 px (a d12 or a d20) a slot shows only its icon. The die card above names the picked face and has the button to choose its skill.
- Dragging a skill onto a slot, tapping to turn the die, double-tapping to choose and the cross to clear all work as before.
- The faces help now also gives the copies rule: one copy of a skill per four faces, 2 on a d6.

## [1.572.0+608]

The Town view shows the shut districts, who holds the others, and how firmly (wave 18).

### Added
- **Shut districts** (`city_chart_painter.dart`, `district_standing.dart`, `journey_screen.dart`): a district a side quest keeps locked is shuttered on the town plan (fog, a hatch and a dashed outline, a padlock over its name) and in the list under the plan: a padlock, its name (never "?") and the reason, its rumour, in two lines. A tap on it, on the plan or in the list, opens a small sheet with the reason and "Opens with: <quest name>" instead of zooming into it.
- **Holders and influence** (`district_standing.dart`): every district with a holder shows its clan's flag in the list, the holder's name with its influence there ("Dominion 48"), a two-colour bar (the holder's from the left, the strongest rival's from the right) and the rival's name and number under it. On the plan each district's label has a small crest above it: a ring filled by the holder's influence, the rival's share inside it, a tick at the point where the rival would take the district, and the holder's flag. A district that changed hands by influence gets a gold star and "changed hands" on its line and on its crest. Influence is shown only in a town where it counts (Saltmouth, for now); elsewhere the holder's flag alone.
- The city chart screen (`city_chart_screen.dart`) shuts the same districts.
- Strings `district_changed_hands` and `district_locked_by` (EN/FR).

### Tests
- New `test/district_standing_test.dart` (the standings from the rules, the rows, the strings) and `test/ux_town_shot_test.dart` (the real screen as pictures with `UX_SHOTS`, see `docs/ux-shots/town-view-*.png`). `district_walk_test` uses a taller screen: the list rows are a line taller.

## [1.571.0+607]

The dice come in real sizes, d4 to d20, and every face of a die is a slot to equip.

### Changed
- **31 dice, new sizes** (`docs/proposals/dice-sizes.md` §1): 10 stay d6. Stone, berserker, shadow, twinfang and headsman become d4 (void already was). Flame, tide, huntsman, Vess's, frost, greenwood and vigil become d8 (vigil was a d7). Storm, arcane, sage and ossuary become d10. Tempest, chorus and tearglass become d12. Gambler becomes a d20 at 200 gold, sold only at the Last Lantern.
  - A die that grows keeps its faces and weights. The new faces are plain Strike, Guard and Mend at the die's own average.
  - A die that shrinks to a d4 keeps its skill faces and drops its two weakest plain faces.
- **Every face is a slot:** any face of a die can hold a skill, signature and Mana faces included (Mana channels it at 70%). No die holds more copies of one skill than one per four faces from the d8 up: 1 on a d4, 2 on a d6, d8 or d10, 3 on a d12, 5 on a d20.
- **Saves move over:** placed skills and Hammersmith work follow their faces. A skill on a dropped face goes back to the skill list, and Hammersmith work on it is refunded in full (gold, iron ore, an elite trophy). Saves record `diceDataVersion: 2`.

### Added
- **The tally die** (d12, 12 plain faces to fill): the reward of *The Candle Count* (chapter 5), or woven at the Skillwright from two d8s you own (both are spent, and their Hammersmith work is refunded). Only one can be owned.
- **The fate coin** (30 gold, one use): when a land-crossing check fails, flip it to roll the check again.

## [1.570.0+606]

Chapters 1–3 read the same in English and French: names, titles and times of day agree between scenes, and the paragraph breaks match in both languages. Wording only.

## [1.569.0+605]

The Journey's ways are grouped by pin, and the notice board is a board you read.

### Changed
- **The list of ways under the district map** (`way_pin_groups.dart`, `journey_screen.dart`): the ways that hang at the same pin (a building, or a spot) on the map are one row: the pin's own banner or disc, the name of the way that leads it, a count and a chevron. It is closed until tapped; a tap opens it in place to its ways, each the row it always was, indented, and a tap on one does what a row's tap did (the way's sheet). Only one pin is open at a time. A pin with one way stays a plain row, and a district with no such pin looks exactly as before. The header reads "2 pins · 5 ways · tap a pin to open it" when there are grouped pins. (The opened state is built as mocked so a row can open; say if you want it otherwise.)
- **The notice board** (`bounty_board.dart`, `town_service_sheet.dart`, `city_chart_painter.dart`): the contracts are pinned on a wooden board as slightly tilted parchment notes, each with a stamp-ring for its kind, its goal, how far along it is as pips and "2 of 3", its pay as two chips (gold, essence), and a wax seal that is the Claim: flat and grey while the note is open, red and glowing once it is met. A claimed note is stamped PAID and drops off; a new board's notes pin up one after another (with reduced motion: no pin-up, no stamp, the note is simply gone). The header says the chapter and what waits ("Chapter 2 · 1 to claim"). The notice board's pin on the district map is a little board with a count of the notices up, red when one can be claimed, and a tap on it opens the board itself instead of a sheet with one row. The contracts, the claim and the posting are unchanged; the camp's board looks the same way.

### Removed
- **On the level-up pop-up and the Level Up screen** (`level_up_dialog.dart`, `level_up_screen.dart`): the "Stat picks left: 1" box, the line "Each level also gives +4 max health.", the line "The clans come to you once this closes: an offer waits." (pop-up only) and the line "Hold a stat to see what it does". The header, the cards, the radar and the Close or Take this pick button stay, and the hold-to-peek on a stat still works, it is just not announced. When more than one pick waits, a small quiet count ("2 picks") shows so the player knows another round follows; with one pick, nothing. **One radar:** while a pick waits, the Level Up screen's own plain radar (and its "tap a corner" line) is gone, in the pop-up and on the screen: the picker's radar (the hero's shape, with the pick in green once one is chosen; before any is chosen, the shape alone) is the only one. With no pick waiting, the plain radar is shown as before. The strings `stat_picks_left`, `level_up_gives` and `level_up_offer_note` are gone; `hold_stat_for_details_hint` stays (the character creation screen uses it).

### Tests
- `level_up_screen_test` (the removed texts are gone, the quiet count shows for several picks) and `qa_real_font_layout_test` (it checked the removed points box; it now checks the pop-up is up). New `test/way_pin_groups_test.dart` (the grouping, a closed pin with its count, opening, one open at a time); `bounty_board_test` (the header, the seals, PAID and the drop, reduced motion); `town_service_pins_view_test` (the notice board opens the board; the pin's count paints).

## [1.568.0+604]

The competent simulated player recruits companions and fights beside them.

### Added
- **Companions in the simulator** (`lib/data/sim_companions.dart`, competent profile only; naive is unchanged and stays the default for every CI band test).
  - **Recruiting.** A companion joins as in the game: when their quest is handed in, once only, never after they leave or the story takes them. Tobin's and Malrik's quests keep their Good and Evil gates.
  - **Seats.** The party holds 2, or 3 once the Barracks Annex stands; Kelda sits once her hall is built.
  - **Story choices.** With companions on, the competent player takes a story choice that offers a companion quest it may take.
- **The pick rule.**
  - Seats go to the companions worth most in a fight: their die's average roll at their damage, plus 0.1 per health and 0.8 per armour.
  - A tie (within 1) goes to higher approval, then to the companion whose approvals fit the player's alignment, then to the earlier recruit.
  - A better recruit takes the weakest seat. The rule runs again at every recruit, departure, house built and chapter rest.
- **In fights.**
  - Each seated companion rolls their signature die through the same dice code as the hero. Their approval tier scales their damage and health.
  - Enemies hit a random standing party member, and the biggest block draws the blows.
  - A knocked-out companion comes back at 30% health after a won fight. A rest or a level-up heals everyone.
- **Approval.** A choice's alignment, its gold and its `approvalMods` move approval for seated companions. At −12 a companion leaves and the best benched one takes the seat. `loseAllyId` takes one for good.
- **The run report** lists every seek, recruit, pick, bench, swap, leave, loss and move into devoted or wary, each with its reason, then the final party.
- **No dice cup.** The game has one die in play, swapped between fights, and the competent player already rolls its best.
- **Measurement.** `docs/simulation/companions-v1.568.md` covers 10 runs per profile. From chapter 3 on, a competent party wins 0.98–1.00 of encounters, against 0.86–0.90 alone and 0.54–0.69 for naive.

## [1.567.0+603]

Chapter 1's first step outside opens the Journey and its tour; the party walks to a pin; "Back to the map" goes where the cards hold every move.

### Changed
- **The first step outside:** in a new game, the first way out of the Blind Beggar lands on the Journey map of the Lower Town (scene 250, the proclamation, with "1 way here"), not on 250's page. It happens once (`journey_first_shown`).
- **The Journey tour starts there,** not on the Beggar's room map, and still only once. A pending "New:" card waits until the tour is skipped or finished. The tour's "tap a step" line now points at the District view's list of ways.
- **The party walks to the pin:** taking a way on the District view (its pin or its row) walks the party marker to the pin, then opens the scene. The walk takes 0.6 s next door and up to 1.2 s from half the town away. A tap anywhere lands the party at once; with reduced motion there's no walk.
- **No "Back to the map" when the page holds every move:** on a page with a way to take, the button and the corner map icon go when every way on the map leads to a place one of the page's cards also reaches. Those ways show as cards on the page, so none is lost. Example: the warhound in the alley (270), where all three ways lead to the family house. The button stays where the map has another move, and on hubs, endings, a page opened with Read, and a new game's first page. The scene lock (v1.563) is unchanged.

## [1.564.0+600]

The playthrough simulator can play like a competent player.

### Added
- **Two player profiles** (`SimPolicy` in `lib/data/sim_policy.dart`):
  - **`naive`** is the simulator as it always played. Every CI band test (boss_balance, clash_balance, qa_clan_power_50, nemesis_quests, sim_playthroughs, sim_coverage, sim_houses) still uses it, and its results are unchanged.
  - **`competent`**, used by the simulator screen's runs:
    - Before every fight it wears the best loadout it owns: loot, quest rewards and scene grants included. It weighs elemental bonuses, uniques and set bonuses, and respects stat requirements.
    - It shops for potions, a better die and gear by how much each improves its loadout.
    - It keeps its signature die, rolls the best die it owns, and crafts a skill merge when that improves its die.
    - Clan offers: it takes the gift that raises its power most, gives ties to the clan it stands closest to, and never takes a banner that turns its main clan or an ally Hostile.
- **The run report:** both profiles record every clan offer (chapter, source, banners, the one taken and why). The transcript prints these, with the gear worn and the die.
- **Measurement:** `docs/simulation/competent-player-v1.564.md` compares the two profiles over 10 runs each. From chapter 3 on, the competent player wins about 0.88 of encounters against 0.62 for the naive one.

## [1.563.0+599]

The scene lock only holds a scene whose ways are all on the spot. Any way with a place on the map is taken from the map again.

### Fixed
- **Map movement is back:** v1.555 locked any scene the story led to that had one choice made on the spot. It turned every way into a text card and greyed the map, even ways that already had a place on it. A scene now locks only when none of its ways is drawn on any map: the place's pins, the town plan, a room's spots, a road or the world. A scene with both kinds no longer locks: its mapped ways stay on the map, and its on-the-spot choices stay in the scene view or the sheet over the map.
- **The sheet over the map is back** for every scene that does not lock, as before v1.555.
- **Fewer scenes lock:** over the whole story, 52 scenes lock instead of 361. The House's Bouncer's aftermath (106) and all of chapter 1's opening (0–400) no longer lock. The wreck (965) still does.
- **No lock before the map is ready:** a save reopened before the map and town plans have loaded no longer locks on its first screen.

## [1.562.0+598]

Forging rolls a d20 for the piece's quality.

### Changed
- **The forge rolls:** forging spends its gold and materials as before, then rolls a d20 plus its modifiers. The total sets the piece's tier: 1–4 Flawed, 5–14 Sound, 15–19 Fine, 20 or more Masterwork. With no modifier, the odds are 20 / 50 / 25 / 5%.
  - The modifiers: a dwarf hero +2, at any forge; standing with the clan holding the forge's place, +1 at Friendly or better and −1 at Unfriendly or worse.
  - A Flawed piece has −1 to its main number (never below 0), a Fine one +1, and a Masterwork one +2. The main number is armour for armour, damage for a weapon. Resale is −25%, +25% or +50%.
  - The tier is kept in the piece's id (`boots_iron_shod@fine`) and its name ("Fine Iron-Shod Boots"). It survives saves, and every item lookup reads it.
  - Until the new forge sheet comes, the Forge button names what was made: "Forged: Fine Iron-Shod Boots".

## [1.560.0+596]

"A Life Before This One" is played as scene pages.

### Changed
- **The memories** (`origin_stories_screen.dart`): each of the six memories is a page like the story reader's. A side-view picture of the memory's place fades into the page with the age, the stage and the title over its foot; the age rail is small under it; the memory's words are set in the reader's prose (no card) and write themselves out the first time (a tap finishes them; with reduced motion they are there at once); the answers come when the words have been written. After an answer, what came of it is written out on the same page, then its two tags (what it teaches, how it leans) and "Next memory". The recall line, the three answers with their stat chip, "Choose my whole life at random" and "Choose again at random", the summary and every word are as before.
- **The fourteen places** (`origin_scene_backdrop.dart`): each memory has a backdrop read off its own words: the rope-walk in the rain (the sparrow), the chapel, the market awning in the rain, the smithy, the street, the frozen well (frost), the tavern on Tallow Street in the snow, the docks (sea), the chandler's, the back alley at night, the Drowned Saint's shrine at night, the marsh (fen), Old Hesk's house, and the parents' house in the snow. The street kit's party at the door is left out of them (`StreetViewScene.party`).

### Tests
- New `test/origin_scene_backdrop_test.dart` (each of the fourteen memories has a place, and every place draws at 320 and 390 px); `origin_stories_test` checks the picture, and that the answers wait for the words.

## [1.559.0+595]

- Saltmouth's side quests now belong to a district and a clan, so what you do on the wharf, at Card Row and on Tern Row changes who holds them. Two new district quests (The Short Count at Card Row, A Boat for the Wrong Name on Tern Row), a door scene and a reason for each locked district, and a line when a district changes hands.

## [1.558.0+594]

Wave 18, step 1: Saltmouth's districts can be locked, and the clans fight over them with influence.

### Added
- **Locked districts:** a district in `geography.json` may carry `"lock": {"quest", "opensOn": "accepted" | "done"}` and a one-line `lockedText` (EN/FR). While locked, the party can't walk in and the district never counts as found. The story's own ways into it stay open. The free "Walk to" rows skip a locked district; if every neighbour is locked, they offer the nearest open district, so the party is never stuck. Step 1 locks the Lantern Alleys (until *The Informant's Tip* is done) and Tern Row (until *Tern's Toll* is done).
- **Influence:** each district keeps its clans' influence (0–100, saved), and its holder starts at 20. A quest done while the party is in Saltmouth adds +15 (side) or +25 (Main), or the quest's own `influence`, in the quest's `district`, or where the party stands. It goes to the clan the chosen turn-in raises most, else to the quest's `faction`.
- **Flips:** a clan whose influence passes the holder's by 15 takes the district, through the same hand-over as war (news, clan log, relations). A news line `district_flipped` names the district and both clans, `flipped_<district>` is set, and the companions' `districtFlipped` remark can fire. A clan holding 4 of Saltmouth's 6 districts holds the town, and loses it below that. Seats never change hands by influence.
- **For scenes:** `held_<district>_<clan>` flags follow every holder in every town. The `attack` camp-errand kind and the `districtAttacked` remark kind are ready for step 2.
- **Saltmouth's holders:** Landward Gate (Dominion), Ship-breaker's Yard (Compact), Lantern Alleys (Mire), Wharf and Card Row (Crows), Tern Row (Tide-Kin).
- **Simulator:** it applies quest influence at turn-in.

## [1.556.0+592]

The clans' gift no longer waits behind a button: it opens on its own, and a gift must be taken.

### Fixed
- **The clans' offer opens by itself:** a gift offer only opened by itself after a level-up or a boss win. Every other offer waited behind "Choose a gift": from a chapter, a quest, an intrigue, a story change or a Tome, carried over from a save, or queued on the feature ladder while the clans were locked. They piled up. Now, whenever an offer waits and the player is on the home screen in play (no fight running, no quests being settled, the clans open), the offer opens. Each offer waiting comes up in turn, until none is left. As before, the sheet can't be dismissed (no tap outside, no back, no "later"), and its confirmation is unchanged. Edit Mode, and the ladder before the clans open, open nothing.
- **A fight no longer loses its offer:** a level-up in a fight that closed itself while the offer was loading kept the offer pending. It now opens over the home screen.

## [1.555.0+591]

A scene the story brings you to holds you on its page until you choose, and a district with no way of the story lets you walk on.

### Changed
- **The scene lock:** when the story brings the party to a scene (a pin or a card taken, a new game's first scene, or a save picked back up), and one of its ways is acted out there, the scene opens as its page and holds the party there. Every way shows as a card, roads included (a road keeps its glyph and says where it leads). The District, Town and World tabs, the map icon and "Back to the map" are greyed, with "Choose first". Taking a road card brings the map back and walks it, the world road included. A shop, or a fight fled, keeps the lock. Hubs, the camp, endings, Edit Mode and jumps never lock. A save on a locked scene reopens on its page, and the recap waits for the next scene with a map. Most story scenes lock, so the sheet over the map now shows only for scenes the story did not bring the party to. The pure rule is `lib/data/scene_lock.dart`.

### Fixed
- **Walk to a neighbouring district:** when the party's district has none of the scene's ways, the District view lists "Walk to <district>" for each district that borders it on the town plan. Saltmouth's Landward Gate is one such district. The walk is free: no story time, no ration, and the scene stays where it was. The district walked into counts as found.
- **No stuck street view:** after walking away from a scene played at a building's doorstep, such as the informant's trap at the Landward Gate, the District view showed that empty street. It now shows the district the party walked to.

## [1.553.0+589]

Two sheets and dialogs, in one release: the place sheet's height and the clan popins that stay open.

### Changed
- **The place sheet** (`arrival_sheet.dart`, `journey_screen.dart`): the words scroll above the whole choices, the sheet grows to 90% of the screen, and its handle can be dragged to make it shorter (down to about a third). The choices are capped at 70% of the room left so a small sheet never overflows.
- **The clan details popin** (`clan_peek.dart`): a long press on a clan's banner opened the card only for as long as the finger was down. It is now a dialog that stays open when the finger lifts, and closes on a tap outside it, on its close button, or on the back gesture; the "Let go to close" and "Tap to close" lines are gone. The other hold-to-open popins already stayed open; a test now says so.

### Tests
- `arrival_sheet_size_test` and `popins_stay_open_test` are new; `offer_dialog_test`, `throne_room_test`, `journey_arrival_test` and `journey_scene_sheet_test` follow the new sheet and popin.


## [1.552.0+588]

The level-up stat pick shows on the ability radar.

### Changed
- **A pick is drawn on the radar** (`stat_pick_picker.dart`, `ability_radar.dart`): picking a stat card no longer opens the detail block under the cards (the path's name, each gain from where it stood to where it goes, the effect lines). The ability radar takes its place: the hero's shape as it stands in gold, the shape the pick would give round it in green, and each corner the pick moves shows its new value highlighted with the gain under it ("CON 7, +1"). The shape grows from the current one over a third of a second; with reduced motion it is there at once. A pick worth more than one point still says "Worth n points" under the radar. "Take this pick", the roll powers and the cards (with the path, each gain and what it does for the hero) are unchanged.
- `RadarAxis` takes a `valueColor` and `AbilityRadar` a `preview` shape.

### Tests
- New `test/ability_radar_preview_test.dart` (the second shape, the corners, the growth, reduced motion, the scale; `UX_SHOTS=<folder>` takes `docs/ux-shots/level-up-pick-radar.png`); `stat_pick_picker_test` and `level_up_screen_test` now expect the radar where the detail block was.

## [1.551.0+587]

A walk along a world road now plays on the World map.

### Fixed
- **Road moves on the World view:** taking a way that leaves a place for another one used to draw the walk on the District tab: a bare grey region with the road's stops on it. One example is "Go the long way round" from the Sleeper's Face to the White Wells. The Journey now switches to the World view with the World tab lit and walks the road there, at the same pace as the road transit. Arriving at the next place shows that place's own view, as before. A tap on the walk skips it and lands the party at once.

## [1.548.0+584]

A page whose only ways on are its own cards no longer offers "Back to the map".

### Fixed
- **No dead "Back to the map":** the Journey can open a scene's page by itself, on a new game's first scene or after a card is taken. If every way on is a card on that page, the "Back to the map" button and the map icon in the corner are gone, and the cards take the story on. The button stays when the map holds a way on, or when the player opened the page from the map. A jump or a loaded save away from such a page lands on the map, as before.

## [1.547.0+583]

- Reedholm's night: the old feud between the Mire and the Penitents now comes back unless someone walks out to meet the Mire with open hands, as the refugees you took aboard, an absolved Ember Sister or a Moss Choir singer can.

## [1.546.0+582]

The Mire and the Penitents no longer start the game at war.

### Changed
- **The Mire and the Penitents start at Hostile**, not at Blood feud (wave 17 item 2). Only the number in `relations.json` changes. With Narrative's Reedholm beat (next release), the feud comes back in chapter 5 unless the party made peace possible. Over 50 simulated runs with the beat, the Mire's Court falls in 10, down from 20. Fight win rates move by 0.3 points or less. The study is in `docs/simulation/clan-power-50-v1.526.md`.

## [1.545.0+581]

A chapter 6 crossing on the Glass Shore, and the Lantern Cliffs' last two events (wave 17).

### Added
- **The Glass Shoals** (chapter 6): after landing at the White Anchorage, the party crosses the glass shore to the White Fleet's Grave, with Narrative's four glass-shore events. Once a clan holds the Anchorage, about one day in three brings that clan's event too. A crossing costs about 2–4% health.
- **The Lantern Cliffs** (chapter 7) also draw the wrecker's lamp and the gulls. Each has a way through that costs nothing.

### Fixed
- **The fen, frost and sea-cliffs crossings** (chapters 4, 5 and 7) now show their side-view scenes; they showed none before.

## [1.544.0+580]

A street-view kit for scenes played outside a building, the room kits' counterpart for the outside.

### Added
- **The street before a building** (`lib/widgets/street_view/`): where a scene plays at a building's doorstep (Core's v1.542: the family house's 300, 400, 400_lost and 450; the Blind Beggar's 125; the informant's warehouse), the district view shows the building's front, the street in front of it in cobbles, and the party at its door, in the side-view engine's pixel style. Six fronts by what the building is (a house, an inn or den, a warehouse, a shop or forge, a temple, a hall or keep), read from its kind and name as the room kits do.
- **The day's weather and hour on it:** rain falls and wets the stones, snow whitens the roof and the kerb, fog and ash drift over; the sky takes the hour (dawn, day, dusk, night with stars) and the windows and a lantern by the door light warm at dusk and night, over the wash so they are not dimmed with the evening.
- **The choices are pins on the street** (the banners and discs the Journey draws everywhere else, with their labels), in two rows when there are more than four; a tap opens the way's sheet as before. The rows under the picture and the buttons over it are unchanged.

### Changed
- The Town tab and the zoom-out button still show the town's plan with the party at the door; only the district view is the street.

### Tests
- New `test/street_view_test.dart` (the front by building, every front at every hour and weather, pins at 320 px, reduced motion; `UX_SHOTS=<folder>` takes `docs/ux-shots/street-view-fronts.png`); `doorstep_scenes_test.dart` now expects the street in the district view and the plan under Town.

### Touches another session's area
- `lib/screens/journey_screen.dart` (`_CityDistrictView`: an optional `street` building, the street scene in place of the plan's picture when set, and the pin builder; about 40 lines, the rest of the diff is the formatter re-indenting the plan view).
## [1.543.0+579]

The story reader: the echoed lines are prose, and the text writes itself out more slowly.

### Changed
- **"Because you chose …" only in Edit Mode** (`story_player_screen.dart`, `EchoLine`): in play, a line an earlier choice earned is set into the story as ordinary prose, with no caption, clock icon or side rule. The story node editor's preview (Edit Mode) keeps the label, icon and rule as before. The Journey's scene panel uses the same widget, so it follows.
- **The text reveal is a third slower** (`story_text.dart`): about 175 characters a second instead of 260, between 0.6 s and 6 s (was 0.4 s and 4 s). A tap still shows it all, and reduced motion still shows it at once.

### Tests
- New `test/echo_line_test.dart` (play and Edit Mode, and the reveal's speed); `scene_flow_play_test` now expects no caption in play.

## [1.542.0+578]

Some scenes now play in the street in front of a building, not inside it.

### Changed
- **Doorstep scenes:** a building in `geography.json` can now list scenes under `"doorstep"`. These scenes play in the street at its door. The Journey shows them on the district plan, with the party at the building's door and the scene's ways on the streets around it. Before, they were shown inside the building's room. Tagged so far:
  - the Alster family house: scenes 300, 400, 400_lost and 450;
  - the blind beggar: 125;
  - the Saltmouth landward warehouse: 2015_informant_trap.

## [1.541.0+577]

A new game no longer shows the map before the story starts.

### Changed
- **The first scene's way is a card:** on a new game, "Choose who you are…" is a card on the first scene's page, not a step on the Lower Town map. Taking it opens character creation; the story then goes straight to the Blind Beggar's page. Later ways across town are still map steps.

## [1.540.0+576]

A game picked up on its first scene opens on that scene.

### Fixed
- **Continue on a game never started:** creating a character and leaving before the first step left a save on the first scene; Continue opened it on the Journey map with "Choose who you are…" in a row at the bottom. It now opens on the first scene's page, as New Game does. The rule is now the story's state (on the first scene, nothing played yet), whatever way the game was opened.

## [1.539.0+575]

- The blurbs for Alster and Saltmouth now describe the places themselves, in English and French.

## [1.538.0+574]

Towns walked in words: the walk between districts, the doorway of a building, and the place panel's name once.

### Added
- **The walk between districts is told** (`journey_screen.dart`): crossing from one district of a town to another says "You walk to the Stone Bridge…" (FR "Vous marchez vers le Pont de Pierre…") in the road walk's bubble. It sits at the top of the map so it does not cover the zoom buttons; a tap skips it.
- **A doorway between a room and the streets**, both ways (`town_walk.dart`): going into a building, or back out to its streets (by the story or by the look-out and go-inside buttons), fades from a veil with a door glyph and says "You step inside the Blind Beggar…" or "You step back out into the streets…". With reduced motion only the line shows.

### Fixed
- **The world map's place panel** no longer names a land twice: a breadcrumb that reads as the title (Alster, as the title and the last crumb) is left out.

### Tests
- New `test/town_walk_test.dart`; `alster_one_place`, `journey_inside`, `journey_transit` and `geography_widgets` tests updated for the new lines (the transit test said "nothing needs saying" along a city's streets).
- Not done: no picture of the caption; the veil is tested on its own, not as a frame of the whole screen.

### Touches another session's area
- `lib/screens/journey_screen.dart` (~80 lines: the door state and veil, a words-only transit, the district caption) and `lib/screens/world_map_screen.dart` (5 lines, the crumbs filter). `app_strings.dart`: three new keys next to `journey_pass_stop`.

## [1.537.0+573]

A dependency update, no gameplay change.

### Changed
- **open_filex** 4.7.0 to 5.0.0 (Dependabot), used to open a downloaded update and exported files.

## [1.536.0+572]

Saltmouth is one place on the world map, like Alster.

### Changed
- **Saltmouth on the world map:** its six districts were six world places joined by roads. Saltmouth is now one dot; the road from the White Wells and the sea lane to the storm leave from its edge.
- **Moving around Saltmouth:** the map shows the Town view for another district and the District view within one, with no world-road journey.

## [1.535.0+571]

Alster, the starting town, is one place on the world map.

### Fixed
- **Alster on the world map:** the Blind Beggar, Weaver's Alley, the family house and the town's other places were seven separate world places joined by roads. Alster is now one dot, like the later towns, and the world roads start from it.
- **Moving around Alster:** it no longer plays a world-road journey ("You pass Tallow Steps"). The map follows the move: the Town view when the place is in another district, the District view when it is in the same one.
- **The District tab after a move** shows the district, no longer the world map.

## [1.545.0+581]

A new game starts on its first scene.

### Fixed
- **New game:** it opens on "Choose who you are…" instead of the Journey map with the scene in a row at the bottom.
- **"Previously…":** the recap no longer shows on a new game. It shows only when a saved game with progress past the start is picked back up.
- **New game over a loading save:** starting a new game while the last save was still loading could bring the old save back; it no longer can.

## [1.533.0+569]

- A new intrigue, The Host's Price: the giants, the Tide-Kin, the oni and the Kindly Ones each name what they want before the crossing, and you decide who gets paid, who does not, and what that costs. Six scenes at camp in the last chapter.

## [1.532.0+568]

- A new intrigue, The Taken's Names: a clerk brings the names cut into the back of the Lantern Throne, and in the last two chapters you decide whether to read them aloud, burn them, or carry them across unread. Six scenes at camp.

## [1.531.0+567]

Chapter 7's claimants stop walling the cleric and the warrior (wave 17).

### Changed
- **The claimant fights** (Vane, Tallis, Morrow): the enemies' Tide stops at level 6, each claimant heals itself at most once, and the claimants lose their resists (they keep their weaknesses). Tallis has 77 health (was 72), Morrow 148 (was 108). Claimants won by the cleric: 8–18% → 31–38%; by the warrior 18–35% → 30–36%; every claimant inside its band. Chapter 7 is won 56–58% (was 52–55%).
- **The playthrough simulator** now plays the enemies' Silence, Hex and Curse as the fight screen does (it skipped them before). With them counted, the clan champions read 39.9% won in the simulator (45.8% before; floor 38%): that is the honest figure, not a change to the champions.

## [1.530.0+566]

- Your Devoted companions now have a scene of their own at camp: eight short scenes, one each for Kelda, Sable, Maren, Liora, Vess, Grosh, Tobin and Malrik, offered once they have grown devoted to you. What you answer is remembered at the muster.

## [1.528.0+564]

Wave 17 UX, item 2: the sea fight's entrance and its spoils, on Core's `shipHasEntranceCard` (v1.522).

### Added
- **An entrance card before a sea fight** (`voyage_screen.dart`, `fight_entrance.dart`): a sea beast, the void barge, and any ship the data marks `entranceCard` (the corsair brig, the Inquisition cutter; the skiff has none) is announced before the fight: the hull or the beast sails in from the right over the waters of the crossing, with its name and the first sentence of its description, 1.2 s, a tap on the card ends it, reduced motion shows none. The card takes a picture of its own (`FightEntrance.art`) and the sea scene a `showShip` switch, so the card shows only what she meets, not the Eel.
- **The spoils over the next day:** a won sea fight counts up its gold and XP and drops in the part taken by boarding and the chapter's rare material (the strip of the land fights, `fight_spoils_strip.dart`) above the route strip of the next day, and over the harbour at the end of a voyage. It clears when the next day is acted on.
- Picture: `docs/ux-shots/sea-fight-entrance.png` (the Brinejaw, the Corsair Brig). Test: `test/sea_fight_entrance_test.dart`.

### Not tested
- The spoils strip is tested on its own (v1.517) but not through a whole won sea fight, which needs the ship battle played out; its wiring is the one place a bug could hide.

### Touches another session's area
- `lib/screens/voyage_screen.dart` (shared): the card around the battle panel, the spoils state and strip (about 70 lines). `ship_battle_panel.dart` is not touched.
## [1.527.0+563]

Camp errands: a scene can be offered from whichever chapter camp the party is at, and bring the party back to it. Nothing changes on screen until Narrative's loyalty scenes use it.

### Added
- **Camp errands:** a story node marked `campErrand` is listed on every chapter camp page, after the camp's own choices, whenever its show/hide flags pass. It does not count toward the camp's choice limit. Its label is `campErrandText` (`campErrandText_fr`).
- **Back to camp:** a choice marked `returnToCamp` leads to the camp of the chapter the party is in.

## [1.526.0+562]

- A new intrigue, The Lantern-Bearer's Will: a sealed page names an heir who is none of the three claimants. Six scenes from Rimewell to Greyhithe, and five ways to settle it.

## [1.525.0+561]

- Four events for the Glass Shore: the glassed dunes, a wrecked hull, a well from a drowned coast and the pull of the tear (not drawn yet).

## [1.524.0+560]

Wave 17 UX, item 5: the party's own faces, as a stand-in until the user's sprite art arrives.

### Added
- **Each companion has a face of their own** on the land walk and on the Eel's deck (`lib/widgets/side_view/party_look.dart`), over the cloak colour they already had: the skin of their people, the hair, a hood, a veil or a helm, a dwarf's beard (Kelda and Brother Tobin), an orc's tusks (Grosh and Malrik), the elf's pointed ears (Liora), the voidkin's grey-violet skin and white hair (Vess), Sister Maren's white veil, Sable's black hood. A companion added later gets a face made from their id (the same each time) until the table names them. The hero is unchanged.
- **No portrait art to crop:** the proposal said "crop the portraits", but the repository has no companion portraits (only the enemies' and the hero's walker); the looks are set here by race and profession instead. When the `companion_<id>` sprites come, this file is what they replace.
- Picture: `docs/ux-shots/party-faces.png`. Test: `test/party_look_test.dart` (every companion distinct, the marks follow the race, the fallback is stable, every group paints on the land and the deck).

## [1.523.0+559]

Wave 17 UX, item 1: the hour on the roads and at sea, on Core's `dayPhaseProvider`.

### Added
- **The land crossing and the voyage follow the hour** (`lib/widgets/side_view/kit_hour.dart`): nothing by day; a thin warm wash at dawn, a violet one at dusk, a deep blue one at night, the same as the town plan's, so a place reads the same hour on the plan and on the road to it. Stars come out in the sky at dusk (a few) and at night, laid right behind the hills so none shines through a mountain or a headland. The wash is a new `overlay` of `SideViewScene` (painted over the actors, under the weather).
- **The hero carries a lantern on the Eel's deck** after dark, with a small warm halo, on every hull.
- The phase is read from `dayPhaseProvider` in `land_crossing_screen.dart` and `voyage_screen.dart` (the day's scene and the harbour); a scene given no phase stays at noon.
- Picture: `docs/ux-shots/hour-on-roads-and-sea.png`. Test: `test/hour_roads_test.dart`.

### Not done
- The fen's lantern, the shelter's lit window and the lighthouse are drawn under the wash, so at night they are dimmed with the rest rather than burning brighter. They would need the kits to take the hour; left for a later pass. The sun (desert, ruins) is only dimmed at night, not removed.

### Touches another session's area
- `lib/screens/land_crossing_screen.dart` and `lib/screens/voyage_screen.dart` (shared): the phase read and its passing, about 8 lines.

## [1.522.0+558]

Hooks for wave 17's sea fights and loyalty scenes. Nothing changes on screen yet: UX and Narrative build on them next.

### Added
- **Sea-fight entrance card:** `shipHasEntranceCard` is true for every sea beast, the void barge and named raiders (the corsair brig and the Inquisition cutter), false for skiffs; an `entranceCard` flag in enemy_ships.json overrides it.
- **Loyalty flags:** `devoted_<companion>` is set the first time a companion's approval reaches Devoted and stays set; `ally_<companion>` is held while a companion is recruited. Old saves get both on load.

## [1.521.0+557]

Wave 17 UX, item 4: a sweep of the wave 16 screens at a narrow width and large text.

### Changed
- **The land crossing's bar keeps its numbers whole** at large text on a narrow phone: the health bar shrinks (from up to 96 px) instead of pushing the figures off the edge at 320 px and text ×1.6. Nothing changes at normal text.

### Added
- **`test/ux_sweep_test.dart`:** the entrance card, the spoils strip, the deck crew with its speech bubble and the sea arrival, the land crossing, and the ward sheet with its mark and the Banish card, each at 320 and 390 px wide, text ×1 and ×1.6, in English and French, with and without reduced motion (the app's own fonts are loaded, as in `qa_fight_tips_real_font_test.dart`; the test font is far wider). No overflow in any; with reduced motion the entrance card shows none and the spoils are whole at once. The crossing's bar was the only thing that did not fit.

## [1.520.0+556]

Wave 17 UX, item 3: the ruler's colour on the crossing, and a list of the towns that changed hands.

### Added
- **The crossing says who holds the road:** a crossing on land a clan holds (`LandCrossingScreen.ruler`, from Core's v1.512) wears the clan's colour in a band under its title and has a small "Held by the Compact" line, with the clan's flag, over the scene (also on a short phone, where the scene is left out). A road no one holds has neither.
- **The layers sheet lists the towns that changed hands** (`lib/widgets/handover_list.dart`): the town, the old ruler's flag and name, an arrow, the new ruler's, for the player who missed the toast of v1.503. It keeps the last eight since the player last looked, newest first; it is this session's only (it is not saved), and draws nothing when nothing has changed.
- Strings: `crossing_ruler`, `town_handover_title`, `town_handover_no_one`, EN and FR.
- Picture: `docs/ux-shots/ruler-and-changes.png`. Test: `test/ruler_changes_test.dart`.

### Touches another session's area
- `lib/screens/land_crossing_screen.dart` (shared): the band, the line (about 40 lines). No other open PR touches it.

## [1.519.0+555]

- Your companions now have something to say at sea: each of the eight has three lines about the deck, the water and the crossing.

## [1.518.0+554]

Wave 16 UX: the sea as the land is now, on Core's `speakUpAtSea` (v1.506).

### Added
- **The party on the Eel's deck** (`lib/widgets/side_view/deck_crew.dart`): the hero and the companions of the party (the same `walkingPartyProvider` the land walk uses) stand on her deck in the sea side view, small, on the rail line of whatever hull she is (all fourteen), riding the swell with her. The hero is in red with a pale hat; each companion keeps the cloak colour they have on the land walk. They look round now and then, and crouch in a squall.
- **A companion speaks up as a voyage casts off:** the voyage screen calls `speakUpAtSea` once the day's picture is on screen, and the words show as a bubble over that companion's figure for seven seconds. Core's rule keeps it to once a chapter; until Narrative writes the lines nobody speaks.
- **What she meets sails in from the right edge** over a second and a half (a raider, a derelict, a beast, a sighting), as the land's encounters walk in from the left; the gulls and the harbour stay put, and reduced motion shows it in place at once.
- Picture: `docs/ux-shots/sea-crew-on-deck.png`. Test: `test/sea_crew_test.dart` (every hull, the arrival, the bubble over a voyage).

### Touches another session's area
- `lib/screens/voyage_screen.dart` (shared): the crew passed to the two scenes, the `speakUpAtSea` call and its bubble (about 60 lines). No other open PR touches it.

## [1.517.0+553]

Wave 16 UX: the fight's entrance and finish, on Core's `hasEntranceCard` (v1.506).

### Added
- **An entrance card** (`lib/widgets/fight_entrance.dart`): a boss, or a foe `enemies.json` marks `entranceCard`, is announced before the fight opens. Its pixel portrait slides in from the right with its name and the first sentence of its description, holds, and fades away, 1.2 s in all; a tap on the card ends it. Reduced motion shows none; test fights and lessons show none. The card takes no touch outside itself, so the setup below is never kept waiting.
- **A spoils strip** (`lib/widgets/fight_spoils_strip.dart`): once a fight is won, a strip over the log tallies the spoils as they land: the gold and the XP count up, then each item drops in. It shows the numbers the fight already settled; reduced motion shows it whole at once.
- Picture: `docs/ux-shots/fight-entrance-finish.png`. Test: `test/fight_entrance_test.dart`.

### Touches another session's area
- `lib/screens/fight_screen.dart`, `lib/screens/fight/fight_view.dart` and `lib/screens/fight/fight_rewards.dart` (shared): a `_withEntrance` wrapper and its import, a `_spoils` field set where the victory is logged, and the strip placed above the log ticker (about 30 lines in all). No other open PR touches them.

## [1.516.0+552]

Clan power moves: wars swing harder, fallen clans regroup, and the story's choices and upheavals shift the map (wave 16).

### Changed
- **War swings:** taking a place in war gives the taker 5 power and costs the loser 8. Seats fall to war only at the turns of chapters 6 and 7, and only to a clan 25 stronger. The Dominion's seat, Candlehold, never falls (chapters 7 and 8 need it).
- **Fallen clans regroup** 5 power a chapter, up to 20; one that rises back to Rising takes its seat back.
- **The returned's taking** (chapter 3) leaves the Dominion and the Mire Hostile rather than at war.

### Fixed
- **The Wrack vote's result** now comes only to those who voted. Before, every player in chapter 5 got the "refused" result (the Dominion −8, the Spire Stair to the Compact).

50-run clan study: the Mire ends a run at 0 in no run (34 before); its seat falls in 20 runs (34), Emberwick's in 10; the patron falls in 1; the lead clan changes in 41 of 50 runs. Fights hold: professions within 5.9 points, bosses won 50.1% on average, every boss inside its band.

## [1.515.0+551]

Wave 16 UX: the town at the hour, on Core's `dayPhaseProvider` (v1.506).

### Added
- **The city plan and the district view follow the hour** (`city_chart_painter.dart`): a warm wash at dawn, none at noon, a dusk glow, a cold night wash. At dusk and night the windows and lanterns of the buildings are lit, and the pins of services that are open glow.
- The phase comes from `dayPhaseProvider` (the saved watch) through `city_chart_screen.dart` and `journey_screen.dart` (`phase:`); a chart given no phase stays at noon.
- Picture: `docs/ux-shots/town-at-the-hour.png`. Test: `test/city_hour_test.dart`.

### Touches another session's area
- `lib/screens/city_chart_screen.dart` and `lib/screens/journey_screen.dart` (shared): one `phase: ref.watch(dayPhaseProvider)` line and its import each.

## [1.514.0+550]

Wave 16 UX: the ward card and the Journey mark, on Core's warding rules (v1.508).

### Added
- **Ward the road from the Banish power** (`lib/widgets/ward_sheet.dart`): with a hunting clan to ward and charges to spend, Banish opens a sheet that lists the clans that hunt you and the lengths on offer (1, 2 or 3 charges, 3 / 6 / 9 roads); a length you cannot pay is dimmed. It works with no card selected, and the roll dialog gets a ward option under its divider. Banish stays greyed when there is no hunter and no card.
- **A mark on the Journey** (`lib/widgets/ward_mark.dart`): a small chip under the level chip on both map placements while a ward runs, naming the clan and the roads left; it goes when the ward ends.

### Touches another session's area
- None beyond widgets: `roll_power_row.dart` and `weather_chip.dart` are UX's. `test/roll_power_row_test.dart` overrides `wardTargetsProvider` with an empty list.

## [1.512.0+548]

Land crossings for the middle chapters, shaped by who holds the land (wave 16).

### Added
- **Three new crossings:** the fen after landing at the Drowned Stair (chapter 4), the frost road from the reliquary to the heart (chapter 5), and the climb up the Lantern Cliffs to Candlehold's gates (chapter 7).
- **The land's ruler:** on the chapter 4 and 5 roads, about one day in three brings the event of the clan that holds the land, as a friend, a neutral or a foe by your standing with it. The road changes hands when the towns around it do. Chapter 7's cliffs stay mild: only the salt wind and the tide stair.
- A crossing costs about 2–10% health; attempt wins by chapter move by under 1.5 points, every boss inside its band.

### Changed
- When leaving camp by sea for a place with a crossing, the crossing now plays after the landing.

## [1.511.0+547]

Thirty events for the roads of the middle chapters (not drawn yet).

### Added
- **18 ruler events** (English and French), one for each main clan and each band of your standing with it (Friend and up, Neutral, Hostile and down): the Dominion’s Writ toll, the Vigil’s checkpoint, the Compact’s forge-cart, the Mire’s reed guide, the Crows’ marked crate, the Penitents’ name wall. Each carries a `ruler` and a `band` for Core’s land routes to pick by.
- **12 biome events:** frost (the pilgrim’s cairn, the rime fall, the hound track, the bell on the road), fen (the reed lantern, the sucking mud, the drowned cart, the child in the reeds) and sea cliffs (the wrecker’s lamp, the salt wind, the gull colony, the tide stair).
- Data only: the routes that draw them are Core’s (next).

## [1.510.0+546]

Wave 16 UX: the land crossing has a backdrop for frost, fen and sea cliffs.

### Added
- **Three new side-view scenes** for land crossings, keyed on the route's terrain (`frost`, `fen`, `sea_cliffs`, the biome ids): a pale cold dawn over white peaks and snowed pines with a pilgrims' cairn, ending at a shelter with a lit window and a thread of smoke; a grey-green dusk over black pools and reed with a boardwalk, ending at a lantern on a post that bobs; and a bright salt morning over headlands with gulls and the sea below, ending at a lighthouse. The goal comes nearer as the days pass, as in the desert and the ruins.
- **Their weather:** snow falls over the frost, fog drifts over the fen and the cliffs; a sky's own weather still wins.
- Core's routes for these biomes name their terrain exactly `frost`, `fen` or `sea_cliffs`; until a route exists the scenes are not seen.

## [1.509.0+545]

Clan power moves with the story.

### Changed
- **19 story choices carry power** (3 to 8 points, `politics.power`): selling a Keyholder’s key, holding the Spire’s wall, cutting the Lantern-Bearer’s standard free, waking the Court, carrying or refusing the Tribunal’s vote, the Crows’ smuggler run, telling the truth about the Vigil’s spear, returning the master hammer, sheltering the Mire’s child or giving her up, breaking the relic, warning the Keyholders. The winners and losers on the same choice move opposite ways.
- **Two upheaval events:** *The vote reaches Candlehold* (as chapter 5 opens: Cinder Row goes to the Dominion or the Spire Stair to the Compact, by what you did with the vote) and *The Conclave counts* (chapter 7: how you came up the cliff moves the Dominion, and by force, the clan behind your gate takes the Lantern Hall). The Conclave’s swings are full size while some clan stands at 50 power or more, and half size, with no place changing hands, when none does.

## [1.508.0+544]

Warding the road: the Warding Cairn's Banish can hide your trail from a clan that hunts you.

### Added
- **Ward the road:** spend 1 / 2 / 3 Banish charges to ward a hunting clan (a rival at Hostile or Hunted, or the nemesis) for 3 / 6 / 9 roads at rest. While warded, that clan's hunters don't roll on the road. Alignment hunters, betrayals, the nemesis's champion and the seat crisis are not wardable, and standing never changes. When a ward runs out, the coast news says so. The choice on the Banish card and the mark on the Journey come in UX's next PR.
- **Simulator:** wards the nemesis for 6 roads when it has 2 charges or more. Nemesis hunters a run 1.42 → 1.23 (seed 7); attempt win rates move by under 1 point for every profession.

## [1.507.0+543]

Wave 16 UX, item 1, second step: two more sheets use the shared parts.

### Changed
- **The offer's confirm dialog** ("Take the gift?") is built from the shared sheet parts: the title, "Offered by" as its italic line, the standing and risk lines, and the main button with Back under it. Same words, same keys; it scrolls on a short phone.
- **The skill sheet's header** (the skill's pixel icon, its name, "step 2 of 5 · known") uses the shared header.
- **Three cosmetic notes from QA's v1.502 pictures.** The camp build sheet's title lines up with its text (it started 8 px in); the temple row's small "Blessing" label is set in the body face (the pixel face read "Glessing" at 320 px); and the build sheet's gold need reads "Or 900/1200" on one line.
- Not moved: the face skill choice sheet keeps its own layout, since its pick-then-set bar does not fit the shared row.

## [1.506.0+542]

Hooks for wave 16's look and story work. Nothing changes on screen yet: UX and Narrative build on them next.

### Added
- **Hour of day:** `dayPhaseProvider` (dawn, day, dusk, night) and `hourOfDayProvider`, read from the saved world clock that the road, walks, voyages and rests already move.
- **Fight entrance card:** `hasEntranceCard` is true for every boss and for any foe with the new optional `entranceCard` flag in enemies.json.
- **Sea remark:** a new `atSea` remark kind and `speakUpAtSea`, at most once per chapter, silent until lines are written.
- **`anyPowerAtLeast`:** a politics event condition that holds when any main clan's power is at least N.

## [1.504.0+540]

The three hardest late bosses lose a little health, so the boss curve is back on target with the simulator's honest gift picks (option B4, `docs/simulation/boss-mean-options.md`).

### Changed
- **The Sovereign** has 66 health (was 77), **the Tear-Herald** 52 (was 58) and **Claimant Morrow** 108 (was 121). Bosses won on average, seeds 7 / 11 / 23: 49.4 / 48.5 / 48.5% → 51.1 / 50.9 / 50.3%. The Sovereign is won 38–40% (was 25–29%, floor 23%). Every boss stays inside its band; chapters 1–6 and the champions are unchanged.

## [1.503.0+539]

Wave 16 UX, item 4: a town changing hands is seen.

### Added
- **Towns that change hands.** The world chart remembers, per save, who ruled each town when it was last looked at. When a town's ruler is another by the next look, its tint fades from the old ruler's colour to the new one's over a second and a toast says so ("The Compact now holds Candlehold.", "No clan holds White Wells now.", or "3 towns changed hands."). A first look, an old save and a town never seen before change nothing; with animations off the tint just changes.
- English and French strings `town_handover_to`, `town_handover_none`, `town_handover_many`.

### Changed
- The save gains `seenTownRulers` (town id to clan id); old saves load with none.

## [1.502.0+538]

Wave 16 UX, item 1: one set of parts for the small sheets.

### Changed
- **Shared sheet parts.** The camp's build sheet, the town's service sheet and the temple rows now share a header (icon, title, one italic line), a row (icon, title with an optional small label, price, lines), a price chip and a button pair (`lib/widgets/sheet_kit.dart`), so a wrap bug on a 320 px phone is fixed once.
- **Temple rows.** The price is a gold chip on the line under the name (it was a "75 gold" text line); a row that cannot be bought says why, as before.
- **Camp build sheet.** A house you can build names its cost in the sheet (the same chips as its card) and the main button carries the price ("Build · 280 G").
## [1.501.0+537]

Chapter 2 gets a little easier, closer to the difficulty curve.

### Changed
- **Ordinary enemies' health floor** in chapter 2 is 1.80 (was 1.98). Bosses keep their own floor. Encounters won within three tries in chapter 2, averaged over seeds 7, 11 and 23: 86.0 → 87.2%. Every boss stays inside its band. Chapter 7 is unchanged: lightening its ordinary fights moved nothing, because its claimants decide it and sit on their target.

## [1.500.0+536]

The playthrough simulator plays the seat crisis and keeps its gifts to the patron, like a player would. No game numbers change.

### Changed
- **Simulator, seat crisis:** when the patron clan's seat is hunted, the simulated party defends it if healthy and wins the fight, pays if it has the gold, else refuses — through the same scene and rules as the app. Runs count crises held, lost, paid and refused.
- **Simulator, gifts:** the party takes risky gifts from its patron and the patron's allies; another clan's card only when it fills an empty die face.
- **Clan study (50 runs) before → after:** Vigil end power 31.6 → 46.0, Crows 65.3 → 45.0, Dominion 78.7 → 73.3; patron falls 3 → 3. Bosses won 48.4% on average (52.9% before), every boss inside its band. Full table in `docs/simulation/clan-power-50-v1.500.md`.

## [1.499.0+535]

The cleric catches up with the other professions.

### Changed
- **The cleric** deals 5 base damage instead of 3. Encounters won within three tries: 65.0 → 70.8 (seed 7), 63.4 → 69.0 (seed 11), 62.2 → 68.6 (seed 23); the other professions are unchanged, bosses are won 52.9% on average (51.4% before), every boss inside its band.

## [1.498.0+534]

Two small town and offer-hall touches from the read-throughs.

### Changed
- **Temple sheet.** A clan-ruled temple shows its keeper's line in italics under the title, and the blessing row is titled with the clan's blessing name ("The First Lantern's ward") with "Blessing" as the small label above it. The neutral shrine keeps the plain title. No new strings: both texts were already in the clans' data.
- **Offer hall.** Between offers the hall kept an empty dark box with a bare spinner; it now keeps the last card, dimmed and not tappable, with the spinner over it. The first load, with no earlier card, still shows the bare spinner.

## [1.497.0+533]

The professions closer together, the bosses back to a fair fight.

### Changed
- **The mage's calling path (Arcanist)** gives INT 4 and CON 1 instead of INT 2, WIS 2 and PER 1; the mage starts with 2 more max health.
- **The Skirmisher path** (rogue and ranger) gives DEX 3, PER 1 and CON 1 instead of DEX 2, PER 1, LUCK 1 and CON 1; the rogue starts with 5 more max health.
- **Bosses** have about 5% more health (the shared boss health scale 1.15 → 1.21), and Claimant Vane 79 instead of 74.
- Encounters won within three tries, seed 7: warrior 70.7 → 69.9, mage 60.1 → 65.8, rogue 59.9 → 66.1, cleric 66.4 → 65.0, ranger 69.0 → 68.7. Bosses are won 51.4% on average (51.1% before).

## [1.496.0+532]

Wave 14 remainder: the player can take the camera during a move.

### Changed
- **Journey, the move on the world chart.** Dragging, pinching, or pressing the zoom or pole buttons while the party walks takes the camera: it stops following and stays where the player put it for the rest of the move. The recentre button lights while the camera is the player's, and tapping it gives the camera back to the party.
## [1.495.0+531]

Wave 15 UX, part 2: towns wear their ruler's colour.

### Added
- **Town tints.** On the world chart each town gets a soft halo in its ruling clan's colour, with the clan's accent as a thin ring; on the city plan the districts take a faint wash of the ruler's colour and a stronger outline. Neutral and mixed towns stay plain. Colours come from Core's `townRulersProvider`.
- **"Held by {clan}"** row on a town's Journey card (or "Held by no one" / "Held by several").
- English and French strings `town_ruled_by`, `town_ruled_none`, `town_ruled_mixed`.
- The Compact and the Crows read close in colour (measured in Lab); rather than change either clan's colour, the outline is stronger and the "Held by" line names the ruler.

### Fixed
- **Offer banner, "The Wayfarer".** The name was cut with an ellipsis at 320 px; it now scales down a little to fit on one line.
- **Build sheet, gold need.** The gold row's label was a bare "G" above the count, which read as a stray letter at 320 px in French; it now says "Gold" / "Or".
## [1.494.0+530]

Companions react to the wave 15 moments.

### Added
- **Companion remarks (English and French):** two lines for each of the eight companions, in their own voice, for building the Parley Tent, the Bone-Caster's Hut, the Warding Cairn and the Star Well; for accepting a risky gift and for winning it or losing it (health, gold or the stat curse); and for the temple's Mending and Blessing. 88 records, data only; the eleven kinds are Core's (v1.493).

## [1.493.0+529]

The party speaks up at wave 15's moments.

### Added
- **Eleven companion remark kinds:** building the Parley Tent, the Bone-Caster's Hut, the Warding Cairn or the Star Well; taking a risky gift, and the die's verdict (the gift, health, gold or the curse); mending and a blessing at a temple. One companion in the party with lines for the moment says one, the one who spoke least recently first, in the same bubble as a shared drink. The lines themselves are Narrative's, in the next release.

## [1.492.0+528]

Every indoor scene has its room (101 of 101).

### Changed
- **The last three seated in their buildings:** `5200_house_returned` (the long room under the hill), `2015_informant_trap` (the informant's warehouse) and `5100_clan_dominion_1_lit` (the cliff light's lamp-room), so the Journey opens on each room's plan.
- **Two fail notes** (English and French) for the rolls that now move the party: reading the informant wrong, and the wind taking the flame on the climb.

## [1.491.0+527]

The roll buildings and the town sheets read alike in both languages.

### Changed
- **House names:** "Bone-Caster’s Hut" with a curly apostrophe, and the French names capitalised like the other houses (La Hutte du jeteur d’os, Le Cairn de garde, Le Puits aux étoiles, La Tente de pourparlers).
- **Strings:** "Harbor" (not "Harbour") on the town sheet; the French "banish" lines no longer have to agree with the gender of the thing banished ("On écarte {name} pour {draws} tirages.", "À l’écart, {n} tirages"); a curly apostrophe in the Roll hint. Text only, keys unchanged.

## [1.490.0+526]

The town temple opens: mending and a clan's blessing.

### Added
- **Mending** (from chapter 2, once a day): the whole party back to full health, for 20 × the chapter in gold. Mana stays as it is and no day passes. The tavern stays the free rest, at the cost of a day.
- **A blessing** (30 + 30 × the chapter in gold): for the next 3 fights, the ruling clan's host effects and a block of 1 for the whole party at the start; a temple no clan holds gives +3% max health instead. One at a time; the first blessing from a clan each chapter raises standing with it by 1.
- Prices follow the standing with the temple's ruler, as clan shops do (×1.40 Hostile to ×0.75 Sworn); a clan that hunts you refuses you. No curse is lifted.
- Each clan's temple name, blessing and lines (Narrative's texts, EN/FR).

### Changed
- **Claimant Morrow** has 121 max health instead of 112: the blessing could still be running when he is met after the chapter 7 hub.
- **Forcing the way into a champion** leaves it at 80% health instead of 85% (the champions' curve sat on its floor).

## [1.489.0+525]

Wave 15 UX, part 1: the risky gift's die and odds, the roll powers as cards.

### Added
- **The risky gift's d20 reveals itself.** After Accept, the die tumbles in a dialog, lands on the saved number, shows the sum with Luck and a verdict ("The gift is yours." / "A price to pay."); Next goes to the result card. With animations off the die is set down at once.
- **The odds as a bar** on the risky card: gift in gold, price in red.

### Changed
- **Roll powers** (Reroll, Banish, Raise) are small cards with an icon, the name and the charges as pips (then "×N"); dim when they cannot act; Raise shows its progress to the next charge. Behaviour is unchanged.
- English and French strings for the die dialog (`offer_risky_roll_*`).
## [1.488.0+524]

The last indoor scenes get their rooms on Core's side.

### Added
- **Two buildings:** the informant's warehouse behind Saltmouth's landward gate, and the lamp-room of the cliff light at Wrack's End (Narrative's names and blurbs, EN/FR).

### Fixed
- **Kindly Hill:** the way of `5200_house_returned` stands in the hall district, where its long room is.

Narrative then seats `5200_house_returned`, `2015_informant_trap` and `5100_clan_dominion_1_lit` in their rooms.

## [1.487.0+523]

Four more indoor scenes have their rooms (98 of the 99).

### Changed
- **Seated in their buildings:** `6010_thread` and `6010_heist_night` (the chart-keeper's chapel), `3100_house_anvil_deaf_failed` (the cold forge) and `5200` (the long room under the hill), so the Journey opens on each room's plan.
- **Two fail notes** (English and French) for the rolls that move the party: the tenth sign gone wrong at the cold forge, and the knife slipping on the bark-bleeder's tree.

## [1.486.0+522]

The story text keeps its room on a small phone.

### Changed
- **About four lines of the story on the smallest phone:** QA's L3 found that at 320 x 568 a scene with three choices left one line of the text. The story's window now keeps 150 px (about four lines with the card's header) before the dog's strip and the choices take any more. A screen too short for the dog's strip beside four lines and about two choices goes without the strip and its fold button; the choices scroll in what is left. Taller phones keep the strip. Measured with the app's own fonts at 320 x 568 and 360 x 740, in English and French (`test/ux_story_room_test.dart`): the window was 72 px at 320 x 568 and is now 150 px.
## [1.485.0+521]

Two bosses brought back to their curve.

### Changed
- **The Void Archon** has 76 max health instead of 73 (won about 53% at seed 7, now about 51%; target 50).
- **Maud Tallis** deals 5 damage instead of 4 and has 72 max health instead of 81 (won about 49%, now about 40%; target 40). Health alone pushed chapter 7's clash gap over its bound.

## [1.484.0+520]

The tutorial strings polished, English and French.

### Changed
- **Typography:** curly apostrophes throughout the `tut_*` strings (English and French were mixed) and no-break spaces before `:` `;` `!` `?` in the French.
- **The Rusty Eel** is masculine throughout the French tours (it was "la" in three places); "Harbor" is capitalised like the Harbor tour's title.
- **A gendered participle** about the player is gone ("blessé" became "à bout de forces"), and the shop line reads "Spend your gold on what the merchant sells."
- Text only: no key changes.
- **Two more indoor scenes seated** (`6010_lysa_dead` in the chair chapel, `6010_record` in the muniment room), now that Core's v1.482 moved their ways on the city plan: 94 of the 99 indoor scenes stand in a building.

## [1.483.0+519]

Who rules each town, for the maps to tint it in its clan's colours. Data and a provider only; UX draws it (contract: `docs/proposals/town-ruler-colours.md`).

### Added
- **Town rulers** (`townRulersProvider`, `rulerOfTown`): the 16 towns with a city plan and their 59 districts, each with its ruling clan and that clan's colour (the `color` factions.json already has) plus a darker accent. A town takes the clan that holds it, else the clan holding most of its districts (neutral on a tie); a district takes its own holder, else its town's. Follows politics as places change hands.

## [1.482.0+518]

Three camp buildings that bend the rolls: reroll, banish and raise the level's stat pick and the clans' offers.

### Added
- **The Bone-Caster's Hut** (Reroll): up to 4 charges, full when built, +1 per level. Redraws the whole set of choices; a rerolled stat pick keeps its rarity.
- **The Warding Cairn** (Banish): up to 3 charges, full when built, +1 per level. Bans a training path (stat pick) or a gift (offer) for 5, 10 or 15 draws, for 1, 2 or 3 charges; the card is replaced at once.
- **The Star Well** (Raise, a great work): 1 charge when built, +1 every 15 draws, up to 5. Lifts one card one rarity, never above Heroic and never a risky card.
- The powers never touch ability checks, combat dice, loot or the risky-gift die. Old saves load unchanged.

### Fixed
- **The Black Reliquary's plan:** the ways of `6010_lysa_dead` and `6010_record` stand in their building's district, so their scenes can open on their room.

## [1.481.0+517]

Wave 14: the move on the world chart, the town's service pins.

### Added
- **The move on the real world view:** when the story sets the party down far away, the Journey shows the walk on the world chart (the sphere or the flat chart): the traveller follows the road or sea lane between the two places, slowly (6 to 13 seconds by the length of the road) while the camera closes in on the party, follows it and pulls back out. **A tap skips it.** The words under the map (the caption and "You pass ...") stay.
- **Service pins on the town plan:** once a district is looked at, its signs show (notice board, market, tavern, temple, forge, harbour), dim when nothing opens there yet; a tap opens a sheet of what the service opens (the shops of the market or the forge, the bounty board, a night's rest, the port, or "Nothing to do here yet." for the temple).
- A scene set in one of Core's new buildings (the prison, the library, the forge) opens its own room; a test checks it.

### Changed
- Tests run a move at a third of its time (`worldMoveTimeScale`, set in `test/flutter_test_config.dart`) so the waits stay short.

## [1.480.0+516]

Wave 13: the road's party, clan banners on the skill tree, the level-up radar.

### Added
- **The walking party on the land walk:** the hero (the ronin) leads and up to two picked companions follow behind, as coloured placeholder figures until their art comes (a companion's colour stays the same every walk).
- **A word on the road:** as a walk starts, a walking companion may speak, shown as a small bubble over their figure for a few seconds (Core's `speakUpOnWalk`, Narrative's walk remarks).
- **Clan banners on the skill tree:** each skill not yet known hangs its offering clan's small banner from its ring (dim while locked); the skill sheet shows the banners of the clans that offer it.
- **Level up as the ability radar:** the Level Up screen and the pop-up after a fight open on the radar of the eight abilities (a tap on a corner says where it comes from), with the fight numbers under it and a **Detail** tab that opens the full list of rows.

### Changed
- **The enemy or NPC met on a land walk comes in from the left**, behind the party, its art mirrored to face east; the party now stands further right to leave it room.
- Tests: `walk_bubble_test`, `walk_party_view_test`, `encounter_figure_test` (left entry), `skill_tree_test`, `level_up_screen_test`.

## [1.479.0+515]

The new buildings' names and blurbs reworded.

### Changed
- **27 buildings** (the cells of the Black Hold, the green door, the Tide Cellar, the Reliquary chapels, the White Anchorage's hulls, the throne room and the rest) have their names and blurbs reworded in English and French. Text only: ids, kinds and parents are unchanged.
- **16 indoor scenes seated in their rooms:** the 7 crownings (`7590_*`) in the throne room, on the dais, and 9 scenes of the Black Reliquary in their chapels (the muniment room, the Tribunal's, the Hammer's, the chart-keeper's, the parish's), so the Journey opens on each room's plan. The French follows the game's own words (Linceul, Porte-Clefs, marteau-maître, Le Coffre des Contrebandiers).

## [1.478.0+514]

Follow-up to the Journey's world data (v1.475): the crownings seat in the Lantern Hall, and the Black Reliquary's chapels count as part of the Reliquary.

### Fixed
- **The crowning scenes (7590_*)** were seated on the Lantern Cliff (`tool/city_plans/district_seats.json`); their way now stands in the throne room's lot of Candlehold's Lantern Hall, where their text sets them.
- **The Black Reliquary's landmark** covers the whole city, not only the Reliquary Quarter, so the scenes in its Chapels and Frost Line districts stay on the same landmark (no world-chart trip between its districts).

Once the story links those 18 scenes to their rooms (their `location`, Narrative's field), 94 of the 99 indoor scenes open on a room plan.

## [1.477.0+513]

Risky gifts: a clan that doesn't trust you may still offer a better gift, at a price the die names.

### Added
- **The Parley Tent** (camp, workshops): 250 gold, 2 timber, 2 cut stone. Once built, risky gifts can be offered.
- **Risky gifts:** in about 3 in 10 offers where a suitor qualifies, at most one card is marked risky. The suitor must be a clan you stand Wary, Unfriendly or Resented with, or one whose alignment opposes yours; never a hostile clan or the nemesis. The gift is one rarity better than its roll. The card shows the odds (for example "Gift 80% · Price 20%").
- **The roll:** a d20 plus up to +2 from Luck, rolled when the offer is drawn, so a reload can't change it.
  - Usually the gift (75 to 85%).
  - Otherwise a price: 40% of max health, a quarter of the purse, or −2 to the clan's stat for two levels, shown as a Curse in the stat breakdown. A natural 1 always costs the health.
  - Each price falls back to another, so "nothing" never happens.
  - Standing with the clan rises whatever the die says.
- **Simulator:** about 3.2 risky cards seen per run and 1.1 taken, 72% of them the gift. A risky card is never taken at half health or less.

### Changed
- **The White Admiral** has 72 max health instead of 80. It sat at its band's floor (33%) and now wins about 40% at seed 7.

## [1.476.0+512]

Companions say a word on the road.

### Added
- **Walk remarks:** four short lines for each of the eight companions (English and French) for the new `walk` trigger, spoken once as a land walk starts by a companion in the walking party. Data only; the trigger is Core's (v1.474).

## [1.475.0+511]

The Journey's world data for wave 14: rooms when you walk into a building, service pins in towns, and the real road for a move on the world view. Data and providers only; UX draws them (contract: `docs/proposals/journey-world-data.md`).

### Added
- **Buildings on arrival:** 28 new buildings in geography.json (prison, temple, library, forge, hall, house, cellar, warehouse, shop), linked from the scenes that take place inside them, with a spot for the party where the text makes it clear. 76 of the story's 99 indoor scenes now open on the building's own room plan (7 before); 23 still wait at their district (listed in the contract).
- **Service spots in towns:** every town with a city plan gets fixed pins for its notice board, market, tavern and temple, plus a harbour on a quay and a forge in 5 towns, each on a real lot or square. `townServicesProvider(cityId)` says what each opens (the town's shop, the bounty board, rest, the port); the temple has no screen yet.
- **The move on the world view:** `worldLegPathProvider((from:, to:))` returns the polyline of a Journey leg in the world chart's coordinates along the world roads and sea lanes, its kind (road, sea, crossing) and stops; a straight line when no route connects the two places.

## [1.474.0+510]

The land walk knows who walks.

### Added
- **Walking party** (`walkingPartyProvider`, for UX's land walk side view): the hero first, then up to two of the companions picked for the party, in the order picked. With no companion picked, the hero walks alone. A benched, lost or departed companion does not walk. Each figure carries a sprite key (`hero`, `companion_<id>`); until the art arrives, UX draws a placeholder figure.
- **A word on the road** (`RemarkKind.walk`, trigger `walk` in Companion Remarks): as a land walk starts, one walking companion with walk lines may say one, the one who spoke least recently first, never within 3 choices of another remark. UX calls `speakUpOnWalk(ref)` once per walk and shows it as a bubble over that companion.

## [1.473.0+509]

Chapters 5 to 8 read in short paragraphs, with the key facts in bold. Needs v1.472 (chapters 3 and 4) first.

### Changed
- **Shorter paragraphs:** the long scenes of chapters 5 onward (node ids 6000 and up) are split into paragraphs of a few sentences, at a change of place, speaker or beat.
- **Key facts in bold** (`**...**`, English and French) in 189 scenes: a number, an object that matters, a deadline, a promise, a few a scene. Names are coloured by the game, not marked.

## [1.472.0+508]

Chapters 3 and 4 read in short paragraphs, with the key facts in bold. Needs v1.471 (chapters 1 and 2) first.

## [1.471.0+507]

Chapters 1 and 2 read in short paragraphs, with the key facts in bold. Needs v1.470 (the story text display) first.

### Changed
- **Shorter paragraphs:** 66 long scenes of chapters 1 and 2 are split into paragraphs of a few sentences, at a change of place, speaker or beat.
- **Key facts in bold** (`**...**`, English and French): a number, an object that matters, a deadline, a promise, a few a scene. Names are coloured by the game, not marked.
- **Fight tips polished** (the 16 one-time tips) and **`affix_armored_desc`** fixed: Armored shrugs off 1 damage, as the code does.

## [1.470.0+506]

The story text reads like a page: paragraphs, names in colour, key facts in bold, written out as you read.

### Changed
- **Names in colour:** the names of people (`npcs.json`, the companions), places (the geography) and clans (factions, sub-clans, and the clans' short names) are coloured wherever they appear in a scene's text, one colour for each kind (warm orange, teal, violet) in both themes. Found by the game from its own tables, in the language of the text, whole words and the longest first; Narrative marks nothing by hand. A description of someone ("The archivist") is not a name.
- **Bold and paragraphs:** `**key facts**` are bold, and a blank line starts a paragraph (docs/proposals/story-markup.md). A text with no markup keeps the look it had (its first sentence in bold), and the voice, the journal and the folded lines read the words without the signs.
- **A scene writes itself out, quickly** (about 260 characters a second, never over 4 s): one tap shows it all, the next goes on as before; the choices (and the Journey's Continue, which shows the rest first if pressed too early) come once the text is complete. A scene read before, Edit Mode, reduced motion and animations off show the text at once. In the story player and the Journey's scene view (page and sheet).
- A place's read mark ignores the `**` signs, so marking a scene up does not make a place you have read look new.

## [1.469.0+505]

A stat's popin on the Character radar.

### Added
- **Tap an ability on the radar:** its name (STR, DEX...) opens a sheet with the exact number, what a point of it does for this hero's calling ("Each point: +1 damage, +2% dodge", from `statPickEffects`), and where it comes from, from Core's stat breakdown: the starting score, the race, the calling, the picks (the paths named), the patron clan, the tomes, the formative memories, and "Earlier" for an old save's unexplained rest; with a total that adds up to the number. What a fight lends on top (gear, signs, titles, the Sworn boon) is a section of its own, with "In a fight: N" under the number. A line under the radar says it can be tapped. EN and FR at 320 px.

## [1.468.0+504]

A fight explains its goal, its enemy's doctrine and its situation the first time a save meets each.

### Added
- **One-time fight tips:** the first fight that shows a goal (Hold the line, Rout, Subdue), an enemy doctrine (the Dominion's Writ, the Crows' Short Con, and the other clans' habits) or a situation (Ambush, Darkness, Cramped, High ground, Shrine) explains what it means for the player, in a sentence or two on the setup screen. Several appear in one card, one after another (1/3, Next). Each one shows once per save, and none show when tutorials are off in Settings. Old saves see them all as new. The texts are drafts in English and French.

## [1.467.0+503]

The Journey's step button reads "Go" in French too.

### Changed
- **"Partir" becomes "Go"** on the selected Journey step's button, and in the two lines that name it (the map hint and the Journey tutorial). The key is unchanged; "Set out" for expeditions keeps "Partir".

## [1.466.0+502]

A skill challenge's dice can be seeded in tests. Play is unchanged.

### Changed
- **`SkillChallengeScreen`** takes an optional `random`. The story player passes it its `storyCheckRandomProvider` (in `story_player_screen.dart`), so a test that overrides that provider settles a multi-round challenge the same way on every run. With no override, the rounds roll on a fresh `Random`, as before.

## [1.465.0+501]

A scene's choices are in the scene, and the map offers only the ways that move you.

### Changed
- **The scene view holds the scene's own choices:** when the party arrives (the full page for the main story, the sheet for a place's errand) the words are followed by the choices acted out here: a card for each (a fight, a payment, a check, a decision), or in a hub a chip for each kind that opens its list. The page's button reads "Back to the map" when it has choices. The wreck's "Lash yourself to the mast" is no longer under the map.
- **The map keeps only the ways that carry the party:** pins for those, and nothing else under it. A button with a count next to Read ("Choices · 3") opens the scene view when you want its choices again. The rings on the party's mark are gone with the cards. A written detour has no map, so its cards stay under its scene.
- Closes the open `TODO(UX)` of the arrival work. Building maps on arrival is not part of this; it keeps its own version.

## [1.464.0+500]

The simulator counts the politics of a quest's turn-in, and the ranger's first chapters get a little easier.

### Changed
- **Ranger** starts with 2 more max health (`bonusMaxHealth` -2 -> 0). Chapters 1-2 within three tries: 71% -> 75%; overall 74.8% (the 75% cap stops a bigger touch).
- **Claimant Tallis** deals 4 damage instead of 5, back in her boss band (47%) with the ranger's extra health.

### Fixed
- **Playthrough simulator:** a turn-in choice's politics (standing, clan power) now apply through the app's own `applyStoryPolitics`, once per quest and choice, as in play (QA #378). Gaps the simulator still has are listed in `docs/simulation/sim-gaps.md`.
- **sea_beast_outrun_test** no longer fails about one run in nine: the voyage's rolls are seeded.

## [1.463.0+499]

Descriptions stop quoting numbers that have moved.

### Changed
- **Placeholders** instead of literal numbers in 6 spells' texts (the multiplier, the turns, the weaken), the two sets' bonus lines, the two mana skills and 8 spec variants (the mana, the heal, the share, the cleanse, the faces, the round), English and French. They fill from the entry's own numbers, so the next rebalance cannot leave a stale text.
- **Stale lines fixed** (v1.458 divided the numbers): Steady is worth 1 more, Hone gives +1, Heavy Hand +1 damage, Apothecary heals 2 more, Vigor gives +3 health, the Iron Skin charm gives +1 armor, and the Hollow Court set's thorns read as a share of the blow.
- **Two Clan Host lines reworded** for what they now do: the Compact's smiths give the party a little more health, and the oni's blows drink a little of the enemy's life.

## [1.462.0+498]

The level-up pick is framed by its rarity.

### Changed
- **Rarity frames on the pick cards:** the three cards of a level's pick share its rarity, and now show it the way the signs do: a frame in the rarity's colour (Rare blue, Epic purple, Heroic orange; Common stays quiet) that gets thicker and brighter with it, a tint on the card, a glow on Heroic, and the rarity's chip on top of each rarer card. Under each gain, what it does for this hero ("+1 damage", "+2% dodge", from `statPickEffects`), and the picked card's detail spells the whole line out ("+4 PER: +4% crit, +4% dodge, reads foes better"). The gold ring still marks the card you picked.

## [1.461.0+497]

The small effects back in proportion, dice faces with their spread again, and descriptions that read their own numbers.

### Changed
- **Effects that stayed at 1 after the ÷5 are now shares:**
  - **Strike:** an element strike gives +8% Attack damage per point.
  - **Thorns:** they return 10–30% of a blow that lands.
  - **+1 armour on a sign or title:** now +8% block chance. A blocked blow loses half. Block from every source is capped at 50%.
  - **Iron Hide:** +10% block chance a rank.
  - **Bull's Neck and Gallows Breaker:** +1 Strength (was +2).
  - **Hone:** a face takes at most as many hones as its own number.
  - **Small bonuses:** small percentage bonuses keep their fractions through a fight.
- **Dice faces keep their spread:** faces 4–7 that had all become 1 now run 1–5 from their old values. Bought dice are a real upgrade over the starter again.

### Added
- **Descriptions can read their own numbers:** spells, set bonuses, skills and spec variants accept placeholders such as `{armor}`, `{dodge}`% or `{heal}`, filled from the entry's data in EN and FR. The names are in `docs/proposals/text-placeholders.md`, for Narrative's text pass.
- **Seeded checks for tests:** story and expedition checks can be seeded in tests.

Simulated over 400 runs, fights won within three tries stay at 72.0%, and every boss and the champions stay in band.

## [1.459.0+495]

The game now remembers where each point of a stat came from.

### Added
- **A stat ledger.** Every pick, tome, patron gift and origin memory records what it added, per stat. That includes the damage and health those points bring.
- **`statBreakdown`.** It lists a stat by source: base, race, profession, level, perk, pick, tome, patron and origin. Then come the fight-only bonuses: gear, sets, signs, titles and the Sworn boon. The rows add up to the number shown. This is ready for the Character radar's stat popin, which is UX's.
- **Old saves.** Whatever the record can't explain shows as one "earlier" row.

## [1.458.0+494]

Smaller numbers, so every point counts: every fight number is a fifth of what it was, each level brings one pick, and each ability has its job.

### Changed
- **A smaller scale.** Health, damage, armour, dice faces, heals and blocks, gear, skills, spells and enemies are all about a fifth of what they were. A starting hero has about 18 to 29 health and hits for 2 to 5.
- **One pick a level, with a rarity:**
  - Every pick rolls Common (+1), Rare (+2), Epic (+3) or Heroic (+4), at 90 / 8 / 1.6 / 0.4%.
  - Each point of Luck raises the odds, up to Luck 15.
  - Rare and better add a second ability from the same path.
  - A level also gives +4 max health.
- **Each ability has its job:**
  - **The damage stat:** Strength for the warrior, Dexterity for the ranger and rogue, Intelligence for the mage and cleric. +1 of it is +1 damage. Base damage no longer grows by itself.
  - **Constitution:** +5 max health.
  - **Dexterity:** +2% dodge.
  - **Perception:** +3% block for the warrior (a blocked blow loses half). For the ranger and rogue, +1% crit and +1% dodge. It still reads the enemy's intent.
  - **Wisdom:** +1 mana (mana comes from Wisdom only); it still helps heals and shortens statuses.
  - **Luck:** crit chance and better picks.
- **Patron gifts** come every other level.
- **Story checks:** a score adds 2 + 2 × √score to the d20. A natural 1 always fails and a natural 20 always passes. Narrative's DCs are unchanged.
- **Old saves are rescaled once on load.**
  - Health, damage and armour are divided by 5, and current health keeps its share.
  - Abilities keep their first 5 points; every 5 above counts as one.
  - Unspent points become picks.
- Ship combat is unchanged.

Simulated over 400 runs, the share of fights won within three tries is 72.0% (it was 73.6%):
- **Chapters 1–2:** 86.3%.
- **Chapters 3–8:** 68.9%.
- **By profession:** 70 to 74%.
- **Bosses and clan champions:** all still in their bands.

## [1.457.0+493]

The road's strangers walk in to meet the party.

### Added
- **Encounter figures on the land walk:** at a land-crossing event with someone on the road, their figure walks in from the right (the way the party walks; the art faces west), stops in front of the party facing it, and breathes while you choose. The Inquisition patrol is Inquisition soldiers (their art); the scavengers, whose enemy has no art yet, are a plain grey placeholder figure; storms, wells, springs, the dogs and the water seller put nobody on the road (the event data names no one). With animations off the figure is already in place. One resolver, `roadEncounterFigure` (`lib/widgets/fight_sprites.dart`), so more art is one line there.

## [1.456.0+492]

The Regent of the Lantern has a face.

### Added
- **The Regent's icon:** Cassian Oriel (`claimant_vane`, the chapter 7 boss of the Lantern clan) is no longer drawn with the Hollow Court Inquisitor's picture. He is a slight, bare-faced man in tide-blue and gold, silver at the temples, holding the great Hooded Lantern on a chain (black cowl, a gold eye where the flame should be), from the look in `docs/proposals/dominion-regent.md`: no mask, no white robe, no red, so he never reads as the Inquisition's soldiers or the White Soldier. Drawn by `tool/gen_hunter_icons.py` like the hunters.

## [1.455.0+491]

Enemies with art stand in the fight, facing the hero.

### Added
- **Enemy sprites in the fight:** the user's first PixelLab characters stand on the ground below the enemy cards, facing west toward the hero (who faces east): Inquisitor-General Aurel Vane, the Inquisition Warden, the White Soldier, and the two Inquisition soldier variants (worn by the Inquisition Soldier and the Inquisition Auxiliary). They breathe, step in with their blows (the lunge the enemy cards already play), flinch when hit and fade when beaten, and stay still with animations off. An enemy with no art keeps its portrait card alone. Which enemy wears which sprite is one data table (`enemyFightSprite`), so more of the user's art is a file and a line. The originals are kept in `art/pixellab/` (not bundled); the game uses `assets/visuals/fighters/`.

## [1.454.0+490]

The hero stands in the fight, facing the enemy.

### Added
- **The hero in the fight:** the ronin of the side view (the walker) stands on the ground below the party's cards, facing east toward the enemies. It breathes while the fight waits, steps in with its blow when the hero strikes, flinches red when a blow lands on the hero, and dims if the hero is knocked out. It stays still with animations off. The art is swappable: one resolver (`heroFightSprite`, in `lib/widgets/fight_sprites.dart`) says which sprite a hero gets, and the figure is sized from its frame, so later art (by profession or race) plugs in with no change to the fight; a missing file falls back to the ronin. It takes no room: it is drawn only where the cards leave the ground free, so the dice and the controls stay where they were on a small phone.

## [1.453.0+489]

A cleared zone pays out as a reward card.

### Changed
- **Zone cleared card:** the end of an expedition (a cleared zone, an escort, a delivery) is the reward card instead of centred lines: the header in the zone's chapter colour, one row per reward (gold, the item with its rarity, materials with their counts, a die, an ally), and what changed the outcome (the cargo that arrived, a late delivery, a place found, the chapter's condition, a lead, an achievement) as notes. One button takes the party back to town.

## [1.452.0+488]

The Lantern Dominion has a boss of its own, and the second Aurel Vane is gone.

### Changed
- **Regent Cassian Oriel** (`cassian_oriel`, Dominion rank 2) is the chapter 7 boss of the Lantern Hall. The `claimant_vane` enemy keeps its id and numbers and takes his name and lore; the chapter 1 Aurel Vane is unchanged and is now the Regent's Inquisitor-General.
- **The story follows:** the Ashen Quarter's envoy, the Hollow Shore vote, the clans' arrivals, the Lantern Hall, the endings, the politics news, the Dominion intrigue and the staff's description now name the Regent. In the Hall Aurel Vane stands behind him, and kneels beside him or slips away by the back stair.
- The Dominion's court ranks move down one under the Regent.

## [1.450.0+486]

The old ways of spending stat points are gone: the picks are the only one.

### Removed
- The free stat-point pool and the 5-point build cards (and their screen). The level's picks (v1.449) replace both.

### Changed
- An old save that still had a build card on the table loads as before: the card is dropped and its unspent points are pending picks.

## [1.449.0+485]

The level's points are picks, three offers each, laid out like a clan's gift.

### Changed
- **Stat picks screen:** on the Level Up screen and in the pop-up after a fight, each point is a pick: three offers in a row (the path's icon, the gain), the picked one ringed in gold with its detail under it (the path, each stat from where it stands to where it goes) and "Take this pick" at the bottom. The rare offer, worth two points, is always the third and is drawn apart (a gold frame and a ribbon). "Stat Points Available" becomes "Stat picks left"; the pop-up says what a level gives by itself (+20 max health, +1 base damage).

## [1.448.0+484]

Arriving at a place: its scene in a sheet over the map, and a notice when you come back.

### Added
- **Arrival sheet:** after a choice, the scene of a place opens in a sheet over the dimmed map (the place's name, the words, Continue) instead of a full page. The main story and the scenes met on a detour keep the full page.
- **"You came back to …":** an errand's one-tap return to its town hub shows a small notice (the unlock card's look) that fades by itself.

## [1.447.0+483]

The family house reads as the scenes tell it.

### Changed
- **The family house's blurb** (English and French) now says only what the scenes say: a kitchen door, shutters, a back room, and a trapdoor under the boards.

## [1.445.0+481]

Stat points become picks: each point earned is a choice between three offers.

### Changed
- **Each stat point is a pick.** You choose between three one-point offers (+1 to a stat, or +10 max health) that follow your profession, your build so far, and one change of course. About one pick in eight has a rare offer worth two points: +2 to one stat, or +1 to two.
- **A level also brings +1 base damage** by itself, beside the +20 max health: picks rarely offer damage, and free points used to give about two a level.
- **Saves:** points left unspent become pending picks, one for one. A 5-point build card left on the table is redrawn as a pick.
- The free pool and the 5-point build cards are on their way out: the new picks screen (UX's) replaces them. Until it lands, the old screen still works.

Simulated over 400 runs, the share of fights won stays within 3 points of today for every profession (Cleric +5, Mage +2, Ranger, Rogue and Warrior −3 to 0). Every boss and the champions stay in their bands.

## [1.444.0+480]

The map is for moving: a choice that stays where you are keeps you in the scene, and one that leads elsewhere hands you the map.

### Changed
- **A scene's place is its "stop":** the building it happens in, else its district, else its place. A building is a place of its own: leaving the Blind Beggar, or walking home to the family house, is a move on the map.
- **The story reads on until the stop changes:** a page no longer runs you from one district to another without the map.
- **An errand's way back to its town's hub is one tap:** you come back to the hub (Smugglers' Wharf and the like) without walking the map. The game marks the return so a "You came back to…" notice can show it.
- **An action whose result is elsewhere carries you there** (a fight, a roll, a payment), as after a lost fight.
- **A village's scenes stand in its hub's district** (White Wells at the Pool, Wrack's End at the Hull-Houses, Rimewell at the Bell Square).
- **The Blind Beggar's scenes are all in one building**, and the family house is a building of its own in Alster.

### Added
- Queries for the Journey: a scene's stop, what a choice leads to (stay, map, carried, back to the hub), the main-story scenes (not a hub, not an errand, not a camp) and the services at a place (shops, rests, trainers, ports). How each looks is UX's next step.
## [1.442.0+478]

The main story's scenes and the hubs have the data the scene view and the arrival sheet read.

### Added
- **Who you face** (`facing`) on ten more main-story scenes: the bouncer at the Blind Beggar, the warhound in the alley, Vane at the docks, the High Warden at the end of chapter 3, and Aurel Vane in the Lantern Hall.
- **A question** (`prompt`, English and French) on the fourteen hubs a sheet opens on: the Wharf, the Ashen Quarter, the Drowned Cloister, the Reliquary Quarter, the Hollow Shore, the eight villages, the White Anchorage and Candlehold.

## [1.440.0+476]

The Journey's pins hang as banners, with a legend.

### Added
- **Banner pins:** a way on the map hangs as a banner in the colour and icon of what it is: main quest (gold flag), side quest (violet speech bubble), detour (ember compass), shop (teal storefront), travel (blue sailboat), rest (green flame) or plain way (grey signpost). The district view's pins hang on their buildings, and the rows and cards of the ways wear the same banner, small. Fights and rolls keep their round numbered pins.
- **The legend:** a key button at the map's top right opens a sheet that says what each banner means (English and French).
- **No "Walk on" tabs:** the row of chips to the other districts under the district's ways is gone (the chart, the Town tab and its rows still go to them).

## [1.439.0+475]

A written detour plays as a scene.

### Added
- **Detours as scenes:** while the party plays one of the written detours, the Journey's map gives way to a scene of its own: the scene's title (a star for the chapter's landmark), the beat it is at ("2 / 3"), the place the beat is set in, and the beat's words under it. The beat's ways are cards under the scene, "Leave it" the last. The ruins' side-view scene dresses the ashlands, tear and volcanic detours and the desert's the dry ones; every other biome gets a band tinted for it. Today's generated detours keep the map.

## [1.438.0+474]

Every building of the new town plans has a name.

### Added
- **Names for 177 buildings** (English and French) on the plans of the nine villages, the Black Reliquary and Candlehold.

### Changed
- **Lysa's two scenes at Wrack's End** (the rider, the black-thread parcel) are seated in the Hull-Houses and on the Lamp Path, so they have a building on the plan.
- **Three district blurbs reworded** (the Reliquary Quarter, the Gates, the Lantern Hall), English and French.
- The scenes keep their village as `location` for now: the plans seat them by district from `tool/city_plans/district_seats.json`. Retagging them made most of a village's choices read as walks between districts, which the choice-shape and champion tests do not allow.

## [1.436.0+472]

The camp and the map tell a party it is under the level the next chapter asks.

### Added
- **The level signpost:** while the party is under the level the next chapter recommends (chapter 4 asks for level 9), the camp's chapter card gets a one-line hint, "Chapter 4: level 9 advised (you: 6)", and the Journey map gets a small chip above the sky's ("Ch. 4 · lvl 9", just "Lvl 9" on a narrow screen). A tap on either reads the whole sentence and Narrative's line. Nothing once the party has the level, or when the chapter recommends none. EN and FR. Uses Core's `nextChapterLevelAdviceProvider` (#355).

## [1.434.0+470]

The fight explains its chips, and shows the blow coming.

### Added
- **Long-press the chips above the fight:** the round (and when the Tide rises), momentum (how it builds and what it gives), the battlefield condition, the weather, the goal and the doctrine each say what they do. The place rule, Tide, nudge, hex and silence chips already did. EN and FR.
- **The blow the party can read, on the health bar:** when a foe's telegraphed move is read in full (Perception), the bar of the one it is aimed at shows the part it would take off, with "−N" beside it; a long press says "after armor and block". Blows are figured one by one, as on the foe's own card.

## [1.433.0+469]

Every town now has its districts, and the villages have plans.

### Added
- **32 new districts** (Narrative's names and blurbs) for Rimewell, Greyhithe, Wrack's End, the Cove Camp, Kindly Hill, Highhearth, Emberwick, Akagiri and White Wells, which had none. The Black Reliquary gains three more (the Last Lantern, the Chapels, the Frost Line) and Candlehold one (the Lantern Cliff).
- **Village plans:** those nine places now have a plan in the District and Town views: smaller, mostly open, with three roads out. The coastal ones sit on the sea; the Cove Camp's palisade and Highhearth are walled. Every scene stands on a building in its district. The new districts are not clan holdings: clan power counts only the places it was tuned on.
- The Black Reliquary and Candlehold are redrawn on their new districts. Candlehold's Gates are unchanged, and the night's rest still happens where the clans are seen arriving.

## [1.431.0+467]

### Changed
- The Crows' collector, the nemesis champion, is now **Mireille Sorrel** (was Sable, which she shared with the rogue companion). Names only, EN and FR, in `npcs.json` and `enemies.json`; the ids are unchanged.

### Added
- A word of warning at the turn from chapter 3 to chapter 4: the camp's old fire-keeper tells the player the Court does not bargain with the weak, and that the Drowned Stair is best gone down stronger. EN and FR. (Core's recommended-level field for the chapter carries the number.)

## [1.430.0+466]

Chapter 4 says how strong you should be before you go down.

### Added
- **A recommended level for chapter 4:** chapter 4 now recommends level 9 (`recommendedLevel` in `chapters.json`). The game can tell whether the party is below it, and by how much, for the chapter after the one the story is in (`nextChapterLevelAdviceProvider`), or for any chapter (`chapterLevelAdviceProvider`). Narrative's warning line (`recommendedLevelNote`, EN and FR) rides along. Showing it is UX's part.

### Changed
- **Chapter 3's side quests pay more XP**, about a fifth more: `q_ch3_marens_penance` 80 → 100, `q_ch3_groshs_price` 65 → 80, `q_ch3_reckoning_wall` 60 → 75, `q_ch3_glass_from_the_terraces` 70 → 85.
## [1.429.0+465]

The game pushes back after the camp: from chapter 3 on, every profession wins about 70% of its fights within three tries, down from 82–97%. Chapters 1 and 2 stay gentler.

### Changed
- **Enemies are stronger**, most from the camp (the landfall that opens chapter 3) to chapter 5. Chapters 1 and 2 get only a lighter raise, so the opening still teaches: about 90% of fights won within three tries and 70% on the first. Chapters 6 to 8 are a little lighter again, since the chapter curve already climbs there.
- **The professions are closer together.**
  - The Mage hits less hard: base damage 6 → 1, Intelligence 4 → 1, health −15 → −20.
  - The Cleric is sturdier: base damage 0 → 5, health 10 → 35.
  - The Warrior: base damage 3 → 4, health 20 → 30.
  - The Ranger: base damage 3 → 1, health 0 → −10, Perception 4 → 1, Luck 2 → 0, Dexterity 3 → 2.
  - The Rogue: base damage 4 → 2.
- **Five late bosses re-tuned** so each is still won about as often as before: the Void Archon, the White Admiral, the Void Sovereign and Claimant Tallis are a little stronger, the Tear-Herald a little weaker. The six clan champions get about an eighth more health and +1 damage, so they are still won about half the time.
- **A lost fight still gives 30% of its XP**, so a struggling character doesn't fall further behind.

### Added
- **A rest before the Lantern Hall:** the rest scene refills provisions and mana.
- **The simulator counts first-try wins** for each chapter.

Simulated over 400 runs, by profession:
- **Chapters 1–2:** 81–95% of fights won within three tries, 55–83% on the first try.
- **Chapters 3–8:** 63–73% within three tries, 37–44% on the first try.

Before, it was 82–97% within three tries and 70–84% on the first try, over the whole game. The tables are in `docs/simulation/difficulty-review.md` §6.
## [1.428.0+464]

### Added
- A night's rest before the Lantern Hall (chapter 7). Every road up from the gates now passes `7515_rest`: the party sleeps on the harbour steps while the clans' fires light the cliff, then climbs to whichever Hall the claimant holds. It gives a full heal, one strong potion, and sets `rest_before_hall` (Core's engine refills provisions and mana from it). Each of the three Halls reads it back.

### Changed
- The Hall's roads: the three duplicate choices per way (one per claimant) are now one choice per way, with the claimant routing moved into the rest scene (66 choices down to 22).

## [1.427.0+463]

### Added
- Names (EN and FR) for the buildings that hold scenes in four of the six new town plans: Alster (33), the Ashen Quarter (27), the Drowned Cloister (22) and the White Anchorage (21), in `city_plans.json`. The Black Reliquary and Candlehold follow with their regenerated plans.

## [1.425.0+461]

The city chart on every stored plan, and the way back in.

### Changed
- **Every city plan Core stored draws on the town chart** (Alster, the Ashen Quarter, the Drowned Cloister, the Black Reliquary, the White Anchorage, Candlehold, besides Saltmouth): whole and by district, with or without a river, a wall, canals, bridges, a shore. A new test draws all seven, and each of their districts.
- **District names on the whole city no longer overlap**: a name slides down or up by its own height until it finds room (the Ashen Quarter's three names sat on one another).
- **A look out of a building shows the city's chart, with a button back in.** A scene inside a building keeps its room view; looking out of it now shows the chart (it showed the generated streets) and a button on it goes back in.

## [1.424.0+460]

A hub's choices on rings and chips, and a beat when one is taken.

### Changed
- **A hub's choices are grouped by kind.** A scene with more than four choices done where you stand shows, round the party's mark, one dashed ring for each kind (Fight, Talk & decide, Checks & pay) with a chip on it ("Fight · 4") and up to five of its icons, the rest a "+N"; the same chips sit under the map, with a "Ways · N" chip for the plain ways on the map. A tap on a chip or an icon opens that list in a sheet (the ring stays lit; a way lights its road on the map above), and a second tap on a card does it.
- **A beat when a choice done here is taken.** A ring in the kind's colour spreads from the party's mark and the choice's icon rises; the other cards dim meanwhile. Reduced motion skips it.
- Plain decisions and words have their own icons (balance, chat) on the cards and rings, not the road's signpost; the cards' tags (price, alignment, check, fight) now come from Core's choice tags.

## [1.423.0+459]

A feature opening is now shown, and a shut one is not in the way.

### Added
- **The unlock card:** when a feature of the ladder opens, a small "New: Quests" card slides in over the game (not during a fight), with a line on what it does, **Show me** (its tour) and **Later**. One card at a time; left alone it goes after 6 seconds. A gold dot stays on the new thing until it is first opened. Under reduced motion the card fades in place and the dot is still. EN and FR.
- **Shut things are hidden or greyed:** the ⚖ Clans & Politics button and the Character's Gifts tab are gone until they open; the Quests row (Other), the Inventory and Dice tiles and the Overview's skills part are greyed with a lock, and a tap says "Opens in chapter N". The Skills screen says the same when it is reached shut. A game off the ladder (an older save) sees everything.

## [1.422.0+458]

### Added
- The chapters 1–2 beats of the feature ladder (`docs/proposals/ch1-2-beats.md`). New scenes: a drill-sergeant's line on the quay approach where the first skill is chosen (`890_trainer`, between the ruins and the High Quay, on every road), and a Crow tally-girl at Smugglers' Wharf who says the clans will make an offer, and that it may be refused (`2015_crow_offer`). New lines at the chalked list (250), the bundle (470) and the gate's tally of who holds Saltmouth (2005). The choices that carry a feature set its `feat_` flag: `feat_quests` (250), `feat_inventory` (470), `feat_skills` (the trainer), `feat_conditions` (1140_spotted), `feat_politics` (2005), `feat_clans` (the Crow, or her words on arrival for a player who came by the wagon or the storm drain). EN and FR.

## [1.421.0+457]

The first two chapters bring the game's features one at a time.

- **A new game climbs the feature ladder:** each feature opens where the story gives it a reason, and stays hidden until then.
  - The chest after your first real fight, the street's rules in the next one, battlefield conditions after the cliff ambush.
  - The quest list at the banner's errand, the inventory at the bundle and the warm die, and skills at the trainer.
  - Standing at the Inquisition's gate, and the clans' offers at Saltmouth.
- **The trainer teaches your first skill,** a strike or a guard of your own trees (the mage's and the cleric's starting offer moves there).
- **The clans' offers** earned in chapter 1 wait for Saltmouth, then come one at a time.
- **Saved games** keep everything open, so nothing pops up mid-game.

## [1.420.0+456]

Six more towns have their plans.

- **Alster, the Ashen Quarter, the Drowned Cloister, the Black Reliquary, White Anchorage and Candlehold** now have a city plan, like Saltmouth. Their districts and the buildings where each scene happens show in the District and Town views:
  - Alster: a river city with its quay.
  - The Ashen Quarter: walled, half burned, at the Spire's foot.
  - The Drowned Cloister: on the fen, cut by channels.
  - The Black Reliquary: on its frozen river.
  - White Anchorage: above a shore of beached hulls.
  - Candlehold: on the cliffs above its harbour.
- **Walking from one town to the next** no longer leaves the Journey on the old town's district.

## [1.419.0+455]

For the in-place choices, and a difficulty review.

- **Each choice now carries what its card shows:** its cost in gold (a toll's included), its alignment shift, and where its aftermath takes you. The choices are also grouped for the map's rings: fight; talk and decide; checks and pay; and the ways on.
- **The story can say who a scene faces, the question it ends on, and what a hub's choice is about** (`facing`, `prompt`, `about`, `aboutLabels`, all optional), for the scene view and the rings.
- **A difficulty review** (docs/simulation/difficulty-review.md): win rates by profession and chapter, deaths, the bosses' bands and five proposals. Nothing is tuned yet.
## [1.418.0+454]

The Journey's choices acted out here become cards under the map.

### Changed
- **A choice done where you stand is a card, not a pin.** In a place up close, a fight, a payment, a check or a decision (Core's `choiceShape`: `here`) is a card under the map: the action's icon, the words, who you face, a "→ place" line when what follows moves you on, and one tag (a price, an alignment shift, a check, or Fight). A tap picks it and shows Go on it; a second tap does it. The map keeps pins only for the plain ways on, spread over the room the cards leave, so the labels no longer pile on the party's mark. A room's ways keep their marks.
- **No road walked for a card.** The scene that follows moves the party.

## [1.417.0+453]

### Added
- The data for the in-place display (`docs/proposals/inplace-data.md`): `facing` on 94 story nodes (who the scene is with), `prompt` / `prompt_fr` on the 226 scenes with two or more choices (the question the scene ends on), and `about` on 69 hub choices (the NPC, clan or sub-clan a choice is about), EN and FR. All optional; nothing reads them yet.

## [1.416.0+452]

Lysa's blood on the Shroud.

- **Blood on the Shroud:** if you give Lysa's blood to the Shroud, the piece wakes and gives you a boon of its own.
  - Its gift, at heroic strength: more damage when you are low on health, lifesteal and critical chance.
  - Its cost, the Void's hold on you: −12 max health.
  It is never offered by a patron.

## [1.415.0+451]

The map's places and names hold a readable size when you zoom.

### Fixed
- **Places and their names no longer shrink as the sphere comes close.** The world map is drawn at its screen size on the sphere, but its marks and names were sized as if a viewer scaled them by the zoom, so at the closest zoom they were a few pixels tall. They now keep their size.

### Changed
- **Each reached place has a plate under its mark** (at least 24 px across once you zoom in), the party's ring and the picked place's ring grow with it, and the clans' seats, villages and other features are held to about 26 px.
- **Names are at least 11–12 px with a small plate behind them**, so they read over dark and light ground; a name that collides with another is left off, the party's place, the picked one and the goal first.
- **A tap on a place hits within 22 px of it** (44 across), at any zoom, on the flat chart and the sphere. The town chart's building names are 11 px and its pins 24 px, with a slightly larger tap.

## [1.414.0+450]

### Changed
- Lysa's story. If you lose her at the house, how you lost her (knelt, fought and lost, ran) decides what the Dominion made of her. Three beats lead to the Reliquary Quarter (a fence's line on the wharf, the envoy's price, a parcel with her mask), and there she says your name before any blade is drawn. You can break her out (Brother Clement, a boss), offer the Shroud's piece (refused), swear to the Lantern for her, end it gently, fight her, lay her blood on the Shroud, or walk away. If you save her at the house, she can be taken during a raid on the camp, trade a ledger page for medicine, and offer to sew the tear shut at the Hollow Shore, which can cost her life. Vane now says plainly that he came for what the mother kept.

## [1.413.0+449]

Lysa's fate turns the Dominion's hunt.

- **Brother Clement,** the Black Hold's torturer, a boss in the Quarter's chapel when you take Lysa by force.
- **The hunt, as her fate turns it:**
  - take her by force, or give her blood to the Shroud, and the Dominion hunts you in earnest: its fighters come more often and join its fights, and Orsolya Keld comes sooner;
  - swear to the Lantern for her, and its hunt is over.
- **Claimant Tallis and the White Admiral** are a little tougher (405 and 350 health), to keep the late bosses in their bands with Lysa's new scenes.
## [1.412.0+448]

A won fight closes itself.

- **The chest opens on its own** and shows everything it holds; take it, and the fight returns to where it began after a moment, or at once on a tap. With reduced motion it returns as soon as the spoils are taken.
- **Nothing is skipped:** a level-up, a clan's offer or a hunter's mercy waits for your answer first.
- **The rewards stay with you:** they open the next scene ("Victory! +47 gold, +87 XP, …"), and the fight log keeps them.
- A defeat is unchanged.
## [1.411.0+447]

A clan's power and the land it holds, drawn.

### Added
- **Power on the clan's card.** A bar across the four tiers (Minor, Rising, Dominant, Ascendant, ticks at 25, 50 and 75) with the tier named and its value, then "Holds N places" with the places as chips (six, then "+N more"). A clan that is the party's nemesis wears a red "Your nemesis" ribbon and a red bar. The card is the one the long press, the offer's (i) and the Throne room open.
- **The Throne room's banner captions** add the clan's power tier, and "Your nemesis" for the nemesis, after the standing.
- **The land takes its holder's colour.** In the Journey the place's ground gets a faint wash and a frame in the colour of the clan that holds it now (red when it is the nemesis), following places that changed hands.

## [1.410.0+446]

Faces for the rival hunters and the nemesis champions.

### Changed
- **Twelve foes have icons of their own.** The six rival hunters (Halvard the spearman, Ysel the candle-bearer, Brodin the quarryman, Tove the deaf anvil, Sedge the returned and Wen of the Heron's Wake) and the six nemesis champions (the Dominion's Orsolya Keld, the Crows' Mireille Sable, the Compact's Hollis Reck, the Vigil's Edda Grey, the Penitents' Ash Confessor and the Mire's Heron Queen's Hand) are no longer drawn with another foe's picture. Each is a 16 × 16 sprite from Narrative's description, in the enemy icons' style, made by `tool/gen_hunter_icons.py`.

## [1.409.0+445]

The Dominion hunts you from the start.

- **Your nemesis from the first page:** your family kept a piece of the Shroud, and the Dominion wants it.
  - Its hunters come now and then from the first chapter, as a Hostile clan's would.
  - Its champion waits for chapter 4, when a lamp-boy brings its quest.
- **How it ends:**
  - your standing with the Dominion reaches Friendly;
  - you break it through its quest;
  - you take the legate's pact or back Vane for the throne.
  A clan you've crossed harder can take its place. Turn Hostile with the Dominion and it hunts you harder.
- **Saved games** take it on load, unless you're already Friendly with the Dominion.
- **Orsolya Keld,** the Dominion's champion, is a little easier (190 health, 26 damage), since you now meet her in every game.
- **The People codex** no longer lists a clan court's leaders before you meet them.

## [1.407.0+443]

### Added
- A court for each of the six clans: a way of ruling (`ruling` on each clan in `factions.json`, EN and FR) and 8 or 9 ranked people each, 49 in all. 22 existing characters are placed in the hierarchy (Aurel Vane, Hesk Morrow, Maud Tallis, the Keyholders...) and 27 new ones fill the empty ranks, among them the Lantern-Bearer, the Heron Queen and the six nemesis champions. New fields on a person in `npcs.json`: `clan`, `rank` (1 = leader), `title`, `stanceLeader`, `stancePlayer`.

## [1.404.0+440]

Your nemesis's quest now has a trail, a choice of way in, and its own ending.

- **The trail:** before the champion comes, a road leads you on its trail.
- **Three ways in** to the champion, each with a small edge:
  - **Force** (it starts at 85% health);
  - **Guile** (it is a little weaker all round);
  - **Mercy** (it starts at 90% health, and beating it this way earns +5 standing with its clan).
- **Its last words:** a champion beaten leaves a line in the fight log.
- **The news:** each clan's broken hunt has its own news line.
- **Champions** are tougher (200 health, 27 damage), so about half of the fights against them are still won.

## [1.403.0+439]

Quest complete gets the chapter's own picture.

### Added
- **One art strip per chapter** (eight, in the app's pixel look, drawn by `tool/gen_chapter_art.py`): chapter 1's harbour and the white ships, and so on through chapter 8. Their files are in `assets/visuals/chapters/`.

### Changed
- **Quest complete is card B.** The card leads with the chapter's strip under the quest's name, and gold and experience become two counters under it (the experience bar and the level stay). The rows for the item, the die and the companion, and the notes, are as on card A. An item found and a clan's gift keep card A.

## [1.402.0+438]

The place's rule, the patron's favour and the hunter's mercy, drawn.

### Added
- **Place-rule marks in the fight.** A chip for the place's rule: its omen the round before (mist, heat, rising water, holy ground, the watch's whistle), then how far it has risen (Mist ×2, Rising water ×3 with the top marked), each with a long-press tip of what it does this round. The boss gets an Enraged chip once the Tide has risen. The Tide alone has no mark.
- **Patron's favour on level-up.** The level-up pop-up names what the patron gave with the level ("Dominion's favour: +1 Strength, +5 max health") in the clan's colour, English and French.

### Changed
- **The mercy choice is a card.** The rival hunter's portrait over a band in its clan's colour, the read of their side as a chip, and two buttons that each say what they cost and give (Dominion +3, no gold, no loot / Dominion −2, the spoils are yours). Same choice and rules as before.

## [1.401.0+437]

Your nemesis sends its champion, and beating it ends the hunt.

- **A quest when a clan makes you its nemesis:** a stranger warns you that its champion is coming.
- **The champions:**
  - the Dominion's High Lantern-Bearer Orsolya Keld;
  - the Crows' Captain Mireille Sable;
  - the Compact's Master Hollis Reck;
  - the Vigil's Watch-Captain Edda Grey;
  - the Penitents' Ash Confessor;
  - the Mire's Heron Queen's Hand.

  From chapter 4, while the quest is under way, the champion finds you on the road. Each is a boss, with Narrative's words.
- **Beat the champion and hand in the quest,** and the nemesis is broken: the clan loses a tier of power, its hunt ends, and it can't become your nemesis again for two chapters.
- **The void hound has a cry of its own.**
- **Balance:** champions are won about half the time where they come (50.3%), and the boss curve is unchanged. Report: docs/simulation/nemesis-hunters.md.

## [1.400.0+436]

Clans' power shows in their offers, and a crisis can be paid in timber and stone.

- **A weak clan gives weaker signs.** A clan under 25 power offers signs up to epic; heroic signs come from stronger clans.
- **The clan that holds the place comes more often** with its offer when you are in its lands.
- **A fallen clan sends no one,** except to those who stayed of it: its survivors still come with gifts.
- **The Host:** a fallen clan joins it only if it pledged.
- **The Character tab's climb:** between equals, the stronger clan's climb now shows.
- **The crisis:** "Send timber and stone" (3 timber, 2 cut stone) now holds your clan's seat as the gold does.
- **Balance:** every profession within 1 point (slightly down); the boss curve holds. Report: docs/simulation/clan-power.md.

## [1.399.0+435]

Rewards come on one card, whatever they are (card A of the user's pick).

### Changed
- **One reward card.** A header in the source's own colour (a small label over the title), one row per reward (an icon tile, a name, a line under it, the value at the right), a note set apart in a dashed box, and one button. The rows come in one after another (with reduced motion they are simply there).
- **Quest complete, an item or materials found, and a clan's gift taken** all use it. Quest complete shows gold, experience with its bar (and the level it brought), the item with its rarity, a die, a companion who joined; the notes carry what changed the outcome (a die made for another class paid in gold, with the gold as a chip), how the quest was settled, and the party's reactions.

## [1.398.0+434]

The clan offer's popup is one block: the ring on top, and under it the clan card with the gift in it.

### Changed
- **The gift moves into the clan card.** The separate gift box is gone. Under the relations ring, one bordered block in the clan's colour: its name and your standing with it on the first line, what this banner gives (the gift's icon, name, kind, rarity and effect) on the left, the clan's radar on the right. "Take this gift" stays at the bottom.
- **The clan's words sit behind an (i).** The button beside the clan's name opens its card (the same one a long press shows), with what the clan says to you; the first time you meet a clan the button is lit. The words no longer take room in the popup.
- The alignment word ("Alignment · toward Good") stays in the block, under the gift.
- **Hold a banner for the clan's details.** A long press on a banner in the offer, on a crest of the ring, or on a standard in the Throne room opens its card: where it leans (alignment, the five axes of its gifts), what it stands for, its sub-clans, its motto and a short recap of its story. Letting go, or a tap outside, closes it.

## [1.397.0+433]

In a place a clan holds, its people join long fights.

- **Reinforcements.** From round 8, in a place a clan holds:
  - if you stand Friend or better with it, its people fight beside you, and each foe loses 5% of its health a round;
  - if it hunts you or is your nemesis, its people fall on you, and each of you loses 5% a round.
- They never join a boss's fight and never strike the finishing blow. The fight log says when they come.
- **Balance:** a gentle edge, as asked. In every fight, allies are worth up to +2.9 points and foes cost up to −2.6. Report: docs/simulation/reinforcements.md.

## [1.394.0+430]

When your clan's seat is attacked, it asks for your help, and if it falls, you choose what becomes of you.

- **The crisis.** When another clan is about to take the seat (or last place) of your clan (sworn, or your patron), a rider finds you on the road first.
  - **Defend it:** a fight with the attacker's hunter. Won, the seat holds and your clan grows stronger. Lost, you can still pay or refuse.
  - **Pay:** 40 gold a chapter. The attacker takes a lesser place instead.
  - **Refuse:** the seat falls, and your clan thinks less of you.
- **The fall.** When your clan has no place left, you choose:
  - **Bend the knee to the winner:** your standing moves to it (sworn if you were sworn), and it takes a fifth of your gold.
  - **Stay of the fallen clan:** no new oath and no patron's stats, its gifts kept, and the winner hunts you as your nemesis, until you raise a banner of your own. Then the fallen clan joins your Host.
- **The Mire has a seat:** the Mire's Court, a dry room in the middle of the Drowned Cloister.
- Narrative's words throughout, in English and French.

## [1.393.0+429]

A clan can make you its nemesis, and good and evil hunt everyone.

- **The nemesis.** The strongest clan (power 25 or more) you stand Hostile or Hunted with becomes your nemesis at a new chapter, and the news says so. It lets go only when you are back to Wary.
  - **It hunts you, sworn or not:** its fighters come on the roads at the Hunted odds, under the same cap, cooldown, mercy and betrayal as the other hunters.
  - **At war it moves first,** and goes after your patron clan's places from Hostile.
  - Its quest, coming later, will break it: a tier of power lost, and two chapters before it can return.
- **A neutral character is hunted too, lightly, by both sides:** 2% a road, rising to 6% at the edge of neutral. Before, a neutral character met no hunter at all.
- **New hunters (Narrative's six):**
  - the good orders hunt an Evil character: Ysel the candle-bearer, Halvard the spearman and the masked penitent;
  - the evil forces hunt a Good character: the cultist acolyte, the Hollow Court zealot and the void hound.

  Each comes with its battle cry and its own ambush lines, and the angels and demons keep theirs. The six are still met as ordinary foes too. A hunter now waits for its chapter.
- **The territory news in French** now uses Narrative's own wording, agreeing with each clan ("La Veille Grise est tombée", "Les Corneilles de Sel tiennent…").
- **Simulator:** 3 to 4 hunters a run at every alignment, out of about 60 roads; neutral characters meet about one alignment hunter a run. The Dominion is the nemesis in most runs (the story turns it against you). Report: docs/simulation/nemesis-hunters.md.

## [1.392.0+428]

### Changed
- `factions.json`: every faction carries `gender_fr` (m, f, mp, fp) and `nameTo_fr` ("au Dominion de la Lanterne"), so the French territory news lines agree with the clan.
- `docs/proposals/territory-texts.md`: the blurb for the Mire's hidden seat, `mire_court`, for Core's next PR.

## [1.391.0+427]

Clans now have power, and the map changes hands.

- **Power.** Each clan has a strength from 0 to 100: the Dominion starts at 60, the Crows 45, the Compact 40, the Vigil 30, the Penitents and the Mire 25.
  - Rises: taking a clan's gift (+2, +4 for a heroic one), doing a quest for it (+5), and each place it holds (+1 a chapter).
  - Falls: a chapter in which you did nothing for a clan (−5), never more than 20 under its start.
- **Places change hands at each new chapter**, at most one per clan:
  - a clan that has grown a tier stronger takes the next place it claims (Narrative's lists);
  - two clans at war fight over places, and the much stronger takes one, the seat last.

  A news line tells it, and the clan log notes it.
- **A clan can fall.** One that loses its last place falls, its power to 0, until it grows back and takes a place again.
- **Shops follow the new holder.** A town that changes hands prices by your standing with the clan that holds it now.
- **Story beats can move power and places** (`power` and `control` in a choice's or an event's politics, and a `powerAtLeast`/`powerAtMost` condition).
- **Simulator:** about 3 to 4 places change hands per run, and the clan you back ends 25 to 50 points stronger. Report: docs/simulation/clan-power.md.

## [1.390.0+426]

Groundwork for the journey map; nothing changes on screen yet.

- **What a story choice does on the map** (`lib/data/choice_shape.dart`). For each choice the game can now tell:
  - whether it takes you somewhere: stay, walk to another place in the same location, or travel to another location;
  - what kind of action it is: fight, pay, talk, sneak, attempt, evade, go or decide;
  - whether it is acted out where you stand. A fight, a payment or a decision happens where you are, even when its aftermath takes you elsewhere.
- **For the journey map:** of the story's 1,061 choices, 80% are acted out where you stand. Only 213 are ways somewhere, so the map can draw pins for those and list the rest as actions at "You are here".

## [1.389.0+425]

What a foe is now matters in a fight.

- **Every foe has a kind:** a person, a beast, the undead, the void, a construct, a demon, an angel or a giant (Narrative's list).
- **Beasts tire.** From round 6, a beast's blows land 5% softer each round, down to half. The log says when it starts tiring.
- **The dead crumble.** From round 6, an undead foe loses a little of itself each round (3% of its health). It never finishes them; the execute does.
- **Only people and beasts break.** Morale no longer makes the dead, the void, constructs, demons, angels or giants flee.
- **Bosses are untouched** by the tiring and the crumbling.
- **An evil foe is told by its kind.** The Lantern Vanguard's heal now counts the void, the undead and demons, no longer anyone weak to Light: the Turned, the cultists and the zealots are living people.
- **Balance:** −0.7 to +1.3 points per profession, and fights don't get longer. Report: docs/simulation/foe-kinds.md.

## [1.388.0+424]

Mercy and the omens, in their own words.

### Changed
- **Mercy for a rival's hunter.** The yield, the choice (Show mercy / Finish it), the read of their heart by Perception, the thanks and the betrayal ambush are reworded in English and French, with no gendered pronoun for a hunter who may be a woman or a man; the two standing causes ("Mercy for a hunter", "No mercy for a hunter") likewise.
- **Hunters' alignments.** Five adjusted to fit their characters: Ysel +25, the Inquisition Soldier +10, the High Warden -10, the Smuggler Captain -25, the Inquisition Penitent +15. The others stand.
- **The omens of a place.** The mist, heat, rising water, holy ground and town watch omens, and the boss's enrage, reworded. Wording only.

## [1.387.0+423]

You can spare a rival's hunter, at a risk.

- **Mercy.** A rival clan's hunter you beat yields: spare them, or finish it.
  - **Spared:** you keep the fight's experience, but no gold or loot, and the hunter's clan thinks a little better of you (+3).
  - **Finished:** the spoils are yours, and the clan holds it against you (−2).
- **The back-stab.** A hunter you spare may come back a few roads later and strike first. The further their alignment from yours, the likelier: 10% when alike, up to 60% when far apart. A hunter who betrays you is never spared twice.
- **Reading them.** With Perception 5 or more, the choice tells you which way the hunter leans, and whether that is close to you.
- **In the simulator:** a run that spares when the odds are under 25% spares about half its hunters, and about one in seven of those comes back.

## [1.385.0+421]

Your clan now shapes your stats as you level up (v5.2, step 5).

- **The patron's favour.** Each level, the clan you stand best with (Friendly or better, or the one you're sworn to) adds a stat point:
  - **Friendly:** to its first stat.
  - **Trusted:** to its first and its second in turn.
  - **Sworn:** the same, and +2 max health.
- **The clans' stats:**
  - Dominion: Strength, Charisma
  - Vigil: Constitution, Perception
  - Compact: Constitution, Strength
  - Mire: Dexterity, Luck
  - Crows: Strength, Dexterity
  - Penitents: Wisdom, Intelligence
- **The Open Hand,** once raised, adds +1 to your strongest stat.
- **In the clan log:** each level-up says what your patron gave.
- **Balance:** about +2.6 points of fights won overall, and the bosses keep their curve. Report: docs/simulation/patron-stats.md.

## [1.380.0+416]

Where you fight now changes how the fight goes (v5.2, step 4).

- **One rule from the place, on top of the Tide.** From round 6 (the omen comes the round before):
  - **Marshes:** a mist eats at both sides, a little more each round.
  - **Deserts:** the heat wears both sides down, and wounds close slower.
  - **Shores, cliffs and halls:** the water rises or the ceiling gives. From round 8 every blow lands harder, the party's most, and heals rise with it, up to +30%.
  - **Holy places:** healing fades and Light strikes harder.
  - **Cities and towns:** the watch breaks the fight up. Ahead on health, your foes scatter and you win; behind, both sides walk away, with nothing won and nothing lost.
  - **Everywhere else:** the Tide alone, as before.
- **Bosses:** a boss's fight keeps the Tide. The log now says when the boss grows enraged.
- **The fight log** names each rule as it rises.
- **Balance:** every profession fights 7 to 14 rounds and wins at least 55% under every rule. The marsh and the desert favour a healer. Report: docs/simulation/context-rules.md.

## [1.379.0+415]

The hunters speak for their clans.

### Changed
- **Battle cries for the Dominion, the Crows and the Penitents.** The six fighters Core reused as rival hunters (Inquisition Soldier and High Warden, Smuggler Captain, Brine Jack, Inquisition Penitent, Masked Penitent) now have a cry of their own, as the Vigil's, the Compact's and the Mire's do.
- **The ambush line.** "{name} is waiting on the road ahead" / "{name} vous attend sur la route", in place of "bars the road". Wording only.

## [1.377.0+413]

Sworn to a clan, its rivals send hunters after you (v5.2, step 3b).

- **Rival hunters on the roads.** While you are sworn to a clan, each of its rivals you stand Hostile with may ambush you on a road at rest (4% a road), and each that hunts you more often (8%), up to 15%. They share the alignment hunters' breather and their settings switch, so a road never holds two ambushes.
- **Six new fighters**, a line fighter and a captain for the Grey Vigil, the Cinder Compact and the Mire Courts, in Narrative's words, each with a battle cry: Halvard and Ysel, Brodin Stonehand and Tove the Unheard, Sedge and Wen. They are met only as hunters. The Dominion, the Crows and the Penitents send fighters already on the roads.
- **The ambush says who sent them and why:** "your oath to the Lantern Dominion is not forgiven".
- **In the simulator:** about one rival hunter a run, in half the runs, beside about two alignment hunters. Report: docs/simulation/specialisations.md.

## [1.373.0+409]

The clans with a weaker tie to your profession now offer a smaller twist of their own (v5.2, step 3c).

- **Eight new gifts**, one for each clan only weakly tied to a profession, in Narrative's words:
  - **Warrior:** Standfast (Vigil): a Defend face adds 1 Fury. Burning Penance (Penitents): a Mana face adds 1 Fury.
  - **Cleric:** Brimming Draught (Mire): a potion's healing past full feeds the Watchfire.
  - **Mage:** Double Kindling (Compact): a Fire spell's reaction counts twice. Lingering Hex (Mire): a spell's status lasts a turn longer.
  - **Rogue:** Stitch-Thrust (Vigil): healing past full strikes the foe. Pitch Hand (Compact): Flurry's second hit slows its target.
  - **Ranger:** Second Broadside (Dominion): once a fight, a face that would not strike goes back, and the Trail draws again.
- **How they come:** from Friend, half as often as a main clan's specialisation, as rare gifts, and with no sub-clan variants or rank II.
- **Balance:** each is worth about half a main specialisation where the simulator can see it. Report: docs/simulation/specialisations.md.

## [1.371.0+407]

Loyalty has a price (v5.2, step 3): the clans remember who you stand with.

- **A clan grown cold quiets what it gave you.** Resented or Hostile with a clan, its specialisation plays only every other round, and its sub-clans' gifts and rank II go quiet. Hunted by it, the specialisation sleeps until you win the clan back. The fight log says so as the fight begins.
- **Your patron's favour cools its rivals, each chapter.** Trusted with a clan, its rivals lose 2 standing at each new chapter. Sworn to it, they lose 4, the clans in tension with it lose 2, and its allies gain 1. Shown in the clan log as "Loyalty's price".
- **No fight penalty:** loyalty costs shops, offers and gifts from the other side of the map, never your strength. A Dominion loyalist ends a run Hunted by three clans; a Crows loyalist by one. Report: docs/simulation/specialisations.md.
## [1.368.0+404]

The fight screen shows the new fight-length rules and the professions' cores.

### Added
- **Fight-length marks.** A "Tide ×N" mark next to the round count once the Tide rises (and "Tide in N" in the three rounds before); a tick at 10% on non-boss foes' health bars (the execute line); a "Wavering" mark on non-boss foes under 25%; the heal number on the preview line dims once healing fatigue sets in.
- **Profession cores on the hero's card.** The warrior's Fury as five notches ("Heavy blow next" when full); the cleric's Watchfire as a flame under the health bar with its worth; the mage's Ash Well starting "empty" on the mana meter; "×2" on the rogue's Flurry face; the ranger's next Trail face beside the die.
- Each mark has a tooltip that explains the rule (English and French).

## [1.367.0+403]

Rank II sounds like its clan.

### Changed
- **Rank II lines.** The fifteen rank-II gifts no longer share one generic line: each says, in its clan's voice, what grows by half again (the Berserker's Pain strikes, the Beacon's fire, the Fen Guide's poison, and so on). English and French. Wording only.

## [1.366.0+402]

The clans' sub-clans bend your specialisation, and the clan raises it to rank II (v5.2, step 2b).

- **Thirty sub-clan gifts.** Once you hold a specialisation and are Trusted by its clan, each of the clan's two sub-clans offers its own twist (a rare gift, in the sub-clan's voice): a *variant* changes how it works (the Tar-Hands' Pain strikes bleed the foe, the Last Watch's Defend feeds the fire, the Drowned Debt's kill deals a new run of the Trail...), an *upgrade* raises its number.
- **Rank II.** Sworn to the clan, it offers rank II of its specialisation (heroic): half again its number.
- **Everywhere they show:** in the clan offers with the specialisation they bend, in the fight log, in the spoils (the Whisper Ledger's stolen gold) and on the ship (the Brig-Born's Broadside, +15% to the guns).
- **Balance:** each measured against its specialisation alone in 60 simulated runs; the strongest, One Witness, Once (the Tribunal), now refills a third of the Well from the fourth round. The boss curve holds. Report: docs/simulation/specialisations.md.
## [1.365.0+401]

The gifts say what they do.

### Changed
- **Specialisation gift texts.** The Lantern Vanguard's heavy blow now heals against "a foe weak to Light (the void, the dead, demons)", the way the game treats it, instead of an "Evil" foe no enemy carries; the Relicbreaker's text says plainly that its three mana are spent on the sure critical; the Beacon burns "with Light". English and French. Wording only.

## [1.363.0+399]

More places to wander off to.

### Added
- **Batch 2 of detour scenes.** 28 new scenes in `detour_scenes.json`, in English and French: echoes for each chapter's lands (the salt pans, the ash road, the lantern-floaters of the fen, the frost-sick queue, the Mirror Shoal, the lamplighters of Candlehold), a few scenes that open only after a story beat (a forgiven candle, the archivist's blank page, a Mire courtesy, a giant's hearth-stone cart), and thirteen short stops, so the higher rate of detours does not repeat. Chapters 4 and 7 first.

## [1.362.0+398]

The march on Candlehold may hold a detour.

### Changed
- **Chapter 7's gates.** The arrival at Candlehold's gates (`7500`) no longer forbids a detour, so the way to the Throne can hold one, and the chapter's landmark, The Banner on the Hill. The scene is tense and stays tense; only the ban is lifted.

## [1.361.0+397]

More detours, spread across the whole story (the user: "a bit more, 7 to 10").

- **Landings roll.** Arriving somewhere by sea can now hold a detour, as a road arriving there would. The sailed chapters (4 to 7) get their share, and the march to Candlehold can hold chapter 7's landmark once Narrative lifts its set piece.
- **The chapter's landmark comes before a hunter** on the road where it is due (a road event still comes first).
- **The odds start lower:** 8% a road, plus 6% for each quiet road, up to 45%. Since more roads now roll, a run meets about 9 detours (median 9, 6 to 15): 1.4 to 2.1 in each of chapters 2 to 6, one in chapter 7. In v1.356 it was 6.8, with chapters 4 and 5 at 0.9.
- No detour comes right after another, and none between two scenes of the same place, as before. Report: docs/simulation/detours.md.

## [1.360.0+396]

The clans specialise your profession (v5.2, step 2a): each profession's core can now be bent three ways, one per main clan.

- **Fifteen specialisations**, three for each profession, offered by the profession's main clans once you are their Friend. Each comes once and stays for the run, and they stack.
  - **Warrior:** Berserker (Crows), Briar Guard (Compact), Lantern Vanguard (Dominion).
  - **Cleric:** Long Vigil (Vigil), Ashen Hand (Penitents), Beacon (Dominion).
  - **Mage:** Censer Mage (Dominion), Burden-Bearer (Penitents), Tempest Toll (Crows).
  - **Rogue:** Fever Blade (Mire), Ledger Knife (Crows), Relicbreaker (Penitents).
  - **Ranger:** Corsair's Eye (Crows), Trapwright (Compact), Fen Guide (Mire).
- **In the clan offers:** a specialisation shows as its own gift, with its text and the clan's voice. The Crows also offer Teleport Strike to a Tempest Toll.
- **In the fight:** each one plays its rule in the fight log (the Verdict, the Rot, the briar biting back, the fire giving back...).
- **Balance:** each was measured against its profession's core in 200 simulated runs. Most add 3 to 6 points of fights won. Report: docs/simulation/specialisations.md.

## [1.358.0+394]

The map reads on a phone, zooming out lands on the sphere, and the camp's buildings have tabs and filters.

### Changed
- **The map is readable.**
  - Place names are never under 12 px on screen, with a dark halo; a crowded chart drops the names with no clear spot (the party's place, the picked one and the goal always stay) and shows them as it opens.
  - Region and land names are larger and brighter; names stay on the ball on the sphere.
  - Roads are thicker, coasts and land borders stronger, the land lighter against the sea (night and shroud looks), the party's place has a glow and a dark-rimmed ring.
- **The sphere is the default, and fills a phone.** Zooming out from the Journey lands on the sphere; its ball fills the box's short side (it was a 250 px ball). The flat chart stays a choice in Layers.
- **A zoom ladder.** The + and − buttons stop on the world, the land, the district and the closest, so a district chart has its rung ready.
- **The Journey's district is board 15's.** In a city Core has stored a plan for (Saltmouth today), the District view is the city chart framed on the party's district, with a numbered pin on the building of each way; under it the ways as numbered rows (a tap opens the way's sheet with Go), and "Walk on" chips to the other districts. The Town view is the whole city with the districts under fog and their rows. Other cities keep the generated plan.
- **The Journey map climbs district → town → world.** Zooming out from a district shows the whole town (all its districts) before the world; zooming in from the world comes back through the town. Three small tab buttons on the map (District, Town, World; Quartier, Ville, Monde) jump to a level in one tap; the Town tab is dimmed where the place has no city plan, and a + under the town view returns to the district.
- **Camp buildings: tabs and filters.** Houses and Additions are tabs (with counts); filters keep what is ready, what the gold and the pack can pay for, what stands, and (for houses) a category. An empty result offers a way back. Each card carries a "built / limit" slot (Core's `WorkLimit`).
## [1.357.0+393]

The new districts have their own voices.

### Changed
- **District pools.** Each of the eleven districts of the Ashen Quarter, the Drowned Cloister and the White Anchorage has its own detour pool: four lines each of shop, quest, treasure, rest and generic, written from the district's blurb, so a detour leaving the Ash-Market no longer sounds like the next biome over.
- **A detour's cost, in the game's own words.** "The detour takes part of the day" (the day's parts are Dawn, Daytime, Dusk and Night), instead of a "watch" that the French rendered as "veille", the name of a clan.

## [1.356.0+392]

Detours become places to explore (Wave 11): short written scenes off the road, paced so every chapter gets its share.

- **Written scenes.** Narrative's first detour scenes are in the game: a landmark for each chapter from 2 to 7 (chapter 7's can't come yet: it has no road at rest), a scene or a stop for each biome, and a short scene in each district of Saltmouth, the Ashen Quarter, the Drowned Cloister and the White Anchorage. A scene plays beat by beat; each choice says what it did. You can back away at the first beat for free ("Leave it and go on"). A scene with a check or a fight takes a watch of the day; none eats a ration.
- **Where detours happen.** Only when the party changes place or district: never between two scenes of the same place. From any scene, not just the main story beats, and on the camp's trips too, so chapter 4 now gets detours. None in the last chapter.
- **When.** A road at rest starts at 20% and gains 10% for each quiet road, up to 60%. After a detour, a hunter or a familiar face, the next road is quiet. City streets halve the odds; a long road raises them. A crisis road holds nothing but owes a detour, paid later in the same chapter; a set piece owes nothing.
- **Each chapter's landmark** comes once, on the chapter's first road at rest that nothing else holds.
- **Fixes.** A detour line doesn't come back until the rest of its pool has. A place's own enemy line now opens fights there. Chapter 2's tunnel, insult and cordon are no longer counted as a beat every run passes.
- **Simulator.** Every road is recorded, and runs can be written out as transcripts. Report: docs/simulation/detours.md.

## [1.354.0+390]

The professions' cores (v5.2 step 1, second half; docs/simulation/profession-cores.md). The hero plays their profession's core; companions keep their dice as they are.

### Added
- **Warrior, Fury.** Each hit landed, and each blow that gets through, adds 1 Fury. At 5, the next damaging face is a heavy blow (×2.5). The fight log says when it's full.
- **Cleric, the Watchfire.** Every heal from the die also burns the enemy for twice its amount. Healing past full feeds a fire (up to half your max health) that takes blows first, and what is left burns at the round's turn. The cleric's heals don't tire.
- **Mage, the Ash Well.**
  - The well starts each fight empty.
  - Mana from the die comes double.
  - Spells cost 1 less.
  - Mana left after a win heals 2% of your max health a point.
- **Rogue, Flurry.** A damaging face strikes twice at 55%, each strike with its own critical.
- **Ranger, the Trail.** The die is a deck: 5 of its 6 faces each run, none twice. The log names the face coming next.
- **Measured (200 simulated runs):** fights run 7 to 14 rounds.

  | Profession | Win rate | Rounds per fight |
  |---|---|---|
  | Cleric | 53% | 14.0 |
  | Mage | 72% | 6.9 |
  | Ranger | 65% | 9.8 |
  | Rogue | 64% | 9.9 |
  | Warrior | 63% | 9.4 |

### Changed
- **To keep the boss curve and the chapter-1 chain:**
  - the Void Archon has 330 health (was 282);
  - Claimant Vane has 370 (was 317);
  - Claimant Tallis has 380 (was 248);
  - Claimant Morrow has 560 (was 398);
  - White Soldiers hit for 21 (was 19).

## [1.353.0+389]

Detours find something to pick up, wherever they are.

### Changed
- **Treasure in every place.** Every place pool of `detours.json` now has treasure lines, three each (five at the Cove camp), so a find in a city district no longer reads like a desert or a cliff.
- **A deeper Cove camp.** The camp's pool gains 16 lines across its shop, quest, rest and generic kinds, some for later chapters, so the same six lines do not come round as often.
- **Corneilles, not Corbeaux.** The French name of the Salt Crows is corrected where two lines still said Corbeaux; two French district blurbs name the Dernière Veille and the Corneilles correctly.

## [1.351.0+387]

Shorter fights: the default fight-length rules and the Tide (v5.2 step 1, docs/simulation/fight-length.md).

### Changed
- **Healing fatigue.** Each heal a member gives in a fight (face, skill or spell) heals 5% less than the one before, never under 30%.
- **Execute.** A foe struck this round and left under 10% of its health falls. Never a boss.
- **Morale.** A hurt foe (under 25%) flees at 50% each round. A fled foe pays part of its spoils, as a Skittish one does.
- **The pack breaks.** When a pack's leader (its biggest) falls, each other foe flees at 70%. Neither morale nor the pack break plays in a boss's fight.
- **The Tide.** From round 8, the party's blows grow 20% a round and the enemies' 10%, adding up; 18% for a boss's side. The fight log says when it turns and how far it has risen.
- **Measured (200 simulated runs):**
  - fights average 10.1 rounds instead of 16.5, at the same win rate (53.4% against 54.0%);
  - the cleric's fights fall from 37 rounds to 13.5;
  - the boss curve holds.

### Added
- The simulator's run summary counts the rounds fought (`roundsFought`). `simulatePlaythroughs` takes `clashOff`, so each rule can be left out to measure it (`fatigue`, `execute`, `morale`, `packBreak`, `tide`).

## [1.349.0+385]

The camp's town has limits; the towns have their districts.

### Changed
- **Town additions are limited.**
  - The watchtower is unique.
  - Storehouses: one, plus one for every four houses up.
  - Stairs: one, plus one for every two houses up.
  - Plain floors stay free.
  - A capped card reads "Limit reached: 1 of 1", and the camp refuses past it.
  - Every house is one of one, as before. The building screen can now read each work's count and limit (`WorkLimit`).

### Added
- **Districts in the story's three towns, as in the cities.** The journey now shows the district level there:
  - **the Ashen Quarter:** the Quarter Gate, the Ash-Market, the Wall of Names, Cinder Row, the Spire Stair;
  - **the Drowned Cloister:** the Drowned Stair, the Flooded Nave, the Ossuary Stalls;
  - **the White Anchorage:** the Anchor Quay, the Hull Town, the Stern Chapel.

  Each of their 89 scenes stands in one.

## [1.348.0+384]

The politics hint waits for its setting.

### Fixed
- **The turn-in dialog's politics hint** ("Vigil +5 · Dominion −5") read its setting before the saved value had loaded, so on the first turn-in after a cold start it could show when the player had turned hints off (or hide when they were on). The dialog now waits for the saved setting first, as the hunters setting does.

## [1.347.0+383]

Settings honoured from the first moment; the ways round a fight have their price.

### Fixed
- **A setting is honoured from the first road after a start**: with the hunters turned off, no temptation or hunter on the first detour after opening the game; the spoils chest opens itself on the first fight if that is the choice.

### Changed
- **The ways round a fight that cost something by their words now do**: the patrol's toll is 20 gold (shut if the purse can't pay), throwing the hound a salt sack or burning the lantern oil costs a tenth of the load, giving away the coal's warmth or outpacing the reed ghoul costs a day; the thieves' bargain pays 5 gold. The other ways round stay free, but leave the fight's spoils behind.

## [1.346.0+382]

### Changed
- Expeditions: five fights written for a single foe (Lantern Docks patrol, Fever-Bark lane, Frost Quarry guards, Ember Run penitents, Shroud's Vigil masks), EN and FR; two choice labels fixed to match their single foe. Text only.

## [1.345.0+381]

The written expeditions, balanced.

### Changed
- **A written fight follows the rule a drawn pack does**: two or more foes only from the pack tier, at most the chapter's pack size; a heavy foe fights alone. Five steps that set two heavies on the party now set one.
- **A few of the longest roads' pairs are now one foe** (the Drowned Stair's zealot, the Dead Heart's and the Shroud's hound, the White Fleet's pilgrim and reflection), and the **Masked Penitent** is a little lighter (185 health, 19 damage): they stopped too many parties short of the bosses.
- The playthrough simulator walks the written roads step by step, as the game does.

## [1.344.0+380]

### Changed
- A read-through of the new expedition and detour text (data only): repeated phrasings varied, American spelling used throughout, and the English and French kept in step. No lines added or removed.

## [1.342.0+378]

### Added
- Detour pools for places that need their own voice (data; Core's engine reads them): the cove camp, Rimewell, Highhearth, the Black Reliquary, Wrack’s End, the gates and the Lantern Hall of Candlehold, the White Anchorage and Greyhithe, English and French. `assets/gamedata/detours.json` now holds fifteen places.

## [1.340.0+376]

### Added
- More detour pools that fit their place (data; Core's engine reads them): the six Saltmouth districts (the Landward Gate, Tern Row, Smugglers’ Wharf, the Ship-breaker’s Yard, the Lantern Alleys, Card Row), the arid coast and the sea cliffs (the cove camp, Wrack’s End, Candlehold), English and French. `assets/gamedata/detours.json` now holds seven biomes and six places.

## [1.338.0+374]

### Added
- Detour pools that fit their place (data; Core's engine reads them): the ashlands (the Ashen Quarter, Emberwick, the Spire), the fen (Kindly Hill, the Drowned Cloister, the Hollow Court) and the red hills (Akagiri), six kinds of six lines each, English and French. A detour in those places now reads as the place, not as one of four generic moods.

## [1.336.0+372]

### Added
- Expedition steps for the four tier-3 expeditions (data; Core's engine plays them): Scaffold Yards, the Shroud’s Vigil, the White Fleet’s Grave and Beyond the Tear, twelve to fifteen steps each, English and French. Every one of the twenty expeditions now walks a written road.

## [1.335.0+371]

### Added
- Expedition steps for the five escort and delivery expeditions (data; Core's engine plays them): the Salt Road, Fever-Bark for the Wall, the Bell Road, the Ember Run and the Lantern Train, eight to ten stages each, English and French. `assets/gamedata/expedition_steps.json` now holds sixteen written zones.
## [1.334.0+370]

The level-up offer reads as three ways to grow.

### Changed
- **The training offer** (Level Up screen and the pop-up after a fight) is three cards in the clan offer's manner: each path has its pixel icon on a tile in the colour of what it raises most (attack ember, defence and health cool, mind violet, the quick green, the social gold), its name and its line, then each gain as a tile with the big "+n" and where the stat goes ("100 → 120").
- **A card is picked, then taken** with "Take this training" under the cards, as a clan's gift is, so a path that is for good is never taken by a stray tap. A small offer (a Tome of Insight's point) reads the same.

## [1.333.0+369]

No hero starts with negative armour.

### Fixed
- **A new character's base armour is never below 0.** An Orc Mage started at -4 (the Orc's -2 and the Mage's -2), which read as a bug; the seven frailest race and profession pairs now start at 0, and every other start is unchanged. Companions and the simulator follow the same rule.
- **A delivery with a written road gets time for all of it**: its deadline keeps the zone's spare days over the written stages (Fever Bark and the Ember Run: 10 days for 8 stages, not 6).

## [1.332.0+368]

### Added
- Expedition steps for four more tier-2 expeditions (data; Core's engine plays them): the Drowned Stair, the Dead Heart Approach, the Glass Strand and the Frost Quarry, nine steps each, English and French. `assets/gamedata/expedition_steps.json` now holds eleven written zones.
## [1.331.0+367]

The clan offer: banners, a compass, then the picked clan's words.

### Changed
- **The clan gift popin** keeps the three banners on top (a little smaller than their pixels, each with its gift and the first standing it moves; the picked one lit in its colour and taking the wind). Under them the clans' compass, and under that the explanation of the picked banner: its charter in the clan's colour (name, where you stand with it, motto, what it stands for when the data has the line, and which way the alignment moves, **in a word**: toward Good, toward Evil, no change), then the gift and the words the clan says. "Take this gift" stays at the bottom.
- **The charter shows a clan's orientation** as a small five-axis radar (might, guard, mending, arcana, fortune: what its signs and sworn boon lean on, the strongest axis at the rim), from Core's `clanRadarProvider`, beside the clan's name, motto and "Stands for" line (Narrative's).
- **The compass** puts the six clans on a ring where friends sit side by side and blood feuds face each other; the picked clan's lines run to the others (friends solid, foes dashed, coloured by how they stand), each crest wears what changes for it (+6, +1.5, −3), and the clans on offer are ringed in gold.
- **The Clans screen's Standing tab** opens with the same compass: each crest wears where you stand with the clan, and a tap names its friends and foes.

## [1.329.0+365]

The clans say what they stand for.

### Added
- **Each clan, tribe and otherworld power says what it stands for** in a few words ("Law, order, one flame over all"), in English and French, ready for the clan gift popin.
- **A clan's radar** for the gift popin and the clan tab: what its gifts lean on (might, guard, mending, arcana, fortune) and how it stands with the other clans, as relations are now.

## [1.328.0+364]

### Added
- Expedition steps for four tier-2 expeditions (data only; Core's engine plays them): Lantern Docks, Cinder Row, the Exorcists’ Road and the Changeling Fen, eight or nine steps each, English and French. `assets/gamedata/expedition_steps.json` now holds seven written zones.
## [1.327.0+363]

Detours and expeditions fit where they happen.

### Changed
- **A detour reads like the place it leaves from**: its lines come from the scene's own district or town, then the land around it, then its biome (the tear shore, the frost), and only then from the four old themes. A tense scene draws tense lines.
- **An expedition can have its own road**: a zone with written steps walks them in order (events, checks, fights, discoveries of a place on the road, rests), and is as long as they are. Its checks get harder with the chapter, a rest heals, a discovery turns up one of the zone's materials, and each choice can say what came of it.
- A zone without written steps plays as before.

## [1.324.0+360]

The Skillwright's bench shows what it fuses.

### Changed
- **Craft a Skill** is a sheet where each recipe is two skills becoming a third, every one drawn with its icon and its real name (no more ids): a skill you know wears a check, one you lack is greyed and locked with "Missing", the recipe you can do stands out in gold with its Merge button, and one already done says so. Merge asks first, shows the same picture and what is spent, and the card flips to "Already crafted" with the sheet left open.
- **The built Skillwright's card** in the camp's building list has a "Craft a Skill" button.
- The sheet waits for the recipes to load instead of saying there are none.

## [1.323.0+359]

### Added
- Detours and expeditions that fit their place (first batch, data only; the engine reads it in Core's coming PR): `assets/gamedata/expedition_steps.json` with six steps each for the three tier-1 expeditions (Fisherman’s Row, Tanner’s Court, the Ossuary Galleries), and `assets/gamedata/detours.json` with the tear shore and frost-city pools (six kinds of six lines). English and French.
## [1.322.0+358]

A brand's toll reads right.

### Fixed
- **A negative effect reads with its own sign**: the Marked's toll is "-10% gold from fights", no longer "+-10%". The same holds for every title, sign, boon and pact line.

## [1.320.0+356]

A level-up is a choice of training, not a pile of points.

### Changed
- **Each level's five stat points buy one of three training paths**, each a bundle toward a playstyle: the Bruiser, the Duelist, the Warden, the Juggernaut, the Arcanist, the Zealot, the Skirmisher, the Hunter, the Envoy and the Brawler. Every path is worth exactly what five points were. The three on offer are one of your calling (your profession or people, likelier the more you have taken it), your habit (the path you take most), and a turn (any other).
- **No "decide later"**: the pop-up after a fight closes once the training is taken, and the Level Up screen shows the offer while points wait. Stats are no longer raised one by one.
- **A Tome of Insight** (one point) brings a small offer: three single gains, each from a likely path.
- Old saves keep their unspent points; they come back as offers.

## [1.319.0+355]

Skills are crafted at the camp's Skillwright.

### Changed
- **Craft a Skill is done at the camp, at the new Skillwright** (a workshop: 350 gold, timber and slag glass, from chapter 3). Until it stands, no skill can be crafted, and the craft entries on the skills screen do not show.
- **The craft lists name the skills** in your language ("Fireball + Shadow Step → Blazing Shadow", "Requires: Second Wind"), never their ids.

## [1.318.0+354]

The title popin names its clan.

### Changed
- **Reading a title** (hold its chip on the Character tab) opens a sheet instead of a plain dialog: the granting clan's banner beside the title's own badge in the clan's colour, "Granted by" and the clan's name, the effect in a card of its own, then the words it came with, quiet. A title you can choose has Wear or Take off in the sheet; a brand ("the Marked") stays unchoosable and shows in red.

## [1.317.0+353]

The item popin reads at a glance.

### Changed
- **An item's detail sheet has a hierarchy** (inventory, shop and loot chest alike): its art on a tile in its rarity colour (a Relic glows), the name with rarity, type and slot tags, then attack and armor as big numbers with a bar and a tick where the item you wear sits, and the gain or loss beside them. Elements, what it scales with, its unique effect, alignment and any requirement you miss follow; the set shows its pieces and which bonuses you have earned; the lore comes last, in quiet type.
- **From the inventory** the sheet offers Equip or Unequip, and nothing is compared with itself when the item is the one worn.

## [1.316.0+352]

Checks on the road and at sea, rolled on the die.

### Changed
- **A check on a land crossing is rolled on the Skill Challenge's die** under the event's choices: the d20 tumbles, lands, the sum against the DC comes up, and the outcome follows with the die set down beside it, in place of the line of text on top.
- **A check at sea** is rolled on the same die over the sea, then written in the ship's log as before.

## [1.315.0+351]

The city plan: Saltmouth from above, zoomed, fogged, with its ways on their buildings.

### Added
- **The city plan page** (board 15, model A): in a city with a plan the Journey has a city-plan button. It opens a page on the whole city, drawn from above in the Map look's colours (the river with its island, the avenues, the squares, the arena, the wall; each district tinted). Pinch or wheel to zoom in and out, or the + and - buttons; a tap on a district zooms to it, its buildings show their names and the scene's ways stand on them as pins (a quest, a fight, a check, a shop, a road); "Whole city" is the way back. The districts the party has not found lie under fog, a dashed outline and a "?"; the party's own district carries its mark.
- **Free walking from the plan:** a district card offers "Walk here" (no road, no time) for a district found; a way's card offers "Go", which closes the page and selects that way on the Journey's map. No separate hub screen and no automatic goal star.
- **A preview in the fight lab** ("City chart") on a denser Saltmouth, with a fog toggle.

## [1.314.0+350]

The world sphere: the story world on the globe, two pole buttons, a ball of about 250 px.

### Changed
- **The sphere wears the story world** (board 11): the whole globe, 360° by 180°, with its three story lands, the empty lands, the polar lands and the archipelagos. The flat map keeps the look's own chart (A, B or C); turning from one to the other frames the view afresh.
- **Two pole buttons** on the map's controls turn the sphere right over the north or the south pole, gliding; a drag still turns it, past the seam as well.
- **A ball of about 250 px:** on a wide screen the sphere no longer grows with the box (a radius of 125 px at the first zoom; on a phone it was already that), and the sky over it follows.
- **The ice caps keep their edges:** an edge lying on the chart's border (the seam, the top and the bottom) stays straight, so the caps are no longer torn along the seam and at the pole. Every other coast falls as it always did.
- **Fixed, QA's order-dependent test:** the sphere's skin render already under way is now the one every caller waits for, so a second render can no longer replace the kept skin.

## [1.313.0+349]

Quests settle themselves; nothing waits for later.

### Changed
- **A quest completes on its own** once its objectives are met: its rewards, its companion and the level-up come at once, with no turn-in to tap (a quest settled by a choice still asks how). It happens out of any fight or expedition; a goal reached in a fight completes when the fight is over.
- **A main quest is taken on as soon as it is offered**: it is never left for later.
- **A clan offer cannot be put off**: the offer stays until a gift is taken.

### Fixed
- A notice closing itself no longer closes a dialog opened over it.

## [1.312.0+348]

Saltmouth's six districts in the story, and the whole sphere named.

### Changed
- **Saltmouth's ways stand in their districts** (Narrative's seating, board 15): the hub's scenes are re-tagged into the Landward Gate, Tern Row, the Smugglers' Wharf, the Ship-breaker's Yard, the Lantern Alleys and Card Row, so each district shows its own ways. The Lantern Alleys and Card Row are on the world map, with a spot on every chart and a road from the wharf.
- **Every place on the whole sphere has a name** (Narrative's, English and French): the seven new lands (the Sundown Lands, the Green Girdle, the Gaunt Lands, the Morning Shore, the Far Dawn, the Long Winter, the Last Shelf), four oceans on the chart, the twelve archipelagos and their twenty-nine islands.

## [1.311.0+347]

Every check rolls a d20 on screen; the Journey's marks say what the ways are.

### Changed
- **A d20 tumbles and lands on every check's roll,** drawn without a panel behind it: its number flickers while it turns in perspective, then the roll settles, the edge turns gold for a success or red for a failure and a ring flashes out of it (a failure shudders). The Skill Challenge waits for each round's die to land before the round counts; a single ability check, in the story and on the expeditions, is rolled the same way and then tells its sum. One reusable widget (`D20Roll`), for the crossings and the voyage to use next.
- **The Journey's marks look like what the ways are:** a fight with a beast, a guard, a ghost or an archer each have their own mark, a check has one for each ability, a shop is a forge, an apothecary, an arcane bazaar or a chandler, an expedition a cave, ruins, a wood, the shore or the desert. Each mark moves a little when nothing else does (a flag sways, a flame flickers, a boat bobs, a blade glints).
- **A quest badge on a mark:** a gold bookmark when the way is the main quest's, a plain one for a side job; shown on a way that offers a quest not taken yet or carries one under way forward.
- **The place's name no longer stamps itself, in yellow, over the map** when the party arrives somewhere new (the seal and the ink still do; the name is in the corner).

## [1.310.0+346]

The ronin walks.

### Changed
- **The hero in the side-view scenes is the ronin sprite** the user supplied (a samurai vagabond, eight walk frames east and west): she walks at the head of the party over the desert and the ruins while the scene scrolls, and stands with a slow breath when the party waits on a choice. The companions behind her are still the placeholders, drawn a little bigger so they stand as tall as she does. Until her images are loaded the old placeholder stands in.

## [1.309.0+345]

The story world on the whole sphere.

### Changed
- **The story world covers the whole globe** (board 11): 360° of longitude by 180° of latitude. The story's three lands are moved in longitude with their latitudes, and so their climates, kept: the Ashen Continent to the west, the Old Continent to the east, the Lantern Isles between. Five empty lands, a polar land under an ice cap over each pole, and twelve archipelagos fill the rest (about 45 % land; every 30° of longitude has land and sea). The globe can turn right over either pole and comes round past the seam; the ice caps are the coldest places on it. The new lands' names are placeholders. The map looks A, B and C keep their band. (The smaller sphere and the pole buttons are UX's, to come.)

## [1.308.0+344]

The city plan's data: Saltmouth from above, its six districts, free walking.

### Added
- **Saltmouth's plan** (board 15, `assets/gamedata/city_plans.json`): the shore and harbour, the river split round an island, canals, the wall with its gates and towers, the avenues from the market square to the gates, the squares (market, arena, plaza, quay), the six districts tiling the town and the buildings on their lots. Each of the hub's ways stands on a building of its district, named as Narrative seats it. Laid out by a generator (`lib/data/city_plan_generator.dart`, run with `tool/city_plans/gen_city_plans.dart`); UX paints it.
- **Two new districts**: the Lantern Alleys and Card Row.
- **Free walking between districts**: the party walks to any district of the city it is in, with no time and no road; a district walked into is found for good, and the ones not found are fogged. The ways shown are the ones in the party's district. (The screens come with UX's city view.)

## [1.307.0+343]

Every hull in side view carries her own gear.

### Changed
- **The twin hull, the ironclad, the lodestone barge and the void carrack now wear their fittings in side view** (voyage, arrival, the shipwright's yard, the fight strip): guns by family at their ports and rails, plating, and the utility's deck gear. The ironclad's guns and gear stand on the casemate's roof and the muzzles come out of its ports; the lodestone barge's on its slab. The twin hull's two lateens and the carrack's void sail carry the painted sails' sigils too. A battered one now shows its damage along its real rail.

## [1.306.0+342]

### Changed
- Wording of the desert scavengers' fight: their success and fail notes, and the three fight-result lines shown after a crossing fight (EN and FR). Text only, no keys or numbers.

## [1.305.0+341]

The desert scavengers are a real fight.

### Changed
- **"Go at them" against the scavengers on a land crossing is fought on the battle screen** (a Wreck Scavenger), with the party's own health, rewards and loot. Won, the road goes on and the sledge is left behind; broken off, the party gets clear with a cut; lost, the crossing is lost and the party is carried back wounded, as when its health runs out. The choice reads "(fight)". "Play to chapter" and the simulator never stop for the battle screen: they slip away or pay, as they mostly did. A crossing's choice can name any enemy with a `fight` field.

## [1.304.0+340]

The Shroud Shrine opens on the Shroud's Vigil too.

### Changed
- **Clearing the Shroud's Vigil unlocks the Shroud Shrine** at the camp, as clearing the Dead Heart's approach already did. The story can send the party into the Vigil without the Dead Heart expedition, and the shrine no longer waits on that one. The building screen lists both expeditions under what it still needs. Houses (and anything else gated by flags) gain an `unlockedByFlags` field: any one of those flags opens it, whatever its required flags.

## [1.303.0+339]

The hulls in side view, with their painted sails.

### Changed
- **The painted sails' sigils show on the canvas in side view** (voyage, arrival, the shipwright's yard, the fight strip): a flight sail's spread wings, a foresight sail's eye, a hearth sail's flame, a wind-knot sail's crossed loops, a void-mark sail's ring with a spiral turning in it, each in the colour of the people whose medium it is painted in (human gold, elf green, dwarf grey-blue, orc black, voidkin violet). A hull with several sail slots carries several sigils, on the biggest sails first; on a fore-and-aft or lateen sail the sigil sits low toward the mast. They show on the sailing hulls (the others' own sails come later).

## [1.302.0+338]

The hulls in side view, armed and equipped.

### Changed
- **What is fitted aboard her shows in side view** (voyage, arrival, the shipwright's yard, the fight strip): **the guns**, each family its own: cannon muzzles out of the gun ports (stubby for the carronade and the grape, long for the culverin, chain-shot at the chain gun's mouth, a glowing tip on the carronade, brass on the better ones), a ballista on a post at the rail, flickering clay fire-pots, a harpoon gun at the bow, the bone horn of the trophy beak; **the plating on her side**: riveted iron plates covering more of her at each version, timbers crossed over the planking for bracing, round shields hung along the rail for the screens, the pale spined scales of the trophy plating; **the gear on deck** for her utility: crates for stores, signal flags for orders, a glowing lantern at the stern for the helm, a pyramid of shot and a rammer for gunnery, roped barrels for the hold, a banner on a tall pole for command, crossed tusks for the trophy hull. They show on the sailing hulls and the sky-sloop and the cloud-cutter, which carry guns on the same side.

## [1.301.0+337]

The hulls in side view, in the fight.

### Changed
- **A sea battle shows the two hulls from the side**, on a tall screen, in a strip between the enemy's bar and the sea: the Eel on the left in what she wears and as battered as she is (scorch, a hole, patched sails, smoke, flames, lower in the water), the enemy on the right with her own hull (the raider skiff, the corsair brig, the Inquisition cutter, the void barge) or as the sea beast it is (the Brinejaw's fin, the Pale Leviathan's back, the Tide-Mother's arms), bow toward the Eel and as battered as she is. The two ease apart or together as the range changes (close, medium, long), on the waters and in the weather of the fight. On a short screen the strip is left out and the sea keeps its room; the fight itself is still from above.

## [1.300.0+336]

The hulls in side view, battered.

### Changed
- **The Eel shows what she has taken** on a voyage day and on arrival, by the hull she has left: below 80%, scorch marks along her side; below 60%, a hole in her planking with splinters round it and patched sails (stitched patches in a darker cloth); below 55%, smoke drifting aft from her deck; below 40%, rips across the sails; below 30%, flames on deck and heavy black smoke; and from half her hull down she sits lower in the water, up to three rows at the last. It works on every hull, the flying boats included (the gasbag, the bat-wings and the bone wings hang as they did, smoking).

## [1.299.0+335]

The hulls in side view, the Harbor and the raiders.

### Changed
- **The shipwright's yard shows her from the side too**: above the plan from above, the Eel in side view on the open sea, on the hull being tried and in the paint, cloth, figurehead and flag being tried, as at sea.
- **The raiders at sea are drawn with their own hulls** (the same side painter as the Eel's), bow to the left so they face her: the raider skiff (a small oared hull with a patched sail), the corsair brig (two masts of dark cloth), the Inquisition cutter (pale gaff sail and two jibs) and the void barge (a violet lateen under a halo). The old simple raider is gone.

## [1.298.0+334]

The voyage in side view: the Eel's own hull.

### Changed
- **All fourteen hulls are drawn in side view** at sea, replacing the one placeholder hull. Each is read off its `ships.json` record (the same one the top-down painter uses): the length, how high she sits and how deep (beam), how full her ends are, the stern and bow castles with their lit cabin windows, gun ports on the great ships, the masts and how each is rigged (square sails with a topsail on three-masters, fore-and-aft gaff sails, lateens), the jibs, a bowsprit and the galleon's beak, the longboat's swinging oars. The odd hulls have their own build: the twin hull (two hulls under one deck and a cabin), the ironclad (a plated slab with a ram, a riveted casemate, two funnels streaming smoke), and the four flying boats (the sky-sloop's gasbag, boiler chimney and screw; the cloud-cutter's bat-wing sails and furnace glow; the lodestone barge with lodestones hanging from the keel and spark arcs; the void carrack's bone wings and void sail).
- **What she wears shows**: the hull paint and trim, the sail cloth with its edge and pattern (stripes, patches, diamonds), the ensign colour and a figurehead at the bow. The arrival scene shows the same ship.

## [1.297.0+333]

The voyage in side view: what the sea meets, and the port ahead.

### Changed
- **A voyage day shows what the Eel meets** beside her: a raider under sail (a skiff, a two-masted corsair brig, the Inquisition's pale cutter, the void barge with its violet glow), a derelict heeled over with her mast snapped, a light on the horizon with a shadow slipping under the keel (sighting), and the sea beasts (the brinejaw's fin, the pale leviathan's long back, the tide kraken's arms). A quiet day has gulls. The day's icon moves to the corner of the picture.
- **Arriving shows the port** instead of an anchor icon: a stone quay, houses with lit windows and a tower with its lantern, over the sea of the waters just crossed.

## [1.296.0+332]

The voyage in side view: the sea.

### Changed
- **A voyage day's picture is a side view** (board 5): the ship small, seen from the side, over a scrolling sea that wears the colours of the waters she sails (the same five records the fight paints: open, shallows, drowned, abyss, ashen), with a sky in dithered bands, what stands on the horizon (islets, a drowned palm islet, broken towers, the ashen cliffs) and what the waters carry (sandbars, kelp, slow rings of void light). A storm day is a squall (rain, higher waves, the flash as before); a windknot sail aboard gives a tailwind; a flying hull hangs above the water with her shadow on it. Reduced motion: a still scene. The ship is one placeholder hull and sail until the fourteen hulls' own side views come.

## [1.295.0+331]

The ash squall on the road to the Ashen Quarter.

### Changed
- **The ash squall fills the ruins scene with ash**, as the sandstorm fills the desert one with dust: on the camp-to-quarter road, when the day's event is the ash squall, the ash falls thick over the scene. Without a storm the ash still falls lightly (the ruins scene itself came in 1.291.0, for terrain `ruins`).

## [1.294.0+330]

The building screen: four sections, what is missing, where to find it.

### Changed
- **The Town tab's houses are a list in four sections** (the Sea, the Company, the Workshops, the Great Works, with Narrative's names and one-line blurbs, each with how many of its houses stand), read from `campWorksProvider`. A card says where a house stands: **Built**, **Ready** (with Build), **Missing** (its cost as icon chips, the count in red while short, and the first thing missing), or a **silhouette** for a house that has not come yet, with one reason ("Chapter 5", "When Kelda joins") and no word of what it gives. No section folds.
- **A tap on a card opens a sheet** that says everything the card says, with where each missing thing comes from, in plain text: the expeditions that pay a material or set a flag, the shops that stock it ("No shop sells it" for a rare), and what is left of the gold. Build is on the sheet too, grey until the house can go up. The cliff town still outlines where the selected house would go.
- The additions tab keeps its strip of cards.

## [1.293.0+329]

The home bar's map icon opens the full map.

### Changed
- **The map icon in the play-mode header opens the full map** (the sphere map of the Journey and the Camp) instead of the old map page. What only the old page had moved onto it: the **look and shape pickers** in the layers sheet, the **chapter chips** that show one chapter's road, **Replay all** in the journeys sheet (the walk of the whole road again), and the map's **tutorial topic**. The old page stays in Edit Mode (`home_world_map`), where its place panel (scenes read, foes met, lands and biome crumbs) is still needed.

## [1.292.0+328]

The road from the cove camp to the Ashen Quarter, crossed on chapter 3's
main quest, and a crash on a chapter's turn fixed.

### Added
- **A third land crossing:** from the cove camp to the Ashen Quarter, 2
  days through the burned town, played as chapter 3's main quest sets out
  (before the story moves on, as a voyage is). Five new events: an ash
  squall, an Inquisition patrol, a burned shrine, feral dogs and a street
  that gives way. Their words were read by Narrative (three French fixes,
  gender-neutral).

### Fixed
- **A crash on a chapter's turn.** With the story open, a new chapter's
  clan offer was granted in the very frame the chapter changed, while the
  quest, badge and chapter-progress readers were rebuilt from the save
  ("rebuilt multiple times in the same frame"). The offer now waits a
  moment.
- The falling street's long way round costs no extra day (its note says
  half a day).

## [1.291.0+327]

The skill choice sheet, places heard of on the full map, and the land crossing in the desert side view.

### Added
- **The face's skill sheet (board 9):** opened from a die face, it lists each skill with the face now and the face after (`Attack 5 → Attack 8`), the change as a pill (+3, changes kind, full), the skill's limit in its rarity colour, and, after a tap, a bar with **Set on this face**: nothing is set until it is pressed. The numbers are the fight's own rule for a face with a skill on it. The 70% rule is behind the title (hold it).
- **Places heard of on the full map:** a "?" in a ring where they lie. Tapped, the sheet offers **Set out** (for a village not yet found, the expedition that finds it, sailing the Eel first when needed; always with the warning that the road may hold anything) or says why it cannot yet, and **Mark as goal** (one goal at a time, ringed on the map).
- **The land crossing in a side view:** the desert crossing wears a scene over its words: a warm sky in dithered bands, a low sun, mesas with the goal coming nearer day by day, three bands of dunes and a path at their own speeds, and the party's placeholder figures walking in place. Heat shimmer in clear weather, a sandstorm on the sandstorm event or a dust sky, rain, snow, ash or fog by the sky. The day and the health bar sit over it. A route whose terrain has no scene yet keeps only that strip. Reduced motion stands still. (`lib/widgets/side_view/`: the scene engine, for the voyage's side view later.)
- **The ruins in side view:** a route of terrain `ruins` (Core's camp-to-quarter road) is drawn with its own scene: a burnt dusk, a far broken skyline, ruined walls and arches, rubble, a path of grey cobbles, and the quarter's tower with one lit window coming nearer by the day; ash falls by default.

### Changed
- The full map's place sheet scrolls when its text is long.

## [1.290.0+326]

The Shroud Shrine within reach.

### Changed
- **More Shroud thread and tear glass in chapter 5:**
  - the Dead Heart approach pays 2 Shroud threads (was 1);
  - the Frost Quarry adds 1 Shroud thread and 2 tear glass;
  - the Ember Run adds 2 tear glass.
- **The Shroud Shrine costs 2 000 gold** (was 2 600).
- The playthrough simulator (held-out seeds 101 and 103, 100 runs each)
  now builds it in 42 to 43 runs (was 7), in chapter 6 at the median,
  within its tier's chapters. The Banner Loft, which used to take the
  thread the shrine needed, goes up in chapter 5 in a quarter to a third
  of runs (was none). The shrine still waits on the Dead Heart approach
  being cleared, which about 45% of runs do.

## [1.289.0+325]

The bosses after chapter 1 are a little tougher, so that the playthrough
simulator, now playing the camp's expeditions, still meets them on the
user's curve.

### Changed
- **Ten bosses re-tuned** (health and damage):
  - Void Stalker 147→168 health, 20→22 damage;
  - High Inquisitor 165→203, 23→27;
  - Bone Warden 229→282, 25→29;
  - Void Archon 235→282, 22→26;
  - White Admiral 305→336, 28→31;
  - Claimant Vane 276→317, 29→32;
  - Claimant Tallis 203→248, 19→22;
  - Claimant Morrow 375→398, 22→23;
  - Tear Herald 264→306, 24→27;
  - Void Sovereign 332→359, 28→30.
  
  Tuned on the held-out seeds 101 and 103: every boss is within about 7
  points of its target (75% in chapter 1 down to 35% in chapter 8), with a
  mean of 50.5%. Aurel Vane (chapter 1, before the camp) is unchanged.

- **"Play to chapter" hands back a character as strong as a run that played
  the camp's expeditions.** Its arrival table was regenerated from the
  800-run check (seeds 11 and 23): chapters 4 to 8 now arrive at levels 8,
  11, 13, 15 and 16 (were 6, 8, 10, 11 and 12), with gold to match (5 710
  in chapter 8).

### Simulator
- **The walk plays the camp's expeditions.** At the camp, once every place
  is toured, it plays each expedition of the chapters reached, once,
  before the main quest, as "Play to chapter" does. One cleared may open
  the next. Its XP, gold and materials made the bosses after chapter 1 won
  12 to 26 points more often, hence the re-tune.
- **The camp's works now come as the materials note meant** (24 runs):
  - the Hammersmith, the Academy and the Needle House in chapter 3;
  - the Hearth-Hall in half the runs, chapter 4;
  - the Banner Loft in about half, chapter 6.

## [1.288.0+324]

One apostrophe for the whole game's descriptions.

### Changed
- **Descriptions in the game data use the curly apostrophe.** 341 texts in
  `companion_remarks`, `enemies`, `enemy_ships`, `houses`, `item_sets`,
  `items`, `ports`, `races`, `ship_parts`, `shops`, `skill_trees`, `skills`,
  `spells` and `zones` had a straight apostrophe in the middle of a word
  ("Kelda's", "l'esquive"); they now read like the story's own text, in
  English and French. Names (`itemName`, `shopName` and the like) and ids are
  left alone for a later pass, so nothing a test or a save matches on
  changes. The jungle biome text from #207 was read and needs no change.
  Text only; no ids, numbers or flags changed.
## [1.287.0+323]

Groundwork: places only heard of, the building screen's data, the skill
choice helper, and the second desert leg.

### Added
- **Places only heard of.** For each place the full map draws as "?",
  `heardOfPlacesProvider` says what its sheet offers:
  - **Set out** straight there, once the place is found and its chapter is
    open, a road leads there (by sea once the harbour stands), and the camp
    stands;
  - **Set out by its expedition**, for a village not found yet: the
    expedition that finds it (`discoversPlaceIds`), sailed to first when it
    sets out from another port. A village not found is reached only that
    way (the user's decision);
  - **Mark as goal** otherwise, with the reason: the story will take you
    there, not before the camp, a later chapter, the harbour first, or an
    expedition to clear first.
  
  One map goal at a time, kept as a flag and gone once the place is
  reached. Narrative wrote the reasons and the warning. The full map's
  sheet is UX's to come (`setOutToHeardOf`, `mapGoalProvider`).
- **The building screen's data** (`campWorksProvider`):
  - the camp's ten houses in four sections (the Sea, the Company, the
    Workshops, the Great Works), each section with its name and blurb by
    Narrative;
  - each house coming with its tier's chapter;
  - its state (locked, shown, buildable, built) and what it still needs,
    with where to find it (the expeditions that open it or pay its
    materials, the shops that stock them).
  
  The screen is UX's to come.
- **The skill choice helper** (`faceSkillChoice`): what a skill on one face
  of a die would change, worked out the way a fight does. It gives:
  - the face before and after;
  - gain or loss;
  - the rarity limit;
  - why it can't go there.
- **The second desert leg:** from the Sleeper's Face to the White Wells
  (2 days), on every way into the Wells. It brings two new events, a flash
  flood and a water-seller (whose line is Narrative's). Every route now
  names its terrain for the side view's scenes.

### Changed
- **A lost crossing is no longer a free rest.** The party is carried back
  with what it set out with, at most half its health and at least a
  quarter (QA found a party that set out low came back at half). Set out
  again after a lost crossing, a choice's check and fight are not played
  twice.
- **A camp house comes with its chapter.** A house can't be built before
  its tier's chapter, or before its companion joins. The Town card says
  "Not yet: chapter N".

### Text
- Narrative's material names and notes ride along (from
  `claude/narrative`).

## [1.286.0+322]

Nine pixel icons for the building materials, and chips for them on the camp's build cards.

### Added
- **Pixel icons for the nine new materials** (timber, cut stone, slag glass, ash-steel, rime crystal, tear glass, Shroud thread, lantern brass, white-fleet oak): 16×16 at 8×, in the iron ore's outline and shading. They replace the borrowed iron-ore icon (`tool/gen_material_icons.py` draws them).
- **Material chips on the camp's build cards:** what a house costs beside gold, as each material's icon and count (`2` when held, `1/2` in red when short). The card's status tag now says "need materials" and the chips say which.

## [1.285.0+321]

Land expeditions, the first: the crossing from the wreck of the Lark.

### Added
- **Land crossings.** A long land route is played like a voyage, on its
  own screen: an event a day (a sandstorm, a dry well, a spring, a mirage,
  scavengers, shade), each asking what the party does. Some choices roll
  an ability check, one harder a chapter after the first.
  - **Health plays the hull.** Each outcome costs or gives a share of the
    party's maximum health, and sometimes gold or an extra day. If health
    runs out, the party is carried back to where it set out at half
    health, with the days spent, and the story choice is not taken. The
    party can also turn back at any time.
  - **The first crossing** is from the wreck of the Lark to the Sleeper's
    Face (3 days, desert): every way out of the wreck takes it. The
    Sleeper's scenes stay as they were.
  - **Data:** `land_routes.json` and `land_events.json`, editable in the
    database editor. A story choice names its route with `landRouteId`.
  - **"Play to chapter" and the playthrough simulator** play crossings
    with the same rules. The simulator rolls them on a stream of their
    own, so the walk's seeded results stay comparable.
  - **A tutorial** for crossings, shown the first time the screen opens.
  - The screen is a plain one for now; its side view is UX's to come.
    The event and tutorial texts were read by Narrative, who kept them and
    gave the route its geography names.

### Changed
- **"Play to chapter" hands back a stronger character late in the story.**
  Its arrival table was regenerated from the 800-run simulator check after
  the boss curve, the materials and the harbour. Chapters 6 to 8 now
  arrive at levels 10, 11 and 12 (were 9, 10 and 10), and the gold moved
  a little throughout.

### Fixed
- A scene whose one way on crosses land or grants materials is no longer
  read straight through, so neither is skipped.

## [1.284.0+320]

The harbour has a reason to be built.

### Changed
- **The camp scene says where the harbour's timber and stone come from.**
  In `3001_camp` the survivors stack the storm's and the tide's spars and
  planks in one heap and the burned wall's sound stones in another: timber
  for a quay, stone for its foot, which is what Core's grant on `3001` puts in
  the pack. The camp tour's first step (`tut_camp_harbour`) now says the same
  in the narrator's words, in English and French, with the typographic
  apostrophes and the space before the colon. Text only; no ids, numbers or
  flags changed.

## [1.283.0+319]

The harbour: the story hands over what it costs, and the camp builds it
first.

### Added
- **A story choice can grant materials**: `grantMaterials`, an object of
  item id to count (`{"material_timber": 4, "material_cut_stone": 2}`).
  They go in the pack with a "Picked up" notice. The story, "Play to
  chapter", expeditions and the playthrough simulator all apply it, and the
  story editor keeps it. The camp's founding choice ("Take stock of the
  shore", in chapter 3) grants the harbour's 4 timber and 2 cut stone;
  Narrative writes the scene's line for it in a later PR.
- **The camp's tour starts at the harbour** while it is unbuilt. A harbour
  card sits above the camp's tabs until it stands, and a tap on it opens
  Town.

### Changed
- **The harbour costs only its materials**: 4 timber and 2 cut stone, with
  no gold, so the story's grant covers it.
- **The Rusty Eel waits on her harbour.** Once the camp is founded, every
  voyage away from it is refused until the harbour is built, with a notice
  pointing at Town. Sailing home is never refused. If the pack can no longer
  pay for the harbour (the grant spent on another building, or sold), she
  sails anyway, so no game is stranded. Her refit already waited on the
  harbour.
- **"Play to chapter" builds the harbour** when its walk founds the camp.

### Fixed
- Saves get version 5. A save from before it that has passed the camp's
  founding has the harbour built on load, once.

## [1.282.0+318]

The full-screen map, the help pattern on ten more pages, and small fixes.

### Added
- **The full map.** The Journey's own chart (sphere or flat, layers, weather)
  on its own page, opened from a **Full map** button among the Journey chart's
  controls, and from **On the map** on each known place of the camp's Road tab
  (it opens on that place with its sheet up). A tap on a reached place opens
  a sheet: where the party stands, **Travel here** (the camp's own way to
  travel; disabled during a fight or an expedition), or why it cannot. Under
  the chart: **Legend** (the marks as the chart draws them), **The story**
  (the Journal's story so far) and **Journeys** (the roads walked, by
  chapter; a tap turns the chart to where one ends). The layers sheet is
  shared by both pages.
- **The guide's ⓘ** in the header of the Skills, Inventory, Level Up,
  Journal, Achievements, World map, Skill challenge, Harbor, Port and Shop
  pages: it replays that page's tour.

### Changed
- "1 Stat Point" and "1 Point de statistique" in the singular (and 0 in
  French).
- On a screen narrower than 340 px the Journey's weather chip is an icon (a
  tap reads the line), so it no longer covers the lowest step's name.

### Fixed
- The dice loadout's "Choose this face's skill" button stays in sight under
  the die card's scrolling text.

### Removed
- The flat travel page and its compass button, replaced by the full map; QA's
  guard of that page (`qa_travel_map_test.dart`) goes with it.

## [1.281.0+317]

Materials: the camp's buildings are raised with what the road brings back.

### Added
- **Ten materials in four tiers**, one tier for each stage of the story.
  Timber and cut stone (chapters 1-2); iron ore and slag glass, with the
  rare ash-steel ingot (3-4); rime crystal and tear glass, with the rare
  Shroud thread (5-6); lantern brass, with the rare white-fleet oak (7-8).
  Names and descriptions in English and French, for Narrative to reword.
- **Where they come from.** Expeditions pay them on completion (each
  chapter's main expedition its tier's rare); ordinary foes drop the commons
  (12%); the weaponsmith, the hammersmith and the Last Lantern sell the
  commons, never a rare; a derelict's salvage at sea yields the chapter's
  common, and a won ship battle the chapter's rare from chapter 3 on.

### Changed
- **The camp's buildings cost materials beside gold**, and about a third
  less gold: Kelda's hall 100 gold and 2 timber, the harbour 170 gold, 4
  timber and 2 cut stone, the hearth hall 1 000 gold with iron ore, slag
  glass and 2 ash-steel ingots, the Shroud shrine 2 600 gold, tear glass and
  3 Shroud threads, and so on. A building's card says which materials are
  missing.
- **Older saves** (save version 3) are given, once, one rare material for
  each tier their story has already passed, so the buildings that need them
  stay within reach.

## [1.280.0+316]

The bosses are won about half the time: more often early, less often late.

### Changed
- **The boss curve.** Every chapter boss was lost 80% to 95% of the time.
  By the user's decision, each is now won about this share of the time
  where the story meets it, after the chapter's own fights: Aurel Vane
  (chapter 1) 75%, the void stalker (3) 65%, the Hollow Court inquisitor and
  the bone warden (4) 55%, the void archon (5) 50%, the white admiral (6)
  45%, the three claimants (7) 40%, the tear herald and the void sovereign
  (8) 35%. Numbers only: each boss's health is scaled, and its damage by
  the square root of the same factor, so a fight keeps its shape and gets
  shorter (the inquisitor, the hardest, loses half its health). In the
  simulator, the bosses go from 18% to 49% won on average (800 runs), and
  the attempt win rate from 39.8% to 45.1%.
- `boss_balance_test` checks the curve with the simulator (200 seeded
  runs), and `docs/simulation/` is regenerated with a before and after.

## [1.279.0+315]

Twelve story achievements.

### Added
- **Twelve achievements that come from what a save already holds.** The
  Lantern Throne, Half a Banner (three pieces of the Shroud), Whole Cloth,
  A Loose Thread (settle an intrigue), The Whole Web (all eight), Time
  Turned (a New Game+), Sworn, Hunted, A Hand at Four Doors (trusted by four of
  the six clans at once, with no oath sworn) and three village finds: Where the Bells Hang (Akagiri), Every
  Bargain to the Minute (the Kindly Hill) and Under the Giants' Roof
  (Highhearth). Each is a one-line check in `checkAchievements` over the
  flags, banner pieces, politics and New Game+ cycle of the save, with its
  English and French row in `achievements.json`; none needs a new counter.
  A save that already has the thing unlocks it the next time achievements
  are checked, and achievements are now also checked right after a story
  choice adds a flag or a piece of the Shroud and after a choice's politics
  (an oath, a standing, an intrigue's end), so taking the Throne unlocks
  its achievement at once. "Hunted" counts the six coast clans, not the
  tribes. `test/achievements_story_test.dart` covers each.


## [1.278.0+314]

A jungle on the story world's east land.

### Added
- **A jungle biome.** The equatorial belt of the story chart's east land is
  now jungle instead of temperate woods: warm (+3 °C) and wet (moisture
  0.9), drawn in deep green with dense woods, pools and hills. Its
  description, six animals, six plants, three weathers and two road hazards
  (a swollen river, jungle fever) are in English and French, for Narrative
  to reword. No story road crosses it yet, so its hazards cannot fire.

### Fixed
- **"Play to chapter" no longer hands back a queue of clan offers.** The
  arrival top-up's levels each queued an offer, so a jump to chapter 8 opened
  on ten offer dialogs in a row. The offers those levels queued are dropped;
  any the walk itself earned stay.

## [1.277.0+313]

The travel map, and a pack of layout fixes.

### Added
- **A map of where you have been.** A compass button in the Journey's header
  opens the story world with the road taken in order (sea legs dashed), the
  places reached by name, the places only heard of as "?", and a dotted ring
  round each place the camp can travel to. A tap on a ringed place offers
  the journey; on a place only heard of, it says the road is not open yet.
  The names are laid out clear of each other, also on the crowded north
  continent, and kept inside what the screen shows; the box round the chart
  is the colour of the uncharted. It zooms and pans.
- **Tap a built building in the camp town** to read its name and what it
  gives.
- **Help pattern.** An ⓘ in a page's header replays the page's guide; holding
  a section name explains it. First on the dice loadout, where the two
  paragraphs under "Faces" are now behind the title.
- A spoken label on the Gifts tab's dot (`gifts_waiting_label`).

### Changed
- **Dice loadout:** the die card keeps one height whatever face is picked.
- **Camp town cards:** the status sits above the name, so "Hammersmith",
  "Storehouse", "Watchtower" and "Smugglers’" are never broken inside a word.
- **The Shroud card** on the Character page's Pages tab is one row of six
  small banners (the names are a tap away).
- **Tour step 4** of the Character tour describes the three tabs.
- **Voyage:** a storm's rain falls over the Eel's water only, no longer
  behind the words and the buttons.
- **Journey:** the "You are here" badge is kept clear of the step names, and
  the weather line wraps clear of the zoom button.
- **Chapter 7 camp hub:** the enter-the-place button scrolls in the room it
  has, so a long quest strip no longer overflows it at 320 px.
## [1.276.0+312]

The empty lands of the story chart have names.

### Changed
- **Seven unnamed lands on the story chart are named, in English and
  French.** The Tallow Downs (Les Landes de suif), the Pale Dunes (Les Dunes
  pâles), the Tidewood (Le Bois des marées), the Orchard Coast (La Côte des
  vergers), the Ember Dunes (Les Dunes de braise), the Wick Meadows (Les
  Prés de la mèche) and the Mute Ice (Les Glaces muettes). The chart's
  "unnamed" exemption in `chart_relief_test` is gone: every zone of every
  chart now has both names. Text only; no shape, biome or place moved.

## [1.275.0+311]

"Play to chapter" hands back a character fit for the chapter it reaches.

### Changed
- **A jump in the simulator's "Play to chapter" (edit mode) tops the
  character up on arrival.** A long jump used to force its last fights and
  hand back a level 3 to 5 character with one or two pieces worn, even at
  chapter 8. On reaching the chapter, the character is now brought up to
  where a typical run arrives there: its level and gold are raised to the
  simulator's median (chapter 6: level 9 and 2 330 gold; chapter 8: level 10
  and 3 240), and, per slot, it receives the best piece the chapter's open
  shops and chests hold that it may wear. Only ever up, never down. The
  levels come as a won fight's would, with their stat points and full
  health, and the best build of 1.274 then spends and equips them.
  Deterministic, and only in edit mode.

### Added
- The land expeditions proposal (`docs/proposals/`) is updated to the
  user's decisions: the party's health plays the hull (no water or food, no
  new save field), and the crash is the first expedition.

## [1.274.0+310]

"Play to chapter" hands back a character ready to play.

### Changed
- **The simulator's "Play to chapter" (edit mode) leaves the best build.**
  Before handing back, it spends the stat points on the profession's own
  stat, wears the best carried piece in each slot (stat and alignment
  requirements met, a copy no companion wears), and puts the best unlocked
  skills on the die's open Skill faces, each on no more faces than its rarity
  allows; the mana skill keeps its face. It is the playthrough simulator's
  own policy, so the character handed back is the one the simulator's
  numbers describe. The build has no randomness, and the walk takes an
  optional seed, so a seeded run hands back the same character every time.

## [1.273.0+309]

Ten new moods, and the scenes that wear them.

### Added
- **Ten scene moods: wistful, solemn, tender, uncanny, wry, defiant,
  mournful, ominous, bitter and wondrous.** Each is a tag string pair
  (`mood_<name>`) in English and French, and 101 scenes carry one: the
  crowning scenes are solemn, the Saltmouth card games wry, Highhearth
  wondrous, the Hollow Shore reflections uncanny, the drowned and the
  vigils mournful. Only scenes that were not already tense, action,
  suspense or desperate were re-tagged, so no random-detour gate changes.
  `defiant` and `ominous` are not tense moods; Core can add them to
  `tenseMoods` later.

## [1.272.0+308]

The travel-history map's data, for the view UX builds beside the Journey.

### Added
- **The story world is a chart the game can use.** The story-true world
  (the cold north, the Waste on the dry belt, Alster's vale) moves from the
  chart tool into the game as a fourth geography, with the clans' seats, the
  stone giants and the other places the story names. It is the travel map's
  own chart and is not offered among the world map's looks.
- **The party's travels, read from the story.** The places reached in the
  order first reached, every move between two places with the roads it took
  and whether by land or sea, the places only heard of (the far ends of known
  roads, to show as "?"), where the party stands, and the reached places the
  camp can travel to. All of it comes from the scenes already saved: no new
  save field, so every save shows its whole journey.

## [1.271.0+307]

The Broken Charter is played end to end.

### Added
- **Five scenes for `broken_charter`, the last intrigue still short.**
  Compact-stamped blades on Inquisition belts at the wharf
  (`2015_dominion_blades`), the Tribunal's purse offered to the Scaffolders
  on the Spire stair (`3005_tribunal_gold`), the Anvil-Deaf vote in signs on
  Wrack's End quay (`5100_anvil_deaf_vote`), the Row and the Tribunal
  meeting at the Rimewell quarry (`6100_charter_signing`) and, at the
  Anchorage, the Charter signed again or burned (`7100_charter_choice`).
  Earlier choices are remembered in later scenes, and two new lines at the
  Herald's battle (`7810`) remember which way the Charter went. The
  intrigue's stage `chapter` labels now match where the scenes sit, and the
  Reveal's contact is the Tribunal's last clerk.

### Changed
- **The three chapter 7 quests read shorter and one notch easier.** Their
  objectives are "Read the petition", "Read Morrow’s terms" and "Copy the
  tide table" (the quest strip overflowed at 320 px), and their difficulty
  shows 13 instead of 14 (display only).

## [1.270.0+306]

Chapter 5 is no longer the wall.

### Changed
- **Chapter 5's enemies hit less hard.** The void hound used the legendary
  Venomous Ambush on 30% of its turns, a hit no other ordinary enemy has; it
  now does on 12% (pack howl 25% to 20%), with 135 health and 16 damage
  (was 155 and 20). The inquisition penitent (220 / 22, was 260 / 26), the
  masked penitent (215 / 21, was 250 / 25) and the Unstitched (255 / 24, was
  300 / 28) lose about a sixth of their health and damage. The void archon
  goes to 340 / 27 (was 380 / 32), with Void Blast on 30% of its turns (was
  40%) and Eclipse on 25% (was 35%). In the simulator, chapter 5's attempt
  win rate goes from 21% to 31% over 800 runs, between chapter 4 (36%) and
  chapter 6 (31%); chapters 1 to 4 do not move, chapters 6 to 8 rise 1 to 3
  points.
- **The simulator's report shows where each chapter is lost.** Its JSON adds
  every enemy's encounters and losses per chapter, and the level and gold
  with which each chapter is reached; `docs/simulation/` is regenerated with
  a before and after.

### Added
- Two proposals for decision in `docs/proposals/`: a building economy with
  materials, and land expeditions in side view.

## [1.269.0+305]

Three visitors at the cove, and a quest goal for chapter 7.

### Added
- **Three side quests before Candlehold.** A Reed Gate factor, an Order
  herald and a pilot's boy sent by the chain-master come to the cove camp.
  Each has a scene to hear them out and a second one to follow up, then a
  turn-in with two ways to answer (`q_ch7_reed_gate_grievance`,
  `q_ch7_heralds_errand`, `q_ch7_chain_masters_boy`; scenes `7400_reed*`,
  `7400_herald*`, `7400_chain*`). Six new gate lines at Candlehold (`7500`)
  remember how each was answered.

### Changed
- **Chapter 7 now asks for one quest before the sail.** `questGoal` goes from
  0 to 1 in `chapters.json`, so the camp's "Sail for Candlehold" opens once
  one of the three is turned in; the chapter hint says so. The rewards of
  the three quests (170 to 190 gold, 220 to 240 XP, difficulty 14, and a gear
  piece each: a coat, a helm and a blade already in the game) and the
  small standing changes of their turn-ins are placeholders for Core to
  confirm. `chapter_loop_test` lists the chapter 7 quests and the new goal.

## [1.268.0+304]

One spelling for two place names.

### Fixed
- **"Smugglers’ Wharf" and "Haut-Âtre" read the same everywhere.** The
  wharf's port, its Vault shop, the Cellar house and one item description
  used a straight apostrophe where the rest of the game uses the curly one,
  and the chart labelled the giants' hall "Hautâtre" while the map, the
  story and the French strings say "Haut-Âtre". Text only; no ids, numbers
  or flags changed.

## [1.267.0+303]

The clans' offer, the loot chest, the dice cube, the Clans screen, the Character
page and the race and profession recap.

### Changed
- **The offer's banners are one size, picked or not.** Unpicked banners were
  drawn at twice the size of the picked one, so they grew and shrank. A tap
  picks one (it takes the wind); press and hold is gone. The chosen banner's
  words show in a zone of one fixed size under the banners; with none chosen
  it says "Select a banner to see its details." (`offer_select_hint`, which
  replaces `offer_hold_hint`).
- **The loot chest hides its rarity until it is tapped.** Before: one neutral
  grey chest, no tier name or colour, no fortune roll. A tap turns the tiers'
  colours, slower and slower, and stops on the real one; the name, the art
  and the fortune roll then appear and the chest opens. A second tap skips to
  where it stops, a third opens it. With reduced motion it opens at once.
  The rarity was rolled before; this is only how it is shown
  (`chest_skip_hint`).
- **The Throne room is the first tab of Clans, then Reputation, then the rest;**
  the screen opens on the Throne room.
- **The Character page is three tabs under its header** (name, level, vitals,
  "Level Up" when points wait): *Overview* (the eight abilities as a radar, the
  skills known as chips, the alignment), *Gifts* (the offer waiting, titles as
  chips, perks, signs; a dot on the tab while an offer waits) and *Pages*
  (mana and spells, the Shroud, New Game+, the links to Inventory, Dice,
  Level Up and Race and profession). It replaces the folded version of
  v1.266 (`tab_overview`, `tab_gifts`, `tab_pages`).
- **The race and profession recap is a dossier**, about a screen and a bit
  instead of three and a half: the name and level, the two choices as rows
  (numbers they change, the skill they grant), health and experience as thin
  bars with damage and armour, the radar beside the eight numbers, the
  elements as chips, the belongings as one line. A tap opens what needs room
  (a choice's lore, the elements' chart, the belongings' list); a press and
  hold on a number says what it does.
- The Character page's offers row says where offers come from on a press and
  hold (`offers_where_from`), in place of the paragraph of the old panel
  (`OffersPanel` and `offers_none` are gone). French `titles_chip_hint` keeps
  its non-breaking spaces before the colons.

### Fixed
- **The dice cube could not be turned sideways from its top or bottom.** It
  kept a yaw about its own upright, so once tipped a drag across only spun it in
  place. It now turns on the screen's axes, so a drag in any direction works
  from any side.

## [1.266.0+302]

The Character tab and the race and profession recap, shorter to read.

### Changed
- **Skills first, with a radar.** The tab opens on the skills known (their
  icons and names, "All skills" for the rest) beside a small radar of the
  eight abilities; the eight numbers that sat further down are gone (the
  radar writes them at its corners). The page links are four tiles:
  Inventory, Dice, Level Up, Race and profession. The Skills link is now the
  skills card's own.
- **Titles are chips.** One chip per title held, the one worn in gold; a tap
  wears it or takes it off, a press and hold reads it (what it does, its
  words, why a bad one stays). A bad title ("the Marked") shows a warning
  and has no tap.
- **Perks and signs fold to one line each**, with their count and their names
  in the line; a tap opens them in place. Perks read one line each, with the
  whole text behind a tap. The empty case is "None yet" instead of a
  paragraph.
- **Offers are one line**: "Offers · Choose a gift · 1 waiting" opens the
  offer; with none, "No offer waiting".
- **The Mana card opens the skills on their Spells tab** (it opened the
  Tree).
- **The race and profession recap is one row per choice**: its mark, name,
  tag, the numbers it changes as chips and the skill it grants as a line; a
  tap opens a sheet with the lore and the skill's words (nothing was cut).
  The two lore cards and the two skill cards, a half screen each, are gone.

### Added
- New strings (English and French): `tile_inventory`, `tile_dice`,
  `skills_see_all`, `skills_none_short`, `titles_chip_hint`,
  `gifts_none_short`, `offers_row_none`, `recap_who_you_are`.
- `test/character_tab_test.dart`: the tab and the recap at 360 and 320 px, in
  both languages, with the app's own fonts.

## [1.265.0+301]

### Fixed
- **The simulator's "Play to chapter" button could not be reached on a phone.**
  With no batch yet, the strategy, runs and chapter controls were taller than
  the screen and did not scroll, so the button ended past the bottom edge.
  They now scroll with the results (`PlaythroughSimulatorScreen`); once
  there are results the compact bar and the scrolling results are as before,
  and scrolling down no longer folds the controls away. Checked at 360 x 640
  and 320 x 568, in English and French, with the app's own fonts and a 48 px
  system bar (`test/simulator_insets_test.dart`).

## [1.264.0+300]

The level-up pop-up, the clans' offer and the dice, redrawn; and a story-true
world chart to look at.

### Changed
- **The level-up pop-up wears the Level Up screen's design.** The medal and
  its pixel burst, the level and the points to spend stay at the top; the
  stats scroll below in four groups (fighting, body, mind, fortune) as seam-
  bordered rows with a gold value and a "+1 Point". A tap or a long press on
  a row says what the stat does. The screen and the pop-up share one list
  (`LevelUpStats`), so they read alike.
- **The clans' offer is three little flags.** Each suitor is a flag showing
  only what the choice turns on: the gift's kind, name and rarity, and the
  first standing it moves. Hold a flag to read the rest (the clan, its intro,
  what the gift replaces and the politics of the pick); it goes when the
  finger lifts. The chosen flag waves, the others dim.
- **The dice roll sits under the fighters**, below the party and the
  enemies, instead of above them.

### Added
- **A story-true world chart (docs and tool only).** `tool/fmg_chart/` draws
  the story's world with Earth-like climate bands, archipelagos kept empty
  for ship content and a globe render; previews are in
  `docs/maps/fmg-chart/` (see `STORY-WORLD.md`). Nothing in the game reads it.
- New string `offer_hold_hint` (English and French).

## [1.263.0+299]

Two choices at the Hollow Shore can be seen at last.

### Fixed
- **The Admiral's log and the throne vote were never offered.** "Decide who
  reads the Admiral's log" and "Cast the Admiralty's vote for the Lantern
  Throne" sat on the Hollow Shore (`7002`), which every run visits before
  the Anchorage sets the flags they need, and chapter 8 hides them again.
  Both choices are now offered from Greyhithe (`7200`), after the Anchorage,
  and their scenes (`7002_orders`, `7002_throne`, same ids as before) lead
  back there. No numbers or flags changed. Fixes #182.

## [1.262.0+298]

Fight tests roll the same dice every run.

### Changed
- **A fight can be given its dice.** `FightScreen` takes an optional
  `random:`, and the new `fightRandomProvider` (a Random factory, like the
  road's) hands every fight its Random, so a test that reaches a fight
  through another screen (the ship battle's boarding) can seed it too. In
  play nothing changes: each fight makes its own unseeded Random. Every roll
  of the fight screen already came from that one Random (the faces, crits and
  dodges, the enemy's moves and targets, the affixes, the ground and its
  anomaly, the loot); the plan of an anomaly the story forces is made before
  the fight, by `forcedFieldAnomaly(id, random:, side:)`, which already took
  its own.

### Tests
- The fight widget tests that assert an outcome (18 files, from `clash_test`
  to the `skill_*_fight_test` harness) run on `Random(7)`, so a dodge, an
  affix or an anomaly cannot turn up in one run and not the next.
- `fight_mirror_spell_test` reads the Mirror's line, not the Venomous
  affix's "You take 3 damage from poison." that it could match first.

## [1.261.0+297]

The people of the coast speak for themselves.

### Added
- **Thirty people have words of their own.** Aurel Vane, Overseer Renn, Nadira, Maud Tallis, Hesk Morrow, Brother Clement, the Keyholder, the chart-keeper, the High Warden, the Tear-Herald, Hathra, Tetsu, Ghrem Stonebrow, Orsabet Vell, Nkem Tallow, the White Admiral and fourteen more now say three lines each on their People page, in both languages (before, only three people did).
- **Six follow-up scenes are spoken by the person they are about**, under their name: Ghrem on the pier, the headman of Wrack’s End, the flagship’s helmsman, the smith’s widow, the eldest of Greyhithe and the road-keeper. Hathra, Tetsu and Tobin gain a spoken line in theirs.

### Fixed
- "l’Ancrage" in two scenes at the White Anchorage is "le Mouillage" in French, as everywhere else.

## [1.260.0+296]

Five more plots play out: every intrigue now runs from its first clue to its outcome.

### Added
- **Five intrigues play end to end.** *The Double Ledger*, *The Admiralty’s Silence*, *The Relic Road*, *The Returned* and *The Unwatched Hour* each have a scene for every stage, in both languages: thirty new scenes in all, offered by a place’s hub once the stage before is reached (Saltmouth, the Ashen Quarter, Emberwick, the Drowned Cloister, Wrack’s End, Rimewell, the Reliquary Quarter, the White Anchorage, Greyhithe), and a closing scene at Greyhithe that settles the plot. Every choice of a stage scene advances the plot, so none can stall.
- **The endings answer back.** What you did shows in the closing scenes: the Crows’ brigs at the landing (`7810`), the Returned children at the water’s edge (`7002_approach`), the second door sewn into the tear (`7003`), the relic and the Fourth Piece in the epilogue (`7004`).
- Stage anchors in `intrigues.json` match where the scenes play (people met in the scenes now carry the plot in their People page).

### Docs
- `docs/chapter-flow-roadmap.md` lists the scenes of all the intrigues; only *The Broken Charter* still has one stage (its coal event).

## [1.259.0+295]

Two flaky tests traced: one was the test, one was a real clipped label.

### Fixed
- **The anomaly chip no longer overflows on a narrow fight.** The chip in
  the fight's header (an anomaly's name, then "soon" or the rounds left)
  was a row around an unwrapped label, so a long name plus its suffix, such
  as « Lumières dans les roseaux · 3 manches restantes », ran past the edge
  of a phone. The label now takes the room there is and ends in an ellipsis;
  the tooltip still shows the whole effect. It also removes a 1 to 2% flake
  of `ship_boarding_retreat_test`.

### Tests
- `test/clash_test.dart` accepts a dodged blow in the parry round. A
  character with no dexterity still has the 5% dodge floor, and a dodged
  blow is not parried by design, so the log then says "you dodge it!"
  instead of "turned aside and answered" (about 4% of runs).

## [1.258.0+294]

The main-quest chain runs in story order, chapter 7 gets its quest, chapters end with a card, and the English text follows the French in using one apostrophe.

### Added
- **A main quest for chapter 7, "The Lantern Throne".** Offered when the party sails for Candlehold; done when the Throne is taken, by any of the seven roads. Its rewards (350 gold, 450 XP) are placeholders for Core to confirm.
- **Chapter-end cards.** Chapters 3, 4, 5, 6 and 7 close with a `[CHAPTER N END]` card (in French `[FIN DU CHAPITRE N]`) on the scene that closes them, like chapter 2 already did: the Warden's standard, the moon-shard, the Dead Heart, the White Fleet's sail and each of the seven crowning scenes.
- **A tag for the "hopeful" mood.** Eleven scenes carried the mood with no label.

### Fixed
- **The main quests chain in order.** Finishing the Dead Heart no longer puts the Sovereign's quest in the log at the end of chapter 5; it now leads to the White Fleet's Grave, which leads to The Lantern Throne, which leads to Beyond the Tear.
- **"Beyond the Tear" is a chapter 8 quest.** Its id (`q_ch6_beyond_the_tear`) is unchanged so that saves keep working; only its chapter changes.

### Changed
- **One apostrophe in the English story text.** All the straight `'` in the English story, quest, people, companion and remark text are now the curly `’`, as the French has been since 1.255.0 (names too, such as "The High Warden’s Fall"). Nothing is recorded for read-aloud yet, so no recording is made stale.

### Docs
- `docs/narrative-proposals.md`: what Core is asked to decide for chapters 7 and 8, three intrigues for them, new moods and themes, and a list of achievements, for the user to choose from.

## [1.257.0+293]

The UX polish proposed in the design-system review.

### Added
- **One page transition for every screen.** A new page fades in over 180 ms
  while rising 12 px (`InkPageTransitions`, on every platform); with reduced
  motion the pages just swap.
- **The title screen's standard blows in the wind.** The Void's banner uses
  the throne room's gusts, ripple and hem flutter (`WindBanner`; the wind
  painter and the banner image cache moved out of `throne_room.dart` into
  `wind_banner.dart`).
- **A pixel flourish for a level gained and a chapter opened** (`PixelMoment`):
  the fight's strips recoloured to gold (a starburst, a ring and a rain of
  sparks behind the level-up medal) or to the chapter's colour (a ring and a
  spark rising from the chapter card).
- **Empty and error states with the companion.** `InkEmptyState` and
  `InkErrorState` seat the dog by the message in place of a bare line of text
  (the journal, the clans list, an empty shop, no dice, and every "failed to
  load" on the race, dice and shop screens).
- **A tablet layout.** From 840 px wide the Home tabs sit in a rail down the
  left edge instead of the bar at the bottom, and the app keeps to 1280 px,
  centred, on a larger window.

### Changed
- **Patrons are shown by their pixel banner.** The patron emblem (offers, the
  Clans screen, signs) is the top sign off the clan's pixel banner on a dark
  tile in its colour; a patron without a banner keeps its icon on a disc.
- **The standing meter moves.** When a standing changes the tick slides to its
  new place over 600 ms and the stretch it crossed glows gold for a gain, red
  for a loss, and fades.
## [1.256.0+292]

A way out of a place leaves by its road, and says which.

### Changed
- **A way out to another place leaves by the first stop of its road.** On the
  Journey map the mark of a way that leaves the location sits toward the
  first stop of the road it takes, not straight toward where it ends, so the
  marks of the roads out of a place point where the roads go.
- **The picked way names its road.** Under where it leads, the details of a
  picked way out list the stops it passes ("Road: The Harbour Chain · The
  Painted Sails"), in English and French.

## [1.255.0+291]

A text pass over the story: the Shroud's pieces counted right, one name for Saltmouth in French, steadier French typography, and four shopkeepers with something to say.

### Fixed
- **The Shroud's pieces are counted the same way everywhere.** The chapter 4 hint and the Drowned Cloister scene (`5010`) called the moon-shard the Shroud's second piece; it is the third, after the heirloom and the Warden's standard. The Lantern Docks' lead, which promised "the second piece" in chapter 2, now speaks of the next piece (English and French, in the zone text and the lead's label).
- **Saltmouth is Bouche-de-Sel in French everywhere.** Three strings (a scene callback in the Ashen Quarter, the Saltmouth quest giver's pitch and a scaffolders' news item) still said "Saltmouth".
- **French punctuation.** Twenty-four story passages had a plain space before `?`, `!`, `:`, `;` or `»` (or after `«`) and now carry a no-break space like the rest. Every French apostrophe in the story files is the curly one (`’`), as is "Wrack’s End" in the people list.

### Added
- **Four more shopkeepers have a line in the People list.** The cellar-boy (remembers how the party left the Blind Beggar), Old Pell (the camp) and Hesta Brann and Needle (read the party's standing with the Compact and the Crows, as the other keepers do), in both languages.

### Docs
- `docs/chapter-flow-roadmap.md` and `docs/quest-progress-tracking.md` describe the game as it is now (chapters 7 and 8, the order of the pieces, how quest objectives are tracked), and `docs/narrative-audit.md` holds the audit this pass came from.

## [1.254.0+290]

The party walks the world's roads, stop by stop.

### Added
- **A journey between two landmarks follows the roads.** When the party leaves
  a place along a way on the Journey map, or the story carries it somewhere
  (a lost fight, a failed roll, a jump along no choice), the world chart no
  longer draws one straight line: it walks the shortest way along the fixed
  roads (`world_roads.dart`), through every landmark on it, with the stops
  of each road marked and named as the party passes them. A road too long to
  frame whole is followed with the party in the middle of the view.
- **The words name the stop.** Under the caption of a carried move, a line
  says which stop the party has just passed ("You pass the Dyers' Gate."), in
  English and French. A road with more to pass takes longer to walk, up to a
  few seconds more; a tap still skips it.

### Changed
- The flight over the chart that follows a picked way out of a place takes the
  same roads and stops, and is as long as the road it takes.

## [1.253.0+289]

### Changed
- **The throne has no spikes: its top is broken.** The crown of spires, the spiked arms and the spiked shoulders are gone. The back is now a tall slab of black stone whose top has broken away in a ragged fracture, pale where the stone is fresh; the recess with its three ember slits is open to the break, the brass ring is chipped, one armrest is chipped, and rubble that fell from the top lies on the steps, the carpet and the cushion. The banners' finials are round.

## [1.252.0+288]

### Changed
- **The throne room is darker.** The throne is now an old seat of black stone: a tall back crowned with jagged spires, a pointed recess cut deep with three ember-red slits glowing in it under a worn brass ring, cracked stone, spiked armrests, a worn wine cushion, clawed feet and dark steps. The stage is nearly black, lit from behind the throne and by a dull red pool on the floor, the carpet is a worn wine, the braziers burn lower, and the banners stand on black iron poles with tarnished brass.

## [1.251.0+287]

### Changed
- **The throne room is restaged as a dark stage.** The Lantern Throne is now a gilded throne with a red velvet back and seat, in the middle of a dark hall lit from above and by a pool of light on the floor, its two braziers burning. Each banner you have earned stands on its own tall gilt standard (a pole, a foot and a finial) instead of hanging on a wall: one each side of the throne, the rest in pairs down the long carpet.
- **The banners blow in the wind.** A wind from the left rises and falls in gusts: it pushes the cloth to the right more the lower it hangs, a ripple runs down it and the hem flutters, while the rod at the top holds still; a few specks of dust drift across the hall. The cycle loops without a seam, and with reduced motion everything stands still.

## [1.250.0+286]

### Added
- **A throne room in the Clans screen** (a new "Throne room" tab, in play and in Edit Mode): the Lantern Throne in pixel art on its dais, a brazier lit at each end of it, a red carpet running down a long hall, and every banner you have earned hanging along the walls and swaying: the cloth swings a little further the lower it hangs, the pole held still. A clan's banner hangs once it is your friend, the Open Hand's once it is raised, and the Shroud's pieces as you find them; a tap names a banner and its standing. Above it, the hall says who holds the throne, or your claim, or that it stands empty. With reduced motion the banners hang still. Drawn by `tool/gen_throne_room.py`.

### Changed
- **"Every skill in motion" on the design canvas is back in the basic hand.** Both boards now play the game's own effect strips, recoloured to each skill's element as the fight does, for all 162 skills (the 20 newest marked NEW), in place of the poster-style motions.

## [1.249.0+285]

### Changed
- **The fight effects are back in their earlier pixel-art hand.** The poster-style redraw of 1.240.0 is undone: the 35 effect strips in `assets/visuals/pixel_fx` and `tool/gen_fight_fx.py` return to their 1.239 state, with their earlier shapes and animations. Nothing else of 1.240.0 changed, and the 20 new skills of 1.245.0 play the same effects as before.

## [1.248.0+284]

Twenty new skills, and the rules they needed.

### Added
- **20 skills** for the mage, cleric, rogue, ranger and warrior (names, texts and battle lines in English and French, a pixel icon each, a place on a profession's tree, in seven new branches: Storm and Frost for the mage, Dawn and Tides for the cleric, Gale for the rogue, Skyhunter for the ranger, Stoneward for the warrior):
  - Mage, ice and storm: Rime Lance, Glacial Ward, Chain Lightning, Static Charge, Thunderclap and the legendary Stormcaller.
  - Cleric, water and light: Tidal Wash, Undertow, Dawn Lance, Lantern Ward and the legendary Winter's Hush and Second Dawn.
  - Rogue and ranger, wind: Gale Cut, Dust Devil, Rain of Arrows, Hawk Mark, Windwalker.
  - Warrior, earth: Rockfall, Bastion Slam, Thornwall.
  - Ice, Electricity and Light now each have player skills (Ice had none).
- **What the skills ask of the fight** (`lib/combat/skill_extras.dart`, all optional fields of a skill, editable in Edit Mode): a shield (`blockAmount`), several blows struck one after the other (`strikes`), a share of the blow on the other enemies, and how many (`splashShare`, `splashTargets`), a status on every enemy (`statusAll`) and a second status beside the first, a ward that lays a status on whoever strikes the shield (`reflectStatus`), a cleanse of the caster (`cleanse`), a heal for the whole party (`healAll`), a blow that goes through guards (`pierces`), damage drawn from armor (`damageFromArmor`), full momentum (`chargesMomentum`) and a free reroll next round (`bonusRolls`).
- `tool/gen_skill_icons.py` draws the twenty icons.

### Changed
- The new skills that only shield, heal or control have a damage multiplier of 0, so they do not also strike for the caster's base damage.
- Windwalker gives a free reroll next round rather than a second action, and Bastion Slam draws its extra damage from the armor you wear rather than from the shield you hold; both read from the same rules as the others.
## [1.247.0+283]

The world's fixed roads: the groundwork for a map where the party only takes roads.

### Added
- **A fixed road graph (`lib/data/world_roads.dart`).** 41 roads join the
  34 landmarks by id, on land or by sea, so they hold on all three chart
  geographies. Each road passes one or two named stops (the Dyers' Gate, the
  Caravan Ford, the Glass Shoals...), in English and French, in the order
  met from either end. `roadRoute(from, to)` finds the shortest way along
  the roads and the stops on it.
- **A content test (`world_roads_test.dart`).** Every landmark is on a road
  and leads to every other, every sea road touches the water, and every
  branch of the story between two landmarks (a chosen way, a failed roll,
  a lost fight) follows a road, so a new branch that skips the map fails
  the build.

No change to play yet: the Journey map uses the roads in the next versions.

## [1.246.0+282]

The party walks the streets of a city, and a 'seen' failure in the Undercroft says why.

### Added
- **Inside one city or room, the mark comes by the streets.** When the story
  sets the party down in another district of the place it already stands in
  (a lost fight, a failed roll, a jump along no choice), the Journey map no
  longer draws the mark in the new district out of nowhere: it walks from
  the district where the party stood to the new one along the plan's roads.
  Nothing needs saying for a plain move inside a city, so no world transit
  plays there.
- **The twenty-one failed rolls of the Undercroft's watch** (every choice of
  the 7510 scenes that falls back to being seen) carry an authored
  `failNote` that says why the party is set down elsewhere.

### Changed
- A step that stays in the same place now walks the party back, instead of
  snapping it home, also when the step's district differed.

## [1.245.0+281]

The party's mark keeps its place on the world, and the map says when the story moves it.

### Added
- **Carried along a branch you did not pick, the party travels there by the
  world chart's road.** When a fight is lost or a roll fails and the story
  sets the party down somewhere other than where the step it took was
  leading, or when a jump along no choice (the travel list, the way back to
  camp) moves it, the Journey map plays the road from where the party stood
  to where it is now, with a short caption under it ("Vane's hand closes on
  your wrist: you are held on the wharf."). A tap skips it; with reduced
  motion only the caption shows. The Edit Mode's jumps are tools and play
  nothing.
- **The author writes that caption** on the choice: `failNote` / `loseNote`
  (with `failNote_fr` / `loseNote_fr`), four new fields in the node editor.
  Without one, the map says it in plain words ("The fight is lost: you are
  taken to {place}."). The seven existing branches that set the party down
  elsewhere (the rot giving way into the Undercroft, the brood driving you
  down, being spotted at the sleepers' camp, the gutter on the roofs, Vane's
  grip, the host turning on you) now carry theirs, in both languages.
- A content test keeps the promise: a lost fight or a failed roll that ends
  at another place than its chosen step must carry a note in both languages,
  and every scene must stand at a place on the world chart.

### Fixed
- **A step that walked the party on and was turned back from** (a fight
  retreated from, a shop shut) no longer snaps the mark back to where it set
  out: it walks back along the road it took.

### Notes
- This is the first stage of the fixed world: the party's position on the
  world is now kept from scene to scene. Still to come: the same for
  districts and rooms inside a place (a forced move between two spots of one
  city shows its caption only), and a fixed road graph with named stops.

## [1.244.0+280]

### Changed
- **Choosing a race and a profession no longer scrolls for the radar.** The radar is pinned above the rails and answers every pick: it starts as the plain start, grows with the race, and with a profession picked it shows the race alone dashed behind it with the corners that moved marked (+4 CHA, +4 WIS). Beside it, the name of the pair, its tags and the four numbers (HP, damage, armour, gold).
- **One detail card for the two.** A switch between the race and the profession (it follows whichever was picked last) shows the first sentence of the lore, the rest behind "more", the bonuses and the starting skill, in place of two long cards one under the other. The list between the radar and the Start button is the only part that scrolls, and the Start button stays in view.

## [1.243.0+279]

Places say what they are like, and the game listens.

### Added
- **Five parameters on every place** (`geography.json`, editable in Edit
  Mode, inherited from the places above when a place says nothing):
  - `danger` 0 to 3 (safe, ordinary, dangerous, deadly): roads to a safe place
    hold half the events, to a deadly one 1.6 times as many; a fight in a
    safe place meets half the ground anomalies, in a deadly one 1.7 times as
    many (never past seven in ten).
  - `light` (day, dusk, night, dark): the backdrop dims with it, and a fight
    at night or in the pitch dark is likelier to have a battlefield
    condition at all, and far likelier to be Dark.
  - `controller`: the faction that holds the place. A faction's shops there
    price by your standing with the holder when the shop names none of its
    own (a country's ruler does not set every shop's price).
  - `tags` (holy, haunted, ruin, underground, market, sea, wild, stronghold):
    the places above add theirs. Some ground anomalies favour a kind of place
    three times over: a wellspring in a holy or wild place, an eclipse or
    marsh lights in a haunted one, a collapse in a ruin or underground, a
    blaze in a stronghold, a sea storm or racing tide by the sea.
  - `watches`: how many watches of the day a walk to the place takes (a
    mountain pass or a far fortress is longer than the plain two).
- The "This land" card of a place shows its danger (when not ordinary), light,
  holder, kinds and the length of the walk to it.
- About 35 places carry values (the Black Hold and the undercroft deadly and
  dark, the Spire of Judgment deadly and four watches away, the safe white
  wells, Highhearth and Kindly Hill, Saltmouth's night wharf…).

### Notes
- The in-app and Python simulators still model plain walks and no ground
  anomalies; roads to deadly places will hold more events in play than they
  do there.

## [1.242.0+278]

### Changed
- **The dice loadout shows the die as a cube you turn.** The same 3D cube the fight tumbles (with the die's own skin, and a skill face drawn as its pixel icon on a plaque) stands above the faces: drag it round with a finger and it settles on the side nearest you, tap a side to bring it round, tap the face in front to give it a skill, or drop a skill chip on the die to put it on that face. The face it stands on is outlined in the list below and told beside the cube (its name and what it does), and a face tapped in the list turns the cube to it. Reduced motion turns the cube without the glide.
  - The dropdown of dice is a row of small cubes, one per die you own, each showing its faces (shown when you own more than one die).
  - A die of seven faces shows six on the cube and slides the window to keep the picked one on it.
- **The faces' odds are Edit Mode only.** In-Game mode no longer says how often each face comes up ("19% of rolls"), on the faces or beside the cube.
- **The faces below the die are squares of one size.** Each is a fixed square (three across or more) with its skill's icon (or its own kind and value), its name on two lines at most, and a mark for what can be done with it (a lock, a cross to clear its skill, a pencil to choose one, a warning when its skill is over its limit), so a long name or text can no longer stretch or crowd it. What the picked face does, in full (its summary, its rule words and what they do, whether it is fixed or custom or over its limit, its element) is told in the panel beside the die, which grows with the text.
- **A double tap chooses a skill.** Double-tap a face's square, or a side of the cube, to open its skill picker; the pencil on a square and a "Choose this face's skill" button in the panel do the same. A single tap only picks the face (the cube turns to it). A cube stood on its top or bottom sits upright.

## [1.241.0+277]

A place for every fight, and ground that sometimes turns on someone.

### Added
- **A background for every fight**, painted in code (no image files) from the
  place the fight is at: open country, dunes, salt flats, the shore, the
  ashlands, volcanic terraces, sea cliffs, the fen, a frozen waste, the glass
  shore, and the inside of a building (a hall of arches and torches). The
  stage comes from the biome of the place the story stands at; a scene can
  name its own, and an expedition fights on the stage of its zone's place.
  It sits behind the setup screen and the battle under a veil that keeps the
  cards and the log readable in either theme, with the day's weather (rain,
  snow, dust, ash, fog) drifting over it. It holds still with reduced motion.
- **Ground anomalies**: in about three fights in ten, the ground or the sky
  turns on someone for a few rounds. 28 of them, named after the roads'
  hazards where there is one (sandstorm, killing heat, whiteout, black ice,
  rockslide, crumbling path, sinking ground, flash flood, hailstorm, racing
  tide, field of glass…) plus a few of their own (thunderstorm, downpour,
  earth break, rising wind, break in the clouds, wellspring, eclipse, falling
  masonry, burning rafters). Each fits its stage and, for the wet and dry
  ones, the day's sky: a thunderstorm needs rain, a sandstorm is likelier
  under dust, and under a roof only the earth, the masonry and the fire can
  come of it.
  - **Announced a round ahead** (in the log and as a chip over the battle),
    it breaks in the second to fourth round and lasts two or three. The chip
    is green when it favours the party, red when it favours the enemies,
    neutral when it spares no one; a party with Perception 5 or more reads
    whom it will favour from the omen, the others only that something is
    coming.
  - **What it does**: it feeds or dampens elements for both sides (Wind +25 %,
    Water −15 %…), takes Perception from the party's read of the enemy,
    slows or spurs one side's damage, and ticks: a share of health lost or
    mended each round by everyone on a side or by one of them. Some fall on
    both sides alike; the others pick a side at the roll, and the same
    anomaly that helps the party in one fight helps the enemy in the next.
    **A wound never finishes anyone**: a tick leaves at least one health.
  - Drawn over the battle as it breaks: streaks and a veil for the storms,
    rain and lightning, falling rock, cracks glowing in the earth, heat
    shimmer and embers, god rays, an eclipse, rising motes for a spring.
- **Story and tools**: a choice can name its fight's ground (`forcedAnomaly`,
  `forcedStage`); a place can name its stage (`stage` in geography.json, and
  in the Data tab): the prison, the sewers, the cathedral, the cloister, the
  Hollow Court and the Lantern Hall are halls. The Edit Mode fight lab picks
  the stage and the anomaly of a test fight (a test fight rolls none unless
  one is picked).
- Pure rules in `lib/combat/field_anomaly.dart`; the painter in
  `lib/widgets/fight_backdrop.dart`; the fight screen's part in
  `lib/screens/fight/fight_ground.dart`.

### Notes
- A fight whose circumstances the story set (a forced condition, such as the
  ambush of a sneak gone wrong) and a lesson roll no anomaly of their own.
- The in-app simulator and the Python one still play fights without
  conditions or anomalies; the anomalies are balanced to be even-handed over
  many fights (sides picked at random, ticks of at most 12 %, factors of 0.6
  to 1.4).

## [1.240.0+276]

### Changed
- **Every skill and spell effect is redrawn in the poster hand**, after the Japanese kanji posters used for the banners. All 36 pixel strips of a fight (strikes, projectiles, landings, the elements, support, the five states and the tier shock) keep their names, size, frame counts and anchors, so every style, spell, weapon strike and status plays as before, but each is now built from heavy slabs with rounded corners and bevelled rims, fat arcs and rings, thin stencil slits cut through them, shaded round discs and eyes, fine concentric lines and flying pixel particles. They are still drawn in four flat tones, so the game still recolours one strip to any element.
  - A slash is one fat arc swept through with a slit cut along it; a heavy slash two arcs and a ground shock of discs; claws three heavy bars; a pierce a spear slab and a starburst; an arrow a shaft and fletching with speed bars; a fireball a bright disc with a trail of smaller ones and an explosion ring of discs; lightning a heavy bolt with branches; a fat eye opens for the void rift; a dome sweeps up for the shield; slabs drop onto each other for the stone shield; a fat plus swells for the heal; a mouth slab and arcs radiating both ways for the shout; a halo with orbiting discs for the stun; twelve rays for the critical hit.
  - A blow of a strong or mighty tier lays the new shock under its landing: a ring of discs running out along the ground.
- `tool/gen_fight_fx.py` is the poster-hand generator (it replaces the first one, which drew the same strips as thin shapes).

## [1.239.0+275]

Titles for the new standing steps, dedicated art for the forty clan cards,
and particles for them in a fight.

### Added
- **24 titles**, English and French: for each of the six clans, a good title
  at Friendly and at Friend and a bad one at Unfriendly and at Resented. They
  use the new source `while:<tier>`: **held only while the standing lasts**,
  good or bad. A good title is lost when standing falls below its step; a
  bad one is worn automatically (like "the Marked") and lost when standing
  recovers. The older tier titles (Known, Trusted, Sworn) are still kept once
  earned.

  | Clan | Friendly | Friend | Unfriendly | Resented |
  |---|---|---|---|---|
  | Dominion | Lamp-Lit | Stamped and Sealed | Marked Absent | Struck from the Roll |
  | Vigil | Watch-Friend | Keeps a Candle | Cold Shoulder | Left in the Dark |
  | Compact | Asked In | Seat at the Anvil | Short Measure | Barred from the Row |
  | Mire | Reed-Friend | Fed at the Fire | Wrong Foot | Led Astray |
  | Crows | Good for a Loan | Name in the Ledger | Overdue | Collected Upon |
  | Penitents | Shared Road | Ash on the Brow | Unforgiven | Anathema |

  Each carries one or two small effects in its clan's theme (a good one a
  buff, a bad one a penalty of the same size).
- **Dedicated icons for the 40 clan-card skills** (10 fusions, 10 ascensions,
  10 sub-clan skills, 10 secrets): a frame per kind (twin gems, a gem with a
  rising crest, a shield, a dark rune plate) in the skill's element colors,
  with a glyph for what it does. They are generated pixel art
  (`tools/gen_skill_card_icons.py`); replace any PNG in `assets/icons/skills/`
  with hand-drawn art and nothing else needs to change.
- **Clan-card particles in fights** (`VfxAccent`): over the skill's own
  effect, a fusion plays two colors circling and flaring as one, an ascension
  a rising pillar with climbing chevrons, a sub-clan's skill a sigil of two
  rings with orbiting motes, a secret a violet veil with drifting rune
  fragments. They ride on the skill's style, so a heal still plays on a
  friend and a strike on a foe. The accent is read off the skill (nothing
  new to author), and shows in the effects gallery too.

### Fixed
- Review of the whole branch: a clan Unfriendly or Resented (the new steps
  between Wary and Hostile) was shut out as a suitor and from the Host, as the
  old "at least Wary" test now stopped higher; both now stop at Hostile as
  documented. A fusion is found when a clan stands behind both parents. The
  simulator's sneak skips a fight only when the choice has an ability check
  that succeeds, as the game does. The ascension label in the data editor says
  Friend. The offer draw works out each clan's cards once. The unused Journey
  "past scenes" helper is gone, and the Intrigues section header is back above
  its tab.

## [1.238.0+274]

Twenty more skills: ten that belong to sub-clans and ten secrets.

### Added
- **Sub-clan skills** (`subclanId`). Once a sub-clan is your friend (taking a
  gift it voiced makes it one), its clan can put its skill on the table, in
  its voice, from Known standing. Rare, one class each:

  | Class | Skills (sub-clan) |
  |---|---|
  | Warrior | Quarry Break (Quarrymen), Last Watch Stand (Last Watch) |
  | Mage | Emberwife Coal (Emberwives), Whispered Ledger (Whisper Ledger) |
  | Rogue | Tar Snare (Tar-Hands), Heron Step (Heron’s Wake) |
  | Cleric | Candle Vigil (Candlebearers), Scorched Hymn (Scorched Choir) |
  | Ranger | Moss Dirge (Moss Choir), Wayside Ward (Road Exorcists) |
- **Secrets** (`hiddenFlags`, `hiddenClan`). Listed nowhere, with no sponsor
  shown, until the story flags are held: then the named clan teaches them
  (from Known standing), the card tagged "Secret". Epic, one class each:

  | Class | Secret (flag, clan) |
  |---|---|
  | Warrior | Matriarch Reckoning (matriarch_slain, Vigil), Gate Oath (siege_gate_held, Compact) |
  | Mage | Tear Sight (tear_touched, Crows), Ash Ledger (ashen_ledger_decoded, Crows) |
  | Rogue | Marked Deck (sable_marker_won, Crows), Borrowed Face (lysa_mask_kept, Penitents) |
  | Cleric | Absolved Penance (maren_absolved, Penitents), Kept Lantern (lantern_kept, Dominion) |
  | Ranger | Followed Trail (tracks_followed, Mire), Horn Call (oni_horns_returned, Vigil) |

  Every flag is one the story really sets (a test checks it).
- All twenty have English and French text, an effect and an icon (the base
  skill’s for now). The Edit Mode Affinities tab lists all forty clan cards
  (fusions, ascensions, sub-clan skills, secrets) with their clans. Companions
  never learn them with points. In 300 simulated runs, skills learned per run
  go from 9.6 to 10.4, level and win rate unchanged.

## [1.237.0+273]

Standing with a clan now has eleven steps, and fusions ask for more.

### Changed
- **Standing ladder.** Five steps up from Unknown and, as their bad
  equivalents, five down:

  | Up | Standing | Price | Down | Standing | Price |
  |---|---|---|---|---|---|
  | Known | 6 to 11 | −5% | Wary | −6 to −11 | +15% |
  | Friendly | 12 to 18 | −8% | Unfriendly | −12 to −18 | +22% |
  | Friend | 19 to 25 | −11% | Resented | −19 to −25 | +30% |
  | Trusted | 26 to 60 | −15% | Hostile | −26 to −60 | +40% |
  | Sworn | 61 to 100 | −25% | Hunted | −61 to −100 | no trade |

  Unknown stays −5 to 5. The ends of the ladder keep their old ranges
  (Trusted from 26, Sworn from 61, Hostile from −26, Hunted from −61); the
  two new steps on each side split what Known and Wary used to cover. French:
  Estime, Cordialité, Amitié, Confiance, Serment; Méfiance, Froideur, Rancune,
  Hostilité, Traque. Shopkeepers use their Wary line for the three lower
  steps above Hostile too.
- **Fusions need Trusted with both clans** (was Known). **Ascensions need
  Friend with their clan** (was Trusted), one step easier since only one clan
  is asked. In 300 simulated runs, skills learned per run: 9.6 (9.9 before),
  level 11.1, win rate 40%.
- The Edit Mode Affinities tab and the offer texts name the new steps.
- Tier titles stay at Known, Trusted and Sworn; the new steps have none yet.

## [1.236.0+272]

Each clan now has a home among the peoples and the classes, and two clans
together, or one at Trusted, can put a stronger skill on the table.

### Added
- **Favorability matrix** in Edit Mode (Clans & Politics, new "Affinities"
  tab): a row per clan, a column per people and per class. A people's cell is
  filled when the clan sponsors its heritage; a class's cell counts the
  clan's branches out of three; tap a cell for the branches. It is read off
  `factions.json` (`sponsors`), so that file stays the one source, and it
  lists any inconsistency (a clan with no people or no class, a people with
  fewer than two clans, a class with fewer than three).
- **Fusions** (`fusionOf`: two skills): with both parent skills known and
  Known standing with *both* clans, either clan puts the fusion on the table
  and the card shows both. Taking it raises the lead clan by 6 and the other
  by 3.
- **Ascensions** (`ascendsSkillID`): with the skill it raises known and
  Trusted standing with the clan behind that skill, the clan offers its
  stronger form. The base skill is kept.
- **20 new skills**, in English and French, with their effect and icon (the
  base skill's icon for now): ten fusions (two per class) and ten
  ascensions (two per class).

  | Class | Fusion (clans) | Ascension (clan) |
  |---|---|---|
  | Warrior | Bastion Charge (Compact × Dominion), Writ Banner (Vigil × Dominion) | Unbroken Stance (Compact), Reaping Whirl (Dominion) |
  | Mage | Scalding Tempest (Dominion × Crows), Ember Aegis (Dominion × Penitents) | Pyre Heart (Dominion), Mending Tide (Penitents) |
  | Rogue | Viper Kiss (Crows × Mire), Borrowed Time (Crows × Penitents) | Deadeye Thrust (Crows), Second Skin (Penitents) |
  | Cleric | Sentinel Verdict (Dominion × Vigil), Absolution (Dominion × Penitents) | Hallowed Sanctuary (Penitents), Unyielding Vigil (Vigil) |
  | Ranger | Snared Shot (Crows × Compact), Pack Ambush (Mire × Compact) | Deadeye Volley (Crows), Call of the Wilds (Mire) |

### Changed
- **Peoples and clans:** human → Dominion and Penitents; elf → Mire and
  Penitents; dwarf → Compact and Dominion; orc → Vigil and Mire; voidkin →
  Vigil and Crows. Every clan now favors a people, and every people has a
  second patron.
- **The home seat** reaches one tier deeper than standing allows (the fourth
  skill of a branch still waits for Sworn), and a clan whose branches are
  grown but that has a fusion or an ascension left still takes the seat, so a
  finished tree keeps growing.
- A companion never learns a fusion or an ascension with points: only the
  clans offer them.
- In 300 simulated runs (same seed), skills learned per run go from 7.0 to
  9.9, with level (10.9) and win rate (39%) unchanged. The simulator takes the
  rarest gift, which favors these epic cards, so this is the upper end.

## [1.235.0+271]

### Changed
- **Every offer now has a home seat.** One of the three suitors is a clan that sponsors a branch of your own tree (your class's branches or your people's heritage) and brings a skill from it, so your tree keeps growing instead of depending on the draw. The clan of your own people is three times likelier while your heritage branch still has a skill to give; once it is done, your class's clans take over. A quest's or an intrigue's clan fills the seat itself when it sponsors your tree; the Choir at a chapter's end and the Wayfarer keep their places, so an offer may then show four cards. A clan you are Hostile with, or whose next skill is deeper than your standing allows, is no home; with a fully grown tree there is no home seat.
- In 300 simulated runs (same seed), skills learned per run go from 3.4 to 7.0 (mage 2.9 to 5.7, ranger 4.2 to 8.3), signs from 15.0 to 12.6, with level and win rate unchanged (10.9, 39%).

## [1.234.0+270]

### Added
- The simulator plays quests the way the game does. A scene that offers or starts a quest is accepted when the character qualifies (alignment, flags, gold); Kill objectives count the fights won since it was taken, Flag objectives the story flags, Fetch objectives what the story hands over and what beaten foes drop (by their loot tables' own odds), Talk objectives once the person's chapter is reached. A finished quest is handed in at once for its gold, XP (which levels the character), item, alignment and follow-up, and a quest with turn-in choices takes the one the player leans to. New goal "Do every quest" (`completionist`) takes every way on of a scene it has not taken yet, work on offer first. See `docs/simulation/report-quests.md`.
- `test/sim_quests_test.dart` covers the quest log (alignment gate, bounty baselines, a quest offered by a fight, pay and chaining, turn-in bias, what a quest waits on).

## [1.233.0+269]

### Added
- The simulator can explore: the new goal "Explore every branch" takes, at every scene, the way on taken least so far over a whole batch of runs, so batch after batch covers more of the story. `simulatePlaythroughs` takes a shared `SimCoverage`; `test/sim_coverage_test.dart` pins that exploring covers more scenes and ways on than random runs, with every run ending in a real ending. `docs/simulation/report-branches.md` and `runs-explore-100.csv` hold the result of 300 runs: 363 of 385 scenes (94%) reached, the 22 that no run reached with what blocks each, and the one quest nothing offers.

### Changed
- The simulator rolls ability checks as the game does (a d20 plus the character's score against the DC, a natural 20 passing and a natural 1 failing, a skill challenge taking rounds), takes the failure scene when a check fails, and lets a sneak that works skip its fight. Before, no run ever took a failure branch, so 70 scenes (18% of the story) were never played. The simulated character's win rate in fights falls from 34% to 31% of attempts.

## [1.232.0+268]

### Added
- The Edit Mode fight lab can add a companion to a test fight. Under the party switch, "Add a companion" lists all eight companions with their race and profession; any of them, recruited by the story or not, joins the party for the test with the skills of their signature die, and a chip takes them off again. They are put back afterwards like the rest of the test: a companion the story never recruited is gone again even with "Keep what happens" on; one the story had recruited keeps what the fight did to them.
- Full simulated playthroughs for the balance review: `simulatePlaythroughs` runs the in-app simulator's walk and fight model headless for any list of goals, professions and races, and `test/sim_playthroughs_test.dart` pins that every goal and profession reaches a real ending through chapter 8. `docs/simulation/` holds the report and the per-run table of 100 runs.

### Changed
- The Journey's read-through prediction follows the real one: the flags each passed scene sets count for the next scene's ways, a way out of a building by a door walks the party out even from that door, and the scenes a way reads through are worked out once per build instead of for every use.
- The fight lab keeps the companions added to a test within the most the camp can field (the base party and every house's bonus), picks first.

## [1.231.0+267]

### Changed
- The Journey walks the party only where the story does. A way that keeps the party where it stands (working the table it is at, a roll, a stall, a scuffle in the square) leaves it on its mark: no walk, no road drawn to it. A way that carries it somewhere still walks it there: across a bridge or a street to another district or building, through a door or to a spot of the room, out along the road to another place.
- The map is closer. The city's plan no longer fits whole in the view: it keeps the party and the places its ways lead to (with some margin, never less than half of the plan), so a scene whose ways all lie close shows just that corner of the city. A scene whose ways cross the city still shows all of it. The camera's zoom on a walking party is 1.5 (was 1.6) on top of that.
- The party's mark never jumps. The plain scenes the story reads straight through on the way (see Fewer presses of Continue) are passed on the road, so the map now places and walks each way to the scene the story really lands on, not to the first scene it leads to: the district or building, the spot of the room and the glimpse of what comes next all follow where the party will stand after the read-through. Edit Mode, which stops at every scene, keeps the first one.
- The road already taken (the chapter's earlier scenes below the party, with the way taken out of each) is gone from the Journey. The Map tab keeps showing it.

## [1.230.0+266]

### Fixed
- Side quest rewards now follow one scale. A turn-in choice pays instead of the quest's base gold, not on top of it, so the clan quests of Chapters 3 to 6 paid far less than the fights of their chapter: the Chapter 5 candle count and hearth-stone paid at most 60 and 70 gold, the Chapter 6 salvage 90, against 80 to 150 for the kill quests beside them, while their XP ran well above (150 to 180 against 110 to 200). Gold and XP now follow the difficulty (about 12 gold and 17 XP per point) and a choice pays about 0.3, 0.8 or 1.5 times the base:
  - Glass from the Terraces 50 gold and 70 XP (was 45 and 90); Bark Tithe 75 and 105 (was 50 and 120); Candle Count and Hearth-Stone 90 and 130 (was 55 and 150); Salvage Rights 140 and 185 (was 60 and 180). The Reckoning Wall's sale to the Inquisition pays 100, not 150.
  - Difficulty ratings follow the pay: Vess 2 (was 4), Bark Tithe 6, Candle Count and Hearth-Stone 7, Salvage Rights 11.
- Only the Chapter 2 harbor chain paid in gear. The four hardest side quests now do: Ossuary Bounty (Bone-Laced Boots), Penitent's Confession (Frostward Cloak), Faces of the Fallen (Tearwalker Boots) and Salvage Rights (Voidsteel Greaves).

## [1.229.0+265]

### Added
- **Pixel-art banners in the style of Japanese kanji posters.** Twenty 64×128 banners drawn by `tool/gen_banners.py`: a black woven cloth filled edge to edge by two heavy signs stacked like vertical writing, built the way the posters build their lettering: fat slabs with rounded corners and rounded bends (a box on a bar, an E-comb, a square spiral, a gate, a stepped tower, a hand, a torn eye), thin black stencil slits where pieces meet, round discs, eyes (a ring round a dot), and fine concentric lines along the curves. Kept to few colours: the signs are always cream on black, with one accent colour per banner (the clan's own) for its discs, a thin header line and the tail's edge; the tassels and finials are brass.
  - **The Shroud, in Pieces** (Character tab) lays the six pieces out as banners: each recovered piece in colour with its name, the others a dark silhouette marked "Not yet found", with a count.
  - **Every clan's main banner** (the Lantern Dominion, the Grey Vigil, the Cinder Compact, the Mire Courts, the Salt Crows, the Ashen Penitents, the Choir, the Pit, the giants, the oni, the Tide-Kin, the Kindly Ones and the Open Hand) in the clan's colour from `factions.json`, beside its standing card; the Open Hand's stays a silhouette until its banner is raised on the Hollow Shore.

### Changed
- The title's mark is the Void's standard in pixel art, replacing the vector banner: twice the size on a tall screen, once on a medium one, and left out on a short one so the menu stays in view.
- A sworn clan's boon name in a standing card wraps instead of overflowing on a narrow phone.

## [1.228.0+264]

### Added
- **Ten hulls, and four flying boats.** The Eel can be rebuilt at the Harbor on another hull, each with its own outline, masts and sails seen from above, its own slots and its own price: Longboat, Cutter, the Sloop she is today, Brigantine, Brig, Corvette, Frigate, Galleon, an elven Twin-hull and a dwarven Ironclad (no sail to paint); and, from chapter 5, the Sky-sloop (twin gasbags, a boiler and a screw), the Cloud-cutter (bat-wing sails and a soul furnace), the Lodestone barge (four glowing lodestones) and the Void carrack (bone wings). A flying boat lets the storms and raiders of a voyage pass beneath her keel, as the Gull's Wing sail does.
  - The Harbor has a **Hull** section: each hull's picture from above, what it carries, its price and the chapter it is built from. A hull is paid for once; going back to one already built is free. Rebuilding says which parts have no slot on the new hull (they wait in the Harbor's store), keeps her name, looks and crew, and keeps her share of hull. "Try on the ship" shows a hull in the yard before it is built.
  - **Several painted sails at once**: a hull with several sail slots carries one sail of each power (a second sail of a power already aboard paints over it), each with its sigil on its own mast, and the voyage and the sea battle take all of their powers together.
  - Hull points, rooms, slots, sail plans and prices are in `ships.json` (new fields: hull name, price, chapter, kind, outline, sail plan, jibs, oars, castles, beak, flying), editable in the data editor.

### Changed
- **The ships are pixel art.** Every ship seen from above (the sea fight, the camp's boat card, the voyage, the yard) is drawn small and stretched back hard-edged, with a hard drop shadow and a heavier wake, so the fleet reads like the skill effects: flat tones, hard edges, one pixel size. Sea beasts keep their own sprites.
- The rooms of a ship shorter than the battle's box sit along her own length, so a small hull's tiles are on her deck.

## [1.227.0+263]

### Changed
- Ships are drawn from above only, as in the sea battle. The Eel at sea (on the voyage, in the camp's boat card, on the ship screen) is the same top-down ship the battle draws, in her paint, cloth, guns and plating, instead of the old side cutaway; the Harbor shows her once, larger, in the yard.

## [1.226.0+262]

### Added
- Ship customisation, in the Harbor, now a shipwright's yard. Above the parts, the Eel is drawn from above on the open sea, as she would look with what is tried on her.
  - **Sixty-seven parts** (forty-eight new), at least a dozen in each of the four slots, in *versions* of a family from the plain to the rare: the ballista becomes an iron-bound one and then a siege engine, the chain swivel a bar-shot swivel and a reaper chain gun, the grape swivel a canister swivel and a shrapnel mortar, the fire pots naphtha pots, the carronade a hot-shot battery and then the dragonfire cannon, the harpoon rack a barbed rack and a whaling gun; plus a culverin that carries long. Shields come as plating (steel, blackiron, pavise, bastion, dwarven, the Aegis of the Deep), as bracing that is all hull, and as screens (shuttered gunports, netted rails, runed wards). Utilities are stores and a keel for hull, a wheel, tackle, a gunner's chest and kit, lanterns and a chart table for the turn clock, the captain's quarters and the admiral's standard. The five powers of the painted sail are now painted in more peoples' ways (twelve new sails), so a sail is a choice of version: the one in your own people's medium holds twice as strong.
  - Each part has a rarity and a version, and the shipwright sells it from its chapter on (a part of a later chapter takes one line, with the chapter it comes in). A new `hullBonus` adds hull to the ship (oak planking, ironwood bracing, ribbed keel plates, oakum stores, a reinforced keel, the Aegis).
  - **Try before you buy**: each part has "Try on the ship", which shows it on the Eel (in place of her weakest gun when the slots are full) without buying or fitting it.
  - **Looks**, thirty-five of them, cosmetic only: eight hull paints, eight sail cloths (plain, patchwork, striped, black, moonsilk...), eleven figureheads (a gull, an eel, a siren, a wolf, a skull, a lion, a dragon, and the trophies of the Brinejaw, the pale Leviathan and the Tide-Mother, which are free once the beast is slain) and eight flags. One free default in each; the rest are bought, from their chapter on, and tried on the ship first.
  - **The parts you carry are drawn on her**, in the yard and in every sea battle: each gun in the gun room as the kind of gun it is (a ballista's bow, a swivel on its post, a carronade that glows when it is loaded hot, pots of fire, a rack of harpoons, a long culverin, the Tide-Mother's beak), grown with its version and tinted by its rarity; the bulwark in its plating (steel, blackiron, bone, scales, shutters, nets, ribs, glowing runes); the utility's gear on deck (barrels, lanterns, a chart table, a cabin roof); and the painted sail's sigil on the canvas (wings, an eye, a flame, a knot, a void spiral) in the colour of the people who painted it.

### Changed
- The one-sail-per-power rule is now one sail per power *and people*: every power is painted by at least two peoples, and no pair is repeated.
- Harbor part cards show their rarity and version, and the description of every part.

## [1.225.0+261]

### Changed
- The fight's effects are sized to what they are. Each effect now has a size of its own (a thud or a scratch is small, a meteor or a quake large) and its power grows or shrinks it, so a plain blow is a small flash and a rare or legendary skill takes the card and more; before, nearly every effect was about as large as the card or larger. A single effect never grows past one and a half cards.
- A plain Attack face plays by the weapon in hand: a sword slashes (a great blade cuts heavy), a spear thrusts, a dagger scratches, a staff or bare fists thud. The weapon's rarity sets how strongly it plays. Skill faces keep their own effect.
- The dice in the fight no longer sit on a coloured square: the cube stands on its own, and a kept die keeps its gold ring.

## [1.224.0+260]

### Added
- Radar charts, so the numbers read as shapes:
  - The character sheet draws the eight abilities as one shape (Strength at the top, clockwise to Charisma), with each corner's name and value, above the stat tiles.
  - Choosing a race and a profession shows the shape they make: the race alone as a dashed outline, the race with the profession as the solid one, and what the profession adds (+4 STR, +2 CON) at its corner.
  - "A Life Before This One" draws what the memories taught you on the summary: your abilities before as a dashed outline, with your memories as the solid one and the gains at their corners.
  - An Elements section on the sheet shows the elemental damage and resistance of the equipped items in four views you can switch between: Radar (damage and resistance as two shapes), Split (one radar for each), Rose (wedges for damage, an inner ring for resistance) and Rows (a bar per element). With nothing equipped that carries an element, it says so.
  - The charts shrink to fit a narrow screen and are read aloud as a list.

## [1.223.0+259]

### Changed
- The character sheet (Race & Profession) reads at a glance. The race and the profession each lead with the first sentence of their lore, set larger, with the rest below at a comfortable size and full contrast; their tag is a chip of its own instead of a prefix, and what they change shows as chips. The starting skills are cards with the skill's icon framed, its name large and its words below. The sheet itself is in sections: level, health and experience as bars, damage and armour as tiles, the eight abilities as a grid of tiles (held, each tells what it does), and the counters as one plain list. The race and profession pickers' descriptions are brighter and larger too.
- "A Life Before This One" is easier to read. The introduction is no longer faint italics; the scene is set larger; the age dots and numbers are bigger; each answer is a card in the book's own type (not the pixel font), left-aligned, with what it teaches as a clear tag under it.

### Added
- Fate can choose your story: "Let fate choose" under a memory's answers picks that one at random, and "Choose my whole life at random" on the first memory picks all six and goes to the summary, where any memory can still be reopened and changed. The summary has "Choose again at random" to draw them all anew.

## [1.222.0+258]

### Changed
- Every skill and spell effect in the fight is now pixel art. All thirty-four styles (slash, heavy slash, claw, pierce, impact, whirl, arrow, volley, bolt, lightning, flame, fireball, meteor, holy fire, frost, splash, poison, smoke, wind, quake, void rift, drain, shadow, radiance, heal, shield, stone shield, mana, shout, stun, weaken, critical hit, miss and a boss's change of phase) play as short strips drawn with hard edges and dithered fades, flown from the caster to the target where they travel. The strips are drawn in four flat tones that the game recolours to the skill's element, so a Fire slash is orange and an Ice one blue from the same strip. A strong or mighty blow adds a pixel shockwave under it, and a mighty one still washes the screen. The old vector effects play only for the instant before a strip is in.
- The enemy portraits move in pixel art: a flash and a shake when a blow lands (every blow, light or mighty), a lunge at the party member it strikes, with a smear and a puff of dust, and, when it is beaten, a fall in which the portrait dissolves from the feet up into rising pixels (a boss's fall adds a ring of light and takes longer). The card dims as it falls. The art is drawn from each enemy's own portrait, so all fifty-one have the three moves. With reduced motion, or with the effects off or in a quick fight, the portrait stays the still sprite.

### Added
- `tool/gen_fight_fx.py` draws the effect strips (`assets/visuals/pixel_fx/vfx_*.png`): run it to change them.

## [1.221.0+257]

### Fixed
- Side quests that did not match their own scenes, from a review of all 27:
  - The Penitent's Confession (ch5) asked for a kill, but its scene is a confession with no fight, and its turn-in offered absolution for a man the quest had you kill. The quest now asks you to hear the confession, and the turn-in is where you decide: take his blade (he hauls water for the camp, as the camp's later lines say), give him the answer he came for, or take his purse and leave him to the tear. The three outcomes now leave `confession_spared`, `confession_executed` and `confession_robbed`, with a camp line for each.
  - The Informant's Tip (ch2) named a warden the scene never fought. The warden now steps out of the warehouse with two hired men; the other branch offers "Go after the warden he named" and only that choice starts the quest.
  - The Ossuary Bounty (ch4) asked for three ghouls where the scene fights two, and the sapper counts two coins now.
  - A Smuggler's Favor (ch2) appeared out of nowhere. A soot-black smith now asks for iron ore at the end of the harbor master's job.
  - Grosh, Tobin and Malrik asked for a kill they had no scene for (and Grosh's zealot only appears from Chapter 4). Each now has the fight in their own scene.
- A quest offered by a choice that also fights now counts that fight. The offer comes after the fight, so a bounty's kills were counted from after it; the kill counts are now kept from before.
- Twelve kill quests counted every kill in the game, so a rat from the first scene could complete Dockside Debts before it was taken. They now count from the moment they are taken.
- Six turn-in options had no flag (Tern's Toll, Liora's Watch, the Reckoning Wall, the Ossuary Bounty), so what you chose was forgotten; each now leaves one.
- The chapter validator reported 14 problems because it held open side quests to the one-start, one-end rule of a linear chain. It now checks the main chain only (a chain running on into the next chapter ends there) and reports none.

## [1.220.0+256]

### Changed
- The party's walk through a place is slower and smoother. It strolls at a steady pace whatever the street's length (a second and a half for a short way, up to four and a quarter for a long one) instead of a fixed second, and its footprints keep a stride apart. The road up the map keeps its short walk.
- The city's map follows the walk: it zooms in on the party as it sets off (to one and three fifths of its size), keeps it toward the middle while it strolls, and eases back out as it arrives, never past the plan's edges. With reduced motion, the map holds still as before.

## [1.219.0+255]

### Changed
- Ship battles are less of a wall. A shield layer that stops a shot no longer cancels it: about a third of the blow (at least 1) still reaches the hull, on either ship, and the log says so. Before, four shots in ten were swallowed whole and a quarter of all rounds saw nothing land on either side.
- A shield can now be broken on purpose. A shot aimed at the bulwark itself strips a second layer; a heavy weapon (damage 20 or more: the fire pots, the hot-shot carronade) strips two; and a perfect aim slips through the gap, landing on the hull and leaving the layers standing. Piercing shots still ignore the layers, and a sea beast's hide keeps its old rule.
- The enemy's bar shows the sums: its shield layers and how many shots of the armed weapon it takes to get one through (fewer when aimed at the bulwark), with a "Salvo ready" flag when the guns ready now can break it and land this turn. The room preview shows the chip a stopped shot would cost.

### Balance
- Against the late Void Barge a captain who ignores the tools now wins one fight in four (3% before); the captain who aims, braces and gives orders wins most of them (53% before, 86% now). The simulator's band for the new rules was widened from +35 to +65 points for that fight, and a new check keeps the plain captain from being walled by the shield again.

## [1.218.0+254]

### Changed
- Close and far read at a glance in the ship fight. The sea is seen from the masthead, so the farther apart the ships lie the smaller each is drawn (full size close, a little over four fifths at medium, under two thirds at long) and the wider the open water between them; closing in or pulling away glides between the three. The closest range now also gives the ships more of the sea's width.

### Added
- Station dice on the Eel. Each hand with a die (the player's equipped die, a companion's signature die, as the Hammersmith left them) has it at their station in the ship fight, a small cube on the room's tile that tumbles when the turn opens or the hand moves, and shows only the faces that room can use: the guns, attack and poison; the bulwark, defend; the hold, heal and mana; the helm, stun and weaken. A skill face shows its skill's icon. A room the die has no face for shows a pale blank cube and gives nothing.
- What a landed face does, while its hand stays at the station and is not busy: at the guns, the Eel's shots hit harder by the face's share (half as much for poison); at the bulwark, the enemy's shots hit softer; at the helm, a weaken face does the same and a stun face costs the enemy's most charged gun a step after it winds; in the hold, a heal face patches the hull and a mana face winds a gun a step when the round ends. The landing depends only on the battle, the turn, the hand and the room, so moving hands about cannot shake out a better roll. Hold a room's tile for what its die landed.

## [1.217.1+253]

### Fixed
- A die now ends its roll on the face that rolled, standing almost square to you, so the skill icon (or the value) of the face that can trigger is what you read. Before, the cube settled tipped far over with its top and sides as large as the landed face.

## [1.217.0+252]

### Fixed
- The map no longer moves when a way is picked. The panel under the Journey map keeps one height whether or not a way or a place is chosen, so the map keeps its size and every mark stays where it was.
- The sky holds still. The game plays turn by turn, so the clouds, fogs and rain no longer drift while the map is watched, and zooming or pinching shows the same clouds at every distance. The sky is the day's, and a new day brings a new one. The weather chip no longer changes on its own either.

### Added
- Each of the thirty-one dice wears a cube skin of its own, from the dice sheet: the stone it is cut from (bone, riveted iron, ember, sea glass, stormcast, Dwarven stone, black lacquer, ivory and gold, blood-iron, rune crystal, antler and oak, living wood, chalk, sky-glass, reliquary bronze, rust, casino ivory, ice, thunder iron, bone mosaic, candle wax, tear-glass, black iron and more), the colour of its edge, a mark cut into its faces and, for the glowing ones, a light round the cube. A die without a skin reads as bone.
- A die kept through the reroll has a gold dashed ring and a lock round its cube.
- Over the burst of a landed face go: a flourish for each rule word it carries (cleave flings arcs to either side, pierce drives a line through, growth lifts a +1, echo sends rings, pain cracks and drips, steady drops an anchor); a tint for its element (embers, droplets, wind arcs, pebbles, forks, ice shards, void arcs, light rays); a turning gold ring and crown for a momentum surge; chains for a curse; and a single shudder for a blank.
- Pixel animations (`tool/gen_pixel_fx.py` draws them as sprite strips in `assets/visuals/pixel_fx/`; `PixelSprite` and `PixelStripPainter` play them, pixels kept square):
  - A die's landing is now pixel art: eight bursts by kind of face, eight element tints, six rule-word marks, a surge ring and crown, curse chains and a white glint, each eight frames. The drawn burst remains until the strips are in.
  - A place found is stamped on the Journey map by a pixel seal that comes down, flings its ink and dissolves, under the place's name.
  - The camp has a pixel campfire that flickers in its header.
  - A spoils chest bursts open in its tier's light, one burst each for wooden, iron, silver, gold and void; a tap anywhere on the chest now opens it.
  - With reduced motion the seal and the chest's burst are skipped and the fire holds one frame.
- The dice are cubes in the fight. A die tumbles through the air in perspective, with a hop and a shadow, and lands on the face it rolled, which stands front; the other five sides carry the die's other faces (a die of fewer than six faces repeats them), lit by a lamp above and to the left, the far sides hidden. It rests tipped toward you so its top and a side show. A die kept through a reroll stays put.
- A skill face on a cube holds the skill's own icon, large, on a pale plaque ringed in what the skill does, so the pixel art reads on the dark stone; the cube is a little bigger on the tray.
- A landed face lets go a burst fitted to what it does: sparks and a shock ring for an attack, a hexagonal ward for a guard, rising crosses for a heal, orbiting blue motes for mana, green bubbles for poison, amber bolts for a stun, a draining purple spiral for a weaken, grey dust for a blank. A skill face or a face worth 8 or more lands bigger, with a white glint.
- With reduced motion the dice roll at once and no burst plays.
- The sea beasts are drawn again, from above, in the dark-fantasy art of the Grey Shroud design ("Sea beasts to hunt"), no longer borrowing a ship's look. Old Brinejaw is the Drowned Wyrm, a sea dragon with sunken coils, fin-wings and a fanged head; the Pale Leviathan is the Deep Leviathan, a vast barnacled back with old harpoons in it and one pale eye; the Tide-Mother is the Mother of Wrecks, a kraken among the timbers of the ships it took. A room knocked out darkens its part of the body, and a beast below half its hull shows gashes. The designs' Ash Drake and Bone Tide are not in the game yet.
- The Tide-Mother's arm has its own icon again for the fight on the dice.
- Seven new kinds of building for the inside view, each with its own plan: casino (a wheel ringed with card tables, a cashier, private rooms, a vault), barracks (guardroom, bunks round a mess table, armoury, officers), library (stacks, reading tables, archive, scriptorium), prison (guardroom and two rows of barred cells), forge (forge, anvil, quench trough, store), theatre (foyer, benches, pit rail, stage, dressing and props rooms) and baths (changing hall, great pool, hot and cold rooms).
- Variants by seed: a temple may be a nave and choir, a cross or a round shrine, and an inn may front the street or stand round a yard.
- A building's name can say what it is: a name with "casino", "barracks", "caserne", "chapel", "gaol", "smithy" and the like (English or French) is laid as that kind, whatever kind the geography gives.

### Changed
- The quest on the Journey is a small round button beside Read, with its icon, a tick when the goal is met and a dot when it moves on, instead of a full bar above the map. Its name and goal are on its tooltip, and a tap opens the quest, where it can be turned in. The map gains the height the bar took.

## [1.216.0+251]

### Fixed
- Chapter 2's bosses were walls. In the fight simulator a solo character won the Tanner's Court plague hound 10% of the time per attempt, the smuggler captain 14%, the Fisherman's Row dock overseer 27% and the Tern Row overseer 29%; the two repair-zone bosses gate casting off. All four are about a quarter lighter (plague hound 175 → 130 health, 21 → 16 damage; smuggler captain 180 → 135, 21 → 16; dock overseer 139 → 112, 17 → 14) and now sit near 45–55% per attempt, which takes Chapter 2 from 38% to 63% across the chapter.
- Kelda's offer is now told: the scene opens on the dwarf holding the wharf gate alone and asking for one more pair of hands, instead of starting after the offer.
- The woman under the bar is introduced in the opening scene before a choice names her. A cloaked woman now waits at the far well for a character the tear has marked, before the choice to answer her.
- The Rusty Eel's capacity matches the choice: twenty in comfort, and a hundred only with the stores over the side and a skiff in tow, which is the skiff the storm later asks you to cut loose.
- "Go find Vane" at the informant now reads "Go after the warden he named", which is who the trap is about.
- French spacing: non-breaking spaces before `;`, `:`, `!`, `?` and inside « » in the Chapter 1 and 2 strings that had ordinary spaces.

### Added
- Chapter 2 has its own main quest, "A Hull to Leave In" (get the Rusty Eel, patch her hull, mend her sail), offered on the way into the wharf market, by any of its three doors. The three optional hub quests that were marked Main (burning manifest, captain's gambit, harbor reckoning) are now Side quests.

### Notes
- Liora's three ability checks can still be retried: she is a recruit, and the refusal says she will be there when you come back.

## [1.215.0+250]

### Added
- Enemy squads. From chapter 2 on, about half the packs of two or three field a squad: a **Healer** (mends its most wounded friend by an eighth of its health each turn, hits at seventy percent), a **Guard** (while it stands, blows on the others are cut by a quarter unless they Pierce) or a **Striker** (hits a quarter harder on a fifth less health). A pack never gives roles to all its members, never doubles a Healer or a Guard, and never to a boss. The role shows as a chip on the enemy's card with its rules on a long press.
- Enemies that answer the party. Fifteen enemies now carry a reaction in `enemies.json` (from chapter 2 on; the opening chapter keeps the plain rules): a **counter** enemy (a blow of a fifth of its health in one round provokes it; its next blow lands half again as hard, at whoever struck), a **press** enemy (a round in which everyone played Defend makes it press: its next blow lands three tenths harder) and a **hunt_healer** enemy (it turns its next blow on whoever healed most). A *Provoked* or *Pressing* chip says so before it strikes.
- The pack fights back harder when it is held rather than slain: a Hold the line fight now asks four of the enemies' turns against a pair and five against more (it was three and four), and they hit a quarter harder (it was a tenth).

### Balance
- The fight simulator plays the whole clash set (goals, the Writ, squads, answers, parries, reactions) when `clash` is on, and each rule can be left out to see what it does (`clashOff`). Four seeds of 400 random walks each, win rate per fight attempt, plain rules → clash rules: Chapter 1 85.9% → 87.1%, Chapter 2 37.3% → 38.3%, Chapter 3 36.8% → 38.0%, Chapter 4 25.7% → 29.6%, Chapter 5 14.0% → 17.1%, Chapter 6 22.1% → 25.4%, Chapter 7 10.5% → 11.2%, Chapter 8 15.4% → 17.6% (all fights 28.5% → 30.4%). Left out one at a time (before the Hold was made harder), the goals were worth about five points of that, the Hold alone four; parries and reactions about one each; squads, answers and the Writ under one. The model plays the rules as well as they can be played (the best parry, the Healer struck first), so a real party will see less of the gain.
- `test/clash_balance_test.dart` keeps every chapter's simulated win rate within ten points of the plain rules'.

### Internal
- `squad.dart` and `enemy_response.dart` hold the pure rules; the fight screen gains a `fight_squad.dart` part. `EncounterModifiers.forcedSquad` pins a pack's roles for tests. The `reaction` field joins the enemies schema.

## [1.214.0+249]

### Added
- Targeted defence. A Defend face no longer only guards whoever rolled it. When an enemy has an attack coming, the defender's card shows a Parry chip: tap it to set the face on that enemy's blow, tap again to move to the next enemy or back to a plain guard. A parry counts half again as much as the guard, covers whoever the blow was aimed at, and blocks its status. A blow it stops outright is turned aside and answered for half the parry. A parry set on an enemy that does not strike that turn is wasted, and the roller's own guard is not raised.
- Element reactions. A hit with an element primes the enemy with it for the rest of that round and the next, shown as a chip on its card. A partner element striking the primed enemy springs a reaction and uses the prime up: **Conduct** (Water and Electricity: half again as much damage, and an arc to the other enemies), **Shatter** (Fire and Ice: sixty percent more and the guard broken), **Firestorm** (Fire and Wind: a quarter more, and the blaze catches the others), **Freeze** (Water and Ice: stunned for a turn, a boss shrugs it off), **Sandblast** (Earth and Wind: weakened) and **Eclipse** (Light and Void: double). Spells react as well as dice. With the Dexterity order, putting the bigger hit second now pays.

### Internal
- `parry.dart` and `element_reaction.dart` hold the pure rules; the fight screen gains a `fight_clash.dart` part.

## [1.213.0+248]

### Added
- The party acts in Dexterity order. The quickest fighter strikes first, and ties keep the party's own order (you first, then your companions as they joined). A small number on each card shows its place in the round. An Echo copies the strike played before it, so order now matters there too.
- Loadout by situation. Before a fight you can swap the die you roll for another you own. Each die you could pick is starred when it can hit an element the party knows its enemies are weak to, and a line says which weaknesses are known and which of them this die hits. The swap holds for this fight only.
- Quick resolve. Against enemies you have already beaten five times or more, with your health above sixty percent, a fight offers to play itself: a roll and a confirm a round, short animations, the same rules as a played fight. It stops and hands the fight back when you tap Stop, when your health falls below forty-five percent, or when a companion is knocked out. Bosses, uniques, hunts, ambushes, lessons, elites and story fights with a defeat branch never offer it.

### Internal
- `turn_order.dart`, `quick_resolve.dart` and `loadout.dart` hold the pure rules. The fight screen gains a `fight_quick.dart` part. A player's die fields can now change before the first roll.

## [1.212.0+247]

### Added
- Fights that ask for more than the slaughter. About one fight in four now has a goal, announced on the setup screen before the first die: **Hold the line** (a pack presses you; survive its turns, three against a pair and four against more, and you win whoever still stands, for a third more gold and XP), **Rout** (a pack's sturdiest member is its captain, marked on its card; bring it down and the rest flee, as a Skittish enemy does) and **Subdue** (one fighter who is a person, not a beast: bring them under thirty percent of their health and they yield and pay a ransom of half again their gold, but drop no loot; kill them outright and you get the usual spoils). Bosses, uniques, hunts, ambushes, lessons and story fights with a defeat branch never roll a goal. A battle chip shows the goal, and a hold counts its turns.
- Faction doctrine. Each faction's fighters now fight by their own habits, announced beside the goal. The Dominion's **Writ**: every third round your skill faces fall silent, and its soldiers favour heavy armour. The Salt Crows' **Short Con**: each hit they land lifts gold, carried by the thief shown on its card; whatever a Crow still carries when the fight ends is missing from the spoils, so kill the thief to get it back, and they would rather run than die. The Ashen Penitents turn frenzied as they bleed, the Choir and the giants wear armour, the Pit's things poison, the Tide-Kin give ground. Twenty-six enemies now carry a faction in enemies.json. A fight against a boss or a unique is never under a doctrine.

### Internal
- `lib/combat/fight_goal.dart` and `lib/combat/doctrine.dart` hold the pure rules; the fight screen gains a `fight_goals.dart` part. An encounter can carry a `forcedGoal` for a hand-made fight; the story files do not use it yet. The fight tests that rely on the plain slaughter pin it.
- The in-app playthrough simulator and the Python simulator do not model goals or doctrines yet.

## [1.211.0+246]

### Added
- Faces for the intrigues. Each stage and outcome of an intrigue can now name the person at its centre. A person's page lists, under "In the intrigues", the stages you have reached that they stand in, and the Clans screen shows the person's name beside a reached stage. The Hooded Lantern and the Dying Lantern Bearer are fully faced; the six intrigues not yet placed in the story name a person where their text already does.
- Six new people: the paid informant of the wharf, the condemned voidkin of the Spire, the drowned courier, the courier at the landward gate, the frozen pilgrim of Rimewell, and the White Admiral.
- People that know where you stand. Twenty-five people gain lines that appear only at a given standing with a faction or a friend or foe mark with a clan: the Keyholders when the Salt Crows count you sworn or have put a price on you, Aurel Vane when the Inquisition has your name on a writ, and so on.
- Second beats for the six quest-givers of 1.204. Once you have settled one of their requests, they send word or come to the next chapter's hub, and what they say follows the way you settled it. Where they are grateful they offer twenty gold; a goodbye is always possible.

### Internal
- People states may carry politics conditions (`conditions`, the shape politics events use), and an intrigue stage or outcome may carry `npcId`. A content test checks that every named person, faction and clan exists.

## [1.210.0+245]

### Changed
- Journey: the map stops repainting when nothing moves. The living layer used to re-record every frame at 60 fps while idle; it now keeps its last frame once walks, reveals and jolts have settled, and wakes on the next motion.
- Roads: a journey that leaves a city or town runs through that city's own land first, so the Salt Coast's and the Vale's weather can reach the party; a boat crossing to the sea keeps the sea's. A test lists the lands whose weather no journey can reach yet (the Vale, the dune sea, the Salt Coast, the terraces) so the list can only shrink.
- One road rule: scenes that read through on their own now use the same "between two places" rule as the Journey, so a one-way scene into another district of the same city no longer stops for a tap.
- The race and profession tiles wrap long French names on two lines instead of cutting them.
- The six side quests of 1.204 retuned after an eighty-run standing probe: the Compact no longer reaches Sworn a chapter early, the Penitents lose less and gain more, the Dominion takes a lighter blow from the scaffold and the salvage, and selling the salvage to the wreck-wrights pleases the Tide-Kin.

### Fixed
- French typography across all game data: 274 strings in 17 files gained the no-break space before ; : ! ? or inside « », and one golem line stopped gendering the player. A lint over every French string in the data and the story now runs in CI, with an empty allowlist that may only shrink.

### Internal
- Scene-to-landmark lookups are a map, not a scan. Save fixtures for 1.198 and 1.204 load, round-trip and migrate in tests.

## [1.209.0+244]

### Added
- The Journey in Edit Mode: a Journey tab beside the Story tab shows the edited scene's map (the room, the streets, the land, the world) with no fog and every place known.
- The world chart in Edit Mode. A second map button in the header (beside the story's scene graph) opens the chart whole: no fog, every place with its name, every chapter's road in its colour, the party's mark where the edited scene stands; the looks, the calques, the sphere and the weather as in play. In play the chart is as before, under the fog of the uncharted.

## [1.208.0+243]

### Added
- The sky touches the play. Each day's weather over the party (the same all day, so a fight or a road reads the same whenever it is looked at) changes a fight: rain dampens Fire (−30%) and feeds Water and Electricity (+20%); snow smothers Fire (−25%) and sharpens Ice (+25%); fog damps Fire a little and hides what the enemy is about to do (the party reads its telegraphs as if its Perception were five lower); the dry dust feeds Fire and Wind (+15%) and does less to Water, and the ash and embers feed Fire (+20%) and Wind; dust, ash and snow hide the enemy's intent too. It applies to the party's blows and spells and to the enemy's own moves alike. The fight log and a chip above it say so, and the Journey's weather chip carries the day's tags (Fire −30%). Bad weather makes the road likelier to hold something: snow ×1.4, fog ×1.3, dust ×1.3, rain ×1.25, ash ×1.2, cloud ×1.05.
- The Layers sheet can keep the weather to the world zoom, for a clear land view; the choice is kept.

### Changed
- The clouds are banks, not discs: every cell's cover is laid as a patch and the patches blurred into one field, so the banks take the shape of the sky's field, their edges penned as thin wavering ink lines; the fill is lighter, so the land under a cloud stays readable.
- The fog of the uncharted follows the land: each land a place was read in shows whole, with a soft torn edge along its border, the roads walked show as cleared corridors, and only a place read outside any land (at sea) keeps a small clearing. Before, every place cleared one disc of the same size, so the known world was a circle round the party.
- When the streets give way to the chart, the fog and the weather fade in over a third of a second instead of popping.

## [1.207.0+242]

### Added
- The inside of a building, one level in from the streets. The geography has a sixth level, `building`, under a district or a location, with a kind (den, tavern, inn, house, hall, keep, temple, shop, warehouse, cellar, cave, tower) that lays out its rooms: walls, doors front and back, the furniture of the kind (a bar, tables, a hearth, beds, a cage, a counting-room with its strongbox, a gallery's rail, pillars and a dais, pews and an altar, a counter and shelves, crates and casks, rocks, a stair), and named spots (the bar, the tables, the cage, the gallery, the stairs, the door, the back…). A scene can say where in the building it happens (`spot`), and a way where it is taken (`spot` on the choice).
- The Journey draws the room when the scene is inside: the party at its spot, each way at the spot it is taken from, a way that leaves the building at the door it leaves by (the back door from the back rooms), and the walk between two rooms through the doorway. A look out (pinch in, or −) shows the streets round the building with the ways kept inside; the + button or a pinch out goes back in; a second look out is the land, as before. Coming back in from the land arrives on the streets first.
- The Blind Beggar is in the geography as a den in the Lower Town, and the story's first scenes (the tables, the room coming down, the fight, the counting-room, the gallery, the way out the back) stand in it at their spots, so the opening no longer sends the party out of town for a choice made at a card table.

## [1.206.0+241]

### Added
- The sphere wears the chart. Looked at as a sphere, the world map is now the flat chart wrapped round the ball as a texture, at the chart's own level of detail (woods, hills, rivers, roads, the fine names), where before the sphere was painted coarse on every turn. The skin is rendered once per look and detail in the background; until it is there the sphere paints as before. Each point of the surface is lifted by its height, so the ranges stand off the limb.
- The sphere is lit: from the upper left, the limb darkening away from the light, a soft highlight toward it, a thin pale air round the edge and the limb drawn. Grey on grey, as the chart is.
- Shaded relief on the chart, flat and on the sphere: the land lit from the north-west, its slopes toward the light paler and those away darker, from the climate's heights with a fine grain on the slopes. Rendered once per chart as a smooth image, so it stays soft at any zoom.
- A chart can show the whole world with no fog (ChartFog.none), for a chart that has nothing left to find.

## [1.205.0+240]

### Added
- The world has a climate. From the chart itself (its coasts, ranges, rivers and lakes, each land's biome and its latitude) every point of the world gets a height, a humidity and a warmth: the land rises from the coast inland and up to the ranges' crests, the fens lie low and the deserts flat; the sea, the rivers and the lakes wet the land near them, the windward slopes catch the rain and the lee of a range lies in its shadow; the latitude and the height set the warmth, the frost is colder and the desert hotter, and the season turns over ninety days with each day a little different. Three new calques on the Layers sheet show it: Height (tinted low to high, with contour lines), Humidity (dry ochre to sodden blue) and Warmth (frost blue to noon red), each with a legend.
- Weather moves over the world map. Clouds ride the wind (westerlies in the temperate bands, easterlies about the equator, turning with the day) with their shadows on the land, rain slants under the heavy ones where the air is wet, snow falls where it is cold, dust blows off the dry lands and ash off the burnt ones, fog settles on wet cold ground. It moves while the map is watched, flat and on the sphere, on its own layer so the chart is not drawn again for every cloud; a switch on the Layers sheet turns it off.
- The Journey map draws what the sky brings where the party stands (rain, snow, dust, fog, the burning chapters' ash still), as does the story's page, and a chip on the place map names it: what falls, the warmth, where the wind comes from, how high the ground is. Each town is laid out for its climate: a wet land grows more trees and fields, a dry one scrub and no fields, a cold one firs, a frozen one lies under snow.

## [1.204.0+239]

### Added
- People: a codex of the people met on the road, in the Play tab beside the bestiary. Forty-six records: the Inquisitor-General and the quartermaster who shares his name, Lysa, Renn and Nadira of Tern Row, the Eldest Wickwarden and the Grand Master, the Hesks, Brother Clement, the Keyholder, the chart-keeper, the sign-painter, the High Warden, the Rat Matriarch, the Herald, the elders and clerks of the villages, every shop keeper, and the six new quest-givers. Each entry gives who they are, their faction and place, what they want, and what passed between you, told from the story's own flags; people appear on first meeting, grouped by chapter, with a badge for those newly met.
- Six side quests with a stake in the clans, each from someone new: Dorran Quill's unpaid scaffold crew at Saltmouth (the Scaffolders against the Salt Ledger), Imeh's spring-glass stall at the Ashen Quarter (the oni against the Scorched Choir), Brannoc Reedtithe's stolen fever-bark at the Drowned Cloister (the Barkbleeders against the Keyholders), Orsabet Vell's count of the taken in the Reliquary Quarter (the Candlebearers against the Reliquary), Ghrem Stonebrow's hearth-stone at Highhearth (the giants against the Quarrymen), and Nkem Tallow's impounded salvage at the White Anchorage (the Brig-Born against the Admiralty). Each ends in a three-way choice that moves two clans' standing, marks a sub-clan, is remembered by the next chapter's hub, and makes the news.
- Quests can now move standing: a turn-in choice may carry politics, shown under the choice and applied once, as story choices do. A quest may also opt out of the random detour pool.
- Relics: a fourth rarity above Rare for eight story-bound pieces (the Grey Shroud, the Saint's Reliquary, the Sovereign's Crown, the Harborwatch Lantern, the Hollow Court Seal, the Phoenix Sigil, the Wisp Ember, the Moon Shard). Every Rare item, every artifact, charm, tome, scroll and material now carries a line or two of lore, shown in the inventory and the item sheet with a translated rarity tag; every item remembers where and in which chapter it came to you.

### Fixed
- The French of the three older people records speaks in « vous » with French spacing, and a test over npcs.json keeps it so.

## [1.203.0+238]

### Added
- Cities drawn as cities on the Journey. A city, a town or a village of the geography gets a plan of its own, laid out once from its seed: a wall with gates and towers (none for a village), main streets from each gate to the market square, ring streets and lanes between, houses set along every street with the blocks filled in, a church (a chapel in a village), a keep in a city, a mill by the water or a windmill without, fields and a suburb outside the wall, trees in the yards and woods in the country. The water is drawn through it: a river with bridges where the streets cross it, or the shore with its surf. The story's districts stand on the plan as what they are: a gatehouse, the market, a wharf with its piers and boats, a quay with warehouses, a shipyard with a hull on the slip, a keep in its bailey, a temple, a guild hall, an undercroft, a slum of shacks outside a gate, fields, the tear.
- The party stands where its district is, the ways into the other districts sit on those districts' buildings, the ways out leave at the map's edge where the roads go, and the ways within the district gather round the party. Walks follow the streets.

## [1.202.0+237]

### Changed
- The world chart drawn in more detail. The sea has shallows along every coast, water lines off the shore when looked at close, and waves on the open water. The lands have a pale shore band, a dotted edge round each land, a stipple of the biome's grain, and denser terrain: woods in clumps with firs on the cold lands, rounded hills shaded on one side, rocks, snow in drifts, lakes with an outline. Rivers run as a thread at the source widening to the mouth, with a light down the middle, streams that feed them and a small delta where they meet the sea; the ranges have a ridge line and shaded, hachured peaks. Villages are four houses and a field, a clan's seat a keep between two towers on its ring wall, a ruin two columns and a fallen lintel, a bridge arched. Every reached place has houses round it, and a wall round the big towns. A compass rose and a scale bar sit on the flat chart.
- The chart keeps its names and marks near one size on screen as it is zoomed, instead of growing with it; the small names (ranges, villages, notes) and the finest detail show from the land level on.
- The street map of a place drawn fuller: cased streets with lanes off them, houses set along the streets with pitched roofs and chimneys, towers on the wall, trees in the yards, a cobbled square with a well; a river with banks and ripples, a shore with surf, a quay and boats; a camp with a palisade, its fire and crates; a ruin with columns, an arch and grass.

## [1.201.2+236]

### Fixed
- Autoplay (Edit Mode's jump to a scene or a chapter) meets road hazards where the game does: with the world's places known, a walk between two districts of one city is no road for it either. It still charged the party a hazard on Saltmouth's gate-to-wharf walk.
- The ledger scenes at the end of chapter 4 (6001, 6002) stand at the Hollow Court's steps, where the text has them, not in the Black Reliquary: the flight out of the Court was scored as a journey into the frost (a ration, a whiteout, the chart zooming out) in the middle of a chase. The gate guard's ambush in Saltmouth stands at the gate.
- The French shop keepers address the player as « vous » like every other line in the game, with no word gendering the player and a no-break space before ; : ! ? as in the rest of the data. A test over shops.json keeps it so.
- The geography is never served half loaded: after a cold start the places could be known before the biomes, and the first road taken in that window rolled with no hazard on it.
- A hunt, an alignment hunter's ambush and a road's champion keep what their choice carries: the loss branch, a forced condition, no healing, the lesson, the lucky die's reveal. A hunt with a loss branch is no permadeath.
- A race or profession whose picture the build does not carry (one added in the Data tab) shows the generic mark on the first screen of a new game instead of breaking it; the tiles read the picture from the record rather than guessing its file name.

## [1.201.1+235]

### Changed
- Journey: the zoom between the streets and the land no longer jumps. A pinch shrinks the streets under the fingers; when let go the chart opens at that very zoom on the party's place and glides out to the land's zoom. The − button does the same from the closest zoom. Coming back, the streets grow in from small instead of snapping. The + and − buttons on the chart and the sphere glide too.

## [1.201.0+234]

### Changed
- The game has no Story tab any more: the story is followed on the Journey. The reader stays Edit Mode's, and opens over the game from the Journey's end panel for the ending and New Game+. Jumps that went to the Story tab (entering the game, a restart after death, the map's "back to the story") go to the Journey in play.
- Journey: the "Here / Land / World" chips and the story-so-far strip under the map are gone. A pinch in on the streets, or the − button over them, looks out at the land; zooming in as far as the chart goes on the party's own place, or tapping it, comes back to the streets. The story so far stays a tap away on the journal button by the stats.
- Journey: once the camp stands, "Back to the camp" and "Travel on" sit under the map in a place (they lived on the Story tab).
- Camp: "Places you know", "Expeditions from the camp", the bounty board and the boutiques fold shut from their title row, with a count by it; the fold is kept for the session.
- Camp, the town: each house card says at a glance whether it is Built, Ready, Locked or short of gold, names its price on the Build button, and the line under the town says where the outlined house would go. Ready houses come first in the tray; the purse and how many houses it can raise sit by the Houses/Additions chips. The size code (3×1) is gone.
- Character: the Titles card folds, shut by default, its header naming the title worn and the count held. The Clans card is gone (the Clans screen, top right, has it all, and now the climb card too).
- Inventory in Stitched Ink: the equipment slots are a two-column grid of seam-bordered boxes (gold when filled), a tap on a box chooses, its cross takes the piece off; items carry an Equipped tag and a gold border when worn, a seam otherwise.
- Level up in Stitched Ink: the level, XP road and points to spend in one panel; the stats grouped as Fighting, Body, Mind, and Fortune & presence, each a seam-bordered row with its value in gold and a +1 Point button.

## [1.200.1+233]

### Changed
- Journey: a choice made opens the scene reached full screen, with a Continue button under it that brings the map back (the Read button still opens the current scene at any time).

### Fixed
- The death screen scrolls when the last words run long on a short phone (its column overflowed by 75 px in a CI run).
- The wind-up fight test read the landing line off the two-line log ticker, which later lines could push out before the test looked; it now waits for the next round and reads the full battle log (the one failure of the CI run after v1.200.0).

## [1.200.0+232]

### The world as a sphere

#### Added
- **The world as a sphere.** The calques sheet on the Journey's map opens
  with a switch, *The world as a sphere*: the Land and World levels then
  lay the chart on a globe looked at straight on. A drag turns it, a
  pinch (or + and −) brings it close, *back to the party* turns it to
  where the story stands, and a tap picks a reached place on it. Every
  layer goes through the same projection: coasts, lands and terrain,
  rivers, the ranges, the roads and the wake at sea, villages, bridges,
  giants and the clans' seats, the fog with its clearings, the calques
  and every name; what lies on the far side is hidden, and a land
  crossing the limb is pressed against it. The choice is kept.

#### Technical
- `GlobeView` (chart_globe.dart) is the orthographic look: the chart
  spans 225 degrees of longitude and 140 of latitude, the rest open sea
  under parallels and meridians. `ChartMapPainter` takes a `globe` and
  draws through it; the ground is painted afresh while the sphere turns
  rather than kept as a picture. `chartGlobeProvider` keeps the pick.

## [1.199.0]

### The Journey on one interface, the world under the fog

#### Changed
- **The Journey without the scene block.** The scene no longer sits over
  the map: a **Read** button on the breadcrumb row opens it full screen,
  and the map has the room. Under the map, three chips look at the
  **place** (the steps, as before), its **land** or the **world**, and a
  strip reads the story so far in a line and opens its page.
- **The world chart, zoomable and scrollable any way.** The Land and World
  levels put the whole chart under a pinch and a drag, with +, −, back to
  the party, and a layers button. A reached place tapped on the chart
  tells its blurb under the map. The world map screen shares the chart.
- **The chart's three geographies, redrawn from the design.** The Ring
  (world B) is the default: the lands make a broken ring round an inner
  sea with the Lantern Isles at its heart. The Two Shores (A) and the
  River & the Frost (C) remain the player's choice. Every landmark has a
  spot on each, ashore or at sea as the story has it.
- **Coasts, terrain, roads.** Coasts break into bays, headlands and islets
  from fixed seeds; each land carries its biome's terrain (snow-capped
  ridges, woods and lakes, dunes, marsh, cinder cones, glass); rivers
  bend; the road walked is a cased road in each chapter's colour that
  bends with the ground, a sea leg a dashed wake.
- **The fog, uncharted.** Where the story has not gone the chart shows
  only a dotted coastline and the lands' names, dim; a land clears when a
  place in it is read, and brings its terrain, villages and roads with it.
- **The story so far, as a state.** Its first page, Now, reads the state
  in one go: where the party stands (the lands above it, the ruler, the
  biome), what is happening now (where it came from and with whom, the
  chapter's hint, the last choice), the threads open (the main quest, the
  followed one, every quest in progress with its goal), who is along and
  how the clans stand, and the echoes that still matter. Scenes, What
  changed and News follow as before. The Previously… dialog reads the same
  page.

#### Added
- **The Ring's world.** Six named ranges (the Rime Teeth, the Scaffold
  Crags, the Firebacks, the Vigil Ridge, the Alster Downs, the Lantern
  Cliffs); twenty-four villages and works from the story (Hedgefold and
  Millbrook in the Vale, Tallow Street, the Veiled Camp, the salt pans,
  the Wreckers' Road, the slag kilns, the Reckoning Wall, the Dawn Wall,
  the hot springs, the Reed Gate and the Bell Road, the Rope Stair and the
  false lamps, the Ossuary Galleries, the milestones, the Ember Run, the
  Frost Quarry, the Glass Strand, the Lantern Train, the salt marsh, the
  cliff lamps, the Admiralty yards, Lowtide); five bridges, two stone
  giants; every clan's seat ringed in its colour with a pennant (the
  Lantern Throne, the Spire, Anvil Gate, the Heron's Wake, the Brig, the
  Vigil's Wall, the Exorcists' Gate, Highhearth, Akagiri, the Kindly Hill,
  Lowtide, the Open Hand's ruined hall); twelve later-quest places and the
  grey trade and quest roads to them. Each shows once its land is reached.
- **Calques.** The layers button opens a sheet of calques, one at a time
  and kept: the clans' zones of influence (each land washed in its clan's
  colour, stripes where two contest it, a legend), the player's standing
  (hunted red to sworn gold), the lands in their colours, the road by
  chapter, and shops and camps. Influence shows only on lands reached, so
  the calque cannot spoil the road ahead.
- **Drawn towns.** Each district of geography.json names a glyph (bridge,
  keep, quay, cellar, gate, market, wharf, yard, temple, void, hall,
  field, slum), drawn above the way into it on the Journey map; a place
  names its water, a river through it or a shore beside it, and the map
  draws it.

#### Technical
- `lib/data/chart_worlds.dart` is generated from the design canvas's
  world data (page W, Journey & the map) and checked in as the source of
  truth: places, lands, rivers, zones with their biome and influence,
  ranges, features and trade roads per world.
  `ChartRelief` (chart_relief.dart) works out each geography's coasts,
  zones, rivers, islets and terrain once; `ChartMapPainter` records the
  static layers in a picture per look. `storySoFarProvider`
  (story_state.dart) composes the state. `chartCalqueProvider` keeps the
  calque. The `world_map_shape_*` names are now The Two Shores, The Ring,
  The River & the Frost.
## [1.198.1+230]

### Fixed
- **Journey map: the city stays on screen.** The map only zooms out to the
  world chart when the party leaves one location for another (Alster for
  the Waste, the camp for a village). A step between two districts of the
  same city (the Blind Beggar to the Stone Bridge, the Landward Gate to
  the Wharf) is a walk through its streets: the party walks the street on
  the city's plan, and the plan and its look stay the same from district
  to district.
- **The road's rules follow suit.** A walk between districts of one city
  costs no day or ration and holds no road event. Only a journey between
  locations does.

## [1.198.0+229]

Three pieces, merged over main's v1.196 (the Throne) and v1.197 (geography).

### Clans in the story

#### Added
- **Clans in the story.** The scales in the top bar, until now only in Edit
  Mode, now open the clans in the story too, titled "Clans", with a dot
  while news from the coast waits unread. It keeps the four tabs, read only:
  - **Standing:** a card per clan, then the tribes the story has opened, the
    dead clan once remembered, and the Choir and the Pit. No sliders, no
    offers, no reset, and a sub-clan's square is not a switch.
  - **Politics:** the relations table back to chapter 1, but no further than
    the chapter reached. A cell gives the reason, with nothing to shift. The
    news from the coast takes the place of Edit Mode's events.
  - **Evolution:** each clan's standing over the story, and the log.
  - **Intrigues:** only the plots the story has opened, and only as far as
    each has gone. The next stage shows locked with its chapter, the
    premise stays hidden until the reveal, and only the chosen outcome shows.

#### Fixed
- The relations table fits a 360-px phone. Its cells take the width the
  screen allows, from 50 to 60 px; before, the sixth clan's column was cut
  off.

### Shops with a trade, a keeper and a clan

Every shop has a trade, a keeper and a clan.

#### Changed
- **One trade per shop.** The shelves are re-sliced so no two shops sell
  the same gear: the Weaponsmith carries blades and spears t1–t5 (tiers 4
  and 5 were sold nowhere), the Shieldwright is the armour house, the
  Apothecary sells cures and nothing else, the Tide Cellar what the law
  forbids, the Hammersmith heavy steel and heavy armour, the Academy every
  spellbook and the tomes, the Needle House daggers and the quiet books,
  the Vault one each of the named blades and relics, the Ossuary bone and
  salt armour, the Last Lantern charms and holy steel, the Chandlery sea
  gear (the whole Harborwatch set). Potions, charms and tomes may sit on
  several shelves; gear sits on one. Every die is sold at one shop.
- **The caravan wanders.** The Wayfarer's Caravan draws six of a
  twelve-item pool each chapter, always one thing from the chapter ahead,
  the same draw on every device (`stockPool`, `stockDraw`).
- **A sign per trade.** Fourteen new shop icons in the item icons' style
  (an anvil, a shield, a mortar, a cellar door, a needle, a wagon…) in
  place of the seven chests; the caravan has its own.

#### Added
- **Keepers.** Each shop names its keeper and what they say, by the
  standing with the shop's clan: a plain line, a Wary one, a Trusted one
  and a Sworn one, in both languages. The shop opens on the sign, the
  keeper and their line.
- **Every shop has a clan** (but the Bazaar and the caravan, who trade
  with all): the Compact's forges and shield hall, the Crows' cellars,
  barrow and Needle House, the Courts' Apothecary, the Dominion's Academy
  and Chandlery, the Vigil's lantern, the Penitents' Ossuary. The clan
  pricing of v1.193 now has shops to act on.
- The Clans screen lists each clan's shops under its standing.

### Race & Profession on one screen

#### Changed
- **Race & Profession, on one screen.** The ten tall cards give way to two
  rows of five tiles — a mark, a name and a word (Sturdy, Quick, Bulwark,
  Caster…) — with the picked one told in full below: its lore, what it
  changes as green and red chips (zeros left out), and the skill it grants
  with its icon and its own name (Stoneskin, not Dwarf Stoneskin).
- **Your character, before you commit.** A preview card adds the two up
  the way a new game does — HP, damage, armour, gold, the abilities, the
  two skills — so the numbers are known before the choice is set in stone.
- **A mark for every people and calling.** Ten pixel icons in the item
  icons' style: the sewn banner, the painted sigil, the stone-mark, the
  ash-ink and the tear for the races; sword and shield, staff, daggers,
  sun-cross and bow for the professions. They show on the picker and on
  the character sheet (`visualAsset`, `tag`, `tag_fr` on both records).

## [1.197.0+228]

Every scene now happens somewhere. The world has five levels of place
(continent, country, zone, location and, in the big cities, district),
and every zone has a land of its own: its biome, fauna, flora, weather
and hazards. The Journey map shows where you stand, and the road can turn
against you.

### Added
- **The world's places** (`geography.json`, 63 places):
  - **4 continents:** the Old Continent, the Ashen Continent, the Lantern
    Isles and the Seas.
  - **9 countries**, each with its ruler where it has one: the Alster
    Marches, the Waste, the Salt Coast, the Narrow Sea, the Ashen Coast,
    the Grey Fen, the Frost Reach, the Hollow Cape and the Throne's
    Demesne.
  - **12 zones** and **23 locations**.
  - **15 districts**, in Alster, Saltmouth, the Black Reliquary,
    Candlehold and the Hollow Shore.
  - Every scene of the story, every expedition and every enemy has its
    place. A scene has a `location`, and an enemy lists the `biomes` it
    lives in.
- **Ten lands** (`biomes.json`): temperate, desert, arid coast, sea,
  ashlands, volcanic, sea cliffs, fen, frost and the tear's glass. Each
  has six animals, six plants, three kinds of weather, two hazards, its
  colours and a pattern of its own.
- **Journey map:**
  - A breadcrumb above the place map shows Continent › Country › Zone ›
    Place › District.
  - Under the plan, the land's pattern is painted faintly: dunes, salt
    flats, waves, ash, terraces, cliffs, reeds, snow, glass or fields.
  - Tapping a crumb opens **This land** (« Cette contrée »): the place,
    its zone and land with their fauna, flora, weather and hazards, the
    country with its ruler, and the continent.
- **World map:** a landmark's panel shows its breadcrumb and its land.
- **Codex, Lands** (« Contrées »), after Clans in the Other tab: the
  continents, countries and zones you have found, with their fauna and
  flora and the places you reached. Places not yet found show as "…".
- **Road hazards:** a road through a land with hazards can hold one
  (a fifth of road events), such as a sandstorm, a whiteout, an ash storm
  or a racing tide.
  - **Push on:** everyone loses 10 + 5 × chapter health, never below 1.
  - **Wait it out:** a day passes and a ration is eaten.

  The Journey map shows the hazard before you set out. The simulator and
  autoplay push on above half health and wait below.
- **Local champions:** a champion on the road is one of the land's own
  creatures when the land has at least two.
- **Edit Mode:**
  - The node editor has a Location field.
  - The Data tab edits `geography.json` and `biomes.json`, a zone's
    `location` and an enemy's `biomes`.

### Changed
- **Place names, one per place:**
  - The Hollow Shore is « la Rive Creuse » on the charts too.
  - The Ashen Coast is « la Côte de Cendre » everywhere.
  - On the archipelago chart, the chapter 4 isles are the Grey Fen.
  - « Au-delà de la déchirure » is written alike in the zone, the quest
    and chapter 8's title.
- **French typography:** the chapter titles and landmark blurbs on the
  world map get their non-breaking spaces, and a few lines no longer
  assume the player's gender.

## [1.196.0+227]

The game now ends with you on the Lantern Throne. You climb from a House
to a clan to the Empire, and one faction always wins: the Dominion keeps
the Throne, one of the five clans takes it, or your own dead clan, the
Open Hand, comes back. Chapter 8 follows the crowning: you gather the
force you built and face the last bosses. Chapter 1 is rewritten to the
new outline, from the casino to the oasis, and chapter 2 moves to
Saltmouth.

### Added
- **The climb** (« l'Ascension »), three rungs per faction:
  1. **House** (« Maison »): befriend one of its sub-clans. You can be
     friends with Houses of many clans.
  2. **Clan**: finish its three clan quests. The third makes you its head,
     and the clan becomes **your claim** (« votre prétention »). You hold
     one claim at a time: taking a second gives up the first (−15).
  3. **Throne** (« Trône »): win the war for the Lantern Throne in
     chapter 7.

  Clans you worked for but did not take can **pledge** to your claim
  instead and fight for you in chapter 8.
- **20 House favours**, one for every sub-clan that had no way to befriend
  it, spread over chapters 2–6. This includes the Open Hand's own House,
  **the Fishbasket Line** (« la Lignée des Paniers »): the children the
  Wickwardens smuggled out in fish baskets. You find a cousin who can also
  draw.
- **18 clan quests**, three for each of the Dominion, the Grey Vigil, the
  Cinder Compact, the Mire Courts, the Salt Crows and the Ashen Penitents.
  The third offers two choices: take the clan, or stand beside it (a
  pledge). The Open Hand has no quests; its claim is the banner raised on
  the Hollow Shore.
- **Chapter 7, "The Lantern Throne"** (« Le Trône de la Lanterne »):
  - The eve of the war.
  - **Candlehold**: confirm your claim. Without one, choose a late claim:
    the Open Hand is always offered; the Dominion needs Known standing; a
    clan needs a House and Trusted standing.
  - A way in for each of the seven claims.
  - **Your rival's last stand**: one of the three claimants of the
    Dominion's succession, each a new boss: **Aurel Vane** (fire and
    hexes), **Hesk Morrow** (heavy blows and guard) or **Maud Tallis**
    (light and lamps).
  - **The coronation**: seven endings, each with its own consequences for
    the clans.
- **Chapter 8, "Beyond the Tear"** (« Au-delà de la déchirure »):
  - You **muster your Host** (« l'Ost »): the banner (the faction on the
    Throne), every faction at Trusted or better or that pledged, the Choir
    or the Pit if you took their sign this life, and your friend Houses.
  - Each contingent adds its own effects to the last fights, and each
    House adds a little health and starting block. A typical Host is worth
    about +10–15 % to the party, a full Host about +30 %.
  - A council of war and a walk along the lines.
  - **The Battle of the Hollow Shore** against a new boss, **the
    Tear-Herald**.
  - Then the Sovereign beyond the tear. The four endings are now told from
    the Throne, with an epilogue for each winner.
- **The Host on screen:**
  - The Character tab's Clans section shows your climb (House · Clan n/3 ·
    Throne), or "On the Lantern Throne for …".
  - A **Your Host** sheet lists who came and why, with each one's effects.
  - Choice hints name claims, pledges and the Throne.
- **Seven throne titles**, such as **Lantern-Bearer** (« Porte-Lanterne »).
- **Edit Mode:** Clans & Politics has a **Throne** tab (rungs, steps,
  claim, crown, pledge, Host preview, "Muster now"). The node editor has a
  `politicsIf` field and a `hostFight` switch.
- **Story data:**
  - New politics keys: `claim`, `pledge`, `throneWinner` and `muster`.
  - New conditions: `claim`, `rungAtLeast` and `throneWinner`.
  - A choice whose `politicsIf` fails is hidden, or shown locked when it
    has a `lockedText`.

### Changed
- **Chapter 1, rewritten to the new outline:**
  - **The casino:** you are at your usual clandestine den when a blast
    tears the wall away. The Inquisition is in the streets. There are
    three ways out:
    - Strip the tables in the rout (alignment −). Each table is one more
      fight, for gold, with no healing in between.
    - Fight your way to people in trouble (alignment +). Each person
      saved is one more fight, with no healing.
    - Take your stake and leave.
  - **The first fight:** after your first wound, **your lucky die** rolls
    loose and strikes your opponent with a spell, and the fight tutorial
    explains the dice.
  - **Across the city** to the house, which is being searched.
  - **The cannonball:** a ball from the flying fleet folds the wall, and
    Inquisitor-General Aurel Vane drags your sister Lysa out. You can:
    - **charge** him (very hard; win and she is saved);
    - **run**, to come back for her later (alignment −);
    - **kneel and beg** (alignment +).

    The last two, and a lost charge, end in the torture and the escape.
  - **The trapdoor** in the ruins: the old cloth with the open hands.
  - **The quay**: one way aboard the flying vessel, by Charisma,
    Intelligence or Dexterity. A failure costs gold, a bribe or health,
    and you board anyway.
  - **The lift-off, the first storm and the crash** in the desert.
  - **The road to the White Wells oasis**: heat, a stone face in the
    dunes, and looters.
- **Chapter 2 moves to Saltmouth** (« Bouche-de-Sel »), the port where the
  desert meets the sea. You reach it overland from the oasis. The Eel is
  bought (120 gold) or worked off at the ship-breaker's yard before its
  repairs.
- **Chapters:**
  - Scenes 7400–7799 are chapter 7 and 7800 and later are chapter 8.
  - The last fights before the Sovereign now use chapter 8's difficulty.
  - The `the_throne_filled` event is now "The Dominion's succession". It
    names the Dominion's leader.
  - `the_last_battle` is now "The Host gathers", in chapter 8.
- **Boss tuning**, checked with the in-app simulator against the old final
  boss:

  | Boss | Health | Damage |
  |---|---|---|
  | Hesk Morrow | 420 → 390 | 31 → 22 |
  | Maud Tallis | 385 → 300 | 29 → 23 |
  | Tear-Herald | 392 → 345 | 31 → 27 |
  | The Sovereign (now in chapter 8) | — | 31 → 30 |

  - Morrow's damage climbs with rallies and charges, so he lost damage
    rather than health.
  - The three claimants now win alike.
  - The Herald is a little easier than the Sovereign.
  - With a typical Host, the Sovereign is as hard as before.

### Fixed
- **No death in story branches:** a story fight with a branch for losing,
  such as the charge at Vane, never kills under permadeath.
- **Saves in moved scenes:** a save standing on a removed chapter 1 scene
  loads at the scene that replaced it.
- **Journey map:** a place with many scenes gets a taller map, so the
  marks no longer overlap.

## [1.195.0+226]

The clans now move with the story. You come from a dead clan, the Open Hand,
and you find out who they were one chapter at a time. Your choices shift
the clans' standing, and the coast changes whether you are there or not.

### Added
- **The Open Hand** (« la Main Ouverte »), the clan the player comes from.
  They were drawers who held the Seal whole on this coast until the
  Reliquary and the Inquisition cut it and burned them, nine years before
  the first night. They are remembered in six stages, one per chapter:
  1. **The cloth (ch1):** a figure with raised, open hands on the heirloom.
  2. **The name (ch2):** an old sign-painter on the Wharf sees the hand and
     goes white. You can buy his silence or let him talk.
  3. **The blood answers (ch3):** the High Warden's standard answers the
     cloth and you draw for the first time. You let it be seen or hide it,
     and the Inquisition, the Penitents and the Vigil take note.
  4. **The ledger (ch4):** the Hollow Court's oldest page names the clan,
     the Unmaking, and the children given to the Wickwardens. In chapter 5,
     the Last Lantern's keeper turns out to be one of them.
  5. **The truth (ch5):** the Reliquary's own record of the Unmaking and of
     the rite that tore the coast. Tell the coast or keep it.
  6. **The banner (ch6):** raise the heirloom on the Hollow Shore, or keep
     it furled. Clans at Trusted or above send someone to stand under it.

  The endings change with the banner, the truth and who stood under it.
  From stage 3, offers can bring a fourth card, **"Your own hand"**, with
  six Open Hand signs. It moves no clan's standing. Once the banner is
  raised it always comes, and the Dominion hunts it (−2 each time).
  Two titles: **Drawer** (« Main qui trace ») and **Last of the Open
  Hand** (« Dernière Main Ouverte »). The codex shows how far you've
  remembered.
- **Choices move the clans.** 37 existing choices and the new scenes carry
  politics: standing (through the ripple), sub-clan friend and foe marks,
  relations between clans, intrigue stages, offers and events. A muted line
  under the choice says what it does, such as "Vigil +5 · Dominion −5".
  Hidden consequences stay hidden, and a setting turns the line off.
- **News from the coast** (« Nouvelles de la côte »). 20 events happen on
  their own at a chapter, a day or a flag. Each has variants decided by
  your flags, standings and relations: the Lantern-Bearer's death, the
  Inquisition's raids, the Order and the Inquisition quarrelling, the
  Throne going to the claimant you backed, the Dominion splitting if the
  truth was told, and who comes to the last battle. News shows on the
  chapter card (three lines each), as a "News (n)" chip at camp, and in
  full in a "News" tab in the journal.
- **Two intrigues in the story, from Clue to Choice:**
  - **The Hooded Lantern:** the Inquisition isn't closing the tear; it
    wants your blood for the rite. It ends in the flagship's log, which
    you can send to the Order or sell to the legate.
  - **The Dying Lantern-Bearer:** envoys from three claimants, a sealed
    vote, a knife meant for Tallis, and the Admiralty's vote for you to
    cast. You back Morrow, Vane or Tallis, and the Throne follows.
- **Edit Mode:** the Politics tab lists every event with "Fire now", after
  the coast's history, and the Evolution log names each event that moved
  the clans.

### Changed
- The 12 new scenes are on the world map, each in its place's list.
- Save data keeps the events already fired, the news, and which story
  choices already applied their politics, so nothing applies twice.

## [1.194.0+225]

Skill points are gone: the clans now come to you. At each level-up, after a
boss and at a new chapter, three suitors from three different factions each
put one gift on the table, Hades-style. Taking one is choosing a side.

### Added
- **Offers** (« Propositions »). Three suitors, each voiced by one of their
  sub-clans ("The Emberwives of the Cinder Compact…"), each offer one gift:
  - a **skill** from a branch the clan sponsors for your class or people;
    the deeper skills need more standing (Unknown: the first, Known: the
    second, Trusted: the third, Sworn: the fourth);
  - a **sign**, with Signs' slots, rarities and duos;
  - an **object** from the clan's stock, gated by standing;
  - a **title** to wear.

  **Who comes:**
  - Clans that aren't Hostile or Hunted.
  - Tribes, once you've found them.
  - The Choir or the Pit, by your alignment. Their gifts are always Rare or
    better and move your alignment by 3.
  - Sometimes the Wayfarer, who belongs to no faction and brings a perk or
    a potion.

  **Each card shows what the pick does to your standing,** for example
  "+6 Compact · +1.5 Vigil · +1.5 Mire · −3 Penitents · alignment +1".
- **Where offers come from:** one per level-up; one per boss beaten; one per
  new chapter, announced on the chapter card; one per Tome of Mastery. A
  character's starting skill points become starting offers. Offers wait if
  you close them, with a badge on the Character tab.
- **Taking a gift:** +6 with that clan, or +10 for a chapter offer. The
  ripple applies, the voicing sub-clan counts you a friend, and the clan's
  lean nudges your alignment by 1.
- **Titles:** 37 to earn and wear. Wear one at a time on the Character tab;
  it shows under your name and works in fights and at sea.
  - **Tier titles** come the first time you reach a tier with a clan.
  - **"The Marked"** sticks to you while the Inquisition counts you a foe,
    and **"the Challenged"** while the Order does.
- **Sworn boons:** only one clan can be Sworn, and only a clan. It offers its
  boon once, and the boon works while you stay sworn:

  | Clan | Boon |
  |---|---|
  | Dominion | the Writ cancels the first enemy blow each fight |
  | Compact | its edge breaks the first raised guard |
  | Crows | their Price takes 3 gold a hit |
  | Penitents | the Ember lifts the first Curse |
  | Mire | your poisons last a turn longer |
  | Vigil | Open Eyes shows the enemy's next move one turn further |

- **Edit Mode:** "Offer now" and "+1 offer", on the Character tab and the
  Clans & Politics screen.
- A short tour the first time an offer opens.

### Changed
- **The player has no skill points any more.** The skill screen lists your
  skills, shows which clan offers each skill you lack, and keeps tier
  upgrades with essence. Mastering a branch now costs 2,000 essence.
  Companions keep their own skill points.
- **One pick per level.** The level-up perk pick and the separate sign pick
  are now offers. Perks come from the Wayfarer, and perk ranks you already
  have still count.
- **Old saves:** each unspent skill point, waiting perk pick and waiting sign
  pick becomes a waiting offer. Learned skills, perk ranks and signs are
  kept. Loading doesn't grant the current chapter's offer again.
- The playthrough simulator takes offers, and can still run the old rules
  for comparison.

### Balance
Fights won per attempt (1,000 simulated runs each), old rules → offers:

| Chapter | Old rules | Offers |
|---|---|---|
| 1 | 59.1% | 57.1% |
| 2 | 38.4% | 36.1% |
| 3 | 32.3% | 34.9% |
| 4 | 21.2% | 23.1% |
| 5 | 16.3% | 17.1% |
| 6 | 25.0% | 25.9% |

Clan weapons and armour now need one more tier of standing (Known instead of
Unknown, and so on): offering them early made chapters 3 and 4 too easy.

## [1.193.0+224]

The coast's clans arrive, from "The Grey Shroud" design: the Lantern Dominion
and five clans, 29 sub-clans, your standing with each, and politics that can
change. In Edit Mode, a new "Clans & Politics" screen shows it all.

### Added
- **The factions:**
  - **the Lantern Dominion** (« le Dominion de la Lanterne », eight Houses);
  - **the Grey Vigil** (« la Veille Grise »);
  - **the Cinder Compact** (« le Pacte des Cendres »);
  - **the Mire Courts** (« les Cours du Marais »);
  - **the Salt Crows** (« les Corneilles de Sel »);
  - **the Ashen Penitents** (« les Pénitents de Cendre »).

  Each clan has its motto, sub-clans and favours, its sponsored skill branches,
  its objects and its Sworn boon. The Choir and the Pit (angels and devils)
  and the four hidden tribes are factions too. The Dominion's House of
  choristers is now "the Cantors of the Flame", since "the Choir" is the
  angels.
- **Standing** from −100 to +100 with each faction, in seven tiers: Hunted,
  Hostile, Wary, Unknown, Known, Trusted, Sworn. The Dominion starts at −10.
  - **The ripple:** a clan's allies gain a quarter of what you gain with it,
    and its rivals lose half of it.
  - **Sworn:** only one faction can be Sworn at a time. Swearing costs each of
    its rivals 20, and they stop at Known while you stay sworn.
  - **Marks:** each sub-clan counts you a friend, nothing or a foe.
  - Every change is logged with its cause, chapter and day.
- **Relations between the clans,** on a seven-step scale from blood feud to
  allies, starting from the design's table. They can move, and each move is
  logged with a snapshot per chapter. The design's 12-event history and its 8
  intrigues are in the data.
- **Prices follow your tier** in the six clan shops: from +40% when they are
  hostile to −25% when you are sworn. A clan that hunts you won't trade.
- **Edit Mode: "Clans & Politics"**, the scales button beside the map button.
  It has four tabs:
  - **Standing:** a card per faction with its meter, sub-clan marks and
    sliders, plus the Choir ↔ Pit bar.
  - **Politics:** the relations table, with a chapter slider and the history.
  - **Evolution:** a chart of your standing over time, and both logs.
  - **Intrigues:** where each plot stands.
- **A Clans section on the Character tab** shows your standing with each clan.

### Changed
- Signs now come from the real factions. The placeholder clans (the
  Standard, the Painted, the Stone-marked, the Inked, the Lettered) are gone:
  their signs went to the Dominion, the Mire, the Compact, the Crows and the
  Penitents. The Vigil gets 7 new signs of its own, and the
  "three clans a life" limit is gone.
- The Patrons codex is now the Clans codex.

## [1.192.0+223]

A new way to grow, Hades-style: **Signs**. Factions draw power on you, three
offers at a time, and every life builds a different kit. Levels, stat points,
skill points, the skill tree and the level-up perks stay as they were.

### Added
- **Signs** (« Signes »). A patron's drawer offers three signs; you take one.
  - **When:** every odd level (3, 5, 7…), next to the perk pick on even
    levels, and after every boss you beat. Picks wait if you close the
    offer: the Character tab shows a badge and a button to reopen it.
  - **Slots:** one sign each for your Attack, Defend, Heal and Mana faces
    (Strike, Guard, Mend, Spell), plus any number of passives. A new sign for
    a filled slot replaces the old one ("Replaces: …"), keeping its level and
    the better rarity.
  - **Rarity:** Common, Rare, Epic, Heroic (×1 to ×2.5). Luck and favour
    with the patron raise the odds.
  - **Titan's Blood** (« Sang de Titan »): won from hunts and a quarter of
    Elite fights, it raises one held sign a level (up to 5).
  - **Duo signs** appear once you hold signs from both of their patrons.
- **Eleven patrons** (names are placeholders, easy to rename in
  `patrons.json`):
  - five clans, at most three per life: the Standard (banners, the whole
    party), the Painted (crits, dodge), the Stone-marked (block, armor,
    thorns), the Inked (fire, poison, lifesteal), the Lettered (mana,
    spells);
  - four tribes, offering only once you have found them: the giants of
    Highhearth, the oni, the Tide-Kin (the sea: hull, guns, calmer voyages)
    and the Kindly Ones;
  - **the Choir** (angels, alignment 10 and up): vows that fall silent while
    your alignment is below 0. Taking one: alignment +3;
  - **the Pit** (« la Fosse », demons, alignment −10 and below): pacts with
    a curse for their first 3 fights (enemies hit harder, you start hurt, or
    fights pay less), then a strong gift for good. Taking one: alignment −3.
  - The Choir and the Pit shut each other out for the rest of a life.
- 66 signs in English and French, each with its effect text written from its
  numbers.
- **Lives:** a permadeath death or New Game+ takes your signs, waiting picks
  and Titan's Blood; favour with each patron stays and improves later
  rarities. The death screen says so.
- **Screens:** the offer dialog, a Signs section on the Character tab (spend
  Titan's Blood there), a Patrons codex of the patrons met, a tutorial the
  first time, fight-log lines when a sign triggers, and in Edit Mode "Offer a
  sign now" and "+1 Titan's Blood".
- The in-app playthrough simulator now plays expeditions and takes signs, so
  its runs reach chapter 6 instead of stopping at the chapter 2 harbor.

### Balance
Sign values were cut by 40% after simulating. Win rate per attempt, before
signs → with signs (6000 simulated runs, solo, no companions):

| Chapter | Before | After |
|---|---|---|
| 1 | 57.5% | 57.9% |
| 2 | 34.1% | 36.5% |
| 3 | 26.3% | 32.3% |
| 4 | 15.8% | 20.1% |
| 5 | 11.1% | 14.6% |
| 6 | 18.0% | 22.5% |

Chapter 3 is the most changed (+6): it's where most players fill every slot.

## [1.191.0+222]

Narration can be recorded a part at a time and kept in the game. This brings
in PR #104 (built on v1.160), brought up to date with main.

### Added
- **Record narration** (Edit Mode). Open it from Settings → Read-Aloud Voice
  → *Choose scenes to record…*.
  - It lists the story's scenes by kind (main story, places, side scenes,
    endings), by chapter (prologue to chapter 6) and by language.
  - Each scene shows how many of its paragraphs are recorded.
  - Tick scenes, or *Select all* for a filter, then record them in one go.
    It shows the ElevenLabs character cost before starting and can be
    stopped.
  - Companions' asides and the callback, race, profession and hub lines
    are included, or can be left out.
- **Record this scene** (Edit Mode). A microphone button beside the node ID
  on the story screen records the scene on screen: every paragraph it can be
  read in, in the app's language, the fight aftermath line included. The
  button lights up once the scene is recorded.
- **Push recordings to GitHub** (Edit Mode), from Settings or the recording
  page.
  - Every recording on the device that the repository doesn't have yet goes
    to a new `narration-…` branch in a single commit, under
    `assets/narration/<en|fr>/`, each with its words in a `.txt` beside it.
  - It uses the GitHub token from the GitHub sync settings.
- **Recordings ship inside the app.** Once a pull request from that branch
  is merged, the game plays those scenes from its own files, with no API
  key, no recording and no download. Settings shows how many recordings
  are on the device and how many ship with the app.
- `docs/audio-asset-list.csv` and `.json`: the list of sounds the game could
  use.

### Changed
- ElevenLabs recordings are now 64 kbit/s MP3, half the size of before and
  still clear for a voice. That matters now that recordings ship in the
  app.

## [1.190.0+221]

The ship battle gets dynamics: the enemy shows what it will do, the Eel can
push a room past its limit, and a long battle gets worse.

### Added
- **The enemy's next move.** It shows under the enemy's name: fire, close
  in, pull away, ram, board, repair, brace or run. Fog hides it.
- **Enemies change their minds** as the fight goes:
  - a ship with its guns shot up comes alongside to board;
  - a boarder that was thrown back stands off and shoots;
  - a hurt raider waits for help before running.
- **Answers to what you see:**
  - Pull away from a ram and it misses; it can try again later.
  - Pull away from boarders and they're left at the rail.
  - A ship that repairs holds its fire, but its guns keep charging, so its
    next volley is a full one.
  - A braced ship takes half the hull from your shots, and holds its own
    fire.
- **Push a room past its limit**, once a turn, with the bolt button:
  - the guns charge a step;
  - the helm dodges more;
  - the bulwark raises one more shield;
  - the hold bails a leak and patches 8 hull.

  Every push risks the room losing a pip or catching fire (30% the first
  time, 20 more each time after; less with a hand in the room).

### Changed
- **The battle gets worse over time:**
  - A fire nobody puts out spreads to the next room.
  - Leaks make a ship heavy: each open leak costs 5% dodge.
  - The weather follows a trend: squalls build out of crosswinds, and the
    weather readout warns "Squall coming".
  - From round 6 a second enemy sail may appear. A few rounds later its
    guns join the fight at medium and long range, and the enemy stands off
    so they can reach you.
- The ship battle tutorial covers the enemy's next move and pushing a room.
- The Board button takes the dock row's free width, so it fits beside Push
  on a 360 px phone.

### Balance
The ship Monte Carlo, the skilled captain's win rate before and after (the
bands against the classic battle hold):
- Early Eel:
  - raider 59 → 60%;
  - corsair 46 → 49%;
  - cutter 58 → 57%.
- Mid Eel against the void barge: 61 → 66%.
- Late Eel:
  - against the void barge 55 → 53%;
  - against the cutter 98 → 95%.
- Grape-fitted Eel against the void barge: 93 → 83%.
- A plain player, who ignores the new tools, still wins the early raider
  61% of the time.

The beast Monte Carlo:
- First meetings stay ones to live through: at most 59% won with any gun.
  The Leviathan and the Tide-Mother still sink the Eel 90% and 100% of the
  time.
- Running at once still always gets away.
- A prepared hunt with the harpoon wins:
  - Brinejaw 80% (60% on main before this);
  - Leviathan 68%;
  - Tide-Mother 78%, with three hands too.

## [1.189.0+220]

Every finding of the v1.186 review, fixed (built on this branch as
v1.187; main's own v1.187 and v1.188, the new crew orders and dock, come
in with it).

### Changed
- **Rations matter.** The pack holds 8 rations (was 12) and you start
  with 8. The crew eats one for every day at sea. With none left, hunger
  costs health at sea too, as on the road. The camp sells rations before
  you sail.
- **Enemies gather strength later:** after 8 days in chapter 3, 28 in
  chapters 4 and 5, 36 in chapter 6 and 12 in the ending.
- **Storm season still has the odd calm day.**
- **Sea pay.** Sea contracts pay three quarters of a land contract,
  "sink or take" needs three ships, and the beast bounty pays half again
  instead of double.
- **Sea beasts.**
  - Grape and chain are only light shot against a beast. A red-hot ball
    or a fire pot is only its hull: the sea puts the fire out.
  - The Hunter's Harpoon reaches no farther than medium range, so a
    beast can't be kited from long range.
  - The Tide-Mother is smaller (210 hull, was 250), so three hands can
    hunt her.
  - A beast you haven't met yet is more likely to cross the Eel's path in
    its first waters (the Brinejaw on the chapter 3 crossing).
- **The void barge is sturdier** (150 hull, was 140).
- **Prices at the Harbor:**
  - Fire Pots 140 gold (was 260).
  - Hot-Shot Carronade 200 (was 180).
  - Grape Swivel 170 (was 110): it is still the best gun against raiders.
  - The Grape Swivel takes two turns to load.
  - The Speaking Tube says it only helps in timed battles.
- **Dice.** A Recast keeps its number only up to the die's best face of
  the new kind, so a big heal or guard no longer turns into a huge
  attack. The buttons show the number you'll get.

### Fixed: the road and the clock
- A walk between places takes half a day (two watches) and one ration,
  whether you pick the place at the camp or set out on foot on the main
  quest. The main quest's walk no longer counts twice.
- The day and the road agree: each step on the road is a watch, and the
  day ends when night does.
- Sailing to a main quest lands you where it begins, with no extra
  ration, watch, road event or detour.
- A payment you can't afford is shown locked, "not enough gold", instead
  of being given for free. This covers:
  - on the road and on expeditions: a shrine offering, a toll, a bribe, a
    guide's fee, a traveller's price;
  - in the story: Sable's buy-in at the cards, the purse sent to Lysa,
    the chart-keeper's fee, the headman's lamps and the Anchorage's
    riggers.
- Back no longer skips the camp's fate die or a choice it asks for. A
  quick double tap no longer plays a choice, or a night's rest, twice.
- Scenes read on the way to the next one show their "Because you chose…"
  lines, in the Story and Journey tabs, and the journal's What changed
  lists them.
- The walk from the wharf to the berths is a real step on the road again.
- An expedition takes its half day however it ends; backing out of one
  counts as a retreat. A lost sea fight counts its day.

### Fixed: dice fights
- Tempering a face with Lightning works. The Temper sold an element the
  game didn't recognise, so it gave no weakness bonus; faces tempered
  before now strike with Lightning.
- The Temper buttons show element names in your language, and never
  offer a face its own element.
- Kelda's Iron Die, Maren's Holy Die and Sable's Shadow Die are smithed
  apart from your own copy of the same die. One payment no longer
  upgrades both, and New Game+ carries only your own work.
- An Echo that repeats last round's face obeys this round's Silence and
  Curse, and its name no longer grows "(Echo) (Echo)…".
- A silenced Skill face lands as a plain blank; a Steady one no longer
  locks your die.
- Against several enemies, an Echo that copies a strike can be aimed
  like one. The log no longer says a blow was redirected when nobody had
  fallen.
- A hired sellsword strikes in the first round too.
- A Hex no longer takes a Steady die, and a die it rolls again no longer
  stays locked.
- A Mirror also sends back a spell cast that round.
- A Luck nudge is no longer offered, or spent, on a die's middle face.
- Only real bosses drop a Champion's Trophy.
- The Luck description mentions critical hits and nudges; the French
  Pierce rule names the Cuirassé affix correctly.

### Fixed: at sea
- A sea beast lets you go only while you're running; turn back to fight
  and it comes after you again.
- The Tide-Mother can't breach under the Eel and send her arms over the
  rail in the same round.
- A beast held by torn fins that heals back turns back to the fight
  instead of vanishing when its fins mend. No dive is shown while its
  fins are torn.
- A beast is always announced by its omen the day before.
- Signs:
  - A fight you run from gives no sign, no edge and no bounty.
  - A lost fight gives none either, but the beast keeps its wounds.
  - Outrunning a beast leaves a sign, as letting it pass does.
- A hunt keeps its signs until you meet the beast, and it's fought in
  the beast's own waters.
- In French, beasts and ships keep their own look.
- On a small phone the ship picture makes way for the day's text, and a
  crowded room tile no longer spills over.
- The range bracket and the run button show how many turns of running
  are left. Below 30% hull you're told to run for it.

### Fixed: the Journey tab and screens
- A tap on a step always picks that step: only its round mark takes
  taps, and each name sits where it covers no other step.
- The Journey tab no longer gets stuck if you double-tap the scene while
  the party walks.
- A timed scene has one clock, carried between the Story and Journey tabs
  and full-screen reading.
- The map keeps its room on a small phone once a step is picked.
- The day shows once in the top bar; the clock turns red while the
  chapter's enemies gather.
- The camp's chapter card header no longer overflows in French.

### Fixed: text
- French: the Eel is « il », and two story lines no longer give the
  narrator a gender.
- The Journey tour describes the new place map, and the ship battle
  tutorial no longer asks to change each gun's shot.
- "Harbor" is spelled the same way throughout the English text.

### Balance
The beast Monte Carlo, with the Eel fitted as she is in each beast's
waters. These numbers replace the v1.185 ones, which went stale when
main was merged in.
- Running at once always gets away, even from the Brinejaw with the
  chapter 3 Eel.
- Fighting a first meeting to the end:
  - Brinejaw: won 18%, the beast gets away 60%.
  - Leviathan and Tide-Mother: they sink the Eel 91% and 100%.
- Swivel and fire guns don't turn a first meeting into a win. Against
  the Brinejaw:
  - grape 62%;
  - chain 60%;
  - Carronade 39%;
  - fire pots 36%.
- A prepared hunt with the harpoon wins:
  - Brinejaw 92% on this branch, 60% once main's orders-from-rooms rule
    came in with the merge (see v1.190.0);
  - Leviathan 81%;
  - Tide-Mother 91% (87% with three hands).
- Without the harpoon, hunts win 21%, 0% and 0% (Brinejaw 14% after the
  merge).
- Against raiders, the late Eel beats the void barge 55% of the time.

## [1.188.0+219]

### Changed
- **Crew orders are dice.** Each hand's order sits under the sea as a
  die, as the dice fight's faces do: a tap gives it (the die spins, the
  hand goes to its room first when they stand elsewhere, a walking mark
  says so); a hold opens what it does, the rooms it is given from and
  where the hand stands. The dice keep their places, spent or not.
- **Weapons in one row.** The Eel's weapons are compact tiles in a single
  row, so up to nine fit without taking room from the sea: the charge
  ring and damage, and the name when there is room; a hold names the
  weapon, its shot and its state.
- The dock's log line puts the newest line first.

### Added
- **Damage on a hit.** A landed shot's damage pops large over the room
  it hit and beside the hull count of the ship it struck.

## [1.187.0+218]

### Added
- **Stations before the battle.** A sea fight (the voyage, the test
  battle, a story's) opens on the Eel from above and her crew: drag a
  hand onto a room, or tap them then the room. Each row shows the hand's
  order and the rooms it is given from, in gold when they stand in one.
  "By orders" sends each hand to their order's room, the wand places them
  as before, and "Battle!" starts the first round. The turn clock waits.
- **Orders from their rooms.** A hand gives their order from its own
  rooms (Brace from the bulwark or the hold, Eagle eye from the guns or
  the helm, and so on; All hands from anywhere).

### Changed
- **Crew orders on the sea.** The log strip under the Eel gives way to
  the crew's orders, one chip each: the hand, the order, and where it is
  given ("at the hold", "goes to the hold"). One tap sends the hand there
  and gives it. What can be done now comes first; spent orders last.
- **Drag a hand to move them.** A crew token on the Eel, or on an order
  chip, drags onto any room. The crew sheet still moves hands and shows
  each order, but no longer gives them.
- **A smaller dock.** End turn is a compact button at the corner, and
  the crew sheet an icon. The dock's line shows the last two lines of
  the battle, with the whole log a tap away.

## [1.186.1+218]

### Fixed
- **Running from a boarding fight no longer blocks the sea battle.** The
  dice fight's retreat left the sea fight waiting for a result that never
  came, End turn and all. Now:
  - Run from the fight on the enemy's deck: the boarding party falls back
    to the Eel and cuts the grapples. No hull is lost (the retreat takes its
    own gold), the boarding is spent for this battle, and the turn goes on.
  - Run from boarders on the Eel's own deck: the deck is left to them, as
    when they win it.
- **A ship fires no more weapons than she has weapon slots.** The Eel has
  2 weapon slots, 1 shield, 1 utility and 1 sail. The ship built for a
  battle now only uses the parts her slots hold, so a surplus weapon stays
  in the hold.
- **The Fight Lab picks the ship's parts slot by slot** instead of fitting
  every part at once (it armed the Eel with all 8 weapons). The "Pick the
  ship's parts" switch starts from the boat as she is. Each slot type holds
  only what she has room for, and picking one more replaces the oldest.
- **The Fight Lab reports a sea battle the Eel ran from as "the Eel got
  away"**, not as a loss.

## [1.186.0+217]

Brings the two lines of work together: this branch (v1.176 to v1.185.1)
and main (v1.176 to v1.183.1 there, below marked "(main)"), which went
apart after v1.175.

### Changed
- **One world clock.** Main's day and watch (dawn, day, dusk, night) and
  this branch's road days are the same clock now. A step on the road is
  a watch and four end the day; a walk between places is two watches, an
  expedition two; a night's rest sleeps through to the next dawn, wherever
  it is taken (camp, port, town), with the heal wave. Days at sea and days
  lost on an expedition count once, toward the chapter's threat as well.
- **Sea beasts in the sea fight from above.** A beast fights on main's
  top-down sea: its rooms are named for a body (fins, hide, jaws, heart)
  on the deck labels and tooltips, and what it is about to do (dive,
  turn for the deep, held on the line, heal, the crew's edge) shows under
  its name. It has no look of its own yet: it borrows the ship nearest its
  size.
- **Run for it on the new range buttons.** At long range the lower
  button runs for it instead of pulling away; the range bracket counts
  the escape.
- **Each weapon carries its own shot (main) and the hunter's harpoon.**
  The harpoon fires round shot and still holds a beast on the line.
- **The Harbour's cards (main's layout).** Parts stay grouped by slot,
  with this branch's swaps, stored parts, trophies and beasts on them.
- **The Journey map (main's chart).** The fog's glimpses of what lies past
  a step, the road events on steps, echoes in scenes and past marks, and
  the timed scene's clock are all on main's chart.
- **Icons drawn on this branch are out for now.** The five v1.176-v1.182
  foes, the five dice-tampering moves, the beast's trophy and the road
  caravan borrow the icon of the nearest of their kind (a Wrecker captain
  the smuggler captain's, the trophy an elite's, and so on) until they
  have art of their own.

### Fixed (from the review of main's v1.178-v1.183.1)
- **Ways out to the same place no longer sit on one spot** on the Journey
  map: exits on (nearly) the same bearing, as when three choices lead to
  the square, are fanned out along the edge, each one tappable.
- **End turn stays on screen on a short phone.** Below 600 px the enemy's
  bar and the sea scroll and the dock stays pinned under them.
- **Tips no longer cover the enemy's rooms:** a tip shows above the dock,
  off the sea.
- **A still sea is no longer washed white in a squall.** With reduced
  motion the lightning's beat never lands on the still frame.
- **The range reads on a phone.** The ships are sized to the sea's height
  as well as its width, a quarter of the water always left for the gap.
- **The voyage's day strip scrolls** when shelters make it longer than the
  screen.
- **The enemy's guns point at the Eel,** not away from it.
- **A storm's stake counts the void-marked sail,** as the loss itself does.
- v1.183.0's balance note says a skilled player used to switch to chain
  shot against the late void barge; the shot it switched to was grape
  (the barge boards). The entry is kept as it shipped.

## [1.185.1+216]

The sea fight is moving to a top-down view on another branch, so the
beasts' side-view art is taken out, and the version the app reports is
fixed.

### Fixed
- **The version the app reports** (settings, main menu, and what the
  in-app updater compares with a release) had stayed at 1.180.0 since
  v1.181. An installed 1.181–1.185 build kept offering itself as an
  update. A test now keeps it equal to `pubspec.yaml`.

### Removed
- The sea beasts' side-view pixel art and the Kraken arm's icon. Until
  they have art of their own, a beast in battle borrows the ship sprite
  nearest its size (the Void Barge's), and the Kraken arm shows the
  Unstitched's icon. The beasts' rules, rooms, status line and text are
  unchanged.

## [1.185.0+215]

Great beasts now roam the open sea. The first time you meet one, you
should get away alive. Then you track it and hunt it down.

### Added
- **Three sea beasts**, each in its own waters:
  - **The Brinejaw**, a scarred shark, on the chapter 3 and 4 crossings.
  - **The Pale Leviathan**, a serpent-whale, on the chapter 5 crossings.
  - **The Tide-Mother**, a kraken, on the chapter 6 crossings. Its arms
    board the Eel and are fought on the dice.

  A crossing through a beast's waters meets it about one time in four.
  On the day before, an omen shows (fish gone, pale water, a tide
  running the wrong way). When it comes, the crew can:
  - fight it;
  - crowd on sail and run (Dexterity, harder than against a raider; a
    failed run costs hull);
  - strike the sails and keep still (Wisdom). If it passes, it leaves a
    sign of itself.
- **Beasts fight differently from ships.** In battle:
  - Their four rooms are fins, hide, jaws and heart.
  - They heal every round while the heart beats.
  - The Leviathan and the Tide-Mother dive every few rounds. That round
    they don't attack; instead they breach under the keel for hull and
    a leak.
  - Badly hurt, a beast turns for the deep and is gone the next turn,
    unless a harpoon holds it or its fins are torn.
  - Nobody boards a beast, and it doesn't chase a ship that runs.
  - The panel shows what the beast is about to do: on the line, dives
    in n, turning for the deep, heals n a round. A tip explains it all
    the first time.
- **Wounds and signs.** A beast keeps the wounds it takes, up to half
  its body. The crew gains a sign of its lair from every meeting
  survived, every time it passes, some wrecks in its waters and shapes
  seen under the keel. Every meeting also teaches the crew its ways:
  it slips less.
- **The hunt.** The Harbor has a new **Sea beasts** section listing the
  beasts seen, their signs and their wounds. With three signs, and the
  Eel moored at the camp, **Hunt** sends her out: a day at sea, then
  the beast, on the crew's terms. The hunt spends the signs, and a
  beast that gets away must be tracked again.
- **The Hunter's Harpoon** goes on sale at the Harbor once a beast has
  been seen. A hit holds a beast on the line for two rounds: no
  healing, no diving, no fleeing. The Harpoon Rack now holds a beast
  for one round.
- **Trophies.** A slain beast pays gold and experience and gives a
  trophy to sell. It also gives the Eel a part, fitted for free:
  - Sharkskin Hull (helm and hold +1);
  - Leviathan-Bone Plating (bulwark +2);
  - The Tide-Mother's Beak (a heavy piercing weapon).
- **A beast bounty.** While a beast is being tracked, the bounty
  board's sea contract is often "Stand up to a sea beast and live",
  paid double.

### Changed
- **Parts can be swapped at the Harbor.** A part can go on in place of
  one already fitted. The part taken off waits in store and goes back
  on for nothing. Each part card now shows its button under its text,
  so long descriptions stay readable on a phone.
- The Edit Mode fight lab fights beasts as beasts.

### Balance
A Monte Carlo test of every beast, with the Eel fitted as she is in its
waters:
- Running from a beast at once gets away every time.
- Fighting the Brinejaw to the end at first sight wins about half the
  time. Against the Leviathan and the Tide-Mother it sinks the Eel.
- A prepared hunt, with the harpoon, one earlier meeting and heavy
  wounds, wins 96% (Brinejaw), 68% (Leviathan) and 76% (Tide-Mother).
  Most failed hunts end with the beast getting away, not with the Eel
  sunk. Without the harpoon, those hunts mostly fail.

## [1.184.0+214]

The Eel can now run from a fight, and the camp's bounty board has work
at sea.

### Added
- **Run for it.** At long range, with a hand at the helm (or the wind
  behind her), the Eel can turn tail instead of firing. Three turns of
  running and she is out of the fight; a tailwind counts double. No gun
  fires in a turn she runs, and a gun fired first means no running that
  turn. An enemy that closes the gap sets the run back a turn, and the
  range bar shows how far the run has got. On a voyage she sails on as
  she is, with no prize. The story's own sea fights must still be seen
  through. A one-time tip explains it the first time it's possible.
- **Sea bounties.** Once the Harbor stands, one of the board's three
  contracts is the sea's:
  - Sink or take two ships at sea.
  - Take a ship by boarding her.
  - Win a sea fight losing no more than a quarter of the hull.

  They pay like the other contracts, and count on voyages and in the
  story's sea fights alike.

## [1.183.0+213]

Every night rested at the camp now rolls the camp's fate die, so the camp
gets small stories of its own between the chapter's errands.

### Added
- **The camp's fate die.** It rolls after a rest on the camp screen, or
  after resting in a town once the camp stands, since that rest is spent
  at the camp. The dialog shows the six faces, tumbles and lands, then
  plays out the night:
  - **Windfall:** a purse on the sand (40 gold plus 20 per chapter), or a
    crate of rations when the pack is half empty or less.
  - **Visitor:** someone at the fire, and a choice. The party's
    companions react to it like any other deed.
    - Hungry pilgrims: share two rations (+3 alignment), or send them
      on (−1).
    - A Crusade deserter: hide them (+2), or hand them over for a bounty
      (20 gold per chapter, −3).
    - An old storyteller: listen, and every companion in the party warms
      to you a little.
  - **Rumor:** a rider speaks of a place of the chapter not found yet,
    and it appears on the map.
  - **Quarrel:** two companions argue. Side with one (+2 for them, −2 for
    the other), or try to make peace on a Charisma check (+1 each if it
    works, −1 each if it doesn't).
  - **Theft:** a Perception check catches the thief. If it fails, the
    thief takes a tenth of the gold, at most 30 per chapter, or two
    rations from an empty purse.
  - **Quiet night:** nothing, and that is a gift too.
- **No empty promises.** A face that can't happen tonight (no place left
  to find, fewer than two companions in the party) shows as a quiet
  night on the die.
- **No rerolling a night.** Each night rolls from the run's seed and the
  day, so reloading a save doesn't change what comes.

### Balance
- 40 simulated runs against the same runs without the die: about 14
  rolls per run, +256 gold per run in all (next to about 11,000 at the
  end), no hungry days, and no change to the win rate or to companions
  leaving.

## [1.182.0+212]

The dice now have rules of their own. Faces carry keywords, the party's
faces combine into combos, and companion pairs have duo techniques. The
Hammersmith works dice face by face, some enemies tamper with the
party's dice, and Luck turns a bad roll around.

### Added
- **Face keywords.** A face can carry one or more keywords, shown as a
  small badge on the die, in the face sheet and on the dice loadout.
  - **Cleave:** the strike also hits every other enemy standing for half.
  - **Pierce:** the strike goes through Armored and through a guard.
  - **Growth:** +1 each time the face is played in the same fight.
  - **Echo:** plays the face played just before it this round. The first
    in line repeats their own face from last round.
  - **Pain:** double damage, paid with 8% of the roller's health. It
    never drops the roller below 1.
  - **Steady:** +2, and the die stays kept through rerolls.
  - Twenty-two faces across the existing dice carry one. Examples: Steady on
    the Iron, Stone, Bulwark and Vigil dice's guards, Pain on the
    Berserker's and Grosh's big hits, Cleave on the Storm, Flame, Tempest
    and Malrik dice, Growth on the Holy, Ossuary and Liora dice.
  - Three new dice build around them:
    - **Headsman Die** (Cleave, Pierce, Pain, Steady): the Weaponsmith's
      and the Hammersmith's forges.
    - **Greenwood Die** (Growth on four faces): the Wayfarer's Caravan
      and the Wreck-Wrights' Chandlery.
    - **Chorus Die** (Echo on four faces): the Arcane Academy and the
      Last Lantern.
- **Party combos.** When two or more party members act, their faces
  combine. A chip over the dice tray shows the combo before you confirm.
  - **Flank** (exactly two strikes): each hits 15% harder.
  - **Volley** (three strikes or more): each hits 15% harder and catches
    the other enemies for a quarter.
  - **Shelter** (a guard and a heal): the heal also mends the rest of
    the party for half.
  - **Shield Wall** (two guards or more): everyone holds the biggest
    block.
  - **Wellspring** (two Mana faces or more): 2 more mana.
- **Face smithing at the Hammersmith.** The Hammersmith's Forge has a
  new dice button. It works on any face of the player's dice or a
  companion's signature die. The work stays on the die, and on the dice
  that New Game+ carries over.
  - **Hone:** +2 to an Attack, Defend or Heal face, up to three times.
    Costs 80, 160, then 240 gold, with one, two, then three iron ore.
  - **Temper:** an element on an Attack face, for 150 gold and two iron
    ore.
  - **Inscribe:** a keyword on any face it fits, for 250 gold and a
    trophy.
  - **Recast:** turns an Attack, Defend or Heal face into another of the
    three and keeps its number, for 120 gold.
  - The trophy for an inscription is an Elite Mark or the new
    **Champion's Trophy**, which every boss drops.
- **Duo techniques.** Two companions of a pair, both at Friendly
  approval or better, who both land a signature face in the same round,
  add a joint move after the faces:
  - Grosh and Kelda: a stunning blow.
  - Sable and Malrik: a poisoned critical.
  - Maren and Tobin: a party-wide heal that clears afflictions.
  - Liora and Vess: a hit on every enemy.
  - Vess and Sable: weakens and hurts every enemy.
  - Kelda and Tobin: a guard for the whole party.
  - Maren and Liora: mends the most wounded and shoots the target.
  - Grosh and Malrik: a heavy blow that heals the two.
- **Enemies that tamper with the dice**, from chapter 3 on:
  - **Hex:** the party's best die of the next first roll is rolled
    again. Cultist Acolytes, Grey Candles and Tormentors of the Pit.
  - **Silence:** Skill faces land blank next round. A face with a skill
    picked onto it falls back to its own type. Judicators of the Choir
    and Hollow Court Inquisitors.
  - **Curse:** one face of the target's die becomes a Pain strike for
    the rest of the fight. Catacomb Ghouls, Bone Sextons and the
    Unstitched.
  - **Mirror:** the party's best hit of the round comes back, between
    half and twice the enemy's own damage. Hollow Reflections, the Glass
    Shepherd and the Sovereign.
  - A telegraphed tamper shows its own icon and text. A pending Hex or
    Silence shows as a chip over the fight.
- **Luck nudges.** Every 3 points of the party's best Luck give a nudge
  per fight, at most 3. Long-press a landed die and nudge it to its
  opposite face; the new face is kept. The nudges left show over the
  fight.

### Balance
- 40 simulated runs against v1.181:
  - The win rate is unchanged (99%), and losses per run are 0.4 against
    0.8.
  - Story fights in chapters 3–6 are shorter (5.4 rounds against 7.1),
    and allies are knocked out less often (8% of fights against 12%).
  - At the first tuning (+30% combos, a Volley splashing half), story
    fights fell to 4.6 rounds, so combos were cut to +15% and a quarter.
  - Smithing takes about 3,100 gold per run, about 15 Hones in all.
  - A run sees about 22 tamper moves and 57 nudges spent.
- The Champion's Trophy sells for 60 gold, like the Elite Mark, so a
  boss's trophy doesn't flood the early chapters with gold.

## [1.181.0+211]

Chapter 1 is a flight from a city under attack, and now plays like one.
Each chapter after it rolls a condition, so two runs differ more. About
twenty-five one-button scenes became real decisions, and the three
companions most runs never met are easier to find.

### Fixed
- **No shops in chapter 1.** The docks no longer open an armory, a
  shieldwright and a black market while the Rusty Eel weighs anchor.
  Instead there is time to grab one thing: a blade from the looted
  armory rack or a buckler from the overturned cart. The market in the
  slums is abandoned mid-trade, with only a bandit still "doing
  business", and the forge's back room is a cache, not a shop. These
  shops now open at Smugglers' Wharf in chapter 2.
- **Nothing on chapter 1's roads.** Random detours, hunters and
  temptations no longer fire in chapter 1. This had allowed a shop stall
  between surrendering and waking in the Black Hold, or a rest by a fire
  right after killing Clement. Nothing is saved up for chapter 2 either.
- **Set pieces aren't interrupted.** The Sovereign naming its price, the
  crossings through the tear, the roof coming down on the Court, the
  Cathedral burning and the evacuation of Alster no longer stop for a
  detour or a road event.
- **Shops that belong to a place stay there.** The Tide Cellar, the Blind
  Beggar's stall, the Ossuary and the Last Lantern no longer turn up as
  roadside stalls elsewhere.
- **Story fixes across chapter 1 and beyond.**
  - The heirloom quest pays out once the Bundle is out of Alster, not
    while soldiers break the door.
  - Vess joins after the escape, not inside chapter 1.
  - The bridge toll is 100 gold; the smuggler takes coin (60 gold) as
    well as stories.
  - The Black Hold strips you to your shirt and gives your kit back.
  - The alley is dark, not daylit.
  - The Crusade had already reached the slums: it started at the Blind
    Beggar.
  - The bridge is held by slum toughs in Crusade colours.
  - Chapter 2 names old Hesk as the man the Bundle killed.
  - Lysa's fate is told the same way on every path.
  - The Broken's Shroud no longer contradicts how it was found.
  - Maren's confession no longer waits for Lysa to have lived.
  - Mother Hesk is old Hesk's wife.
  - Several French lines no longer give the narrator a gender.

### Added
- **Chapter conditions.** Chapters 2 to 6 each draw one of eight
  conditions from the run's own seed, never the same one twice in a run.
  Each one only appears where it fits: no weather at sea before the boat
  sails, and no fair while Alster falls.
  - **Quarantine:** shops cost a quarter more, rations half again.
  - **Tide Fair:** shops cost a fifth less, and the roads are busier,
    with the Caravan out more often.
  - **Contested roads:** half again as many road events, mostly
    champions.
  - **Storm season / Fair winds:** more or fewer storms at sea.
  - **A rival company / Bounty season:** expeditions pay a quarter less
    or more.
  - **Lean season:** rations cost double.
  - The first town or village you reach in a chapter tells you its
    condition. The road panel (tap your stats) keeps it in view, and
    shops and expedition rewards show what it changed.
- **Decisions where there was one button.** About twenty-five scenes
  across the story now offer two or three choices, with checks, costs
  and consequences that later scenes remember. Some examples:
  - what you take from the ring of loot at the tear, which decides
    whether Vess can find you later;
  - lying past the Wardens;
  - feeding the Rat Matriarch instead of fighting her;
  - sharing Vane's tunnel with the refugees, or selling it;
  - cutting Vane's purse on the way out;
  - the bell rope into the Cathedral;
  - absolving Maren or not;
  - tearing your parents' page out of the ledger;
  - how the dead are buried after the siege;
  - diving for the Court's pay chest, or selling out the deserter;
  - what to do with the Inquisitor who burned the Ashen Quarter;
  - buying the chart-keeper's map;
  - where Lysa belongs;
  - hiring the Admiral's helmsman;
  - the wreckers' false lamps;
  - buying a blade from Tetsu;
  - promises to the widow, to Nell, to the eldest and to Hathra.
- **Scenes can hand you an item** (`grantItemId` on a story choice, shown
  on the choice and in a notice), with an editor field for it.

### Changed
- **Chapter 1 balance.** Without detours or shops, players reached
  Inquisitor Clement at a lower level and with less gear. To compensate,
  chapter 1 fights give more experience (slum thug 30, street bandit 40,
  White Soldier 22). The White Soldiers are a little weaker (80 health,
  19 damage), and so is Clement (115 health, 15 damage).
- **Rare companions are easier to meet.**
  - **Sable** now works with anyone short of a saint (alignment up to
    +15). Her marker can be won at the dockhands' table, lifted from
    the card sharp's coat (Dexterity) or bought back (Charisma, 30
    gold). A lost card game can be played again while she waits, so her
    quest can always be finished. If you won her marker at cards before
    meeting her, you simply hand it over.
  - **Liora** is met on the wharf like the town's other people: talk
    her down (Charisma), read what she is watching (Perception) or climb
    to her (Dexterity). If she refuses, you can try again. Hunting the
    captain with her is the chapter's exit.
  - **Vess** finds you on the wharf in chapter 2 if you missed her in the
    burning market: she follows the Bundle, which everyone carries out
    of Alster. If the tear touched you, she says so.

## [1.180.0+210]

The memories before the story are rewritten. There are six of them now,
from age six to sixteen, set in the slums where the story opens, and
each answer stays with the character.

### Changed
- **Six memories instead of five, set in the story's world.** They are a
  sparrow in the gutter (age 6), a memory of the character's race (8),
  the blind beggar the Blind Beggar tavern is named after (10), the
  first time the class showed (12), old Hesk's blue lamp next door (14),
  and the loose board over the grey Bundle the winter the parents did
  not come home (16).
- **Race and class change what you remember.** A human is pulled out of
  a Crusade feast-day line, an elf's first paint is wet in the rain, a
  dwarf cuts a crooked first mark, an orc's first ink hides from an
  orphan-taker, and voidkin freeze a well. A warrior hauls nets, a mage
  makes a candle lean, a rogue shills at a rigged table, a cleric sweeps
  a shrine and a ranger sets snares.
- **Every answer teaches something (+1 to an ability).** The answers
  show what they teach before you pick. Six answers add six points, and
  no memory teaches the same ability twice. Alignment still leans +4,
  −4 or 0.
- **Each answer shows what came of it.** After you pick, the page tells
  what happened and what it taught, and shows the lesson and the
  alignment lean, before the next memory. You can choose again.
- **Memories remember each other.** A later memory can open with a line
  about an earlier answer. The blind man remembers the sparrow; the
  thief under the board is his granddaughter. At fourteen, the street
  has a name for you, depending on how you have leaned so far.
- **A timeline of ages** at the top of the page, and a summary that
  shows the character's name, a one-line portrait (kind, hard, careful
  or changeable), every answer with its lesson, what the six taught in
  all, and a gauge of the starting alignment.

### Added
- **The story remembers.** 48 new lines in the opening scenes and in
  chapter 5 answer the memories. They appear at the Blind Beggar's door,
  when the party flees with Lysa, at the hound in the wire, at the
  floorboard, when the soldiers break in, when old Hesk dies, over the
  ledger with the parents' names, and when Mother Hesk is found among
  the sleepers. The journal credits each one to the memory's answer.

### Fixed
- **Two Hesks.** The chapter 3 delivery boss from 1.179 shared a name
  with old Hesk next door. He is now Purifier Vell.

## [1.179.0+209]

Two new kinds of expedition: escorts, paid for what arrives, and
deliveries, which race a deadline. There is one of them in each chapter
from 2 to 6.

### Added
- **Escorts.** The wagons set out at 100% load. Each stage is a scene on
  the road with a choice to make: an ambush (hold the line or slip past),
  a broken axle, a ford in flood, a chain across the road with a toll,
  thieves among the crates at night, mules that will not cross, and
  stragglers asking for a place on a wagon. Fights, failed rolls and
  kindness each cost some of the load. A safe choice costs a day instead,
  and that day passes on the world's clock. The boss takes another 10%.
  Pay is the zone's gold times the share that arrives. The zone's item
  comes only with half the load or more, and losing all of it ends the
  escort.
- **Deliveries.** A parcel to carry by a deadline: 6 days for 4 stages.
  Each stage takes a day. A safe detour or a failed roll costs another,
  and a paid guide saves one. The scenes are a crossroads, a checkpoint,
  pursuers, a rotten bridge, a shepherd who knows a shortcut, a storm,
  and a stranger's letter to carry on the way. On time pays in full
  with the item; late pays half without it.
- The expedition screen shows the wagons' load or the days on the road
  under the progress bar. After each choice it says what it cost (load,
  a day, health). Zone cards carry an Escort or Delivery tag.
- **Five expeditions, each with its own boss**, in English and French:
  - *The Salt Road* (chapter 2, escort): Brine Jack.
  - *Fever-Bark for the Wall* (chapter 3, delivery to the Reckoning
    Wall): Purifier Hesk.
  - *The Bell Road* (chapter 4, escort): the Knell-Keeper.
  - *The Ember Run* (chapter 5, delivery to Rimewell): the Rime Bailiff.
  - *The Lantern Train* (chapter 6, escort): the Glass Shepherd.

### Balance (Python simulator, 60 runs)
- The five bosses sit with their chapter's other zone bosses. Their
  first fight is won 98–100% of the time in 6.8 to 12 rounds, against
  5 to 17 for the others.
- Escorts arrive with 70–80% of the load on average, never less than
  25%. They pay 70–80% of the zone's gold and keep the item 95–100% of
  the time.
- Deliveries were first given 5 days (one to spare), and a careful party
  arrived late more than half the time. With 6 days, they are on time
  82–87% of the time.
- An escort or delivery has about 0.3 fights before the boss, so its
  stages are about choices rather than fights.

## [1.178.0+208]

Angels and demons come less often and finish what they start, and stalls
met on the road stay on the road.

### Changed
- **Hunters are rarer and give the party a breather.** A hunter now comes
  6% of the time at ±20 alignment (was 10%), plus 0.15% per point past
  that (was 0.2%), up to 15% (was 22%). After an ambush, the next five
  alignment rolls send no hunter. In the simulator, hunter fights fall
  from 6.6 to 3.1 a run, from the most common random fight to about as
  common as a champion. Temptations for a Neutral party are unchanged.
- **Twelve ambush openings instead of four.** Angels and demons each
  arrive six ways, in English and French.

### Fixed
- **A temptation quest's quarry always comes.** A party that struck the
  demon's bargain and then grew Good met only demons, so the bargain's
  angel never came and the quest could not be finished. While a
  temptation quest is open, its side now hunts the party first, whatever
  the alignment.
- **Any of the Choir's or the Pit's soldiers counts.** "A Charge of Light"
  needs any creature of the Pit and "A Bargain in Shadow" any soldier of
  the Choir, including the stronger ones that come from chapter 3. Only
  kills made after the quest is taken count. In the simulator, runs
  ending with one of them still open fall from 10 in 200 to 4.
- **The Wayfarer's Caravan moves on.** A stall met on the road was
  recorded against the scene the party had just left. Back in that town
  or at the camp, the Shops list opened it again. Stalls met on detours
  and expeditions, and the caravan, are now marked as met on the road and
  stay shut in the Shops list. A shop the story places in a town stays
  open there, even after its stall was met on the road.
- Expedition stalls no longer claim to be at the camp in the Shops list.

## [1.177.0+207]

The road's numbers, tuned with the playthrough simulator. The simulator
now plays v1.176's rules. Over 200 playthroughs on two sets of seeds,
compared with v1.175's rules on the same seeds, it showed where they
missed.

### Changed
- **The threat waits longer in the chapters crossed by sea.** In chapters
  4 to 6, most days pass at sea: about 25 to 33 days a chapter for a party
  that sails to every place, against 1 to 5 days on the road and at rest.
  With a 6-day grace, 41% of chapter 4's fights and 44% of chapter 6's
  came under the threat, most at the full +30%. The party was punished
  for going where the chapter sends it. The grace is now 24 days in
  chapters 4 and 5 and 32 in chapter 6 (still 6 in chapters 2 and 3).
  - About a sixth to a quarter of those chapters' fights come under the
    threat now, at +2 to 3% on average: a party that does everything
    meets it near the chapter's end, and one that lingers still reaches
    +30%.
  - The Road panel says how many days the current chapter allows.
- **Champions are a real fight.** A champion was drawn from every enemy
  up to the chapter, often an early one the party had long outgrown. It
  took no longer than an ordinary detour fight (5.8 rounds, like a story
  fight). A champion is now one of the chapter's own foes (first met in
  this chapter or the one before), with a quarter more health. It now
  takes about 8.3 rounds, and the simulated party still wins 99% of
  first attempts.
- **Familiar faces come back more often.** At a 25% chance, a
  traveller's third meeting happened in only about a quarter of runs.
  At 40%, Oswin's full story is seen in about 70% of runs, Wren's and
  Mira's in about half. Detour fights barely change (1.4 to 1.3 a run).

### Fixed
- A party caught slipping past a champion is ambushed, as the failed
  roll says. The ambush was lost when the fight began.

### Checked and left as they are
- **Rations.** Buying at markets, no simulated party ever went hungry.
  The longest walk between two markets was three roads, and rations cost
  about 270 gold a run. A party that never buys takes about 12 hungry
  steps a run and wins as often.
- **The sellsword.** Hired whenever the threat is up, it is paid about
  1,500 gold a run and deals about a tenth of the enemies' health in the
  fights it joins.
- **Shrines, the caravan, detours.** Detour fights fell from 5.2 to 1.4 a
  run and champions add 2.4, so fights per run stay about the same.
  Losses per run are unchanged against v1.175, and the gold left at the
  end falls by about 17%.

## [1.176.0+206]

Play with fewer taps, and a road worth planning: choices come back, days
pass, travellers return, and the last chapters build to set pieces.

### Added
- **Choices come back, and say so.** When a later scene has a line that an
  earlier choice earned, the line now says which choice it was
  ("Because you chose …"). The journal has a new tab, **What changed**,
  listing every such line the party has seen, newest first. On the Journey
  map, a scene behind the party with such a line has a small history mark.
  Tapping the scene shows the line again.
- **A look ahead on the Journey map.** Small icons above each step show
  what the next scene holds (a fight, a roll, a shop and so on). When a
  scene has only one way on, the map picks it for you, so Go is a single
  tap.
- **Days, rations and a gathering threat (from chapter 2).** A road
  between two places eats a ration, and every four roads end a day. The
  pack holds 12 rations. You start with 10 and can buy more at any town or
  camp market, at 4 gold plus 2 per chapter each. With none left, each
  road costs 8% of your health. After six days in one chapter, its enemies
  gather strength: +3% health and damage per day, up to +30% (bosses
  excepted). A fight says so in its log. Resting passes a night; a voyage
  passes its days. The status sheet has a new **Road** panel with the day,
  the threat, your rations and buttons to buy them. Your rations and the
  day also show in the stats bar.
- **A sellsword for hire.** From the Road panel, hire a sellsword for
  three fights (120 gold plus 80 per chapter). The sellsword strikes the
  weakest enemy at the start of each of your rounds.
- **Road events, visible before you set out.** From chapter 2, about a
  third of the roads between two places hold something, marked on the
  Journey step and named in its details:
  - **A champion.** An Elite of the chapter's enemies, with at least a
    silver chest and a quarter more reward. You can instead try a hard
    Dexterity roll to slip past it; if it fails, the fight starts with an
    ambush.
  - **A wayside shrine.** Health back, and twice as much for an offering.
  - **The Wayfarer's Caravan.** A roadside shop with its own stock.

  What a road holds is fixed for that road at that point in the journey,
  so you can choose your road by it. A road event replaces a detour on
  that road.
- **Familiar faces.** Three travellers are met again and again, three
  times each over the chapters: Wren the mapmaker, Brother Oswin the
  defrocked monk and Mira the treasure hunter. Each meeting is written
  for what the party did at the last one. A kindness, a hard bargain or a
  cold shoulder is paid back in kind, and one of them can come to blows.
- **Set pieces in the last chapters.**
  - **A chase out of the Court's catacombs,** against a 20-second clock.
    If you wait too long, the party is caught and must fight its way out.
    A failed roll corners the party, with the same result.
  - **The siege of the camp,** in two timed waves. First, hold the
    palisade in a fight, light the beach fires to bluff with a Charisma
    roll, or get the children to the boats. Then, sally out against the
    enemy's zealot, or hold the gate in a Constitution skill challenge. A
    failed bluff, a lost gate or the children's escape means a fight in
    the breach. Back at camp, the scene tells what the party did.
  - **Crossing the Hollow Shore,** unseen by Dexterity or Wisdom skill
    challenges, or by force. If you are spotted, an alarm scene follows.
  - **A sea battle with the Crusade's last cutter** from the Anchorage.
    It uses the full ship battle, with its gold, XP and prize. If you
    lose, the ship limps home.
- **Timed scenes.** A scene can carry a clock (`time_limit`, and
  `timeout_choice` for the choice taken when time runs out). The clock
  runs only while the scene is on screen, and not in Edit Mode. The node
  editor keeps both fields.

### Changed
- **Fewer Continue presses.** A scene with a single plain way on is read
  on the way to the next scene. It sits above the next scene's text, set
  off by a ⁂, and the story no longer stops on it. At most two such scenes
  are read in a row. Towns, timed scenes, endings and hub updates still
  stop the story, and Edit Mode shows every scene as before.
- **Fewer, shorter detours.** A road now has a 35% chance of a detour (was
  70%). A detour lasts one or two scenes, or three or four when it carries
  a quest (was up to seven). What waits on a road is now chosen in this
  order: an alignment event, a familiar face (25%), then a detour.
- **Retreat costs more.** Running from a fight now costs a fifth of your
  gold (was 15%) and a potion, if you carry one.
## [1.183.1+215] (main)

### Removed
- **Coral in the shallows and fallen columns in the drowned waters.** The
  shallows keep their seagrass, rocks and reef fish; the drowned waters
  their weed, eels and fish.

## [1.183.0+214] (main)

### Added
- **Life under the water.** Each of the waters has its own bed and fish,
  drawn beneath the waves:
  - the open sea: schools of silver fish, a great shadow passing deep
    down, jellyfish;
  - the shallows: coral heads, seagrass and rocks, bright reef fish;
  - the drowned waters: fallen columns furred with weed, pale eels;
  - the abyss: black spires, glowing jellyfish, an angler's lure in the
    dark;
  - the ashen chop: grey rocks crusted with barnacles, dead weed, small
    dark fish.
- **Three weapons that fire their own shot:**

  | Weapon | Shot | Damage | Turns to charge |
  |---|---|---|---|
  | Chain Swivel | chain | 14 | 2 |
  | Grape Swivel | grape | 12 | 1 |
  | Hot-Shot Carronade | heated | 24 | 3 |

  All three reach close and medium range.

### Changed
- **The shot is the weapon's own.** The battle no longer has a shot picker.
  Each weapon fires the shot set in its part: a new `ammo` field in
  ship_parts.json (round, chain, grape or heated), which is an enumeration
  in the editor. The shot's mark sits beside the weapon's damage in the
  dock, and its tooltip says what the shot does. The tip about changing
  shot is gone.
  - Balance: since a skilled player no longer switches to chain shot
    against a hard ship, the late void barge falls more often (57%, up
    from 23% under the old rules). The balance test's upper band is now
    35 points.

## [1.182.1+213] (main)

### Changed
- **The sea fight is pared down to the mockup:** one enemy bar, small ships
  on a sea that fills the screen, one dock.
  - **Enemy bar:** the enemy's name, habit, shields and hull, in one bar
    above the sea.
  - **The sea** holds everything between the ships:
    - the weather and the next in a chip at the top corner;
    - the enemy's guns as small charge rings, with the room each one
      aims at when the foresight sail shows it;
    - the range bracket down the left edge;
    - close in and pull away as two round buttons on the right, up
      toward the enemy and down away from her;
    - the last two lines of the log at the bottom.
  - **The ships are smaller** (at most 260 px long). How far apart they
    lie is how much of the sea's height the range takes.
  - **Rooms** carry no frame until they matter: a target, a station to
    move to, or the enemy's aim. The room's state is painted on the deck.
  - **The dock** starts with the Eel's bar. The weapons are ring tiles
    three across.

## [1.182.0+212] (main)

### Changed
- **The sea fight is seen from above.** The two ships lie broadside to
  broadside: the enemy at the top, the Eel below. The rules are the same;
  what changed is how they read.
  - **The rooms lie along the deck:** the helm at the stern, the hold's
    hatch, the guns amidships and the bulwark at the bow. Each room is a
    tap zone a thumb wide, showing its pips, crew, fire, leaks and the
    enemy's aim. The rooms' names are written beside the ship in their
    colours.
  - **The range is the gap between the ships.** Closing in or pulling
    away slides the Eel across the water, with a bracket down the side
    naming the range.
  - **Shields are arcs** on the side facing the enemy. The hold fills with
    water as it leaks, a knocked-out room goes dark, and a ship below half
    its hull is holed with torn sails. The wake grows with how quick the
    ship is.
  - **Each enemy has its own look from above:** the raider's short skiff,
    the corsair's two black sails, the inquisition's white cutter and the
    void barge's glowing runes, with no sails at all.
- **The waters of the voyage set the sea.** Each port names its waters
  (a new `waters` field in ports.json), and a fight on the way there is
  fought on them:
  - the open sea's long swells;
  - the clear shallows over sand, with sandbars and rocks;
  - the drowned waters' murk, kelp and rising bubbles;
  - the abyss's black water, slow rings and violet motes;
  - the ashen coast's grey chop under falling ash.

  The Edit Mode test battle can pick the waters.
- **The weather is drawn as particles over the sea.**
  - A squall brings slanting rain, rings where it lands, whitecaps and
    lightning.
  - Fog banks drift across, thickest over the enemy.
  - Wind tears streaks and spray across the water: with the Eel in a
    tailwind, across her in a crosswind.
  - A calm day glints, with gulls wheeling overhead.

  When the weather turns between rounds, the old weather fades out as
  the new one comes in, and a wave rolls under both ships.

## [1.181.0+211] (main)

### Changed
- **The Journey map follows the real map.** Standing in a place the world
  chart knows, the map is that place up close, north up. Before, the ways
  always went up the screen.
  - **The ground** is drawn by what the place is:
    - a town is what is left of its wall, with streets out of the square
      and blocks between;
    - a camp is tents round its fire;
    - a site is broken stones;
    - the sea is its own.

    Each place is drawn from its own seed, so it looks the same every
    visit.
  - **The ways ring the party:** a fight, a shop or a talk in this place is
    a spot round the square, reached by walking its street. A busy town's
    spots fill an inner and an outer ring.
  - **The ways out sit at the map's edge in their true direction:** the
    Cove Camp south-west of the Ashen Quarter, Tern Row from the wharf.
  - **Taking a way out zooms out** to the world chart (in the chosen chart
    shape), and the party walks the road there. The map then opens on the
    new place.
  - The road behind now peeks in at the map's foot, and "You are here"
    sits in a corner badge.
  - A detour, on no place, keeps the road going up as before.
- On a busy hub every way now inks in; the last ones used to stay hidden.

## [1.180.0+210] (main)

### Changed
- **The camp puts the next step first.**
  - One header: the camp, its chapter, the day and the hour, and the
    purse.
  - The main quest is a checklist: each place still to visit is a line
    that leads to the Road, then how much of the chapter is explored and
    its quests settled. The way in says how many steps are left.
  - The camp's scene is a card until read ("Put it away"), then a chip
    beside Rest that opens it again.
- **The camp in four tabs:**
  - **Road:** places, expeditions and the bounty board;
  - **Town:** the cliff town and its shops;
  - **Party;**
  - **Sea:** the Rusty Eel, the harbour and the chart.

  It replaces eight sections in one scroll.
- **The harbour is always in view.** The Sea tab shows the Eel drawn on
  the water, her hull (in the sea's colour, red when low), her named
  shield, her slots and the repair. Until the harbour is built, a card
  says what it gives and costs, and a tap goes to Town. Once built, it
  opens the refit, where the shipwright's parts are grouped by slot
  ("Weapons · 1 of 2 filled") with the Install button under each.
- **A day at sea you can read:**
  - the crossing as a strip of days, each behind her showing what it
    cost or gave, today marked, the rest unknown;
  - the Eel on the water beside what she meets, and one hull bar;
  - every choice says what it wins or costs and, for a check, the bonus,
    the DC and the odds ("Perception +1 vs DC 15 · win +80 gold · fail
    −12 hull · 35%"). No choice is highlighted as the one to take;
  - the log is labelled, and hull losses carry their minus sign.

## [1.179.0+209] (main)

### Changed
- **The Skills screen, simpler.** Three tabs with one job each:
  - **Tree** to learn;
  - **My skills** to raise tiers and craft;
  - **Spells** for magic.

  The List view, its two rows of filters and the compare mode are gone.
- **One sheet per skill**, wherever it is tapped:
  - its numbers at base and at each tier;
  - the die faces it sits on, with a way to the dice;
  - one button: Learn, or Raise tier. When greyed, it says how much
    essence is missing and that essence comes with XP.

  Compare and Craft are labelled links on it.
- **State you can see on the tree:**
  - a gold ring is known, with its tier in dots;
  - a lit gold ring is ready to learn;
  - grey with a lock comes later.

  A skill's kind is a small mark in the corner. Every skill not yet
  known shows its cost, and so does Mastery.
- **The purse explains itself:** points "to learn skills, 1 per level";
  essence "to raise a tier, earned with XP", with a bar to the next tier.
  The rules paragraph is one line with a How it works link, and each
  branch's description sits under its name.
- **Spells** are compact rows, known first, then the ones still to find
  and where their spellbooks are sold.
- A companion's screen is their points and their class's list, each skill
  learned right there.
- The screen's 1,400-line file is split into six under
  `lib/screens/skills/`. What each skill shows (status, cost, lock
  reason, tier and its price) now comes from a view model with its own
  unit tests.

## [1.178.0+208] (main)

### Added
- **A world clock.** The days pass as the party goes (two watches for a
  walk or an expedition, a whole day at sea) through dawn, daytime, dusk
  and night; the top bar shows the day and a sun or moon for the watch,
  and a rest now runs to the next dawn. The town on the cliff darkens at
  dusk and fills with stars at night.
- **A level gained** shows its medal over turning golden rays, the banner
  rising in and the perk choices dealt like a card.
- **A quest settled** is stamped with a wax seal; **every achievement**
  earned (quests, the camp, the town, expeditions) slides down from the top
  in its own toast.
- **A new chapter** opens with its title card across the story.
- **Moments across the game:**
  - the chapter's ash, rain or snow drifts faintly behind the story text;
  - a storm at sea rains and flashes behind its day, and every voyage day
    and expedition event turns over like a card;
  - the screen's edges throb red while the hero's health is low;
  - coins fly from the purse when buying; sparks mark a skill learned;
  - a skill set on a die's face snaps into place;
  - a rest sends a green wave through the screen; a save presses a seal;
  - devoted companions wear a beating heart in the camp's party list;
  - the death screen bleeds in, title then last words;
  - New Game+ starts with a crown of gold sparks;
  - the Shroud drifts behind the main menu;
  - earned badges turn a ring of light in the achievements list.
- All of it rests with reduced motion, and none of it runs on a hidden tab.

## [1.177.0+207] (main)

### Added
- **The Journey map moves.** Ten transitions:
  - a new scene's words come out of the ink, top to bottom, and its ways
    draw out from your mark one after the other, each step popping in at
    the end of its road;
  - a place the map hadn't shown is stamped under your mark, ink
    spreading from it;
  - the picked way flows with ink toward its step, which breathes a ring;
  - walking leaves fading footprints and a puff of dust where it stops;
  - opening the tab from another, the map unrolls on a gold rod;
  - a new chapter burns its map open from your mark, an ember ring at
    the edge;
  - a scene on the road behind opens out of its own mark;
  - a shut way's padlock rattles with a red flash;
  - going into a fight, the map jolts and its edges run red.
- **And ten effects that say what a step holds:** a fight's (or an
  expedition's) heartbeat and embers, a shop's or a quest's glint, a
  rest's fireflies, a roll's glimmer (and a die tumbling beside you on
  the way to it), a voyage's ripples, the main quest's column of gold,
  the Void seeping from an ending, fog drifting over a town's far ways,
  each chapter's weather (ash over the Lower City, Alster and the Spire,
  rain over the Hollow Court and the Hollow Shore, snow in the giants'
  frost), and your mark glowing softly so the eye finds it.
- The effects run only while the Journey tab is on screen, and not at
  all with the phone's reduced-motion setting: the map is then drawn at
  once, as before.

## [1.176.0+206] (main)

### Added
- **The Journey tab has its tour.** The first time you open it, the guide
  dog shows it around in five steps: what the Journey is, the scene you
  are in (fold it, or double-tap to read it full screen), the map (your
  mark, a step for every way on, what each step's colour means, the road
  behind you), picking a step and Go, and the tab bar to switch back to
  the Story. It is in the Tutorials list too, to replay any time.

## [1.175.0+205]

The Journey tab walks, remembers and has hills.

### Added
- **The party walks.** Go, or a second tap on a step, walks the party's
  mark along the road to it. The road fills in behind the party, the other
  ways fade, and the map follows. The step taken ends where the mark
  stood, so the next scene's map takes over without a jump, and only then
  does the choice play out (its roll, fight or detour). With the system's
  "remove animations" setting on, the step is taken at once.
- **The chapter behind the party.** Below the mark, the road runs down
  through every scene of the chapter so far (the latest 40), each with the
  way taken out of it and each new place named where the road reaches it.
  It ends at "Where the chapter began". The map opens on the party with the
  scene just left in view, and scrolls down to the rest. Tapping a scene
  on that road shows it again, with the way taken. On a detour, the scene
  it interrupts is the latest on the road.
- **Relief.** Gentle hills under the map: contour lines in the look's own
  colour (a stronger index line every other level), a soft shade on each
  hill's far side, and a small peak mark on the highest. Each chapter has
  its own land, and the land stays put as the party walks, so the hills
  pass under the mark from one scene to the next.
- **Reading full screen.** A double-tap on the scene's text reads it full
  screen, as in the Story tab: larger text, a short scene centred. The map
  button or another double-tap brings the map back. A double-tap on the
  folded scene opens it straight to full screen.

## [1.174.0+204]

A Journey tab: the story and the map in one screen.

### Added
- **Journey tab (play mode, between Story and Character).** The scene the
  story is on reads at the top, the same text as the Story tab with what
  the last fight or roll left behind. Under it is a chart in the world
  map's look (Night, Parchment or Shroud): the party's mark with the place's
  name, the last places passed on the road behind, and every way on from
  the scene as a step ahead. Each step's icon and colour say what it holds:
  road, fight, roll, challenge, shop, work, voyage, rest, expedition, main
  quest or ending. Faint dots above a step show how many ways go on from
  it, and "To …" names the place it leads to when that is somewhere else.
- Tapping a step picks it. The bar under the map shows its full text and
  what it costs or brings (gold, HP, alignment, the roll and its DC, who is
  fought). Go, or a second tap, takes it exactly as the choice under the
  story would: the same checks, fights, detours, effects and pop-ups.
  Shut ways stay on the map, locked, with the reason shown.
- A town's many ways stack in rows. The rows interleave, the roads to the
  far rows fade, and the map scrolls. The scene text folds to two lines to
  give the map more room. A detour shows on the map like any scene, with
  the way it interrupts; an ending sends the player to the Story tab for
  the ending screen and New Game+.

### Changed
- Arrival pop-ups, the "previously" recap and the companions' remarks now
  show over the Journey tab as well as the Story tab.
- At the camp the Journey tab closes along with the Story tab. Leaving the
  camp returns to whichever of the two was open last.

## [1.173.0+203]

Three side-story villages, each found by its own expedition, and the
narrative review applied.

### Added
- **Akagiri, the oni village (chapter 3).** Found halfway up the new
  Exorcists' Road expedition (after Cinder Row), whose boss is the
  Horn-Taker, the Spire's senior exorcist, who proves each exorcism with a
  sawn-off horn. In the village: break an exorcists' salt circle (fight),
  out-drink the brewers (Constitution), hear Tetsu the smith, soak in the
  hot springs, and, once the road is cleared, give the horns back.
- **The Kindly Hill (chapter 4).** The Good Folk's green hill in the grey
  fen, found on the new Changeling Fen expedition (after the Ossuary
  Galleries), whose boss is the Teind-Rider, the Hollow Court inquisitor
  who collects the hill's mortal every seventh year. Drive the Court's
  sextons off the barrows (fight), play the riddle-game (Intelligence; lose
  and it takes a year), sit with Nell, this year's teind, sleep one night
  by the clock, and tell Nell the rider will not come.
- **Highhearth, the giants' village (chapter 5).** The last forty giants,
  who cut the Reliquary's stone and were paid by being written out of
  scripture, found on the new Frost Quarry expedition (after the Dead
  Heart Approach), whose boss is Gorm, a giant the tear's frost has kept
  standing for three winters. Hold the quarry gate (fight), help the
  midwife (Dexterity), hear Hathra on the old contract, sleep by a fire six
  hundred years old, and bring back the names from the tally-stone.
- Each village has its own place on the world map (all three looks), a
  line when enough of it is done, and a payoff at the next chapter's camp.

### Changed
- **Kroll is now Inquisitor Clement**, "the Branded": the order hands out
  its names the way it hands out its mercy. The pier scene names him and
  sets up the Eel's anchor chain the fight ends on; whoever kept Lysa sends
  her up the chain first, and she pulls the narrator over the rail.
- **Story fixes.** The Beggar's keeper, dead since the tavern, no longer
  dies again at the hovel: it is old Hesk, the neighbour. The Shroud is
  called the Shroud; "Void Banner" is only what the Inquisition calls it.
  The Ashen Quarter's scenes no longer send you back to "the archives". The
  High Warden is met before he is fought. The sixth piece is the
  Sovereign's crown, from the tear to the crown ending. "No one's back",
  not "no one back". The camp's first choice waits for the coast to be
  known.
- **Tone.** The narrator is never "a man"; fewer "considerably" and "with
  the particular" in chapters 1–2; a dry line in the late scenes that had
  gone earnest; "the ledger's last page" varied. Renamed foes and places:
  Pit Wretch, Grey Candle, the Unstitched, the Sovereign, the Tide Cellar
  and the Needle House.
- **Payoffs.** The two faces at the Hollow Court's altar are named; each
  ending says what going back costs or keeps; every scene has its place,
  mood and speaker tags.

## [1.172.0+202]

The iPhone app is shared as a file, like the Android one.

### Added
- **Every release has an IPA next to the APK.** After the Android job
  publishes a release (each push to `main`), a macOS job (`ios-release` in
  `build_apk.yml`) builds the iPhone app and adds
  `NarrativeApp-<version>.ipa` to the same release. If the iPhone build
  fails, the Android release stays as it is. The build steps are shared
  with the Build iOS workflow (`.github/actions/build-ios`).
- **Installing on iPhone without a Mac**
  (`docs/INSTALL_IPHONE.md`, linked from the README): the IPA is signed
  with your own free Apple ID when you install it, with Sideloadly (from a
  Windows or Mac computer) or SideStore / AltStore (on the phone). A free
  Apple ID keeps the app working 7 days at a time, and three such apps at
  most.

### Changed
- **"Check for Updates" works on iPhone.** It finds the IPA in the latest
  release (the APK on Android), downloads it and opens it. From there,
  Share opens it in AltStore or SideStore, which install it, or saves it
  to Files. The dialog explains this before the download. On other
  devices, Settings says where new versions are.
- The Build iOS workflow's artifact is now `ios-ipa`, and the file is named
  `NarrativeApp-<version>.ipa`.
- **Build iOS runs only by hand** (Actions, Build iOS, Run workflow). It no
  longer runs on pull requests, so the iPhone build is only checked when
  asked.

## [1.171.0+201]

The app builds for iPhone.

### Added
- **An iOS build in CI** (`.github/workflows/build_ios.yml`). A macOS
  runner builds the app and packages an unsigned IPA
  (`NarrativeApp-<version>-unsigned.ipa`, artifact `ios-unsigned-ipa`). It
  runs on pull requests that touch the iOS project, `pubspec.yaml` or
  `pubspec.lock`, and by hand from the Actions tab (Build iOS, Run
  workflow). It doesn't run on every push because macOS minutes count ten
  times against a private repository's quota. The IPA is unsigned: it
  installs through a tool that signs it with your own Apple ID (Sideloadly,
  AltStore), or it becomes a TestFlight build once an Apple Developer
  account's certificate and profile are added.
- **The iOS project is set up:** a Podfile for iOS 15 (the oldest iOS every
  plugin supports is 13), the Pods settings in the Xcode configurations,
  and the export-compliance answer TestFlight asks for (the app uses only
  standard HTTPS).

### Changed
- **Read-aloud on iPhone plays with the Ring/Silent switch on,** like a
  podcast, and lowers other apps' sound while it speaks. Without this, iOS
  silences an app's speech when the switch is on. ElevenLabs voices
  already played that way.
- **Settings on iPhone doesn't offer "Check for Updates".** That button
  downloads an APK and installs it, which only Android can do. iPhone
  shows where new versions come from instead (TestFlight, or a new build).

## [1.170.0+200]

The companions speak over the screen, in a speech bubble like the guide's
in a tutorial, instead of in the scene's text.

### Changed
- **Remarks show in a speech bubble.** What a companion says about the
  last choice no longer opens the next scene's text. It pops up over the
  scene, once the scene is on screen and any arrival, discovery or
  tutorial pop-up has closed: the tutorial's bubble (name on top, words
  typed out, gold border), its tail pointing at a round badge with the
  speaker's initial at the bottom of the screen. Tap anywhere or "Go on"
  to close it; the first tap shows the words at once. When a second
  companion answers, their badge stands on the other side and the bubble
  counts "1 / 2". Each remark shows once, and read-aloud still reads it
  with the scene.
- **The same bubble everywhere companions talk:** after a check on an
  expedition or at sea (the log keeps the roll), after a drink at the camp
  (after the "warms to you" notice), and after an approval notice or a
  quest turn-in. There, the notice keeps the facts ("Maren approves",
  "Malrik leaves the party") and the bubble has the words, including what
  a companion says when they come to trust you completely, lose patience
  or walk out.
- The guide's tour and the companions share one speech bubble widget.

### Fixed
- A quest turn-in that brought a level waited for its notice to close
  before showing the level-up dialog; the notice's auto-close could
  otherwise pop the dialog instead.

## [1.169.0+199]

The companions' remarks become game data, edited in the Data tab like the
rest of the game.

### Changed
- **Companion Remarks is a table in the Data tab**
  (`assets/gamedata/companion_remarks.json`, 142 records). Each record is
  one companion, a trigger (a kind, cruel or profitable deed they like or
  dislike, a scene's own reaction, a check, a sneak, a drink at the camp,
  or one story choice) and the lines they pick from, in English and
  French. Records can be edited, added and removed; the game reads the
  table, saved edits included, and the Data tab's GitHub push writes it
  back like the other tables. Two records for the same companion and
  trigger add their lines together; a French list left empty falls back to
  the English.
- **Help under the fields** in the record editor, where a label alone
  can't explain a field (used by the new table).

### Fixed
- **Saving a record no longer cuts sentences apart at their commas.** The
  editor took list fields as comma-separated, so saving any enemy (its
  encounter texts) or NPC (their dialogue) split every sentence with a
  comma in it into pieces. List fields are now edited one entry per line.

## [1.168.0+198]

The nine narration proposals from 1.167.

### Added
- **Companions have lines written for the story's heaviest choices**: 23 of
  them, from the Inquisitor on the pier to the tear's price (the wharf, the
  skiff in the storm, the standard, the Court's sleepers, the legate's
  pact, the flagship's sail…). A companion with such a line says it rather
  than a general one.
- **The party answers itself.** When one companion approves and another
  disapproves, the second answers the first: Maren blesses, Malrik bills.
- **A check with no scene of its own is told in a sentence**: searching
  further, scavenging and slipping past on a detour or an expedition, in
  the narrator's voice (every ability, pass and fail, EN and FR).
- **Comments at sea and at camp.** A crew member now and then remarks on
  pushing through a storm, boarding a derelict or outrunning raiders (in
  the ship's log), and a companion thanks you for a shared drink.
- **Dialogue in 13 scenes** that were narration only: Kelda and Sable at
  the market, the harbor master, Tern Row's toll-man and Nadira, Reya at
  the Reckoning Wall, the runner, the Court's deserter, the headman, the
  widow, the road-keeper, the helmsman, Greyhithe's eldest and the legate.

### Changed
- **Companions take turns in the scene asides.** The line went to the
  first companion in the party every time; it now turns with the scene.
- **Shorter sentences.** 86 of the longest (over 50 words in English, 55 in
  French) are split, in both languages.
- **Read aloud, a scene opens as it does on screen**: the fight's
  aftermath, a check's outcome and the party's remarks come first.
- **French speaks to the player as « vous » everywhere**: companions' fight
  and chest lines, their words in the asides, and two settings texts.
  Lines said to an enemy keep « tu ».

### Fixed
- **The story no longer makes the narrator male** in four more places: the
  swim under the wharf ("a grown man's shoulders", « plus ou moins
  intact »), the Rat's origin (« m'ait surpris ») and Tern Row (« je fus
  ravi »).

## [1.167.0+197]

The party speaks up about what the player does.

### Added
- **Companions remark on your choices.** When a choice moves the party (a
  kind or cruel deed, one that fills the purse, a scene's own reaction),
  the companion who took it hardest says so in their own voice, and the
  next scene opens with their words under their name. A check passed or
  failed, or a fight slipped past, gets a remark too, at most once every
  three choices. Companions take turns and use all their lines before one
  repeats. The eight companions have about twenty lines each, in English
  and French.
- Quest turn-ins and expeditions quote the remark in the approval notice.

### Changed
- A companion whose opinion crosses into "friendly" can still remark; only
  the three changes with words of their own (trusting the player
  completely, losing patience, walking out) take the remark's place.
- "Work on offer" is for side jobs: a choice that leads to the main quest
  is no longer tagged (both ways over the river were).

### Fixed
- **The story no longer calls the character a man.** After the rooftop
  ledger, "what kind of man kept that ledger" (EN and FR) and "un homme
  qui vient de choisir la clémence" (FR) now say "person" and
  « quiconque ».
- **French speaks to the player as « vous » from the first screen**: the
  opening question, "Choose who you are" and "Keep what's left of
  yourself" were in « tu ».

## [1.166.0+196]

A review of the whole PR: fifteen bugs fixed and four balance changes.

### Fixed
- **Defending no longer draws a whole pack onto one party member.** Taunt
  sent every enemy's blow to whoever kept the biggest Defend face, but
  their block only soaked the first; the rest landed in full (three blows
  of 15 against Defend 8 took 37). Now the defender steps in only while
  their guard holds, and later blows go where they were aimed.
- **"Give it one of the crew" takes the companion in the scene.** Who the
  story takes is settled before the party reacts, and they don't react
  themselves; before, a companion walking out over that choice left the
  story to take whoever had just stepped into their seat.
- **A companion the story takes leaves their seat to the bench too**, like
  one who walks out (the finale's "one of the crew", a companion turned).
  Nobody is seated whose house gate can't be read.
- **The bounty board keeps contracts already met.** A new chapter used to
  replace the board, losing earned but unclaimed rewards.
- **A level-up perk can always be chosen.** The picker on the Character
  tab drew its offer only once; a level-up with no level-up window (a ship
  battle's) left a pick with nothing to choose from.
- **Saving a node in Edit Mode keeps every choice field.** Ten had no
  control in the editor and were dropped: showIfFlags, main-quest and
  travel markers, hunts, the sneak round a fight, approval reactions.
- **No hunt trail after a fight the party slipped past.**
- **Loot on the road isn't greed.** A detour's cache or an expedition's
  find no longer costs the approval of companions who dislike profit.
- **A failed run from raiders keeps its roll and its toll on the log.**
- **The day added by sheltering follows the voyage's rules**: one raider
  a crossing on known waters, none past a flight sail.
- An enemy skill set to "attack" in the data editor attacks, even one
  that only heals.
- Edit Mode's "play to" fights play the enemy's wind-ups, guards, rallies
  and heals as the fight screen does.
- The same seed builds the same detour, whatever detours came before.
- Save files keep a bounty's kill counts only for the foes it counts, and
  drop them when it's done.

### Changed
- **Work on offer.** A story choice that leads to a side job not yet
  taken on shows it (the market's informant, Tern Row, Liora's watch).
- **Boarding a derelict** rolls against the sea DC + 3.
- **Maren** no longer minds profit; she still minds cruelty.
- **"Copy the list"** at the Reckoning Wall pays 80 gold (was 50) and the
  party approves.

## [1.165.0+195]

Two fixes from a 50-playthrough simulation of 1.164.

### Fixed
- **A companion who walks out no longer leaves an empty seat.** The
  benched companion who thinks best of the player steps in (the earlier
  recruit on a tie, and only once their house is built), and the notice
  says who took the place. In the simulation, players who never refilled
  the seat by hand fought the finale a companion short: 2 to 5 runs in 50
  got stuck on the Void Sovereign (up to 250 losses, one run never
  finished). With the seat filled, 0.2 losses per run and no stuck runs.

### Changed
- **Boarding a derelict is a gamble again.** A passed Perception check
  now pays twice the salvage (was 2.5 times), and a failed one costs the
  Rusty Eel 12 hull as the hulk rolls against her (was a wound that healed
  before it mattered). Wrecks now bring in about 18% less gold per run in
  the simulation; a character without sharp eyes salvages more often.

## [1.164.0+194]

### Fixed
- **The voyage tour plays by itself.** Its trigger only wrapped the
  loading spinner, so the tour was cancelled the moment the crossing
  loaded and never started on its own. It now waits for the first day at
  sea and lights the hull and the day's choices.
- The voyage tour is rewritten for the sea choices (paying off or
  outrunning raiders, pushing through storms, boarding wrecks, the stat
  each check rolls), in English and French.

### Added
- **Ship battles in the Tutorials list.** The battle still teaches itself
  with one-time tips as each rule comes up; the new entry sums the rules
  up (rooms, crew posts, firing and aiming, range, shot and orders,
  boarding, winning and losing) and brings those tips back for the next
  battle.

## [1.163.0+193]

Companions with opinions, quests that ask how they end, decisions at sea,
and a perk to choose as the character grows.

### Added
- **Companion approval.** Each companion cares about kindness, cruelty
  and profit in their own way (Maren and Tobin about mercy, Malrik,
  Sable and Grosh about the purse, and so on). Every choice made in
  front of them moves their approval, and they say so ("Maren
  approves."). A few finale choices have their own reactions: giving the
  Sovereign one of the crew costs everyone's trust. Benched companions
  don't see what they weren't there for.
  - **Friendly** companions deal +5% damage; **devoted** ones +10% damage
    and health.
  - **Wary** companions deal −10% damage and warn the player. Pushed
    further, a companion leaves the party for good, in their own words.
  - At the camp, each companion's card shows the meter, what they like
    and dislike, and a **drink to share** once a chapter (gold for a
    little approval).
- **Quest turn-in choices.** Six quests ask how they're settled, each way
  with its own gold, alignment and companion reactions:
  - take the informant's cut or give the goods back;
  - keep the smuggler's purse or refund the refugees (Liora watches);
  - pocket Tern Row's toll or return it;
  - guard the Reckoning Wall, copy its list, or sell it to the
    Inquisition;
  - take the sapper's three coins or leave them;
  - absolve the penitent, carry out the sentence, or rob him.
- **Choices at sea.** Every day of a voyage asks what the crew does:
  - raiders: fight, pay them off (twice their bounty), or try to outrun
    them (Dexterity; failing costs hull, then it's a fight);
  - storms: ride them out, push through under full sail (Strength:
    nothing lost, or double the damage), or shelter in a cove at the
    cost of one more day at sea;
  - derelicts: salvage, board her (Perception: 2.5 times the gold, or a
    wound), or leave her;
  - calm days: repairs or rest (a quarter of the health back).
- **Level-up perks.** Every second level offers three perks to choose
  one from (the level-up window and the character sheet both have the
  choice): Steady Hands (a roll more each round), Apothecary, Keen Eye,
  Light Feet, Heavy Hand, Iron Hide, Vigor, Battle Rhythm (momentum
  after 2 hits), Plunderer, Quick Study, Leader (companions +5% damage),
  Deep Well and Last Stand (one killing blow a fight leaves 1 health).
  Most can be taken up to three times. Perks stay through permadeath
  like levels do.

### Balance
- The playthrough simulator now plays the v1.162 rules (enemy intents,
  weaknesses, the momentum drain, the enemy heals) and v1.163's perks.
  It ran 40 playthroughs per variant on two seed sets:
  - **old rules:** 0.3 and 1.1 losses per run, with stuck runs (26
    losses to the White Admiral in one);
  - **new rules, a perk every level:** 0.1 and 0.2 losses per run;
  - **new rules, a perk every other level (shipped):** 0.3 and 0.2
    losses per run, worst run 3, first-attempt wins 98–100% in every
    chapter.

  A perk every level made fights noticeably easier; one every other level
  keeps them where they were. Per run, enemies wind up about 10 times (a
  quarter of them broken by the party), guard 13 times and rally 10
  times; the party lands about 26 hits on a weakness.

## [1.163.0+193] (main, #109: towns read once)

### Changed
- **A town's story is read once.** Arriving in a town or at the camp, its
  scene fills the screen with a single Enter under it; the town's lists
  wait until you go in. Once read, the place opens straight onto its
  lists, then and on every later visit, even after closing the app (the
  scenes read are kept in the save). Reread on the place's card opens the
  scene again, and a scene that changed (a new line for something you
  did) shows in full once more.
- **The town screen is tidier.** The place's name, how much of it is done,
  Rest and Reread share one card; its shops, expeditions, people and
  challenges are tabs (with All to see everything), each tab counting
  what is left to do; the walking companion steps aside while the town
  is open; and "Move on" is one line at the bottom that only takes the
  room it needs.

## [1.162.0+192]

Fights that change shape from turn to turn, detours with a choice in them,
and something to aim the next fight at.

### Added
- **Enemy intents.** An enemy's turn is no longer always a hit:
  - **Guard** (Brace): it raises a guard worth its own damage that soaks
    the party's next hits.
  - **Wind-up** (Heavy Wind-up, Void Gathering): it gathers itself, and
    next turn the blow lands at double weight (×1.8 for the Void). The
    party breaks it by dealing a quarter of its health in one round, by
    stunning it, or by hitting a weakness. A broken wind-up leaves it
    **staggered**: it loses its next turn.
  - **Rally** (Rallying Cry, Pack Howl): it and every living packmate hit
    20–25% harder. An enemy can be rallied at most twice a fight.
  - **Mend** (Bind Wounds): it heals instead of hitting.
  A wound-up enemy is marked at every Perception tier, and the telegraph
  names a coming guard, wind-up or rally from the category tier up. Slum thugs,
  bandits, ghouls, bone wardens, Inquisition soldiers, void hounds and
  the Strand Colossus, among others, use them.
- **Weaknesses and resistances.** 44 of 47 enemies are weak to an element
  (×1.5 damage) and 41 resist one (×½): ghouls fear Light and Fire and
  shrug off Ice, the Inquisition burns poorly but conducts lightning. A
  weakness shows on the enemy once it has been hit with it, and all of
  them show from the category telegraph tier or for a kind already
  beaten.
- **Taunt.** In a party fight, whoever keeps the biggest Defend face
  draws the enemies' attacks that round.
- **Detours with a choice** (expeditions and excursions):
  - A fight can be **slipped past** with a Dexterity check (DC 9 +
    chapter, +2 for a pack). A failed sneak starts the fight as an
    ambush.
  - A cache can be **dug deeper** with a Perception check: 2.5 times the
    gold, or nothing.
  - A rest spot can be **scavenged** with a Luck check instead of healing.
  - Treasure gold and rest healing grow with the chapter.
- **The bounty board at the camp.** Three contracts at a time: hunt so
  many of one foe, win against packs, win without anyone falling or
  drinking a potion, break wind-ups, hit weaknesses, beat marked foes.
  Each pays gold and skill essence at the board (more in later
  chapters). A fresh board goes up once all three are claimed or the
  chapter turns.
- **Charisma haggles.** Each point takes 2% off shop prices, up to 20%.
- **Shops restock** potions and scrolls every chapter. Gear stays one of
  a kind.

### Changed
- **Momentum** drops by one when the party takes a hit, instead of
  falling to nothing.
- **The road keeps its dangers.** Random encounters draw every enemy the
  chapter allows, not only the ones never met; unmet ones come three
  times as often. Late detours used to run dry into treasure.
- Detour descriptions don't repeat within five detours.
- Player skills that enemies use are described as the enemy's move ("A
  ragged breath, and the enemy steadies."), not as "You …", in both
  languages.

### Fixed
- **Enemy heals.** Second Wind, Stoneskin and the other heal-only skills
  enemies use hit the party for the enemy's full damage and healed
  nothing. They now heal, scaled with the enemy's health, and don't hit.
  Shadow Step's self-heal now applies too.
- **Bounty quests** (the Ossuary bounty, Faces of the Fallen) count only
  the kills made after the quest is taken. Kills from earlier in the run
  used to complete them on the spot.

## [1.162.0+192] (main, #108: ship cutaways)

### Changed
- **Ship battles show the ships in pixel art, cut open.** The drawn hull
  outline is gone: each ship is a pixel-art cutaway with its near side
  open, and the four rooms are inside it, the helm aft, the guns
  amidships, the bulwark forward and the hold below. The rooms are what
  you tap, as before, with their names and pips on small labels.
- Every ship has its own look: the Rusty Eel (patched sail, rusted bands,
  an eel at the prow), the Raider Skiff, the Corsair Brig, the
  Inquisition Cutter and the Void Barge. The enemy faces the Eel, so its
  helm is on the right.
- What happens in a room is drawn in it: the hands stationed there stand
  in it, a fire burns on its floor, a knocked-out room goes dark and is
  crossed out, and the hold fills with water, two rows a leak.
- A ship below half its hull is drawn battered, holed and with torn
  sails, and the Eel shows her refits: a crow's nest once her rooms reach
  level 2, iron plates on the bulwark at level 3.

## [1.161.0+191]

### Added
- **Ship battles come alive.** Every shot now flies: a muzzle flash and
  smoke at the gun, the ball arcing across the sea, then what it did on
  arrival: splinters on a hit, a gold ward on a blocked one, a splash
  beside a ship that slipped it, a flash on a critical, fibres from torn
  rigging, a flare where a fire catches and bubbles where a leak opens.
  Chain, grape and heated shot each look their own. It works both ways:
  the enemy's volleys land on the Rusty Eel with the same effects.
- Burning rooms smoke and throw embers and leaking holds drip, on either
  ship, for as long as they last. Fog drifts, squalls bring rain and
  lightning, and a tailwind streaks across the battle.
- Sea events show: a rogue wave rolls across the sea, a creature
  bubbles up under its ship, a wreck scatters debris. A ram splinters
  both bulwarks, and boarding lines fly from whichever ship throws them.
- Crew orders answer too: All hands sparkles on the rooms being fixed, a
  blessing glows over the Eel, Brace and the void ward ring the hull, and
  marking the helm or cutting rigging flashes on the enemy.
- The loser goes down: the beaten ship tilts and sinks in bubbles before
  the battle ends.
- With reduced motion turned on in the phone's settings, none of this is
  drawn and nothing waits for it.

### Fixed
- A ship with two or more leaks no longer breaks the battle screen.

## [1.160.0+190]

### Fixed
- **The tutorial lights up the right thing.** The app sits inside the
  phone's safe area, but the guide measured the screen from its very top,
  so the gold frame and the dimmed cut-out landed a status bar's height
  below what the dog was talking about, and the speech bubble's tail
  missed the dog. The guide now measures from its own corner.
- The bubble's tail now meets the sitting dog's head, and the dog sits
  right under a lit part instead of a gap away.
- A part filling most of the screen (a whole list) is no longer framed:
  the guide just talks about it.
- Skip moves to the left when the lit button is in the top-right corner
  (Compare in the inventory), instead of covering it.
- A step about something not on screen yet (the harbour before it is
  built, Compare in the skill tree, a die's skills when there are none)
  is left out rather than described over nothing.

## [1.159.0+189]

The release that brings every open branch together: the ElevenLabs voice
(1.156.0, already released) and the unreleased work below it, 1.155.1 to
1.158.0, built beside it (that line had its own 1.156.0, the Data tab
downloads). Nothing in the game changes in this entry itself.

### Changed
- **Riverpod 3** (from 2.6): the app's state library. The on/off settings,
  the game session and the other stores keep the same API through
  Riverpod's `legacy` import. One behaviour differs: a screen hidden under
  another one (the story under a fight, say) hears about changes when it
  is shown again, with the latest change only. The quest-ready notice, the
  camp arrival and the tab switches only need the latest change, so they
  behave as before.
- **flutter_lints 6** (from 3). No new findings.
- **CI actions**: checkout v7, cache v6, upload-artifact v7, gitleaks v3,
  action-gh-release v3.

## [1.158.0+188]

### Fixed
- **Ship battles** (the review of v1.153):
  - The **Timed ship battles** setting is waited for before a battle
    starts. A player who turned the clock off and restarted the game
    could get a timed battle anyway, from voyages and the fight lab.
  - A ship whose **helm is knocked out slips nothing**, however far off
    and whatever the wind. Range and weather used to add evasion even
    then.
  - A **weapon that goes out of range is put down** for one that still
    reaches (or none), after the Eel closes in, pulls away or is hauled
    alongside. The enemy's rooms light up only for a shot that can be
    fired.
  - **Liora's Eagle eye and Malrik's Mark their helmsman** wait for a turn
    a weapon can fire, instead of being spent on nothing.
  - **Chain shot on the helm** is logged and previewed in full: both pips
    it tears off, and "helm knocked out" whether it was aimed at the helm
    or tore it down from another room.
  - The **Void Barge boards every third round spent alongside**, counted
    only while the ships lie side by side. It used to board on the
    battle's third, sixth and ninth rounds, even on the round it arrived.
  - **Fight lab:** an enemy that gets away reads "The enemy got away", no
    longer "lost", and the boat's sail plays its power (Wind-Knot,
    Kraken's Eye) as on a voyage.
  - The Harbour reads a weapon's reach with the battle's own rules.
  - The battle log's French tidying builds its patterns once, not on every
    refresh of the clock.
- The on/off settings (tremble, combat effects, chest auto-open,
  alignment hunters, companion targeting, the ship clock) share one
  implementation; a choice made before the saved one loads now wins.

### Added
- **Ship battle tips.** The first time each rule comes up, a one-line tip
  explains it: the range and the enemy's habit at the start, the weather
  when it turns, aimed shots with the first ready gun, shot from the
  second turn, orders, fire, a leak, an open rail, the sea's surprises.
  One at a time, each once. They follow the tutorials setting, and
  "Replay tutorials" shows them again.
- **Aimed shots setting** (Settings): Normal, Slow (the marker takes
  1.6 s instead of 0.9 s) or Off (a long press does nothing; every shot
  is a plain one).
- **Skill effects:**
  - Damage and healing numbers are sized by the effect's tier: small for
    a light touch, big for a mighty blow, which lands big and settles.
  - The card a strong or mighty effect lands on reacts: a blow shoves it
    aside and flashes it in the effect's color, a mighty one harder; a
    strong heal or shield lifts it.
  - A mighty blow freezes every effect for a split second as it lands
    (hit-stop), shakes the screen and gives a heavy vibration, all under
    the tremble setting. Blows landing together share one pause.
  - With more than four effects in flight at once (a pack fight's dice
    and a spell), the extra details are thinned and the screen flashes
    once, so the frame holds.
  - The effects gallery previews a real skill at the power a fight would
    give it: its rarity, its upgrades, the share of the foe's health it
    takes, a critical. The stand-ins recoil too.

### Changed
- **Ship battles on a phone:** the empty log is a thin strip until it
  has lines, the tips fit on one row, and on a narrow phone the four
  shots fit without the "Shot:" label. At 412 px wide the Eel's rooms
  are now on screen when a battle opens.
- The Void Barge's and the evasion's hints say the fixed rules.

## [1.157.0+187]

### Changed
- **Skill effects play at the skill's power.** Every effect in a fight
  now has a power, and a stronger skill looks stronger:
  - **What the skill is**: its rarity (a common skill plays smaller than
    an epic or legendary one), how far it is upgraded, and for a spell
    its mana cost.
  - **How hard it lands**: the share of the target's health it takes
    (a blow that takes a third of it plays much bigger than a scratch),
    a critical hit, and a boss's blows.
  - **Four tiers**: light, normal, strong, mighty. A light effect is
    smaller, shorter and throws fewer particles; a strong one adds a
    second shockwave and lingering embers; a mighty one adds a flash of
    the screen, a ring along the ground, light rays, and shakes the
    screen as the blow lands (when screen tremble is on). A strong or
    mighty heal or shield gets rising motes and a pillar of light
    instead.
  - Size grows up to a cap, so a mighty blow gets its extra details
    without swallowing the screen.
- **More detail in each style:**
  - A slash leaves an afterimage, and a strong one crosses back.
  - A heavy slash and an impact crack the ground.
  - A pierce draws speed lines.
  - Flame shimmers with heat and leaves embers.
  - A fireball leaves smoke and embers.
  - Frost brings a cold mist and falling snowflakes.
  - A quake splits the ground.
  - Lightning forks, and a mighty strike brings down a second bolt.
  - Some styles grow in count with the tier: a volley fires 3 to 9
    arrows, a claw rakes 3 to 5 marks, a shout sends 2 to 5 rings.

### Added
- **Effects gallery (Edit Mode, from the fight lab).** Plays any style,
  in any element, at any of the four tiers (or all four in turn), to
  see how an effect looks from a light touch to a mighty blow.

## [1.156.0+186]

### Added
- **Download the game data from the Data tab (Edit Mode).** Each
  collection (items, enemies, quests…) has a Download button with three
  choices, each to copy or to save as a file:
  - **Records (JSON)**: every record with every field, as the game
    stores it (`items.json`).
  - **Records (CSV)**: one row per record, an `id` column and one column
    per field; lists and nested values go in their cell as JSON
    (`items.csv`).
  - **Texts (CSV)**: every text of the collection, one row each, with
    the English and the French side by side (`items_texts.csv`). Nested
    texts are included (a ship's weapon names, an enemy's encounter
    lines one by one); ids, flags and numbers are left out.
- **Download all data**, at the top of the Data tab: the same three,
  for all 24 collections in one file (`game_data.json`,
  `game_data.csv` with one row per field, and `game_texts.csv` with the
  game's 1,334 texts).
- The CSV files are UTF-8 with a byte order mark, so spreadsheets show
  the French accents.

### Fixed
- The Enemy Ships list no longer overflows on a phone: its filter took
  the new Battle Habit field's long label. The label is short now, and
  a filter never pushes the search box off the row whatever its label.

## [1.156.0+185]

### Changed
- **The story is read in a recorded ElevenLabs voice**, replacing the
  Gemini voice. In Settings → Read-Aloud Voice, turn it on and enter your
  ElevenLabs API key. The key is kept on this device only. The narrator
  voice is `8TMmdpPgqHKvDOGYP2lN` by default, and you can enter another
  voice ID.
- Each paragraph is recorded once, saved on the device as an MP3 (with its
  words in a `.txt` beside it), and played offline after that. A scene not
  recorded yet is recorded the first time it is read. The next paragraph
  records while the current one plays.
- **Record the whole story** records every scene, companion aside,
  callback, race and profession line and hub line in the current language
  in one go. Before it starts, it shows how many ElevenLabs characters it
  will use (about 146,000 in English and 163,000 in French). It can be
  stopped at any point, and what was recorded is kept. **Delete
  recordings** clears a voice.
- A companion's aside is its own clip, so each scene is recorded once
  whoever walks with you.
- Auto-read uses the ElevenLabs voice when it is on, and the device voice
  otherwise. Without a key, only scenes already recorded use the ElevenLabs
  voice. The web version keeps the device voice.

## [1.155.1+185]

### Fixed
- **The guide's Next button no longer goes off the screen.** On a phone
  with large text, a long line (the Story tour's "The story itself…"
  for one) made the speech bubble taller than the room kept for it, and
  its bottom, Next included, ended up under the navigation bar. The
  guide now measures the bubble at the player's text size before it
  sits down, and keeps the bubble between Skip and the bottom of the
  screen; if the words still don't fit, they scroll inside the bubble
  and Next stays in place.

## [1.155.0+184]

### Changed
- **Ship battles, redrawn.** Each ship is now drawn side on: a hull with
  a mast and its flag, the helm, guns and bulwark on deck and the hold
  below, each room with its pips, its crew and what is wrong with it
  (fire, a leak, knocked out). Hulls are bars of planks, red for the
  enemy and gold for the Eel. Every gun carries its charge as a ring,
  and the enemy's show the room of the Eel they mean to hit.
- The sea between the ships shows the weather and a range ruler with
  the ships' distance marked. The log keeps a fixed size (the whole
  battle opens from it), so the Eel never moves down the screen.
- The player's turn sits in a panel at the bottom that is always in
  reach: the clock along its top edge, the hint, the guns as cards, the
  shot, the crew, and End turn. Both ships fit a phone's screen above it.
- The crew and their orders open in one sheet: each hand's health, a
  station to tap, and their order with what it does.
- A shot's result rises off the room it hit: the damage, Slipped or
  Blocked.
- Stitched Ink colours throughout, in dark and light.

## [1.154.0+183]

### Added
- **The companion dog is now your guide.** The first time you reach a
  feature, the dog walks onto the screen by itself (no dark card behind
  it) and talks you through it in a speech bubble. The part it describes
  is lit up and the rest of the screen dims. Tap anywhere or Next to go
  on; Skip ends the tour at any time. A speaker button in the bubble reads
  the lines aloud.
- Tours for the Story, Character, Camp and Other tabs, the world map,
  the skill tree, dice, inventory, level up, dice combat, skill
  challenges, the harbour, voyages, expeditions, towns, shops, the
  journal and achievements, in English and French.
- **Tutorials** in the Other tab lists every tour, marks the ones not seen
  yet as New, and plays any of them again: on its own tab or page when it
  has one, so the dog points at the real thing.

### Changed
- The walking companion is on by default. On a short screen it is drawn
  smaller, and the choices leave room for it and for the story.
- Settings' tutorial switch now covers every tour, and "Show all
  tutorials again" plays each one again the next time you reach it.

## [1.153.0+182]

Ship battles become more than trading shots: ten new rules, each one a
decision to make under the clock.

### Added
- **Speed pays.** In a timed battle, ending the turn with half the clock
  left gives quick orders: +10% evasion against the volley that follows.
  A bolt next to the clock lights while it is on offer.
- **Crew orders, once a battle each.** Every crew member can give one:
  All hands! (you: every damaged room mends a pip), Brace! (Kelda: half
  the hull this round), Grapple! (Grosh: hauled side by side and
  boarded, shields or not), Bless the deck (Maren: fires out, crew
  healed), Shore up (Tobin: bulwark mended, a layer raised), Mark their
  helmsman (Malrik: the enemy slips nothing this turn), Cut their
  rigging (Sable: every enemy weapon loses a step of charge), Eagle eye
  (Liora: the next shot is a critical), Void ward (Vess: the first enemy
  shot is turned aside).
- **Range.** The ships lie close, at medium range or far apart. Far off,
  both are 10% harder to hit; side by side, 10% easier. The helm can
  close in or pull away once a turn; the helm hand spends the turn on
  it. Harpoons reach no farther than medium range and fire pots need
  the ships close. Boarding, by either side, needs them side by side.
  Enemy helms steer for the range they like (30% a working helm pip).
- **Weather**, rolled each round, with the next round's shown:
  calm, a tailwind for the Eel (+10% evasion, her helm turns without a
  hand), a crosswind (+10% evasion for both; the Wind-Knot sail makes it
  a tailwind), a squall (no fire starts, every fire goes out) and fog
  (the enemy's aim hidden even from the Kraken's Eye, +5% evasion).
- **Shot.** Round, chain (half the hull, tears a pip off their helm),
  grape (half the hull, their crew repairs one less for two rounds) or
  heated (three quarters of the hull, sets the room burning).
- **Aimed shots.** Hold an enemy room instead of tapping it: a marker
  sweeps the aim bar. Stop it in the green for a critical (cannot be
  slipped, half again the hull, an extra pip); amber is a plain shot;
  the red edges go wide.
- **Enemy habits.** The Raider Skiff runs for open water when hurt and
  escapes from long range (no prize, no loss). The Corsair Brig keeps
  its distance and shoots the crew where they stand (half again the
  hurt). The Inquisition Cutter rams once alongside: 12 hull through any
  shield, and a leak. The Void Barge comes alongside to board every third
  round, shields or not, twice at most. Shown under the enemy's name.
- **Leaks.** A hit of 8 or more on the hold opens a leak (three at most),
  2 hull each every round. A hand in the hold bails one a turn after
  any fire; the enemy's crew plugs theirs.
- **The sea itself.** From the second round, one round in ten: a rogue
  wave takes a shield layer off both ships, a sea creature goes for the
  ship lower in the water (10 hull and the hold), or a drifting wreck
  takes the next enemy shot.
- **Focused fire.** A room already hit this turn loses an extra pip per
  hit; a crosshair marks it and the shot preview counts it.
- `habit` on enemy ships and `ranges` on weapons in the data and in the
  editor; the Harbor shows a weapon's reach.

### Changed
- The battle's rules moved out of the panel into a tested engine
  (`ship_battle.dart`). A Monte Carlo of 14,400 battles on the real data
  compares the new battle with the old one, Eel fitted early, mid and
  late against every ship. Win rates stay within 14 points of the old
  battle for every pairing: a player who uses the new tools lands
  between 11 points below and 13 above, one who ignores them between
  14 below and 11 above. Fights last about as long.

### Fixed
- Battle log lines no longer read "the The Rusty Eel's hold" or "de Le
  Rusty Eel" (now "du Rusty Eel"); a crew member's hurt reads the same
  for everyone in French.

## [1.152.0+181]

Ship battles run against the clock.

### Added
- **A clock on every ship-battle turn.** The Rusty Eel has 20 seconds a
  turn to fire and move her crew. A bar and the seconds left show above
  End turn, red for the last five. The clock stands still while the
  enemy fires and while a deck is fought over.
- **When time runs out, the turn ends as it stands.** A ready weapon not
  fired keeps its charge ("holds her fire"), and the enemy fires back as
  usual.
- **The Speaking Tube**, a new Utility part at the Harbor (140 gold):
  orders reach every station faster, and a turn lasts 8 seconds longer.
  It shares the Utility slot with the Tar-Sealed Hull and the Spare
  Canvas. Ships and parts carry the figures (`turnSeconds`,
  `turnSecondsBonus`), so later refits can add more time (60 s at most).
- **A setting to turn the clock off** (Settings, Combat: "Timed ship
  battles"). Off, a turn waits for End turn as before.

## [1.151.0+180]

Everything in one place: the design branch's last three updates (the
chart map, colour fixes, review fixes) join the open chapters and the
skill tree.

### Fixed
- **No pop-up when a stat point is spent.** Level Up no longer shows
  "Base Armor increased!" after each +1 Point; the row's value goes up.
- **The points on the character sheet say which kind they are.** Stat
  points open Level Up and skill points open the skill tree ("2 Skill
  Points"), instead of one sum that led to Level Up showing 0.

### Changed
- **The pixel map is gone for good**; the world map is the chart. The
  open chapters' places (Emberwick, Wrack's End, Rimewell, the White
  Anchorage, Greyhithe, the White Fleet's grave) have a spot on each of
  the chart's three geographies; the White Fleet's grave lies at sea.
- Die faces and skills keep their colour per effect; the skills list's
  cards take the design's square corners.

### From the design branch 1.142.0+171: review fixes

**Fixed**
- **Full review pass on the Stitched Ink branch.** The traveller on the
  chart no longer has a place name drawn over it. Houses are drawn only
  for places already reached, and switching the map's geography mid-walk
  stops the walk instead of letting it jump. The chapter title in the
  Story header shrinks to fit at large text sizes. A locked choice's
  cost tags fade along with the card. The map's style and geography
  toggles are announced by name to screen readers. Stale "pixel map"
  wording is gone from the map's description and comments.

### From the design branch 1.141.0+170: colours, and no more pixel map

**Fixed**
- **Buttons look like buttons again.** Every raised button (Unlock on
  the Skills screen, Roll Dice in a fight, +1 Point on Level Up, and the
  rest) had taken the story choices' card look; only story choices keep
  it now. Buttons are back to their standard sizes.
- **Skills list.** An unlocked skill's tier and Upgrade button fit their
  row again instead of overflowing it.
- **Skills on the dice.** On the Dice Loadout screen a face set to a skill
  is marked in the techniques' violet again instead of gold, and each
  skill's element icon (fire, wind, water, void...) takes its element's
  own colour.

**Removed**
- **The pixel map.** Its generated terrain, fog, sprites and ground looks
  are gone; the chart draws the map. Places keep their story data only;
  where they sit is each geography's.

### From the design branch 1.140.0+169: the chart map

The world map is redrawn as a chart in the Stitched Ink design, on the
geography of your choice.

**Added**
- **Three geographies.** Under the map: *Continent* (one land round an
  inland sea, Alster on its west arm, the Ashen Coast on the east, the
  Hollow Cape to the north), *Archipelago* (Alster an island, the later
  chapters on isles across open water) and *Delta* (Alster upstream on a
  great river whose mouths fan into the Grey Bay, the later chapters on
  the far bank). Chosen under the map and remembered.

**Changed**
- **The map is a chart.** Sea and land with smooth coasts, rivers, small
  roofs about each place, the road walked in moving gold dashes, a dotted
  way on to the next place, the places reached in their chapter's
  colour, the tear's places in violet, and fog over what the story has
  not reached. Regions are named once reached and marked uncharted
  before.
- **Names find their own place.** Each place's name goes right, left,
  above or below its mark, wherever it stays inside the chart and clear
  of the others; region names only show where they fit.
- The three looks (Night, Parchment, Shroud) colour the chart; the
  traveller and the pin still walk the road.

## [1.150.0+179]

Brings in main's redesign (PR #98, numbered 1.138.0+167 and 1.139.0+168
there): the Stitched Ink look and the camp as a town on the cliff, on
top of this branch's open chapters (1.138 to 1.149 here).

### From main 1.139.0+168: the cliff town

The camp becomes a town on the cliff, and the story, character, skill
challenge and map screens take on the Stitched Ink designs. Fights and
ship battles keep their layout.

**Added**
- **The cliff town.** The Camp tab opens on the town: the harbour and The
  Rusty Eel at the bottom, every house built stacked up between two
  cliffs, in pixel art. Houses take one to three plots across and one or
  two levels up; each new one goes as low and as far right as it fits,
  resting on what is below it, with timber struts under what overhangs.
  The town scrolls, starting at the harbour.
- **Building from the town.** A tray under the town lists the houses;
  tapping one outlines where it will go and scrolls there, Build raises
  it. Locked houses say what they wait on, and ones you cannot afford say
  how much gold is missing. The boat sails from its button in the
  harbour.
- **Town additions.** A second tab sells pieces that only add to the
  town, again and again: a timber room (40 gold), a lantern stair (60),
  a storehouse (90) and a watchtower (120). They give no bonuses.
- **Place and mood on the story page.** The scene's place (the docks, the
  cathedral...) and mood show as tags above the text.
- **The chapter in the header.** In play, the Story tab's header shows
  the chapter's number and name, in the chapter's colour.

**Changed**
- **Character sheet.** It opens on the character's name, race and
  profession, level and experience, health, mana and gold, an alignment
  bar from Evil to Good with the thresholds marked, a button when points
  are waiting, and the eight abilities in a grid.
- **Skill challenge.** A d20 shows each roll as it lands, with the sum
  under it; successes and failures fill square counters; the result is
  stamped at the end.
- **World map.** Its title and place names use the title face; the three
  looks are side by side instead of in a menu; chips have square corners.

**Saves**
- Saves keep the order the town went up in (`townOrder`); older saves
  build their town from their houses in the order they were built.

**Fixed**
- The character sheet's ability boxes use each language's own short
  names (French *Charisme* and *Chance* no longer both read CHA).
- Build in the camp's tray only reports a house or an addition going up
  when it actually did, and a locked house never reads "Requires: null".

### From main 1.138.0+167: Stitched Ink

The whole app takes on the "Stitched Ink" look from the design proposal:
a dark book you read, stitched to a game you play.

**Added**
- **Stitched Ink palette, now the default.** Shroud-dark pages, Bone
  ink, Banner gold for the main action, with a parchment variant in light
  mode. The other palettes stay in Settings.
- **One set of type for the whole app.** Spectral for story and body
  text, Pixelify Sans for numbers, labels, buttons and dice, and IM FELL
  English SC (bundled, SIL OFL) for titles, chapters and places. All
  three fonts are now used across the app, not only on the world map.
- **Costs on choices.** A story choice that changes gold, health or
  alignment shows it underneath as small tags ("+20 gold", "−10 HP",
  "Alignment −1").

**Changed**
- **Shapes.** 4 px corners and 1 px seams instead of rounded, shadowed
  cards, for buttons, cards, dialogs, sheets, chips and the tab bar.
- **The story page.** The prose sits on the bare page beside a dashed
  thread in the colour of where the story is (slums, docks, cathedral…),
  left-aligned at reading size; chapter headings are in the title face.
- **The main menu.** A tattered banner with the Void's sigil over the
  title, on a plain page instead of a gradient.
- **The stats bar.** Each number's icon says what it is: gold for level
  and gold, red for health, mana's colour for mana.
- **Dice and the fight log.** Colours by meaning: ember for attacks,
  steel for guarding, green for healing, purple for techniques.

## [1.149.0+178]

The camp opens once it is set up, every place leads back to it, and the
cathedral waits for the chapter's quests.

### Fixed
- **No camp before it is set up.** On the chapter 3 shore (3001), the
  Camp tab used to offer the way "back" to a camp that did not exist yet.
  It now stays closed until "Take stock of the shore" sets up the camp
  (`camp_founded`). That choice opens the camp screen, from which the
  party travels to the towns, villages and expeditions it knows. The
  "locked" lines say "Opens once the camp is set up in chapter 3".
- **Villages and the Hollow Shore were dead ends.** Emberwick, Wrack's
  End, Rimewell, Greyhithe and the Hollow Shore have too few choices to
  count as hubs, so they had no "Back to the camp" or "Travel on" row.
  Every place of an open chapter now gets that row, like the towns.

### Changed
- **The main quest waits for the chapter's quests.** Besides 8 things
  done and the needed place visited, each chapter now asks for some of
  its own quests to be turned in (`questGoal` in chapters.json): 2 in
  chapter 3, then 1 in chapters 4, 5 and 6. So the Spire's gates stay
  shut until the Ashen Quarter trusts the party. The camp's Chapter card
  shows "Quests completed: N of 2". The chapter 3 hint and the Quarter's
  scene (3005) now say the way in has to be earned.
- **The main quest is shut in the story view too.** A camp scene shown
  as a story page (Edit Mode) greys out the main quest ("Not yet: the
  camp shows what this chapter still asks.") until the camp opens it.

### Added
- **Camp on the editor map.** Camp scenes have their own colour and icon
  in the map legend.

### Balance (Python simulation, 200 runs a style)
- Every run reaches the true ending and meets the quest goals without
  being forced through. At the chapter 3 gate, thorough players and
  rushers have 5.9 and 5.8 of the chapter's quests done (at least 2).
  In chapters 4 to 6 they have 1.5 to 1.9 (at least 1).
- A control run without the quest goal gives the same numbers (1.45
  fights lost a run for thorough players). The goal asks for what
  players already do, and stops only a party that skips every quest.

## [1.148.0+177]

A word at the camp about companions, and a longer look round each chapter.

### Added
- **Companion hint at the camp.** When a place the party knows has
  someone who could still join, the Chapter card says so ("Word at the
  fire: someone in the Ashen Quarter might join you."). The place's card
  is tagged "someone to meet". The hint follows the recruit scenes
  (`placeCompanionLeads`):
  - it leaves out a companion the party's alignment or story rules out
    (Tobin for a party that is not Good, Malrik for one that is not Evil,
    Maren once Lysa is lost);
  - it keeps one who only asks for gold (Grosh);
  - it goes once the companion has joined or their scene is done.

### Changed
- **Each chapter asks for 8 things done** before its main quest (was 6),
  so a party makes about one more trip in each chapter.

### Balance (Python simulation, 200 runs a style)
- **Rushers** (only what the gate asks):
  - Before this change: 4.24 fights lost a run, 3.3 companions, 5 runs
    with no companion.
  - With the goal of 8 alone: 1.69 lost a run, 3.6 companions, 1 run
    with no companion.
  - With the hint as well: 1.10 lost a run, 4.1 companions, none alone.
    Every run finishes.
- **Thorough players:** 1.30 fights lost a run, 4.0 companions. They
  already did more than 8.

### Tests
- `chapter_loop_test`:
  - the goal of 8;
  - companions to meet: a town's leads and a village's none;
  - leads leaving once met or done;
  - alignment and story gates.
- `camp_flow_test` checks the hint and the place tag once the Ashen
  Quarter is found, and opens the main quest at 8 of 8.

## [1.147.0+176]

The camp is the base from chapter 3 on. Each chapter is explored from it,
and its main quest opens once enough of it has been done.

### Added
- **Open chapters** (`assets/gamedata/chapters.json`, `chapter_loop.dart`).
  Chapters 3 to 6 and the Ending each stand at the camp. The camp's
  Chapter card shows how much is explored ("Explored: 4 of 6") and the
  chapter's main quest. The main quest stays shut until six things are
  done and its key place has been visited. A thing done is one of the
  chapter's expeditions cleared, or an activity in one of its places.
- **Places are found by expeditions** (zones.json `discoversPlaceIds`):
  the first at the expedition's midpoint, all of them on clearing it.
  The camp lists the places found, with how far they are and how much of
  each is done.
- **Travel between the camp and the places.** A place on the camp's shore
  is a walk, and the road may hold a detour or a raid. A place with its
  own landing is a voyage there and back. From a place the party can go
  back to the camp or travel on to another place it knows.
- **Four villages**: Emberwick (chapter 3), Wrack's End (4), Rimewell (5)
  and Greyhithe (6), each with five scenes, a fight, a check and a second
  beat.
- **Chapter 6 is a loop on the Hollow Shore.** It adds a town (the White
  Anchorage, with its chandlery), the Glass Strand expedition (the Strand
  Colossus), and the White Fleet's Grave (the White Admiral), where the
  fifth piece lies. The Ending sets out from the camp into the tear.
- **Six banner pieces:** the heirloom, the Warden's standard, the Court's
  twin, the reliquary thread, the White Fleet's sail and the Sovereign's
  mantle. **The epilogue** ends on the night before the invasion: the
  whole Banner turns time back, which is where New Game+ starts.

### Changed
- The camp no longer asks for its shore's expeditions before the story
  moves on. The main quest's gate replaces that rule, and the Leave the
  camp sheet is gone.
- Fights in a place use the place's own chapter, however late the party
  comes back to it. Fights in the camp's towns used chapter 1 before.
- **Known waters:** a crossing to a port the Eel has put in at before, or
  home, has a 15% chance of raiders a day (35% on new waters) and meets
  one raider at most.
- **Boarding crews** fight at most one chapter past the chapter their
  ship first sails in.
- The Court's road (5001, 5002) became the fourth chapter's camp and main
  quest. Saves on those scenes pick up at the camp.
- Edit Mode: Play to Chapter and autoplay clear a chapter's expeditions
  and find its places before taking its main quest. The in-app simulator
  tours each place before the main quest.

### Balance (Python simulation, 200 runs a style)
- **Thorough players** visit every place and go for the companions:
  - 1.25 fights lost a run (1.146: 1.46), median 1.
  - Every run finishes, with 4.0 companions.
  - At first try, the White Admiral is beaten 90.5% of the time, the
    Void Sovereign 94.5% and the Archon 98%.
- **Rushers** do only what the gate asks:
  - 4.24 fights lost a run, median 1.
  - 5 runs out of 200 recruit no companion and account for most of those
    losses.
- About 20 voyages a run (10.8 before), with the same number of raiders
  as before (about 11) thanks to known waters.

### Tests
- `test/chapter_loop_test.dart`: loops, camps, chapters, known places,
  discoveries, activity counts and the main-quest gate.
- `test/camp_flow_test.dart` plays the loop in the app:
  - it finds a place and walks to it;
  - it goes back to the camp;
  - the main quest opens;
  - a later place is reached by voyage.
- Known waters (`sea_events_test`), boarding crews (`ship_combat_test`),
  retired scenes (`story_providers_test`), autoplay exploring a chapter
  (`autoplay_engine_test`), and the story tests for six pieces, chapter 6
  and the epilogue.

## [1.146.0+175]

Skills cost what they are worth, and the fights are tuned to the new economy.

### Changed
- **Skill tiers cost 1,000, 2,000 and 3,000 essence** (they cost 3, 6 and
  9, so essence, which comes in with XP, raised every skill to tier 3 by
  mid-run). A first tier now comes around level 5, a first skill at tier 3
  around level 11, and about three skills reach tier 3 by the end.
- **The deeper a tree skill, the more points it costs:** 1, 1, 2, then 3
  points down a branch (`branchSkillPointCosts`), 7 for a whole branch.
  Mastery stays at 2 points, and the two reputation skills and the
  companions' skills at 1. The points cover about two branches and one
  mastery, where the whole tree was learned by level 15.
- The tree marks a skill that costs more than a point, its sheet's button
  says what it costs ("Learn (3 points)", or "Needs 3 skill points"), and
  the list shows the cost of each skill not yet known.
- **Difficulty retuned for the new economy.** A regular enemy's floor now
  ramps over the first chapters: health ×1.15, ×1.25, then ×1.35 from
  chapter 3; damage ×1.10, ×1.15, then ×1.20. It was ×1.15 and ×1.10
  throughout. The chapter step goes from 0.12 to 0.15 a chapter, and
  bosses get a floor of their own (×1.10 health, ×1.05 damage; they had
  none).
- **The Void Barge's boarders** are a void hound and two void wisps (two
  hounds and a wisp), and board at 25% (30%). Half of the simulated
  parties lost that fight.

### Balance (Python simulation, 200 runs)
- Before the retune, the new economy lost 0.12 fights a run. After it:
  - 1.46 fights lost a run (median 1, 92 of 200 runs without a loss).
  - Every run finishes.
  - Chapter 1 is won 97.9% of the time.
  - The Void Sovereign and the Archon are beaten at the first try by 89.5%
    and 87.5% of the parties.
- The Void Barge boarders are beaten 84% of the time (45%).
- With the costs, a run learns about 11 skills (13) and ends with about 1
  point left (6), 2.8 skills at tier 3 (5.3), and all three camp works
  built in 85% of the runs (24%).

### Tests
- `test/skill_tree_test.dart` covers the depth costs, a skill waiting for
  its points, and a tree that costs more than a run's points.
- `test/difficulty_curve_test.dart` covers the ramped floor and the boss
  floor. The Void Sovereign phase test in `test/sim_combat_test.dart` uses
  a stronger test character (900 health, 100 damage) to reach its first
  phase against the harder curve.
- Tier costs in `combat_engine_test` and `player_session_provider_test`.

## [1.145.0+174]

The camp is reachable from every town, and a skill can't fill a die.

### Added
- **Back to the camp, from any town once the camp stands.** The Ashen
  Quarter, the Drowned Cloister and the Reliquary Quarter each show "Back to
  the camp" with how far it is. The story waits in the town while the party
  is at the camp: its expeditions, its works and Harbor, the voyages out,
  and the companions' gear, skills and dice.
- **Set out for the town again from the camp.** The camp shows where the
  story waits. Its small leave button becomes "Set out for {town}", with a
  last look at who comes along, and the Story tab comes back on the town.
- **The boat between the camp and a town.** The Ashen Quarter is a day's
  walk inland; the Drowned Cloister (the Drowned Stair) and the Reliquary
  Quarter (its river gate) are voyages on the Rusty Eel, sea events and
  raiders included, both ways. New `landingPortId` on a story settlement
  names the port a town's voyage lands at.
- **Skill rarity.** Every skill has a rarity (common, uncommon, rare, epic,
  legendary; new `rarity` field in skills.json, set from each skill's
  strength), and a skill fits on at most 3 faces of a die if common, 2 if
  uncommon or rare, and 1 if epic or legendary. A die's own fixed faces
  count toward it; its open faces left as Heavy Blow don't.
- The dice loadout shows each skill's rarity and how many of its faces it
  already takes; the picker greys out a skill at its limit, and a dragged
  skill won't drop on one face too many. The skill tree's sheet shows the
  rarity too.

### Changed
- Away from the camp, the Camp tab is the way back to it (from a town) and
  the Rusty Eel's state; it is the Ship tab only while the Eel is out on an
  expedition from the camp.
- A voyage back to the camp takes as long as the voyage out to the port it
  leaves (it took the home cove's 2 days from anywhere).
- Fights apply the rarity limits to saved dice: a skill set on more faces
  than it may take keeps its first faces, and the others do their own action
  (shown as "Over its limit" in the loadout).

## [1.144.0+173]

Skills grow on a tree, and the player has to pick a path; companions keep
to their own trade.

### Added
- **A skill tree for each class.** Three branches of four skills, learned
  from the top down, one skill point each: Bulwark, Vanguard and Warlord
  for the Warrior; Evocation, Tempest and Aegis for the Mage; Shadow, Venom
  and Trickster for the Rogue; Judgment, Devotion and Vigil for the Cleric;
  Marksman, Trapper and Wilds for the Ranger. Every class skill sits on its
  class's tree, and a new character's own skills open a branch.
- **A heritage branch for each race**: its three skills, in order.
- **Mastery: the specialisation.** A class branch learned in full can be
  mastered for 2 skill points, and its skills then fight one tier above
  their own (on top of what skill essence has bought). Only one branch is
  ever mastered, so the others stay a side road.
- The Skills screen opens on the tree (tap a skill to see what it does
  and learn it, tap a mastery star to master its branch), with a **List**
  view that filters by what a skill does (attack, healing, mana, status)
  and by known or learnable now. Spells sit under the skills in both.
- Skill trees are game data (`skill_trees.json`), editable in Edit Mode.

### Changed
- **Skill points buy the tree only**: the next skill on a branch, or a
  skill the character's reputation opens (Zealous Conviction, Ruthless
  Edge). Skills already known stay known; a die's own skills still work
  for whoever holds it, and crafted skills still come from recipes.
- **Companions keep it simple**: they learn their own class's skills only,
  in any order, one point each, and their dice take only those skills and
  what their die already carries. A rogue companion learns rogue skills.
- Permadeath resets the mastery with the rest of the skill build.

## [1.143.0+172]

The camp is somewhere the party goes back to, not a tab it carries around.
While the story stands at the camp, the camp takes the Story tab's place;
away from it, that tab is the ship.

### Changed
- **The camp opens only at the camp.** When the story comes back to the
  cove (the founding, the return after the Spire, the stop before the
  Reliquary Quarter), the Story tab closes and the Camp tab opens with the
  scene the story tells there (its first lines, the rest a tap away), the
  followed quest, and the camp itself. Building, choosing who comes along,
  gear, skills and dice of companions, the camp's shops and its shore's
  expeditions are all there, and only there.
- **Leaving the camp** is a small "Leave camp" button at the top of the
  page. It opens a last look at who comes along (companions can be added
  or benched there) and the story's own ways out of the scene; picking one
  closes the camp and brings the Story tab back.
- **The camp keeps the party until its shore is safe**: the expeditions on
  the camp's own shore (Cinder Row, then the Scaffold Yards) must be
  cleared before the story can move on. The camp says so, and "Leave camp"
  lists what is left.
- **Setting sail from the camp**: other ports' expeditions are a voyage
  away. Once the Rusty Eel makes landfall, the Camp tab becomes the ship:
  the port she is moored at (its rest, shops and expeditions), the chart,
  and "Sail back to camp" first. The camp comes back when she does.
- **Away from the camp** (the story has moved on), the Camp tab is the
  Ship tab: her hull, what she carries, and the chart to the other ports.
  The way home is the story's.
- Coming back to the camp through the story brings the Eel home with it.
- A companion's own house (Kelda's Hall) is offered only once that
  companion has joined. The Camp tab's dot for a house to build shows only
  at the camp.
- The camp's arrival pop-up is gone (the camp page says it all); towns keep
  theirs, with its text updated for the ship.

### Added
- **The Harbor**, a camp house (250 gold): once built, a Harbor button
  sits at the top of the camp and opens the slipway, where the Eel's hull
  is repaired and the shipwright's parts are fitted. It is now the only
  place she is refitted. The story mentions it on coming home.

## [1.142.0+171]

The play-mode lists only show what the player has discovered, and a
followed quest keeps its current goal in sight above the story.

### Added
- **A followed quest.** Its name and current goal ("Goal: Clear three
  catacomb ghouls (1/3)") show under the numbers above the story, with a
  Turn in button once every objective is met and a short "Updated"
  highlight when the goal moves on. Tapping it opens the quest: what was
  asked, each objective with its progress, the reward, and the other
  quests in progress to follow instead.
- A quest taken on is followed when no other quest is; any quest in
  progress can be followed from the Quests list (pin) or the quest sheet.
  A quest turned in hands over to the next one in progress.
- **"Goal reached"**: when a quest in progress has every objective met, a
  notice says so once (after the fight, if it happened in one).
- The "Previously" card lists each quest in progress with its current goal.

### Changed
- **Play mode lists show only what was discovered**:
  - Quests: offered, in progress or done, the followed one first, then
    those ready to turn in, in progress, offered and done. Their objectives
    show before the quest is taken on too.
  - Bestiary: creatures the party has beaten, with a count of those still
    to meet.
  - Shops: the ones found, saying where to trade ("where you found it", or
    "at the camp" for a camp house's shop).
  - People: those the story has reached (their chapter and flag) or
    already spoken to.
  - Achievements: an achievement not earned yet keeps its name and how to
    earn it hidden.
  - Edit Mode still lists everything.
- Turning a quest in (from the list or above the story) names the item
  won instead of its id.

## [1.141.0+170]

Each class starts with its own die and its own skills, dice made for a class
go to that class, every face shows what it does by its colour, and Wisdom
now feeds the mana pool.

### Changed
- **One die to start with.** A new Mage or Cleric owns the apprentice die
  only (it replaces the starter die); a Warrior, Rogue or Ranger owns the
  starter die only. A New Game+ legacy still adds the dice of the last
  cycle.
- **Starting skills match the class.** A character starts with their
  class's technique, their race's technique and, for a caster, a mana
  skill: **Channel** (Mage) and **Prayer** (Cleric), new skills that add 2
  mana (plus Wisdom) and sit on the apprentice die's Channeling face.
  Nothing is shared by every class any more except Heavy Blow, the basic
  strike an open Skill face falls back to: Fireball is a Mage skill, Shadow
  Step and Second Wind are general skills to learn with a point, and Void
  Blast no longer needs Fireball first.
- **The skill list shows only what the character can learn**: their class's
  and race's skills and the general ones, known skills first. Another
  class's skills, and merges they could never craft, are no longer listed.
- **Dice are made for a class** (or a race): the apprentice and sage dice
  for casters, the flame and arcane dice for mages, the holy and tide dice
  for clerics, the storm and huntsman dice for rangers, the shadow and
  twinfang dice for rogues, the iron and bulwark dice for warriors, the
  stone die for dwarves and the berserker die for orcs. Shops show who a die
  is made for and only sell it to them; the die picker only equips your
  own. A quest reward die made for another class is paid in gold (its
  price) instead.
- **Wisdom adds mana**: one more point per 3 Wisdom on every Mana face and
  mana skill (a human Cleric starts with +2). The skills screen shows the
  bonus, and the Wisdom description says so.

### Added
- **Colours by effect on every die face**: red for attacks, steel for
  guards, pink for heals, blue for mana, and a status skill wears its
  status's colour (poison green, stun amber, weaken purple). The fight's
  dice tray, the face sheet, the party cards, the dice loadout, the skill
  chips and the skill list all use them, with a colour key on the loadout
  and in the face sheet.

## [1.140.0+169]

From chapter 3 on, the camp is the party's base: the story comes back to it,
towns are places visited away from it, and what is built there is read back.

### Added
- **Two returns to the camp.** After the Spire the party walks home with the
  Warden's standard before going down to the Court, as promised ("three
  days"): sleep a night by the fires (+40 health) or leave before dawn with
  what the camp can spare (+40 gold). Before the Reliquary Quarter, going
  back to the camp first is a third way there (+30 health, and the frost at
  the Quarter's gate has spread a street further). Both scenes open with a
  "Back at camp" pop-up.
- **The camp grows in the story.** Building a house now leaves a flag
  (house_…), including on older saves, and every house is read back: Kelda's
  Hall, the Barracks Annex, the Hammersmith, the Academy and the Smugglers'
  Cellar on the first return, the Sharpweave Den, Banner Loft, Hearth-Hall
  and Shroud Shrine on the second, on the Hollow Shore and in the "home"
  ending.
- **The Smugglers' Cellar**, a new camp house (400 gold) that opens the
  Smugglers' Vault at the camp. The Vault no longer turns up "relocated" in
  the Ashen Quarter.
- **The Drowned Cloister and the Reliquary Quarter are towns**, with their
  name in the header and an arrival pop-up (including when entering the
  Quarter through its gate).
- **Endings bring the camp home**: the Eel comes into the cove to the camp's
  fires; the lanterns hang on the camp's landing; the seeker leaves the camp
  its stores and keeps the Eel; the dawn ending has a camp to come back to,
  or its ashes if it was given away.

### Changed
- **Rest in a town is "Rest at camp"** once the camp is founded: the party
  walks back for the night.
- **Arrival pop-ups**: the camp's names the Camp tab (not the old "Play"
  tab) and says "your base from now on"; coming back reads "Back at camp";
  towns after the founding say you are away from camp. Titles no longer
  break on names with an article ("Vous arrivez à Le Quartier…"), and
  "Leave {place}" is now "Move on" / « Quitter les lieux ».
- **Story fixes**: the Ashen Quarter's text is written as an arrival, a
  day's walk from the camp; the camp's smoke is a day behind you, not on the
  shingle; three days, not a week; the crew is sent back to the camp (where
  the Eel is), and the Eel's arrival on the Hollow Shore is explained; one
  camp line in 7004 instead of two contradicting ones; quests and Lysa point
  to the camp instead of Alster; the 7002 rest is a night on the sand.
- **One name per place** (French mostly): Quartier des Cendres, Néant (not
  Vide), Coffre des Contrebandiers, Quartier des Reliquaires, Cloître noyé /
  Drowned Cloister, Rive Creuse, Linceul (not Suaire or Voile), Mur du
  Jugement, Haut Gardien, the Rusty Eel as "l'Eel" and masculine, the camp
  as "The Cove Camp" / « Le camp de la crique ».
- **The narrator is no longer a man by default**: English lines like "a man
  who has never owned anything" and "A man can build…", and about 45 French
  agreements in chapters 3–7 (plus Lysa, Sister Inès and the death screen:
  « Vous avez péri »), now read for any character. Lysa and Sister Inès say
  « vous ».

## [1.139.0+168]

A town's scene folds away once it has been read.

### Changed
- **Towns and camps fold their scene when the player comes back.** Back
  in a town from one of its shops, people or challenges, the scene the
  player has already read shrinks to one line, "Read the scene again", and
  the town's own lists (shops, people, expeditions, the way on) get the
  rest of the screen. A tap opens the scene again, and "Fold the scene"
  closes it. The first arrival still shows the scene in full, and so does
  any return where the scene has something new (a progress line, a
  callback, a companion's remark). The last fight's aftermath stays
  visible under the folded line.
- The French hint under "Leave {place}" no longer assumes the player's
  gender ("quand vous le souhaitez" instead of "quand vous serez prêt").

## [1.138.0+167]

Character creation's five memories get their own page, and the French
speaks to the player as "vous" throughout.

### Added
- **The memories have their own page.** "A Life Before This One" opens
  after naming the character, with one line on what the memories do, a
  progress bar, the memory's title and scene, and its three answers in a
  shuffled order (the same order if you come back to it).
- **A summary before the story.** "Who You Are" lists each memory with
  the answer given and the starting alignment they add up to. Tapping a
  memory reopens it to change the answer; "Begin Your Story" starts the
  story. The closing line hands the telling over to the player, as the
  story itself is told in the first person.

### Changed
- **French in "vous".** The name dialog and all memories (including the
  five profession variants of the beggar memory) now use "vous" instead of
  "tu", with grammar fixes (missing pronouns, "supplier de", "avant que
  personne ne s'en aperçoive") and wording that doesn't assume the
  player's gender ("même si le froid vous mord", "même s'il ne vous reste
  rien"). "Le tyran de cour" becomes "La brute de la cour".
- The name dialog's button now reads Continue (the story starts after the
  memories).
- The memories' alignment is added once, at the end, instead of after
  each answer.

### Fixed
- **Android Back skipped a memory.** Back during the memories closed the
  question without an answer, so a memory could be skipped with no
  alignment, and five presses skipped them all. Back now returns to the
  previous memory; on the first one it returns to the character sheet with
  nothing applied, and Continue starts again (with the name kept).
- **Crash after naming the character.** The name field's controller was
  thrown away while the dialog was still closing, which raised an error
  after tapping the button. The dialog now owns the controller.

## [1.137.0+166]

The world map gets its original lettering, real zoom, the player walking
their own road, and three looks.

### Added
- **The player on the map.** A small traveller in a grey cloak stands
  where the story is. Opening the map, they walk the road from where the
  map last showed them to where the story is now (up to eight places),
  and the view follows them when zoomed in. A button walks the whole
  journey again.
- **The road the player took.** The road drawn is the player's own:
  every leg they actually walked, in the order they walked it, so the
  alley or the bridge shows whichever was taken.
- **Zoom.** The map stays put above the text, so pinching and panning
  work; + and − buttons, a double tap (in, or back out when zoomed), and
  a button that centres on the player.
- **Three looks.** Night (the map as drawn), Parchment (an old paper
  chart in ink and sepia) and Shroud (the world in grey, with only the
  Void keeping its colour). Chosen under the map and remembered.

### Changed
- **The original's lettering and colours.** Spectral for the text and
  Pixelify Sans for titles, labels and buttons, with the map page's own
  colours in light and dark, as the map was first drawn. Spectral (SIL
  Open Font License) is bundled and listed in the app's licences.

## [1.136.0+165]

A pixel map of the story's world, in play mode.

### Added
- **World map (play mode).** The map button in the header now opens a
  pixel map of the world: Alster and its river, the sea crossing, the
  Ashen Coast and the Hollow Shore, with the 23 places where the story's
  163 scenes happen.
  - A place appears once one of its scenes has been read; the rest of the
    world stays under fog, and the road between places reached is drawn
    in story order.
  - A gold marker shows where the story stands (for an excursion step,
    the last place it passed).
  - Tapping a place shows its chapter, what happens there, how many of
    its scenes have been read, and the foes fought there (named once
    beaten). Back and Next walk the road through the places reached.
  - Chapter chips filter the map to one chapter; pinch to zoom.
  - English and French; the water, embers and road move unless the
    device asks for less motion.
- **Pixel font.** Pixelify Sans (SIL Open Font License) for the map's
  lettering; its licence shows in the app's licences.

### Changed
- Edit Mode keeps the story graph behind the same button.

## [1.135.0+164]

The play tabs say what waits on them, New Game+ reaches stories finished
before the menu existed, and loading a save asks first.

### Added
- **Tab dots.** In play, a dot marks Character when stat or skill points
  wait, Camp when the purse covers a house (once the camp is open), and
  Other when a quest can be turned in. Holding a tab says why. In Other,
  the Quests section shows how many quests are ready to turn in.

### Changed
- **New Game+ for earlier finishes.** A story finished before 1.134 now
  offers New Game+ on the menu: the game in progress, or failing that the
  most recent save slot, counts when it is already on an ending. A
  recorded finish is never replaced.
- **Loading asks first.** Loading a save over a game in progress, from
  the menu or in play, warns that anything since the last save will be
  lost.

## [1.134.0+163]

A main menu, play tabs built around the character, the map in the header,
and a fight lab in Edit Mode.

### Added
- **Main menu.** The app opens on a menu: **Continue** on top when a
  story is under way (with the character's name, level and chapter),
  **New Game**, **New Game+** once a story has been finished, **Load**,
  **Settings** and **Edit Mode**. A home button in the game's header
  returns to it. New Game asks before replacing a story in progress;
  New Game+ starts the next cycle from the last finished run.
- **Fight lab (Edit Mode).** From the Play tab: pick up to three
  enemies, the chapter, a difficulty, an affix, the die to fight with,
  solo or with the party, and full health or as things stand, then
  fight. A boat fight against any enemy ship, with the boat's own
  parts or all of them, runs the same way. Afterwards the game is put
  back as it was (gold, health, items, dice, party) unless "Keep what
  happens" is on; the die picked for the test never stays equipped.
  A lab fight never triggers permadeath, even under ironman.

### Changed
- **Play mode tabs.** Story, Character, Camp and Other. Character is
  the character sheet; Camp opens at chapter 3 (before that the tab
  says when); Other holds the quests, bestiary, town and the rest of
  the old Play tab. Edit Mode keeps Story, Play, Generate and Data.
- **Map in the header.** The story map is an icon next to the language
  and settings buttons in both modes, and opens as its own page; jumping
  to a node from it returns to the story.
- **Camp houses.** Each house is a card with its description, and the
  Build button sits under it instead of squeezing the text.

### Removed
- The "try the game mode" nudge on the Play tab (the menu chooses the
  mode now).

## [1.133.0+162]

A lighter reading screen, gold in view when trading, expedition cards
that read on a phone, and a story export in Edit Mode.

### Added
- **Gold in view.** Shops, the sell and forge sheets, the camp and the
  boat show the purse at the top, and it pops when it changes.
- **Story export (Edit Mode).** A share button next to the map's legend
  button exports every story node: **Light** (id, chapter, text and
  choices with where they lead, what they fight and where a loss goes,
  in chapter order and in the app's language) or **Full** (every field
  of every node in both languages, in the story file's own format,
  edits included). Either one can be copied or saved to a file.

### Changed
- **A lighter story screen in play.** The header is one line: level,
  health, mana, gold and open quests, with the journal and read-aloud
  buttons at its end. Tapping the numbers opens the rest (experience,
  alignment, flags, and the way to the quests and shops). The separate
  Quests and Shops chips are gone, and node ids only show in Edit Mode,
  so the story gets more of the screen. The same line heads the Play
  tab and the character sheet.
- **Expedition cards read on a phone.** Each card shows the zone's name,
  tier and level chips, its boss and the Begin button; tapping or
  holding it opens the zone's description, with Begin there too.
- **Play tab.** Places that are not open yet (camp, boat, town) share
  one line, "Camp, The Rusty Eel: Reach Chapter 3 to unlock", instead
  of a locked card each.

### Fixed
- A town's done count no longer pushes its Rest button off a narrow
  screen in French; it sits under the place's name.

## [1.132.0+161]

The review's content, balance and feature list: selling and forging,
a story journal, save slots, retreat, clearer fights, new gear and
enemies for the late chapters, French game data, and a Play to Chapter
that always gets there.

### Added
- **Play to Chapter always arrives.** A run that falls short (a fight
  lost after every retry, a dead end, the step cap) is undone and played
  again with fresh rolls and choices, up to ten times; the last attempt
  pushes through any fight it cannot win. The button shows the attempt,
  and the result says how many attempts and forced wins it took.
- **Selling.** Shops buy back what nobody wears for two fifths of its
  price (an item's own sale value wins, such as the Elite Mark's 60); a
  piece sold where it is stocked goes back on the shelf. Quest items
  stay with the party.
- **The Hammersmith's forge.** Iron ore drops from Inquisition soldiers,
  void wisps, catacomb ghouls, Bone Sextons, the Dock Overseer, the Iron
  Golem and the Bone Warden, and the forge turns ore and gold into an
  Iron Cap, Iron-Shod Boots, Iron Greaves and an Iron Scale Coat.
- **"The story so far".** A journal from the story header lists every
  scene's opening line and the choice that left it, newest first by
  chapter. Picking a saved story back up shows a short "Previously..."
  recap once: the last scenes and the quests still open.
- **Hub checklists.** Finished activities stay on the hub's list, ticked
  and greyed, with a done count next to Rest.
- **Three save slots** with a summary each (the old save becomes slot 1).
  **Ironman:** with permadeath on, nothing can be loaded and a death
  deletes every save.
- **Retreat.** In any fight without a boss, the party can get away for a
  share of the purse (15%, at least 10 gold) and keeps its wounds.
  Nothing is won and no loss is recorded, so there is no defeat branch
  and no permadeath; a detour is left behind, an expedition ends as a
  retreat and a story fight waits where it was.
- **Clearer intents.** A fully read enemy intent shows the damage that
  would land after the target's armor, resist and block, with the raw
  blow beside it.
- **Choose the critical.** With momentum full, you pick which strike
  gets the guaranteed critical; left alone it goes to an Attack face
  first.
- **Scroll of Fireball** is read in a fight: a fireball at one enemy, no
  mana, the scroll spent.
- **New gear.** Boots and greaves in five steps each (chapters 1 to 5),
  common and uncommon head and body armor for chapters 3 to 6 that sits
  below each chapter's rare piece, and three late dice: the Ossuary die
  (the Ossuary Trade), and the Vigil and Tear-Glass dice (the Last
  Lantern).
- **Spells for every fighter.** Warriors learn Rally the Line (party
  heal that grows with Strength) and Sundering Roar (every enemy
  Weakened); rogues learn Smoke Veil (party block) and Bleeding Cut
  (damage and Poison); rangers learn Arrow Volley (every enemy) and
  Snare Shot (damage and a stun). Each is a spellbook in a shop.
- **Three enemies for chapters 4 to 6:** the Bone Sexton, the Drowned
  Pilgrim and the Unmade Knight, each with its own lines, loot and
  icon, and able to lead packs.
- **French game data.** Items, dice, enemies, shops, skills, spells,
  quests, zones, houses, races, professions, achievements, ships,
  companions and people now read in French when the app is in French,
  and the data editor shows the French fields.

### Changed
- **Boss moves are enemy-only:** never listed, unlocked or set on a die.
- **Zone bosses stay in their zones.** They never turn up as random
  fights or in packs, and are never promoted to Elite.
- **Shops open by chapter.** Detours and expeditions only open shops
  their chapter allows, never a camp house's own shop.
- **Outliers brought in line.** The Void Banner is a strong chapter-1
  artifact, given by the story once and sold nowhere; the Boiled Leather
  Jerkin, the Tear-Glass Blade, the High Warden's reward and War Shout
  (which now grows with Strength) were retuned. To keep the opening
  hovel fight as winnable as before without the old banner, the White
  Soldiers there hit a little softer (90 health, 24 damage).
- **Dice:** the berserker die was toned down, the weak shop dice raised,
  and the void die's signature skills now work.
- **Loot tables:** hunters drop gear the hunted can wear, out-of-chapter
  drops were moved, and potions, antidotes, scrolls and ore drop at
  their own odds (capped) instead of only weighting the chest.
- **Boss ladder.** The Hollow Court Inquisitor (340), Void Archon (380)
  and Void Sovereign (390) now rise in raw health too. They already rose
  in the fight, where the chapter curve and zone tier multiply them.
- **Full House** asks for six companions; every zone says when it is
  cleared; chapter 3's regulars were retuned.

### Fixed
- **Safer loading.** Saves carry a format version; a session that cannot
  be read is kept aside instead of being overwritten, and nothing is
  written before the save has been read.

### Internal
- The fight screen (5,300 lines) is split into eleven part files under
  `lib/screens/fight/`, with no behavior change.
- Balance check (40 simulated runs): first-try win rate 97% in chapter 1
  and 89% in chapter 6; Void Archon 34/40 and Void Sovereign 35/40 on
  the first try; Lysa survives the opening in 24 of 40 runs (25 before).

## [1.131.0+160]

Fixes from the review of 1.130: endings, death, fights, gear, tomes and
the town layout.

### Fixed
- **Endings reach New Game+.** An ending whose only way out is "Begin
  again, changed" now shows the ending screen, with its New Game+ button
  and a button carrying the ending's own words, instead of a plain choice
  list.
- **Permadeath keeps the character.** After a death with permadeath on,
  the story restarts at the first scene after character creation instead
  of the very first scene, whose only choice rolled a new character. You
  keep level, stats, gold and companions; items are lost (companions'
  worn gear included) and skills go back to the class basics. The
  setting and the death screen now say so.
- **No walking out of a fight.** The back arrow stays disabled until the
  fight is settled, and the system back gesture during a fight shows "The
  fight is not over" instead of leaving. Before, back skipped a loss (and
  permadeath) or left a won fight so it could be fought again for its
  rewards. Once the fight is over, back does what the return button does.
- **One copy, one wearer.** A single copy of an item can no longer be
  worn by you and every companion at once. The pack shows who wears each
  item, and the equip list only offers copies nobody else is wearing.
- **Zones opened from the story load their data first.** A story choice
  that starts an expedition, fight, shop or quest waits for that data to
  load, so after a relaunch the zone is no longer skipped.
- **Stuns stop companions too.** A stunned companion sits out the party's
  round instead of rolling as usual.
- **Tomes are read.** A tome bought in a shop is read on the spot and
  grants its stat or skill point. A tome found as loot has a Read button
  in the pack.

### Changed
- **What a skill does on a basic face.** 1.130 promised a skill on a basic
  face would never be weaker than the face, but on a Guard face it lost
  the block. The skill replaces the face's own action, as before; the
  text now says so, and that the floor only holds on Attack and Heal
  faces (never less damage than the attack, never less healing than the
  heal). Keeping the block as well would have made Guard the best face
  for every skill.
- **Onward choices are sorted by where they lead.** A hub choice counts as
  something to do there only if it comes back to the hub within a few
  scenes; the rest is listed as the way onward. At node 6010 the way on
  was listed under People.
- **Camp arrival.** The pop-up no longer tells you to "Rest here" where no
  Rest button exists; it points to the Camp page.
- **Arrival pop-ups wait for the story.** The town or camp pop-up only
  shows when the story tab is in front and nothing is open over it, such
  as another tab, a fight or the autoplay spinner.
- **Hubs fit small phones.** The choices take at most 60% of the space
  under the header, and a hub's things to do and its way onward each
  scroll in their own part, so nothing overflows at 360x640. The
  expedition card puts its button under the text, and long titles on the
  Play tab and in the edit-mode header are shortened.
- The Gemini voice player is only created when the Gemini voice is used.

### Tests
- `story_layout_test.dart` opens six story scenes, hubs included, at
  390x844 and 360x640 in English and French and fails on any overflow.
- `fight_back_guard_test.dart` checks that back leaves a fight's setup but
  not a fight in progress.
- `review_fixes_test.dart` covers shared gear, tomes, story endings, the
  scene after character creation, onward choices at 6010 and the wharf,
  and waiting for zone data.

## [1.130.0+159]

Shops, loot and dice say what things do before you commit to them, the
wharf reads as a town, and edit mode can skip a fight.

### Added
- **Stats on every shop row.** Each item shows its stats as chips, with a
  green or red difference against what you wear in the same slot, plus
  what it scales with, its unique effect, its alignment and any
  requirement you miss. Potions, charms and tomes say what they do.
- **A full look at any item.** Tap or hold an item in a shop to open a
  sheet: every stat beside the item you wear in that slot, the
  difference, its set, requirement and effect, with a Buy button. Dice in
  shops are listed by name with all their faces.
- **Use your spoils now.** Once the chest's items are revealed, gear you
  can wear gets an Equip toggle and a healing potion a Drink toggle; each
  row compares the drop with what you wear, and tapping it opens the full
  sheet. Picked gear is put on and potions drunk as soon as the loot is
  granted. If leveling up already healed you, the potion stays in your
  pack.
- **Six new dice.** Gambler's (big swings), Frost (Ice guard and a
  stunning grip), Twinfang (two quick fangs and poison), Bulwark (heavy
  guard and a shield bash), Pilgrim's (Light heals and a radiant
  judgment) and Tempest (Electricity and mana). They are sold at the
  beggar's stall, the docks black market, the Hammersmith, the
  Sharpweave Den, the Last Lantern and the Academy.
- **Arriving in town or camp.** Reaching Smugglers' Wharf, the Ashen
  Quarter or the camp from elsewhere in the story shows a pop-up that
  says where you are and how the place works. Story nodes can now carry
  a `settlement` (town or camp, name, optional port).
- **Win a fight in edit mode.** A trophy button in the fight's top bar
  drops every enemy and wins the fight with its rewards and chest.

### Changed
- **A face is the skill it carries.** Die faces no longer show the die's
  fixed flavor name above the skill: each face is named after its skill,
  or its basic action (Attack, Guard, Heal, Mana). The same names appear
  in the fight tray, the face sheet, the combat log, the skills tab and
  the dice loadout.
- **Attack, Guard and Heal faces take skills.** Every basic face is now
  open: tap it (or drag a skill onto it) to choose its skill. A skill on
  a basic face works at 70% power and never weaker than the face itself;
  a skill face casts at full power. A die's own signature faces stay
  locked, and whoever holds a die can cast its signature skills even
  without having unlocked them, so a bought die's faces no longer fizzle.
  The loadout shows each face's chance to come up.
- **Hubs read as places.** On a hub, the things to do there come first
  (boutiques, expeditions, people, challenges) and the choices that move
  the story on come last. In a town the way onward is folded under
  "Leave <town>". The wharf lists the port's own shops and expeditions
  beside the story's.
- **The Town page opens only in town.** The Play tab's Town card opens
  while the story stands in a town with a port, and says so otherwise;
  expeditions are offered in towns and at the camp.

## [1.129.0+158]

Fights draw their effects on screen: every skill and spell plays its own
effect on the fighter it touches, with the numbers floating off them.

### Added
- **An effect for every skill and spell.** skills.json and spells.json
  gain a `vfx` field naming one of 29 effect styles, set on all 89 skills
  and 11 spells: a fireball flies from the caster and bursts, a meteor
  falls and craters, lightning forks down from above, a void rift tears
  open and drinks the light around it, frost shards scatter, a volley of
  arrows rains in, a whirlwind circles, a quake throws up rock, smoke
  swallows the card, a drain pulls motes back to the one who cast it, a
  radiant column falls on the target. The style gives the shape and
  motion, the element the colors, so a Fire heal glows warm and a Void
  heal dark. The data editor offers the styles as a list.
- **Die faces, enemy moves and statuses play too.** An Attack face is a
  blade stroke, Defend a shield around the member, Heal rising sparks and
  crosses, Mana motes spiralling in, an empty face a puff. An enemy's
  move plays its skill's effect on the member it hits, a plain attack a
  claw-and-blade strike; a dodge is a puff and "Dodge!", a hit fully
  absorbed a shield and 0. Poison bubbles on every tick, a stun circles
  stars over the card, Weaken drops chevrons, a critical hit bursts
  gold, a boss changing phase sends out a great ring. Spells, potions,
  the antidote, thorns, lifesteal and the Phoenix Sigil's second wind all
  have theirs.
- **Floating numbers.** Damage, healing, block and mana rise off the card
  they apply to, in their own colors: pale on an enemy hit, red on a
  party member hurt, green for healing, blue for block, violet for mana,
  gold and larger for a critical.
- **Pacing.** Each party member's die plays a beat after the one before,
  and the enemy answers once the round's effects have landed. A heal skill
  plays on the one who uses it, while the base damage every Skill face
  still deals lands on the enemy as a plain blow.
- **A Combat effects switch** in Settings (on by default). With the
  system's reduced-motion setting on, only the numbers are drawn, without
  particles or movement.

### Verification
- Tests check that every skill and spell names a known style, that every
  style has an id and colors for every element, the mapping from faces,
  skills, spells, enemy moves and statuses, the heal-skill rule, that an
  enemy move reports the skill it used, and that the effect layer plays
  every style between two cards and then stops asking for frames, with
  and without reduced motion. Every style was also rendered to an image
  mid-flight and checked by eye; the light beams were shortened to fall
  from just above their target rather than the top of the screen.

## [1.128.0+157]

Every fight and event now says why it happens. A review of how scenes
follow one another found the story's own scenes mostly set up their
fights, but the random detours between scenes did not: they rolled on
seven story transitions in ten, opened with a line that ignored what was
actually drawn ("A figure steps out, weapon already drawn", then a rat),
offered a bare "Fight", and could land in the middle of a chase.

### Added
- **Enemies say who they are and why they attack.** enemies.json gains a
  `description` (EN/FR) for all 42 enemies, shown under each name on the
  fight's setup card, and `encounterText` lines (two per enemy, EN/FR)
  for the 19 enemies a detour or a zone can draw, plus a `packText` line
  for the 9 that come in groups. A detour fight now opens with the drawn
  enemy's own line, which gives its motive: the rat is in its supper, the
  bandit counted your coin, the warden has a warrant, the void hound points
  at the Shroud. The theme's generic line is only the fallback.
- **Detour fights name who is fought** ("Fight: Street Bandit ×2"), a
  detour stall names the shop ("Take a look: …"), a detour job names the
  quest and says what it asks ("The job: …").
- **A context card on every detour**: "Detour on your way:" and the choice
  the player just made, the reason when the builder knows it, and that the
  story picks up where the player was going once it is dealt with. A
  hunter's ambush says who sent it and why (the Choir after the wicked,
  the Pit after the righteous, more often the further you lean); a
  temptation says both sides court the undecided and the answer moves the
  alignment.
- **Story fight buttons carry crossed swords and the enemy names**, so a
  plain label never hides a fight. The pact's turned companion stays
  unnamed on purpose.
- **Expeditions state their goal** under the progress bar: clear N
  encounters, then the guardian (named), to claim the zone. A hunter or
  temptation met in a zone shows its reason too.
- **A raider at sea is named and described** before the battle, from
  enemy_ships.json's description.

### Changed
- **No detour interrupts a crisis.** A transition from one tense scene
  into another (the hovel raid into the unfurling, "Run for the docks",
  "Climb out before the roof comes down"; 22 transitions, by the scene
  moods the story file already carries) takes no detour and no alignment
  event. What the road held is owed, not lost: a detour rolled there is
  taken at the next transition at rest.
- **Kelda's gate announces its fight.** "Return to the stalls" launched a
  soldier fight nobody had mentioned; the scene now brings the boarding
  party she was holding the gate against up the wharf, and the choice
  reads "Hold the gate beside her".

### Fixed
- **A stall found on a detour could never be opened.** It was recorded
  against the scene the detour left, so the Shops tab showed it as left
  behind. "Take a look" now opens it on the spot.
- **A job offered on a detour was accepted blind.** It now shows the same
  pop-up as a job offered by the story, with the quest and an Accept
  button.

### Verification
- New tests cover the encounter helpers (rosters, pack lines, wrapping,
  fallbacks), the detour builder's lines and labels with and without
  records, the mid-crisis gate on the story's own transitions, the owed
  detour, the detour's origin in the play state, the hunter and
  temptation reasons, Kelda's scene, and that every enemy has a
  description and every drawable one has its lines in both languages.
- The simulator's story walk gained the same rule and was run on two sets
  of 80 seeded playthroughs against the old placement. With the gate and
  the owed detour, detours per run fall from 50 to 42, and level (20.3
  against 20.5), gold left, fight win rate (95 to 97%) and the Sovereign's
  first-try rate stay within the noise between seed sets; every run
  reaches an ending. A stricter rule, no detour whenever either scene is
  tense, was tried and rejected: it removed a third of the detours and cut
  companion recruitment (Liora 33 to 14 runs, Sable 36 to 19) because most
  of chapter 1 is one long flight.

## [1.127.0+156]

Boarding, both ways, and the ship battle's polish: what a shot would do
shown on every room, an auto-station button, and the boarding crew named
before the grapples are thrown.

### Added
- **Boarding.** When the enemy's bulwark is out and her layers are gone,
  her rail is open: a Board button beside End turn throws the grapples.
  Her helm may slip them (a roll against her evasion; the turn is spent
  either way). If they hold, the battle drops onto her deck: the existing
  dice fight against the ship's boarding crew (two street bandits on the
  Skiff, two and a harbor rat on the Brig, two auxiliaries and a soldier
  on the Cutter, two void hounds and a wisp on the Barge), fought at 2.5x
  difficulty, a crew on its own pitching deck being far more than the same
  men met on a road. Win and the ship is taken: her gold, and her prize
  part installed when the Eel has room for it (its worth in gold
  otherwise): spare canvas from the Brig, iron plating from the Cutter,
  fire pots from the Barge. Lose and the party is thrown back to the Eel,
  15% of her hull the poorer, once a battle.
- **They board you too.** While the Eel's own rail is open, a boarding
  crew may come over on any enemy turn (30-40% a turn by ship, once a
  battle). A hand in the Hold meets them at the companionway and the
  boarders fight at three-quarters health; with nobody in the Hold they
  come at full strength. Boarders beaten are gone; boarders that win wreck
  the Hold (knocked out) and a fifth of the hull.
- **Shot preview.** With a weapon armed, every enemy room shows what the
  shot would do if it lands: the hull it would cost and the pips it would
  knock off, "KO" on a room it would put out, a flame when it would set
  the room burning, and "shield +0" when a layer would stop it (the
  bulwark pip the blow would still crack is shown). Evasion is the one
  thing not previewed.
- **Auto-station.** A button in the crew bar places the crew the way the
  simulator does: the nimblest hand to the helm, the strongest to the
  guns, the third to the bulwark, the fourth to the hold; under half hull
  a hand goes to the hold, and an unmanned fire pulls a hand to it.
- The hint line names the boarding crew when the rail is open ("board and
  fight Street Bandit x2, Harbor Rat at the rail"), and a door icon marks
  a bulwark that is open to boarding.
- enemy_ships.json gains `boardingCrew`, `boardingChance`, `prizePartId`
  and `prizeGold` (schema-validated, checked against enemies.json and
  ship_parts.json by the data test). The Raider Skiff gets a gunwale for
  a bulwark (one pip), so even she must be shot open before she is
  boarded.

### Verification
- `ship_combat.dart` gains `bulwarkOpen`, `grapplesHold`,
  `boardingRepelled`, `boardersWreck`, `boardingProfileFor`, `previewShot`
  and `autoStations`, all pure and unit-tested (39 ship-combat tests).
- The simulator's `sim_v11.py` boards when the rail is open and the crew
  are fit, and is boarded on the same rule as the game. The deck fight's
  difficulty was swept over 24 playthroughs: at 2x the party took 77 of
  the 84 ships it boarded, the Barge among them, and boarding was the
  opening against everything; at 3x the Barge's deck was never taken and
  her fights fell to 40% won, the auto-pilot paying 15% hull for every
  refused boarding. At the shipped 2.5x, over 78 voyages and 97 raider
  fights: the Skiff won every time in 2.2 rounds, the Brig every time in
  4.6, the Cutter every time in 3.5, the Barge 68% in 12.8 with 43% hull
  left; the party boarded 79 times and took 63 ships (the Brig and Skiff
  every time, the Cutter 26 of 28, the Barge 2 of 16); the enemy boarded
  25 times and took the deck 5; 6 voyages turned back; every run reached
  an ending.

## [1.126.0+155]

Ship battles rebuilt in the manner of FTL: two ships of four rooms each,
weapons that charge and fire at a room, shield layers that stop shots and
crack under them, fires, and the party as crew at their stations.

### Added
- **Rooms.** Every ship has a Helm, Guns, Bulwark and Hold, each with
  system pips. The Helm gives 8% evasion a pip; the Bulwark holds one
  shield layer a pip and raises one back each round; the Guns charge the
  weapons, extra pips speeding the heaviest; the Hold is where the crew
  shelters and the hull is patched. A hit knocks pips off the room it
  lands in; a room at zero is out (a silenced ship charges nothing, a
  blind one slips nothing, a broken bulwark holds no layer).
- **Shots.** A weapon fires at a room of the enemy's ship: tap the weapon,
  then the room. The target's evasion is rolled first; then a shield
  layer stops a non-piercing shot, though the blow still cracks a pip off
  the bulwark behind it (so a single gun can wear a bulwark down); a shot
  that gets through costs hull and pips, and an incendiary one leaves the
  room burning (a pip and hull a round until someone fights it).
- **Crew stations.** The player and every active companion sail as crew.
  Tap a member, then a room: a helmsman adds evasion (more with
  Dexterity), a gunner a charge step to the heaviest gun, a bulwark hand a
  second layer a round, a hold hand hull repairs (more with Wisdom).
  Anyone repairs the room they stand in or fights its fire, and that
  takes their turn at the station. A shot that lands in a crewed room
  hurts whoever stands there, and the hurt persists to the shore.
- **The enemy's crew and aim.** Enemy ships repair a pip or fight a fire
  each round (their guns first, the bigger crews twice), and aim: fire at
  the hold, otherwise the bulwark or the guns, then down the list. With
  the Kraken's Eye aboard the enemy's aim is marked on your rooms and
  named on its weapons before it fires.
- **Weapons and parts re-read.** The ballista fires every turn; the
  harpoon rack pierces the bulwark and tears two pips, three turns to
  wind; fire pots burn, four turns; the void volley pierces, four turns.
  Iron plating is one more Bulwark pip (a second layer), the tar-sealed
  hull one more Hold pip, spare canvas one more Helm pip. ship_parts.json
  gains `chargeTurns`, `piercesShield`, `setsFire`, `roomDamage` and
  `roomBonus`; the old bulwark-pool fields are gone.
- **Four enemy ships with rooms and weapons of their own**, in
  enemy_ships.json's new `rooms`, `weapons` and `crew`: the Raider Skiff
  (open boat, bow chaser and grapnel, no bulwark, nimble), the new
  Corsair Brig (chapter 3: twin ballistae, a 24% helm, a thin bulwark),
  the Inquisition Cutter (a layer, a ballista, fire arrows for the hold,
  two hands) and the Void Barge (chapter 4: two layers, a piercing void
  lance, a harpoon, a chaser, two hands). Each has a description.
- **ShipBattlePanel** draws it: the enemy's rooms, weapons and charge on
  top, the log, the Eel's rooms with her crew, her weapons and crew chips
  below, and one End turn button.

### Changed
- The Kraken's Eye no longer blunts a first volley; it shows the enemy's
  aim every turn instead (its description and label say so).
- The boat screen lists the Eel's room pips instead of a bulwark pool,
  and a part's summary reads its charge, piercing, fire and room pips.

### Balance
- The Python simulator carries the same rules (sim_v11.py). Over 24
  playthroughs with a four-part Eel and a full crew: the Skiff is won
  every time in 4 rounds with 88% hull left, the Brig 95% of the time
  (7 rounds, 79% hull), the Cutter 88% (9 rounds, 71% hull), the Barge
  79% (14 rounds, 43% hull), 8 voyages in 80 turned back, every run
  reaching an ending. A first pass without busy hands and with the enemy
  repairing its bulwark first was won 100% everywhere with no hull lost;
  a second with a harpoon wound in two turns lost to the Barge 93% of the
  time.

## [1.125.1+154]

### Changed
- **The coming damage is blue.** The slice of an enemy's health bar that
  the aimed dice would take off, and its "-N" chip, are now painted blue
  instead of darkened. Nothing else on the enemy side is blue, so it never
  reads as damage already taken, and in a pack fight the blue moves to
  whichever enemy the player aims at.

## [1.125.0+153]

The number before the confirm: every rolled die now says what it will do
to the enemy it is aimed at.

### Added
- **Damage preview on the dice.** Under each landed die's name, the damage
  its target would take if confirmed now (or the healing, block or mana
  it gives), computed with the confirm's own formula: base, gear, stat
  scaling, alignment gear, element bonus, Weaken, the target's Armored
  affix, bracing and the battlefield's multipliers. A strike that would
  drop its target reads "KO"; a strike that cashes in the momentum meter
  shows its guaranteed-critical number with a star. A lucky critical is
  the one thing not shown, since it is rolled at the confirm.
- **The enemy's bar shows the slice about to go.** The health bar of an
  enemy with dice aimed at it darkens the part those dice would take off,
  reads "now → after / max", and carries a "-N" chip (or "-N KO"). In a
  pack fight, re-aiming a die moves the slice and the number with it, so
  the player can pick a target from what each choice actually does.
- **The face sheet says the same.** A long-press on a die now adds
  "Against <enemy>: N damage, M HP left" under the face's own line, from
  the same preview.

### Fixed
- The face sheet's numbers left out alignment gear and unique/set gear
  damage, so they could read lower than what the confirm dealt. The
  confirm, the preview and the sheet now share one damage formula
  (`_totalDamageFor`) and one affix rule (`strikeDamageAfterAffixes`).

## [1.124.0+152]

A fight the story can lose, and outcomes said plainly.

### Added
- **Defeat branches.** `StoryChoice.loseNextId`: a story fight with one is
  played once, and losing it is a scene rather than a retreat (the
  choice's own effects and unlocks stay the winner's). The fight's end
  button reads "Face what comes" instead of "Retreat", the editor has a
  Defeat Destination field next to the check-failure one, the graph
  check walks the branch, and the in-app and Python simulators take it.
- **The hovel is a real fight.** Unfurling the Bundle at 400 now means
  three White Soldiers (a new chapter-1 enemy, weak alone and hard as a
  pack for a first character) before the Shroud's shockwave finishes
  them. Win and the Guardian path is yours as before. Lose and you are
  taken to the Black Hold with Lysa lost, a scar from rib to hip that the
  docks read back, and +2 alignment for having fought. Surrendering is
  interrogated all the same and now costs the character's name: -2 to
  beg for her, -4 to tell them what they want to hear (was 0 and -2).
- **Outcomes stated where the story lands.** The defeat scene opens with
  "I lost.", the Black Hold with "Captured, then." and a line for how you
  got there (fought and lost, or surrendered), the Guardian scene with
  "I won, barely", the tear's failed check with "The tear won."

## [1.123.0+151]

The chapter-1 rules applied to chapters 2 through 6: a choice is a short
line, a lock is one line, a lock the story already decided is hidden, no
node whose only choice is "continue", and every choice costs, gains or
leaves a mark a later scene reads back. `story_rules_test.dart` now holds
those rules for the whole story.

### Changed
- **Eighteen padding beats given a real choice or a cost.** The wharf
  arrival (walk the stalls, or lift from an unwatched crate), the bilge
  swim (-10 health), the inspector's corpse (+20 gold), Vane's tunnel
  key and his broken cordon (-10 health), the stained-glass drop (-10
  health), the Warden's standard, the catacomb descent (down in the dark
  for -10 health, or a lantern for 25 gold), the way to the drowned
  cloister (the candles, or the rats' dry passage on a Perception
  check for a dead runner's purse), the altar (reached by the circle
  fleeing or by breaking it), the climb out (before the roof comes down,
  or searching the loyalists' dead for +40 gold and -1), the ledger in
  daylight (read at once, or rest an hour first for +20 health), the
  road to the Quarter (go now, or pay a runner to warn the camp), the
  tear (the crew at your back, or sent home first), the Void's showing
  (accepted, or torn loose from for -25 health), Lysa's mask (kept, or
  left on her), the turned companion's body (carried aboard, or left to
  the legate's rowers), and the Sovereign's throne (leave at once, or cut
  the taken's names from it for -10 health). Each leaves a mark the next
  scene reads.
- **Thirty-five choice lines cut to at most 55 characters** (the longest
  was 112, an acolyte "still chanting among the ashes as though
  conviction alone might stop a blade"), ten paragraph locks cut to one
  line (the three harbor recruits, the orc mercenary, the choir deserter,
  the white sail, the chapel), the cleric Maren's scene hidden for a
  player who lost Lysa instead of explained, and "(Combat Encounter)"
  gone from Vane's fight.
- **Two silent marks now read:** the storm's lost stores on landfall, the
  Warden's mercy in the Hollow Court; the Sovereign's "Tell it nothing"
  now leaves one too.

### Tests
- `story_rules_test.dart`: the five rules over every node, with the final
  crossing's explained lock as the one named exception.

## [1.122.0+150]

Chapter 1 consistency pass, on the owner's rules: a choice is a short
line, never a paragraph; a lock the story already decided is hidden, not
explained; no node whose only choice is "continue"; every choice costs
something, gains something, or leaves a mark a later scene reads back.

### Changed
- **Twelve padding nodes removed** (47 → 35 in the chapter): the tavern
  cellar folds into the escape choice (250), the Black Hold's wake /
  breach / search / shim / door chain becomes two scenes (800, 816), the
  toll fight, the freed hound, the hound's Warden kill, the battlements
  jump, the sewer exit, the dockside hound and Kroll's entrance become
  effects on the choice that caused them plus a callback line where the
  story next stops (280, 823, 891, 960).
- **Fake forks are gone.** Kroll's aftermath no longer offers "Climb
  toward Lysa" to a player who lost her (or "Climb up alone" to one who
  kept her) with a paragraph explaining why they cannot: the climb shows
  only the path the player earned, and the Rat/Broken choice moves up
  onto it. The cloaked figure at the market, the hound at the hallway
  and at the docks appear only when the story allows them. "Back away"
  from the Rat Matriarch, which looped straight back into the same fight,
  is replaced by a Constitution check to wade past her; "Try to push
  past" the Wardens, which always ended in the same fight, is a Strength
  check that costs health on success.
- **Every remaining lock is one line** (the toll, the smuggler's three
  approaches, the Broken's rage): the longest is 66 characters, down from
  239.
- **Every choice does something.** The slums offer a neighbor to help
  (+1, -10 health), stalls to empty (+20 gold, -1) or a straight run
  the cellar remembers; the market detour no longer has a free exit
  (the bandit, the forge's smoke, or the figure at the edge); the tear's Luck
  check pays out on success (+30 gold from what the looters dropped) and
  scars on failure (-10 health, void-marked); the hovel can be searched
  (+15 gold for -10 health); leaving the hound is remembered; the keeper
  can be covered before the run (+1, -10 health); the Black Hold's
  wounded assistant can be finished for his purse (-2, +10 gold) or
  dragged clear (+1, -5 health); the torturer's instruments can be
  pocketed (+20 gold, -1); the battlements cost the river jump (-20
  health); the smuggler's three doors now differ (+1 / a debt and -10
  health / -2 and +25 gold, each read back on the crossing).
- **Path-blind lines fixed.** Kroll is "my torturer" only for a player
  who was in the Black Hold; a player who kept Lysa meets him as the man
  sent for the Bundle, and the mercy/vengeance aftermaths no longer
  mention sessions that never happened. The ex-quest meta labels in
  choice text ("(Start Battle)", "(Luck Check)", "(The Rat Path)") are
  gone; the UI already shows a check's stat and DC.
- Twenty new flags, each read back by a callback or a gate; `keeper_dead`,
  set since 1.118 and never read, now is.

### Tests
- `chapter_one_test.dart` holds the rules: choice text ≤ 55 characters,
  lock text ≤ 80, a story-decided lock is hidden, every single-choice
  node's choice carries an effect, every choice differs from its
  siblings in effect or destination, and every chapter-1 flag is read.

## [1.121.0+149]

The four improvements the 1.120 simulation pass proposed and the owner
approved: a gentler New Game+ step, Lysa's fate as a beat the story does
not let you miss, Resolve (a small stacking edge against a boss that has
beaten you), and a late gold sink in the camp.

### Changed
- **New Game+ is +10% per cycle** (was +15%): at +15% the Sovereign was
  beaten first try by 8 of 32 simulated parties and two runs never
  crossed; at +10% every run finishes.
- **The Reliquary Quarter has a gate** (`6010_gate`, between 6002 and
  the hub). A character who kept Lysa walks through with her at their
  shoulder; one who lost her cannot go in among the chapels until they
  have followed the chalk to the chair (alignment 5 and up) or faced the
  masked penitent (4 and down). Before, the fate was one hub activity
  among fifteen and 8 of 44 simulated players who lost her never took
  it; now none miss it. The hub's own fate choices stay as a fallback
  for saves already past the gate.

### Added
- **Resolve.** A lost boss fight goes on the books
  (`PlayerSession.bossDefeatCounts`, one per boss in the fight), and the
  next attempt against that boss gives the whole party +5% health and
  damage per defeat, up to five stacks, shown on the fight's setup card.
  It softens the tail without moving the median: with Resolve alone the
  Sovereign's first-try rate is unchanged, but no simulated run lost to
  it more than seven times (one lost 25 times before) and a run's worst
  case fell from 26 losses to 7.
- **The camp's works**, three late houses priced in the thousands with a
  party-wide bonus: the Hearth-Hall (1,500 gold, +3% health, after
  Cinder Row), the Banner Loft (2,500, +3% damage, after the Ossuary
  Galleries) and the Shroud Shrine (4,000, +2% health and damage, after
  the Dead Heart). Together +5%/+5%, deliberately small (a +10%/+10%
  version pushed the Sovereign's first-try rate from 65% to 90%). Gold
  left at the end of a simulated run falls from 14.5k to 6.4k.
  `houses.json` gains `partyHealthBonus` / `partyDamageBonus`, the camp
  card shows them, and `party_bonus.dart` resolves Resolve and the works
  into one `PartyBonus` the fight screen applies at party build.

### Simulation (80 runs, same seeds as 1.120; 32 New Game+ runs)
- Base: 99% of fights won, 0.7 losses per run (max 6, 46 flawless runs),
  the Sovereign first try 61/80 (was 52) with 29 losses across the batch
  (was 139), the Archon 68/80 (was 59). New Game+ at +10% with both:
  96% won, 2.4 losses per run, the Sovereign first try 19/32, all 32 runs
  finishing (at the old +15%: 59%, 40.6 losses per run, 8/32, 30/32).

### Tests
- `party_bonus_test.dart` (stacks, cap, the works' data), the session's
  boss-defeat book, and the gate's routing in `story_direction_test`.

## [1.120.0+148]

Simulation pass on 1.119: 80 playthroughs on the shipped tuning, 32 more on
each of three New Game+ steps, and the one bug the numbers exposed, fixed.

### Fixed
- An excursion could offer Tobin's vigil (Good only) and Malrik's cut
  (Evil only) to any character: the excursion quest pool never read a
  quest's `requiredAlignment`, and it prioritizes companion-recruit
  quests, so nearly every playthrough ended with both companions their
  story nodes gate by alignment (Malrik in 78 of 80 simulated runs, Tobin
  in 73). `SubNodeEngine.filterQuestPool` now applies the same gate as
  the recruit nodes ('Good' or 'Evil' must match the character's
  alignment label; 'Neutral' or unset means anyone), the story player
  passes the session's label, and the Python simulator mirrors it. After
  the fix: Tobin in 37 of 80 runs (all Good), Malrik in 20 (all Evil),
  and a Neutral character in neither.

### Tests
- `sub_node_engine_test.dart`: the quest pool by alignment, and the two
  shipped recruit quests against their gates.

## [1.119.0+147]

The 1.118 seams closed, the Shroud given its meaning, the companions
given their say at every dilemma, Lysa's arc carried through to a fate,
an Inquisition pact that turns a companion against you, and a painted
sail that lets the Rusty Eel fly.

### Fixed (1.118 regressions)
- Vane's maintenance tunnel now runs under the Inquisition's cordon to
  the old berths (2030, 2070) instead of an Upper Gate that no longer
  exists; the harbor's-end companion lines and callbacks no longer
  mention a tunnel or a Gate.
- `7005_seeker`'s three epilogues carry the whole Shroud.
- `7004` no longer says the camp is waiting when it was given to the
  Sovereign, and `2900` no longer says the Eel needs a hull and a sail
  when both are done: `FlagCallback.andFlags` (all must be held) joins
  `unlessFlags`, and both nodes read their state from callbacks.
- Lysa sails with you (callbacks at 2001, 2015, the wharf and the camp;
  the sailed-alone lines yield to her), her hub scenes hide instead of
  locking for a player who lost her, and 6010_lysa no longer has her
  arrive over water on the only hull.
- 3002's "second set of doors", and a death narration that named the camp
  before it existed.

### Added
- **The Shroud's meaning**: the Void wanted it whole (6004), the Court's
  kneeling inquisitors were its hands, the crossing thanks the bearer for
  carrying it (7002_confront), 4999 plants the question and 7005_dawn
  answers it: whole is also the only way the door closes.
- **Companion voices at the dilemmas**: `ally_acknowledgments.dart` gains
  the wharf, the storm, the Warden, the altar, the reliquary, the
  Sovereign's price (every companion steps forward) and the legate's
  offer, in both languages; the `{lost}` token names the companion the
  story took last (7003, 7004, 7005_dawn, the betrayal).
- **The Inquisition's pact** (`7002_pact`, Evil only, alignment ≤ -15): the
  last legate lands on the Hollow Shore; taking the pact turns the first
  active companion against you (`@first_ally` resolves to a new
  `<companion>_turned` enemy with that companion's own skills and a
  phase, or to the legate's champion with no one left to turn), removes
  them for good, and pays in gold and a fourth toll at the crossing (give
  the Sovereign the legate). Eight turned companions, the champion and
  their icons; callbacks through 7003, 7004, 7005 and 7005_crown.
- **Lysa's fate** for a character who surrendered her: on the Reliquary
  Quarter hub, a Good character (alignment ≥ 5) finds her dead in the
  Inquisition's penitent-chair with the player's name scratched twelve
  times beside it; anyone else fights a masked penitent who will not
  stop staring and learns whose face was under the porcelain only when
  the mask comes away. New `masked_penitent` enemy whose phase says your
  name; `lysa_found_dead` / `lysa_fallen` read back through chapter 6 and
  the endings.
- **Painted sails** (`lib/data/sail_powers.dart`, a `Sail` slot on the
  Eel, five ship parts): the Gull's Wing (elven paint: flight, storms and
  raiders pass beneath the keel), the Kraken's Eye (orcish ink: tomorrow's
  weather shown, the first volley seen coming), the Hearth-Mark (dwarven
  stone-mark: every day at sea heals the crew and mends the hull), the
  Wind-Knot (human banner: a shorter crossing, richer wrecks) and the Void
  Mark (a void volley in battle, storms that do not bite). One sigil at a
  time; repainting replaces it; painted the character's own people's way
  a sigil holds twice as strong. Wired into the voyage and ship battle,
  the shipwright card, the schema and l10n.
- Tests: `sail_powers_test.dart`; story-direction groups for the pact,
  Lysa's fate and the regressions; session and narration suites extended.
  The Python simulator turns the first companion on `@first_ally`; 40/40
  runs reach an ending.

## [1.118.0+146]

The story reviewed against the owner's direction: one Shroud, in pieces,
carried from the first chapter and completed on the spine at a cost; a
transport built to leave the town; a camp on a remote coast after a long
voyage; power that is worn, not held; and no clean way through.

### Changed
- **Every origin carries the Shroud.** The Rat steals the Bundle back
  from the Black Hold's table and the Broken has it burned into his scars;
  all three epilogues set `void_banner_bearer` and grant the heirloom
  piece. The seeker branch (`void_banner_seeker`, `5003_seeker`,
  `6001_seeker`) is retired; `7005_seeker` is now the wanderer's ending
  (sailing for the other tears with the whole Shroud) open to anyone.
- **Chapter 2 ends by building the transport.** Node 2900 is the harbor's
  end: the Rusty Eel needs a hull (Fisherman's Row) and a sail (Tanner's
  Court), both launched from the story and mandatory; "Cast off" appears
  only with both done. Casting off is a choice about who sails: everyone
  (stores thrown over), the twenty who can fight (the rest left to the
  Crusade), or no one. The voyage (2999) is three weeks at sea and a storm
  that costs the stores, the refugees' skiff, or the character's body.
- **Chapter 3 is remote.** Landfall on the Ashen Coast after twenty days;
  the Spire of Judgment (the Inquisition's mother-house, where the Crusade
  sailed from) a day's walk inland; the camp founded in a hidden cove and
  written to grow into whatever the player brings back. The old Upper
  Gate/Lower City geography is gone from chapter 3 onward, including the
  death narration and the ending texts.
- **The Shroud's four pieces on the spine.** The heirloom (chapter 1); the
  Warden's standard, stitched to the High Warden's living back
  (`4999_standard`: cut it free alive, wait for him to die in the burning
  Cathedral, or give him the blade first); the Court's twin, wrapped
  around twelve sleeping taken (`5004_altar`: wake them to die as
  themselves, or cut it free without waking them); the reliquary thread,
  sewn around the chart-keeper's sister (`6010_thread`: open it yourself,
  pay for the chapel and let her cut it, or hand the penitent the seal).
  6002 explains the four pieces. `banner_whole` gates `7002_confront`, and
  the Sovereign then names a price (`7002_price`): a companion, the
  character's blood, or the camp.
- **Power is worn.** Node 0 sets it out; races.json gains `powerMedium`
  (banner, painted sigil, stone-mark, ink, void-mark) and a sentence per
  race; the `{sigil}` token resolves to the character's medium; the Court's
  ash-ink, the Warden's standard-into-skin and 13 new persona lines at
  250, 450, 3001 and 7003 show it.
- **No clean way through.** The unfurling costs 15 health and the
  Beggar's keeper; every choice of the seven spine dilemmas (400,
  2900_boat_fixed, 2999, 4999_standard, 5004_altar, 6010_thread,
  7002_price) wounds, impoverishes, blackens, takes a companion or leaves
  a mark; 24 new callbacks read those marks back from the camp's founding
  to each ending.
- Quests `q_ch1_*` and `q_ch3_alsters_dawn` no longer grant Shroud pieces
  (the story does).

### Added
- `StoryChoice.grantsBannerPieceId` (adds to `bannerPiecesCollected`) and
  `StoryChoice.loseAllyId` (a companion id, or `*` for the first active
  ally, removed from the roster for good and never re-recruited:
  `PlayerSession.lostAllyIds`, `loseAlly`). A negative `healAmount` is a
  wound the story deals and stops at 1 health. Editor fields and l10n for
  both; the character screen names the two new pieces.
- `docs/chapter-flow-roadmap.md` records the refined structure.
- Tests: `test/story_direction_test.dart` (origins, seeker retirement,
  four pieces in order and unavoidable, the whole-Shroud gate, the
  boat-building exit, the remote chapter 3 and the old geography's
  absence, every dilemma choice costing something and its mark being read
  back, races' media and `{sigil}`), session tests for the new effects.
- The Python simulator applies the new costs; a 40-run batch reaches an
  ending 40/40 through the mandatory boat zones and the dilemmas (94.2%
  fight win rate).

## [1.117.0+145]

Narration that remembers, reacts and varies: scenes that call back the
player's earlier choices, hubs that note how they have changed, companions
in their own voices, fights that leave a mark on the next scene, a written
death, second beats and a spoken finale, and far more variety on the road.

### Added
- **Flag callbacks** (`flag_callbacks` on a story node): paragraphs shown
  only to a player holding an earned flag, with an optional `unlessFlags`
  veto. 34 callbacks across chapters 1-6 and the four endings wire up the
  eleven flags the story set but never read (`took_bundle`,
  `forge_cache_found`, `tern_row_spared`, `ashen_ledger_decoded`,
  `reckoning_wall_saved`, `camp_founded`, the optional zones' reward flags,
  `banner_second_piece_lead`) plus `lysa_survived`, `void_marked` and the
  penitent's confession.
- **Hub progress lines** (`hub_progress`): each of the four late hubs
  (2015, 3005, 5010, 6010) adds a what-has-changed sentence once 3-4 and
  again once 6-9 of its activities are done, counting its own
  `hub_<id>_` flags.
- **Persona variants** (`persona_variants`, keyed `race:<id>` /
  `profession:<id>`): 26 sentences on ten scenes that react to an orc on
  the wharf, a voidkin in the drowned cloister, a mage at the bazaar, a
  cleric in the Hollow Court, and the like.
- **Name tokens**: `{name}`, `{race}`, `{profession}` and `{companion}` in
  story text are filled from the session at render time
  (`lib/data/narration_tokens.dart`, with French nouns for every race and
  profession). Tobin, Malrik and Vane now say the character's name.
- **Companion voices**: `ally_acknowledgments.dart` is now keyed by node
  *and* companion -- seventeen scenes carry a party-wide default and two
  to nine companion-specific lines each (Kelda at the Warden's fall,
  Sable on the Eel's rail, Vess hearing the Void, ...), in English and
  French; the first active ally with a line speaks.
- **Fight aftermath** (`lib/combat/combat_aftermath.dart`): FightScreen
  publishes a `FightOutcome` (won, enemy names, Elite/hunt/boss, phases
  crossed, companion knocked out, flawless, rounds) and the next story
  node or expedition event opens with a paragraph drawn from seven
  bilingual pools -- a retreat, a boss that changed stance, an Elite, a
  hunt's quarry, a companion down, a clean fight, a plain win.
- **A written death**: the permadeath screen now opens with one of four
  bilingual death narrations naming the killer, above the tally.
- **Second beats** on the late hubs, via the new `StoryChoice.showIfFlags`
  (hidden until every flag is held -- the mirror of `hideIfFlags`): the
  deserter's warning, the archivist's second ledger, an hour with Tobin,
  the sapper's thanks (5010); the chart-keeper's sister, the penitent's
  answer (three alignment-weighted replies), a walk with Lysa, the Last
  Lantern's keeper (6010). Eight nodes, each appearing only after its
  first visit and retiring itself.
- **Finale**: "Sail into the tear" now leads to `7002_confront`, where the
  Sovereign speaks through the tear and the player answers (the names of
  the taken +2, the ballista, or the crown -2) before the crossing; and
  `7002_crew`, a last word to the companions with a line for every one of
  them.
- **Speaker labels**: a node whose `speaker` is not the Narrator shows an
  italic eyebrow above its text (The Archivist, The Sovereign, The
  Chart-keeper, The Penitent, The Lantern-keeper, The Deserter, Vane,
  Lysa), translated.
- **Zone midpoint beats** (`midpointFlavorText`/`midpointFlavorTextFr` on
  zones.json): halfway through a zone of three or more events, its own
  paragraph of narration between two draws (Scaffold Yards, Drowned
  Stair, Dead Heart Approach, Shroud's Vigil, Beyond the Tear).
- **Variety on the road**: every excursion flavor pool grows from 7 to 12
  lines per kind per theme (120 new lines, English and French); the
  hunt's trail lines go from 3 to 8 and its quarry lines from 2 to 8; the
  60 generic "Back to the market / into the quarter / to the Cloister /
  to the Quarter" return choices are rewritten from a pool of eight per
  hub, assigned round-robin.
- l10n: `aftermath_heading`, `expedition_midpoint_label`,
  `expedition_press_on`.
- Tests: `test/narration_test.dart` (show-if flags, callbacks, persona
  lines, hub progress, tokens, speaker labels, companion voices, aftermath
  pools and routing, pool sizes and EN/FR parity, and the authored data:
  every callback and show-if flag is settable, every persona key is a real
  race or profession, tokens match across languages, return lines vary,
  second beats retire themselves, the finale confronts before crossing).

### Changed
- `withAllyAcknowledgment` takes the party's `activeAllyIds` instead of a
  boolean, so the line can be the speaking companion's own.
- The Python simulator's `hidden()` honors `showIfFlags`; a 40-run batch on
  the new graph still reaches an ending 40/40 (94.4% fight win rate).

## [1.116.0+144]

A medium-hard difficulty curve, boss phases, item sets and unique gear,
companions that aim their own strikes, New Game+ and alignment epilogues
with two alignment-locked companions.

### Changed
- **Difficulty curve.** The v1.115 equip-gate fix had left the corrected
  40-run batch winning 99.6% of its fights. Every regular enemy now
  carries a flat floor (health ×1.15, damage ×1.10) under the unchanged
  chapter curve (+12% health per chapter, damage half that); bosses skip
  the floor and get their difficulty from phases instead. A steeper
  global step was tried first and rejected: it left chapters 1–4 at 100%
  while turning the chapter 5–6 bosses into walls. The same 40 seeds now
  win 96.6% of fights (1.9 losses per run, 16 flawless runs, all 40
  reach an ending); first-attempt rates are 100% on story fights, 96.6%
  in chapter-4 zones, 91.8% in chapter-5 zones and 81.7% in chapter-6
  zones, with the Void Archon beaten first try 27/40 and the Void
  Sovereign 26/40 (from 37/40 and 38/40). Ordinary fights stay a resource
  drain rather than a lethal threat for a full party of three; the risk
  now lives in the bosses.
- `difficultyCurveFor` in `combat_engine.dart` is the one place the fight
  screen, the in-app simulator and the autoplay engine resolve a fight's
  health and damage multipliers (floor, chapter, zone tier, New Game+).

### Added
- **Boss phases** (`phases` on an enemies.json record, `BossPhase` in
  `combat_engine.dart`). Once a boss falls to a phase's health threshold
  it changes stance, once: a heal, a cleanse of its afflictions, a
  damage multiplier for the rest of the fight, and new moves added to
  (or replacing) its list. The battle log announces the transition in
  purple, the enemy card shows a phase chip, the enemy sheet lists how
  many stances it has, and the telegraph is re-rolled so the new move
  shows on its very next turn. Every zone boss, every solo-only unique
  and both tier-2 alignment hunters have phases (18 enemies, the Void
  Stalker, Hollow Court Inquisitor, Void Archon and Void Sovereign two
  each), with eight new phase-only moves and pixel icons: brood call,
  meltdown, bone storm, eclipse, unmaking, martyrdom, many faces,
  stalker's ambush. Phase multipliers are capped at ×1.15 (×1.10 each on
  a two-phase boss): the first cut at ×1.3 made the two final bosses
  unwinnable for a fifth of the seeded builds.
- **Item sets and unique gear** (`lib/combat/gear_effects.dart`, a new
  `item_sets.json` table). The Harborwatch Kit (cutlass, coat, lantern;
  chapter 2, sold across the chapter-2 shops) gives +2 armor and +5%
  dodge at two pieces, +4 attack and +8% crit at three; the Hollow Court
  Vestments (blade, mantle, seal; chapter 4, sold at the Ossuary Trade
  and the Last Lantern, the seal a signature drop of the Inquisitor) give
  +5 armor and 4 thorns at two, +8 attack and 10% lifesteal at three. Four
  uniques: the Bloodthorn Blade (heals 20% of its damage), the Thornmail
  Hauberk (6 damage back to whatever connects), the Phoenix Sigil (once
  per fight a lethal blow leaves you at 1 HP) and the Siphon Wand (+1 mana
  per damaging hit). Set and unique effects apply in the fight screen and
  the simulator alike (flat attack/armor, crit and dodge bonuses through a
  new `critChanceBonus` on `resolvePlayerFace`, lifesteal and mana on
  hit per landed hit, thorns and second wind on the enemy's turn, all
  logged); the inventory shows "Set: Name (n/3)" with every tier and its
  check mark, and "Unique: …" with the effect, on tiles and in the
  detail dialog. Ten pixel icons.
- **Companions aim their own strikes.** A new combat setting (on by
  default) has companions focus fire on the player's target in a pack
  fight, or on the weakest enemy when the player has none, following a
  retarget as it happens; their cards leave the target picker. Off, every
  party member is aimed by hand as before.
- **New Game+.** A genuine story ending now offers the next cycle: a
  quarter of the gold, every die owned and every spell known are banked as
  a legacy that survives the reset at character creation and is handed to
  the new character; level, gear, companions, camp, quests and flags start
  over, and every enemy is +15% health and damage per cycle (the fight
  setup screen and a character-screen card say so). The same 40 seeds on
  cycle 1 win 73.8% of fights with 19.8 losses per run and all 40 still
  reaching an ending; +30% per cycle was tried and left eight runs stuck
  on the late bosses. An Edit-Mode reset wipes the legacy back to a first
  run.
- **Alignment epilogues.** Each of the four endings closes with an
  italic paragraph for the alignment the character actually reached it
  with (Good, Neutral or Evil; ten paragraphs, English and French), read
  from a new `alignment_epilogues` field on the node.
- **Two alignment-locked companions.** Brother Tobin, a dwarf cleric who
  deserted the Court's choir and keeps the drowned cloister's candles
  (chapter 4, Good only: Holy Light, Celestial Ward, Stoneskin, Mend), and
  Malrik Sarn, an orc rogue selling what the tear leaves behind in the
  Reliquary Quarter (chapter 5, Evil only: Poison Blade, Ruthless Edge,
  Savage Cleave, Bloodlust). Each has a recruit scene on the chapter hub
  (locked text when the alignment doesn't fit), a recruit quest, a
  signature die and battle banter in both languages.

### Tests
- New `boss_phases_test.dart` (phase parsing, ordering, index, move
  merging, heals, and a data check that every phase names real skills,
  is bilingual and stays under the enrage cap, and that every zone boss
  and unique has one), `gear_effects_test.dart` (set tiers, uniques,
  stacking, and a data check on item_sets.json); the difficulty test
  covers the floor, the boss exemption and New Game+; the session test
  covers banking, keeping and spending a legacy; the simulator test
  covers phases, gear numbers and a harder New Game+ fight; the
  story-node test covers epilogue parsing and round-trip; the engine
  test covers the crit-chance bonus and its cap.

## [1.115.0+143]

The in-app playthrough simulator now plays its fights out and reports
spells cast per run, and a gear-requirement bug that left every Mage
unarmed is fixed.

### Added
- **Simulator fight model** (`lib/data/sim_combat.dart`). Each simulated
  run now rolls a character of a random race and profession, created the
  way a new game creates one (defaults plus bonuses, the profession's
  starting die with the Technique faces wired on, its starting spells, a
  full mana pool), and plays every combat choice out with the engine a
  live fight uses: `rollDie`, `resolvePlayerFace`, `resolveEnemyMove`,
  statuses, the chapter curve and pack multipliers, Mana faces feeding
  the pool, and the same caster policy the Python simulator uses (heal
  below half, cleanse, the strongest affordable damage spell keeping a
  heal in reserve, block against a heavy swing, a hex on a long-lived
  enemy). A lost fight is retried up to three times, then the walk moves
  on and counts it lost; a loss refills health and mana as the app does;
  a new chapter counts as a rest; XP levels the character through the
  app's own thresholds. A shop is visited once when the story unlocks it:
  the profession's spellbook first, two potion charges per potion entry,
  the best affordable piece per slot, the sage die for a caster. No
  companions, affixes or battlefield conditions; a solo player's read,
  stated on the card.
- **Spells cast per run, on the simulator screen.** The batch recap gains
  fights won / lost and spells cast per run (with mana gained from dice),
  a Spells cast section with one chip per spell (total casts, runs that
  cast it on hover), a By profession list (runs, fights won / lost,
  casts) and the model's assumptions in one line. Each run's row shows
  its profession, level and casts; the run detail shows the character,
  its fight record and every spell with its count, and each step's fight
  as won or lost (with attempts) plus the spells cast in it. The chapter
  breakdown counts fights lost and spells per chapter. The transcript,
  batch summary (also what the Gemini analysis reads), CSV and JSON
  exports carry the same fields.

### Fixed
- **Half the builds could never equip gear.** The equip gate compared
  each of a character's four scores against an item's requirement, and
  treated a missing requirement as 0. Any character with a score below
  zero (a Mage's Strength −1, every Orc's Intelligence −1, every
  Voidkin's Constitution −2) therefore failed "score >= 0" on every item
  in the game and could equip nothing at all -- in the inventory screen
  as much as in the simulators. A requirement of 0 is now no gate, as
  the gate's own doc comment always said. The Python simulator had the
  same comparison: 15 of the 40 seeded builds had fought unarmed in every
  batch to date, which is why the same 40 seeds re-run after the fix win
  99.6% of their fights (from 82.3%), with 9 losses against 460 and the
  chapter-4 to chapter-6 bosses beaten on the first attempt 37 to 40
  times out of 40. Earlier batches' balance numbers stand corrected by
  this one; the enemy curve was tuned against a half-armed party and now
  reads as easy for a player who shops.

### Tests
`sim_combat_test.dart`: character creation for a Mage and a Warrior,
level-ups, a won fight with Arcane Bolt casts recorded, a loss refilling
health and mana, Mana faces feeding the pool over many fights, a
spell-less Warrior, and shop visits (spellbook, potions, gear, the sage
die, another profession's book left on the shelf). A regression test for
the requirement gate with a negative score.

## [1.114.0+142]

Mana and spells on the character screen and the skills tab, so the pool
and the spellbook are readable outside a fight.

### Added
- **Stats bar**: a mana chip (current / pool) next to health, pulsing
  when it changes like the health and gold chips.
- **Character screen**: a Mana & Spells card under the stats bar with the
  pool as pips and the names of every known spell; tapping it opens the
  Skills screen.
- **Skills tab** (the player's own, never a companion's): a Spells
  section heads the list with the pool, how it refills and where spells
  are cast from, then one card per spell the profession can ever cast --
  known ones with the numbers they would land right now (the same sum the
  battle screen uses: base damage, gear, stat scaling, alignment gear and
  the spell's element bonus, then the spell's own scaling), the unlearned
  ones greyed out with the shop that sells their spellbook. Each card
  opens a detail dialog: cost, effect, live amount, target, element,
  status, whether it is known and where to learn it.
- `lib/utils/spell_preview.dart`: the session-side spell preview and the
  spellbook-shop lookup; `lib/widgets/mana_meter.dart`: the shared pip
  meter; the mana and spell icons and labels move to `game_icons.dart`
  so the battle, character and skills screens draw them the same way.

### Tests
`spell_preview_test.dart`: caster damage from a session with a weapon,
its stat scaling and element bonus; the preview matching the engine's
own spell scaling; a hex's level-scaled poison; the spellbook-shop
lookup against the real data, including that every non-starting spell
is sold somewhere; the profession spell list's ordering and filtering.

## [1.113.0+141]

Mana and spells, and a combat screen rebuilt around them. Spells are cast
on demand during the party's turn, like potions, and cost mana; dice can
carry a Mana face that refills the pool mid-fight; a Mage or Cleric starts
with an apprentice die and two spells, everyone else can buy their
profession's spellbooks. The battle screen now reads like a dice-battler:
the party's dice in a tray on top (tap to keep one through a reroll,
long-press for every face of the die), the party down the left with each
member's die slot, the enemies down the right with an intent box, and one
action bar at the bottom for mana, spells, potions, reroll and confirm.

### Added
- **Mana.** A pool of 4 plus half the higher of Intelligence and Wisdom
  (a starting Mage or Cleric has 6). It carries over between fights like
  health, refills on a rest, on a lost fight and at a new game, and comes
  back mid-fight through a die's `Mana` faces (any party member's Mana
  face feeds the one pool). Persisted on every cast and every Mana face,
  so a fight abandoned half-way keeps what was spent. Saves from before
  mana existed wake up with a full pool. The debug stats editor exposes
  it.
- **Spells** (`assets/gamedata/spells.json`, a new Data tab table): eleven
  spells across the five professions -- Arcane Bolt, Frost Bind (damage
  plus a one-turn Stun), Ember Wave (every enemy) and Mana Ward (block for
  the whole party) for Mages; Mending Light, Sanctified Ground (party
  heal), Smite the Wicked and Purge (cleanse) for Clerics; Venom Hex for
  Rogues, Hunter's Mark for Rangers, War Shout for Warriors. A damage
  spell reads like a skill: the caster's own damage (base, gear, stat
  scaling, element) plus the spell's surge and half its stat, times its
  multiplier (Arcane Bolt x1.6), so it stays the caster's strongest single
  action from chapter 1 to chapter 6; healing and block grow with level
  on the enemies' own health curve, a hex's poison with level like enemy
  damage. Spells never crit, are never Weakened and ignore the Armored
  affix, so the number on the button is the number that lands. A spell
  that needs a single target asks for it in a sheet when there is a real
  choice.
- **Spellbooks**, a new item type: bought in a shop, the spell is learned
  on the spot and the book never enters the inventory; a book the player
  already knows, or another profession's, is greyed out with the reason.
  Seven books across the Arcane Bazaar, the Academy, Apothecary Row, The
  Last Lantern, the Black Market Docks and the Weaponsmith's Forge, each
  with a pixel icon. A spellbook handed out as loot is read the same way.
- **Dice.** The `apprentice_die` (two Focus faces for 1 mana, a jab and
  a ward worth the starter die's own, and the two Technique faces at the
  starter die's indexes) is a
  Mage's and Cleric's starting die and sells at the Bazaar; the
  `sage_die` (two Deep Focus faces for 2 mana, Arcane Missile, a mend) is
  sold at the Academy and the Ossuary Trade; the Arcane and Holy dice
  trade their Heavy Strike for a Mana Well / Prayer face. `Mana` joins
  the Data tab's face types.
- **Professions** carry `startingDiceId` and `startingSpellIds`; a new
  character owns both the starter die and the profession's die with the
  Technique faces wired on each, and permadeath resets spells to the
  starting ones.

### Changed
- **Battle screen.** Dice tray on top with each party member's die in
  their own accent color; a tap on a landed die keeps it (locks it)
  through the next reroll, and only unlocked dice reroll; a long-press
  shows what confirming would do and every face of the die. Party column
  on the left: avatar, thin health bar with numbers, damage/armor/block
  and status chips, and a die slot holding the rolled face; a crosshair
  marks whoever a readable enemy is about to hit. Enemy column on the
  right: portrait, health bar, affix and status chips, one colored dot
  per party die aimed at it, and an intent box that shows what the
  party's Perception can read (a question mark, the target, a move
  category, or the damage number, element and the move's own words).
  In a pack fight, tap a party card then an enemy to re-aim that die;
  every strike is aimed at the first living enemy by default, so Confirm
  is never blocked on a pick. The log shrinks to a two-line ticker that
  opens the full log in a sheet. The bottom bar holds the mana meter and
  one button per known spell (cost shown as pips, greyed when short),
  potion and antidote as icon buttons with counts, and Reroll (rolls
  left) / Confirm or Roll.
- A `Mana` face resolves through `resolvePlayerFace` like every other face
  type (`PlayerActionResult.manaGained`).

### Tests
`spells_test.dart` (mana formula, spell parsing, scaling, learning gate,
spellbook lookup), `spells_data_test.dart` (every spell well-formed and
obtainable, every spellbook teaches a real spell exactly once, starting
spells and dice consistent with the profession, Technique faces at the
starter die's indexes, Mana faces on the caster dice, the sage die on
sale), a Mana-face group in `combat_engine_test.dart`, and a mana/spells
group in `player_session_provider_test.dart` (round-trip, pre-mana save
migration, clamping, learning, spellbook purchase, rest refill, combat
persistence, new-game grant, permadeath reset). 377 tests pass.

### Simulation
40 seeded runs with the simulator taught to roll Mana faces, start a Mage
or Cleric on the apprentice die, buy the profession's spellbooks and cast
one spell a round (heal below half, cleanse, the best damage spell it can
afford, block against a heavy swing, a hex on a long-lived enemy), against
the same 40 seeds with spells off. Casters gained the most: the Mage's win
rate rose from 56.6% to 75.0% with deaths per run down from 43.5 to 18.1,
Mage and Cleric together from 62.6% to 79.1%; overall combat went from
79.5% to 82.3% with 460 deaths against 565. Boss first-attempt rates are
unchanged (Inquisitor 31/40 against 34/40, Void Archon 30/40 against
31/40, Void Sovereign 27/39 against 28/40), so the pool is a caster's
tool rather than a shortcut. 2,689 casts over 2,606 fights, 3,619 mana
back from dice faces, Arcane Bolt 1,848 of the casts. A first pass with
flat spell numbers (14 damage plus half of Intelligence) made the Mage
worse (45% win rate): by chapter 5 a bolt was worth a third of a Slash
and the apprentice die's two Focus faces were dead weight, which is why
damage spells now ride the caster's own damage and heals grow with level.
Two non-caster seeds diverged the other way (a Ranger and a Rogue reached
the chapter-4 boss with one companion fewer on the spells-on path and died
there repeatedly), a path effect of a spellbook's gold on recruitment, not
of the spells themselves. The simulator never rests at camp, so its mana
is the pessimistic read.

## [1.112.0+140]

The late-game batch, fourth step of the chapter-flow roadmap: chapter 4
becomes the second big zone, chapter 5 the last big zone, and a new
chapter 6 the final zone with four endings -- nine new enemies, five
zones, three ports, two hubs, two shops, six quests and three pieces of
gear, all with pixel icons and French text.

### Added
- **Chapter 4, the Hollow Court.** A new hub, the Sunken Cloister
  (node 5010), between the descent and the Court: an archivist who hands
  out the Main quest The Second Ledger, the sapper's Ossuary Bounty (a
  two-ghoul pack), the Bone Warden at the sealed stair, the deserters'
  ossuary stall (a new shop, The Ossuary Trade), a collapsed span
  (Dexterity check), void wisps among the candles and a deserter to
  question (Charisma check). Two zones at the new port The Drowned Stair:
  the Ossuary Galleries (tier 1, boss Bone Warden) and the Drowned Stair
  itself (tier 2, main zone, boss Hollow Court Inquisitor), which the
  hub's exit launches as an expedition before the story descends.
- **Chapter 5, the Reliquary Quarter** (node 6010): the chart-keeper who
  reads the ledger's last page (Main quest The Dead Heart), Lysa if she
  survived the Spire, void hounds, a penitent Inquisitor's confession
  and challenge, The Last Lantern (a new shop), a tear-spawn in the
  chapel and the frost's pattern (Wisdom check). Two zones at the port
  The Black Reliquary: the Dead Heart Approach (tier 2, boss Tear-Spawn)
  and the Shroud's Vigil (tier 3, main zone, boss Void Archon), launched
  by the hub's exit.
- **Chapter 6, Beyond the Tear.** The Void returns the party to the
  Hollow Shore with the Rusty Eel beached beside them; hollow reflections
  wearing the faces of the fallen walk the sand (side quest Faces of the
  Fallen), a last fire, then the Eel sails into the tear: the final zone
  Beyond the Tear (tier 3, port The Hollow Shore, boss The Void Sovereign,
  Main quest Beyond the Tear). After the throne room, four endings: carry
  the Banner home (bearers), keep seeking it (seekers), sew the tear shut
  with it (bearers of good standing) or take the Sovereign's crown (the
  wicked). The old chapter-5 endings live on as the first two.
- **Enemies**: Catacomb Ghoul, Bone Warden, Hollow Court Inquisitor
  (chapter 4); Void Hound, Tear-Spawn, Inquisition Penitent, Void Archon
  (chapter 5); Hollow Reflection and The Void Sovereign (chapter 6), each
  with skill moves, guile, loot and a pixel icon. The three new bosses
  join the solo-only set.
- **Gear**: the Tear-Glass Blade, the Archon's Mantle and The Sovereign's
  Crown (a guaranteed drop from the final boss).
- **Story-launched zones.** A story choice can carry `launchZoneId`: the
  expedition (and its boss) runs before the choice resolves; a retreat or
  defeat leaves the player on the node, an already-cleared zone is
  skipped. The editor exposes the field.

### Changed
- Story and zone bosses (the solo-only set) are no longer drawn as random
  expedition or excursion events.
- Chapter spine: chapter 4 and 5 gain their hub beats, chapter 6 is new;
  the map's chapter grid follows.

### Simulation
40 seeded runs: 40/40 reach chapter 6 and end (bearer 6, seeker 20, dawn
10, crown 4), party level by chapter 2.3 / 5.4 / 8.9 / 12.8 / 16.3 / 18.6,
three voyages per run with 142 raider battles all won once the harpoon
rack and iron plating are aboard. First-attempt win rates against the new
bosses: Bone Warden 90%, Hollow Court Inquisitor 88%, Tear-Spawn 92%,
Void Archon 72%, The Void Sovereign 72%; late packs 95% or better. Two
earlier passes were dropped: one where the simulator sailed to later
chapters' ports ahead of the story (levels 14 by chapter 3) and one where
the Sovereign could be drawn as a random expedition event.

## [1.111.0+139]

The boat batch, third step of the chapter-flow roadmap: chapter 3 opens
on raising the camp, and the Rusty Eel becomes the way to reach every
port's expeditions -- a chart of ports, short voyages of sea events, ship
battles fought with the parts aboard, and a shipwright to fit her out.

### Added
- **Camp founding beat.** A new node between the Upper Gate and the Spire
  district: the refugees who followed the party up from the Lower City
  raise a camp on the shingle below the Spire, with the Rusty Eel hauled
  up above the tide, and the story flags `camp_founded`. The camp stays
  there for the rest of the game.
- **Ports** (ports.json, `portsSchema`): a name and description in both
  languages, a chapter, the zones and shops found there, days at sea to
  reach it, `isHome` and `requiredFlags`. Ashen Landing (the camp's
  shore, home port: Cinder Row and the Scaffold Yards) and the Smugglers'
  Wharf (chapter 2's harbor: Fisherman's Row, Tanner's Court, Lantern
  Docks and the three starter shops). The Town Hub is now that port under
  its familiar name; the Camp's zone list is the home port's.
- **The Rusty Eel** (Play → The Rusty Eel, from chapter 3): hull and
  bulwark, the parts fitted by slot (two weapon, one bulwark, one rigging
  slot), repairs at one gold per hull point, the shipwright's six parts
  (ballista to start; harpoon rack, fire pots, iron plating, tar-sealed
  hull, spare canvas) and the chart of ports the story has reached, each
  with its chapter, days at sea and zone count. Setting sail opens a
  voyage; landfall moors the boat there and opens that port.
- **Voyages** (`lib/data/sea_events.dart`): one event per day at sea --
  calm days that mend the hull, storms that cost it, derelicts worth
  salvaging, sightings, and raiders (from chapter 2: a raider skiff;
  chapter 3: an Inquisition cutter; chapter 4: a void barge) that open a
  **ship battle**: pick a fitted part each turn (loose the ballista,
  brace the plating, patch the hull...), the bulwark absorbs before the
  hull, cooldowns keep the heavy parts honest, and a sunk hull limps back
  to the port it left at a quarter strength. Prizes pay gold and XP.
- **Session state**: hull, fitted parts, current and visited ports, with
  full save round-tripping.
- Tests: ship-combat rules, sea-event drawing, ports/ship data validation,
  session ship state.

### Changed
- ships.json / ship_parts.json / enemy_ships.json lose their sci-fi
  placeholders (starter freighter, laser) for the Rusty Eel, fantasy
  parts with FR names and labels, and three enemy ships gated by chapter.

### Simulation
40 seeded runs: 40/40 true endings, 92.2% win rate, every zone cleared,
an attentive player buying the harpoon rack, iron plating and tar-sealed
hull by the end (mean 439 gold on the ship) -- but zero voyages, because
every current zone is either on foot in chapter 2 or at the home port:
the later chapters' ports (next batch) are what make sailing mandatory.
The ship battle itself, run 300 times per loadout: the ballista alone
beats a skiff untouched and a cutter with half a hull, cannot beat a void
barge; harpoons make the barge winnable (15 hull left), iron plating
makes it comfortable (72).

## [1.110.0+138]

The difficulty batch, second step of the chapter-flow roadmap: enemies now
scale with the chapter as well as the party's level, every expedition zone
has a tier, a recommended level and a boss guarding its reward, zones and
the camp's workshops unlock in order, and the Smugglers' Vault no longer
sells endgame steel in chapter 3.

### Added
- **Chapter difficulty curve.** Every enemy's max health is multiplied by
  1 + 0.12 × (chapter − 1) and its damage by half that excess (chapter 3:
  ×1.24 health, ×1.12 damage; chapter 6: ×1.6 / ×1.3), on top of level
  scaling and before the Elite and pack multipliers. Gold and XP climb
  more gently (+10% per chapter). A fight's chapter is its story node's,
  or the zone's for an expedition.
- **Zone tiers and bosses.** zones.json rows carry `tier` (each tier past
  the first adds a tenth to health and half that to damage),
  `recommendedLevel`, `bossEnemyId` with EN/FR boss narration,
  `requiredFlags` and `isMainZone`. Once a zone's events are done its boss
  steps out: the dock overseer at Fisherman's Row, the plague hound under
  Tanner's Court, the smuggler captain at Lantern Docks, an iron sentinel
  on Cinder Row and a void stalker in the Scaffold Yards. Beating it banks
  the zone's reward with a Gold chest at least and half again the gold and
  XP; losing ends the expedition as a defeat.
- **Zone gating and cards.** Lantern Docks waits on the hull being patched
  (Fisherman's Row), the Scaffold Yards on Cinder Row; a locked card names
  the zone to clear first. Town Hub and Camp share one zone card with
  tier, recommended-level (highlighted while the party is below it) and
  Main-zone chips, plus the boss's name.
- **Camp workshops gated on zones.** houses.json `requiredFlags`: the
  Hammersmith waits on the Scaffold Yards, the Academy on Cinder Row, the
  Sharpweave Den on the Lantern Docks' lead; the camp shows the lock and
  `buildHouse` refuses an early build.
- Cinder Row and the Scaffold Yards now set `cinder_row_cleared` /
  `scaffold_yards_cleared` when cleared.

### Changed
- **Smugglers' Vault** stocks tier 6–7 weapons and shields plus the Void
  Banner instead of tier 8–10 (those stay behind the camp's workshops).
- The fight setup screen shows a "Zone boss" note alongside the hunt and
  hunter notes.

### Simulation
40 seeded runs with a player who heeds the recommended level: 40/40 true
endings, combat win rate 91.7% (94.7% with the curve off on the same
seeds), deaths per run 3.4 (2.2), zone bosses won 200 of 201 expeditions
(dock overseer 70% per attempt at level 3, smuggler captain 47% at level
5, void stalker 85% at level 8), chapter-2 story fights 93%, chapter 3
still 100% at a mean level of 9.6 -- the later chapters' new enemies (next
batch) are what that end of the curve is waiting on. A first pass with a
full-rate damage curve (+15% per chapter on both stats) collapsed the
tuned chapter-2 fights (smuggler captain 100% → 16%) and was dropped.

## [1.109.0+137]

The hub-loops batch, first step of the chapter-flow roadmap: the harbor
market and the Spire district are now real hubs that every route passes
through and that the party works through activity by activity, the
chapter Main quests are handed out where their story happens, and quest
items no longer depend on a drop roll.

### Added
- **Hub loops.** A story choice can now carry `hideIfFlags`: once any of
  those flags is set, the choice disappears from its node. Every activity
  on the harbor market (node 2015) and in the Spire district (node 3005)
  sets its own flag and its bridge node ends on "Back to the market" /
  "Back to the district", so a hub plays as a list of things to do that
  shrinks as it is worked through instead of a one-shot pick. The Iron
  Anvil's armoury, shieldwright and patch-up stalls loop the same way.
  Choices that lead back to their own node never roll an excursion. The
  story editor exposes the field ("Hide if flags", comma-separated).
- **Harbor bounty.** A new market activity, the harbor master's bounty on
  the wharf bandits (a two-bandit pack), hands out the Main quest The
  Burning Manifest.
- **Lysa's dawn.** If Lysa survived the Spire, a new district activity
  delivers her message and starts Alster's Dawn.
- **Failure branches** for the Spire archive and ledger checks: a failed
  read now lands on its own consequence node instead of a dead end.
- **Guaranteed drops.** A loot-table entry with a drop rate of 100 or more
  is always awarded on a win, on top of the spoils chest, so the High
  Warden's sealed letter can no longer be missed.

### Changed
- **Every route reaches the hubs.** Disembarking at the wharf now leads
  straight into the market before Vane is dealt with (his three exits,
  the crane and the rooftop archer sit on the hub itself); the stowaway
  route's bilge drain and inspector ambush both come out under the wharf
  and climb into the same market instead of skipping to the Upper Gate.
  The Spire's first doors open onto the district hub, whose only exit
  pushes deeper into the Spire; the openings of nodes 3002 and 3005 were
  rewritten in both languages to fit the new order.
- **Main quests wired to their beats.** The High Warden's Fall starts on
  entering the Spire, the Inquisition Ledger on the ledger choice, the
  Captain's Gambit on the smuggler and Harbor Reckoning on the plague
  hound; the weaponsmith's forge unlocks from the market armoury and the
  blind beggar's stall from the forge.
- **Chapter spine.** The bilge-drain node (2050) moved to chapter 2's
  arrival beat alongside 2010 and 2020.

### Simulation
40 seeded runs (4 strategies, alternating builds) with a player-like hub
policy (take an untried activity 85% of the time): 40/40 true endings,
combat win rate 97.0%, 8.3 harbor-market and 11.9 Spire activities per
run (37/40 and 40/40 runs visit them), 16.7 quests completed per run
(5.2 on v1.108), Kelda recruited in 29 runs (14 before), Sable in 25
(15), full roster 5/40 (1/40), mean final level 10.2 (7.3). The same
seeds under v1.107 rules still end 40/40.

## [1.108.0+136]

The dynamics batch: a clickable spoils chest after every win, enemy
affixes, battlefield conditions, momentum, charms and tomes, hunts, and an
alignment layer in which angels hunt the wicked, demons hunt the righteous,
and both court the undecided.

### Added
- **Spoils chest.** Every won fight now ends on a chest the player taps
  open, then flips slot by slot (or takes all at once; a Settings toggle
  auto-opens it). Its tier — Wooden, Iron, Silver, Gold or Void — comes from
  one visible fortune roll: d100 plus Luck (×2 for the player, ×1 for the
  best ally), +25 for an Elite, +6 per extra pack member, +8 for a
  flawless fight (no potion, nobody knocked out), +8 for two rounds or
  fewer, +8 for a critical killing blow, +8 per affixed enemy, +10 under
  an Ambush or Darkness, and +15 per consecutive Wooden chest. An Elite is
  never below Silver, a boss never below Gold, a first kill of an enemy
  type never below Iron, and a full telegraph read finds one extra slot.
  Contents are drawn by tier from a chapter window of items.json's new
  `rarity`/`lootChapter` bands: gear the party already carries never drops
  again, the last three drops weigh half, profession affinity and a
  matching alignment weigh more, and an enemy's old `lootTable` now only
  marks its signature drops (×3, ×6 on a first kill). Replaces the
  per-enemy drop-rate roll entirely; gold and XP are unchanged, the chest's
  own gold comes on top.
- **New item kinds.** Four charms (Gambler's Knucklebone: one extra reroll;
  Lucky Coin: +15% crit; Ironskin Salve: +5 armor; Warding Knot: the first
  hit taken is negated), picked on the fight's setup screen and burned for
  that fight only; two tomes read on the spot (Tome of Insight: +1 stat
  point; Tome of Mastery: +1 skill point); eight named pieces of gear, four
  of them alignment-bound.
- **Enemy affixes.** A solo enemy has a 20% chance (a pack member 15%) of
  one trait: Venomous (attacks poison), Armored (ignores 4 damage from
  Attack faces; Skill faces cut through), Skittish (flees below a quarter
  health with half its reward and one chest tier), Frenzied (×1.4 damage
  below half health) or, in packs only, Pack Leader (+20% health, and the
  rest of the pack hits ×1.25 while it stands). Bosses, uniques and Elites
  never carry one. Shown as a title ("Venomous Harbor Rat") with its rules
  on the setup screen.
- **Battlefield conditions.** A quarter of fights open under one: Ambush
  (enemies strike first, nothing reads off them that round), Darkness
  (every telegraph one tier worse), Cramped (packs of three: only two reach
  the party each round), High Ground (Defend ×1.5), Shrine (Heal faces and
  potions ×1.5).
- **Momentum.** Three damaging party hits with no enemy hit landing in
  between make the next Attack/Skill face a guaranteed critical.
- **Hunts.** After a random pack fight, a 35% chance of a trail leading to
  the pack's named survivor ("Merrick the Half-Faced", "Old Scar"): 20% more
  health, two affixes, ×1.5 rewards and a chest never below Gold. Expedition
  hunts are extra events, never a substitute for the zone's own.
- **Alignment on the road.** Off a Good or Evil score (±20), a hunter of
  the other side ambushes 10–22% of story transitions and expedition draws:
  angels (Sentinel and Judicator of the Choir) for the wicked, demons (Pit
  Imp and Tormentor of the Pit) for the righteous, the stronger pair from
  chapter 3. Hunters yield ×1.25 rewards and never less than a Silver chest,
  and never appear as ordinary random enemies. A Neutral character instead
  meets temptations (10%): four short scenes that pull the score one way or
  the other for gold, and two quest offers — "A Charge of Light" (kill a Pit
  Imp, +15) and "A Bargain in Shadow" (kill a Sentinel, −15) — which let the
  hunted side come looking while active. A Settings toggle turns the whole
  layer off.
- **Alignment on skills and gear.** A skill tagged `alignment` in
  skills.json is ×1.25 for a matching character and ×0.75 for the opposite
  (fourteen existing skills are tagged: the cleric's light and the void/
  poison kit chiefly); two new gated skills, Celestial Ward (Good) and
  Infernal Pact (Evil). Gear tagged with an alignment can't be worn by the
  opposite one and pays an `alignedAttackBonus`/`alignedArmorBonus` to a
  match; opposed gear never drops. The inventory and skills screens say so.
- **Companion banter** for four more moments (fight start, a pack sighted,
  an ally knocked out, a Gold-or-better chest), authored EN/FR for all six
  companions.

### Changed
- The Inquisition Warden leaves the random pack pool (17 damage is the
  chapter-1 heavy; a pair of them stuck a level-1 character for 25
  attempts in simulation). It stays a solo encounter with its own
  signature drop.
- Simulator port (sim_v3.py) of every rule above, run over the same 40
  seeds as the v1.107 batch: 40/40 endings, 98.4% combat win rate (98.0%
  before), affixed fights 98.1% vs plain 98.4%, chests Iron 25% / Silver
  25% / Gold 45% (about 26 points of that from the boss and hunt floors) /
  Void 3%, 2.5 tomes and 7.7 charms per run, 83 hunts and hunter ambushes
  across the batch (the Judicator, at 55%, is now the hardest fight in the
  game and only stalks the wicked), and end-of-run gold roughly doubled
  (1191 vs 604) from chest gold and the extra fights.

## [1.107.0+135]

The review's remaining P2 items: the Chapter-1 difficulty wall, three
combat-engine/data outliers, and the continuity nits.

### Fixed
- **The Rat Matriarch is no longer a Chapter-1 wall.** Node 855's forced
  fight (195 HP / 24 damage, the lowest win rate in the game at 48–63%,
  and a hard stop for a level-2 mage) is now 150 / 18, and the node offers
  "Back away and look for another way through" — the sewer's other exit.
- **`OnLowHealth` moves now honor their `chance`.** Every wounded-enemy
  nuke in enemies.json is authored at 40–60%, but the engine fired it 100%
  of turns below the threshold.
- **`void_blast` is no longer a one-shot.** 25 × 2.5 gave a flat +62.5 to
  every enemy that carries it (three times any other enemy skill) and
  ~128 damage in a level-4 player's hands (Sable's die now carries it for
  free). Retuned to 12 × 1.8. The three regression-tested bosses that leaned
  on it get a small base bump to stay in their tuned win-rate bands (High
  Warden 170 HP, Zealot 20 dmg / 160 HP, Manifestation 21 dmg / 165 HP).
- **`heavy_attack` no longer beats every purchasable skill for free**
  (8 × 1.6 → 6 × 1.4; still the default for any unassigned Skill face).
  The Plague Hound and Smuggler Captain — the other two Chapter-2 heavies
  a random excursion can force on a level-3 character — come down with it
  (175 / 21 and 180 / 21, from 205–210 / 24) so neither is a wall for a
  weak solo build.
- **Packs scale to the party.** A random pack never outnumbers the party's
  dice — a solo character meets at most a pair — and pair/triple members
  now fight at 80% / 70% of their solo stats (a level-5 solo mage went 0
  for 25 against a triple on action economy alone). The Dock Overseer and
  Inquisition Soldier leave the pack pool: two 40%-chance stunners lock a
  solo character out of most rounds, whatever their stats.
- **Pack overkill is redirected instead of wasted.** A hit whose picked
  enemy went down to an earlier blow this round now carries on to the next
  one standing, with the log saying so — previously it vanished while the
  log still claimed a hit.
- A telegraph badge can no longer name a party member poison just knocked
  out — the cached move is re-aimed at someone conscious.
- Story continuity: the Chapter-2 rat swarm is in the ship's forward hold,
  not a sewer; hiding in the cargo hold means slipping back aboard; a failed
  winch roll no longer draws steel on Vane; Kroll's fight now follows his
  taunt (the choice of mercy or vengeance is the fight, not its aftermath);
  the informant's ambush is three men fighting for the informant, not one
  for Vane; the smuggler waves *you* aboard on every path; the Chapter-3
  climax names the High Warden and knows two chapters remain; bribing the
  archivist costs 40 gold (and needs it); a failed archive lockpick skips
  the archive; paying the bridge toll no longer starts a kill quest; and
  `[COMBAT]`/`[TORTURE]`/`[SUCCESS]`-style authoring tags no longer leak
  into the prose.

## [1.106.0+134]

Fixes from the full mechanics/narrative review and the 40-playthrough
simulation.

### Fixed
- **Orc and Voidkin characters could not finish Chapter 1.** Any node with
  a flag/gold/alignment requirement also silently required Charisma ≥ 0
  (the default `reqCharisma` of 0 was compared against a negative starting
  Charisma), which locked all three doors at the smuggler gate (node 895)
  and every later gated node. Only a node that actually sets `reqCharisma`
  gates on it now.
- **Random enemy packs were unwinnable.** Packs of two or three chapter-2
  heavies (Rat Matriarch, Smuggler Captain, Plague Hound) out-statted every
  boss; in simulation a third of chapter-2 expedition fights were lost and 4
  of 40 runs ended stuck on one. Packs now draw only from `packEligible`
  trash-tier enemies, are capped at pairs through chapter 2, and each member
  is scaled to 85% (pairs) / 75% (triples) of its solo stats. Rewards are
  unchanged, so a pack still pays more than the same enemy alone.
- **Bought and looted potions/antidotes were inert.** They landed in the
  inventory where nothing could drink them; only the starting 3 potions and
  1 antidote ever existed. Potion-type items now become charges (a Major
  Healing Potion is worth two) when bought, looted, or granted by a quest.
- **Weaken lost a turn on both sides.** Party members' effects ticked before
  they acted (a 2-turn Weaken weakened one swing; with Wisdom ≥5, none), and
  a Weaken landed on an enemy was baked into its already-pre-rolled move a
  turn late. Members now tick after acting, and enemy moves are pre-rolled
  un-weakened with the debuff applied when the hit actually lands.
- **Companion signature-die faces fizzled.** Maren's Smite/Revive Prayer,
  Sable's Void Blast, Liora's Beast Bond, Vess's Entropy Touch and Grosh's
  Adrenaline Surge were all "Skill fizzles" until that exact skill was
  bought; every skill linked on a companion's signature die is now unlocked
  at recruit.
- Story: Vane's guards (2040) and the pushed-past Wardens (822) now actually
  fight; a failed ledger check at 3005 no longer lands on the acolyte's
  post-fight text; the torturer no longer dies at 810 before returning at
  955; the Rusty Eel beat reads correctly whether or not it was repaired.
- Quests: the Ashen Oath, Void Relic, Liora's Watch, Kelda's Stand and
  Dockside Debts kill targets are fought on the bridge node that hands out
  the quest, instead of being unreachable once the one-shot hub is left;
  Tern Row and Reckoning Wall quests are offered before their kill, not with
  it; The Heirloom of Alster completes by taking the bundle at the hovel
  (new `Flag` objective type) instead of only by buying the heirloom back.

### Changed
- **Perception is readable earlier and pays off tactically.** Every
  character starts with 1 Perception (Elf/Ranger +4 as before), enemy Guile
  is rescaled (trash 0–1, mid-tier 2–3, uniques 4–5, bosses 6–7) so an early
  investment reads trash immediately and a dedicated build can read a boss,
  and a Defend face rolled by the member a readable telegraph is aimed at
  blocks double.
- Data polish: Slum Thug shows its name instead of its id, two no-op enemy
  moves are gone, and `void_die` declares its real face count.

## [1.105.0+133]

Perception-gated enemy telegraphing and multi-enemy pack combat.

### Added
- **Perception stat and enemy telegraphing.** A new Perception stat (mirrored
  onto allies, race/profession bonuses — Elf and Ranger both get +4, making
  it their signature stat) is compared against a new enemy-side Guile stat to
  determine how much of an enemy's next move the party can see ahead of
  time: nothing below 1 net Perception, just who's targeted from 1-4, who
  plus a rough move category (attack/heal/debuff icon) from 5-9, and full
  detail (move name, element, effect) at 10+. Guile is deterministic and
  subtractive (`perception − guile`), not a per-turn roll, so bosses stay
  harder to read even for a heavily invested Perception build. Enemy moves
  are now decided one step ahead and shown as a telegraph badge, then
  applied unchanged on that enemy's actual turn.
- **Multi-enemy pack combat.** Fights can now pit the party against 2-3
  enemies at once, with an explicit target picker letting each attacking
  party member choose which living enemy to hit. Random expedition/excursion
  encounters have a chance to roll a pack instead of a single enemy, and two
  hand-placed pack encounters were added to the Chapter 2 and Chapter 3 hub
  nodes. The game's tuned boss/unique fights are excluded from packs (and
  packs are never Elite), so their balance is untouched. Rewards, loot, and
  kill-count credit are summed across every enemy defeated in a pack.

## [1.104.0+132]

Critical hits, dodging, companion banter, and Elite enemy encounters.

### Added
- **Critical hits and dodging in combat.** Luck now drives a critical-hit
  chance (5% baseline, +1.5% per point, capped at 35%) on every damaging
  Attack/Skill die face for the player and every active ally alike — a crit
  multiplies the hit's damage by 1.5x and is called out in the log. Dexterity
  now drives a dodge chance (5% baseline, +1.5% per point, capped at 30%) for
  whoever the enemy targets — a dodge evades the hit entirely, no damage, no
  status effect. Allies derive their own Luck the same way they already
  derive Wisdom, from their race/profession bonuses, so the mechanic applies
  uniformly across the whole party.
- **Companion banter.** An active ally has a chance to react with a short,
  personality-voiced line in the fight log when a crit lands or a hit is
  dodged — six new lines per companion (crit + dodge, EN + FR).
- **Elite enemy encounters.** Roughly 12% of eligible fights promote the
  enemy to an "Elite" version: +35% health/damage, +50% gold/XP reward, and
  a guaranteed unique "Elite Mark" trophy drop, with a gold-accented name and
  portrait in the fight UI. The game's tuned boss fights are excluded, so
  Elite stays a trash-pool variance mechanic rather than a boss reskin.

## [1.103.0+131]

### Added
- **A Map tab in normal (in-game) play**, not just Edit Mode. Now that the
  map shadows nodes you haven't reached yet (previous release), it's safe
  to hand to players — same fog-of-war rules apply, so nothing about a
  future chapter is spoiled. Edit Mode keeps its extra Generate/Data tabs;
  Map now shows in both.

## [1.102.0+130]

Fog of war for the story map: outside Edit Mode, it now shows your journey
so far rather than the entire spoiler-laden graph at once.

### Added
- **The story map shadows nodes you haven't reached yet.** A node the
  player hasn't actually visited this playthrough now renders as an
  unrevealed shadow (position and connecting edges still visible, so the
  map's shape reads as a map) instead of its real kind, id, and
  description — tapping it explains it hasn't been discovered yet rather
  than opening the full node-info sheet. Edit Mode is unaffected and
  always sees the whole graph, same as every other authoring feature
  already gated to it. A new legend row explains the shadow style.
- `StoryPlayState.visitedNodeIds`, a monotonically-growing set backing
  this — persisted alongside the existing autosaved position/history, and
  backfilled from history for a save written before this feature existed
  so a returning player doesn't lose map progress they've actually made.

### Fixed
- `StoryPlayNotifier._persistAutosave` read `state` after an `await`,
  which could throw ("Tried to use StoryPlayNotifier after dispose") if
  the notifier was disposed while a fire-and-forget autosave was still in
  flight — a pre-existing latent race, made easy to hit by this batch's
  extra autosaved field. Now snapshots `state` synchronously before the
  first await instead.

## [1.101.0+129]

A quicker way to hand a reviewer (human or AI) your authoring notes without
sharing the whole repository.

### Added
- **JSON and CSV export for Review Comments.** The Review Comments screen's
  export button (Edit Mode → the notes left on story nodes while reading or
  testing) now offers a format picker — plain text as before, plus a
  compact JSON array and a CSV file, each just `id`/`chapter`/`comment` per
  commented node. Meant to be pasted straight into a prompt when a repo
  link isn't the easiest way to hand someone your notes.

### Changed
- Extracted the Review Comments export formatters into
  `lib/utils/comment_export_format.dart`, shared by the screen and now
  covered by dedicated unit tests independent of the widget tree.

## [1.100.0+128]

A follow-up balance pass on the last two updates: endgame gear is reachable
again, `kroll_the_branded`'s signature move is no longer a stun-lock trap,
achievement copy matches the current roster, and the playthrough simulator
finally models Wisdom and status effects — which is what surfaced the real
size of kroll's problem in the first place.

### Changed
- **Endgame sword/spear requirements loosened.** Tier 8-10 swords and spears
  required Strength 10-14 plus Constitution 4-8 — thresholds high enough
  that a normally-leveled character could reach the late chapters without
  ever qualifying for their own tier of gear. Now Strength 6/7/8 with only a
  small Constitution add-on at t9-10 (2/3); t4-7 unchanged.
- **`kroll_the_branded` rebalanced twice this batch**, once before and once
  after extending the simulator (see Fixed below): `maxHealth` 196 → 145,
  `damage` 24 → 19. Its signature move, Radiant Judgment, inflicts Stun on
  top of a heavy hit — `damageMultiplier` 1.4 → 1.2 and trigger `chance`
  35 → 18, so the stun-then-big-hit combo is rarer and less punishing when
  it lands, rather than the near-guaranteed spiral it was.
- **`plague_hound` trimmed to its actual weight class**: `maxHealth` 239 →
  205, `damage` 28 → 24 (matching `rat_matriarch`/`smuggler_captain`, the
  next enemies down), and its Poison-inflicting bite's trigger chance
  45% → 33% — it had drifted well above its chapter-2 peers.
- **`full_roster`/`full_party` achievement copy corrected** to match the
  current 6-companion roster and 2-active-ally party cap: "Three's
  Company" → "Full House" ("Recruit all three companions" → "all six"),
  and "Field a full 3-member active party" → "Field two active companions
  at once."

### Fixed
- **The (non-shipping) Python playthrough simulator never modeled Wisdom's
  combat role or status effects** (Poison/Stun/Weaken), even though both
  have been live in the shipped game since v1.98.0 — every simulation
  batch since then was blind to them. Fixed: the simulator now ticks
  Poison, skips a Stunned combatant's round, applies Weaken to a
  combatant's own outgoing damage, and gives Wisdom its real heal-bonus
  and status-resistance effect, turn-for-turn matching
  `_startPartyRound`/`_confirmRoll`/`_takeEnemyTurn` in `fight_screen.dart`.
  This immediately surfaced that `kroll_the_branded`'s Stun move made it a
  genuine outlier (a ~36% true win rate, invisible to every earlier,
  status-blind simulation) — the deeper kroll rebalance above is a direct
  result of this fix.

Re-simulated after this batch: 85.7% combat win rate, no enemy below a 50%
win rate (down from `kroll_the_branded` at ~36% once status effects were
actually counted), 100% true-ending rate across 40 runs, and
`boss_balance_test.dart` still passes unchanged.

## [1.99.0+127]

Real pixel-art icons for every item, skill, enemy, and shop, replacing the
generic Material glyphs that stood in for them since launch.

### Added
- **170 procedurally-generated pixel-art icons** (16x16, upscaled with
  crisp-pixel rendering) covering all 63 items, 79 skills, 18 enemies, and
  10 shops -- full 1:1 coverage with the current game data, verified by a
  new coverage test. Wired into every place a player actually sees one of
  these by its own identity: the Inventory/Equipment screen (equipped
  slots, item list, item-picker sheet, detail dialog), shop stock lists,
  the Skills screen (list rows and detail dialog), the race/profession
  skill preview during character creation, the Fight screen's enemy
  portrait, and the Boutiques/basic-shops lists in Camp and Town Hub. Falls
  back to the existing generic icon for any id without a matching asset
  (defensive, not expected to trigger today).

## [1.98.0+126]

Wisdom finally does something in a fight, status effects show up more often,
and combat is meaningfully harder across the first three chapters.

### Added
- **Wisdom's combat role.** Beyond backing Wisdom story checks, it now
  amplifies every point healed (by `wisdom ÷ 2`, both dice-face Heal and
  healing Skill faces) and shortens the duration of Poison/Stun/Weaken
  landed on you by 1 round per 5 points, never below 1 round. Applies to
  active allies too, derived from their own race/profession the same way
  Strength/Dexterity/Constitution/Intelligence already were.
- **7 more status-inflicting skills** (up from 7 to 14 of 79): Rogue's
  Poison Blade now actually poisons, Mage's Frost Nova and Orc's Savage
  Cleave inflict Weaken, and Ranger's Trap Set plus 3 elemental enemy moves
  (Frigid Grip, Molten Backlash, Radiant Judgment) inflict Stun/Weaken —
  status effects show up in noticeably more fights.

### Changed
- **Harder combat in Chapters 1-3.** Enemy health and damage scale up by
  chapter (+15% in Ch1, +35% in Ch2, +10% in Ch3), pulling the overall
  combat win rate down from ~95% to ~87% and roguelike-style "close calls"
  (lost fights — permadeath is off by default, so these cost time, not the
  run) up to an average of 3 per playthrough. Chapters 4-5 are intentionally
  left alone: an existing regression test (`boss_balance_test.dart`) locks
  in win-rate floors for 3 late-game bosses that a prior session already
  found could become unwinnable, and that ceiling is the reason overall
  difficulty stops short of an even harder target.

### Fixed
- The playthrough simulator never actually visited Camp's own Expedition
  zones (chapter 3 onward) — only Town Hub's chapter-2 zones were ever
  driven, so `z_cinder_row`/`z_scaffold_yards` always showed 0 attempts in
  every prior simulation batch. Fixed in the (non-shipping) Python
  simulator only.

## [1.97.0+125]

Three new camp buildings that finally give endgame gear somewhere to be
bought, and loot that leans toward what your profession actually wants.

### Added
- **Three new camp houses: Hammersmith, Academy, and Sharpweave Den.** Each
  is buildable from Camp for 350 gold and, on completion, immediately
  unlocks a themed shop — the Hammersmith's Forge (swords/spears/shields),
  the Arcane Academy (staves), and the Sharpweave Den (daggers) — stocking
  tier 6-10 gear that was previously only obtainable as loot, quest, or zone
  rewards and had no purchasable source anywhere in the game. Built houses
  now show an "Unlocks: ..." line alongside their existing stats, and Camp
  gained a new Boutiques section listing every shop a built house has
  opened, reusing the same shop-browsing screen as Town Hub.
- **Profession loot affinity.** Every profession now favors one ability
  score's gear (Warrior → Strength, Mage → Intelligence, Rogue/Ranger →
  Dexterity; Cleric has none, since Wisdom has no gear-scaling tie-in) via a
  new `preferredScalingStat` field. A combat loot roll for an item whose own
  `scalingStat` matches gets a flat +20 percentage-point bump on top of the
  existing luck bonus — a Mage sees noticeably more staves off the same
  enemy a Warrior would fight, without any single drop ever becoming
  guaranteed.

## [1.96.0+124]

Gear that actually cares who's wielding it: weapons now scale with your
ability scores, and the heaviest ones require enough of them to wield at all.

### Added
- **Ability-score weapon/shield scaling.** Every sword, spear, dagger,
  staff, and shield now declares which ability score it scales with
  (Strength for sword/spear, Dexterity for dagger, Intelligence for staff,
  Constitution for shield), adding `stat ~/ 2` on top of its flat
  attackDamage (or armor, for shields) — a Mage's staff hits harder with
  Intelligence, a Warrior's sword with Strength, without any profession-
  specific code: the effect is entirely driven by which weapon type is
  equipped. Never subtracts below an item's flat value, so an off-build
  weapon just doesn't reach its full potential. Applies to allies' own
  equipment too, scaled off their race/profession-derived scores.
- **Stat-gated equipment requirements.** The heaviest three tiers of every
  sword and spear now require both Strength and Constitution to equip (a
  "heavy sword" needs the power to swing it and the stamina to keep
  swinging); daggers, staves, and shields scale their own single-stat
  requirement up through their tiers. Early-tier gear (t1-t3) stays
  unrestricted so no build is locked out of basic equipment. The
  Inventory/Equipment screen shows a lock icon and a "Requires: N STR, M
  CON"-style note on anything not yet met, for both the player and any
  ally.
- Updated the four ability-score stat-hold explanations (Strength,
  Dexterity, Constitution, Intelligence) to mention their new gear tie-in.

## [1.95.0+123]

Hold a stat to see what it does.

### Added
- **Long-press stat explanations.** Every core stat row (Health, Base
  Damage, Base Armor, Luck, Charisma, Strength, Dexterity, Constitution,
  Intelligence, Wisdom) on the character sheet (`RaceProfessionScreen`) and
  the level-up screen (`LevelUpScreen`) can now be held to pop up its
  purpose and gameplay impact, reusing the existing `*_desc` strings so the
  two screens' explanations never drift apart. The level-up screen's
  existing tap-the-icon shortcut still works alongside it.
- A small hint ("Hold a stat to see what it does") on both screens so the
  new interaction is discoverable.

## [1.94.0+122]

A reviewer-comment system for story nodes: leave a private note while
reading/testing in Edit Mode, then find every note again in one place.

### Added
- **Reviewer comments on story nodes.** The node editor (`StoryNodeEditorScreen`)
  has a new "Reviewer comment" field, saved on `StoryNode.authoringComment` —
  a free-text note never shown to players, for things like "pacing feels
  rushed here" or "needs a 3rd choice". Persists through the same local
  edit-override mechanism every other node edit already uses.
- **Review Comments screen**, reached from the Data tab: lists every node
  with a comment (id, chapter, comment text), tap to jump straight into
  that node's editor, plus Copy/Export actions (reusing a newly-extracted
  `lib/utils/export_utils.dart`) so the whole list can be pulled off the
  device as plain text.
- The Map (story graph) view now marks commented nodes with a small badge,
  and its node-info sheet shows the comment inline plus a new "Edit Node"
  button, so a comment is discoverable without leaving the graph.

### Known issue (pre-existing, not touched here)
- While live-verifying this feature, found the choice editor's "destination
  node" dropdown overflows at phone width — unrelated to this change, left
  as-is; flagged for a follow-up fix.

## [1.93.0+121]

Over-branched story nodes (10-12 choices piled into one flat button list)
now present like a village instead of a wall of text.

### Changed
- **Nodes with more than 5 choices** (currently 2010, 2015, 3005) now split
  their non-core choices — shops, fights/skill checks, and people to talk
  to — into categorized "Shops" / "Challenges" / "People" sections with a
  Rest option, rendered as icon-led cards below the node's own main
  branches, instead of one long list of identical-looking buttons. Nodes
  with 5 or fewer choices are unchanged. All existing choice logic (ability
  checks, combat, unlocks, routing) is shared via one extracted function,
  so the new cards behave exactly like the buttons they replace.

## [1.92.0+120]

Chapter 1 follow-up to the Town Hub/Camp redesign: two of Chapter 1's own
shop unlocks turned out to duplicate Town Hub's now-permanent boutique list,
undercutting "Town Hub is the first shopping stop between Chapter 1 and 2."

### Fixed
- **Removed two Chapter 1 shop unlocks that now duplicate Town Hub's
  permanent boutiques.** Node 100 (the opening tavern scene) no longer
  unlocks the Blind Beggar Stall, and node 891 (the pre-boss docks scene) no
  longer unlocks the Weaponsmith's Forge — both are already always available
  at Town Hub from the Chapter 1/2 seam, so granting them again mid-Chapter-1
  was redundant and made the boutiques feel like they "arrived too early."
  Node 891's other two shop unlocks (Black Market Docks, Shieldwright's
  Hall) are untouched: neither is part of Town Hub's curated list, and
  neither has any other unlock point in the story graph, so removing them
  would have made those shops permanently unobtainable.



Reshapes the mid-game meta-progression loop so Town Hub and Camp read as two
distinct, sequential stops rather than one thing available from the start
and another available from the very first chapter.

### Changed
- **Town Hub is genuinely "the first stop between Chapter 1 and 2"** now
  that it has more than two shops: added Apothecary Row to its permanent
  boutique list (alongside the Blind Beggar Stall and the Weaponsmith's
  Forge). Its unlock point was already exactly this seam
  (`chapterOfNode >= 2`, flipping the moment Chapter 2's opening node
  fires) — this was a content gap, not a gating one.
- **Camp is now discovered at the start of Chapter 3**, not available from
  the very first minute of a new game. `PlayScreen`'s Camp entry mirrors
  Town Hub's own lock/subtitle treatment, unlocking once
  `chapterOfNode >= 3`.
- **A freshly recruited companion now joins the active party immediately**
  (up to capacity, respecting their own house gate if they have one) —
  `recruitAlly` no longer requires a trip to Camp to actually help in a
  fight. Needed once Camp stopped being available from turn one: Kelda,
  Sable, and Liora all recruit in Chapter 2, before Camp exists.
- **Camp becomes the second expedition hub, picking up where Town Hub
  leaves off.** Camp's Roster/Houses now sit above a new Zones section
  showing every zone from Chapter 3 onward (two new ones: Cinder Row and
  the Scaffold Yards, `ashenStreets`-themed, dropping gold and the new
  `plate_emberproof` armor respectively) — forward-compatible with future
  chapters' zones without further wiring.

### Added
- **A quiet payoff for actually doing Town Hub's expeditions**: completing
  Fisherman's Row and Tanner's Court (2 of Town Hub's 3 zones) now marks
  the Rusty Eel's hull patched and sail mended. At Chapter 2's close (node
  `2900`, the approach to the Upper Gate), a new choice lets the player
  check on the ship one last time and see it seaworthy again — locked with
  in-character flavor text if they never got around to it. Deliberately a
  narrative acknowledgment, not a hard requirement: skipping every
  expedition still lets the story continue exactly as before, just without
  that beat.
- `partyCapacityFor` (`player_session_provider.dart`), extracted out of
  `CampScreen` so its own roster capacity math and `recruitAlly`'s new
  auto-activate logic can never drift apart.

## [1.90.0+118]

Elements go from flavor text to a real combat layer, and last patch's
status-effect system gets a wider footprint across skills, companions, and
items.

### Added
- **Elemental damage/resistance, finally wired up.** `items.json` has
  carried per-element `<element>DmgBonus`/`<element>Resist` fields (and a
  fully-authored Fire→Wind→Earth→Water→Electricity staff progression) since
  early in this project, completely unread by combat. `resolvePlayerFace`
  and `resolveEnemyMove` now both apply them: a party member's outgoing
  Attack/Skill damage is boosted by their gear's matching element bonus (the
  element comes from the skill's own `element` field for Skill faces, the
  die face's own for Attack faces), and an enemy move's damage is cut by the
  target's matching resist gear the same way armor and block already are.
- **Two new elements: Ice and Light.** Added to `elementOptions` alongside
  Fire/Wind/Earth/Water/Electricity/Void, with their own `iceDmgBonus`/
  `iceResist`/`lightDmgBonus`/`lightResist` item fields (Void picked up the
  matching `voidDmgBonus`/`voidResist` pair too, completing `void_banner`'s
  existing all-elements bonus).
- **`OnHitByElement` is a real condition now.** `skillMoveConditionOptions`
  has listed it since enemy moves first shipped; it always evaluated to
  false. `FightScreen` now tracks which elements the party actually hit the
  enemy with each round and feeds it to `resolveEnemyMove`, so a move can
  react to it — `iron_golem` now shrugs off Fire and flings it right back
  (`molten_backlash`, a real reason to *not* bring fire against a golem).
- **New elemental content:** `frigid_grip` (Ice) for the docks' Overseer
  Renn, `radiant_judgment` (Light) for Inquisitor Kroll, plus three new
  elemental-gear drops (`plate_emberproof`, `cloak_frostward`,
  `circlet_radiance`).
- **Status effects reach further.** Three more signature skills now inflict
  one: `warrior_shield_bash` (Stun — a shield bash staggers), `rogue_backstab`
  (Weaken — thrown off balance), and `voidkin_entropy_touch` (Poison —
  unraveling flesh, matching last patch's "void corruption" pitch).
- **A cure for them, too.** New `antidoteCount` resource (mirrors
  `potionCount`'s plumbing exactly) and `consumeAntidote()` clear every
  active Poison/Stun/Weaken off the player. A new Antidote button appears in
  `FightScreen` whenever the player actually has something to cure; a new
  `antidote` item drops from Plague Hounds.

## [1.89.0+117]

Combat gets a status-effect system: Poison, Stun, and Weaken now exist as
real, persistent afflictions rather than one-off numbers, on both sides of a
fight.

### Added
- **Poison/Stun/Weaken status effects.** New `lib/combat/status_effect.dart`
  holds the pure model (`StatusEffect`, `applyStatusEffect`,
  `poisonDamageFor`, `isStunned`, `applyWeaken`, `tickStatusEffects`) and
  `FightScreen` wires it into the party's simultaneous-round turn loop:
  Poison ticks flat damage at the start of the afflicted side's round,
  Stun excludes a combatant from acting that round (with the whole party
  round auto-skipped straight to the enemy's turn if everyone able to act
  is stunned, rather than stalling on a roll nobody can make), and Weaken
  cuts the afflicted combatant's own outgoing damage for its duration.
  A new row of small chips under each health bar (party and enemy) shows
  every active effect with its remaining rounds.
- **Skills and enemy moves can inflict them.** `skills.json` records gained
  optional `inflictsStatus`/`statusDuration`/`statusMagnitude` fields, read
  by both `resolvePlayerFace` (Skill faces) and `resolveEnemyMove` (enemy
  `skillMoves`, via the same referenced skill record) in
  `combat_engine.dart`. Wired into real content: the player's existing
  `venomous_ambush` merge-skill now actually poisons on hit (matching its
  "the wound that doesn't stop" flavor text), a new `plague_bite` gives
  Plague Hounds their disease bite, and two new Void-flavored abilities —
  `void_drain` (Weaken) and `disorienting_pulse` (Stun) — round out Void
  Stalkers and the Void Manifestation boss.

### Changed
- `resolvePlayerFace`/`resolveEnemyMove` take an optional `activeEffects`
  parameter so a Weakened attacker's damage is correct in both the
  resolved number and its preview/log message, not just applied
  after the fact.

## [1.88.0+116]

Interface diversity, this time: the story graph has tagged every node with
its setting (`context_taxonomy.ui_theme` — docks, cathedral, slums,
catacombs, sewers, torture chamber...) since the very first version of this
app, but that field only ever picked which flavor pool random excursions
drew from. The reading screen itself always looked identical no matter
where the player was.

### Added
- **Location-based accent theming on the story reading screen.** Eight
  settings with real narrative weight — docks, cathedral, torture chamber,
  slums, catacombs, sewers, and the two ending flavors (origin_ending,
  epilogue) — now shift the prose card's border, header color, and a faint
  background tint to match, plus a light typographic nudge (letter-spacing,
  line height) for a few of them: tighter and quicker through interrogation
  scenes, slower and heavier through the catacombs and sewers. The
  remaining, rarer settings (bridge, market, hovel, gate, prologue,
  battlements — each under 5 nodes) are left exactly as they were.
  Deliberately layered on top of the player's own selectable app palette
  (Settings → 7 color options) rather than replacing it: only this one
  card's colors move, never the app's chrome, navigation, or any other
  screen. New `lib/data/ui_theme_palettes.dart` holds the per-location
  palette data and a pure `resolveUiAccent` blending function — accent
  hues are blended into the scheme's own `onSurface`/`outlineVariant`
  colors (not used raw) so every location stays legible in both light and
  dark mode and against all 7 base palettes, verified with unit tests
  checking luminance in both directions.

## [1.87.0+115]

Gameplay diversity, as opposed to the last two entries' narrative/world
content: a genuinely new non-combat interaction type, not just another
single ability-check roll.

### Added
- **Skill Challenges: a new multi-round "push your luck" mechanic**, distinct
  from both a one-shot ability check (a single roll settles it) and full
  combat (health, dice faces, an enemy). A skill challenge is a sequence of
  rolls against the same ability and DC, won by reaching a set number of
  successes before a set number of failures — an early bad roll doesn't end
  the attempt, it just narrows the margin, which is the whole point of
  offering it as its own thing. Implemented as two new optional fields on a
  story choice (`challengeSuccessesNeeded`/`challengeMaxFailures`, alongside
  the existing `checkAbility`/`checkDC`/`failNextId`) resolved by a new pure,
  independently-testable function (`lib/data/skill_challenge.dart`) and
  presented through a new dedicated screen
  (`lib/screens/skill_challenge_screen.dart`) that reveals each round in
  turn with a running success/failure tally before the final result — pushed
  and popped the same way the combat screen reports a win. Added editor
  support for the two new fields alongside the existing ability-check editor
  UI, so more of this content can be authored later.
- **First real use: a card game at the Chapter 2 harbor market** (new choice
  on node `2015`, "Sit in on a card game with dock regulars"). Win 3 hands
  before 2 losses (a Luck-based skill challenge, DC 12) for a solid payout;
  lose the challenge and it costs a little instead — either way, the story
  continues normally.

## [1.86.0+114]

Second round of narrative/world diversity content, this time in Chapter 3:
a population the story had repeatedly referenced as backstory (the
Inquisition's slum purge, mentioned at nodes `100`/`3001` and named as the
High Warden's crime in `q_ch3_the_high_wardens_fall`) but never gave real
presence to.

### Added
- **The Reckoning Wall, a new Chapter 3 location, and its side quest.**
  Reached via a new choice on the Ashen Quarter hub (node `3005`), the wall
  is where purge survivors — led by a woman named Reya — chalk the names of
  everyone the Inquisition's official record insists simply "relocated," a
  counter-record to the same erasure already running through this chapter's
  Hall of Records content. An Inquisition auxiliary (a new
  `inquisition_auxiliary` enemy) is sent to burn the wall before it becomes
  evidence. Players can talk him down with a DC 13 Intelligence check —
  quoting Inquisition procedure back at him, deliberately a different stat
  and angle than Tern Row's Charisma-based resolution — for a no-combat
  outcome (25 gold, +5 alignment, its own flag), or fight him directly,
  which registers the formal quest (`q_ch3_reckoning_wall`, 50 gold/60 XP/+5
  alignment on completion). Failing the check still leads to the fight
  rather than a dead end, same pattern as Tern Row.

## [1.85.0+113]

Acted on a full Chapter 1-2 audit: one game-breaking bug fixed, two smaller
balance/continuity issues cleaned up, plus a requested change moving the
chapter's first shop access next to its boss fight. (One audit finding —
`rat_matriarch`/`kroll_the_branded` tagged `minChapter: 2` despite fighting
in Chapter 1 — turned out to be correct as shipped: that field only gates
the *random* excursion pool, not their scripted story fights, and was
deliberately set that way in a previous pass to keep Chapter 1's random
encounters safe. Left unchanged. Also skipped a purely cosmetic finding —
missing `npcs.json` entries for Kelda/Sable/Liora — since nothing currently
reads that data for them and adding unused records isn't worth the churn.)

### Fixed
- **Vess's questline (`q_ch1_vess_in_the_dark`) was permanently
  unreachable.** Node `151_vess` requires the `void_marked` flag, but the
  only choice that ever sets it (`281_scarred`, reached by *failing* the
  luck check at the Tear) routed straight past the market stall that leads
  to her — no playthrough could ever satisfy the gate. `281_scarred`'s
  "Continue" now routes through node `151` first, so a void-marked player
  can actually find her. Added a permanent regression test
  (`test/story_graph_integrity_test.dart`) that walks every path from the
  start node tracking which flags are set along the way, since the
  existing integrity check deliberately ignores `reqFlags` gating and
  wouldn't have caught this.
- **Failing the Chapter 2 "read the crowd for an informant" Wisdom check
  landed the player on the *aftermath* text for a plague-hound fight they
  never actually had.** `failNextId` jumps straight to a node, skipping
  combat entirely — so the old target (`2015_hound`, the hardest fight at
  that hub) played as pure narration of a win that never happened. Added a
  proper failure node (`2015_informant_caught`) with its own light,
  appropriately-scaled consequence (a real `street_bandit` fight).
- Reworded node `2030`'s arrival text at Vane's, which assumed "whatever
  I'd brought him" — a real mismatch for the newer branches (Kelda, Sable,
  Tern Row) where nothing was physically brought. Now frames it as Vane
  having heard about the player's evening generally, which fits every
  incoming path.

### Changed
- **Moved the Chapter 1 market's first shop access to node `891`**, the
  single node every Chapter 1 branch (Surrender or Unfurl the Bundle)
  passes through immediately before the boss fight — previously it only
  lived at node `151`, an optional detour skippable outright by two of the
  three choices at the node before it, so a real playthrough had no
  guarantee of ever seeing a shop before Chapter 1's climax. Also added an
  explicit heal choice at the same node, so a player who took the harsher
  Surrender branch (which stacks two unhealed fights) isn't forced into
  the boss below full health while the Bundle branch always was.

## [1.84.0+112]

Added narrative/world content: a new dockside location and side quest
giving real presence to a population the story had only ever mentioned in
passing.

### Added
- **Tern Row, a new Chapter 2 location, and its side quest "Tern's
  Toll."** `Liora's Watch` has always referenced smuggler-run "refugee
  boats," but the refugees themselves never appeared as people — Tern Row
  fixes that: a quarter of the Tide-Kin, seafaring refugees from the
  Drowned Isles, with their own funerary custom of setting lit paper boats
  adrift at dusk. Reached via a new choice on the harbor hub (node
  `2015`), the quarter's organizer, Nadira, explains that an Inquisition
  customs officer (Overseer Renn, a new `dock_overseer` enemy) is
  extorting the quarter with an invented "landing toll" and threats of
  deportation. Players can talk him down with a DC 13 Charisma check for a
  no-combat resolution (20 gold, +5 alignment, its own flag), or refuse
  and fight him directly, which registers the formal quest
  (`q_ch2_terns_toll`, 40 gold/45 XP/+5 alignment on completion). Either
  way, failing the talk-down still leads to the fight rather than a dead
  end.

## [1.83.0+111]

Follow-up to a question about whether an NPC could actually mislead or trap
the player: it turned out the narrative engine already had every piece
needed (ability checks, `triggerEnemyId`, branching), but no NPC in the
story graph actually used them that way. Added a real example.

### Added
- **The Chapter 2 harbor informant (node `2015_informant`) can now genuinely
  set you up.** Trusting him outright — or trying to see through him and
  failing a DC 12 Wisdom check — routes into a new node
  (`2015_informant_trap`) where his "associates" spring an ambush
  (`street_bandit`) the moment you go looking for the warden he named.
  Catching the lie on a successful Wisdom check instead routes to
  `2015_informant_exposed`: no fight, and he pays out 15 gold for your
  discretion. The quest (`q_ch2_informants_tip`) still unlocks either way —
  only whether you walk into the ambush changes.

## [1.82.0+110]

Correction to the previous entry: "Slum Thug — cleared, not the culprit" was
only true for the diagnostic's own hand-rolled combat loop, which always
modeled a properly created character. It never actually exercised the real
in-app autoplay tools those bosses were investigated with, and a real
in-app **Play to Chapter** run hit exactly the "stuck against slum_thug"
failure the earlier investigation had ruled out — caught from a player's own
screenshot of that failure.

### Fixed
- **Autoplay (`Play to Chapter` and the map's node/chapter jump) lost every
  single fight when starting from a brand-new game, reporting "stuck"
  against whichever enemy happened to be first on the path — Slum Thug in
  the reported case, but any enemy would have triggered it.** Root cause:
  `autoplayToNode`/`autoplayToChapter` (`lib/data/autoplay_engine.dart`)
  walked straight through the story's character-creation choice (node 0's
  "Choose who you are...") like any other choice, without ever calling
  `PlayerSessionNotifier.startNewGame(...)` — unlike the real story player
  screen, which special-cases that choice. The simulated session was left
  with no race, profession, or equipped die, so `_simulateFight`'s die-face
  lookup came back empty and every combat auto-lost, exhausting all retries
  against the first fight on the walked path. Fixed by handling
  `StoryChoice.opensCharacterCreation` the same way the real player flow
  does: autoplay now picks a random race/profession and starts a real game
  the moment it walks through that choice, mirroring the "Randomize"
  convenience already on the race/profession picker. Added a regression
  test (`test/autoplay_engine_test.dart`) that drives a real
  `autoplayToChapter` run from a fresh session and asserts it doesn't get
  stuck on its first fight.

## [1.81.0+109]

Investigated a "speedrun" playthrough to see how far the fastest route
through the story could actually get, which surfaced a real problem: three
late-game bosses were effectively unwinnable for a normal (non-optimal,
non-party-boosted) character, hard-blocking the story at three separate
points. Diagnosed with a proper simulation (30 full playthroughs, real
combat resolution, correctly modeling that a lost story fight blocks
progress and must be retried) rather than guesswork — also used the same
diagnostic to check an unrelated report that Slum Thug was blocking
progress, and cleared it: 33 encounters, 100% first-attempt win rate,
not the culprit.

### Fixed
- **Inquisition High Warden (Ch3), Hollow Court Zealot (Ch4), and Void
  Manifestation (Ch5, the climax) were near-unwinnable walls.** The
  diagnostic simulation showed a normal playthrough needed an average of
  93, 176, and **249** retry attempts respectively to clear these three —
  Void Manifestation regularly hit the 300-attempt cap outright (a genuine
  soft-lock). Root cause: `scaledMaxHealth`/`scaledDamage` scale *every*
  enemy's stats up with player level, but these three had such a high base
  that the scaling compounded faster than a character's own (linear,
  stat-point-driven) growth could keep pace — checked directly, win rate
  against Void Manifestation barely moved between level 3 and level 10
  (0% → 7%), so grinding wasn't a real way past it either.
  Reduced each boss's base stats (found via a win-rate search targeting
  ~30-50% for a solo, unassisted character at the level a normal
  playthrough actually reaches them):
  - Inquisition High Warden: 200hp/23dmg → 150hp/17dmg (~47% win rate at
    level 3)
  - Hollow Court Zealot: 218hp/25dmg → 142hp/16dmg (~34% win rate at
    level 4)
  - Void Manifestation: 236hp/27dmg → 154hp/18dmg (~30% win rate at
    level 4, matching this fight's original "tough but fair" design
    intent) — and critically, this win rate now actually **rises with
    level** (~30% → 40% → 64% → 75% from level 4 to 8), so a player who
    grinds a bit more before attempting the climax is meaningfully
    rewarded for it, instead of hitting a wall that doesn't move no
    matter how strong they get.

Added `test/boss_balance_test.dart`, a permanent regression test asserting
each boss's win rate stays in a healthy band (catches both a regression
back toward the old unwinnable stats and an over-correction that makes the
fight trivial), and confirming Void Manifestation's win rate keeps rising
with level.

## [1.80.0+108]

Balanced difficulty across the early chapters so Chapter 1 reads as the
safe tutorial it's meant to be, and Chapter 2's roguelike expeditions are
where real death risk actually starts — before the escalation continues
into Chapter 3 and beyond.

### Fixed
- **Expeditions could roll any enemy in the game, with zero chapter
  gating.** `ExpeditionScreen._rollEvent` built its enemy pool from every
  entry in `enemies.json`, filtering only by "already fought" — unlike
  regular excursions, it never checked `minChapter`. A Chapter 2
  expedition (a level ~2 character) could randomly draw a Chapter 5
  endgame monster (236hp/27dmg) with no way to decline the fight and no
  way to win it. Extracted the excursion engine's existing chapter-gate
  logic into a new shared `SubNodeEngine.filterEnemyPool`, used by both
  excursions and expeditions now, so a zone's encounters are always
  capped to enemies that chapter's story has actually introduced.
- **Rat Matriarch and Inquisitor Kroll could ambush a brand-new
  character.** Both are scripted Chapter 1 story bosses fought near the
  chapter's end (nodes 850/855 and 955, right before the Chapter 1
  finale) — strong enough to be a real threat at that point — but were
  flagged `minChapter: 1`, making them eligible for a *random* Chapter 1
  excursion from the very first node. Bumped both to `minChapter: 2`:
  their scripted story fights are unaffected (main-path encounters never
  consult `minChapter`), but they can no longer ambush an early Chapter 1
  run, and they now also fold into Chapter 2's random pool — one more
  reason expeditions there feel noticeably more dangerous than the
  tutorial chapter that came before them.

Net effect: Chapter 1's random encounters are now capped at Inquisition
Warden (80hp/12dmg) — safe, teaches the mechanics, essentially unlosable
for a fresh character. Chapter 2's pool tops out around Plague Hound
(146hp/17dmg) and the now-included Kroll/Rat Matriarch (145/120hp,
18/15dmg) — a real chance of going down in an expedition's three-encounter
run, especially back-to-back with no healing between fights, exactly
where the "start to die a little" ramp should begin.

Added `test/sub_node_engine_test.dart` covering the shared chapter gate,
including the exact regression (a chapter-2 pool never contains a
chapter-5 enemy).

## [1.79.0+107]

Reworked the skill system to play like a roguelike build each run: skills
now level up in place, two skills can be fused into a new one, and dying
wipes the build back to class basics so every life is its own experiment.

### Added
- **Skill tiers** — any unlocked skill can be upgraded up to 3 times,
  each tier adding +25% to its damage/heal numbers and +0.1 to its damage
  multiplier (`combat_engine.dart`'s new `applySkillTier`). Upgrades are
  applied live at combat-resolution time from a per-player tier map, never
  by mutating the shared skills database (enemies read from that same
  table via their own skill references).
- **Skill Essence** — a new resource earned 1:1 alongside XP from combat
  wins and quest completions, spent to buy tiers (rising cost: 3/6/9
  essence per tier). Shown next to Skill Points at the top of the Skills
  screen.
- **Merging skills** — a new "Craft a Skill" button on the Skills screen
  opens a recipe list (`assets/gamedata/skill_merges.json`) of two-skill
  fusions; picking a ready recipe consumes both input skills and unlocks a
  new, more powerful hybrid in their place. Six recipes ship with this
  release: Blazing Shadow, Unbreakable Will, Bastion of Stone, Arcane
  Convergence, Venomous Ambush, and Wrath of Dawn — each crafted from two
  existing race/profession or starter skills.
- **Skills reset on death** — permadeath now wipes the skill build back to
  exactly what a fresh character would have (the race and profession's
  own standard skill, wired onto the starter die), clearing every other
  unlocked skill, all tier progress, and skill essence, and refunding
  skill points back to the profession's starting amount. Level, gold,
  stats, owned dice, and story progress are untouched — only the skill
  build itself restarts, so each life is a genuinely new roguelike run.
  The death screen now shows how many skills were lost in the reset.

## [1.78.0+106]

The Level Up popup was unreadable on narrow phone screens — stat labels like
"Damage" and "Armor" were being split mid-word ("Dam"/"age", "Armo"/"r")
because the dialog's default insets plus a wide leading icon and trailing
button left almost no room for the label text. Also adds tap-to-learn stat
descriptions, previously only implicitly understood from context.

### Fixed
- **Level Up modal readability on mobile** — rebuilt each stat row's layout
  in `level_up_dialog.dart` with a tighter, width-budgeted `Row`
  (smaller icon avatar, single-line label, compact `+1 Point` button) and
  added explicit `insetPadding`/`contentPadding` overrides to the
  `AlertDialog`, so labels render on one line instead of wrapping mid-word
  on narrow viewports. Verified numerically via a widget test measuring
  rendered text height at 412px and 360px simulated screen widths.

### Added
- **Stat descriptions on tap** — tapping a stat's icon on either the Level
  Up modal or the full-screen Level Up tab now opens a short description of
  what that stat actually does in-game (e.g. Luck improves post-fight loot
  odds, Strength/Dexterity/Constitution/Intelligence/Wisdom back their
  respective story-choice ability checks, Charisma opens persuasion-gated
  dialogue), reusing the existing `showDetailDialog` helper. All ten
  descriptions are localized in English and French.

## [1.77.0+105]

Three new recruitable companions, each gated behind a different kind of
requirement — so which allies a playthrough can actually reach depends on
the build and the choices that got it there, not just on finding the right
hub node.

### Added
- **Liora** (Elf Ranger) — a wary rooftop archer at the Chapter 2 harbor
  hub (node `2010`), who only comes down if you can talk your way past her
  (`reqCharisma: 3`). Signature die: `liora_die` (aimed shots, evasive
  steps, `ranger_aimed_shot`/`ranger_beast_bond`).
- **Vess** (Voidkin Mage) — a fellow void-marked stranger at the Chapter 1
  market hub (node `151`), reachable only by players carrying the
  `void_marked` flag from a failed Luck check at the Tear (node `280`) —
  a direct consequence chain from an earlier round's content, not a new
  gate type in isolation. Signature die: `vess_die` (void/arcane, `mage_arcane_missile`,
  `voidkin_umbral_veil`/`voidkin_entropy_touch`).
- **Grosh** (Orc Warrior) — a mercenary at the Chapter 3 Ashen Quarter hub
  (node `3005`) who only takes clients who look like they can pay
  (`reqGold: 80`). Signature die: `grosh_die` (`orc_berserk_rage`,
  `warrior_shield_bash`).

  Each ships with its own recruit quest (`q_ch2_lioras_watch`,
  `q_ch1_vess_in_the_dark`, `q_ch3_groshs_price`) and bridge node, following
  the exact pattern Kelda/Sable/Maren established — no new mechanics, just
  new data reusing `reqCharisma`/`reqFlags`/`reqGold` node gating and the
  existing companion/signature-die/recruit-quest schema.

## [1.76.0+104]

Five new build-specific interactions and a new quest, so every one of the
six core stats (plus Luck) now has at least one real moment where it
changes what happens — reinforcing that a playthrough's build determines
what it can actually do, not just how hard it hits in combat.

### Added
- **Five new ability checks**, each exercising a stat that had no story
  moment of its own yet:
  - **Luck** — the Chapter 1 "Touch the Tear" choice was flavor-text only
    (labeled "Luck Check" but never actually rolled); it now rolls for
    real (DC 10), with a new failure scene (`281_scarred`) for a bad roll.
  - **Strength** (DC 13, Chapter 2 harbor) — force a jammed loading crane
    open for bonus gold, or fail and draw Vane's crossbow.
  - **Constitution** (DC 12, Chapter 1 market) — push through a
    smoke-choked forge to find a stashed cache.
  - **Wisdom** (DC 13, Chapter 2 harbor market) — read the crowd for an
    informant, unlocking the new quest below; fail and a plague hound
    notices you instead.
  - **Intelligence** (DC 13, Chapter 3 Ashen Quarter) — decipher scorched
    ledger fragments outside the archive for bonus gold and a flag; fail
    and a cultist acolyte notices you rifling through their things.

  `ability_check.dart`'s `abilityScoreKeys` now includes `luck` alongside
  the six D&D-style stats, reusing the exact same roll/DC/`failNextId`
  machinery already proven out by the Dexterity check from last round —
  every failure route reuses an existing sibling node instead of adding
  new dead ends.
- **New quest: The Informant's Tip** (`q_ch2_informants_tip`) — unlocked by
  the Wisdom check above, a bounty on a corrupt warden skimming smuggled
  goods.

## [1.75.1+103]

### Fixed
- **Story Map panning.** Removed the Edit Mode "Jump to Chapter" panel,
  which sat over the top-right corner of the map and silently swallowed
  any drag gesture that started on it — the likely cause of the map
  feeling unscrollable in that area. The map's `InteractiveViewer` always
  supported free pan/zoom in every direction; with the panel gone, nothing
  on screen blocks it anymore. (Jumping to a chapter is still available
  from the map by tapping a node and using "Jump to this node".)

## [1.75.0+102]

Sharper item/quest icons, and the first choices whose consequences reach past
their own scene: which companions you can recruit, and which skills you can
learn, now depend on who you've been so far.

### Added
- **Choice-driven build divergence.** Recruiting Kelda (the dwarf
  shieldbearer) now requires an alignment score of at least 2; recruiting
  Sable (the rogue) requires -2 or lower; recruiting Sister Maren requires
  having saved Lysa back in Chapter 1 (`lysa_survived`). All three use the
  existing node-level `reqAlignmentScore`/`reqAlignmentMax`/`reqFlags` gates,
  each with its own in-voice locked reason instead of a generic message. Two
  new signature skills, `zealous_conviction` (alignment ≥ 3) and
  `ruthless_edge` (alignment ≤ -3), extend the same idea to skills via new
  `requiredAlignmentMin`/`requiredAlignmentMax` fields on the skill schema,
  shown in the Skills screen as "Reserved: Good-aligned"/"Evil-aligned"
  alongside the existing race/profession restriction. The point: who you
  recruit and what you can learn is no longer available to every
  playthrough — it's shaped by the choices you already made.

### Changed
- **Item and quest icons are sharper.** Weapon items now render a
  sword/dagger/spear/staff/shield-specific icon instead of one generic
  glyph for the whole "Weapon" category (`itemIcon`), and quests render an
  icon for what their first objective actually asks — a fight, a fetch, or
  a conversation — instead of just their Main/Side category
  (`questIcon`), across Inventory, Shops, and the Quests tab.

## [1.74.0+101]

A D&D/Baldur's Gate 3-style ability check system: five new stats and a
dice-roll "attempt" mechanic for story choices, layered alongside last
round's flat Charisma gate rather than replacing it.

### Added
- **Strength, Dexterity, Constitution, Intelligence, and Wisdom** join
  Luck and Charisma as full character stats — derived at creation from
  `game_config.json` + race/profession bonuses (e.g. Dwarves run high
  Constitution, Mages run high Intelligence, Rogues run high Dexterity),
  spendable from the level-up dialog/screen, and editable from the debug
  stats panel like every other stat.
- **Ability checks on story choices.** `StoryChoice` gained
  `checkAbility`/`checkDC`/`failNextId`: tapping a checked choice rolls a
  d20 plus the matching stat against the DC (`lib/data/ability_check.dart`)
  and shows the roll in a themed popup before anything else happens — the
  BG3 "attempt" pattern, distinct from `reqCharisma`'s hard, deterministic
  gate. Success applies the choice's effects as normal; failure either
  routes to `failNextId` when the author set one, or continues to the same
  destination without the reward. Authorable from the Story Node Editor's
  choice panel, and the graph-integrity checker now walks `failNextId` too,
  so a check-only branch is neither flagged orphaned nor left unvalidated.
  Wired into a new optional choice at the Ashen Quarter hub (a Dexterity
  check to pick a sealed archive's lock) as a worked example.

## [1.73.0+100]

A round of new-mechanics requests: a proper celebration for leveling up,
two new stats with real gameplay teeth, and NPCs the player can actually
talk to.

### Added
- **Colored level-up dialog.** The plain gray "Level Up!" alert is now a
  gold-gradient trophy icon with a soft glow, a gold title, and each
  spendable stat given its own themed color (red damage, blue armor, pink
  health, purple luck, teal charisma) instead of identical gray rows.
- **Luck and Charisma stats.** Derived at character creation the same way
  as every other stat (`game_config.json` base + race bonus + profession
  bonus — e.g. Rogues run high luck, Clerics and Humans run high
  charisma), spendable from the level-up dialog/screen alongside Damage,
  Armor, and Health.
  - **Luck** boosts the drop-rate roll on combat loot directly (in
    percentage points), so a lucky character sees noticeably better item
    drops.
  - **Charisma** gates story content: `StoryNode` gained a `reqCharisma`
    requirement (checked in `PlayerSession.meetsRequirements` alongside
    the existing reqGold/reqAlignment/reqFlags), authorable from the
    Story Node Editor like every other requirement, for
    persuasion-flavored choices a low-charisma character can't take.
- **NPCs you can talk to.** A new `npcs.json`/`npcsSchema` (three NPCs to
  start: a returning companion from the opening chapter, and two flavor
  encounters), surfaced as a new NPCs section in the Play tab —
  flag-gated the same way node requirements already are, so an NPC can be
  tied to a story event before they're discoverable. Tapping one opens a
  simple conversation screen (description + a few flavor lines) with a
  Talk button that records the conversation
  (`PlayerSession.talkedToNpcIds`). Quests' existing `Talk`-type
  objectives (previously always auto-met, with nothing to actually check)
  now gate on a new `targetNPCID` field against that record when one is
  set — wired end-to-end for one real quest (`q_ch3_alsters_dawn`) as a
  worked example, with older/other Talk objectives left ungated exactly
  as before if they don't specify a target NPC.

## [1.72.0+99]

Follow-up to the last round of live-device feedback: relocate a
half-discoverable feature, make character creation faster to start, and
make quest completion actually mean something.

### Changed
- **"Play to Chapter" moved from the Story Map to Settings → Simulate a
  Playthrough.** The strategy-driven chapter autoplay added last round sat
  awkwardly on the Map's node-jump picker; it now lives alongside the
  batch-simulation controls it's a natural sibling of, sharing the same
  strategy selector. Still lands the player back in live Story view with a
  real, earned session once the target chapter is reached.

### Added
- **Randomize button on the Race & Profession screen.** Picks a random race
  and profession in one tap, next to the existing random-name die — for
  players who just want to jump in without reading five race/profession
  cards first.
- **Real quest objective tracking.** `quests.json`'s `objectives` field
  (previously unread by any gameplay code) is now enforced: a quest's
  Complete button stays disabled until its Kill objectives (tracked via a
  new lifetime `PlayerSession.enemyKillCounts`, bumped on every combat win)
  and Fetch objectives (checked against current inventory) are satisfied.
  The active quest card shows each objective as its own checklist line,
  which doubles as sub-quest tracking for any quest with more than one
  objective — no new "quest group" concept was needed, since a multi-part
  quest is just a quest with multiple `objectives` entries. Talk objectives
  are left ungated (no reliable signal exists yet to detect them). Existing
  saves with quests already active before this change are grandfathered so
  they're never stuck unable to complete.

## [1.71.0+98]

Live-device UX feedback from actually playing the app: the story map's
overlapping panels, a genuinely useful "simulate up to a chapter" feature
that turned out to be half-built, and a fullscreen-reading toggle that
fired but was too subtle to notice.

### Fixed
- Story Map: the Legend panel and the "Jump to Chapter" panel both sat at
  the top of the screen, overlapping on narrower viewports. Legend now
  anchors to the bottom-left instead.
- Double-tapping the story text to enter distraction-free fullscreen
  reading worked, but the narration card stayed pinned at its normal small
  size with the freed-up space left as dead blank area below it — easy to
  read as "nothing happened." It now fills and centers in the available
  viewport height.

### Added
- `autoplayToChapter`: a strategy-driven counterpart to the existing
  shortest-path `autoplayToNode` — walks real choices forward from the
  player's current position toward a target chapter, favoring good/evil/
  gold (or random) at each branch, applying every step's true effects
  (gold, alignment, flags, shop/quest unlocks, real simulated combat) via
  the same session methods a live choice tap uses. Wired into the Story
  Map's "Autoplay to chapter" picker alongside a strategy selector, so
  picking a chapter now plays a real, strategy-flavored path there instead
  of always taking the single shortest route — and lands the player back
  in live Story view afterward, ready to keep going manually with a real
  earned session. This is the "simulate up to a chapter, then take over"
  capability `firstNodeIdForChapter`'s doc comment had anticipated but
  never actually existed.

## [1.70.0+97]

The remaining CI/polish loose ends from the last review round.

### Added
- **A one-time nudge toward In-Game Mode.** Every fresh install defaults to Edit Mode (the full authoring app) since that's what this project's own development relies on — flipping that default would work against the developer's own daily workflow, so it stays. Instead, a dismissible banner on the Play tab now points a genuine first-time player at the Settings toggle, shown once until dismissed either by switching or by closing it outright.
- **`docs/quest-progress-tracking.md`** — a scoping writeup (not an implementation) for enforcing quest objectives for real, grounding the plan in the `objectives` schema that already exists in `quests.json` but was never read anywhere in gameplay code.
- **`.github/workflows/format.yml`** — a manual (`workflow_dispatch`-only) way to actually apply `dart format` via CI's Flutter install, since this dev environment has no local Dart SDK to run it directly.

### Changed
- **The codebase is now actually `dart format`-clean** (71 files reformatted via the new workflow) and **the CI format check is a real gate** — dropped the `continue-on-error` that was only ever meant to be temporary, pending a pass that confirmed the repo was clean.

## [1.69.0+96]

Fixes from a 40-run simulated-playthrough analysis (built as an accurate Python port of the real combat/quest/achievement logic, cross-checked against `test/combat_engine_test.dart`'s hand-verified values). 3 confirmed bugs fixed, 2 of 3 balance findings addressed; the third needs a product decision rather than a code fix (see below).

### Fixed
- **A level-1 character could roll an unwinnable fight in the very first random encounter.** `SubNodeEngine`'s procedural "excursion" encounters drew from the *entire* enemy roster with no level/chapter filter, so a chapter-1 side-fight could occasionally draw a chapter-4/5-tier monster (230 HP / 27 dmg vs. a fresh character) — unwinnable, with no way to decline or route around it. Traced in simulation to every one of 12/300 permanently-stuck sample runs. Every `enemies.json` entry now carries a `minChapter` (derived from where the main story itself first uses that enemy), and excursions only draw from enemies already at-or-below the current chapter.
- **Quest `alignmentChange` was defined in data but never applied.** `completeQuest()` had no alignment parameter at all, so `quests.json`'s `alignmentChange` field (set on several quests, including the near-mandatory banner quest) was silently dropped every time — quietly denying players alignment the content was designed to grant, on a game that gates real story branches on alignment thresholds. Now threaded through from the quest record into the same `alignmentScore` update `applyChoiceEffects` already uses for choice-driven alignment.
- **A completed quest could be re-offered by a later excursion.** The excursion quest pool excluded `unlockedQuestIds`, but a quest reached via `questIDToProgress` (rather than `unlockQuestId`) never lands in that list — so `q_first_blood` specifically could resurface after completion. The pool now also excludes `completedQuestIds`.

### Changed
- **Companion co-recruitment is more reliable.** Kelda and Sable are offered as a single, mutually-exclusive, non-revisitable pick at node 2015 (by design — every other recruitment/vignette hub in this story works the same way), so getting both in one run depended entirely on a later excursion randomly re-offering the one not picked, at roughly a 1-in-N chance against the whole side-quest pool. Excursions now prioritize an eligible companion-recruit quest over an ordinary side quest whenever one is available, without changing the main-path structure.
- **Unspent stat/skill points now show a badge on the Character card** (matching the existing unseen-quest/shop/enemy badge style) — spending them is entirely manual and nothing else calls attention to it; a full-game simulation with points never spent saw Chapter 4-5 win rates roughly halve.

### Investigated, not changed
- **Quest "objectives" (kill X, fetch Y) aren't enforced — completion is gated on nothing**, so reward chains resolve the instant they unlock regardless of whether the described events happened. This inflates the in-game economy (~30% of average simulated end-game gold is quest rewards) but may be an intentional lightweight quest-log design rather than a bug. Actually enforcing objectives would mean building real progress-tracking (kill counts, item possession, flag state) per quest — a new feature, not a fix — so left alone pending a product decision.

## [1.68.0+95]

The remaining two of five requested UX improvements, scoped after a clarifying round: a real-state "autoplay ahead" testing tool, and closing the Camp Rest gap.

### Added
- **Autoplay to a node or chapter (Edit Mode).** `lib/data/autoplay_engine.dart` finds the shortest forward path through the story graph to a target node, then walks it applying every choice's real effects (gold/alignment/heal/flags/quest-progress, shop/quest unlocks, achievement checks) through the exact same `PlayerSessionNotifier` methods a live choice tap calls — including a genuine simulated combat (the same `combat_engine.dart` functions and scaling a real fight uses, retried a bounded number of times on a loss) for any triggered fight, so the state you land in is a real earned one, not a fabricated snapshot. Reachable from the map: "Autoplay to this node" in a node's detail sheet, and "Autoplay to chapter…" next to the existing Jump-to-Chapter chips. Both Edit-Mode-only, like the quick-preview jump they sit beside. Deliberately skips procedural excursions and ignores active allies in the simulated fight — a testing tool, not a faithful full replay.
- **Rest at the Town Hub, not just Camp.** Town Hub gets its own "Rest" action (same `healPartyToFull()`), since a town is as much a safe haven as camp.

### Fixed
- **Camp Rest is now blocked while a fight or expedition is in progress** (`expedition_active_provider.dart`, mirroring the existing `combat_active_provider.dart`), applied to both Camp's and Town Hub's Rest buttons. Mostly a defensive check today — both already cover the bottom nav with their own full-screen route — but closes the gap for good.

## [1.67.0+94]

Three of five requested UX improvements (the other two — a "simulate ahead to a node/chapter" testing tool, and precisely scoping where Camp's Rest action should be allowed — need a design decision first and are being scoped separately).

### Added
- **Autosave for story position.** `PlayerSession` (stats, inventory, quests) has always auto-persisted continuously, but the *story position* (`StoryPlayNotifier`'s current node + history) only ever lived in memory — closing and reopening the app silently reset the narration back to the very first node while every stat/item earned since stayed intact. It's now autosaved on every real position change, to its own slot separate from the existing manual Save/Load checkpoint, and restored on launch. A restart (permadeath, or the Edit Mode reset) correctly clears it too, and an autosave pointing at a since-deleted node still degrades to the existing "trail went cold" recovery screen rather than crashing.
- **Double-tap the story text for a distraction-free fullscreen read.** Hides the status bar, header row, walking companion, and choices, leaving just the narration; double-tap again to bring them back.

### Changed
- **Story map readability.** Node labels were unbounded-width text, so a long id (e.g. `2015_dockside`) could render wider than its column and visually overlap the next one — now fixed-width and ellipsized. Same-depth nodes were ordered alphabetically with no regard for which column their edges actually connected to, producing heavy crossing clutter in fan-out/fan-in clusters like the Chapter 3 companion-quest diamond; they're now ordered by a barycenter heuristic (each node sorted near the average row of its already-placed predecessors), which measurably cuts down edge-crossing on the real story graph. Column and row spacing widened slightly to match.

## [1.66.0+93]

Two regressions found by a fresh functional review of the companion/camp system (spawned as three parallel reviews covering combat/camp, Town Hub/expeditions/achievements, and map/UI/origin-story features — the latter two found no bugs).

### Fixed
- **A winning fight that leveled the player up would immediately undo that level-up's full heal for every active ally.** `applyCombatResult` already full-heals and grants skill points to every recruited ally when its XP gain crosses a level threshold, but `FightScreen._finishFight`'s very next loop unconditionally wrote each ally's stale, pre-level-up battle-end HP over that heal (and revived a knocked-out ally against their *old*, lower max health instead of the new one). That per-ally write is now skipped whenever the fight's win also leveled the player up.
- **A companion's one customizable die face was permanently stuck on `heavy_attack`.** `InventoryScreen` and `SkillsScreen` were parameterized by `allyId` when the companion/camp system landed, but `DiceLoadoutScreen` never was — so there was no UI path to ever reassign a companion's single open Skill-die face, making their skill-point/unlock progression's actual combat payoff unreachable. `DiceLoadoutScreen` now takes an optional `allyId` (mirroring the other two screens: no die-switcher, since an ally only ever has their one fixed signature die) and Camp's roster cards got a third "Dice Loadout" button to reach it.

## [1.65.0+92]

CI/build pipeline and test-coverage improvements, from a review of the setup itself rather than the game.

### Added
- **Real unit tests for game logic, for the first time.** `test/combat_engine_test.dart` covers dice rolling, player/enemy move resolution (Attack/Defend/Heal/Skill faces, Always/Chance/OnLowHealth enemy conditions, priority ordering including the "a match consumes the turn even if its skill doesn't resolve" edge case), and the three level-scaling formulas. `test/player_session_provider_test.dart` covers `completeQuest` (gold/XP/item rewards, leveling up, banner-piece de-dup), `completeZone` (rewards, one-time payout), `applyCombatResult` (rewards, leveling, HP clamping), `recruitAlly` (starter skills, no duplicate recruits), and `checkAchievements` (including a regression test pinning `full_party` at exactly 2 active allies — the threshold bug fixed a few versions back). Every one of this session's real balance bugs was previously only ever caught by a hand-written Python simulation run manually, outside CI; this is the start of closing that gap for real.
- `.github/dependabot.yml` — weekly update PRs for pub packages and GitHub Actions, so "N packages have newer versions" is an actual PR to review instead of a CI log line nobody acts on.

### Changed
- **CI workflow (`build_apk.yml`)**: added `concurrency` with `cancel-in-progress` so a branch that gets several quick follow-up pushes stops burning minutes on runs whose result is already superseded; enabled `subosito/flutter-action`'s built-in SDK+pub caching (was off) and added a Gradle cache, both aimed at the 7-9 minute build-APK step being the slowest thing in every run; bumped `actions/setup-java` from the now-deprecated v3 to v5; added a `dart format --set-exit-if-changed` check (non-blocking for now — the repo's formatting hasn't been verified clean without a local Dart SDK to check first); tightened the workflow-level permissions default from `contents: write` to `read`, with `build` granting itself `write` explicitly for its own release step.

### Investigated, no change needed
- `flutter_tts` (the package CI warns applies the Kotlin Gradle Plugin directly) is already pinned to its latest published release, 4.2.5 — there's no newer version to bump to yet. Dependabot will now surface one automatically whenever the maintainers ship a fix.

## [1.64.0+91]

### Added
- **Profession-flavored origin story.** The "beggar's plea" childhood prompt (one of the five formative-memory beats shown at character creation) now has a variant per profession instead of one generic version for everyone: Warrior (a wounded veteran's ration), Mage (a hedge-mage's warming charm), Cleric (a pilgrim's offering coin), Ranger (a trapper's dried meat) each get a small reskin of the same beat; Rogue gets a genuinely different scenario — a rigged card game, warn the mark or run it as rigged. New `originPromptForSlot()` picks the right variant for the player's chosen profession, falling back to the original generic prompt for any profession without one.

## [1.63.0+90]

### Changed
- **Narrative text throughout the app now reads like prose, not a form field.** The childhood/teenage origin-story dialog (shown once at character creation), the Quests tab's quest cards, and the shared item/skill/quest detail popup all now render their descriptive text with a serif typeface, 1.55-1.6 line height, and slight letter-spacing — the same readability treatment the story reader itself got earlier this session. The Quests tab's cards were also rebuilt from a cramped 3-line-max `ListTile` (which truncated longer dialogue) into a proper card layout that shows the full text.
- **Added a "Jump to Chapter" panel to the Map screen.** A row of chapter chips (Prologue through the current content's last chapter) in the top-right corner jumps straight to that chapter's opening beat, reusing the same `jumpTo` the map's existing (undiscoverable) per-node double-tap already used — now there's a visible way to skip ahead and pick up a playthrough from a specific chapter without replaying from the start.

## [1.62.0+89]

Phases 2 and 3 of the roguelike redesign (see the design doc's Phase 1 entry below for background). Both delivered without touching the story graph's existing routing — Phase 3 in particular turned out to need far less new content than expected, since its two "banner piece" payoffs were already fully built and just needed tagging.

### Added
- **Town Hub now has all 3 of Chapter 2's tutorial zones.** New zone: Lantern Docks — rewards a narrative lead (a flag, not an item) on where the Shroud's second piece went, rather than gold or an item, giving zones their first non-material reward type.
- **Banner-piece tracking.** `PlayerSession.bannerPiecesCollected` (new field) tracks recovered pieces of the Shroud — the "heirloom cut into pieces" mechanic from this session's design doc. A quest's new `grantsBannerPieceId` field (mirrors the existing `rewardAllyId` pattern) tags a piece on completion; a zone's new `rewardFlag` field (mirrors a quest's `flagToAdd`) grants a plain narrative flag instead of gold/item/dice/ally, for zone rewards that are leads rather than loot.
- Both of Chapter 1 and Chapter 3's **existing** quests already delivered on the brief's "expedition to get the map to the second part" / "go get the flag" beats without any new content: `q_retrieve_banner` (Ch1, "The Heirloom of Alster" — literally the heirloom pickup) now tags the first piece; `q_ch3_alsters_dawn` (Ch3, the payoff of the already-wired `q_ch3_void_relic → q_ch3_the_high_wardens_fall → q_ch3_alsters_dawn` chain reachable from node `3005`) now tags the second. Character screen shows collected pieces when there are any.

### Not in this slice
The existing Chapter 2 harbor (`2015`) and Chapter 3 Ashen Quarter (`3005`) hub nodes were deliberately **not** restructured into the expedition/zone frame — turning an authored, one-shot story choice into a repeatable zone is a real engine change, distinct from adding parallel zone content, and risks the narrative-audit fixes from a few versions back. The new zones wrap around this content rather than replacing it, per the design doc's central recommendation. The boat (Phase 4) and Chapters 4-7's content (Phase 5) are still ahead.

## [1.61.0+88]

The first build slice of a larger roguelike redesign discussed and written up as a design doc this session ("The Scattered Banner"): a town-and-expedition loop wrapped around the existing chapters rather than replacing them. This entry is Phase 1 only — "one zone, land only" — proving the mechanism before any existing story content is touched.

### Added
- **Town Hub screen.** A new, separate screen (`lib/screens/town_hub_screen.dart`, reachable from a new Play-tab card) distinct from Camp: a tutorial/prologue stop with a couple of already-stocked basic shops (Blind Beggar Stall, Weaponsmith's Forge — nothing to build) and a list of the current chapter's expedition zones. Camp remains the one persistent base the player builds from scratch and keeps for the rest of the game; the town hub is what they have before they have that.
- **Expeditions.** A new `zones.json` data table (2 zones added for Chapter 2: Fisherman's Row, Tanner's Court) and `ExpeditionScreen` (`lib/screens/expedition_screen.dart`) that walks a zone's fixed chain of events — each one drawn live from `SubNodeEngine`'s existing themed flavor pools (its internal node-builder was made public, `SubNodeEngine.buildNode`, rather than duplicated) so a new zone needs no per-event writing, only a data row. Fights resolve through the existing `FightScreen`/`combat_engine.dart` unchanged; shop finds push the existing `ShopDetailScreen`; treasure/rest apply through the existing `applyChoiceEffects`. Losing or fleeing a fight, or retreating voluntarily between events, ends the run — everything already gained that run (gold, items, XP from any won fight) is kept, but the zone's own banked completion reward is forfeit until the zone is cleared in one run. `PlayerSession.completedZoneIds` (new field) tracks cleared zones permanently, mirroring `completedQuestIds`.

### Not in this slice
Re-plumbing Chapters 2-3's *existing* content onto this frame, the boat/FTL system, and Chapters 5-7's content are later phases per the design doc — deliberately not started here.

## [1.60.0+87]

### Changed
- **The story map now lays out as a grid capped at 5 nodes per column, with each chapter as its own vertical band** ("a map in itself"), instead of an automatic Sugiyama layered-graph layout with no ceiling on how many nodes could stack in one column. New `ChapterGridAlgorithm` (`lib/screens/story_graph_screen.dart`) positions every node from a precomputed slot map (`lib/data/chapter_grid_layout.dart`): column = BFS hops from that chapter's opening beat (following only same-chapter edges), row = position within that column, split into extra columns whenever a depth level would otherwise exceed the cap. Each chapter's band is labeled and sized to its own tallest column, so a low-branching chapter doesn't waste space matching a denser one. Verified against the real 97-node graph via a Python mirror of the same algorithm before porting to Dart: every column caps at exactly 5, and all 97 nodes place correctly.
- Content-side note: the *target* node budget this map layout is meant to support — roughly 15 authored nodes per chapter (5 main beats + up to 10 side nodes) — isn't met yet by the existing chapters (currently 43/21/17/7/8 across chapters 1-5); that's a separate, larger content pass, not part of this change.

## [1.59.0+86]

### Added
- **Random name generation.** A dice-icon button next to the character-name field on the lock-in dialog fills it with a random name drawn from a race-matched pool (`lib/data/random_names.dart`, 20 names per race) — Kelda-style dwarven names for a dwarf, elvish for an elf, and so on. Purely a convenience for players who don't want to type one; the field stays freely editable either way.

## [1.58.0+85]

A full audit of the story graph's 133 choice→node transitions, requested to make sure every scene follows sensibly from the choice that leads into it — found and fixed two structural bugs and two smaller routing/wording issues. Followed by 50 simulated full playthroughs (graph walk + real combat/quest/shop/companion resolution) judging narration coverage, feature usage, item usage, and combat difficulty — which turned up a game-breaking combat bug and two economy bugs, also fixed here.

### Fixed
- **Chapter 2's harbor hub (`2015`) and Chapter 3's outer-district hub (`3005`) had no real content of their own.** All 7 choices at `2015` (visit the Arcane Bazaar, visit Apothecary Row, take the harbor master's job, fight a smuggler captain, fight a plague hound, and the two companion-recruit choices for Kelda and Sable) landed on the exact same unrelated node — a Vane bribery scene meant for a different edge entirely — with zero acknowledgment of what was actually chosen. Chapter 3's `3005` had the identical bug across all 8 of its choices (the Ashen Oath, four separate fights, the Smugglers' Vault, the Void Relic contract, and Maren's recruit choice), landing on an unrelated Hall-of-Records scene. Neither companion-recruit choice had ever had its own scene — the actual "meeting them" dialogue only ever showed up in the quest-discovery popup, never in the story itself. Added 15 new short bridge nodes (one per choice) that acknowledge the specific thing just done — winning that fight, taking that oath, hearing that companion out — before continuing on to Vane or the archives as before. Lightly reworded both shared continuation nodes (`2030`, `3020`) so they read naturally regardless of which of several very different preceding scenes led into them.
- **Node `280` (the Tear's first appearance) assumed every arrival came from the alley.** Two of its four incoming routes are from crossing the bridge instead, where the opening line "The alley opened onto a scorched square" doesn't hold. Reworded to "Whichever way I'd come, it let out onto a scorched square" — the same route-agnostic-opener trick already used for the harbor's multi-path buffer node.
- **Escaping into the canals mid-fight (node `2021`) skipped the multi-path buffer node built to handle exactly this.** It jumped straight to the Chapter 2 end-of-chapter gate with no transition from "fleeing through canal tunnels" to "standing at the threshold." Rerouted through `2900` (the existing "whatever path had brought me here" buffer), same as the harbor's other three convergent routes.
- **The Void Manifestation and Void Stalker's `void_blast` was set to fire every single turn, guaranteed.** Both enemies had this skill (a ~60-90 flat-damage hit on top of their base attack) on `condition: "Always"` at top priority, while every other enemy with access to the same skill gates it behind a 25-40% `Chance` instead. Void Manifestation guards the one and only choice at node `6003b` — a mandatory, no-alternative fight late in Chapter 5 — so this made the game **unfinishable**: a 50-playthrough simulation had a 1.1% win rate against it and 47 of 50 runs permanently stuck there, unable to progress or pick a different option. Changed both to `Chance` (30% for Void Manifestation, 35% for Void Stalker), matching the pattern already used by `inquisition_high_warden`/`hollow_court_zealot`. Re-simulated: 48 of 50 runs now reach a real ending, and Void Manifestation is a genuinely tough (34% win rate) but fair climactic fight rather than an impossible one.
- **Completing a quest never actually granted its XP reward**, despite the discovery popup and completion notice both displaying a "+N XP" figure — `completeQuest()` only ever applied gold/item/dice/ally rewards. Extracted the level-up logic `applyCombatResult()` already had into a shared `_applyXp()` helper and wired `completeQuest()` through it, so quest XP now actually levels the player (and shows the same level-up dialog combat does). This was silently starving players of a large chunk of their intended XP income — average simulated player level by the Chapter 5 climax rose from 2.6 to 3.8 once fixed.
- **The "Field a full 3-member active party" achievement required 4 people, not 3.** Its condition checked `activeAllyIds.length >= 3` (three *active allies*, i.e. the player plus three companions) instead of the two active allies that make up a 3-member party at the default party capacity — meaning it was unreachable without first building the party-capacity-boosting house, despite nothing in its name or description saying so. Changed the threshold to 2.

### Reviewed, no changes needed
- The `960` → `965`/`965_mercy`/`965_vengeance` fork and its downstream flag-gated split — tone and gating both correctly match each branch.
- The `5003_seeker`/`6001_seeker`/`6005_seeker` bearer/seeker variant pairs — correctly differentiated and flag-gated.
- Chapter 4/5 content generally.

Two more nodes (`6003b`'s "faces I had put down" retrospective, and `4999`'s "the High Inquisitor fell" line after fighting a warden rather than the Inquisitor by name) look like they might be reading a specific fight into a line meant to stay impressionistic — flagged for a possible follow-up rather than changed here, since resolving it either way is an authorial call, not a structural bug.

## [1.57.0+84]

A round of usability fixes to the companion/party feature and the QA tooling, from direct play feedback.

### Changed
- **Party combat now rolls together.** Previously each active ally took a full separate sequential turn (their own roll/reroll/confirm cycle) after the player's — with one ally that meant up to 6 rolls before the enemy acted. Now the player and every active ally roll their own die *at the same time*, shown side by side, and Reroll rerolls the whole group together under one shared budget of 3 rolls per round (not 3 per member) — so a 2-person party still only ever takes as many taps as a solo fight did. `fight_screen.dart`'s turn state collapsed accordingly: no more per-member turn cycling, just one combined roll → confirm → enemy-turn loop.
- **Story text is easier to skim.** Each node's opening sentence is now bolded (a quick "what's this scene about" hook) and quoted dialogue is italicized to stand out from narration, via a small `_highlightedSpans()` helper in `story_player_screen.dart`. Every node's text is one continuous block with no author paragraph breaks, so this highlights within that block rather than across paragraphs.
- **Removed the floating collapse/expand arrow** on the story screen's status header — it sat alone in its own row doing little but getting in the way. Tapping the header (the stats bar itself) now collapses it directly, and tapping the collapsed state's slim handle bar re-expands it; scrolling down still auto-collapses it as before.

### Added
- **Companion-quest map legend entry.** The story map previously classified every quest-unlocking node the same amber "Quest" color, including the three companion recruit quests. Those now get their own teal "Companion Quest" kind (`_NodeKind.companionQuest` in `story_graph_screen.dart`, detected via the target quest's `rewardAllyId`), togglable in the legend like every other kind.
- **Simulator recap: color + companions encountered.** The batch recap's key stats (nodes visited, gold, alignment, combat encounters) are now icon-led and colored instead of plain uncolored text. A new "Companions encountered" section shows, per companion, how many of the batch's runs discovered their recruit quest (the closest signal this graph-walk simulator has to "met this companion", since it doesn't model quest completion) — colored chips, `_companionEncounterCounts()` in `playthrough_simulator_screen.dart`.

## [1.56.0+83]

A follow-up review of the companion feature (PR #85) against quests, story, and — since it turned out not to exist yet — achievements.

### Added
- A small achievements system: `assets/gamedata/achievements.json` (new `DbSchema`, like every other data table) and a new Achievements screen (card on the Play tab), seeded with 7 milestones — 4 tied to the new companion feature (recruit your first companion, recruit all three, field a full 3-member active party, build Kelda's Hall specifically) and 3 general ones (win a fight after reviving a knocked-out ally, complete your first quest, discover your first shop). `PlayerSession` gained `unlockedAchievementIds`; a new `checkAchievements()` scans persisted state for newly-met conditions after recruiting/activating/building/completing, and `unlockAchievement()` grants one-off event achievements directly (the ally-revival case, detected in `FightScreen` itself since "was knocked out this fight" isn't state that survives past the fight).
- The story prose now briefly acknowledges having an active ally at the two biggest post-Chapter-2 combat beats (the Chapter 3 climax and the Chapter 5 finale) — previously "fighting alongside you" was never mentioned anywhere in the narration, even when the player mechanically had two companions in the fight. Deliberately generic (never names which companion, to avoid enumerating every active-party combination) and computed live off the player's current party via a small `withAllyAcknowledgment()` helper in `story_player_screen.dart`, rather than forked story nodes — simpler and more correct than a flag-gated variant, since active-party membership is state that changes at any time (via Camp), not a one-time story flag.

### Reviewed, no changes needed
- All 15 quests (12 existing + the 3 new recruit quests) — schema-consistent, no name collisions with existing NPCs, dialogue reads consistently with the game's voice, and quest difficulty/rewards are player-level-scaled rather than party-composition-scaled, so nothing there interacts with active allies.
- The rest of the story's "alone" language — all of it predates Chapter 2, before any companion can exist, so none of it contradicts the new feature.

Deliberately out of scope: acknowledging allies at every combat encounter across all 5 chapters (a much larger content project than this pass), and naming which specific companions are present in the acknowledgment lines (would need real templating support the story format doesn't have).

## [1.55.0+82]

### Added
- **Companions.** Three recruitable allies — Kelda (dwarven shieldbearer), Sable (rogue), and Sister Maren (cleric) — each earned through a new side quest (`q_ch2_keldas_stand`, `q_ch2_sables_wager` in Chapter 2, `q_ch3_marens_penance` in Chapter 3, surfaced as new optional choices on the existing Chapter 2/3 hub nodes). Recruiting is permanent for the save the moment the quest completes, regardless of whether that companion ever fights.
- **Party combat.** Up to 2 recruited allies (more with the right House, see below) can be active at once and fight alongside the player as full combatants, not a stat buff: each active ally gets their own turn in `FightScreen` with the same roll/reroll-up-to-3 dice flow the player has always had, using their own signature die (`iron_die` for Kelda, `shadow_die` for Sable, `holy_die` for Maren), their own damage/armor, and their own equipment. The enemy's own turn now picks a target at random among every conscious party member instead of always hitting the player. An ally reduced to 0 HP is knocked out (skipped for the rest of that fight, not a loss condition) and revived at 30% health on a win, or fully healed at Camp; only the player's own death still ends the fight.
- **Automatic scaling.** An ally's combat stats are derived from their race/profession (the same New-Game-Defaults-plus-bonuses formula used for the player) and scaled to the player's current level via the same functions already used to scale enemies — so recruiting someone at level 12 doesn't hand you a level-1 stat block, and every ally (and their skill points) grows automatically whenever the player levels up.
- **Ally gear and skills.** Each recruited ally has their own equipment slots and their own learnable-skill pool, restricted by their own race/profession using the exact same `restrictedRaceID`/`restrictedProfessionID` mechanism skills already had — a Voidkin spell still can't go on a Dwarf, whichever character is holding the die. Managed through the same Inventory and Skills screens the player uses, now accepting an optional `allyId` to point them at a companion instead.
- **Camp & Houses.** A new Camp screen (reachable from a new card on the Play tab) shows the recruited roster — active/benched toggle, live HP, and quick links into that companion's Inventory/Skills — plus a Houses list and a Rest action that fully heals the whole party. Houses are a new buildable, gold-spending structure: Kelda specifically requires "Kelda's Hall" to be built before she can join the active party (shown on her roster card as recruited-but-benched with a note explaining why), while the separate "Barracks Annex" simply raises active-party capacity from the default 2 to 3, independent of any one companion.

### Changed
- `PlayerSession` gained `recruitedAllies`, `activeAllyIds`, and `builtHouseIds`, following the same append-only-list and hand-written-JSON patterns already used for quests/shops/dice — no persistence restructuring needed.

Deliberately out of scope for this pass: a dedicated die-face-reassignment UI for allies (their one open "Heavy Strike" slot works, just not yet player-customizable the way `DiceLoadoutScreen` lets the player reassign their own); and wiring up `adventure_nodes.json`'s long-dormant "Rest" node category (confirmed unread anywhere in the live game already) — Camp's own Rest action delivers the "fully healed at camp" behavior without touching that unrelated, pre-existing gap.

## [1.54.0+81]

### Fixed
- Kroll — the story's Chapter 1 antagonist, described across three nodes as "my torturer" wielding a blade with "fond familiarity" — never actually had a `triggerEnemyId`, so the climactic "boss fight" at the docks was entirely narrated with no mechanical combat behind it. Added a `kroll_the_branded` enemy and wired it to the fight's starting choice.
- The Chapter 3 climax (node 4999, "The High Inquisitor fell") was reachable via two routes (bribing or subduing the archivist) with zero combat of any kind — only the third, rooftop route actually fought anyone. Both now fight the same `inquisition_high_warden` vanguard the rooftop route always has, so "The High Inquisitor fell" is earned on every path instead of being a non sequitur on two of the three.
- Node 4999's `speaker` metadata read "High Inquisitor" despite the text being third-person narrator prose, not a quote. Corrected to "Narrator".
- Node 6003b's climax specter recalled fighting "Wardens... on a bridge, in a hallway, on a dock" — none of which matches what those fights actually were (a `slum_thug` on the bridge, no "hallway" encounter exists at all). Reworded to match the actual fights without over-claiming a specific enemy type.
- Chapter 4 was the only chapter whose opening node (5001) lacked a "[CHAPTER 4: ...]" title, unlike every other chapter's opener. Added "[CHAPTER 4: THE HOLLOW COURT]".
- The Chapter 3 hub (node 3005, reached by choosing to "pause and take stock") silently forecloses the rooftop/cloisters infiltration route (3010) without ever telling the player — its own text even claimed choices here were still "before committing to a path". Reworded to state plainly that the rooftop route is off the table once you're here.

### Changed
- How Kroll's death is narrated now depends on how the fight was resolved: ending it quickly (the mercy option) and making him "pay for every session" (the vengeance option) each get their own aftermath text distinct from a plain fight, instead of all three of node 960's choices funneling into identical prose regardless of what the player actually chose.
- Chapters 4 and 5 assumed every player is physically carrying the Void Banner/Grey Shroud by the time they reach the catacombs and beyond ("the Void Banner had gone warm... against my back") — true only for the Guardian origin, which starts with it. The Rat and Broken origins explicitly begin with no Heirloom and no Banner. The Hollow Court altar scene (5003), the Chapter 5 opener (6001), and the ending (6005) now each have a Banner-seeker variant reflecting that honestly, selected automatically by which origin was played; node 6004's "the Shroud speaking" line was also generalized to "the Void itself" since that line didn't need forking to be accurate for both.

A fresh 3000-run random-walk simulation (same model as before, ignoring gating) confirms these additions don't regress the economy: average final gold actually rises further (217 → 329, still zero zero-gold outcomes) since Kroll's now-guaranteed fight and the archivist-route fights both pay out, and average alignment is unchanged at -0.48 since none of this touches alignment math.

## [1.53.0+80]

### Fixed
- The Playthrough Simulator's gold model never paid out a won fight's `goldReward` — it counted the encounter but only ever applied the choice's own (usually zero) `goldMod`. Since most of the story's gold comes from combat rather than flat pickups, every "random strategy" batch reliably ended near 0 gold despite visiting working shops, which is exactly the "can't participate in the economy" pattern a Gemini analysis of simulator batches flagged. Combat gold now folds into the step's recorded `goldMod` so the chapter breakdown and CSV/JSON exports stay consistent with the run's final total. The "maximize gold" strategy also now accounts for a fight's payout when scoring choices, instead of only ever chasing flat `goldMod` bonuses.
- Node 260's "Refuse & Fight" carried a -1 alignment penalty despite being the only reachable choice for any player without the 50 gold node 261 requires to pay the toll instead — i.e. a guaranteed alignment hit for self-defense with no real alternative this early in the story. Removed.

### Added
- A real fork at the Hollow Court altar (node 5003): fighting the zealots outright (`hollow_court_zealot`) is now an alternative to letting them scatter, leading to its own aftermath beat before rejoining the main path.
- A climax guardian fight at the Void tear (node 6003/6003b): a `void_manifestation` now contests the crossing into Chapter 5's final scene instead of it being an unopposed walk-through.
- Two new enemies (`hollow_court_zealot`, `void_manifestation`) extending the existing difficulty curve past the previous `inquisition_high_warden` ceiling, so Chapters 4 and 5 — previously zero combat encounters between them — have real stakes at the story's climax.

A random-walk simulation against the story graph (ignoring gating, matching the in-app simulator's own model) confirms the intended effect: average final gold across 3000 simulated runs goes from 86 to 217 with the zero-gold outcome eliminated entirely (was 1.6% of runs even before this fix, would have been ~75% without any combat payout at all), and average final alignment improves from -0.97 to -0.48.

Chapter 3-5 branching still falls well short of Chapter 1's — closing that gap properly is a larger, multi-release content project rather than something to rush into one PR alongside a balance/bug-fix pass.

## [1.52.1+79]

### Fixed
- Collapsing the story view's status bar left a large blank band instead of actually reclaiming the space (an `Expanded(child: statusBarCollapsed ? SizedBox.shrink() : ...)` inside a `Row` kept the row's own height and the Expanded's claimed width regardless of the collapsed state). Restructured so collapsed shows nothing but the small toggle itself.

### Changed
- Quest/item/skill/dice detail dialogs now render their flavor-text description with larger text and more generous line spacing, matching how the main story narration is styled, instead of the dialog's cramped default text style.


### Added
- Copy button for the Playthrough Simulator's batch summary (previously only individual runs and the Gemini analysis could be copied — batches only had Export).
- CSV and JSON export options for a batch's results, alongside the existing plain-text transcript export — CSV as one row per run (ending, gold, alignment, nodes visited, combat encounters, etc.) ready to drop into a spreadsheet, JSON as the same per-run data structured for scripting.

## [1.51.1+77]

### Added
- A `secret-scan` job in CI (using [gitleaks](https://github.com/gitleaks/gitleaks)) that runs before every build and gates the whole pipeline: if an API key, token, or other credential is ever committed, the push or PR fails before anything is built or released. Verified against the full existing codebase and git history first — both clean.

## [1.51.0+76]

### Added
- Copy button next to "Analyze with Gemini" in the Playthrough Simulator, matching the Copy/Export actions individual run transcripts already had.

### Fixed
- Playthrough Simulator results were lost every time the screen was backed out of and reopened (it's reached via `Navigator.push`, so a fresh widget instance means fresh, empty state) — moved the batch list into a Riverpod provider that lives for the app's lifetime, so results now persist until explicitly cleared with the app bar's clear-all button.
- Settings > Check for Updates always failed silently: this repository is private, and both the release lookup and the APK download were unauthenticated GitHub API calls, which a private repo answers with a 404 indistinguishable from a generic network failure. Both now send the GitHub Personal Access Token already stored for GitHub Sync (the download goes through GitHub's authenticated release-asset API instead of the plain, sign-in-walled `browser_download_url`), and tapping "Check for Updates" with no token set shows a specific message pointing at where to add one instead of a generic failure.

### Changed
- The Playthrough Simulator's strategy/runs controls now also collapse the moment the player scrolls down into the results (previously they only auto-collapsed right after running a batch, and only re-expanded on scrolling back to the top).
- The story view's status bar and companion strip now collapse automatically once the player scrolls down into a long piece of narration, instead of only ever collapsing via their manual chevron toggles.

## [1.50.0+75]

### Added
- Structural graph-integrity checker (`lib/data/story_graph_integrity.dart`) that walks every choice from the start node, ignoring gold/alignment/flag gating, to find unreachable nodes, dead ends, and broken `next_id` links — codifying the exhaustive BFS this project had been running by hand after content passes.
- "Audit Graph Structure" button in the Playthrough Simulator that runs the same check and reports results in-app.
- Automated test suite (`test/story_graph_integrity_test.dart`) that runs the structural audit against the shipped story graph on every CI run.
- A real smoke test (`test/widget_test.dart`) that launches the actual app and checks it renders, replacing the leftover default Flutter counter-app test.
- `flutter analyze` and `flutter test` steps in CI, and a `pull_request` trigger so both run before merge instead of only after pushing to `main`.
- `CHANGELOG.md` (this file).
- A guaranteed encounter for the previously-unused `void_wisp` enemy and its "Void Relic" quest, added to node 3005 alongside the chapter's other optional side-fights.

### Changed
- Node 3005's four side-fights now hint at their relative danger in their choice text (previously identical HP-blind phrasing spanned 74-182 HP with no in-fiction signal).
- Bumped the `gemini-1.5-flash` calls in the AI story generator and the simulator's Gemini analysis to `gemini-2.5-flash`, matching the model generation already used for Gemini TTS.

### Removed
- Seven dead root-level prototype files (`main.dart`, `models.dart`, `game_provider.dart`, `editor_tab.dart`, `play_tab.dart`, `schema_tab.dart`, `theme.dart`) superseded by `lib/` since the project's earliest commits and never part of the actual build.

### Fixed
- A version-string sync regression from earlier in this same release: `pubspec.yaml` bumped to 1.50.0 but `AppInfo.version` and the AndroidManifest app label were left at 1.49.2, so Settings' "Current version" and the in-app update checker's own version comparison were reading a stale value. Resynced all three.
- `installApk()` discarded the system installer's result entirely, so a failed install (most commonly "install unknown apps" not yet granted for this app — the expected first run) failed completely silently after a successful download. Now surfaces a message telling the user to grant the permission and retry.
- `flutter analyze` failing on 23 pre-existing info-level issues that had accumulated silently since analyze had never run in CI before this release — 17 fixed outright (deprecated `withOpacity`, missing `const`, unguarded `BuildContext` use across an `await`), 6 deliberately left as `DropdownButtonFormField.value` (each genuinely needs to stay reactive to external state) and suppressed with a documented `// ignore:`.
- Added `test/update_checker_test.dart` covering the update checker's version-string comparison.

## [1.49.2+74]
- Fix the story's true ending looping back to Chapter 1 instead of ending (#77)

## [1.49.1+73]
- Reduce clutter in playthrough simulator results (#76)

## [1.49.0+72]
- Add chapter/location/mood breakdowns, run filtering, and transcript export to the playthrough simulator (#75)

## [1.48.1+71]
- Remove the 'Leave (End Game)' choice from the very first story node (#74)

## [1.48.0+70]
- Fix silent combat trigger and an infinitely-farmable rat fight found in a coherence audit (#73)

## [1.47.1+69]
- Vary overused narrator phrasing found by re-running the 20-playthrough simulation (#72)

## [1.47.0+68]
- Rewrite all 75 story nodes in a denser, ironic first-person voice (#71)

## [1.46.1+67]
- Add collapse toggles for the status bar and companion, fix mislabeled origin-ending moods (#70)

## [1.46.0+66]
- Normalize story node metadata, enrich chapters 4-5, and auto-match excursion flavor to scene (#69)

## [1.45.0+65]
- Remove sherpa-onnx voice, add manual save/load, restrict reset to edit mode (#68)

## [1.44.7+64]
- Surface auto-read voice errors instead of failing silently (#67)

## [1.44.6+63]
- Fix "Please initialize sherpa-onnx first" error on every French read-aloud (#66)

## [1.44.5+62]
- Fix demon walk sprite overflowing the companion strip (#65)

## [1.44.4+61]
- Use the uploaded walking_angel/walking_evil frame sequences (#64)

## [1.44.3+60]
- Fix main build (pattern-assignment compile error) + scaffold companion walk-cycle folders (#63)

## [1.44.1+58]
- Fix UI freeze from sherpa-onnx voice by moving it off the main isolate (#62)

## [1.44.0+57]
- Use sherpa-onnx offline neural voice for French narration (#61)

## [1.43.0+56]
- Add auto-read narration using the fast on-device voice (#60)

## [1.42.2+55]
- Fix alignment-based companion sprite scale during walking (#59)

## [1.42.1+54]
- Remove misleading Later option on shop discovery, add alignment-based companion look (#58)

## [1.42.0+53]
- Add edit-mode back button fix, node-scoped shops, unseen badges, and level-up point distribution (#57)

## [1.41.0+52]
- Character creation overhaul: skill preview, lock-in naming, origin stories (#56)

## [1.40.0+51]
- Gemini voice loading/preload, and a 3-reroll dice mechanic with face preview (#55)

## [1.39.0+50]
- Edit-mode stat editor, Gemini playthrough analysis, dice/log polish in combat (#54)

## [1.38.0+49]
- Add optional Gemini AI voice for the read-aloud button (#53)

## [1.37.0+48]
- Restrict Back to edit mode, bark on fight-available nodes, animate dice rolls (#52)

## [1.36.0+47]
- Fix narrative continuity issues in the Ashen Street story (#51)

## [1.35.0+46]
- South-facing idle/fight poses, walk-in entrance, and a companion name (#50)

## [1.34.0+45]
- Turn the companion into an idle/walk/fight state machine (#49)

## [1.33.1+44]
- Show character stats before starting the game after creation (#48)

## [1.33.0+43]
- Rework companion animation direction/size and tutorial trigger (#47)

## [1.32.1+42]
- Fix walking companion still showing the fallback dog on-device (#46)

## [1.32.0+41]
- Add a first-time guided tour for In-Game mode, hosted by the companion (#45)

## [1.31.2+40]
- Wire the walking companion to the uploaded sprite frames (#44)

## [1.31.1+39]
- Scaffold sprite-frame folder for the walking companion (#43)

## [1.31.0+38]
- Add a walking companion animation option for story transitions (#42)

## [1.30.0+37]
- Add Continue button, filter, and sort to the shop screen (#41)

## [1.29.1+36]
- Fix release APK signing so in-app updates install without uninstall (#40)

## [1.29.0+35]
- New app icon; replace player-facing SnackBars with immersive modals (#39)

## [1.28.0+34]
- Split the app into Edit mode and In-Game mode (#38)

## [1.27.0+33]
- Collapsible Play sections, multi-run simulator, dark-mode map fix, TTS (#37)

## [1.26.0+32]
- Animate the story interface: node transitions, staggered choices, stat pulses (#36)

## [1.25.0+31]
- Add GitHub push-as-branch for in-app data edits (#35)

## [1.24.1+30]
- Make the discovery modal's View Quest actually work, add direct Accept (#34)

## [1.24.0+29]
- Add fixed shop stock, direct equip, and item/skill comparison (#33)

## [1.23.1+28]
- Fix update checker silently reporting "up to date" on API failures (#32)
