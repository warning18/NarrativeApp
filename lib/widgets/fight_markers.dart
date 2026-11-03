// The fight screen's marks for the fight-length rules and the professions'
// cores (v1.368; fight_length.dart, profession_cores.dart): small, readable
// pieces the fight cards place where each rule acts.
import 'package:flutter/material.dart';

import '../combat/context_rules.dart';

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
