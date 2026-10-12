# Simulation report: a more human player, with quests (v1.256.0)

Regenerated on `main` at v1.256.0 (702df94), docs only: nothing in the game was changed. The previous run was v1.230.0. 300 runs over six goals (50 each, professions rotated, seed 7) plus 200 thorough and 200 random runs for the per-quest table.

## What the simulated player now does

- **Takes work on offer.** A scene that offers a quest (`unlockQuestId`) or starts one (`questIDToProgress`) is accepted if the character qualifies: the quest's alignment (Good, Evil, or anyone), required flags and gold. A bounty counts only the kills made after it was taken (a fight that offers the quest counts its own kills).
- **Counts progress as the game does.** Kill objectives from the fights won (expedition fights included), Flag objectives from the story flags, Fetch objectives from the pack (items the story hands over and what the beaten foes drop, by their loot tables' own odds), Talk objectives once the person's chapter is reached. The objectives are read by the game's own `objectiveStatusesFor`.
- **Hands in at once** when every objective is met: gold, XP (through the level thresholds, so quests level the character), the reward item, alignment, the follow-up quest, and, for a quest with turn-in choices, the choice the player leans to (good, evil, most gold, else any).
- **Thorough goal** (`completionist`): takes every way on of a scene it has not taken yet before leaving, work on offer first, then what serves a quest it holds (a flag or a foe an objective waits on), the way out of the place last.
- Already there from before: rolling ability checks, spending level-up points on the class's stat, shops, potions, spells.

## 1. Effect on the run

| goal | runs | quests taken | quests done | quest gold | quest XP | level | attempt win |
|---|---|---|---|---|---|---|---|
| random | 50 | 12.7 | 7.8 | 773 | 1055 | 9.8 | 36% |
| favorGood | 50 | 12.5 | 7.8 | 676 | 985 | 9.8 | 37% |
| favorEvil | 50 | 13.6 | 8.3 | 828 | 1074 | 10.3 | 38% |
| maximizeGold | 50 | 13.6 | 9.9 | 902 | 1180 | 12.3 | 35% |
| explore | 50 | 13.8 | 9.1 | 823 | 1137 | 10.1 | 37% |
| completionist | 50 | 23.1 | 17.1 | 1367 | 1844 | 11.5 | 41% |

Since v1.230.0 the goals end a little lower and win a little less (level 9.8 to 12.3 against 9.8 to 13.1, attempt win 35% to 41% against 35% to 43%), which fits the 100-run report: the game and the simulator have both changed in 24 versions. The thorough player is still paid the most by quests, about 1 840 XP a run.

## 2. Every quest, thorough player against random (200 runs each)

| chapter | quest | kind | difficulty | taken (thorough) | done (thorough) | taken (random) | done (random) | scenes to finish | pays | what stayed undone |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | A Bargain in Shadow (`q_temptation_dark`) | Side | 3 | 0% | 0% | 0% | 0% | – | 90g 90xp |  |
| 0 | A Charge of Light (`q_temptation_light`) | Side | 3 | 0% | 0% | 0% | 0% | – | 60g 90xp |  |
| 1 | First Blood (`q_first_blood`) | Main | 1 | 23% | 23% | 23% | 23% | 0 | 20g 25xp |  |
| 1 | The Family Heirloom (`q_retrieve_banner`) | Main | 2 | 100% | 100% | 100% | 100% | 22 | 100g 150xp |  |
| 1 | Vess in the Dark (`q_ch1_vess_in_the_dark`) | Side | 2 | 24% | 24% | 14% | 14% | 0 | 25g 40xp |  |
| 2 | A Hull to Leave In (`q_ch2_leave_saltmouth`) | Main | 3 | 100% | 100% | 100% | 100% | 22 | 80g 120xp |  |
| 2 | A Smuggler's Favor (`q_ch2_smugglers_favor`) | Side | 3 | 100% | 86% | 20% | 18% | 29 | 40g 40xp | Fetch: Bring back iron ore for the smuggler's forge |
| 2 | Dockside Debts (`q_ch2_dockside_debts`) | Side | 3 | 100% | 100% | 20% | 20% | 1 | 30g 35xp |  |
| 2 | Harbor Reckoning (`q_ch2_harbor_reckoning`) | Side | 5 | 100% | 100% | 28% | 28% | 0 | 90g 100xp |  |
| 2 | Kelda's Stand (`q_ch2_keldas_stand`) | Side | 3 | 100% | 98% | 18% | 16% | 1 | 40g 50xp | Kill: Help Kelda hold the wharf gate against the boarding party |
| 2 | Liora's Watch (`q_ch2_lioras_watch`) | Side | 3 | 9% | 2% | 10% | 2% | 17 | 40g 50xp | Kill: Help Liora end the smuggler captain's raids on refugee boats |
| 2 | Sable's Wager (`q_ch2_sables_wager`) | Side | 3 | 65% | 38% | 13% | 4% | 1 | 35g 45xp | Flag: Get back the marker Sable lost to the card sharp at the dockhand |
| 2 | Tern's Toll (`q_ch2_terns_toll`) | Side | 3 | 18% | 18% | 16% | 16% | 1 | 40g 45xp |  |
| 2 | The Burning Manifest (`q_ch2_burning_manifest`) | Side | 4 | 100% | 100% | 27% | 21% | 0 | 50g 60xp |  |
| 2 | The Captain's Gambit (`q_ch2_captains_gambit`) | Side | 5 | 100% | 88% | 34% | 13% | 4 | 70g 85xp | Kill: Confront the smuggler captain |
| 2 | The Informant's Tip (`q_ch2_informants_tip`) | Side | 3 | 10% | 10% | 8% | 8% | 0 | 45g 40xp |  |
| 2 | The Unpaid Scaffold (`q_ch2_unpaid_scaffold`) | Side | 3 | 22% | 5% | 18% | 2% | 4 | 40g 45xp | Flag: Face the Salt Ledger’s clerk over the Scaffolders’ wages |
| 3 | Alster's Dawn (`q_ch3_alsters_dawn`) | Main | 9 | 88% | 88% | 73% | 73% | 1 | 100g 150xp |  |
| 3 | Glass from the Terraces (`q_ch3_glass_from_the_terraces`) | Side | 4 | 0% | 0% | 18% | 0% | – | 50g 70xp |  |
| 3 | Grosh's Price (`q_ch3_groshs_price`) | Side | 5 | 0% | 0% | 18% | 13% | – | 55g 65xp |  |
| 3 | Sister Maren's Penance (`q_ch3_marens_penance`) | Side | 6 | 85% | 85% | 16% | 16% | 0 | 60g 80xp |  |
| 3 | The Ashen Oath (`q_ch3_ashen_oath`) | Main | 6 | 76% | 76% | 12% | 12% | 1 | 60g 90xp |  |
| 3 | The High Warden's Fall (`q_ch3_the_high_wardens_fall`) | Main | 9 | 100% | 86% | 100% | 73% | 28 | 150g 200xp | Kill: Defeat the Inquisition High Warden |
| 3 | The Inquisition's Ledger (`q_ch3_inquisition_ledger`) | Main | 6 | 92% | 80% | 22% | 16% | 25 | 70g 100xp | Fetch: Recover the sealed Inquisition letter |
| 3 | The Reckoning Wall (`q_ch3_reckoning_wall`) | Side | 5 | 0% | 0% | 14% | 14% | – | 50g 60xp |  |
| 3 | The Void Relic (`q_ch3_void_relic`) | Main | 7 | 98% | 98% | 32% | 29% | 1 | 90g 120xp |  |
| 4 | Brother Tobin's Vigil (`q_ch4_tobins_vigil`) | Side | 6 | 4% | 4% | 10% | 10% | 0 | 60g 90xp |  |
| 4 | The Bark Tithe (`q_ch4_bark_tithe`) | Side | 6 | 8% | 0% | 26% | 5% | – | 75g 105xp | Flag: Recover Brannoc’s fever-bark from the Keyholders’ cache |
| 4 | The Ossuary Bounty (`q_ch4_ossuary_bounty`) | Side | 8 | 100% | 83% | 22% | 14% | 0 | 90g 120xp | Kill: Clear two catacomb ghouls from the flooded galleries |
| 4 | The Second Ledger (`q_ch4_the_second_ledger`) | Main | 11 | 100% | 6% | 32% | 1% | 23 | 200g 260xp | Kill: Defeat the Hollow Court Inquisitor who keeps the second ledger |
| 5 | Malrik's Cut (`q_ch5_malriks_cut`) | Side | 7 | 0% | 0% | 0% | 0% | – | 80g 110xp |  |
| 5 | The Candle Count (`q_ch5_candle_count`) | Side | 7 | 10% | 0% | 28% | 3% | – | 90g 130xp | Flag: Carry Orsabet’s count back from the tally stone past the frost |
| 5 | The Dead Heart (`q_ch5_the_dead_heart`) | Main | 13 | 100% | 2% | 27% | 1% | 26 | 260g 320xp | Kill: Defeat the Void Archon keeping the Shroud's vigil |
| 5 | The Hearth-Stone (`q_ch5_hearth_stone`) | Side | 7 | 48% | 7% | 46% | 7% | 3 | 90g 130xp | Flag: Hold the hearth-stone’s quarry face against the Quarrymen’s cut |
| 5 | The Penitent's Confession (`q_ch5_penitents_confession`) | Side | 10 | 100% | 100% | 27% | 27% | 1 | 120g 160xp |  |
| 6 | Beyond the Tear (`q_ch6_beyond_the_tear`) | Main | 15 | 100% | 18% | 100% | 16% | 5 | 400g 500xp | Kill: Defeat the Sovereign beyond the tear |
| 6 | Faces of the Fallen (`q_ch6_faces_of_the_fallen`) | Side | 12 | 100% | 71% | 79% | 39% | 0 | 150g 200xp | Kill: Put down the hollow reflections that wear the faces of the falle |
| 6 | Salvage Rights (`q_ch6_salvage_rights`) | Side | 11 | 26% | 4% | 32% | 2% | 2 | 140g 185xp | Flag: Free Nkem’s salvage from the Admiralty’s impound |
| 6 | The White Fleet’s Grave (`q_ch6_the_white_fleet`) | Main | 14 | 100% | 12% | 100% | 14% | 0 | 300g 400xp | Kill: Defeat the White Admiral on his flagship |

The thorough player takes 23.0 quests a run and hands in 17.1.

## 3. Findings

1. **Quests nobody took:** `q_temptation_light`, `q_temptation_dark` and `q_ch5_malriks_cut` are at 0% for both players. The two temptation quests come from code the walk does not run. Malrik's Cut is Evil-only (`requiredAlignment`) and is offered by scene 6010_malrik; I did not check whether the `favorEvil` runs reach that scene Evil enough.
2. **Hub quests the thorough player never takes but random runs do:** Grosh's Price, The Reckoning Wall and Glass from the Terraces are at 0% for the thorough player and 18%, 14% and 18% taken for random (13%, 14% and 0% done). All three are offered by beats of the Ashen Quarter hub (scene 3005) through a plain choice with no flag condition, and their quests admit any alignment (`Neutral` accepts everyone); only Grosh's beat has a gate, 80 gold. The thorough player does visit that hub (it takes the quests offered by its other beats), so this looks like a gap in how it picks among the hub's beats. I did not trace the cause; it is open.
3. **The main line's boss kills are what the simulated character cannot finish.** Thorough player, taken then done: the Second Ledger 100% then 6%, the Dead Heart 100% then 2%, Beyond the Tear 100% then 18%, the White Fleet's Grave 100% then 12%, though the goal ends at level 11.5 on average. Random runs finish 1%, 1%, 16% and 14%. The earlier boss quests do finish: the High Warden's Fall 86%, the Captain's Gambit 88%, the Ossuary Bounty 83% (thorough).
4. **Flag quests mostly stall:** taken then done for the thorough player: Sable's Wager 65% then 38%, The Hearth-Stone 48% then 7%, The Unpaid Scaffold 22% then 5%, Salvage Rights 26% then 4%, The Bark Tithe 8% then 0%, The Candle Count 10% then 0%. Each waits on a flag set by a hub beat. I have not checked which branch of those beats sets the flag, so I do not say here why they stall.
5. **Fetch quests do complete** now that foes drop their loot: A Smuggler's Favor (iron ore; the thorough player always takes it, as the follow-up of an earlier quest, and finishes 86%; random runs take it 20% of the time) and The Inquisition's Ledger (sealed letter, 92% taken, 80% done).
6. **Rewards:** a thorough run is paid about 1 370 gold and 1 840 XP by its quests, against 680 to 900 gold and 990 to 1 180 XP for the other goals.

## 4. Still not human

Retreating from a fight to level up first, buying gear with the gold it holds, choosing dice faces and loadouts, reading telegraphs, and companion management are not modelled: the character retries a lost fight up to three times and then the story moves on. The NPC conversations that Talk objectives need are assumed done once the NPC's chapter is reached.
