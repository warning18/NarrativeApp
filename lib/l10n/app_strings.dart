import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';

/// A small hand-maintained UI string table. Covers navigation chrome, the
/// story reader, and a handful of the most common action labels — not an
/// exhaustive translation of every screen (see the language toggle's
/// tooltip in Settings for the current coverage note).
const Map<String, Map<AppLanguage, String>> _strings = {
  'nav_story': {AppLanguage.en: 'Story', AppLanguage.fr: 'Histoire'},
  'nav_play': {AppLanguage.en: 'Play', AppLanguage.fr: 'Jouer'},
  'nav_map': {AppLanguage.en: 'Map', AppLanguage.fr: 'Carte'},
  'nav_generate': {AppLanguage.en: 'Generate', AppLanguage.fr: 'Générer'},
  'nav_data': {AppLanguage.en: 'Data', AppLanguage.fr: 'Données'},
  'title_story': {AppLanguage.en: 'Story', AppLanguage.fr: 'Histoire'},
  'title_play': {AppLanguage.en: 'Play', AppLanguage.fr: 'Jouer'},
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
    AppLanguage.en: 'Improves your odds of finding better loot after a fight.',
    AppLanguage.fr:
        'Améliore vos chances de trouver un meilleur butin après un combat.',
  },
  'charisma_desc': {
    AppLanguage.en: 'Opens persuasion-gated dialogue and story choices.',
    AppLanguage.fr:
        'Débloque des dialogues et choix narratifs liés à la persuasion.',
  },
  'strength_desc': {
    AppLanguage.en: 'Backs Strength checks on story choices — forcing your way '
        'through, moving what won\'t move.',
    AppLanguage.fr:
        'Intervient dans les jets de Force des choix narratifs — forcer '
            'un passage, déplacer ce qui ne bouge pas.',
  },
  'dexterity_desc': {
    AppLanguage.en: 'Backs Dexterity checks on story choices — picking locks, '
        'staying light on your feet.',
    AppLanguage.fr:
        'Intervient dans les jets de Dextérité des choix narratifs — '
            'crocheter une serrure, rester agile.',
  },
  'constitution_desc': {
    AppLanguage.en:
        'Backs Constitution checks on story choices — enduring what '
            'would stop most people.',
    AppLanguage.fr:
        'Intervient dans les jets de Constitution des choix narratifs — '
            'endurer ce qui arrêterait la plupart des gens.',
  },
  'intelligence_desc': {
    AppLanguage.en:
        'Backs Intelligence checks on story choices — puzzling things '
            'out, reading what others missed.',
    AppLanguage.fr:
        'Intervient dans les jets d\'Intelligence des choix narratifs — '
            'comprendre ce que d\'autres ont manqué.',
  },
  'wisdom_desc': {
    AppLanguage.en:
        'Backs Wisdom checks on story choices — reading people, sensing '
            'what\'s really going on.',
    AppLanguage.fr:
        'Intervient dans les jets de Sagesse des choix narratifs — lire '
            'les gens, sentir ce qui se trame vraiment.',
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
    AppLanguage.en: 'Reads each scene aloud as soon as it appears, using the '
        "device's built-in voice (fast — never waits on Gemini).",
    AppLanguage.fr: "Lit chaque scène à voix haute dès son affichage, avec la "
        "voix intégrée de l'appareil (rapide — n'attend jamais Gemini).",
  },
  'gemini_voice_setting_title': {
    AppLanguage.en: 'Use Gemini AI voice (higher quality)',
    AppLanguage.fr: "Utiliser la voix IA Gemini (meilleure qualité)",
  },
  'gemini_voice_setting_desc': {
    AppLanguage.en:
        'Needs a Gemini API key (set one below in Edit mode) and an internet connection. '
            'Falls back to the device voice otherwise.',
    AppLanguage.fr:
        "Nécessite une clé API Gemini (à définir ci-dessous en mode Édition) et une connexion "
            "internet. Utilise sinon la voix de l'appareil.",
  },
  'gemini_voice_picker_label': {
    AppLanguage.en: 'Gemini voice',
    AppLanguage.fr: 'Voix Gemini'
  },
  'gemini_voice_missing_key_hint': {
    AppLanguage.en: 'No Gemini API key set — using the device voice instead.',
    AppLanguage.fr:
        "Aucune clé API Gemini définie — utilisation de la voix de l'appareil à la place.",
  },
  'gemini_voice_error_prefix': {
    AppLanguage.en: 'Gemini voice failed',
    AppLanguage.fr: 'Échec de la voix Gemini',
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
    AppLanguage.fr: 'Ton personnage, gravé dans la pierre',
  },
  'lock_character_dialog_desc': {
    AppLanguage.en:
        "Once you begin, your race and profession can't be changed for the rest "
            'of this run. Choose a name to carry with you.',
    AppLanguage.fr:
        'Une fois commencé, ta race et ta profession ne pourront plus être '
            'changées pour le reste de cette partie. Choisis un nom à porter.',
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
    AppLanguage.fr: 'Commencer ton histoire',
  },
  'origin_stories_section_title': {
    AppLanguage.en: 'A Life Before This One',
    AppLanguage.fr: 'Une vie avant celle-ci',
  },
  'origin_childhood_bird_title': {
    AppLanguage.en: 'Childhood: The Injured Bird',
    AppLanguage.fr: "Enfance : L'oiseau blessé",
  },
  'origin_childhood_bird_desc': {
    AppLanguage.en:
        'As a child, you stumbled upon a sparrow with a broken wing, thrashing '
            'weakly in the grass.',
    AppLanguage.fr:
        "Enfant, tu tombes sur un moineau à l'aile brisée, se débattant "
            "faiblement dans l'herbe.",
  },
  'origin_childhood_bird_good': {
    AppLanguage.en: 'Cup it in your hands and nurse it back to health',
    AppLanguage.fr: 'Le prendre dans tes mains et le soigner',
  },
  'origin_childhood_bird_evil': {
    AppLanguage.en: 'Crush it beneath your heel and walk on',
    AppLanguage.fr: 'Écraser sous ton talon et poursuivre ton chemin',
  },
  'origin_childhood_bird_neutral': {
    AppLanguage.en: 'Leave it to nature and walk away',
    AppLanguage.fr: 'Laisser à son sort et t\'en aller',
  },
  'origin_childhood_beggar_title': {
    AppLanguage.en: "Childhood: The Beggar's Plea",
    AppLanguage.fr: 'Enfance : La supplique du mendiant',
  },
  'origin_childhood_beggar_desc': {
    AppLanguage.en:
        'An old beggar outside the market grabs your sleeve, pleading for the '
            'last piece of bread in your hand.',
    AppLanguage.fr:
        "Un vieux mendiant devant le marché s'accroche à ta manche, suppliant "
            'pour le dernier morceau de pain dans ta main.',
  },
  'origin_childhood_beggar_good': {
    AppLanguage.en: 'Give him the bread, even hungry yourself',
    AppLanguage.fr: 'Lui donner le pain, même le ventre vide',
  },
  'origin_childhood_beggar_evil': {
    AppLanguage.en: 'Mock him and eat it in front of him',
    AppLanguage.fr: 'Te moquer de lui et le manger devant lui',
  },
  'origin_childhood_beggar_neutral': {
    AppLanguage.en: 'Pull free and keep walking without a word',
    AppLanguage.fr: 'Te dégager et continuer ton chemin sans un mot',
  },
  // Profession-flavored small variants of the beggar's-plea beat above —
  // same shape and length, reworded to each profession's own world. Rogue
  // gets a genuinely different scenario (a rigged card game) rather than a
  // reskin, matching the "cheat in a game" example this was requested with.
  'origin_childhood_beggar_warrior_title': {
    AppLanguage.en: 'Childhood: The Wounded Veteran',
    AppLanguage.fr: 'Enfance : Le vieux soldat',
  },
  'origin_childhood_beggar_warrior_desc': {
    AppLanguage.en:
        'An old soldier begging outside the training yard grabs your sleeve, '
            'pleading for the last ration in your pack.',
    AppLanguage.fr:
        "Un vieux soldat devant la cour d'entraînement s'accroche à ta manche, "
            'suppliant pour la dernière ration dans ton sac.',
  },
  'origin_childhood_beggar_warrior_good': {
    AppLanguage.en: 'Give him the ration, even hungry yourself',
    AppLanguage.fr: 'Lui donner la ration, même le ventre vide',
  },
  'origin_childhood_beggar_warrior_evil': {
    AppLanguage.en: 'Mock his weakness and eat it in front of him',
    AppLanguage.fr: 'Te moquer de sa faiblesse et la manger devant lui',
  },
  'origin_childhood_beggar_warrior_neutral': {
    AppLanguage.en: 'Pull free and keep walking without a word',
    AppLanguage.fr: 'Te dégager et continuer ton chemin sans un mot',
  },
  'origin_childhood_beggar_mage_title': {
    AppLanguage.en: "Childhood: The Hedge-Mage's Plea",
    AppLanguage.fr: 'Enfance : La supplique du sorcier des rues',
  },
  'origin_childhood_beggar_mage_desc': {
    AppLanguage.en:
        'An old hedge-mage outside the arcane bazaar grabs your sleeve, pleading '
            'for the last warming charm in your hand.',
    AppLanguage.fr:
        'Un vieux sorcier des rues devant le bazar arcanique s\'accroche à ta '
            'manche, suppliant pour le dernier charme de chaleur dans ta main.',
  },
  'origin_childhood_beggar_mage_good': {
    AppLanguage.en: 'Give him the charm, even cold yourself',
    AppLanguage.fr: 'Lui donner le charme, même transi de froid',
  },
  'origin_childhood_beggar_mage_evil': {
    AppLanguage.en: 'Mock him and use it yourself in front of him',
    AppLanguage.fr: "Te moquer de lui et l'utiliser devant lui",
  },
  'origin_childhood_beggar_mage_neutral': {
    AppLanguage.en: 'Pull free and keep walking without a word',
    AppLanguage.fr: 'Te dégager et continuer ton chemin sans un mot',
  },
  'origin_childhood_beggar_rogue_title': {
    AppLanguage.en: 'Childhood: The Rigged Game',
    AppLanguage.fr: 'Enfance : La partie truquée',
  },
  'origin_childhood_beggar_rogue_desc': {
    AppLanguage.en:
        'An old card-sharp in the back alley waves you over, offering a game you '
            'can tell — even at your age — is rigged in your favor against the next mark.',
    AppLanguage.fr:
        'Un vieux tricheur de cartes dans la ruelle te fait signe, proposant une '
            'partie que tu devines déjà — même à cet âge — truquée en ta faveur contre le '
            'prochain pigeon.',
  },
  'origin_childhood_beggar_rogue_good': {
    AppLanguage.en: 'Warn the next mark before he sits down to lose',
    AppLanguage.fr:
        "Prévenir le prochain pigeon avant qu'il ne s'assoie pour perdre",
  },
  'origin_childhood_beggar_rogue_evil': {
    AppLanguage.en: 'Take the seat and let the game run as rigged',
    AppLanguage.fr:
        'Prendre place et laisser la partie truquée suivre son cours',
  },
  'origin_childhood_beggar_rogue_neutral': {
    AppLanguage.en: 'Walk past without a word either way',
    AppLanguage.fr:
        "Passer ton chemin sans un mot, dans un sens comme dans l'autre",
  },
  'origin_childhood_beggar_cleric_title': {
    AppLanguage.en: "Childhood: The Pilgrim's Plea",
    AppLanguage.fr: 'Enfance : La supplique du pèlerin',
  },
  'origin_childhood_beggar_cleric_desc': {
    AppLanguage.en:
        'An old pilgrim outside the temple steps grabs your sleeve, pleading for '
            'the last coin in your hand for the offering box.',
    AppLanguage.fr:
        "Un vieux pèlerin devant les marches du temple s'accroche à ta manche, "
            'suppliant pour la dernière pièce dans ta main, pour le tronc des offrandes.',
  },
  'origin_childhood_beggar_cleric_good': {
    AppLanguage.en: 'Give him the coin, even poor yourself',
    AppLanguage.fr: 'Lui donner la pièce, même démuni toi-même',
  },
  'origin_childhood_beggar_cleric_evil': {
    AppLanguage.en: 'Mock his faith and pocket it in front of him',
    AppLanguage.fr: 'Te moquer de sa foi et l\'empocher devant lui',
  },
  'origin_childhood_beggar_cleric_neutral': {
    AppLanguage.en: 'Pull free and keep walking without a word',
    AppLanguage.fr: 'Te dégager et continuer ton chemin sans un mot',
  },
  'origin_childhood_beggar_ranger_title': {
    AppLanguage.en: "Childhood: The Trapper's Plea",
    AppLanguage.fr: 'Enfance : La supplique du trappeur',
  },
  'origin_childhood_beggar_ranger_desc': {
    AppLanguage.en:
        'An old trapper outside the hunting lodge grabs your sleeve, pleading for '
            'the last strip of dried meat in your pack.',
    AppLanguage.fr:
        "Un vieux trappeur devant le pavillon de chasse s'accroche à ta manche, "
            'suppliant pour la dernière lanière de viande séchée dans ton sac.',
  },
  'origin_childhood_beggar_ranger_good': {
    AppLanguage.en: 'Give him the meat, even hungry yourself',
    AppLanguage.fr: 'Lui donner la viande, même affamé toi-même',
  },
  'origin_childhood_beggar_ranger_evil': {
    AppLanguage.en: 'Mock his hunger and eat it in front of him',
    AppLanguage.fr: 'Te moquer de sa faim et la manger devant lui',
  },
  'origin_childhood_beggar_ranger_neutral': {
    AppLanguage.en: 'Pull free and keep walking without a word',
    AppLanguage.fr: 'Te dégager et continuer ton chemin sans un mot',
  },
  'origin_teen_bully_title': {
    AppLanguage.en: 'Teenage Years: The Bully',
    AppLanguage.fr: 'Adolescence : Le tyran de cour',
  },
  'origin_teen_bully_desc': {
    AppLanguage.en:
        'Behind the schoolyard, an older boy has a smaller kid pinned against '
            'the wall, fists ready.',
    AppLanguage.fr:
        "Derrière la cour de l'école, un garçon plus âgé plaque un plus petit "
            'contre le mur, poings levés.',
  },
  'origin_teen_bully_good': {
    AppLanguage.en: 'Step in and stand between them',
    AppLanguage.fr: 'Intervenir et te placer entre eux',
  },
  'origin_teen_bully_evil': {
    AppLanguage.en: 'Laugh and egg the bully on',
    AppLanguage.fr: 'Rire et encourager le tyran',
  },
  'origin_teen_bully_neutral': {
    AppLanguage.en: 'Turn the corner and pretend you saw nothing',
    AppLanguage.fr: "Tourner au coin et faire comme si tu n'avais rien vu",
  },
  'origin_teen_vase_title': {
    AppLanguage.en: 'Teenage Years: The Broken Vase',
    AppLanguage.fr: 'Adolescence : Le vase brisé',
  },
  'origin_teen_vase_desc': {
    AppLanguage.en:
        "Running through the market, you knock over a merchant's prized vase. "
            'It shatters at your feet.',
    AppLanguage.fr:
        "En courant dans le marché, tu renverses le vase précieux d'un "
            'marchand. Il se brise à tes pieds.',
  },
  'origin_teen_vase_good': {
    AppLanguage.en: 'Confess and offer to work off the debt',
    AppLanguage.fr: 'Avouer et proposer de rembourser en travaillant',
  },
  'origin_teen_vase_evil': {
    AppLanguage.en: 'Point at another passerby and blame them',
    AppLanguage.fr: 'Désigner un autre passant et l\'accuser',
  },
  'origin_teen_vase_neutral': {
    AppLanguage.en: 'Slip into the crowd before anyone notices',
    AppLanguage.fr: 'Te fondre dans la foule avant que quiconque remarque',
  },
  'origin_teen_thief_title': {
    AppLanguage.en: 'Teenage Years: The Cornered Thief',
    AppLanguage.fr: 'Adolescence : Le voleur acculé',
  },
  'origin_teen_thief_desc': {
    AppLanguage.en:
        'You catch a gaunt, starving thief mid-theft, rifling through your '
            "family's stores.",
    AppLanguage.fr:
        'Tu surprends un voleur famélique en train de fouiller les provisions '
            'de ta famille.',
  },
  'origin_teen_thief_good': {
    AppLanguage.en: 'Let them go, and press some food into their hands',
    AppLanguage.fr: 'Le laisser partir, en lui glissant un peu de nourriture',
  },
  'origin_teen_thief_evil': {
    AppLanguage.en: 'Hand them to the guards, knowing what awaits them',
    AppLanguage.fr: 'Le livrer aux gardes, sachant ce qui l\'attend',
  },
  'origin_teen_thief_neutral': {
    AppLanguage.en: 'Report the theft plainly and let others decide',
    AppLanguage.fr: 'Signaler le vol sans détour et laisser les autres décider',
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
  'increased_suffix': {
    AppLanguage.en: 'increased!',
    AppLanguage.fr: 'augmenté(e) !'
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
  'skill_faces_title': {
    AppLanguage.en: 'Skill Faces',
    AppLanguage.fr: 'Faces de compétence'
  },
  'drag_skill_hint': {
    AppLanguage.en: 'Drag a skill below onto a face to bind it for combat.',
    AppLanguage.fr:
        'Faites glisser une compétence ci-dessous sur une face pour la lier au combat.',
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
  'house_built_prefix': {AppLanguage.en: 'Built', AppLanguage.fr: 'Construit'},
  'build_button': {AppLanguage.en: 'Build', AppLanguage.fr: 'Construire'},
  'town_hub_title': {
    AppLanguage.en: 'Town Hub',
    AppLanguage.fr: 'Place du village'
  },
  'town_hub_locked_subtitle': {
    AppLanguage.en: 'Reach Chapter 2 to unlock',
    AppLanguage.fr: 'Atteignez le chapitre 2 pour débloquer',
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
  'expedition_progress_label': {
    AppLanguage.en: 'Expedition',
    AppLanguage.fr: 'Expédition'
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
  'antidote_button_prefix': {
    AppLanguage.en: 'Antidote',
    AppLanguage.fr: 'Antidote',
  },
  'tremble_setting_title': {
    AppLanguage.en: 'Screen tremble on hit',
    AppLanguage.fr: "Tremblement d'écran à l'impact",
  },
  'tremble_setting_desc': {
    AppLanguage.en: 'Shakes the screen briefly when you take damage in combat.',
    AppLanguage.fr:
        "Fait légèrement trembler l'écran lorsque vous subissez des dégâts au combat.",
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
  'the_enemy_label': {AppLanguage.en: 'The enemy', AppLanguage.fr: "L'ennemi"},
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
        'When enabled, losing a fight sends you back to the beginning of the '
            'story. You keep your level and stats, but lose all items.',
    AppLanguage.fr: 'Une fois activée, perdre un combat vous renvoie au début de '
        "l'histoire. Vous conservez votre niveau et vos statistiques, mais perdez tous vos objets.",
  },
  'you_died_title': {
    AppLanguage.en: 'You Died',
    AppLanguage.fr: 'Vous êtes mort'
  },
  'you_died_message': {
    AppLanguage.en:
        'The story starts over. You keep everything you\'ve learned — your '
            'level, stats, and skills — but your pack is empty.',
    AppLanguage.fr:
        "L'histoire recommence. Vous conservez tout ce que vous avez appris — "
            'votre niveau, vos statistiques et vos compétences — mais votre sac est vide.',
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
        'reached.',
    AppLanguage.fr:
        "Enchaîne de vrais choix selon la stratégie ci-dessus, avec de "
            "l'or, un alignement, des drapeaux et des combats réellement "
            "gagnés, puis vous redonne la main dans la vue Histoire une "
            'fois le chapitre atteint.',
  },
  'play_to_chapter_button': {
    AppLanguage.en: 'Play to Chapter',
    AppLanguage.fr: 'Jouer jusqu\'au chapitre',
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
    AppLanguage.en: 'Guided tour',
    AppLanguage.fr: 'Visite guidée'
  },
  'tutorial_setting_desc': {
    AppLanguage.en:
        'Show a short walkthrough the first time you enter In-Game mode.',
    AppLanguage.fr:
        'Affiche une courte visite guidée la première fois que vous entrez en mode En jeu.',
  },
  'tutorial_replay_button': {
    AppLanguage.en: 'Replay tutorial',
    AppLanguage.fr: 'Revoir le tutoriel',
  },
  'tutorial_skip_button': {AppLanguage.en: 'Skip', AppLanguage.fr: 'Passer'},
  'tutorial_next_button': {AppLanguage.en: 'Next', AppLanguage.fr: 'Suivant'},
  'tutorial_done_button': {
    AppLanguage.en: 'Got it!',
    AppLanguage.fr: 'Compris !'
  },
  'tutorial_step1_title': {
    AppLanguage.en: 'Welcome, adventurer!',
    AppLanguage.fr: 'Bienvenue, aventurier !',
  },
  'tutorial_step1_body': {
    AppLanguage.en:
        "Hi, I'm your companion for the journey — let me show you around before "
            'you dive in.',
    AppLanguage.fr:
        'Bonjour, je suis votre compagnon pour le voyage — laissez-moi vous faire '
            'visiter avant de commencer.',
  },
  'tutorial_step1_body_named_prefix': {
    AppLanguage.en: "Hi, I'm ",
    AppLanguage.fr: 'Bonjour, je suis ',
  },
  'tutorial_step1_body_named_suffix': {
    AppLanguage.en: ' — let me show you around before you dive in.',
    AppLanguage.fr: ' — laissez-moi vous faire visiter avant de commencer.',
  },
  'tutorial_step2_title': {
    AppLanguage.en: 'The Story tab',
    AppLanguage.fr: "L'onglet Histoire"
  },
  'tutorial_step2_body': {
    AppLanguage.en:
        'This is where the tale unfolds. Read each passage, then pick a choice to '
            'see what happens next.',
    AppLanguage.fr:
        "C'est ici que l'histoire se déroule. Lisez chaque passage, puis faites un "
            'choix pour voir la suite.',
  },
  'tutorial_step3_title': {
    AppLanguage.en: 'The Play tab',
    AppLanguage.fr: "L'onglet Jouer"
  },
  'tutorial_step3_body': {
    AppLanguage.en:
        "Track active quests, browse shops, and check the bestiary here — "
            "everything you've discovered so far.",
    AppLanguage.fr:
        'Suivez vos quêtes actives, visitez les boutiques et consultez le '
            "bestiaire ici — tout ce que vous avez découvert jusqu'à présent.",
  },
  'tutorial_step4_title': {
    AppLanguage.en: 'Your character',
    AppLanguage.fr: 'Votre personnage'
  },
  'tutorial_step4_body': {
    AppLanguage.en:
        'Keep an eye on health, gold, and stats at the top of the screen. Win '
            'fights to gain experience and level up.',
    AppLanguage.fr:
        "Surveillez votre santé, votre or et vos statistiques en haut de l'écran. "
            "Gagnez des combats pour prendre de l'expérience et monter de niveau.",
  },
  'tutorial_step5_title': {
    AppLanguage.en: 'Make it yours',
    AppLanguage.fr: "Personnalisez l'expérience",
  },
  'tutorial_step5_body': {
    AppLanguage.en:
        'Visit Settings anytime to adjust dark mode, read-aloud narration, and '
            'more — including turning me on or off.',
    AppLanguage.fr:
        'Allez dans les paramètres à tout moment pour ajuster le mode sombre, la '
            "narration vocale, et plus encore — y compris m'activer ou me désactiver.",
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
