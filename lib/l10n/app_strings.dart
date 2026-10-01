import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';

/// A small hand-maintained UI string table. Covers navigation chrome, the
/// story reader, and a handful of the most common action labels — not an
/// exhaustive translation of every screen (see the language toggle's
/// tooltip in Settings for the current coverage note).
const Map<String, Map<AppLanguage, String>> _strings = {
  'nav_story': {AppLanguage.en: 'Story', AppLanguage.fr: 'Histoire'},
  'nav_play': {AppLanguage.en: 'Play', AppLanguage.fr: 'Jouer'},
  'nav_character': {AppLanguage.en: 'Character', AppLanguage.fr: 'Personnage'},
  'nav_camp': {AppLanguage.en: 'Camp', AppLanguage.fr: 'Campement'},
  'nav_other': {AppLanguage.en: 'Other', AppLanguage.fr: 'Autres'},
  'nav_ship': {AppLanguage.en: 'Ship', AppLanguage.fr: 'Navire'},
  'nav_journey': {AppLanguage.en: 'Journey', AppLanguage.fr: 'Parcours'},
  'journey_pick_hint': {
    AppLanguage.en:
        'Tap a step on the map to see where it leads; tap it again or press Go to take it.',
    AppLanguage.fr:
        'Touchez une étape de la carte pour voir où elle mène ; touchez-la encore ou appuyez sur Partir pour la prendre.',
  },
  'journey_go': {AppLanguage.en: 'Go', AppLanguage.fr: 'Partir'},
  'journey_you_are_here': {
    AppLanguage.en: 'You are here',
    AppLanguage.fr: 'Vous êtes ici',
  },
  'journey_leads_to': {
    AppLanguage.en: 'To {place}',
    AppLanguage.fr: 'Vers {place}',
  },
  'journey_ended': {
    AppLanguage.en: 'The road ends here. The Story tab has what comes next.',
    AppLanguage.fr:
        'La route s’arrête ici. L’onglet Histoire vous montre la suite.',
  },
  'journey_open_story': {
    AppLanguage.en: 'Open the story',
    AppLanguage.fr: 'Ouvrir l’histoire',
  },
  'journey_read_in_story': {
    AppLanguage.en: 'Read the scene in the Story tab',
    AppLanguage.fr: 'Lire la scène dans l’onglet Histoire',
  },
  'journey_chapter_start': {
    AppLanguage.en: 'Where the chapter began',
    AppLanguage.fr: 'Là où le chapitre a commencé',
  },
  'journey_reading_exit': {
    AppLanguage.en: 'Back to the map',
    AppLanguage.fr: 'Revenir à la carte',
  },
  'journey_way_taken': {
    AppLanguage.en: 'Way taken: {way}',
    AppLanguage.fr: 'Chemin pris : {way}',
  },
  'journey_kind_ending': {AppLanguage.en: 'Ending', AppLanguage.fr: 'Fin'},
  'journey_kind_mainQuest': {
    AppLanguage.en: 'Main quest',
    AppLanguage.fr: 'Quête principale',
  },
  'journey_kind_expedition': {
    AppLanguage.en: 'Expedition',
    AppLanguage.fr: 'Expédition',
  },
  'journey_kind_fight': {AppLanguage.en: 'Fight', AppLanguage.fr: 'Combat'},
  'journey_kind_challenge': {
    AppLanguage.en: 'Challenge',
    AppLanguage.fr: 'Épreuve',
  },
  'journey_kind_check': {AppLanguage.en: 'Roll', AppLanguage.fr: 'Jet'},
  'journey_kind_shop': {AppLanguage.en: 'Shop', AppLanguage.fr: 'Boutique'},
  'journey_kind_quest': {AppLanguage.en: 'Work', AppLanguage.fr: 'Travail'},
  'journey_kind_travel': {AppLanguage.en: 'Voyage', AppLanguage.fr: 'Voyage'},
  'journey_kind_rest': {AppLanguage.en: 'Rest', AppLanguage.fr: 'Repos'},
  'journey_kind_road': {AppLanguage.en: 'Road', AppLanguage.fr: 'Route'},
  'echo_because': {
    AppLanguage.en: 'Because you chose “{choice}”',
    AppLanguage.fr: 'Parce que vous avez choisi « {choice} »',
  },
  'journal_story_tab': {AppLanguage.en: 'Scenes', AppLanguage.fr: 'Scènes'},
  'journal_changed_title': {
    AppLanguage.en: 'What changed',
    AppLanguage.fr: 'Ce qui a changé',
  },
  'journal_changed_empty': {
    AppLanguage.en:
        'Nothing yet. What you choose comes back in later scenes, and is noted here.',
    AppLanguage.fr:
        'Rien encore. Vos choix reviennent dans des scènes plus loin, et sont notés ici.',
  },
  'journey_event_champion': {
    AppLanguage.en:
        'A champion holds this road: an Elite fight, a better chest.',
    AppLanguage.fr:
        'Un champion tient cette route : un combat d’Élite, un meilleur coffre.',
  },
  'journey_event_shrine': {
    AppLanguage.en: 'A wayside shrine on this road: a place to heal.',
    AppLanguage.fr: 'Un sanctuaire sur cette route : de quoi vous soigner.',
  },
  'journey_event_caravan': {
    AppLanguage.en: 'The Wayfarer’s Caravan is on this road: rare goods.',
    AppLanguage.fr:
        'La Caravane du Voyageur est sur cette route : des marchandises rares.',
  },
  'timed_choice_hint': {
    AppLanguage.en: 'Choose before time runs out',
    AppLanguage.fr: 'Choisissez avant la fin du temps',
  },
  'road_title': {AppLanguage.en: 'The road', AppLanguage.fr: 'La route'},
  'road_day_line': {
    AppLanguage.en: 'Day {day} · {n} days in this chapter',
    AppLanguage.fr: 'Jour {day} · {n} jours dans ce chapitre',
  },
  'road_threat_on': {
    AppLanguage.en:
        'The longer you linger, the more your enemies gather: they hit harder and last longer (+{p}%).',
    AppLanguage.fr:
        'Plus vous vous attardez, plus vos ennemis se rassemblent : ils frappent plus fort et tiennent plus longtemps (+{p} %).',
  },
  'road_threat_off': {
    AppLanguage.en:
        'After {n} days in this chapter, its enemies start to gather strength. A night’s rest or a voyage takes days.',
    AppLanguage.fr:
        'Après {n} jours dans ce chapitre, ses ennemis commencent à se renforcer. Une nuit de repos ou un voyage prend des jours.',
  },
  'condition_line': {
    AppLanguage.en: 'This chapter: {name}',
    AppLanguage.fr: 'Ce chapitre : {name}',
  },
  'condition_where': {
    AppLanguage.en:
        'It lasts the whole chapter. Tap your stats at the top of the screen to see it again, under The road.',
    AppLanguage.fr:
        'Cela dure tout le chapitre. Touchez vos statistiques en haut de l’écran pour le revoir, sous « La route ».',
  },
  'condition_shop_line': {
    AppLanguage.en: '{name}: prices {p}%',
    AppLanguage.fr: '{name} : prix {p} %',
  },
  'condition_pay_line': {
    AppLanguage.en: '{name}: {delta} gold on the pay',
    AppLanguage.fr: '{name} : {delta} or sur la paie',
  },
  'road_rations_line': {
    AppLanguage.en: 'Rations: {n}/{max}',
    AppLanguage.fr: 'Rations : {n}/{max}',
  },
  'road_rations_help': {
    AppLanguage.en:
        'You eat one on every road between two places, and one for every day at sea. With none left, hunger costs health.',
    AppLanguage.fr:
        'Vous en mangez une sur chaque route entre deux lieux, et une par jour en mer. Sans rien à manger, la faim vous coûte de la santé.',
  },
  'road_rations_label': {AppLanguage.en: 'Rations', AppLanguage.fr: 'Rations'},
  'stats_threat': {
    AppLanguage.en: 'Your enemies are gathering (+{p}%)',
    AppLanguage.fr: 'Vos ennemis se rassemblent (+{p} %)',
  },
  'road_buy_one': {
    AppLanguage.en: 'Buy 1 ({gold} gold)',
    AppLanguage.fr: 'En acheter 1 ({gold} or)',
  },
  'road_fill_up': {
    AppLanguage.en: 'Fill the pack ({gold} gold)',
    AppLanguage.fr: 'Remplir le sac ({gold} or)',
  },
  'road_sellsword_line': {
    AppLanguage.en: 'A sellsword',
    AppLanguage.fr: 'Un mercenaire',
  },
  'road_sellsword_hired': {
    AppLanguage.en: 'Sellsword under contract: {n} fights left',
    AppLanguage.fr: 'Mercenaire sous contrat : encore {n} combats',
  },
  'road_sellsword_help': {
    AppLanguage.en:
        'Fights beside you for {n} fights and strikes the weakest enemy for {dmg} each round.',
    AppLanguage.fr:
        'Se bat à vos côtés pendant {n} combats et frappe l’ennemi le plus faible ({dmg} dégâts) à chaque tour.',
  },
  'road_hire_sellsword': {
    AppLanguage.en: 'Hire ({gold} gold)',
    AppLanguage.fr: 'Engager ({gold} or)',
  },
  'road_market_hint': {
    AppLanguage.en:
        'Rations and sellswords are found in towns, villages and at the camp.',
    AppLanguage.fr:
        'Rations et mercenaires se trouvent dans les villes, les villages et au campement.',
  },
  'road_note_day': {
    AppLanguage.en: 'Night falls on the road. Day {day} begins.',
    AppLanguage.fr: 'La nuit tombe sur la route. Le jour {day} commence.',
  },
  'road_note_hungry': {
    AppLanguage.en: 'Nothing left to eat: hunger costs you {n} health.',
    AppLanguage.fr:
        'Plus rien à manger : la faim vous coûte {n} points de santé.',
  },
  'road_note_low': {
    AppLanguage.en: 'Rations are running low ({n} left).',
    AppLanguage.fr: 'Les rations s’épuisent (il en reste {n}).',
  },
  'road_note_last': {
    AppLanguage.en:
        'That was the last ration. More are sold in towns and at the camp.',
    AppLanguage.fr:
        'C’était la dernière ration. Il s’en vend en ville et au campement.',
  },
  'rest_new_day': {
    AppLanguage.en: 'Day {day} begins.',
    AppLanguage.fr: 'Le jour {day} commence.',
  },
  'retreat_potion_part': {
    AppLanguage.en: ' and a potion',
    AppLanguage.fr: ' et une potion',
  },
  'sellsword_strikes': {
    AppLanguage.en: 'Your sellsword strikes {name} for {n}.',
    AppLanguage.fr: 'Votre mercenaire frappe {name} : {n} dégâts.',
  },
  'threat_fight_note': {
    AppLanguage.en:
        'Your enemies have gathered strength while you lingered (+{p}%).',
    AppLanguage.fr:
        'Vos ennemis se sont renforcés pendant que vous vous attardiez (+{p} %).',
  },
  'camp_party_section': {
    AppLanguage.en: 'Who comes along',
    AppLanguage.fr: 'Qui vous accompagne',
  },
  'camp_scene_title': {
    AppLanguage.en: 'Back at the fire',
    AppLanguage.fr: 'De retour au coin du feu',
  },
  'camp_scene_read_all': {
    AppLanguage.en: 'Read it all',
    AppLanguage.fr: 'Tout lire',
  },
  'camp_expeditions_section': {
    AppLanguage.en: 'Expeditions from the camp',
    AppLanguage.fr: 'Expéditions depuis le camp',
  },
  'camp_return_button': {
    AppLanguage.en: 'Back to the camp',
    AppLanguage.fr: 'Retour au camp',
  },
  'travel_walked_to': {
    AppLanguage.en: 'You walk to {place}.',
    AppLanguage.fr: 'Vous gagnez {place} à pied.',
  },
  'travel_road_to': {
    AppLanguage.en: 'The road to {place}',
    AppLanguage.fr: 'La route de {place}',
  },
  'travel_road_to_camp': {
    AppLanguage.en: 'The road back to the camp',
    AppLanguage.fr: 'La route du camp',
  },
  'travel_on_button': {
    AppLanguage.en: 'Travel on',
    AppLanguage.fr: 'Aller ailleurs',
  },
  'travel_on_title': {
    AppLanguage.en: 'Where to next',
    AppLanguage.fr: 'Et maintenant, où ?',
  },
  'places_section': {
    AppLanguage.en: 'Places you know',
    AppLanguage.fr: 'Lieux connus',
  },
  'places_empty': {
    AppLanguage.en:
        'No place found yet. Expeditions find them: a town, a village, a ruin worth the walk.',
    AppLanguage.fr:
        'Aucun lieu trouvé pour l’instant. Les expéditions les révèlent : une ville, un village, une ruine qui vaut la marche.',
  },
  'place_kind_town': {AppLanguage.en: 'Town', AppLanguage.fr: 'Ville'},
  'place_kind_village': {AppLanguage.en: 'Village', AppLanguage.fr: 'Village'},
  'place_kind_site': {AppLanguage.en: 'Site', AppLanguage.fr: 'Site'},
  'place_kind_camp': {AppLanguage.en: 'Camp', AppLanguage.fr: 'Camp'},
  'place_progress': {
    AppLanguage.en: '{done}/{total} done',
    AppLanguage.fr: '{done}/{total} faits',
  },
  'place_go_button': {AppLanguage.en: 'Go', AppLanguage.fr: 'Y aller'},
  'place_found_line': {
    AppLanguage.en: 'New place: {place}. You can travel there now.',
    AppLanguage.fr:
        'Nouveau lieu : {place}. Vous pouvez désormais vous y rendre.',
  },
  'companion_hint': {
    AppLanguage.en: 'Word at the fire: someone in {place} might join you.',
    AppLanguage.fr:
        'Au coin du feu, on parle de quelqu’un qui pourrait vous rejoindre : {place}.',
  },
  'place_companion_label': {
    AppLanguage.en: 'someone to meet',
    AppLanguage.fr: 'quelqu’un à rencontrer',
  },
  'chapter_quests_progress': {
    AppLanguage.en: 'Quests completed: {done} of {goal}',
    AppLanguage.fr: 'Quêtes accomplies : {done} sur {goal}',
  },
  'main_quest_shut_lock': {
    AppLanguage.en: 'Not yet: the camp shows what this chapter still asks.',
    AppLanguage.fr: 'Pas encore : le camp indique ce que ce chapitre demande.',
  },
  'choice_gold_short_lock': {
    AppLanguage.en: '{choice} · not enough gold ({gold} in the purse)',
    AppLanguage.fr: '{choice} · pas assez d’or ({gold} dans la bourse)',
  },
  'chapter_progress': {
    AppLanguage.en: 'Explored: {done} of {goal}',
    AppLanguage.fr: 'Exploré : {done} sur {goal}',
  },
  'main_quest_label': {
    AppLanguage.en: 'Main quest',
    AppLanguage.fr: 'Quête principale',
  },
  'main_quest_needs_place': {
    AppLanguage.en: 'Visit {place} first.',
    AppLanguage.fr: 'Visitez d’abord {place}.',
  },
  'camp_route_walk': {
    AppLanguage.en: 'a day’s walk',
    AppLanguage.fr: 'une journée de marche',
  },
  'camp_route_sail': {
    AppLanguage.en: '{n} days at sea',
    AppLanguage.fr: '{n} jours de mer',
  },
  'camp_walked_back': {
    AppLanguage.en: 'You walk back to the camp.',
    AppLanguage.fr: 'Vous rentrez au camp à pied.',
  },
  'camp_away_title': {
    AppLanguage.en: 'Away from the camp',
    AppLanguage.fr: 'Loin du camp',
  },
  'camp_away_body': {
    AppLanguage.en:
        'The story has taken you away from the camp. You will be back at the fire when this road ends.',
    AppLanguage.fr:
        'Le récit se poursuit loin du camp. Vous retrouverez le feu au bout de cette route.',
  },
  'camp_away_town_body': {
    AppLanguage.en:
        'You are in {place}, {route} from the camp. The camp is your base: your companions’ gear, skills and dice, the works and the Harbor are there. Go back whenever you like.',
    AppLanguage.fr:
        'Vous êtes à {place}, à {route} du camp. Le camp est votre base : l’équipement, les compétences et les dés de vos compagnons, les ouvrages et le port s’y trouvent. Revenez-y quand vous voulez.',
  },
  'camp_sail_section': {
    AppLanguage.en: 'Set sail',
    AppLanguage.fr: 'Prendre la mer',
  },
  'camp_sail_hint': {
    AppLanguage.en:
        'Other ports’ expeditions are a voyage away. While the Rusty Eel is out, the Camp tab is the ship until you sail back.',
    AppLanguage.fr:
        'Les expéditions des autres ports sont à une traversée d’ici. Tant que le Rusty Eel est au large, l’onglet Campement devient le navire jusqu’à votre retour.',
  },
  'chart_empty': {
    AppLanguage.en: 'No other port on the chart yet.',
    AppLanguage.fr: 'Aucun autre port sur la carte pour l’instant.',
  },
  'sail_home_title': {
    AppLanguage.en: 'Sail back to camp',
    AppLanguage.fr: 'Rentrer au camp',
  },
  'ship_sailed_out_note': {
    AppLanguage.en:
        'You have sailed out from the camp. Its expeditions, shops and rest are wherever the Eel is moored; sail back to camp to go on with the story.',
    AppLanguage.fr:
        'Vous avez quitté le camp par la mer. Expéditions, boutiques et repos sont là où l’Eel est amarré ; rentrez au camp pour reprendre le récit.',
  },
  'ship_away_note': {
    AppLanguage.en:
        'The story has taken you away from camp. The Rusty Eel can still sail to the ports on the chart; the camp opens again when the story brings you back.',
    AppLanguage.fr:
        'Le récit se poursuit loin du camp. Le Rusty Eel peut encore gagner les ports de la carte ; le camp rouvre quand le récit vous y ramène.',
  },
  'ship_ashore_section': {
    AppLanguage.en: 'Ashore at {port}',
    AppLanguage.fr: 'À terre : {port}',
  },
  'harbor_title': {AppLanguage.en: 'Harbor', AppLanguage.fr: 'Port'},
  'harbor_open_button': {
    AppLanguage.en: 'Go to the Harbor',
    AppLanguage.fr: 'Aller au port',
  },
  'harbor_unlocks_note': {
    AppLanguage.en: 'refits the Rusty Eel: repairs and ship parts',
    AppLanguage.fr: 'radoube le Rusty Eel : réparations et pièces de navire',
  },
  'ally_gear_button': {AppLanguage.en: 'Gear', AppLanguage.fr: 'Équipement'},
  'ally_dice_button': {AppLanguage.en: 'Dice', AppLanguage.fr: 'Dés'},
  'title_other': {AppLanguage.en: 'Other', AppLanguage.fr: 'Autres'},
  'badge_points_waiting': {
    AppLanguage.en: 'points to spend',
    AppLanguage.fr: 'points à dépenser',
  },
  'badge_house_affordable': {
    AppLanguage.en: 'a house you can build',
    AppLanguage.fr: 'une maison à construire',
  },
  'badge_quest_ready': {
    AppLanguage.en: 'a quest to turn in',
    AppLanguage.fr: 'une quête à rendre',
  },
  'quests_ready_label': {
    AppLanguage.en: 'to turn in',
    AppLanguage.fr: 'à rendre'
  },
  'load_confirm_title': {
    AppLanguage.en: 'Load this save?',
    AppLanguage.fr: 'Charger cette sauvegarde ?',
  },
  'load_confirm_body': {
    AppLanguage.en:
        'It replaces the game in progress. Anything since your last save will be lost.',
    AppLanguage.fr:
        'Elle remplace la partie en cours. Tout ce qui s’est passé depuis votre dernière sauvegarde sera perdu.',
  },
  'fight_lab_title': {
    AppLanguage.en: 'Fight lab',
    AppLanguage.fr: 'Labo de combat'
  },
  'fight_lab_card_desc': {
    AppLanguage.en: 'Test any fight, pack, die or ship battle',
    AppLanguage.fr:
        'Tester n’importe quel combat, meute, dé ou bataille navale',
  },
  'fight_lab_intro': {
    AppLanguage.en:
        'Test fights never run permadeath. Your game is put back as it was afterwards (health, gold, loot, experience, die and party) unless you keep what happens.',
    AppLanguage.fr:
        'Les combats de test ne déclenchent jamais la mort définitive. Votre partie est remise comme avant ensuite (santé, or, butin, expérience, dé et groupe), sauf si vous gardez le résultat.',
  },
  'fight_lab_keep': {
    AppLanguage.en: 'Keep what happens',
    AppLanguage.fr: 'Garder le résultat',
  },
  'fight_lab_keep_desc': {
    AppLanguage.en:
        'Rewards, wounds and loot stay; your own die and party come back',
    AppLanguage.fr:
        'Récompenses, blessures et butin restent ; votre dé et votre groupe reviennent',
  },
  'fight_lab_full_health': {
    AppLanguage.en: 'Start at full health',
    AppLanguage.fr: 'Commencer en pleine santé',
  },
  'fight_lab_land_section': {
    AppLanguage.en: 'Land fight',
    AppLanguage.fr: 'Combat à terre',
  },
  'fight_lab_add_enemy': {
    AppLanguage.en: 'Add an enemy (up to 3)',
    AppLanguage.fr: 'Ajouter un ennemi (3 max.)',
  },
  'fight_lab_search_enemy': {
    AppLanguage.en: 'Search by name or id',
    AppLanguage.fr: 'Chercher par nom ou id',
  },
  'fight_lab_difficulty': {
    AppLanguage.en: 'Enemy strength (health and damage)',
    AppLanguage.fr: 'Force des ennemis (santé et dégâts)',
  },
  'fight_lab_affix': {
    AppLanguage.en: 'Affix on the first enemy',
    AppLanguage.fr: 'Trait du premier ennemi',
  },
  'fight_lab_none': {AppLanguage.en: 'None', AppLanguage.fr: 'Aucun'},
  'fight_lab_die': {
    AppLanguage.en: 'Your die for the test',
    AppLanguage.fr: 'Votre dé pour le test',
  },
  'fight_lab_equipped_die': {
    AppLanguage.en: 'Equipped',
    AppLanguage.fr: 'Équipé',
  },
  'fight_lab_solo': {
    AppLanguage.en: 'Fight alone',
    AppLanguage.fr: 'Combattre seul',
  },
  'fight_lab_party': {
    AppLanguage.en: 'Companions in the party',
    AppLanguage.fr: 'Compagnons dans le groupe',
  },
  'fight_lab_no_party': {
    AppLanguage.en: 'No companion in the party',
    AppLanguage.fr: 'Aucun compagnon dans le groupe',
  },
  'fight_lab_start_fight': {
    AppLanguage.en: 'Start the test fight',
    AppLanguage.fr: 'Lancer le combat de test',
  },
  'fight_lab_ship_section': {
    AppLanguage.en: 'Ship battle',
    AppLanguage.fr: 'Bataille navale',
  },
  'fight_lab_waters': {
    AppLanguage.en: 'Waters',
    AppLanguage.fr: 'Eaux',
  },
  'sea_waters_open': {
    AppLanguage.en: 'Open sea: long swells',
    AppLanguage.fr: 'Haute mer : longue houle',
  },
  'sea_waters_shallows': {
    AppLanguage.en: 'Shallows: clear water over sand',
    AppLanguage.fr: 'Hauts-fonds : eau claire sur le sable',
  },
  'sea_waters_drowned': {
    AppLanguage.en: 'Drowned waters: murk and kelp',
    AppLanguage.fr: 'Eaux noyées : vase et varech',
  },
  'sea_waters_abyss': {
    AppLanguage.en: 'The abyss: black water, void light',
    AppLanguage.fr: 'L\'abîme : eau noire, lueurs du vide',
  },
  'sea_waters_ashen': {
    AppLanguage.en: 'Ashen chop: grey waves, falling ash',
    AppLanguage.fr: 'Clapot de cendre : vagues grises, cendre qui tombe',
  },
  'fight_lab_enemy_ship': {
    AppLanguage.en: 'Enemy ship',
    AppLanguage.fr: 'Navire ennemi',
  },
  'fight_lab_all_parts': {
    AppLanguage.en: 'Pick the ship\'s parts',
    AppLanguage.fr: 'Choisir les pièces du bateau',
  },
  'fight_lab_all_parts_desc': {
    AppLanguage.en: 'Off: your boat as it is now',
    AppLanguage.fr: 'Désactivé : votre bateau tel qu’il est',
  },
  'fight_lab_start_ship': {
    AppLanguage.en: 'Start the test battle',
    AppLanguage.fr: 'Lancer la bataille de test',
  },
  'fight_lab_fight_won': {
    AppLanguage.en: 'Test fight won',
    AppLanguage.fr: 'Combat de test gagné',
  },
  'fight_lab_fight_lost': {
    AppLanguage.en: 'Test fight lost or left',
    AppLanguage.fr: 'Combat de test perdu ou quitté',
  },
  'fight_lab_ship_won': {
    AppLanguage.en: 'Test battle won',
    AppLanguage.fr: 'Bataille de test gagnée',
  },
  'fight_lab_ship_lost': {
    AppLanguage.en: 'Test battle lost',
    AppLanguage.fr: 'Bataille de test perdue',
  },
  'fight_lab_ship_fled': {
    AppLanguage.en: 'Test battle over: the Eel got away',
    AppLanguage.fr: 'Combat d\'essai terminé : l\'Eel s\'est échappé',
  },
  'fight_lab_ship_escaped': {
    AppLanguage.en: 'The enemy got away',
    AppLanguage.fr: 'L’ennemi s’est échappé',
  },
  'fight_lab_restored': {
    AppLanguage.en: 'game put back as it was',
    AppLanguage.fr: 'partie remise comme avant',
  },
  'fight_lab_kept': {
    AppLanguage.en: 'results kept',
    AppLanguage.fr: 'résultat conservé',
  },
  'menu_title': {
    AppLanguage.en: 'The Grey Shroud',
    AppLanguage.fr: 'Le Linceul gris',
  },
  'menu_subtitle': {
    AppLanguage.en: 'A tale of dice, debts and a shroud that should not exist',
    AppLanguage.fr:
        'Un récit de dés, de dettes et d’un linceul qui ne devrait pas exister',
  },
  'menu_continue': {AppLanguage.en: 'Continue', AppLanguage.fr: 'Continuer'},
  'menu_new_game': {
    AppLanguage.en: 'New Game',
    AppLanguage.fr: 'Nouvelle partie',
  },
  'menu_new_game_confirm_body': {
    AppLanguage.en:
        'Start a new story from character creation? The story in progress is replaced. Games saved in a slot are kept.',
    AppLanguage.fr:
        'Commencer une nouvelle histoire à la création du personnage ? L’histoire en cours est remplacée. Les parties sauvegardées dans un emplacement sont conservées.',
  },
  'menu_load': {AppLanguage.en: 'Load', AppLanguage.fr: 'Charger'},
  'menu_no_saves': {
    AppLanguage.en: 'No saved game yet',
    AppLanguage.fr: 'Aucune partie sauvegardée',
  },
  'menu_edit_mode': {
    AppLanguage.en: 'Edit Mode',
    AppLanguage.fr: 'Mode édition',
  },
  'menu_edit_mode_desc': {
    AppLanguage.en: 'Story editor, map, data and test tools',
    AppLanguage.fr: 'Éditeur du récit, carte, données et outils de test',
  },
  'menu_back_to_menu': {
    AppLanguage.en: 'Main menu',
    AppLanguage.fr: 'Menu principal',
  },
  'camp_tab_locked_body': {
    AppLanguage.en:
        'Your camp is set up on the shore in chapter 3. From then on it is your base: you rest there, choose who comes along, build, and set out to the towns and expeditions around it.',
    AppLanguage.fr:
        'Votre campement s’installe sur le rivage au chapitre 3. Il devient alors votre base : vous vous y reposez, choisissez qui vous accompagne, bâtissez et partez vers les villes et les expéditions alentour.',
  },
  'nav_map': {AppLanguage.en: 'Map', AppLanguage.fr: 'Carte'},
  'nav_generate': {AppLanguage.en: 'Generate', AppLanguage.fr: 'Générer'},
  'nav_data': {AppLanguage.en: 'Data', AppLanguage.fr: 'Données'},
  'title_story': {AppLanguage.en: 'Story', AppLanguage.fr: 'Histoire'},
  'title_play': {AppLanguage.en: 'Play', AppLanguage.fr: 'Jouer'},
  'world_map_title': {AppLanguage.en: 'Map', AppLanguage.fr: 'Carte'},
  'world_map_semantics': {
    AppLanguage.en: 'Chart of the places the story has reached',
    AppLanguage.fr: 'Carte des lieux atteints par l’histoire',
  },
  'world_map_hint': {
    AppLanguage.en:
        'Places appear as the story reaches them. Tap one to read about it. Pinch, double-tap or use + and − to zoom.',
    AppLanguage.fr:
        'Les lieux apparaissent à mesure que l’histoire les atteint. Touchez-en un pour en savoir plus. Pincez, touchez deux fois ou utilisez + et − pour zoomer.',
  },
  'world_map_shape': {
    AppLanguage.en: 'Map geography',
    AppLanguage.fr: 'Géographie de la carte',
  },
  'world_map_look': {
    AppLanguage.en: 'Map style',
    AppLanguage.fr: 'Style de carte',
  },
  'world_map_look_night': {AppLanguage.en: 'Night', AppLanguage.fr: 'Nuit'},
  'world_map_shape_continental': {
    AppLanguage.en: 'Continent',
    AppLanguage.fr: 'Continent'
  },
  'world_map_shape_archipelago': {
    AppLanguage.en: 'Archipelago',
    AppLanguage.fr: 'Archipel'
  },
  'world_map_shape_delta': {AppLanguage.en: 'Delta', AppLanguage.fr: 'Delta'},
  'world_map_look_parchment': {
    AppLanguage.en: 'Parchment',
    AppLanguage.fr: 'Parchemin',
  },
  'world_map_look_shroud': {
    AppLanguage.en: 'Shroud',
    AppLanguage.fr: 'Linceul',
  },
  'world_map_zoom_in': {AppLanguage.en: 'Zoom in', AppLanguage.fr: 'Zoomer'},
  'world_map_zoom_out': {
    AppLanguage.en: 'Zoom out',
    AppLanguage.fr: 'Dézoomer',
  },
  'world_map_centre': {
    AppLanguage.en: 'Centre on me',
    AppLanguage.fr: 'Centrer sur moi',
  },
  'world_map_replay': {
    AppLanguage.en: 'Replay the journey',
    AppLanguage.fr: 'Rejouer le voyage',
  },
  'world_map_all': {AppLanguage.en: 'All', AppLanguage.fr: 'Tout'},
  'world_map_chapter_short': {AppLanguage.en: 'Ch', AppLanguage.fr: 'Ch.'},
  'world_map_here': {
    AppLanguage.en: 'You are here',
    AppLanguage.fr: 'Vous êtes ici',
  },
  'world_map_scenes_read': {
    AppLanguage.en: 'Scenes read',
    AppLanguage.fr: 'Scènes lues',
  },
  'world_map_fights': {
    AppLanguage.en: 'Fights here',
    AppLanguage.fr: 'Combats ici',
  },
  'world_map_back': {AppLanguage.en: 'Back', AppLanguage.fr: 'Retour'},
  'world_map_next': {AppLanguage.en: 'Next', AppLanguage.fr: 'Suite'},
  'world_map_start': {AppLanguage.en: 'the start', AppLanguage.fr: 'le début'},
  'world_map_end': {AppLanguage.en: 'the end', AppLanguage.fr: 'la fin'},
  'world_map_first_ally': {
    AppLanguage.en: 'Your first ally',
    AppLanguage.fr: 'Votre premier allié',
  },
  'title_map': {
    AppLanguage.en: 'Story Map',
    AppLanguage.fr: "Carte de l'histoire"
  },
  'title_generate': {
    AppLanguage.en: 'AI Generator',
    AppLanguage.fr: 'Générateur IA'
  },
  'title_data': {AppLanguage.en: 'Game Data', AppLanguage.fr: 'Données du jeu'},
  'settings': {AppLanguage.en: 'Settings', AppLanguage.fr: 'Paramètres'},
  'back': {AppLanguage.en: 'Back', AppLanguage.fr: 'Retour'},
  'node': {AppLanguage.en: 'Node', AppLanguage.fr: 'Nœud'},
  'detour': {AppLanguage.en: 'Detour', AppLanguage.fr: 'Détour'},
  'detour_on_the_way': {
    AppLanguage.en: 'Detour on your way:',
    AppLanguage.fr: 'Détour en chemin :',
  },
  'detour_resumes': {
    AppLanguage.en:
        'Something met on the road. The story picks up where you were going once it is dealt with.',
    AppLanguage.fr:
        'Une rencontre en chemin. Le récit reprend là où vous alliez une fois ceci réglé.',
  },
  'choice_fight_roster': {
    AppLanguage.en: 'Fight: {roster}',
    AppLanguage.fr: 'Combat : {roster}',
  },
  'restart_story': {
    AppLanguage.en: 'Restart Story',
    AppLanguage.fr: "Recommencer l'histoire"
  },
  'the_end': {AppLanguage.en: 'The End', AppLanguage.fr: 'Fin'},
  'branch_end_message': {
    AppLanguage.en: 'You have reached the end of this branch.',
    AppLanguage.fr: 'Vous avez atteint la fin de cette branche.',
  },
  'trail_cold_title': {
    AppLanguage.en: 'The trail goes cold',
    AppLanguage.fr: 'La piste se perd',
  },
  'trail_cold_message': {
    AppLanguage.en: 'This path leads nowhere in the current story data.',
    AppLanguage.fr: "Ce chemin ne mène nulle part dans les données actuelles.",
  },
  'quests': {AppLanguage.en: 'Quests', AppLanguage.fr: 'Quêtes'},
  'shops': {AppLanguage.en: 'Shops', AppLanguage.fr: 'Boutiques'},
  'bestiary': {AppLanguage.en: 'Bestiary', AppLanguage.fr: 'Bestiaire'},
  'npcs_section': {AppLanguage.en: 'NPCs', AppLanguage.fr: 'PNJ'},
  'character': {AppLanguage.en: 'Character', AppLanguage.fr: 'Personnage'},
  'language': {AppLanguage.en: 'Language', AppLanguage.fr: 'Langue'},
  'legend_title': {AppLanguage.en: 'Legend', AppLanguage.fr: 'Légende'},
  'node_kind_camp': {
    AppLanguage.en: 'Camp',
    AppLanguage.fr: 'Camp',
  },
  'node_kind_character_creation': {
    AppLanguage.en: 'Character Creation',
    AppLanguage.fr: 'Création de personnage',
  },
  'node_kind_combat': {AppLanguage.en: 'Combat', AppLanguage.fr: 'Combat'},
  'node_kind_shop': {AppLanguage.en: 'Shop', AppLanguage.fr: 'Boutique'},
  'node_kind_quest': {AppLanguage.en: 'Quest', AppLanguage.fr: 'Quête'},
  'node_kind_companion_quest': {
    AppLanguage.en: 'Companion Quest',
    AppLanguage.fr: 'Quête de compagnon',
  },
  'node_kind_generic': {AppLanguage.en: 'Generic', AppLanguage.fr: 'Générique'},
  'chapter_band_prefix': {
    AppLanguage.en: 'Chapter',
    AppLanguage.fr: 'Chapitre'
  },
  'chapter_band_prologue': {
    AppLanguage.en: 'Prologue',
    AppLanguage.fr: 'Prologue'
  },
  'main_story_beat': {
    AppLanguage.en: 'Main Story Beat',
    AppLanguage.fr: "Étape principale de l'histoire",
  },
  'undiscovered_node_legend': {
    AppLanguage.en: 'Undiscovered',
    AppLanguage.fr: 'Non découvert',
  },
  'node_not_yet_discovered': {
    AppLanguage.en: "You haven't reached this part of the story yet.",
    AppLanguage.fr:
        "Vous n'avez pas encore atteint cette partie de l'histoire.",
  },
  'main_beat_chip': {
    AppLanguage.en: 'Main Beat',
    AppLanguage.fr: 'Étape principale'
  },
  'requires_label': {
    AppLanguage.en: 'Requires:',
    AppLanguage.fr: 'Nécessite :'
  },
  'choices_label': {AppLanguage.en: 'Choices', AppLanguage.fr: 'Choix'},
  'no_choices_ending': {
    AppLanguage.en: '(none — this is an ending)',
    AppLanguage.fr: '(aucun — ceci est une fin)',
  },
  'jump_to_node': {
    AppLanguage.en: 'Jump to this node',
    AppLanguage.fr: 'Aller à ce nœud'
  },
  'autoplay_to_node': {
    AppLanguage.en: 'Autoplay to this node',
    AppLanguage.fr: 'Jouer automatiquement jusqu\'à ce nœud',
  },
  'autoplay_running': {
    AppLanguage.en: 'Playing ahead…',
    AppLanguage.fr: 'Avancement automatique…',
  },
  'autoplay_already_there': {
    AppLanguage.en: 'Already there.',
    AppLanguage.fr: 'Déjà arrivé.',
  },
  'autoplay_no_path': {
    AppLanguage.en: 'No forward path to that node from here.',
    AppLanguage.fr: "Aucun chemin possible jusqu'à ce nœud depuis ici.",
  },
  'autoplay_step_cap_reached': {
    AppLanguage.en: 'Stopped after many steps without reaching the chapter — '
        'progress made so far is still saved.',
    AppLanguage.fr:
        "Arrêt après de nombreuses étapes sans atteindre le chapitre — "
            'la progression réalisée est tout de même conservée.',
  },
  'autoplay_stuck_prefix': {
    AppLanguage.en: 'Stuck — couldn\'t win the fight against',
    AppLanguage.fr: 'Bloqué — impossible de gagner le combat contre',
  },
  'autoplay_reached_prefix': {
    AppLanguage.en: 'Reached the target.',
    AppLanguage.fr: 'Cible atteinte.',
  },
  'autoplay_steps_suffix': {
    AppLanguage.en: 'steps applied',
    AppLanguage.fr: 'étapes appliquées',
  },
  'autoplay_attempt_label': {
    AppLanguage.en: 'attempt',
    AppLanguage.fr: 'tentative',
  },
  'autoplay_forced_suffix': {
    AppLanguage.en: 'fights won by force',
    AppLanguage.fr: 'combats gagnés d’office',
  },
  'end_label': {AppLanguage.en: 'End', AppLanguage.fr: 'Fin'},
  'tap_to_filter': {
    AppLanguage.en: 'Tap a legend row to hide/show that node type',
    AppLanguage.fr: "Touchez une ligne pour afficher/masquer ce type de nœud",
  },
  'edit_node': {
    AppLanguage.en: 'Edit node',
    AppLanguage.fr: 'Modifier le nœud'
  },
  'save': {AppLanguage.en: 'Save', AppLanguage.fr: 'Enregistrer'},
  'description_en': {
    AppLanguage.en: 'Description (English)',
    AppLanguage.fr: 'Description (anglais)'
  },
  'description_fr_label': {
    AppLanguage.en: 'Description (French)',
    AppLanguage.fr: 'Description (français)',
  },
  'choice_n': {AppLanguage.en: 'Choice', AppLanguage.fr: 'Choix'},
  'choice_text_en': {
    AppLanguage.en: 'Choice text (English)',
    AppLanguage.fr: 'Texte du choix (anglais)'
  },
  'choice_text_fr': {
    AppLanguage.en: 'Choice text (French)',
    AppLanguage.fr: 'Texte du choix (français)'
  },
  'destination_node': {
    AppLanguage.en: 'Destination node',
    AppLanguage.fr: 'Nœud de destination'
  },
  'add_choice': {
    AppLanguage.en: 'Add choice',
    AppLanguage.fr: 'Ajouter un choix'
  },
  'remove_choice': {
    AppLanguage.en: 'Remove choice',
    AppLanguage.fr: 'Supprimer le choix'
  },
  'advanced_options': {
    AppLanguage.en: 'Advanced options',
    AppLanguage.fr: 'Options avancées'
  },
  'requirements': {
    AppLanguage.en: 'Requirements to view this node',
    AppLanguage.fr: 'Conditions pour voir ce nœud'
  },
  'required_gold': {
    AppLanguage.en: 'Required gold',
    AppLanguage.fr: "Or requis"
  },
  'required_alignment': {
    AppLanguage.en: 'Required alignment score (minimum)',
    AppLanguage.fr: "Score d'alignement requis (minimum)",
  },
  'required_alignment_max': {
    AppLanguage.en: 'Required alignment score (maximum)',
    AppLanguage.fr: "Score d'alignement requis (maximum)",
  },
  'required_flags': {
    AppLanguage.en: 'Required flags (comma-separated)',
    AppLanguage.fr: 'Drapeaux requis (séparés par des virgules)',
  },
  'required_charisma': {
    AppLanguage.en: 'Required charisma (minimum)',
    AppLanguage.fr: 'Charisme requis (minimum)',
  },
  'ability_check_section': {
    AppLanguage.en:
        'Ability Check (rolled attempt, not a hard gate — see Charisma above)',
    AppLanguage.fr:
        'Jet de caractéristique (tentative, pas un verrou strict — voir Charisme ci-dessus)',
  },
  'check_ability': {
    AppLanguage.en: 'Ability to check',
    AppLanguage.fr: 'Caractéristique testée',
  },
  'challenge_successes_needed': {
    AppLanguage.en: 'Skill challenge: successes needed',
    AppLanguage.fr: 'Épreuve de compétence : réussites requises',
  },
  'challenge_max_failures': {
    AppLanguage.en: 'Skill challenge: max failures',
    AppLanguage.fr: 'Épreuve de compétence : échecs max.',
  },
  'challenge_hint': {
    AppLanguage.en:
        'Leave both blank for an ordinary single-roll check. Set both to turn '
            'this into a multi-round skill challenge instead.',
    AppLanguage.fr:
        'Laissez les deux champs vides pour un simple jet unique. Remplissez '
            'les deux pour en faire une épreuve de compétence à plusieurs manches.',
  },
  'check_dc': {
    AppLanguage.en: 'Difficulty Class (DC)',
    AppLanguage.fr: 'Classe de Difficulté (DD)',
  },
  'lose_destination_node': {
    AppLanguage.en:
        'Defeat Destination Node (a lost fight goes here instead of retrying)',
    AppLanguage.fr:
        'Nœud de destination en cas de défaite (un combat perdu y mène au lieu d\'être rejoué)',
  },
  'fail_destination_node': {
    AppLanguage.en: 'Fail Destination Node (empty = same node, no reward)',
    AppLanguage.fr:
        'Nœud de destination en cas d\'échec (vide = même nœud, sans récompense)',
  },
  'none_option': {AppLanguage.en: 'None', AppLanguage.fr: 'Aucun(e)'},
  'check_label': {AppLanguage.en: 'check', AppLanguage.fr: 'jet de'},
  'vs_dc_label': {AppLanguage.en: 'vs DC', AppLanguage.fr: 'contre DD'},
  'ability_check_success': {
    AppLanguage.en: 'Success!',
    AppLanguage.fr: 'Réussite !',
  },
  'ability_check_fail': {
    AppLanguage.en: 'Failure.',
    AppLanguage.fr: 'Échec.',
  },
  'skill_challenge_title': {
    AppLanguage.en: 'Skill Challenge',
    AppLanguage.fr: 'Épreuve de compétence',
  },
  'skill_challenge_begin': {
    AppLanguage.en: 'Begin',
    AppLanguage.fr: 'Commencer',
  },
  'skill_challenge_continue': {
    AppLanguage.en: 'Continue',
    AppLanguage.fr: 'Continuer',
  },
  'skill_challenge_round_label': {
    AppLanguage.en: 'Round',
    AppLanguage.fr: 'Manche',
  },
  'skill_challenge_successes_label': {
    AppLanguage.en: 'Successes',
    AppLanguage.fr: 'Réussites',
  },
  'skill_challenge_failures_label': {
    AppLanguage.en: 'Failures',
    AppLanguage.fr: 'Échecs',
  },
  'skill_challenge_success_banner': {
    AppLanguage.en: 'You pulled it off.',
    AppLanguage.fr: 'Vous y êtes arrivé.',
  },
  'skill_challenge_fail_banner': {
    AppLanguage.en: 'Not this time.',
    AppLanguage.fr: 'Pas cette fois.',
  },
  'node_saved': {
    AppLanguage.en: 'Node saved.',
    AppLanguage.fr: 'Nœud enregistré.'
  },
  'reset_story': {
    AppLanguage.en: 'Reset story to defaults',
    AppLanguage.fr: "Réinitialiser l'histoire"
  },
  'reset_story_confirm': {
    AppLanguage.en:
        'This discards all edits to the story text and reloads the bundled version.',
    AppLanguage.fr:
        "Ceci annule toutes les modifications du texte de l'histoire et recharge la version d'origine.",
  },
  'cancel': {AppLanguage.en: 'Cancel', AppLanguage.fr: 'Annuler'},
  'reset': {AppLanguage.en: 'Reset', AppLanguage.fr: 'Réinitialiser'},
  'save_game_tooltip': {
    AppLanguage.en: 'Save game',
    AppLanguage.fr: 'Sauvegarder la partie'
  },
  'load_game_tooltip': {
    AppLanguage.en: 'Load game',
    AppLanguage.fr: 'Charger la partie'
  },
  'game_saved_message': {
    AppLanguage.en: 'Game saved.',
    AppLanguage.fr: 'Partie sauvegardée.'
  },
  'session_unreadable_notice': {
    AppLanguage.en:
        'Your last session could not be read, so a new one started. The old save was kept aside, untouched.',
    AppLanguage.fr:
        'Votre dernière partie n’a pas pu être lue : une nouvelle a commencé. L’ancienne sauvegarde a été mise de côté, intacte.',
  },
  'hub_done_count': {
    AppLanguage.en: '{done}/{total} done',
    AppLanguage.fr: '{done}/{total} faits',
  },
  'journal_title': {
    AppLanguage.en: 'The story so far',
    AppLanguage.fr: 'L’histoire jusqu’ici',
  },
  'journal_empty': {
    AppLanguage.en: 'Nothing written yet.',
    AppLanguage.fr: 'Rien d’écrit pour l’instant.',
  },
  'journal_you_are_here': {
    AppLanguage.en: 'You are here.',
    AppLanguage.fr: 'Vous êtes ici.',
  },
  'previously_title': {
    AppLanguage.en: 'Previously…',
    AppLanguage.fr: 'Précédemment…',
  },
  'previously_quests_label': {
    AppLanguage.en: 'Still on your mind',
    AppLanguage.fr: 'Ce qui vous occupe encore',
  },
  'previously_continue_button': {
    AppLanguage.en: 'Go on',
    AppLanguage.fr: 'Reprendre',
  },
  'sell_title': {AppLanguage.en: 'Sell', AppLanguage.fr: 'Vendre'},
  'sell_button': {AppLanguage.en: 'Sell', AppLanguage.fr: 'Vendre'},
  'sell_nothing': {
    AppLanguage.en: 'Nothing in the pack to sell.',
    AppLanguage.fr: 'Rien à vendre dans le sac.',
  },
  'sell_worn_note': {
    AppLanguage.en: 'Worn: take it off to sell it',
    AppLanguage.fr: 'Porté : retirez-le pour le vendre',
  },
  'sold_prefix': {AppLanguage.en: 'Sold', AppLanguage.fr: 'Vendu :'},
  'forge_title': {AppLanguage.en: 'Forge', AppLanguage.fr: 'Forge'},
  'forge_button': {AppLanguage.en: 'Forge', AppLanguage.fr: 'Forger'},
  'forged_prefix': {AppLanguage.en: 'Forged', AppLanguage.fr: 'Forgé :'},
  'forge_needs_label': {AppLanguage.en: 'Needs', AppLanguage.fr: 'Il faut'},
  'forge_hint': {
    AppLanguage.en:
        'Iron ore comes off Inquisition soldiers, the dock overseer, wisps, the iron golem and the dead of the catacombs.',
    AppLanguage.fr:
        'Le minerai de fer se prend sur les soldats de l’Inquisition, le contremaître des docks, les feux follets, le golem de fer et les morts des catacombes.',
  },
  'save_slots_save_title': {
    AppLanguage.en: 'Save to a slot',
    AppLanguage.fr: 'Sauvegarder dans un emplacement',
  },
  'save_slots_load_title': {
    AppLanguage.en: 'Load a saved game',
    AppLanguage.fr: 'Charger une sauvegarde',
  },
  'save_slot_label': {AppLanguage.en: 'Slot', AppLanguage.fr: 'Emplacement'},
  'save_slot_empty': {AppLanguage.en: 'Empty', AppLanguage.fr: 'Vide'},
  'save_slot_overwrite_title': {
    AppLanguage.en: 'Save over this game?',
    AppLanguage.fr: 'Écraser cette sauvegarde ?',
  },
  'save_slot_overwrite_button': {
    AppLanguage.en: 'Save over it',
    AppLanguage.fr: 'Écraser',
  },
  'save_slot_delete_tooltip': {
    AppLanguage.en: 'Delete this save',
    AppLanguage.fr: 'Supprimer cette sauvegarde',
  },
  'save_slot_unreadable': {
    AppLanguage.en: 'This save could not be read. It was left as it is.',
    AppLanguage.fr:
        'Cette sauvegarde est illisible. Elle a été laissée telle quelle.',
  },
  'ironman_note': {
    AppLanguage.en:
        'Ironman: with permadeath on, a saved game can’t be loaded, and a death deletes every save.',
    AppLanguage.fr:
        'Ironman : avec la mort définitive, une sauvegarde ne peut pas être chargée, et une mort les efface toutes.',
  },
  'ironman_load_tooltip': {
    AppLanguage.en: 'Ironman: no loading while permadeath is on',
    AppLanguage.fr: 'Ironman : pas de chargement avec la mort définitive',
  },
  'game_loaded_message': {
    AppLanguage.en: 'Game loaded.',
    AppLanguage.fr: 'Partie chargée.'
  },
  'close_legend': {
    AppLanguage.en: 'Close legend',
    AppLanguage.fr: 'Fermer la légende'
  },
  'show_legend': {
    AppLanguage.en: 'Show legend',
    AppLanguage.fr: 'Afficher la légende'
  },
  'hide_companion': {
    AppLanguage.en: 'Hide companion',
    AppLanguage.fr: 'Masquer le compagnon'
  },
  'show_companion': {
    AppLanguage.en: 'Show companion',
    AppLanguage.fr: 'Afficher le compagnon'
  },
  'map_theme_section': {AppLanguage.en: 'Map', AppLanguage.fr: 'Carte'},
  'map_theme_description': {
    AppLanguage.en:
        'The 5 main beats per chapter never change. This picks the flavor of the random '
            'encounters, shops, and quests generated between them. Auto matches each scene\'s '
            'own setting automatically; pick a fixed theme to override every chapter with it.',
    AppLanguage.fr:
        'Les 5 étapes principales de chaque chapitre ne changent jamais. Ceci choisit '
            "l'ambiance des rencontres, boutiques et quêtes générées entre elles. Le mode "
            'automatique correspond au décor propre à chaque scène ; choisissez une ambiance '
            'fixe pour l\'imposer à tous les chapitres.',
  },
  'map_theme_auto_label': {
    AppLanguage.en: 'Auto (match story)',
    AppLanguage.fr: 'Automatique (selon le récit)',
  },
  'map_theme_ashen_streets': {
    AppLanguage.en: 'Ashen Streets',
    AppLanguage.fr: 'Rues de Cendre',
  },
  'map_theme_salt_roads': {
    AppLanguage.en: 'Salt Roads',
    AppLanguage.fr: 'Routes du Sel'
  },
  'map_theme_hollow_reaches': {
    AppLanguage.en: 'Hollow Reaches',
    AppLanguage.fr: 'Étendues Creuses',
  },
  'map_theme_wilds_beyond': {
    AppLanguage.en: 'Wilds Beyond',
    AppLanguage.fr: 'Terres Sauvages'
  },
  'gold_mod': {AppLanguage.en: 'Gold mod', AppLanguage.fr: "Modif. d'or"},
  'alignment_mod': {
    AppLanguage.en: 'Alignment mod',
    AppLanguage.fr: "Modif. d'alignement"
  },
  'heal_amount': {AppLanguage.en: 'Heal amount', AppLanguage.fr: 'Soins'},
  'flags_to_add': {
    AppLanguage.en: 'Flags to add (comma-separated)',
    AppLanguage.fr: 'Drapeaux à ajouter (séparés par des virgules)',
  },
  'quest_id_to_progress': {
    AppLanguage.en: 'Quest ID to progress',
    AppLanguage.fr: 'ID de quête à faire progresser',
  },
  'trigger_enemy_id': {
    AppLanguage.en: 'Trigger enemy ID',
    AppLanguage.fr: "ID d'ennemi déclenché"
  },
  'trigger_enemy_ids': {
    AppLanguage.en: 'Trigger enemy IDs (pack, comma-separated)',
    AppLanguage.fr: "IDs d'ennemis déclenchés (groupe, séparés par virgule)"
  },
  'trigger_enemy_ids_helper': {
    AppLanguage.en:
        'Overrides Trigger enemy ID above when set — a 2-3 enemy pack fight. '
            'Never include a tuned boss/unique enemy here.',
    AppLanguage.fr:
        "Remplace l'ID d'ennemi déclenché ci-dessus si renseigné — un combat "
            "de groupe de 2 à 3 ennemis. N'incluez jamais un boss ou un "
            "ennemi unique ici.",
  },
  'unlock_shop_id': {
    AppLanguage.en: 'Unlock shop ID',
    AppLanguage.fr: 'ID de boutique débloquée'
  },
  'unlock_quest_id': {
    AppLanguage.en: 'Unlock quest ID',
    AppLanguage.fr: 'ID de quête débloquée'
  },
  'locked_text': {
    AppLanguage.en: 'Locked text (English, shown when requirements unmet)',
    AppLanguage.fr:
        'Texte verrouillé (anglais, affiché si conditions non remplies)',
  },
  'locked_text_fr': {
    AppLanguage.en: 'Locked text (French)',
    AppLanguage.fr: 'Texte verrouillé (français)',
  },
  'opens_character_creation': {
    AppLanguage.en: 'Opens character creation',
    AppLanguage.fr: 'Ouvre la création de personnage',
  },
  'failed_to_load_story': {
    AppLanguage.en: 'Failed to load story',
    AppLanguage.fr: "Échec du chargement de l'histoire",
  },
  'player_session': {
    AppLanguage.en: 'Player Session',
    AppLanguage.fr: 'Session du joueur'
  },
  'failed_to_load_quests': {
    AppLanguage.en: 'Failed to load quests',
    AppLanguage.fr: 'Échec du chargement des quêtes',
  },
  'failed_to_load_shops': {
    AppLanguage.en: 'Failed to load shops',
    AppLanguage.fr: 'Échec du chargement des boutiques',
  },
  'failed_to_load_enemies': {
    AppLanguage.en: 'Failed to load enemies',
    AppLanguage.fr: 'Échec du chargement des ennemis',
  },
  'failed_to_load_npcs': {
    AppLanguage.en: 'Failed to load NPCs',
    AppLanguage.fr: 'Échec du chargement des PNJ',
  },
  'no_quests_defined': {
    AppLanguage.en: 'No quests defined yet.',
    AppLanguage.fr: 'Aucune quête définie pour le moment.',
  },
  'no_shops_defined': {
    AppLanguage.en: 'No shops defined yet.',
    AppLanguage.fr: 'Aucune boutique définie pour le moment.',
  },
  'no_enemies_defined': {
    AppLanguage.en: 'No enemies defined yet.',
    AppLanguage.fr: 'Aucun ennemi défini pour le moment.',
  },
  'no_npcs_defined': {
    AppLanguage.en: 'No NPCs defined yet.',
    AppLanguage.fr: 'Aucun PNJ défini pour le moment.',
  },
  'status_completed': {AppLanguage.en: 'Completed', AppLanguage.fr: 'Terminée'},
  'status_active': {AppLanguage.en: 'Active', AppLanguage.fr: 'En cours'},
  'status_undiscovered': {
    AppLanguage.en: 'Undiscovered',
    AppLanguage.fr: 'Non découverte'
  },
  'status_locked': {AppLanguage.en: 'Locked', AppLanguage.fr: 'Verrouillée'},
  'status_available': {
    AppLanguage.en: 'Available',
    AppLanguage.fr: 'Disponible'
  },
  'quest_complete_prefix': {
    AppLanguage.en: 'Quest complete',
    AppLanguage.fr: 'Quête terminée',
  },
  'quest_accepted_prefix': {
    AppLanguage.en: 'Quest accepted',
    AppLanguage.fr: 'Quête acceptée',
  },
  'complete': {AppLanguage.en: 'Complete', AppLanguage.fr: 'Terminer'},
  'accept': {AppLanguage.en: 'Accept', AppLanguage.fr: 'Accepter'},
  'status_label': {AppLanguage.en: 'Status', AppLanguage.fr: 'Statut'},
  'shop_undiscovered': {
    AppLanguage.en: 'Undiscovered — find this shop during the story.',
    AppLanguage.fr:
        "Non découverte — trouvez cette boutique au cours de l'histoire.",
  },
  'shop_left_behind': {
    AppLanguage.en: 'Unavailable — return to the node that unlocked it.',
    AppLanguage.fr: 'Indisponible — retournez au nœud qui l\'a débloquée.',
  },
  'not_yet_encountered': {
    AppLanguage.en: 'Not yet encountered.',
    AppLanguage.fr: 'Pas encore rencontré.',
  },
  'npc_not_yet_met': {
    AppLanguage.en: 'Not yet met — find them during the story.',
    AppLanguage.fr:
        'Pas encore rencontré — trouvez-les au cours de l\'histoire.',
  },
  'npc_talked_message': {
    AppLanguage.en: 'Conversation recorded.',
    AppLanguage.fr: 'Conversation enregistrée.',
  },
  'npc_already_talked': {
    AppLanguage.en: 'Already talked',
    AppLanguage.fr: 'Déjà discuté',
  },
  'talk_button': {AppLanguage.en: 'Talk', AppLanguage.fr: 'Discuter'},
  'hp_label': {AppLanguage.en: 'HP', AppLanguage.fr: 'PV'},
  'damage_label': {AppLanguage.en: 'Damage', AppLanguage.fr: 'Dégâts'},
  'luck_label': {AppLanguage.en: 'Luck', AppLanguage.fr: 'Chance'},
  'strength_abbr': {AppLanguage.en: 'STR', AppLanguage.fr: 'FOR'},
  'dexterity_abbr': {AppLanguage.en: 'DEX', AppLanguage.fr: 'DEX'},
  'constitution_abbr': {AppLanguage.en: 'CON', AppLanguage.fr: 'CON'},
  'intelligence_abbr': {AppLanguage.en: 'INT', AppLanguage.fr: 'INT'},
  'wisdom_abbr': {AppLanguage.en: 'WIS', AppLanguage.fr: 'SAG'},
  'charisma_abbr': {AppLanguage.en: 'CHA', AppLanguage.fr: 'CHA'},
  'luck_abbr': {AppLanguage.en: 'LCK', AppLanguage.fr: 'CHN'},
  'perception_abbr': {AppLanguage.en: 'PER', AppLanguage.fr: 'PER'},
  'charisma_label': {AppLanguage.en: 'Charisma', AppLanguage.fr: 'Charisme'},
  'strength_label': {AppLanguage.en: 'Strength', AppLanguage.fr: 'Force'},
  'dexterity_label': {AppLanguage.en: 'Dexterity', AppLanguage.fr: 'Dextérité'},
  'constitution_label': {
    AppLanguage.en: 'Constitution',
    AppLanguage.fr: 'Constitution',
  },
  'intelligence_label': {
    AppLanguage.en: 'Intelligence',
    AppLanguage.fr: 'Intelligence',
  },
  'wisdom_label': {AppLanguage.en: 'Wisdom', AppLanguage.fr: 'Sagesse'},
  'perception_label': {
    AppLanguage.en: 'Perception',
    AppLanguage.fr: 'Perspicacité',
  },
  'base_damage_desc': {
    AppLanguage.en: 'Added to every attack you land in combat.',
    AppLanguage.fr: 'S\'ajoute à chaque attaque que vous portez en combat.',
  },
  'base_armor_desc': {
    AppLanguage.en: 'Reduces the damage you take from enemy attacks.',
    AppLanguage.fr: 'Réduit les dégâts subis lors des attaques ennemies.',
  },
  'max_health_desc': {
    AppLanguage.en: 'How much damage you can take before you go down.',
    AppLanguage.fr:
        'La quantité de dégâts que vous pouvez encaisser avant de tomber.',
  },
  'luck_desc': {
    AppLanguage.en: 'Raises your chance of a critical hit, and your odds of '
        'finding better loot after a fight. Every 3 points of the party\'s '
        'best Luck also give a nudge per fight, up to 3: long-press a '
        'landed die to turn it to its opposite face.',
    AppLanguage.fr:
        'Augmente vos chances de coup critique, et de trouver un meilleur '
            'butin après un combat. Tous les 3 points de la meilleure Chance '
            'du groupe donnent aussi un coup de pouce par combat, jusqu\'à '
            '3 : un appui long sur un dé tombé le tourne sur sa face opposée.',
  },
  'charisma_desc': {
    AppLanguage.en: 'Opens persuasion-gated dialogue and story choices.',
    AppLanguage.fr:
        'Débloque des dialogues et choix narratifs liés à la persuasion.',
  },
  'strength_desc': {
    AppLanguage.en: 'Backs Strength checks on story choices — forcing your way '
        'through, moving what won\'t move. Also boosts damage on '
        'Strength-scaling weapons like swords and spears, and unlocks the '
        'heaviest ones.',
    AppLanguage.fr:
        'Intervient dans les jets de Force des choix narratifs — forcer '
            'un passage, déplacer ce qui ne bouge pas. Augmente aussi les '
            'dégâts des armes liées à la Force (épées, lances) et débloque '
            'les plus lourdes.',
  },
  'dexterity_desc': {
    AppLanguage.en: 'Backs Dexterity checks on story choices — picking locks, '
        'staying light on your feet. Also boosts damage on Dexterity-scaling '
        'weapons like daggers.',
    AppLanguage.fr:
        'Intervient dans les jets de Dextérité des choix narratifs — '
            'crocheter une serrure, rester agile. Augmente aussi les dégâts '
            'des armes liées à la Dextérité (dagues).',
  },
  'constitution_desc': {
    AppLanguage.en:
        'Backs Constitution checks on story choices — enduring what '
            'would stop most people. Also boosts the armor of '
            'Constitution-scaling shields, and unlocks the heaviest gear.',
    AppLanguage.fr:
        'Intervient dans les jets de Constitution des choix narratifs — '
            'endurer ce qui arrêterait la plupart des gens. Augmente aussi '
            'l\'armure des boucliers liés à la Constitution et débloque '
            'l\'équipement le plus lourd.',
  },
  'intelligence_desc': {
    AppLanguage.en:
        'Backs Intelligence checks on story choices — puzzling things '
            'out, reading what others missed. Also boosts damage on '
            'Intelligence-scaling weapons like staves.',
    AppLanguage.fr:
        'Intervient dans les jets d\'Intelligence des choix narratifs — '
            'comprendre ce que d\'autres ont manqué. Augmente aussi les '
            'dégâts des armes liées à l\'Intelligence (bâtons).',
  },
  'wisdom_desc': {
    AppLanguage.en:
        'Backs Wisdom checks on story choices — reading people, sensing '
            'what\'s really going on. In a fight, it also strengthens every '
            'point you heal, adds 1 mana to every Mana face and mana skill '
            'per 3 Wisdom, and shortens how long Poison, Stun, or Weaken '
            'holds on to you.',
    AppLanguage.fr:
        'Intervient dans les jets de Sagesse des choix narratifs — lire '
            'les gens, sentir ce qui se trame vraiment. En combat, elle '
            'renforce aussi chaque soin, ajoute 1 point de mana à chaque '
            'face Mana et compétence de mana tous les 3 points de Sagesse, '
            'et raccourcit la durée du Poison, de l\'Étourdissement ou de '
            'l\'Affaiblissement.',
  },
  'perception_desc': {
    AppLanguage.en:
        'Lets you read an enemy\'s next move before it happens — who '
            'they\'ll target, and (with enough Perception relative to '
            'their Guile) what kind of move it is or exactly what it '
            'does.',
    AppLanguage.fr:
        'Vous permet de lire le prochain coup d\'un ennemi avant qu\'il '
            'ne survienne — qui il va viser, et (avec assez de '
            'Perspicacité face à sa Ruse) le type de coup ou exactement '
            'ce qu\'il fait.',
  },
  'fight': {AppLanguage.en: 'Fight', AppLanguage.fr: 'Combattre'},
  'gold_label': {AppLanguage.en: 'gold', AppLanguage.fr: 'or'},
  'level_abbrev': {AppLanguage.en: 'Lvl', AppLanguage.fr: 'Niv.'},
  'item_count_label': {AppLanguage.en: 'item(s)', AppLanguage.fr: 'objet(s)'},
  'skill_pt_label': {
    AppLanguage.en: 'skill pt(s)',
    AppLanguage.fr: 'pt(s) de compétence'
  },
  'stat_pt_label': {
    AppLanguage.en: 'stat pt(s)',
    AppLanguage.fr: 'pt(s) de statistique'
  },
  'char_not_set': {
    AppLanguage.en: 'Not set — tap to create a character',
    AppLanguage.fr: 'Non défini — touchez pour créer un personnage',
  },
  'race_profession_title': {
    AppLanguage.en: 'Race & Profession',
    AppLanguage.fr: 'Race et profession',
  },
  'inventory_equipment': {
    AppLanguage.en: 'Inventory & Equipment',
    AppLanguage.fr: 'Inventaire et équipement',
  },
  'skills': {AppLanguage.en: 'Skills', AppLanguage.fr: 'Compétences'},
  'level_up': {AppLanguage.en: 'Level Up', AppLanguage.fr: 'Monter de niveau'},
  'dice_loadout': {
    AppLanguage.en: 'Dice Loadout',
    AppLanguage.fr: 'Équipement de dés'
  },
  'failed_to_load_dice': {
    AppLanguage.en: 'Failed to load dice',
    AppLanguage.fr: 'Échec du chargement des dés',
  },
  'failed_to_load_items': {
    AppLanguage.en: 'Failed to load items',
    AppLanguage.fr: 'Échec du chargement des objets',
  },
  'equipment_section': {
    AppLanguage.en: 'Equipment',
    AppLanguage.fr: 'Équipement'
  },
  'dice_label': {AppLanguage.en: 'Dice', AppLanguage.fr: 'Dé'},
  'wisdom_mana_bonus_line': {
    AppLanguage.en: 'Wisdom {wis}: +{n} mana on every Mana face and mana '
        'skill (1 more per 3 Wisdom).',
    AppLanguage.fr: 'Sagesse {wis} : +{n} mana sur chaque face Mana et '
        'compétence de mana (1 de plus tous les 3 points).',
  },
  'quest_goal_ready': {
    AppLanguage.en: 'Goal reached: turn it in',
    AppLanguage.fr: 'Objectif atteint : à rendre',
  },
  'quest_goal_prefix': {AppLanguage.en: 'Goal:', AppLanguage.fr: 'Objectif :'},
  'quest_updated_label': {
    AppLanguage.en: 'Updated',
    AppLanguage.fr: 'Mis à jour',
  },
  'quest_turn_in_button': {AppLanguage.en: 'Turn in', AppLanguage.fr: 'Rendre'},
  'quest_main': {
    AppLanguage.en: 'Main quest',
    AppLanguage.fr: 'Quête principale'
  },
  'quest_side': {
    AppLanguage.en: 'Side quest',
    AppLanguage.fr: 'Quête secondaire'
  },
  'quest_following_label': {
    AppLanguage.en: 'Followed: its goal shows above the story',
    AppLanguage.fr: 'Suivie : son objectif s’affiche au-dessus du récit',
  },
  'quest_objectives_title': {
    AppLanguage.en: 'Objectives',
    AppLanguage.fr: 'Objectifs',
  },
  'quest_rewards_label': {
    AppLanguage.en: 'Reward',
    AppLanguage.fr: 'Récompense'
  },
  'quest_follow_button': {AppLanguage.en: 'Follow', AppLanguage.fr: 'Suivre'},
  'quest_others_title': {
    AppLanguage.en: 'Other quests in progress',
    AppLanguage.fr: 'Autres quêtes en cours',
  },
  'quest_ally_joins_suffix': {
    AppLanguage.en: 'joins you',
    AppLanguage.fr: 'vous rejoint',
  },
  'quest_ready_notice': {
    AppLanguage.en: 'Goal reached: {quest}. Turn it in from the quest above '
        'the story.',
    AppLanguage.fr: 'Objectif atteint : {quest}. Rendez-la depuis la quête '
        'affichée au-dessus du récit.',
  },
  'quests_section_following': {
    AppLanguage.en: 'Followed',
    AppLanguage.fr: 'Suivie',
  },
  'quests_section_active': {
    AppLanguage.en: 'In progress',
    AppLanguage.fr: 'En cours',
  },
  'quests_section_available': {
    AppLanguage.en: 'Offered',
    AppLanguage.fr: 'Proposées',
  },
  'quests_section_done': {AppLanguage.en: 'Done', AppLanguage.fr: 'Terminées'},
  'quests_none_found': {
    AppLanguage.en: 'No quest yet. People and places in the story will ask '
        'things of you.',
    AppLanguage.fr: 'Aucune quête pour l’instant. Les gens et les lieux du '
        'récit vous demanderont des choses.',
  },
  'bestiary_none_met': {
    AppLanguage.en: 'No creature met yet.',
    AppLanguage.fr: 'Aucune créature rencontrée pour l’instant.',
  },
  'bestiary_unmet_count': {
    AppLanguage.en: '{n} more to meet on the road.',
    AppLanguage.fr: 'Encore {n} à croiser en chemin.',
  },
  'shops_none_found': {
    AppLanguage.en: 'No shop found yet.',
    AppLanguage.fr: 'Aucune boutique trouvée pour l’instant.',
  },
  'shop_met_on_road': {
    AppLanguage.en: 'Met on the road, and gone on down it.',
    AppLanguage.fr: 'Une rencontre de la route, qui a repris son chemin.',
  },
  'shop_back_where_found': {
    AppLanguage.en: 'Go back where you found it to trade.',
    AppLanguage.fr: 'Retournez là où vous l’avez trouvée pour commercer.',
  },
  'shop_at_camp': {
    AppLanguage.en: 'At the camp: open it from the Camp tab.',
    AppLanguage.fr: 'Au camp : ouvrez-la depuis l’onglet Campement.',
  },
  'npcs_none_met': {
    AppLanguage.en: 'No one to speak with yet.',
    AppLanguage.fr: 'Personne à qui parler pour l’instant.',
  },
  'achievement_hidden_name': {
    AppLanguage.en: 'Hidden achievement',
    AppLanguage.fr: 'Succès caché',
  },
  'achievement_hidden_desc': {
    AppLanguage.en: 'Keep playing to reveal it.',
    AppLanguage.fr: 'Continuez à jouer pour le révéler.',
  },
  'face_kind_attack': {AppLanguage.en: 'Attack', AppLanguage.fr: 'Attaque'},
  'face_kind_defend': {AppLanguage.en: 'Guard', AppLanguage.fr: 'Garde'},
  'face_kind_heal': {AppLanguage.en: 'Heal', AppLanguage.fr: 'Soin'},
  'face_kind_mana': {AppLanguage.en: 'Mana', AppLanguage.fr: 'Mana'},
  'face_kind_poison': {AppLanguage.en: 'Poison', AppLanguage.fr: 'Poison'},
  'face_kind_stun': {AppLanguage.en: 'Stun', AppLanguage.fr: 'Étourdit'},
  'face_kind_weaken': {AppLanguage.en: 'Weaken', AppLanguage.fr: 'Affaiblit'},
  'face_kind_empty': {AppLanguage.en: 'Blank', AppLanguage.fr: 'Vide'},
  'die_made_for_prefix': {
    AppLanguage.en: 'Made for',
    AppLanguage.fr: 'Conçu pour',
  },
  'reward_die_traded': {
    AppLanguage.en: 'The {die} is made for another class: you took its '
        'price in gold instead.',
    AppLanguage.fr: 'Le {die} est fait pour une autre classe : vous en '
        'avez pris le prix en or.',
  },
  'none_equipped': {
    AppLanguage.en: '(none equipped)',
    AppLanguage.fr: '(aucun équipé)'
  },
  'choose_die': {AppLanguage.en: 'Choose die', AppLanguage.fr: 'Choisir un dé'},
  'unequip': {AppLanguage.en: 'Unequip', AppLanguage.fr: 'Déséquiper'},
  'choose_item': {
    AppLanguage.en: 'Choose item',
    AppLanguage.fr: 'Choisir un objet'
  },
  'all_items': {AppLanguage.en: 'All Items', AppLanguage.fr: 'Tous les objets'},
  'inventory_empty': {
    AppLanguage.en: 'Your inventory is empty. Buy or loot some gear!',
    AppLanguage.fr:
        "Votre inventaire est vide. Achetez ou pillez de l'équipement !",
  },
  'faces_label': {AppLanguage.en: 'faces', AppLanguage.fr: 'faces'},
  'skill_tree_view': {AppLanguage.en: 'Tree', AppLanguage.fr: 'Arbre'},
  'skill_list_view': {AppLanguage.en: 'List', AppLanguage.fr: 'Liste'},
  'skill_tree_intro': {
    AppLanguage.en:
        'Skills are no longer bought with points: the clans offer them. Each branch is sponsored by a clan, and a clan offers a branch’s skills from the top down, deeper as it trusts you more: the first at Unknown, the second at Known, the third at Trusted, the fourth at Sworn. Learn a whole branch of your class to master it with essence: its skills then fight a tier higher.',
    AppLanguage.fr:
        'Les compétences ne s’achètent plus avec des points\u00a0: les clans les offrent. Chaque branche est parrainée par un clan, qui en offre les compétences de haut en bas, plus profondes à mesure qu’il vous fait confiance\u00a0: la première à l’Anonymat, la deuxième à l’Estime, la troisième à la Confiance, la quatrième au Serment. Apprenez toute une branche de votre classe pour la maîtriser avec de l’essence\u00a0: ses compétences combattent alors un rang au-dessus.',
  },
  'skill_tree_mastered': {
    AppLanguage.en:
        'Mastered: {branch}. Its skills fight a tier higher. Each other branch can still be learned, but not mastered.',
    AppLanguage.fr:
        'Maîtrisée : {branch}. Ses compétences combattent un rang au-dessus. Les autres branches s’apprennent encore, mais ne se maîtrisent plus.',
  },
  'skill_after_label': {
    AppLanguage.en: 'After {skill}',
    AppLanguage.fr: 'Après {skill}',
  },
  'learn_for_point': {
    AppLanguage.en: 'Learn (1 point)',
    AppLanguage.fr: 'Apprendre (1 point)',
  },
  'learn_for_points': {
    AppLanguage.en: 'Learn ({n} points)',
    AppLanguage.fr: 'Apprendre ({n} points)',
  },
  'skill_points_needed': {
    AppLanguage.en: 'Needs {n} skill points',
    AppLanguage.fr: 'Il faut {n} points de compétence',
  },
  'skill_point_cost_one': {
    AppLanguage.en: '1 skill point',
    AppLanguage.fr: '1 point de compétence',
  },
  'skill_point_cost_many': {
    AppLanguage.en: '{n} skill points',
    AppLanguage.fr: '{n} points de compétence',
  },
  'no_skill_points': {
    AppLanguage.en: 'No skill point to spend',
    AppLanguage.fr: 'Aucun point de compétence à dépenser',
  },
  'mastery_label': {AppLanguage.en: 'Mastery', AppLanguage.fr: 'Maîtrise'},
  'mastery_title': {
    AppLanguage.en: 'Mastery of the {branch}',
    AppLanguage.fr: 'Maîtrise : {branch}',
  },
  'mastery_body': {
    AppLanguage.en:
        'Every skill of this branch fights one tier higher. It costs {cost} essence once the whole branch is learned, and only one branch can ever be mastered.',
    AppLanguage.fr:
        'Chaque compétence de cette branche combat un rang au-dessus. Elle coûte {cost}\u00a0d’essence une fois toute la branche apprise, et une seule branche peut être maîtrisée.',
  },
  'mastery_done': {
    AppLanguage.en: 'Mastered.',
    AppLanguage.fr: 'Maîtrisée.',
  },
  'mastery_closed': {
    AppLanguage.en: 'Another branch is already mastered.',
    AppLanguage.fr: 'Une autre branche est déjà maîtrisée.',
  },
  'mastery_needs_branch': {
    AppLanguage.en: 'Learn every skill of this branch first.',
    AppLanguage.fr: 'Apprenez d’abord toutes les compétences de cette branche.',
  },
  'mastery_button': {
    AppLanguage.en: 'Master this branch ({cost} essence)',
    AppLanguage.fr: 'Maîtriser cette branche ({cost}\u00a0d’essence)',
  },
  'mastery_gained': {
    AppLanguage.en: 'Mastered: {branch}',
    AppLanguage.fr: 'Maîtrisée : {branch}',
  },
  'skill_filter_all': {AppLanguage.en: 'All', AppLanguage.fr: 'Toutes'},
  'filter_attack': {AppLanguage.en: 'Attack', AppLanguage.fr: 'Attaque'},
  'filter_heal': {AppLanguage.en: 'Healing', AppLanguage.fr: 'Soin'},
  'filter_mana': {AppLanguage.en: 'Mana', AppLanguage.fr: 'Mana'},
  'filter_status': {AppLanguage.en: 'Status', AppLanguage.fr: 'Altération'},
  'filter_known': {AppLanguage.en: 'Known', AppLanguage.fr: 'Connues'},
  'filter_learnable': {
    AppLanguage.en: 'Can learn',
    AppLanguage.fr: 'À apprendre',
  },
  'filter_nothing': {
    AppLanguage.en: 'No skill matches these filters.',
    AppLanguage.fr: 'Aucune compétence ne correspond à ces filtres.',
  },
  'ally_skills_note': {
    AppLanguage.en:
        'A companion keeps to their own trade: {class} skills only, one point each, in any order. What their die already carries is theirs from the start.',
    AppLanguage.fr:
        'Un compagnon s’en tient à son métier : compétences de {class} uniquement, un point chacune, dans l’ordre voulu. Ce que porte déjà son dé lui appartient dès le départ.',
  },
  'skill_points_label': {
    AppLanguage.en: 'Skill Points',
    AppLanguage.fr: 'Points de compétence',
  },
  'failed_to_load_skills': {
    AppLanguage.en: 'Failed to load skills',
    AppLanguage.fr: 'Échec du chargement des compétences',
  },
  'no_skills_defined': {
    AppLanguage.en: 'No skills defined yet.',
    AppLanguage.fr: 'Aucune compétence définie pour le moment.',
  },
  'unlocked_prefix': {AppLanguage.en: 'Unlocked', AppLanguage.fr: 'Débloqué'},
  'unlock_button': {AppLanguage.en: 'Unlock', AppLanguage.fr: 'Débloquer'},
  'reserved_prefix': {AppLanguage.en: 'Reserved', AppLanguage.fr: 'Réservé'},
  'good_aligned_label': {
    AppLanguage.en: 'Good-aligned',
    AppLanguage.fr: 'Aligné bien',
  },
  'evil_aligned_label': {
    AppLanguage.en: 'Evil-aligned',
    AppLanguage.fr: 'Aligné mal',
  },
  'skill_essence_label': {
    AppLanguage.en: 'Skill Essence',
    AppLanguage.fr: "Essence de compétence",
  },
  'tier_label': {AppLanguage.en: 'Tier', AppLanguage.fr: 'Niveau'},
  'upgrade_button': {
    AppLanguage.en: 'Upgrade',
    AppLanguage.fr: 'Améliorer',
  },
  'craft_skill_button': {
    AppLanguage.en: 'Craft a Skill',
    AppLanguage.fr: 'Fusionner une compétence',
  },
  'merge_button': {AppLanguage.en: 'Merge', AppLanguage.fr: 'Fusionner'},
  'merge_only_hint': {
    AppLanguage.en:
        'Crafted by merging two skills — tap the craft button above.',
    AppLanguage.fr:
        'Obtenue en fusionnant deux compétences — touchez le bouton de fusion ci-dessus.',
  },
  'merge_consumes_hint': {
    AppLanguage.en: 'Both skills below are consumed by this merge.',
    AppLanguage.fr:
        'Les deux compétences ci-dessous seront consommées par cette fusion.',
  },
  'merge_confirm_message': {
    AppLanguage.en: 'Merge these skills? Both are lost for good this life:',
    AppLanguage.fr:
        'Fusionner ces compétences ? Les deux seront perdues pour cette vie :',
  },
  'already_crafted_label': {
    AppLanguage.en: 'Already crafted',
    AppLanguage.fr: 'Déjà fusionnée',
  },
  'no_merge_recipes': {
    AppLanguage.en: 'No merge recipes defined yet.',
    AppLanguage.fr: 'Aucune recette de fusion définie pour le moment.',
  },
  'skills_reset_label': {
    AppLanguage.en: 'Skills Reset',
    AppLanguage.fr: 'Compétences réinitialisées',
  },
  'shop_no_stock': {
    AppLanguage.en: 'This shop has no stock configured.',
    AppLanguage.fr: "Cette boutique n'a aucun stock configuré.",
  },
  'buy_button': {AppLanguage.en: 'Buy', AppLanguage.fr: 'Acheter'},
  'bought_prefix': {AppLanguage.en: 'Bought', AppLanguage.fr: 'Achat de'},
  'for_label': {AppLanguage.en: 'for', AppLanguage.fr: 'pour'},
  'owned_label': {AppLanguage.en: 'Owned', AppLanguage.fr: 'Possédé'},
  'continue_button': {AppLanguage.en: 'Continue', AppLanguage.fr: 'Continuer'},
  'sort_name': {AppLanguage.en: 'Name (A-Z)', AppLanguage.fr: 'Nom (A-Z)'},
  'sort_price_low': {
    AppLanguage.en: 'Price: Low to High',
    AppLanguage.fr: 'Prix : croissant',
  },
  'sort_price_high': {
    AppLanguage.en: 'Price: High to Low',
    AppLanguage.fr: 'Prix : décroissant',
  },
  'sort_stock': {
    AppLanguage.en: 'Most in stock',
    AppLanguage.fr: 'Plus en stock'
  },
  'filter_all': {AppLanguage.en: 'All', AppLanguage.fr: 'Tous'},
  'shop_filtered_empty': {
    AppLanguage.en: 'No items match this filter.',
    AppLanguage.fr: 'Aucun objet ne correspond à ce filtre.',
  },
  'interface_section_title': {
    AppLanguage.en: 'Interface',
    AppLanguage.fr: 'Interface'
  },
  'walk_companion_setting_title': {
    AppLanguage.en: 'Walking companion',
    AppLanguage.fr: 'Compagnon qui marche',
  },
  'walk_companion_setting_desc': {
    AppLanguage.en:
        'A little companion walks across the page whenever the story moves to a new node.',
    AppLanguage.fr:
        "Un petit compagnon traverse la page à chaque fois que l'histoire passe à un nouveau nœud.",
  },
  'companion_name_label': {
    AppLanguage.en: 'Companion name',
    AppLanguage.fr: 'Nom du compagnon'
  },
  'companion_name_hint': {
    AppLanguage.en: 'e.g. Rex',
    AppLanguage.fr: 'ex. Rex'
  },
  'voice_section_title': {
    AppLanguage.en: 'Read-Aloud Voice',
    AppLanguage.fr: 'Voix de lecture'
  },
  'voice_section_desc': {
    AppLanguage.en: 'Choose which voice reads the story aloud.',
    AppLanguage.fr: "Choisis la voix qui lit l'histoire à voix haute.",
  },
  'auto_read_aloud_setting_title': {
    AppLanguage.en: 'Auto-read narration',
    AppLanguage.fr: 'Lecture automatique du récit',
  },
  'auto_read_aloud_setting_desc': {
    AppLanguage.en: 'Reads each scene aloud as soon as it appears: in the '
        "ElevenLabs voice when it is on, otherwise in the device's built-in "
        'voice.',
    AppLanguage.fr: "Lit chaque scène à voix haute dès son affichage : avec "
        "la voix ElevenLabs si elle est activée, sinon avec la voix intégrée "
        "de l'appareil.",
  },
  'elevenlabs_voice_setting_title': {
    AppLanguage.en: 'Use the ElevenLabs voice (recorded)',
    AppLanguage.fr: 'Utiliser la voix ElevenLabs (enregistrée)',
  },
  'elevenlabs_voice_setting_desc': {
    AppLanguage.en: 'Each paragraph is recorded once with your ElevenLabs API '
        'key and kept on this device, then plays offline. Scenes not recorded '
        "yet are recorded when read (this uses ElevenLabs credits). Without a "
        "key, only recorded scenes use this voice; the rest use the device "
        'voice.',
    AppLanguage.fr: "Chaque paragraphe est enregistré une fois avec votre clé API "
        "ElevenLabs et gardé sur cet appareil, puis lu hors ligne. Les scènes "
        "pas encore enregistrées le sont à la lecture (cela consomme des "
        "crédits ElevenLabs). Sans clé, seules les scènes enregistrées "
        "utilisent cette voix ; les autres, la voix de l'appareil.",
  },
  'elevenlabs_api_key_label': {
    AppLanguage.en: 'ElevenLabs API key',
    AppLanguage.fr: 'Clé API ElevenLabs',
  },
  'elevenlabs_api_key_saved_hint': {
    AppLanguage.en: 'A key is saved on this device. Enter a new one to '
        'replace it.',
    AppLanguage.fr: 'Une clé est enregistrée sur cet appareil. Saisis-en une '
        'nouvelle pour la remplacer.',
  },
  'elevenlabs_api_key_missing_hint': {
    AppLanguage.en: 'No key: only scenes already recorded can be heard in '
        'this voice. Stored only on this device.',
    AppLanguage.fr: 'Pas de clé : seules les scènes déjà enregistrées '
        "peuvent être lues avec cette voix. Stockée uniquement sur cet "
        'appareil.',
  },
  'elevenlabs_voice_id_label': {
    AppLanguage.en: 'ElevenLabs voice ID',
    AppLanguage.fr: 'ID de voix ElevenLabs',
  },
  'elevenlabs_voice_id_hint': {
    AppLanguage.en: 'Leave empty for the narrator voice ({id}). Each voice '
        'keeps its own recordings.',
    AppLanguage.fr: 'Laisse vide pour la voix du narrateur ({id}). Chaque '
        'voix garde ses propres enregistrements.',
  },
  'elevenlabs_recorded_count': {
    AppLanguage.en: 'In this language: {count} paragraphs recorded on this '
        'device, {bundled} shipped inside the app. Recorded here:',
    AppLanguage.fr: 'Dans cette langue : {count} paragraphes enregistrés sur '
        "cet appareil, {bundled} fournis avec l'application. Enregistrés ici :",
  },
  'elevenlabs_record_all_button': {
    AppLanguage.en: 'Record the whole story',
    AppLanguage.fr: "Enregistrer toute l'histoire",
  },
  'elevenlabs_record_button': {
    AppLanguage.en: 'Record',
    AppLanguage.fr: 'Enregistrer',
  },
  'elevenlabs_record_confirm_body': {
    AppLanguage.en: '{count} paragraphs are not recorded yet in this '
        'language. Recording them sends about {chars} characters to '
        'ElevenLabs, which uses about as many credits. Recordings already '
        'made are kept if you stop.',
    AppLanguage.fr: "{count} paragraphes ne sont pas encore enregistrés dans "
        "cette langue. Les enregistrer envoie environ {chars} caractères à "
        "ElevenLabs, soit à peu près autant de crédits. Les enregistrements "
        "déjà faits sont gardés si vous arrêtez.",
  },
  'elevenlabs_record_nothing': {
    AppLanguage.en: 'The whole story is already recorded in this language.',
    AppLanguage.fr: "Toute l'histoire est déjà enregistrée dans cette langue.",
  },
  'elevenlabs_recording_title': {
    AppLanguage.en: 'Recording the story…',
    AppLanguage.fr: "Enregistrement de l'histoire…",
  },
  'elevenlabs_progress': {
    AppLanguage.en: '{done} / {total}',
    AppLanguage.fr: '{done} / {total}',
  },
  'elevenlabs_needs_key': {
    AppLanguage.en: 'Set an ElevenLabs API key in Settings → Read-Aloud Voice '
        'to record.',
    AppLanguage.fr:
        'Définissez une clé API ElevenLabs dans Paramètres → Voix de '
            'lecture pour enregistrer.',
  },
  'record_scene': {
    AppLanguage.en: 'Record this scene',
    AppLanguage.fr: 'Enregistrer cette scène',
  },
  'scene_recorded': {
    AppLanguage.en: 'This scene is recorded',
    AppLanguage.fr: 'Cette scène est enregistrée',
  },
  'narration_recording_open_button': {
    AppLanguage.en: 'Choose scenes to record…',
    AppLanguage.fr: 'Choisir les scènes à enregistrer…',
  },
  'narration_recording_title': {
    AppLanguage.en: 'Record narration',
    AppLanguage.fr: 'Enregistrer la narration',
  },
  'narration_recording_desc': {
    AppLanguage.en: 'Pick scenes by kind and chapter, tick them, and record '
        'them in the ElevenLabs voice. The mark on each scene shows how many '
        'of its paragraphs are recorded (on this device or inside the app). '
        'Push the recordings to GitHub to ship them with the game.',
    AppLanguage.fr: "Choisissez les scènes par type et par chapitre, cochez-les et "
        "enregistrez-les avec la voix ElevenLabs. La marque de chaque scène "
        "indique combien de ses paragraphes sont enregistrés (sur cet appareil "
        "ou dans l'application). Envoyez les enregistrements sur GitHub pour "
        'les livrer avec le jeu.',
  },
  'narration_filter_kind': {AppLanguage.en: 'Kind', AppLanguage.fr: 'Type'},
  'narration_filter_chapter': {
    AppLanguage.en: 'Chapter',
    AppLanguage.fr: 'Chapitre',
  },
  'narration_filter_language': {
    AppLanguage.en: 'Languages',
    AppLanguage.fr: 'Langues',
  },
  'narration_language_en': {
    AppLanguage.en: 'English',
    AppLanguage.fr: 'Anglais',
  },
  'narration_language_fr': {
    AppLanguage.en: 'French',
    AppLanguage.fr: 'Français',
  },
  'narration_category_main': {
    AppLanguage.en: 'Main story',
    AppLanguage.fr: 'Histoire principale',
  },
  'narration_category_places': {
    AppLanguage.en: 'Places',
    AppLanguage.fr: 'Lieux',
  },
  'narration_category_side': {
    AppLanguage.en: 'Side scenes',
    AppLanguage.fr: 'Scènes annexes',
  },
  'narration_category_endings': {
    AppLanguage.en: 'Endings',
    AppLanguage.fr: 'Fins',
  },
  'narration_chapter_prologue': {
    AppLanguage.en: 'Prologue',
    AppLanguage.fr: 'Prologue',
  },
  'narration_chapter_n': {
    AppLanguage.en: 'Chapter {n}',
    AppLanguage.fr: 'Chapitre {n}',
  },
  'narration_variations_title': {
    AppLanguage.en: 'Include asides and variations',
    AppLanguage.fr: 'Inclure apartés et variantes',
  },
  'narration_variations_desc': {
    AppLanguage.en: "Each companion's aside, and the callback, race, "
        "profession and hub lines a scene can add.",
    AppLanguage.fr: "L'aparté de chaque compagnon, et les rappels, lignes de "
        "race, de profession et de lieu qu'une scène peut ajouter.",
  },
  'narration_scenes_shown': {
    AppLanguage.en: '{count} scenes',
    AppLanguage.fr: '{count} scènes',
  },
  'narration_select_all': {
    AppLanguage.en: 'Select all',
    AppLanguage.fr: 'Tout cocher',
  },
  'narration_select_none': {
    AppLanguage.en: 'Clear',
    AppLanguage.fr: 'Tout décocher',
  },
  'narration_record_selected': {
    AppLanguage.en: 'Record {count} selected scenes',
    AppLanguage.fr: 'Enregistrer les {count} scènes cochées',
  },
  'elevenlabs_push_button': {
    AppLanguage.en: 'Push recordings to GitHub',
    AppLanguage.fr: 'Envoyer les enregistrements sur GitHub',
  },
  'elevenlabs_push_needs_token': {
    AppLanguage.en: 'Set your GitHub token in Settings (Edit Mode) first.',
    AppLanguage.fr: "Renseignez d'abord votre jeton GitHub dans les Paramètres "
        '(mode Édition).',
  },
  'elevenlabs_push_checking': {
    AppLanguage.en: 'Checking the repository…',
    AppLanguage.fr: 'Vérification du dépôt…',
  },
  'elevenlabs_push_nothing': {
    AppLanguage.en: 'Every recording on this device is already in the '
        'repository.',
    AppLanguage.fr: 'Tous les enregistrements de cet appareil sont déjà dans '
        'le dépôt.',
  },
  'elevenlabs_push_confirm_body': {
    AppLanguage.en: '{count} recordings are not in the repository yet. They '
        'will be pushed in one commit to a new branch, {branch}, under '
        'assets/narration/. Open a pull request from it to ship them inside '
        'the app.',
    AppLanguage.fr: "{count} enregistrements ne sont pas encore dans le dépôt. "
        "Ils seront envoyés en un seul commit sur une nouvelle branche, "
        "{branch}, dans assets/narration/. Ouvrez une pull request depuis "
        "celle-ci pour les livrer dans l'application.",
  },
  'elevenlabs_pushing_title': {
    AppLanguage.en: 'Pushing recordings…',
    AppLanguage.fr: 'Envoi des enregistrements…',
  },
  'elevenlabs_push_success_body': {
    AppLanguage.en: 'The recordings are on a new branch. Merge a pull request '
        'from it and the next build plays them without a key or a download.',
    AppLanguage.fr: "Les enregistrements sont sur une nouvelle branche. "
        "Fusionnez une pull request depuis celle-ci et la prochaine version "
        "les lira sans clé ni téléchargement.",
  },
  'elevenlabs_record_done': {
    AppLanguage.en: '{count} paragraphs recorded.',
    AppLanguage.fr: '{count} paragraphes enregistrés.',
  },
  'elevenlabs_delete_button': {
    AppLanguage.en: 'Delete recordings',
    AppLanguage.fr: 'Supprimer les enregistrements',
  },
  'elevenlabs_delete_confirm': {
    AppLanguage.en: "Delete this voice's recordings in both languages? "
        'Recording them again uses ElevenLabs credits.',
    AppLanguage.fr: 'Supprimer les enregistrements de cette voix dans les '
        'deux langues ? Les refaire consommera des crédits ElevenLabs.',
  },
  'elevenlabs_deleted': {
    AppLanguage.en: 'Recordings deleted.',
    AppLanguage.fr: 'Enregistrements supprimés.',
  },
  'elevenlabs_web_unsupported': {
    AppLanguage.en: 'Recorded voices need the app (Android, iOS or desktop); '
        'the web version uses the device voice.',
    AppLanguage.fr: "Les voix enregistrées nécessitent l'application "
        '(Android, iOS ou ordinateur) ; la version web utilise la voix de '
        "l'appareil.",
  },
  'voice_error_prefix': {
    AppLanguage.en: 'Voice failed',
    AppLanguage.fr: 'Échec de la voix',
  },
  'item_type_label': {AppLanguage.en: 'Type', AppLanguage.fr: 'Type'},
  'cost_label': {AppLanguage.en: 'Cost', AppLanguage.fr: 'Coût'},
  'equip_slot_label': {
    AppLanguage.en: 'Equip Slot',
    AppLanguage.fr: "Emplacement d'équipement"
  },
  'attack_damage_label': {
    AppLanguage.en: 'Attack Damage',
    AppLanguage.fr: "Dégâts d'attaque"
  },
  'armor_label': {AppLanguage.en: 'Armor', AppLanguage.fr: 'Armure'},
  'fire_dmg_label': {AppLanguage.en: 'Fire Dmg', AppLanguage.fr: 'Dégâts Feu'},
  'wind_dmg_label': {AppLanguage.en: 'Wind Dmg', AppLanguage.fr: 'Dégâts Vent'},
  'earth_dmg_label': {
    AppLanguage.en: 'Earth Dmg',
    AppLanguage.fr: 'Dégâts Terre'
  },
  'water_dmg_label': {
    AppLanguage.en: 'Water Dmg',
    AppLanguage.fr: 'Dégâts Eau'
  },
  'elec_dmg_label': {
    AppLanguage.en: 'Elec Dmg',
    AppLanguage.fr: 'Dégâts Élec.'
  },
  'fire_resist_label': {
    AppLanguage.en: 'Fire Resist',
    AppLanguage.fr: 'Résist. Feu'
  },
  'wind_resist_label': {
    AppLanguage.en: 'Wind Resist',
    AppLanguage.fr: 'Résist. Vent'
  },
  'earth_resist_label': {
    AppLanguage.en: 'Earth Resist',
    AppLanguage.fr: 'Résist. Terre'
  },
  'water_resist_label': {
    AppLanguage.en: 'Water Resist',
    AppLanguage.fr: 'Résist. Eau'
  },
  'elec_resist_label': {
    AppLanguage.en: 'Elec Resist',
    AppLanguage.fr: 'Résist. Élec.'
  },
  'unknown_label': {AppLanguage.en: 'Unknown', AppLanguage.fr: 'Inconnu'},
  'ice_dmg_label': {AppLanguage.en: 'Ice Dmg', AppLanguage.fr: 'Dégâts Glace'},
  'light_dmg_label': {
    AppLanguage.en: 'Light Dmg',
    AppLanguage.fr: 'Dégâts Lumière'
  },
  'void_dmg_label': {AppLanguage.en: 'Void Dmg', AppLanguage.fr: 'Dégâts Vide'},
  'ice_resist_label': {
    AppLanguage.en: 'Ice Resist',
    AppLanguage.fr: 'Résist. Glace'
  },
  'light_resist_label': {
    AppLanguage.en: 'Light Resist',
    AppLanguage.fr: 'Résist. Lumière'
  },
  'void_resist_label': {
    AppLanguage.en: 'Void Resist',
    AppLanguage.fr: 'Résist. Vide'
  },
  'compare_vs_label': {
    AppLanguage.en: 'Compared with your',
    AppLanguage.fr: 'Comparé à votre',
  },
  'shop_alignment_locked': {
    AppLanguage.en: 'Your alignment cannot wear this',
    AppLanguage.fr: 'Votre alignement ne peut pas porter ceci',
  },
  'potion_use_desc': {
    AppLanguage.en: 'Drink to restore {hp} HP.',
    AppLanguage.fr: 'Se boit pour rendre {hp} PV.',
  },
  'potion_major_use_desc': {
    AppLanguage.en: 'Two draughts, each restoring {hp} HP.',
    AppLanguage.fr: 'Deux gorgées, chacune rend {hp} PV.',
  },
  'antidote_use_desc': {
    AppLanguage.en: 'Drink to cure poison and other afflictions.',
    AppLanguage.fr: 'Se boit pour guérir le poison et les afflictions.',
  },
  'charm_use_prefix': {
    AppLanguage.en: 'Burned at the start of a fight:',
    AppLanguage.fr: 'Consumé au début d’un combat :',
  },
  'tome_stat_point_desc': {
    AppLanguage.en: 'Read on the spot: one stat point.',
    AppLanguage.fr: 'Lu sur-le-champ : un point de caractéristique.',
  },
  'tome_skill_point_desc': {
    AppLanguage.en: 'Read on the spot: the clans come to you with an offer.',
    AppLanguage.fr:
        'Lu sur-le-champ\u00a0: les clans viennent à vous avec une offre.',
  },
  'loot_use_now_title': {
    AppLanguage.en: 'Use your spoils now',
    AppLanguage.fr: 'Utiliser votre butin tout de suite',
  },
  'drink_now_button': {AppLanguage.en: 'Drink', AppLanguage.fr: 'Boire'},
  'loot_undo_button': {AppLanguage.en: 'Undo', AppLanguage.fr: 'Annuler'},
  'loot_auto_read_note': {
    AppLanguage.en: 'Read on the spot when you take it.',
    AppLanguage.fr: 'Lu sur-le-champ quand vous le prenez.',
  },
  'loot_cannot_wear_note': {
    AppLanguage.en: 'You cannot wear this yet; it goes to your pack.',
    AppLanguage.fr:
        'Vous ne pouvez pas encore le porter ; il va dans votre sac.',
  },
  'loot_equipped_message': {
    AppLanguage.en: 'You put on',
    AppLanguage.fr: 'Vous équipez',
  },
  'loot_drank_message': {
    AppLanguage.en: 'You drink a potion from the chest: +{hp} HP.',
    AppLanguage.fr: 'Vous buvez une potion du coffre : +{hp} PV.',
  },
  'loot_potion_kept_message': {
    AppLanguage.en: 'Leveling up healed you; the potion stays in your pack.',
    AppLanguage.fr:
        'La montée de niveau vous a soigné ; la potion reste dans votre sac.',
  },
  'face_attack_label': {AppLanguage.en: 'Attack', AppLanguage.fr: 'Attaque'},
  'face_guard_label': {AppLanguage.en: 'Guard', AppLanguage.fr: 'Garde'},
  'face_heal_label': {AppLanguage.en: 'Heal', AppLanguage.fr: 'Soin'},
  'face_mana_label': {AppLanguage.en: 'Mana', AppLanguage.fr: 'Mana'},
  'channeled_face_note': {
    AppLanguage.en:
        'Set on a {face} face, a skill replaces the face\'s own action and works at 70% power. On an Attack face it never hits for less than the attack; on a Heal face it never heals less than the heal.',
    AppLanguage.fr:
        'Posée sur une face {face}, une compétence remplace l’action de la face et agit à 70 % de sa puissance. Sur une face Attaque, elle ne frappe jamais moins fort que l’attaque ; sur une face Soin, elle ne soigne jamais moins que le soin.',
  },
  'pick_face_skill_title': {
    AppLanguage.en: 'Choose this face\'s skill',
    AppLanguage.fr: 'Choisir la compétence de cette face',
  },
  'reset_face_button': {
    AppLanguage.en: 'Back to the face\'s own action',
    AppLanguage.fr: 'Revenir à l’action de la face',
  },
  'face_chance_suffix': {
    AppLanguage.en: 'of rolls',
    AppLanguage.fr: 'des jets'
  },
  'channeled_face_badge': {
    AppLanguage.en: 'On a {face} face · 70%',
    AppLanguage.fr: 'Sur une face {face} · 70 %',
  },
  'edit_auto_win_tooltip': {
    AppLanguage.en: 'Win this fight (edit mode)',
    AppLanguage.fr: 'Gagner ce combat (mode édition)',
  },
  'edit_auto_win_log': {
    AppLanguage.en: 'Edit mode: the fight is won on the spot.',
    AppLanguage.fr: 'Mode édition : le combat est gagné sur-le-champ.',
  },
  'hub_expeditions_section': {
    AppLanguage.en: 'Expeditions',
    AppLanguage.fr: 'Expéditions',
  },
  'hub_onward_section': {AppLanguage.en: 'Onward', AppLanguage.fr: 'Plus loin'},
  'day_abbrev': {AppLanguage.en: 'D', AppLanguage.fr: 'J'},
  'day_label': {AppLanguage.en: 'Day {n}', AppLanguage.fr: 'Jour {n}'},
  'watch_0': {AppLanguage.en: 'Dawn', AppLanguage.fr: 'Aube'},
  'watch_1': {AppLanguage.en: 'Daytime', AppLanguage.fr: 'Plein jour'},
  'watch_2': {AppLanguage.en: 'Dusk', AppLanguage.fr: 'Crépuscule'},
  'watch_3': {AppLanguage.en: 'Night', AppLanguage.fr: 'Nuit'},
  'skills_tab_tree': {
    AppLanguage.en: 'Tree',
    AppLanguage.fr: 'Arbre',
  },
  'skills_tab_mine': {
    AppLanguage.en: 'My skills',
    AppLanguage.fr: 'Mes compétences',
  },
  'skills_tab_spells': {
    AppLanguage.en: 'Spells',
    AppLanguage.fr: 'Sorts',
  },
  'purse_points_one': {
    AppLanguage.en: '1 point',
    AppLanguage.fr: '1 point',
  },
  'purse_points_many': {
    AppLanguage.en: '{n} points',
    AppLanguage.fr: '{n} points',
  },
  'purse_points_note': {
    AppLanguage.en: 'to learn skills · 1 per level',
    AppLanguage.fr: 'pour apprendre · 1 par niveau',
  },
  'purse_essence': {
    AppLanguage.en: 'essence',
    AppLanguage.fr: 'essence',
  },
  'purse_essence_note': {
    AppLanguage.en: 'to raise a tier · earned with XP',
    AppLanguage.fr: 'pour monter d\'un rang · gagnée avec l\'XP',
  },
  'skills_ready': {
    AppLanguage.en: '{n} ready to learn',
    AppLanguage.fr: '{n} à apprendre',
  },
  'skills_none_ready': {
    AppLanguage.en: 'Nothing to learn right now',
    AppLanguage.fr: 'Rien à apprendre pour l\'instant',
  },
  'skills_rules_short': {
    AppLanguage.en:
        'The clans offer skills · deeper with standing · one Mastery',
    AppLanguage.fr:
        'Les clans offrent les compétences · plus profondes avec la réputation · une seule Maîtrise',
  },
  'skills_how_it_works': {
    AppLanguage.en: 'How it works',
    AppLanguage.fr: 'Comment ça marche',
  },
  'cost_pt_one': {
    AppLanguage.en: '1 pt',
    AppLanguage.fr: '1 pt',
  },
  'cost_pt_many': {
    AppLanguage.en: '{n} pts',
    AppLanguage.fr: '{n} pts',
  },
  'mastery_cost_label': {
    AppLanguage.en: 'Mastery · {n} essence',
    AppLanguage.fr: 'Maîtrise · {n}\u00a0d’essence',
  },
  'skill_step_of': {
    AppLanguage.en: '{branch} · step {i} of {n}',
    AppLanguage.fr: '{branch} · étape {i} sur {n}',
  },
  'skill_by_tier': {
    AppLanguage.en: 'By tier',
    AppLanguage.fr: 'Par rang',
  },
  'tier_base': {
    AppLanguage.en: 'Base',
    AppLanguage.fr: 'Base',
  },
  'skill_on_die_one': {
    AppLanguage.en: 'On 1 face of {die}',
    AppLanguage.fr: 'Sur 1 face de {die}',
  },
  'skill_on_die_many': {
    AppLanguage.en: 'On {n} faces of {die}',
    AppLanguage.fr: 'Sur {n} faces de {die}',
  },
  'skill_not_on_die': {
    AppLanguage.en: 'Not on your die yet',
    AppLanguage.fr: 'Pas encore sur votre dé',
  },
  'skill_dice_link': {
    AppLanguage.en: 'Dice',
    AppLanguage.fr: 'Dés',
  },
  'raise_tier_button': {
    AppLanguage.en: 'Raise to tier {n} · {cost} essence',
    AppLanguage.fr: 'Monter au rang {n} · {cost} essence',
  },
  'raise_tier_short': {
    AppLanguage.en: '{n} more essence needed; it comes with XP.',
    AppLanguage.fr: 'Encore {n} d\'essence ; elle vient avec l\'XP.',
  },
  'tier_max_label': {
    AppLanguage.en: 'Highest tier',
    AppLanguage.fr: 'Rang maximal',
  },
  'no_tiers_label': {
    AppLanguage.en: 'no tiers',
    AppLanguage.fr: 'sans rang',
  },
  'skill_no_tiers_note': {
    AppLanguage.en: 'Everyone has this one: it has no tiers.',
    AppLanguage.fr: 'Tout le monde l\'a : elle n\'a pas de rang.',
  },
  'compare_with': {
    AppLanguage.en: 'Compare with…',
    AppLanguage.fr: 'Comparer avec…',
  },
  'compare_pick_title': {
    AppLanguage.en: 'Compare with',
    AppLanguage.fr: 'Comparer avec',
  },
  'craft_link': {
    AppLanguage.en: 'Craft…',
    AppLanguage.fr: 'Fusionner…',
  },
  'craft_card_body': {
    AppLanguage.en: 'Two skills you know make a new one.',
    AppLanguage.fr: 'Deux compétences connues en font une nouvelle.',
  },
  'skills_group_other': {
    AppLanguage.en: 'Other',
    AppLanguage.fr: 'Autres',
  },
  'skills_reputation_section': {
    AppLanguage.en: 'Earned by reputation',
    AppLanguage.fr: 'Selon votre réputation',
  },
  'mine_empty': {
    AppLanguage.en: 'Nothing here yet: learn skills in the Tree.',
    AppLanguage.fr: 'Rien ici pour l\'instant : apprenez dans l\'Arbre.',
  },
  'spells_known': {
    AppLanguage.en: 'Known',
    AppLanguage.fr: 'Connus',
  },
  'spells_to_find': {
    AppLanguage.en: 'To find',
    AppLanguage.fr: 'À trouver',
  },
  'summary_damage': {
    AppLanguage.en: '+{n} damage',
    AppLanguage.fr: '+{n} dégâts',
  },
  'summary_heal': {
    AppLanguage.en: 'heals {n}',
    AppLanguage.fr: 'soigne {n}',
  },
  'summary_mana': {
    AppLanguage.en: '+{n} mana',
    AppLanguage.fr: '+{n} mana',
  },
  'fights_at_tier': {
    AppLanguage.en: 'Fights at tier {n} (Mastery)',
    AppLanguage.fr: 'Combat au rang {n} (Maîtrise)',
  },
  'ship_shield_line': {
    AppLanguage.en: 'Shield: blocks {n} hit(s) a fight, then recharges',
    AppLanguage.fr: 'Bouclier : pare {n} coup(s) par combat, puis se recharge',
  },
  'shield_short_label': {
    AppLanguage.en: 'Shield',
    AppLanguage.fr: 'Bouclier',
  },
  'camp_tab_road': {
    AppLanguage.en: 'Road',
    AppLanguage.fr: 'Route',
  },
  'camp_tab_town': {
    AppLanguage.en: 'Town',
    AppLanguage.fr: 'Ville',
  },
  'camp_tab_party': {
    AppLanguage.en: 'Party',
    AppLanguage.fr: 'Groupe',
  },
  'camp_tab_sea': {
    AppLanguage.en: 'Sea',
    AppLanguage.fr: 'Mer',
  },
  'camp_scene_put_away': {
    AppLanguage.en: 'Put it away',
    AppLanguage.fr: 'Ranger',
  },
  'next_main_quest_label': {
    AppLanguage.en: 'Next · main quest',
    AppLanguage.fr: 'Ensuite · quête principale',
  },
  'main_quest_open_label': {
    AppLanguage.en: 'Main quest · open',
    AppLanguage.fr: 'Quête principale · ouverte',
  },
  'next_visit_place': {
    AppLanguage.en: 'Visit {place}',
    AppLanguage.fr: 'Visiter {place}',
  },
  'next_visit_place_sub': {
    AppLanguage.en: 'on the Road, under Places',
    AppLanguage.fr: 'sur la Route, parmi les Lieux',
  },
  'next_explore_sub': {
    AppLanguage.en: 'places, expeditions and bounties count',
    AppLanguage.fr: 'lieux, expéditions et primes comptent',
  },
  'steps_left_one': {
    AppLanguage.en: '1 step left',
    AppLanguage.fr: 'Encore 1 étape',
  },
  'steps_left_many': {
    AppLanguage.en: '{n} steps left',
    AppLanguage.fr: 'Encore {n} étapes',
  },
  'harbour_not_built_title': {
    AppLanguage.en: 'The Harbor: not built yet',
    AppLanguage.fr: 'Le Port : pas encore bâti',
  },
  'harbour_not_built_body': {
    AppLanguage.en:
        'Build it in Town ({cost} gold) to fit guns, plates and a sail to the Eel.',
    AppLanguage.fr:
        'Bâtissez-le en Ville ({cost} or) pour armer le Rusty Eel : canons, plaques, voile.',
  },
  'harbour_built_body': {
    AppLanguage.en: 'Refit the Eel: parts for her slots.',
    AppLanguage.fr: 'Radouber le Rusty Eel : des pièces pour ses emplacements.',
  },
  'tut_camp_0': {
    AppLanguage.en:
        'Next: what the chapter\'s main quest still needs. Tap a place to find it on the Road.',
    AppLanguage.fr:
        'Ensuite : ce qu\'il manque à la quête principale du chapitre. Touchez un lieu pour le trouver sur la Route.',
  },
  'tut_camp_6': {
    AppLanguage.en:
        'Road: the places you know, expeditions from the shore, and the bounty board.',
    AppLanguage.fr:
        'Route : les lieux connus, les expéditions depuis la côte et le tableau des primes.',
  },
  'slots_filled': {
    AppLanguage.en: '{used} of {cap} filled',
    AppLanguage.fr: '{used} sur {cap} occupés',
  },
  'stake_safe_gold': {
    AppLanguage.en: 'Safe · +{n} gold',
    AppLanguage.fr: 'Sans risque · +{n} or',
  },
  'stake_board': {
    AppLanguage.en: 'win +{gold} gold · fail −{hull} hull',
    AppLanguage.fr: 'réussite +{gold} or · échec −{hull} coque',
  },
  'stake_nothing': {
    AppLanguage.en: 'Nothing gained, nothing lost',
    AppLanguage.fr: 'Rien de gagné, rien de perdu',
  },
  'stake_lose_hull': {
    AppLanguage.en: 'Certain · −{n} hull',
    AppLanguage.fr: 'Certain · −{n} coque',
  },
  'stake_push': {
    AppLanguage.en: 'win: nothing lost · fail −{n} hull',
    AppLanguage.fr: 'réussite : rien de perdu · échec −{n} coque',
  },
  'stake_shelter': {
    AppLanguage.en: 'Safe · one more day at sea',
    AppLanguage.fr: 'Sans risque · un jour de mer de plus',
  },
  'stake_repair': {
    AppLanguage.en: 'Safe · +{n} hull',
    AppLanguage.fr: 'Sans risque · +{n} coque',
  },
  'stake_rest': {
    AppLanguage.en: 'Safe · +{n} health',
    AppLanguage.fr: 'Sans risque · +{n} santé',
  },
  'stake_pay': {
    AppLanguage.en: '−{n} gold · they sheer off',
    AppLanguage.fr: '−{n} or · ils s\'éloignent',
  },
  'stake_outrun': {
    AppLanguage.en: 'win: away clean · fail −{n} hull, then a fight',
    AppLanguage.fr: 'réussite : on s\'échappe · échec −{n} coque, puis combat',
  },
  'stake_hold_still': {
    AppLanguage.en: 'win: it passes, a sign of it · fail: a fight',
    AppLanguage.fr: 'réussite : elle passe, un signe d\'elle · échec : combat',
  },
  'stake_fight': {
    AppLanguage.en: 'A sea fight: guns, crew and rooms',
    AppLanguage.fr: 'Un combat naval : canons, équipage et salles',
  },
  'route_today': {
    AppLanguage.en: 'today',
    AppLanguage.fr: 'aujourd\'hui',
  },
  'route_day_quiet': {
    AppLanguage.en: 'quiet',
    AppLanguage.fr: 'calme',
  },
  'ships_log_title': {
    AppLanguage.en: 'SHIP\'S LOG',
    AppLanguage.fr: 'JOURNAL DE BORD',
  },
  'route_from_to': {
    AppLanguage.en: 'From {from} to {to}',
    AppLanguage.fr: 'De {from} à {to}',
  },
  'hub_tab_all': {AppLanguage.en: 'All', AppLanguage.fr: 'Tout'},
  'hub_enter_button': {
    AppLanguage.en: 'Enter {place}',
    AppLanguage.fr: 'Entrer : {place}',
  },
  'hub_back_button': {
    AppLanguage.en: 'Back to {place}',
    AppLanguage.fr: 'Retour : {place}',
  },
  'hub_enter_hint': {
    AppLanguage.en: 'Read once: Reread it any time from the place\'s card.',
    AppLanguage.fr: 'Lu une fois : « Relire » sur la carte du lieu.',
  },
  'hub_story_unfold': {
    AppLanguage.en: 'Read the scene again',
    AppLanguage.fr: 'Relire le récit',
  },
  'hub_story_fold': {
    AppLanguage.en: 'Fold the scene',
    AppLanguage.fr: 'Replier le récit',
  },
  'leave_settlement_title': {
    AppLanguage.en: 'Move on',
    AppLanguage.fr: 'Quitter les lieux',
  },
  'leave_settlement_hint': {
    AppLanguage.en: 'Where the story goes next, when you are ready',
    AppLanguage.fr: 'La suite de l’histoire, quand vous le souhaitez',
  },
  'arrival_town_title': {
    AppLanguage.en: '{place}',
    AppLanguage.fr: '{place}',
  },
  'arrival_town_body': {
    AppLanguage.en:
        'You arrive in a town. Read what is happening here, then enter: its shops, expeditions, people and challenges are sorted into tabs, and you can come and go between them as you like. When you want to go on with the story, open "Move on" at the bottom.',
    AppLanguage.fr:
        'Vous arrivez en ville. Lisez ce qui s’y passe, puis entrez : ses boutiques, expéditions, habitants et défis sont rangés par onglets ; allez de l’un à l’autre à votre guise. Quand vous voudrez reprendre la route, ouvrez « Quitter les lieux » en bas.',
  },
  'arrival_town_button': {
    AppLanguage.en: 'Enter the town',
    AppLanguage.fr: 'Entrer en ville',
  },
  'arrival_town_away_body': {
    AppLanguage.en:
        'You arrive at {place}. Its shops, people and challenges are sorted into tabs once you enter, and everything you do here counts toward the chapter. "Back to the camp" takes you home; "Travel on" takes you to the other places you know.',
    AppLanguage.fr:
        'Vous arrivez à {place}. Ses boutiques, habitants et défis sont rangés par onglets une fois entré, et tout ce que vous y faites compte pour le chapitre. « Retour au camp » vous ramène à la base ; « Aller ailleurs » vous mène vers les autres lieux connus.',
  },
  'arrival_away_button': {AppLanguage.en: 'Go in', AppLanguage.fr: 'Entrer'},
  'story_end_message': {
    AppLanguage.en:
        'Your story ends here. Begin again as someone new, or carry this run into New Game+.',
    AppLanguage.fr:
        'Votre histoire s’achève ici. Recommencez sous un autre visage, ou emportez cette partie dans une Nouvelle Partie+.',
  },
  'fight_not_over_notice': {
    AppLanguage.en: 'The fight is not over. Win it or fall.',
    AppLanguage.fr: 'Le combat n’est pas fini. Gagnez-le ou tombez.',
  },
  'worn_by_prefix': {AppLanguage.en: 'Worn by', AppLanguage.fr: 'Porté par'},
  'read_button': {AppLanguage.en: 'Read', AppLanguage.fr: 'Lire'},
  'tome_read_prefix': {
    AppLanguage.en: 'You read',
    AppLanguage.fr: 'Vous lisez'
  },
  'this_item_header': {
    AppLanguage.en: 'This item',
    AppLanguage.fr: 'Cet objet'
  },
  'slot_empty_label': {
    AppLanguage.en: 'Nothing worn',
    AppLanguage.fr: 'Rien de porté'
  },
  'slot_empty_compare_note': {
    AppLanguage.en: 'Nothing worn in this slot yet',
    AppLanguage.fr: "Rien n'est porté à cet emplacement",
  },
  'shop_details_hint': {
    AppLanguage.en: 'Tap or hold an item for its full stats.',
    AppLanguage.fr: 'Touchez ou maintenez un objet pour voir tous ses effets.',
  },
  'element_label': {AppLanguage.en: 'Element', AppLanguage.fr: 'Élément'},
  'damage_mod_label': {
    AppLanguage.en: 'Damage Mod',
    AppLanguage.fr: 'Modif. de dégâts'
  },
  'damage_multiplier_label': {
    AppLanguage.en: 'Damage Multiplier',
    AppLanguage.fr: 'Multiplicateur de dégâts',
  },
  'active_skill_label': {
    AppLanguage.en: 'Active Skill',
    AppLanguage.fr: 'Compétence active'
  },
  'yes_label': {AppLanguage.en: 'Yes', AppLanguage.fr: 'Oui'},
  'no_label': {AppLanguage.en: 'No', AppLanguage.fr: 'Non'},
  'equipped_prefix': {AppLanguage.en: 'Equipped', AppLanguage.fr: 'Équipé'},
  'atk_abbrev': {AppLanguage.en: 'ATK', AppLanguage.fr: 'ATQ'},
  'arm_abbrev': {AppLanguage.en: 'ARM', AppLanguage.fr: 'ARM'},
  'str_abbrev': {AppLanguage.en: 'STR', AppLanguage.fr: 'FOR'},
  'dex_abbrev': {AppLanguage.en: 'DEX', AppLanguage.fr: 'DEX'},
  'con_abbrev': {AppLanguage.en: 'CON', AppLanguage.fr: 'CON'},
  'int_abbrev': {AppLanguage.en: 'INT', AppLanguage.fr: 'INT'},
  'wis_abbrev': {AppLanguage.en: 'WIS', AppLanguage.fr: 'SAG'},
  'per_abbrev': {AppLanguage.en: 'PER', AppLanguage.fr: 'PER'},
  'stat_requirement_label': {
    AppLanguage.en: 'Requires',
    AppLanguage.fr: 'Requiert',
  },
  'scales_with_label': {
    AppLanguage.en: 'Scales with',
    AppLanguage.fr: 'Évolue avec',
  },
  'level_field_label': {AppLanguage.en: 'Level', AppLanguage.fr: 'Niveau'},
  'experience_label': {
    AppLanguage.en: 'Experience',
    AppLanguage.fr: 'Expérience'
  },
  'health_label': {AppLanguage.en: 'Health', AppLanguage.fr: 'Santé'},
  'base_damage_label': {
    AppLanguage.en: 'Base Damage',
    AppLanguage.fr: 'Dégâts de base'
  },
  'base_armor_label': {
    AppLanguage.en: 'Base Armor',
    AppLanguage.fr: 'Armure de base'
  },
  'gold_field_label': {AppLanguage.en: 'Gold', AppLanguage.fr: 'Or'},
  'alignment_label': {
    AppLanguage.en: 'Alignment',
    AppLanguage.fr: 'Alignement'
  },
  'stat_points_label': {
    AppLanguage.en: 'Stat Points',
    AppLanguage.fr: 'Points de statistique'
  },
  'debug_stats_section_title': {
    AppLanguage.en: 'Debug: Edit Stats',
    AppLanguage.fr: 'Débogage : modifier les statistiques',
  },
  'debug_stats_section_desc': {
    AppLanguage.en:
        'Edit mode only — directly overwrites stats for testing, bypassing normal game rules.',
    AppLanguage.fr:
        'Mode Édition uniquement — modifie directement les statistiques pour les tests, en '
            'contournant les règles normales du jeu.',
  },
  'current_hp_label': {
    AppLanguage.en: 'Current HP',
    AppLanguage.fr: 'PV actuels'
  },
  'max_hp_label': {AppLanguage.en: 'Max HP', AppLanguage.fr: 'PV max'},
  'alignment_score_label': {
    AppLanguage.en: 'Alignment',
    AppLanguage.fr: 'Alignement'
  },
  'potion_count_label': {AppLanguage.en: 'Potions', AppLanguage.fr: 'Potions'},
  'antidote_count_label': {
    AppLanguage.en: 'Antidotes',
    AppLanguage.fr: 'Antidotes',
  },
  'current_xp_label': {
    AppLanguage.en: 'Current XP',
    AppLanguage.fr: 'XP actuelle'
  },
  'apply_button': {AppLanguage.en: 'Apply', AppLanguage.fr: 'Appliquer'},
  'stats_updated_message': {
    AppLanguage.en: 'Stats updated.',
    AppLanguage.fr: 'Statistiques mises à jour.',
  },
  'potions_label': {AppLanguage.en: 'Potions', AppLanguage.fr: 'Potions'},
  'antidotes_label': {AppLanguage.en: 'Antidotes', AppLanguage.fr: 'Antidotes'},
  'inventory_items_label': {
    AppLanguage.en: 'Inventory Items',
    AppLanguage.fr: "Objets d'inventaire",
  },
  'equipped_items_label': {
    AppLanguage.en: 'Equipped Items',
    AppLanguage.fr: 'Objets équipés'
  },
  'unlocked_skills_label': {
    AppLanguage.en: 'Unlocked Skills',
    AppLanguage.fr: 'Compétences débloquées',
  },
  'character_sheet_title': {
    AppLanguage.en: 'Character Sheet',
    AppLanguage.fr: 'Fiche de personnage'
  },
  'choose_who_desc': {
    AppLanguage.en:
        'Choose who you are. This sets your starting stats and starts a new game.',
    AppLanguage.fr:
        'Choisissez qui vous êtes. Ceci définit vos statistiques de départ et démarre une nouvelle partie.',
  },
  'randomize_character_button': {
    AppLanguage.en: 'Randomize',
    AppLanguage.fr: 'Aléatoire',
  },
  'race_label': {AppLanguage.en: 'Race', AppLanguage.fr: 'Race'},
  'profession_label': {
    AppLanguage.en: 'Profession',
    AppLanguage.fr: 'Profession'
  },
  'start_new_game_button': {
    AppLanguage.en: 'Start New Game With This Character',
    AppLanguage.fr: 'Commencer une nouvelle partie avec ce personnage',
  },
  'start_new_game_dialog_title': {
    AppLanguage.en: 'Start new game?',
    AppLanguage.fr: 'Commencer une nouvelle partie ?',
  },
  'start_new_game_dialog_prefix': {
    AppLanguage.en: 'This begins your journey as a',
    AppLanguage.fr: 'Ceci commence votre voyage en tant que',
  },
  'start_button': {AppLanguage.en: 'Start', AppLanguage.fr: 'Commencer'},
  'new_character_prefix': {
    AppLanguage.en: 'New character',
    AppLanguage.fr: 'Nouveau personnage'
  },
  'skill_pt_bonus_label': {
    AppLanguage.en: 'Skill Pt',
    AppLanguage.fr: 'Pt Comp.'
  },
  'race_profession_footer_note': {
    AppLanguage.en:
        'Race and profession can only be changed by restarting the story '
            'from the very beginning.',
    AppLanguage.fr:
        "La race et la profession ne peuvent être modifiées qu'en recommençant "
            "l'histoire depuis le tout début.",
  },
  'granted_skill_label': {
    AppLanguage.en: 'Starting Skill',
    AppLanguage.fr: 'Compétence de départ',
  },
  'lock_character_dialog_title': {
    AppLanguage.en: 'Your Character, Set in Stone',
    AppLanguage.fr: 'Votre personnage, gravé dans la pierre',
  },
  'lock_character_dialog_desc': {
    AppLanguage.en:
        "Once you begin, your race and profession can't be changed for the rest "
            'of this run. Choose a name to carry with you.',
    AppLanguage.fr:
        "Une fois l'histoire commencée, votre race et votre profession ne "
            'pourront plus changer pour le reste de cette partie. Choisissez '
            'un nom à porter.',
  },
  'character_name_field_label': {
    AppLanguage.en: 'Character name',
    AppLanguage.fr: 'Nom du personnage',
  },
  'character_name_field_hint': {
    AppLanguage.en: 'e.g. Kaelen',
    AppLanguage.fr: 'ex. Kaelen'
  },
  'random_name_tooltip': {
    AppLanguage.en: 'Generate a random name',
    AppLanguage.fr: 'Générer un nom aléatoire',
  },
  'begin_story_button': {
    AppLanguage.en: 'Begin Your Story',
    AppLanguage.fr: 'Commencer votre histoire',
  },
  'origin_stories_section_title': {
    AppLanguage.en: 'A Life Before This One',
    AppLanguage.fr: 'Une vie avant celle-ci',
  },
  'origin_stories_intro': {
    AppLanguage.en: 'Six moments from before the story, from the age of six '
        'to sixteen. Each answer leans who you are, and teaches you something '
        'you will carry into it.',
    AppLanguage.fr: "Six moments d'avant l'histoire, de six à seize ans. "
        'Chaque réponse oriente la personne que vous êtes, et vous apprend '
        "quelque chose que vous emporterez dans l'histoire.",
  },
  'origin_memory_progress': {
    AppLanguage.en: 'Memory {n} of {total}',
    AppLanguage.fr: 'Souvenir {n} sur {total}',
  },
  'origin_age_label': {
    AppLanguage.en: 'Age {n}',
    AppLanguage.fr: '{n} ans',
  },
  'origin_stage_childhood': {
    AppLanguage.en: 'Childhood',
    AppLanguage.fr: 'Enfance',
  },
  'origin_stage_youth': {
    AppLanguage.en: 'Adolescence',
    AppLanguage.fr: 'Adolescence',
  },
  'origin_teaches': {
    AppLanguage.en: '+1 {ability}',
    AppLanguage.fr: '+1 {ability}',
  },
  'origin_lean_good': {
    AppLanguage.en: 'Leans Good (+{n})',
    AppLanguage.fr: 'Penche vers le Bien (+{n})',
  },
  'origin_lean_evil': {
    AppLanguage.en: 'Leans Evil (−{n})',
    AppLanguage.fr: 'Penche vers le Mal (−{n})',
  },
  'origin_lean_neutral': {
    AppLanguage.en: 'Leans neither way',
    AppLanguage.fr: "Ne penche d'aucun côté",
  },
  'origin_next_memory': {
    AppLanguage.en: 'Next memory',
    AppLanguage.fr: 'Souvenir suivant',
  },
  'origin_to_summary': {
    AppLanguage.en: 'See who you became',
    AppLanguage.fr: 'Voir ce que ces années ont fait de vous',
  },
  'origin_choose_again': {
    AppLanguage.en: 'Choose again',
    AppLanguage.fr: 'Choisir autrement',
  },
  'origin_summary_title': {
    AppLanguage.en: 'Who You Are',
    AppLanguage.fr: 'Qui vous êtes',
  },
  'origin_summary_intro': {
    AppLanguage.en: 'These memories are yours now. From here on, you tell '
        'the story yourself.',
    AppLanguage.fr: 'Ces souvenirs sont désormais les vôtres. À partir '
        "d'ici, c'est vous qui racontez l'histoire.",
  },
  'origin_portrait_good': {
    AppLanguage.en: 'The slums never managed to teach you to look away.',
    AppLanguage.fr: "Les taudis n'ont jamais réussi à vous apprendre à "
        'détourner les yeux.',
  },
  'origin_portrait_evil': {
    AppLanguage.en: 'The slums taught you early, and you were a quick study.',
    AppLanguage.fr: 'Les taudis ont fait votre éducation très tôt, et la leçon '
        'a pris.',
  },
  'origin_portrait_neutral': {
    AppLanguage.en: 'You learned to keep your head down and your eyes open.',
    AppLanguage.fr: 'Vous avez appris à baisser la tête et à garder les yeux '
        'ouverts.',
  },
  'origin_portrait_mixed': {
    AppLanguage.en: 'You were whatever the day needed you to be.',
    AppLanguage.fr: 'Vous avez été ce que chaque jour exigeait de vous.',
  },
  'origin_summary_lessons': {
    AppLanguage.en: 'What it taught you',
    AppLanguage.fr: 'Ce que cela vous a appris',
  },
  'origin_summary_change_hint': {
    AppLanguage.en: 'Tap a memory to change your answer.',
    AppLanguage.fr: 'Touchez un souvenir pour changer votre réponse.',
  },
  'origin_starting_alignment': {
    AppLanguage.en: 'Starting alignment',
    AppLanguage.fr: 'Alignement de départ',
  },
  'failed_to_load_races': {
    AppLanguage.en: 'Failed to load races',
    AppLanguage.fr: 'Échec du chargement des races',
  },
  'failed_to_load_professions': {
    AppLanguage.en: 'Failed to load professions',
    AppLanguage.fr: 'Échec du chargement des professions',
  },
  'empty_slot_label': {AppLanguage.en: '(empty)', AppLanguage.fr: '(vide)'},
  'xp_label': {AppLanguage.en: 'XP', AppLanguage.fr: 'XP'},
  'stat_points_available': {
    AppLanguage.en: 'Stat Points Available',
    AppLanguage.fr: 'Points de statistique disponibles',
  },
  'max_health_label': {
    AppLanguage.en: 'Max Health',
    AppLanguage.fr: 'Santé max.'
  },
  'plus_one_point': {AppLanguage.en: '+1 Point', AppLanguage.fr: '+1 Point'},
  'distribute_later_button': {
    AppLanguage.en: 'Decide later',
    AppLanguage.fr: 'Décider plus tard',
  },
  'none_label': {AppLanguage.en: 'None', AppLanguage.fr: 'Aucun'},
  'restriction_label': {
    AppLanguage.en: 'Restriction',
    AppLanguage.fr: 'Restriction'
  },
  'own_no_dice': {
    AppLanguage.en: "You don't own any dice yet — buy or find one first.",
    AppLanguage.fr:
        "Vous ne possédez encore aucun dé — achetez-en ou trouvez-en un.",
  },
  'die_label': {AppLanguage.en: 'Die', AppLanguage.fr: 'Dé'},
  'skill_faces_title': {AppLanguage.en: 'Faces', AppLanguage.fr: 'Faces'},
  'skill_rarity_label': {AppLanguage.en: 'Rarity', AppLanguage.fr: 'Rareté'},
  'skill_rarity_common': {AppLanguage.en: 'Common', AppLanguage.fr: 'Commune'},
  'skill_rarity_uncommon': {
    AppLanguage.en: 'Uncommon',
    AppLanguage.fr: 'Peu commune',
  },
  'skill_rarity_rare': {AppLanguage.en: 'Rare', AppLanguage.fr: 'Rare'},
  'skill_rarity_epic': {AppLanguage.en: 'Epic', AppLanguage.fr: 'Épique'},
  'skill_rarity_legendary': {
    AppLanguage.en: 'Legendary',
    AppLanguage.fr: 'Légendaire',
  },
  'skill_faces_limit_hint': {
    AppLanguage.en:
        'A skill fits on 3 faces of a die at most if it is common, 2 if uncommon or rare, and 1 if epic or legendary.',
    AppLanguage.fr:
        'Une compétence tient sur 3 faces d’un dé au plus si elle est commune, 2 si elle est peu commune ou rare, et 1 si elle est épique ou légendaire.',
  },
  'skill_faces_count': {
    AppLanguage.en: '{rarity} · on {n}/{max} faces',
    AppLanguage.fr: '{rarity} · sur {n}/{max} faces',
  },
  'skill_faces_full': {
    AppLanguage.en: '{rarity} · already on {max} faces of this die',
    AppLanguage.fr: '{rarity} · déjà sur {max} faces de ce dé',
  },
  'skill_max_faces': {
    AppLanguage.en: '{rarity} · {max} faces per die at most',
    AppLanguage.fr: '{rarity} · {max} faces par dé au plus',
  },
  'face_over_limit_label': {
    AppLanguage.en: 'Over its limit: the face does its own action',
    AppLanguage.fr: 'Au-delà de sa limite : la face fait son action de base',
  },
  'drag_skill_hint': {
    AppLanguage.en:
        'Each face casts the skill it shows. Tap an open face (pencil) to choose its skill, or drag a skill below onto it. Locked faces are the die\'s own signature.',
    AppLanguage.fr:
        'Chaque face lance la compétence affichée. Touchez une face ouverte (crayon) pour choisir sa compétence, ou glissez-y une compétence ci-dessous. Les faces verrouillées sont la signature du dé.',
  },
  'no_skill_faces': {
    AppLanguage.en: 'This die has no Skill faces to customize.',
    AppLanguage.fr:
        'Ce dé ne possède aucune face de compétence à personnaliser.',
  },
  'your_unlocked_skills': {
    AppLanguage.en: 'Your Unlocked Skills',
    AppLanguage.fr: 'Vos compétences débloquées',
  },
  'no_skills_unlocked_hint': {
    AppLanguage.en:
        'No skills unlocked yet — unlock some on the Skills screen.',
    AppLanguage.fr:
        "Aucune compétence débloquée pour le moment — débloquez-en sur l'écran Compétences.",
  },
  'clear_assigned_skill_tooltip': {
    AppLanguage.en: 'Clear assigned skill',
    AppLanguage.fr: 'Effacer la compétence assignée',
  },
  'drop_skill_here': {
    AppLanguage.en: 'Drop a skill here',
    AppLanguage.fr: 'Déposez une compétence ici'
  },
  'custom_label': {AppLanguage.en: 'Custom', AppLanguage.fr: 'Personnalisé'},
  'skill_singular': {AppLanguage.en: 'Skill', AppLanguage.fr: 'Compétence'},
  'fight_begins_prefix': {
    AppLanguage.en: 'The fight begins!',
    AppLanguage.fr: 'Le combat commence !'
  },
  'has_label': {AppLanguage.en: 'has', AppLanguage.fr: 'a'},
  'you_take_damage_prefix': {
    AppLanguage.en: 'You take',
    AppLanguage.fr: 'Vous subissez'
  },
  'takes_damage_word': {AppLanguage.en: 'takes', AppLanguage.fr: 'subit'},
  'damage_word': {AppLanguage.en: 'damage', AppLanguage.fr: 'dégâts'},
  'is_knocked_out_suffix': {
    AppLanguage.en: 'is knocked out!',
    AppLanguage.fr: 'est mis hors combat !',
  },
  'knocked_out_label': {
    AppLanguage.en: 'Knocked Out',
    AppLanguage.fr: 'Hors combat'
  },
  'from_poison_suffix': {
    AppLanguage.en: 'from poison',
    AppLanguage.fr: 'à cause du poison',
  },
  'poisoned_suffix': {
    AppLanguage.en: 'is poisoned!',
    AppLanguage.fr: 'est empoisonné(e) !',
  },
  'stunned_suffix': {
    AppLanguage.en: 'is stunned!',
    AppLanguage.fr: 'est étourdi(e) !',
  },
  'weakened_suffix': {
    AppLanguage.en: 'is weakened!',
    AppLanguage.fr: 'est affaibli(e) !',
  },
  'stunned_skip_turn_suffix': {
    AppLanguage.en: "is stunned and can't act this round.",
    AppLanguage.fr: 'est étourdi(e) et ne peut pas agir ce tour.',
  },
  'fighting_alongside_prefix': {
    AppLanguage.en: 'Fighting alongside',
    AppLanguage.fr: 'Combat aux côtés de',
  },
  'recruited_prefix': {
    AppLanguage.en: 'recruited',
    AppLanguage.fr: 'recruté(e)'
  },
  'camp_title': {AppLanguage.en: 'Camp', AppLanguage.fr: 'Campement'},
  'roster_section': {AppLanguage.en: 'Roster', AppLanguage.fr: 'Compagnons'},
  'active_party_label': {
    AppLanguage.en: 'Active Party',
    AppLanguage.fr: 'Groupe actif'
  },
  'party_rested_message': {
    AppLanguage.en: 'You and your companions rest and recover fully.',
    AppLanguage.fr:
        'Vous et vos compagnons vous reposez et récupérez entièrement.',
  },
  'rest_button': {AppLanguage.en: 'Rest', AppLanguage.fr: 'Se reposer'},
  'rest_at_camp_button': {
    AppLanguage.en: 'Rest at camp',
    AppLanguage.fr: 'Se reposer au camp',
  },
  'party_rested_at_camp_message': {
    AppLanguage.en:
        'You walk back to camp, sleep by its fires and return rested.',
    AppLanguage.fr:
        'Vous regagnez le camp, dormez près de ses feux et revenez en pleine forme.',
  },
  'rest_blocked_hint': {
    AppLanguage.en: 'Not while a fight or expedition is in progress.',
    AppLanguage.fr: "Impossible pendant un combat ou une expédition.",
  },
  'no_companions_recruited': {
    AppLanguage.en: 'No companions recruited yet — their quests are out there.',
    AppLanguage.fr:
        "Aucun compagnon recruté pour l'instant — leurs quêtes vous attendent.",
  },
  'requires_house_prefix': {
    AppLanguage.en: 'Requires',
    AppLanguage.fr: 'Nécessite'
  },
  'party_at_capacity': {
    AppLanguage.en: 'Active party is full',
    AppLanguage.fr: 'Le groupe actif est complet',
  },
  'active_label': {AppLanguage.en: 'Active', AppLanguage.fr: 'Actif'},
  'benched_label': {AppLanguage.en: 'Benched', AppLanguage.fr: 'Sur le banc'},
  'houses_section': {AppLanguage.en: 'Houses', AppLanguage.fr: 'Maisons'},
  'party_capacity_label': {
    AppLanguage.en: 'party capacity',
    AppLanguage.fr: 'capacité du groupe'
  },
  'party_health_bonus_label': {
    AppLanguage.en: 'party health',
    AppLanguage.fr: 'santé du groupe'
  },
  'party_damage_bonus_label': {
    AppLanguage.en: 'party damage',
    AppLanguage.fr: 'dégâts du groupe'
  },
  'camp_works_label': {
    AppLanguage.en: 'Camp works',
    AppLanguage.fr: 'Ouvrages du camp'
  },
  'resolve_label': {AppLanguage.en: 'Resolve', AppLanguage.fr: 'Résolution'},
  'resolve_bonus_suffix': {
    AppLanguage.en: 'health and damage: the Shroud has learned this enemy',
    AppLanguage.fr: 'de santé et de dégâts : le Linceul a appris cet ennemi'
  },
  'house_built_prefix': {AppLanguage.en: 'Built', AppLanguage.fr: 'Construit'},
  'build_button': {AppLanguage.en: 'Build', AppLanguage.fr: 'Construire'},
  'place_docks': {AppLanguage.en: 'The docks', AppLanguage.fr: 'Les quais'},
  'place_cathedral': {
    AppLanguage.en: 'The cathedral',
    AppLanguage.fr: 'La cathédrale'
  },
  'place_catacombs': {
    AppLanguage.en: 'The catacombs',
    AppLanguage.fr: 'Les catacombes'
  },
  'place_slums': {AppLanguage.en: 'The slums', AppLanguage.fr: 'Les bas-fonds'},
  'place_torture_chamber': {
    AppLanguage.en: 'The torture chamber',
    AppLanguage.fr: 'La salle de torture'
  },
  'place_market': {AppLanguage.en: 'The market', AppLanguage.fr: 'Le marché'},
  'place_sewers': {AppLanguage.en: 'The sewers', AppLanguage.fr: 'Les égouts'},
  'place_bridge': {AppLanguage.en: 'The bridge', AppLanguage.fr: 'Le pont'},
  'place_hovel': {AppLanguage.en: 'The hovel', AppLanguage.fr: 'Le taudis'},
  'place_gate': {AppLanguage.en: 'The gate', AppLanguage.fr: 'La porte'},
  'mood_grim': {AppLanguage.en: 'Grim', AppLanguage.fr: 'Sombre'},
  'mood_tense': {AppLanguage.en: 'Tense', AppLanguage.fr: 'Tendu'},
  'mood_action': {AppLanguage.en: 'Action', AppLanguage.fr: 'Action'},
  'mood_creepy': {AppLanguage.en: 'Eerie', AppLanguage.fr: 'Inquiétant'},
  'mood_suspense': {AppLanguage.en: 'Suspense', AppLanguage.fr: 'Suspense'},
  'mood_desperate': {AppLanguage.en: 'Desperate', AppLanguage.fr: 'Désespéré'},
  'mood_triumphant': {
    AppLanguage.en: 'Triumphant',
    AppLanguage.fr: 'Triomphant'
  },
  'mood_reflective': {AppLanguage.en: 'Reflective', AppLanguage.fr: 'Pensif'},
  'town_title': {
    AppLanguage.en: 'The cliff town',
    AppLanguage.fr: 'La ville de la falaise'
  },
  'town_additions_tab': {AppLanguage.en: 'Additions', AppLanguage.fr: 'Ajouts'},
  'town_tap_to_preview': {
    AppLanguage.en: 'Tap to see where it goes',
    AppLanguage.fr: 'Touchez pour voir où il ira'
  },
  'town_need': {AppLanguage.en: 'need', AppLanguage.fr: 'manque'},
  'town_start': {
    AppLanguage.en: 'Build to climb the cliff.',
    AppLanguage.fr: 'Construisez pour gravir la falaise.'
  },
  'town_raised_quay': {
    AppLanguage.en: '{name} goes up on the quay.',
    AppLanguage.fr: '{name} s\'élève sur le quai.'
  },
  'town_raised_level': {
    AppLanguage.en: '{name} is raised on level {level}.',
    AppLanguage.fr: '{name} s\'élève au niveau {level}.'
  },
  'town_counts': {
    AppLanguage.en: '{houses} of {total} houses · {additions} additions',
    AppLanguage.fr: '{houses} maisons sur {total} · {additions} ajouts'
  },
  'add_floor_name': {
    AppLanguage.en: 'Timber room',
    AppLanguage.fr: 'Chambre à colombages'
  },
  'add_floor_desc': {
    AppLanguage.en: 'A room on stilts, one more light',
    AppLanguage.fr: 'Une pièce sur pilotis, une lumière de plus'
  },
  'add_stair_name': {
    AppLanguage.en: 'Lantern stair',
    AppLanguage.fr: 'Escalier à lanterne'
  },
  'add_stair_desc': {
    AppLanguage.en: 'Joins one level to the next',
    AppLanguage.fr: 'Relie un niveau au suivant'
  },
  'add_store_name': {AppLanguage.en: 'Storehouse', AppLanguage.fr: 'Entrepôt'},
  'add_store_desc': {
    AppLanguage.en: 'Planks, crates and rope',
    AppLanguage.fr: 'Planches, caisses et cordages'
  },
  'add_tower_name': {
    AppLanguage.en: 'Watchtower',
    AppLanguage.fr: 'Tour de guet'
  },
  'add_tower_desc': {
    AppLanguage.en: 'A lantern to see the Shroud coming',
    AppLanguage.fr: 'Une lanterne pour voir venir le Linceul'
  },
  'unlocks_shop_prefix': {
    AppLanguage.en: 'Unlocks',
    AppLanguage.fr: 'Débloque',
  },
  'boutiques_section': {
    AppLanguage.en: 'Boutiques',
    AppLanguage.fr: 'Boutiques',
  },
  'no_boutiques_yet': {
    AppLanguage.en:
        'Build a house that unlocks a shop (see Houses above) to browse one here.',
    AppLanguage.fr:
        'Construisez une maison qui débloque un commerce (voir Maisons '
            'ci-dessus) pour en visiter un ici.',
  },
  'town_hub_title': {
    AppLanguage.en: 'Town Hub',
    AppLanguage.fr: 'Place du village'
  },
  'town_hub_locked_subtitle': {
    AppLanguage.en: 'Open only while the story is in a town',
    AppLanguage.fr: 'Ouvert seulement quand le récit est en ville',
  },
  'camp_locked_subtitle': {
    AppLanguage.en: 'Opens once the camp is set up in chapter 3',
    AppLanguage.fr: 'S’ouvre une fois le campement installé au chapitre 3',
  },
  'zones_cleared_label': {
    AppLanguage.en: 'Zones Cleared',
    AppLanguage.fr: 'Zones nettoyées'
  },
  'basic_shops_section': {
    AppLanguage.en: 'Basic Shops',
    AppLanguage.fr: 'Commerces de base'
  },
  'zones_section': {AppLanguage.en: 'Zones', AppLanguage.fr: 'Zones'},
  'no_zones_available': {
    AppLanguage.en: 'No zones to explore here yet.',
    AppLanguage.fr: "Aucune zone à explorer ici pour l'instant.",
  },
  'zone_cleared_label': {AppLanguage.en: 'Cleared', AppLanguage.fr: 'Nettoyée'},
  'begin_expedition_button': {
    AppLanguage.en: 'Begin Expedition',
    AppLanguage.fr: "Partir en expédition"
  },
  'export_nodes_title': {
    AppLanguage.en: 'Export the story nodes',
    AppLanguage.fr: 'Exporter les nœuds du récit',
  },
  'export_nodes_light': {
    AppLanguage.en: 'Light',
    AppLanguage.fr: 'Légère',
  },
  'export_nodes_light_desc': {
    AppLanguage.en:
        'Id, chapter, text and choices of every node, in chapter order: for reading or review',
    AppLanguage.fr:
        'Id, chapitre, texte et choix de chaque nœud, par chapitre : pour lire ou relire',
  },
  'export_nodes_full': {
    AppLanguage.en: 'Full',
    AppLanguage.fr: 'Complète',
  },
  'export_nodes_full_desc': {
    AppLanguage.en:
        'Every field of every node in both languages, in the story file format',
    AppLanguage.fr:
        'Tous les champs de chaque nœud dans les deux langues, au format du fichier du récit',
  },
  'export_nodes_copied': {
    AppLanguage.en: 'Story nodes copied to the clipboard.',
    AppLanguage.fr: 'Nœuds du récit copiés dans le presse-papiers.',
  },
  'hold_for_details_hint': {
    AppLanguage.en: 'Tap or hold for details',
    AppLanguage.fr: 'Touchez ou maintenez pour les détails',
  },
  'expedition_progress_label': {
    AppLanguage.en: 'Expedition',
    AppLanguage.fr: 'Expédition'
  },
  'expedition_goal': {
    AppLanguage.en:
        'Clear {n} encounters here, then its guardian, {boss}, to claim the zone.',
    AppLanguage.fr:
        'Franchissez {n} rencontres ici, puis son gardien, {boss}, pour conquérir la zone.',
  },
  'expedition_goal_no_boss': {
    AppLanguage.en: 'Clear {n} encounters here to claim the zone.',
    AppLanguage.fr: 'Franchissez {n} rencontres ici pour conquérir la zone.',
  },
  'expedition_goal_escort': {
    AppLanguage.en:
        'Bring the wagons through {n} stages; {boss} waits at the end. You are paid for what arrives.',
    AppLanguage.fr:
        'Menez les chariots à travers {n} étapes ; {boss} attend au bout. La paie dépend de ce qui arrive.',
  },
  'expedition_goal_delivery': {
    AppLanguage.en:
        'Deliver within {days} days: {n} stages, then {boss}. Destination: {place}. Late, it pays half.',
    AppLanguage.fr:
        'Livrez en {days} jours : {n} étapes, puis {boss}. Destination : {place}. En retard, la paie est de moitié.',
  },
  'escort_cargo_label': {
    AppLanguage.en: 'Wagons’ load',
    AppLanguage.fr: 'Chargement',
  },
  'delivery_days_line': {
    AppLanguage.en: 'Days on the road: {used} of {deadline}',
    AppLanguage.fr: 'Jours de route : {used} sur {deadline}',
  },
  'escort_cargo_lost': {
    AppLanguage.en: 'The wagons lost {n}% of their load ({left}% left).',
    AppLanguage.fr:
        'Les chariots ont perdu {n} % de leur chargement (il en reste {left} %).',
  },
  'escort_day_lost': {
    AppLanguage.en: 'That cost a day on the road.',
    AppLanguage.fr: 'Cela a coûté une journée de route.',
  },
  'delivery_day_lost': {
    AppLanguage.en: 'That cost a day: {used} of {deadline} days gone.',
    AppLanguage.fr: 'Cela a coûté une journée : {used} jours sur {deadline}.',
  },
  'delivery_day_saved': {
    AppLanguage.en: 'A day saved: {used} of {deadline} days gone.',
    AppLanguage.fr: 'Une journée de gagnée : {used} jours sur {deadline}.',
  },
  'expedition_hurt': {
    AppLanguage.en: 'The effort cost you {n} health.',
    AppLanguage.fr: 'L’effort vous a coûté {n} points de vie.',
  },
  'escort_lost_message': {
    AppLanguage.en:
        'The last wagon is gone. There is nothing left to deliver, and nobody left to pay you.',
    AppLanguage.fr:
        'Le dernier chariot est perdu. Il n’y a plus rien à livrer, et plus personne pour vous payer.',
  },
  'escort_arrived': {
    AppLanguage.en: 'The wagons arrived with {n}% of their load.',
    AppLanguage.fr: 'Les chariots sont arrivés avec {n} % de leur chargement.',
  },
  'escort_item_missed': {
    AppLanguage.en: 'Too little arrived for the merchant’s extra thanks.',
    AppLanguage.fr:
        'Trop peu est arrivé pour mériter la gratitude du marchand.',
  },
  'delivery_on_time': {
    AppLanguage.en: 'Delivered on time: {used} of {deadline} days.',
    AppLanguage.fr: 'Livré à temps : {used} jours sur {deadline}.',
  },
  'delivery_late': {
    AppLanguage.en: 'Delivered {n} days late: half the pay, and no thanks.',
    AppLanguage.fr:
        'Livré avec {n} jours de retard : la moitié de la paie, et aucun remerciement.',
  },
  'escort_done_title': {
    AppLanguage.en: 'The wagons are in',
    AppLanguage.fr: 'Les chariots sont arrivés',
  },
  'delivery_done_title': {
    AppLanguage.en: 'Delivered',
    AppLanguage.fr: 'Livraison faite',
  },
  'expedition_kind_escort': {
    AppLanguage.en: 'Escort',
    AppLanguage.fr: 'Escorte',
  },
  'expedition_kind_delivery': {
    AppLanguage.en: 'Delivery',
    AppLanguage.fr: 'Livraison',
  },
  'expedition_defeated_message': {
    AppLanguage.en:
        "You're overwhelmed and pull back to town — everything you'd already gained this run stays with you, but this zone's prize is still out there.",
    AppLanguage.fr:
        "Débordé, vous vous repliez vers la ville — tout ce que vous aviez déjà gagné durant cette sortie reste acquis, mais la récompense de cette zone vous échappe encore.",
  },
  'expedition_retreat_message': {
    AppLanguage.en:
        "You break off and head back to town — everything you'd already gained this run stays with you, but this zone's prize is still out there.",
    AppLanguage.fr:
        "Vous interrompez la sortie et rentrez en ville — tout ce que vous aviez déjà gagné durant cette sortie reste acquis, mais la récompense de cette zone vous échappe encore.",
  },
  'expedition_ended_title': {
    AppLanguage.en: 'Expedition Ended',
    AppLanguage.fr: 'Expédition interrompue'
  },
  'zone_cleared_prefix': {
    AppLanguage.en: 'Zone cleared',
    AppLanguage.fr: 'Zone nettoyée'
  },
  'return_to_town_button': {
    AppLanguage.en: 'Return to Town',
    AppLanguage.fr: 'Retourner en ville'
  },
  'zone_flag_banner_second_piece_lead': {
    AppLanguage.en: "A lead on the Shroud's second piece",
    AppLanguage.fr: "Une piste vers le deuxième fragment du Linceul",
  },
  'zone_flag_hull_patched': {
    AppLanguage.en: "The Rusty Eel's hull, patched",
    AppLanguage.fr: "La coque du Rusty Eel, colmatée",
  },
  'zone_flag_sail_mended': {
    AppLanguage.en: "The Rusty Eel's sail, mended",
    AppLanguage.fr: "La voile du Rusty Eel, rapiécée",
  },
  'banner_piece_found_prefix': {
    AppLanguage.en: 'A piece of the Shroud, recovered',
    AppLanguage.fr: 'Un fragment du Linceul, récupéré',
  },
  'banner_pieces_title': {
    AppLanguage.en: 'The Shroud, in Pieces',
    AppLanguage.fr: 'Le Linceul, en morceaux'
  },
  'banner_piece_heirloom_shroud': {
    AppLanguage.en: 'The heirloom piece',
    AppLanguage.fr: "Le fragment de l'héritage",
  },
  'banner_piece_moon_shard_shroud': {
    AppLanguage.en: 'The moon-shard piece',
    AppLanguage.fr: 'Le fragment de lune',
  },
  'banner_piece_warden_standard': {
    AppLanguage.en: "The Warden's standard",
    AppLanguage.fr: "L'étendard du Gardien",
  },
  'banner_piece_reliquary_thread': {
    AppLanguage.en: 'The reliquary thread',
    AppLanguage.fr: 'Le fil du reliquaire',
  },
  'banner_piece_white_fleet_sail': {
    AppLanguage.en: 'The White Fleet’s sail',
    AppLanguage.fr: 'La voile de la Flotte Blanche',
  },
  'banner_piece_sovereign_mantle': {
    AppLanguage.en: 'The Sovereign’s mantle',
    AppLanguage.fr: 'Le manteau du Souverain',
  },
  'grants_banner_piece_id': {
    AppLanguage.en: 'Grants Shroud piece (id)',
    AppLanguage.fr: 'Accorde une pièce du Linceul (id)',
  },
  'grant_item_id': {
    AppLanguage.en: 'Grants item (id)',
    AppLanguage.fr: 'Accorde un objet (id)',
  },
  'keyword_cleave': {
    AppLanguage.en: 'Cleave',
    AppLanguage.fr: 'Fauche',
  },
  'keyword_cleave_desc': {
    AppLanguage.en: 'the strike also hits every other enemy standing for half.',
    AppLanguage.fr:
        'le coup touche aussi chaque autre ennemi debout, pour moitié.',
  },
  'keyword_pierce': {
    AppLanguage.en: 'Pierce',
    AppLanguage.fr: 'Perce',
  },
  'keyword_pierce_desc': {
    AppLanguage.en:
        'the strike goes through a raised guard and an Armored hide.',
    AppLanguage.fr: 'le coup traverse une garde levée et une peau Cuirassée.',
  },
  'keyword_growth': {
    AppLanguage.en: 'Growth',
    AppLanguage.fr: 'Croissance',
  },
  'keyword_growth_desc': {
    AppLanguage.en: 'the face gains 1 each time it is used in this fight.',
    AppLanguage.fr:
        'la face gagne 1 à chaque fois qu\'elle sert dans ce combat.',
  },
  'keyword_echo': {
    AppLanguage.en: 'Echo',
    AppLanguage.fr: 'Écho',
  },
  'keyword_echo_desc': {
    AppLanguage.en:
        'the face does what the party member before it does this round (the first in line repeats last round).',
    AppLanguage.fr:
        'la face fait ce que fait le membre du groupe qui la précède ce round (le premier de la file répète le round précédent).',
  },
  'keyword_pain': {
    AppLanguage.en: 'Pain',
    AppLanguage.fr: 'Douleur',
  },
  'keyword_pain_desc': {
    AppLanguage.en:
        'the strike hits for double, and costs its roller 8% of their max health.',
    AppLanguage.fr:
        'le coup frappe double, et coûte à qui le lance 8 % de sa santé max.',
  },
  'keyword_steady': {
    AppLanguage.en: 'Steady',
    AppLanguage.fr: 'Stable',
  },
  'keyword_steady_desc': {
    AppLanguage.en:
        'the face can\'t be rerolled once it lands, and is worth 2 more.',
    AppLanguage.fr:
        'la face ne peut pas être relancée une fois tombée, et vaut 2 de plus.',
  },
  'combo_flank': {
    AppLanguage.en: 'Flank',
    AppLanguage.fr: 'Prise en tenaille',
  },
  'combo_flank_desc': {
    AppLanguage.en: 'Two strikes: each hits 15% harder.',
    AppLanguage.fr: 'Deux coups : chacun frappe 15 % plus fort.',
  },
  'combo_volley': {
    AppLanguage.en: 'Volley',
    AppLanguage.fr: 'Salve',
  },
  'combo_volley_desc': {
    AppLanguage.en:
        'Three strikes or more: each hits 15% harder and catches every other enemy for a quarter.',
    AppLanguage.fr:
        'Trois coups ou plus : chacun frappe 15 % plus fort et touche chaque autre ennemi pour un quart.',
  },
  'combo_shelter': {
    AppLanguage.en: 'Shelter',
    AppLanguage.fr: 'Abri',
  },
  'combo_shelter_desc': {
    AppLanguage.en:
        'A Guard and a Heal: the heal also mends the rest of the party for half.',
    AppLanguage.fr:
        'Une garde et un soin : le soin soigne aussi le reste du groupe pour moitié.',
  },
  'combo_shieldWall': {
    AppLanguage.en: 'Shield Wall',
    AppLanguage.fr: 'Mur de boucliers',
  },
  'combo_shieldWall_desc': {
    AppLanguage.en:
        'Two Guards or more: every party member holds the biggest guard.',
    AppLanguage.fr:
        'Deux gardes ou plus : chaque membre du groupe tient la plus grande garde.',
  },
  'combo_wellspring': {
    AppLanguage.en: 'Wellspring',
    AppLanguage.fr: 'Source vive',
  },
  'combo_wellspring_desc': {
    AppLanguage.en: 'Two Mana faces or more: 2 more mana.',
    AppLanguage.fr: 'Deux faces de mana ou plus : 2 de mana en plus.',
  },
  'shelter_heals': {
    AppLanguage.en: 'Shelter: {name}\'s heal reaches the party (+{n} each).',
    AppLanguage.fr: 'Abri : le soin de {name} atteint le groupe (+{n} chacun).',
  },
  'splash_hits': {
    AppLanguage.en: '{name} is caught by the blow: {n} damage.',
    AppLanguage.fr: '{name} est pris dans le coup : {n} dégâts.',
  },
  'pain_costs': {
    AppLanguage.en: 'Pain: {name} loses {n} health.',
    AppLanguage.fr: 'Douleur : {name} perd {n} de santé.',
  },
  'tamper_hex': {
    AppLanguage.en: 'Hex',
    AppLanguage.fr: 'Maléfice',
  },
  'tamper_hex_desc': {
    AppLanguage.en:
        'on the party\'s next roll, the best die that lands is rolled again at once (a Steady face holds).',
    AppLanguage.fr:
        'au prochain lancer du groupe, le meilleur dé tombé est aussitôt relancé (une face Stable tient bon).',
  },
  'tamper_silence': {
    AppLanguage.en: 'Silence',
    AppLanguage.fr: 'Silence',
  },
  'tamper_silence_desc': {
    AppLanguage.en:
        'next round, Skill faces land blank (a skill set on a basic face falls back to that face).',
    AppLanguage.fr:
        'au round suivant, les faces de compétence tombent vides (une compétence posée sur une face simple revient à cette face).',
  },
  'tamper_curse': {
    AppLanguage.en: 'Curse',
    AppLanguage.fr: 'Malédiction',
  },
  'tamper_curse_desc': {
    AppLanguage.en:
        'one face of the target\'s die becomes a Pain face for the rest of the fight.',
    AppLanguage.fr:
        'une face du dé de la cible devient une face de Douleur pour le reste du combat.',
  },
  'tamper_mirror': {
    AppLanguage.en: 'Mirror',
    AppLanguage.fr: 'Miroir',
  },
  'tamper_mirror_desc': {
    AppLanguage.en: 'hits back with the party\'s best blow of the round.',
    AppLanguage.fr: 'renvoie le meilleur coup du groupe de ce round.',
  },
  'telegraph_category_tamper': {
    AppLanguage.en: 'Tampers with your dice',
    AppLanguage.fr: 'Trafique vos dés',
  },
  'tamper_hex_laid': {
    AppLanguage.en: 'Your best die will be rolled again on your next throw.',
    AppLanguage.fr: 'Votre meilleur dé sera relancé à votre prochain lancer.',
  },
  'tamper_silence_laid': {
    AppLanguage.en: 'Your Skill faces will land blank next round.',
    AppLanguage.fr:
        'Vos faces de compétence tomberont vides au prochain round.',
  },
  'tamper_curse_laid': {
    AppLanguage.en:
        '{name}\'s {face} face is cursed: it now strikes with Pain.',
    AppLanguage.fr:
        'La face {face} de {name} est maudite : elle frappe désormais avec Douleur.',
  },
  'tamper_hex_sprung': {
    AppLanguage.en: 'Hex: {name}\'s {from} is rolled again: {to}.',
    AppLanguage.fr: 'Maléfice : {from} de {name} est relancé : {to}.',
  },
  'silenced_face_label': {
    AppLanguage.en: 'Silenced',
    AppLanguage.fr: 'Réduite au silence',
  },
  'silence_round_note': {
    AppLanguage.en: 'Silence: Skill faces land blank this round.',
    AppLanguage.fr: 'Silence : les faces de compétence tombent vides ce round.',
  },
  'cursed_face_note': {
    AppLanguage.en:
        'Cursed: this face strikes with Pain for the rest of the fight.',
    AppLanguage.fr:
        'Maudite : cette face frappe avec Douleur pour le reste du combat.',
  },
  'steady_kept_note': {
    AppLanguage.en: 'Steady: this face stays put through the rerolls.',
    AppLanguage.fr: 'Stable : cette face reste en place pendant les relances.',
  },
  'nudges_label': {
    AppLanguage.en: 'Nudges',
    AppLanguage.fr: 'Coups de pouce',
  },
  'nudge_hint': {
    AppLanguage.en:
        'Luck: long-press a landed die to turn it to its opposite face.',
    AppLanguage.fr:
        'Chance : appui long sur un dé tombé pour le tourner sur sa face opposée.',
  },
  'nudge_button': {
    AppLanguage.en: 'Nudge to {face} ({n} left)',
    AppLanguage.fr: 'Pousser sur {face} (reste {n})',
  },
  'nudge_log': {
    AppLanguage.en: 'Nudge: {name}\'s die turns from {from} to {to}.',
    AppLanguage.fr: 'Coup de pouce : le dé de {name} passe de {from} à {to}.',
  },
  'smith_hone': {
    AppLanguage.en: 'Hone',
    AppLanguage.fr: 'Affûter',
  },
  'smith_hone_desc': {
    AppLanguage.en:
        '+2 to an Attack, Guard or Heal face (three times at most).',
    AppLanguage.fr:
        '+2 à une face d\'attaque, de garde ou de soin (trois fois au plus).',
  },
  'smith_temper': {
    AppLanguage.en: 'Temper',
    AppLanguage.fr: 'Tremper',
  },
  'smith_temper_desc': {
    AppLanguage.en: 'Give an Attack face an element.',
    AppLanguage.fr: 'Donner un élément à une face d\'attaque.',
  },
  'smith_inscribe': {
    AppLanguage.en: 'Inscribe',
    AppLanguage.fr: 'Graver',
  },
  'smith_inscribe_desc': {
    AppLanguage.en:
        'Carve a keyword into the face (one per face; a new one replaces it).',
    AppLanguage.fr:
        'Graver un mot-clé sur la face (un par face ; un nouveau le remplace).',
  },
  'smith_recast': {
    AppLanguage.en: 'Recast',
    AppLanguage.fr: 'Refondre',
  },
  'smith_recast_desc': {
    AppLanguage.en:
        'Turn an Attack, Guard or Heal face into another of the three. It keeps its number, up to the die\'s best face of the new kind.',
    AppLanguage.fr:
        'Changer une face d\'attaque, de garde ou de soin en une autre des trois. Elle garde son nombre, sans dépasser la meilleure face de ce type sur le dé.',
  },
  'smith_title': {
    AppLanguage.en: 'Dice smithing',
    AppLanguage.fr: 'Forge des dés',
  },
  'smith_hint': {
    AppLanguage.en:
        'The work stays on the die: a companion\'s die keeps it too, separately from your own copy of the same die.',
    AppLanguage.fr:
        'Le travail reste sur le dé : le dé d\'un compagnon le garde aussi, séparément de votre exemplaire du même dé.',
  },
  'smith_open_button': {
    AppLanguage.en: 'Smith dice',
    AppLanguage.fr: 'Forger les dés',
  },
  'smith_pick_face': {
    AppLanguage.en: 'Tap a face to work on it.',
    AppLanguage.fr: 'Touchez une face pour la travailler.',
  },
  'smith_cost_label': {
    AppLanguage.en: 'Cost',
    AppLanguage.fr: 'Coût',
  },
  'smith_trophy_label': {
    AppLanguage.en: 'trophy',
    AppLanguage.fr: 'trophée',
  },
  'smith_done': {
    AppLanguage.en: 'The Hammersmith worked the face: {work}.',
    AppLanguage.fr: 'Le Maître-forgeron a travaillé la face : {work}.',
  },
  'smith_nothing': {
    AppLanguage.en: 'Nothing more can be done to this face.',
    AppLanguage.fr: 'Rien de plus ne peut être fait sur cette face.',
  },
  'smith_worked_label': {
    AppLanguage.en: 'Worked',
    AppLanguage.fr: 'Travaillée',
  },
  'die_keywords_label': {
    AppLanguage.en: 'Keywords',
    AppLanguage.fr: 'Mots-clés',
  },
  'item_picked_up': {
    AppLanguage.en: 'Picked up: {item}',
    AppLanguage.fr: 'Ramassé : {item}',
  },
  'lose_ally_id': {
    AppLanguage.en: 'Companion lost for good (id, or * for the first active)',
    AppLanguage.fr:
        'Compagnon perdu pour de bon (id, ou * pour le premier actif)',
  },
  'achievement_unlocked_prefix': {
    AppLanguage.en: 'Achievement unlocked',
    AppLanguage.fr: 'Haut fait débloqué',
  },
  'achievements_title': {
    AppLanguage.en: 'Achievements',
    AppLanguage.fr: 'Hauts faits'
  },
  'achievements_progress_label': {
    AppLanguage.en: 'Unlocked',
    AppLanguage.fr: 'Débloqués'
  },
  'failed_to_load_achievements': {
    AppLanguage.en: 'Failed to load achievements',
    AppLanguage.fr: 'Échec du chargement des hauts faits',
  },
  'drink_potion_prefix': {
    AppLanguage.en: 'You drink a potion and recover',
    AppLanguage.fr: 'Vous buvez une potion et récupérez',
  },
  'drink_antidote_prefix': {
    AppLanguage.en: 'You drink the antidote. Your afflictions fade.',
    AppLanguage.fr: "Vous buvez l'antidote. Vos afflictions se dissipent.",
  },
  'victory_prefix': {AppLanguage.en: 'Victory!', AppLanguage.fr: 'Victoire !'},
  'loot_label': {AppLanguage.en: 'loot', AppLanguage.fr: 'butin'},
  'defeat_message': {
    AppLanguage.en: 'You are overwhelmed, but crawl away to recover.',
    AppLanguage.fr:
        'Vous êtes submergé, mais parvenez à ramper pour vous rétablir.',
  },
  'fight_prefix': {AppLanguage.en: 'Fight', AppLanguage.fr: 'Combat'},
  'scaled_to_level': {
    AppLanguage.en: 'scaled to level',
    AppLanguage.fr: 'ajusté au niveau'
  },
  'your_equipment_prefix': {
    AppLanguage.en: 'Your equipment',
    AppLanguage.fr: 'Votre équipement'
  },
  'equipped_die_label': {
    AppLanguage.en: 'Equipped Die',
    AppLanguage.fr: 'Dé équipé'
  },
  'no_die_equipped': {
    AppLanguage.en: 'No die equipped',
    AppLanguage.fr: 'Aucun dé équipé'
  },
  'equip_die_hint': {
    AppLanguage.en: 'Equip a die from Inventory before fighting.',
    AppLanguage.fr: "Équipez un dé depuis l'Inventaire avant de combattre.",
  },
  'enter_battle_button': {
    AppLanguage.en: 'Enter Battle',
    AppLanguage.fr: 'Entrer au combat'
  },
  'you_label': {AppLanguage.en: 'You', AppLanguage.fr: 'Vous'},
  'block_active_prefix': {
    AppLanguage.en: 'Block active',
    AppLanguage.fr: 'Blocage actif'
  },
  'victory_return_button': {
    AppLanguage.en: 'Victory! Return',
    AppLanguage.fr: 'Victoire ! Retour'
  },
  'retreat_button': {
    AppLanguage.en: 'Retreat',
    AppLanguage.fr: 'Battre en retraite'
  },
  'defeat_continue_button': {
    AppLanguage.en: 'Face what comes',
    AppLanguage.fr: 'Affronter la suite'
  },
  'roll_dice_button': {
    AppLanguage.en: 'Roll Dice',
    AppLanguage.fr: 'Lancer le dé'
  },
  'reroll_button': {AppLanguage.en: 'Reroll', AppLanguage.fr: 'Relancer'},
  'confirm_roll_button': {
    AppLanguage.en: 'Confirm',
    AppLanguage.fr: 'Confirmer'
  },
  'skill_label': {AppLanguage.en: 'Skill', AppLanguage.fr: 'Compétence'},
  'rolling_label': {
    AppLanguage.en: 'Rolling…',
    AppLanguage.fr: 'Lancer en cours…'
  },
  'potion_button_prefix': {AppLanguage.en: 'Potion', AppLanguage.fr: 'Potion'},
  'mana_label': {AppLanguage.en: 'Mana', AppLanguage.fr: 'Mana'},
  'spells_label': {AppLanguage.en: 'Spells', AppLanguage.fr: 'Sorts'},
  'spell_known_label': {
    AppLanguage.en: 'Already known',
    AppLanguage.fr: 'Déjà connu',
  },
  'spell_profession_only_prefix': {
    AppLanguage.en: 'Only for a',
    AppLanguage.fr: 'Réservé à la classe',
  },
  'spell_learned_prefix': {
    AppLanguage.en: 'Learned',
    AppLanguage.fr: 'Appris :',
  },
  'round_label': {AppLanguage.en: 'Round', AppLanguage.fr: 'Manche'},
  'roll_hint': {
    AppLanguage.en: 'Roll the party\'s dice, then keep or reroll.',
    AppLanguage.fr: 'Lancez les dés du groupe, puis gardez ou relancez.',
  },
  'lock_hint': {
    AppLanguage.en:
        'Tap a die to keep it through a reroll. Long-press for details.',
    AppLanguage.fr:
        'Touchez un dé pour le garder à la relance. Appui long pour les détails.',
  },
  'confirm_hint': {
    AppLanguage.en: 'Last roll: these faces resolve when you confirm.',
    AppLanguage.fr:
        'Dernier lancer : ces faces s\'appliquent à la confirmation.',
  },
  'preview_against_prefix': {
    AppLanguage.en: 'Against',
    AppLanguage.fr: 'Contre'
  },
  'preview_left_suffix': {AppLanguage.en: 'left', AppLanguage.fr: 'restants'},
  'preview_lethal_label': {AppLanguage.en: 'KO', AppLanguage.fr: 'KO'},
  'nobody_can_act_label': {
    AppLanguage.en: 'Nobody can act this round.',
    AppLanguage.fr: 'Personne ne peut agir ce tour-ci.',
  },
  'die_faces_label': {
    AppLanguage.en: 'Every face of this die',
    AppLanguage.fr: 'Toutes les faces de ce dé',
  },
  'intent_unknown_label': {
    AppLanguage.en: 'Intent unknown',
    AppLanguage.fr: 'Intention inconnue',
  },
  'intent_label': {
    AppLanguage.en: 'Next move',
    AppLanguage.fr: 'Prochain coup'
  },
  'intent_unknown_desc': {
    AppLanguage.en:
        'The party cannot read this enemy yet. More Perception than its Guile reveals who it will hit, then what with.',
    AppLanguage.fr:
        'Le groupe ne peut pas encore lire cet ennemi. Plus de Perception que sa Ruse révèle qui il frappera, puis avec quoi.',
  },
  'intent_target_prefix': {
    AppLanguage.en: 'It is about to go for',
    AppLanguage.fr: 'Il s\'apprête à viser',
  },
  'fled_label': {AppLanguage.en: 'Fled', AppLanguage.fr: 'En fuite'},
  'battle_log_title': {
    AppLanguage.en: 'Battle log',
    AppLanguage.fr: 'Journal du combat',
  },
  'no_spells_hint': {
    AppLanguage.en: 'No spells known -- spellbooks are sold in shops.',
    AppLanguage.fr: 'Aucun sort connu -- les grimoires se vendent en boutique.',
  },
  'cast_prefix': {AppLanguage.en: 'You cast', AppLanguage.fr: 'Vous lancez'},
  'recovers_word': {AppLanguage.en: 'recovers', AppLanguage.fr: 'récupère'},
  'gains_block_word': {AppLanguage.en: 'gains', AppLanguage.fr: 'gagne'},
  'cleansed_suffix': {
    AppLanguage.en: 'is cleansed of every affliction.',
    AppLanguage.fr: 'est purifié de toute affliction.',
  },
  'choose_target_title': {
    AppLanguage.en: 'Choose a target',
    AppLanguage.fr: 'Choisissez une cible',
  },
  'spell_effect_damage': {AppLanguage.en: 'Damage', AppLanguage.fr: 'Dégâts'},
  'spell_effect_heal': {AppLanguage.en: 'Heals', AppLanguage.fr: 'Soigne'},
  'spell_effect_block': {AppLanguage.en: 'Block', AppLanguage.fr: 'Blocage'},
  'spell_effect_status': {
    AppLanguage.en: 'Afflicts',
    AppLanguage.fr: 'Afflige'
  },
  'spell_effect_cleanse': {
    AppLanguage.en: 'Cleanses',
    AppLanguage.fr: 'Purifie'
  },
  'spell_target_enemy': {
    AppLanguage.en: 'one enemy',
    AppLanguage.fr: 'un ennemi'
  },
  'spell_target_all_enemies': {
    AppLanguage.en: 'every enemy',
    AppLanguage.fr: 'tous les ennemis'
  },
  'spell_target_ally': {
    AppLanguage.en: 'one party member',
    AppLanguage.fr: 'un membre du groupe'
  },
  'spell_target_party': {
    AppLanguage.en: 'the whole party',
    AppLanguage.fr: 'tout le groupe'
  },
  'spell_target_self': {
    AppLanguage.en: 'yourself',
    AppLanguage.fr: 'vous-même'
  },
  'mana_and_spells_title': {
    AppLanguage.en: 'Mana & Spells',
    AppLanguage.fr: 'Mana et sorts',
  },
  'cast_in_battle_hint': {
    AppLanguage.en:
        'Cast from the action bar during your turn in battle, like a potion.',
    AppLanguage.fr:
        "Lancés depuis la barre d'action pendant votre tour au combat, comme une potion.",
  },
  'known_label': {AppLanguage.en: 'Known', AppLanguage.fr: 'Connu'},
  'not_learned_label': {
    AppLanguage.en: 'Not learned yet',
    AppLanguage.fr: 'Pas encore appris',
  },
  'spellbook_sold_at_prefix': {
    AppLanguage.en: 'Spellbook sold at',
    AppLanguage.fr: 'Grimoire vendu à',
  },
  'spellbook_not_sold': {
    AppLanguage.en: 'No shop sells this spellbook yet',
    AppLanguage.fr: 'Aucune boutique ne vend encore ce grimoire',
  },
  'effect_label': {AppLanguage.en: 'Effect', AppLanguage.fr: 'Effet'},
  'target_label': {AppLanguage.en: 'Target', AppLanguage.fr: 'Cible'},
  'right_now_label': {
    AppLanguage.en: 'Right now',
    AppLanguage.fr: 'Actuellement'
  },
  'where_to_learn_label': {
    AppLanguage.en: 'Where to learn',
    AppLanguage.fr: 'Où l\'apprendre'
  },
  'mana_pool_label': {
    AppLanguage.en: 'Mana pool',
    AppLanguage.fr: 'Réserve de mana'
  },
  'mana_pool_desc': {
    AppLanguage.en:
        '4 plus half of your Intelligence or Wisdom, whichever is higher.',
    AppLanguage.fr:
        '4 plus la moitié de votre Intelligence ou de votre Sagesse, la plus haute des deux.',
  },
  'status_poison_label': {AppLanguage.en: 'Poison', AppLanguage.fr: 'Poison'},
  'status_stun_label': {
    AppLanguage.en: 'Stun',
    AppLanguage.fr: 'Étourdissement'
  },
  'status_weaken_label': {
    AppLanguage.en: 'Weaken',
    AppLanguage.fr: 'Affaiblissement'
  },
  'mana_faces_note': {
    AppLanguage.en:
        'Mana faces on your dice refill the pool mid-fight; resting refills it fully.',
    AppLanguage.fr:
        'Les faces Mana de vos dés remplissent la réserve en combat ; le repos la remplit entièrement.',
  },
  'antidote_button_prefix': {
    AppLanguage.en: 'Antidote',
    AppLanguage.fr: 'Antidote',
  },
  'vfx_dodge_label': {
    AppLanguage.en: 'Dodge!',
    AppLanguage.fr: 'Esquive !',
  },
  'vfx_gallery_title': {
    AppLanguage.en: 'Effects gallery',
    AppLanguage.fr: 'Galerie des effets',
  },
  'vfx_gallery_intro': {
    AppLanguage.en:
        'Plays each skill effect at each power. In a fight, the power comes from the skill: its rarity, its upgrades, how much of the target\'s health it takes, a critical, a boss. A mighty blow also shakes the screen.',
    AppLanguage.fr:
        'Joue chaque effet de compétence à chaque puissance. En combat, la puissance vient de la compétence : sa rareté, ses améliorations, la part de vie de la cible qu’elle emporte, un critique, un boss. Un coup dévastateur fait aussi trembler l’écran.',
  },
  'vfx_gallery_hero': {
    AppLanguage.en: 'Hero',
    AppLanguage.fr: 'Héros',
  },
  'vfx_gallery_foe': {
    AppLanguage.en: 'Foe',
    AppLanguage.fr: 'Ennemi',
  },
  'vfx_gallery_power': {
    AppLanguage.en: 'Power',
    AppLanguage.fr: 'Puissance',
  },
  'vfx_gallery_particles': {
    AppLanguage.en: 'particles',
    AppLanguage.fr: 'particules',
  },
  'vfx_gallery_play': {
    AppLanguage.en: 'Play',
    AppLanguage.fr: 'Jouer',
  },
  'vfx_gallery_play_all': {
    AppLanguage.en: 'All four',
    AppLanguage.fr: 'Les quatre',
  },
  'vfx_gallery_element': {
    AppLanguage.en: 'Element',
    AppLanguage.fr: 'Élément',
  },
  'vfx_gallery_style': {
    AppLanguage.en: 'Style (tap to play)',
    AppLanguage.fr: 'Style (touchez pour jouer)',
  },
  'vfx_gallery_skill': {
    AppLanguage.en: 'A real skill',
    AppLanguage.fr: 'Une vraie compétence',
  },
  'vfx_gallery_no_skill': {
    AppLanguage.en: 'None: pick a style and a power below',
    AppLanguage.fr: 'Aucune : choisissez un style et une puissance plus bas',
  },
  'vfx_gallery_upgrades': {
    AppLanguage.en: 'Upgrades',
    AppLanguage.fr: 'Améliorations',
  },
  'vfx_gallery_share': {
    AppLanguage.en: 'Share of the foe\'s health it takes',
    AppLanguage.fr: 'Part de la vie de l’ennemi qu’elle emporte',
  },
  'vfx_gallery_critical': {
    AppLanguage.en: 'Critical hit',
    AppLanguage.fr: 'Coup critique',
  },
  'vfx_gallery_play_skill': {
    AppLanguage.en: 'Play this skill',
    AppLanguage.fr: 'Jouer cette compétence',
  },
  'vfx_tier_light': {
    AppLanguage.en: 'Light',
    AppLanguage.fr: 'Léger',
  },
  'vfx_tier_normal': {
    AppLanguage.en: 'Normal',
    AppLanguage.fr: 'Normal',
  },
  'vfx_tier_strong': {
    AppLanguage.en: 'Strong',
    AppLanguage.fr: 'Fort',
  },
  'vfx_tier_mighty': {
    AppLanguage.en: 'Mighty',
    AppLanguage.fr: 'Dévastateur',
  },
  'fight_lab_effects': {
    AppLanguage.en: 'Effects gallery',
    AppLanguage.fr: 'Galerie des effets',
  },
  'fight_lab_effects_desc': {
    AppLanguage.en: 'Every skill effect, from a light touch to a mighty blow',
    AppLanguage.fr:
        'Chaque effet de compétence, du coup léger au coup dévastateur',
  },
  'combat_effects_setting_title': {
    AppLanguage.en: 'Combat effects',
    AppLanguage.fr: 'Effets de combat',
  },
  'combat_effects_setting_desc': {
    AppLanguage.en:
        'Draws each skill\'s and spell\'s effect on screen in fights, bigger for a stronger one, with floating damage and healing numbers.',
    AppLanguage.fr:
        "Affiche l'effet de chaque compétence et de chaque sort pendant les combats, plus grand pour les plus puissants, avec les dégâts et soins flottants.",
  },
  'tremble_setting_title': {
    AppLanguage.en: 'Screen tremble on hit',
    AppLanguage.fr: "Tremblement d'écran à l'impact",
  },
  'tremble_setting_desc': {
    AppLanguage.en:
        'Shakes the screen briefly when you take damage in combat, and when a mighty blow lands (with a vibration).',
    AppLanguage.fr:
        "Fait légèrement trembler l'écran lorsque vous subissez des dégâts au combat, et quand un coup dévastateur porte (avec une vibration).",
  },
  'language_coverage_note': {
    AppLanguage.en:
        'Applies to the whole app — navigation, the full story (reader and map), '
            'the Legend, and every gameplay screen. Game data tables, field names, and IDs '
            'stay in English.',
    AppLanguage.fr:
        "S'applique à toute l'application — navigation, l'histoire complète "
            '(lecteur et carte), la Légende, et tous les écrans de jeu. Les tables de données, '
            'les noms de champs et les identifiants restent en anglais.',
  },
  'gemini_api_key_title': {
    AppLanguage.en: 'Gemini API Key',
    AppLanguage.fr: 'Clé API Gemini'
  },
  'gemini_api_key_desc': {
    AppLanguage.en: 'Used by the AI Generator tab to create new story beats. '
        'Stored only on this device.',
    AppLanguage.fr:
        "Utilisée par l'onglet Générateur IA pour créer de nouvelles scènes. "
            'Stockée uniquement sur cet appareil.',
  },
  'api_key_label': {AppLanguage.en: 'API key', AppLanguage.fr: 'Clé API'},
  'show_api_key_tooltip': {
    AppLanguage.en: 'Show API key',
    AppLanguage.fr: 'Afficher la clé API'
  },
  'hide_api_key_tooltip': {
    AppLanguage.en: 'Hide API key',
    AppLanguage.fr: 'Masquer la clé API'
  },
  'api_key_saved': {
    AppLanguage.en: 'API key saved.',
    AppLanguage.fr: 'Clé API enregistrée.'
  },
  'api_key_removed': {
    AppLanguage.en: 'API key removed.',
    AppLanguage.fr: 'Clé API supprimée.'
  },
  'clear_button': {AppLanguage.en: 'Clear', AppLanguage.fr: 'Effacer'},
  'palette_section_title': {
    AppLanguage.en: 'Color Palette',
    AppLanguage.fr: 'Palette de couleurs'
  },
  'palette_section_desc': {
    AppLanguage.en: 'Choose an accent palette for the whole app.',
    AppLanguage.fr:
        "Choisissez une palette d'accentuation pour toute l'application.",
  },
  'palette_stitched_ink': {
    AppLanguage.en: 'Stitched Ink',
    AppLanguage.fr: 'Encre cousue'
  },
  'palette_deep_purple': {
    AppLanguage.en: 'Deep Purple',
    AppLanguage.fr: 'Violet profond'
  },
  'palette_weathered_earth': {
    AppLanguage.en: 'Weathered Earth',
    AppLanguage.fr: 'Terre patinée'
  },
  'palette_autumn_meadow': {
    AppLanguage.en: 'Autumn Meadow',
    AppLanguage.fr: 'Prairie automnale'
  },
  'palette_dusk_horizon': {
    AppLanguage.en: 'Dusk Horizon',
    AppLanguage.fr: 'Horizon crépusculaire',
  },
  'palette_aurora_dusk': {
    AppLanguage.en: 'Aurora Dusk',
    AppLanguage.fr: 'Aurore crépusculaire'
  },
  'palette_rose_noir': {
    AppLanguage.en: 'Rose Noir',
    AppLanguage.fr: 'Rose et noir'
  },
  'palette_mist_slate': {
    AppLanguage.en: 'Mist Slate',
    AppLanguage.fr: "Brume d'ardoise"
  },
  'combat_section_title': {AppLanguage.en: 'Combat', AppLanguage.fr: 'Combat'},
  'add_api_key_first': {
    AppLanguage.en: 'Add your Gemini API key in Settings first.',
    AppLanguage.fr: "Ajoutez d'abord votre clé API Gemini dans les Paramètres.",
  },
  'describe_next': {
    AppLanguage.en: 'Describe what should happen next.',
    AppLanguage.fr: 'Décrivez ce qui doit se passer ensuite.',
  },
  'no_api_key_banner': {
    AppLanguage.en: 'No Gemini API key set. Open Settings to add one.',
    AppLanguage.fr:
        "Aucune clé API Gemini définie. Ouvrez les Paramètres pour en ajouter une.",
  },
  'what_happens_next_label': {
    AppLanguage.en: 'What happens next?',
    AppLanguage.fr: 'Que se passe-t-il ensuite ?',
  },
  'ai_prompt_hint': {
    AppLanguage.en: 'e.g. Lysa wakes up and finds the Grey Bundle missing.',
    AppLanguage.fr:
        'ex. Lysa se réveille et découvre que le Balluchon Gris a disparu.',
  },
  'generating_label': {
    AppLanguage.en: 'Generating...',
    AppLanguage.fr: 'Génération en cours...'
  },
  'generate_button': {AppLanguage.en: 'Generate', AppLanguage.fr: 'Générer'},
  'no_response_generated': {
    AppLanguage.en: 'No response generated.',
    AppLanguage.fr: 'Aucune réponse générée.',
  },
  'generation_failed_prefix': {
    AppLanguage.en: 'Generation failed',
    AppLanguage.fr: 'Échec de la génération',
  },
  'close_button': {AppLanguage.en: 'Close', AppLanguage.fr: 'Fermer'},
  'flags_count_label': {AppLanguage.en: 'flags', AppLanguage.fr: 'drapeaux'},
  'alignment_good': {AppLanguage.en: 'Good', AppLanguage.fr: 'Bon'},
  'alignment_neutral': {AppLanguage.en: 'Neutral', AppLanguage.fr: 'Neutre'},
  'alignment_evil': {AppLanguage.en: 'Evil', AppLanguage.fr: 'Mauvais'},
  'main_story_title': {
    AppLanguage.en: 'Main Story',
    AppLanguage.fr: 'Histoire principale'
  },
  'chapter_label': {AppLanguage.en: 'Chapter', AppLanguage.fr: 'Chapitre'},
  'missing_node_label': {
    AppLanguage.en: '(missing node)',
    AppLanguage.fr: '(nœud manquant)'
  },
  'node_activated': {
    AppLanguage.en: 'Node activated — jumped to it in the story.',
    AppLanguage.fr: "Nœud activé — vous y avez été téléporté dans l'histoire.",
  },
  'you_deal_prefix': {
    AppLanguage.en: 'you deal',
    AppLanguage.fr: 'vous infligez'
  },
  'you_brace_prefix': {
    AppLanguage.en: 'you brace for',
    AppLanguage.fr: 'vous vous préparez à bloquer',
  },
  'block_word': {AppLanguage.en: 'block', AppLanguage.fr: 'blocage'},
  'redirected_hit_prefix': {
    AppLanguage.en: 'That one was already down — the blow lands on',
    AppLanguage.fr: 'Celui-là était déjà à terre — le coup atteint',
  },
  'braced_suffix': {
    AppLanguage.en: 'braces for the telegraphed blow — block doubled',
    AppLanguage.fr: 'se prépare au coup annoncé — blocage doublé',
  },
  'skill_fizzles': {
    AppLanguage.en: 'The skill fizzles.',
    AppLanguage.fr: 'La compétence échoue.',
  },
  'you_recover_prefix': {
    AppLanguage.en: 'you recover',
    AppLanguage.fr: 'vous récupérez'
  },
  'miss_label': {AppLanguage.en: 'Miss', AppLanguage.fr: 'Raté'},
  'nothing_happens': {
    AppLanguage.en: 'nothing happens.',
    AppLanguage.fr: 'il ne se passe rien.',
  },
  'attacks_suffix': {AppLanguage.en: 'attacks!', AppLanguage.fr: 'attaque !'},
  // v1.162: the camp's bounty board (see contracts.dart).
  'bounty_board_section': {
    AppLanguage.en: 'Bounty board',
    AppLanguage.fr: 'Tableau des contrats',
  },
  'contract_hunt': {
    AppLanguage.en: 'Put down {n} × {enemy}',
    AppLanguage.fr: 'Abattre {n} × {enemy}',
  },
  'contract_packs': {
    AppLanguage.en: 'Win {n} fights against a pack',
    AppLanguage.fr: 'Gagner {n} combats contre une meute',
  },
  'contract_flawless': {
    AppLanguage.en: 'Win {n} fights with nobody down and no potion drunk',
    AppLanguage.fr:
        'Gagner {n} combats sans que personne ne tombe et sans boire de potion',
  },
  'contract_breaker': {
    AppLanguage.en: 'Break {n} enemy wind-ups',
    AppLanguage.fr: 'Briser l’élan ennemi {n} fois',
  },
  'contract_weakness': {
    AppLanguage.en: 'Hit an enemy weakness {n} times',
    AppLanguage.fr: 'Frapper un point faible ennemi {n} fois',
  },
  'contract_marked': {
    AppLanguage.en: 'Beat {n} marked foes (an affix or an Elite)',
    AppLanguage.fr: 'Vaincre {n} ennemis marqués (un trait ou une élite)',
  },
  'contract_claim': {AppLanguage.en: 'Claim', AppLanguage.fr: 'Réclamer'},
  'contract_claimed': {
    AppLanguage.en: 'Contract paid:',
    AppLanguage.fr: 'Contrat payé :',
  },
  'contract_essence_label': {
    AppLanguage.en: 'essence',
    AppLanguage.fr: 'essence',
  },
  'contracts_posting': {
    AppLanguage.en: 'A fresh notice is going up on the board…',
    AppLanguage.fr: 'Une nouvelle affiche est placardée sur le tableau…',
  },
  'contracts_hint': {
    AppLanguage.en:
        'Fights anywhere count. A new board goes up once these are claimed or the chapter turns.',
    AppLanguage.fr:
        'Tous les combats comptent. Un nouveau tableau apparaît quand ceux-ci sont réclamés ou au chapitre suivant.',
  },
  // v1.163: level-up perks.
  'perk_choose_title': {
    AppLanguage.en: 'Choose a perk',
    AppLanguage.fr: 'Choisissez un atout',
  },
  'perk_section': {
    AppLanguage.en: 'Perks',
    AppLanguage.fr: 'Atouts',
  },
  'perk_pending': {
    AppLanguage.en: '{n} perk(s) to choose',
    AppLanguage.fr: '{n} atout(s) à choisir',
  },
  'perk_rank': {
    AppLanguage.en: 'Rank {n}/{max}',
    AppLanguage.fr: 'Rang {n}/{max}',
  },
  'perks_none': {
    AppLanguage.en:
        'No perks yet. The Wayfarer brings them in the clans’ offers.',
    AppLanguage.fr:
        'Aucun atout pour l’instant. Le Voyageur en apporte dans les offres des clans.',
  },
  'perk_steadyHands': {
    AppLanguage.en: 'Steady Hands',
    AppLanguage.fr: 'Mains sûres',
  },
  'perk_steadyHands_desc': {
    AppLanguage.en: 'One more roll each round in fights.',
    AppLanguage.fr: 'Un lancer de plus par tour en combat.',
  },
  'perk_apothecary': {
    AppLanguage.en: 'Apothecary',
    AppLanguage.fr: 'Apothicaire',
  },
  'perk_apothecary_desc': {
    AppLanguage.en: 'Potions heal 10 more.',
    AppLanguage.fr: 'Les potions soignent 10 de plus.',
  },
  'perk_keenEye': {
    AppLanguage.en: 'Keen Eye',
    AppLanguage.fr: 'Œil perçant',
  },
  'perk_keenEye_desc': {
    AppLanguage.en: '+5% chance of a critical hit.',
    AppLanguage.fr: '+5 % de chances de coup critique.',
  },
  'perk_lightFeet': {
    AppLanguage.en: 'Light Feet',
    AppLanguage.fr: 'Pas léger',
  },
  'perk_lightFeet_desc': {
    AppLanguage.en: '+4% chance to dodge.',
    AppLanguage.fr: '+4 % de chances d’esquive.',
  },
  'perk_heavyHand': {
    AppLanguage.en: 'Heavy Hand',
    AppLanguage.fr: 'Main lourde',
  },
  'perk_heavyHand_desc': {
    AppLanguage.en: '+2 damage on every attack.',
    AppLanguage.fr: '+2 dégâts à chaque attaque.',
  },
  'perk_ironHide': {
    AppLanguage.en: 'Iron Hide',
    AppLanguage.fr: 'Cuir de fer',
  },
  'perk_ironHide_desc': {
    AppLanguage.en: '+2 armor.',
    AppLanguage.fr: '+2 d’armure.',
  },
  'perk_vigor': {
    AppLanguage.en: 'Vigor',
    AppLanguage.fr: 'Vigueur',
  },
  'perk_vigor_desc': {
    AppLanguage.en: '+15 max health.',
    AppLanguage.fr: '+15 de santé maximale.',
  },
  'perk_battleRhythm': {
    AppLanguage.en: 'Battle Rhythm',
    AppLanguage.fr: 'Rythme du combat',
  },
  'perk_battleRhythm_desc': {
    AppLanguage.en: 'Momentum surges after 2 hits instead of 3.',
    AppLanguage.fr: 'L’élan se déclenche après 2 coups au lieu de 3.',
  },
  'perk_plunderer': {
    AppLanguage.en: 'Plunderer',
    AppLanguage.fr: 'Pillage',
  },
  'perk_plunderer_desc': {
    AppLanguage.en: '+10% gold from fights.',
    AppLanguage.fr: '+10 % d’or gagné en combat.',
  },
  'perk_quickStudy': {
    AppLanguage.en: 'Quick Study',
    AppLanguage.fr: 'Apprentissage rapide',
  },
  'perk_quickStudy_desc': {
    AppLanguage.en: '+10% XP from fights.',
    AppLanguage.fr: '+10 % d’XP gagnée en combat.',
  },
  'perk_leader': {
    AppLanguage.en: 'Leader',
    AppLanguage.fr: 'Commandement',
  },
  'perk_leader_desc': {
    AppLanguage.en: 'Companions deal +5% damage.',
    AppLanguage.fr: 'Les membres du groupe infligent +5 % de dégâts.',
  },
  'perk_deepWell': {
    AppLanguage.en: 'Deep Well',
    AppLanguage.fr: 'Puits profond',
  },
  'perk_deepWell_desc': {
    AppLanguage.en: '+2 max mana.',
    AppLanguage.fr: '+2 de mana maximal.',
  },
  'perk_lastStand': {
    AppLanguage.en: 'Last Stand',
    AppLanguage.fr: 'Dernier rempart',
  },
  'perk_lastStand_desc': {
    AppLanguage.en:
        'Once a fight, a killing blow leaves you at 1 health instead.',
    AppLanguage.fr:
        'Une fois par combat, un coup fatal vous laisse à 1 point de vie.',
  },
  // v1.163: sea choices.
  'ship_log_paid': {
    AppLanguage.en: 'Paid {n} gold; the raider sheers off',
    AppLanguage.fr: '{n} pièces d’or versées ; le pillard s’écarte',
  },
  'ship_log_outran': {
    AppLanguage.en: 'The Eel outruns them',
    AppLanguage.fr: 'Le Rusty Eel les distance',
  },
  'ship_log_beast_outran': {
    AppLanguage.en: 'The Eel outruns {ship}',
    AppLanguage.fr: 'Le Rusty Eel distance {ship}',
  },
  'ship_log_outrun_failed': {
    AppLanguage.en: 'They catch the Eel and rake her: −{n} hull',
    AppLanguage.fr:
        'Ils rattrapent le Rusty Eel et le mitraillent : −{n} points de coque',
  },
  'ship_log_pushed_through': {
    AppLanguage.en: 'Through the storm with nothing lost',
    AppLanguage.fr: 'La tempête est passée sans rien perdre',
  },
  'ship_log_push_failed': {
    AppLanguage.en: 'The storm punishes the gamble: −{n} hull',
    AppLanguage.fr: 'La tempête punit le pari : −{n} points de coque',
  },
  'ship_log_sheltered': {
    AppLanguage.en: 'Sheltered in a cove; the crossing takes a day longer',
    AppLanguage.fr:
        'À l’abri dans une crique ; la traversée prend un jour de plus',
  },
  'ship_log_boarded': {
    AppLanguage.en: 'Found {n} gold in the hold',
    AppLanguage.fr: '{n} pièces d’or trouvées dans la cale',
  },
  'ship_log_board_holed': {
    AppLanguage.en:
        'The hulk rolled against the Eel as she was grappled: {n} hull lost',
    AppLanguage.fr:
        'L’épave a roulé contre la Rusty Eel pendant l’abordage : {n} points de coque perdus',
  },
  'ship_log_passed_by': {
    AppLanguage.en: 'The derelict drifts astern',
    AppLanguage.fr: 'L’épave dérive derrière vous',
  },
  'ship_log_rested': {
    AppLanguage.en: 'The crew rests: {n} health back',
    AppLanguage.fr: 'L’équipage se repose : {n} points de vie récupérés',
  },
  'sea_choice_cost': {
    AppLanguage.en: '{n} gold',
    AppLanguage.fr: '{n} or',
  },
  // v1.163: quest turn-in choices.
  'turn_in_choice_title': {
    AppLanguage.en: 'How do you settle it?',
    AppLanguage.fr: 'Comment réglez-vous l’affaire ?',
  },
  'turn_in_gold_varies': {
    AppLanguage.en: '{min}–{max} gold, by how you settle it',
    AppLanguage.fr: '{min} à {max} or, selon votre décision',
  },
  // v1.163: companion approval.
  'approval_label': {
    AppLanguage.en: 'Approval',
    AppLanguage.fr: 'Estime',
  },
  'approval_devoted': {
    AppLanguage.en: 'Devoted',
    AppLanguage.fr: 'Dévouement',
  },
  'approval_friendly': {
    AppLanguage.en: 'Friendly',
    AppLanguage.fr: 'Amitié',
  },
  'approval_neutral': {
    AppLanguage.en: 'Neutral',
    AppLanguage.fr: 'Neutralité',
  },
  'approval_wary': {
    AppLanguage.en: 'Wary',
    AppLanguage.fr: 'Méfiance',
  },
  'approval_estranged': {
    AppLanguage.en: 'Estranged',
    AppLanguage.fr: 'Rupture',
  },
  'approval_effect_devoted': {
    AppLanguage.en: '+10% damage and health in fights',
    AppLanguage.fr: '+10 % de dégâts et de santé en combat',
  },
  'approval_effect_friendly': {
    AppLanguage.en: '+5% damage in fights',
    AppLanguage.fr: '+5 % de dégâts en combat',
  },
  'approval_effect_wary': {
    AppLanguage.en: '−10% damage in fights; leaves if pushed further',
    AppLanguage.fr: '−10 % de dégâts en combat ; part si cela continue',
  },
  'approval_likes': {
    AppLanguage.en: 'Likes',
    AppLanguage.fr: 'Apprécie',
  },
  'approval_dislikes': {
    AppLanguage.en: 'Dislikes',
    AppLanguage.fr: 'Réprouve',
  },
  'deed_good': {
    AppLanguage.en: 'kindness',
    AppLanguage.fr: 'la bonté',
  },
  'deed_evil': {
    AppLanguage.en: 'cruelty',
    AppLanguage.fr: 'la cruauté',
  },
  'deed_profit': {
    AppLanguage.en: 'profit',
    AppLanguage.fr: 'le profit',
  },
  'approval_approves': {
    AppLanguage.en: '{name} approves.',
    AppLanguage.fr: '{name} approuve.',
  },
  'approval_disapproves': {
    AppLanguage.en: '{name} disapproves.',
    AppLanguage.fr: '{name} désapprouve.',
  },
  'approval_devoted_notice': {
    AppLanguage.en: '{name} trusts you completely now.',
    AppLanguage.fr: '{name} vous accorde désormais toute sa confiance.',
  },
  'approval_wary_notice': {
    AppLanguage.en: '{name} is losing patience with you.',
    AppLanguage.fr: '{name} perd patience avec vous.',
  },
  'approval_leaves_notice': {
    AppLanguage.en: '{name} leaves the party for good.',
    AppLanguage.fr: '{name} quitte le groupe pour de bon.',
  },
  'choice_work_ahead': {
    AppLanguage.en: 'Work on offer',
    AppLanguage.fr: 'Du travail proposé',
  },
  'approval_replaced_notice': {
    AppLanguage.en: '{name} takes {left}’s place in the party.',
    AppLanguage.fr: '{name} prend la place de {left} dans le groupe.',
  },
  'share_drink_button': {
    AppLanguage.en: 'Share a drink ({cost} gold)',
    AppLanguage.fr: 'Partager un verre ({cost} or)',
  },
  'share_drink_done': {
    AppLanguage.en: 'Drink shared this chapter',
    AppLanguage.fr: 'Verre partagé ce chapitre',
  },
  'share_drink_notice': {
    AppLanguage.en: '{name} warms to you.',
    AppLanguage.fr: '{name} vous apprécie un peu plus.',
  },
  // v1.162: enemy intents, weaknesses, taunt.
  'telegraph_category_guard': {
    AppLanguage.en: 'Guard',
    AppLanguage.fr: 'Garde',
  },
  'telegraph_category_charge': {
    AppLanguage.en: 'Wind-up',
    AppLanguage.fr: 'Préparation',
  },
  'telegraph_category_rally': {
    AppLanguage.en: 'Rallying cry',
    AppLanguage.fr: 'Cri de ralliement',
  },
  'charge_release_suffix': {
    AppLanguage.en: 'unleashes the blow it wound up!',
    AppLanguage.fr: ': le coup préparé s’abat !',
  },
  'charge_broken_suffix': {
    AppLanguage.en: 'is knocked off balance: the wind-up is broken!',
    AppLanguage.fr: 'perd l’équilibre : son élan est brisé !',
  },
  'staggered_skip_turn_suffix': {
    AppLanguage.en: 'is still reeling and loses the turn.',
    AppLanguage.fr: 'chancelle encore et perd son tour.',
  },
  'weak_to_suffix': {
    AppLanguage.en: 'is weak to',
    AppLanguage.fr: '— point faible :',
  },
  'resists_suffix': {
    AppLanguage.en: 'resists',
    AppLanguage.fr: '— résistance :',
  },
  'weak_to_label': {
    AppLanguage.en: 'Weak to',
    AppLanguage.fr: 'Point faible :',
  },
  'resists_label': {
    AppLanguage.en: 'Resists',
    AppLanguage.fr: 'Résistance :',
  },
  'guard_soaks_suffix': {
    AppLanguage.en: '— the guard soaks',
    AppLanguage.fr: '— la garde absorbe',
  },
  'enemy_recovers_word': {
    AppLanguage.en: 'recovers',
    AppLanguage.fr: 'récupère',
  },
  'enemy_guards_word': {
    AppLanguage.en: 'raises a guard of',
    AppLanguage.fr: 'lève sa garde :',
  },
  'enemy_winds_up_suffix': {
    AppLanguage.en: 'is winding up a heavy blow. Break it before it lands!',
    AppLanguage.fr:
        'prépare un coup puissant. Brisez son élan avant qu’il ne frappe !',
  },
  'enemy_rallies_message': {
    AppLanguage.en: 'The enemy presses harder',
    AppLanguage.fr: 'L’ennemi redouble d’ardeur',
  },
  'rally_spent_message': {
    AppLanguage.en: 'The pack is already roused to the full.',
    AppLanguage.fr: 'La meute est déjà à son comble.',
  },
  'draws_attacks_suffix': {
    AppLanguage.en: "stands guard and draws the enemy's attacks.",
    AppLanguage.fr: 'monte la garde et attire les coups de l’ennemi.',
  },
  'enemy_guard_tooltip': {
    AppLanguage.en: 'Raised guard: soaks your next hits',
    AppLanguage.fr: 'Garde levée : absorbe vos prochains coups',
  },
  'winding_up_label': {
    AppLanguage.en: 'Winding up',
    AppLanguage.fr: 'Prépare un coup',
  },
  'winding_up_tooltip': {
    AppLanguage.en:
        'Winding up a double-strength blow. Deal a quarter of its health this round, stun it or hit its weakness to break it.',
    AppLanguage.fr:
        'Prépare un coup de double force. Infligez un quart de ses PV ce tour-ci, étourdissez l’ennemi ou frappez son point faible pour briser l’élan.',
  },
  'staggered_label': {
    AppLanguage.en: 'Staggered',
    AppLanguage.fr: 'Déséquilibre',
  },
  'rallied_label': {
    AppLanguage.en: 'Rallied',
    AppLanguage.fr: 'Ardeur',
  },
  'intent_staggered_label': {
    AppLanguage.en: 'Staggered: loses its next turn',
    AppLanguage.fr: 'Déséquilibre : perd son prochain tour',
  },
  'intent_charged_label': {
    AppLanguage.en: 'Charged blow incoming!',
    AppLanguage.fr: 'Coup chargé imminent !',
  },
  'defend_draws_attacks_hint': {
    AppLanguage.en: 'draws attacks',
    AppLanguage.fr: 'attire les coups',
  },
  'element_name_fire': {AppLanguage.en: 'Fire', AppLanguage.fr: 'Feu'},
  'element_name_ice': {AppLanguage.en: 'Ice', AppLanguage.fr: 'Glace'},
  'element_name_void': {AppLanguage.en: 'Void', AppLanguage.fr: 'Vide'},
  'element_name_wind': {AppLanguage.en: 'Wind', AppLanguage.fr: 'Vent'},
  'element_name_water': {AppLanguage.en: 'Water', AppLanguage.fr: 'Eau'},
  'element_name_earth': {AppLanguage.en: 'Earth', AppLanguage.fr: 'Terre'},
  'element_name_electricity': {
    AppLanguage.en: 'Lightning',
    AppLanguage.fr: 'Foudre',
  },
  'element_name_light': {AppLanguage.en: 'Light', AppLanguage.fr: 'Lumière'},
  'telegraph_category_attack': {
    AppLanguage.en: 'Attack',
    AppLanguage.fr: 'Attaque',
  },
  'telegraph_category_heal': {
    AppLanguage.en: 'Self-heal',
    AppLanguage.fr: 'Soin',
  },
  'telegraph_category_debuff': {
    AppLanguage.en: 'Debuff',
    AppLanguage.fr: 'Affaiblissement',
  },
  'the_enemy_label': {AppLanguage.en: 'The enemy', AppLanguage.fr: "L'ennemi"},
  'elite_prefix': {AppLanguage.en: 'Elite', AppLanguage.fr: 'Élite'},
  'critical_hit_suffix': {
    AppLanguage.en: '(Critical Hit!)',
    AppLanguage.fr: '(Coup Critique !)',
  },
  'you_dodge_suffix': {
    AppLanguage.en: 'you dodge it!',
    AppLanguage.fr: 'vous esquivez !',
  },
  'dodges_suffix': {
    AppLanguage.en: 'dodges it!',
    AppLanguage.fr: 'esquive !',
  },
  'updates_section': {
    AppLanguage.en: 'Updates',
    AppLanguage.fr: 'Mises à jour'
  },
  'current_version_label': {
    AppLanguage.en: 'Current version',
    AppLanguage.fr: 'Version actuelle',
  },
  'check_for_updates_button': {
    AppLanguage.en: 'Check for Updates',
    AppLanguage.fr: 'Rechercher des mises à jour',
  },
  'updates_elsewhere_note': {
    AppLanguage.en: "On this device, get new versions from the project's "
        'releases on GitHub.',
    AppLanguage.fr: 'Sur cet appareil, les nouvelles versions se récupèrent '
        'dans les versions publiées du projet sur GitHub.',
  },
  'update_available_suffix_ios': {
    AppLanguage.en: 'is available. Download it now?',
    AppLanguage.fr: 'est disponible. La télécharger maintenant ?',
  },
  'ios_update_hint': {
    AppLanguage.en: 'An iPhone installs it through AltStore or SideStore: '
        'in the screen that opens, use Share to open it in one of them. '
        'Or save it to Files and install it from a computer with '
        'Sideloadly.',
    AppLanguage.fr: "Un iPhone l'installe avec AltStore ou SideStore : dans "
        "l'écran qui s'ouvre, utilisez Partager pour l'ouvrir dans l'une de "
        "ces applications. Ou enregistrez-le dans Fichiers et installez-le "
        'depuis un ordinateur avec Sideloadly.',
  },
  'download_open_button': {
    AppLanguage.en: 'Download & Open',
    AppLanguage.fr: 'Télécharger et ouvrir',
  },
  'ios_open_failed': {
    AppLanguage.en: "Couldn't open the downloaded file. It is also in the "
        'latest release on GitHub.',
    AppLanguage.fr: "Impossible d'ouvrir le fichier téléchargé. Il se trouve "
        'aussi dans la dernière version publiée sur GitHub.',
  },
  'checking_for_updates': {
    AppLanguage.en: 'Checking…',
    AppLanguage.fr: 'Recherche en cours…'
  },
  'up_to_date_message': {
    AppLanguage.en: "You're up to date.",
    AppLanguage.fr: 'Vous êtes à jour.'
  },
  'update_check_failed': {
    AppLanguage.en: 'Could not check for updates. Try again later.',
    AppLanguage.fr:
        'Impossible de vérifier les mises à jour. Réessayez plus tard.',
  },
  'update_check_needs_token': {
    AppLanguage.en: 'This repository is private — set a GitHub Personal '
        'Access Token below (in Edit mode) to check for updates.',
    AppLanguage.fr: 'Ce dépôt est privé — définissez un jeton d\'accès '
        'personnel GitHub ci-dessous (en mode Édition) pour rechercher '
        'des mises à jour.',
  },
  'update_available_title': {
    AppLanguage.en: 'Update available',
    AppLanguage.fr: 'Mise à jour disponible',
  },
  'update_available_prefix': {
    AppLanguage.en: 'Version',
    AppLanguage.fr: 'La version'
  },
  'update_available_suffix': {
    AppLanguage.en: 'is available. Download and install it now?',
    AppLanguage.fr:
        "est disponible. La télécharger et l'installer maintenant ?",
  },
  'download_install_button': {
    AppLanguage.en: 'Download & Install',
    AppLanguage.fr: 'Télécharger et installer',
  },
  'downloading_label': {
    AppLanguage.en: 'Downloading…',
    AppLanguage.fr: 'Téléchargement…'
  },
  'download_failed': {
    AppLanguage.en: 'Download failed. Try again later.',
    AppLanguage.fr: 'Échec du téléchargement. Réessayez plus tard.',
  },
  'install_failed': {
    AppLanguage.en: "Couldn't start the installer. If prompted, allow this "
        'app to install unknown apps, then try again.',
    AppLanguage.fr: "Impossible de lancer l'installation. Si demandé, "
        'autorisez cette application à installer des applications inconnues, '
        'puis réessayez.',
  },
  'theme_mode_section': {
    AppLanguage.en: 'Appearance',
    AppLanguage.fr: 'Apparence'
  },
  'theme_mode_system': {AppLanguage.en: 'System', AppLanguage.fr: 'Système'},
  'theme_mode_light': {AppLanguage.en: 'Light', AppLanguage.fr: 'Clair'},
  'theme_mode_dark': {AppLanguage.en: 'Dark', AppLanguage.fr: 'Sombre'},
  'your_stats_label': {
    AppLanguage.en: 'Your Stats',
    AppLanguage.fr: 'Vos statistiques'
  },
  'enemy_stats_label': {
    AppLanguage.en: 'Enemy Stats',
    AppLanguage.fr: "Statistiques de l'ennemi"
  },
  'permadeath_setting_title': {
    AppLanguage.en: 'Permadeath',
    AppLanguage.fr: 'Mort permanente'
  },
  'permadeath_setting_desc': {
    AppLanguage.en:
        'When enabled, losing a fight sends the same character back to the '
            'beginning of the story. You keep your level, stats, gold and '
            'companions, but lose all items and your skills return to your '
            'class basics. Ironman: saved games can’t be loaded, and a death '
            'deletes them.',
    AppLanguage.fr: 'Une fois activée, perdre un combat renvoie le même personnage au début de '
        "l'histoire. Vous conservez votre niveau, vos statistiques, votre or et vos compagnons, "
        'mais perdez tous vos objets et vos compétences reviennent aux bases de votre classe. '
        'Mode Ironman : les sauvegardes ne peuvent pas être chargées, et une mort les efface.',
  },
  'you_died_title': {
    AppLanguage.en: 'You Died',
    AppLanguage.fr: 'Vous avez péri'
  },
  'you_died_message': {
    AppLanguage.en:
        'The story starts over with you. You keep your level, stats, gold '
            'and companions; your pack is empty and your skills are back to '
            'your class basics. Your saved games are gone with the rest.',
    AppLanguage.fr:
        "L'histoire recommence avec vous. Vous conservez votre niveau, vos statistiques, "
            'votre or et vos compagnons ; votre sac est vide et vos compétences '
            'reviennent aux bases de votre classe. Vos sauvegardes sont parties avec le reste.',
  },
  'items_lost_label': {
    AppLanguage.en: 'Items lost',
    AppLanguage.fr: 'Objets perdus'
  },
  'return_to_start_button': {
    AppLanguage.en: 'Return to the Beginning',
    AppLanguage.fr: 'Retourner au début',
  },
  'dev_tools_section': {
    AppLanguage.en: 'Developer Tools',
    AppLanguage.fr: 'Outils de développement',
  },
  'auto_playthrough_button': {
    AppLanguage.en: 'Simulate a Playthrough',
    AppLanguage.fr: 'Simuler une partie',
  },
  'simulating_label': {
    AppLanguage.en: 'Simulating…',
    AppLanguage.fr: 'Simulation en cours…'
  },
  'structural_audit_button': {
    AppLanguage.en: 'Audit Graph Structure',
    AppLanguage.fr: 'Auditer la structure du graphe',
  },
  'structural_audit_clean_title': {
    AppLanguage.en: 'Graph is structurally clean',
    AppLanguage.fr: 'Le graphe est structurellement propre',
  },
  'structural_audit_issues_title': {
    AppLanguage.en: 'Graph issues found',
    AppLanguage.fr: 'Problèmes de graphe détectés',
  },
  'structural_audit_endings_label': {
    AppLanguage.en: 'Reachable endings',
    AppLanguage.fr: 'Fins atteignables',
  },
  'structural_audit_unreachable_label': {
    AppLanguage.en: 'Unreachable nodes',
    AppLanguage.fr: 'Nœuds inaccessibles',
  },
  'structural_audit_dead_ends_label': {
    AppLanguage.en: 'Dead ends',
    AppLanguage.fr: 'Impasses',
  },
  'structural_audit_broken_links_label': {
    AppLanguage.en: 'Broken links',
    AppLanguage.fr: 'Liens rompus',
  },
  'analyze_with_gemini_button': {
    AppLanguage.en: 'Analyze with Gemini',
    AppLanguage.fr: 'Analyser avec Gemini',
  },
  'analyzing_label': {
    AppLanguage.en: 'Analyzing…',
    AppLanguage.fr: 'Analyse en cours…'
  },
  'playthrough_recap_title': {
    AppLanguage.en: 'Playthrough Recap',
    AppLanguage.fr: 'Récapitulatif de la partie',
  },
  'ending_reached_label': {
    AppLanguage.en: 'Ending reached',
    AppLanguage.fr: 'Fin atteinte'
  },
  'nodes_visited_label': {
    AppLanguage.en: 'Nodes visited',
    AppLanguage.fr: 'Nœuds visités'
  },
  'final_level_label': {
    AppLanguage.en: 'Final level',
    AppLanguage.fr: 'Niveau final'
  },
  'final_gold_label': {
    AppLanguage.en: 'Final gold',
    AppLanguage.fr: 'Or final'
  },
  'final_alignment_label': {
    AppLanguage.en: 'Final alignment',
    AppLanguage.fr: 'Alignement final',
  },
  'quests_completed_label': {
    AppLanguage.en: 'Quests completed',
    AppLanguage.fr: 'Quêtes terminées',
  },
  'path_summary_label': {
    AppLanguage.en: 'Your Journey',
    AppLanguage.fr: 'Votre parcours'
  },
  'discovery_title': {
    AppLanguage.en: 'Discovered!',
    AppLanguage.fr: 'Découverte !'
  },
  'shop_discovered_message': {
    AppLanguage.en: 'A new shop is available:',
    AppLanguage.fr: 'Une nouvelle boutique est disponible :',
  },
  'quest_discovered_message': {
    AppLanguage.en: 'A new quest is available:',
    AppLanguage.fr: 'Une nouvelle quête est disponible :',
  },
  'open_shop_button': {
    AppLanguage.en: 'Open Shop',
    AppLanguage.fr: 'Ouvrir la boutique'
  },
  'view_quest_button': {
    AppLanguage.en: 'View Quest',
    AppLanguage.fr: 'Voir la quête'
  },
  'maybe_later_button': {
    AppLanguage.en: 'Maybe Later',
    AppLanguage.fr: 'Plus tard'
  },
  'shops_discovered_label': {
    AppLanguage.en: 'Shops discovered',
    AppLanguage.fr: 'Boutiques découvertes',
  },
  'quests_discovered_label': {
    AppLanguage.en: 'Quests discovered',
    AppLanguage.fr: 'Quêtes découvertes',
  },
  'combat_encounters_label': {
    AppLanguage.en: 'Combat encounters',
    AppLanguage.fr: 'Rencontres de combat',
  },
  'fixed_face_label': {AppLanguage.en: 'Fixed', AppLanguage.fr: 'Fixe'},
  'only_suffix': {AppLanguage.en: 'only', AppLanguage.fr: 'seulement'},
  'xp_earned_label': {
    AppLanguage.en: 'XP earned this run',
    AppLanguage.fr: 'XP gagnée cette partie'
  },
  'equip_button': {AppLanguage.en: 'Equip', AppLanguage.fr: 'Équiper'},
  'sold_out_label': {AppLanguage.en: 'Sold out', AppLanguage.fr: 'Épuisé'},
  'left_suffix': {AppLanguage.en: 'left', AppLanguage.fr: 'restant(s)'},
  'compare_button': {AppLanguage.en: 'Compare', AppLanguage.fr: 'Comparer'},
  'compare_hint_items': {
    AppLanguage.en: 'Tap two items to compare them.',
    AppLanguage.fr: 'Touchez deux objets pour les comparer.',
  },
  'compare_hint_skills': {
    AppLanguage.en: 'Tap two skills to compare them.',
    AppLanguage.fr: 'Touchez deux compétences pour les comparer.',
  },
  'compare_first_selected': {
    AppLanguage.en: 'Selected. Now tap a second one to compare.',
    AppLanguage.fr: 'Sélectionné. Touchez-en un second pour comparer.',
  },
  'vs_equipped_suffix': {
    AppLanguage.en: '(equipped)',
    AppLanguage.fr: '(équipé)'
  },
  'category_label': {AppLanguage.en: 'Category', AppLanguage.fr: 'Catégorie'},
  'required_gold_label': {
    AppLanguage.en: 'Required Gold',
    AppLanguage.fr: 'Or requis'
  },
  'required_flags_label': {
    AppLanguage.en: 'Requires',
    AppLanguage.fr: 'Nécessite'
  },
  'reward_gold_label': {
    AppLanguage.en: 'Reward Gold',
    AppLanguage.fr: 'Récompense (or)'
  },
  'reward_xp_label': {
    AppLanguage.en: 'Reward XP',
    AppLanguage.fr: 'Récompense (XP)'
  },
  'reward_item_label': {
    AppLanguage.en: 'Reward Item',
    AppLanguage.fr: 'Récompense (objet)'
  },
  'reward_dice_label': {
    AppLanguage.en: 'Reward Die',
    AppLanguage.fr: 'Récompense (dé)'
  },
  'github_sync_title': {
    AppLanguage.en: 'GitHub Sync',
    AppLanguage.fr: 'Synchronisation GitHub'
  },
  'github_sync_desc': {
    AppLanguage.en:
        'Edits made in the Data tab and Story editor stay on this device until '
            'you push them to GitHub as a branch. Needs a Personal Access Token with '
            'Contents: Read and write on this repo. Stored only on this device.',
    AppLanguage.fr:
        "Les modifications faites dans l'onglet Données et l'éditeur d'histoire "
            "restent sur cet appareil tant qu'elles ne sont pas envoyées sur GitHub sous forme "
            "de branche. Nécessite un jeton d'accès personnel avec accès Contents: Read and "
            "write sur ce dépôt. Stocké uniquement sur cet appareil.",
  },
  'github_token_label': {
    AppLanguage.en: 'GitHub Personal Access Token',
    AppLanguage.fr: "Jeton d'accès personnel GitHub",
  },
  'show_token_tooltip': {
    AppLanguage.en: 'Show token',
    AppLanguage.fr: 'Afficher le jeton'
  },
  'hide_token_tooltip': {
    AppLanguage.en: 'Hide token',
    AppLanguage.fr: 'Masquer le jeton'
  },
  'github_token_saved': {
    AppLanguage.en: 'Token saved.',
    AppLanguage.fr: 'Jeton enregistré.'
  },
  'github_token_removed': {
    AppLanguage.en: 'Token removed.',
    AppLanguage.fr: 'Jeton supprimé.'
  },
  'push_edits_button': {
    AppLanguage.en: 'Push Local Edits to GitHub',
    AppLanguage.fr: 'Envoyer les modifications vers GitHub',
  },
  'no_local_edits_message': {
    AppLanguage.en:
        'No local edits to push — the Data tab and story editor are unchanged from the bundled defaults.',
    AppLanguage.fr:
        "Aucune modification locale à envoyer — l'onglet Données et l'éditeur "
            "d'histoire sont inchangés par rapport aux valeurs par défaut.",
  },
  'set_github_token_first_message': {
    AppLanguage.en: 'Set your GitHub token above first.',
    AppLanguage.fr: "Renseignez d'abord votre jeton GitHub ci-dessus.",
  },
  'push_confirm_title': {
    AppLanguage.en: 'Push to GitHub?',
    AppLanguage.fr: 'Envoyer vers GitHub ?'
  },
  'push_confirm_message': {
    AppLanguage.en:
        'This will push the following changed files to a new branch:',
    AppLanguage.fr:
        'Cela enverra les fichiers modifiés suivants vers une nouvelle branche :',
  },
  'branch_name_label': {
    AppLanguage.en: 'Branch name',
    AppLanguage.fr: 'Nom de la branche'
  },
  'pushing_label': {
    AppLanguage.en: 'Pushing…',
    AppLanguage.fr: 'Envoi en cours…'
  },
  'push_success_title': {AppLanguage.en: 'Pushed!', AppLanguage.fr: 'Envoyé !'},
  'push_success_message': {
    AppLanguage.en:
        'Your edits are now on a new branch. Open a pull request to bring them into the game.',
    AppLanguage.fr:
        'Vos modifications sont maintenant sur une nouvelle branche. Ouvrez une '
            'pull request pour les intégrer au jeu.',
  },
  'copy_link_button': {
    AppLanguage.en: 'Copy Link',
    AppLanguage.fr: 'Copier le lien'
  },
  'link_copied_message': {
    AppLanguage.en: 'Link copied.',
    AppLanguage.fr: 'Lien copié.'
  },
  'push_failed_prefix': {
    AppLanguage.en: 'Push failed',
    AppLanguage.fr: "Échec de l'envoi"
  },
  'push_button': {AppLanguage.en: 'Push', AppLanguage.fr: 'Envoyer'},
  'strategy_label': {AppLanguage.en: 'Strategy', AppLanguage.fr: 'Stratégie'},
  'play_to_chapter_title': {
    AppLanguage.en: 'Play to Chapter',
    AppLanguage.fr: 'Jouer jusqu\'au chapitre',
  },
  'play_to_chapter_subtitle': {
    AppLanguage.en: 'Plays real choices forward using the strategy above, '
        'earning true gold/alignment/flags/combat along the way, then '
        'hands control back to you in Story view once the chapter is '
        'reached. A run that is lost on the way is undone and played '
        'again until one gets there.',
    AppLanguage.fr:
        "Enchaîne de vrais choix selon la stratégie ci-dessus, avec de "
            "l'or, un alignement, des drapeaux et des combats réellement "
            "gagnés, puis vous redonne la main dans la vue Histoire une "
            'fois le chapitre atteint. Une partie perdue en chemin est '
            'annulée et rejouée jusqu’à ce qu’une y parvienne.',
  },
  'play_to_chapter_button': {
    AppLanguage.en: 'Play to Chapter',
    AppLanguage.fr: 'Jouer jusqu\'au chapitre',
  },
  'sim_character_label': {
    AppLanguage.en: 'Character',
    AppLanguage.fr: 'Personnage'
  },
  'sim_fights_label': {
    AppLanguage.en: 'Fights won / lost',
    AppLanguage.fr: 'Combats gagnés / perdus'
  },
  'sim_spells_cast_label': {
    AppLanguage.en: 'Spells cast',
    AppLanguage.fr: 'Sorts lancés'
  },
  'sim_mana_from_dice_label': {
    AppLanguage.en: 'Mana from dice',
    AppLanguage.fr: 'Mana gagné aux dés'
  },
  'sim_by_profession_label': {
    AppLanguage.en: 'By profession',
    AppLanguage.fr: 'Par classe'
  },
  'sim_no_spells_cast': {
    AppLanguage.en: 'No spells cast',
    AppLanguage.fr: 'Aucun sort lancé'
  },
  'sim_fight_won_label': {AppLanguage.en: 'won', AppLanguage.fr: 'gagné'},
  'sim_fight_lost_label': {AppLanguage.en: 'lost', AppLanguage.fr: 'perdu'},
  'sim_attempts_label': {
    AppLanguage.en: 'attempts',
    AppLanguage.fr: 'tentatives'
  },
  'sim_runs_casting_label': {
    AppLanguage.en: 'runs casting',
    AppLanguage.fr: 'parties l\'ayant lancé'
  },
  'sim_combat_model_note': {
    AppLanguage.en:
        'Fights: a solo character of a random race and profession, the real dice, enemy moves, statuses, chapter curve and spells; no companions, affixes or conditions. Shops are visited once when unlocked; a new chapter counts as a rest.',
    AppLanguage.fr:
        "Combats : un personnage seul de race et classe aléatoires, les vrais dés, coups ennemis, statuts, courbe de chapitre et sorts ; sans compagnons, affixes ni conditions. Chaque boutique est visitée une fois au déblocage ; un nouveau chapitre vaut un repos.",
  },
  'sim_strategy_random': {
    AppLanguage.en: 'Random',
    AppLanguage.fr: 'Aléatoire'
  },
  'sim_strategy_favor_good': {
    AppLanguage.en: 'Favor Good',
    AppLanguage.fr: 'Favoriser le bien'
  },
  'sim_strategy_favor_evil': {
    AppLanguage.en: 'Favor Evil',
    AppLanguage.fr: 'Favoriser le mal'
  },
  'sim_strategy_maximize_gold': {
    AppLanguage.en: 'Maximize Gold',
    AppLanguage.fr: "Maximiser l'or",
  },
  'runs_label': {AppLanguage.en: 'Runs', AppLanguage.fr: 'Parties'},
  'clear_all_button': {
    AppLanguage.en: 'Clear All',
    AppLanguage.fr: 'Tout effacer'
  },
  'no_batches_yet_message': {
    AppLanguage.en: 'Run a simulation to see results here.',
    AppLanguage.fr: 'Lancez une simulation pour voir les résultats ici.',
  },
  'endings_label': {AppLanguage.en: 'Endings', AppLanguage.fr: 'Fins'},
  'companions_encountered_label': {
    AppLanguage.en: 'Companions encountered',
    AppLanguage.fr: 'Compagnons rencontrés',
  },
  'individual_runs_label': {
    AppLanguage.en: 'Individual Runs',
    AppLanguage.fr: 'Parties individuelles'
  },
  'exceeded_step_cap_label': {
    AppLanguage.en: 'did not reach an ending (hit the step limit)',
    AppLanguage.fr: "n'ont pas atteint de fin (limite de pas atteinte)",
  },
  'furthest_chapter_label': {
    AppLanguage.en: 'Furthest chapter reached',
    AppLanguage.fr: 'Chapitre le plus avancé atteint',
  },
  'unique_nodes_visited_label': {
    AppLanguage.en: 'Unique nodes visited',
    AppLanguage.fr: 'Nœuds uniques visités',
  },
  'total_steps_label': {
    AppLanguage.en: 'total steps',
    AppLanguage.fr: 'pas au total'
  },
  'flags_collected_label': {
    AppLanguage.en: 'Flags collected',
    AppLanguage.fr: 'Drapeaux collectés'
  },
  'chapter_breakdown_label': {
    AppLanguage.en: 'By Chapter',
    AppLanguage.fr: 'Par chapitre'
  },
  'by_location_label': {
    AppLanguage.en: 'By Location',
    AppLanguage.fr: 'Par lieu'
  },
  'by_mood_label': {AppLanguage.en: 'By Mood', AppLanguage.fr: 'Par ambiance'},
  'filter_runs_label': {
    AppLanguage.en: 'Filter runs',
    AppLanguage.fr: 'Filtrer les parties'
  },
  'ending_filter_all': {
    AppLanguage.en: 'All endings',
    AppLanguage.fr: 'Toutes les fins'
  },
  'min_chapter_filter_label': {
    AppLanguage.en: 'Min. chapter',
    AppLanguage.fr: 'Chapitre min.'
  },
  'any_label': {AppLanguage.en: 'Any', AppLanguage.fr: 'Tous'},
  'stuck_only_filter': {
    AppLanguage.en: 'Stuck only',
    AppLanguage.fr: 'Bloquées seulement'
  },
  'no_runs_match_filter': {
    AppLanguage.en: 'No runs match this filter.',
    AppLanguage.fr: 'Aucune partie ne correspond à ce filtre.',
  },
  'show_all_runs_label': {
    AppLanguage.en: 'Show all',
    AppLanguage.fr: 'Tout afficher'
  },
  'show_less_label': {
    AppLanguage.en: 'Show less',
    AppLanguage.fr: 'Afficher moins'
  },
  'collapse_batch_label': {
    AppLanguage.en: 'Collapse',
    AppLanguage.fr: 'Réduire'
  },
  'expand_batch_label': {
    AppLanguage.en: 'Expand',
    AppLanguage.fr: 'Développer'
  },
  'hide_options_tooltip': {
    AppLanguage.en: 'Hide options',
    AppLanguage.fr: 'Masquer les options'
  },
  'export_button': {AppLanguage.en: 'Export', AppLanguage.fr: 'Exporter'},
  'copy_button': {AppLanguage.en: 'Copy', AppLanguage.fr: 'Copier'},
  'export_all_runs_button': {
    AppLanguage.en: 'Export all runs',
    AppLanguage.fr: 'Exporter toutes les parties',
  },
  'export_as_text': {
    AppLanguage.en: 'Export as text (.txt)',
    AppLanguage.fr: 'Exporter en texte (.txt)',
  },
  'export_as_csv': {
    AppLanguage.en: 'Export as spreadsheet (.csv)',
    AppLanguage.fr: 'Exporter en tableur (.csv)',
  },
  'export_as_json': {
    AppLanguage.en: 'Export as data (.json)',
    AppLanguage.fr: 'Exporter en données (.json)',
  },
  'transcript_copied_message': {
    AppLanguage.en: 'Transcript copied to clipboard.',
    AppLanguage.fr: 'Transcription copiée dans le presse-papiers.',
  },
  'export_failed_prefix': {
    AppLanguage.en: 'Export failed',
    AppLanguage.fr: "Échec de l'export"
  },
  'chapter_filter_all_label': {AppLanguage.en: 'All', AppLanguage.fr: 'Tout'},
  'prologue_label': {AppLanguage.en: 'Prologue', AppLanguage.fr: 'Prologue'},
  'read_aloud_tooltip': {
    AppLanguage.en: 'Read aloud',
    AppLanguage.fr: 'Lire à voix haute'
  },
  'stop_reading_tooltip': {
    AppLanguage.en: 'Stop reading',
    AppLanguage.fr: 'Arrêter la lecture'
  },
  'loading_voice_tooltip': {
    AppLanguage.en: 'Loading voice…',
    AppLanguage.fr: 'Chargement de la voix…',
  },
  'app_mode_section_title': {
    AppLanguage.en: 'App Mode',
    AppLanguage.fr: "Mode de l'application"
  },
  'app_mode_section_desc': {
    AppLanguage.en:
        'Edit mode has the full toolset (Map, Generate, Data, node editing, dev '
            'tools). In-Game mode hides all of that for a clean, player-only experience — just '
            'Story and Play.',
    AppLanguage.fr:
        'Le mode Édition donne accès à tous les outils (Carte, Générer, Données, '
            'édition des nœuds, outils de développement). Le mode En jeu masque tout cela pour '
            'une expérience réservée au joueur — seulement Histoire et Jouer.',
  },
  'edit_mode_label': {AppLanguage.en: 'Edit', AppLanguage.fr: 'Édition'},
  'in_game_mode_label': {AppLanguage.en: 'In-Game', AppLanguage.fr: 'En jeu'},
  'mode_nudge_message': {
    AppLanguage.en:
        "You're in Edit Mode, which shows story/data-editing tools alongside the "
            'game. Just here to play? Switch to In-Game Mode in Settings for a clean, '
            'player-only view.',
    AppLanguage.fr:
        "Vous êtes en mode Édition, qui affiche les outils d'édition de l'histoire "
            'et des données en plus du jeu. Juste ici pour jouer ? Passez en mode En jeu dans les '
            "paramètres pour une vue réservée au joueur.",
  },
  'switch_to_in_game_mode_button': {
    AppLanguage.en: 'Switch to In-Game Mode',
    AppLanguage.fr: 'Passer en mode En jeu',
  },
  'tutorial_setting_title': {
    AppLanguage.en: 'Tutorials',
    AppLanguage.fr: 'Tutoriels',
  },
  'tutorial_setting_desc': {
    AppLanguage.en:
        'Your companion shows you each feature the first time you find it.',
    AppLanguage.fr:
        'Votre compagnon vous présente chaque fonctionnalité la première fois que vous la découvrez.',
  },
  'tutorial_replay_button': {
    AppLanguage.en: 'Show all tutorials again',
    AppLanguage.fr: 'Revoir tous les tutoriels',
  },
  'tutorial_reset_notice': {
    AppLanguage.en: 'Each tutorial will play again the next time you reach it.',
    AppLanguage.fr:
        'Chaque tutoriel sera rejoué la prochaine fois que vous y arriverez.',
  },
  'tutorials_section': {
    AppLanguage.en: 'Tutorials',
    AppLanguage.fr: 'Tutoriels',
  },
  'tutorials_section_hint': {
    AppLanguage.en: 'Replay a tour of any feature.',
    AppLanguage.fr: "Revoir la visite d'une fonctionnalité.",
  },
  'tut_seen_label': {
    AppLanguage.en: 'Seen',
    AppLanguage.fr: 'Vu',
  },
  'tut_new_label': {
    AppLanguage.en: 'New',
    AppLanguage.fr: 'Nouveau',
  },
  'tut_skip': {
    AppLanguage.en: 'Skip',
    AppLanguage.fr: 'Passer',
  },
  'tut_next': {
    AppLanguage.en: 'Next',
    AppLanguage.fr: 'Suivant',
  },
  'tut_done': {
    AppLanguage.en: 'Got it!',
    AppLanguage.fr: 'Compris !',
  },
  'remark_done': {
    AppLanguage.en: 'Go on',
    AppLanguage.fr: 'Continuer',
  },
  'tut_voice_on': {
    AppLanguage.en: 'Read aloud',
    AppLanguage.fr: 'Lire à voix haute',
  },
  'tut_voice_off': {
    AppLanguage.en: 'Stop reading aloud',
    AppLanguage.fr: 'Arrêter la lecture',
  },
  'tut_guide_default_name': {
    AppLanguage.en: 'your companion',
    AppLanguage.fr: 'votre compagnon',
  },
  'tut_story_title': {
    AppLanguage.en: 'The story',
    AppLanguage.fr: "L'histoire",
  },
  'tut_character_title': {
    AppLanguage.en: 'Your character',
    AppLanguage.fr: 'Votre personnage',
  },
  'tut_camp_title': {
    AppLanguage.en: 'The camp',
    AppLanguage.fr: 'Le camp',
  },
  'tut_other_title': {
    AppLanguage.en: 'The Other tab',
    AppLanguage.fr: "L'onglet Autre",
  },
  'tut_map_title': {
    AppLanguage.en: 'The world map',
    AppLanguage.fr: 'La carte du monde',
  },
  'tut_skills_title': {
    AppLanguage.en: 'Skills',
    AppLanguage.fr: 'Compétences',
  },
  'tut_dice_title': {
    AppLanguage.en: 'Dice',
    AppLanguage.fr: 'Dés',
  },
  'tut_inventory_title': {
    AppLanguage.en: 'Inventory',
    AppLanguage.fr: 'Inventaire',
  },
  'tut_levelUp_title': {
    AppLanguage.en: 'Level up',
    AppLanguage.fr: 'Montée de niveau',
  },
  'tut_fight_title': {
    AppLanguage.en: 'Dice combat',
    AppLanguage.fr: 'Combat aux dés',
  },
  'tut_skillChallenge_title': {
    AppLanguage.en: 'Skill challenges',
    AppLanguage.fr: 'Épreuves de compétence',
  },
  'tut_boat_title': {
    AppLanguage.en: 'The Harbor',
    AppLanguage.fr: 'Le port',
  },
  'tut_voyage_title': {
    AppLanguage.en: 'Voyages',
    AppLanguage.fr: 'Traversées',
  },
  'tut_shipBattle_title': {
    AppLanguage.en: 'Ship battles',
    AppLanguage.fr: 'Batailles navales',
  },
  'tut_expedition_title': {
    AppLanguage.en: 'Expeditions',
    AppLanguage.fr: 'Expéditions',
  },
  'tut_town_title': {
    AppLanguage.en: 'Towns and ports',
    AppLanguage.fr: 'Villes et ports',
  },
  'tut_shop_title': {
    AppLanguage.en: 'Shops',
    AppLanguage.fr: 'Boutiques',
  },
  'tut_journal_title': {
    AppLanguage.en: 'The journal',
    AppLanguage.fr: 'Le journal',
  },
  'tut_achievements_title': {
    AppLanguage.en: 'Achievements',
    AppLanguage.fr: 'Succès',
  },
  'tut_story_1': {
    AppLanguage.en:
        "Woof! I'm {name}. The first time you find something new, I'll show you around. Tap anywhere to go on, or Skip whenever you like.",
    AppLanguage.fr:
        "Wouf ! Je suis {name}. La première fois que vous découvrez quelque chose, je vous fais visiter. Touchez l'écran pour continuer, ou Passer quand vous voulez.",
  },
  'tut_story_2': {
    AppLanguage.en: 'This is the chapter you are in.',
    AppLanguage.fr: 'Voici le chapitre en cours.',
  },
  'tut_story_3': {
    AppLanguage.en:
        'Your level, health, mana and gold. Tap them for alignment, quests and more. The book opens your journal; the speaker reads the page aloud.',
    AppLanguage.fr:
        "Votre niveau, votre santé, votre mana et votre or. Touchez-les pour l'alignement, les quêtes et plus encore. Le livre ouvre le journal ; le haut-parleur lit la page.",
  },
  'tut_story_4': {
    AppLanguage.en:
        'The story itself. Scroll to read on, or double-tap the text to read it full screen.',
    AppLanguage.fr:
        "L'histoire elle-même. Faites défiler pour lire la suite, ou touchez deux fois le texte pour le lire en plein écran.",
  },
  'tut_story_5': {
    AppLanguage.en:
        "Choose what you do. Tags show what a choice costs or brings. A padlock means you can't take it yet.",
    AppLanguage.fr:
        'Choisissez ce que vous faites. Les étiquettes montrent ce que coûte ou rapporte un choix. Un cadenas : pas encore possible.',
  },
  'tut_story_6': {
    AppLanguage.en:
        "And that's me! I trot along each time the story moves on. The arrow tucks me away.",
    AppLanguage.fr:
        "Et ça, c'est moi ! Je trottine à chaque fois que l'histoire avance. La flèche me range.",
  },
  'tut_story_7': {
    AppLanguage.en: 'The map shows every place the story has reached.',
    AppLanguage.fr: "La carte montre chaque lieu atteint par l'histoire.",
  },
  'tut_journey_title': {
    AppLanguage.en: 'The Journey',
    AppLanguage.fr: 'Le Parcours',
  },
  'tut_journey_1': {
    AppLanguage.en:
        'This is the Journey: the same story as the Story tab, told on a map, so you can see where each way leads before you take it.',
    AppLanguage.fr:
        "Voici le Parcours : la même histoire que dans l'onglet Histoire, racontée sur une carte, pour voir où mène chaque chemin avant de le prendre.",
  },
  'tut_journey_2': {
    AppLanguage.en:
        'The scene you are in. Fold it to give the map more room, or double-tap it to read it full screen.',
    AppLanguage.fr:
        'La scène où vous êtes. Repliez-la pour laisser plus de place à la carte, ou touchez-la deux fois pour la lire en plein écran.',
  },
  'tut_journey_3': {
    AppLanguage.en:
        'Your mark, with a step round it for each thing to do here; the ways to other places sit at the edge, in their true direction. A step’s icon and colour say what it holds. The road behind you is below.',
    AppLanguage.fr:
        'Votre repère, entouré d’une étape pour chaque chose à faire ici ; les chemins vers d’autres lieux sont au bord, dans leur vraie direction. L’icône et la couleur d’une étape disent ce qu’elle réserve. Plus bas, la route parcourue.',
  },
  'tut_journey_4': {
    AppLanguage.en:
        'Tap a step to see what it costs or brings. Go, or a second tap on the step, walks the party there.',
    AppLanguage.fr:
        'Touchez une étape pour voir ce qu’elle coûte ou rapporte. « Partir », ou un second toucher sur l’étape, y mène le groupe.',
  },
  'tut_journey_5': {
    AppLanguage.en:
        'Story and Journey are two views of the same tale: switch between them whenever you like.',
    AppLanguage.fr:
        'Histoire et Parcours sont deux vues du même récit : passez de l’une à l’autre quand vous voulez.',
  },
  'tut_story_8': {
    AppLanguage.en:
        'Your character, your camp and everything else live down here. A dot means something is waiting for you.',
    AppLanguage.fr:
        'Votre personnage, votre camp et tout le reste sont ici. Un point signale que quelque chose vous attend.',
  },
  'tut_camp_5': {
    AppLanguage.en:
        'Sea: the Rusty Eel, the Harbor, and the chart. Sail to a port for its expeditions.',
    AppLanguage.fr:
        'Mer : le Rusty Eel, le port et la carte. Faites voile vers un port pour ses expéditions.',
  },
  'tut_character_1': {
    AppLanguage.en: 'This is you: level and experience, health, mana and gold.',
    AppLanguage.fr: "C'est vous : niveau et expérience, santé, mana et or.",
  },
  'tut_character_2': {
    AppLanguage.en:
        'Your choices tip you toward Good or Evil. Past either mark, the story changes, and so do I.',
    AppLanguage.fr:
        "Vos choix vous font pencher vers le Bien ou le Mal. Au-delà d'une marque, l'histoire change, et moi aussi.",
  },
  'tut_character_3': {
    AppLanguage.en:
        'Your eight abilities. They back story checks and fights. Hold one to see its full name.',
    AppLanguage.fr:
        'Vos huit caractéristiques. Elles servent aux épreuves et aux combats. Maintenez-en une pour voir son nom.',
  },
  'tut_character_4': {
    AppLanguage.en:
        'From here: your gear, your skills, your level-up points and your dice.',
    AppLanguage.fr:
        "D'ici : votre équipement, vos compétences, vos points de niveau et vos dés.",
  },
  'tut_camp_1': {
    AppLanguage.en:
        'Town: your cliff town. Every house you build climbs the cliff, and its shops open here.',
    AppLanguage.fr:
        'Ville : votre ville sur la falaise. Chaque maison bâtie grimpe la falaise, et ses boutiques ouvrent ici.',
  },
  'tut_camp_2': {
    AppLanguage.en:
        'Pick a house or an addition to see where it would go, then build it with gold.',
    AppLanguage.fr:
        "Choisissez une maison ou un ajout pour voir où il irait, puis construisez-le avec de l'or.",
  },
  'tut_camp_3': {
    AppLanguage.en:
        'The Harbor, once you build it. Your boat is refitted there.',
    AppLanguage.fr:
        'Le port, une fois construit. On y remet votre bateau en état.',
  },
  'tut_camp_4': {
    AppLanguage.en:
        'Party: companions you recruit rest here. Choose who fights at your side.',
    AppLanguage.fr:
        'Groupe : vos compagnons se reposent ici. Choisissez qui combat à vos côtés.',
  },
  'tut_other_1': {
    AppLanguage.en: 'Save your game here, or load another one.',
    AppLanguage.fr: 'Sauvegardez ici, ou chargez une autre partie.',
  },
  'tut_other_2': {
    AppLanguage.en:
        "The achievements you've earned, and the ones still waiting.",
    AppLanguage.fr: 'Les succès obtenus, et ceux qui vous attendent.',
  },
  'tut_other_3': {
    AppLanguage.en:
        "Quests, shops, the bestiary and the people you've met. New entries get a count.",
    AppLanguage.fr:
        'Quêtes, boutiques, bestiaire et personnes rencontrées. Les nouveautés sont comptées.',
  },
  'tut_other_4': {
    AppLanguage.en:
        'And here you can replay any of my tours, whenever you like.',
    AppLanguage.fr:
        "Et ici, vous pouvez revoir n'importe laquelle de mes visites.",
  },
  'tut_map_1': {
    AppLanguage.en:
        'The chart of your journey. Places appear as the story reaches them. Tap one to read about it; pinch to zoom.',
    AppLanguage.fr:
        "La carte de votre voyage. Les lieux apparaissent quand l'histoire les atteint. Touchez-en un pour le découvrir ; pincez pour zoomer.",
  },
  'tut_map_2': {
    AppLanguage.en:
        'Zoom, find where you stand, or walk the whole journey again. The switches change how the chart looks and the shape of the land.',
    AppLanguage.fr:
        'Zoomez, retrouvez où vous êtes, ou refaites tout le voyage. Les boutons changent le style de la carte et la forme des terres.',
  },
  'tut_map_3': {
    AppLanguage.en: 'Each chapter has its colour. Tap one to see its places.',
    AppLanguage.fr:
        'Chaque chapitre a sa couleur. Touchez-en un pour voir ses lieux.',
  },
  'tut_skills_1': {
    AppLanguage.en:
        'The clans offer your skills: each branch is sponsored by one, deeper as it trusts you more. Essence, earned with XP, raises the skills you know a tier, and masters a whole branch.',
    AppLanguage.fr:
        'Les clans vous offrent vos compétences\u00a0: chaque branche est parrainée par l’un d’eux, plus profonde à mesure qu’il vous fait confiance. L’essence, gagnée avec l’XP, fait monter d’un rang celles que vous connaissez, et maîtrise une branche entière.',
  },
  'tut_skills_2': {
    AppLanguage.en:
        'Each branch is learned from the top down; a gold ring is known, a lit one is ready. Tap any skill to see what it does, learn it or raise it.',
    AppLanguage.fr:
        'Chaque branche s\'apprend de haut en bas ; un anneau doré est acquis, un anneau lumineux est prêt. Touchez une compétence pour voir ce qu\'elle fait, l\'apprendre ou la monter.',
  },
  'tut_skills_5': {
    AppLanguage.en:
        'Tree to learn, My skills to raise tiers and craft, Spells for your magic.',
    AppLanguage.fr:
        'Arbre pour apprendre, Mes compétences pour monter les rangs et fusionner, Sorts pour votre magie.',
  },
  'tut_skills_3': {
    AppLanguage.en:
        'In My skills, raise tiers with essence, and fuse two skills you know into a new one.',
    AppLanguage.fr:
        'Dans Mes compétences, montez les rangs avec l\'essence et fusionnez deux compétences connues en une nouvelle.',
  },
  'tut_dice_1': {
    AppLanguage.en: 'Pick the die you want to set up.',
    AppLanguage.fr: 'Choisissez le dé à préparer.',
  },
  'tut_dice_2': {
    AppLanguage.en:
        'Its faces: attack, defend, heal and skill. In a fight, one lands at random.',
    AppLanguage.fr:
        'Ses faces : attaque, défense, soin et compétence. En combat, l’une tombe au hasard.',
  },
  'tut_dice_3': {
    AppLanguage.en:
        'Your skills. Drag one onto an open face, or tap an open face to choose.',
    AppLanguage.fr:
        'Vos compétences. Glissez-en une sur une face libre, ou touchez une face libre pour choisir.',
  },
  'tut_inventory_1': {
    AppLanguage.en:
        'Your gear. Tap an item to equip it or use it. Rarer items have a coloured edge.',
    AppLanguage.fr:
        'Votre équipement. Touchez un objet pour l’équiper ou l’utiliser. Les objets rares ont un bord coloré.',
  },
  'tut_inventory_2': {
    AppLanguage.en: 'Compare two items before you choose.',
    AppLanguage.fr: 'Comparez deux objets avant de choisir.',
  },
  'tut_levelUp_1': {
    AppLanguage.en: 'Each level gives you points to spend.',
    AppLanguage.fr: 'Chaque niveau vous donne des points à dépenser.',
  },
  'tut_levelUp_2': {
    AppLanguage.en:
        'Tap +1 Point to raise what you use most. Hold a line to learn what it does.',
    AppLanguage.fr:
        'Touchez +1 point pour améliorer ce que vous utilisez le plus. Maintenez une ligne pour savoir à quoi elle sert.',
  },
  'tut_fight_1': {
    AppLanguage.en: "A fight! Here's how dice combat works.",
    AppLanguage.fr: 'Un combat ! Voici comment marche le combat aux dés.',
  },
  'tut_fight_2': {
    AppLanguage.en:
        'Each of your fighters rolls a die. Tap a die to keep it, then reroll the others. Hold one to see all its faces.',
    AppLanguage.fr:
        'Chacun de vos combattants lance un dé. Touchez un dé pour le garder, puis relancez les autres. Maintenez-le pour voir ses faces.',
  },
  'tut_fight_3': {
    AppLanguage.en:
        'Your foes. With enough Perception you can see what they will do next.',
    AppLanguage.fr:
        'Vos ennemis. Avec assez de Perception, vous voyez ce qu’ils vont faire.',
  },
  'tut_fight_4': {
    AppLanguage.en: 'Your side: health, shields and effects.',
    AppLanguage.fr: 'Votre camp : santé, boucliers et effets.',
  },
  'tut_fight_5': {
    AppLanguage.en:
        'Roll, then confirm to play the faces you landed. Spells and items are here too.',
    AppLanguage.fr:
        'Lancez, puis confirmez pour jouer les faces obtenues. Les sorts et les objets sont ici aussi.',
  },
  'tut_fight_6': {
    AppLanguage.en:
        'The round and the battlefield. Momentum builds as you fight; when it is full, you can surge.',
    AppLanguage.fr:
        'Le tour et le champ de bataille. L’élan monte au fil du combat ; plein, il permet un déferlement.',
  },
  'tut_skillChallenge_1': {
    AppLanguage.en:
        'A skill challenge: roll the d20 and add your ability. Meet the number to succeed.',
    AppLanguage.fr:
        'Une épreuve : lancez le d20 et ajoutez votre caractéristique. Atteignez le seuil pour réussir.',
  },
  'tut_skillChallenge_2': {
    AppLanguage.en: 'Get enough successes before too many failures.',
    AppLanguage.fr: "Obtenez assez de succès avant trop d'échecs.",
  },
  'tut_boat_1': {
    AppLanguage.en: 'The Rusty Eel on her slipway. Mend her hull here.',
    AppLanguage.fr: 'La Rusty Eel sur sa cale. Réparez sa coque ici.',
  },
  'tut_boat_2': {
    AppLanguage.en:
        "Fit the shipwright's parts into her slots to make her stronger for the sea.",
    AppLanguage.fr:
        'Installez les pièces du charpentier dans ses emplacements pour la renforcer en mer.',
  },
  'tut_voyage_1': {
    AppLanguage.en:
        'A crossing takes a few days at sea, and each day brings something: a calm, a storm, a wreck or raiders.',
    AppLanguage.fr:
        'Une traversée dure quelques jours en mer, et chaque jour apporte quelque chose : un calme plat, une tempête, une épave ou des pillards.',
  },
  'tut_voyage_2': {
    AppLanguage.en:
        'Watch the hull. Storms and raiders wear it down, calm days let you mend it. If it gives out, the Rusty Eel limps back to the port she left.',
    AppLanguage.fr:
        'Surveillez la coque. Les tempêtes et les pillards l’usent, les jours calmes permettent de la réparer. Si elle cède, la Rusty Eel regagne tant bien que mal son port de départ.',
  },
  'tut_voyage_3': {
    AppLanguage.en:
        'Each day, choose what the crew does. Some choices roll one of your stats, named on the button: pushing through a storm, boarding a wreck, outrunning raiders.',
    AppLanguage.fr:
        'Chaque jour, choisissez ce que fait l’équipage. Certains choix lancent l’une de vos caractéristiques, indiquée sur le bouton : forcer le passage dans une tempête, fouiller une épave, distancer des pillards.',
  },
  'tut_voyage_4': {
    AppLanguage.en:
        'Raiders can be paid off or outrun. Fight them and it becomes a ship battle, with your party crewing the stations.',
    AppLanguage.fr:
        'Les pillards peuvent être payés ou distancés. Si vous les combattez, c’est une bataille navale : votre groupe tient les postes.',
  },
  'tut_shipBattle_1': {
    AppLanguage.en:
        'A ship battle is fought room by room. Each ship has four: the helm dodges, the guns charge the weapons, the bulwark raises shields and the hold repairs the hull.',
    AppLanguage.fr:
        'Une bataille navale se joue salle par salle. Chaque navire en a quatre : la barre esquive, les canons chargent les armes, le pavois lève les boucliers et la cale répare la coque.',
  },
  'tut_shipBattle_2': {
    AppLanguage.en:
        'Tap a crew member, then a room, to post them there. A hand at a post makes the room work better, repairs it and fights its fires.',
    AppLanguage.fr:
        'Touchez un membre d’équipage, puis une salle, pour l’y poster. Une personne à son poste fait mieux fonctionner la salle, la répare et y combat le feu.',
  },
  'tut_shipBattle_3': {
    AppLanguage.en:
        'When a weapon is charged, tap it, then the enemy room to hit: the shot costs them hull and weakens that room. Hold the room instead to take aim, unless aiming is off in Settings.',
    AppLanguage.fr:
        'Quand une arme est chargée, touchez-la, puis la salle ennemie à frapper : le tir leur coûte de la coque et affaiblit cette salle. Maintenez plutôt la salle pour viser, sauf si la visée est désactivée dans les réglages.',
  },
  'tut_shipBattle_4': {
    AppLanguage.en:
        'Close in or pull away, and give each hand’s one order. Each gun fires the shot it was fitted with at the Harbor. Side by side with their rail open, you can board them.',
    AppLanguage.fr:
        'Approchez ou éloignez-vous, et donnez l’ordre unique de chaque personne. Chaque arme tire la munition avec laquelle le port l’a montée. Bord à bord, leur bastingage ouvert, vous pouvez les aborder.',
  },
  'tut_shipBattle_5': {
    AppLanguage.en:
        'Under its name the enemy shows its next move, unless the fog hides it. Once a turn, the bolt pushes one of your rooms past its limit, at a risk to that room. Then end the turn and they answer.',
    AppLanguage.fr:
        'Sous son nom, l’ennemi montre son prochain coup, sauf si le brouillard le cache. Une fois par tour, l’éclair force une de vos salles au-delà de ses limites, au risque de l’abîmer. Terminez ensuite le tour, et l’ennemi répond.',
  },
  'tut_shipBattle_6': {
    AppLanguage.en:
        'Sink them or take their deck to win; if the Rusty Eel’s hull gives out, she limps back to the port she left. The detailed tips will show again, one at a time, in your next ship battle.',
    AppLanguage.fr:
        'Coulez-le ou prenez son pont pour gagner ; si la coque du Rusty Eel cède, il regagne tant bien que mal son port de départ. Les conseils détaillés s’afficheront de nouveau, un par un, lors de votre prochaine bataille navale.',
  },
  'tut_expedition_1': {
    AppLanguage.en:
        'An expedition is a chain of events in one zone. Clear them all to win its reward.',
    AppLanguage.fr:
        "Une expédition est une suite d'événements dans une zone. Terminez-les tous pour gagner sa récompense.",
  },
  'tut_expedition_2': {
    AppLanguage.en:
        'You can turn back between events. You keep what you found, but not the final reward.',
    AppLanguage.fr:
        'Vous pouvez rebrousser chemin entre deux événements. Vous gardez vos trouvailles, mais pas la récompense finale.',
  },
  'tut_town_1': {
    AppLanguage.en:
        'A port of call: rest, trade in its shops and set out on the expeditions nearby. The Rusty Eel takes you on to the next port.',
    AppLanguage.fr:
        'Une escale : reposez-vous, commercez et partez pour les expéditions voisines. La Rusty Eel vous emmène au port suivant.',
  },
  'tut_shop_1': {
    AppLanguage.en: 'Buy what the merchant sells with your gold.',
    AppLanguage.fr: 'Achetez ce que vend le marchand avec votre or.',
  },
  'tut_shop_2': {
    AppLanguage.en:
        'You can sell what you carry too: the tag at the top opens the sale.',
    AppLanguage.fr:
        'Vous pouvez aussi vendre ce que vous portez : l’étiquette en haut ouvre la vente.',
  },
  'tut_journal_1': {
    AppLanguage.en:
        'The story so far, newest first: each scene and the choice that left it.',
    AppLanguage.fr:
        "L'histoire jusqu'ici, la plus récente d'abord : chaque scène et le choix qui l'a conclue.",
  },
  'tut_achievements_1': {
    AppLanguage.en:
        'Every achievement. The ones you have earned are lit; the rest are waiting.',
    AppLanguage.fr:
        'Tous les succès. Ceux obtenus sont allumés ; les autres vous attendent.',
  },
  'hub_shops_section': {AppLanguage.en: 'Shops', AppLanguage.fr: 'Commerces'},
  'hub_challenges_section': {
    AppLanguage.en: 'Challenges',
    AppLanguage.fr: 'Défis',
  },
  'hub_people_section': {AppLanguage.en: 'People', AppLanguage.fr: 'Habitants'},
  'authoring_comment_label': {
    AppLanguage.en: 'Reviewer comment',
    AppLanguage.fr: 'Commentaire de relecture',
  },
  'authoring_comment_hint': {
    AppLanguage.en: 'A private note about this node, never shown to players',
    AppLanguage.fr: 'Une note privée sur ce nœud, jamais visible des joueurs',
  },
  'review_comments_title': {
    AppLanguage.en: 'Review Comments',
    AppLanguage.fr: 'Commentaires de relecture',
  },
  'hold_stat_for_details_hint': {
    AppLanguage.en: 'Hold a stat to see what it does',
    AppLanguage.fr: 'Maintenez une statistique pour voir son effet',
  },
  'no_review_comments_message': {
    AppLanguage.en:
        'No nodes have a reviewer comment yet. Open a node in Edit Mode to leave one.',
    AppLanguage.fr:
        "Aucun nœud n'a de commentaire pour l'instant. Ouvrez un nœud en mode édition pour en laisser un.",
  },
  'export_as_text_option': {
    AppLanguage.en: 'Export as text (.txt)',
    AppLanguage.fr: 'Exporter en texte (.txt)',
  },
  'export_as_json_option': {
    AppLanguage.en: 'Export as JSON (.json)',
    AppLanguage.fr: 'Exporter en JSON (.json)',
  },
  // --- Spoils chest, affixes, battlefield conditions, momentum, charms ---
  'spoils_title': {AppLanguage.en: 'Spoils', AppLanguage.fr: 'Butin'},
  'chest_tier_wooden': {
    AppLanguage.en: 'Wooden Chest',
    AppLanguage.fr: 'Coffre en bois',
  },
  'chest_tier_iron': {
    AppLanguage.en: 'Iron Chest',
    AppLanguage.fr: 'Coffre en fer',
  },
  'chest_tier_silver': {
    AppLanguage.en: 'Silver Chest',
    AppLanguage.fr: "Coffre d'argent",
  },
  'chest_tier_gold': {
    AppLanguage.en: 'Gold Chest',
    AppLanguage.fr: "Coffre d'or",
  },
  'chest_tier_void': {
    AppLanguage.en: 'Void Chest',
    AppLanguage.fr: 'Coffre du Néant',
  },
  'chest_tap_hint': {
    AppLanguage.en: 'Tap the chest to open it.',
    AppLanguage.fr: "Touchez le coffre pour l'ouvrir.",
  },
  'chest_slot_hint': {
    AppLanguage.en: 'Tap each slot to see what you found.',
    AppLanguage.fr: 'Touchez chaque case pour voir ce que vous avez trouvé.',
  },
  'chest_all_revealed_hint': {
    AppLanguage.en: 'Everything is yours.',
    AppLanguage.fr: 'Tout est à vous.',
  },
  'chest_take_button': {AppLanguage.en: 'Take', AppLanguage.fr: 'Prendre'},
  'chest_take_all_button': {
    AppLanguage.en: 'Take all',
    AppLanguage.fr: 'Tout prendre',
  },
  'chest_extra_slot_note': {
    AppLanguage.en: 'Your keen eye found a hidden pouch (+1 slot).',
    AppLanguage.fr: 'Votre œil perçant a trouvé une bourse cachée (+1 case).',
  },
  'fortune_roll_label': {
    AppLanguage.en: 'Fortune roll',
    AppLanguage.fr: 'Jet de fortune',
  },
  'fortune_floor_label': {
    AppLanguage.en: 'Guaranteed at least',
    AppLanguage.fr: 'Garanti au moins',
  },
  'fortune_luck': {AppLanguage.en: 'Luck', AppLanguage.fr: 'Chance'},
  'fortune_elite': {AppLanguage.en: 'Elite', AppLanguage.fr: 'Élite'},
  'fortune_pack': {AppLanguage.en: 'Pack', AppLanguage.fr: 'Meute'},
  'fortune_flawless': {
    AppLanguage.en: 'Flawless',
    AppLanguage.fr: 'Sans faute',
  },
  'fortune_swift': {AppLanguage.en: 'Swift', AppLanguage.fr: 'Rapide'},
  'fortune_critical_finish': {
    AppLanguage.en: 'Critical finish',
    AppLanguage.fr: 'Coup de grâce critique',
  },
  'fortune_affixes': {
    AppLanguage.en: 'Affixed foes',
    AppLanguage.fr: 'Ennemis affixés',
  },
  'fortune_condition': {
    AppLanguage.en: 'Battlefield',
    AppLanguage.fr: 'Terrain',
  },
  'fortune_pity': {
    AppLanguage.en: 'Overdue luck',
    AppLanguage.fr: 'Chance due',
  },
  'chest_auto_open_setting_title': {
    AppLanguage.en: 'Open spoils chests automatically',
    AppLanguage.fr: 'Ouvrir les coffres de butin automatiquement',
  },
  'chest_auto_open_setting_desc': {
    AppLanguage.en:
        'Skips the tap-to-open and reveals every slot at once after a fight.',
    AppLanguage.fr:
        "Saute l'ouverture au toucher et révèle toutes les cases d'un coup après un combat.",
  },
  'alignment_hunters_setting_title': {
    AppLanguage.en: 'Alignment has consequences',
    AppLanguage.fr: "L'alignement a des conséquences",
  },
  'alignment_hunters_setting_desc': {
    AppLanguage.en:
        'Angels hunt the wicked, demons hunt the righteous, and both court the undecided.',
    AppLanguage.fr:
        'Les anges traquent les méchants, les démons traquent les justes, et les deux courtisent les indécis.',
  },
  'affix_venomous': {AppLanguage.en: 'Venomous', AppLanguage.fr: 'Venimeux'},
  'affix_venomous_desc': {
    AppLanguage.en: 'Its attacks poison whoever they hit.',
    AppLanguage.fr: 'Ses attaques empoisonnent leur cible.',
  },
  'affix_armored': {AppLanguage.en: 'Armored', AppLanguage.fr: 'Cuirassé'},
  'affix_armored_desc': {
    AppLanguage.en:
        'Shrugs off 4 damage from every Attack face. Skills cut through.',
    AppLanguage.fr:
        'Encaisse 4 dégâts de chaque face Attaque. Les compétences passent.',
  },
  'affix_skittish': {AppLanguage.en: 'Skittish', AppLanguage.fr: 'Craintif'},
  'affix_skittish_desc': {
    AppLanguage.en: 'Flees below a quarter health, taking part of the spoils.',
    AppLanguage.fr:
        "Fuit sous un quart de sa vie, emportant une partie du butin.",
  },
  'affix_frenzied': {AppLanguage.en: 'Frenzied', AppLanguage.fr: 'Enragé'},
  'affix_frenzied_desc': {
    AppLanguage.en: 'Hits much harder once below half health.',
    AppLanguage.fr: 'Frappe bien plus fort sous la moitié de sa vie.',
  },
  'affix_pack_leader': {
    AppLanguage.en: 'Pack Leader',
    AppLanguage.fr: 'Chef de meute',
  },
  'affix_pack_leader_desc': {
    AppLanguage.en:
        'While it stands, the rest of the pack hits harder. Kill it first.',
    AppLanguage.fr:
        "Tant qu'il tient debout, le reste de la meute frappe plus fort. Abattez-le en premier.",
  },
  'armored_absorbs_suffix': {
    AppLanguage.en: 'shrugs off part of the blow (armored).',
    AppLanguage.fr: 'encaisse une partie du coup (cuirassé).',
  },
  'flees_suffix': {
    AppLanguage.en: 'breaks and flees the fight!',
    AppLanguage.fr: 'panique et fuit le combat !',
  },
  'holds_back_suffix': {
    AppLanguage.en: "can't reach you in the press and holds back.",
    AppLanguage.fr: 'ne peut vous atteindre dans la cohue et reste en retrait.',
  },
  'condition_ambush': {AppLanguage.en: 'Ambush', AppLanguage.fr: 'Embuscade'},
  'condition_ambush_desc': {
    AppLanguage.en:
        'They strike first, and nothing can be read off them this opening round.',
    AppLanguage.fr:
        "Ils frappent en premier, et rien ne peut être lu sur eux lors de ce premier tour.",
  },
  'condition_dark': {AppLanguage.en: 'Darkness', AppLanguage.fr: 'Ténèbres'},
  'condition_dark_desc': {
    AppLanguage.en: 'Every telegraph reads one tier worse.',
    AppLanguage.fr: 'Chaque anticipation se lit un niveau en dessous.',
  },
  'condition_cramped': {
    AppLanguage.en: 'Cramped',
    AppLanguage.fr: 'Exigu',
  },
  'condition_cramped_desc': {
    AppLanguage.en:
        'Only two enemies can reach you each round; the rest hold back.',
    AppLanguage.fr:
        'Seuls deux ennemis peuvent vous atteindre chaque tour ; les autres restent en retrait.',
  },
  'condition_high_ground': {
    AppLanguage.en: 'High Ground',
    AppLanguage.fr: 'Position dominante',
  },
  'condition_high_ground_desc': {
    AppLanguage.en: 'Every Defend face blocks half again as much.',
    AppLanguage.fr: 'Chaque face Défense bloque moitié plus.',
  },
  'condition_shrine': {AppLanguage.en: 'Shrine', AppLanguage.fr: 'Sanctuaire'},
  'condition_shrine_desc': {
    AppLanguage.en: 'Every Heal face and potion restores half again as much.',
    AppLanguage.fr: 'Chaque face Soin et chaque potion soigne moitié plus.',
  },
  'momentum_label': {AppLanguage.en: 'Momentum', AppLanguage.fr: 'Élan'},
  'momentum_ready_label': {
    AppLanguage.en: 'Momentum: next strike crits!',
    AppLanguage.fr: 'Élan : le prochain coup est critique !',
  },
  'momentum_ready_message': {
    AppLanguage.en: 'Momentum builds -- the next strike is a sure critical.',
    AppLanguage.fr: "L'élan monte : le prochain coup sera critique à coup sûr.",
  },
  'retreat_confirm_title': {
    AppLanguage.en: 'Get away from this fight?',
    AppLanguage.fr: 'Fuir ce combat ?',
  },
  'retreat_confirm_body': {
    AppLanguage.en:
        'You drop {gold} gold{potion} getting clear and keep the wounds you have. Nothing is won. A detour is left behind; a fight in the story waits where it was.',
    AppLanguage.fr:
        'Vous laissez tomber {gold} or{potion} en vous dégageant et gardez vos blessures. Rien n’est gagné. Un détour est abandonné ; un combat de l’histoire vous attend là où il était.',
  },
  'read_scroll_prefix': {
    AppLanguage.en: 'You read the',
    AppLanguage.fr: 'Vous lisez :',
  },
  'surge_pick_label': {
    AppLanguage.en: 'Crit goes to:',
    AppLanguage.fr: 'Le critique pour :',
  },
  'momentum_surge_message': {
    AppLanguage.en: 'Momentum surges into the blow!',
    AppLanguage.fr: "L'élan se déchaîne dans le coup !",
  },
  'charms_label': {AppLanguage.en: 'Charms', AppLanguage.fr: 'Charmes'},
  'charms_hint': {
    AppLanguage.en: 'Pick charms to burn for this fight only.',
    AppLanguage.fr:
        'Choisissez les charmes à consumer pour ce combat seulement.',
  },
  'charm_used_prefix': {
    AppLanguage.en: 'Charm burned:',
    AppLanguage.fr: 'Charme consumé :',
  },
  'charm_fourth_roll_desc': {
    AppLanguage.en: 'One extra reroll every round this fight.',
    AppLanguage.fr: 'Une relance supplémentaire à chaque tour de ce combat.',
  },
  'charm_lucky_coin_desc': {
    AppLanguage.en: 'Your critical-hit chance rises by 15% this fight.',
    AppLanguage.fr: 'Votre chance de coup critique augmente de 15 % ce combat.',
  },
  'charm_iron_skin_desc': {
    AppLanguage.en: '+5 armor this fight.',
    AppLanguage.fr: '+5 armure ce combat.',
  },
  'charm_warding_desc': {
    AppLanguage.en: 'The first hit you take this fight is negated.',
    AppLanguage.fr: 'Le premier coup que vous subissez ce combat est annulé.',
  },
  'warding_absorbs_message': {
    AppLanguage.en: 'The warding knot unravels and the blow never lands.',
    AppLanguage.fr: 'Le nœud de garde se défait et le coup ne porte jamais.',
  },
  'hunt_fight_note': {
    AppLanguage.en:
        'A hunt: the quarry is tougher than its kind and carries two traits, but its lair holds a Gold chest at least.',
    AppLanguage.fr:
        "Une traque : la proie est plus coriace que ses semblables et porte deux traits, mais son repaire recèle au moins un coffre d'or.",
  },
  'hunter_fight_note': {
    AppLanguage.en:
        'A hunter sent for you. It yields more than its kind, and never less than a Silver chest.',
    AppLanguage.fr:
        "Un chasseur envoyé pour vous. Il rapporte plus que ses semblables, et jamais moins qu'un coffre d'argent.",
  },
  'aligned_gear_label': {
    AppLanguage.en: 'Aligned',
    AppLanguage.fr: 'Aligné',
  },
  'aligned_bonus_suffix': {
    AppLanguage.en: 'bonus when your alignment matches',
    AppLanguage.fr: 'bonus si votre alignement correspond',
  },
  'alignment_rejects_label': {
    AppLanguage.en: 'Rejects your alignment',
    AppLanguage.fr: 'Rejette votre alignement',
  },
  'aligned_skill_note': {
    AppLanguage.en: '+25% for a matching alignment, -25% for the opposite',
    AppLanguage.fr: "+25 % pour un alignement assorti, -25 % pour l'opposé",
  },
  'launch_zone_id': {
    AppLanguage.en: 'Launch zone (expedition cleared before continuing)',
    AppLanguage.fr: 'Zone lancée (expédition à terminer avant de continuer)',
  },
  'hide_if_flags': {
    AppLanguage.en: 'Hide once any of these flags is held (comma-separated)',
    AppLanguage.fr:
        'Masquer dès que l\'un de ces drapeaux est détenu (séparés par des virgules)',
  },
  'zone_tier_label': {AppLanguage.en: 'Tier', AppLanguage.fr: 'Palier'},
  'zone_main_label': {
    AppLanguage.en: 'Main zone',
    AppLanguage.fr: 'Zone principale'
  },
  'zone_boss_prefix': {AppLanguage.en: 'Boss', AppLanguage.fr: 'Boss'},
  'zone_level_chip': {AppLanguage.en: 'Lv', AppLanguage.fr: 'Niv'},
  'requires_zone_prefix': {
    AppLanguage.en: 'Requires',
    AppLanguage.fr: 'Nécessite'
  },
  'zone_boss_face_prefix': {
    AppLanguage.en: 'Face',
    AppLanguage.fr: 'Affronter'
  },
  'expedition_boss_label': {
    AppLanguage.en: 'Zone boss',
    AppLanguage.fr: 'Boss de zone'
  },
  'zone_boss_fight_note': {
    AppLanguage.en:
        "The zone's master guards its reward. Win, and the spoils chest is never below Gold.",
    AppLanguage.fr:
        "Le maître de la zone garde sa récompense. Gagnez, et le coffre de butin ne sera jamais en dessous de l'or.",
  },
  'zone_flag_cinder_row_cleared': {
    AppLanguage.en: 'Cinder Row, cleared',
    AppLanguage.fr: 'La Rue des Braises, nettoyée',
  },
  'zone_flag_scaffold_yards_cleared': {
    AppLanguage.en: 'The Scaffold Yards, cleared',
    AppLanguage.fr: 'Les Chantiers aux Échafaudages, nettoyés',
  },
  'zone_flag_ossuary_galleries_cleared': {
    AppLanguage.en: 'The Ossuary Galleries, cleared',
    AppLanguage.fr: 'Les Galeries de l’Ossuaire, nettoyées',
  },
  'zone_flag_drowned_stair_cleared': {
    AppLanguage.en: 'The Drowned Stair, cleared',
    AppLanguage.fr: 'L’Escalier Noyé, nettoyé',
  },
  'zone_flag_dead_heart_cleared': {
    AppLanguage.en: 'The road to the Dead Heart, open',
    AppLanguage.fr: 'La route du Cœur Mort, ouverte',
  },
  'zone_flag_shroud_vigil_cleared': {
    AppLanguage.en: 'The Shroud’s vigil, kept',
    AppLanguage.fr: 'La Veillée du Linceul, tenue',
  },
  'zone_flag_glass_strand_cleared': {
    AppLanguage.en: 'The Glass Strand, crossed',
    AppLanguage.fr: 'La Grève de Verre, traversée',
  },
  'zone_flag_exorcists_road_cleared': {
    AppLanguage.en: 'The Exorcists’ Road, walked to the top',
    AppLanguage.fr: 'La Route des Exorcistes, gravie jusqu’en haut',
  },
  'zone_flag_salt_road_cleared': {
    AppLanguage.en: 'The Salt Road, the Wreckers’ lantern put out',
    AppLanguage.fr: 'La Route du Sel, la lanterne des Naufrageurs éteinte',
  },
  'zone_flag_fever_bark_delivered': {
    AppLanguage.en: 'Fever-Bark for the Wall, the chest delivered',
    AppLanguage.fr: 'L’Écorce pour le Mur, le coffre livré',
  },
  'zone_flag_bell_road_cleared': {
    AppLanguage.en: 'The Bell Road, the bells brought home',
    AppLanguage.fr: 'La Route des Cloches, les cloches ramenées',
  },
  'zone_flag_ember_run_delivered': {
    AppLanguage.en: 'The Ember Run, the hearths of Rimewell lit again',
    AppLanguage.fr:
        'La Course des Braises, les foyers de Puits-de-Givre rallumés',
  },
  'zone_flag_lantern_train_cleared': {
    AppLanguage.en: 'The Lantern Train, the oil brought up the hill',
    AppLanguage.fr: 'Le Convoi des Lanternes, l’huile montée sur les hauteurs',
  },
  'zone_flag_changeling_fen_cleared': {
    AppLanguage.en: 'The Changeling Fen, its rider unhorsed',
    AppLanguage.fr: 'Le Marais des Changelins, son cavalier désarçonné',
  },
  'zone_flag_frost_quarry_cleared': {
    AppLanguage.en: 'The Frost Quarry, its tally-stone read',
    AppLanguage.fr: 'La Carrière de Givre, sa pierre de compte lue',
  },
  'zone_flag_white_fleet_grave_cleared': {
    AppLanguage.en: 'The White Fleet’s grave, silent',
    AppLanguage.fr: 'Le Tombeau de la Flotte Blanche, silencieux',
  },
  'zone_flag_void_sovereign_fallen': {
    AppLanguage.en: 'The Sovereign, fallen',
    AppLanguage.fr: 'Le Souverain, tombé',
  },
  'boat_title': {
    AppLanguage.en: 'The Rusty Eel',
    AppLanguage.fr: 'Le Rusty Eel'
  },
  'boat_locked_subtitle': {
    AppLanguage.en: 'Opens once the camp is set up in chapter 3',
    AppLanguage.fr: 'S’ouvre une fois le campement installé au chapitre 3',
  },
  'boat_at_port_prefix': {
    AppLanguage.en: 'Moored at',
    AppLanguage.fr: 'Amarré à'
  },
  'hull_label': {AppLanguage.en: 'Hull', AppLanguage.fr: 'Coque'},
  'bulwark_label': {AppLanguage.en: 'Bulwark', AppLanguage.fr: 'Pavois'},
  'repair_ship_button': {AppLanguage.en: 'Repair', AppLanguage.fr: 'Réparer'},
  'ship_sound_label': {
    AppLanguage.en: 'Hull sound',
    AppLanguage.fr: 'Coque saine'
  },
  'shipwright_section': {
    AppLanguage.en: 'Shipwright',
    AppLanguage.fr: 'Charpentier de marine'
  },
  'install_button': {AppLanguage.en: 'Install', AppLanguage.fr: 'Installer'},
  'installed_label': {AppLanguage.en: 'Installed', AppLanguage.fr: 'Installé'},
  'slot_full_label': {
    AppLanguage.en: 'No free slot',
    AppLanguage.fr: 'Aucun emplacement libre'
  },
  'slot_weapon_label': {AppLanguage.en: 'Weapons', AppLanguage.fr: 'Armes'},
  'slot_shield_label': {AppLanguage.en: 'Bulwark', AppLanguage.fr: 'Pavois'},
  'slot_utility_label': {AppLanguage.en: 'Rigging', AppLanguage.fr: 'Gréement'},
  'slot_sail_label': {
    AppLanguage.en: 'Painted sail',
    AppLanguage.fr: 'Voile peinte',
  },
  'sail_repaint_note': {
    AppLanguage.en: 'Painting the sail replaces the sigil already on it.',
    AppLanguage.fr: 'Peindre la voile remplace le sigil qui s\'y trouve déjà.',
  },
  'sail_medium_match_label': {
    AppLanguage.en:
        'Painted your people\'s way: the sigil holds twice as strong',
    AppLanguage.fr:
        'Peint à la manière de votre peuple : le sigil tient deux fois plus fort',
  },
  'sail_power_flight': {
    AppLanguage.en: 'Flight: storms and raiders pass beneath the keel',
    AppLanguage.fr: 'Vol : tempêtes et pillards passent sous la quille',
  },
  'sail_power_foresight': {
    AppLanguage.en:
        'Foresight: tomorrow\'s weather shown, and where the enemy\'s guns are aimed',
    AppLanguage.fr:
        'Prescience : le temps de demain annoncé, et où pointent les canons ennemis',
  },
  'sail_power_hearth': {
    AppLanguage.en:
        'Hearth: every day at sea heals the crew and mends the hull',
    AppLanguage.fr:
        'Foyer : chaque jour en mer soigne l\'équipage et répare la coque',
  },
  'sail_power_windknot': {
    AppLanguage.en: 'Wind-knot: a shorter crossing, and richer wrecks',
    AppLanguage.fr:
        'Nœud de vent : une traversée plus courte, et des épaves plus riches',
  },
  'sail_power_voidmark': {
    AppLanguage.en:
        'Void mark: a void volley in battle, and storms that do not bite',
    AppLanguage.fr:
        'Marque du Néant : une bordée de Néant au combat, et des tempêtes qui ne mordent plus',
  },
  'ship_log_lift': {
    AppLanguage.en:
        'The painted sail lifts the Eel clear of the weather: {n} bad days pass beneath her keel.',
    AppLanguage.fr:
        'La voile peinte soulève l\'Eel au-dessus du temps : {n} mauvais jours passent sous sa quille.',
  },
  'ship_log_foresight_prefix': {
    AppLanguage.en: 'The Kraken\'s Eye sees ahead',
    AppLanguage.fr: 'L\'Œil du Kraken voit devant',
  },
  'ship_log_first_volley_seen': {
    AppLanguage.en:
        'The sail saw the first volley coming; the Eel slips most of it.',
    AppLanguage.fr:
        'La voile a vu venir la première bordée ; l\'Eel en esquive l\'essentiel.',
  },
  'ship_log_hearth': {
    AppLanguage.en:
        'The hearth-mark warms the crew: +{n} health, and the hull knits.',
    AppLanguage.fr:
        'La marque du foyer réchauffe l\'équipage : +{n} de santé, et la coque se ressoude.',
  },
  'ship_log_windknot': {
    AppLanguage.en:
        'The wind-knot finds the faster passage: {n} fewer days at sea.',
    AppLanguage.fr:
        'Le nœud de vent trouve le passage le plus rapide : {n} jours de mer en moins.',
  },
  'ship_log_void_calm': {
    AppLanguage.en: 'The void mark takes the storm\'s teeth.',
    AppLanguage.fr: 'La marque du Néant ôte ses dents à la tempête.',
  },
  'sea_event_raider': {
    AppLanguage.en: 'a raider',
    AppLanguage.fr: 'un pillard'
  },
  'sea_event_storm': {AppLanguage.en: 'a storm', AppLanguage.fr: 'une tempête'},
  'sea_event_derelict': {
    AppLanguage.en: 'a derelict',
    AppLanguage.fr: 'une épave'
  },
  'sea_event_calm': {
    AppLanguage.en: 'calm water',
    AppLanguage.fr: 'une mer calme'
  },
  'sea_event_sighting': {
    AppLanguage.en: 'a sighting',
    AppLanguage.fr: 'une apparition'
  },
  'ports_section': {AppLanguage.en: 'Chart', AppLanguage.fr: 'Carte marine'},
  'sail_button': {AppLanguage.en: 'Set sail', AppLanguage.fr: "Lever l'ancre"},
  'moored_here_label': {
    AppLanguage.en: 'Moored here',
    AppLanguage.fr: 'Amarré ici'
  },
  'days_at_sea_label': {
    AppLanguage.en: 'days at sea',
    AppLanguage.fr: 'jours en mer'
  },
  'voyage_title': {AppLanguage.en: 'Voyage', AppLanguage.fr: 'Traversée'},
  'voyage_day_label': {AppLanguage.en: 'Day', AppLanguage.fr: 'Jour'},
  'voyage_arrived_title': {
    AppLanguage.en: 'Landfall',
    AppLanguage.fr: 'Terre en vue'
  },
  'voyage_failed_title': {
    AppLanguage.en: 'Limping home',
    AppLanguage.fr: 'Retour en boitant'
  },
  'voyage_failed_message': {
    AppLanguage.en:
        'The Rusty Eel took on too much water. You put back to the port you left, hull barely holding.',
    AppLanguage.fr:
        "Le Rusty Eel a embarqué trop d'eau. Vous regagnez le port que vous aviez quitté, la coque tenant à peine.",
  },
  'sail_on_button': {AppLanguage.en: 'Sail on', AppLanguage.fr: 'Poursuivre'},
  'go_ashore_button': {
    AppLanguage.en: 'Go ashore',
    AppLanguage.fr: 'Descendre à terre'
  },
  'ship_fight_title': {
    AppLanguage.en: 'Ship battle',
    AppLanguage.fr: 'Bataille navale'
  },
  'ready_in_prefix': {AppLanguage.en: 'ready in', AppLanguage.fr: 'prêt dans'},
  'ship_log_you_strike': {
    AppLanguage.en: 'You strike the {ship} for {n}',
    AppLanguage.fr: 'Vous frappez {ship} pour {n}',
  },
  'ship_log_enemy_strikes': {
    AppLanguage.en: 'The {ship} strikes for {n}',
    AppLanguage.fr: '{ship} frappe pour {n}',
  },
  'ship_log_brace': {
    AppLanguage.en: 'Bulwark braced, +{n}',
    AppLanguage.fr: 'Pavois renforcé, +{n}',
  },
  'ship_log_repair': {
    AppLanguage.en: 'Hull patched, +{n}',
    AppLanguage.fr: 'Coque colmatée, +{n}',
  },
  'ship_log_sunk': {
    AppLanguage.en: 'The {ship} goes down',
    AppLanguage.fr: '{ship} sombre',
  },
  'ship_log_storm': {
    AppLanguage.en: 'The storm costs {n} hull',
    AppLanguage.fr: 'La tempête coûte {n} points de coque',
  },
  'ship_log_calm': {
    AppLanguage.en: 'Repairs restore {n} hull',
    AppLanguage.fr: 'Les réparations rendent {n} points de coque',
  },
  'ship_log_salvage': {
    AppLanguage.en: 'Salvaged {n} gold',
    AppLanguage.fr: '{n} pièces d\'or récupérées',
  },
  'ship_fight_won_prefix': {
    AppLanguage.en: 'Prize taken',
    AppLanguage.fr: 'Prise capturée'
  },
  // --- The room-by-room ship battle (see ship_combat.dart) ---
  'ship_room_helm_title': {AppLanguage.en: 'Helm', AppLanguage.fr: 'Barre'},
  'ship_room_guns_title': {AppLanguage.en: 'Guns', AppLanguage.fr: 'Canons'},
  'ship_room_bulwark_title': {
    AppLanguage.en: 'Bulwark',
    AppLanguage.fr: 'Pavois'
  },
  'ship_room_hold_title': {AppLanguage.en: 'Hold', AppLanguage.fr: 'Cale'},
  'ship_room_helm': {AppLanguage.en: 'helm', AppLanguage.fr: 'la barre'},
  'ship_room_guns': {AppLanguage.en: 'guns', AppLanguage.fr: 'les canons'},
  'ship_room_bulwark': {AppLanguage.en: 'bulwark', AppLanguage.fr: 'le pavois'},
  'ship_room_hold': {AppLanguage.en: 'hold', AppLanguage.fr: 'la cale'},
  'ship_room_helm_hint': {
    AppLanguage.en: 'Evasion: 8% per pip. A helmsman adds their own.',
    AppLanguage.fr: 'Esquive : 8 % par cran. Un barreur ajoute la sienne.',
  },
  'ship_room_guns_hint': {
    AppLanguage.en:
        'Weapons charge here. Extra pips and a gunner speed the heaviest gun.',
    AppLanguage.fr:
        'Les armes se chargent ici. Les crans en plus et un canonnier hâtent la plus lourde.',
  },
  'ship_room_bulwark_hint': {
    AppLanguage.en:
        'One shield layer per pip, one back each round (two with a hand here). Each shot it stops cracks a pip.',
    AppLanguage.fr:
        'Une couche de bouclier par cran, une qui revient chaque tour (deux avec une main ici). Chaque tir arrêté fêle un cran.',
  },
  'ship_room_hold_hint': {
    AppLanguage.en:
        'A hand here patches the hull every turn, and meets boarders at the rail (they come in weakened).',
    AppLanguage.fr:
        'Une main ici colmate la coque à chaque tour, et reçoit les assaillants au bastingage (ils arrivent affaiblis).',
  },
  'ship_room_bulwark_open_hint': {
    AppLanguage.en: 'The bulwark is down: the rail is open to boarders.',
    AppLanguage.fr:
        'Le pavois est à terre : le bastingage est ouvert aux assaillants.',
  },
  'ship_board_button': {
    AppLanguage.en: 'Board them',
    AppLanguage.fr: 'À l\'abordage'
  },
  'ship_board_hint': {
    AppLanguage.en:
        'Side by side with their rail open: board and fight {crew} at the rail (their helm may slip the grapples; it ends the turn).',
    AppLanguage.fr:
        'Bord à bord, leur bastingage ouvert : abordez et affrontez {crew} au bastingage (leur barre peut esquiver les grappins ; cela termine le tour).',
  },
  'ship_order_here': {
    AppLanguage.en: 'at the {room}',
    AppLanguage.fr: 'au poste : {room}',
  },
  'ship_order_go': {
    AppLanguage.en: 'goes to the {room}',
    AppLanguage.fr: 'va au poste : {room}',
  },
  'ship_order_anywhere': {
    AppLanguage.en: 'from anywhere',
    AppLanguage.fr: 'depuis n’importe où',
  },
  'ship_order_from_label': {
    AppLanguage.en: 'Given from:',
    AppLanguage.fr: 'Donné depuis :',
  },
  'ship_order_now_label': {
    AppLanguage.en: 'now at:',
    AppLanguage.fr: 'actuellement :',
  },
  'ship_order_once_label': {
    AppLanguage.en: 'Once a battle. Tap the die to give it.',
    AppLanguage.fr: 'Une fois par bataille. Touchez le dé pour le donner.',
  },
  'ship_order_spent': {
    AppLanguage.en: 'given',
    AppLanguage.fr: 'donné',
  },
  'ship_place_title': {
    AppLanguage.en: 'Stations!',
    AppLanguage.fr: 'À vos postes !',
  },
  'ship_place_intro': {
    AppLanguage.en:
        'The {ship} comes on. Set each hand where they will fight: an order is given from its own rooms.',
    AppLanguage.fr:
        '{ship} approche. Placez chacun là où il se battra : un ordre se donne depuis ses propres postes.',
  },
  'ship_place_hint': {
    AppLanguage.en:
        'Drag a hand onto a room, or tap them then the room. Gold: their order can be given from where they stand.',
    AppLanguage.fr:
        'Glissez un membre sur une salle, ou touchez-le puis la salle. En or : son ordre peut être donné d’où il se tient.',
  },
  'ship_place_skills': {
    AppLanguage.en: 'By orders',
    AppLanguage.fr: 'Selon les ordres',
  },
  'ship_place_start': {
    AppLanguage.en: 'Battle!',
    AppLanguage.fr: 'Au combat !',
  },
  'ship_auto_station_button': {
    AppLanguage.en: 'Auto-station',
    AppLanguage.fr: 'Postes auto'
  },
  'ship_log_boarding_start': {
    AppLanguage.en: 'You board the {ship}',
    AppLanguage.fr: 'Vous abordez {ship}',
  },
  'ship_log_boarding_won': {
    AppLanguage.en: 'The {ship} is yours: her crew is cut down at the rail',
    AppLanguage.fr:
        '{ship} est à vous : son équipage est taillé en pièces au bastingage',
  },
  'ship_log_boarding_repelled': {
    AppLanguage.en: 'Thrown back to the Eel, -{n} hull; the {ship} fights on',
    AppLanguage.fr:
        'Repoussés vers l\'Eel, -{n} de coque ; {ship} poursuit le combat',
  },
  'ship_log_boarding_abandoned': {
    AppLanguage.en:
        'The boarding party falls back to the Eel and cuts the grapples; the {ship} fights on',
    AppLanguage.fr:
        'L\'équipe d\'abordage regagne l\'Eel et tranche les grappins ; {ship} poursuit le combat',
  },
  'ship_log_grapple_slipped': {
    AppLanguage.en: 'The {ship} slips the grapples; the turn is lost',
    AppLanguage.fr: '{ship} esquive les grappins ; le tour est perdu',
  },
  'ship_log_boarders': {
    AppLanguage.en:
        'Boarders from the {ship} come over the rail into the hold!',
    AppLanguage.fr:
        'Des assaillants de {ship} franchissent le bastingage jusqu\'à la cale !',
  },
  'ship_log_boarders_repelled': {
    AppLanguage.en: 'The boarders are thrown into the sea',
    AppLanguage.fr: 'Les assaillants sont jetés à la mer',
  },
  'ship_log_boarders_won': {
    AppLanguage.en:
        'The boarders wreck the hold before they are driven off, -{n} hull',
    AppLanguage.fr:
        'Les assaillants saccagent la cale avant d\'être repoussés, -{n} de coque',
  },
  'ship_log_prize_part': {
    AppLanguage.en: 'Prize: {weapon} taken aboard',
    AppLanguage.fr: 'Prise : {weapon} embarqué',
  },
  'ship_log_prize_gold': {
    AppLanguage.en: 'Prize: {n} gold from the hold',
    AppLanguage.fr: 'Prise : {n} pièces d\'or de la cale',
  },
  'ship_layers_label': {AppLanguage.en: 'Layers', AppLanguage.fr: 'Couches'},
  'charge_turns_label': {
    AppLanguage.en: 'charge',
    AppLanguage.fr: 'chargement'
  },
  'room_damage_label': {
    AppLanguage.en: 'room damage',
    AppLanguage.fr: 'dégâts de salle'
  },
  'pierces_shield_label': {
    AppLanguage.en: 'pierces the bulwark',
    AppLanguage.fr: 'perce le pavois'
  },
  'sets_fire_label': {AppLanguage.en: 'sets fire', AppLanguage.fr: 'incendie'},
  'ship_evasion_label': {AppLanguage.en: 'Evasion', AppLanguage.fr: 'Esquive'},
  'ship_weapons_label': {AppLanguage.en: 'Weapons', AppLanguage.fr: 'Armes'},
  'ship_crew_label': {AppLanguage.en: 'Crew', AppLanguage.fr: 'Équipage'},
  'ship_weapon_ready_label': {AppLanguage.en: 'ready', AppLanguage.fr: 'prête'},
  'ship_turn_seconds': {AppLanguage.en: '{n} s', AppLanguage.fr: '{n} s'},
  'ship_log_time_up': {
    AppLanguage.en: 'Time runs out: the turn ends.',
    AppLanguage.fr: 'Le temps est écoulé : le tour se termine.',
  },
  'ship_log_time_up_held': {
    AppLanguage.en:
        'Time runs out: {ship} holds her fire; her guns keep their charge.',
    AppLanguage.fr:
        'Le temps est écoulé : {ship} retient son tir ; ses armes gardent leur charge.',
  },
  'turn_seconds_bonus_label': {
    AppLanguage.en: '+{n} s per turn of a timed battle',
    AppLanguage.fr: '+{n} s par tour de bataille chronométrée',
  },
  'ship_turn_timer_setting_title': {
    AppLanguage.en: 'Timed ship battles',
    AppLanguage.fr: 'Batailles navales chronométrées',
  },
  'ship_turn_timer_setting_desc': {
    AppLanguage.en:
        'Each turn of a ship battle has a time limit (20 s, more with a Speaking Tube). When it runs out, the turn ends as it stands; a turn ended with half the time left is quick orders, +10% evasion.',
    AppLanguage.fr:
        'Chaque tour de bataille navale a une limite de temps (20 s, davantage avec un Porte-voix). Quand elle est écoulée, le tour se termine en l’état ; un tour terminé avec la moitié du temps restant donne des ordres rapides, +10 % d’esquive.',
  },
  'ship_end_turn_button': {
    AppLanguage.en: 'End turn',
    AppLanguage.fr: 'Fin du tour'
  },
  'ship_fire_hint_no_aim': {
    AppLanguage.en: 'Tap a ready weapon, then the room to hit.',
    AppLanguage.fr: 'Touchez une arme prête, puis la salle à frapper.',
  },
  'aimed_shots_setting_title': {
    AppLanguage.en: 'Aimed shots in ship battles',
    AppLanguage.fr: 'Tirs visés en bataille navale',
  },
  'aimed_shots_setting_desc': {
    AppLanguage.en:
        'Hold an enemy room to aim: stop the marker in the middle for a critical. Slow gives the marker more time; off makes every shot a plain one.',
    AppLanguage.fr:
        'Maintenez une salle ennemie pour viser : arrêtez le curseur au milieu pour un critique. Lent laisse plus de temps au curseur ; désactivé, chaque tir est un tir simple.',
  },
  'aimed_shots_normal': {AppLanguage.en: 'Normal', AppLanguage.fr: 'Normal'},
  'aimed_shots_slow': {AppLanguage.en: 'Slow', AppLanguage.fr: 'Lent'},
  'aimed_shots_off': {AppLanguage.en: 'Off', AppLanguage.fr: 'Désactivé'},
  'tip_got_it': {AppLanguage.en: 'Got it', AppLanguage.fr: 'Compris'},
  'tip_ship_range': {
    AppLanguage.en:
        'The ships start at medium range. Once a turn the helm can close in or pull away: far off, both ships are harder to hit; side by side, easier. Some weapons reach only so far.',
    AppLanguage.fr:
        'Les navires commencent à moyenne portée. Une fois par tour, la barre peut se rapprocher ou s’éloigner : de loin, les deux navires sont plus durs à toucher ; bord à bord, plus faciles. Certaines armes ne portent pas partout.',
  },
  'tip_ship_habit': {
    AppLanguage.en: 'How {ship} fights:',
    AppLanguage.fr: 'Comment {ship} se bat :',
  },
  'tip_ship_weather': {
    AppLanguage.en:
        'The weather turns every round, and the next round’s shows ahead. Wind throws the aim, rain puts fires out, fog hides where the enemy is aiming.',
    AppLanguage.fr:
        'Le temps change à chaque tour, et celui du tour suivant s’affiche d’avance. Le vent dévie les tirs, la pluie éteint les feux, le brouillard cache où l’ennemi vise.',
  },
  'tip_ship_aim': {
    AppLanguage.en:
        'Tap a room to fire, or hold it to take aim: stop the marker in the middle for a critical that cannot be slipped; at the edges the shot goes wide. Settings can slow the marker or turn aiming off.',
    AppLanguage.fr:
        'Touchez une salle pour tirer, ou maintenez-la pour viser : arrêtez le curseur au milieu pour un critique impossible à esquiver ; aux bords, le tir part à côté. Les réglages peuvent ralentir le curseur ou désactiver la visée.',
  },
  'tip_ship_orders': {
    AppLanguage.en:
        'Each hand aboard can give one order a battle, from the right room: tap their die under the sea and they go there and give it; hold it to read it. Drag a hand onto a room to move them.',
    AppLanguage.fr:
        'Chaque membre de l’équipage peut donner un ordre par bataille, depuis le bon poste : touchez son dé sous la mer, il s’y rend et le donne ; maintenez-le pour le lire. Glissez un membre sur une salle pour le déplacer.',
  },
  'tip_ship_fire': {
    AppLanguage.en:
        'Fire aboard: a burning room loses a pip and 3 hull every round. The hand at that station puts it out at the start of the turn.',
    AppLanguage.fr:
        'Le feu à bord : une salle en flammes perd un cran et 3 points de coque à chaque tour. La personne à ce poste l’éteint au début du tour.',
  },
  'tip_ship_leak': {
    AppLanguage.en:
        'A leak: the sea is in the hold and costs hull every round until the hand in the hold bails it.',
    AppLanguage.fr:
        'Une voie d’eau : la mer entre dans la cale et coûte de la coque à chaque tour, jusqu’à ce que la personne en cale l’écope.',
  },
  'tip_ship_boarding': {
    AppLanguage.en:
        'Their rail is open and the ships lie side by side: you can board them. The deck is fought on the dice; winning it wins the battle and their hold.',
    AppLanguage.fr:
        'Leur bastingage est ouvert et les navires sont bord à bord : vous pouvez les aborder. Le pont se dispute aux dés ; le gagner vous donne la victoire et leur cale.',
  },
  'tip_ship_sea': {
    AppLanguage.en:
        'The sea has its own say: now and then a rogue wave, a sea creature or a drifting wreck changes the round.',
    AppLanguage.fr:
        'La mer a son mot à dire : de temps en temps, une lame de fond, une créature marine ou une épave à la dérive change le tour.',
  },
  'ship_fire_hint': {
    AppLanguage.en:
        'Tap a ready weapon, then the room to hit; hold the room to take aim.',
    AppLanguage.fr:
        'Touchez une arme prête, puis la salle à frapper ; maintenez la salle pour viser.',
  },
  'ship_station_hint': {
    AppLanguage.en: 'Tap a crew member, then the room to send them to.',
    AppLanguage.fr:
        'Touchez un membre d\'équipage, puis la salle où l\'envoyer.',
  },
  'ship_aim_prefix': {AppLanguage.en: 'Aiming at', AppLanguage.fr: 'Vise'},
  'ship_incoming_label': {
    AppLanguage.en: 'incoming',
    AppLanguage.fr: 'en approche'
  },
  'ship_log_shot_hits': {
    AppLanguage.en: '{weapon} hits the {ship}\'s {room} for {n}',
    AppLanguage.fr: '{weapon} touche {room} de {ship} pour {n}',
  },
  'ship_log_shot_absorbed': {
    AppLanguage.en: '{weapon} breaks on the {ship}\'s bulwark',
    AppLanguage.fr: '{weapon} se brise sur le pavois de {ship}',
  },
  'ship_log_shot_dodged': {
    AppLanguage.en: 'The {ship} slips {weapon}',
    AppLanguage.fr: '{ship} esquive {weapon}',
  },
  'ship_log_room_down': {
    AppLanguage.en: 'The {ship}\'s {room} is knocked out',
    AppLanguage.fr: '{room} de {ship} est hors service',
  },
  'ship_log_fire_started': {
    AppLanguage.en: 'Fire in the {ship}\'s {room}!',
    AppLanguage.fr: 'Feu dans {room} de {ship} !',
  },
  'ship_log_fire_burns': {
    AppLanguage.en: 'The fire spreads in the {ship}\'s {room}',
    AppLanguage.fr: 'Le feu gagne dans {room} de {ship}',
  },
  'ship_log_fire_out': {
    AppLanguage.en: '{crew} puts out the fire in the {room}',
    AppLanguage.fr: '{crew} éteint le feu dans {room}',
  },
  'ship_log_room_repaired': {
    AppLanguage.en: '{crew} repairs the {room}',
    AppLanguage.fr: '{crew} répare {room}',
  },
  'ship_log_hull_patched': {
    AppLanguage.en: '{crew} patches the hull, +{n}',
    AppLanguage.fr: '{crew} colmate la coque, +{n}',
  },
  'ship_log_crew_hurt': {
    AppLanguage.en: '{crew} is hurt at the {room}, -{n}',
    AppLanguage.fr: '{crew} prend un coup à {room}, -{n}',
  },
  'ship_log_enemy_repairs': {
    AppLanguage.en: 'The {ship} repairs its {room}',
    AppLanguage.fr: '{ship} répare {room}',
  },
  'ship_log_leak_bailed': {
    AppLanguage.en: '{crew} bails out the hold',
    AppLanguage.fr: '{crew} écope la cale',
  },
  'ship_log_shot_wide': {
    AppLanguage.en: '{weapon} goes wide',
    AppLanguage.fr: '{weapon} part à côté',
  },
  'ship_log_critical': {
    AppLanguage.en: 'A clean hit!',
    AppLanguage.fr: 'Coup parfait !',
  },
  'ship_log_focus': {
    AppLanguage.en: 'Focused fire: the {room} takes another pip',
    AppLanguage.fr: 'Tir concentré : {room} perd un cran de plus',
  },
  'ship_log_grape': {
    AppLanguage.en: 'Grapeshot cuts down the {ship}\'s crew',
    AppLanguage.fr: 'La mitraille fauche l\'équipage de {ship}',
  },
  'ship_log_close_in': {
    AppLanguage.en: 'The {ship} closes in: {range}',
    AppLanguage.fr: '{ship} se rapproche : {range}',
  },
  'ship_log_pull_away': {
    AppLanguage.en: 'The {ship} pulls away: {range}',
    AppLanguage.fr: '{ship} s\'éloigne : {range}',
  },
  'ship_log_enemy_closes': {
    AppLanguage.en: 'The {ship} closes in: {range}',
    AppLanguage.fr: '{ship} se rapproche : {range}',
  },
  'ship_log_enemy_pulls_away': {
    AppLanguage.en: 'The {ship} pulls away: {range}',
    AppLanguage.fr: '{ship} s\'éloigne : {range}',
  },
  'ship_log_quick_orders': {
    AppLanguage.en: 'Quick orders: the Eel is already turning, +{n}% evasion',
    AppLanguage.fr: 'Ordres rapides : l\'Eel vire déjà, +{n} % d\'esquive',
  },
  'ship_log_escaped': {
    AppLanguage.en: 'The {ship} slips away over the horizon',
    AppLanguage.fr: '{ship} disparaît à l\'horizon',
  },
  'ship_log_enemy_leak_plugged': {
    AppLanguage.en: 'The {ship} plugs a leak',
    AppLanguage.fr: '{ship} colmate une voie d\'eau',
  },
  'ship_log_rammed': {
    AppLanguage.en: 'The {ship} rams you! -{n} hull, and the sea comes in',
    AppLanguage.fr: '{ship} vous éperonne ! -{n} de coque, et la mer entre',
  },
  'ship_log_warded': {
    AppLanguage.en: 'A ward of void turns {weapon} aside',
    AppLanguage.fr: 'Une garde du Néant détourne {weapon}',
  },
  'ship_log_wreck_hit': {
    AppLanguage.en: '{weapon} smashes into the drifting wreck',
    AppLanguage.fr: '{weapon} s\'écrase sur l\'épave à la dérive',
  },
  'ship_log_squall_quench': {
    AppLanguage.en: 'The squall puts out the {ship}\'s fires',
    AppLanguage.fr: 'Le grain éteint les feux de {ship}',
  },
  'ship_log_flooding': {
    AppLanguage.en: 'The {ship} takes on water, -{n} hull',
    AppLanguage.fr: '{ship} embarque de l\'eau, -{n} de coque',
  },
  'ship_log_rigging_torn': {
    AppLanguage.en: 'Chain shot tears the {ship}\'s rigging',
    AppLanguage.fr: 'Les boulets ramés déchirent le gréement de {ship}',
  },
  'ship_log_leak': {
    AppLanguage.en: 'The {ship} is holed below the waterline!',
    AppLanguage.fr: 'Voie d\'eau sous la ligne de flottaison de {ship} !',
  },
  'ship_log_weather_calm': {
    AppLanguage.en: 'The wind drops: calm',
    AppLanguage.fr: 'Le vent tombe : calme',
  },
  'ship_log_weather_tailwind': {
    AppLanguage.en: 'The wind swings behind the Eel',
    AppLanguage.fr: 'Le vent passe dans le dos de l\'Eel',
  },
  'ship_log_weather_crosswind': {
    AppLanguage.en: 'A crosswind rises: shots drift',
    AppLanguage.fr: 'Un vent de travers se lève : les tirs dévient',
  },
  'ship_log_weather_squall': {
    AppLanguage.en: 'A squall sweeps in: rain on every deck',
    AppLanguage.fr: 'Un grain arrive : la pluie sur tous les ponts',
  },
  'ship_log_weather_fog': {
    AppLanguage.en: 'Fog rolls in',
    AppLanguage.fr: 'Le brouillard tombe',
  },
  'ship_event_rogue_wave': {
    AppLanguage.en:
        'A rogue wave breaks over both ships: a shield layer lost on each',
    AppLanguage.fr:
        'Une vague scélérate balaie les deux navires : chacun perd une couche de bouclier',
  },
  'ship_event_sea_creature': {
    AppLanguage.en:
        'Something huge rises under the {ship}! -{n} hull, the hold stove in',
    AppLanguage.fr:
        'Une chose énorme surgit sous {ship} ! -{n} de coque, la cale enfoncée',
  },
  'ship_event_wreck': {
    AppLanguage.en:
        'A wreck drifts between the ships: the next shot at the Eel will hit it',
    AppLanguage.fr:
        'Une épave dérive entre les navires : le prochain tir contre l\'Eel la touchera',
  },
  'ship_log_got_away': {
    AppLanguage.en: 'The {ship} got away: no prize, but the Eel sails on',
    AppLanguage.fr:
        '{ship} a pris la fuite : pas de prise, mais l\'Eel poursuit sa route',
  },
  'ship_order_log_allHands': {
    AppLanguage.en: '{crew}: "All hands!" Every damaged room is mended a pip',
    AppLanguage.fr:
        '{crew} : « Tout le monde sur le pont ! » Chaque salle endommagée regagne un cran',
  },
  'ship_order_log_brace': {
    AppLanguage.en: '{crew}: "Brace!" The Eel takes half the hull this round',
    AppLanguage.fr:
        '{crew} : « Tenez bon ! » L\'Eel ne perd que la moitié de la coque ce tour-ci',
  },
  'ship_order_log_grapple': {
    AppLanguage.en: '{crew}: "Grapple!" The ships are hauled side by side',
    AppLanguage.fr:
        '{crew} : « Grappins ! » Les navires sont hâlés bord à bord',
  },
  'ship_order_log_bless': {
    AppLanguage.en:
        '{crew} blesses the deck: the fires die and the crew take heart',
    AppLanguage.fr:
        '{crew} bénit le pont : les feux meurent et l\'équipage reprend courage',
  },
  'ship_order_log_shoreUp': {
    AppLanguage.en: '{crew} shores up the bulwark: mended, and a layer raised',
    AppLanguage.fr: '{crew} étaye le pavois : réparé, et une couche relevée',
  },
  'ship_order_log_markHelm': {
    AppLanguage.en: '{crew} marks their helmsman: they slip nothing this turn',
    AppLanguage.fr:
        '{crew} marque leur timonier : il n\'esquive rien ce tour-ci',
  },
  'ship_order_log_cutRigging': {
    AppLanguage.en:
        '{crew} cuts their rigging: every weapon loses a step of charge',
    AppLanguage.fr:
        '{crew} coupe leur gréement : chaque arme perd un cran de charge',
  },
  'ship_order_log_eagleEye': {
    AppLanguage.en: '{crew} takes aim: the next shot will be a clean hit',
    AppLanguage.fr: '{crew} ajuste : le prochain tir fera mouche',
  },
  'ship_order_log_voidWard': {
    AppLanguage.en: '{crew} raises a ward of void over the Eel',
    AppLanguage.fr: '{crew} dresse une garde du Néant sur l\'Eel',
  },
  'ship_quick_orders_hint': {
    AppLanguage.en:
        'End the turn with half the clock left: +{n}% evasion against the volley that follows.',
    AppLanguage.fr:
        'Terminez le tour avec la moitié du temps restant : +{n} % d\'esquive contre la bordée qui suit.',
  },
  'ship_aim_fire_button': {
    AppLanguage.en: 'Fire!',
    AppLanguage.fr: 'Feu !',
  },
  'ship_weather_next_label': {
    AppLanguage.en: 'next:',
    AppLanguage.fr: 'ensuite :',
  },
  'ship_weather_calm': {
    AppLanguage.en: 'Calm',
    AppLanguage.fr: 'Calme',
  },
  'ship_weather_tailwind': {
    AppLanguage.en: 'Tailwind',
    AppLanguage.fr: 'Vent arrière',
  },
  'ship_weather_crosswind': {
    AppLanguage.en: 'Crosswind',
    AppLanguage.fr: 'Vent de travers',
  },
  'ship_weather_squall': {
    AppLanguage.en: 'Squall',
    AppLanguage.fr: 'Grain',
  },
  'ship_weather_fog': {
    AppLanguage.en: 'Fog',
    AppLanguage.fr: 'Brouillard',
  },
  'ship_weather_calm_hint': {
    AppLanguage.en: 'Calm sea: nothing changes.',
    AppLanguage.fr: 'Mer calme : rien ne change.',
  },
  'ship_weather_tailwind_hint': {
    AppLanguage.en:
        'Wind behind the Eel: +10% evasion for her, and her helm turns without a hand\'s work.',
    AppLanguage.fr:
        'Vent dans le dos de l\'Eel : +10 % d\'esquive pour elle, et sa barre manœuvre sans y employer personne.',
  },
  'ship_weather_crosswind_hint': {
    AppLanguage.en:
        'Shots drift: +10% evasion for both ships (the Wind-Knot turns it into a tailwind for the Eel).',
    AppLanguage.fr:
        'Les tirs dévient : +10 % d\'esquive pour les deux navires (le Nœud de Vent en fait un vent arrière pour l\'Eel).',
  },
  'ship_weather_squall_hint': {
    AppLanguage.en:
        'Rain on every deck: no fire starts, and every fire goes out at the end of the round.',
    AppLanguage.fr:
        'La pluie sur tous les ponts : aucun feu ne prend, et tous s\'éteignent en fin de tour.',
  },
  'ship_weather_fog_hint': {
    AppLanguage.en:
        'The enemy\'s aim cannot be read, and both ships gain +5% evasion.',
    AppLanguage.fr:
        'La visée ennemie ne se lit plus, et les deux navires gagnent +5 % d\'esquive.',
  },
  'ship_wreck_hint': {
    AppLanguage.en:
        'A wreck drifts between the ships: the next enemy shot hits it.',
    AppLanguage.fr:
        'Une épave dérive entre les navires : le prochain tir ennemi la touche.',
  },
  'ship_close_in_button': {
    AppLanguage.en: 'Close in',
    AppLanguage.fr: 'Approcher',
  },
  'ship_pull_away_button': {
    AppLanguage.en: 'Pull away',
    AppLanguage.fr: 'S\'éloigner',
  },
  'ship_range_close': {
    AppLanguage.en: 'close range',
    AppLanguage.fr: 'bord à bord',
  },
  'ship_range_medium': {
    AppLanguage.en: 'medium range',
    AppLanguage.fr: 'moyenne portée',
  },
  'ship_range_long': {
    AppLanguage.en: 'long range',
    AppLanguage.fr: 'longue portée',
  },
  'ship_range_close_title': {
    AppLanguage.en: 'Close',
    AppLanguage.fr: 'Bord à bord',
  },
  'ship_range_medium_title': {
    AppLanguage.en: 'Medium range',
    AppLanguage.fr: 'Moyenne portée',
  },
  'ship_range_long_title': {
    AppLanguage.en: 'Long range',
    AppLanguage.fr: 'Longue portée',
  },
  'ship_range_close_hint': {
    AppLanguage.en:
        'Side by side: -10% evasion for both ships; boarding is possible; every weapon reaches.',
    AppLanguage.fr:
        'Bord à bord : -10 % d\'esquive pour les deux navires ; l\'abordage est possible ; toutes les armes portent.',
  },
  'ship_range_medium_hint': {
    AppLanguage.en: 'Medium range: no change; fire pots cannot reach.',
    AppLanguage.fr:
        'Moyenne portée : rien ne change ; les pots à feu ne portent pas.',
  },
  'ship_range_long_hint': {
    AppLanguage.en:
        'Far apart: +10% evasion for both ships; harpoons and fire pots cannot reach. A fleeing ship escapes from here.',
    AppLanguage.fr:
        'Loin l\'un de l\'autre : +10 % d\'esquive pour les deux navires ; harpons et pots à feu ne portent pas. Un navire en fuite s\'échappe d\'ici.',
  },
  'ship_habit_flee': {
    AppLanguage.en: 'Runs when hurt',
    AppLanguage.fr: 'Fuit une fois touché',
  },
  'ship_habit_marksman': {
    AppLanguage.en: 'Keeps its distance, shoots the crew',
    AppLanguage.fr: 'Garde ses distances, vise l\'équipage',
  },
  'ship_habit_ram': {
    AppLanguage.en: 'Rams',
    AppLanguage.fr: 'Éperonne',
  },
  'ship_habit_boarder': {
    AppLanguage.en: 'Boards again and again',
    AppLanguage.fr: 'Aborde encore et encore',
  },
  'ship_habit_none': {
    AppLanguage.en: 'Fights',
    AppLanguage.fr: 'Combat',
  },
  'ship_habit_none_hint': {
    AppLanguage.en: 'An ordinary opponent.',
    AppLanguage.fr: 'Un adversaire ordinaire.',
  },
  'ship_habit_flee_hint': {
    AppLanguage.en:
        'Closes in to grapple while healthy; at 40% hull or less it runs for long range, and escapes if it starts its turn there. Close in, or break its helm.',
    AppLanguage.fr:
        'Se rapproche pour agripper tant qu\'il est intact ; à 40 % de coque ou moins il file vers la longue portée, et s\'échappe s\'il y commence son tour. Rapprochez-vous, ou brisez sa barre.',
  },
  'ship_habit_marksman_hint': {
    AppLanguage.en:
        'Steers for long range and aims at the rooms your crew stand in; its hits hurt the crew half again as much.',
    AppLanguage.fr:
        'Cherche la longue portée et vise les salles où se tient votre équipage ; ses coups blessent moitié plus l\'équipage.',
  },
  'ship_habit_ram_hint': {
    AppLanguage.en:
        'Steers alongside and, once a battle, rams: 12 hull through any shield, and a leak.',
    AppLanguage.fr:
        'Vient bord à bord et, une fois par bataille, éperonne : 12 de coque à travers tout bouclier, et une voie d\'eau.',
  },
  'ship_habit_boarder_hint': {
    AppLanguage.en:
        'Steers alongside and boards every third round spent side by side, shields or not (twice a battle at most).',
    AppLanguage.fr:
        'Vient bord à bord et aborde tous les trois tours passés bord à bord, boucliers ou non (deux fois par bataille au plus).',
  },
  'ship_focus_hint': {
    AppLanguage.en: 'Hit this turn: another hit here knocks off an extra pip.',
    AppLanguage.fr:
        'Touchée ce tour : un nouveau coup ici arrache un cran de plus.',
  },
  'ship_out_of_range_label': {
    AppLanguage.en: 'out of reach',
    AppLanguage.fr: 'hors de portée',
  },
  'ship_slips_label': {
    AppLanguage.en: 'SLIPS {n}%',
    AppLanguage.fr: 'ESQUIVE {n} %',
  },
  'ship_evasion_hint': {
    AppLanguage.en:
        'The chance this ship slips a shot: its helm, its helmsman, the range and the weather. None at all with its helm knocked out.',
    AppLanguage.fr:
        'La chance que ce navire esquive un tir : sa barre, son timonier, la portée et le temps. Aucune si sa barre est hors d\'usage.',
  },
  'ship_crew_button': {
    AppLanguage.en: 'Crew',
    AppLanguage.fr: 'Équipage',
  },
  'ship_crew_title': {
    AppLanguage.en: 'Crew & orders',
    AppLanguage.fr: 'Équipage et ordres',
  },
  'ship_log_title': {
    AppLanguage.en: 'Battle log',
    AppLanguage.fr: 'Journal de bataille',
  },
  'ship_room_out_label': {
    AppLanguage.en: 'OUT',
    AppLanguage.fr: 'HS',
  },
  'ship_slipped_label': {
    AppLanguage.en: 'Slipped',
    AppLanguage.fr: 'Esquivé',
  },
  'ship_blocked_label': {
    AppLanguage.en: 'Blocked',
    AppLanguage.fr: 'Paré',
  },
  'ship_enemy_turn_label': {
    AppLanguage.en: '{ship} fires',
    AppLanguage.fr: '{ship} fait feu',
  },
  'ship_weapon_armed_label': {
    AppLanguage.en: 'armed',
    AppLanguage.fr: 'armée',
  },
  'ship_ammo_round_hint': {
    AppLanguage.en: 'Round shot: the weapon as it is.',
    AppLanguage.fr: 'Boulet : l\'arme telle quelle.',
  },
  'ship_ammo_chain_hint': {
    AppLanguage.en:
        'Chain shot: half the hull, but it tears a pip off their helm wherever it lands.',
    AppLanguage.fr:
        'Boulet ramé : moitié moins de coque, mais il arrache un cran à leur barre où qu\'il touche.',
  },
  'ship_ammo_grape_hint': {
    AppLanguage.en:
        'Grapeshot: half the hull, but their crew repairs one less for two rounds.',
    AppLanguage.fr:
        'Mitraille : moitié moins de coque, mais leur équipage répare une fois de moins pendant deux tours.',
  },
  'ship_ammo_heated_hint': {
    AppLanguage.en:
        'Heated shot: three quarters of the hull, and the room it lands in burns.',
    AppLanguage.fr:
        'Boulet rouge : trois quarts de la coque, et la salle touchée prend feu.',
  },
  'ship_orders_label': {
    AppLanguage.en: 'Orders:',
    AppLanguage.fr: 'Ordres :',
  },
  'ship_order_allHands': {
    AppLanguage.en: 'All hands!',
    AppLanguage.fr: 'Tous sur le pont !',
  },
  'ship_order_brace': {
    AppLanguage.en: 'Brace!',
    AppLanguage.fr: 'Tenez bon !',
  },
  'ship_order_grapple': {
    AppLanguage.en: 'Grapple!',
    AppLanguage.fr: 'Grappins !',
  },
  'ship_order_bless': {
    AppLanguage.en: 'Bless the deck',
    AppLanguage.fr: 'Bénir le pont',
  },
  'ship_order_shoreUp': {
    AppLanguage.en: 'Shore up',
    AppLanguage.fr: 'Étayer',
  },
  'ship_order_markHelm': {
    AppLanguage.en: 'Mark their helmsman',
    AppLanguage.fr: 'Marquer le timonier',
  },
  'ship_order_cutRigging': {
    AppLanguage.en: 'Cut their rigging',
    AppLanguage.fr: 'Couper le gréement',
  },
  'ship_order_eagleEye': {
    AppLanguage.en: 'Eagle eye',
    AppLanguage.fr: 'Œil d\'aigle',
  },
  'ship_order_voidWard': {
    AppLanguage.en: 'Void ward',
    AppLanguage.fr: 'Garde du Néant',
  },
  'ship_order_allHands_hint': {
    AppLanguage.en:
        'Once a battle: every damaged room on the Eel is mended a pip.',
    AppLanguage.fr:
        'Une fois par bataille : chaque salle endommagée de l\'Eel regagne un cran.',
  },
  'ship_order_brace_hint': {
    AppLanguage.en: 'Once a battle: the Eel takes half the hull this round.',
    AppLanguage.fr:
        'Une fois par bataille : l\'Eel ne perd que la moitié de la coque ce tour-ci.',
  },
  'ship_order_grapple_hint': {
    AppLanguage.en:
        'Once a battle: the ships are hauled side by side and the grapples hold; board this turn, shields or not.',
    AppLanguage.fr:
        'Une fois par bataille : les navires sont hâlés bord à bord et les grappins tiennent ; abordez ce tour-ci, boucliers ou non.',
  },
  'ship_order_bless_hint': {
    AppLanguage.en:
        'Once a battle: every fire aboard goes out and the crew heal 10.',
    AppLanguage.fr:
        'Une fois par bataille : tous les feux à bord s\'éteignent et l\'équipage récupère 10 points de vie.',
  },
  'ship_order_shoreUp_hint': {
    AppLanguage.en:
        'Once a battle: the bulwark is mended and a shield layer raised.',
    AppLanguage.fr:
        'Une fois par bataille : le pavois est réparé et une couche de bouclier relevée.',
  },
  'ship_order_markHelm_hint': {
    AppLanguage.en: 'Once a battle: the enemy slips nothing this turn.',
    AppLanguage.fr:
        'Une fois par bataille : l\'ennemi n\'esquive rien ce tour-ci.',
  },
  'ship_order_cutRigging_hint': {
    AppLanguage.en: 'Once a battle: every enemy weapon loses a step of charge.',
    AppLanguage.fr:
        'Une fois par bataille : chaque arme ennemie perd un cran de charge.',
  },
  'ship_order_eagleEye_hint': {
    AppLanguage.en:
        'Once a battle: the next shot this turn cannot be slipped, does half again the hull and an extra pip.',
    AppLanguage.fr:
        'Une fois par bataille : le prochain tir de ce tour ne peut être esquivé, inflige moitié plus de coque et un cran de plus.',
  },
  'ship_order_voidWard_hint': {
    AppLanguage.en:
        'Once a battle: the first enemy shot this round is turned aside.',
    AppLanguage.fr:
        'Une fois par bataille : le premier tir ennemi de ce tour est détourné.',
  },
  'weapon_reach_label': {
    AppLanguage.en: 'reach:',
    AppLanguage.fr: 'portée :',
  },
  'ship_log_enemy_fire_out': {
    AppLanguage.en: 'The {ship} fights the fire in its {room}',
    AppLanguage.fr: '{ship} combat le feu dans {room}',
  },
  'port_shops_section': {
    AppLanguage.en: 'Harbor trade',
    AppLanguage.fr: 'Commerce du port'
  },
  'port_sail_subtitle': {
    AppLanguage.en: 'Other ports, other expeditions',
    AppLanguage.fr: "D'autres ports, d'autres expéditions"
  },
  'home_port_label': {
    AppLanguage.en: 'Home port',
    AppLanguage.fr: "Port d'attache"
  },
  'chapter_short_prefix': {
    AppLanguage.en: 'Chapter',
    AppLanguage.fr: 'Chapitre'
  },
  'back_to_port_button': {
    AppLanguage.en: 'Back to port',
    AppLanguage.fr: 'Retour au port'
  },
  'export_as_csv_option': {
    AppLanguage.en: 'Export as CSV (.csv)',
    AppLanguage.fr: 'Exporter en CSV (.csv)',
  },
  // --- Boss phases ---
  'phase_chip_prefix': {AppLanguage.en: 'Phase', AppLanguage.fr: 'Phase'},
  'phases_label': {AppLanguage.en: 'Phases', AppLanguage.fr: 'Phases'},
  'phases_hint': {
    AppLanguage.en: 'this one changes as it weakens',
    AppLanguage.fr: "celui-ci change à mesure qu'il faiblit",
  },
  'phase_heals_prefix': {
    AppLanguage.en: 'recovers',
    AppLanguage.fr: 'récupère'
  },
  'phase_cleansed_label': {
    AppLanguage.en: 'shrugs off every affliction',
    AppLanguage.fr: 'se débarrasse de toutes ses afflictions',
  },
  'phase_enraged_label': {
    AppLanguage.en: 'hits harder from now on',
    AppLanguage.fr: 'frappe plus fort désormais',
  },
  // --- Gear effects: sets and uniques ---
  'set_label': {AppLanguage.en: 'Set', AppLanguage.fr: 'Panoplie'},
  'set_pieces_label': {AppLanguage.en: 'pieces', AppLanguage.fr: 'pièces'},
  'unique_label': {AppLanguage.en: 'Unique', AppLanguage.fr: 'Unique'},
  'unique_lifesteal_desc': {
    AppLanguage.en: 'heals {v}% of the damage it deals',
    AppLanguage.fr: "soigne {v} % des dégâts infligés",
  },
  'unique_thorns_desc': {
    AppLanguage.en: 'whatever hits you takes {v} damage back',
    AppLanguage.fr: 'ce qui vous frappe encaisse {v} dégâts en retour',
  },
  'unique_second_wind_desc': {
    AppLanguage.en: 'once per fight, a lethal blow leaves you at 1 HP',
    AppLanguage.fr: 'une fois par combat, un coup mortel vous laisse à 1 PV',
  },
  'unique_mana_on_hit_desc': {
    AppLanguage.en: '+{v} mana on every damaging hit',
    AppLanguage.fr: '+{v} mana à chaque coup qui blesse',
  },
  'unique_crit_desc': {
    AppLanguage.en: '+{v}% critical chance',
    AppLanguage.fr: '+{v} % de chance de critique',
  },
  'unique_dodge_desc': {
    AppLanguage.en: '+{v}% dodge',
    AppLanguage.fr: "+{v} % d'esquive",
  },
  'lifesteal_suffix': {
    AppLanguage.en: 'drinks back',
    AppLanguage.fr: 'récupère par le sang'
  },
  'thorns_suffix': {
    AppLanguage.en: 'is cut by the thorns for',
    AppLanguage.fr: 'est entaillé par les épines :',
  },
  'second_wind_message': {
    AppLanguage.en: 'refuses to fall — the Phoenix Sigil burns out!',
    AppLanguage.fr: "refuse de tomber — le Sceau du Phénix se consume !",
  },
  // --- Companion targeting ---
  'companion_auto_target_setting_title': {
    AppLanguage.en: 'Companions pick their own targets',
    AppLanguage.fr: 'Les compagnons choisissent leurs cibles',
  },
  'companion_auto_target_setting_desc': {
    AppLanguage.en:
        'In a pack fight, companions focus fire on your target (or the weakest enemy). Turn off to aim every party member by hand.',
    AppLanguage.fr:
        'Dans un combat de groupe, les compagnons concentrent leurs coups sur votre cible (ou le plus faible ennemi). Désactivez pour viser chaque membre à la main.',
  },
  // --- New Game+ ---
  'new_game_plus_label': {
    AppLanguage.en: 'New Game+',
    AppLanguage.fr: 'Nouvelle partie+'
  },
  'new_game_plus_button': {
    AppLanguage.en: 'New Game+',
    AppLanguage.fr: 'Nouvelle partie+'
  },
  'new_game_plus_cycle_label': {
    AppLanguage.en: 'Cycle',
    AppLanguage.fr: 'Cycle'
  },
  'new_game_plus_hint': {
    AppLanguage.en:
        'Go round again with your dice, your spells and a quarter of your gold. Everything else starts over, and every enemy is tougher.',
    AppLanguage.fr:
        "Repartez avec vos dés, vos sorts et un quart de votre or. Tout le reste recommence, et chaque ennemi est plus coriace.",
  },
  'new_game_plus_desc': {
    AppLanguage.en:
        'The next cycle starts the story from the top with a new character who inherits every die you own, every spell you know and a quarter of your gold. Level, gear, companions, camp and quests start over.',
    AppLanguage.fr:
        "Le cycle suivant reprend l'histoire depuis le début avec un nouveau personnage qui hérite de tous vos dés, de tous vos sorts et d'un quart de votre or. Niveau, équipement, compagnons, camp et quêtes recommencent.",
  },
  'new_game_plus_enemies_prefix': {
    AppLanguage.en: 'Enemies',
    AppLanguage.fr: 'Ennemis'
  },
  'new_game_plus_enemies_suffix': {
    AppLanguage.en: 'health and damage',
    AppLanguage.fr: 'de santé et de dégâts',
  },
  'new_game_plus_confirm': {
    AppLanguage.en: 'Begin the next cycle',
    AppLanguage.fr: 'Commencer le cycle suivant',
  },
  'new_game_plus_started_message': {
    AppLanguage.en:
        'The road begins again. Your legacy waits at character creation.',
    AppLanguage.fr:
        'La route recommence. Votre héritage vous attend à la création du personnage.',
  },
  'new_game_plus_card_desc': {
    AppLanguage.en:
        'Your dice, spells and a share of your gold came through from the last cycle.',
    AppLanguage.fr:
        "Vos dés, vos sorts et une part de votre or viennent du cycle précédent.",
  },
  // --- Endings ---
  'epilogue_heading': {AppLanguage.en: 'Epilogue', AppLanguage.fr: 'Épilogue'},
  'aftermath_heading': {
    AppLanguage.en: 'After the fight',
    AppLanguage.fr: 'Après le combat',
  },
  'expedition_midpoint_label': {
    AppLanguage.en: 'Halfway',
    AppLanguage.fr: 'À mi-chemin',
  },
  'expedition_press_on': {
    AppLanguage.en: 'Press on',
    AppLanguage.fr: 'Continuer',
  },
  'fate_title': {
    AppLanguage.en: 'The fate die',
    AppLanguage.fr: 'Le dé du destin',
  },
  'fate_intro': {
    AppLanguage.en:
        'The fire burns low. Before sleep, someone rolls the camp\'s old die, the one that decides the night.',
    AppLanguage.fr:
        'Le feu baisse. Avant de dormir, quelqu\'un lance le vieux dé du camp, celui qui décide de la nuit.',
  },
  'fate_roll_button': {
    AppLanguage.en: 'Roll',
    AppLanguage.fr: 'Lancer',
  },
  'fate_close_button': {
    AppLanguage.en: 'Sleep',
    AppLanguage.fr: 'Dormir',
  },
  'fate_hint': {
    AppLanguage.en:
        'Every rest at the camp rolls it. A face that cannot happen tonight shows a quiet night.',
    AppLanguage.fr:
        'Chaque repos au camp le lance. Une face qui ne peut pas arriver cette nuit montre une nuit calme.',
  },
  'fate_face_windfall': {
    AppLanguage.en: 'Windfall',
    AppLanguage.fr: 'Aubaine',
  },
  'fate_face_visitor': {
    AppLanguage.en: 'Visitor',
    AppLanguage.fr: 'Visite',
  },
  'fate_face_rumor': {
    AppLanguage.en: 'Rumor',
    AppLanguage.fr: 'Rumeur',
  },
  'fate_face_quarrel': {
    AppLanguage.en: 'Quarrel',
    AppLanguage.fr: 'Querelle',
  },
  'fate_face_theft': {
    AppLanguage.en: 'Theft',
    AppLanguage.fr: 'Vol',
  },
  'fate_face_quiet': {
    AppLanguage.en: 'Quiet night',
    AppLanguage.fr: 'Nuit calme',
  },
  'fate_windfall_gold': {
    AppLanguage.en:
        'Someone gathering firewood finds a purse half buried in the sand, and no one to claim it.',
    AppLanguage.fr:
        'En ramassant du bois, quelqu\'un trouve une bourse à moitié enfouie dans le sable, et personne pour la réclamer.',
  },
  'fate_windfall_rations': {
    AppLanguage.en:
        'A crate washes up on the shore with its seal still good: salt fish and hard bread.',
    AppLanguage.fr:
        'Une caisse s\'échoue sur la rive, le sceau intact : du poisson salé et du pain dur.',
  },
  'fate_visitor_pilgrims': {
    AppLanguage.en:
        'Three pilgrims come out of the dark, thin as their staffs. They ask for nothing, which is worse.',
    AppLanguage.fr:
        'Trois pèlerins sortent de l\'obscurité, maigres comme leurs bâtons. Ils ne demandent rien, et c\'est pire.',
  },
  'fate_visitor_deserter': {
    AppLanguage.en:
        'A young soldier in Crusade colours stumbles into the firelight, sword belt cut away. "They hang deserters."',
    AppLanguage.fr:
        'Un jeune soldat aux couleurs de la Croisade entre en titubant dans la lumière du feu, le baudrier tranché. « Ils pendent les déserteurs. »',
  },
  'fate_visitor_storyteller': {
    AppLanguage.en:
        'An old storyteller asks for a seat by the fire and offers a tale for it.',
    AppLanguage.fr:
        'Un vieux conteur demande une place près du feu et offre une histoire en échange.',
  },
  'fate_choice_shareRations': {
    AppLanguage.en: 'Share our rations ({n} rations)',
    AppLanguage.fr: 'Partager nos rations ({n} rations)',
  },
  'fate_choice_sendOn': {
    AppLanguage.en: 'Send them on',
    AppLanguage.fr: 'Les laisser repartir',
  },
  'fate_choice_hideDeserter': {
    AppLanguage.en: 'Hide the deserter',
    AppLanguage.fr: 'Cacher le déserteur',
  },
  'fate_choice_handOver': {
    AppLanguage.en: 'Hand them over (+{n} gold)',
    AppLanguage.fr: 'Le livrer (+{n} or)',
  },
  'fate_choice_listen': {
    AppLanguage.en: 'Listen',
    AppLanguage.fr: 'Écouter',
  },
  'fate_choice_sendAway': {
    AppLanguage.en: 'Send the storyteller away',
    AppLanguage.fr: 'Renvoyer le conteur',
  },
  'fate_choice_sideWithFirst': {
    AppLanguage.en: 'Side with {name}',
    AppLanguage.fr: 'Donner raison à {name}',
  },
  'fate_choice_sideWithSecond': {
    AppLanguage.en: 'Side with {name}',
    AppLanguage.fr: 'Donner raison à {name}',
  },
  'fate_choice_makePeace': {
    AppLanguage.en: 'Make peace (Charisma, DC {dc})',
    AppLanguage.fr: 'Ramener la paix (Charisme, DD {dc})',
  },
  'fate_result_shareRations': {
    AppLanguage.en:
        'They eat in silence and leave before dawn, lighter of step.',
    AppLanguage.fr:
        'Ils mangent en silence et repartent avant l\'aube, d\'un pas plus léger.',
  },
  'fate_result_sendOn': {
    AppLanguage.en:
        'They nod as if they had expected it, and walk on into the dark.',
    AppLanguage.fr:
        'Ils hochent la tête comme s\'ils s\'y attendaient, et repartent dans la nuit.',
  },
  'fate_result_hideDeserter': {
    AppLanguage.en:
        'At dawn a patrol passes the camp and finds nothing. The deserter is gone by noon, in a borrowed cloak.',
    AppLanguage.fr:
        'À l\'aube, une patrouille passe au camp et ne trouve rien. Le déserteur est parti avant midi, dans un manteau prêté.',
  },
  'fate_result_handOver': {
    AppLanguage.en:
        'The patrol pays in silver and does not look back. Neither does the deserter.',
    AppLanguage.fr:
        'La patrouille paie en argent et ne se retourne pas. Le déserteur non plus.',
  },
  'fate_result_listen': {
    AppLanguage.en:
        'The tale runs past midnight, and the whole camp laughs in the same places.',
    AppLanguage.fr:
        'L\'histoire dure jusqu\'après minuit, et tout le camp rit aux mêmes endroits.',
  },
  'fate_result_sendAway': {
    AppLanguage.en: 'The storyteller shrugs and takes the tale elsewhere.',
    AppLanguage.fr:
        'Le conteur hausse les épaules et emporte son histoire ailleurs.',
  },
  'fate_rumor': {
    AppLanguage.en:
        'A rider stops to water a horse and talks of {place}. Before dawn, it is on your map.',
    AppLanguage.fr:
        'Un cavalier s\'arrête pour abreuver son cheval et parle de {place}. Avant l\'aube, l\'endroit est sur votre carte.',
  },
  'fate_quarrel': {
    AppLanguage.en: '{a} and {b} are at it again, {topic}.',
    AppLanguage.fr: '{a} et {b} se disputent encore, {topic}.',
  },
  'fate_quarrel_topic_0': {
    AppLanguage.en: 'over the watch rota',
    AppLanguage.fr: 'pour les tours de garde',
  },
  'fate_quarrel_topic_1': {
    AppLanguage.en: 'over the last of the wine',
    AppLanguage.fr: 'pour le fond de la dernière bouteille',
  },
  'fate_quarrel_topic_2': {
    AppLanguage.en: 'about how the last fight went',
    AppLanguage.fr: 'sur la façon dont le dernier combat a tourné',
  },
  'fate_quarrel_topic_3': {
    AppLanguage.en: 'over whose turn it is to cook',
    AppLanguage.fr: 'pour savoir à qui revient la cuisine',
  },
  'fate_result_side': {
    AppLanguage.en: '{winner} nods. {loser} goes to sleep without a word.',
    AppLanguage.fr:
        '{winner} approuve d\'un signe de tête. {loser} va se coucher sans un mot.',
  },
  'fate_result_peace': {
    AppLanguage.en:
        'By the end, the two of them are laughing at the whole thing.',
    AppLanguage.fr: 'À la fin, les deux en rient.',
  },
  'fate_result_no_peace': {
    AppLanguage.en: 'Your words only give them something else to argue about.',
    AppLanguage.fr: 'Vos mots ne leur donnent qu\'un autre sujet de dispute.',
  },
  'fate_theft': {
    AppLanguage.en: 'Something moves among the packs in the dark.',
    AppLanguage.fr: 'Quelque chose bouge parmi les sacs, dans le noir.',
  },
  'fate_theft_caught': {
    AppLanguage.en:
        'You catch a thin hand in the supplies and send its owner running, empty-handed.',
    AppLanguage.fr:
        'Vous surprenez une main maigre dans les provisions et faites fuir son propriétaire, les mains vides.',
  },
  'fate_theft_gold': {
    AppLanguage.en:
        'By morning the thief is long gone, and the gold with them.',
    AppLanguage.fr: 'Au matin, le voleur est loin, et l\'or avec lui.',
  },
  'fate_theft_rations': {
    AppLanguage.en:
        'By morning the thief is long gone, and some rations with them.',
    AppLanguage.fr: 'Au matin, le voleur est loin, et des rations avec lui.',
  },
  'fate_theft_nothing': {
    AppLanguage.en:
        'By morning the thief is gone, empty-handed: there was nothing left to take.',
    AppLanguage.fr:
        "Au matin, le voleur est reparti les mains vides : il n'y avait plus rien à prendre.",
  },
  'fate_check_line': {
    AppLanguage.en: '{stat} {total} against {dc}.',
    AppLanguage.fr: '{stat} {total} contre {dc}.',
  },
  'fate_quiet_0': {
    AppLanguage.en:
        'Nothing comes out of the dark tonight. The fire, the sea, and sleep.',
    AppLanguage.fr:
        'Rien ne sort de l\'obscurité cette nuit. Le feu, la mer, et le sommeil.',
  },
  'fate_quiet_1': {
    AppLanguage.en: 'Someone hums an old song until the others join in, badly.',
    AppLanguage.fr:
        'Quelqu\'un fredonne une vieille chanson jusqu\'à ce que les autres s\'y mettent, mal.',
  },
  'fate_quiet_2': {
    AppLanguage.en:
        'The sky is clear. For one night, nobody talks about the Shroud.',
    AppLanguage.fr:
        'Le ciel est clair. Pour une nuit, personne ne parle du Linceul.',
  },
  'fate_gain_gold': {
    AppLanguage.en: '+{n} gold',
    AppLanguage.fr: '+{n} or',
  },
  'fate_lose_gold': {
    AppLanguage.en: '−{n} gold',
    AppLanguage.fr: '−{n} or',
  },
  'fate_gain_rations': {
    AppLanguage.en: '+{n} rations',
    AppLanguage.fr: '+{n} rations',
  },
  'fate_lose_rations': {
    AppLanguage.en: '−{n} rations',
    AppLanguage.fr: '−{n} rations',
  },
  'fate_alignment': {
    AppLanguage.en: 'Alignment {n}',
    AppLanguage.fr: 'Alignement {n}',
  },
  'fate_approval_up': {
    AppLanguage.en: '{name} approves',
    AppLanguage.fr: '{name} approuve',
  },
  'fate_approval_down': {
    AppLanguage.en: '{name} disapproves',
    AppLanguage.fr: '{name} désapprouve',
  },
  'fate_place_found': {
    AppLanguage.en: 'New place: {place}',
    AppLanguage.fr: 'Nouveau lieu : {place}',
  },
  'ship_run_button': {
    AppLanguage.en: 'Run for it',
    AppLanguage.fr: 'Prendre la fuite',
  },
  'ship_run_hint': {
    AppLanguage.en:
        'Far off, turn tail instead of firing: three turns of it and the Eel is away (a tailwind counts double). No gun fires in a turn you run.',
    AppLanguage.fr:
        'De loin, virer de bord au lieu de tirer : trois tours et l\'Eel est hors d\'atteinte (un vent arrière compte double). Aucun canon ne tire pendant un tour de fuite.',
  },
  'ship_escape_label': {
    AppLanguage.en: 'run: {n} to go',
    AppLanguage.fr: 'fuite : encore {n}',
  },
  'ship_run_left_hint': {
    AppLanguage.en: 'Turns of running still needed to get away: {n}.',
    AppLanguage.fr: 'Tours de fuite encore nécessaires pour s\'échapper : {n}.',
  },
  'ship_run_warning': {
    AppLanguage.en:
        'Hull under 30%: get to long range and run for it while you can.',
    AppLanguage.fr:
        'Coque sous 30 % : gagnez la longue portée et prenez la fuite tant que vous le pouvez.',
  },
  'ship_log_running': {
    AppLanguage.en: 'The {ship} turns tail and runs ({n}/3)',
    AppLanguage.fr: '{ship} vire de bord et fuit ({n}/3)',
  },
  'ship_log_fled': {
    AppLanguage.en: 'The {ship} runs clear and leaves the fight behind',
    AppLanguage.fr: '{ship} prend le large et laisse le combat derrière lui',
  },
  'ship_log_run_caught': {
    AppLanguage.en: 'The {ship} closes the gap: the run loses ground ({n}/3)',
    AppLanguage.fr: '{ship} réduit l\'écart : la fuite perd du terrain ({n}/3)',
  },
  'tip_ship_run': {
    AppLanguage.en:
        'At long range the Eel can run for it instead of firing. Three turns of running and she is away, two with the wind behind her. If the enemy closes the gap, the run loses a turn: start before the hull runs low.',
    AppLanguage.fr:
        'À longue portée, l\'Eel peut prendre la fuite au lieu de tirer. Trois tours de fuite et il est hors d\'atteinte, deux avec le vent arrière. Si l\'ennemi réduit l\'écart, la fuite perd un tour : fuyez avant que la coque ne soit trop basse.',
  },
  'contract_sinkShips': {
    AppLanguage.en: 'Sink or take {n} ships at sea',
    AppLanguage.fr: 'Couler ou prendre {n} navires en mer',
  },
  'contract_takeShip': {
    AppLanguage.en: 'Take a ship by boarding her',
    AppLanguage.fr: 'Prendre un navire à l\'abordage',
  },
  'contract_keelIntact': {
    AppLanguage.en: 'Win a sea fight losing no more than a quarter of the hull',
    AppLanguage.fr:
        'Gagner un combat en mer sans perdre plus d\'un quart de la coque',
  }, // --- Sea beasts (v1.185, see sea_beasts.dart) ---
  'contract_beastFought': {
    AppLanguage.en: 'Stand up to a sea beast and live',
    AppLanguage.fr: 'Tenir tête à une bête marine et en revenir',
  },
  'beast_room_helm_title': {
    AppLanguage.en: 'Fins',
    AppLanguage.fr: 'Nageoires'
  },
  'beast_room_guns_title': {AppLanguage.en: 'Jaws', AppLanguage.fr: 'Gueule'},
  'beast_room_bulwark_title': {AppLanguage.en: 'Hide', AppLanguage.fr: 'Cuir'},
  'beast_room_hold_title': {AppLanguage.en: 'Heart', AppLanguage.fr: 'Cœur'},
  'beast_room_helm': {AppLanguage.en: 'fins', AppLanguage.fr: 'les nageoires'},
  'beast_room_guns': {AppLanguage.en: 'jaws', AppLanguage.fr: 'la gueule'},
  'beast_room_bulwark': {AppLanguage.en: 'hide', AppLanguage.fr: 'le cuir'},
  'beast_room_hold': {AppLanguage.en: 'heart', AppLanguage.fr: 'le cœur'},
  'beast_room_helm_hint': {
    AppLanguage.en:
        'How it slips your shots and turns. With its fins torn it can neither dive nor flee.',
    AppLanguage.fr:
        'Ce qui lui fait esquiver vos tirs et virer. Nageoires déchirées, la bête ne peut ni plonger ni fuir.',
  },
  'beast_room_guns_hint': {
    AppLanguage.en:
        'Its bites and blows charge here. Knock the jaws out and it strikes at nothing.',
    AppLanguage.fr:
        'Ses morsures et ses coups se préparent ici. Gueule hors d\'état, la bête ne frappe plus rien.',
  },
  'beast_room_bulwark_hint': {
    AppLanguage.en:
        'One layer of hide per pip turns a shot that does not pierce, and cracks for it.',
    AppLanguage.fr:
        'Chaque cran de cuir arrête un tir qui ne perce pas, et se fend à chaque fois.',
  },
  'beast_room_hold_hint': {
    AppLanguage.en:
        'While the heart beats it heals every round. Stop it, or hold it on a harpoon line.',
    AppLanguage.fr:
        'Tant que le cœur bat, la bête guérit à chaque tour. Arrêtez ce cœur, ou tenez-la au bout d\'une ligne de harpon.',
  },
  'beast_status_turning': {
    AppLanguage.en: 'Turning for the deep!',
    AppLanguage.fr: 'Part vers les fonds !',
  },
  'beast_status_tethered': {
    AppLanguage.en: 'On the line: {n}',
    AppLanguage.fr: 'À la ligne : {n}',
  },
  'beast_status_dives_now': {
    AppLanguage.en: 'Dives this turn!',
    AppLanguage.fr: 'Plonge ce tour-ci !',
  },
  'beast_status_dives_in': {
    AppLanguage.en: 'Dives in {n}',
    AppLanguage.fr: 'Plonge dans {n}',
  },
  'beast_status_regen': {
    AppLanguage.en: 'Heals {n} a round',
    AppLanguage.fr: 'Guérit de {n} par tour',
  },
  'beast_status_regen_stopped': {
    AppLanguage.en: 'Not healing',
    AppLanguage.fr: 'Ne guérit plus',
  },
  'beast_status_edge': {
    AppLanguage.en: 'Known ways: -{n}% slip',
    AppLanguage.fr: 'Ruses connues : -{n} % d\'esquive',
  },
  'tip_ship_beast': {
    AppLanguage.en:
        'A sea beast, not a ship. It heals every round while its heart beats, some dive under the Eel, and when it is hurt it turns for the deep and is gone the next turn. Tear its fins or hold it on a harpoon line and it cannot go. Run for it if it is too much: its wounds stay with it for the next meeting.',
    AppLanguage.fr:
        'Une bête marine, pas un navire. Elle guérit à chaque tour tant que son cœur bat, certaines plongent sous l\'Eel, et blessée elle part vers les fonds et disparaît au tour suivant. Déchirez ses nageoires ou tenez-la au bout d\'une ligne de harpon et elle ne peut plus partir. Fuyez si c\'est trop : ses blessures la suivent jusqu\'à la prochaine rencontre.',
  },
  'tip_ship_tether': {
    AppLanguage.en:
        'A harpoon that bites holds the beast on the line for a few rounds: no healing, no diving, no fleeing while it holds.',
    AppLanguage.fr:
        'Un harpon qui mord tient la bête au bout de la ligne quelques tours : ni guérison, ni plongée, ni fuite tant qu\'il tient.',
  },
  'ship_log_tethered': {
    AppLanguage.en: 'The harpoon bites: the {ship} is on the line ({n})',
    AppLanguage.fr: 'Le harpon mord : {ship} est à la ligne ({n})',
  },
  'ship_log_tether_slips': {
    AppLanguage.en: 'The line goes slack: the {ship} is free of it',
    AppLanguage.fr: 'La ligne mollit : {ship} s\'en libère',
  },
  'ship_log_beast_escaped': {
    AppLanguage.en: 'The {ship} sounds into the deep and is gone',
    AppLanguage.fr: '{ship} sonde vers les fonds et disparaît',
  },
  'ship_log_beast_dives': {
    AppLanguage.en: 'The {ship} dives under the Eel…',
    AppLanguage.fr: '{ship} plonge sous l\'Eel…',
  },
  'ship_log_beast_breach': {
    AppLanguage.en:
        '…and breaches beneath her keel! -{n} hull, and the sea comes in',
    AppLanguage.fr:
        '…et jaillit sous sa quille ! -{n} de coque, et la mer entre',
  },
  'ship_log_beast_heals': {
    AppLanguage.en: 'The {ship}\'s wounds close, +{n}',
    AppLanguage.fr: 'Les plaies de {ship} se referment, +{n}',
  },
  'ship_log_beast_turning': {
    AppLanguage.en: 'The {ship} turns for the deep: hold it now or lose it',
    AppLanguage.fr:
        '{ship} vire vers les fonds : retenez la bête maintenant, ou elle est perdue',
  },
  'ship_log_beast_turns_back': {
    AppLanguage.en: 'Its wounds closed, the {ship} turns back to the fight',
    AppLanguage.fr: 'Ses plaies refermées, {ship} revient au combat',
  },
  'beast_ship_log_enemy_repairs': {
    AppLanguage.en: 'Flesh knits over the {ship}\'s {room}',
    AppLanguage.fr: 'La chair se referme sur {room} de {ship}',
  },
  'beast_ship_log_enemy_fire_out': {
    AppLanguage.en:
        'The {ship} rolls in the swell and the fire on its {room} dies',
    AppLanguage.fr: '{ship} roule dans la houle et le feu sur {room} s\'éteint',
  },
  'beast_ship_log_enemy_leak_plugged': {
    AppLanguage.en: 'A wound on the {ship} stops bleeding',
    AppLanguage.fr: 'Une plaie de {ship} cesse de saigner',
  },
  'beast_ship_log_leak': {
    AppLanguage.en: 'The {ship} is bleeding!',
    AppLanguage.fr: '{ship} saigne !',
  },
  'beast_ship_log_flooding': {
    AppLanguage.en: 'The {ship} bleeds, -{n}',
    AppLanguage.fr: '{ship} saigne, -{n}',
  },
  'beast_ship_log_shot_absorbed': {
    AppLanguage.en: '{weapon} glances off the {ship}\'s hide',
    AppLanguage.fr: '{weapon} ricoche sur le cuir de {ship}',
  },
  'beast_ship_log_boarders': {
    AppLanguage.en: 'The {ship}\'s arms come over the rail into the hold!',
    AppLanguage.fr:
        'Les bras de {ship} franchissent le bastingage jusqu\'à la cale !',
  },
  'sea_event_beast': {
    AppLanguage.en: 'a sea beast',
    AppLanguage.fr: 'une bête marine',
  },
  'sea_event_hunt': {
    AppLanguage.en: 'the hunt',
    AppLanguage.fr: 'la chasse',
  },
  'beast_wounds_line': {
    AppLanguage.en: 'It still carries the wounds of the last meeting ({n}).',
    AppLanguage.fr:
        'La bête porte encore les blessures de la dernière rencontre ({n}).',
  },
  'beast_known_line': {
    AppLanguage.en: 'The crew knows its ways: it slips {n}% less.',
    AppLanguage.fr:
        'L\'équipage connaît ses ruses : la bête esquive {n} % de moins.',
  },
  'ship_log_beast_sign_wreck': {
    AppLanguage.en: 'The wreck\'s timbers bear the marks of {ship}.',
    AppLanguage.fr: 'Les bordages de l\'épave portent les marques de {ship}.',
  },
  'ship_log_beast_sign_sighting': {
    AppLanguage.en: 'The crew marks where it went down: a sign of {ship}.',
    AppLanguage.fr:
        'L\'équipage note où la chose a plongé : un signe de {ship}.',
  },
  'ship_log_beast_watched': {
    AppLanguage.en:
        'Every eye aboard follows {ship} as it goes: a sign of where it lairs.',
    AppLanguage.fr:
        'Chaque regard à bord suit {ship} qui s\'éloigne : un signe de son repaire.',
  },
  'ship_log_beast_sign_outran': {
    AppLanguage.en:
        'Looking back, the crew marks where it turned away: a sign of {ship}.',
    AppLanguage.fr:
        'En se retournant, l\'équipage note où la bête a renoncé : un signe de {ship}.',
  },
  'ship_log_beast_clues': {
    AppLanguage.en: 'Signs of {ship}: {n} of {of}',
    AppLanguage.fr: 'Signes de {ship} : {n} sur {of}',
  },
  'ship_log_beast_hunt_ready': {
    AppLanguage.en:
        'Enough signs of {ship} to hunt it: the Harbor can send the Eel out.',
    AppLanguage.fr:
        'Assez de signes de {ship} pour partir en chasse : le Port peut envoyer l\'Eel.',
  },
  'ship_log_beast_passed': {
    AppLanguage.en:
        'Sails struck, nobody breathing: {ship} passes beneath the keel.',
    AppLanguage.fr:
        'Voiles amenées, personne ne respire : {ship} passe sous la quille.',
  },
  'ship_log_beast_noticed': {
    AppLanguage.en: 'A rope creaks, and {ship} turns toward the sound.',
    AppLanguage.fr: 'Un cordage grince, et {ship} se tourne vers le bruit.',
  },
  'ship_log_beast_caught': {
    AppLanguage.en:
        'It is faster than any sail: it rams the Eel\'s quarter, -{n} hull',
    AppLanguage.fr:
        'Aucune voile ne va plus vite : un coup de boutoir dans la hanche de l\'Eel, -{n} de coque',
  },
  'ship_log_beast_slain': {
    AppLanguage.en: '{ship} goes still, and the sea around the Eel turns red.',
    AppLanguage.fr: '{ship} ne bouge plus, et la mer rougit autour de l\'Eel.',
  },
  'ship_log_beast_got_away': {
    AppLanguage.en: '{ship} gets away, carrying its wounds into the deep.',
    AppLanguage.fr:
        '{ship} s\'échappe et emporte ses blessures vers les fonds.',
  },
  'ship_log_trophy_fitted': {
    AppLanguage.en: 'A trophy for the Eel: {weapon}, fitted at once.',
    AppLanguage.fr: 'Un trophée pour l\'Eel : {weapon}, monté sur-le-champ.',
  },
  'ship_log_trophy_waiting': {
    AppLanguage.en:
        'A trophy for the Eel: {weapon}. No room aboard; it waits at the Harbor.',
    AppLanguage.fr:
        'Un trophée pour l\'Eel : {weapon}. Pas de place à bord ; il attend au Port.',
  },
  'beasts_section': {
    AppLanguage.en: 'Sea beasts',
    AppLanguage.fr: 'Bêtes marines',
  },
  'beasts_none_hint': {
    AppLanguage.en:
        'No beast has crossed the Eel\'s path yet. They roam the open water from the Ashen coast outward.',
    AppLanguage.fr:
        'Aucune bête n\'a encore croisé la route de l\'Eel. Elles rôdent en haute mer, de la côte des Cendres vers le large.',
  },
  'beasts_hint': {
    AppLanguage.en:
        'Every fight with a beast seen through to the end and survived, every beast let pass or outrun, and some wrecks give a sign of where it lairs (a fight run from gives none). With {of} signs the Eel can go out and hunt it: it carries its wounds, and the crew knows its ways.',
    AppLanguage.fr:
        'Chaque combat contre une bête mené jusqu\'au bout et dont l\'Eel réchappe, chaque bête laissée passer ou distancée, et certaines épaves donnent un signe de son repaire (un combat qu\'on a fui n\'en donne aucun). Avec {of} signes, l\'Eel peut partir en chasse : la bête garde ses blessures, et l\'équipage connaît ses ruses.',
  },
  'beast_slain_label': {
    AppLanguage.en: 'Slain. Its trophy is at the shipwright\'s.',
    AppLanguage.fr: 'Bête abattue. Son trophée est chez le charpentier.',
  },
  'beast_signs_label': {
    AppLanguage.en: 'Signs: {n} of {of}',
    AppLanguage.fr: 'Signes : {n} sur {of}',
  },
  'beast_wounds_label': {
    AppLanguage.en: 'Wounds it carries: {n}',
    AppLanguage.fr: 'Blessures portées : {n}',
  },
  'beast_hunt_away_hint': {
    AppLanguage.en: 'The Eel must be moored at the camp to set out.',
    AppLanguage.fr: 'L\'Eel doit être amarré au camp pour partir.',
  },
  'beast_hunt_button': {
    AppLanguage.en: 'Hunt',
    AppLanguage.fr: 'Chasser',
  },
  'swap_title': {
    AppLanguage.en: 'Fit {part} in place of',
    AppLanguage.fr: 'Monter {part} à la place de',
  },
  'swap_button': {
    AppLanguage.en: 'Swap',
    AppLanguage.fr: 'Échanger',
  },
  'part_stored_note': {
    AppLanguage.en: 'In store at the Harbor: it goes back on for nothing.',
    AppLanguage.fr: 'En réserve au Port : il se remonte sans frais.',
  },
  'free_label': {
    AppLanguage.en: 'free',
    AppLanguage.fr: 'gratuit',
  },
  'tether_label': {
    AppLanguage.en: 'holds a beast {n} rounds',
    AppLanguage.fr: 'retient une bête {n} tours',
  },
  // --- v1.190: the enemy's intents -----------------------------------------
  'ship_intent_volley': {
    AppLanguage.en: 'Aiming a volley',
    AppLanguage.fr: 'Prépare une bordée',
  },
  'ship_intent_volley_hint': {
    AppLanguage.en:
        'Every gun it has ready and in reach fires this round. Keep a shield up, or brace.',
    AppLanguage.fr:
        'Toutes ses pièces prêtes et à portée tirent ce tour-ci. Gardez un bouclier levé, ou préparez-vous à encaisser.',
  },
  'ship_intent_closeIn': {
    AppLanguage.en: 'Closing in',
    AppLanguage.fr: 'Se rapproche',
  },
  'ship_intent_closeIn_hint': {
    AppLanguage.en:
        'It steers one range closer, then fires. Pull away to keep your distance.',
    AppLanguage.fr:
        'L\'ennemi se rapproche d\'une portée, puis tire. Éloignez-vous pour garder la distance.',
  },
  'ship_intent_pullAway': {
    AppLanguage.en: 'Pulling away',
    AppLanguage.fr: 'S\'éloigne',
  },
  'ship_intent_pullAway_hint': {
    AppLanguage.en:
        'It steers one range farther off, then fires. Close in to stay on it.',
    AppLanguage.fr:
        'L\'ennemi s\'éloigne d\'une portée, puis tire. Rapprochez-vous pour ne pas le lâcher.',
  },
  'ship_intent_ram': {
    AppLanguage.en: 'Coming about to ram',
    AppLanguage.fr: 'Vire pour éperonner',
  },
  'ship_intent_ram_hint': {
    AppLanguage.en:
        'Side by side, it drives its prow into you: hull through any shield, and a leak. Pull away before it comes, or brace.',
    AppLanguage.fr:
        'Bord à bord, l\'ennemi vous enfonce sa proue : de la coque malgré les boucliers, et une voie d\'eau. Éloignez-vous avant, ou préparez-vous à encaisser.',
  },
  'ship_intent_board': {
    AppLanguage.en: 'Crew massing at the rail',
    AppLanguage.fr: 'L\'équipage se masse au bastingage',
  },
  'ship_intent_board_hint': {
    AppLanguage.en:
        'After its volley its crew comes over your rail if the rail is open. Keep a shield up, pull away, or put a hand in the hold.',
    AppLanguage.fr:
        'Après sa bordée, son équipage passe votre bastingage s\'il est ouvert. Gardez un bouclier levé, éloignez-vous, ou postez quelqu\'un dans la cale.',
  },
  'ship_intent_mend': {
    AppLanguage.en: 'All hands to the pumps',
    AppLanguage.fr: 'Tout le monde aux pompes',
  },
  'ship_intent_mend_hint': {
    AppLanguage.en:
        'Its crew mends instead of fighting: its guns hold fire this round and come back charged. Hit it hard now.',
    AppLanguage.fr:
        'Son équipage répare au lieu de se battre : ses pièces se taisent ce tour-ci et reviennent chargées. Frappez fort maintenant.',
  },
  'ship_intent_brace': {
    AppLanguage.en: 'Braced for your volley',
    AppLanguage.fr: 'Paré à encaisser votre bordée',
  },
  'ship_intent_brace_hint': {
    AppLanguage.en:
        'This turn your shots take half the hull they would (its rooms as ever), and it holds its own fire. Repair, push a room or manoeuvre, or aim at its rooms.',
    AppLanguage.fr:
        'Ce tour-ci, vos tirs ne lui prennent que la moitié de la coque (ses salles, elles, comme d\'habitude), et l\'ennemi retient son feu. Réparez, forcez une salle ou manœuvrez, ou visez ses salles.',
  },
  'ship_intent_flee': {
    AppLanguage.en: 'Making sail to run',
    AppLanguage.fr: 'Hisse les voiles pour fuir',
  },
  'ship_intent_flee_hint': {
    AppLanguage.en:
        'It runs for it: one range farther off, and gone if it is already far. Close in to keep it.',
    AppLanguage.fr:
        'L\'ennemi prend la fuite : une portée plus loin, et hors de vue s\'il est déjà loin. Rapprochez-vous pour le retenir.',
  },
  'ship_intent_dive': {
    AppLanguage.en: 'Going under',
    AppLanguage.fr: 'Plonge',
  },
  'ship_intent_dive_hint': {
    AppLanguage.en:
        'It goes under and comes up beneath you: hull through any shield, and a leak. Brace.',
    AppLanguage.fr:
        'La bête plonge et remonte sous vous : de la coque malgré les boucliers, et une voie d\'eau. Préparez-vous à encaisser.',
  },
  'beast_ship_intent_volley': {
    AppLanguage.en: 'About to strike',
    AppLanguage.fr: 'S\'apprête à frapper',
  },
  'beast_ship_intent_volley_hint': {
    AppLanguage.en:
        'Every blow it has ready and in reach lands this round. Keep a shield up, or brace.',
    AppLanguage.fr:
        'Tous ses coups prêts et à portée tombent ce tour-ci. Gardez un bouclier levé, ou préparez-vous à encaisser.',
  },
  'beast_ship_intent_flee': {
    AppLanguage.en: 'Turning for the deep',
    AppLanguage.fr: 'Part vers les fonds',
  },
  'beast_ship_intent_flee_hint': {
    AppLanguage.en:
        'It is gone at its next turn unless a harpoon holds it or its fins are torn.',
    AppLanguage.fr:
        'La bête disparaît à son prochain tour, sauf si un harpon la retient ou si ses nageoires sont déchirées.',
  },
  'beast_ship_intent_ram': {
    AppLanguage.en: 'Coming to ram',
    AppLanguage.fr: 'Fonce pour éperonner',
  },
  'beast_ship_intent_ram_hint': {
    AppLanguage.en:
        'Side by side, it drives into you: hull through any shield, and a leak. Pull away before it comes, or brace.',
    AppLanguage.fr:
        'Bord à bord, la bête vous percute : de la coque malgré les boucliers, et une voie d\'eau. Éloignez-vous avant, ou préparez-vous à encaisser.',
  },
  'ship_intent_hidden': {
    AppLanguage.en: 'Hidden by the fog',
    AppLanguage.fr: 'Caché par le brouillard',
  },
  'ship_intent_hidden_hint': {
    AppLanguage.en: 'The fog hides what the enemy means to do next.',
    AppLanguage.fr: 'Le brouillard cache ce que l\'ennemi prépare.',
  },
  'tip_ship_intent': {
    AppLanguage.en:
        'Read the enemy: its next move shows under its name. The fog hides it.',
    AppLanguage.fr:
        'Lisez l\'ennemi : son prochain coup s\'affiche sous son nom. Le brouillard le cache.',
  },
  'ship_log_intent_helm_slow': {
    AppLanguage.en: 'The {ship}\'s helm is slow to answer',
    AppLanguage.fr: 'La barre de {ship} répond mal',
  },
  'ship_log_intent_ram_missed': {
    AppLanguage.en: 'The {ship}\'s prow cuts empty water',
    AppLanguage.fr: 'La proue de {ship} ne fend que l\'eau',
  },
  'ship_log_intent_board_foiled': {
    AppLanguage.en:
        'The {ship}\'s boarders are left at the rail: too far to jump',
    AppLanguage.fr:
        'Les abordeurs de {ship} restent au bastingage : trop loin pour sauter',
  },
  'ship_log_intent_board_held': {
    AppLanguage.en: 'The {ship}\'s boarders hang back: your rail holds',
    AppLanguage.fr: 'Les abordeurs de {ship} hésitent : votre bastingage tient',
  },
  'ship_log_intent_mend': {
    AppLanguage.en:
        'Every hand aboard the {ship} runs to the pumps and the fires',
    AppLanguage.fr: 'Tout l\'équipage de {ship} court aux pompes et aux feux',
  },
  'ship_log_intent_brace': {
    AppLanguage.en: 'The {ship} braces for your volley: half the hull',
    AppLanguage.fr:
        '{ship} encaisse votre bordée : la moitié seulement de la coque',
  },
  // --- v1.190: push a room past its limit ----------------------------------
  'ship_push_button': {
    AppLanguage.en: 'Push a room',
    AppLanguage.fr: 'Forcer une salle',
  },
  'ship_push_title': {
    AppLanguage.en: 'Push a room past its limit',
    AppLanguage.fr: 'Forcer une salle au-delà de ses limites',
  },
  'ship_push_once_label': {
    AppLanguage.en:
        'Once a turn. Every push makes the next one likelier to strain.',
    AppLanguage.fr:
        'Une fois par tour. Chaque salle forcée rend la suivante plus risquée.',
  },
  'ship_push_guns_hint': {
    AppLanguage.en: 'Push the guns: every gun a step closer to firing.',
    AppLanguage.fr: 'Forcer les canons : chaque pièce gagne un cran.',
  },
  'ship_push_helm_hint': {
    AppLanguage.en: 'Push the helm: harder to hit this round.',
    AppLanguage.fr: 'Forcer la barre : plus dur à toucher ce tour-ci.',
  },
  'ship_push_bulwark_hint': {
    AppLanguage.en: 'Push the bulwark: one more shield layer now.',
    AppLanguage.fr:
        'Forcer le pavois : une couche de bouclier de plus tout de suite.',
  },
  'ship_push_hold_hint': {
    AppLanguage.en: 'Push the hold: bail a leak and patch {n} hull.',
    AppLanguage.fr:
        'Forcer la cale : écoper une voie d\'eau et colmater {n} de coque.',
  },
  'ship_push_strain_label': {
    AppLanguage.en: 'Strain {n}%',
    AppLanguage.fr: 'Tension {n} %',
  },
  'ship_push_strain_hint': {
    AppLanguage.en: 'Strain {n}%: the room may lose a pip, or catch fire.',
    AppLanguage.fr:
        'Tension {n} % : la salle peut perdre un cran, ou prendre feu.',
  },
  'ship_push_flash': {
    AppLanguage.en: 'Pushed',
    AppLanguage.fr: 'À fond',
  },
  'ship_push_strain_flash': {
    AppLanguage.en: 'Strain!',
    AppLanguage.fr: 'Tension !',
  },
  'tip_ship_push': {
    AppLanguage.en:
        'Once a turn, the bolt pushes one of the Eel\'s rooms past its limit: the guns charge, the helm slips, the bulwark shields, the hold patches. Each push risks the room, more every time.',
    AppLanguage.fr:
        'Une fois par tour, l\'éclair force une salle de l\'Eel au-delà de ses limites : les canons chargent, la barre esquive, le pavois protège, la cale colmate. Chaque fois, la salle risque davantage de céder.',
  },
  'ship_log_push_guns': {
    AppLanguage.en: 'Guns pushed past their limit: every gun a step closer',
    AppLanguage.fr: 'Canons forcés : chaque pièce gagne un cran',
  },
  'ship_log_push_helm': {
    AppLanguage.en: 'Helm pushed past its limit: +{n}% evasion this round',
    AppLanguage.fr: 'Barre forcée : +{n} % d\'esquive ce tour-ci',
  },
  'ship_log_push_bulwark': {
    AppLanguage.en: 'Bulwark pushed past its limit: one more shield layer',
    AppLanguage.fr: 'Pavois forcé : une couche de bouclier de plus',
  },
  'ship_log_push_hold': {
    AppLanguage.en:
        'Hold pushed past its limit: the pumps and the patches, +{n}',
    AppLanguage.fr: 'Cale forcée : les pompes et les rustines, +{n}',
  },
  'ship_log_push_strain': {
    AppLanguage.en: 'The strain tells: a pip lost in the {room}',
    AppLanguage.fr: 'La tension se paie : un cran perdu pour {room}',
  },
  'ship_log_push_strain_fire': {
    AppLanguage.en:
        'The strain tells: a pip lost in the {room}, and it catches fire!',
    AppLanguage.fr:
        'La tension se paie : un cran perdu pour {room}, et le feu y prend !',
  },
  // --- v1.190: the battle gets worse over time ------------------------------
  'ship_log_fire_spreads': {
    AppLanguage.en: 'The fire spreads to the {ship}\'s {room}!',
    AppLanguage.fr: 'Le feu gagne {room} de {ship} !',
  },
  'ship_heavy_label': {
    AppLanguage.en: '−{n}%',
    AppLanguage.fr: '−{n} %',
  },
  'ship_heavy_hint': {
    AppLanguage.en:
        'Heavy with water: −{n}%. Each open leak costs this ship evasion until it is bailed.',
    AppLanguage.fr:
        'De l\'eau à bord : −{n} %. Chaque voie d\'eau ouverte coûte de l\'esquive à ce navire jusqu\'à ce qu\'on l\'écope.',
  },
  'ship_weather_squall_coming': {
    AppLanguage.en: 'Squall coming',
    AppLanguage.fr: 'Grain en approche',
  },
  'ship_weather_squall_coming_hint': {
    AppLanguage.en:
        'A squall builds out of the crosswind: next round the rain puts every fire out and starts none.',
    AppLanguage.fr:
        'Un grain se forme dans le vent de travers : au prochain tour, la pluie éteint tous les feux et n\'en allume aucun.',
  },
  'ship_sail_coming_label': {
    AppLanguage.en: 'Sail on the horizon: {n}',
    AppLanguage.fr: 'Voile à l\'horizon : {n}',
  },
  'ship_sail_coming_hint': {
    AppLanguage.en:
        'A friend of theirs: in {n} rounds its guns join the fight, at medium and long range. Finish this before it comes, or fight side by side.',
    AppLanguage.fr:
        'Un renfort de l\'ennemi : dans {n} tours, ses canons entrent dans la bataille, à moyenne et longue portée. Finissez-en avant, ou battez-vous bord à bord.',
  },
  'ship_consort_label': {
    AppLanguage.en: 'Consort',
    AppLanguage.fr: 'Renfort',
  },
  'ship_consort_hint': {
    AppLanguage.en:
        'Its friend has come up: its guns fire at medium and long range. Side by side, only the ship itself can reach you.',
    AppLanguage.fr:
        'Son renfort est arrivé : ses canons tirent à moyenne et longue portée. Bord à bord, seul le navire lui-même vous atteint.',
  },
  'ship_log_sail_sighted': {
    AppLanguage.en: 'A sail on the horizon, flying the {ship}\'s colours',
    AppLanguage.fr: 'Une voile à l\'horizon, aux couleurs de {ship}',
  },
  'ship_log_sail_arrives': {
    AppLanguage.en: 'The {ship}\'s consort comes up and runs out her guns',
    AppLanguage.fr: 'Le renfort de {ship} arrive et met ses canons en batterie',
  },
  // v1.192: Signs, the patrons' boons (see signs.dart). French: « un
  // Signe » (masculine), the player is « vous », a non-breaking space
  // before : ; ! ? % and inside « ».
  'signs_section': {AppLanguage.en: 'Signs', AppLanguage.fr: 'Signes'},
  'signs_none': {
    AppLanguage.en:
        'No signs yet. The clans, the tribes, the Choir and the Pit bring them in their offers.',
    AppLanguage.fr:
        'Aucun Signe pour l’instant. Les clans, les tribus, le Chœur et la Fosse en apportent dans leurs offres.',
  },
  'sign_pending': {
    AppLanguage.en: '{n} sign(s) to choose',
    AppLanguage.fr: '{n}\u00a0Signe(s) à choisir',
  },
  'sign_open_offer_button': {
    AppLanguage.en: 'Choose a sign',
    AppLanguage.fr: 'Choisir un Signe',
  },
  'sign_none_to_offer': {
    AppLanguage.en: 'No patron has a sign to offer you yet.',
    AppLanguage.fr: 'Aucun protecteur n’a encore de Signe à vous offrir.',
  },
  'sign_choose_hint': {
    AppLanguage.en: 'Choose one sign.',
    AppLanguage.fr: 'Choisissez un Signe.',
  },
  'sign_take_button': {
    AppLanguage.en: 'Take this sign',
    AppLanguage.fr: 'Prendre ce Signe',
  },
  'sign_later_button': {AppLanguage.en: 'Later', AppLanguage.fr: 'Plus tard'},
  'sign_replaces': {
    AppLanguage.en: 'Replaces: {name}',
    AppLanguage.fr: 'Remplace\u00a0: {name}',
  },
  'sign_duo_badge': {AppLanguage.en: 'Duo', AppLanguage.fr: 'Duo'},
  'sign_level': {AppLanguage.en: 'Lv {n}', AppLanguage.fr: 'Niv.\u00a0{n}'},
  'sign_vow_silent': {
    AppLanguage.en: 'Silent: your alignment is below 0.',
    AppLanguage.fr: 'Silencieux\u00a0: votre alignement est sous 0.',
  },
  'sign_passives_label': {
    AppLanguage.en: 'Passives',
    AppLanguage.fr: 'Passifs',
  },
  'titan_blood_label': {
    AppLanguage.en: 'Titan’s Blood: {n}',
    AppLanguage.fr: 'Sang de Titan\u00a0: {n}',
  },
  'titan_blood_hint': {
    AppLanguage.en: 'Tap a sign to raise it one level.',
    AppLanguage.fr: 'Touchez un Signe pour l’élever d’un niveau.',
  },
  'titan_blood_no_sign': {
    AppLanguage.en: 'It waits for a sign to raise.',
    AppLanguage.fr: 'Il attend un Signe à élever.',
  },
  'titan_blood_confirm_title': {
    AppLanguage.en: 'Raise {name}?',
    AppLanguage.fr: 'Élever {name}\u00a0?',
  },
  'titan_blood_confirm_body': {
    AppLanguage.en: 'A drop of Titan’s Blood raises it to level {n}.',
    AppLanguage.fr: 'Une goutte de Sang de Titan l’élève au niveau {n}.',
  },
  'titan_blood_raise_button': {
    AppLanguage.en: 'Raise',
    AppLanguage.fr: 'Élever',
  },
  'titan_blood_max': {
    AppLanguage.en: '{name} is at its highest level.',
    AppLanguage.fr: '{name} est à son plus haut niveau.',
  },
  'sign_rarity_common': {AppLanguage.en: 'Common', AppLanguage.fr: 'Commun'},
  'sign_rarity_rare': {AppLanguage.en: 'Rare', AppLanguage.fr: 'Rare'},
  'sign_rarity_epic': {AppLanguage.en: 'Epic', AppLanguage.fr: 'Épique'},
  'sign_rarity_heroic': {AppLanguage.en: 'Heroic', AppLanguage.fr: 'Héroïque'},
  'sign_slot_strike': {AppLanguage.en: 'Strike', AppLanguage.fr: 'Frappe'},
  'sign_slot_guard': {AppLanguage.en: 'Guard', AppLanguage.fr: 'Garde'},
  'sign_slot_mend': {AppLanguage.en: 'Mend', AppLanguage.fr: 'Soin'},
  'sign_slot_spell': {AppLanguage.en: 'Spell', AppLanguage.fr: 'Sort'},
  'sign_slot_passive': {AppLanguage.en: 'Passive', AppLanguage.fr: 'Passif'},
  'sign_status_poison': {
    AppLanguage.en: 'poison ({m} a turn for {d} turns)',
    AppLanguage.fr: 'du poison ({m} par tour pendant {d}\u00a0tours)',
  },
  'sign_status_weaken': {
    AppLanguage.en: 'weakness ({m}% for {d} turns)',
    AppLanguage.fr: 'un affaiblissement ({m}\u00a0% pendant {d}\u00a0tours)',
  },
  'sign_status_stun': {
    AppLanguage.en: 'a stun ({d} turn)',
    AppLanguage.fr: 'un étourdissement ({d}\u00a0tour)',
  },
  // One line per effect kind, written with the sign's numbers.
  'sign_fx_strikeDamagePercent': {
    AppLanguage.en: 'Attack faces deal +{v}% damage.',
    AppLanguage.fr: 'Les faces Attaque infligent +{v}\u00a0% de dégâts.',
  },
  'sign_fx_strikeFlat': {
    AppLanguage.en: 'Attack faces deal +{v} damage.',
    AppLanguage.fr: 'Les faces Attaque infligent +{v}\u00a0dégâts.',
  },
  'sign_fx_strikeElement': {
    AppLanguage.en: 'Attack faces strike with {e}, +{v} damage.',
    AppLanguage.fr:
        'Les faces Attaque prennent l’élément {e}, +{v}\u00a0dégâts.',
  },
  'sign_fx_strikeStatus': {
    AppLanguage.en: 'Attack faces: {c}% chance to inflict {s}.',
    AppLanguage.fr:
        'Faces Attaque\u00a0: {c}\u00a0% de chances d’infliger {s}.',
  },
  'sign_fx_strikeKeyword': {
    AppLanguage.en: 'Attack faces gain {k}.',
    AppLanguage.fr: 'Les faces Attaque gagnent {k}.',
  },
  'sign_fx_guardBlockPercent': {
    AppLanguage.en: 'Guard faces block +{v}%.',
    AppLanguage.fr: 'Les faces Garde bloquent +{v}\u00a0%.',
  },
  'sign_fx_guardFlat': {
    AppLanguage.en: 'Guard faces block +{v}.',
    AppLanguage.fr: 'Les faces Garde bloquent +{v}.',
  },
  'sign_fx_guardHeal': {
    AppLanguage.en: 'Guard faces also heal you {v}.',
    AppLanguage.fr: 'Les faces Garde vous soignent aussi de {v}.',
  },
  'sign_fx_guardRetaliate': {
    AppLanguage.en:
        'While your guard holds, the enemy that hits you takes {v} damage.',
    AppLanguage.fr:
        'Tant que votre garde tient, l’ennemi qui vous frappe subit {v}\u00a0dégâts.',
  },
  'sign_fx_guardStatus': {
    AppLanguage.en:
        'Behind your guard: {c}% chance to inflict {s} on the enemy that hits you.',
    AppLanguage.fr:
        'Derrière votre garde\u00a0: {c}\u00a0% de chances d’infliger {s} à l’ennemi qui vous frappe.',
  },
  'sign_fx_mendPercent': {
    AppLanguage.en: 'Heal faces heal +{v}%.',
    AppLanguage.fr: 'Les faces Soin soignent +{v}\u00a0%.',
  },
  'sign_fx_mendParty': {
    AppLanguage.en: 'Your Heal faces also heal each companion {v}% of it.',
    AppLanguage.fr:
        'Vos faces Soin soignent aussi chaque compagnon de {v}\u00a0% du soin.',
  },
  'sign_fx_mendShield': {
    AppLanguage.en: 'Healing past full health becomes block, up to {v}.',
    AppLanguage.fr:
        'Le soin au-delà de la santé pleine devient du blocage, jusqu’à {v}.',
  },
  'sign_fx_mendCleanse': {
    AppLanguage.en: 'Heal faces lift {v} of your afflictions.',
    AppLanguage.fr: 'Les faces Soin vous libèrent de {v}\u00a0affliction(s).',
  },
  'sign_fx_manaFlat': {
    AppLanguage.en: 'Mana faces give +{v} mana.',
    AppLanguage.fr: 'Les faces Mana donnent +{v}\u00a0mana.',
  },
  'sign_fx_spellDamagePercent': {
    AppLanguage.en: 'Spells deal and heal +{v}%.',
    AppLanguage.fr: 'Les sorts infligent et soignent +{v}\u00a0%.',
  },
  'sign_fx_spellCostLess': {
    AppLanguage.en: 'Spells cost {v} less mana (never under 1).',
    AppLanguage.fr:
        'Les sorts coûtent {v}\u00a0mana de moins (jamais moins de 1).',
  },
  'sign_fx_spellStatus': {
    AppLanguage.en: 'Spells: {c}% chance to inflict {s}.',
    AppLanguage.fr: 'Sorts\u00a0: {c}\u00a0% de chances d’infliger {s}.',
  },
  'sign_fx_maxHealth': {
    AppLanguage.en: '+{v} max health in fights.',
    AppLanguage.fr: '+{v} de santé maximale en combat.',
  },
  'sign_fx_armor': {
    AppLanguage.en: '+{v} armor.',
    AppLanguage.fr: '+{v} d’armure.',
  },
  'sign_fx_critChance': {
    AppLanguage.en: '+{v}% chance of a critical hit.',
    AppLanguage.fr: '+{v}\u00a0% de chances de coup critique.',
  },
  'sign_fx_dodgeChance': {
    AppLanguage.en: '+{v}% chance to dodge.',
    AppLanguage.fr: '+{v}\u00a0% de chances d’esquive.',
  },
  'sign_fx_lifestealPercent': {
    AppLanguage.en: 'Your hits heal you {v}% of their damage.',
    AppLanguage.fr: 'Vos coups vous soignent de {v}\u00a0% de leurs dégâts.',
  },
  'sign_fx_thorns': {
    AppLanguage.en: 'An enemy whose hit lands takes {v} damage back.',
    AppLanguage.fr:
        'Un ennemi dont le coup porte subit {v}\u00a0dégâts en retour.',
  },
  'sign_fx_manaOnHit': {
    AppLanguage.en: 'Each hit you land gives {v} mana.',
    AppLanguage.fr: 'Chaque coup que vous portez donne {v}\u00a0mana.',
  },
  'sign_fx_maxMana': {
    AppLanguage.en: '+{v} max mana in fights.',
    AppLanguage.fr: '+{v} de mana maximal en combat.',
  },
  'sign_fx_secondWind': {
    AppLanguage.en: 'Once a fight, a killing blow leaves you at 1 health.',
    AppLanguage.fr:
        'Une fois par combat, un coup fatal vous laisse à 1\u00a0point de vie.',
  },
  'sign_fx_potionBonus': {
    AppLanguage.en: 'Potions heal {v} more.',
    AppLanguage.fr: 'Les potions soignent {v} de plus.',
  },
  'sign_fx_goldPercent': {
    AppLanguage.en: '+{v}% gold from fights.',
    AppLanguage.fr: '+{v}\u00a0% d’or gagné en combat.',
  },
  'sign_fx_xpPercent': {
    AppLanguage.en: '+{v}% XP from fights.',
    AppLanguage.fr: '+{v}\u00a0% d’XP gagnée en combat.',
  },
  'sign_fx_allyDamagePercent': {
    AppLanguage.en: 'Companions deal +{v}% damage.',
    AppLanguage.fr: 'Les compagnons infligent +{v}\u00a0% de dégâts.',
  },
  'sign_fx_stat': {
    AppLanguage.en: '+{v} {stat} in fights.',
    AppLanguage.fr: '+{v} en {stat} en combat.',
  },
  'sign_fx_partyStartBlock': {
    AppLanguage.en: 'The whole party starts each fight with {v} block.',
    AppLanguage.fr:
        'Tout le groupe commence chaque combat avec {v} de blocage.',
  },
  'sign_fx_startMomentum': {
    AppLanguage.en: 'Start each fight with {v} momentum.',
    AppLanguage.fr: 'Commencez chaque combat avec {v} d’élan.',
  },
  'sign_fx_lowHealthDamagePercent': {
    AppLanguage.en: '+{v}% damage while under 35% health.',
    AppLanguage.fr: '+{v}\u00a0% de dégâts sous 35\u00a0% de santé.',
  },
  'sign_fx_killHeal': {
    AppLanguage.en: 'Recover {v} health when an enemy falls.',
    AppLanguage.fr: 'Récupérez {v}\u00a0PV quand un ennemi tombe.',
  },
  'sign_fx_afterFightHealPercent': {
    AppLanguage.en: 'After a won fight, the party heals {v}% of max health.',
    AppLanguage.fr:
        'Après un combat gagné, le groupe récupère {v}\u00a0% de sa santé maximale.',
  },
  'sign_fx_firstRoundDamagePercent': {
    AppLanguage.en: '+{v}% damage in the first round.',
    AppLanguage.fr: '+{v}\u00a0% de dégâts au premier tour.',
  },
  'sign_fx_partyMaxHealthPercent': {
    AppLanguage.en: 'The whole party has +{v}% max health in fights.',
    AppLanguage.fr: 'Tout le groupe a +{v}\u00a0% de santé maximale en combat.',
  },
  'sign_fx_shipHullPercent': {
    AppLanguage.en: 'The Rusty Eel has +{v}% hull in sea battles.',
    AppLanguage.fr: 'Le Rusty Eel a +{v}\u00a0% de coque en bataille navale.',
  },
  'sign_fx_shipGunPercent': {
    AppLanguage.en: 'The Eel’s guns deal +{v}% damage.',
    AppLanguage.fr: 'Les canons de l’Eel infligent +{v}\u00a0% de dégâts.',
  },
  'sign_fx_voyageCalm': {
    AppLanguage.en: 'Each bad day at sea: {v}% chance it passes you by.',
    AppLanguage.fr:
        'Chaque mauvais jour en mer\u00a0: {v}\u00a0% de chances qu’il vous épargne.',
  },
  'sign_fx_writFace': {
    AppLanguage.en: 'Writ face: cancels {v} enemy attack on you each fight.',
    AppLanguage.fr:
        'Face Mandat : annule {v} attaque ennemie contre vous par combat.',
  },
  'sign_fx_intentLookahead': {
    AppLanguage.en:
        'Open Eyes: you see each enemy’s intent {v} round further, and the tear’s things cannot ambush the party.',
    AppLanguage.fr:
        'Yeux ouverts : vous voyez l’intention de chaque ennemi {v} tour plus tôt, et les choses de la déchirure ne peuvent pas surprendre le groupe.',
  },
  'sign_fx_compactEdge': {
    AppLanguage.en: 'Compact edge: breaks {v} enemy guard outright each fight.',
    AppLanguage.fr: 'Fil du Pacte : brise net {v} garde ennemie par combat.',
  },
  'sign_fx_crowsPrice': {
    AppLanguage.en:
        'Crow’s Price: each hit you land steals {v} gold (10 hits a fight at most).',
    AppLanguage.fr:
        'Prix de la Corneille : chaque coup que vous portez vole {v} pièces d’or (10 coups par combat au plus).',
  },
  'sign_fx_emberFace': {
    AppLanguage.en: 'Ember face: lifts {v} Curse from your die each fight.',
    AppLanguage.fr:
        'Face Braise : lève {v} malédiction de votre dé par combat.',
  },
  'sign_fx_poisonExtraTurns': {
    AppLanguage.en: 'Poison you inflict lasts {v} more turn.',
    AppLanguage.fr: 'Le poison que vous infligez dure {v} tour de plus.',
  },
  'sign_curse_enemyDamagePercent': {
    AppLanguage.en:
        'Pact: enemies deal +{v}% damage for the next {n} fights, then the gift.',
    AppLanguage.fr:
        'Pacte\u00a0: les ennemis infligent +{v}\u00a0% de dégâts pendant les {n}\u00a0prochains combats, puis vient le don.',
  },
  'sign_curse_startHealthPercentLoss': {
    AppLanguage.en:
        'Pact: start each of the next {n} fights {v}% down, then the gift.',
    AppLanguage.fr:
        'Pacte\u00a0: commencez les {n}\u00a0prochains combats avec {v}\u00a0% de santé en moins, puis vient le don.',
  },
  'sign_curse_goldPercentLoss': {
    AppLanguage.en: 'Pact: the next {n} fights pay {v}% less, then the gift.',
    AppLanguage.fr:
        'Pacte\u00a0: les {n}\u00a0prochains combats rapportent {v}\u00a0% d’or en moins, puis vient le don.',
  },
  // The fight log, when a sign acts.
  'sign_log_status': {
    AppLanguage.en: '{sign}: {line}',
    AppLanguage.fr: '{sign}\u00a0: {line}',
  },
  'sign_log_retaliate': {
    AppLanguage.en: '{sign}: {name} takes {n} damage from your guard.',
    AppLanguage.fr:
        '{sign}\u00a0: {name} subit {n}\u00a0dégâts de votre garde.',
  },
  'sign_log_kill_heal': {
    AppLanguage.en: 'Your signs feed on the fall: you recover {n} HP.',
    AppLanguage.fr:
        'Vos Signes se nourrissent de la chute\u00a0: vous récupérez {n}\u00a0PV.',
  },
  'sign_log_guard_heal': {
    AppLanguage.en: 'The sign on your guard heals you {n} HP.',
    AppLanguage.fr: 'Le Signe de votre garde vous soigne de {n}\u00a0PV.',
  },
  'sign_log_mend_party': {
    AppLanguage.en: 'Your mending reaches the party: +{n} HP each.',
    AppLanguage.fr: 'Votre soin gagne le groupe\u00a0: +{n}\u00a0PV chacun.',
  },
  'sign_log_mend_shield': {
    AppLanguage.en: 'The healing spills over into {n} block.',
    AppLanguage.fr: 'Le soin déborde en {n} de blocage.',
  },
  'sign_log_cleanse': {
    AppLanguage.en: 'Your sign lifts an affliction from you.',
    AppLanguage.fr: 'Votre Signe vous libère d’une affliction.',
  },
  'sign_log_vow_silent': {
    AppLanguage.en: 'A vow is silent: your alignment is below 0.',
    AppLanguage.fr: 'Un vœu se tait\u00a0: votre alignement est sous 0.',
  },
  'sign_log_pact': {
    AppLanguage.en: 'A pact still binds you: {n} fight(s) before its gift.',
    AppLanguage.fr:
        'Un pacte vous lie encore\u00a0: {n}\u00a0combat(s) avant son don.',
  },
  'sign_log_start_block': {
    AppLanguage.en: 'Your signs: the party starts behind {n} block.',
    AppLanguage.fr:
        'Vos Signes\u00a0: le groupe commence derrière {n} de blocage.',
  },
  'sign_log_start_curse': {
    AppLanguage.en: 'A pact takes {n} HP before the fight begins.',
    AppLanguage.fr: 'Un pacte vous prend {n}\u00a0PV avant le combat.',
  },
  'sign_log_after_fight': {
    AppLanguage.en: 'Your signs: the party recovers {n}% of its health.',
    AppLanguage.fr:
        'Vos Signes\u00a0: le groupe récupère {n}\u00a0% de sa santé.',
  },
  'sign_log_offer': {
    AppLanguage.en: 'A boss beaten: the clans come to you with an offer.',
    AppLanguage.fr:
        'Un boss vaincu\u00a0: les clans viennent à vous avec une offre.',
  },
  'sign_log_titan_blood': {
    AppLanguage.en: 'A drop of Titan’s Blood!',
    AppLanguage.fr: 'Une goutte de Sang de Titan\u00a0!',
  },
  'ship_log_calm_sign': {
    AppLanguage.en: 'A sign keeps {n} bad day(s) at sea off the Eel',
    AppLanguage.fr: 'Un Signe épargne à l’Eel {n}\u00a0mauvais jour(s) en mer',
  },
  'signs_lost_label': {
    AppLanguage.en: 'Signs Lost',
    AppLanguage.fr: 'Signes perdus',
  },
  'patrons_section': {
    AppLanguage.en: 'Clans',
    AppLanguage.fr: 'Clans',
  },
  'patrons_none_met': {
    AppLanguage.en: 'No one has offered you a sign yet.',
    AppLanguage.fr: 'Personne ne vous a encore offert de Signe.',
  },
  'patron_favour': {
    AppLanguage.en: 'Favour {n} · level {l}',
    AppLanguage.fr: 'Faveur {n} · niveau {l}',
  },
  'patron_kind_clan': {AppLanguage.en: 'Clan', AppLanguage.fr: 'Clan'},
  'patron_kind_tribe': {AppLanguage.en: 'Tribe', AppLanguage.fr: 'Tribu'},
  'patron_kind_otherworld': {
    AppLanguage.en: 'Otherworld',
    AppLanguage.fr: 'Outre-monde',
  },
  'patron_closed_life': {
    AppLanguage.en: 'Closed to you this life',
    AppLanguage.fr: 'Fermé pour vous dans cette vie',
  },
  'tut_signs_title': {
    AppLanguage.en: 'Offers from the clans',
    AppLanguage.fr: 'Les offres des clans',
  },
  'tut_signs_1': {
    AppLanguage.en:
        'At each level, boss and chapter, three suitors from different factions come to you, each with one gift: a skill, a sign, an object or a title. Take one.',
    AppLanguage.fr:
        'À chaque niveau, boss et chapitre, trois prétendants de factions différentes viennent à vous, chacun avec un don\u00a0: une compétence, un Signe, un objet ou un titre. Prenez-en un.',
  },
  'tut_signs_2': {
    AppLanguage.en:
        'Each card says what its gift does and the standing it moves: the faction you take rises, its allies a little, and its rivals hold it against you.',
    AppLanguage.fr:
        'Chaque carte dit ce que fait son don et la réputation qu’il déplace\u00a0: la faction choisie monte, ses alliés un peu, et ses rivaux vous en tiennent rigueur.',
  },
  'tut_signs_3': {
    AppLanguage.en:
        'Signs hold one each in strike, guard, mend and spell; rarer ones are stronger, and Titan’s Blood raises one a level. Death takes them all; the patrons remember your favour.',
    AppLanguage.fr:
        'Les Signes de frappe, de garde, de soin et de sort en tiennent un chacun\u00a0; les plus rares sont plus forts, et le Sang de Titan en élève un d’un niveau. La mort les emporte tous\u00a0; les protecteurs se souviennent de votre faveur.',
  },
  'debug_offer_sign': {
    AppLanguage.en: 'Offer a sign now',
    AppLanguage.fr: 'Offrir un Signe maintenant',
  },
  'debug_titan_blood': {
    AppLanguage.en: '+1 Titan’s Blood',
    AppLanguage.fr: '+1 Sang de Titan',
  }, // Clans (v1.193): standing, marks, relations and the Edit Mode screen.
  'standing_tier_hunted': {
    AppLanguage.en: 'Hunted',
    AppLanguage.fr: 'Traque',
  },
  'standing_tier_hostile': {
    AppLanguage.en: 'Hostile',
    AppLanguage.fr: 'Hostilité',
  },
  'standing_tier_wary': {AppLanguage.en: 'Wary', AppLanguage.fr: 'Méfiance'},
  'standing_tier_unknown': {
    AppLanguage.en: 'Unknown',
    AppLanguage.fr: 'Anonymat',
  },
  'standing_tier_known': {AppLanguage.en: 'Known', AppLanguage.fr: 'Estime'},
  'standing_tier_trusted': {
    AppLanguage.en: 'Trusted',
    AppLanguage.fr: 'Confiance',
  },
  'standing_tier_sworn': {AppLanguage.en: 'Sworn', AppLanguage.fr: 'Serment'},
  'subclan_mark_none': {
    AppLanguage.en: 'No mark',
    AppLanguage.fr: 'Aucune marque',
  },
  'subclan_mark_friend': {
    AppLanguage.en: 'Friend',
    AppLanguage.fr: 'Amitié',
  },
  'subclan_mark_foe': {AppLanguage.en: 'Foe', AppLanguage.fr: 'Inimitié'},
  'standing_cause_offer': {
    AppLanguage.en: 'Offer accepted',
    AppLanguage.fr: 'Offre acceptée',
  },
  'standing_cause_quest': {AppLanguage.en: 'Quest', AppLanguage.fr: 'Quête'},
  'standing_cause_chapter': {
    AppLanguage.en: 'Chapter’s end',
    AppLanguage.fr: 'Fin de chapitre',
  },
  'standing_cause_favour': {
    AppLanguage.en: 'Favour',
    AppLanguage.fr: 'Service rendu',
  },
  'standing_cause_intrigue': {
    AppLanguage.en: 'Intrigue',
    AppLanguage.fr: 'Intrigue',
  },
  'standing_cause_sea': {AppLanguage.en: 'Sea', AppLanguage.fr: 'Mer'},
  'standing_cause_story': {
    AppLanguage.en: 'Story',
    AppLanguage.fr: 'Histoire',
  },
  'standing_cause_boss': {
    AppLanguage.en: 'Boss beaten',
    AppLanguage.fr: 'Boss vaincu',
  },
  'standing_cause_level': {
    AppLanguage.en: 'Level up',
    AppLanguage.fr: 'Niveau gagné',
  },
  'standing_cause_edit': {
    AppLanguage.en: 'Edit Mode',
    AppLanguage.fr: 'Mode édition',
  },
  'standing_cause_sworn_cap': {
    AppLanguage.en: 'The banner’s limit',
    AppLanguage.fr: 'Limite du serment',
  },
  'intrigue_stage_clue': {AppLanguage.en: 'Clue', AppLanguage.fr: 'Indice'},
  'intrigue_stage_hook': {AppLanguage.en: 'Hook', AppLanguage.fr: 'Accroche'},
  'intrigue_stage_turn': {AppLanguage.en: 'Turn', AppLanguage.fr: 'Tournant'},
  'intrigue_stage_reveal': {
    AppLanguage.en: 'Reveal',
    AppLanguage.fr: 'Révélation',
  },
  'intrigue_stage_crisis': {
    AppLanguage.en: 'Crisis',
    AppLanguage.fr: 'Crise',
  },
  'intrigue_stage_choice': {
    AppLanguage.en: 'Choice',
    AppLanguage.fr: 'Choix',
  },
  'clans_title': {
    AppLanguage.en: 'Clans & Politics',
    AppLanguage.fr: 'Clans et politique',
  },
  'clans_tab_standing': {
    AppLanguage.en: 'Standing',
    AppLanguage.fr: 'Réputation',
  },
  'clans_tab_politics': {
    AppLanguage.en: 'Politics',
    AppLanguage.fr: 'Politique',
  },
  'clans_tab_evolution': {
    AppLanguage.en: 'Evolution',
    AppLanguage.fr: 'Évolution',
  },
  'clans_tab_intrigues': {
    AppLanguage.en: 'Intrigues',
    AppLanguage.fr: 'Intrigues',
  },
  'clans_section': {AppLanguage.en: 'Clans', AppLanguage.fr: 'Clans'},
  'clans_section_hint': {
    AppLanguage.en: 'Where you stand with the coast.',
    AppLanguage.fr: 'Où vous en êtes avec la côte.',
  },
  'clans_tribes_label': {AppLanguage.en: 'Tribes', AppLanguage.fr: 'Tribus'},
  'clans_sworn_marker': {
    AppLanguage.en: 'Sworn: their banner hangs in your Loft',
    AppLanguage.fr: 'Serment\u00a0: leur bannière pend dans votre grenier',
  },
  'clans_edit_hint': {
    AppLanguage.en:
        'Slide to set a standing (no ripple); tap a sub-clan’s square to change its mark.',
    AppLanguage.fr:
        'Faites glisser pour fixer une réputation (sans contrecoup)\u00a0; touchez le carré d’un sous-clan pour changer sa marque.',
  },
  'clans_reset_done': {
    AppLanguage.en: 'The coast stands as the story opens.',
    AppLanguage.fr: 'La côte est telle qu’au début de l’histoire.',
  },
  'clans_alignment_title': {
    AppLanguage.en: 'The Choir and the Pit',
    AppLanguage.fr: 'Le Chœur et la Fosse',
  },
  'clans_vows_state': {
    AppLanguage.en: 'Vows held: {n} · silent: {s}',
    AppLanguage.fr: 'Vœux tenus\u00a0: {n} · silencieux\u00a0: {s}',
  },
  'clans_pacts_state': {
    AppLanguage.en: 'Pacts held: {n} · still binding: {r}',
    AppLanguage.fr: 'Pactes tenus\u00a0: {n} · encore actifs\u00a0: {r}',
  },
  'clans_otherworld_claim': {
    AppLanguage.en: 'Claimed this life: {name}. The other will not come.',
    AppLanguage.fr:
        'A réclamé cette vie\u00a0: {name}. L’autre ne viendra pas.',
  },
  'clans_otherworld_open': {
    AppLanguage.en: 'Neither has claimed this life.',
    AppLanguage.fr: 'Aucun des deux n’a réclamé cette vie.',
  },
  'clans_matrix_hint': {
    AppLanguage.en: 'Tap a cell for the reason.',
    AppLanguage.fr: 'Touchez une case pour en connaître la raison.',
  },
  'clans_chapter_label': {
    AppLanguage.en: 'Relations in chapter {n}',
    AppLanguage.fr: 'Les relations au chapitre {n}',
  },
  'clans_chapter_now': {
    AppLanguage.en: 'Relations now',
    AppLanguage.fr: 'Les relations aujourd’hui',
  },
  'clans_history_title': {
    AppLanguage.en: 'Six hundred years in one line',
    AppLanguage.fr: 'Six cents ans en une ligne',
  },
  'clans_pair_title': {
    AppLanguage.en: '{a} and {b}',
    AppLanguage.fr: '{a} et {b}',
  },
  'clans_pair_moved': {
    AppLanguage.en: 'Chapter {c}, day {d}: {from} → {to} ({cause})',
    AppLanguage.fr: 'Chapitre {c}, jour {d}\u00a0: {from} → {to} ({cause})',
  },
  'clans_shift_down': {
    AppLanguage.en: 'One step worse',
    AppLanguage.fr: 'Un cran plus bas',
  },
  'clans_shift_up': {
    AppLanguage.en: 'One step better',
    AppLanguage.fr: 'Un cran plus haut',
  },
  'clans_evolution_empty': {
    AppLanguage.en: 'Nothing has moved yet.',
    AppLanguage.fr: 'Rien n’a encore bougé.',
  },
  'clans_log_title': {
    AppLanguage.en: 'The log, newest first',
    AppLanguage.fr: 'Le journal, du plus récent au plus ancien',
  },
  'clans_log_when': {
    AppLanguage.en: 'Ch. {c} · day {d}',
    AppLanguage.fr: 'Ch. {c} · jour {d}',
  },
  'clans_log_swore': {
    AppLanguage.en: 'Sworn: {name}',
    AppLanguage.fr: 'Serment\u00a0: {name}',
  },
  'clans_log_released': {
    AppLanguage.en: 'Oath released: {name}',
    AppLanguage.fr: 'Serment rompu\u00a0: {name}',
  },
  'clans_chart_start': {AppLanguage.en: 'Start', AppLanguage.fr: 'Début'},
  'clans_chart_tick': {
    AppLanguage.en: 'Ch{c}·D{d}',
    AppLanguage.fr: 'Ch{c}·J{d}',
  },
  'clans_subclans_label': {
    AppLanguage.en: 'Sub-clans',
    AppLanguage.fr: 'Sous-clans',
  },
  'clans_relations_log_title': {
    AppLanguage.en: 'Relations that moved',
    AppLanguage.fr: 'Relations qui ont changé',
  },
  'clans_intrigue_not_started': {
    AppLanguage.en: 'Not started',
    AppLanguage.fr: 'Pas commencée',
  },
  'clans_intrigue_stage': {
    AppLanguage.en: 'Stage {n} of 6: {stage}',
    AppLanguage.fr: 'Étape {n} sur 6\u00a0: {stage}',
  },
  'clans_intrigue_outcomes': {
    AppLanguage.en: 'Outcomes',
    AppLanguage.fr: 'Issues',
  },
  'clans_intrigue_chosen': {
    AppLanguage.en: 'Chosen',
    AppLanguage.fr: 'Choisie',
  },
  'clans_intrigue_chapter': {
    AppLanguage.en: 'Ch. {c}',
    AppLanguage.fr: 'Ch. {c}',
  },
  'intrigue_companion_leaves': {
    AppLanguage.en: '{name} leaves',
    AppLanguage.fr: '{name} quitte le groupe',
  },
  'intrigue_companion_disapproves': {
    AppLanguage.en: '{name} disapproves',
    AppLanguage.fr: '{name} désapprouve',
  },
  'intrigue_companion_approves': {
    AppLanguage.en: '{name} approves',
    AppLanguage.fr: '{name} approuve',
  },
  'intrigue_title_effect': {
    AppLanguage.en: 'Title: {name}',
    AppLanguage.fr: 'Titre\u00a0: {name}',
  },
  'clans_none': {
    AppLanguage.en: 'No clan data yet.',
    AppLanguage.fr: 'Pas encore de données de clans.',
  },
  'offer_title': {
    AppLanguage.en: 'The clans come to you',
    AppLanguage.fr: 'Les clans viennent à vous',
  },
  'offer_hint': {
    AppLanguage.en: 'Take one gift: the one you take is a side chosen.',
    AppLanguage.fr:
        'Prenez un don\u00a0: celui que vous prenez est un camp choisi.',
  },
  'offer_pending': {
    AppLanguage.en: '{n} waiting',
    AppLanguage.fr: '{n}\u00a0en attente',
  },
  'offer_take_button': {
    AppLanguage.en: 'Take this gift',
    AppLanguage.fr: 'Prendre ce don',
  },
  'offer_later_button': {
    AppLanguage.en: 'Later',
    AppLanguage.fr: 'Plus tard',
  },
  'offer_confirm_title': {
    AppLanguage.en: 'Take {gift}?',
    AppLanguage.fr: 'Prendre {gift}\u00a0?',
  },
  'offer_confirm_from': {
    AppLanguage.en: 'Offered by: {who}',
    AppLanguage.fr: 'Offert par\u00a0: {who}',
  },
  'offer_confirm_accept': {
    AppLanguage.en: 'Accept',
    AppLanguage.fr: 'Accepter',
  },
  'offer_confirm_back': {
    AppLanguage.en: 'Back',
    AppLanguage.fr: 'Retour',
  },
  'offer_no_standing': {
    AppLanguage.en: 'No faction: standing doesn’t move.',
    AppLanguage.fr: 'Sans faction\u00a0: la réputation ne bouge pas.',
  },
  'offer_alignment_nudge': {
    AppLanguage.en: 'alignment\u00a0{n}',
    AppLanguage.fr: 'alignement\u00a0{n}',
  },
  'offer_none_to_come': {
    AppLanguage.en: 'Nobody can come to you yet.',
    AppLanguage.fr: 'Personne ne peut encore venir à vous.',
  },
  'offer_source_level': {
    AppLanguage.en: 'A level reached',
    AppLanguage.fr: 'Un niveau atteint',
  },
  'offer_source_boss': {
    AppLanguage.en: 'A boss beaten',
    AppLanguage.fr: 'Un boss vaincu',
  },
  'offer_source_chapter': {
    AppLanguage.en: 'Chapter {n} begins',
    AppLanguage.fr: 'Le chapitre {n} commence',
  },
  'offer_source_tome': {
    AppLanguage.en: 'A Tome of Mastery read',
    AppLanguage.fr: 'Un Tome de maîtrise lu',
  },
  'offer_source_quest': {
    AppLanguage.en: 'A quest step',
    AppLanguage.fr: 'Une étape de quête',
  },
  'offer_source_intrigue': {
    AppLanguage.en: 'An intrigue comes to a head',
    AppLanguage.fr: 'Une intrigue se dénoue',
  },
  'offer_source_start': {
    AppLanguage.en: 'Your first steps',
    AppLanguage.fr: 'Vos premiers pas',
  },
  'offer_source_migrated': {
    AppLanguage.en: 'From the points you had not spent',
    AppLanguage.fr: 'Des points que vous n’aviez pas dépensés',
  },
  'offer_source_edit': {
    AppLanguage.en: 'Edit Mode',
    AppLanguage.fr: 'Mode Édition',
  },
  'offer_gift_skill': {
    AppLanguage.en: 'Skill',
    AppLanguage.fr: 'Compétence',
  },
  'offer_gift_sign': {
    AppLanguage.en: 'Sign',
    AppLanguage.fr: 'Signe',
  },
  'offer_gift_object': {
    AppLanguage.en: 'Object',
    AppLanguage.fr: 'Objet',
  },
  'offer_gift_title': {
    AppLanguage.en: 'Title',
    AppLanguage.fr: 'Titre',
  },
  'offer_gift_sworn': {
    AppLanguage.en: 'Sworn boon',
    AppLanguage.fr: 'Don du serment',
  },
  'offer_gift_perk': {
    AppLanguage.en: 'Perk',
    AppLanguage.fr: 'Atout',
  },
  'offer_sworn_note': {
    AppLanguage.en:
        'Given once, to the one sworn to them. It holds while you stay sworn.',
    AppLanguage.fr:
        'Donné une seule fois, à qui leur est juré. Il tient tant que vous le restez.',
  },
  'offer_wayfarer_name': {
    AppLanguage.en: 'The Wayfarer',
    AppLanguage.fr: 'Le Voyageur',
  },
  'offer_wayfarer_intro': {
    AppLanguage.en: 'A traveller with no banner falls in step beside you.',
    AppLanguage.fr: 'Un voyageur sans bannière se met à marcher à votre pas.',
  },
  'offer_wayfarer_greeting_0': {
    AppLanguage.en: 'No banner, no price. Take what helps.',
    AppLanguage.fr: 'Ni bannière ni prix. Prenez ce qui vous aide.',
  },
  'offer_wayfarer_greeting_1': {
    AppLanguage.en: 'The road teaches what the clans won’t.',
    AppLanguage.fr: 'La route enseigne ce que les clans taisent.',
  },
  'offer_wayfarer_greeting_2': {
    AppLanguage.en: 'I owe nobody on this coast. Neither do you, for this.',
    AppLanguage.fr:
        'Je ne dois rien à personne sur cette côte. Vous non plus, pour ceci.',
  },
  'offer_wayfarer_greeting_3': {
    AppLanguage.en: 'A small thing, freely given.',
    AppLanguage.fr: 'Une petite chose, donnée sans condition.',
  },
  'offers_section': {
    AppLanguage.en: 'Offers',
    AppLanguage.fr: 'Offres',
  },
  'offers_none': {
    AppLanguage.en:
        'No offer waiting. Each level, boss beaten, chapter and Tome of Mastery brings one.',
    AppLanguage.fr:
        'Aucune offre en attente. Chaque niveau, boss vaincu, chapitre et Tome de maîtrise en apporte une.',
  },
  'offer_open_button': {
    AppLanguage.en: 'Choose a gift',
    AppLanguage.fr: 'Choisir un don',
  },
  'offer_chapter_note': {
    AppLanguage.en: 'The clans come to you: an offer waits.',
    AppLanguage.fr: 'Les clans viennent à vous\u00a0: une offre vous attend.',
  },
  'offer_count_label': {
    AppLanguage.en: 'offer(s)',
    AppLanguage.fr: 'offre(s)',
  },
  'offer_bonus_label': {
    AppLanguage.en: 'Offer',
    AppLanguage.fr: 'Offre',
  },
  'offers_waiting_label': {
    AppLanguage.en: 'Offers waiting',
    AppLanguage.fr: 'Offres en attente',
  },
  'level_up_offer_note': {
    AppLanguage.en: 'The clans come to you once this closes: an offer waits.',
    AppLanguage.fr:
        'Les clans viennent à vous une fois ceci fermé\u00a0: une offre vous attend.',
  },
  'purse_offers_note': {
    AppLanguage.en: 'skills come in the clans’ offers',
    AppLanguage.fr: 'les compétences viennent des offres des clans',
  },
  'skill_offered_by': {
    AppLanguage.en: 'Offered by {clan}',
    AppLanguage.fr: 'Offert par {clan}',
  },
  'skill_no_sponsor': {
    AppLanguage.en: 'No clan offers it.',
    AppLanguage.fr: 'Aucun clan ne l’offre.',
  },
  'skill_offers_note': {
    AppLanguage.en:
        'A clan offers its branch’s skills one by one, deeper as it trusts you more.',
    AppLanguage.fr:
        'Un clan offre les compétences de sa branche une à une, plus profondes à mesure qu’il vous fait confiance.',
  },
  'titles_section': {
    AppLanguage.en: 'Titles',
    AppLanguage.fr: 'Titres',
  },
  'titles_none': {
    AppLanguage.en:
        'No title yet. The clans give them, and standing earns them.',
    AppLanguage.fr:
        'Aucun titre pour l’instant. Les clans en donnent, et la réputation en vaut.',
  },
  'title_wear': {
    AppLanguage.en: 'Wear',
    AppLanguage.fr: 'Porter',
  },
  'title_worn': {
    AppLanguage.en: 'Worn',
    AppLanguage.fr: 'Porté',
  },
  'title_bad_note': {
    AppLanguage.en: 'A brand: it counts, worn or not.',
    AppLanguage.fr: 'Une marque\u00a0: elle compte, portée ou non.',
  },
  'debug_offer_now': {
    AppLanguage.en: 'Offer now',
    AppLanguage.fr: 'Offre maintenant',
  },
  'debug_offer_plus': {
    AppLanguage.en: '+1 offer',
    AppLanguage.fr: '+1\u00a0offre',
  },
  'sign_log_writ': {
    AppLanguage.en: 'The Lantern’s Writ cancels the blow.',
    AppLanguage.fr: 'Le Mandat de la Lanterne annule le coup.',
  },
  'sign_log_edge': {
    AppLanguage.en: 'loses its guard to the Compact edge.',
    AppLanguage.fr: 'perd sa garde sous le fil du Pacte.',
  },
  'sign_log_ember': {
    AppLanguage.en: 'The Ember face lifts the curse.',
    AppLanguage.fr: 'La face Braise lève la malédiction.',
  },
  'sign_log_crows': {
    AppLanguage.en: 'The Crow’s Price: {n} gold stolen.',
    AppLanguage.fr:
        'Le Prix de la Corneille\u00a0: {n}\u00a0pièces d’or volées.',
  },
  'intent_then_label': {
    AppLanguage.en: 'Then:',
    AppLanguage.fr: 'Ensuite\u00a0:',
  },
  'shop_faction_line': {
    AppLanguage.en: '{name}: {tier}, prices {p}%',
    AppLanguage.fr: '{name}\u00a0: {tier}, prix {p}\u00a0%',
  },
  'shop_faction_fair': {
    AppLanguage.en: '{name}: {tier}, fair prices',
    AppLanguage.fr: '{name}\u00a0: {tier}, prix justes',
  },
  'shop_faction_refuses': {
    AppLanguage.en: '{name}: {tier}. This shop will not trade with you.',
    AppLanguage.fr:
        '{name}\u00a0: {tier}. Cette boutique refuse de commercer avec vous.',
  },
  // The clan story (v1.195): politics on choices, the coast's events, the
  // Open Hand.
  'politics_hint_mark_friend': {
    AppLanguage.en: '{name}: friend',
    AppLanguage.fr: '{name}\u00a0: amitié',
  },
  'politics_hint_mark_foe': {
    AppLanguage.en: '{name}: foe',
    AppLanguage.fr: '{name}\u00a0: inimitié',
  },
  'politics_hint_mark_none': {
    AppLanguage.en: '{name}: no mark',
    AppLanguage.fr: '{name}\u00a0: aucune marque',
  },
  'politics_hints_setting_title': {
    AppLanguage.en: 'Show what choices do to the clans',
    AppLanguage.fr: 'Montrer l’effet des choix sur les clans',
  },
  'politics_hints_setting_desc': {
    AppLanguage.en:
        'A muted line under a choice that moves the clans, such as “Vigil +5 · Dominion −5”. Hidden consequences stay hidden.',
    AppLanguage.fr:
        'Une ligne discrète sous un choix qui fait bouger les clans, comme «\u00a0Veille +5 · Dominion −5\u00a0». Les conséquences cachées restent cachées.',
  },
  'standing_cause_event': {
    AppLanguage.en: 'News from the coast',
    AppLanguage.fr: 'Nouvelles de la côte',
  },
  'offer_source_story': {
    AppLanguage.en: 'From the story',
    AppLanguage.fr: 'De l’histoire',
  },
  'patron_kind_lost': {
    AppLanguage.en: 'Lost clan',
    AppLanguage.fr: 'Clan perdu',
  },
  'coast_news_title': {
    AppLanguage.en: 'News from the coast',
    AppLanguage.fr: 'Nouvelles de la côte',
  },
  'coast_news_noted': {
    AppLanguage.en: 'Noted',
    AppLanguage.fr: 'Noté',
  },
  'coast_news_more': {
    AppLanguage.en: '{n} more in the journal',
    AppLanguage.fr: '{n}\u00a0de plus dans le journal',
  },
  'coast_news_chip': {
    AppLanguage.en: 'News ({n})',
    AppLanguage.fr: 'Nouvelles ({n})',
  },
  'coast_news_when': {
    AppLanguage.en: 'Chapter {c}, day {d}',
    AppLanguage.fr: 'Chapitre {c}, jour {d}',
  },
  'journal_news_tab': {
    AppLanguage.en: 'News',
    AppLanguage.fr: 'Nouvelles',
  },
  'journal_news_empty': {
    AppLanguage.en:
        'No news from the coast yet. The clans move whether you are there or not; what they do is written here.',
    AppLanguage.fr:
        'Aucune nouvelle de la côte pour l’instant. Les clans bougent que vous soyez là ou non\u00a0; ce qu’ils font s’écrit ici.',
  },
  'clans_events_title': {
    AppLanguage.en: 'The coast moves',
    AppLanguage.fr: 'La côte bouge',
  },
  'clans_events_none': {
    AppLanguage.en: 'No politics events in the data.',
    AppLanguage.fr: 'Aucun événement politique dans les données.',
  },
  'clans_event_fired': {
    AppLanguage.en: 'Fired: chapter {c}, day {d} · variant {v}',
    AppLanguage.fr: 'Survenu\u00a0: chapitre {c}, jour {d} · variante {v}',
  },
  'clans_event_waiting': {
    AppLanguage.en: 'Not yet',
    AppLanguage.fr: 'Pas encore',
  },
  'clans_event_fire_now': {
    AppLanguage.en: 'Fire now',
    AppLanguage.fr: 'Déclencher',
  },
  'clans_event_fired_notice': {
    AppLanguage.en: '“{name}” fired.',
    AppLanguage.fr: '«\u00a0{name}\u00a0» est survenu.',
  },
  'clans_event_by_story': {
    AppLanguage.en: 'Fired by the story',
    AppLanguage.fr: 'Déclenché par l’histoire',
  },
  'clans_event_trigger_chapter': {
    AppLanguage.en: 'chapter {n}',
    AppLanguage.fr: 'chapitre {n}',
  },
  'clans_event_trigger_day': {
    AppLanguage.en: 'day {n}',
    AppLanguage.fr: 'jour {n}',
  },
  'clans_event_trigger_flag': {
    AppLanguage.en: 'flag {f}',
    AppLanguage.fr: 'drapeau {f}',
  },
  'clans_event_or': {
    AppLanguage.en: 'or',
    AppLanguage.fr: 'ou',
  },
  'open_hand_unknown_name': {
    AppLanguage.en: 'A clan with no name',
    AppLanguage.fr: 'Un clan sans nom',
  },
  'open_hand_unknown_line': {
    AppLanguage.en:
        'A grey cloth, a giant figure with its hands open. Nobody will say whose.',
    AppLanguage.fr:
        'Un tissu gris, une silhouette géante aux mains ouvertes. Personne ne veut dire à qui il était.',
  },
  'open_hand_stage': {
    AppLanguage.en: 'Remembrance {n}/{max}',
    AppLanguage.fr: 'Souvenir {n}/{max}',
  },
  'open_hand_stage_none': {
    AppLanguage.en: 'Not remembered yet',
    AppLanguage.fr: 'Pas encore de souvenir',
  },
  'open_hand_banner_raised': {
    AppLanguage.en: 'Banner raised',
    AppLanguage.fr: 'Bannière levée',
  },
  'open_hand_edit_hint': {
    AppLanguage.en:
        'No standing: the remembrance stage, from the flags open_hand_1 to open_hand_6.',
    AppLanguage.fr:
        'Pas de réputation\u00a0: le stade du souvenir, d’après les drapeaux open_hand_1 à open_hand_6.',
  },
  'offer_own_hand_name': {
    AppLanguage.en: 'Your own hand',
    AppLanguage.fr: 'Votre propre main',
  },
  'offer_own_hand_greeting': {
    AppLanguage.en:
        'No clan comes. Your hand moves of itself, and the old blood draws.',
    AppLanguage.fr:
        'Aucun clan ne vient. Votre main bouge d’elle-même, et le vieux sang trace.',
  },
  'politics_editor_label': {
    AppLanguage.en: 'Politics (JSON)',
    AppLanguage.fr: 'Politique (JSON)',
  },
  'politics_on_enter_label': {
    AppLanguage.en: 'Politics on entering (JSON)',
    AppLanguage.fr: 'Politique à l’entrée (JSON)',
  },
  'politics_editor_help': {
    AppLanguage.en:
        '{"standing": {"vigil": 5}, "marks": {"inquisition": "foe"}, "relations": [{"a": "mire", "b": "penitents", "steps": 1}], "offerFrom": "penitents", "intrigue": {"id": "hooded_lantern", "stage": 2}, "remembrance": 3, "event": "id", "hidden": true, "claim": "vigil", "pledge": "mire", "throneWinner": "vigil", "muster": true}',
    AppLanguage.fr:
        '{"standing": {"vigil": 5}, "marks": {"inquisition": "foe"}, "relations": [{"a": "mire", "b": "penitents", "steps": 1}], "offerFrom": "penitents", "intrigue": {"id": "hooded_lantern", "stage": 2}, "remembrance": 3, "event": "id", "hidden": true, "claim": "vigil", "pledge": "mire", "throneWinner": "vigil", "muster": true}',
  },
  // The climb to the Lantern Throne and the Host (v1.196, see throne.dart).
  'politics_if_editor_label': {
    AppLanguage.en: 'Shown only if (JSON)',
    AppLanguage.fr: 'Affiché seulement si (JSON)',
  },
  'politics_if_editor_help': {
    AppLanguage.en:
        '{"claim": "any", "rungAtLeast": {"vigil": 1}, "standingAtLeast": {"vigil": 26}, "throneWinner": "none", "flags": ["x"]} -- hidden when it fails, or shut with the locked text',
    AppLanguage.fr:
        '{"claim": "any", "rungAtLeast": {"vigil": 1}, "standingAtLeast": {"vigil": 26}, "throneWinner": "none", "flags": ["x"]} -- caché quand la condition échoue, ou fermé avec le texte verrouillé',
  },
  'host_fight_editor_label': {
    AppLanguage.en: 'A last battle: the Host fights beside the party',
    AppLanguage.fr: 'Une dernière bataille : l’Ost combat aux côtés du groupe',
  },
  'throne_hint_claim': {
    AppLanguage.en: 'Claim: {name}',
    AppLanguage.fr: 'Prétention : {name}',
  },
  'throne_hint_claim_renounce': {
    AppLanguage.en: 'Claim: {name} (gives up {old})',
    AppLanguage.fr: 'Prétention : {name} (vous quittez {old})',
  },
  'throne_hint_pledge': {
    AppLanguage.en: 'Joins your cause: {name}',
    AppLanguage.fr: 'Rejoint votre cause : {name}',
  },
  'throne_hint_throne': {
    AppLanguage.en: 'The Throne: {name}',
    AppLanguage.fr: 'Le Trône : {name}',
  },
  'standing_cause_claim': {
    AppLanguage.en: 'Claim taken',
    AppLanguage.fr: 'Prétention',
  },
  'standing_cause_renounce': {
    AppLanguage.en: 'Claim given up',
    AppLanguage.fr: 'Prétention abandonnée',
  },
  'standing_cause_pledge': {
    AppLanguage.en: 'Joins your cause',
    AppLanguage.fr: 'Rejoint votre cause',
  },
  'standing_cause_throne': {
    AppLanguage.en: 'The Lantern Throne',
    AppLanguage.fr: 'Le Trône de la Lanterne',
  },
  'standing_cause_muster': {
    AppLanguage.en: 'The Host musters',
    AppLanguage.fr: 'L’Ost se rassemble',
  },
  'throne_climb_title': {
    AppLanguage.en: 'The climb',
    AppLanguage.fr: 'L’Ascension',
  },
  'throne_climb_hint': {
    AppLanguage.en:
        'A House of a clan, then the clan itself, then the Lantern Throne.',
    AppLanguage.fr:
        'Une Maison d’un clan, puis le clan lui-même, puis le Trône de la Lanterne.',
  },
  'throne_your_claim': {
    AppLanguage.en: 'Your claim: {name}',
    AppLanguage.fr: 'Votre prétention : {name}',
  },
  'throne_no_claim': {
    AppLanguage.en: 'No claim yet',
    AppLanguage.fr: 'Aucune prétention pour l’instant',
  },
  'throne_climbing': {
    AppLanguage.en: 'Furthest climb: {name}',
    AppLanguage.fr: 'Ascension la plus avancée : {name}',
  },
  'throne_on_throne': {
    AppLanguage.en: 'On the Lantern Throne for {name}',
    AppLanguage.fr: 'Sur le Trône de la Lanterne pour {name}',
  },
  'throne_rung_house': {AppLanguage.en: 'House', AppLanguage.fr: 'Maison'},
  'throne_rung_clan': {
    AppLanguage.en: 'Clan {n}/3',
    AppLanguage.fr: 'Clan {n}/3',
  },
  'throne_rung_clan_plain': {AppLanguage.en: 'Clan', AppLanguage.fr: 'Clan'},
  'throne_rung_throne': {AppLanguage.en: 'Throne', AppLanguage.fr: 'Trône'},
  'throne_rung_reached': {
    AppLanguage.en: '{rung}, reached',
    AppLanguage.fr: '{rung}, atteint',
  },
  'throne_rung_open': {
    AppLanguage.en: '{rung}, not yet',
    AppLanguage.fr: '{rung}, pas encore',
  },
  'host_title': {AppLanguage.en: 'Your Host', AppLanguage.fr: 'Votre Ost'},
  'host_intro': {
    AppLanguage.en:
        'The force you raised on the way. It fights beside the party in the last battles.',
    AppLanguage.fr:
        'La force que vous avez levée en chemin. Elle combat aux côtés du groupe lors des dernières batailles.',
  },
  'host_preview_intro': {
    AppLanguage.en:
        'Who would come if you mustered now: the Host fights beside the party in the last battles.',
    AppLanguage.fr:
        'Qui viendrait si vous rassembliez l’Ost maintenant : il combat aux côtés du groupe lors des dernières batailles.',
  },
  'host_mustered_on': {
    AppLanguage.en: 'Mustered in chapter {c}, day {d}',
    AppLanguage.fr: 'Rassemblé au chapitre {c}, jour {d}',
  },
  'host_banner': {AppLanguage.en: 'The Banner', AppLanguage.fr: 'La Bannière'},
  'host_no_banner': {
    AppLanguage.en: 'No banner: you hold no claim.',
    AppLanguage.fr: 'Aucune bannière : vous n’avez pas de prétention.',
  },
  'host_allies': {AppLanguage.en: 'Allies', AppLanguage.fr: 'Alliés'},
  'host_no_allies': {
    AppLanguage.en: 'No faction stands with you yet.',
    AppLanguage.fr: 'Aucune faction ne se tient encore avec vous.',
  },
  'host_houses': {AppLanguage.en: 'Houses', AppLanguage.fr: 'Maisons'},
  'host_no_houses': {
    AppLanguage.en: 'No House has sent a champion.',
    AppLanguage.fr: 'Aucune Maison n’a envoyé de champion.',
  },
  'host_houses_line': {
    AppLanguage.en: 'A champion from each House:',
    AppLanguage.fr: 'Un champion de chaque Maison :',
  },
  'host_why_pledged': {
    AppLanguage.en: 'pledged',
    AppLanguage.fr: 'ralliement',
  },
  'host_why_sign': {
    AppLanguage.en: 'a sign this life',
    AppLanguage.fr: 'un signe dans cette vie',
  },
  'host_size': {
    AppLanguage.en: '{n} in the Host',
    AppLanguage.fr: '{n} dans l’Ost',
  },
  'host_fight_log': {
    AppLanguage.en: 'Your Host fights beside you: {names}.',
    AppLanguage.fr: 'Votre Ost combat à vos côtés : {names}.',
  },
  'host_fight_houses': {
    AppLanguage.en: '{n} Houses',
    AppLanguage.fr: '{n} Maisons',
  },
  'host_fight_house_one': {
    AppLanguage.en: 'one House',
    AppLanguage.fr: 'une Maison',
  },
  'host_fight_note': {
    AppLanguage.en: 'Your Host fights beside you.',
    AppLanguage.fr: 'Votre Ost combat à vos côtés.',
  },
  'clans_tab_throne': {AppLanguage.en: 'Throne', AppLanguage.fr: 'Trône'},
  'throne_edit_hint': {
    AppLanguage.en:
        'Each faction’s climb: its House, its clan steps (the flags clan_<id>_step_1 to 3), the claim and the Throne. Set them here, and muster the Host.',
    AppLanguage.fr:
        'L’ascension de chaque faction : sa Maison, les étapes du clan (les drapeaux clan_<id>_step_1 à 3), la prétention et le Trône. Réglez-les ici, et rassemblez l’Ost.',
  },
  'throne_edit_steps': {
    AppLanguage.en: 'Steps {n}/3',
    AppLanguage.fr: 'Étapes {n}/3',
  },
  'throne_edit_claim': {AppLanguage.en: 'Claim', AppLanguage.fr: 'Prétention'},
  'throne_edit_pledge': {
    AppLanguage.en: 'Pledge',
    AppLanguage.fr: 'Ralliement',
  },
  'throne_edit_crown': {AppLanguage.en: 'Crown', AppLanguage.fr: 'Couronner'},
  'throne_edit_muster': {
    AppLanguage.en: 'Muster now',
    AppLanguage.fr: 'Rassembler maintenant',
  },
  'throne_edit_clear': {
    AppLanguage.en: 'Undo the climb',
    AppLanguage.fr: 'Annuler l’ascension',
  },
  'throne_edit_preview': {
    AppLanguage.en: 'Host preview',
    AppLanguage.fr: 'Aperçu de l’Ost',
  },
  'throne_edit_claimed': {
    AppLanguage.en: 'Claim',
    AppLanguage.fr: 'Prétention',
  },
  'throne_edit_pledged': {
    AppLanguage.en: 'Pledged',
    AppLanguage.fr: 'Ralliement',
  },
  'throne_edit_crowned': {
    AppLanguage.en: 'On the Throne',
    AppLanguage.fr: 'Sur le Trône',
  },
  'throne_edit_done': {
    AppLanguage.en: 'Done.',
    AppLanguage.fr: 'C’est fait.',
  },
};

/// Translates the raw English [PlayerSession.alignmentLabel] value
/// ('Good' / 'Neutral' / 'Evil') for display.
String trAlignmentLabel(WidgetRef ref, String raw) {
  switch (raw) {
    case 'Good':
      return tr(ref, 'alignment_good');
    case 'Evil':
      return tr(ref, 'alignment_evil');
    default:
      return tr(ref, 'alignment_neutral');
  }
}

/// Looks up [key] for a known [language] without needing a [WidgetRef] —
/// for use in callbacks (dialogs, bottom sheets) outside a widget's build.
String trFor(AppLanguage language, String key) {
  return _strings[key]?[language] ?? _strings[key]?[AppLanguage.en] ?? key;
}

String tr(WidgetRef ref, String key) =>
    trFor(ref.watch(appLanguageProvider), key);
