# Audio Asset List: Sound Design Brief

This is the full list of music, ambience, SFX and voice assets the game needs.
It is built from the code and game data as of **v1.154.0**. Every row points to
the system that will trigger the sound, so the list can double as an
implementation checklist.

**What exists today.** The game has **no music, no SFX and no haptics**. The
only audio is voice narration: on-device TTS through `flutter_tts`, and Gemini
TTS played through `audioplayers`. There is no volume setting. Everything below
is new work.

---

## 0. Creative context

| | |
|---|---|
| **Genre** | Narrative RPG, choice-driven. Dice-based party combat, naval battles, expeditions and camp building. |
| **Platform** | Flutter on Android, iOS, web and desktop. Mobile-first, so assume phone speakers and earbuds. |
| **Tone** | Grim low fantasy that turns cosmic horror. A burned harbour city (Alster), an Inquisition, a void cult ("Hollow Court"), and a **Tear** in reality that leads to a glass world "beyond". Moments of hope, found family and a loyal dog. |
| **Recurring sonic motifs (from the writing)** | Ash falling like snow. A cracked bell that tolls once. Gulls that go silent before danger. Slow water drips "like a heartbeat". Guttering candles. Inquisition hymns. The Tear "hums a note just below hearing, and reflections hum it back". Boots ringing on glass. |
| **Alignment** | Good / Neutral / Evil (score ±20). This drives an angel/demon look for the dog and angel/demon hunters. Audio can follow it too. |
| **Languages** | EN and FR. Every piece of VO needs both. |
| **Pacing** | Turn-based, tap-driven. There are many short UI and combat events, so keep SFX short (under 700 ms) and the variation high. |

**Suggested leitmotifs** (the designer can override):
1. **Main / Alster theme.** The ruined city, "what was lost".
2. **The Eel theme.** The player's ship, the Rusty Eel: found family, the sea.
3. **The Tear motif.** A sub-audible hum plus a reflected, reversed voice. It grows louder chapter by chapter.
4. **Inquisition motif.** Liturgical, choral, stern.
5. **Hollow Court motif.** A corrupted version of the Inquisition hymn.
6. **Companion motifs.** Optional: 8 short cells, used for recruit stingers.

---

## 1. Delivery specs (proposed)

- **Format.** Masters as WAV 48 kHz / 24-bit. The game ships OGG Vorbis (q5–6) for music and ambience, and OGG or short WAV for SFX. iOS needs m4a/AAC fallbacks if OGG proves a problem.
- **Loudness (mobile).**
  - Music: −16 LUFS integrated.
  - Ambience beds: −24 to −20 LUFS.
  - SFX: peaks at −1 dBTP, loudness balanced by ear against the music.
  - All must stay intelligible on a phone speaker, so check the low end doesn't carry the cue.
- **Loops.** Seamless and sample-accurate. Music loops 1:30–3:00. Ambience loops 45–90 s, plus separate one-shot "sweeteners" played at random.
- **Variations.** Plan 3–5 per frequent SFX (hits, dice, footsteps, UI taps). The table below gives a count for each.
- **Naming.** `<bus>_<domain>_<event>[_<variant>]_<nn>.ogg`, for example `sfx_dice_land_wood_03.ogg`, `mus_combat_boss_layerB.ogg`, `amb_zone_drowned_stair_loop.ogg`, `vo_en_kelda_crit_01.ogg`.
- **Mix buses.** `Master`, `Music`, `Ambience`, `SFX`, `UI`, `VO/Narration`. Narration TTS must **duck** Music and Ambience by about 8–10 dB.
- **Settings to add** (for the developer): master, music, SFX, ambience and voice volume, plus haptics on/off. Today the Settings screen has none of these.

Priority key: **P1** = needed for a first playable audio pass. **P2** = full coverage. **P3** = polish.

---

## 2. Music

### 2.1 Front end and meta

| ID | Cue | Type | Trigger | Pri |
|---|---|---|---|---|
| `mus_menu_main` | Main menu / title theme | loop | `main_menu_screen` | P1 |
| `mus_char_creation` | Race and profession choice, origin story prompts (11) | loop | `race_profession_screen` | P2 |
| `mus_newgameplus` | New Game+ start sting | stinger 3–5 s | `beginNewGamePlus` | P3 |
| `mus_death_permadeath` | Permadeath screen | loop or long stinger | `DeathScreen` | P2 |
| `mus_credits_ending` | End credits / recap | loop | `_EndingView` | P2 |

### 2.2 Story (narrative) beds

Story nodes carry a `mood` and a `ui_theme`. Score the beds by **mood**, then colour them by chapter. The ambience (§3) handles place.

| ID | Mood (node count) | Pri |
|---|---|---|
| `mus_story_neutral` | neutral (71): an understated, sparse bed | P1 |
| `mus_story_grim` | grim (27) | P1 |
| `mus_story_tense` | tense (24) | P1 |
| `mus_story_action` | action (17), non-combat urgency | P2 |
| `mus_story_creepy` | creepy (9) | P2 |
| `mus_story_suspense` | suspense (5) | P2 |
| `mus_story_desperate` | desperate (2) | P3 |
| `mus_story_triumphant` | triumphant (2) | P2 |
| `mus_story_hopeful` | hopeful (2) | P2 |
| `mus_story_reflective` | reflective (1) | P3 |

46 nodes have no mood, so fall back to `neutral`.

**Chapter variants.** The same mood beds can be re-orchestrated per chapter, or one "chapter signature" layer can sit on top:

| Chapter | Title | Setting and colour |
|---|---|---|
| Ch 1 | (prologue road) | Slums, bridge, hovel, sewers, torture chamber, market, docks: street-level, intimate |
| Ch 2 | The Ashes of Alster | Docks, smugglers: maritime, salt, rope |
| Ch 3 | The Spire of Judgment | Cathedral: Inquisition choir, organ, bells |
| Ch 4 | The Hollow Court | Catacombs, drowned cloister: water, stone, corrupted hymn |
| Ch 5 | The Shroud's Truth | The Tear opens in the open air: frost, candles, dread |
| Ch 6 | The Hollow Shore | Glass world, the White Fleet's grave: alien, vast, glassy |
| Ending | Beyond the Tear | Final act: every motif resolved |

### 2.3 Hubs and exploration

| ID | Cue | Trigger | Pri |
|---|---|---|---|
| `mus_camp` | Cove Camp (the home base) | Camp tab, camp nodes (3001_camp, 4999_camp, 6002_camp, 7001, 7400) | P1 |
| `mus_camp_evolved` | The camp grows richer as houses are built (optional stems: +forge, +hall, +shrine) | house count | P3 |
| `mus_town` | Town hub (Smugglers' Wharf, Ashen Quarter, Drowned Cloister, Reliquary Quarter, White Anchorage) | settlement arrival | P2 |
| `mus_village` | Villages (Emberwick, Wrack's End, Rimewell, Greyhithe) | settlement arrival | P3 |
| `mus_shop` | Shop browsing (quiet) | `shop_detail_screen` | P3 |
| `mus_world_map` | World map / chart | `world_map_screen` | P2 |
| `mus_voyage` | At sea, sailing between ports | `voyage_screen` | P1 |
| `mus_voyage_storm` | Storm day at sea | `SeaEventKind.storm` | P2 |
| `mus_expedition_<theme>` | Expedition exploration, one per map theme (ashenStreets, saltRoads, hollowReaches, wildsBeyond) = 4 | `expedition_screen` | P2 |
| `mus_journal` | Journal, achievements, menus (optional; can reuse camp) | | P3 |

### 2.4 Combat music

Build these as layered stems if possible. The fight runs in phases (roll → resolve → enemy turn), and 30 of the 47 enemies have **boss phases**.

| ID | Cue | Trigger | Pri |
|---|---|---|---|
| `mus_combat_standard` | Normal fight | `FightScreen` | P1 |
| `mus_combat_pack` | Pack fight (2–3 enemies), a variation or intensity layer | pack | P3 |
| `mus_combat_elite` | Elite enemy (12% chance): add a layer or an intro sting | `isElite` | P3 |
| `mus_combat_boss` | Boss fight, **with phase layers A/B/C** that switch on phase change | zone bosses, solo-only uniques | P1 |
| `mus_combat_hunter_angel` | Angel hunters ambush an Evil player (angel_sentinel, angel_judicator) | alignment ambush | P2 |
| `mus_combat_hunter_demon` | Demon hunters ambush a Good player (demon_imp, demon_tormentor) | alignment ambush | P2 |
| `mus_combat_turned_companion` | Duel against a companion who has turned (8 variants possible, or 1 theme) | `<ally>_turned` | P2 |
| `mus_combat_final` | Final boss, the Void Sovereign (plus white_admiral if you want a distinct finale) | `void_sovereign` | P1 |
| `mus_ship_battle` | Naval battle, turn-based with a 20 s clock | `ship_battle_panel` | P1 |
| `mus_ship_battle_urgent` | Layer for low hull or low clock | hull < 25% or clock ≤ 5 s | P3 |
| `mus_boarding_fight` | Boarding deck fight (a dice fight on deck) | boarding | P2 |
| `mus_skill_challenge` | d20 skill challenge (a light, tense pulse) | `SkillChallengeScreen` | P3 |

### 2.5 Music stingers (2–8 s, play over or replace the bed)

| ID | Event | Pri |
|---|---|---|
| `stg_combat_start` / `stg_boss_intro` | Fight begins / boss reveal | P1 |
| `stg_ambush` | Ambush battlefield condition: enemies act first | P3 |
| `stg_boss_phase` | Boss changes phase (heal, cleanse, enrage variants optional) | P1 |
| `stg_victory` / `stg_victory_boss` / `stg_victory_flawless` | Win, boss win, flawless | P1 / P2 / P3 |
| `stg_defeat` | Fight lost, without permadeath | P1 |
| `stg_retreat` | Fled the fight (costs gold) | P2 |
| `stg_ship_victory` / `stg_ship_sunk` / `stg_ship_boarded_lost` / `stg_ship_enemy_escaped` | `BattleEnd { won, lost, boarded, escaped }` | P1 / P1 / P2 / P2 |
| `stg_level_up` | Level up | P1 |
| `stg_quest_accepted` / `stg_quest_complete` | Quest lifecycle | P1 |
| `stg_quest_ready` | Quest goals met, ready to turn in | P2 |
| `stg_main_quest_open` | Chapter's main quest unlocks | P2 |
| `stg_chapter_start` × 6 | New chapter title card | P2 |
| `stg_achievement` | Achievement unlocked (7 in the game) | P2 |
| `stg_recruit` (or × 8, one per companion) | Companion joins | P2 |
| `stg_ally_lost` | Companion leaves for good or turns (node 7002_price, `@first_ally`) | P2 |
| `stg_discovery` | New shop, quest or place discovered | P2 |
| `stg_banner_piece` | Found a Shroud banner piece (6 pieces: heirloom_shroud, warden_standard, reliquary_thread, white_fleet_sail, sovereign_mantle, moon_shard_shroud) | P2 |
| `stg_town_arrival` / `stg_village_arrival` | Settlement arrival card | P2 |
| `stg_landfall` | Voyage arrives in port | P2 |
| `stg_zone_cleared` | Expedition zone completed | P2 |
| `stg_alignment_good` / `stg_alignment_evil` / `stg_alignment_neutral` | Crossing the ±20 alignment threshold (needs a new code hook) | P3 |
| `stg_temptation` | A temptation scene opens (Neutral only) | P3 |
| `stg_ending_<id>` × 4 | Endings: 7005, 7005_seeker, 7005_dawn, 7005_crown | P1 |
| `stg_epilogue_good` / `_neutral` / `_evil` | Alignment epilogues | P2 |
| `stg_skill_mastery` / `stg_skill_merge` | Branch mastered / legendary skill crafted | P3 |
| `stg_house_built` | Camp building finished (bigger for hearth_hall, banner_loft, shroud_shrine) | P2 |

---

## 3. Ambience

### 3.1 Story scene beds, by `ui_theme` (13)

| ID | Theme (node count) | Content ideas (from the writing) | Pri |
|---|---|---|---|
| `amb_docks` | docks (62) | Lapping water, creaking rope and planks, gulls, a buoy bell, a mooring chain | P1 |
| `amb_cathedral` | cathedral (32) | Vast reverb, distant choir or hymn, candle flutter, footsteps on stone | P1 |
| `amb_slums` | slums (19) | Ash wind, broken shutters, distant dogs and coughing, a cracked bell | P1 |
| `amb_origin_ending` | origin_ending (9) | Intimate, memory-like | P2 |
| `amb_epilogue` | epilogue (6) | Calm aftermath, wind, the sea | P2 |
| `amb_catacombs` | catacombs (5) | Drips like a heartbeat, bones shifting, low moans | P1 |
| `amb_torture_chamber` | torture_chamber (5) | Chains, a brazier, muffled cries (tasteful) | P2 |
| `amb_market` | market (4) | Crowd walla, haggling, carts | P2 |
| `amb_sewers` | sewers (4) | Running water, rats, echo | P2 |
| `amb_bridge` | bridge (3) | Wind, river below, creaking | P3 |
| `amb_hovel` | hovel (3) | Room tone, fire crackle, rain on thatch | P3 |
| `amb_prologue` | prologue (1) | | P3 |
| `amb_gate` | gate (1) | The slums gate: guards, wind | P3 |

### 3.2 Expedition map themes (4 beds and one-shot pools)

| ID | Theme | Bed | Random one-shots | Pri |
|---|---|---|---|---|
| `amb_theme_ashen_streets` | ashenStreets | Burned city wind, ash hiss | Bell toll, rubble shift, cat, cultist chant, echoing steps | P1 |
| `amb_theme_salt_roads` | saltRoads | Waves, tide | Gulls (**cut them out before an enemy appears**), buoy bell, chain, pier groan | P1 |
| `amb_theme_hollow_reaches` | hollowReaches | Black water, drips | Candle gutter, skitter, hymn, tremor, chapel bell, wisps | P1 |
| `amb_theme_wilds_beyond` | wildsBeyond | The Tear hum and its reflected hum | Glass chimes, "wrong light" hound, the sky folding, plus a little birdsong or stream for the rare forest beats | P1 |

### 3.3 Zones (12). Each is a theme bed plus a zone sweetener, a boss-approach layer and a midpoint beat

| Zone | Ch | Theme | Sweetener | Boss |
|---|---|---|---|---|
| z_fishermans_row | 2 | saltRoads | Net sheds, gutting tables | dock_overseer |
| z_tanners_court | 2 | saltRoads | Lime pits, drains | plague_hound |
| z_lantern_docks | 2 | saltRoads | Lanterns, boathouse (a lantern going out) | smuggler_captain |
| z_cinder_row | 3 | ashenStreets | Embers, a golem waking from ash | iron_golem |
| z_scaffold_yards | 3 | ashenStreets | Cold forges, scaffolds creaking, hymn | void_stalker |
| z_ossuary_galleries | 4 | hollowReaches | Flooded bone galleries, sea cave | bone_warden |
| z_drowned_stair | 4 | hollowReaches | Spiral stair in black water, candles | hollow_court_inquisitor |
| z_dead_heart_approach | 5 | ashenStreets | Frost in summer, glass ground (boots ring) | tear_spawn |
| z_shroud_vigil | 5 | hollowReaches | Hundreds of candles, the Tear in the open air | void_archon |
| z_beyond_the_tear | 6 | wildsBeyond | No sky, the Eel on "not-water", a throne | void_sovereign |
| z_glass_strand | 6 | wildsBeyond | Humming glass sand, wreckage, dunes | strand_colossus |
| z_white_fleet_grave | 6 | wildsBeyond | 40 hulls on glass, flags snapping, silence | white_admiral |

Naming: `amb_zone_<id>_loop` plus `amb_zone_<id>_boss_approach`.

### 3.4 Camp, ports, settlements and sea

| ID | Content | Pri |
|---|---|---|
| `amb_camp_cove` | A night cove with the ship moored and a lantern. Waves, fire, crew murmur | P1 |
| `amb_camp_house_<id>` × 10 | Optional layers, one per camp building: keldas_hall (forge-hall), barracks_annex (mess), harbor (quay, shipwright), hammersmith (anvil, bellows), academy (page turns), sharpweave_den (quiet), smugglers_cellar, hearth_hall (the great fire), banner_loft (cloth, sewing), shroud_shrine (void glow hum) | P3 |
| `amb_port_<id>` × 5 | ashen_landing (shingle, the hauled-up Eel), smugglers_wharf (market, tanneries, lantern docks), drowned_stair (flooded landing), black_reliquary (river gate, rusted chains), hollow_shore (grey sand, the Tear like a door) | P2 |
| `amb_town_<id>` × 5, `amb_village_<id>` × 4 | Settlement beds (Emberwick: kilns and slag; Rimewell: frost and a counting bell; Wrack's End: hull-houses; Greyhithe: fishers) | P3 |
| `amb_sea_calm` / `amb_sea_open` / `amb_sea_storm` | Voyage beds: the hull under way, rigging, wind | P1 |
| `amb_sea_weather_<calm\|tailwind\|crosswind\|squall\|fog>` | Ship-battle weather beds (5). The weather re-rolls every round, so crossfade | P2 |
| `amb_world_map` | Parchment room tone and a soft sea swell (the map animates swell lines) | P3 |
| `amb_tear_drone` | A drone that rises when the map or a scene focuses on a void place (reliquary, heart, shore) | P3 |

There is **no day/night system**. The camp view is always night.

---

## 4. UI and system SFX

| ID | Event | Var | Pri |
|---|---|---|---|
| `ui_tap` / `ui_tap_soft` | Generic button, list item | 3 | P1 |
| `ui_back` / `ui_close` | Back, dismiss | 2 | P1 |
| `ui_tab_switch` | Bottom nav (Story / Character / Camp or Ship / Other) | 2 | P1 |
| `ui_toggle_on` / `ui_toggle_off` | Settings switches | 1 each | P2 |
| `ui_slider_tick` | Volume and other sliders | 1 | P3 |
| `ui_confirm` / `ui_cancel` | Confirm dialogs (new game, load, NG+, retreat) | 1 each | P1 |
| `ui_error` / `ui_denied` | Locked choice, can't afford, party full, shop locked by alignment | 2 | P1 |
| `ui_notice_in` | "Immersive notice" card (29 call sites) | 2 | P1 |
| `ui_notice_<kind>` | Optional flavoured versions: gold, quest, trophy, hammer, map | | P3 |
| `ui_badge_ping` | Nav badge appears (points to spend, house affordable, quest ready) | 1 | P2 |
| `ui_modal_open` / `ui_modal_close` | Bottom sheets (pickers, trade sheets, compare) | 1 each | P2 |
| `ui_page_turn` | Journal, bestiary, tutorials list | 3 | P2 |
| `ui_drag_pick` / `ui_drag_drop` / `ui_drag_invalid` | Dice loadout: drag a skill onto a face | 1 each | P2 |
| `ui_sort_filter` | Shop sort and filter | 1 | P3 |
| `ui_save` / `ui_load` / `ui_save_fail` | 3 manual slots | 1 each | P2 |
| `ui_language_switch` | EN/FR switch | 1 | P3 |
| `ui_text_type_tick` | Typewriter tick for the tutorial dog's speech bubble (16 ms per char; play every n chars) | 3 | P2 |
| `ui_highlight_spotlight` | Tutorial dims the screen and spotlights a target | 1 | P2 |
| `ui_zoom_in` / `ui_zoom_out` | World map zoom (280 ms) | 1 each | P3 |
| `ui_map_pin_select` | Tap a landmark (28 landmarks) | 2 | P3 |
| `ui_read_aloud_on` / `off` | Narration speaker button | 1 each | P3 |

**Haptics** (new, optional): light tick on dice lock, medium on a hit taken, heavy on a crit taken, cannon hit and boss phase, success pattern on level up.

---

## 5. Story and narrative SFX

| ID | Event | Source | Pri |
|---|---|---|---|
| `sfx_story_advance` | Page, node transition (soft whoosh or paper) | every node | P1 |
| `sfx_story_choice_select` | Pick a choice | `_selectChoice` | P1 |
| `sfx_story_choice_locked` | A locked choice (18) is tapped | `lockedText` | P2 |
| `sfx_gold_gain_small/large`, `sfx_gold_loss` | `goldMod` (50 choices), treasure, rewards | | P1 |
| `sfx_heal_rest` / `sfx_wound` | `healAmount` + / − (39 choices) | | P2 |
| `sfx_alignment_good` / `sfx_alignment_evil` | `alignmentMod` (62 choices, ±1 to ±5): a subtle bright or dark shimmer that scales with the amount | | P2 |
| `sfx_ability_check_roll` / `_success` / `_fail` | d20 check on 20 choices (wisdom, con, luck, str, dex, int, cha) | `checkAbility` | P1 |
| `sfx_discovery` | Discovery modal (unlock shop or quest) | | P2 |
| `sfx_flag_callback` | Optional: "the world remembers" tick | `flag_callbacks` | P3 |
| `sfx_ally_aside` | An ally interjects in a scene (26 node keys) | ally_acknowledgments | P3 |
| `sfx_previously_recap` | "Previously…" recap on resume | | P3 |
| `sfx_trail_cold` | Dead-end / error view | | P3 |
| `sfx_story_hook_<node>` × up to 30 | One-off scripted sounds. 30 nodes already carry `script_trigger: on_load_node_<id>`, a ready-made hook | | P3 |

**Temptation scenes** (6, one-shot Foley): the beggar's cup, a dropped satchel, a drunk's purse, a ledger, a grey soldier's armour, the coin-juggler's coins.

---

## 6. Dice (the core combat verb, so give it the most care)

28 dice exist. Most have 6 faces; `void_die` has 4 and `vigil_die` has 7. Consider **material families** so each die sounds like what it is:

| Material family | Dice |
|---|---|
| Wood / bone (starter) | starter_die, pilgrim_die, huntsman_die, ossuary_die |
| Iron / metal | iron_die, bulwark_die, grosh_die, berserker_die |
| Stone | stone_die, tempest_die, storm_die |
| Arcane / crystal | arcane_die, apprentice_die, sage_die, vess_die, frost_die, flame_die |
| Holy / glass-bright | holy_die, tide_die, tobin_die, vigil_die |
| Shadow / soft | shadow_die, twinfang_die, malrik_die, liora_die, gambler_die |
| Void / tear-glass | void_die, tearglass_die |

| ID | Event | Var | Pri |
|---|---|---|---|
| `sfx_dice_shake` | Roll pressed (650 ms spin) | 3 | P1 |
| `sfx_dice_tumble_<material>` | Tumble or spin | 3 × 7 | P1 (1 material) / P2 (all) |
| `sfx_dice_land_<material>` | Face lands; stagger for multiple dice (one per party member) | 4 × 7 | P1 / P2 |
| `sfx_dice_lock` / `sfx_dice_unlock` | Keep a die between rerolls | 2 each | P1 |
| `sfx_dice_reroll` | Reroll button (3 rolls per round, 4 with the charm) | 2 | P1 |
| `sfx_dice_final_autoconfirm` | Last roll is forced (700 ms) | 1 | P2 |
| `sfx_dice_confirm` | Confirm the roll | 1 | P1 |
| `sfx_face_resolve_<type>` | Face reveal accents: Attack, Defend, Skill, Heal, Mana, Empty/Miss | 6 | P2 |
| `sfx_face_fizzle` | Skill fizzles (skill unavailable) | 1 | P2 |
| `sfx_face_channeled` | Skill on a basic face (0.7x power, a "muffled" version) | 1 | P3 |
| `sfx_dice_buy` / `sfx_dice_equip` | Buying or equipping a die | 1 each | P2 |
| `sfx_d20_roll` / `_nat20` / `_nat1` | Skill challenge and ability check (nat 20 and nat 1 exist in code) | 3 / 1 / 1 | P2 |

---

## 7. On-foot combat

### 7.1 Flow and targeting

| ID | Event | Pri |
|---|---|---|
| `sfx_fight_enter` | "Enter battle" button, weapon draw | P1 |
| `sfx_condition_reveal_<ambush\|dark\|cramped\|highGround\|shrine>` | Battlefield condition banner (25% of fights) | P3 |
| `sfx_elite_reveal` / `sfx_affix_chip` | Elite prefix, affix chips on the enemy card | P3 |
| `sfx_charm_arm` / `sfx_charm_consume` | Arm a charm before the fight, burn it at the start | P2 |
| `sfx_target_select` | Tap an enemy card | P1 |
| `sfx_telegraph_<attack\|healSelf\|statusDebuff>` | Enemy intent revealed | P2 |
| `sfx_turn_party` / `sfx_turn_enemy` | Round handoff (subtle) | P2 |
| `sfx_momentum_ready` | 3 hits in a row, so the next strike is a sure crit | P2 |
| `sfx_surge_pick` / `sfx_surge_release` | Choose the crit striker, surge consumed | P2 |
| `sfx_momentum_lost` | Party took damage and momentum resets | P3 |
| `sfx_brace` | Defend face on a telegraphed target (x2 block) | P2 |
| `sfx_hp_lethal_warning` | Lethal-preview chip / low HP heartbeat (optional loop) | P3 |
| `sfx_screen_shake_hit` | Player hurt (paired with the 400 ms shake) | P1 |

### 7.2 Skill and spell VFX, 1:1 with `VfxStyle` (29 data styles + 5 system)

Each style needs a **cast/whoosh** and an **impact**. Projectiles also need a **travel** sound. Durations are 550–1000 ms, so match them.

| Style | Usage in skills | Suggested content | Notes |
|---|---|---|---|
| `slash` | 2 + default Attack face | Blade swish + flesh/cloth hit | 5 var, P1 |
| `heavy_slash` | 6 | Big swing + crunch | P1 |
| `pierce` | 5 | Thrust + puncture | P1 |
| `whirl` | 2 | Spinning multi-swish | P2 |
| `claw` | 2 + **every enemy plain attack** | Rake + beast snarl | 5 var, P1 |
| `impact` | 3 + Thorns | Blunt thud | P1 |
| `arrow` | 3 + 3 ranger spells | Bow loose, flight, thunk | projectile, P1 |
| `volley` | 1 | Many arrows, rain of thunks | P2 |
| `bolt` | 1 + Arcane Bolt | Crackling arcane projectile | projectile, P1 |
| `lightning` | 2 | Strike + thunder crack | P2 |
| `flame` | 6 | Whoosh + burn | P1 |
| `fireball` | 2 + Scroll of Fireball | Launch, roar, explosion | projectile, P1 |
| `meteor` | 2 | Descending roar + massive impact (1000 ms) | P2 |
| `holy_fire` | 2 | Choir-tinged flame | P2 |
| `frost` | 2 | Ice crackle + shatter | P2 |
| `splash` | 1 + Antidote + Purge | Water burst | P2 |
| `poison` | 3 + poison ticks | Hiss, bubbling | P1 |
| `smoke` | 1 | Puff, cough | P3 |
| `wind` | 1 | Gust | P2 |
| `quake` | 3 | Rumble + rock crack | P2 |
| `void_rift` | 4 | Tear hum, reversed swell, glass | P1 (signature) |
| `drain` | 3 + Lifesteal | Suck-in, heartbeat pull | projectile, P2 |
| `shadow` | 6 | Dark whoosh, whisper | P1 |
| `radiance` | 4 | Bright bloom, bell shimmer | P2 |
| `heal` | 8 + potions | Warm chime rise | P1 |
| `shield` | 5 + Defend face + block | Shield raise, metal ring | P1 |
| `stone_shield` | 5 | Stone grind-up | P2 |
| `mana` | 2 + Mana face | Crystalline fill | P1 |
| `shout` | 4 + 3 warrior spells | War cry (VO-like, gendered or race variants?) | P2 |
| **System:** `stun` | status | Ringing-bell daze | P1 |
| **System:** `weaken` | status | Deflating drone | P1 |
| **System:** `crit` | crits | Big accent layered over the hit | P1 |
| **System:** `miss` | miss, dodge | Whiff | P1 |
| **System:** `phase` | boss phase | Huge transformation swell (1000 ms) | P1 |

**Element sweeteners** (layer on top when the skill has an element): Fire, Wind, Earth, Water, Electricity, Void, Ice, Light. That is 8 short tails.

**Alignment tint** (optional): Good-aligned skills get a bright shimmer tail, Evil-aligned ones a dark tail.

### 7.3 Hits, defence and outcomes

| ID | Event | Var | Pri |
|---|---|---|---|
| `sfx_hit_enemy` / `sfx_hit_player` | Damage number, by weight (light, medium, heavy) | 3 × 3 | P1 |
| `sfx_crit` | Crit accent + `big` burst | 3 | P1 |
| `sfx_dodge` | Dodge (5–30%) | 3 | P1 |
| `sfx_block_full` | Fully blocked, "0" | 3 | P1 |
| `sfx_armored_absorb` | Armored affix: −4 on Attack faces | 2 | P2 |
| `sfx_redirect` | Target already dead, blow moves on | 1 | P3 |
| `sfx_enemy_death_<family>` | **No VFX exists, so audio carries this.** One per family (§7.6) | 3 per family | P1 |
| `sfx_enemy_flee` | Skittish enemy flees below 25% | 2 | P2 |
| `sfx_ally_ko` | Companion knocked out | 2 | P1 |
| `sfx_player_death` | Player falls | 1 | P1 |
| `sfx_ally_revive` | Allies back at 30% after a win | 1 | P2 |
| `sfx_second_wind` | Survive at 1 HP (gear) | 1 | P2 |
| `sfx_warding_block` | Warding charm eats the first hit | 1 | P2 |
| `sfx_thorns` | Thorns reflect | 2 | P2 |
| `sfx_lifesteal` | Drain + heal | 1 | P2 |
| `sfx_mana_on_hit` | Small mana tick | 1 | P3 |
| `sfx_enemy_holds_back` | Cramped condition: enemy waits | 1 | P3 |

### 7.4 Status effects (3) and battlefield conditions

| ID | Event | Pri |
|---|---|---|
| `sfx_status_poison_apply` / `_tick` | Applied (by the venomous affix, skills or spells) / damage each turn | P1 |
| `sfx_status_stun_apply` / `_skip` | Applied / "skips turn" | P1 |
| `sfx_status_weaken_apply` | Applied | P1 |
| `sfx_status_refresh` | Status reapplied (refreshes, doesn't stack) | P3 |
| `sfx_status_cleanse` | Antidote, Purge spell, or a boss cleanse | P1 |
| `amb_combat_condition_dark` / `_shrine` | Optional ambience tint for the Dark / Shrine conditions | P3 |

### 7.5 Consumables and off-turn actions

| ID | Event | Pri |
|---|---|---|
| `sfx_potion_drink` (minor / major) | Potion | P1 |
| `sfx_antidote_drink` | Antidote | P1 |
| `sfx_scroll_unfurl` | Scroll of Fireball (then `fireball`) | P2 |
| `sfx_spell_cast_generic` | Mana spent (pre-cast) | P1 |
| `sfx_retreat` | Flee the fight: footsteps, dropped coins | P2 |

### 7.6 Enemy vocal sets (47 enemies)

There is no family field in the data, so this grouping was made for audio. Each family needs **aggro, attack grunt, hurt, death** (3 variants each). Bosses additionally need **intro, phase-change roar and death**.

| Family | Enemies | Voice direction |
|---|---|---|
| Street criminals | slum_thug, street_bandit, smuggler_captain*, dock_overseer* | Human male/female efforts, rough |
| Inquisition / White | inquisition_warden, _soldier, _auxiliary, _high_warden, kroll_the_branded, inquisition_penitent, masked_penitent, inquisition_legate, white_soldier, white_admiral* | Armoured, disciplined; the penitents are self-flagellating, muffled under masks |
| Void cult / Hollow Court | cultist_acolyte, hollow_court_zealot, hollow_court_inquisitor*, unmade_knight | Chanting, fanatic; the knight is hollow and echoing |
| Beasts / vermin | harbor_rat, rat_matriarch, plague_hound* | Squeaks and swarm; wet, sick hound |
| Void / Tear creatures | void_wisp, void_stalker*, void_manifestation, void_hound, tear_spawn*, void_archon*, void_sovereign*, hollow_reflection | Non-human: glassy, reversed, "the hum reflected" |
| Undead | catacomb_ghoul, bone_warden*, bone_sexton, drowned_pilgrim | Bone rattle, drowned gurgle |
| Constructs | iron_golem*, strand_colossus* | Metal and stone grind; a molten backlash on Fire hits |
| Celestial "Choir" | angel_sentinel, angel_judicator | Choral, piercing, beautiful and terrible |
| Demonic "Pit" | demon_imp, demon_tormentor | Chittering imp; guttural tormentor |
| Turned companions | kelda_, sable_, maren_, liora_, vess_, grosh_, tobin_, malrik_turned | Reuse the companion VO actor with combat efforts (§12) |

\* = zone boss or unique. The 7 zone bosses are dock_overseer, plague_hound, smuggler_captain, iron_golem, bone_warden, tear_spawn and strand_colossus.

**Enemy-only signature skills (12)**, each a bespoke SFX: plague_bite, void_drain, disorienting_pulse, molten_backlash, matriarch_brood_call, golem_meltdown, warden_bone_storm, archon_eclipse, sovereign_unmaking, zealot_martyrdom, manifestation_many_faces, stalker_ambush.

### 7.7 Spells (17 + scroll)

These mostly reuse the VFX styles above. List them so the designer can give flagship spells a unique pass.

| Class | Spells |
|---|---|
| Mage | Arcane Bolt (bolt, Electricity), Frost Bind (frost + stun), Ember Wave (flame, all enemies), Mana Ward (shield, party) |
| Cleric | Mending Light (radiance), Sanctified Ground (heal, party), Smite the Wicked (holy_fire), Purge (splash, cleanse) |
| Rogue | Venom Hex (poison), Bleeding Cut (poison), Smoke Veil (shield, Wind) |
| Ranger | Hunter's Mark (arrow + weaken), Arrow Volley (arrow, all enemies), Snare Shot (arrow + stun) |
| Warrior | War Shout (shout, party block), Rally the Line (shout, party heal), Sundering Roar (shout + weaken, all enemies) |
| Item | Scroll of Fireball |

**Legendary merged skills (6)** deserve unique sounds: blazing_shadow, unbreakable_will, bastion_of_stone, arcane_convergence, venomous_ambush, wrath_of_dawn.

---

## 8. Loot and spoils chest

The chest has 5 tiers: `wooden`, `iron`, `silver`, `gold`, `void`. Gold and above counts as a "big chest", which calls for a fanfare.

| ID | Event | Var | Pri |
|---|---|---|---|
| `sfx_chest_appear_<tier>` | Chest dialog opens | 5 | P2 |
| `sfx_chest_shake_<tier>` | Tap: 550 ms shake | 5 | P1 (shared) / P2 |
| `sfx_chest_open_<tier>` | Lid opens (wood creak, iron clank, silver ring, gold fanfare, void tear-rip) | 5 | P1 |
| `sfx_fortune_roll` | Fortune-roll counter tallying up (modifiers: luck, elite, pack, flawless, swift, crit finish, affixes, condition, pity) | 1 + tick | P3 |
| `sfx_loot_flip` | Flip a face-down slot (250 ms) | 3 | P1 |
| `sfx_loot_reveal_<common\|uncommon\|rare>` | Item revealed by rarity | 3 | P1 |
| `sfx_loot_<goldPouch\|consumable\|gear\|charm\|tome>` | Content-type sweetener | 5 | P2 |
| `sfx_loot_reveal_all` | Reveal all | 1 | P2 |
| `sfx_elite_trophy` | Guaranteed Elite trophy | 1 | P3 |

---

## 9. Skill challenge (d20 series)

| ID | Event | Pri |
|---|---|---|
| `sfx_challenge_begin` | Begin | P3 |
| `sfx_d20_roll` (see §6) | Each round (550 ms) | P2 |
| `sfx_challenge_pip_success` / `_pip_fail` | Success or failure pip | P2 |
| `stg_challenge_success` / `stg_challenge_fail` | Result banner | P2 |

---

## 10. Naval: ship battle (Rusty Eel vs. 4 enemy ships)

### 10.1 Player ship actions

| ID | Event | Var | Pri |
|---|---|---|---|
| `sfx_ship_weapon_ballista_fire` | Ballista (12 dmg, 1 turn) | 3 | P1 |
| `sfx_ship_weapon_harpoon_fire` | Harpoon rack: pierces shields, close/medium range | 3 | P1 |
| `sfx_ship_weapon_firepots_fire` | Fire pots: incendiary, close range | 3 | P1 |
| `sfx_ship_weapon_void_volley_fire` | Void-Mark sail as a weapon (pierces shields) | 2 | P2 |
| `sfx_ship_weapon_charged` | Weapon ready (charges build over turns) | 1 | P2 |
| `sfx_ship_ammo_<round\|chain\|grape\|heated>` | Ammo select, plus a distinct flight and impact per type | 4 × 2 | P2 |
| `sfx_ship_aim_sweep` (loop) / `sfx_ship_aim_stop` | Aim minigame: a marker sweeps and the player stops it | 1 / 1 | P1 |
| `sfx_ship_aim_perfect` / `_steady` / `_wide` | `AimResult`; perfect = crit | 1 each | P1 |
| `sfx_ship_crew_move` | Station crew in a room (helm, guns, bulwark, hold) | 3 | P2 |
| `sfx_ship_auto_station` | Auto-station | 1 | P3 |
| `sfx_ship_maneuver_close` / `_pull_away` | Helm changes range (close, medium, long) | 1 each | P2 |
| `sfx_ship_end_turn` | End turn | 1 | P1 |
| `sfx_ship_quick_orders` | Turn ended with half the clock left (bolt icon) | 1 | P3 |
| `sfx_ship_clock_tick` / `_tick_urgent` / `_time_up` | 20 s turn clock; red at ≤ 5 s | 1 / 1 / 1 | P1 |
| `sfx_ship_focus` | Focus fire on the same room (+1 pip) | 1 | P3 |

### 10.2 Crew orders (9, once per battle each). A short VO bark plus an SFX

| Order | Who | SFX idea |
|---|---|---|
| All hands! | Player | Bell, crew rush, hammers |
| Brace! | Kelda | Timbers groan, everyone grabs on |
| Grapple! | Grosh | Hooks thrown, ships slam together |
| Bless the deck | Maren | Prayer, hiss of fires going out |
| Shore up | Tobin | Planks hammered, shield raised |
| Mark their helmsman | Malrik | Crossbow twang, distant cry |
| Cut their rigging | Sable | Rope snaps, sails flap loose |
| Eagle eye | Liora | Bowstring draw, held breath |
| Void ward | Vess | Void hum, a shot turned aside |

### 10.3 Hits and damage

| ID | Event | Pri |
|---|---|---|
| `sfx_ship_shot_splash` | Dodged: a miss into the water | P1 |
| `sfx_ship_shield_absorb` | Shield layer absorbs the shot (bulwark pip lost) | P1 |
| `sfx_ship_hull_hit` (light, heavy) | Hull damage: wood splinters | P1 |
| `sfx_ship_crit` | Critical hit | P1 |
| `sfx_ship_room_down` | A room is disabled | P2 |
| `sfx_ship_fire_start` / `amb_ship_fire_loop` / `sfx_ship_fire_out` | Fires | P1 |
| `sfx_ship_leak_start` / `amb_ship_flooding_loop` / `sfx_ship_leak_bailed` | Leaks (max 3) | P1 |
| `sfx_ship_rigging_torn` | Chain shot | P2 |
| `sfx_ship_grape_hit` | Grapeshot hits the crew | P2 |
| `sfx_ship_crew_hurt` | Crew in the hit room is injured (VO grunt) | P2 |
| `sfx_ship_rammed` | Iron-prow ram (inquisition_cutter) | P1 |
| `sfx_ship_repair_room` / `_hull_patch` / `_shield_regen` | Crew work at turn start | P2 |
| `sfx_ship_warded` | Void Ward turns a shot aside | P2 |
| `sfx_ship_low_hull_alarm` | Hull < 25% | P2 |

### 10.4 Enemy ships and weapons

- **Enemy ships (4):** raider_skiff (oars, open boat, flees), corsair_brig (marksman), inquisition_cutter (rams, hymn on deck?), void_barge (boarder, void hum).
- **Enemy weapons (6):** bow chaser, grapnel, ballista, fire arrows, void lance, harpoon. Enemy volleys fire one by one, 350 ms apart.
- **Enemy states:** fires out, leak plugged, repairs, closes in / pulls away, escapes.
- **Aim warning:** an incoming-aim cue, shown when the Kraken's Eye sail is fitted.

### 10.5 Boarding

| ID | Event | Pri |
|---|---|---|
| `sfx_board_grapple_throw` / `_slipped` | Grapple | P1 |
| `sfx_board_start` | Crews clash, bodies on deck, then the dice deck-fight | P1 |
| `sfx_board_enemy_boarders` | Enemy boarders come over the rail | P1 |
| `stg_board_won` / `stg_board_repelled` | Outcomes, for both sides | P2 |

### 10.6 Weather (re-rolled each round) and sea events

- **Weather:** calm, tailwind, crosswind, squall (puts fires out; `sfx_squall_quench`) and fog (muffles everything, **hides the enemy's aim**, so try a low-pass on enemy audio).
- **Forecast:** `sfx_weather_forecast_change` when the next round's weather is revealed.
- **Sea events:**
  - `sfx_sea_rogue_wave`: both ships lose a shield layer.
  - `sfx_sea_creature_bite`: a leviathan bites the most damaged ship.
  - `sfx_sea_wreck_soak`: drifting wreckage soaks a shot.

---

## 11. Voyage, travel, map and expeditions

| ID | Event | Pri |
|---|---|---|
| `sfx_voyage_cast_off` | Sail button: anchor up, sail drops | P1 |
| `sfx_voyage_day_advance` | "Day n / total": ship's bell | P2 |
| `sfx_voyage_event_<storm\|calm\|derelict\|sighting\|raider>` | Event cards. Storm: thunder and green water over the bow. Calm: gulls, glassy sea. Derelict: creaking wreck, salvage. Sighting: something huge under the keel, a phantom coast. Raider: "a grapnel thuds into the rail", then beat to quarters | P1 |
| `sfx_voyage_beat_to_quarters` | Battle alarm drum or bell | P1 |
| `sfx_voyage_landfall` | Anchor drop, "Go ashore" | P1 |
| `sfx_voyage_failed` | Limp back at 25% hull | P2 |
| `sfx_sail_power_<flight\|foresight\|hearth\|windknot\|voidmark>` | Sail sigil effects: Gull's Wing lift, Kraken's Eye vision, Hearth-Mark heal, Wind-Knot gust, Void-Mark calm | P2 |
| `sfx_ship_part_install` | Shipwright installs a part (12 parts: 3 weapons, 1 shield, 3 utility, 5 sails) | P2 |
| `sfx_ship_repair` | Paid hull repair: hammering and caulking | P2 |
| `sfx_travel_walk` | Walk to a place on the same shore | P2 |
| `sfx_map_traveller_step` / `_oar_stroke` | The world map replays each leg (550 ms per leg); oars on sea legs | P3 |
| `sfx_map_fog_reveal` | A new place is revealed from the fog | P3 |
| `sfx_expedition_start` / `_event_draw` / `_midpoint` / `_place_found` | Expedition flow | P2 |
| `sfx_expedition_boss_approach` | "Face <boss>" | P1 |
| `sfx_hunt_trail` / `sfx_hunt_quarry` | Hunt chain after a pack fight | P3 |
| `sfx_alignment_ambush_angel` / `_demon` | Hunter ambush reveal | P2 |
| `sfx_expedition_retreat` / `_defeated` | Expedition endings | P2 |

---

## 12. Economy, camp and progression

| ID | Event | Pri |
|---|---|---|
| `sfx_shop_enter` | Shop opened. 13 shops; optional per-shop bell or door: blind_beggar_stall, black_market_docks, weaponsmith_forge, shieldwrights_hall, arcane_bazaar, apothecary_row, smugglers_vault, hammersmith_forge, arcane_academy, sharpweave_den, ossuary_relics, last_lantern, anchorage_chandlery | P2 |
| `sfx_shop_buy` / `sfx_shop_sell` / `sfx_shop_cant_afford` / `sfx_shop_sold_out` | Transactions | P1 |
| `sfx_craft_forge` | Hammersmith forging (4 iron recipes) | P2 |
| `sfx_spell_learned` / `sfx_tome_read` | Spellbook learned / tome read | P2 |
| `sfx_equip_<weapon\|armor_head\|armor_top\|armor_bottom\|armor_foot\|artifact\|charm>` / `sfx_unequip` | Equip by slot (61 weapons, 28 armour) | P1 |
| `sfx_item_set_bonus` | Set bonus activates (Harborwatch Kit, Hollow Court Vestments) | P3 |
| `sfx_house_build_<id>` × 10 + `sfx_town_addition` × 4 | Camp building complete (floor, stair, store, tower) | P2 |
| `sfx_camp_rest` | Rest button: party healed to full, fire crackle | P1 |
| `sfx_party_swap` / `sfx_party_full` | Bench or activate an ally / party at capacity | P2 |
| `sfx_xp_gain` | XP tally | P2 |
| `sfx_stat_point_spend` | Spend a stat point (strength, dex, con, int, wis, per, luck, cha) | P1 |
| `sfx_skill_unlock` / `sfx_skill_upgrade` / `sfx_skill_merge` / `sfx_branch_mastery` | Skill tree (91 skills; 20 branches) | P1 / P2 / P2 / P2 |
| `sfx_skill_rarity_<common…legendary>` | Optional accent by rarity (5) | P3 |
| `sfx_npc_talk` | Open an NPC dialogue (lysa, old_harker, sister_ines) | P3 |
| `sfx_journal_open` / `sfx_quest_track` | Quests UI | P3 |

---

## 13. The dog companion (Foley)

This is a key emotional piece. The dog walks on the story screen at every node, guides every tutorial, and changes form with alignment.

| ID | Event | Var | Pri |
|---|---|---|---|
| `sfx_dog_step` | Paw steps (Walking: 8 frames per direction; walk in 700 ms, out 2600 ms) | 6 | P1 |
| `sfx_dog_sit` | Sits down | 2 | P2 |
| `sfx_dog_bark` | Fight loop bark (Bark anim, 6 frames at 900 ms) | 5 | P1 |
| `sfx_dog_growl` | Pre-fight (the node offers a fight) | 2 | P2 |
| `sfx_dog_pant` / `_whine` / `_happy` | Idle and emotion (optional) | 2 each | P3 |
| `sfx_dog_angel_<step\|bark\|shimmer>` | Angel form (Good): soft wing flutter, chime tail | 3 each | P2 |
| `sfx_dog_demon_<step\|bark\|ember>` | Demon form (Evil): hoof click, ember crackle, growl with reverb | 3 each | P2 |
| `sfx_dog_transform` | Alignment form change | 1 | P3 |
| `sfx_guide_appear` / `sfx_guide_next` / `sfx_guide_skip` | Tutorial guide flow (18 topics) | 1 each | P2 |

---

## 14. Voice-over

### 14.1 Narration (existing TTS; decide whether to keep it or record)
- **151 of 200 nodes** use the "Narrator". Other speakers are Archivist (3), The Sovereign (2), and one node each for Vane, Deserter, Chart-keeper, Penitent, Lantern-keeper and Legate.
- Today narration is TTS: on-device, or the Gemini voices Kore, Puck, Charon, Aoede, Fenrir, Leda, Zephyr and Autonoe.
- **For the designer:** music and ambience must leave room under narration. Plan a −8 to −10 dB duck while TTS plays, and avoid dense mids in the story beds.
- **Optional processing:** give The Sovereign and other void speakers a signature voice process (the reflected/reversed "Tear" treatment).

### 14.2 Companion barks (8 companions × 6 bark types × EN/FR)
Written lines already exist in `companions.json`. Bark types: `crit`, `dodge`, `fightStart`, `pack`, `ko`, `chest`. Each fires with a 35% chance.

| Companion | Race / class | Direction |
|---|---|---|
| Kelda | Dwarf warrior | Gruff |
| Sable | Human rogue | Wry thief |
| Sister Maren | Human cleric | Pious |
| Liora | Elf ranger | Calm scout |
| Vess | Voidkin mage | Cold; void-processed |
| Grosh | Orc warrior | Shouts, talks about himself in the third person |
| Brother Tobin | Dwarf cleric | Gentle; Good path only (no pack line) |
| Malrik Sarn | Orc rogue | Mercenary; Evil path only |

That is 8 × 6 = **48 lines per language** (about 94 lines, since Tobin has no pack line), plus:
- **9 crew-order barks** (§10.2)
- **scene asides**: 26 story nodes carry ally lines (vess 13, kelda 11, maren 11, liora 10, sable 8, tobin 8, malrik 7, grosh 6), about 74 lines per language
- **combat efforts** per companion (attack, hurt, KO, revive) × 8, also reused for their turned-enemy versions
- **recruit line** × 8

### 14.3 Player character efforts (non-verbal)
- 5 races (human, elf, dwarf, orc, voidkin), each with a male/female or neutral option if the design has one: attack, hurt, death, heal and level-up breaths.

### 14.4 Walla and crowd
Market, docks, tavern-like camp, Inquisition sermon, cult chant, and the White Fleet's dead in rows (whispers).

---

## 15. Asset count summary (approximate unique files, before variations)

| Category | Unique cues | With variations |
|---|---|---|
| Music: loops (menu, mood beds, hubs, combat, naval) | ~35 | + boss phase stems |
| Music: stingers | ~40 | |
| Ambience: loops (scenes, themes, zones, ports, sea, weather) | ~50 | + ~60 random one-shots |
| UI | ~30 | ~60 |
| Story and narrative | ~20 | ~40 |
| Dice | ~20 | ~80 (7 materials) |
| On-foot combat (VFX styles, hits, statuses, flow) | ~110 | ~300 |
| Enemy vocal sets | 10 families + 12 bosses + 12 signature skills | ~200 |
| Loot and chest | ~20 | ~35 |
| Naval (battle + voyage) | ~80 | ~150 |
| Economy, camp, progression | ~45 | ~70 |
| Dog | ~20 | ~50 |
| VO (companions, EN+FR) | ~350 lines | |

**Minimum P1 slice** (first playable pass), about 120 files:
- menu, story (neutral, grim, tense), camp, voyage, combat, boss and ship-battle music
- victory, defeat, level-up and quest stingers
- 5 key ambiences (docks, cathedral, slums, catacombs, camp) plus the 4 map themes
- core UI
- dice (1 material)
- the 34 VFX styles at P1 subset
- hits, crit, dodge, block, death
- poison, stun, weaken and cleanse
- chest open and reveal
- ship fire, aim, clock, hit, splash and ram
- dog steps and barks

---

## 16. Notes for integration (developer side)

- **No audio system exists yet.** Add an `AudioService` (e.g. `audioplayers` pools or `flame_audio` / `soloud`) with the buses in §1, plus Settings entries for per-bus volume and haptics.
- **Natural hook points already in code:**
  - `VfxStyle` playback (`combat_vfx.dart`): one SFX per style
  - the `_LogKind` and `_BanterKind` enums in the fight screen
  - the ship-battle log keys (`ship_log_*`, about 45 emitted): one event → one SFX
  - `showImmersiveNotice`
  - `showLevelUpDialog`
  - `SpoilsChestDialog` states
  - `SeaEventKind`, `BattleEnd`, `SeaWeather`, `CrewOrder`, `AimResult`, `ChestTier`
  - story `mood`, `ui_theme` and `script_trigger`
  - `isSettlementArrival`
  - `TutorialTopic`
- **Events with no VFX**, where sound must be added as a new hook: enemy death, enemy flee, alignment threshold crossing, weapon-charged, shield regen.
- **Respect existing toggles.** Reduce-motion and `combatEffectsEnabled` gate visuals only; audio should have its own switches.
