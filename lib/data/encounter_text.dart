/// The words a random fight comes with: who the enemy is
/// (`description`), how it turns up and why it attacks (`encounterText`,
/// or `packText` when it leads a pack), and the roster a fight button names
/// ("Street Bandit ×2, Harbor Rat"). All read from enemies.json, so a new
/// enemy brings its own narration as data.
library;

/// A line in both languages.
typedef Bilingual = ({String en, String fr});

/// The enemies of [ids] by name, duplicates counted and first-seen order
/// kept: "Street Bandit ×2, Harbor Rat". An id missing from [enemies]
/// shows as itself.
String enemyRoster(List<String> ids, Map<String, dynamic> enemies) {
  final counts = <String, int>{};
  for (final id in ids) {
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts.entries.map((e) {
    final name =
        (enemies[e.key] as Map<String, dynamic>?)?['enemyName']?.toString() ??
            e.key;
    return e.value > 1 ? '$name ×${e.value}' : name;
  }).join(', ');
}

/// The label of a random fight's button: "Fight: Harbor Rat".
Bilingual fightLabelFor(List<String> ids, Map<String, dynamic> enemies) {
  final roster = enemyRoster(ids, enemies);
  return (en: 'Fight: $roster', fr: 'Combattre : $roster');
}

/// Who [enemy] is, in the reader's language (English when the French line
/// is missing), or null when the record has no description.
String? enemyDescriptionFor(Map<String, dynamic>? enemy, bool fr) {
  if (enemy == null) return null;
  final en = enemy['description']?.toString() ?? '';
  final frText = enemy['description_fr']?.toString() ?? '';
  final text = fr && frText.isNotEmpty ? frText : en;
  return text.isEmpty ? null : text;
}

/// How the fight against [ids] turns up and why: the leader's pack line
/// when several come at once (its own encounter line when it has none),
/// otherwise its encounter line number [index] (wrapped). Null when the
/// leader has no lines, so the caller keeps its themed fallback.
Bilingual? encounterLineFor({
  required List<String> ids,
  required Map<String, dynamic> enemies,
  required int index,
}) {
  if (ids.isEmpty) return null;
  final leader = enemies[ids.first] as Map<String, dynamic>?;
  if (leader == null) return null;
  if (ids.length > 1) {
    final pack = leader['packText']?.toString() ?? '';
    if (pack.isNotEmpty) {
      final packFr = leader['packText_fr']?.toString() ?? '';
      return (en: pack, fr: packFr.isEmpty ? pack : packFr);
    }
  }
  final lines = _strings(leader['encounterText']);
  if (lines.isEmpty) return null;
  final linesFr = _strings(leader['encounterText_fr']);
  final i = index.abs() % lines.length;
  return (en: lines[i], fr: i < linesFr.length ? linesFr[i] : lines[i]);
}

List<String> _strings(Object? raw) => raw is List
    ? [
        for (final e in raw)
          if (e.toString().isNotEmpty) e.toString()
      ]
    : const [];
