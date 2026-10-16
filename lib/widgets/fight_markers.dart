// The fight screen's marks for the fight-length rules and the professions'
// cores (v1.368; fight_length.dart, profession_cores.dart): small, readable
// pieces the fight cards place where each rule acts.
import 'package:flutter/material.dart';

import '../combat/context_rules.dart';

/// Fury as notches: [value] of [max] filled; when full the notches glow and
/// [readyLabel] says the next blow is the heavy one.
class FuryGauge extends StatelessWidget {
  const FuryGauge({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    required this.readyLabel,
    required this.tooltip,
  });

  final int value;
  final int max;
  final String label;
  final String readyLabel;
  final String tooltip;

  static const Color colour = Color(0xFFE0762B);

  @override
  Widget build(BuildContext context) {
    final full = value >= max;
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: colour)),
          const SizedBox(width: 4),
          for (var i = 0; i < max; i++)
            Container(
              key: Key('fury_notch_$i'),
              width: 11,
              height: 7,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i < value ? colour : colour.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
                boxShadow: full
                    ? [
                        BoxShadow(
                            color: colour.withValues(alpha: 0.7), blurRadius: 5)
                      ]
                    : null,
              ),
            ),
          if (full) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Text(readyLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colour)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Watchfire: a flame, the fire's worth, and a strip of how much of its
/// cap is lit (it takes blows first, and burns the enemy at the round's end).
class WatchfireMark extends StatelessWidget {
  const WatchfireMark({
    super.key,
    required this.fire,
    required this.cap,
    required this.label,
    required this.tooltip,
  });

  final int fire;
  final int cap;
  final String label;
  final String tooltip;

  static const Color colour = Color(0xFFF2A33A);

  @override
  Widget build(BuildContext context) {
    final share = cap <= 0 ? 0.0 : (fire / cap).clamp(0.0, 1.0);
    final lit = fire > 0;
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 15, color: lit ? colour : colour.withValues(alpha: 0.35)),
          const SizedBox(width: 2),
          Text(lit ? '$fire' : label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: lit ? colour : colour.withValues(alpha: 0.6))),
          const SizedBox(width: 4),
          Container(
            width: 34,
            height: 5,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: share,
              child: Container(
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small badge on a die: "×2" for a Flurry.
class DieBadge extends StatelessWidget {
  const DieBadge({super.key, required this.text, required this.tooltip});

  final String text;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
        decoration: BoxDecoration(
          color: const Color(0xFF17151B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF2C14E), width: 1),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF2C14E))),
      ),
    );
  }
}

/// What a fight's place rule (context_rules.dart) shows in a round: its
/// omen (the round before it starts), or how far it has risen.
class PlaceRuleStatus {
  const PlaceRuleStatus(this.stem, {required this.level, required this.omen});

  /// The rule's l10n stem (`mist`, `heat`, `water`, `holy`, `guards`).
  final String stem;

  /// How far it has risen (0 in its omen).
  final int level;

  /// The round before it starts.
  final bool omen;

  /// The rule at its highest (the water stops at [waterMaxLevel]).
  bool get maxed => stem == 'water' && level >= waterMaxLevel;

  @override
  bool operator ==(Object other) =>
      other is PlaceRuleStatus &&
      other.stem == stem &&
      other.level == level &&
      other.omen == omen;

  @override
  int get hashCode => Object.hash(stem, level, omen);
}

/// The mark of [rule] in [round], or null when it has nothing to say: the
/// Tide alone (it has its own mark), before the omen, or once the watch has
/// come (the fight is over by then).
PlaceRuleStatus? placeRuleStatus(ContextRule rule, int round) {
  final stem = rule.logStem;
  if (stem == null) return null;
  final start =
      rule == ContextRule.risingWater ? waterStartRound : risingStartRound;
  if (round == start - 1) return PlaceRuleStatus(stem, level: 0, omen: true);
  if (rule.guardsCome(round)) return null;
  final level = rule.levelAt(round);
  if (level <= 0) return null;
  return PlaceRuleStatus(stem, level: level, omen: false);
}

/// The icon and colour of a place rule's mark.
(IconData, Color) placeRuleLook(String stem) => switch (stem) {
      'mist' => (Icons.foggy, const Color(0xFF6E9E7A)),
      'heat' => (Icons.wb_sunny, const Color(0xFFD9822B)),
      'water' => (Icons.flood, const Color(0xFF3F8FB8)),
      'holy' => (Icons.church, const Color(0xFFC9A94E)),
      _ => (Icons.sports, const Color(0xFF8A8F9C)),
    };
