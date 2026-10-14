// The People codex (v1.204): the npcs.json records read for the Other
// tab's "People" section and a person's page -- who they are (role,
// faction, place, kind), what they want, where they are met (`metNodes`,
// `metFlags`, a shop's `shopId`) and the `states` lines that remember what
// passed between them and the player.
//
// Discovery itself is `npcDiscovered` in quest_tracking.dart; this file
// reads the records around it.
//
// v1.210 ("Faces"): a `states` entry may also carry `conditions` in the
// politicsIf shape (standing, marks, a claim...), read in the coast's
// world; and the intrigues name their people (`npcId` on a stage or an
// outcome), listed on the person's page by npcIntrigueLines.

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart' show trFor;
import '../providers/player_session_provider.dart';
import 'factions.dart' show Intrigue, PoliticsState;
import 'politics_events.dart'
    show CoastWorld, intrigueOutcomeFlag, intrigueStageFlag, politicsIfHolds;
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

/// The `conditions` of a `states` entry (v1.210), in the politicsIf shape
/// (see politicsIfHolds): empty when it has none.
Map<String, dynamic> npcStateConditions(Map<String, dynamic> state) {
  final raw = state['conditions'];
  return raw is Map ? raw.cast<String, dynamic>() : const {};
}

/// What passed between [npc] and the player, in the record's order: every
/// `states` entry whose `flag` is held, whose `andFlags` are all held and
/// whose `unlessFlags` are none held (see FlagCallback in story_node.dart
/// for the same rule on a scene), its `line` (or `line_fr` in [french]).
///
/// (v1.210) An entry may carry `conditions` in the politicsIf shape
/// (standingAtLeast, marks, claim...): it shows only when they hold with
/// [politics] in [world], so never when either is not given. Its `flag`
/// may then be "" (no flag needed); an entry with neither a flag nor
/// conditions never shows.
List<String> npcStateLines(
  Map<String, dynamic> npc,
  Iterable<String> flags,
  bool french, {
  CoastWorld? world,
  PoliticsState? politics,
}) {
  final held = flags is Set<String> ? flags : flags.toSet();
  final lines = <String>[];
  for (final raw in (npc['states'] as List?) ?? const []) {
    if (raw is! Map) continue;
    final state = raw.cast<String, dynamic>();
    final flag = state['flag']?.toString().trim() ?? '';
    final conditions = npcStateConditions(state);
    if (flag.isEmpty && conditions.isEmpty) continue;
    if (flag.isNotEmpty && !held.contains(flag)) continue;
    if (!_stringList(state['andFlags']).every(held.contains)) continue;
    if (_stringList(state['unlessFlags']).any(held.contains)) continue;
    if (conditions.isNotEmpty) {
      if (world == null || politics == null) continue;
      if (!politicsIfHolds(conditions,
          politics: politics, flags: held, world: world)) {
        continue;
      }
    }
    final line = npcText(state, 'line', french).trim();
    if (line.isNotEmpty) lines.add(line);
  }
  return lines;
}

/// One line of a person's part in the intrigues (v1.210, see
/// npcIntrigueLines): the [intrigue]'s name, the [stage]'s name (or
/// "Outcome") and the stage's [text] (or the outcome's name), shown as
/// `<intrigue> · <stage>: <text>`.
typedef NpcIntrigueLine = ({String intrigue, String stage, String text});

/// [npc]'s id: the record's `npcID` (or `id`), '' when it has none.
String npcRecordId(Map<String, dynamic> npc) =>
    (npc['npcID'] ?? npc['id'])?.toString().trim() ?? '';

/// Where [npc] stands in the [intrigues] the story has reached, in the
/// records' order: every stage whose `npcId` is theirs and whose flag
/// `intrigue_<id>_stage_<n>` is held (n counting from 1), then every
/// outcome whose `npcId` is theirs and whose flag
/// `intrigue_<id>_outcome_<i>` is held (i counting from 0). The stage's
/// text (or the outcome's name) in [french] when written so.
List<NpcIntrigueLine> npcIntrigueLines(
  Map<String, dynamic> npc,
  Iterable<Intrigue> intrigues,
  Iterable<String> flags,
  bool french,
) {
  final id = npcRecordId(npc);
  if (id.isEmpty) return const [];
  final held = flags is Set<String> ? flags : flags.toSet();
  final language = french ? AppLanguage.fr : AppLanguage.en;
  final lines = <NpcIntrigueLine>[];
  for (final intrigue in intrigues) {
    for (final (i, stage) in intrigue.stages.indexed) {
      if (stage.npcId != id) continue;
      if (!held.contains(intrigueStageFlag(intrigue.id, i + 1))) continue;
      lines.add((
        intrigue: intrigue.nameFor(language),
        stage: trFor(language, stage.key),
        text: stage.textFor(language),
      ));
    }
    for (final (i, outcome) in intrigue.outcomes.indexed) {
      if (outcome.npcId != id) continue;
      if (!held.contains(intrigueOutcomeFlag(intrigue.id, i))) continue;
      lines.add((
        intrigue: intrigue.nameFor(language),
        stage: trFor(language, 'npc_intrigue_outcome'),
        text: outcome.nameFor(language),
      ));
    }
  }
  return lines;
}

/// [line] as the person's page shows it, `<intrigue> · <stage>: <text>`
/// (a no-break space before the colon in [french]).
String npcIntrigueLineText(NpcIntrigueLine line, bool french) =>
    '${line.intrigue} · ${line.stage}${french ? '\u00a0:' : ':'} ${line.text}';

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
