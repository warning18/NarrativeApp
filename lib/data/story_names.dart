// The names the story text colours (docs/proposals/story-markup.md), found
// in the game's own tables: the people (npcs.json, companions.json), the
// places (geography.json) and the clans (factions.json, subclans.json).
// Narrative does not mark them by hand.
import 'geography.dart';
import 'story_markup.dart';

/// Plain words that are also a clan's short name, and so are never
/// coloured on their own.
const Set<String> _storyNamesIgnore = {'Mire', 'Pit', 'Choir', 'Giants', 'Oni'};

final RegExp _article = RegExp(
    r"^(?:(?:The|A|An|Le|La|Les|Un|Une)\s+|L['’]\s*)(?=\S)",
    caseSensitive: false);

/// [name] without its article ("The Lantern Dominion" -> "Lantern
/// Dominion"), or null when the name is only a description of someone ("The
/// archivist", "A Crow with no name") and [people] says to skip those.
String? _clean(String name, {required bool people}) {
  final n = name.trim();
  if (n.length < 3) return null;
  final stripped = n.replaceFirst(_article, '');
  if (people && stripped != n) return null;
  return stripped.length < 3 ? null : stripped;
}

/// The matcher of the names in one language ([french] or not), from the raw
/// tables ([npcs], [companions], [factions], [subclans]) and the parsed
/// [geography].
StoryNameMatcher buildStoryNames({
  Map<String, dynamic> npcs = const {},
  Map<String, dynamic> companions = const {},
  Map<String, dynamic> factions = const {},
  Map<String, dynamic> subclans = const {},
  Geography? geography,
  bool french = false,
}) {
  final names = <String, StoryNameKind>{};
  String field(Map record, String key) {
    final fr = french ? record['${key}_fr']?.toString() ?? '' : '';
    return fr.isNotEmpty ? fr : record[key]?.toString() ?? '';
  }

  void add(String? name, StoryNameKind kind) {
    if (name == null || _storyNamesIgnore.contains(name)) return;
    // The first kind wins: a person before a place before a clan.
    names.putIfAbsent(name, () => kind);
  }

  for (final r in npcs.values) {
    if (r is Map) {
      add(_clean(field(r, 'npcName'), people: true), StoryNameKind.person);
    }
  }
  for (final r in companions.values) {
    if (r is Map) {
      add(_clean(r['companionName']?.toString() ?? '', people: true),
          StoryNameKind.person);
    }
  }
  if (geography != null) {
    for (final p in geography.places.values) {
      add(
          _clean(french && p.nameFr.isNotEmpty ? p.nameFr : p.name,
              people: false),
          StoryNameKind.place);
    }
  }
  for (final r in factions.values) {
    if (r is Map) {
      add(_clean(field(r, 'name'), people: false), StoryNameKind.clan);
      add(_clean(field(r, 'short'), people: false), StoryNameKind.clan);
    }
  }
  for (final r in subclans.values) {
    if (r is Map) {
      add(_clean(field(r, 'name'), people: false), StoryNameKind.clan);
    }
  }
  return StoryNameMatcher(names);
}
