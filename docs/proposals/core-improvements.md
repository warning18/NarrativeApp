# Core: improvements within Core's scope (proposal, v1.698)

Analysis only, no code. Measured on `main` at v1.696–v1.698 with:
- the QA scanners (`tool/qa_unused.py`, `qa_unused_fields.py`, `qa_duplicates.py`, `qa_size.py`, `qa_xref_audit.py`);
- grep, every claim below checked by hand;
- two throwaway timing tests (JIT on desktop; a phone in release is about the same or up to 2× slower);
- one simulator batch: 50 competent and 50 naive playthroughs, the 25 race × profession pairs twice, `seed: 11`, default flags, about 45 s.

Nothing here adds a feature. Each item says what, why (evidence), risk, effort (S < ½ day, M ~1 day, L > 1 day), and what the player would notice. Tags:
- **[−]** removes or simplifies code or data
- **[⚡]** makes the app faster or lighter
- **[⚖]** a balance or consistency fix

Section 4 folds in the cleanup plan's waves 3c, 4 and 5 (`docs/qa/code-cleanup-plan.md`) for Core's files. Section 5 gives the order and one PR per step, with versions from v1.702 as the Manager assigned.

## 1. Ranked list (value over effort)

| # | Item | Tag | Effort | Risk | Player notices |
|---|---|---|---|---|---|
| 1 | P2 `loadedGameDb` uses the cached localized table | ⚡ | S | low | French: 20–60 ms less at each scene change and fight start |
| 2 | R1 delete the two editor-only tables (`gates`, `adventure_nodes`) | − | S | low | nothing |
| 3 | R2 delete the three enemy move thresholds (always 0) | − | S | low | nothing (the editor loses three fields that do nothing) |
| 4 | P1 the fight stops saving and rebuilding the app on every mana gain | ⚡ | M | medium | smoother fights; fewer storage writes |
| 5 | P5 cap the standing log at 100, leave default fields out of the save | ⚡ | S | low | smaller save (late game 13.7 KB, growing to ~80 KB); slightly faster load |
| 6 | P3 parse the story and the city plans off the main thread | ⚡ | S | low | about 80 ms less on the first Journey frame |
| 7 | B1 why the competent player keeps the starter die (30/50) | ⚖ | M | n/a (investigation) | none until fixed; then dice worth taking |
| 8 | B2 nine of 14 shops never found in the simulator | ⚖ | S (look) | n/a | none until settled |
| 9 | R3 unread or duplicated gamedata fields | − ⚖ | S | low | nothing; `void_banner`'s stray `damage: 25` gone |
| 10 | P4 `select` on providers that watch the whole session or story | ⚡ | M (2–3 PRs) | low | fewer rebuilds of the always-visible bar and the Journey |
| 11 | R5 one new-game build and one XP rule for the game and the simulator | − ⚖ | M | low | nothing (the simulator stops drifting from the game) |
| 12 | B3 `void_banner` is worn in 50/50 competent runs | ⚖ | S (look) | medium (a balance number: the user decides) | one item stops being the only answer |
| 13 | B4 the competent player loses rat_matriarch more than the naive one (54% vs 27%) | ⚖ | S (look) | n/a | an early fight that's fair |
| 14 | R4 dead and test-only symbols in Core (1 dead, ~45 test-only) | − | S per batch | low | nothing |
| 15 | P6 small repeated parses (detour pools, `game_config` ×3) | ⚡ | S | low | a few ms per detour |
| 16 | Wave 4 file splits (section 4) | − | M each | low per split | nothing |

## 2. The items

### P1 [⚡] The fight saves the whole session on every mana gain
- **Where:** `fight_rounds.dart:646` and `fight_actions.dart:358` call `setMana` during rounds. `setMana` (`player_session_provider.dart:5801`) sets the state and awaits `_persist()`.
- **Cost of `_persist`:** it JSON-encodes the whole session (13.7 KB late game, 0.58 ms) and writes it to SharedPreferences. It has 128 call sites and no debounce, so a reward screen with five changes writes five times.
- **Rebuilds:** each mana change also rebuilds everything that watches the whole session behind the fight: `journey_screen.dart:1537` (its 1,600-line `build`), `HomeShell` through `tabBadgesProvider`, and `story_player_screen.dart:247`.
- **Fix:**
  - (a) keep mana in the fight's state and commit it once when the fight ends (fight_rewards already sets it at the end);
  - (b) coalesce `_persist` (one write per ~300 ms, flushed when the app pauses or closes).
- **Risk:** medium. With (a), a fight the app is killed in loses its mana gains; it isn't resumable today anyway. With (b), the last 300 ms of changes can be lost on a crash; the pause flush covers a normal close.
- **Test:** the fight tests, plus a test that counts `_persist` calls in a scripted fight (it should drop from one per mana gain to one).

### P2 [⚡] `loadedGameDb` rebuilds the localized table on each call
- **Where:** `game_db_providers.dart:97`. It runs `withResolvedPlaceholders` and, in French, a deep-copy `frenchOverlay` every time.
- **Measured per call:** enemies 17 ms, items 10 ms, skills 9.6 + 4.1 ms.
- **Callers:** 23 sites, all at scene changes or fight starts:
  - 11 in `story_player_screen.dart` (for example `:1476` enemies, `:1577–1578` trees and skills);
  - 7 tables per sea battle (`story_ship_battle.dart:39–46`);
  - 3 in `land_crossing_screen.dart`.
- **The cache exists:** `localizedDbProvider` already holds exactly this result.
- **Fix:** after `whenLoaded()`, read `localizedDbProvider(schema)`; about 3 lines. Risk low; the same values, cached.

### P3 [⚡] The first entry into the Journey blocks on two big files
- **Story file:** `StoryRepository.load` (`story_repository.dart:21`) decodes and builds the 1.5 MB story (479 nodes) on the main isolate: 65 ms.
- **City plans:** `cityPlanRecordsProvider` (`city_provider.dart:22`) adds 17 ms for `city_plans.json` (715 KB).
- **Fix:** `Isolate.run` around decode and parse for both. Risk low (pure data); the rest of the app already awaits them.

### P4 [⚡] Providers that watch a whole state for a small value
Most of them return a new object with no `==`, so everything below them rebuilds as well.
- **Worst case:** `tabBadgesProvider` (`tab_badges_provider.dart:81`). `HomeShell` is always on screen and needs 2 bools and a count, but it reruns the quest and house scans on every session change.
- **Others, watching the whole session:**
  - `shipDressProvider` and `shipFormProvider` (9 watchers)
  - `walkingPartyProvider`
  - `clanEffectsProvider` (it feeds `signEffectsProvider`)
  - `statBreakdownProvider` (it also reparses item sets on each call)
  - `roadWardsProvider` and `campRollsProvider` (they need only `rollBans`)
- **Others, watching the story state:**
  - `skyHereProvider` (5 watchers, including the Journey)
  - `foundDistrictsProvider`
- **Fix:** `select` plus `==` on the small result types. 2–3 PRs, grouped by screen. Risk low: the existing tests, and a rebuild count in one widget test per group.

### P5 [⚡] Save size
A seeded run (dwarf warrior, seed 7) played to chapter 7 in 111 steps gives a 13,732-byte session with 114 fields.
- **Biggest fields:**
  - `politics`: 5,223 B, of which the standing `log` is 4,269 B for 27 entries;
  - `flags`: 3,071 B.
- **The one large growth:** the standing log is capped at 500 entries (`factions.dart:170`), about 80 KB at ~160 B each. The relations log is capped at 200; story `history` is uncapped but small (1.1 KB at 111 steps).
- **Defaults:** 56 fields are default or empty, 1,047 B (8%).
- **Load cost:** reading the session back (`fromJson`) takes 4.1 ms, 7× the encode.
- **Fix:**
  - cap the standing log at 100 (check what UX's history view shows; it reads the last entries);
  - leave default-valued fields out of `toJson` (`fromJson` already defaults them).
- **Risk:** low; a save test round-trips a full session.

### P6 [⚡] Small repeated parses
- `loadPlacePools` and `loadDetourScenes` (`place_pools_provider.dart:14,17`) reparse on each detour, 1.0 + 1.3 ms; `placePoolsProvider` already caches the first.
- `game_config.json` is read three times.
- S, low risk.

### R1 [−] Two tables only the data editor reads
- `gates.json` (1 record, `slums_gate`) and `adventure_nodes.json` (3 records).
- Their fields (`possibleMonsters`, `isPermanentGate`, `guaranteedLoot`, `possibleEnemyShips`, `storyEventID`) appear only in their schemas (`db_schema.dart:2099`, `:2123`). No test or tool reads them.
- **Remove:** the two files, their schemas, the `pubspec.yaml` asset line, and the two icon cases. The icon cases are UX's lines in `game_icons.dart`: a few lines, listed in the PR.

### R2 [−] Enemy move thresholds that are always 0
- `skillMoves[].attackCountRequirement`, `playerPatternThreshold` and `blockThreshold` sit on all 194 moves in `enemies.json`. Every value is 0, and no game code reads them, only `db_schema.dart`.
- That is about 580 lines of data. The editor offers three fields that do nothing when set.
- **Remove** the data and the schema fields.

### R3 [−⚖] Unread or duplicated gamedata fields
Each is read only by `db_schema.dart` (and, where named, one test).

| Field | Records | Note |
|---|---|---|
| `items.json` `damage` | 134 | unread; nonzero only on `void_banner` (25, while its read `attackDamage` is 2), a trap for whoever edits it |
| `shops.json` `unlockLevel`, `merchantSpecialties` | 14 | unread |
| `ship_parts.json` `battleActionLabel` (+ `_fr`) | 67 | unread outside 2 tests: **the text is Narrative's; ask before removing** |
| `factions.json` `_newKinds` | 6 | a design brief the loader skips (`factions.dart:1088`); read by `clans_content_test:111` only |
| `specialisations.json` `link: "weak"` | 8 | duplicates `weakLinkSpecs` (`specialisations.dart:91`); they agree today: keep one |
| `items.json` `materialTier` | 10 | duplicates `materialTiers` (`materials.dart:16`); they agree: keep one |
| `enemies.json` `championClan` | 6 | the code builds `champion_<clan>` (`nemesis.dart:282`); one test reads the field |
| `factions.json` `ruling` / `ruling_fr` | 6 | long lore paragraphs nothing shows: **Narrative's call** (show them or drop them) |

Simplification, separate PR:
- 13 element bonus/resist fields and the `alignment*` fields are 0 or empty on 129 of 134 items. Making 0 the default in the reader and dropping the zeros cuts `items.json` by about a third.
- The `partID`, `lookID`, `shipID`, `zoneID`, `branchID` and `raceID` fields repeat the record key (only the editor reads them); low value, leave them.

### R4 [−] Dead and test-only symbols
- **Dead:**
  - `regionHoldersProvider` (`clans_provider.dart:68`); without it, `regionHolders()` (~20 lines) is test-only.
  - The cleanup plan's §6 list is stale: `SubClan.favourFor`, `EventVariant.newsFor` and `SimGrowthTables.offerTables` are already gone, and UX's `clan_rank_plate.dart` uses `clanPowerRankingProvider`.
- **Test-only (~45 symbols, ~400 lines).** The larger ones:
  - `skillIdsForCharacter` (23)
  - `fightGoalFromName` (20)
  - `chartZoneHolders` (18)
  - `professionLootAffinityBonus` (16)
  - `ShipWeapon.withAmmo` (15)
  - `worldLegPathForScenes` (13) and `worldLegPathProvider` (10)
  - `trainingStats` (13)
  - `watchfireAfterHeal` (12)
  - `forgeSheetFor` (12)
  - `hullRecordOf` (10)
- **Keep:**
  - `simulatePlaythroughs`, the tests' entry point;
  - the content guards `unresolvedPlaceholdersIn` and `anyPatronCanOffer` (move them to `test/support/` instead);
  - three names the scanner found inside strings, to check by hand.
- **Approach:** decide name by name, delete with its test lines, in batches of ~10. Stay off whatever Cleanup's v1.700 PR touches.

### R5 [−⚖] The simulator copies the game's rules by hand
- **New-game build:** `SimCharacter.create` (`sim_combat.dart:115–175`, "Mirrors startNewGame") re-implements `startNewGame` (`player_session_provider.dart:2025–2130`): the defaults, race and profession bonuses, starting gold and die. The starting die's face slots are literals (`'1'`, `'4'`, `'5'`) where the game has named constants.
- **XP threshold:** `level * 100` is written in 5 places (`player_session_provider.dart:918`, `:5832`; `sim_combat.dart:479`; `autoplay_build.dart:230`).
- **Within the simulator:** shop stock preparation is copied twice (`sim_combat.dart:597`, `:728`), and the autoplay "stuck in combat" exit too (`autoplay_engine.dart:556`, `:1157`).
- **Fix:** one pure `newCharacterTotals(...)` both call, and one `xpForLevel` constant. Risk low; the `sim_*` tests and `boss_balance_test` prove the simulator's numbers don't move.
- **The rest of 3c:** C6 and C7 were done in v1.653 (the simulator's fight numbers are aliases of the real constants, `sim_combat.dart:912–914`), so R5 is what is left of wave 3c.

### B1 [⚖] The competent player keeps the starter die in 30 of 50 runs
- **Final dice over 50 competent runs:** starter 30, vigil 9, apprentice 7, court 4.
- **Never kept:** 32 of the 36 dice, including every profession die, every companion die and all high-cost dice (tearglass 290, ossuary 220).
- **Taken but never kept:**
  - cinder: 21 competent, 28 naive
  - ossuary: 17 naive
  - tally: 12 naive
- **Then and now:** the v1.564 report had casters buying tearglass and ossuary.
- **Two readings, to settle before any number changes:**
  - (a) the simulator's die scoring, or the v1.689 trial gate, rejects good dice;
  - (b) those dice really are worse than the starter die for the build the simulator plays.
- **Measure:** log each trial's two results (current die vs candidate). If (a), the gate is the fix (Core). If (b), the dice are dead content, and the user decides whether to retune or remove them.
- **Simulator gap:** its summary doesn't expose purchases, owned dice, spells cast per id or titles. Exposing them is a few fields in the run summary (tooling, not a game feature) and makes B1–B3 measurable.

### B2 [⚖] Nine of 14 shops are never found in the simulator
- **Never discovered, under either player type:**
  - blind_beggar_stall
  - black_market_docks
  - weaponsmith_forge
  - shieldwrights_hall
  - smugglers_vault
  - hammersmith_forge
  - arcane_academy
  - sharpweave_den
  - wayfarer_caravan
- **Effect:** it explains why the tiered weapons (`dagger_t1–9`, `shield_*`, `spear_*`, `sword_*`, `staff_t1–8`) are never worn.
- **Two readings:**
  - (a) the simulator's route never visits them, and players do: a simulator gap;
  - (b) nothing in the story unlocks them: dead content.
- **First step:** a look (S), then a short note to the Manager.

### B3 [⚖] `void_banner` is worn in 50 of 50 competent runs
- **Evidence:** it is the only item every competent run ends in.
- **Also:** its data carries an unread `damage: 25` (R3).
- **What to do:** look at its read stats against its slot's next best. Any number change is the user's call; I'd bring options with simulator results.

### B4 [⚖] Early fights are harder for the competent player than the naive one
| Enemy | Competent losses | Naive losses |
|---|---|---|
| rat_matriarch | 7/13 (54%) | 27% |
| white_soldier | 23% | 14% |
| aurel_vane | 17% | 0% |

- **Chapter 1** is the competent player's hardest chapter (0.91 encounter win rate). From chapter 2 on it is at about 1.00, far above the 35–75% boss targets, which were set on the naive player.
- **Likely cause:** a different route, or a gear or die swap before the gear is any good.
- **What to do:** a look (S), then a fix in the simulator's policy if that is the cause.

### Smaller findings, no PR of their own
- **26 enemies are never fought in 100 runs.**
  - Most are gated or expected:
    - the 6 champions (off by default)
    - the 9 turned companions
    - the angels and demon of the late quests
  - Six sub-clan named foes have no reference outside the icon table:
    - `compact_anvil_deaf_tove`
    - `compact_quarryman_brodin`
    - `mire_herons_wake_wen`
    - `mire_returned_sedge`
    - `vigil_candlebearer_ysel`
    - `vigil_spearman_halvard`
  - Check whether their ids are built at run time before calling them orphans.
- **Naive caster/melee gap:** fights lost per run are mage 46.9, cleric 57.8, warrior 67.3. Voidkin is the weakest race under both player types. This is the gap `difficulty-review.md` describes. Noted, not proposed here: a balance change is a feature-level call for the user.
- **`qa_unused_fields.py`** counts `db_schema.dart` as a reader, so it misses every editor-only field (it reports 1 where R2 and R3 find about 12). That is QA's tool: a note to QA.

## 3. What is not worth doing
- **Fight query loops:** they run over 5 or fewer actors.
- **`chapterOfNode`'s RegExp:** 0.9 µs a call.
- **Startup:** it reads only the session, the autosave, 3 slot summaries and the finished-story record.
- **Editor overrides:** the data editor's overrides store whole tables, but they affect editors only.

## 4. Waves 3c, 4 and 5 for Core's files

- **3c:** what is left is R5. C6 and C7 are done (v1.653).
- **5 (performance):** P1–P6. C4 and C5 are done (v1.652, checked: `chapter_loop_provider.dart:24` selects; `choice_flow_provider.dart:16` indexes once).

**4 (big files):** one per PR, no behaviour change, never two at once, each after checking no other branch touches the file. Order, least shared first:

| Step | File (lines) | Split | Risk |
|---|---|---|---|
| 4a | `playthrough_simulator_screen.dart` (4,894) | the engine (`simulatePlaythroughs`, the runner, `SimRunSummary`) to `lib/data/sim_playthrough.dart`; the screen keeps the UI | low: the simulator only; 22 test files change one import |
| 4b | `sim_combat.dart` (2,862; `simulateSimFight` is 1,492 lines) | the fight into `part` files by phase (setup, party turn, enemy turn, end), as the fight screen does | low: `sim_*` and `boss_balance_test` pin the numbers |
| 4c | `factions.dart` (2,623, 28 classes) | one file per type family (standing, politics state, events) | low |
| 4d | `db_schema.dart` (3,989) | one file per table family; the schema list stays one const | low; the editor tests |
| 4e | `fight_rounds.dart` (`_confirmRoll` 489, `_takeEnemyTurn` 415) | named helpers inside the same extension | medium: the fight's core; the fight tests and a play-through |
| 4f | `player_session_provider.dart` (6,232) | the `PlayerSession` model to `lib/models/`, the notifier's methods into extensions by feature (camp, forge, allies, signs, politics) | medium: the most imported Core file; only in a quiet window, merged the same day |

## 5. Order and PRs
One PR per line, each with a version from the Manager starting at v1.702. A docs-only PR takes no version.
1. P2 (3 lines)
2. R1 + R2 (data and schema only)
3. P5
4. P3
5. P1
6. R3, first batch (the unread fields; Narrative asked about `battleActionLabel` and `ruling`)
7. B2 look, B1 measurement (the simulator summary fields), B4 look: notes to the Manager, then fixes as approved
8. P4 in 2–3 PRs
9. R5
10. P6
11. R4 in batches
12. 4a → 4f, one at a time

B3 and any other balance number changes only after the user picks from options.

Each PR: merge `origin/main`, format, analyze, the tests that touch the change, and the simulator tests when the simulator or a balance input moves. Each PR avoids files that Cleanup's v1.700 PR or any other open branch touches.
