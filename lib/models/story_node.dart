class StoryChoice {
  const StoryChoice({
    required this.text,
    required this.nextId,
    this.goldMod = 0,
    this.alignmentMod = 0,
    this.healAmount = 0,
    this.flagsToAdd = const [],
    this.questIDToProgress,
    this.lockedText,
    this.triggerEnemyId,
    this.unlockShopId,
    this.unlockQuestId,
    this.opensCharacterCreation = false,
    this.textFr,
    this.lockedTextFr,
    this.checkAbility,
    this.checkDC,
    this.failNextId,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'] as String? ?? '',
      nextId: (json['next_id'] ?? json['nextEventId'] ?? json['nextEventID'])
              as String? ??
          '',
      goldMod: (json['goldMod'] as num?)?.toInt() ?? 0,
      alignmentMod: (json['alignmentMod'] as num?)?.toInt() ?? 0,
      healAmount: (json['healAmount'] as num?)?.toInt() ?? 0,
      flagsToAdd:
          (json['flagsToAdd'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      questIDToProgress: json['questIDToProgress'] as String?,
      lockedText: json['lockedText'] as String?,
      triggerEnemyId: json['triggerEnemyId'] as String?,
      unlockShopId: json['unlockShopId'] as String?,
      unlockQuestId: json['unlockQuestId'] as String?,
      opensCharacterCreation: json['opensCharacterCreation'] as bool? ?? false,
      textFr: json['text_fr'] as String?,
      lockedTextFr: json['lockedText_fr'] as String?,
      checkAbility: json['checkAbility'] as String?,
      checkDC: (json['checkDC'] as num?)?.toInt(),
      failNextId: json['failNextId'] as String?,
    );
  }

  final String text;
  final String nextId;
  final int goldMod;
  final int alignmentMod;
  final int healAmount;
  final List<String> flagsToAdd;
  final String? questIDToProgress;
  final String? lockedText;
  final String? triggerEnemyId;
  final String? unlockShopId;
  final String? unlockQuestId;
  final bool opensCharacterCreation;

  /// Optional French translation of [text]; falls back to English when absent.
  final String? textFr;

  /// Optional French translation of [lockedText]; falls back to English when absent.
  final String? lockedTextFr;

  /// One of [abilityScoreKeys] (ability_check.dart) — when set, tapping
  /// this choice rolls a d20 + the player's bonus for that ability against
  /// [checkDC] before anything else happens, the BG3/D&D "attempt" pattern
  /// rather than a hard gate like [StoryNode.reqCharisma]. Kept as a plain
  /// string, not an enum, so this model (used by the offline
  /// graph-integrity tooling too) never needs to import gameplay code.
  final String? checkAbility;

  /// The difficulty class the roll must meet or beat. Only meaningful
  /// alongside [checkAbility].
  final int? checkDC;

  /// Where a failed check leads instead of [nextId]. Empty/null means a
  /// failure still proceeds to [nextId] as normal, just without this
  /// choice's [goldMod]/[alignmentMod]/[healAmount]/[flagsToAdd]/
  /// [questIDToProgress] applied — the "you tried, but gained nothing
  /// extra" outcome. Set it when failure should tell a genuinely different
  /// beat instead.
  final String? failNextId;

  bool get hasAbilityCheck => checkAbility != null && checkAbility!.isNotEmpty;

  String textFor(bool french) =>
      french && (textFr?.isNotEmpty ?? false) ? textFr! : text;

  String? lockedTextFor(bool french) =>
      french && (lockedTextFr?.isNotEmpty ?? false) ? lockedTextFr : lockedText;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (textFr != null && textFr!.isNotEmpty) 'text_fr': textFr,
        'next_id': nextId,
        if (goldMod != 0) 'goldMod': goldMod,
        if (alignmentMod != 0) 'alignmentMod': alignmentMod,
        if (healAmount != 0) 'healAmount': healAmount,
        if (flagsToAdd.isNotEmpty) 'flagsToAdd': flagsToAdd,
        if (questIDToProgress != null && questIDToProgress!.isNotEmpty)
          'questIDToProgress': questIDToProgress,
        if (lockedText != null && lockedText!.isNotEmpty)
          'lockedText': lockedText,
        if (lockedTextFr != null && lockedTextFr!.isNotEmpty)
          'lockedText_fr': lockedTextFr,
        if (triggerEnemyId != null && triggerEnemyId!.isNotEmpty)
          'triggerEnemyId': triggerEnemyId,
        if (unlockShopId != null && unlockShopId!.isNotEmpty)
          'unlockShopId': unlockShopId,
        if (unlockQuestId != null && unlockQuestId!.isNotEmpty)
          'unlockQuestId': unlockQuestId,
        if (opensCharacterCreation)
          'opensCharacterCreation': opensCharacterCreation,
        if (checkAbility != null && checkAbility!.isNotEmpty)
          'checkAbility': checkAbility,
        if (checkDC != null) 'checkDC': checkDC,
        if (failNextId != null && failNextId!.isNotEmpty)
          'failNextId': failNextId,
      };

  bool get triggersCombat =>
      triggerEnemyId != null && triggerEnemyId!.isNotEmpty;

  bool get hasUnlocks =>
      triggersCombat ||
      (unlockShopId != null && unlockShopId!.isNotEmpty) ||
      (unlockQuestId != null && unlockQuestId!.isNotEmpty);

  static const List<String> _endMarkers = ['EXIT', 'END'];

  bool get isEnding => _endMarkers.contains(nextId);

  bool get hasEffects =>
      goldMod != 0 ||
      alignmentMod != 0 ||
      healAmount != 0 ||
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
    this.reqAlignmentMax,
    this.reqFlags = const [],
    this.reqCharisma = 0,
    this.descriptionFr,
    this.uiTheme,
    this.mood,
    this.speaker,
    this.scriptTrigger,
  });

  factory StoryNode.fromJson(String id, Map<String, dynamic> json) {
    final choicesJson =
        (json['choices'] ?? json['possibleChoices']) as List<dynamic>? ??
            const [];
    final taxonomy = json['context_taxonomy'] as Map<String, dynamic>?;
    final automations = json['automations'] as Map<String, dynamic>?;
    return StoryNode(
      id: id,
      description: json['description'] as String? ?? '',
      choices: choicesJson
          .map((c) => StoryChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      reqGold: (json['reqGold'] as num?)?.toInt() ?? 0,
      reqAlignmentScore: (json['reqAlignmentScore'] as num?)?.toInt(),
      reqAlignmentMax: (json['reqAlignmentMax'] as num?)?.toInt(),
      reqFlags:
          (json['reqFlags'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      reqCharisma: (json['reqCharisma'] as num?)?.toInt() ?? 0,
      descriptionFr: json['description_fr'] as String?,
      uiTheme: taxonomy?['ui_theme'] as String?,
      mood: taxonomy?['mood'] as String?,
      speaker: taxonomy?['speaker'] as String?,
      scriptTrigger: automations?['script_trigger'] as String?,
    );
  }

  final String id;
  final String description;
  final List<StoryChoice> choices;
  final int reqGold;
  final int? reqAlignmentScore;

  /// Upper bound on alignment score, alongside [reqAlignmentScore] as the
  /// lower bound — together they express a stance band (e.g. a "neutral"
  /// path requiring an alignment score close to zero in either direction),
  /// not just a minimum threshold.
  final int? reqAlignmentMax;
  final List<String> reqFlags;

  /// Minimum charisma required to take this node's choice — the
  /// persuasion-flavored counterpart to [reqGold]'s "can you afford it"
  /// gate.
  final int reqCharisma;

  /// French translation of [description]; falls back to English if a node
  /// is ever added without one.
  final String? descriptionFr;

  /// The node's narrative setting (e.g. "docks", "cathedral") — used to pick
  /// a matching flavor for the procedural excursions generated after this
  /// node (see [mapThemeForUiTheme] in map_themes.dart) so wandering shops,
  /// enemies, and rest stops read consistently with the current scene.
  final String? uiTheme;

  /// The node's emotional tone (e.g. "tense", "grim"). Authoring metadata,
  /// not currently read by the app, but preserved so editing a node never
  /// silently discards it.
  final String? mood;

  /// Who is speaking this node's description (e.g. "Narrator", "Vane").
  /// Authoring metadata, not currently read by the app.
  final String? speaker;

  /// An authoring hook name for this node's on-load script, if any.
  /// Not currently read by the app.
  final String? scriptTrigger;

  String descriptionFor(bool french) =>
      french && (descriptionFr?.isNotEmpty ?? false)
          ? descriptionFr!
          : description;

  bool get hasRequirements =>
      reqGold > 0 ||
      reqAlignmentScore != null ||
      reqAlignmentMax != null ||
      reqFlags.isNotEmpty ||
      reqCharisma > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        if (descriptionFr != null && descriptionFr!.isNotEmpty)
          'description_fr': descriptionFr,
        if (uiTheme != null || mood != null || speaker != null)
          'context_taxonomy': {
            if (uiTheme != null) 'ui_theme': uiTheme,
            if (mood != null) 'mood': mood,
            if (speaker != null) 'speaker': speaker,
          },
        if (scriptTrigger != null && scriptTrigger!.isNotEmpty)
          'automations': {'script_trigger': scriptTrigger},
        if (reqGold != 0) 'reqGold': reqGold,
        if (reqAlignmentScore != null) 'reqAlignmentScore': reqAlignmentScore,
        if (reqAlignmentMax != null) 'reqAlignmentMax': reqAlignmentMax,
        if (reqFlags.isNotEmpty) 'reqFlags': reqFlags,
        if (reqCharisma != 0) 'reqCharisma': reqCharisma,
        'choices': choices.map((c) => c.toJson()).toList(),
      };
}
