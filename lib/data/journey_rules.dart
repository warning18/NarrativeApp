import 'dart:math' as math;

import 'world_map.dart';

/// The road's rules: provisions, days, the threat that grows while the
/// party lingers, and the sellswords it can hire. All of them start with
/// chapter 2, the first chapter with a town to buy from.

/// The first chapter the road's rules apply to.
const int roadRulesFromChapter = 2;

/// Provisions carried at most, and at the start.
const int provisionsMax = 12;
const int provisionsStart = 10;

/// Road steps in a day: every fourth step out on the road ends one.
const int stepsPerDay = 4;

/// With no provisions left, each step on the road costs this share of
/// the character's maximum health (never the last point).
const double hungerShare = 0.08;

/// Days a chapter can take before its enemies start to gather strength.
const int threatGraceDays = 6;

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

/// How much stronger enemies are after [daysInChapter] days in the
/// current chapter: nothing for the first [threatGraceDays], then
/// [threatPerDay] a day up to [threatMax].
double threatFor(int daysInChapter) =>
    (math.max(0, daysInChapter - threatGraceDays) * threatPerDay)
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
