import 'dart:math';

/// The camp's fate die (v1.183): every night's rest at the camp rolls it,
/// and the camp gets a small story of its own between the chapter's
/// errands. Pure rules: what the die shows tonight, where it lands and
/// what each face asks or gives. The session applies the outcome (see
/// PlayerSessionNotifier.applyFateOutcome) and the camp shows it (see
/// camp_fate_dialog.dart).
enum FateFace {
  /// Gold found, or a cache of rations when the pack runs low.
  windfall,

  /// Someone at the fire, with a choice to make.
  visitor,

  /// Word of a place not found yet, which the map now shows.
  rumor,

  /// Two companions at odds: take a side, or try to make peace.
  quarrel,

  /// A thief in the night -- Perception to catch them.
  theft,

  /// Nothing happens, and that is a gift too.
  quiet,
}

/// The die's six faces, in the order they sit on it.
const List<FateFace> fateDieFaces = [
  FateFace.windfall,
  FateFace.visitor,
  FateFace.rumor,
  FateFace.quarrel,
  FateFace.theft,
  FateFace.quiet,
];

/// The camp as the die finds it.
class FateContext {
  const FateContext({
    required this.chapter,
    required this.gold,
    required this.provisions,
    required this.provisionsMax,
    required this.companionIds,
    required this.rumorPlaceIds,
  });

  final int chapter;
  final int gold;
  final int provisions;
  final int provisionsMax;

  /// The companions in the party tonight (the ones whose approval a night
  /// can move).
  final List<String> companionIds;

  /// The places a rumor could reveal: not found yet, in the chapter's
  /// reach.
  final List<String> rumorPlaceIds;
}

/// Whether [face] can happen at the camp as [context] finds it: a rumor
/// needs a place left to find, a quarrel two companions.
bool fateFaceAvailable(FateFace face, FateContext context) => switch (face) {
      FateFace.rumor => context.rumorPlaceIds.isNotEmpty,
      FateFace.quarrel => context.companionIds.length >= 2,
      _ => true,
    };

/// Tonight's die: [fateDieFaces] with each face that can't happen shown
/// as a quiet night instead, so the die never promises what it can't give.
List<FateFace> fateDieFor(FateContext context) => [
      for (final face in fateDieFaces)
        fateFaceAvailable(face, context) ? face : FateFace.quiet,
    ];

/// The random draw for the night of [day] in the run of [seed]: the same
/// night always rolls the same, so reloading a save doesn't roll again.
Random fateRandomFor(int seed, int day) => Random(seed * 7919 + day * 104729);

/// Who calls at the camp.
enum FateVisitor {
  /// Hungry pilgrims: share the rations, or send them on.
  pilgrims,

  /// A deserter from the Crusade: hide them, or hand them over for the
  /// bounty.
  deserter,

  /// An old storyteller who trades a tale for a seat by the fire.
  storyteller,
}

/// What two companions quarrel about.
const int fateQuarrelTopics = 4;

/// The quiet night's lines.
const int fateQuietLines = 3;

/// The gold a windfall brings in [chapter].
int windfallGold(int chapter) => 40 + 20 * max(1, chapter);

/// The rations a windfall brings when the pack is at half or less.
const int windfallRations = 4;

/// The Difficulty Class of catching the thief in [chapter] (Perception)
/// and of making peace in a quarrel (Charisma).
int fateCheckDc(int chapter) => 10 + max(1, chapter);

/// The gold a thief who isn't caught takes: a tenth of the purse, at most
/// 30 per chapter.
int theftGold({required int gold, required int chapter}) =>
    max(0, min(gold, min((gold * 0.1).round(), 30 * max(1, chapter))));

/// The ability each check of the night rolls.
const String theftCheckAbility = 'perception';
const String peaceCheckAbility = 'charisma';

/// The rations a thief takes from an empty purse.
const int theftRations = 2;

/// The rations shared with the pilgrims.
const int pilgrimRations = 2;

/// The bounty for handing the deserter over in [chapter].
int deserterBounty(int chapter) => 20 * max(1, chapter);

/// The approval a quarrel moves: [quarrelSideApproval] up for the one
/// sided with and down for the other, [quarrelPeaceApproval] both ways
/// for a peace made or failed.
const int quarrelSideApproval = 2;
const int quarrelPeaceApproval = 1;

/// The approval of each companion at the camp after the storyteller's
/// tale.
const int storytellerApproval = 1;

/// The alignment of the visitors' choices.
const int pilgrimShareAlignment = 3;
const int pilgrimRefuseAlignment = -1;
const int deserterHideAlignment = 2;
const int deserterHandOverAlignment = -3;

/// Where the die landed and what it drew with it.
class FateRoll {
  const FateRoll({
    required this.faceIndex,
    required this.face,
    this.visitor,
    this.quarrelers = const [],
    this.quarrelTopic = 0,
    this.placeId,
    this.quietLine = 0,
  });

  /// The face of [fateDieFor] it landed on.
  final int faceIndex;
  final FateFace face;

  /// Who calls, on a visitor.
  final FateVisitor? visitor;

  /// The two companions, on a quarrel.
  final List<String> quarrelers;
  final int quarrelTopic;

  /// The place revealed, on a rumor.
  final String? placeId;

  /// Which quiet-night line.
  final int quietLine;
}

/// Rolls tonight's die for [context].
FateRoll rollFate(FateContext context, Random random) {
  final die = fateDieFor(context);
  final index = random.nextInt(die.length);
  final face = die[index];
  switch (face) {
    case FateFace.visitor:
      return FateRoll(
        faceIndex: index,
        face: face,
        visitor: FateVisitor.values[random.nextInt(FateVisitor.values.length)],
      );
    case FateFace.quarrel:
      final pool = [...context.companionIds];
      final first = pool.removeAt(random.nextInt(pool.length));
      final second = pool[random.nextInt(pool.length)];
      return FateRoll(
        faceIndex: index,
        face: face,
        quarrelers: [first, second],
        quarrelTopic: random.nextInt(fateQuarrelTopics),
      );
    case FateFace.rumor:
      return FateRoll(
        faceIndex: index,
        face: face,
        placeId:
            context.rumorPlaceIds[random.nextInt(context.rumorPlaceIds.length)],
      );
    case FateFace.quiet:
      return FateRoll(
        faceIndex: index,
        face: face,
        quietLine: random.nextInt(fateQuietLines),
      );
    case FateFace.windfall:
    case FateFace.theft:
      return FateRoll(faceIndex: index, face: face);
  }
}

/// The choices a roll asks for. Windfall, rumor, theft and a quiet night
/// ask none: they simply happen (a theft rolls Perception on its own).
enum FateChoice {
  shareRations,
  sendOn,
  hideDeserter,
  handOver,
  listen,
  sendAway,
  sideWithFirst,
  sideWithSecond,
  makePeace,
}

/// The choices [roll] offers, in order.
List<FateChoice> fateChoicesFor(FateRoll roll) => switch (roll.face) {
      FateFace.visitor => switch (roll.visitor!) {
          FateVisitor.pilgrims => const [
              FateChoice.shareRations,
              FateChoice.sendOn,
            ],
          FateVisitor.deserter => const [
              FateChoice.hideDeserter,
              FateChoice.handOver,
            ],
          FateVisitor.storyteller => const [
              FateChoice.listen,
              FateChoice.sendAway,
            ],
        },
      FateFace.quarrel => const [
          FateChoice.sideWithFirst,
          FateChoice.sideWithSecond,
          FateChoice.makePeace,
        ],
      _ => const [],
    };

/// Whether [choice] can be taken with [context]: sharing takes the
/// rations.
bool fateChoiceOpen(FateChoice choice, FateContext context) =>
    choice != FateChoice.shareRations || context.provisions >= pilgrimRations;

/// What a night comes to: the changes the session applies.
class FateOutcome {
  const FateOutcome({
    this.gold = 0,
    this.provisions = 0,
    this.alignment = 0,
    this.approval = const {},
    this.revealPlaceId,
    this.checkRoll,
    this.checkPassed,
  });

  final int gold;
  final int provisions;
  final int alignment;

  /// Approval changes by companion id.
  final Map<String, int> approval;
  final String? revealPlaceId;

  /// The d20 total of a check (catching the thief, making peace), and
  /// whether it passed.
  final int? checkRoll;
  final bool? checkPassed;

  bool get isEmpty =>
      gold == 0 &&
      provisions == 0 &&
      alignment == 0 &&
      approval.isEmpty &&
      revealPlaceId == null;
}

/// What [roll] comes to with [choice] (null for a face that asks none).
/// [checkTotal] is the d20 total of the check the night calls for (the
/// thief's Perception, the peace's Charisma), rolled by the caller, and
/// [checkPassed] whether it passed (by default: [checkTotal] reaches
/// [fateCheckDc]).
FateOutcome fateOutcome(
  FateRoll roll,
  FateContext context, {
  FateChoice? choice,
  int? checkTotal,
  bool? checkPassed,
}) {
  bool passed(int total) =>
      checkPassed ?? total >= fateCheckDc(context.chapter);
  final chapter = context.chapter;
  switch (roll.face) {
    case FateFace.windfall:
      if (context.provisions * 2 <= context.provisionsMax) {
        return FateOutcome(
            provisions: min(
                windfallRations, context.provisionsMax - context.provisions));
      }
      return FateOutcome(gold: windfallGold(chapter));
    case FateFace.rumor:
      return FateOutcome(revealPlaceId: roll.placeId);
    case FateFace.quiet:
      return const FateOutcome();
    case FateFace.theft:
      final total = checkTotal ?? 0;
      if (passed(total)) {
        return FateOutcome(checkRoll: total, checkPassed: true);
      }
      final taken = theftGold(gold: context.gold, chapter: chapter);
      if (taken > 0) {
        return FateOutcome(gold: -taken, checkRoll: total, checkPassed: false);
      }
      return FateOutcome(
          provisions: -min(theftRations, context.provisions),
          checkRoll: total,
          checkPassed: false);
    case FateFace.visitor:
      return switch (choice) {
        FateChoice.shareRations => const FateOutcome(
            provisions: -pilgrimRations, alignment: pilgrimShareAlignment),
        FateChoice.sendOn =>
          const FateOutcome(alignment: pilgrimRefuseAlignment),
        FateChoice.hideDeserter =>
          const FateOutcome(alignment: deserterHideAlignment),
        FateChoice.handOver => FateOutcome(
            gold: deserterBounty(chapter),
            alignment: deserterHandOverAlignment),
        FateChoice.listen => FateOutcome(approval: {
            for (final id in context.companionIds) id: storytellerApproval,
          }),
        _ => const FateOutcome(),
      };
    case FateFace.quarrel:
      final first = roll.quarrelers.first;
      final second = roll.quarrelers.last;
      switch (choice) {
        case FateChoice.sideWithFirst:
          return FateOutcome(approval: {
            first: quarrelSideApproval,
            second: -quarrelSideApproval,
          });
        case FateChoice.sideWithSecond:
          return FateOutcome(approval: {
            first: -quarrelSideApproval,
            second: quarrelSideApproval,
          });
        case FateChoice.makePeace:
          final total = checkTotal ?? 0;
          final peace = passed(total);
          final delta = peace ? quarrelPeaceApproval : -quarrelPeaceApproval;
          return FateOutcome(
            approval: {first: delta, second: delta},
            checkRoll: total,
            checkPassed: peace,
          );
        default:
          return const FateOutcome();
      }
  }
}
