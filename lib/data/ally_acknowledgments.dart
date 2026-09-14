/// A brief, generic line appended to a handful of the story's biggest
/// combat-adjacent beats when the player has at least one active ally at
/// the moment they read it. Without this, "fighting alongside you" went
/// entirely unmentioned in the prose, even at climax fights a companion
/// could easily have been part of.
///
/// Deliberately generic — never names which companion — rather than
/// enumerating every possible active-party combination, and computed live
/// off the player's *current* party (see [withAllyAcknowledgment]'s
/// `hasActiveAlly` parameter) rather than a snapshot story flag, so it
/// always reflects who's active right now, including a party that changed
/// since the last camp visit.
const Map<String, String> _ackEn = {
  '4999': ' Whoever had come down into that cathedral at my back was still '
      'standing beside me when the dust settled, and I found — against '
      'every instinct three chapters like these should have taught me — '
      'that this mattered rather more than the victory itself.',
  '6004': " I was, at least, not the only one who heard it. Whoever had "
      "followed me this far into the dark heard it too, and a certainty "
      "like that, it turned out, weighed rather less when it wasn't mine "
      "alone to carry.",
};

const Map<String, String> _ackFr = {
  '4999': " Quiconque était descendu dans cette cathédrale à mes côtés se "
      "tenait encore debout près de moi une fois la poussière retombée, et "
      "je découvris — contre tout instinct que trois chapitres pareils "
      "auraient dû m'enseigner — que cela comptait bien davantage que la "
      "victoire elle-même.",
  '6004': " Je n'étais, du moins, pas seul à l'entendre. Quiconque m'avait "
      "suivi jusque dans cette obscurité l'entendit aussi, et une telle "
      "certitude, s'avéra-t-il, pesait nettement moins lorsqu'elle n'était "
      "pas mienne seule à porter.",
};

/// [description] with the ally acknowledgment appended, if [nodeId] has one
/// defined and [hasActiveAlly] is true; otherwise returns [description]
/// unchanged.
String withAllyAcknowledgment(
  String nodeId,
  String description, {
  required bool hasActiveAlly,
  required bool french,
}) {
  if (!hasActiveAlly) return description;
  final addition = (french ? _ackFr : _ackEn)[nodeId];
  return addition == null ? description : '$description$addition';
}
