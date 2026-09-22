# Changelog

All notable changes to this project are documented here, generated from the
repository's pull-request history (each entry corresponds to one merged PR
and the version it bumped `pubspec.yaml` to). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

History before v1.23.1 predates per-PR versioning in this repository and
isn't reconstructable from git history alone.

## [1.103.0+131]

### Added
- **A Map tab in normal (in-game) play**, not just Edit Mode. Now that the
  map shadows nodes you haven't reached yet (previous release), it's safe
  to hand to players — same fog-of-war rules apply, so nothing about a
  future chapter is spoiled. Edit Mode keeps its extra Generate/Data tabs;
  Map now shows in both.

## [1.102.0+130]

Fog of war for the story map: outside Edit Mode, it now shows your journey
so far rather than the entire spoiler-laden graph at once.

### Added
- **The story map shadows nodes you haven't reached yet.** A node the
  player hasn't actually visited this playthrough now renders as an
  unrevealed shadow (position and connecting edges still visible, so the
  map's shape reads as a map) instead of its real kind, id, and
  description — tapping it explains it hasn't been discovered yet rather
  than opening the full node-info sheet. Edit Mode is unaffected and
  always sees the whole graph, same as every other authoring feature
  already gated to it. A new legend row explains the shadow style.
- `StoryPlayState.visitedNodeIds`, a monotonically-growing set backing
  this — persisted alongside the existing autosaved position/history, and
  backfilled from history for a save written before this feature existed
  so a returning player doesn't lose map progress they've actually made.

### Fixed
- `StoryPlayNotifier._persistAutosave` read `state` after an `await`,
  which could throw ("Tried to use StoryPlayNotifier after dispose") if
  the notifier was disposed while a fire-and-forget autosave was still in
  flight — a pre-existing latent race, made easy to hit by this batch's
  extra autosaved field. Now snapshots `state` synchronously before the
  first await instead.

## [1.101.0+129]

A quicker way to hand a reviewer (human or AI) your authoring notes without
sharing the whole repository.

### Added
- **JSON and CSV export for Review Comments.** The Review Comments screen's
  export button (Edit Mode → the notes left on story nodes while reading or
  testing) now offers a format picker — plain text as before, plus a
  compact JSON array and a CSV file, each just `id`/`chapter`/`comment` per
  commented node. Meant to be pasted straight into a prompt when a repo
  link isn't the easiest way to hand someone your notes.

### Changed
- Extracted the Review Comments export formatters into
  `lib/utils/comment_export_format.dart`, shared by the screen and now
  covered by dedicated unit tests independent of the widget tree.

## [1.100.0+128]

A follow-up balance pass on the last two updates: endgame gear is reachable
again, `kroll_the_branded`'s signature move is no longer a stun-lock trap,
achievement copy matches the current roster, and the playthrough simulator
finally models Wisdom and status effects — which is what surfaced the real
size of kroll's problem in the first place.

### Changed
- **Endgame sword/spear requirements loosened.** Tier 8-10 swords and spears
  required Strength 10-14 plus Constitution 4-8 — thresholds high enough
  that a normally-leveled character could reach the late chapters without
  ever qualifying for their own tier of gear. Now Strength 6/7/8 with only a
  small Constitution add-on at t9-10 (2/3); t4-7 unchanged.
- **`kroll_the_branded` rebalanced twice this batch**, once before and once
  after extending the simulator (see Fixed below): `maxHealth` 196 → 145,
  `damage` 24 → 19. Its signature move, Radiant Judgment, inflicts Stun on
  top of a heavy hit — `damageMultiplier` 1.4 → 1.2 and trigger `chance`
  35 → 18, so the stun-then-big-hit combo is rarer and less punishing when
  it lands, rather than the near-guaranteed spiral it was.
- **`plague_hound` trimmed to its actual weight class**: `maxHealth` 239 →
  205, `damage` 28 → 24 (matching `rat_matriarch`/`smuggler_captain`, the
  next enemies down), and its Poison-inflicting bite's trigger chance
  45% → 33% — it had drifted well above its chapter-2 peers.
- **`full_roster`/`full_party` achievement copy corrected** to match the
  current 6-companion roster and 2-active-ally party cap: "Three's
  Company" → "Full House" ("Recruit all three companions" → "all six"),
  and "Field a full 3-member active party" → "Field two active companions
  at once."

### Fixed
- **The (non-shipping) Python playthrough simulator never modeled Wisdom's
  combat role or status effects** (Poison/Stun/Weaken), even though both
  have been live in the shipped game since v1.98.0 — every simulation
  batch since then was blind to them. Fixed: the simulator now ticks
  Poison, skips a Stunned combatant's round, applies Weaken to a
  combatant's own outgoing damage, and gives Wisdom its real heal-bonus
  and status-resistance effect, turn-for-turn matching
  `_startPartyRound`/`_confirmRoll`/`_takeEnemyTurn` in `fight_screen.dart`.
  This immediately surfaced that `kroll_the_branded`'s Stun move made it a
  genuine outlier (a ~36% true win rate, invisible to every earlier,
  status-blind simulation) — the deeper kroll rebalance above is a direct
  result of this fix.

Re-simulated after this batch: 85.7% combat win rate, no enemy below a 50%
win rate (down from `kroll_the_branded` at ~36% once status effects were
actually counted), 100% true-ending rate across 40 runs, and
`boss_balance_test.dart` still passes unchanged.

## [1.99.0+127]

Real pixel-art icons for every item, skill, enemy, and shop, replacing the
generic Material glyphs that stood in for them since launch.

### Added
- **170 procedurally-generated pixel-art icons** (16x16, upscaled with
  crisp-pixel rendering) covering all 63 items, 79 skills, 18 enemies, and
  10 shops -- full 1:1 coverage with the current game data, verified by a
  new coverage test. Wired into every place a player actually sees one of
  these by its own identity: the Inventory/Equipment screen (equipped
  slots, item list, item-picker sheet, detail dialog), shop stock lists,
  the Skills screen (list rows and detail dialog), the race/profession
  skill preview during character creation, the Fight screen's enemy
  portrait, and the Boutiques/basic-shops lists in Camp and Town Hub. Falls
  back to the existing generic icon for any id without a matching asset
  (defensive, not expected to trigger today).

## [1.98.0+126]

Wisdom finally does something in a fight, status effects show up more often,
and combat is meaningfully harder across the first three chapters.

### Added
- **Wisdom's combat role.** Beyond backing Wisdom story checks, it now
  amplifies every point healed (by `wisdom ÷ 2`, both dice-face Heal and
  healing Skill faces) and shortens the duration of Poison/Stun/Weaken
  landed on you by 1 round per 5 points, never below 1 round. Applies to
  active allies too, derived from their own race/profession the same way
  Strength/Dexterity/Constitution/Intelligence already were.
- **7 more status-inflicting skills** (up from 7 to 14 of 79): Rogue's
  Poison Blade now actually poisons, Mage's Frost Nova and Orc's Savage
  Cleave inflict Weaken, and Ranger's Trap Set plus 3 elemental enemy moves
  (Frigid Grip, Molten Backlash, Radiant Judgment) inflict Stun/Weaken —
  status effects show up in noticeably more fights.

### Changed
- **Harder combat in Chapters 1-3.** Enemy health and damage scale up by
  chapter (+15% in Ch1, +35% in Ch2, +10% in Ch3), pulling the overall
  combat win rate down from ~95% to ~87% and roguelike-style "close calls"
  (lost fights — permadeath is off by default, so these cost time, not the
  run) up to an average of 3 per playthrough. Chapters 4-5 are intentionally
  left alone: an existing regression test (`boss_balance_test.dart`) locks
  in win-rate floors for 3 late-game bosses that a prior session already
  found could become unwinnable, and that ceiling is the reason overall
  difficulty stops short of an even harder target.

### Fixed
- The playthrough simulator never actually visited Camp's own Expedition
  zones (chapter 3 onward) — only Town Hub's chapter-2 zones were ever
  driven, so `z_cinder_row`/`z_scaffold_yards` always showed 0 attempts in
  every prior simulation batch. Fixed in the (non-shipping) Python
  simulator only.

## [1.97.0+125]

Three new camp buildings that finally give endgame gear somewhere to be
bought, and loot that leans toward what your profession actually wants.

### Added
- **Three new camp houses: Hammersmith, Academy, and Sharpweave Den.** Each
  is buildable from Camp for 350 gold and, on completion, immediately
  unlocks a themed shop — the Hammersmith's Forge (swords/spears/shields),
  the Arcane Academy (staves), and the Sharpweave Den (daggers) — stocking
  tier 6-10 gear that was previously only obtainable as loot, quest, or zone
  rewards and had no purchasable source anywhere in the game. Built houses
  now show an "Unlocks: ..." line alongside their existing stats, and Camp
  gained a new Boutiques section listing every shop a built house has
  opened, reusing the same shop-browsing screen as Town Hub.
- **Profession loot affinity.** Every profession now favors one ability
  score's gear (Warrior → Strength, Mage → Intelligence, Rogue/Ranger →
  Dexterity; Cleric has none, since Wisdom has no gear-scaling tie-in) via a
  new `preferredScalingStat` field. A combat loot roll for an item whose own
  `scalingStat` matches gets a flat +20 percentage-point bump on top of the
  existing luck bonus — a Mage sees noticeably more staves off the same
  enemy a Warrior would fight, without any single drop ever becoming
  guaranteed.

## [1.96.0+124]

Gear that actually cares who's wielding it: weapons now scale with your
ability scores, and the heaviest ones require enough of them to wield at all.

### Added
- **Ability-score weapon/shield scaling.** Every sword, spear, dagger,
  staff, and shield now declares which ability score it scales with
  (Strength for sword/spear, Dexterity for dagger, Intelligence for staff,
  Constitution for shield), adding `stat ~/ 2` on top of its flat
  attackDamage (or armor, for shields) — a Mage's staff hits harder with
  Intelligence, a Warrior's sword with Strength, without any profession-
  specific code: the effect is entirely driven by which weapon type is
  equipped. Never subtracts below an item's flat value, so an off-build
  weapon just doesn't reach its full potential. Applies to allies' own
  equipment too, scaled off their race/profession-derived scores.
- **Stat-gated equipment requirements.** The heaviest three tiers of every
  sword and spear now require both Strength and Constitution to equip (a
  "heavy sword" needs the power to swing it and the stamina to keep
  swinging); daggers, staves, and shields scale their own single-stat
  requirement up through their tiers. Early-tier gear (t1-t3) stays
  unrestricted so no build is locked out of basic equipment. The
  Inventory/Equipment screen shows a lock icon and a "Requires: N STR, M
  CON"-style note on anything not yet met, for both the player and any
  ally.
- Updated the four ability-score stat-hold explanations (Strength,
  Dexterity, Constitution, Intelligence) to mention their new gear tie-in.

## [1.95.0+123]

Hold a stat to see what it does.

### Added
- **Long-press stat explanations.** Every core stat row (Health, Base
  Damage, Base Armor, Luck, Charisma, Strength, Dexterity, Constitution,
  Intelligence, Wisdom) on the character sheet (`RaceProfessionScreen`) and
  the level-up screen (`LevelUpScreen`) can now be held to pop up its
  purpose and gameplay impact, reusing the existing `*_desc` strings so the
  two screens' explanations never drift apart. The level-up screen's
  existing tap-the-icon shortcut still works alongside it.
- A small hint ("Hold a stat to see what it does") on both screens so the
  new interaction is discoverable.

## [1.94.0+122]

A reviewer-comment system for story nodes: leave a private note while
reading/testing in Edit Mode, then find every note again in one place.

### Added
- **Reviewer comments on story nodes.** The node editor (`StoryNodeEditorScreen`)
  has a new "Reviewer comment" field, saved on `StoryNode.authoringComment` —
  a free-text note never shown to players, for things like "pacing feels
  rushed here" or "needs a 3rd choice". Persists through the same local
  edit-override mechanism every other node edit already uses.
- **Review Comments screen**, reached from the Data tab: lists every node
  with a comment (id, chapter, comment text), tap to jump straight into
  that node's editor, plus Copy/Export actions (reusing a newly-extracted
  `lib/utils/export_utils.dart`) so the whole list can be pulled off the
  device as plain text.
- The Map (story graph) view now marks commented nodes with a small badge,
  and its node-info sheet shows the comment inline plus a new "Edit Node"
  button, so a comment is discoverable without leaving the graph.

### Known issue (pre-existing, not touched here)
- While live-verifying this feature, found the choice editor's "destination
  node" dropdown overflows at phone width — unrelated to this change, left
  as-is; flagged for a follow-up fix.

## [1.93.0+121]

Over-branched story nodes (10-12 choices piled into one flat button list)
now present like a village instead of a wall of text.

### Changed
- **Nodes with more than 5 choices** (currently 2010, 2015, 3005) now split
  their non-core choices — shops, fights/skill checks, and people to talk
  to — into categorized "Shops" / "Challenges" / "People" sections with a
  Rest option, rendered as icon-led cards below the node's own main
  branches, instead of one long list of identical-looking buttons. Nodes
  with 5 or fewer choices are unchanged. All existing choice logic (ability
  checks, combat, unlocks, routing) is shared via one extracted function,
  so the new cards behave exactly like the buttons they replace.

## [1.92.0+120]

Chapter 1 follow-up to the Town Hub/Camp redesign: two of Chapter 1's own
shop unlocks turned out to duplicate Town Hub's now-permanent boutique list,
undercutting "Town Hub is the first shopping stop between Chapter 1 and 2."

### Fixed
- **Removed two Chapter 1 shop unlocks that now duplicate Town Hub's
  permanent boutiques.** Node 100 (the opening tavern scene) no longer
  unlocks the Blind Beggar Stall, and node 891 (the pre-boss docks scene) no
  longer unlocks the Weaponsmith's Forge — both are already always available
  at Town Hub from the Chapter 1/2 seam, so granting them again mid-Chapter-1
  was redundant and made the boutiques feel like they "arrived too early."
  Node 891's other two shop unlocks (Black Market Docks, Shieldwright's
  Hall) are untouched: neither is part of Town Hub's curated list, and
  neither has any other unlock point in the story graph, so removing them
  would have made those shops permanently unobtainable.



Reshapes the mid-game meta-progression loop so Town Hub and Camp read as two
distinct, sequential stops rather than one thing available from the start
and another available from the very first chapter.

### Changed
- **Town Hub is genuinely "the first stop between Chapter 1 and 2"** now
  that it has more than two shops: added Apothecary Row to its permanent
  boutique list (alongside the Blind Beggar Stall and the Weaponsmith's
  Forge). Its unlock point was already exactly this seam
  (`chapterOfNode >= 2`, flipping the moment Chapter 2's opening node
  fires) — this was a content gap, not a gating one.
- **Camp is now discovered at the start of Chapter 3**, not available from
  the very first minute of a new game. `PlayScreen`'s Camp entry mirrors
  Town Hub's own lock/subtitle treatment, unlocking once
  `chapterOfNode >= 3`.
- **A freshly recruited companion now joins the active party immediately**
  (up to capacity, respecting their own house gate if they have one) —
  `recruitAlly` no longer requires a trip to Camp to actually help in a
  fight. Needed once Camp stopped being available from turn one: Kelda,
  Sable, and Liora all recruit in Chapter 2, before Camp exists.
- **Camp becomes the second expedition hub, picking up where Town Hub
  leaves off.** Camp's Roster/Houses now sit above a new Zones section
  showing every zone from Chapter 3 onward (two new ones: Cinder Row and
  the Scaffold Yards, `ashenStreets`-themed, dropping gold and the new
  `plate_emberproof` armor respectively) — forward-compatible with future
  chapters' zones without further wiring.

### Added
- **A quiet payoff for actually doing Town Hub's expeditions**: completing
  Fisherman's Row and Tanner's Court (2 of Town Hub's 3 zones) now marks
  the Rusty Eel's hull patched and sail mended. At Chapter 2's close (node
  `2900`, the approach to the Upper Gate), a new choice lets the player
  check on the ship one last time and see it seaworthy again — locked with
  in-character flavor text if they never got around to it. Deliberately a
  narrative acknowledgment, not a hard requirement: skipping every
  expedition still lets the story continue exactly as before, just without
  that beat.
- `partyCapacityFor` (`player_session_provider.dart`), extracted out of
  `CampScreen` so its own roster capacity math and `recruitAlly`'s new
  auto-activate logic can never drift apart.

## [1.90.0+118]

Elements go from flavor text to a real combat layer, and last patch's
status-effect system gets a wider footprint across skills, companions, and
items.

### Added
- **Elemental damage/resistance, finally wired up.** `items.json` has
  carried per-element `<element>DmgBonus`/`<element>Resist` fields (and a
  fully-authored Fire→Wind→Earth→Water→Electricity staff progression) since
  early in this project, completely unread by combat. `resolvePlayerFace`
  and `resolveEnemyMove` now both apply them: a party member's outgoing
  Attack/Skill damage is boosted by their gear's matching element bonus (the
  element comes from the skill's own `element` field for Skill faces, the
  die face's own for Attack faces), and an enemy move's damage is cut by the
  target's matching resist gear the same way armor and block already are.
- **Two new elements: Ice and Light.** Added to `elementOptions` alongside
  Fire/Wind/Earth/Water/Electricity/Void, with their own `iceDmgBonus`/
  `iceResist`/`lightDmgBonus`/`lightResist` item fields (Void picked up the
  matching `voidDmgBonus`/`voidResist` pair too, completing `void_banner`'s
  existing all-elements bonus).
- **`OnHitByElement` is a real condition now.** `skillMoveConditionOptions`
  has listed it since enemy moves first shipped; it always evaluated to
  false. `FightScreen` now tracks which elements the party actually hit the
  enemy with each round and feeds it to `resolveEnemyMove`, so a move can
  react to it — `iron_golem` now shrugs off Fire and flings it right back
  (`molten_backlash`, a real reason to *not* bring fire against a golem).
- **New elemental content:** `frigid_grip` (Ice) for the docks' Overseer
  Renn, `radiant_judgment` (Light) for Inquisitor Kroll, plus three new
  elemental-gear drops (`plate_emberproof`, `cloak_frostward`,
  `circlet_radiance`).
- **Status effects reach further.** Three more signature skills now inflict
  one: `warrior_shield_bash` (Stun — a shield bash staggers), `rogue_backstab`
  (Weaken — thrown off balance), and `voidkin_entropy_touch` (Poison —
  unraveling flesh, matching last patch's "void corruption" pitch).
- **A cure for them, too.** New `antidoteCount` resource (mirrors
  `potionCount`'s plumbing exactly) and `consumeAntidote()` clear every
  active Poison/Stun/Weaken off the player. A new Antidote button appears in
  `FightScreen` whenever the player actually has something to cure; a new
  `antidote` item drops from Plague Hounds.

## [1.89.0+117]

Combat gets a status-effect system: Poison, Stun, and Weaken now exist as
real, persistent afflictions rather than one-off numbers, on both sides of a
fight.

### Added
- **Poison/Stun/Weaken status effects.** New `lib/combat/status_effect.dart`
  holds the pure model (`StatusEffect`, `applyStatusEffect`,
  `poisonDamageFor`, `isStunned`, `applyWeaken`, `tickStatusEffects`) and
  `FightScreen` wires it into the party's simultaneous-round turn loop:
  Poison ticks flat damage at the start of the afflicted side's round,
  Stun excludes a combatant from acting that round (with the whole party
  round auto-skipped straight to the enemy's turn if everyone able to act
  is stunned, rather than stalling on a roll nobody can make), and Weaken
  cuts the afflicted combatant's own outgoing damage for its duration.
  A new row of small chips under each health bar (party and enemy) shows
  every active effect with its remaining rounds.
- **Skills and enemy moves can inflict them.** `skills.json` records gained
  optional `inflictsStatus`/`statusDuration`/`statusMagnitude` fields, read
  by both `resolvePlayerFace` (Skill faces) and `resolveEnemyMove` (enemy
  `skillMoves`, via the same referenced skill record) in
  `combat_engine.dart`. Wired into real content: the player's existing
  `venomous_ambush` merge-skill now actually poisons on hit (matching its
  "the wound that doesn't stop" flavor text), a new `plague_bite` gives
  Plague Hounds their disease bite, and two new Void-flavored abilities —
  `void_drain` (Weaken) and `disorienting_pulse` (Stun) — round out Void
  Stalkers and the Void Manifestation boss.

### Changed
- `resolvePlayerFace`/`resolveEnemyMove` take an optional `activeEffects`
  parameter so a Weakened attacker's damage is correct in both the
  resolved number and its preview/log message, not just applied
  after the fact.

## [1.88.0+116]

Interface diversity, this time: the story graph has tagged every node with
its setting (`context_taxonomy.ui_theme` — docks, cathedral, slums,
catacombs, sewers, torture chamber...) since the very first version of this
app, but that field only ever picked which flavor pool random excursions
drew from. The reading screen itself always looked identical no matter
where the player was.

### Added
- **Location-based accent theming on the story reading screen.** Eight
  settings with real narrative weight — docks, cathedral, torture chamber,
  slums, catacombs, sewers, and the two ending flavors (origin_ending,
  epilogue) — now shift the prose card's border, header color, and a faint
  background tint to match, plus a light typographic nudge (letter-spacing,
  line height) for a few of them: tighter and quicker through interrogation
  scenes, slower and heavier through the catacombs and sewers. The
  remaining, rarer settings (bridge, market, hovel, gate, prologue,
  battlements — each under 5 nodes) are left exactly as they were.
  Deliberately layered on top of the player's own selectable app palette
  (Settings → 7 color options) rather than replacing it: only this one
  card's colors move, never the app's chrome, navigation, or any other
  screen. New `lib/data/ui_theme_palettes.dart` holds the per-location
  palette data and a pure `resolveUiAccent` blending function — accent
  hues are blended into the scheme's own `onSurface`/`outlineVariant`
  colors (not used raw) so every location stays legible in both light and
  dark mode and against all 7 base palettes, verified with unit tests
  checking luminance in both directions.

## [1.87.0+115]

Gameplay diversity, as opposed to the last two entries' narrative/world
content: a genuinely new non-combat interaction type, not just another
single ability-check roll.

### Added
- **Skill Challenges: a new multi-round "push your luck" mechanic**, distinct
  from both a one-shot ability check (a single roll settles it) and full
  combat (health, dice faces, an enemy). A skill challenge is a sequence of
  rolls against the same ability and DC, won by reaching a set number of
  successes before a set number of failures — an early bad roll doesn't end
  the attempt, it just narrows the margin, which is the whole point of
  offering it as its own thing. Implemented as two new optional fields on a
  story choice (`challengeSuccessesNeeded`/`challengeMaxFailures`, alongside
  the existing `checkAbility`/`checkDC`/`failNextId`) resolved by a new pure,
  independently-testable function (`lib/data/skill_challenge.dart`) and
  presented through a new dedicated screen
  (`lib/screens/skill_challenge_screen.dart`) that reveals each round in
  turn with a running success/failure tally before the final result — pushed
  and popped the same way the combat screen reports a win. Added editor
  support for the two new fields alongside the existing ability-check editor
  UI, so more of this content can be authored later.
- **First real use: a card game at the Chapter 2 harbor market** (new choice
  on node `2015`, "Sit in on a card game with dock regulars"). Win 3 hands
  before 2 losses (a Luck-based skill challenge, DC 12) for a solid payout;
  lose the challenge and it costs a little instead — either way, the story
  continues normally.

## [1.86.0+114]

Second round of narrative/world diversity content, this time in Chapter 3:
a population the story had repeatedly referenced as backstory (the
Inquisition's slum purge, mentioned at nodes `100`/`3001` and named as the
High Warden's crime in `q_ch3_the_high_wardens_fall`) but never gave real
presence to.

### Added
- **The Reckoning Wall, a new Chapter 3 location, and its side quest.**
  Reached via a new choice on the Ashen Quarter hub (node `3005`), the wall
  is where purge survivors — led by a woman named Reya — chalk the names of
  everyone the Inquisition's official record insists simply "relocated," a
  counter-record to the same erasure already running through this chapter's
  Hall of Records content. An Inquisition auxiliary (a new
  `inquisition_auxiliary` enemy) is sent to burn the wall before it becomes
  evidence. Players can talk him down with a DC 13 Intelligence check —
  quoting Inquisition procedure back at him, deliberately a different stat
  and angle than Tern Row's Charisma-based resolution — for a no-combat
  outcome (25 gold, +5 alignment, its own flag), or fight him directly,
  which registers the formal quest (`q_ch3_reckoning_wall`, 50 gold/60 XP/+5
  alignment on completion). Failing the check still leads to the fight
  rather than a dead end, same pattern as Tern Row.

## [1.85.0+113]

Acted on a full Chapter 1-2 audit: one game-breaking bug fixed, two smaller
balance/continuity issues cleaned up, plus a requested change moving the
chapter's first shop access next to its boss fight. (One audit finding —
`rat_matriarch`/`kroll_the_branded` tagged `minChapter: 2` despite fighting
in Chapter 1 — turned out to be correct as shipped: that field only gates
the *random* excursion pool, not their scripted story fights, and was
deliberately set that way in a previous pass to keep Chapter 1's random
encounters safe. Left unchanged. Also skipped a purely cosmetic finding —
missing `npcs.json` entries for Kelda/Sable/Liora — since nothing currently
reads that data for them and adding unused records isn't worth the churn.)

### Fixed
- **Vess's questline (`q_ch1_vess_in_the_dark`) was permanently
  unreachable.** Node `151_vess` requires the `void_marked` flag, but the
  only choice that ever sets it (`281_scarred`, reached by *failing* the
  luck check at the Tear) routed straight past the market stall that leads
  to her — no playthrough could ever satisfy the gate. `281_scarred`'s
  "Continue" now routes through node `151` first, so a void-marked player
  can actually find her. Added a permanent regression test
  (`test/story_graph_integrity_test.dart`) that walks every path from the
  start node tracking which flags are set along the way, since the
  existing integrity check deliberately ignores `reqFlags` gating and
  wouldn't have caught this.
- **Failing the Chapter 2 "read the crowd for an informant" Wisdom check
  landed the player on the *aftermath* text for a plague-hound fight they
  never actually had.** `failNextId` jumps straight to a node, skipping
  combat entirely — so the old target (`2015_hound`, the hardest fight at
  that hub) played as pure narration of a win that never happened. Added a
  proper failure node (`2015_informant_caught`) with its own light,
  appropriately-scaled consequence (a real `street_bandit` fight).
- Reworded node `2030`'s arrival text at Vane's, which assumed "whatever
  I'd brought him" — a real mismatch for the newer branches (Kelda, Sable,
  Tern Row) where nothing was physically brought. Now frames it as Vane
  having heard about the player's evening generally, which fits every
  incoming path.

### Changed
- **Moved the Chapter 1 market's first shop access to node `891`**, the
  single node every Chapter 1 branch (Surrender or Unfurl the Bundle)
  passes through immediately before the boss fight — previously it only
  lived at node `151`, an optional detour skippable outright by two of the
  three choices at the node before it, so a real playthrough had no
  guarantee of ever seeing a shop before Chapter 1's climax. Also added an
  explicit heal choice at the same node, so a player who took the harsher
  Surrender branch (which stacks two unhealed fights) isn't forced into
  the boss below full health while the Bundle branch always was.

## [1.84.0+112]

Added narrative/world content: a new dockside location and side quest
giving real presence to a population the story had only ever mentioned in
passing.

### Added
- **Tern Row, a new Chapter 2 location, and its side quest "Tern's
  Toll."** `Liora's Watch` has always referenced smuggler-run "refugee
  boats," but the refugees themselves never appeared as people — Tern Row
  fixes that: a quarter of the Tide-Kin, seafaring refugees from the
  Drowned Isles, with their own funerary custom of setting lit paper boats
  adrift at dusk. Reached via a new choice on the harbor hub (node
  `2015`), the quarter's organizer, Nadira, explains that an Inquisition
  customs officer (Overseer Renn, a new `dock_overseer` enemy) is
  extorting the quarter with an invented "landing toll" and threats of
  deportation. Players can talk him down with a DC 13 Charisma check for a
  no-combat resolution (20 gold, +5 alignment, its own flag), or refuse
  and fight him directly, which registers the formal quest
  (`q_ch2_terns_toll`, 40 gold/45 XP/+5 alignment on completion). Either
  way, failing the talk-down still leads to the fight rather than a dead
  end.

## [1.83.0+111]

Follow-up to a question about whether an NPC could actually mislead or trap
the player: it turned out the narrative engine already had every piece
needed (ability checks, `triggerEnemyId`, branching), but no NPC in the
story graph actually used them that way. Added a real example.

### Added
- **The Chapter 2 harbor informant (node `2015_informant`) can now genuinely
  set you up.** Trusting him outright — or trying to see through him and
  failing a DC 12 Wisdom check — routes into a new node
  (`2015_informant_trap`) where his "associates" spring an ambush
  (`street_bandit`) the moment you go looking for the warden he named.
  Catching the lie on a successful Wisdom check instead routes to
  `2015_informant_exposed`: no fight, and he pays out 15 gold for your
  discretion. The quest (`q_ch2_informants_tip`) still unlocks either way —
  only whether you walk into the ambush changes.

## [1.82.0+110]

Correction to the previous entry: "Slum Thug — cleared, not the culprit" was
only true for the diagnostic's own hand-rolled combat loop, which always
modeled a properly created character. It never actually exercised the real
in-app autoplay tools those bosses were investigated with, and a real
in-app **Play to Chapter** run hit exactly the "stuck against slum_thug"
failure the earlier investigation had ruled out — caught from a player's own
screenshot of that failure.

### Fixed
- **Autoplay (`Play to Chapter` and the map's node/chapter jump) lost every
  single fight when starting from a brand-new game, reporting "stuck"
  against whichever enemy happened to be first on the path — Slum Thug in
  the reported case, but any enemy would have triggered it.** Root cause:
  `autoplayToNode`/`autoplayToChapter` (`lib/data/autoplay_engine.dart`)
  walked straight through the story's character-creation choice (node 0's
  "Choose who you are...") like any other choice, without ever calling
  `PlayerSessionNotifier.startNewGame(...)` — unlike the real story player
  screen, which special-cases that choice. The simulated session was left
  with no race, profession, or equipped die, so `_simulateFight`'s die-face
  lookup came back empty and every combat auto-lost, exhausting all retries
  against the first fight on the walked path. Fixed by handling
  `StoryChoice.opensCharacterCreation` the same way the real player flow
  does: autoplay now picks a random race/profession and starts a real game
  the moment it walks through that choice, mirroring the "Randomize"
  convenience already on the race/profession picker. Added a regression
  test (`test/autoplay_engine_test.dart`) that drives a real
  `autoplayToChapter` run from a fresh session and asserts it doesn't get
  stuck on its first fight.

## [1.81.0+109]

Investigated a "speedrun" playthrough to see how far the fastest route
through the story could actually get, which surfaced a real problem: three
late-game bosses were effectively unwinnable for a normal (non-optimal,
non-party-boosted) character, hard-blocking the story at three separate
points. Diagnosed with a proper simulation (30 full playthroughs, real
combat resolution, correctly modeling that a lost story fight blocks
progress and must be retried) rather than guesswork — also used the same
diagnostic to check an unrelated report that Slum Thug was blocking
progress, and cleared it: 33 encounters, 100% first-attempt win rate,
not the culprit.

### Fixed
- **Inquisition High Warden (Ch3), Hollow Court Zealot (Ch4), and Void
  Manifestation (Ch5, the climax) were near-unwinnable walls.** The
  diagnostic simulation showed a normal playthrough needed an average of
  93, 176, and **249** retry attempts respectively to clear these three —
  Void Manifestation regularly hit the 300-attempt cap outright (a genuine
  soft-lock). Root cause: `scaledMaxHealth`/`scaledDamage` scale *every*
  enemy's stats up with player level, but these three had such a high base
  that the scaling compounded faster than a character's own (linear,
  stat-point-driven) growth could keep pace — checked directly, win rate
  against Void Manifestation barely moved between level 3 and level 10
  (0% → 7%), so grinding wasn't a real way past it either.
  Reduced each boss's base stats (found via a win-rate search targeting
  ~30-50% for a solo, unassisted character at the level a normal
  playthrough actually reaches them):
  - Inquisition High Warden: 200hp/23dmg → 150hp/17dmg (~47% win rate at
    level 3)
  - Hollow Court Zealot: 218hp/25dmg → 142hp/16dmg (~34% win rate at
    level 4)
  - Void Manifestation: 236hp/27dmg → 154hp/18dmg (~30% win rate at
    level 4, matching this fight's original "tough but fair" design
    intent) — and critically, this win rate now actually **rises with
    level** (~30% → 40% → 64% → 75% from level 4 to 8), so a player who
    grinds a bit more before attempting the climax is meaningfully
    rewarded for it, instead of hitting a wall that doesn't move no
    matter how strong they get.

Added `test/boss_balance_test.dart`, a permanent regression test asserting
each boss's win rate stays in a healthy band (catches both a regression
back toward the old unwinnable stats and an over-correction that makes the
fight trivial), and confirming Void Manifestation's win rate keeps rising
with level.

## [1.80.0+108]

Balanced difficulty across the early chapters so Chapter 1 reads as the
safe tutorial it's meant to be, and Chapter 2's roguelike expeditions are
where real death risk actually starts — before the escalation continues
into Chapter 3 and beyond.

### Fixed
- **Expeditions could roll any enemy in the game, with zero chapter
  gating.** `ExpeditionScreen._rollEvent` built its enemy pool from every
  entry in `enemies.json`, filtering only by "already fought" — unlike
  regular excursions, it never checked `minChapter`. A Chapter 2
  expedition (a level ~2 character) could randomly draw a Chapter 5
  endgame monster (236hp/27dmg) with no way to decline the fight and no
  way to win it. Extracted the excursion engine's existing chapter-gate
  logic into a new shared `SubNodeEngine.filterEnemyPool`, used by both
  excursions and expeditions now, so a zone's encounters are always
  capped to enemies that chapter's story has actually introduced.
- **Rat Matriarch and Inquisitor Kroll could ambush a brand-new
  character.** Both are scripted Chapter 1 story bosses fought near the
  chapter's end (nodes 850/855 and 955, right before the Chapter 1
  finale) — strong enough to be a real threat at that point — but were
  flagged `minChapter: 1`, making them eligible for a *random* Chapter 1
  excursion from the very first node. Bumped both to `minChapter: 2`:
  their scripted story fights are unaffected (main-path encounters never
  consult `minChapter`), but they can no longer ambush an early Chapter 1
  run, and they now also fold into Chapter 2's random pool — one more
  reason expeditions there feel noticeably more dangerous than the
  tutorial chapter that came before them.

Net effect: Chapter 1's random encounters are now capped at Inquisition
Warden (80hp/12dmg) — safe, teaches the mechanics, essentially unlosable
for a fresh character. Chapter 2's pool tops out around Plague Hound
(146hp/17dmg) and the now-included Kroll/Rat Matriarch (145/120hp,
18/15dmg) — a real chance of going down in an expedition's three-encounter
run, especially back-to-back with no healing between fights, exactly
where the "start to die a little" ramp should begin.

Added `test/sub_node_engine_test.dart` covering the shared chapter gate,
including the exact regression (a chapter-2 pool never contains a
chapter-5 enemy).

## [1.79.0+107]

Reworked the skill system to play like a roguelike build each run: skills
now level up in place, two skills can be fused into a new one, and dying
wipes the build back to class basics so every life is its own experiment.

### Added
- **Skill tiers** — any unlocked skill can be upgraded up to 3 times,
  each tier adding +25% to its damage/heal numbers and +0.1 to its damage
  multiplier (`combat_engine.dart`'s new `applySkillTier`). Upgrades are
  applied live at combat-resolution time from a per-player tier map, never
  by mutating the shared skills database (enemies read from that same
  table via their own skill references).
- **Skill Essence** — a new resource earned 1:1 alongside XP from combat
  wins and quest completions, spent to buy tiers (rising cost: 3/6/9
  essence per tier). Shown next to Skill Points at the top of the Skills
  screen.
- **Merging skills** — a new "Craft a Skill" button on the Skills screen
  opens a recipe list (`assets/gamedata/skill_merges.json`) of two-skill
  fusions; picking a ready recipe consumes both input skills and unlocks a
  new, more powerful hybrid in their place. Six recipes ship with this
  release: Blazing Shadow, Unbreakable Will, Bastion of Stone, Arcane
  Convergence, Venomous Ambush, and Wrath of Dawn — each crafted from two
  existing race/profession or starter skills.
- **Skills reset on death** — permadeath now wipes the skill build back to
  exactly what a fresh character would have (the race and profession's
  own standard skill, wired onto the starter die), clearing every other
  unlocked skill, all tier progress, and skill essence, and refunding
  skill points back to the profession's starting amount. Level, gold,
  stats, owned dice, and story progress are untouched — only the skill
  build itself restarts, so each life is a genuinely new roguelike run.
  The death screen now shows how many skills were lost in the reset.

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
