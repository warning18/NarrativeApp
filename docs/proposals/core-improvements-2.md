# Core: improvements, round 2 (proposal, v1.756)

This is a second look at Core's own scope, with fresh eyes on what landed
since round 1 (`core-improvements.md`): the page break (v1.750), the 15%
enemy damage (v1.743) and the splits.

It lists **only new items**. Nothing from round 1 (P1–P6, R1–R5, B1–B4) is
here, nor anything merged or held. Removing, simplifying and speeding up
come first; there are no new features.

The starter die (B1/B2) has its own note: `docs/simulation/starter-die.md`.
Nothing is built from this note until the items are released.

Each item says what it is, why it matters, its size (S/M/L), its risk, and
what the user would notice.

## 1. Ranked (value over effort)

| # | Item | Size | Risk | The user notices |
|---|---|---|---|---|
| N1 | The editor's game_config defaults contradict the game | S | low | the data editor stops offering 100 HP / 10 damage as "default" |
| N2 | `city_plans.json` written minified | S | low | the app is about 350 KB smaller |
| N3 | Two generator files in `lib/` that only `tool/` runs | S | low | nothing (smaller app) |
| N4 | `[PAGE]` shows as text in the narration recording preview | S | low | no stray "[PAGE]" in that screen |
| N5 | Fold `ordinaryDamageLift` into the damage floor table | S | low | nothing (one table instead of a table and a factor) |
| N6 | `loadClanData` / `loadOfferTables` re-parse on every call | S | low | slightly faster offers and clan pages |
| N7 | Data fields stored at their default everywhere | S | low | nothing (smaller data files) |
| N8 | The scene's text is composed 2–3 times per Journey build | M | low | slightly smoother Journey |
| N9 | `SimProgression.legacy` and the simulator's clash toggles are test-only | M | low | nothing |
| N10 | `_settleFight` is 460 lines | M | med | nothing |
| N11 | The procedural city plan still drawn for 16 stored cities | L | med | nothing if done right; needs UX |

## 2. The items

### N1. The editor's game_config defaults contradict the game (S, low)

**What.** `lib/gamedata/game_config_schema.dart` gives `maxHealth` a
default of **100** and `baseDamage` a default of **10**. The game's own
values (`game_config.json`) are **20** and **2**, the scale since
`stat-scale.md`.

The schema also has no field for `antidoteCount`, `perception` or the six
stats. So the editor can't show them, and it falls back on the wrong
numbers whenever a value is cleared.

**Why.** Someone who resets a field in the data editor gets a character
five times too strong. Nothing warns them.

**Fix.** Set the defaults to the shipped values, add the missing fields,
and add a guard test that compares the schema's defaults with
`game_config.json`.

**User notices.** In the data editor, "reset" gives the real values.

### N2. `city_plans.json` written minified (S, low)

**What.** The file is 733 KB pretty-printed and **386 KB minified**. Only
the generator (`tool/city_plans/gen_city_plans.dart`) writes it, and no
person edits it by hand.

**Fix.** Have the generator write it without indentation.

**Risk.** Diffs of the file become one line. That is fine for a generated
file, but say so in its header comment.

**User notices.** The download is about 350 KB smaller.

### N3. Two generator files in `lib/` that only `tool/` runs (S, low)

**What.** `lib/data/city_plan_generator.dart` (757 lines) and
`lib/data/town_service_pins.dart` (177 lines) are imported only by
`tool/city_plans/*.dart` and by tests. The app only names them in comments.

**Fix.** Move them under `tool/city_plans/`, along with their tests' imports.

**Why.** It keeps generator code out of the app bundle and out of the
analyzer's app scope.

**Risk.** Low. The tests that pin the stored plans keep running, from the
new path.

### N4. `[PAGE]` shows as text in the narration recording preview (S, low)

**What.** Since v1.750, a `[PAGE]` marker cuts a scene into pages. The
Journey, the story player and the read-aloud clips (`narration_clips.dart`)
all handle it. `narration_recording_screen.dart:285` builds its preview from
`node.descriptionFor(...)` raw, so one node there (`6010_record`, both
languages) shows the marker as text. The expedition scene passes its text
through `stripStoryMarkup`, which doesn't know the marker either. No
expedition node carries one today, but the next written one would show it.

**Fix.** Make `stripStoryMarkup` (Core's `story_markup.dart`) drop
`pageBreakMarker`, and have the recording preview use `joinedNarration`.
That is two lines, plus a test.

**Touches.** The recording screen is a shared screen (one line).

**User notices.** No "[PAGE]" in the recording screen.

### N5. Fold `ordinaryDamageLift` into the damage floor table (S, low)

**What.** The 15% lift (`combat_engine.dart`, `ordinaryDamageLift = 1.15`)
multiplies `enemyDamageBaseMultiplier` from chapter 2 on, on top of the
per-chapter floor table. Two knobs now do one job.

**Fix.** Multiply the lift into the table's chapter 2+ rows and delete the
constant.

**Risk.** Low. The simulator and boss tests must give identical numbers;
check rounding.

**User notices.** Nothing; tuning gets one place to look.

### N6. `loadClanData` / `loadOfferTables` re-parse on every call (S, low)

**What.** Both read and decode their JSON on each call (11 callers between
them), while a provider already holds the same tables. This is the same
kind of finding as round 1's P6, which was about other functions.

**Fix.** Cache the decoded result once (a `late final` or the provider's
value), and drop the duplicate loader where the provider serves.

**User notices.** Offers and clan pages open a little faster.

### N7. Data fields stored at their default everywhere (S, low)

These are new fields, outside R3's list. Each is the same value on every
record, and the reader already defaults to it:

- `skills.json`: `healthMod: 0` and `isActiveSkill: true` on all 162
  skills.
- `ships.json`: `shipName` is "The Rusty Eel" on all 14 hulls. Nothing
  outside the editor reads it.
- `zones.json`: `rewardDiceId` and `rewardAllyId` are empty on all 20
  zones, and nothing in `lib/` reads either one.
- `dice.json` faces: `"element": "None"` and `"linkedSkillID": ""` are on
  most faces.

**Fix.** Drop them, and make the schema's default match. That needs the
editor not to write defaults back when a record is saved; check
`GameDbRepository` first.

**Risk.** Low. A record saved by an older editor still loads, because the
values are the defaults.

### N8. The scene's text is composed 2–3 times per Journey build (M, low)

**What.** Since the page break, the Journey composes the scene's narration
for the page count, and `_ScenePanel` composes it again for display. The
story player also calls both `composeNarration` and
`composeNarrationParts`.

**Fix.** Compose once per build and pass the parts down.

**Touches.** `journey_screen.dart` is UX-2's split (4-2), so this waits
until that lands.

**User notices.** A slightly smoother Journey on slow phones.

### N9. Test-only simulator modes (M, low)

**What.** Two simulator code paths only tests exercise:

- `SimProgression.legacy`: about 80 lines, plus its perk and sign pick
  helpers. The simulator screen and CI batches use the ladder.
- The clash toggles (`clash` / `clashOff`), which only 6 tests change.

**Fix.** Drop the legacy mode, along with the tests that only pin it, and
fix the toggle at its one real value.

**Risk.** Low. The ladder tests cover the real path.

This is a code path, not the named symbols of R4's list.

### N10. `_settleFight` is 460 lines (M, med)

**What.** One function settles a fight: rewards, loot, XP, quests and
politics.

**Fix.** Split it into named steps, the same way as the 4a/4b splits. It
is a pure move, and the fight tests pin it.

**When.** After 4b–4f, in the same series.

### N11. The procedural city plan, still drawn for stored cities (L, med)

**What.** `CityPlan.of` (`lib/data/city_plan.dart`, 1,200 lines) and its
painter (UX's `city_plan_painter.dart`, 751 lines) build a plan for every
city, town and village. For the 16 places in `city_plans.json`, the Journey
then replaces it with the stored record. The procedural plan is only needed
where no record exists.

**Fix, in two steps:**

1. Skip building the procedural plan when a record exists. This is S, in
   Core's half of the code.
2. Once every place has a record, remove the procedural path, about 2,000
   lines. This needs UX for the painter and a generator run for the
   missing places.

**User notices.** Nothing. This is the largest removal on the list, so it
is ranked last only because of its effort.

## 3. Looked at and dropped

- **The autoplay "stuck" exit, copied twice.** Already in round 1's R5.
- **`healthThreshold` / `requiredElement` on enemy moves.** These are read
  (`combat_engine.dart:547,564`), so they are not dead.
- **`hunterTier: 0` on non-hunters.** It is only read for hunters.
  Harmless.
- **`PlayerSession` has 127 fields.** True, but a split is a feature-sized
  change with save-migration risk, for no visible gain.
- **`ports.json` `zoneIds`, `items.json` `setId`, `skill_merges`
  `resultSkillID`.** Each repeats data held elsewhere. Deriving them saves
  a few KB, and each would need a guard test that the copies agree.
  Low value; leave them.
