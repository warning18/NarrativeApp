// The People codex (v1.204): the npcs.json records read for the Other
// tab's "People" section and a person's page -- who they are (role,
// faction, place, kind), what they want, where they are met (`metNodes`,
// `metFlags`, a shop's `shopId`) and the `states` lines that remember what
// passed between them and the player.
//
// Discovery itself is `npcDiscovered` in quest_tracking.dart; this file
// reads the records around it.

import '../providers/player_session_provider.dart';
import 'quest_tracking.dart';

List<String> _stringList(Object? raw) => [
      for (final e in (raw as List?) ?? const [])
        if (e.toString().trim().isNotEmpty) e.toString().trim(),
    ];

/// The scenes meeting [npc]: once the story has stood in one, they are
/// known.
List<String> npcMetNodes(Map<String, dynamic> npc) =>
    _stringList(npc['metNodes']);

/// The flags meeting [npc]: once one is held, they are known.
List<String> npcMetFlags(Map<String, dynamic> npc) =>
    _stringList(npc['metFlags']);

/// The shop [npc] keeps ('' for none): once found, they are known.
String npcShopId(Map<String, dynamic> npc) =>
    npc['shopId']?.toString().trim() ?? '';

/// A record from before the codex (v1.204): no `metNodes`, `metFlags` or
/// `shopId`. Such a person is known by chapter and `requiredFlag` alone
/// (see npcDiscovered).
bool npcIsLegacy(Map<String, dynamic> npc) =>
    npcMetNodes(npc).isEmpty &&
    npcMetFlags(npc).isEmpty &&
    npcShopId(npc).isEmpty;

/// [npc]'s chapter (1 when unset).
int npcChapter(Map<String, dynamic> npc) =>
    (npc['chapter'] as num?)?.toInt() ?? 1;

/// [npc]'s [key] in [french] (its `_fr` twin when filled), else in
/// English; '' when the record has neither.
String npcText(Map<String, dynamic> npc, String key, bool french) {
  if (french) {
    final fr = npc['${key}_fr']?.toString() ?? '';
    if (fr.trim().isNotEmpty) return fr;
  }
  return npc[key]?.toString() ?? '';
}

/// What passed between [npc] and the player, in the record's order: every
/// `states` entry whose `flag` is held, whose `andFlags` are all held and
/// whose `unlessFlags` are none held (see FlagCallback in story_node.dart
/// for the same rule on a scene), its `line` (or `line_fr` in [french]).
List<String> npcStateLines(
    Map<String, dynamic> npc, Iterable<String> flags, bool french) {
  final held = flags is Set<String> ? flags : flags.toSet();
  final lines = <String>[];
  for (final raw in (npc['states'] as List?) ?? const []) {
    if (raw is! Map) continue;
    final state = raw.cast<String, dynamic>();
    final flag = state['flag']?.toString().trim() ?? '';
    if (flag.isEmpty || !held.contains(flag)) continue;
    if (!_stringList(state['andFlags']).every(held.contains)) continue;
    if (_stringList(state['unlessFlags']).any(held.contains)) continue;
    final line = npcText(state, 'line', french).trim();
    if (line.isNotEmpty) lines.add(line);
  }
  return lines;
}

/// The people of [records] the player knows (see npcDiscovered), in the
/// file's order.
List<String> discoveredNpcIds(
  Map<String, dynamic> records,
  PlayerSession session, {
  required int currentChapter,
  Iterable<String> visitedNodeIds = const [],
}) =>
    [
      for (final entry in records.entries)
        if (entry.value is Map<String, dynamic> &&
            npcDiscovered(entry.key, entry.value as Map<String, dynamic>,
                session, currentChapter,
                visitedNodeIds: visitedNodeIds))
          entry.key,
    ];

/// [npcIds] grouped by chapter, chapters in order, each group sorted by
/// id.
Map<int, List<String>> npcsByChapter(
    Iterable<String> npcIds, Map<String, dynamic> records) {
  final groups = <int, List<String>>{};
  for (final id in npcIds) {
    final npc = records[id];
    final chapter = npc is Map<String, dynamic> ? npcChapter(npc) : 1;
    (groups[chapter] ??= []).add(id);
  }
  final chapters = groups.keys.toList()..sort();
  return {
    for (final chapter in chapters) chapter: groups[chapter]!..sort(),
  };
}

/// How many of [discovered] the player has not looked at in the People
/// section yet (see PlayerSession.seenNpcIds).
int unseenNpcCount(Iterable<String> discovered, Iterable<String> seen) {
  final seenSet = seen is Set<String> ? seen : seen.toSet();
  return discovered.where((id) => !seenSet.contains(id)).length;
}
