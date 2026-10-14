import 'dart:math';

import '../models/story_politics.dart';

/// One way to settle a quest when it's turned in (v1.163): keep the purse
/// or give it back, sell the list or guard it. A quest's `turnInChoices`
/// replaces its fixed reward with a decision; each choice sets its own
/// gold and alignment (the quest's own when left out), may set a story
/// flag, may move companions' approval (see approval.dart) and (v1.204)
/// may move the clans' [politics], written as a story choice's are. XP,
/// items, dice and companions come from the quest as usual.
class TurnInChoice {
  const TurnInChoice({
    required this.text,
    this.resultText = '',
    this.rewardGold,
    this.alignmentChange,
    this.flag = '',
    this.approvalMods = const {},
    this.politics,
  });

  factory TurnInChoice.fromJson(Map<String, dynamic> json) => TurnInChoice(
        text: json['choiceText']?.toString() ?? '',
        resultText: json['resultText']?.toString() ?? '',
        rewardGold: (json['rewardGold'] as num?)?.toInt(),
        alignmentChange: (json['alignmentChange'] as num?)?.toInt(),
        flag: json['flag']?.toString() ?? '',
        approvalMods: (json['approvalMods'] as Map?)?.map(
              (id, delta) =>
                  MapEntry(id.toString(), (delta as num?)?.toInt() ?? 0),
            ) ??
            const {},
        politics: StoryPolitics.tryParse(json['politics']),
      );

  final String text;

  /// A line on what came of it, shown with the rewards.
  final String resultText;
  final int? rewardGold;
  final int? alignmentChange;
  final String flag;
  final Map<String, int> approvalMods;

  /// What settling it this way moves among the clans (standing, marks...,
  /// see story_politics.dart), applied once at turn-in under
  /// `questTurnInPoliticsKey` and logged under `quest:<questId>`; null
  /// when the choice moves nothing.
  final StoryPolitics? politics;

  bool get hasPolitics => politics != null && !politics!.isEmpty;

  int goldFor(int questGold) => rewardGold ?? questGold;
  int alignmentFor(int questAlignment) => alignmentChange ?? questAlignment;

  /// Gold taken beyond the quest's own pay: what a companion who likes
  /// profit notices (the pay itself is just wages).
  int profitOver(int questGold) => max(0, goldFor(questGold) - questGold);
}

/// [quest]'s turn-in choices, in order; empty for a quest that simply pays.
List<TurnInChoice> turnInChoicesOf(Map<String, dynamic>? quest) => [
      for (final raw in (quest?['turnInChoices'] as List?) ?? const [])
        if (raw is Map<String, dynamic>) TurnInChoice.fromJson(raw),
    ];
