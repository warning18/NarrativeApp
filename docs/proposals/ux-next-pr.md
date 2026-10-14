# UX: where the work stands

For the manager (read here because UX has no `send_message`). #212 (1.282) is merged.

## PR 1: [#217](https://github.com/warning18/NarrativeApp/pull/217), v1.286.0+322 (the version the manager gave): material icons and chips only

Nine pixel icons for the building materials (`tool/gen_material_icons.py` writes `assets/icons/items/material_*.png`; the borrow list in `ItemIcons` is gone, the boss trophy keeps its own), and the material chips on the camp's build cards (the cost beside gold as each material's icon and count: `2` held, `1/2` in red when short; the status tag says "need materials"). It reads Core's `materialCost` and `missingMaterials`. Touches only `camp_town_section.dart` (UX's), `item_icons.dart`, one new string key (`town_materials`, EN + FR). Tests: `camp_town_section_test.dart`.

## PR 2: [#223](https://github.com/warning18/NarrativeApp/pull/223), v1.290.0+326 (Core's 1.287 is in main)

The skill choice sheet (C, board 9 approved) on Core's `faceSkillChoice`; places heard of on the full map (H: "?" marks, Set out by their expedition, Mark as goal; Narrative owes the reason lines); the land crossing in the desert side view on a shared side-view engine (`lib/widgets/side_view/`, with a sea kit not yet wired); the building screen (G, board 10) if the user's three questions are answered. Notes for each are in the branch history's `docs/proposals/ux-next-pr.md`.

## Questions for the user: the building screen (board 10, https://claude.ai/artifact/HvLA3w9MU1hh1NtDKgSK8R)

The board draws the camp's Town tab as four sections (the Sea, the Company, the Workshops, the Great Works) with one card per house, state tags (Ready, Missing, Built, a locked silhouette), the material chips, and a sheet on a missing card that says what is missing and where it comes from. Nothing is built until these are answered:

1. **Locked houses:** show them as dashed silhouettes with one reason ("Chapter 5", "When Kelda joins"), as on the board, or hide them until they come? (Silhouettes promise what is ahead; hiding keeps the surprise and a shorter list.)
2. **Finished sections:** fold a section once all its houses are built (the Company in the board's example), so the screen stays short as the camp grows? Or always show every house?
3. **Where a missing thing comes from, on the sheet:** plain text (the expeditions and shops by name), or links (an expedition name opens the camp's expedition list, a shop name opens its page)? Links are more work and more to keep right when a zone or shop changes.

My recommendation: silhouettes, fold finished sections, plain text first (links later if wanted).

## E, the Journey's same-place choices: what I found before building

I looked at the Journey as it is on `main` (v1.286), at "Your family's house" (scene 300: three choices, all leading to scene 400, the same place). The three ways are drawn as three signpost marks around the party, **with no road and no walk** (since v1.224 a way that keeps the party where it stands has none), over the town's plan. So "the Journey draws them as if you had to travel" is already not true for those; what remains is **crowding when a place has many same-place ways** and no town plan to spread them on. In the story data, 103 of 426 scenes at a landmark have 3 or more same-place choices; the big ones are the towns' hubs (31, 28, 25, 21, 19 same-place ways), which use the town plan and "Enter the town".

Two small things I could build, as its own PR:
- **Group the ways that lead to the same scene** (as scene 300's three do, three ways to scene 400) into one mark with a count, expanding on tap into its ways; or
- **Collapse same-place ways past 5 into a "Here" mark** that expands on tap (the ring stays readable).

I would rather not build either without the user saying which crowding they mean. Question for the user: **where does the Journey still look like travel when it is not?** A screenshot or the scene's name is enough.

## Instead, UX work that needs nobody (if the manager agrees): the home bar's map icon

Open the full map instead of `WorldMapPage`, after moving what only the old page has: the look and shape pickers (into the layers sheet), the chapter chips, the replay of the walked road (board 8's "Replay all"), its tutorial topic. UX-only, independent of Core's 1.287.

## The user's answers (building screen, board 10), relayed by UX

- **Locked houses: silhouettes** with one reason ("Chapter 5", "When Kelda joins").
- **Finished sections: no fold.** Every house stays a card, each one may be tapped.
- **Sources on the sheet: plain text** for now (expeditions and shops by name).
- **Branches** are the coordinator's decision (the manager's), not the user's.
- **E (same-place choices):** the user asked for the link to the design file to look at; there is no board for E (the Journey already draws those ways without roads), so the question stands: where does it still look like travel when it is not?

G (the building screen) is unblocked: UX builds it as its own PR, after #223 and the home map PR; it needs a version from the manager.

## G status: built locally, waiting for a version and its turn

Branch `ux-g` (local, one commit on `origin/main`) has the building screen: `lib/widgets/camp_works_list.dart` (four sections from `campWorksProvider` with Core's names and blurbs, cards by state, silhouettes with one reason, cost chips, the first missing thing, a sheet with plain-text sources and a Build button), wired into the Town tab's Houses list. The additions tab keeps its strip. EN and FR strings (`works_*`), tests in `camp_town_section_test.dart`.

- **Needs from the manager:** a version number. It opens after #223 and the home-map PR (one open PR at a time).
- **Touches another session's area:** `test/qa_real_font_cards_test.dart` (QA's). Its "cards fit" case asserted one height for every card of both trays; the houses are now a list of cards by state (a silhouette is shorter than a ready house), so only the additions strip keeps that check. It also preloads the tables the list reads, and scrolls the tab into view before tapping it.
- `CampTownSection` now reads `campWorksProvider` and the localised houses itself, so locked houses (not discovered yet) show as silhouettes.

## For the manager (14 Oct, after Core's 1.290 and your numbers)

- #223 is now **v1.291.0+327** (merged with `main`, format and analyze clean). It also carries **the ruins scene kit** you asked for (`ruins_kit.dart`: burnt dusk, far skyline, ruined walls and arches, rubble, the quarter's tower with a lit window, ash by default), keyed on route terrain `ruins`, so Core's `camp_to_quarter` gets it as soon as it merges. A test checks a ruins route draws the scene.
- **Second PR, the map icon, v1.292.0+328** (ready locally on `ux-home-map`, needs #223's code, so it merges after it). **I need a branch name for it** (Core's second is `claude/core-2`; I would use `claude/eager-pascal-2`). I will not push it until you say.
- **Third, the building screen (G),** built on `ux-g` (one commit): it needs **a version** (1.293.0+329?) and a third branch, so it opens when one of the two is merged.
- G edits QA's `test/qa_real_font_cards_test.dart` (the houses tray is a list of cards by state, not a strip of equal cards; the preload list gains the tables the list reads). Listed in G's PR.

## Open PRs (14 Oct, after #223 merged as 1.291.0)

- **[#228](https://github.com/warning18/NarrativeApp/pull/228): v1.293.0+329, the map icon opens the full map.** Format, analyze and the six map test files pass locally. It merges after Core's 1.292 (renumber if it goes first). The ruins kit for `camp_to_quarter` was already in #223.
- Next, built locally on `ux-g`: the building screen (G). It needs a version.
- Design board 11 (the world sphere: smaller, two poles, the whole sphere filled, climate by latitude) is on the design artifact; it asks Core for a whole-sphere chart if the user picks it.

## Open PRs (14 Oct, after #228 merged as 1.293.0)

- **[#229](https://github.com/warning18/NarrativeApp/pull/229): v1.294.0+330, the building screen (G).** Format, analyze and its tests pass locally; it edits QA's `qa_real_font_cards_test.dart` (listed in the PR).
- **The ruins scene kit for `camp_to_quarter` is already in `main`** (v1.291.0, #223: `ruins_kit.dart`, chosen by route terrain `ruins`, tested). Nothing more to build for it unless the user wants changes after seeing it. A second PR is not needed for it.
- Design board 11 (the world sphere) waits on the user's three answers.

## Open PRs (14 Oct, after #229 merged as 1.294.0)

- **[#230](https://github.com/warning18/NarrativeApp/pull/230): v1.295.0+331, the ash squall fills the ruins scene with ash.** Format, analyze and `land_crossing_test` + `side_view_test` pass locally.
- **For the manager:** the ruins scene kit for `camp_to_quarter` is already in `main` since v1.291.0 (#223, `ruins_kit.dart`, route terrain `ruins`); #230 adds only the ash squall's thick ash. Nothing else is queued for UX except what the user decides: board 11 (the world sphere) waits on their three answers, and the Journey's same-place choices (E) on where it still looks like travel.

## The user's answers, 14 Oct (boards 11 and 12)

- **Board 11 (the world sphere):** two poles (north and south): yes. **No heat view**: the sphere keeps its own look; climate by latitude is only the rule behind the world's generation. The story lands move (Ashen Continent west, Old Continent east, Lantern Isles between, latitudes kept): yes. If built, Core generates a whole-sphere chart (360° x 180°, ten lands, 12 archipelagos, a polar land at each pole) from the layout on the board; UX takes the smaller sphere (250 px) and the two pole buttons. Not started: it waits on Core's chart.
- **Board 12 (E, the Journey in a busy place):** drawn on the design artifact, waiting for the user's pick (stacks by kind with a sheet per stack, or six named marks and "More ways"; threshold of 8 ways). Real numbers: Smugglers' Wharf shows 23 ways at once, the Ashen Quarter 18, the Ossuary and the Reliquary Quarter 13.

## Open PRs (14 Oct, after #230 merged as 1.295.0): Wave 4

- **[#231](https://github.com/warning18/NarrativeApp/pull/231): v1.296.0+332, the voyage in side view, step 1: the sea** (`sea_kit.dart`: sea by waters and weather, placeholder ship, flying hull; the hulls' own side views left for later). Tests pass locally.
- **E changed course (the user, 14 Oct):** not stacks. Split the map in two, a **high view** and a **city view with districts** (each its own ambiance), and adapt the same-place ways (quests) and the districts to match. UX is drawing a first city view on the design artifact (board 13) and will wait for the user's pick; the story's ways would be placed in districts by Narrative/Core, which is a later piece.

## E, the city view (board 13, 14 Oct)

Proposed to the user, waiting for their pick: the Journey's levels at a city become **city view** (the plan with its districts) → **district** (its own ring of 3 to 6 ways, with its ambiance), with the high view (Land, World) unchanged. First city: Saltmouth, six districts (the four it has: Landward Gate, Tern Row, Smugglers' Wharf, Ship-breaker's Yard; two proposed: the Lantern Alleys and Card Row); the hub's 23 ways are seated 6 + 5 + 3 + 5 + 1 + 3 by what they are about. Asks (if the user picks it): **Narrative** names, ambiance lines and re-tagging of the destination scenes' `location`; **Core** two `geography.json` records, the plan's spot for them, "show the party's district's ways", free walking between districts; **UX** the city view and the district ring. Nothing built; the earlier stacks idea (board 12) is dropped by the user.

## PR #232 (v1.297.0+333): voyage encounters and the port ahead
Raiders, derelict, sighting and sea beasts drawn beside the Eel; arrival shows a harbour scene. Hulls' side views still out until the user decides who draws them. Green CI: please merge.

## City models (board 14, 14 Oct; v2 organic)
The user asked for the city drawn like a real old city (Paris, Venice, Rome: crooked blocks, a river with an island and bridges, canals, a star of avenues, an arena) with a zoom into each district, **top-down only**; v2 of the board is organic, not a grid. Board 14 shows two top-down models over the same generated Saltmouth plan: **A** a cartographer's parchment plan, **B** the same plan in pixel art on the dark map card. Tapping a district zooms to its map, where each way is a pin on its own building. Waiting for the user's pick (A or B, the level of detail, pinch-zoom or tap-to-zoom only). Design only; nothing built. If picked: Core a per-city plan record (wall, shore, avenues, squares, district shapes, one anchor per way), Narrative the building names, UX the painter and the zoom.

## Hulls in side view (v1.298.0+334)
All 14 hulls drawn in the sea kit from their records (forms, rigs, castles, oars, twin, ironclad, the four flying boats), dressed with the worn looks. Parts still to do if wanted: the painted sail powers (one of each) on the side view, mounted guns and utility gear on deck, damage/repair states, the hulls in the fight and Harbor side views.

## Hulls in the Harbor and the raiders (v1.299.0+335)
The yard shows the Eel in side view above her plan (with the try-on of hulls, parts and looks); the raiders at sea use the same hull painter. Next, in the manager's order: damage states (smoke, list, patched sails by hull %, in the voyage scene), a side-view strip for the fight (the two real hulls facing each other above the grid; the fight itself stays from above), deck gear and mounted guns, painted sail powers.

## Damage states (v1.300.0+336)
The Eel's side view shows her hull: scorch, a hole, patched sails, smoke, rips, flames, and lower in the water, by hull %. Next: the fight strip (two real hulls facing each other above the grid; the fight stays from above), deck gear and mounted guns, painted sail powers.

## The fight strip (v1.301.0+337)
The sea battle shows the two hulls in side view (the Eel dressed and battered, the enemy's own hull or beast, easing apart with the range) above the sea on a tall screen (>= 720 high); the fight stays from above and `ship_battle_panel.dart` got only the strip. Next: deck gear and mounted guns, painted sail powers.
