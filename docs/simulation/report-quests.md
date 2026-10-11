# Simulation report: a more human player, with quests (v1.230.0)

The simulator now plays quests the way the game does, and has a thorough player. 300 runs over six goals (50 each, professions rotated, seed 7) plus 200 thorough and 200 random runs for the per-quest table.

## What the simulated player now does

- **Takes work on offer.** A scene that offers a quest (`unlockQuestId`) or starts one (`questIDToProgress`) is accepted if the character qualifies: the quest's alignment (Good, Evil, or anyone), required flags and gold. A bounty counts only the kills made after it was taken (a fight that offers the quest counts its own kills).
- **Counts progress as the game does.** Kill objectives from the fights won (expedition fights included), Flag objectives from the story flags, Fetch objectives from the pack (items the story hands over and what the beaten foes drop, by their loot tables' own odds), Talk objectives once the person's chapter is reached. The objectives are read by the game's own `objectiveStatusesFor`.
- **Hands in at once** when every objective is met: gold, XP (through the level thresholds, so quests level the character), the reward item, alignment, the follow-up quest, and, for a quest with turn-in choices, the choice the player leans to (good, evil, most gold, else any).
- **Thorough goal** (`completionist`): takes every way on of a scene it has not taken yet before leaving, work on offer first, then what serves a quest it holds (a flag or a foe an objective waits on), the way out of the place last.
- Already there from before: rolling ability checks, spending level-up points on the class's stat, shops, potions, spells.

## 1. Effect on the run

| goal | runs | quests taken | quests done | quest gold | quest XP | level | attempt win |
|---|---|---|---|---|---|---|---|
| random | 50 | 13.2 | 8.2 | 764 | 1053 | 10.1 | 37% |
| favorGood | 50 | 12.3 | 8.4 | 823 | 1194 | 10.8 | 42% |
| favorEvil | 50 | 12.7 | 7.0 | 727 | 926 | 9.8 | 35% |
| maximizeGold | 50 | 13.6 | 10.1 | 927 | 1218 | 13.1 | 39% |
| explore | 50 | 13.5 | 8.9 | 822 | 1128 | 10.7 | 41% |
| completionist | 50 | 23.2 | 17.5 | 1431 | 1921 | 11.9 | 43% |

Before quests were played the same goals ended at level 7 to 8 (11 for the gold chaser) with a 31% attempt win rate (see `report-branches.md`); with quests they end at level 10 to 13 and win 35% to 43%. The thorough player is paid about 1 900 XP a run by quests alone.

## 2. Every quest, thorough player against random (200 runs each)

| chapter | quest | kind | difficulty | taken (thorough) | done (thorough) | taken (random) | done (random) | scenes to finish | pays | what stayed undone |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | A Bargain in Shadow (`q_temptation_dark`) | Side | 3 | 0% | 0% | 0% | 0% | – | 90g 90xp |  |
| 0 | A Charge of Light (`q_temptation_light`) | Side | 3 | 0% | 0% | 0% | 0% | – | 60g 90xp |  |
| 1 | Vess in the Dark (`q_ch1_vess_in_the_dark`) | Side | 2 | 25% | 25% | 17% | 17% | 0 | 25g 40xp |  |
| 1 | First Blood (`q_first_blood`) | Main | 1 | 34% | 34% | 34% | 34% | 0 | 20g 25xp |  |
| 1 | The Family Heirloom (`q_retrieve_banner`) | Main | 2 | 100% | 100% | 100% | 100% | 22 | 100g 150xp |  |
| 2 | The Burning Manifest (`q_ch2_burning_manifest`) | Side | 4 | 100% | 100% | 34% | 29% | 0 | 50g 60xp |  |
| 2 | The Captain's Gambit (`q_ch2_captains_gambit`) | Side | 5 | 100% | 85% | 39% | 20% | 2 | 70g 85xp | Kill: Confront the smuggler captain |
| 2 | Dockside Debts (`q_ch2_dockside_debts`) | Side | 3 | 100% | 100% | 20% | 20% | 1 | 30g 35xp |  |
| 2 | Harbor Reckoning (`q_ch2_harbor_reckoning`) | Side | 5 | 100% | 100% | 34% | 34% | 0 | 90g 100xp |  |
| 2 | The Informant's Tip (`q_ch2_informants_tip`) | Side | 3 | 10% | 10% | 9% | 9% | 0 | 45g 40xp |  |
| 2 | Kelda's Stand (`q_ch2_keldas_stand`) | Side | 3 | 100% | 98% | 18% | 18% | 1 | 40g 50xp | Kill: Help Kelda hold the wharf gate against the boarding party |
| 2 | A Hull to Leave In (`q_ch2_leave_saltmouth`) | Main | 3 | 100% | 100% | 100% | 100% | 22 | 80g 120xp |  |
| 2 | Liora's Watch (`q_ch2_lioras_watch`) | Side | 3 | 5% | 1% | 11% | 3% | 4 | 40g 50xp | Kill: Help Liora end the smuggler captain's raids on refugee boats |
| 2 | Sable's Wager (`q_ch2_sables_wager`) | Side | 3 | 60% | 38% | 12% | 5% | 1 | 35g 45xp | Flag: Get back the marker Sable lost to the card sharp at the dockhand |
| 2 | A Smuggler's Favor (`q_ch2_smugglers_favor`) | Side | 3 | 100% | 86% | 20% | 16% | 25 | 40g 40xp | Fetch: Bring back iron ore for the smuggler's forge |
| 2 | Tern's Toll (`q_ch2_terns_toll`) | Side | 3 | 16% | 16% | 17% | 17% | 1 | 40g 45xp |  |
| 2 | The Unpaid Scaffold (`q_ch2_unpaid_scaffold`) | Side | 3 | 12% | 2% | 25% | 4% | 5 | 40g 45xp | Flag: Face the Salt Ledger’s clerk over the Scaffolders’ wages |
| 3 | Alster's Dawn (`q_ch3_alsters_dawn`) | Main | 9 | 93% | 93% | 74% | 74% | 1 | 100g 150xp |  |
| 3 | The Ashen Oath (`q_ch3_ashen_oath`) | Main | 6 | 72% | 72% | 16% | 16% | 1 | 60g 90xp |  |
| 3 | Glass from the Terraces (`q_ch3_glass_from_the_terraces`) | Side | 4 | 0% | 0% | 18% | 2% | – | 50g 70xp |  |
| 3 | Grosh's Price (`q_ch3_groshs_price`) | Side | 5 | 0% | 0% | 16% | 12% | – | 55g 65xp |  |
| 3 | The Inquisition's Ledger (`q_ch3_inquisition_ledger`) | Main | 6 | 88% | 78% | 22% | 16% | 24 | 70g 100xp | Fetch: Recover the sealed Inquisition letter |
| 3 | Sister Maren's Penance (`q_ch3_marens_penance`) | Side | 6 | 85% | 85% | 22% | 22% | 0 | 60g 80xp |  |
| 3 | The Reckoning Wall (`q_ch3_reckoning_wall`) | Side | 5 | 0% | 0% | 12% | 12% | – | 50g 60xp |  |
| 3 | The High Warden's Fall (`q_ch3_the_high_wardens_fall`) | Main | 9 | 100% | 90% | 100% | 73% | 28 | 150g 200xp | Kill: Defeat the Inquisition High Warden |
| 3 | The Void Relic (`q_ch3_void_relic`) | Main | 7 | 96% | 96% | 31% | 28% | 1 | 90g 120xp |  |
| 4 | The Bark Tithe (`q_ch4_bark_tithe`) | Side | 6 | 8% | 0% | 26% | 2% | – | 75g 105xp | Flag: Recover Brannoc’s fever-bark from the Keyholders’ cache |
| 4 | The Ossuary Bounty (`q_ch4_ossuary_bounty`) | Side | 8 | 100% | 85% | 26% | 20% | 0 | 90g 120xp | Kill: Clear two catacomb ghouls from the flooded galleries |
| 4 | The Second Ledger (`q_ch4_the_second_ledger`) | Main | 11 | 100% | 6% | 29% | 3% | 23 | 200g 260xp | Kill: Defeat the Hollow Court Inquisitor who keeps the second ledger |
| 4 | Brother Tobin's Vigil (`q_ch4_tobins_vigil`) | Side | 6 | 6% | 6% | 16% | 16% | 0 | 60g 90xp |  |
| 5 | The Candle Count (`q_ch5_candle_count`) | Side | 7 | 8% | 0% | 26% | 2% | – | 90g 130xp | Flag: Carry Orsabet’s count back from the tally stone past the frost |
| 5 | The Hearth-Stone (`q_ch5_hearth_stone`) | Side | 7 | 50% | 5% | 48% | 14% | 2 | 90g 130xp | Flag: Hold the hearth-stone’s quarry face against the Quarrymen’s cut |
| 5 | Malrik's Cut (`q_ch5_malriks_cut`) | Side | 7 | 0% | 0% | 0% | 0% | – | 80g 110xp |  |
| 5 | The Penitent's Confession (`q_ch5_penitents_confession`) | Side | 10 | 100% | 100% | 26% | 26% | 1 | 120g 160xp |  |
| 5 | The Dead Heart (`q_ch5_the_dead_heart`) | Main | 13 | 100% | 3% | 26% | 0% | 32 | 260g 320xp | Kill: Defeat the Void Archon keeping the Shroud's vigil |
| 6 | Beyond the Tear (`q_ch6_beyond_the_tear`) | Main | 15 | 100% | 17% | 100% | 12% | 10 | 400g 500xp | Kill: Defeat the Sovereign beyond the tear |
| 6 | Faces of the Fallen (`q_ch6_faces_of_the_fallen`) | Side | 12 | 100% | 74% | 70% | 51% | 0 | 150g 200xp | Kill: Put down the hollow reflections that wear the faces of the falle |
| 6 | Salvage Rights (`q_ch6_salvage_rights`) | Side | 11 | 38% | 4% | 36% | 3% | 2 | 140g 185xp | Flag: Free Nkem’s salvage from the Admiralty’s impound |
| 6 | The White Fleet’s Grave (`q_ch6_the_white_fleet`) | Main | 14 | 100% | 12% | 100% | 9% | 0 | 300g 400xp | Kill: Defeat the White Admiral on his flagship |

The thorough player takes 23.1 quests a run and hands in 17.2.

## 3. Findings

1. **Quests nobody took:** `q_temptation_light`, `q_temptation_dark` and `q_ch5_malriks_cut`. The two temptation quests come from code the walk does not run; Malrik's Cut is Evil-only and no run reached it Evil enough.
2. **Hub quests the thorough player skipped but random runs took:** Grosh's Price, The Reckoning Wall and Glass from the Terraces (all offered by Ashen Quarter hub beats, scene 3005) are at 0% for the thorough player and 16%, 12% and 18% taken for random. The thorough player does visit that hub, so this looks like a gap in how it picks among the hub's beats, or in how Grosh's beat is gated. I did not trace the cause; it is open.
3. **The main line's boss kills are what the simulated character cannot finish.** Thorough player, done: the Second Ledger 6%, the Dead Heart 3%, Beyond the Tear 17%, the White Fleet's Grave 12%, though it takes every one of them (100%) at level 12 on average. Random: 3%, 0%, 12%, 9%.
4. **Flag quests mostly stall:** Sable's Wager 38% done, Hearth-Stone 5%, Salvage Rights 4%, Unpaid Scaffold 2%, Bark Tithe 0%, Candle Count 0% (thorough player, among those who took them; the last two are taken by only 8%). Each waits on a flag set by a hub beat. I have not checked which branch of those beats sets the flag, so I do not say here why they stall.
5. **Fetch quests do complete now** that foes drop their loot: A Smuggler's Favor (iron ore, reached as the follow-up of an earlier quest) 86% done, The Inquisition's Ledger (sealed letter) 78%.
6. **Rewards:** a thorough run is paid about 1 430 gold and 1 920 XP by its quests, against 730 to 930 gold and 930 to 1 220 XP for the other goals.

## 4. Still not human

Retreating from a fight to level up first, buying gear with the gold it holds, choosing dice faces and loadouts, reading telegraphs, and companion management are not modelled: the character retries a lost fight up to three times and then the story moves on. The NPC conversations that Talk objectives need are assumed done once the NPC's chapter is reached.
