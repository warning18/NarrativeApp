// The simulator's batch statistics: spells, professions, endings,
// companions and the per-chapter breakdown, cut out of
// playthrough_simulator_screen.dart with no change (wave 4a).
part of '../playthrough_simulator_screen.dart';

/// Total casts per spell id across [results], most cast first.
Map<String, int> _spellCastTotals(List<_SimResult> results) {
  final totals = <String, int>{};
  for (final r in results) {
    for (final entry in r.spellsCast.entries) {
      totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
    }
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// How many of [results] cast each spell at least once.
Map<String, int> _runsCastingCounts(List<_SimResult> results) {
  final counts = <String, int>{};
  for (final r in results) {
    for (final id in r.spellsCast.keys) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
}

/// Runs, fights won, fights lost and casts per profession id.
Map<String, ({int runs, int won, int lost, int casts})> _professionTotals(
    List<_SimResult> results) {
  final map = <String, ({int runs, int won, int lost, int casts})>{};
  for (final r in results) {
    if (!r.hasCharacter) continue;
    final current = map[r.professionId] ?? (runs: 0, won: 0, lost: 0, casts: 0);
    map[r.professionId] = (
      runs: current.runs + 1,
      won: current.won + r.fightsWon,
      lost: current.lost + r.fightsLost,
      casts: current.casts + r.totalCasts,
    );
  }
  return map;
}

String _spellDisplayName(
        String id, Map<String, SpellSpec> spells, AppLanguage lang) =>
    spells[id]?.nameFor(lang) ?? id;

String _professionDisplayName(String id, Map<String, dynamic> professions) =>
    (professions[id] as Map<String, dynamic>?)?['professionName']?.toString() ??
    id;

/// "Arcane Bolt ×12, Mana Ward ×3" for one run's casts, or null.
String? _castsSummary(
    Map<String, int> casts, Map<String, SpellSpec> spells, AppLanguage lang) {
  if (casts.isEmpty) return null;
  final entries = casts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) => '${_spellDisplayName(e.key, spells, lang)} ×${e.value}')
      .join(', ');
}

double _avg(Iterable<num> values) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

Map<String, int> _endingCounts(List<_SimResult> results) {
  final counts = <String, int>{};
  for (final r in results) {
    counts[r.endingSummary] = (counts[r.endingSummary] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// How many of [results]' runs discovered each companion's recruit quest —
/// derived purely from [_SimResult.questsDiscovered] (this graph-walk
/// simulator has no quest-completion model, so "discovered the recruit
/// quest" is the closest available proxy for "encountered this companion"),
/// cross-referenced against [quests] for which quest ids actually grant a
/// companion (a non-empty `rewardAllyId`). Most-encountered first.
Map<String, int> _companionEncounterCounts(
    List<_SimResult> results, Map<String, dynamic> quests) {
  final counts = <String, int>{};
  for (final r in results) {
    final companionsThisRun = <String>{};
    for (final questId in r.questsDiscovered) {
      final quest = quests[questId] as Map<String, dynamic>?;
      final allyId = quest?['rewardAllyId']?.toString() ?? '';
      if (allyId.isNotEmpty) companionsThisRun.add(allyId);
    }
    for (final allyId in companionsThisRun) {
      counts[allyId] = (counts[allyId] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// A stable, distinct color per companion id (cycled from a small fixed
/// palette by insertion order) — just enough to tell chips apart at a
/// glance, not meaningful per-companion branding.
const List<Color> _companionColors = [
  Palette.lagoon,
  Palette.arcane,
  Palette.flame,
  Palette.dusk,
  Palette.rose,
];

Color _companionColor(String companionId, Map<String, int> allCounts) {
  final index = allCounts.keys.toList().indexOf(companionId);
  return _companionColors[index % _companionColors.length];
}

/// One colored, icon-led stat row in a batch's recap — a lightweight,
/// scan-friendly alternative to the plain uncolored [Text] lines this
/// section used before.
class _StatLine extends StatelessWidget {
  const _StatLine(
      {required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A grouping bucket (a chapter, a location, or a mood) with the tallies
/// needed to summarize how a batch of runs spent their time in it.
class _GroupStat {
  _GroupStat(this.label);

  final String label;
  int nodeCount = 0;
  int combatCount = 0;
  int goldDelta = 0;
  int alignmentDelta = 0;
  int runsReaching = 0;
  int fightsLost = 0;
  int spellCasts = 0;
}

String _chapterLabel(int? chapter) =>
    chapter == null ? 'Prologue' : 'Chapter $chapter';

/// Buckets every step of every run by the chapter it counts toward,
/// tracking node/combat counts, gold & alignment swing, and how many runs
/// reached that chapter at all — the breakdown this screen's chapter view
/// is built from.
List<_GroupStat> _chapterBreakdown(List<_SimResult> results) {
  final map = <String, _GroupStat>{};
  for (final r in results) {
    final seenThisRun = <String>{};
    for (final s in r.steps) {
      final key = _chapterLabel(s.chapter);
      final stat = map.putIfAbsent(key, () => _GroupStat(key));
      stat.nodeCount++;
      if (s.enemyId != null) stat.combatCount++;
      if (s.fightWon == false) stat.fightsLost++;
      stat.spellCasts += s.spellsCast.values.fold(0, (a, b) => a + b);
      stat.goldDelta += s.goldMod;
      stat.alignmentDelta += s.alignmentMod;
      seenThisRun.add(key);
    }
    for (final key in seenThisRun) {
      map[key]!.runsReaching++;
    }
  }
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a == 'Prologue') return -1;
      if (b == 'Prologue') return 1;
      final na = int.tryParse(a.replaceFirst('Chapter ', '')) ?? 0;
      final nb = int.tryParse(b.replaceFirst('Chapter ', '')) ?? 0;
      return na.compareTo(nb);
    });
  return [for (final k in keys) map[k]!];
}

/// A simple node-count distribution over some per-step attribute (mood or
/// location), most-visited first — how much of the story, on average,
/// reads as "grim" vs "tense", or plays out on the "docks" vs "cathedral".
List<_GroupStat> _distributionBy(
    List<_SimResult> results, String? Function(_SimStep) keyOf) {
  final map = <String, _GroupStat>{};
  for (final r in results) {
    for (final s in r.steps) {
      final key = keyOf(s) ?? '(untagged)';
      map.putIfAbsent(key, () => _GroupStat(key)).nodeCount++;
    }
  }
  final entries = map.values.toList()
    ..sort((a, b) => b.nodeCount.compareTo(a.nodeCount));
  return entries;
}
