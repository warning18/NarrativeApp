# Narrative: improvements, second round

From the Narrative session to the manager. Scope as before: `assets/Cleaned_Narrative_DAG.json`, the story data in `assets/gamedata/` (quests, chapters, NPCs, companions and remarks, intrigues, politics events, achievements) and the EN/FR wording. **Only new items**: nothing here repeats `narrative-improvements.md` (labels, callbacks, long scenes, repeated epilogue, parked `270`, narrator tics, replies) or anything merged since. Counts were made with a script on `main` at v1.751. No content change, nothing built.

## What I looked for and did not find

Said first so nobody pays for work that is not needed.

- **Quests with no reward or no way in: none.** All 51 quests pay gold, XP, an item, a die or an ally; every `nextQuestID` exists; every quest has objectives and an FR name and dialogue.
- **Characters who vanish: none that are bugs.** 80 NPCs, every `metNodes` id exists. Five (`old_hesk`, `mother_hesk`, `rat_matriarch`, `drowned_courier`, `frozen_pilgrim`) are met in one scene and have no dialogue lines: that is how they were written, not a hole.
- **Text that exists in one language only, or FR identical to EN: none.** Every scene, choice, quest, NPC and remark has both; no FR line equals its EN line.
- **Companion remarks:** the gaps between companions (for example no `cruelApproved` for Kelda) follow each one's temperament. Not a fault.
- **Dead branches:** I could not prove any. Flags such as `origin_*`, `house_*`, `pledged_*` and `host_*` are built by code, so a static search cannot call them dead; the simulator can (QA).

## Ranked items

### 1. Stop callbacks stacking into a wall [tightens] — value high, effort S to M

- **What:** a scene shows every callback its flags have earned, with no limit (`firedCallbacks` in `story_node.dart`). The ceiling is large: `7800` (the muster) has 70 callbacks worth up to **8,963 characters** under an 840-character scene; `7005_dawn` 4,786; `7004` 3,829; `7400` 3,083; `7001` 3,022; `7500` 2,892. Across the DAG, 1,010 callbacks hold 129,000 characters, 53% of the scene text.
- **Why:** a player who did everything gets the longest page of the game on the muster night, and one who did little gets a short one; the wall is the best-played run's reward.
- **Plan:** (a) QA's simulator measures how many callbacks really fire per scene over a few runs, so the cap is set on data; (b) Core adds an optional `priority` on a callback and a per-scene cap (say 5), the rest folded into a one-line "and the others" or dropped; (c) Narrative sets the priorities on the six scenes above.
- **Size:** S for the data, M for code and priorities. **Risk:** a payoff a player earned goes unseen; mitigated by ranking the most specific first and keeping every ending payoff. **Player notices:** the muster and ending pages stop being a scroll.

### 2. Use `[PAGE]` on the ten scenes still over their cap, instead of cutting more [tightens] — value medium, effort S

- **What:** after v1.719 and v1.751, ten scenes sit between 860 and 920 English characters (FR 930 to 1050) with a natural beat in the middle: `400`, `470`, `6010_thread`, `1200`, `6002`, `7400`, `2015_dockside`, `4999_drawn`, `5004b`, `5004`.
- **Why:** the percussive cap is a reading rhythm. A page-turn at the beat keeps every word and gets the pages under 600. Cutting further now would cost facts.
- **Size:** S, one PR, EN and FR together. **Risk:** low; `narration_pages_test` and `new_game_start_test` pin the four endings at two pages, so those are left alone. A scene whose test pins a phrase stays whole across pages. **Player notices:** fewer long pages on a small phone; one tap more on ten scenes.

### 3. Retire the hub rows that do nothing [removes] — value low after checking (see `hub-rows-candidates.md`: only 12 rows qualify, 3 are thin), effort M

- **What:** the big hubs list rows whose scene has no fight, no gold, no alignment and no flag beyond the hub's own: they read a short scene and return. Counts: `2015` 11 of its 36 rows (`2015_bazaar`, `2015_apothecary`, `2015_informant`, `2015_ternrow`, `2015_cards`, `2015_liora`, `2015_dorran`, `2015_vane`, and three more), `6010` 6, `5010` 6, `7100` 3, `3005` 2, `7200` 1, `5100` 1. `2015` shows up to 25 ungated buttons at once.
- **Why:** choice overload on a 320 px screen, and each flavor row has the same weight as a quest. Folding the ones that only give a line into the hub's own description or into a companion remark keeps the voice and loses the button.
- **Plan:** I list the candidates with what each one says; the manager keeps or drops each; where a row carries a fact later scenes cite, it stays.
- **Size:** M (about 25 rows, plus the tests that count hub rows). **Risk:** `story_rules_test`, `qa_story_blocking_test` and the Saltmouth place tests pin rows; a hub-by-hub PR with its tests, as for the labels. **Player notices:** shorter hub menus, quicker to the rows that matter.

### 4. A shorter text when a hub is re-entered [tightens] — value medium, effort M (needs Core)

- **What:** hubs are re-entered by many edges: `2015` has 78 incoming choices, `6010` 63, `7200` 53, `3005` 51, `4999_camp` 48, `5010` 40, `7100` 39. Each return re-reads the full hub description (370 to 600 characters) and its callbacks. These are edges, not visits; a run's real return count should be measured (QA).
- **Plan:** an optional `revisit_description` (EN/FR) a hub uses after the first visit, one or two sentences. Core adds the field; Narrative writes about ten lines.
- **Risk:** low, falls back to the full text. **Player notices:** the hub no longer re-tells itself every time you come back.

### 5. A dead field on 44 NPCs [removes] — value low, effort S (Core's call)

- **What:** `stanceLeader` (`loyal`, `scheming`, `wavering`) is set on 44 entries of `npcs.json` and read by no code in `lib`, `test` or `tool`; only the old design note `docs/proposals/clan-courts.md` mentions it.
- **Why:** data that nothing reads drifts out of date. Either the clan courts use it (then wire it) or it goes.
- **Size:** S. **Risk:** none if unused. **Player notices:** nothing.

### 6. Prices inside choice labels [tightens] — value low, effort M (UX and Core)

- **What:** 31 labels end in a number in brackets, such as "Pay the toll (30 gold)". They read as a menu, not as a line the narrator speaks. Showing the price as a chip on the button would let the label be the story.
- **Risk:** `qa_chapter1_test` pins "10 pièces d’or" in a French label and other tests look labels up by text, so this is a code change first. **Player notices:** cleaner bubbles; nothing is hidden because the chip still shows the cost. Recommend: only if UX already plans a button chip.

## What I would build, in order

1. **Item 2** (pages on ten scenes): one small PR, no risk.
2. **Item 1(a)**: QA's measurement, then the cap with Core.
3. **Item 3**, hub by hub, after I send the candidate list.
4. **Item 4** once Core agrees to the field.
5. **Items 5 and 6**: Core and UX's call.

## Not proposed

- No new scenes, quests or characters.
- Shared callbacks, narrator tics: still skipped (first note).
- The opening scene `0` stays untouched until UX-2's animation ships.
