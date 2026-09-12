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
