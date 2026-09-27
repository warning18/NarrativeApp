import '../models/story_node.dart';
import 'story_repository.dart';

/// Whether taking [choice] leads, within a scene or two, to a choice that
/// offers a quest the player hasn't taken on yet ([takenQuestIds]: active
/// or done). The story shows such a choice with a "work on offer" tag, so
/// the side jobs a hub's scenes hand out (the informant's tip, Tern Row's
/// toll, Liora's watch) are seen for what they are before a player walks
/// past them.
///
/// A hub (a place with many things to do, a settlement) isn't looked into:
/// a way back to one would otherwise be tagged for every job it holds,
/// and those show on its own choices there. The main quest
/// ([mainQuestIds]) isn't a side job: the story walks the player into it
/// whichever way they go.
bool questOfferedAhead({
  required StoryChoice choice,
  required StoryData story,
  required Set<String> takenQuestIds,
  Set<String> mainQuestIds = const {},
}) {
  bool offers(StoryChoice c) {
    final id = c.unlockQuestId;
    return id != null &&
        id.isNotEmpty &&
        !takenQuestIds.contains(id) &&
        !mainQuestIds.contains(id);
  }

  bool isHub(StoryNode node) =>
      node.choices.length > hubChoiceCount || node.settlement != null;

  if (offers(choice)) return true;
  var frontier = <String>{
    choice.nextId,
    if (choice.failNextId != null) choice.failNextId!,
  };
  final seen = <String>{};
  for (var depth = 0; depth < 2; depth++) {
    final next = <String>{};
    for (final id in frontier) {
      if (!seen.add(id)) continue;
      final node = story.nodeFor(id);
      if (node == null || isHub(node)) continue;
      for (final c in node.choices) {
        if (offers(c)) return true;
        next.add(c.nextId);
        if (c.failNextId != null) next.add(c.failNextId!);
      }
    }
    frontier = next;
  }
  return false;
}

/// The ids of [quests] (the quests table) that belong to the main quest.
Set<String> mainQuestIdsOf(Map<String, dynamic> quests) => {
      for (final entry in quests.entries)
        if ((entry.value as Map?)?['category']?.toString() == 'Main') entry.key,
    };

/// More choices than this make a node a hub (the story view's own rule).
const int hubChoiceCount = 5;
