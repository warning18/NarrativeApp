// The feature ladder (docs/proposals/feature-ladder.md, the user's call):
// chapters 1 and 2 bring the game's features one by one, each where the
// story gives it a reason, and each stays hidden until then.
//
// - A game on the ladder carries [featureLadderFlag] (a new game sets it).
//   A save from before the ladder, or a session made without it, has
//   every feature open, and nothing to acknowledge.
// - Each feature opens by its flag (Narrative's beats set it: `feat_*`),
//   or by what the character has done (the first fight won after the
//   lesson, level 2), and in any case once the story is past its chapter,
//   so a missed beat never locks it for good.
// - The UI shows a feature once [featureUnlocked] says so, and tells the
//   player of it once ([newlyUnlockedFeatures], then the session's
//   acknowledgeFeature).
//
// Pure; the session and the fight read it.

/// The flag a game on the ladder carries.
const String featureLadderFlag = 'feature_ladder';

/// A feature the ladder opens.
enum GameFeature {
  /// The spoils chest: the first fight won after the lesson (105).
  chest,

  /// The place's rule in a fight (the town guards, the mist...): from the
  /// fight after that one.
  placeRules,

  /// Battlefield conditions rolled in a fight: after the ambush at 1140.
  conditions,

  /// The level-up's training pick: level 2.
  levelUp,

  /// The Quests list: 250.
  quests,

  /// The Inventory page (and the dice loadout, the Shroud): 470.
  inventory,

  /// The Skills screen: the trainer (890_trainer).
  skills,

  /// Standing, and the Clans & Politics screen: 2005.
  politics,

  /// The clans' offers, signs and patrons: the Crow at the Wharf (2015).
  clans,
}

extension GameFeatureInfo on GameFeature {
  /// The id the UI keys its card and gate on.
  String get id => name;

  /// The story's flag that opens it, '' when it opens by deed alone.
  String get flag => switch (this) {
        GameFeature.chest => 'feat_chest',
        GameFeature.placeRules => 'feat_place_rules',
        GameFeature.conditions => 'feat_conditions',
        GameFeature.levelUp => '',
        GameFeature.quests => 'feat_quests',
        GameFeature.inventory => 'feat_inventory',
        GameFeature.skills => 'feat_skills',
        GameFeature.politics => 'feat_politics',
        GameFeature.clans => 'feat_clans',
      };

  /// The chapter it belongs to: open in any case once the story is past
  /// it.
  int get chapter => switch (this) {
        GameFeature.politics || GameFeature.clans => 2,
        _ => 1,
      };
}

GameFeature? gameFeatureNamed(String? id) =>
    GameFeature.values.where((f) => f.id == id).firstOrNull;

/// What the ladder reads of a session.
typedef LadderState = ({
  Iterable<String> flags,
  int level,

  /// The chapter the story has reached (the session's chapter turns).
  int chapter,
});

/// Whether [feature] is open in [state].
bool featureUnlocked(GameFeature feature, LadderState state) {
  final flags = state.flags;
  if (!flags.contains(featureLadderFlag)) return true;
  if (state.chapter > feature.chapter) return true;
  if (feature == GameFeature.levelUp) return state.level >= 2;
  return flags.contains(feature.flag);
}

/// Every open feature, in the ladder's order.
List<GameFeature> unlockedFeatures(LadderState state) => [
      for (final f in GameFeature.values)
        if (featureUnlocked(f, state)) f,
    ];

/// The features open and not yet told of ([acknowledged]: their ids), in
/// the ladder's order; none off the ladder.
List<GameFeature> newlyUnlockedFeatures(
        LadderState state, Iterable<String> acknowledged) =>
    !state.flags.contains(featureLadderFlag)
        ? const []
        : [
            for (final f in unlockedFeatures(state))
              if (!acknowledged.contains(f.id)) f,
          ];

/// The flags a won fight sets on the ladder ([tutorial]: the lesson,
/// which sets none): the chest's, then, a fight later, the place rules'.
List<String> ladderFlagsForWin(Iterable<String> flags,
    {required bool tutorial}) {
  if (tutorial || !flags.contains(featureLadderFlag)) return const [];
  if (!flags.contains(GameFeature.chest.flag)) {
    return [GameFeature.chest.flag];
  }
  if (!flags.contains(GameFeature.placeRules.flag)) {
    return [GameFeature.placeRules.flag];
  }
  return const [];
}

// --- The trainer (890_trainer) ----------------------------------------------

/// The flags the trainer's choices set: a strike, or a guard, learned.
const String trainerStrikeFlag = 'trainer_strike';
const String trainerGuardFlag = 'trainer_guard';

/// The skill the trainer teaches a character of [professionId] for
/// [strike] (else a guard): the first of its trees' skills (skill_trees.json,
/// in their order) it doesn't [known], with no prerequisite, that hits
/// (damage, no heal) for a strike and holds (a heal or a ward, no damage)
/// for a guard; null when none is left.
String? trainerSkillFor({
  required String professionId,
  required bool strike,
  required Map<String, dynamic> trees,
  required Map<String, dynamic> skills,
  Iterable<String> known = const [],
}) {
  final branches = [
    for (final t in trees.values)
      if (t is Map &&
          t['professionId'] == professionId &&
          (t['raceId']?.toString() ?? '').isEmpty)
        t,
  ]..sort((a, b) =>
      ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
  for (final branch in branches) {
    for (final id in (branch['skillIds'] as List?) ?? const []) {
      final skill = skills[id];
      if (skill is! Map || known.contains(id)) continue;
      if ((skill['requiredSkillID']?.toString() ?? '').isNotEmpty) continue;
      final damage = (skill['damageMod'] as num?) ?? 0;
      final heal = (skill['healAmount'] as num?) ?? 0;
      final hits = damage > 0 && heal == 0;
      final holds = heal > 0 || damage == 0;
      if (strike ? hits : holds && !hits) return id.toString();
    }
  }
  return null;
}
