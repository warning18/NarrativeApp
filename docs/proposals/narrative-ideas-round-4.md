# Narrative: ideas, round 4

New items only; nothing from rounds 1 to 3 or already shipped. Each one removes or
simplifies. Measured on `main` (v1.875), English text of `Cleaned_Narrative_DAG.json`
(479 scenes, 46,906 words) and the story files of `assets/gamedata/`.

## Ranked, my recommendation first

### 1. Cut the three crutch words, keep the best use of each — recommended
- **What:** three filler constructions recur across the scenes: *something* (85 uses
  in 78 scenes, twice in five of them: `270`, `1120`, `3005_clan_vigil_1`,
  `3005_wisp`, `3100_house_anvil_deaf_failed`), *the way* (84 in 80) and *as if*
  (52 in 51). Many stand in for a thing the author did not name ("something thrashed
  in razor wire", "something I decided was wine"). I read each and either name the
  thing, or cut the clause; the ones that carry a deliberate mystery stay.
- **Why:** an unnamed *something* is the weakest image in a sentence, and the story
  already runs on named things (the Lantern, the Hooded Lantern, the First).
- **Size:** M (about 220 hits, EN and FR together, I read each). **Risk:** low; a few
  tests pin a phrase, I list and update them. Words only, no flag or number moves.
- **The player notices:** sharper images, slightly shorter pages.

### 2. Own wording for the hub-return buttons (corrected after reading the code)
- **What:** two hubs end ten scenes with the same button: "Back into the Anchorage" (5 rows of
  `7100`) and "Head back toward the harbour master’s post" (5 rows of `2015`). Each now names
  what that scene just did ("Leave the helmsman to his cup"). The other repeated labels I first
  listed are not repeats of a formula: "Crawl out into the street" and "Get up and go home" are one
  scene's gold-loss variants, and "Begin again, changed" is the four endings' exit; all stay.
- **Why:** the same line after five different scenes reads as a menu, not a story.
- **Size:** S (10 labels, EN and FR). **Risk:** none found; flags and gold untouched.
- **The player notices:** each return button belongs to its scene.

(The first draft of this item proposed capping the nine four-line `*_walk` remarks. Withdrawn: the
walk bubble shows one line chosen at random, so the four lines are variants, not a sequence.)

### 3. Shorten the French where it runs a third longer than the English
- **What:** over 392 long scenes the French is on average 14 % longer than the
  English; 34 of them pass 900 French characters, and the longest ratios (`2015_sable`,
  `2015_sable_lifted`, `2015_cards`, `820`) reach 1.27 to 1.29. Tighten those 34 French
  scenes toward the English length, without changing the English.
- **Why:** the percussive cap is counted in English; the French page is the long one on
  a 320 px phone, and the nature of French does not need the extra words.
- **Size:** M (34 scenes, French only). **Risk:** low; the French lints (NBSP, « »,
  vous) stay green; I read each for meaning.
- **The player notices:** a French page that scrolls no further than the English one.

## What I would do first
1. **Item 2**, one small PR (10 labels; done in v1.878).
2. **Item 1**, the biggest read, after the bold trim has landed (they touch the same scenes).
3. **Item 3** last, French only.

## Not proposed (checked)
- 19 NPCs carry no spoken line (13 are shopkeepers): adds text, so I left it.
- 85 scenes have no incoming choice: they are reached by code (failures, flags); a QA
  guard rather than a story change.
- Politics news (108 variants, median 175 characters, two over 250): already tight.
- The 19 achievements and 51 quest names: no duplicates, no gaps.
