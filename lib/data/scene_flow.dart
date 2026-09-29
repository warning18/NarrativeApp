import '../models/story_node.dart';

/// Scenes the story reads straight through.
///
/// A scene whose only way on is a plain "go on" (it may note what happened
/// in a flag, but costs, pays, rolls and fights nothing) is not a decision:
/// pressing its lone button only turns a page. The story plays such a
/// scene through as soon as it is reached: its text opens the next scene
/// (see [ScenePrelude]), its flags are set, and the party arrives at the
/// scene after in one step. At most [maxPassThrough] such scenes are read
/// together, so a page never runs on too long.

/// The most plain scenes folded into the one that follows them.
const int maxPassThrough = 2;

/// Whether [choice] only moves the story on: no gold, health, alignment,
/// approval, roll, fight, shop, quest, zone, voyage, piece or companion
/// change, and no ending. Flags it sets are carried along.
bool isPlainGoOn(StoryChoice choice) =>
    !choice.isEnding &&
    choice.nextId.isNotEmpty &&
    choice.goldMod == 0 &&
    choice.alignmentMod == 0 &&
    choice.healAmount == 0 &&
    choice.approvalMods.isEmpty &&
    !choice.triggersCombat &&
    !choice.hasAbilityCheck &&
    (choice.unlockShopId ?? '').isEmpty &&
    (choice.unlockQuestId ?? '').isEmpty &&
    (choice.questIDToProgress ?? '').isEmpty &&
    !choice.launchesZone &&
    !choice.mainQuest &&
    !choice.travels &&
    !choice.opensCharacterCreation &&
    (choice.grantsBannerPieceId ?? '').isEmpty &&
    (choice.loseAllyId ?? '').isEmpty &&
    (choice.roadEvent ?? '').isEmpty &&
    !choice.triggersShipBattle;

/// The lone plain way on out of [node] for a party holding [flags], or
/// null when [node] is a real stop: a place (town, camp, village), an
/// ending, a timed scene, a scene with more than one way on (hidden ones aside) or whose
/// one way on does more than move on.
StoryChoice? passThroughChoiceOf(StoryNode node, Iterable<String> flags) {
  if (node.settlement != null || isStoryEnding(node)) return null;
  if (node.hubProgress != null || node.isTimed) return null;
  final held = flags.toSet();
  final ways = node.choices.where((c) => !c.isHiddenFor(held)).toList();
  if (ways.length != 1) return null;
  final way = ways.single;
  return isPlainGoOn(way) ? way : null;
}

/// A scene read on the way to the next one, shown above it.
class ScenePrelude {
  const ScenePrelude({required this.nodeId, required this.text, this.speaker});

  final String nodeId;

  /// The scene as the player reads it (see composeNarration).
  final String text;

  /// Who speaks in it, when it is not the narrator.
  final String? speaker;
}
