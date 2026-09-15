# Changelog

All notable changes to this project are documented here, generated from the
repository's pull-request history (each entry corresponds to one merged PR
and the version it bumped `pubspec.yaml` to). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

History before v1.23.1 predates per-PR versioning in this repository and
isn't reconstructable from git history alone.

## [1.78.0+106]

The Level Up popup was unreadable on narrow phone screens — stat labels like
"Damage" and "Armor" were being split mid-word ("Dam"/"age", "Armo"/"r")
because the dialog's default insets plus a wide leading icon and trailing
button left almost no room for the label text. Also adds tap-to-learn stat
descriptions, previously only implicitly understood from context.

### Fixed
- **Level Up modal readability on mobile** — rebuilt each stat row's layout
  in `level_up_dialog.dart` with a tighter, width-budgeted `Row`
  (smaller icon avatar, single-line label, compact `+1 Point` button) and
  added explicit `insetPadding`/`contentPadding` overrides to the
  `AlertDialog`, so labels render on one line instead of wrapping mid-word
  on narrow viewports. Verified numerically via a widget test measuring
  rendered text height at 412px and 360px simulated screen widths.

### Added
- **Stat descriptions on tap** — tapping a stat's icon on either the Level
  Up modal or the full-screen Level Up tab now opens a short description of
  what that stat actually does in-game (e.g. Luck improves post-fight loot
  odds, Strength/Dexterity/Constitution/Intelligence/Wisdom back their
  respective story-choice ability checks, Charisma opens persuasion-gated
  dialogue), reusing the existing `showDetailDialog` helper. All ten
  descriptions are localized in English and French.

## [1.77.0+105]

Three new recruitable companions, each gated behind a different kind of
requirement — so which allies a playthrough can actually reach depends on
the build and the choices that got it there, not just on finding the right
hub node.

### Added
- **Liora** (Elf Ranger) — a wary rooftop archer at the Chapter 2 harbor
  hub (node `2010`), who only comes down if you can talk your way past her
  (`reqCharisma: 3`). Signature die: `liora_die` (aimed shots, evasive
  steps, `ranger_aimed_shot`/`ranger_beast_bond`).
- **Vess** (Voidkin Mage) — a fellow void-marked stranger at the Chapter 1
  market hub (node `151`), reachable only by players carrying the
  `void_marked` flag from a failed Luck check at the Tear (node `280`) —
  a direct consequence chain from an earlier round's content, not a new
  gate type in isolation. Signature die: `vess_die` (void/arcane, `mage_arcane_missile`,
  `voidkin_umbral_veil`/`voidkin_entropy_touch`).
- **Grosh** (Orc Warrior) — a mercenary at the Chapter 3 Ashen Quarter hub
  (node `3005`) who only takes clients who look like they can pay
  (`reqGold: 80`). Signature die: `grosh_die` (`orc_berserk_rage`,
  `warrior_shield_bash`).

  Each ships with its own recruit quest (`q_ch2_lioras_watch`,
  `q_ch1_vess_in_the_dark`, `q_ch3_groshs_price`) and bridge node, following
  the exact pattern Kelda/Sable/Maren established — no new mechanics, just
  new data reusing `reqCharisma`/`reqFlags`/`reqGold` node gating and the
  existing companion/signature-die/recruit-quest schema.

## [1.76.0+104]

Five new build-specific interactions and a new quest, so every one of the
six core stats (plus Luck) now has at least one real moment where it
changes what happens — reinforcing that a playthrough's build determines
what it can actually do, not just how hard it hits in combat.

### Added
- **Five new ability checks**, each exercising a stat that had no story
  moment of its own yet:
  - **Luck** — the Chapter 1 "Touch the Tear" choice was flavor-text only
    (labeled "Luck Check" but never actually rolled); it now rolls for
    real (DC 10), with a new failure scene (`281_scarred`) for a bad roll.
  - **Strength** (DC 13, Chapter 2 harbor) — force a jammed loading crane
    open for bonus gold, or fail and draw Vane's crossbow.
  - **Constitution** (DC 12, Chapter 1 market) — push through a
    smoke-choked forge to find a stashed cache.
  - **Wisdom** (DC 13, Chapter 2 harbor market) — read the crowd for an
    informant, unlocking the new quest below; fail and a plague hound
    notices you instead.
  - **Intelligence** (DC 13, Chapter 3 Ashen Quarter) — decipher scorched
    ledger fragments outside the archive for bonus gold and a flag; fail
    and a cultist acolyte notices you rifling through their things.

  `ability_check.dart`'s `abilityScoreKeys` now includes `luck` alongside
  the six D&D-style stats, reusing the exact same roll/DC/`failNextId`
  machinery already proven out by the Dexterity check from last round —
  every failure route reuses an existing sibling node instead of adding
  new dead ends.
- **New quest: The Informant's Tip** (`q_ch2_informants_tip`) — unlocked by
  the Wisdom check above, a bounty on a corrupt warden skimming smuggled
  goods.

## [1.75.1+103]

### Fixed
- **Story Map panning.** Removed the Edit Mode "Jump to Chapter" panel,
  which sat over the top-right corner of the map and silently swallowed
  any drag gesture that started on it — the likely cause of the map
  feeling unscrollable in that area. The map's `InteractiveViewer` always
  supported free pan/zoom in every direction; with the panel gone, nothing
  on screen blocks it anymore. (Jumping to a chapter is still available
  from the map by tapping a node and using "Jump to this node".)

## [1.75.0+102]

Sharper item/quest icons, and the first choices whose consequences reach past
their own scene: which companions you can recruit, and which skills you can
learn, now depend on who you've been so far.

### Added
- **Choice-driven build divergence.** Recruiting Kelda (the dwarf
  shieldbearer) now requires an alignment score of at least 2; recruiting
  Sable (the rogue) requires -2 or lower; recruiting Sister Maren requires
  having saved Lysa back in Chapter 1 (`lysa_survived`). All three use the
  existing node-level `reqAlignmentScore`/`reqAlignmentMax`/`reqFlags` gates,
  each with its own in-voice locked reason instead of a generic message. Two
  new signature skills, `zealous_conviction` (alignment ≥ 3) and
  `ruthless_edge` (alignment ≤ -3), extend the same idea to skills via new
  `requiredAlignmentMin`/`requiredAlignmentMax` fields on the skill schema,
  shown in the Skills screen as "Reserved: Good-aligned"/"Evil-aligned"
  alongside the existing race/profession restriction. The point: who you
  recruit and what you can learn is no longer available to every
  playthrough — it's shaped by the choices you already made.

### Changed
- **Item and quest icons are sharper.** Weapon items now render a
  sword/dagger/spear/staff/shield-specific icon instead of one generic
  glyph for the whole "Weapon" category (`itemIcon`), and quests render an
  icon for what their first objective actually asks — a fight, a fetch, or
  a conversation — instead of just their Main/Side category
  (`questIcon`), across Inventory, Shops, and the Quests tab.

## [1.74.0+101]

A D&D/Baldur's Gate 3-style ability check system: five new stats and a
dice-roll "attempt" mechanic for story choices, layered alongside last
round's flat Charisma gate rather than replacing it.

### Added
- **Strength, Dexterity, Constitution, Intelligence, and Wisdom** join
  Luck and Charisma as full character stats — derived at creation from
  `game_config.json` + race/profession bonuses (e.g. Dwarves run high
  Constitution, Mages run high Intelligence, Rogues run high Dexterity),
  spendable from the level-up dialog/screen, and editable from the debug
  stats panel like every other stat.
- **Ability checks on story choices.** `StoryChoice` gained
  `checkAbility`/`checkDC`/`failNextId`: tapping a checked choice rolls a
  d20 plus the matching stat against the DC (`lib/data/ability_check.dart`)
  and shows the roll in a themed popup before anything else happens — the
  BG3 "attempt" pattern, distinct from `reqCharisma`'s hard, deterministic
  gate. Success applies the choice's effects as normal; failure either
  routes to `failNextId` when the author set one, or continues to the same
  destination without the reward. Authorable from the Story Node Editor's
  choice panel, and the graph-integrity checker now walks `failNextId` too,
  so a check-only branch is neither flagged orphaned nor left unvalidated.
  Wired into a new optional choice at the Ashen Quarter hub (a Dexterity
  check to pick a sealed archive's lock) as a worked example.

## [1.73.0+100]

A round of new-mechanics requests: a proper celebration for leveling up,
two new stats with real gameplay teeth, and NPCs the player can actually
talk to.

### Added
- **Colored level-up dialog.** The plain gray "Level Up!" alert is now a
  gold-gradient trophy icon with a soft glow, a gold title, and each
  spendable stat given its own themed color (red damage, blue armor, pink
  health, purple luck, teal charisma) instead of identical gray rows.
- **Luck and Charisma stats.** Derived at character creation the same way
  as every other stat (`game_config.json` base + race bonus + profession
  bonus — e.g. Rogues run high luck, Clerics and Humans run high
  charisma), spendable from the level-up dialog/screen alongside Damage,
  Armor, and Health.
  - **Luck** boosts the drop-rate roll on combat loot directly (in
    percentage points), so a lucky character sees noticeably better item
    drops.
  - **Charisma** gates story content: `StoryNode` gained a `reqCharisma`
    requirement (checked in `PlayerSession.meetsRequirements` alongside
    the existing reqGold/reqAlignment/reqFlags), authorable from the
    Story Node Editor like every other requirement, for
    persuasion-flavored choices a low-charisma character can't take.
- **NPCs you can talk to.** A new `npcs.json`/`npcsSchema` (three NPCs to
  start: a returning companion from the opening chapter, and two flavor
  encounters), surfaced as a new NPCs section in the Play tab —
  flag-gated the same way node requirements already are, so an NPC can be
  tied to a story event before they're discoverable. Tapping one opens a
  simple conversation screen (description + a few flavor lines) with a
  Talk button that records the conversation
  (`PlayerSession.talkedToNpcIds`). Quests' existing `Talk`-type
  objectives (previously always auto-met, with nothing to actually check)
  now gate on a new `targetNPCID` field against that record when one is
  set — wired end-to-end for one real quest (`q_ch3_alsters_dawn`) as a
  worked example, with older/other Talk objectives left ungated exactly
  as before if they don't specify a target NPC.

## [1.72.0+99]

Follow-up to the last round of live-device feedback: relocate a
half-discoverable feature, make character creation faster to start, and
make quest completion actually mean something.

### Changed
- **"Play to Chapter" moved from the Story Map to Settings → Simulate a
  Playthrough.** The strategy-driven chapter autoplay added last round sat
  awkwardly on the Map's node-jump picker; it now lives alongside the
  batch-simulation controls it's a natural sibling of, sharing the same
  strategy selector. Still lands the player back in live Story view with a
  real, earned session once the target chapter is reached.

### Added
- **Randomize button on the Race & Profession screen.** Picks a random race
  and profession in one tap, next to the existing random-name die — for
  players who just want to jump in without reading five race/profession
  cards first.
- **Real quest objective tracking.** `quests.json`'s `objectives` field
  (previously unread by any gameplay code) is now enforced: a quest's
  Complete button stays disabled until its Kill objectives (tracked via a
  new lifetime `PlayerSession.enemyKillCounts`, bumped on every combat win)
  and Fetch objectives (checked against current inventory) are satisfied.
  The active quest card shows each objective as its own checklist line,
  which doubles as sub-quest tracking for any quest with more than one
  objective — no new "quest group" concept was needed, since a multi-part
  quest is just a quest with multiple `objectives` entries. Talk objectives
  are left ungated (no reliable signal exists yet to detect them). Existing
  saves with quests already active before this change are grandfathered so
  they're never stuck unable to complete.

## [1.71.0+98]

Live-device UX feedback from actually playing the app: the story map's
overlapping panels, a genuinely useful "simulate up to a chapter" feature
that turned out to be half-built, and a fullscreen-reading toggle that
fired but was too subtle to notice.

### Fixed
- Story Map: the Legend panel and the "Jump to Chapter" panel both sat at
  the top of the screen, overlapping on narrower viewports. Legend now
  anchors to the bottom-left instead.
- Double-tapping the story text to enter distraction-free fullscreen
  reading worked, but the narration card stayed pinned at its normal small
  size with the freed-up space left as dead blank area below it — easy to
  read as "nothing happened." It now fills and centers in the available
  viewport height.

### Added
- `autoplayToChapter`: a strategy-driven counterpart to the existing
  shortest-path `autoplayToNode` — walks real choices forward from the
  player's current position toward a target chapter, favoring good/evil/
  gold (or random) at each branch, applying every step's true effects
  (gold, alignment, flags, shop/quest unlocks, real simulated combat) via
  the same session methods a live choice tap uses. Wired into the Story
  Map's "Autoplay to chapter" picker alongside a strategy selector, so
  picking a chapter now plays a real, strategy-flavored path there instead
  of always taking the single shortest route — and lands the player back
  in live Story view afterward, ready to keep going manually with a real
  earned session. This is the "simulate up to a chapter, then take over"
  capability `firstNodeIdForChapter`'s doc comment had anticipated but
  never actually existed.

## [1.70.0+97]

The remaining CI/polish loose ends from the last review round.

### Added
- **A one-time nudge toward In-Game Mode.** Every fresh install defaults to Edit Mode (the full authoring app) since that's what this project's own development relies on — flipping that default would work against the developer's own daily workflow, so it stays. Instead, a dismissible banner on the Play tab now points a genuine first-time player at the Settings toggle, shown once until dismissed either by switching or by closing it outright.
- **`docs/quest-progress-tracking.md`** — a scoping writeup (not an implementation) for enforcing quest objectives for real, grounding the plan in the `objectives` schema that already exists in `quests.json` but was never read anywhere in gameplay code.
- **`.github/workflows/format.yml`** — a manual (`workflow_dispatch`-only) way to actually apply `dart format` via CI's Flutter install, since this dev environment has no local Dart SDK to run it directly.

### Changed
- **The codebase is now actually `dart format`-clean** (71 files reformatted via the new workflow) and **the CI format check is a real gate** — dropped the `continue-on-error` that was only ever meant to be temporary, pending a pass that confirmed the repo was clean.

## [1.69.0+96]

Fixes from a 40-run simulated-playthrough analysis (built as an accurate Python port of the real combat/quest/achievement logic, cross-checked against `test/combat_engine_test.dart`'s hand-verified values). 3 confirmed bugs fixed, 2 of 3 balance findings addressed; the third needs a product decision rather than a code fix (see below).

### Fixed
- **A level-1 character could roll an unwinnable fight in the very first random encounter.** `SubNodeEngine`'s procedural "excursion" encounters drew from the *entire* enemy roster with no level/chapter filter, so a chapter-1 side-fight could occasionally draw a chapter-4/5-tier monster (230 HP / 27 dmg vs. a fresh character) — unwinnable, with no way to decline or route around it. Traced in simulation to every one of 12/300 permanently-stuck sample runs. Every `enemies.json` entry now carries a `minChapter` (derived from where the main story itself first uses that enemy), and excursions only draw from enemies already at-or-below the current chapter.
- **Quest `alignmentChange` was defined in data but never applied.** `completeQuest()` had no alignment parameter at all, so `quests.json`'s `alignmentChange` field (set on several quests, including the near-mandatory banner quest) was silently dropped every time — quietly denying players alignment the content was designed to grant, on a game that gates real story branches on alignment thresholds. Now threaded through from the quest record into the same `alignmentScore` update `applyChoiceEffects` already uses for choice-driven alignment.
- **A completed quest could be re-offered by a later excursion.** The excursion quest pool excluded `unlockedQuestIds`, but a quest reached via `questIDToProgress` (rather than `unlockQuestId`) never lands in that list — so `q_first_blood` specifically could resurface after completion. The pool now also excludes `completedQuestIds`.

### Changed
- **Companion co-recruitment is more reliable.** Kelda and Sable are offered as a single, mutually-exclusive, non-revisitable pick at node 2015 (by design — every other recruitment/vignette hub in this story works the same way), so getting both in one run depended entirely on a later excursion randomly re-offering the one not picked, at roughly a 1-in-N chance against the whole side-quest pool. Excursions now prioritize an eligible companion-recruit quest over an ordinary side quest whenever one is available, without changing the main-path structure.
- **Unspent stat/skill points now show a badge on the Character card** (matching the existing unseen-quest/shop/enemy badge style) — spending them is entirely manual and nothing else calls attention to it; a full-game simulation with points never spent saw Chapter 4-5 win rates roughly halve.

### Investigated, not changed
- **Quest "objectives" (kill X, fetch Y) aren't enforced — completion is gated on nothing**, so reward chains resolve the instant they unlock regardless of whether the described events happened. This inflates the in-game economy (~30% of average simulated end-game gold is quest rewards) but may be an intentional lightweight quest-log design rather than a bug. Actually enforcing objectives would mean building real progress-tracking (kill counts, item possession, flag state) per quest — a new feature, not a fix — so left alone pending a product decision.

## [1.68.0+95]

The remaining two of five requested UX improvements, scoped after a clarifying round: a real-state "autoplay ahead" testing tool, and closing the Camp Rest gap.

### Added
- **Autoplay to a node or chapter (Edit Mode).** `lib/data/autoplay_engine.dart` finds the shortest forward path through the story graph to a target node, then walks it applying every choice's real effects (gold/alignment/heal/flags/quest-progress, shop/quest unlocks, achievement checks) through the exact same `PlayerSessionNotifier` methods a live choice tap calls — including a genuine simulated combat (the same `combat_engine.dart` functions and scaling a real fight uses, retried a bounded number of times on a loss) for any triggered fight, so the state you land in is a real earned one, not a fabricated snapshot. Reachable from the map: "Autoplay to this node" in a node's detail sheet, and "Autoplay to chapter…" next to the existing Jump-to-Chapter chips. Both Edit-Mode-only, like the quick-preview jump they sit beside. Deliberately skips procedural excursions and ignores active allies in the simulated fight — a testing tool, not a faithful full replay.
- **Rest at the Town Hub, not just Camp.** Town Hub gets its own "Rest" action (same `healPartyToFull()`), since a town is as much a safe haven as camp.

### Fixed
- **Camp Rest is now blocked while a fight or expedition is in progress** (`expedition_active_provider.dart`, mirroring the existing `combat_active_provider.dart`), applied to both Camp's and Town Hub's Rest buttons. Mostly a defensive check today — both already cover the bottom nav with their own full-screen route — but closes the gap for good.

## [1.67.0+94]

Three of five requested UX improvements (the other two — a "simulate ahead to a node/chapter" testing tool, and precisely scoping where Camp's Rest action should be allowed — need a design decision first and are being scoped separately).

### Added
- **Autosave for story position.** `PlayerSession` (stats, inventory, quests) has always auto-persisted continuously, but the *story position* (`StoryPlayNotifier`'s current node + history) only ever lived in memory — closing and reopening the app silently reset the narration back to the very first node while every stat/item earned since stayed intact. It's now autosaved on every real position change, to its own slot separate from the existing manual Save/Load checkpoint, and restored on launch. A restart (permadeath, or the Edit Mode reset) correctly clears it too, and an autosave pointing at a since-deleted node still degrades to the existing "trail went cold" recovery screen rather than crashing.
- **Double-tap the story text for a distraction-free fullscreen read.** Hides the status bar, header row, walking companion, and choices, leaving just the narration; double-tap again to bring them back.

### Changed
- **Story map readability.** Node labels were unbounded-width text, so a long id (e.g. `2015_dockside`) could render wider than its column and visually overlap the next one — now fixed-width and ellipsized. Same-depth nodes were ordered alphabetically with no regard for which column their edges actually connected to, producing heavy crossing clutter in fan-out/fan-in clusters like the Chapter 3 companion-quest diamond; they're now ordered by a barycenter heuristic (each node sorted near the average row of its already-placed predecessors), which measurably cuts down edge-crossing on the real story graph. Column and row spacing widened slightly to match.

## [1.66.0+93]

Two regressions found by a fresh functional review of the companion/camp system (spawned as three parallel reviews covering combat/camp, Town Hub/expeditions/achievements, and map/UI/origin-story features — the latter two found no bugs).

### Fixed
- **A winning fight that leveled the player up would immediately undo that level-up's full heal for every active ally.** `applyCombatResult` already full-heals and grants skill points to every recruited ally when its XP gain crosses a level threshold, but `FightScreen._finishFight`'s very next loop unconditionally wrote each ally's stale, pre-level-up battle-end HP over that heal (and revived a knocked-out ally against their *old*, lower max health instead of the new one). That per-ally write is now skipped whenever the fight's win also leveled the player up.
- **A companion's one customizable die face was permanently stuck on `heavy_attack`.** `InventoryScreen` and `SkillsScreen` were parameterized by `allyId` when the companion/camp system landed, but `DiceLoadoutScreen` never was — so there was no UI path to ever reassign a companion's single open Skill-die face, making their skill-point/unlock progression's actual combat payoff unreachable. `DiceLoadoutScreen` now takes an optional `allyId` (mirroring the other two screens: no die-switcher, since an ally only ever has their one fixed signature die) and Camp's roster cards got a third "Dice Loadout" button to reach it.

## [1.65.0+92]

CI/build pipeline and test-coverage improvements, from a review of the setup itself rather than the game.

### Added
- **Real unit tests for game logic, for the first time.** `test/combat_engine_test.dart` covers dice rolling, player/enemy move resolution (Attack/Defend/Heal/Skill faces, Always/Chance/OnLowHealth enemy conditions, priority ordering including the "a match consumes the turn even if its skill doesn't resolve" edge case), and the three level-scaling formulas. `test/player_session_provider_test.dart` covers `completeQuest` (gold/XP/item rewards, leveling up, banner-piece de-dup), `completeZone` (rewards, one-time payout), `applyCombatResult` (rewards, leveling, HP clamping), `recruitAlly` (starter skills, no duplicate recruits), and `checkAchievements` (including a regression test pinning `full_party` at exactly 2 active allies — the threshold bug fixed a few versions back). Every one of this session's real balance bugs was previously only ever caught by a hand-written Python simulation run manually, outside CI; this is the start of closing that gap for real.
- `.github/dependabot.yml` — weekly update PRs for pub packages and GitHub Actions, so "N packages have newer versions" is an actual PR to review instead of a CI log line nobody acts on.

### Changed
- **CI workflow (`build_apk.yml`)**: added `concurrency` with `cancel-in-progress` so a branch that gets several quick follow-up pushes stops burning minutes on runs whose result is already superseded; enabled `subosito/flutter-action`'s built-in SDK+pub caching (was off) and added a Gradle cache, both aimed at the 7-9 minute build-APK step being the slowest thing in every run; bumped `actions/setup-java` from the now-deprecated v3 to v5; added a `dart format --set-exit-if-changed` check (non-blocking for now — the repo's formatting hasn't been verified clean without a local Dart SDK to check first); tightened the workflow-level permissions default from `contents: write` to `read`, with `build` granting itself `write` explicitly for its own release step.

### Investigated, no change needed
- `flutter_tts` (the package CI warns applies the Kotlin Gradle Plugin directly) is already pinned to its latest published release, 4.2.5 — there's no newer version to bump to yet. Dependabot will now surface one automatically whenever the maintainers ship a fix.

## [1.64.0+91]

### Added
- **Profession-flavored origin story.** The "beggar's plea" childhood prompt (one of the five formative-memory beats shown at character creation) now has a variant per profession instead of one generic version for everyone: Warrior (a wounded veteran's ration), Mage (a hedge-mage's warming charm), Cleric (a pilgrim's offering coin), Ranger (a trapper's dried meat) each get a small reskin of the same beat; Rogue gets a genuinely different scenario — a rigged card game, warn the mark or run it as rigged. New `originPromptForSlot()` picks the right variant for the player's chosen profession, falling back to the original generic prompt for any profession without one.

## [1.63.0+90]

### Changed
- **Narrative text throughout the app now reads like prose, not a form field.** The childhood/teenage origin-story dialog (shown once at character creation), the Quests tab's quest cards, and the shared item/skill/quest detail popup all now render their descriptive text with a serif typeface, 1.55-1.6 line height, and slight letter-spacing — the same readability treatment the story reader itself got earlier this session. The Quests tab's cards were also rebuilt from a cramped 3-line-max `ListTile` (which truncated longer dialogue) into a proper card layout that shows the full text.
- **Added a "Jump to Chapter" panel to the Map screen.** A row of chapter chips (Prologue through the current content's last chapter) in the top-right corner jumps straight to that chapter's opening beat, reusing the same `jumpTo` the map's existing (undiscoverable) per-node double-tap already used — now there's a visible way to skip ahead and pick up a playthrough from a specific chapter without replaying from the start.

## [1.62.0+89]

Phases 2 and 3 of the roguelike redesign (see the design doc's Phase 1 entry below for background). Both delivered without touching the story graph's existing routing — Phase 3 in particular turned out to need far less new content than expected, since its two "banner piece" payoffs were already fully built and just needed tagging.

### Added
- **Town Hub now has all 3 of Chapter 2's tutorial zones.** New zone: Lantern Docks — rewards a narrative lead (a flag, not an item) on where the Shroud's second piece went, rather than gold or an item, giving zones their first non-material reward type.
- **Banner-piece tracking.** `PlayerSession.bannerPiecesCollected` (new field) tracks recovered pieces of the Shroud — the "heirloom cut into pieces" mechanic from this session's design doc. A quest's new `grantsBannerPieceId` field (mirrors the existing `rewardAllyId` pattern) tags a piece on completion; a zone's new `rewardFlag` field (mirrors a quest's `flagToAdd`) grants a plain narrative flag instead of gold/item/dice/ally, for zone rewards that are leads rather than loot.
- Both of Chapter 1 and Chapter 3's **existing** quests already delivered on the brief's "expedition to get the map to the second part" / "go get the flag" beats without any new content: `q_retrieve_banner` (Ch1, "The Heirloom of Alster" — literally the heirloom pickup) now tags the first piece; `q_ch3_alsters_dawn` (Ch3, the payoff of the already-wired `q_ch3_void_relic → q_ch3_the_high_wardens_fall → q_ch3_alsters_dawn` chain reachable from node `3005`) now tags the second. Character screen shows collected pieces when there are any.

### Not in this slice
The existing Chapter 2 harbor (`2015`) and Chapter 3 Ashen Quarter (`3005`) hub nodes were deliberately **not** restructured into the expedition/zone frame — turning an authored, one-shot story choice into a repeatable zone is a real engine change, distinct from adding parallel zone content, and risks the narrative-audit fixes from a few versions back. The new zones wrap around this content rather than replacing it, per the design doc's central recommendation. The boat (Phase 4) and Chapters 4-7's content (Phase 5) are still ahead.

## [1.61.0+88]

The first build slice of a larger roguelike redesign discussed and written up as a design doc this session ("The Scattered Banner"): a town-and-expedition loop wrapped around the existing chapters rather than replacing them. This entry is Phase 1 only — "one zone, land only" — proving the mechanism before any existing story content is touched.

### Added
- **Town Hub screen.** A new, separate screen (`lib/screens/town_hub_screen.dart`, reachable from a new Play-tab card) distinct from Camp: a tutorial/prologue stop with a couple of already-stocked basic shops (Blind Beggar Stall, Weaponsmith's Forge — nothing to build) and a list of the current chapter's expedition zones. Camp remains the one persistent base the player builds from scratch and keeps for the rest of the game; the town hub is what they have before they have that.
- **Expeditions.** A new `zones.json` data table (2 zones added for Chapter 2: Fisherman's Row, Tanner's Court) and `ExpeditionScreen` (`lib/screens/expedition_screen.dart`) that walks a zone's fixed chain of events — each one drawn live from `SubNodeEngine`'s existing themed flavor pools (its internal node-builder was made public, `SubNodeEngine.buildNode`, rather than duplicated) so a new zone needs no per-event writing, only a data row. Fights resolve through the existing `FightScreen`/`combat_engine.dart` unchanged; shop finds push the existing `ShopDetailScreen`; treasure/rest apply through the existing `applyChoiceEffects`. Losing or fleeing a fight, or retreating voluntarily between events, ends the run — everything already gained that run (gold, items, XP from any won fight) is kept, but the zone's own banked completion reward is forfeit until the zone is cleared in one run. `PlayerSession.completedZoneIds` (new field) tracks cleared zones permanently, mirroring `completedQuestIds`.

### Not in this slice
Re-plumbing Chapters 2-3's *existing* content onto this frame, the boat/FTL system, and Chapters 5-7's content are later phases per the design doc — deliberately not started here.

## [1.60.0+87]

### Changed
- **The story map now lays out as a grid capped at 5 nodes per column, with each chapter as its own vertical band** ("a map in itself"), instead of an automatic Sugiyama layered-graph layout with no ceiling on how many nodes could stack in one column. New `ChapterGridAlgorithm` (`lib/screens/story_graph_screen.dart`) positions every node from a precomputed slot map (`lib/data/chapter_grid_layout.dart`): column = BFS hops from that chapter's opening beat (following only same-chapter edges), row = position within that column, split into extra columns whenever a depth level would otherwise exceed the cap. Each chapter's band is labeled and sized to its own tallest column, so a low-branching chapter doesn't waste space matching a denser one. Verified against the real 97-node graph via a Python mirror of the same algorithm before porting to Dart: every column caps at exactly 5, and all 97 nodes place correctly.
- Content-side note: the *target* node budget this map layout is meant to support — roughly 15 authored nodes per chapter (5 main beats + up to 10 side nodes) — isn't met yet by the existing chapters (currently 43/21/17/7/8 across chapters 1-5); that's a separate, larger content pass, not part of this change.

## [1.59.0+86]

### Added
- **Random name generation.** A dice-icon button next to the character-name field on the lock-in dialog fills it with a random name drawn from a race-matched pool (`lib/data/random_names.dart`, 20 names per race) — Kelda-style dwarven names for a dwarf, elvish for an elf, and so on. Purely a convenience for players who don't want to type one; the field stays freely editable either way.

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
