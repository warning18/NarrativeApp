# Changelog

All notable changes to this project are documented here, generated from the
repository's pull-request history (each entry corresponds to one merged PR
and the version it bumped `pubspec.yaml` to). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

History before v1.23.1 predates per-PR versioning in this repository and
isn't reconstructable from git history alone.

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
