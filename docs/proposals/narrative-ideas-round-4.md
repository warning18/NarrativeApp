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

### 2. Cap companion remarks at three lines
- **What:** 278 remarks: 72 have one line, 153 two, 44 three, and 9 four. The nine
  four-line ones are the `*_walk` remarks (`tobin_walk` 305 characters, `sable_walk` 296,
  `kelda_walk` 295, `malrik_walk` 294, and five more). Cut each to three lines by
  merging the two shortest; no line is rewritten.
- **Why:** a remark is a companion's aside under a scene; at four lines it is a
  second scene, and it is the only place the pages can still grow.
- **Size:** S (nine remarks, EN and FR; 9 lines removed). **Risk:** none found;
  `companion_remarks_test` counts remarks, not lines.
- **The player notices:** the nine longest asides land in one glance.

### 3. Give the return-and-retreat buttons their own wording
- **What:** five formula labels are reused as the exit of many scenes: "Crawl out into
  the street" (5), "Head back toward the harbour master’s post" (5), "Back into the
  Anchorage" (5), "Get up and go home" (4), "Begin again, changed" (4); plus
  "Continue" (3), "Fight" (3) and "Proceed to Chapter 2" (3). 32 labels in all. Keep the
  last four as they are (they are navigation); rewrite the first five so each names what
  that scene just did ("Crawl out with the bandits’ laughter behind you").
- **Why:** the same line after five different failures reads as a menu, not a story.
- **Size:** S (23 labels, EN and FR). **Risk:** low; flags and gold untouched;
  a few tests look a label up by text, I update those.
- **The player notices:** a failed scene ends on a line that belongs to it.

### 4. Shorten the French where it runs a third longer than the English
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
1. **Item 2** and **item 3** together, one small PR (about 32 strings).
2. **Item 1**, the biggest read, after the bold trim has landed (they touch the same scenes).
3. **Item 4** last, French only.

## Not proposed (checked)
- 19 NPCs carry no spoken line (13 are shopkeepers): adds text, so I left it.
- 85 scenes have no incoming choice: they are reached by code (failures, flags); a QA
  guard rather than a story change.
- Politics news (108 variants, median 175 characters, two over 250): already tight.
- The 19 achievements and 51 quest names: no duplicates, no gaps.
