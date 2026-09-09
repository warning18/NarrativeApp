class StoryChoice {
  const StoryChoice({
    required this.text,
    required this.nextId,
    this.goldMod = 0,
    this.alignmentMod = 0,
    this.flagsToAdd = const [],
    this.questIDToProgress,
    this.lockedText,
    this.triggerEnemyId,
    this.unlockShopId,
    this.unlockQuestId,
    this.opensCharacterCreation = false,
    this.textFr,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'] as String? ?? '',
      nextId: (json['next_id'] ?? json['nextEventId'] ?? json['nextEventID']) as String? ?? '',
      goldMod: (json['goldMod'] as num?)?.toInt() ?? 0,
      alignmentMod: (json['alignmentMod'] as num?)?.toInt() ?? 0,
      flagsToAdd:
          (json['flagsToAdd'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      questIDToProgress: json['questIDToProgress'] as String?,
      lockedText: json['lockedText'] as String?,
      triggerEnemyId: json['triggerEnemyId'] as String?,
      unlockShopId: json['unlockShopId'] as String?,
      unlockQuestId: json['unlockQuestId'] as String?,
      opensCharacterCreation: json['opensCharacterCreation'] as bool? ?? false,
      textFr: json['text_fr'] as String?,
    );
  }

  final String text;
  final String nextId;
  final int goldMod;
  final int alignmentMod;
  final List<String> flagsToAdd;
  final String? questIDToProgress;
  final String? lockedText;
  final String? triggerEnemyId;
  final String? unlockShopId;
  final String? unlockQuestId;
  final bool opensCharacterCreation;

  /// Optional French translation of [text]; falls back to English when absent.
  final String? textFr;

  String textFor(bool french) => french && (textFr?.isNotEmpty ?? false) ? textFr! : text;

  bool get triggersCombat => triggerEnemyId != null && triggerEnemyId!.isNotEmpty;

  bool get hasUnlocks =>
      triggersCombat ||
      (unlockShopId != null && unlockShopId!.isNotEmpty) ||
      (unlockQuestId != null && unlockQuestId!.isNotEmpty);

  static const List<String> _endMarkers = ['EXIT', 'END'];

  bool get isEnding => _endMarkers.contains(nextId);

  bool get hasEffects =>
      goldMod != 0 ||
      alignmentMod != 0 ||
      flagsToAdd.isNotEmpty ||
      (questIDToProgress != null && questIDToProgress!.isNotEmpty);
}

class StoryNode {
  const StoryNode({
    required this.id,
    required this.description,
    required this.choices,
    this.reqGold = 0,
    this.reqAlignmentScore,
    this.reqFlags = const [],
    this.descriptionFr,
  });

  factory StoryNode.fromJson(String id, Map<String, dynamic> json) {
    final choicesJson =
        (json['choices'] ?? json['possibleChoices']) as List<dynamic>? ?? const [];
    return StoryNode(
      id: id,
      description: json['description'] as String? ?? '',
      choices: choicesJson
          .map((c) => StoryChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      reqGold: (json['reqGold'] as num?)?.toInt() ?? 0,
      reqAlignmentScore: (json['reqAlignmentScore'] as num?)?.toInt(),
      reqFlags: (json['reqFlags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      descriptionFr: json['description_fr'] as String?,
    );
  }

  final String id;
  final String description;
  final List<StoryChoice> choices;
  final int reqGold;
  final int? reqAlignmentScore;
  final List<String> reqFlags;

  /// French translation of [description]; falls back to English if a node
  /// is ever added without one.
  final String? descriptionFr;

  String descriptionFor(bool french) =>
      french && (descriptionFr?.isNotEmpty ?? false) ? descriptionFr! : description;

  bool get hasRequirements =>
      reqGold > 0 || reqAlignmentScore != null || reqFlags.isNotEmpty;
}
