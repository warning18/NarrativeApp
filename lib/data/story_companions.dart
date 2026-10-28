// The companions the story itself gives (v1.601, docs/proposals/
// guide-dog-companion.md §6): Vica, the tutorial's guide dog, joins every
// hero without a quest, at the first of her `joinNodeIds` the story reaches
// (her scene, else the White Wells for a save or a path that never saw it),
// and stays: a `permanent` companion never walks out at low approval, no
// `loseAllyId` takes her, and the party is never left empty while she is
// recruited (she sits down in it). Pure: the session and the simulator
// apply it.
import 'approval.dart';

/// Whether [record] (a companions.json entry) is given by the story.
bool isStoryRecruit(Map<String, dynamic>? record) =>
    record?['storyRecruit'] == true;

/// Whether [record] never leaves the roster (see the file's head).
bool isPermanentCompanion(Map<String, dynamic>? record) =>
    record?['permanent'] == true;

/// The scenes where [record] joins: the first one reached does.
List<String> joinNodeIdsOf(Map<String, dynamic>? record) => [
      for (final id in (record?['joinNodeIds'] as List?) ?? const [])
        id.toString(),
    ];

/// The story's companions due once the story has reached [visited]: those
/// of [companions] given by the story, one of whose join scenes is in
/// [visited], and not yet [recruited] (nor [gone]: departed or lost).
List<String> storyRecruitsDue(
  Map<String, dynamic> companions, {
  required Iterable<String> visited,
  required Iterable<String> recruited,
  Iterable<String> gone = const [],
}) {
  final seen = visited.toSet();
  final skip = {...recruited, ...gone};
  return [
    for (final entry in companions.entries)
      if (!skip.contains(entry.key) &&
          isStoryRecruit(entry.value as Map<String, dynamic>?) &&
          joinNodeIdsOf(entry.value as Map<String, dynamic>?)
              .any(seen.contains))
        entry.key,
  ];
}

/// [active] with a permanent companion of [recruited] seated when [active]
/// is empty (the first such one, in recruit order); else [active] as is.
List<String> withPermanentSeated(
  List<String> active, {
  required Iterable<String> recruited,
  required Map<String, dynamic> companions,
}) {
  if (active.isNotEmpty) return active;
  for (final id in recruited) {
    if (isPermanentCompanion(companions[id] as Map<String, dynamic>?)) {
      return [id];
    }
  }
  return active;
}

/// Whether [companionId] may leave the seated party [active]: anyone but a
/// permanent companion who is the last one seated (she is benched only by
/// seating someone else).
bool canBenchCompanion(
  String companionId, {
  required List<String> active,
  required Map<String, dynamic> companions,
}) =>
    !(isPermanentCompanion(companions[companionId] as Map<String, dynamic>?) &&
        active.where((id) => id != companionId).isEmpty);

/// The approval [record] ends at after [after]: a permanent companion
/// never falls to [leavingApproval] (she stays wary, never estranged).
int permanentApprovalFloor(Map<String, dynamic>? record, int after) =>
    isPermanentCompanion(record) && after <= leavingApproval
        ? leavingApproval + 1
        : after;

/// The companion a choice's `loseAllyId` takes from [active]: [loseAllyId]
/// itself, or the first seated for `*`; never a permanent one (null then).
String? storyLossOf(
  String? loseAllyId, {
  required List<String> active,
  required Map<String, dynamic> companions,
}) {
  if (loseAllyId == null || loseAllyId.isEmpty) return null;
  bool permanent(String id) =>
      isPermanentCompanion(companions[id] as Map<String, dynamic>?);
  if (loseAllyId == '*') {
    return active.where((id) => !permanent(id)).firstOrNull;
  }
  return permanent(loseAllyId) ? null : loseAllyId;
}
