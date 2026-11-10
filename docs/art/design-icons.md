# Design proposal: one icon language for the whole game (phase 1, nothing wired)

> **Decision (the user, 2026-11-10): "For icons don't redraw, mix with the original style."** The 289 existing pixel icons (157 skills, 132 items) stay the base: we **harmonise, don't redraw**. Only the shared palette, one ink colour, the size scale and the gaps change; everything new is drawn in the original icons' style (outlined 16 px gems and objects, 2 to 3 tones), not in the chunkier first-pilot style below. Sections 1 to 6 are the first pilot (kept for the rules and the counts); **section 7 is the mix pilot and what applies.**

Inventory: UX-2's `docs/ux-shots/icons-inventory/` (branch `claude/ux-2-icons-inventory`). Pilot sheet: `docs/art/boards/icons-pilot.png`. Pilot files: `art/pixellab-pilots/icons/` (`world/` full colour, `chrome/` tintable masks, generator `icons_gen.py`). Pilot cost: **3 generations** (the PixelLab comparison); everything else is hand-drawn, 0.

Scope (as sent): UI icons only. Portraits, sprites, chapter strips, tower bands and dice bodies follow the character style track.

## The problem in one line
A pixel world shown through a vector UI: 377 pixel PNG icons, and 378 distinct Material glyphs used 1,255 times in 163 files, at sizes 18/16/20/14 dp that are not a pixel scale.

## 1. The style guide
**Two kinds of icon, one look**
- **World icons** (things in the game: skills, items, enemies, shops, die kinds, elements, journey glyphs): full colour, fixed.
- **Chrome glyphs** (chevron, lock, check, close, add, arrows, home, map, settings...): a one-colour mask the theme tints (`onSurface`, gold when lit, bone on dark), so light, dark and disabled states cost nothing. No outline; the shape alone is the glyph.

**Grid and scale (answers a)**
- **16x16 native** for rows, chips, stats bar, lists, die badges. Drawn at **16, 32 or 48 dp** (1x, 2x, 3x), never 18, 20 or 14.
- **24x24 native** only for the nav bar, header, main menu and map pins (drawn at 24 or 48 dp). 32x32 stays for chests and the few big marks.
- A size token set in `lib/theme` (16, 24, 32, 48), so a screen never asks for 18. The 108 uses at 18 dp become 16; the 49 at 20 become 16 or 32 by the row's height.
- `FilterQuality.none` always, whole multiples only.

**Rules the code applies** (`icons_gen.py: finish()`, so the set stays coherent):
1. **Outline:** 1 px ink `#17120F` around the silhouette (world icons). Inner lines use a darker tone of the fill, never ink.
2. **Light from the top-left:** pixels on a top or left edge are 28% lighter, bottom or right edge pixels 28% darker. One highlight, one shade, no gradients, no dithering.
3. **Flat front view.** Three-quarter view only for chests and shop fronts.
4. **Chunky proportions** like the main hero (chibi, thick shapes): minimum stroke 2 px (3 px for a chevron), no detail smaller than 2 px, at most 4 colours plus ink.
5. **Kinds are told apart by silhouette first, colour second** (so they survive colour blindness and 16 px): attack = blade, defend = shield, heal = heart, mana = drop, poison = skull, element = its own shape (bolt, snowflake, sun, crescent, ring).

**Palette (21 colours: the theme tokens plus the hero's browns and greys)**
ink `#17120F`, bone `#E9DFC4`, ash `#CFC4AE`, steel `#A8A194` / `#6B6356`, gold `#F2C14E` / `#B8862A`, blood `#D9544D` / `#A5302A`, ember `#E0762B` / `#A84E12`, tide `#4FB0B0` / `#226565`, heal `#7DBE6A` / `#3D7A2C`, void `#A987EA` / `#6A4FB0`, wood `#8A5A2B` / `#5A3A1C`, ice `#CFE6F2`, white. (Source: `lib/theme/palette.dart` tokens; wood, steel and bone match the main hero sprite.)

**Readable at 16 px:** the pilot sheet shows each at 1x and 4x on the parchment and on the dark surface; the outline keeps every colour icon legible on both.

## 2. Replacing the Material glyphs (answers b)
Counted from `lib/` (`Icons.*`, outlined/rounded/sharp variants merged into one glyph): **298 base glyphs, 1,255 uses.**

| Pixel glyphs drawn | Share of all uses covered |
|---|---|
| 42 | 50% |
| 62 | 60% |
| 90 | 70% |
| 127 | 80% |
| 187 | 90% |

So a few dozen do **not** cover 90%: the use is a long tail. The first 62 glyphs cover 60% and are mostly the same ideas the game already draws (fire, die, shield, flag, sailing, check, anchor, bolt, map, heart, book, trophy, scales...). **Recommendation:** v1 = about 60 pixel glyphs (chrome and world), then the rest by family; what is left stays Material for now. The top of the ranking (merged): chevron_right 42, lock 40, local_fire_department 32, casino 32, shield 29, auto_awesome 25, flag 22, sailing 20, check_circle 20, visibility 18, check 17, anchor 16, bolt 16, arrow_forward 15, storefront 14, map 13, favorite 13, menu_book 12, sports_martial_arts 12, emoji_events 12, balance 12, add 12, explore 11, close 11. The pilot draws the first 10 in context (header, stats bar, nav bar, a button): chevron, lock, check, close, add, arrow, flag, home, map, settings as tintable masks, and flame, die, shield, anchor, bolt, sparkle, heart as world icons.

## 3. The gaps (answers c)
- **5 elements** drawing an empty circle (lightning, ice, holy, dark, none): drawn in the pilot (bolt, snowflake, sun, crescent, ring).
- **14 enemies without an icon:** derive from the new fight sprites (crop and box-reduce to 16 px with the dice-cut recipe, 0 generations), or 1 generation each in pixen if a sprite is missing.
- **2 items and 5 skills without an icon:** hand-drawn, 0 (or pixen 7).

## 4. Per family: PixelLab or hand-drawn, count and cost
| Family | Count | Method | Cost (generations) |
|---|---|---|---|
| Skills | 157 + 5 missing | keep the PNGs; hand-draw the 5 missing and the odd ones; a palette and outline normalisation pass by code | 0 (pixen 5) |
| Items | 132 + 2 | the same | 0 (pixen 2) |
| Enemies | 64 + 14 | derive the 14 from the new sprites | 0 (pixen 14) |
| Shops | 14 | keep | 0 |
| Chests | 10 | the new 32x32 set (v1.899) is the target; the 16 px ones follow | 0 |
| Die face kinds | 8 | hand-drawn (pilot: attack, mana, poison) | 0 |
| Rule words | 6 | hand-drawn | 0 |
| Elements | 9 | hand-drawn (5 gaps in the pilot) | 0 |
| Spell effects | 5 | hand-drawn | 0 |
| Game lookups | 62 | hand-drawn, merged with the first 62 glyphs | 0 |
| Journey glyphs | 33 | hand-drawn | 0 |
| Stats bar, header, nav, main menu | 25 + 7 | chrome masks, 24 grid for nav and menu | 0 |
| Map pins and marks | 20 banner pins + painted | banners are done (v2); the place and way marks hand-drawn | 0 |
| Material rest (the long tail) | about 230 more | v2, family by family, only if the user wants it | 0 (pixen about 230) |
Total: **0 generations** by hand; about 21 if the model does the gaps. **Why hand-drawn:** at 16 px the model's pixen result (3 generations in the pilot) keeps its own proportions, outline weight and shading, so every icon would need the same clean-up the hand-drawn ones get for free from the two rules; consistency is the goal. PixelLab stays the right tool above 32 px (chests, sprites, banners).

## 5. What changes in the app (UX-2's part, later)
A `PixelGlyph` widget that tints a mask and a size-token set; a family-by-family swap behind the user's approval. Ids, names and numbers never change.


## 6. Update (user priority: skills, event/journey interface, UI first): the skill badge system
Sheet: `docs/art/boards/icons-pilot-skills-journey.png`. Files: `art/pixellab-pilots/icons/skills/` (9 pilots) and `world/` (tree, mountains, paw, waves, eye, compass, pin). Order of work after approval: **1 skills, 2 event and journey glyphs, 3 items, 4 elements, 5 die kinds and rule words, 6 the top Material glyphs of the header, nav bar and buttons.**

**What the 162 skill icons are today:** a badge (diamond, shield, octagon, framed square) with a glyph in it, but the container does not follow anything: `rarity` (common 29, uncommon 36, rare 45, epic 43, legendary 9) and `element` (None 41, Earth 28, Fire 23, Wind 20, Void 17, Water 11, Light 11, Electricity 7, Ice 4) are both in `skills.json`, and the shapes mix freely across them.
**Proposal (pilot drawn):** the badge becomes a code, so a player reads rarity and element before the glyph:
- **Container = rarity:** common diamond, uncommon rounded square, rare shield, epic octagon, legendary gold frame.
- **Fill = element:** Fire ember, Water tide, Earth wood, Wind ice, Electricity gold, Ice pale blue, Light bone, Void violet, None steel.
- **Glyph = the skill's subject**, 10x10 white inside the 1 px rim. About 60 reusable motifs (flame, flake, bolt, dagger, shield, sword, orb, sun, wind, rock, fist, arrow, heart, hand, eye, skull...) cover the 162 skills; the badge itself is composed by code from (rarity, element, motif): 5 x 9 = 45 containers, so only the motifs are drawn.
**Honest findings:** at 16 px the glyph has about 10 px, so it works for strong silhouettes (flame, flake, bolt, dagger) and not for fine ones; the 20 skills that are 32x32 today keep a bigger glyph (the same badge at 32 px). Today's icons carry more individual detail than a composed badge: the trade is coherence for detail. The user should look at the sheet before we draw the 60 motifs.
**Cost:** 0 generations (hand-drawn, composed by code). Effort: 60 motifs plus 5 missing skills (the dice-tampering moves that borrow another's icon). PixelLab alternative: 162 x 1 = about 162 generations plus a clean-up pass to a common outline; not recommended at 16 px.

**Event and journey glyphs:** the 33 journey way glyphs (Material today) become world icons (pilot: tree, mountains, paw, waves, eye, compass) and the map pin; road-event and quest marks follow as 24x24 pins (a coloured teardrop with a 10 px glyph) so a mark's kind reads from its colour and shape. 0 generations, hand-drawn.


## 7. Mix pilot: harmonise, don't redraw (the decision above)
Sheet: `docs/art/boards/icons-pilot-mix.png`. Files: `art/pixellab-pilots/icons/mix/` (palette PNGs), `shared_palette.json`, generators `harmonise_gen.py` and `mix_sheet_gen.py`. **0 generations.**

**What the originals already do (measured on all 289 PNGs):** every icon has a 1 px dark outline (`#0A0807` in 10,071 pixels, `#18121C` in 1,514); 269 are 16x16 and 20 are 32x32; 467 distinct colours in total. So the outline rule is already met, and what drifts is two near-black inks and a long tail of one-off colours.

**Harmonisation (applies to every skill and item icon, by script, drawings untouched):**
1. **One ink:** every near-black outline pixel becomes `#0A0807`.
2. **Shared palette of 63 colours:** `palette.dart` tokens (16), the hero's browns and greys (10), and the originals' 40 most used colours, merged within a small distance. Every pixel snaps to the nearest. Measured change on 60 icons: 5.6 out of 255 on average, so each icon still looks like itself (see the (a) columns).
3. **Light from the top-left:** the originals already follow it; new pieces follow it; nothing is changed on existing icons.
4. **Size scale:** 16 native drawn at 16, 32 or 48 dp; the 20 skills and 6 chests that are 32 native drawn at 32 or 64 dp; 24 native only for nav, header and menu.

**Skills, two variants of the same 9 icons (today | a | b):**
- **(a) harmonised only:** the original badge and glyph, palette and ink unified. Nearly identical to today by design.
- **(b) the original glyph in the rarity frame and element colour:** the glyph pixels are cut out of the original (the pixels inside the container that are not its colour family) and set in the rarity container (common diamond, uncommon rounded square, rare shield, epic octagon, legendary gold frame) filled with the element's colour. Works for the badge-style skills (8 of 9 in the pilot). **Object-style icons** (a sword or a dagger with no container, e.g. rogue_backstab) get the rarity/element plate behind the original drawing instead. A 32 px skill gets the same frame at 32 px (not piloted). Cost: 0. Honest note: (b) changes every skill's silhouette, so the user may prefer (a) for everything and (b) only for the legendary and epic skills.

**Items:** harmonised only (palette and ink); the drawings are untouched.

**Gaps, drawn in the original style (next to a neighbouring original on the sheet):**
- 5 elements (lightning, ice, holy, dark, none) as the original common gem with a cream glyph, in the element's colour ramp.
- 5 skills with no icon (edict_of_silence, glass_reflection, hex_of_ill_luck, rotting_mark, shroud_reflection) as common gems with new glyphs (lips, mirror, a crossed die, a skull blotch, a shroud).
- 2 items (boss_trophy, fate_coin) as outlined objects.
- 6 journey glyphs (tree, mountains, paw, waves, eye, compass) as outlined objects.

**Material replacements, drawn to match the originals:** the top 12 (chevron, lock, check, close, add, arrow, flag, home, map, settings, person, more) as outlined, two-tone pixel glyphs at 16 px, shown in a header, stats bar, nav bar and a button. Trade-off: they are fixed colours, so no theme tint; plain chrome (chevron, close, add) can still use the one-colour masks from the first pilot if the user prefers.

**Cost and method per family (updated):** skills and items: harmonise by script (289 icons, 0 generations); skill variant (b): 0; gaps (5 + 5 + 2 + 6 + 5 elements): hand-drawn, 0, done in the pilot; Material replacement: hand-drawn in the same style, 0 for the first 60 (about 60% of the uses), the long tail later; enemies, shops, chests: keep (harmonise the palette only). Total generations: 0.
