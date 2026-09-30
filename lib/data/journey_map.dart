import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../models/story_node.dart';
import 'chapter_grid_layout.dart';

/// What a step on the Journey map holds, read off the choice that takes
/// it: its mark on the map and the word under it.
enum JourneyStepKind {
  /// The story's ending, or a new beginning.
  ending,

  /// A camp's main quest: the chapter's way on.
  mainQuest,

  /// An expedition into a zone.
  expedition,

  /// A fight.
  fight,

  /// A skill challenge (several rolls).
  challenge,

  /// One ability check.
  check,

  /// A shop opens.
  shop,

  /// Someone offers work.
  quest,

  /// A voyage to another place.
  travel,

  /// A rest that heals.
  rest,

  /// The road on, nothing more said.
  road,
}

/// The kind of step [choice] leads to. A choice that does several things
/// shows the one that matters most to the player: an ending or the main
/// quest first, then danger (an expedition, a fight, a roll), then what a
/// place offers.
JourneyStepKind journeyStepKindOf(StoryChoice choice) {
  if (choice.isEnding) return JourneyStepKind.ending;
  if (choice.mainQuest) return JourneyStepKind.mainQuest;
  if (choice.launchesZone) return JourneyStepKind.expedition;
  if (choice.triggersCombat || choice.triggersShipBattle) {
    return JourneyStepKind.fight;
  }
  if (choice.hasSkillChallenge) return JourneyStepKind.challenge;
  if (choice.hasAbilityCheck) return JourneyStepKind.check;
  if ((choice.unlockShopId ?? '').isNotEmpty) return JourneyStepKind.shop;
  if ((choice.unlockQuestId ?? '').isNotEmpty) return JourneyStepKind.quest;
  if (choice.travels) return JourneyStepKind.travel;
  if (choice.healAmount > 0) return JourneyStepKind.rest;
  return JourneyStepKind.road;
}

/// The most steps side by side in one row of the map.
const int journeyStepsPerRow = 3;

/// How many steps each row of the map holds, the row nearest the current
/// scene first: as few rows as [perRow] allows, filled as evenly as they
/// can be, the fuller rows nearest (5 steps: 3 then 2).
List<int> journeyRowSizes(int count, {int perRow = journeyStepsPerRow}) {
  if (count <= 0) return const [];
  final rows = (count + perRow - 1) ~/ perRow;
  final base = count ~/ rows;
  final extra = count % rows;
  return [for (var r = 0; r < rows; r++) base + (r < extra ? 1 : 0)];
}

/// Where one step sits on the map: its [row] away from the current scene
/// (0 the nearest) and [x], its centre across the map from 0 (left edge)
/// to 1 (right edge).
class JourneySlot {
  const JourneySlot({required this.row, required this.x});

  final int row;
  final double x;

  @override
  bool operator ==(Object other) =>
      other is JourneySlot && other.row == row && other.x == x;

  @override
  int get hashCode => Object.hash(row, x);

  @override
  String toString() => 'JourneySlot(row: $row, x: $x)';
}

/// The slots of [count] steps, in the order the choices come: rows as
/// [journeyRowSizes] gives them, each row's steps spread evenly across
/// the map. Rows after the first lean half a step to one side and then
/// the other, so a far row's steps sit between the nearer ones and the
/// roads to them pass through the gaps.
List<JourneySlot> journeySlots(int count, {int perRow = journeyStepsPerRow}) {
  final slots = <JourneySlot>[];
  final sizes = journeyRowSizes(count, perRow: perRow);
  for (var row = 0; row < sizes.length; row++) {
    final n = sizes[row];
    final lean = row == 0 ? 0.0 : (row.isOdd ? -0.5 : 0.5) / (n + 1);
    for (var i = 0; i < n; i++) {
      final x = (i + 1) / (n + 1) + lean;
      slots.add(JourneySlot(row: row, x: x.clamp(0.08, 0.92)));
    }
  }
  return slots;
}

/// A scene the party has passed through in this chapter, as the Journey
/// map draws it under the party: the scene, and the way taken out of it
/// (null when the story moved on some other way: a voyage, a jump).
class JourneyPastStep {
  const JourneyPastStep({required this.nodeId, this.wayTaken});

  final String nodeId;
  final StoryChoice? wayTaken;
}

/// The most scenes the Journey map keeps below the party.
const int journeyPastLimit = 40;

/// The scenes of the current chapter the party has come through, the
/// latest first: [history] read back from [currentNodeId] while its
/// scenes stay in the same chapter, a scene the story stayed on (a shop
/// visited from a town) counted once. Each carries the choice that led
/// on from it to the scene after, when one did.
({List<JourneyPastStep> steps, bool reachesStart}) journeyChapterPast({
  required List<String> history,
  required String currentNodeId,
  required StoryNode? Function(String id) nodeFor,
  int limit = journeyPastLimit,
}) {
  final chapter = chapterOfNode(currentNodeId);
  final steps = <JourneyPastStep>[];
  var next = currentNodeId;
  for (final id in history.reversed) {
    if (chapterOfNode(id) != chapter) {
      return (steps: steps, reachesStart: true);
    }
    if (id == next) continue;
    if (steps.length == limit) return (steps: steps, reachesStart: false);
    final node = nodeFor(id);
    StoryChoice? way;
    for (final choice in node?.choices ?? const <StoryChoice>[]) {
      if (choice.nextId == next ||
          choice.failNextId == next ||
          choice.loseNextId == next) {
        way = choice;
        break;
      }
    }
    steps.add(JourneyPastStep(nodeId: id, wayTaken: way));
    next = id;
  }
  return (steps: steps, reachesStart: true);
}

/// Where each way sits on the map of a place (v1.181), around the party
/// at [here] in an [area]. A way that leaves for another place ([bearings]
/// non-null: its true direction on the world chart, in radians, 0 east
/// and clockwise, as the chart's y runs down) sits near the map's edge
/// that way; ways out on (nearly) the same bearing, as when several
/// choices lead to the same place, are fanned out along the edge so each
/// can be tapped (see [fanOutBearings]). The rest -- a fight, a shop, a
/// talk in this place -- ring the
/// party: an inner ring, then an outer one, spread evenly and kept clear
/// of the ways out. Rings are ellipses, as the map is taller than wide.
List<Offset> journeyPlaceLayout({
  required Size area,
  required Offset here,
  required List<double?> bearings,
  double margin = 34,
  double footMargin = 86,
  int innerCapacity = 6,
}) {
  final positions = List<Offset>.filled(bearings.length, here);
  // The ways out: where their bearing meets the map's edge, just inside.
  final fanned = fanOutBearings(bearings);
  final exits = <double>[];
  for (var i = 0; i < fanned.length; i++) {
    final a = fanned[i];
    if (a == null) continue;
    exits.add(a);
    positions[i] = _toEdge(here, a, area, margin, footMargin);
  }
  final local = [
    for (var i = 0; i < bearings.length; i++)
      if (bearings[i] == null) i
  ];
  if (local.isEmpty) return positions;
  final inner = local.length <= innerCapacity + 1
      ? local
      : local.sublist(0, innerCapacity);
  final outer = local.length <= innerCapacity + 1
      ? const <int>[]
      : local.sublist(innerCapacity);
  final reachX = math.min(here.dx, area.width - here.dx) - margin;
  // Below the party the marks need room for their names.
  final reachY = math.min(here.dy - margin, area.height - here.dy - footMargin);
  void ring(List<int> ids, double fraction, double turn) {
    if (ids.isEmpty) return;
    final angles = _spreadAngles(ids.length, exits, turn);
    for (var k = 0; k < ids.length; k++) {
      positions[ids[k]] = here +
          Offset(math.cos(angles[k]) * reachX * fraction,
              math.sin(angles[k]) * reachY * fraction);
    }
  }

  ring(inner, outer.isEmpty ? 0.62 : 0.5, 0);
  ring(outer, 0.95, math.pi / outer.length.clamp(1, 99));
  return positions;
}

/// [bearings] with the ones closer than [spread] radians to each other
/// fanned out round their mean, [spread] apart, so no two ways out sit on
/// one spot. Nulls (ways in this place) stay null; the order is kept.
List<double?> fanOutBearings(List<double?> bearings, {double spread = 0.35}) {
  final order = [
    for (var i = 0; i < bearings.length; i++)
      if (bearings[i] != null) i
  ]..sort((a, b) => _norm(bearings[a]!).compareTo(_norm(bearings[b]!)));
  final out = List<double?>.of(bearings);
  var start = 0;
  while (start < order.length) {
    var end = start + 1;
    while (end < order.length &&
        _angleBetween(bearings[order[end]]!, bearings[order[end - 1]]!).abs() <
            spread) {
      end++;
    }
    final group = order.sublist(start, end);
    if (group.length > 1) {
      // The mean, measured from the group's first so a group across the
      // turn of the circle is not split.
      final first = bearings[group.first]!;
      final mean = first +
          group
                  .map((i) => _angleBetween(bearings[i]!, first))
                  .reduce((a, b) => a + b) /
              group.length;
      for (var k = 0; k < group.length; k++) {
        out[group[k]] = mean + (k - (group.length - 1) / 2) * spread;
      }
    }
    start = end;
  }
  return out;
}

/// [a] in [0, 2π).
double _norm(double a) => a % (2 * math.pi);

/// Where a ray from [from] at [angle] leaves [area] shrunk by [margin]
/// ([footMargin] at the foot, where names go under the marks).
Offset _toEdge(
    Offset from, double angle, Size area, double margin, double footMargin) {
  final dx = math.cos(angle), dy = math.sin(angle);
  var t = double.infinity;
  if (dx > 1e-6) t = math.min(t, (area.width - margin - from.dx) / dx);
  if (dx < -1e-6) t = math.min(t, (margin - from.dx) / dx);
  if (dy > 1e-6) t = math.min(t, (area.height - footMargin - from.dy) / dy);
  if (dy < -1e-6) t = math.min(t, (margin - from.dy) / dy);
  if (!t.isFinite || t < 0) t = 0;
  return from + Offset(dx * t, dy * t);
}

/// [count] angles evenly round a circle from straight up (plus [turn]),
/// each nudged off any of [avoid] (the ways out) it comes too near.
List<double> _spreadAngles(int count, List<double> avoid, double turn) {
  const clearance = 0.42;
  final step = 2 * math.pi / count;
  return [
    for (var k = 0; k < count; k++)
      () {
        var a = -math.pi / 2 + turn + k * step;
        for (final exit in avoid) {
          final d = _angleBetween(a, exit);
          if (d.abs() < clearance) {
            a += (d >= 0 ? 1 : -1) * (clearance - d.abs()).clamp(0.0, step / 2);
          }
        }
        return a;
      }(),
  ];
}

/// The signed turn from [b] to [a], in (-pi, pi].
double _angleBetween(double a, double b) {
  var d = (a - b) % (2 * math.pi);
  if (d > math.pi) d -= 2 * math.pi;
  return d;
}
