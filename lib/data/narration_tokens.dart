// Narration that knows who is reading it: `{name}`, `{race}`,
// `{profession}` and `{companion}` tokens in a story node's text are
// filled from the session at render time (see [personalizeNarration]),
// and a node's `speaker` gets a display label in either language (see
// [speakerLabelFor]).

/// English and French nouns for each race and profession id -- the
/// gamedata records only carry an English display name.
const Map<String, ({String en, String fr})> _raceNouns = {
  'human': (en: 'human', fr: 'humain'),
  'elf': (en: 'elf', fr: 'elfe'),
  'dwarf': (en: 'dwarf', fr: 'nain'),
  'orc': (en: 'orc', fr: 'orc'),
  'voidkin': (en: 'voidkin', fr: 'enfant du Néant'),
};

const Map<String, ({String en, String fr})> _professionNouns = {
  'warrior': (en: 'warrior', fr: 'guerrier'),
  'mage': (en: 'mage', fr: 'mage'),
  'rogue': (en: 'rogue', fr: 'voleur'),
  'cleric': (en: 'cleric', fr: 'clerc'),
  'ranger': (en: 'ranger', fr: 'rôdeur'),
};

String raceNounFor(String raceId, {required bool french}) {
  final noun = _raceNouns[raceId];
  if (noun == null) {
    return raceId.isEmpty ? (french ? 'inconnu' : 'stranger') : raceId;
  }
  return french ? noun.fr : noun.en;
}

String professionNounFor(String professionId, {required bool french}) {
  final noun = _professionNouns[professionId];
  if (noun == null) {
    return professionId.isEmpty
        ? (french ? 'vagabond' : 'wanderer')
        : professionId;
  }
  return french ? noun.fr : noun.en;
}

/// How each race wears its power -- the `{sigil}` token. Mirrors
/// races.json's `powerMedium` (the story data is the reference; this is
/// the render-time lookup).
const Map<String, ({String en, String fr})> _powerMedia = {
  'human': (en: 'banner', fr: 'bannière'),
  'elf': (en: 'painted sigil', fr: 'sigil peint'),
  'dwarf': (en: 'stone-mark', fr: 'marque de pierre'),
  'orc': (en: 'ink', fr: 'encre'),
  'voidkin': (en: 'void-mark', fr: 'marque du Néant'),
};

String powerMediumFor(String raceId, {required bool french}) {
  final medium = _powerMedia[raceId];
  if (medium == null) return french ? 'marque' : 'mark';
  return french ? medium.fr : medium.en;
}

bool hasNarrationTokens(String text) => text.contains('{');

/// [text] with every `{name}`, `{race}`, `{profession}`, `{companion}` and
/// `{sigil}` (the race's power medium) filled in. An unnamed character reads as "stranger"; a party with no
/// companion reads `{companion}` as "no one" -- authored lines that name a
/// companion should sit behind a companion acknowledgment instead (see
/// ally_acknowledgments.dart), this is only the safety net.
String personalizeNarration(
  String text, {
  required String name,
  required String raceId,
  required String professionId,
  String? companionName,
  required bool french,
}) {
  if (!hasNarrationTokens(text)) return text;
  final displayName =
      name.trim().isEmpty ? (french ? "l'étranger" : 'stranger') : name.trim();
  final companion = (companionName?.trim().isNotEmpty ?? false)
      ? companionName!.trim()
      : (french ? 'personne' : 'no one');
  return text
      .replaceAll('{name}', displayName)
      .replaceAll('{race}', raceNounFor(raceId, french: french))
      .replaceAll(
          '{profession}', professionNounFor(professionId, french: french))
      .replaceAll('{companion}', companion)
      .replaceAll('{sigil}', powerMediumFor(raceId, french: french));
}

/// Display labels for the `speaker` values authored on story nodes -- a
/// node voiced by someone other than the Narrator shows this above its
/// text. Unknown speakers show as written.
const Map<String, ({String en, String fr})> _speakerLabels = {
  'Archivist': (en: 'The Archivist', fr: "L'Archiviste"),
  'Chart-keeper': (en: 'The Chart-keeper', fr: 'La Gardienne des cartes'),
  'The Sovereign': (en: 'The Sovereign', fr: 'Le Souverain'),
  'Lysa': (en: 'Lysa', fr: 'Lysa'),
  'Vane': (en: 'Vane', fr: 'Vane'),
  'Deserter': (en: 'The Deserter', fr: 'Le Déserteur'),
  'Penitent': (en: 'The Penitent Inquisitor', fr: "L'Inquisiteur pénitent"),
  'Lantern-keeper': (
    en: 'The Lantern-keeper',
    fr: 'La Gardienne de la Lanterne'
  ),
};

/// Null for the Narrator (or no speaker at all): the plain card needs no
/// label.
String? speakerLabelFor(String? speaker, {required bool french}) {
  if (speaker == null || speaker.isEmpty || speaker == 'Narrator') return null;
  final label = _speakerLabels[speaker];
  if (label == null) return speaker;
  return french ? label.fr : label.en;
}
