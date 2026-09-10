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
  'title_map': {AppLanguage.en: 'Story Map', AppLanguage.fr: "Carte de l'histoire"},
  'title_generate': {AppLanguage.en: 'AI Generator', AppLanguage.fr: 'Générateur IA'},
  'title_data': {AppLanguage.en: 'Game Data', AppLanguage.fr: 'Données du jeu'},
  'settings': {AppLanguage.en: 'Settings', AppLanguage.fr: 'Paramètres'},
  'back': {AppLanguage.en: 'Back', AppLanguage.fr: 'Retour'},
  'node': {AppLanguage.en: 'Node', AppLanguage.fr: 'Nœud'},
  'detour': {AppLanguage.en: 'Detour', AppLanguage.fr: 'Détour'},
  'restart_story': {AppLanguage.en: 'Restart Story', AppLanguage.fr: "Recommencer l'histoire"},
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
  'node_kind_generic': {AppLanguage.en: 'Generic', AppLanguage.fr: 'Générique'},
  'main_story_beat': {
    AppLanguage.en: 'Main Story Beat',
    AppLanguage.fr: "Étape principale de l'histoire",
  },
  'main_beat_chip': {AppLanguage.en: 'Main Beat', AppLanguage.fr: 'Étape principale'},
  'requires_label': {AppLanguage.en: 'Requires:', AppLanguage.fr: 'Nécessite :'},
  'choices_label': {AppLanguage.en: 'Choices', AppLanguage.fr: 'Choix'},
  'no_choices_ending': {
    AppLanguage.en: '(none — this is an ending)',
    AppLanguage.fr: '(aucun — ceci est une fin)',
  },
  'jump_to_node': {AppLanguage.en: 'Jump to this node', AppLanguage.fr: 'Aller à ce nœud'},
  'end_label': {AppLanguage.en: 'End', AppLanguage.fr: 'Fin'},
  'tap_to_filter': {
    AppLanguage.en: 'Tap a legend row to hide/show that node type',
    AppLanguage.fr: "Touchez une ligne pour afficher/masquer ce type de nœud",
  },
  'edit_node': {AppLanguage.en: 'Edit node', AppLanguage.fr: 'Modifier le nœud'},
  'save': {AppLanguage.en: 'Save', AppLanguage.fr: 'Enregistrer'},
  'description_en': {AppLanguage.en: 'Description (English)', AppLanguage.fr: 'Description (anglais)'},
  'description_fr_label': {
    AppLanguage.en: 'Description (French)',
    AppLanguage.fr: 'Description (français)',
  },
  'choice_n': {AppLanguage.en: 'Choice', AppLanguage.fr: 'Choix'},
  'choice_text_en': {AppLanguage.en: 'Choice text (English)', AppLanguage.fr: 'Texte du choix (anglais)'},
  'choice_text_fr': {AppLanguage.en: 'Choice text (French)', AppLanguage.fr: 'Texte du choix (français)'},
  'destination_node': {AppLanguage.en: 'Destination node', AppLanguage.fr: 'Nœud de destination'},
  'add_choice': {AppLanguage.en: 'Add choice', AppLanguage.fr: 'Ajouter un choix'},
  'remove_choice': {AppLanguage.en: 'Remove choice', AppLanguage.fr: 'Supprimer le choix'},
  'advanced_options': {AppLanguage.en: 'Advanced options', AppLanguage.fr: 'Options avancées'},
  'requirements': {AppLanguage.en: 'Requirements to view this node', AppLanguage.fr: 'Conditions pour voir ce nœud'},
  'required_gold': {AppLanguage.en: 'Required gold', AppLanguage.fr: "Or requis"},
  'required_alignment': {
    AppLanguage.en: 'Required alignment score',
    AppLanguage.fr: "Score d'alignement requis",
  },
  'required_flags': {
    AppLanguage.en: 'Required flags (comma-separated)',
    AppLanguage.fr: 'Drapeaux requis (séparés par des virgules)',
  },
  'node_saved': {AppLanguage.en: 'Node saved.', AppLanguage.fr: 'Nœud enregistré.'},
  'reset_story': {AppLanguage.en: 'Reset story to defaults', AppLanguage.fr: "Réinitialiser l'histoire"},
  'reset_story_confirm': {
    AppLanguage.en: 'This discards all edits to the story text and reloads the bundled version.',
    AppLanguage.fr: "Ceci annule toutes les modifications du texte de l'histoire et recharge la version d'origine.",
  },
  'cancel': {AppLanguage.en: 'Cancel', AppLanguage.fr: 'Annuler'},
  'reset': {AppLanguage.en: 'Reset', AppLanguage.fr: 'Réinitialiser'},
  'close_legend': {AppLanguage.en: 'Close legend', AppLanguage.fr: 'Fermer la légende'},
  'show_legend': {AppLanguage.en: 'Show legend', AppLanguage.fr: 'Afficher la légende'},
  'map_theme_section': {AppLanguage.en: 'Map', AppLanguage.fr: 'Carte'},
  'map_theme_description': {
    AppLanguage.en:
        'The 5 main beats per chapter never change. This picks the flavor of the random '
        'encounters, shops, and quests generated between them.',
    AppLanguage.fr:
        'Les 5 étapes principales de chaque chapitre ne changent jamais. Ceci choisit '
        "l'ambiance des rencontres, boutiques et quêtes générées entre elles.",
  },
  'map_theme_ashen_streets': {
    AppLanguage.en: 'Ashen Streets',
    AppLanguage.fr: 'Rues de Cendre',
  },
  'map_theme_salt_roads': {AppLanguage.en: 'Salt Roads', AppLanguage.fr: 'Routes du Sel'},
  'map_theme_hollow_reaches': {
    AppLanguage.en: 'Hollow Reaches',
    AppLanguage.fr: 'Étendues Creuses',
  },
  'map_theme_wilds_beyond': {AppLanguage.en: 'Wilds Beyond', AppLanguage.fr: 'Terres Sauvages'},
};

/// Looks up [key] for a known [language] without needing a [WidgetRef] —
/// for use in callbacks (dialogs, bottom sheets) outside a widget's build.
String trFor(AppLanguage language, String key) {
  return _strings[key]?[language] ?? _strings[key]?[AppLanguage.en] ?? key;
}

String tr(WidgetRef ref, String key) => trFor(ref.watch(appLanguageProvider), key);
