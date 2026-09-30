import 'dart:math' as math;

import 'world_map.dart';

/// The road's rules: provisions, days, the threat that grows while the
/// party lingers, and the sellswords it can hire. All of them start with
/// chapter 2, the first chapter with a town to buy from.

/// The first chapter the road's rules apply to.
const int roadRulesFromChapter = 2;

/// Provisions carried at most, and at the start. The crew eats one a day
/// at sea too (v1.187), so a long crossing wants a full pack: in the
/// simulator, a party that tops the pack up before it sails goes hungry
/// now and then; one that never looks at it, often.
const int provisionsMax = 8;
const int provisionsStart = 8;

/// Watches in a day (dawn, day, dusk, night). A step on the road is a
/// watch, so four steps from dawn end the day.
const int watchesPerDay = 4;

/// Watches a walk between two places takes (the camp and its places, see
/// camp_travel.dart): two steps' worth, for one ration.
const int walkWatches = 2;

/// With no provisions left, each step on the road costs this share of
/// the character's maximum health (never the last point).
const double hungerShare = 0.08;

/// Days a chapter can take before its enemies start to gather strength
/// (see [threatGraceDaysFor]).
const int threatGraceDays = 6;

/// The open chapters' grace: their places lie across the sea, and every
/// voyage takes days, so a party that sails to each of them once would
/// otherwise meet stronger enemies for going where the chapter sends it.
/// Measured with the playthrough simulator (v1.187, one world clock): a
/// party that does everything a chapter holds spends about 8 days in
/// chapter 3, 33 in chapters 4 and 5 and 43 in chapter 6; past these
/// graces, the lingering shows. The ending (chapter 7) is one crossing
/// of four days, the tear and a night or two at the camp.
const Map<int, int> _threatGraceByChapter = {
  3: 8,
  4: 28,
  5: 28,
  6: 36,
  7: 12,
};

/// Days [chapter] can take before its enemies start to gather strength.
int threatGraceDaysFor(int chapter) =>
    _threatGraceByChapter[chapter] ?? threatGraceDays;

/// How much stronger (health and damage) enemies get per day past the
/// grace, and at most.
const double threatPerDay = 0.03;
const double threatMax = 0.30;

/// Fights a sellsword's contract covers.
const int sellswordContractFights = 3;

/// Whether the road's rules apply in [chapter].
bool roadRulesApply(int chapter) => chapter >= roadRulesFromChapter;

/// Whether going from scene [from] to scene [to] crosses the map: a step
/// on the road between two places, not a move within one.
bool isRoadStep(String from, String to) {
  if (from == to) return false;
  final a = landmarkOfScene(from);
  final b = landmarkOfScene(to);
  if (a == null || b == null) return false;
  return a.id != b.id;
}

/// What one ration costs in [chapter].
int provisionPrice(int chapter) => 4 + 2 * math.max(chapter, 1);

/// What a sellsword's contract costs in [chapter].
int sellswordPrice(int chapter) => 120 + 80 * math.max(chapter, 1);

/// The damage a sellsword deals each round in [chapter].
int sellswordDamage(int chapter) => 5 + 3 * math.max(chapter, 1);

/// What hunger costs a character of [maxHealth] at [health]: never the
/// last point.
int hungerDamage({required int health, required int maxHealth}) {
  final bite = math.max(1, (maxHealth * hungerShare).round());
  return math.max(0, math.min(bite, health - 1));
}

/// How much stronger enemies are after [daysInChapter] days in
/// [chapter]: nothing for its grace (see [threatGraceDaysFor]), then
/// [threatPerDay] a day up to [threatMax].
double threatFor(int daysInChapter, {required int chapter}) =>
    (math.max(0, daysInChapter - threatGraceDaysFor(chapter)) * threatPerDay)
        .clamp(0.0, threatMax);

/// What one step on the road did (see PlayerSessionNotifier.takeRoadStep).
class RoadStep {
  const RoadStep({
    this.counted = false,
    this.hungry = false,
    this.hunger = 0,
    this.dayEnded = false,
    this.day = 0,
    this.provisionsLeft = 0,
  });

  /// False where the road's rules don't apply yet (chapter 1).
  final bool counted;

  /// No ration was left to eat, and the health it cost.
  final bool hungry;
  final int hunger;

  /// The step ended the day; [day] is the day it is now.
  final bool dayEnded;
  final int day;

  final int provisionsLeft;
}
