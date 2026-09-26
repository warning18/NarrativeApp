// The owner's rules for every chapter, checked against the authored data:
// a choice is a short line, never a paragraph; a lock is one line; a lock
// the story already decided is hidden, not explained; no node whose only
// choice is "continue"; every choice costs something, gains something, or
// leaves a mark a later scene reads back; and every mark left is read.
// chapter_one_test.dart holds the chapter-1 specifics on top of these.

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
    // A camp's way into its chapter's main quest is the chapter's turn,
    // and a trip to where it starts.
    c.mainQuest ||
    c.travels ||
    c.opensCharacterCreation;

void main() {
  final dag = _loadJson('assets/Cleaned_Narrative_DAG.json');
  final nodes = {
    for (final entry in dag.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };
  final flagsRead = <String>{};
  final hubPrefixes = <String>[];
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
    final prefix = node.hubProgress?.prefix ?? '';
    if (prefix.isNotEmpty) hubPrefixes.add(prefix);
  }

  test('a choice is a short line, in both languages, with no meta label', () {
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        expect(choice.text.length, lessThanOrEqualTo(55),
            reason: '${node.id}: ${choice.text}');
        expect(choice.textFr?.isNotEmpty ?? false, isTrue,
            reason: '${node.id}: ${choice.text} has no French');
        for (final label in ['(Start', 'Check)', 'Path)', '(Combat']) {
          expect(choice.text, isNot(contains(label)), reason: node.id);
        }
      }
    }
  });

  test('a lock is one line, never a paragraph', () {
    for (final node in nodes.values) {
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
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        final target = nodes[choice.nextId];
        if (target == null || target.reqFlags.isEmpty) continue;
        expect(choice.showIfFlags, containsAll(target.reqFlags),
            reason: '${node.id} -> ${choice.nextId}: ${choice.text}');
        expect(choice.lockedText ?? '', isEmpty,
            reason: '${node.id}: ${choice.text} explains a hidden lock');
      }
    }
  });

  test('every choice does something, or goes somewhere its siblings do not',
      () {
    for (final node in nodes.values) {
      final choices = node.choices;
      if (choices.isEmpty) continue;
      if (choices.length == 1) {
        final only = choices.single;
        if (only.isEnding) continue;
        expect(_hasImpact(only), isTrue,
            reason: '${node.id} is a padding node: ${only.text}');
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

  test('every mark the story leaves is read back somewhere', () {
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        for (final flag in choice.flagsToAdd) {
          final read = flagsRead.contains(flag) ||
              hubPrefixes.any((p) => flag.startsWith(p));
          expect(read, isTrue,
              reason: '${node.id} sets $flag, nobody reads it');
        }
      }
    }
  });
}
