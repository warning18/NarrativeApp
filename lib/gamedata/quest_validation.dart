/// Validates that each quest chapter has exactly one start quest (a quest no
/// other quest in the same chapter points to via `nextQuestID`) and exactly
/// one end quest (a quest whose `nextQuestID` is empty).
List<String> validateQuestChapters(Map<String, dynamic> quests) {
  final byChapter = <int, List<MapEntry<String, Map<String, dynamic>>>>{};
  for (final entry in quests.entries) {
    final quest = entry.value as Map<String, dynamic>;
    final chapter = (quest['chapter'] as num?)?.toInt() ?? 1;
    byChapter.putIfAbsent(chapter, () => []).add(MapEntry(entry.key, quest));
  }

  final issues = <String>[];
  final chapters = byChapter.keys.toList()..sort();
  for (final chapter in chapters) {
    final questsInChapter = byChapter[chapter]!;
    final targeted = <String>{
      for (final e in questsInChapter)
        if ((e.value['nextQuestID']?.toString() ?? '').isNotEmpty)
          e.value['nextQuestID'].toString(),
    };
    final starts = questsInChapter
        .where((e) => !targeted.contains(e.key))
        .map((e) => e.key)
        .toList();
    final ends = questsInChapter
        .where((e) => (e.value['nextQuestID']?.toString() ?? '').isEmpty)
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
