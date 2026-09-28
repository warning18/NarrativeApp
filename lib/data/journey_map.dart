import '../models/story_node.dart';

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
  if (choice.triggersCombat) return JourneyStepKind.fight;
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
