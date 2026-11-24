import '../l10n/app_locale.dart';

/// Numbers in descriptions that can't go stale (v1.462): a description may
/// write `{armor}`, `{dodge}%`, `{heal}`, `{multiplier}`... instead of the
/// number itself, and the placeholder is filled from the entry's own
/// numeric fields when the text is read, in English and in French alike.
/// The names each file offers are listed in docs/proposals/text-placeholders.md
/// (spells.json in spells.dart, item_sets.json in gear_effects.dart,
/// skills.json here, spec_variants.json in spec_variants.dart).
///
/// A placeholder the entry has no number for stays as written, braces and
/// all, so a misspelt one shows on screen (and the content test fails).

/// A placeholder: a name in braces, letters and digits only (`{dodge}`,
/// `{duration2}`). Anything else in braces is left alone.
final RegExp _placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9]*)\}');

/// [value] as a description shows it: a whole number without decimals, a
/// fraction with at most two (trailing zeros dropped), a French decimal
/// comma.
String formatPlaceholderNumber(num value, AppLanguage language) {
  String text;
  if (value is int || value == value.roundToDouble()) {
    text = '${value.round()}';
  } else {
    text = value.toStringAsFixed(2);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  }
  return language == AppLanguage.fr ? text.replaceAll('.', ',') : text;
}

/// [text] with each placeholder [values] knows replaced by its number
/// (see [formatPlaceholderNumber]); unknown ones stay as written.
String resolvePlaceholders(
    String text, Map<String, num> values, AppLanguage language) {
  if (!text.contains('{')) return text;
  return text.replaceAllMapped(_placeholderPattern, (match) {
    final value = values[match.group(1)!];
    return value == null
        ? match.group(0)!
        : formatPlaceholderNumber(value, language);
  });
}

/// The placeholders of [text] that [values] can't fill (for the content
/// test, and for the data editor to warn).
List<String> unresolvedPlaceholders(String text, Map<String, num> values) => [
      for (final match in _placeholderPattern.allMatches(text))
        if (!values.containsKey(match.group(1))) match.group(0)!,
    ];

/// A share written as a fraction (0.5) shown as a percent (50).
num percentOfShare(num share) {
  final percent = share * 100;
  return percent == percent.roundToDouble() ? percent.round() : percent;
}

/// skills.json's placeholders: the name a description writes -> the
/// record's field. Only the fields the record has are offered.
const Map<String, String> _skillPlaceholderFields = {
  'damage': 'damageMod',
  'multiplier': 'damageMultiplier',
  'heal': 'healAmount',
  'health': 'healthMod',
  'block': 'blockAmount',
  'cost': 'cost',
  'mana': 'manaGain',
  'rolls': 'bonusRolls',
  'strikes': 'strikes',
  'targets': 'splashTargets',
  'rally': 'rallyPercent',
  'charge': 'chargeMultiplier',
  'guard': 'guardMultiplier',
  'duration': 'statusDuration',
  'magnitude': 'statusMagnitude',
  'duration2': 'statusDuration2',
  'magnitude2': 'statusMagnitude2',
  'reflect': 'reflectMagnitude',
  'reflectDuration': 'reflectDuration',
};

/// skills.json's placeholders whose field is a share (0.5), shown as a
/// percent (`{splash}%` reads "50%").
const Map<String, String> _skillPercentPlaceholderFields = {
  'splash': 'splashShare',
  'armorShare': 'damageFromArmor',
};

/// The numbers a skills.json record's description may name (see
/// [_skillPlaceholderFields]).
Map<String, num> skillPlaceholderValues(Map<String, dynamic> skill) => {
      for (final MapEntry(:key, :value) in _skillPlaceholderFields.entries)
        if (skill[value] case final num number) key: number,
      for (final MapEntry(:key, :value)
          in _skillPercentPlaceholderFields.entries)
        if (skill[value] case final num number) key: percentOfShare(number),
    };
