import 'dice_faces.dart';

/// Loadout by situation (v1.213): before a fight the player may swap the
/// die they roll for another they own. These helpers say what a die would
/// bring against the enemies in front of them, so the choice is informed.

/// The elements the faces of a die can strike with: an Attack face's own,
/// and the element of the skill a Skill face (or a face the player set a
/// skill on, [assignments] keyed by face index) casts. 'None' is left out.
Set<String> dieElements(
  List<Map<String, dynamic>> faces,
  Map<String, String> assignments,
  Map<String, dynamic> skills,
) {
  final elements = <String>{};
  for (var i = 0; i < faces.length; i++) {
    final face = faces[i];
    final skillId = faceSkillId(face, assignments[i.toString()]);
    final skill = skillId == null ? null : skills[skillId];
    final element = skill is Map<String, dynamic>
        ? skill['element']?.toString()
        : face['type'] == 'Attack'
            ? face['element']?.toString()
            : null;
    if (element != null && element.isNotEmpty && element != 'None') {
      elements.add(element);
    }
  }
  return elements;
}

/// The elements of [weaknesses] a die with [elements] can hit, sorted.
List<String> weaknessesHit(Set<String> elements, Iterable<String> weaknesses) =>
    [
      for (final weakness in weaknesses.toSet())
        if (elements.contains(weakness)) weakness,
    ]..sort();
