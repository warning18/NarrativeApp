# Three UX items from the user: pictures first (UX-2, no code)

Pictures: `docs/ux-shots/character-three/` on `claude/ux-2-pictures` (412 px, EN, plus FR with the longest strings, before/after).

## 1. A radar instead of the skill list, a Detail tab for the list (`character-radar-designs.png`)
What exists (v1.267): the Overview tab already has the **ability radar** (eight abilities) in a card, then up to six **skills as chips**, then the alignment. I read "a radar instead of the skill list" as: the chips go, a radar of the skills takes their place, and the list moves behind "Detail". If the user meant something else (for instance only the eight numbers), tell me.
- **A · two radars + a Detail tab**: abilities and skills-by-element side by side (small, ~100 px polygons), a new Detail tab (Overview · Detail · Gifts · Pages) with the eight numbers, the skills per element with bars, the first chips and "All skills". Overview about 430 px (today about 700).
- **B · one radar + a switch**: the card keeps one radar; a switch under it: Abilities · Skills · Detail. Same three tabs. About 540 px.
- **Data**: the skills radar's axes are the **elements of `skills.json`** (Fire, Water, Wind, Earth, Light, Void, Electricity, Ice; `None` skills have no axis), each axis = the number of known skills of that element (or their tiers); the known skills already come from `watchSkillsModel(...).knownIds`. **Core provides nothing**; the radar widget (`ability_radar.dart`) takes any eight values, scale per axis to be settled (the count of skills of that element the character can reach).
- FR: the switch "Caractéristiques · Compétences · Détail" is the longest line and just fits at 412 px; at 320 px it needs the short forms (the radar's own abbreviations).

## 2. A smaller Shroud (`character-shroud-designs.png`)
Today (Pages tab) `_ShroudCard` is about 140 px: title row + six banners at 40 × 80.
- **A · one line, ~46 px**: six 14 × 28 mini banners inline with the count; a tap opens a sheet with today's banners (same size and tooltips).
- **B · a fold, ~44 px**: a progress bar and the count; unfolded it shows the banners at 28 × 56 in place.
- FR: "Le Linceul, en morceaux" does not fit a strip: A shortens to "Linceul", B to "Le Linceul"; the full title stays in the sheet / the unfolded card. **Data**: `bannerPiecesCollected` (exists). Core provides nothing.

## 3. Skippable tutorial animations (`tutorial-skip-designs.png`)
What exists: **18 guide tours** (`lib/tutorial/tutorial_topics.dart`: story, journey, character, camp, other, map, skills, dice, inventory, signs, fight, boat, voyage, expedition, town, shop, journal, achievements), all one machine (`guide_tour.dart`): the guide walks to the lit part, the words type out, Next or a tap goes on. **A Skip button already shows on every step and ends the tour, and the tour is marked seen when it starts**, so a skipped tour does not come back; Settings has one Tutorials switch and a Replay button. Not tours but animated: the opening (tap skips, v1.654), the "New:" card (leaves after 6 s or Later), the pulsing "new" dots. So I need to know **what the user could not skip**: my guess is the walk + typing of each step, or that Skip is not seen. Two designs:
- **A · "Don't show tutorials again"** as a small link in the bubble: it switches off the Tutorials setting (remembered); Replay brings them back.
- **B · "Fast guide"**: a toggle in the bubble, remembered as Settings › Guide animation (Full / Fast): the guide is already at the lit part and the words come whole; the tours still play.
- **Data**: A reuses `tutorialProvider.enabled`; B needs one new remembered bool in `tutorial_provider.dart` (Core's file, a few lines). No gamedata. Strings (EN + FR) mine.
