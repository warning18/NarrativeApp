// The owner's rules for chapter 1, checked against the authored data: a
// choice is a short line, never a paragraph; a lock the story already
// decided is hidden, not explained; no node whose only choice is
// "continue"; every choice costs something, gains something, or leaves a
// mark a later scene reads back; and the Kroll scenes read the same on
// both origins (a player who kept Lysa was never in the Black Hold).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $relative under ${Directory.current.path}');
}

/// A choice does something: it changes the character, starts a fight, a
/// check, a quest or a shop, or hands over a piece of the Shroud.
bool _hasImpact(StoryChoice c) =>
    c.goldMod != 0 ||
    c.alignmentMod != 0 ||
    c.healAmount != 0 ||
    c.flagsToAdd.isNotEmpty ||
    c.triggersCombat ||
    c.checkAbility != null ||
    (c.unlockShopId?.isNotEmpty ?? false) ||
    (c.unlockQuestId?.isNotEmpty ?? false) ||
    (c.questIDToProgress?.isNotEmpty ?? false) ||
    (c.grantsBannerPieceId?.isNotEmpty ?? false) ||
    (c.loseAllyId?.isNotEmpty ?? false) ||
    (c.launchZoneId?.isNotEmpty ?? false) ||
    c.opensCharacterCreation;

void main() {
  final dag = _loadJson('assets/Cleaned_Narrative_DAG.json');
  final nodes = {
    for (final entry in dag.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };
  bool inChapterOne(String id) {
    final head = int.tryParse(id.split('_').first);
    return head != null && head < 2000;
  }

  final chapterOne = {
    for (final e in nodes.entries)
      if (inChapterOne(e.key)) e.key: e.value,
  };
  final flagsRead = <String>{};
  for (final node in nodes.values) {
    flagsRead.addAll(node.reqFlags);
    for (final callback in node.flagCallbacks) {
      flagsRead.add(callback.flag);
      flagsRead.addAll(callback.unlessFlags);
      flagsRead.addAll(callback.andFlags);
    }
    for (final choice in node.choices) {
      flagsRead.addAll(choice.showIfFlags);
      flagsRead.addAll(choice.hideIfFlags);
    }
  }
  final hubPrefixes = [
    for (final node in nodes.values)
      if (node.hubProgress != null) node.hubProgress!.prefix,
  ];

  test('chapter 1 has no padding: 35 scenes, all reachable', () {
    expect(chapterOne.length, 35);
    final targets = <String>{};
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        targets.add(choice.nextId);
        if (choice.failNextId != null) targets.add(choice.failNextId!);
      }
    }
    for (final id in chapterOne.keys) {
      if (id == '0') continue;
      expect(targets, contains(id), reason: '$id is never reached');
    }
    for (final removed in [
      '200',
      '265',
      '271',
      '810',
      '817',
      '818',
      '821',
      '830',
      '860',
      '892',
      '955',
      '1003',
    ]) {
      expect(nodes.containsKey(removed), isFalse, reason: removed);
    }
  });

  test('a choice is a short line, in both languages, with no meta label', () {
    for (final node in chapterOne.values) {
      for (final choice in node.choices) {
        expect(choice.text.length, lessThanOrEqualTo(55),
            reason: '${node.id}: ${choice.text}');
        expect(choice.textFr?.isNotEmpty ?? false, isTrue,
            reason: '${node.id}: ${choice.text} has no French');
        expect(choice.text, isNot(contains('(Start')), reason: node.id);
        expect(choice.text, isNot(contains('Check)')), reason: node.id);
        expect(choice.text, isNot(contains('Path)')), reason: node.id);
      }
    }
  });

  test('a lock is one line, never a paragraph', () {
    for (final node in chapterOne.values) {
      for (final choice in node.choices) {
        final lock = choice.lockedText ?? '';
        if (lock.isEmpty) continue;
        expect(lock.length, lessThanOrEqualTo(80),
            reason: '${node.id}: ${choice.text}');
        expect(choice.lockedTextFr?.isNotEmpty ?? false, isTrue,
            reason: '${node.id}: ${choice.text} lock has no French');
      }
    }
  });

  test('a lock the story already decided is hidden, not explained', () {
    // A choice whose target waits on a story flag can only ever be locked
    // by an earlier choice, so it shows only when that flag is held; the
    // locks that remain are ones the player can still change (gold,
    // alignment).
    for (final node in chapterOne.values) {
      for (final choice in node.choices) {
        final target = nodes[choice.nextId];
        if (target == null || target.reqFlags.isEmpty) continue;
        expect(choice.showIfFlags, containsAll(target.reqFlags),
            reason: '${node.id} -> ${choice.nextId}: ${choice.text}');
        expect(choice.lockedText ?? '', isEmpty,
            reason: '${node.id}: ${choice.text} explains a hidden lock');
      }
    }
    // Kroll's aftermath shows one climb, never both.
    for (final id in ['965', '965_mercy', '965_vengeance']) {
      final climbs = nodes[id]!.choices;
      expect(climbs.where((c) => c.nextId == '1000').single.showIfFlags,
          ['lysa_survived']);
      expect(climbs.where((c) => c.nextId != '1000').length, 2, reason: id);
      for (final alone in climbs.where((c) => c.nextId != '1000')) {
        expect(alone.showIfFlags, ['lysa_lost'], reason: '$id: ${alone.text}');
      }
    }
  });

  test('every choice does something, or goes somewhere its siblings do not',
      () {
    for (final node in chapterOne.values) {
      final choices = node.choices;
      if (choices.isEmpty) continue;
      if (choices.length == 1) {
        expect(_hasImpact(choices.single), isTrue,
            reason: '${node.id} is a padding node: ${choices.single.text}');
        continue;
      }
      for (final choice in choices) {
        final elsewhere =
            choices.where((c) => c != choice && c.nextId == choice.nextId);
        expect(_hasImpact(choice) || elsewhere.isEmpty, isTrue,
            reason: '${node.id}: ${choice.text} changes nothing');
      }
    }
  });

  test('every mark chapter 1 leaves is read back somewhere', () {
    for (final node in chapterOne.values) {
      for (final choice in node.choices) {
        for (final flag in choice.flagsToAdd) {
          final read = flagsRead.contains(flag) ||
              hubPrefixes.any((p) => p.isNotEmpty && flag.startsWith(p));
          expect(read, isTrue,
              reason: '${node.id} sets $flag, nobody reads it');
        }
      }
    }
    expect(flagsRead, contains('keeper_dead'));
  });

  test('the Kroll scenes read the same on both origins', () {
    final kroll = nodes['960']!;
    expect(kroll.description, isNot(contains('torturer')));
    expect(kroll.flagCallbacks.map((c) => c.flag).toSet(),
        {'lysa_lost', 'lysa_survived'});
    for (final id in ['965', '965_mercy', '965_vengeance']) {
      final text = nodes[id]!.description.toLowerCase();
      expect(text, isNot(contains('session')), reason: id);
      expect(text, isNot(contains('three days')), reason: id);
      expect(nodes[id]!.flagCallbacks.single.flag, 'lysa_lost', reason: id);
    }
    // The smuggler's three doors differ, and the crossing remembers each.
    final crossing = nodes['2001']!.flagCallbacks.map((c) => c.flag).toSet();
    for (final (id, flag) in [
      ('896', 'smuggler_pitied'),
      ('897', 'smuggler_debt'),
      ('898', 'smuggler_cowed'),
    ]) {
      expect(nodes[id]!.choices.single.flagsToAdd, contains(flag));
      expect(crossing, contains(flag));
    }
  });
}
