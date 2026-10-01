import '../models/story_node.dart';
import 'echoes.dart';
import 'journey_rules.dart';

/// Scenes the story reads straight through.
///
/// A scene whose only way on is a plain "go on" (it may note what happened
/// in a flag, but costs, pays, rolls and fights nothing) is not a decision:
/// pressing its lone button only turns a page. The story plays such a
/// scene through as soon as it is reached: its text opens the next scene
/// (see [ScenePrelude]), its flags are set, and the party arrives at the
/// scene after in one step. At most [maxPassThrough] such scenes are read
/// together, so a page never runs on too long. A way on that crosses the
/// map is a step on the road (a ration, a watch, what the road holds), so
/// its scene is a stop.

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
    !choice.grantsItem &&
    (choice.loseAllyId ?? '').isEmpty &&
    (choice.roadEvent ?? '').isEmpty &&
    !choice.triggersShipBattle;

/// The lone plain way on out of [node] for a party holding [flags], or
/// null when [node] is a real stop: a place (town, camp, village), an
/// ending, a timed scene, a scene with more than one way on (hidden ones aside) or whose
/// one way on does more than move on, or takes the road to another place.
///
/// [hidden] says which choices are out of sight (v1.196: a politics gate
/// that fails, see choiceHiddenFor); by default, those [flags] hide.
StoryChoice? passThroughChoiceOf(StoryNode node, Iterable<String> flags,
    {bool Function(StoryChoice choice)? hidden}) {
  if (node.settlement != null || isStoryEnding(node)) return null;
  if (node.hubProgress != null || node.isTimed) return null;
  final held = flags.toSet();
  final ways = node.choices
      .where((c) => !(hidden?.call(c) ?? c.isHiddenFor(held)))
      .toList();
  if (ways.length != 1) return null;
  final way = ways.single;
  if (!isPlainGoOn(way) || isRoadStep(node.id, way.nextId)) return null;
  return way;
}

/// A scene read on the way to the next one, shown above it.
class ScenePrelude {
  const ScenePrelude({
    required this.nodeId,
    required this.body,
    this.echoes = const [],
    this.speaker,
  });

  final String nodeId;

  /// The scene as the player reads it (see composeNarrationParts), less
  /// the lines an earlier choice earned: those are its [echoes], each
  /// shown with the choice that earned it.
  final String body;
  final List<SceneEcho> echoes;

  /// Who speaks in it, when it is not the narrator.
  final String? speaker;

  /// The whole scene in one text, its echoes read inline (read aloud, and
  /// wherever they aren't shown apart).
  String get text => [body, for (final echo in echoes) echo.line].join('\n\n');
}
