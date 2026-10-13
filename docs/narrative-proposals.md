# Narrative proposals and what Core is asked to decide

Written by the Narrative session after the user's answers to the audit
(`docs/narrative-audit.md`). Nothing here is built unless it says so. Each
section ends with what the user has to choose.

## 1. Chapters 6, 7 and 8: what changed and what Core decides

### What this PR did (text and data only)

- `q_ch6_beyond_the_tear` now says `chapter: 8`. It is the main quest of the
  "Beyond the Tear" chapter (node `7800` offers it). **Its id is unchanged**
  on purpose: the id is stored in saves (active, completed, unlocked quests)
  and in flags (`q_ch6_beyond_the_tear_accepted`), so renaming it would
  strand a player who is partway through.
- The main-quest chain now runs in story order. Before:
  `q_ch5_the_dead_heart → q_ch6_beyond_the_tear` and
  `q_ch6_the_white_fleet → q_ch6_beyond_the_tear` (the Dead Heart's turn-in
  put the Sovereign's quest in the log at the end of chapter 5, and the
  quest had two predecessors). Now:
  `the_dead_heart (5) → the_white_fleet (6) → lantern_throne (7) →
  beyond_the_tear (8)`.
- New main quest **`q_ch7_lantern_throne`** ("The Lantern Throne" /
  « Le Trône de la Lanterne »), chapter 7, offered by the chapter 7 camp
  scene `7400` (the "Sail for Candlehold" choice). One `Flag` objective:
  `on_throne`, which every crowning scene (`7590_*`) sets. It is met when
  the party has taken the Throne by any road.
- `test/quest_validation_test.dart` (one start and one end per chapter's
  main chain) still holds: chapters 5, 6, 7 and 8 each have one main quest.

### What Core is asked to decide

1. **Rewards of `q_ch7_lantern_throne`.** I set placeholders between the
   White Fleet (300 gold, 400 XP, difficulty 14) and the Sovereign (400,
   500, difficulty 15): **350 gold, 450 XP, difficulty "14", no item.** They
   are Core's numbers to confirm or replace.
2. **Do chapters 7 and 8 get goals?** Today `chapters.json` gives both
   `activityGoal: 0` and `questGoal: 0` and no `mainQuestNeedsPlaceIds`, so
   their main quest is open the moment the camp scene is reached (see
   `mainQuestOpen` in `lib/data/chapter_loop.dart`). The chapter card then
   shows no "Explored" or "Quests completed" line. Options:
   - **A. Leave at 0** (what ships). Chapters 7 and 8 stay a story
     campaign: no loop, no side quests, one scene chain each. Cheapest.
   - **B. Quest goal 1–2 in chapter 7.** Narrative adds two or three side
     quests around Candlehold (a House's grievance, a claimant's herald,
     the harbour chain-master) and the Throne waits until the party has
     settled one. Core only sets the number; no code change, since
     `chapterQuestCount` already counts any quest whose `chapter` is 7.
   - **C. A full loop in chapter 7** (activity goal and places). Candlehold
     would need found places and expeditions like chapters 3–6. This is
     Core's work (zones, discoveries, boss tiers) and a lot of it.
   Narrative's advice is **B**, because the Houses are the chapter's
   subject and quests are the cheapest way to make them matter.
3. **Chapter 8 goal.** Same question, same advice: leave at 0. The Host
   scenes (`7800_council`, `7800_lines`, the Herald fight `7810`) are the
   chapter.
4. **Saves already past `7400`.** A party that reached Candlehold before
   this release never sees `q_ch7_lantern_throne` offered (the offer fires
   when the player takes the `7400` choice). It is harmless: the quest
   gates nothing, and `on_throne` is already set for anyone who was
   crowned. Core can leave it or grandfather it (`grandfatheredQuestIds`).
5. **The playthrough simulator** (`docs/simulation/`) follows
   `nextQuestID`; its quest report will list the new link. Worth a re-run.

**The user chooses:** option A, B or C for chapter 7; A (or something else)
for chapter 8.

## 2. Intrigues for chapters 7 and 8 (proposals)

The existing intrigues have six stages that run chapters 1 to 7. These three
start late (stages in chapters 6–8) and use the new chapters. All three are
content only: scenes with `politics.intrigue` steps and outcomes in
`intrigues.json`, no new mechanic. Each needs its outcome numbers set by Core.

- **The Taken's Names.** The Sovereign's throne is carved with the names of
  the people the tear took. In chapter 7 a clerk in Candlehold has been
  copying them; in chapter 8 the Host argues over whether to read them
  aloud before the crossing. Outcomes: read them (the Choir and the
  Penitents warm; the Dominion cools), burn the list (the Pit warms, a
  companion with a lost kin leaves or approves), carry it unread across the
  tear (an ending line at `7003`, "Cut the taken's names from the throne
  first" gets a reason).
- **The Host's Price.** Every power that joins the Host asks for something
  after the crossing. Stages follow the muster (`7800_council`): the
  giants want their quarry face back, the Tide-Kin want a drowned island
  raised, the oni want the bells returned, the Kindly Ones want a bargain
  honoured to the minute. Outcomes: pay all, pay some and break one, pay
  none. Uses the Host flags that already exist (`host_giants`, `host_oni`,
  `host_tidekin`, `host_kindly`).
- **The Lantern-Bearer's Will.** A sealed will, left before the
  Lantern-Bearer failed (the `dying_lantern_bearer` intrigue), names an
  heir who is neither Vane, Morrow nor Tallis. It surfaces in the Lantern
  Hall (`7520_*`) and decides what the Houses do if the claimant dies.
  Outcomes: read it, hide it, give it to the claimant you beat. Depends on
  that intrigue's earlier stages being played.

**The user chooses:** which, if any, to write after the five dormant
intrigues are merged.

## 3. Moods and themes (proposals)

How they work today: a scene's `mood` (`context_taxonomy.mood`) shows a small
tag if the string `mood_<mood>` exists in `app_strings.dart`; a few moods
(`action`, `tense`, `suspense`, `desperate`) also keep random detours from
firing in the middle of a crisis (`tenseMoods` in
`lib/data/sub_node_engine.dart`). A scene's `ui_theme` picks its accent
colour and line height (`lib/data/ui_theme_palettes.dart`) and its place tag
(`place_<theme>` string).

Of the 385 nodes, 130 are `neutral` (no tag), 98 `grim`, 72 `tense`.
Eleven nodes use `hopeful`, which has **no tag string** today: a small gap
(fixed in this PR with `mood_hopeful`).

### New moods (strings only; I can add them and re-tag scenes)

| Mood | EN tag | FR tag | Where it would sit |
|---|---|---|---|
| `wistful` | Wistful | Nostalgique | the Hollow Shore reflections, the epilogues |
| `solemn` | Solemn | Solennel | the crowning scenes `7590_*`, oaths, the Lantern Hall |
| `tender` | Tender | Tendre | camp evenings, Lysa and companion scenes |
| `uncanny` | Uncanny | Étrange | the tear, the reflections, the Dead Heart (some `creepy` become this) |
| `wry` | Wry | Narquois | the narrator's comic beats: Saltmouth bargaining, the cards, the touts |
| `defiant` | Defiant | Frondeur | stands, sieges, "hold the gate" |
| `mournful` | Mournful | Endeuillé | losing Lysa, Tobin's vigil, the drowned |
| `ominous` | Ominous | De mauvais augure | arrivals under a clan's banner, the Herald |
| `bitter` | Bitter | Amer | betrayals, the Penitent's confession |
| `wondrous` | Wondrous | Merveilleux | first sight of the tear, the giants' hall, the glass strand |

Adding a mood is a pair of strings. Only the tag changes; none of them is a
"tense" mood unless Core adds it to `tenseMoods` (suggested: `defiant`,
`ominous`).

**Done (v1.274):** all ten moods exist, and 101 scenes carry one (11 wistful,
11 solemn, 8 tender, 12 uncanny, 15 wry, 5 defiant, 10 mournful, 10 ominous,
9 bitter, 10 wondrous). Only scenes that were not already `tense`,
`action`, `suspense` or `desperate` were re-tagged, so no random detour
gate changed; `defiant` and `ominous` are therefore not tense moods, and Core
can add them to `tenseMoods` later if it wants the stands and omens to hold
detours back.

### New themes (need UX)

A theme needs a palette entry (UX) and a place string (Narrative). The 385
nodes now use 14 themes, and every chapter 5–8 place falls into `cathedral`,
`docks`, `epilogue` or `catacombs`. Candidates:

| Theme | For | Today it is |
|---|---|---|
| `fen` | the Mire Courts, Wrack's End | `docks` |
| `frost` | Rimewell, the Reliquary Quarter's cold | `cathedral` / `epilogue` |
| `forge` | Emberwick, Hammersmith, the Cinder Compact | `slums` |
| `camp` | the cove camp (14 nodes) | `docks` |
| `throne_hall` | Candlehold's Lantern Hall (10 nodes) | `cathedral` |
| `cliff_city` | Candlehold's gates | `docks` / `cathedral` |
| `glass_strand` | the Hollow Shore, White Fleet's grave | `epilogue` / `docks` |
| `highland` | Highhearth | `cathedral` |

**The user chooses:** which moods to add (I can do the strings and tag the
scenes in one PR), and whether to ask UX for the themes.

## 4. Achievements (proposals)

Today there are 7 (`first_companion`, `full_roster`, `full_party`,
`keldas_hall_built`, `ally_revival`, `first_quest`, `first_shop`), checked in
`checkAchievements` (`lib/providers/player_session_provider.dart`) from
persisted state. A new achievement is a row in `achievements.json` (mine)
plus a check (Core). I have **not** added rows without checks, since they
would show as locked forever.

"Data today" means the state already exists and Core only adds a `check(...)`
line. "Counter" means Core must also track something new.

| Id | Name (EN / FR) | Earned when | Needs |
|---|---|---|---|
| `first_combo` | In Step / Au pas | land a party combo | Counter (combos landed, by kind) |
| `every_combo` | Five Ways to Fight / Cinq façons de se battre | land each combo: Flank, Volley, Shelter, Shield Wall, Wellspring | Counter (set of kinds) |
| `sworn_to_a_clan` | Sworn / Lié par serment | reach Sworn (standing 61+) with any clan | Data today (politics standing) |
| `friend_of_each_clan` | A Hand for Every Door / Une main pour chaque porte | Trusted or better with all six clans | Data today |
| `hunted_by_a_clan` | Hunted / Traqué | fall to Hunted (−61 or lower) with a clan | Data today |
| `both_sides` | Both Sides of the Wall / Des deux côtés du mur | Trusted with two clans that are at odds | Data today (relations) |
| `akagiri_found` | Where the Bells Hang / Là où pendent les cloches | reach Akagiri, the oni village | Data today (visited nodes) |
| `kindly_hill_found` | Every Bargain to the Minute / Chaque marché à la minute | reach the Kindly Hill | Data today |
| `all_villages` | Off the Road / Hors des routes | visit every village of the geography (8) | Data today |
| `half_a_banner` | Half a Banner / Une demi-bannière | hold 3 pieces of the Shroud | Data today |
| `whole_cloth` | Whole Cloth / Étoffe entière | hold all 6 | Data today |
| `first_thread` | A Loose Thread / Un fil qui dépasse | settle any intrigue | Data today (`intrigue_*_outcome_*`) |
| `whole_web` | The Whole Web / Toute la toile | settle all 8 | Data today (needs the dormant intrigues, in progress) |
| `on_the_throne` | The Lantern Throne / Le Trône de la Lanterne | take the Throne (flag `on_throne`) | Data today |
| `crowned_by_each` | A Crown for Every Hand / Une couronne pour chaque main | be crowned by each of the seven roads, across runs | Meta: needs a profile that outlives a save (Core) |
| `journeys_end` | Journey's End / Fin du voyage | reach any ending | Data today |
| `time_turned` | Time Turned / Le temps rebroussé | start New Game+ | Data today |
| `all_endings` | Every Dawn / Toutes les aubes | see the four epilogues, across runs | Meta (Core) |
| `devoted` | Devoted / Dévoué | a companion reaches their devoted line | Data today (approval) |
| `parted_ways` | Parted Ways / Séparés | a companion leaves | Data today |
| `saint` / `scoundrel` | Saint / Scélérat | reach the alignment extremes | Data today |
| `eel_afloat` | Afloat / À flot | put the Rusty Eel to sea | Data today (voyage state) |
| `ships_sunk` | Broadside / Bordée | sink 10 ships | Counter |
| `last_word` | The Last Word / Le dernier mot | win a skill challenge on the last allowed attempt | Counter |
| `deathless_chapter` | Unbroken / Sans faille | finish a chapter without losing a fight | Counter |

**The user chooses:** which to keep. I would start with the "data today"
rows (about 15), which need one `check(...)` line each from Core, and leave
the counters and the cross-run ones for later. Names are first drafts and
the French is for Narrative to finish once the list is fixed.

## 5. The other story directions (asked again once the work above is merged)

From the audit, section 4: **B** (chapters 7 and 8 as a game, see section 1
here), **D** (companion loyalty scenes, needs a trigger from Core) and **E**
(New Game+ as story, needs state from Core and a prologue card from UX).
**A** (the dormant intrigues) and **C** (NPC voices) are done.
