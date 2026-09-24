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
            'point you heal and shortens how long Poison, Stun, or Weaken '
            'holds on to you.',
    AppLanguage.fr:
        'Intervient dans les jets de Sagesse des choix narratifs — lire '
            'les gens, sentir ce qui se trame vraiment. En combat, elle '
            'renforce aussi chaque soin et raccourcit la durée du Poison, '
            'de l\'Étourdissement ou de l\'Affaiblissement.',
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
    AppLanguage.en: 'Read on the spot: one skill point.',
    AppLanguage.fr: 'Lu sur-le-champ : un point de compétence.',
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
  'leave_settlement_title': {
    AppLanguage.en: 'Leave {place}',
    AppLanguage.fr: 'Quitter {place}',
  },
  'leave_settlement_hint': {
    AppLanguage.en: 'Where the story goes next, when you are ready',
    AppLanguage.fr: 'La suite de l’histoire, quand vous serez prêt',
  },
  'arrival_town_title': {
    AppLanguage.en: 'You arrive in {place}',
    AppLanguage.fr: 'Vous arrivez à {place}',
  },
  'arrival_town_body': {
    AppLanguage.en:
        'This is a town. Its shops, expeditions, people and challenges are listed under the story; you can come and go between them as you like. When you are ready to move on, open "Leave {place}" at the bottom.',
    AppLanguage.fr:
        'Vous êtes en ville. Ses boutiques, expéditions, habitants et défis sont listés sous le récit ; allez de l’un à l’autre à votre guise. Quand vous serez prêt à repartir, ouvrez « Quitter {place} » en bas.',
  },
  'arrival_town_button': {
    AppLanguage.en: 'Enter the town',
    AppLanguage.fr: 'Entrer en ville',
  },
  'arrival_camp_title': {
    AppLanguage.en: 'You reach {place}',
    AppLanguage.fr: 'Vous atteignez {place}',
  },
  'arrival_camp_body': {
    AppLanguage.en:
        'This is your camp. From now on the Camp page (Play tab) holds your companions, rest, the camp\'s works, its shops and the expeditions that leave from it.',
    AppLanguage.fr:
        'Voici votre camp. Désormais, la page Camp (onglet Jouer) réunit vos compagnons, le repos, les ouvrages du camp, ses boutiques et les expéditions qui en partent.',
  },
  'arrival_camp_button': {
    AppLanguage.en: 'Make camp',
    AppLanguage.fr: 'Installer le camp',
  },
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
  'skill_faces_title': {AppLanguage.en: 'Faces', AppLanguage.fr: 'Faces'},
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
    AppLanguage.fr: 'de santé et de dégâts : le Suaire a appris cet ennemi'
  },
  'house_built_prefix': {AppLanguage.en: 'Built', AppLanguage.fr: 'Construit'},
  'build_button': {AppLanguage.en: 'Build', AppLanguage.fr: 'Construire'},
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
    AppLanguage.en: 'Reach Chapter 3 to unlock',
    AppLanguage.fr: 'Atteignez le chapitre 3 pour débloquer',
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
  'grants_banner_piece_id': {
    AppLanguage.en: 'Grants Banner piece (id)',
    AppLanguage.fr: 'Accorde un fragment de la Bannière (id)',
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
  'combat_effects_setting_title': {
    AppLanguage.en: 'Combat effects',
    AppLanguage.fr: 'Effets de combat',
  },
  'combat_effects_setting_desc': {
    AppLanguage.en:
        'Draws each skill\'s and spell\'s effect on screen in fights, with floating damage and healing numbers.',
    AppLanguage.fr:
        "Affiche l'effet de chaque compétence et de chaque sort pendant les combats, avec les dégâts et soins flottants.",
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
    AppLanguage.fr: 'Vous êtes mort'
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
        'You drop {gold} gold getting clear and keep the wounds you have. Nothing is won. A detour is left behind; a fight in the story waits where it was.',
    AppLanguage.fr:
        'Vous laissez tomber {gold} or en vous dégageant et gardez vos blessures. Rien n’est gagné. Un détour est abandonné ; un combat de l’histoire vous attend là où il était.',
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
  'zone_flag_void_sovereign_fallen': {
    AppLanguage.en: 'The Void Sovereign, fallen',
    AppLanguage.fr: 'Le Souverain, tombé',
  },
  'boat_title': {
    AppLanguage.en: 'The Rusty Eel',
    AppLanguage.fr: 'Le Rusty Eel'
  },
  'boat_locked_subtitle': {
    AppLanguage.en: 'Reach Chapter 3 to unlock',
    AppLanguage.fr: 'Atteignez le chapitre 3 pour débloquer',
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
        'Their bulwark is down: board and fight {crew} at the rail (their helm may slip the grapples; it ends the turn).',
    AppLanguage.fr:
        'Leur pavois est à terre : abordez et affrontez {crew} au bastingage (leur barre peut esquiver les grappins ; cela termine le tour).',
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
  'ship_end_turn_button': {
    AppLanguage.en: 'End turn',
    AppLanguage.fr: 'Fin du tour'
  },
  'ship_fire_hint': {
    AppLanguage.en: 'Tap a ready weapon, then the room to hit.',
    AppLanguage.fr: 'Touchez une arme prête, puis la salle à frapper.',
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
    AppLanguage.fr: '{crew} est blessé à {room}, -{n}',
  },
  'ship_log_enemy_repairs': {
    AppLanguage.en: 'The {ship} repairs its {room}',
    AppLanguage.fr: '{ship} répare {room}',
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
