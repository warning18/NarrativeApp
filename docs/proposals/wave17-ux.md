# Wave 17 on the look side (UX, for the user to choose)

Docs only. Nothing is built until the user picks. Written on v1.517, with #474 (the sea as the land, v1.518) green and waiting.

Wave 16 is shipped: the sheet kit, towns that change hands, the backdrops for frost, fen and sea cliffs, the ward card and its Journey mark, the town at the hour, the fight's entrance card and spoils strip, and the party on the Eel's deck with a word at sea. What is left on the look side is mostly the places where one of those stops half way. Five items. Sizes are for UX's part: **S** is one PR and under a day, **M** two or three days, **L** a design board first. Each item says what it needs from Core or Narrative; none needs both.

| # | Item | Size | Needs |
|---|---|---|---|
| 1 | The hour on the roads and at sea | M | nothing |
| 2 | The sea fight gets its entrance and its finish | M | Core: one flag on `enemy_ships.json` |
| 3 | The ruler's colour on the crossing, and a "what changed" list on the map | S + S | nothing |
| 4 | A reduced-motion and large-text sweep of the wave 16 screens | S | nothing (QA may add a guard) |
| 5 | The party's own faces | M | the user's art, or a decision to crop the portraits |

## 1. The hour on the roads and at sea (M)

**What the player gets.** The town plan already darkens at dusk and lights its windows at night (v1.515). The land crossing and the voyage still sit at noon: a crossing that starts in the evening should look like one. A warm wash at dawn, the dusk glow, a cold night wash with the stars out over the sea; the lanterns on the fen's boardwalk and the lighthouse on the cliffs burn brightest at night; the Eel's windows and her stern lantern light at dusk.

**How.** One new helper in `lib/widgets/side_view/` takes a `DayPhase` and tints the sky and the far layers of a kit, the way `city_chart_painter.dart` does for the plan; the land crossing and the voyage screen pass `dayPhaseProvider`. The three new kits already paint their own sky stops, so the work is a shared "at this hour" pass plus a few lit marks (desert and ruins get none, the fen and cliffs get theirs). With reduced motion nothing changes but the colours.

**Needs.** Nothing: Core's `dayPhaseProvider` is on main. If Core later makes the clock advance on a crossing (a long walk that ends at night) the wash follows with no change here.

**Risk.** The sea kit is the busiest painter; the wash is one extra pass over the sky rows only, not the water.

## 2. The sea fight gets its entrance and its finish (M)

**What the player gets.** A land fight opens on an entrance card and ends with a strip that counts the spoils (v1.517). The ship fight does neither: a raider or a sea beast just appears, and the win is a log line. Give it the same two things in the sea's own way: the raider's hull (or the beast) slides in from the right in the duel strip with its name and one line of the story, and a won fight counts up the gold, the prize part and the XP in a strip under the duel.

**How.** The card and the strip are already widgets (`fight_entrance.dart`, `fight_spoils_strip.dart`); the sea version feeds them from `ship_battle_panel.dart` (shared with Core) and `SeaDuelScene`. About 40 lines in the panel, the rest reuse.

**Needs.**
- Core: a flag on `enemy_ships.json` records, like `entranceCard` on enemies (a named raider or a beast gets a card, a skiff does not; every beast and the void barge would be the sensible default). One field and a helper like `hasEntranceCard`.
- Narrative: nothing; the records already have `description` and `description_fr`, and the card takes their first sentence.

**Risk.** `ship_battle_panel.dart` is a shared file; it is checked for open PRs before any edit.

## 3. The ruler's colour on the crossing, and a "what changed" list on the map (S + S)

**What the player gets.** Two pieces wave 16 left open.
- The crossing screen already carries the road's ruler (`LandCrossingScreen.ruler`, from Core's v1.512); nothing draws it. The header (and the first line of the day's event) takes the ruler's clan colour and name: "The road is held by the Compact", with the clan's little flag, so the player sees why the Writ toll is on this road and not another. The colour follows the ruler live, as the town tints do.
- The world chart's layers sheet gets a short list of the towns that changed hands since the player last looked (the toast of v1.503 says it once and is gone): the town, the old clan's flag, an arrow, the new clan's flag. It reads `townHandovers` and the same saved `seenTownRulers`, so it needs no new data.

**Needs.** Nothing. The strings are new but short; Narrative may reword them without renaming keys.

## 4. A reduced-motion and large-text sweep of the wave 16 screens (S)

**What the player gets.** Wave 16 added a lot of motion and a few narrow layouts: the entrance card, the spoils strip, the handover fade and toast, the ward sheet and its mark, the deck crew, the sea arrival. Each was written to stand still with reduced motion and was tried at 320 px, but not together at large text scale. One pass: every one of them at reduced motion, at 1.0, 1.3 and 1.6 text scale, in English and French, at 320 and 390 px wide, with a picture of each worst case. Fix what wraps or overlaps (the ward sheet's three length rows and the spoils strip's gold label are the likeliest).

**Needs.** Nothing. QA could turn the same list into a `qa_` guard (every wave 16 widget builds at 320 px and text scale 1.6 without an overflow), which would keep the next wave honest; that is QA's call and its file.

## 5. The party's own faces (M, needs the user's art or a decision)

**What the player gets.** On the land walk, on the deck and in the speech bubbles the companions are cloaked placeholders, each in a colour of its own; only the hero has walking frames. The companion strip and the portraits already have a pixel face for every companion. Two ways to give the figures faces:
- **With the user's art:** the walking and deck sprites come from the user, as the ronin's did; UX wires them (the sprite keys are already `companion_<id>`).
- **Without it:** crop and scale each companion's 64×64 portrait to a head-and-shoulders figure of eight to twelve pixels, drawn over the cloak. Cheaper, and good enough until the real frames arrive, but it will look like what it is.

**Needs.** The user's choice (and art, if the first). Nothing from Core or Narrative.

## Order I would suggest

3 first (small, finishes a half-built piece and gives the crossing its reason), then 4 (small and protects everything else), then 1 and 2, which are the two the player will see most. 5 waits on the user's art; the cropped version can be done at any time if the user prefers not to wait.
