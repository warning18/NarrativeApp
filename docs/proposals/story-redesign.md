# An overall update of the story side's design (UX-2, pictures only)

The user asked for "an overall update of the design for the story game, according to the existing one". No new style: bring the story screens up to what shipped this week (the PixelLab rarity frames, the clan colours, banners and backdrops, the fight blocks' nameplates and gems, the scene bands, Apollo). Pictures only; nothing in `lib/` changes. The mocks are `test/ux_story_audit_shots_test.dart` (the real app) and `test/ux_story_redesign_test.dart` (UX_SHOTS=<folder>).

## 1. Audit: where we start
`docs/ux-shots/story-audit/audit-dark.png` and `audit-light.png`: eleven real screens at 360, one line under each (the eleven pictures are in the same folder; `make_sheet.py` builds the sheets). In short:
- **The new look is on the surfaces that were redrawn**: the main menu's banner, the scene band, the speaker strip, the map, the throne. Around them the story side is still flat Material: plain dark cards, round chat icons, tab bars, collapsing rows, a word for a rarity, a grey chip for a clan.
- **None of the week's pieces reaches it**: no rarity frame on a rare choice or a rare item, no clan colour or banner on a clan's NPC, choice or quest, no nameplates or gems, no clan backdrop.

## 2. Three directions
Pictures, `docs/ux-shots/story-redesign/`: `overview-dark.png` and `overview-light.png` (three directions across the five screens, 360 wide), and each screen alone (`a-scene-dark.png`, `b-npc-light.png`, ...; a|b|c, scene|npc|chapter|quests|character). Real text (the Saltmouth scene, Aurel Vane's own lines, chapter 3's hint, the chapter 2 quests, the real items), English, dark and light. The 9-slice frames are Art's five card frames stretched round any box (the 6 art-pixel band kept at 2 dp, the middle left empty): no new art is needed to see them.

| | A Illuminated page | B Board and plates | C Quiet book |
|---|---|---|---|
| Idea | the story as a framed ink page: drop caps, the scene band in a bronze frame, choices as small framed cards, a clan tab where a choice touches a clan | the fight screen's system everywhere: a nameplate band, plates and gems (alignment, gold, XP, standing) | calm and large: 18 dp type, hairlines, no boxes; frames and colour only for what weighs |
| Rarity and clan | a frame tier by the weight of the outcome or the reward's rarity; a clan tab and emblem | the clan's colour on the nameplate and its emblem; a rarity-coloured pixel border on items | one framed row for a clan or a weighty choice, a framed item for a rare reward, the rest plain |
| Reads best for | the story, NPCs, the chapter title | the state screens: character, quests, clans | long reading; a phone in the dark |
| Risk | a lot of frame: the heaviest on a light page and on a small phone | boxes on boxes: the text screens feel like a UI, less like a book | the least new: the game may still read as flat |

My pick is a mix: **C's quiet type for the reading screens (scene, NPC, chapter), A's frames for what weighs (a clan choice, a rare reward, a rare item), B's plates and gems for the state screens (character, quests, clans).** One rule for the player: text is a page, state is a plate, weight is a frame.

### Cost to build (PRs, files; * = shared file, check for open PRs first)
Common first PR for any of them: `lib/widgets/story_panel.dart` (the 9-slice `Framed`, `Plate` and `Gem`, the same pieces as the fight block, so `fight_block.dart` can share them) plus its test: about a day's work, no data change.
- **A**: 4 more PRs. Scene and choices (`lib/screens/story_player_screen.dart`*, `story_player/story_choice_widgets.dart`*, `lib/widgets/story_text.dart`, the Journey's scene page*); NPC and chapter (`npc_detail_screen.dart`*, `home_shell.dart`* for the chapter title); journal and quests (`journal_screen.dart`*, `quest_tracker.dart`); character and inventory (`character_screen.dart`*, `inventory_screen.dart`*). 5 PRs in all.
- **B**: the same screens, the same 5 PRs; the character sheet and the quests are the most work (gems, bars).
- **C**: the smallest: a type scale for the reading screens (one token file) and the same files with less decoration. 3 PRs: the kit and the scene; NPC and chapter; journal and character.
- **The mix**: 5 PRs (the kit, the reading screens, the quests and journal, the character and inventory, the clans screen), in that order, each showing in the game as it merges.

### What it needs from Art (names, no cost yet; I will not ask Art directly)
- **A**: nothing to start. Optional: a parchment or ink panel fill (104 x 76 art px, tileable) per tier, drop-cap letters in the display font (26 letters, or a cap in the clan colours), a divider ornament, and a scroll ribbon. 
- **B**: nothing to start. Optional: a PixelLab button slab (idle, pressed, disabled) in gold and in the clan colours, and nameplate end-caps.
- **C**: nothing. Optional: one hairline ornament for chapter titles.
- **The mix**: nothing to start; the optional pieces above can follow one by one.

### What it needs from Core or Narrative (no rule or text changes)
- A choice that "touches a clan" and one that "weighs": probably derivable from a choice's existing standing and alignment effects (Core to confirm that a choice record exposes them); if not, a `clan` field per choice that Narrative or Core adds.
- A quest's clan (`quests.json` has no clan): a `clan` field on a quest (Narrative; the giver's faction can fill it by a script).
- Everything else exists: an NPC's `faction`, a chapter's `recommendedLevel` and main quest, an item's `rarity`, a quest's reward item.

## 3. To decide
One direction (or the mix); whether the chapter title gets its own full screen (the mocks show one) or stays the app bar's number and name; the clans screen is not drawn here (the mix would give it plates for each clan, with its banner and backdrop).
