part of '../factions.dart';

// The sub-clan mark and relation rules: setSubclanMark, shiftRelation
// and the relations and standings read back by chapter.

class MarkResult {
  const MarkResult({required this.state, this.entry});

  final PoliticsState state;
  final StandingLogEntry? entry;

  bool get changed => entry != null;
}

/// [subclanId] marks the character [mark] (friend, none or foe), for
/// [cause], logged in the standing log under its clan.
MarkResult setSubclanMark(
  PoliticsState state,
  String subclanId,
  SubclanMark mark,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (subclanId.isEmpty || state.markOf(subclanId) == mark) {
    return MarkResult(state: state);
  }
  final marks = {...state.marks};
  if (mark == SubclanMark.none) {
    marks.remove(subclanId);
  } else {
    marks[subclanId] = mark;
  }
  final entry = StandingLogEntry(
    chapter: chapter,
    day: day,
    cause: cause,
    factionId: data.subclan(subclanId)?.clanId ?? '',
    subclanId: subclanId,
    mark: mark,
  );
  return MarkResult(
    state: state.copyWith(
      marks: marks,
      standingLog:
          _appendCapped(state.standingLog, entry, maxStandingLogEntries),
    ),
    entry: entry,
  );
}

/// What [shiftRelation] did: the [state] after, its log [entry] (null
/// when the pair didn't move) and, when the banner's caps took standing
/// off a new rival of the sworn faction, that [standing] change.
class RelationResult {
  const RelationResult({required this.state, this.entry, this.standing});

  final PoliticsState state;
  final RelationLogEntry? entry;
  final StandingLogEntry? standing;

  bool get changed => entry != null;
}

/// [a] and [b] move [steps] along the scale (negative: towards Blood
/// feud), within [minRelationStep]..[maxRelationStep], for [cause] on
/// [chapter]'s [day]. Logged, and the relations as they now stand kept
/// as [chapter]'s snapshot (see [relationsAtChapter]). A pair the data
/// doesn't relate starts from the middle step. While a faction is sworn,
/// a pair turned rival to it is capped at once.
RelationResult shiftRelation(
  PoliticsState state,
  String a,
  String b,
  int steps,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (a.isEmpty || b.isEmpty || a == b || steps == 0) {
    return RelationResult(state: state);
  }
  final from = state.relationStep(a, b, data) ?? 4;
  final to = (from + steps).clamp(minRelationStep, maxRelationStep);
  if (to == from) return RelationResult(state: state);
  final key = relationKey(a, b);
  final base = data.relations.baseSteps[key];
  final relationSteps = {...state.relationSteps};
  if (base == to) {
    relationSteps.remove(key);
  } else {
    relationSteps[key] = to;
  }
  final entry = RelationLogEntry(
      chapter: chapter, day: day, a: a, b: b, from: from, to: to, cause: cause);
  var next = state.copyWith(
    relationSteps: relationSteps,
    relationSnapshots: {...state.relationSnapshots, chapter: relationSteps},
    relationsLog:
        _appendCapped(state.relationsLog, entry, _maxRelationsLogEntries),
  );
  StandingLogEntry? standing;
  if (next.swornFactionId.isNotEmpty) {
    final before = _allStandings(next, data);
    final values = {...before};
    final banner = _applyBanner(values,
        sworn: next.swornFactionId,
        preferred: next.swornFactionId,
        state: next,
        data: data,
        chargeRivals: false);
    final capped = _commit(next, before, values,
        sworn: banner.sworn,
        swore: banner.swore,
        released: banner.released,
        factionId: next.swornFactionId,
        cause: 'sworn_cap',
        chapter: chapter,
        day: day);
    next = capped.state;
    standing = capped.entry;
  }
  return RelationResult(state: next, entry: entry, standing: standing);
}

/// Every related pair's step as it stood at [chapter], by [relationKey]:
/// the snapshot of the latest chapter up to it in which a pair moved,
/// over the steps the story opens on. A chapter past every snapshot reads
/// the relations as they stand now.
Map<String, int> relationsAtChapter(
    PoliticsState state, int chapter, ClanData data) {
  final base = data.relations.baseSteps;
  final earlier = [
    for (final c in state.relationSnapshots.keys)
      if (c <= chapter) c,
  ]..sort();
  final moved = earlier.isEmpty
      ? const <String, int>{}
      : state.relationSnapshots[earlier.last]!;
  return {...base, ...moved};
}

/// Every faction's standing after each entry of the standing log that
/// moved any, for the Evolution chart: index 0 is where they stood before
/// the first, then one map per such entry. Factions in [ids] only.
List<Map<String, double>> standingHistory(
    PoliticsState state, ClanData data, List<String> ids) {
  final moving = [
    for (final e in state.standingLog)
      if (e.deltas.isNotEmpty) e,
  ];
  // Where each stood before its first logged change: its value then, less
  // that change; one never logged stands where it stands now.
  final start = <String, double>{};
  for (final id in ids) {
    final first = moving.where((e) => e.after.containsKey(id)).firstOrNull;
    start[id] = first == null
        ? state.standingOf(id, data)
        : first.after[id]! - (first.deltas[id] ?? 0);
  }
  final history = <Map<String, double>>[start];
  var current = start;
  for (final e in moving) {
    current = {
      for (final id in ids) id: e.after[id] ?? current[id]!,
    };
    history.add(current);
  }
  return history;
}
