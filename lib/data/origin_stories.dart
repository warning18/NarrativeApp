/// The five formative-memory prompts shown once, right after character
/// creation, before the story itself begins. Each is a short vignette with
/// three choices (good/evil/neutral) that shift the freshly-created
/// character's starting alignment score — so who the player already was
/// carries into the choices the main story then offers.
class OriginChoice {
  const OriginChoice({required this.textKey, required this.alignmentMod});

  /// Key into app_strings.dart (resolves both English and French).
  final String textKey;

  final int alignmentMod;
}

class OriginPrompt {
  const OriginPrompt({
    required this.titleKey,
    required this.descriptionKey,
    required this.choices,
  });

  final String titleKey;
  final String descriptionKey;
  final List<OriginChoice> choices;
}

const List<OriginPrompt> originStoryPrompts = [
  // Childhood 1: the injured bird.
  OriginPrompt(
    titleKey: 'origin_childhood_bird_title',
    descriptionKey: 'origin_childhood_bird_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_bird_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_bird_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_bird_neutral', alignmentMod: 0),
    ],
  ),
  // Childhood 2: the beggar's plea.
  OriginPrompt(
    titleKey: 'origin_childhood_beggar_title',
    descriptionKey: 'origin_childhood_beggar_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_beggar_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_beggar_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_beggar_neutral', alignmentMod: 0),
    ],
  ),
  // Teenage years 1: the bully.
  OriginPrompt(
    titleKey: 'origin_teen_bully_title',
    descriptionKey: 'origin_teen_bully_desc',
    choices: [
      OriginChoice(textKey: 'origin_teen_bully_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_teen_bully_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_teen_bully_neutral', alignmentMod: 0),
    ],
  ),
  // Teenage years 2: the broken vase.
  OriginPrompt(
    titleKey: 'origin_teen_vase_title',
    descriptionKey: 'origin_teen_vase_desc',
    choices: [
      OriginChoice(textKey: 'origin_teen_vase_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_teen_vase_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_teen_vase_neutral', alignmentMod: 0),
    ],
  ),
  // Teenage years 3: the cornered thief.
  OriginPrompt(
    titleKey: 'origin_teen_thief_title',
    descriptionKey: 'origin_teen_thief_desc',
    choices: [
      OriginChoice(textKey: 'origin_teen_thief_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_teen_thief_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_teen_thief_neutral', alignmentMod: 0),
    ],
  ),
];

/// Index into [originStoryPrompts] of the "beggar's plea" beat — the one
/// prompt slot that gets a profession-specific variant (see
/// [beggarPromptByProfession]) instead of the shared generic text.
const int beggarPromptSlotIndex = 1;

/// Profession-flavored variants of the beggar's-plea prompt: same beat, a
/// small reskin of the setting/object for warrior/mage/cleric/ranger, and a
/// genuinely different rigged-card-game scenario for rogue. Keyed by
/// professionID (professions.json). A profession missing here (including
/// none selected yet) falls back to the generic prompt at
/// [beggarPromptSlotIndex] — see [originPromptForSlot].
const Map<String, OriginPrompt> beggarPromptByProfession = {
  'warrior': OriginPrompt(
    titleKey: 'origin_childhood_beggar_warrior_title',
    descriptionKey: 'origin_childhood_beggar_warrior_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_beggar_warrior_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_beggar_warrior_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_beggar_warrior_neutral', alignmentMod: 0),
    ],
  ),
  'mage': OriginPrompt(
    titleKey: 'origin_childhood_beggar_mage_title',
    descriptionKey: 'origin_childhood_beggar_mage_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_beggar_mage_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_beggar_mage_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_beggar_mage_neutral', alignmentMod: 0),
    ],
  ),
  'rogue': OriginPrompt(
    titleKey: 'origin_childhood_beggar_rogue_title',
    descriptionKey: 'origin_childhood_beggar_rogue_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_beggar_rogue_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_beggar_rogue_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_beggar_rogue_neutral', alignmentMod: 0),
    ],
  ),
  'cleric': OriginPrompt(
    titleKey: 'origin_childhood_beggar_cleric_title',
    descriptionKey: 'origin_childhood_beggar_cleric_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_beggar_cleric_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_beggar_cleric_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_beggar_cleric_neutral', alignmentMod: 0),
    ],
  ),
  'ranger': OriginPrompt(
    titleKey: 'origin_childhood_beggar_ranger_title',
    descriptionKey: 'origin_childhood_beggar_ranger_desc',
    choices: [
      OriginChoice(textKey: 'origin_childhood_beggar_ranger_good', alignmentMod: 4),
      OriginChoice(textKey: 'origin_childhood_beggar_ranger_evil', alignmentMod: -4),
      OriginChoice(textKey: 'origin_childhood_beggar_ranger_neutral', alignmentMod: 0),
    ],
  ),
};

/// The prompt to show for slot [index] of [originStoryPrompts], given the
/// player's chosen [professionId] — the beggar slot swaps in that
/// profession's variant when one exists; every other slot (and an unknown
/// or empty professionId) just returns the shared generic prompt.
OriginPrompt originPromptForSlot(int index, String? professionId) {
  if (index == beggarPromptSlotIndex && professionId != null) {
    final variant = beggarPromptByProfession[professionId];
    if (variant != null) return variant;
  }
  return originStoryPrompts[index];
}
