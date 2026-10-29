// The element a rolled face hits with (v1.613, the element dice): a Skill
// face casts its skill, so the skill's own element; a skill without one
// takes the face's, which on an elemental die is the die's element. Any
// other face hits with its own. Shared by the fight, the simulator and the
// loadout so they agree.

/// The element of a face of [type] whose own element is [faceElement],
/// casting [skill] (its skills.json record, or null) when it is a Skill
/// face. 'None' when nothing gives one.
String faceHitElement(String type, String faceElement, Object? skill) {
  if (type == 'Skill' && skill is Map<String, dynamic>) {
    final own = skill['element']?.toString() ?? 'None';
    if (own.isNotEmpty && own != 'None') return own;
  }
  return faceElement.isEmpty ? 'None' : faceElement;
}
