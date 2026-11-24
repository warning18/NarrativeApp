// How the party came to stand where it does (v1.245): the Journey map keeps
// the party's mark on the world, and when the story carries it somewhere the
// player did not pick on the map (a fight lost, a roll failed, a jump from
// the travel list), the map walks it there by road and says why, instead of
// drawing the mark in the new place out of nowhere.
import '../models/story_node.dart';
import 'story_repository.dart';

/// Why the party is somewhere it did not choose to walk to.
enum PartyMoveCause {
  /// The fight of the choice taken was lost: its loseNextId.
  lost,

  /// The roll of the choice taken failed: its failNextId.
  failed,

  /// Neither: no choice of the last scene leads here (the travel list, the
  /// way back to camp, a save loaded).
  carried,
}

/// The way the story came from [previousId] to [currentId], or null when
/// one of the last scene's choices leads straight there (a way the player
/// took on the map: the party walked it).
PartyMoveCause? partyMoveCause(
    StoryData story, String? previousId, String currentId) {
  final previous = previousId == null ? null : story.nodeFor(previousId);
  if (previous == null) return PartyMoveCause.carried;
  var lost = false;
  var failed = false;
  for (final choice in previous.choices) {
    if (choice.nextId == currentId) return null;
    if (choice.loseNextId == currentId) lost = true;
    if (choice.failNextId == currentId) failed = true;
  }
  if (lost) return PartyMoveCause.lost;
  if (failed) return PartyMoveCause.failed;
  return PartyMoveCause.carried;
}

/// What the author wrote for the branch from [previousId] to [currentId]
/// (see StoryChoice.loseNote and failNote), or null.
String? partyMoveNote(StoryData story, String? previousId, String currentId,
    {required bool french}) {
  final previous = previousId == null ? null : story.nodeFor(previousId);
  if (previous == null) return null;
  // A way the player picked is no forced move, whatever else leads there.
  if (previous.choices.any((c) => c.nextId == currentId)) return null;
  for (final StoryChoice choice in previous.choices) {
    String? note;
    if (choice.loseNextId == currentId) note = choice.loseNoteFor(french);
    if ((note == null || note.isEmpty) && choice.failNextId == currentId) {
      note = choice.failNoteFor(french);
    }
    if (note != null && note.trim().isNotEmpty) return note.trim();
  }
  return null;
}
