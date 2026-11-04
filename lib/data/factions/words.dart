part of '../factions.dart';

// How standings and their causes read: formatStanding,
// formatStandingDelta, standingCauseLabel.

// --- The words ------------------------------------------------------------

/// A standing as shown: rounded, signed, with a true minus: "+31", "−14",
/// "0".
String formatStanding(num value) {
  final n = value.round();
  if (n > 0) return '+$n';
  if (n < 0) return '\u2212${-n}';
  return '0';
}

/// A change as shown, to the half where it has one: "+6", "+1.5", "−3".
String formatStandingDelta(num delta, {AppLanguage? language}) {
  final rounded = (delta * 10).round() / 10;
  final whole = rounded == rounded.roundToDouble();
  var digits = whole
      ? rounded.abs().round().toString()
      : rounded.abs().toStringAsFixed(1);
  if (language == AppLanguage.fr) digits = digits.replaceAll('.', ',');
  if (rounded > 0) return '+$digits';
  if (rounded < 0) return '\u2212$digits';
  return '0';
}

/// A cause as the log shows it. A cause is `kind` or `kind:detail`; a
/// kind with words (`standing_cause_<kind>`: offer, quest, favour,
/// intrigue, sea, edit, chapter, story, sworn_cap...) is said in
/// [language], the detail after it as written -- or as [describe] names
/// it (an offer's gift id read as the gift's name, see offers.dart), when
/// it gives a name; an unknown kind is shown as it is.
String standingCauseLabel(String cause, AppLanguage language,
    {String? Function(String kind, String detail)? describe}) {
  final split = cause.indexOf(':');
  final kind = split < 0 ? cause : cause.substring(0, split);
  final detail = split < 0 ? '' : cause.substring(split + 1).trim();
  final key = 'standing_cause_$kind';
  final label = trFor(language, key);
  final head = label == key ? kind : label;
  if (detail.isEmpty) return head;
  if (label == key) return cause;
  return '$head · ${describe?.call(kind, detail) ?? detail}';
}
