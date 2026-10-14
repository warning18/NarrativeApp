/// Validates that each chapter's main quest chain has exactly one start
/// quest (a main quest no other main quest of the chapter points to via
/// `nextQuestID`) and exactly one end quest (one whose `nextQuestID` is
/// empty, or leads into another chapter's chain).
///
/// Side quests are open (taken in any order, or chained loosely like the
/// harbor jobs), so they are not part of the chain; a chapter with no main
/// quest has nothing to check.
List<String> validateQuestChapters(Map<String, dynamic> quests) {
  final byChapter = <int, List<MapEntry<String, Map<String, dynamic>>>>{};
  for (final entry in quests.entries) {
    final quest = entry.value as Map<String, dynamic>;
    if ((quest['category']?.toString() ?? 'Main') != 'Main') continue;
    final chapter = (quest['chapter'] as num?)?.toInt() ?? 1;
    byChapter.putIfAbsent(chapter, () => []).add(MapEntry(entry.key, quest));
  }

  String nextOf(Map<String, dynamic> quest) =>
      quest['nextQuestID']?.toString() ?? '';

  final issues = <String>[];
  final chapters = byChapter.keys.toList()..sort();
  for (final chapter in chapters) {
    final questsInChapter = byChapter[chapter]!;
    final ids = {for (final e in questsInChapter) e.key};
    final targeted = <String>{
      for (final e in questsInChapter)
        if (nextOf(e.value).isNotEmpty) nextOf(e.value),
    };
    final starts = questsInChapter
        .where((e) => !targeted.contains(e.key))
        .map((e) => e.key)
        .toList();
    // A chain may run on into the next chapter's: that link is its end.
    final ends = questsInChapter
        .where((e) => nextOf(e.value).isEmpty || !ids.contains(nextOf(e.value)))
        .map((e) => e.key)
        .toList();

    if (starts.length > 1) {
      issues.add(
        'Chapter $chapter has ${starts.length} start quests (${starts.join(", ")}) — only one is allowed.',
      );
    } else if (starts.isEmpty) {
      issues.add('Chapter $chapter has no start quest.');
    }

    if (ends.length > 1) {
      issues.add(
        'Chapter $chapter has ${ends.length} end quests (${ends.join(", ")}) — only one is allowed.',
      );
    } else if (ends.isEmpty) {
      issues.add('Chapter $chapter has no end quest.');
    }
  }
  return issues;
}
