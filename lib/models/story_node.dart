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
    this.triggerEnemyIds = const [],
    this.unlockShopId,
    this.unlockQuestId,
    this.opensCharacterCreation = false,
    this.textFr,
    this.lockedTextFr,
    this.checkAbility,
    this.checkDC,
    this.failNextId,
    this.loseNextId,
    this.challengeSuccessesNeeded,
    this.challengeMaxFailures,
    this.huntName,
    this.huntAffixes = const [],
    this.chestFloor,
    this.isHunterAmbush = false,
    this.hideIfFlags = const [],
    this.showIfFlags = const [],
    this.launchZoneId,
    this.grantsBannerPieceId,
    this.loseAllyId,
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
      triggerEnemyIds: (json['triggerEnemyIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unlockShopId: json['unlockShopId'] as String?,
      unlockQuestId: json['unlockQuestId'] as String?,
      opensCharacterCreation: json['opensCharacterCreation'] as bool? ?? false,
      textFr: json['text_fr'] as String?,
      lockedTextFr: json['lockedText_fr'] as String?,
      checkAbility: json['checkAbility'] as String?,
      checkDC: (json['checkDC'] as num?)?.toInt(),
      failNextId: json['failNextId'] as String?,
      loseNextId: json['loseNextId'] as String?,
      challengeSuccessesNeeded:
          (json['challengeSuccessesNeeded'] as num?)?.toInt(),
      challengeMaxFailures: (json['challengeMaxFailures'] as num?)?.toInt(),
      huntName: json['huntName'] as String?,
      huntAffixes:
          (json['huntAffixes'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      chestFloor: json['chestFloor'] as String?,
      isHunterAmbush: json['isHunterAmbush'] as bool? ?? false,
      launchZoneId: json['launchZoneId'] as String?,
      grantsBannerPieceId: json['grantsBannerPieceId'] as String?,
      loseAllyId: json['loseAllyId'] as String?,
      hideIfFlags:
          (json['hideIfFlags'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      showIfFlags:
          (json['showIfFlags'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
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

  /// A 2-3-id pack for a multi-enemy fight, coexisting with (never
  /// replacing) [triggerEnemyId] -- when non-empty, takes precedence (see
  /// [allTriggerEnemyIds]). Every existing single-enemy choice leaves this
  /// empty and is completely unaffected.
  final List<String> triggerEnemyIds;
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

  /// Where the story goes when this choice's fight is LOST: a defeat
  /// branch instead of a retry (the choice's own effects and unlocks are
  /// the winner's). Null keeps today's behavior, the fight can be retried.
  final String? loseNextId;

  bool get hasLossBranch => loseNextId != null && loseNextId!.isNotEmpty;

  /// Set alongside [checkAbility]/[checkDC] to turn a single roll into a
  /// "skill challenge": a sequence of rolls against the same ability and
  /// DC, won by reaching [challengeSuccessesNeeded] successes before
  /// [challengeMaxFailures] failures — a push-your-luck tension curve
  /// distinct from both a one-shot ability check (pass or fail on one
  /// roll) and full combat (health, dice faces, an enemy). Null/0 means
  /// this choice is an ordinary single-roll check.
  final int? challengeSuccessesNeeded;

  /// How many failed rolls the challenge tolerates before it's lost.
  /// Only meaningful alongside [challengeSuccessesNeeded].
  final int? challengeMaxFailures;

  /// Set on a generated hunt node's fight choice (see SubNodeEngine's hunt
  /// chain): the quarry's one-off display name. Alongside it,
  /// [huntAffixes] (EnemyAffix enum names forced onto that enemy) and
  /// [chestFloor] (a ChestTier asset name the spoils chest can't fall
  /// below). Never set on hand-authored story content.
  final String? huntName;
  final List<String> huntAffixes;
  final String? chestFloor;

  /// Set on a generated alignment-hunter ambush (see alignment_events.dart)
  /// so FightScreen applies that encounter's own reward/chest rules.
  final bool isHunterAmbush;

  /// The choice is not shown at all once the player holds ANY of these
  /// flags -- how a hub's activities are consumed: the activity's bridge
  /// node returns to the hub with a `flagsToAdd` marker, and the hub's
  /// choice carries the same marker here, so a market visit or a fight is
  /// offered once and then quietly leaves the list. Distinct from a
  /// locked choice (see [lockedText]), which stays visible as a reminder.
  final List<String> hideIfFlags;

  /// The choice is not shown until the player holds ALL of these flags --
  /// the mirror of [hideIfFlags], for a scene's second beat: "the deserter,
  /// later" appears on the hub only once the first visit's marker is set,
  /// and its own marker in [hideIfFlags] retires it in turn. Unlike a
  /// locked choice it leaves no trace until it is available.
  final List<String> showIfFlags;

  /// A piece of the Shroud this choice hands the player (see
  /// `PlayerSession.bannerPiecesCollected`): the origin epilogues grant the
  /// heirloom piece, and the spine's three dilemmas the rest.
  final String? grantsBannerPieceId;

  /// A companion this choice costs for good -- their id, or `*` for the
  /// first active ally (whoever steps forward). Nothing happens when the
  /// character walks alone; the choice's other costs still do.
  final String? loseAllyId;

  /// A zones.json id to run as an expedition BEFORE this choice resolves --
  /// a chapter's main zone launched from its story beat (the Drowned
  /// Stair, the Shroud's Vigil, Beyond the Tear). Clearing the zone
  /// continues to [nextId]; retreating or losing leaves the player on the
  /// node to try again. An already-cleared zone is skipped.
  final String? launchZoneId;

  bool get launchesZone => launchZoneId != null && launchZoneId!.isNotEmpty;

  bool isHiddenFor(Iterable<String> flags) =>
      hideIfFlags.any((flag) => flags.contains(flag)) ||
      showIfFlags.any((flag) => !flags.contains(flag));

  bool get hasAbilityCheck => checkAbility != null && checkAbility!.isNotEmpty;

  bool get hasSkillChallenge =>
      hasAbilityCheck &&
      (challengeSuccessesNeeded ?? 0) > 0 &&
      (challengeMaxFailures ?? 0) > 0;

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
        if (triggerEnemyIds.isNotEmpty) 'triggerEnemyIds': triggerEnemyIds,
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
        if (loseNextId != null && loseNextId!.isNotEmpty)
          'loseNextId': loseNextId,
        if (challengeSuccessesNeeded != null)
          'challengeSuccessesNeeded': challengeSuccessesNeeded,
        if (challengeMaxFailures != null)
          'challengeMaxFailures': challengeMaxFailures,
        if (huntName != null && huntName!.isNotEmpty) 'huntName': huntName,
        if (huntAffixes.isNotEmpty) 'huntAffixes': huntAffixes,
        if (chestFloor != null && chestFloor!.isNotEmpty)
          'chestFloor': chestFloor,
        if (isHunterAmbush) 'isHunterAmbush': isHunterAmbush,
        if (hideIfFlags.isNotEmpty) 'hideIfFlags': hideIfFlags,
        if (showIfFlags.isNotEmpty) 'showIfFlags': showIfFlags,
        if (launchesZone) 'launchZoneId': launchZoneId,
        if (grantsBannerPieceId != null && grantsBannerPieceId!.isNotEmpty)
          'grantsBannerPieceId': grantsBannerPieceId,
        if (loseAllyId != null && loseAllyId!.isNotEmpty)
          'loseAllyId': loseAllyId,
      };

  /// Every enemy id this choice triggers combat against -- [triggerEnemyIds]
  /// when set (a multi-enemy pack), otherwise [triggerEnemyId] wrapped as a
  /// single-item list, or empty if this choice doesn't trigger combat at
  /// all. The one place that resolves "which enemy/enemies" for a choice.
  List<String> get allTriggerEnemyIds {
    if (triggerEnemyIds.isNotEmpty) return triggerEnemyIds;
    if (triggerEnemyId != null && triggerEnemyId!.isNotEmpty) {
      return [triggerEnemyId!];
    }
    return const [];
  }

  bool get triggersCombat => allTriggerEnemyIds.isNotEmpty;

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
      (questIDToProgress != null && questIDToProgress!.isNotEmpty) ||
      (grantsBannerPieceId != null && grantsBannerPieceId!.isNotEmpty) ||
      (loseAllyId != null && loseAllyId!.isNotEmpty);
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
    this.authoringComment,
    this.alignmentEpilogues = const {},
    this.flagCallbacks = const [],
    this.personaVariants = const {},
    this.hubProgress,
    this.contextNote,
    this.contextNoteFr,
    this.settlement,
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
      authoringComment: json['authoring_comment'] as String?,
      alignmentEpilogues: _parseEpilogues(json['alignment_epilogues']),
      flagCallbacks: _parseCallbacks(json['flag_callbacks']),
      personaVariants: _parseLines(json['persona_variants']),
      hubProgress: HubProgress.fromJson(json['hub_progress']),
      settlement: Settlement.fromJson(json['settlement']),
    );
  }

  static List<FlagCallback> _parseCallbacks(Object? raw) {
    if (raw is! List) return const [];
    final out = <FlagCallback>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final flag = entry['flag']?.toString() ?? '';
      final en = entry['en']?.toString() ?? '';
      if (flag.isEmpty || en.isEmpty) continue;
      out.add(FlagCallback(
        flag: flag,
        line: NarrationLine(en: en, fr: entry['fr']?.toString()),
        unlessFlags: (entry['unlessFlags'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        andFlags:
            (entry['andFlags'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      ));
    }
    return out;
  }

  static Map<String, NarrationLine> _parseLines(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, NarrationLine>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final en = value['en']?.toString() ?? '';
      if (en.isEmpty) continue;
      out[entry.key.toString()] =
          NarrationLine(en: en, fr: value['fr']?.toString());
    }
    return out;
  }

  static Map<String, AlignmentEpilogue> _parseEpilogues(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, AlignmentEpilogue>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final en = value['en']?.toString() ?? '';
      if (en.isEmpty) continue;
      out[entry.key.toString()] =
          AlignmentEpilogue(en: en, fr: value['fr']?.toString());
    }
    return out;
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

  /// A free-text reviewer/authoring note attached to this node in Edit
  /// Mode — never shown to a player, purely so a note left while
  /// reading/testing ("pacing feels off here", "needs a 3rd choice") can be
  /// found again later via the Review Comments screen instead of relying
  /// on memory.
  final String? authoringComment;

  /// An extra closing paragraph shown under the node's text to a character
  /// of the matching alignment ('Good' / 'Neutral' / 'Evil') -- how the
  /// road looked from where they walked it. Authored on the endings; an
  /// unmatched or missing entry shows nothing.
  final Map<String, AlignmentEpilogue> alignmentEpilogues;

  /// The epilogue for [alignmentLabel], if this node has one.
  String? epilogueFor(String alignmentLabel, bool french) {
    final epilogue = alignmentEpilogues[alignmentLabel];
    if (epilogue == null) return null;
    return french && (epilogue.fr?.isNotEmpty ?? false)
        ? epilogue.fr
        : epilogue.en;
  }

  /// Paragraphs that only appear to a player who earned a given flag
  /// earlier -- how a scene remembers what the player did (sparing Tern
  /// Row, saving the Reckoning Wall, founding the camp). Shown under the
  /// body, in authored order.
  final List<FlagCallback> flagCallbacks;

  /// Sentences keyed `race:<raceId>` or `profession:<professionId>`, shown
  /// under the body to a character of that race or profession -- a stall
  /// keeper who reacts to an orc, a guard who has a word for mages.
  final Map<String, NarrationLine> personaVariants;

  /// For a hub node: a line that notes how the place has changed as its
  /// activities get done (see [HubProgress]).
  final HubProgress? hubProgress;

  /// Set on the story's town and camp nodes: the player arrives there
  /// (a pop-up says so), its shops and expeditions are listed as the
  /// place's own services, and the Town page is open only while there.
  final Settlement? settlement;

  /// Why a generated scene is happening, shown in the detour's context
  /// card above its text: a hunter's reason for coming, the job a stranger
  /// offers. Never authored in the story file (and never written back to
  /// it): only the excursion and alignment-event builders set it.
  final String? contextNote;
  final String? contextNoteFr;

  /// [contextNote] in the reader's language (English when French is
  /// missing), or null.
  String? contextNoteFor(bool fr) {
    final text = fr && (contextNoteFr?.isNotEmpty ?? false)
        ? contextNoteFr
        : contextNote;
    return (text?.isEmpty ?? true) ? null : text;
  }

  /// The callback paragraphs the player's [flags] have earned, in order.
  List<String> callbacksFor(Iterable<String> flags, bool french) {
    final held = flags.toSet();
    return [
      for (final callback in flagCallbacks)
        if (held.contains(callback.flag) &&
            !callback.unlessFlags.any(held.contains) &&
            callback.andFlags.every(held.contains))
          callback.line.textFor(french),
    ];
  }

  /// The persona sentences for this character, race first.
  List<String> personaLinesFor(
      {required String raceId,
      required String professionId,
      required bool french}) {
    return [
      for (final key in ['race:$raceId', 'profession:$professionId'])
        if (personaVariants[key] != null) personaVariants[key]!.textFor(french),
    ];
  }

  /// The hub's what-has-changed line for the player's [flags], if any.
  String? hubProgressLineFor(Iterable<String> flags, bool french) =>
      hubProgress?.lineFor(flags, french);

  String descriptionFor(bool french) =>
      french && (descriptionFr?.isNotEmpty ?? false)
          ? descriptionFr!
          : description;

  bool get hasComment => authoringComment?.isNotEmpty ?? false;

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
        if (authoringComment != null && authoringComment!.isNotEmpty)
          'authoring_comment': authoringComment,
        if (reqGold != 0) 'reqGold': reqGold,
        if (reqAlignmentScore != null) 'reqAlignmentScore': reqAlignmentScore,
        if (reqAlignmentMax != null) 'reqAlignmentMax': reqAlignmentMax,
        if (reqFlags.isNotEmpty) 'reqFlags': reqFlags,
        if (reqCharisma != 0) 'reqCharisma': reqCharisma,
        if (alignmentEpilogues.isNotEmpty)
          'alignment_epilogues': {
            for (final entry in alignmentEpilogues.entries)
              entry.key: {
                'en': entry.value.en,
                if (entry.value.fr != null && entry.value.fr!.isNotEmpty)
                  'fr': entry.value.fr,
              },
          },
        if (flagCallbacks.isNotEmpty)
          'flag_callbacks': [
            for (final callback in flagCallbacks)
              {
                'flag': callback.flag,
                ...callback.line.toJson(),
                if (callback.unlessFlags.isNotEmpty)
                  'unlessFlags': callback.unlessFlags,
                if (callback.andFlags.isNotEmpty) 'andFlags': callback.andFlags,
              },
          ],
        if (personaVariants.isNotEmpty)
          'persona_variants': {
            for (final entry in personaVariants.entries)
              entry.key: entry.value.toJson(),
          },
        if (hubProgress != null) 'hub_progress': hubProgress!.toJson(),
        if (settlement != null) 'settlement': settlement!.toJson(),
        'choices': choices.map((c) => c.toJson()).toList(),
      };
}

/// One bilingual sentence or paragraph of narration.
class NarrationLine {
  const NarrationLine({required this.en, this.fr});

  final String en;
  final String? fr;

  String textFor(bool french) => french && (fr?.isNotEmpty ?? false) ? fr! : en;

  Map<String, dynamic> toJson() => {
        'en': en,
        if (fr != null && fr!.isNotEmpty) 'fr': fr,
      };
}

/// A paragraph a node shows only to a player holding [flag] and every
/// [andFlags], and none of [unlessFlags] -- see [StoryNode.flagCallbacks].
class FlagCallback {
  const FlagCallback({
    required this.flag,
    required this.line,
    this.unlessFlags = const [],
    this.andFlags = const [],
  });

  final String flag;
  final NarrationLine line;

  /// Any of these held vetoes the paragraph.
  final List<String> unlessFlags;

  /// All of these must be held as well as [flag].
  final List<String> andFlags;
}

/// A hub's what-has-changed line: counts the player's flags starting with
/// [prefix] (the hub's own `hub_<id>_` activity markers) and shows the
/// line with the highest `after` threshold that count has reached.
/// A town or camp in the story (see [StoryNode.settlement]).
class Settlement {
  const Settlement({
    required this.kind,
    required this.name,
    this.nameFr,
    this.portId,
    this.landingPortId,
  });

  /// 'town' or 'camp'.
  final String kind;
  final String name;
  final String? nameFr;

  /// The ports.json row whose shops and expeditions this place offers, if
  /// any.
  final String? portId;

  /// The ports.json row where the Rusty Eel puts in for this place, when
  /// the voyage between it and the camp lands somewhere other than
  /// [portId] (a town whose expeditions the story launches itself offers
  /// no port services, but is still a voyage away).
  final String? landingPortId;

  bool get isCamp => kind == 'camp';

  String nameFor(bool french) =>
      french && (nameFr?.isNotEmpty ?? false) ? nameFr! : name;

  static Settlement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name']?.toString() ?? '';
    if (name.isEmpty) return null;
    final portId = raw['portId']?.toString() ?? '';
    final landingPortId = raw['landingPortId']?.toString() ?? '';
    return Settlement(
      kind: raw['kind']?.toString() == 'camp' ? 'camp' : 'town',
      name: name,
      nameFr: raw['name_fr']?.toString(),
      portId: portId.isEmpty ? null : portId,
      landingPortId: landingPortId.isEmpty ? null : landingPortId,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'name': name,
        if (nameFr != null && nameFr!.isNotEmpty) 'name_fr': nameFr,
        if (portId != null) 'portId': portId,
        if (landingPortId != null) 'landingPortId': landingPortId,
      };
}

class HubProgress {
  const HubProgress({required this.prefix, required this.lines});

  final String prefix;

  /// Ascending by [HubProgressLine.after].
  final List<HubProgressLine> lines;

  static HubProgress? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final prefix = raw['prefix']?.toString() ?? '';
    final lines = <HubProgressLine>[];
    for (final entry in (raw['lines'] as List?) ?? const []) {
      if (entry is! Map) continue;
      final en = entry['en']?.toString() ?? '';
      if (en.isEmpty) continue;
      lines.add(HubProgressLine(
        after: (entry['after'] as num?)?.toInt() ?? 1,
        line: NarrationLine(en: en, fr: entry['fr']?.toString()),
      ));
    }
    if (prefix.isEmpty || lines.isEmpty) return null;
    lines.sort((a, b) => a.after.compareTo(b.after));
    return HubProgress(prefix: prefix, lines: lines);
  }

  int doneCount(Iterable<String> flags) =>
      flags.where((f) => f.startsWith(prefix)).length;

  String? lineFor(Iterable<String> flags, bool french) {
    final done = doneCount(flags);
    HubProgressLine? best;
    for (final line in lines) {
      if (line.after <= done) best = line;
    }
    return best?.line.textFor(french);
  }

  Map<String, dynamic> toJson() => {
        'prefix': prefix,
        'lines': [
          for (final line in lines)
            {'after': line.after, ...line.line.toJson()},
        ],
      };
}

class HubProgressLine {
  const HubProgressLine({required this.after, required this.line});

  final int after;
  final NarrationLine line;
}

/// One alignment's closing paragraph on an ending node (see
/// [StoryNode.alignmentEpilogues]).
class AlignmentEpilogue {
  const AlignmentEpilogue({required this.en, this.fr});

  final String en;
  final String? fr;
}

/// Whether [node] is one of the story's endings: every way on from it ends
/// the story ("Begin again"), so the reader gets the ending screen -- the
/// run's recap, a fresh start and New Game+ -- instead of a choice that
/// quietly restarts.
bool isStoryEnding(StoryNode node) =>
    node.choices.isNotEmpty && node.choices.every((c) => c.isEnding);
