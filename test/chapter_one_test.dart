// The owner's rules for chapter 1, checked against the authored data: a
// choice is a short line, never a paragraph; a lock the story already
// decided is hidden, not explained; no node whose only choice is
// "continue"; every choice costs something, gains something, or leaves a
// mark a later scene reads back. And the chapter's shape (v1.196): the
// casino and its three ways out, each through the first fight; the chains
// with no healing; the charge at the Inquisitor-General; the cloth found
// under the trapdoor by every road; three ways aboard the flying vessel;
// the crash, the Waste and the White Wells; chapter 2 reached overland.

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
    c.grantsItem ||
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
  StoryChoice choiceTo(String nodeId, String target) =>
      nodes[nodeId]!.choices.singleWhere((c) => c.nextId == target,
          orElse: () => fail('$nodeId does not lead to $target'));

  test('chapter 1 has no padding: 47 scenes, all reachable', () {
    expect(chapterOne.length, 47);
    final targets = <String>{};
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        targets.add(choice.nextId);
        if (choice.failNextId != null) targets.add(choice.failNextId!);
        if (choice.loseNextId != null) targets.add(choice.loseNextId!);
      }
    }
    for (final id in chapterOne.keys) {
      if (id == '0') continue;
      expect(targets, contains(id), reason: '$id is never reached');
    }
    for (final removed in [
      '151', '151_forge', '151_vess', '200', '265', '271', '280', '281', //
      '281_scarred', '810', '817', '818', '821', '830', '860', '892', '896',
      '897', '898', '899_paid', '955', '965_mercy', '965_vengeance', '1003',
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
      expect(node.descriptionFr?.isNotEmpty ?? false, isTrue, reason: node.id);
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
    // The White Wells show one road south per Lysa, never both.
    final wells = nodes['1200']!;
    expect(choiceTo('1200', '1000').showIfFlags, ['lysa_survived']);
    for (final alone in ['1001', '1002']) {
      expect(choiceTo('1200', alone).showIfFlags, ['lysa_lost'], reason: alone);
    }
    expect(wells.choices.length, lessThanOrEqualTo(5),
        reason: 'the Wells stay a scene, not a hub');
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

  group('the casino', () {
    test('three ways out of the blast, each through the first fight', () {
      final casino = nodes['100']!;
      expect(casino.choices.map((c) => c.nextId).toSet(), {'105'});
      final paths = {
        for (final c in casino.choices) c.flagsToAdd.single: c,
      };
      expect(paths.keys.toSet(),
          {'casino_tables', 'casino_rescue', 'casino_fled'});
      expect(paths['casino_tables']!.alignmentMod, lessThan(0));
      expect(paths['casino_rescue']!.alignmentMod, greaterThan(0));
      expect(paths['casino_fled']!.goldMod, greaterThan(0));
      // The first fight: one per path, easy, and the lucky die's.
      final first = nodes['105']!;
      expect(first.choices, hasLength(3));
      for (final fight in first.choices) {
        expect(fight.showIfFlags.single, isIn(paths.keys), reason: fight.text);
        expect(fight.triggersCombat, isTrue, reason: fight.text);
        expect(fight.tutorialFight, isTrue, reason: fight.text);
        expect(fight.luckyDieReveal, isTrue, reason: fight.text);
        expect(fight.noHeal, isTrue, reason: fight.text);
        expect(fight.hasLossBranch, isTrue, reason: fight.text);
        expect(fight.nextId, '106');
      }
      // Lucky die only there.
      for (final node in nodes.values.where((n) => n.id != '105')) {
        for (final c in node.choices) {
          expect(c.luckyDieReveal, isFalse, reason: node.id);
          expect(c.tutorialFight, isFalse, reason: node.id);
        }
      }
      // After it, the chain of the path taken, or the street.
      expect(choiceTo('106', '110').showIfFlags, ['casino_tables']);
      expect(choiceTo('106', '120').showIfFlags, ['casino_rescue']);
      expect(choiceTo('106', '250').showIfFlags, isEmpty);
    });

    for (final (hub, lost, sign) in [('110', '115', -1), ('120', '125', 1)]) {
      test('$hub: one more fight each, no healing, paid; stop after any', () {
        final links =
            nodes[hub]!.choices.where((c) => c.triggersCombat).toList();
        expect(links, hasLength(3));
        String? previous;
        for (final link in links) {
          expect(link.noHeal, isTrue, reason: link.text);
          expect(link.loseNextId, lost, reason: link.text);
          expect(link.nextId, hub, reason: link.text);
          expect(link.goldMod, greaterThan(0), reason: link.text);
          expect(link.alignmentMod.sign, sign, reason: link.text);
          expect(link.hideIfFlags, link.flagsToAdd, reason: link.text);
          if (previous != null) {
            expect(link.showIfFlags, [previous], reason: link.text);
          }
          previous = link.flagsToAdd.single;
        }
        // The pay rises with each link, and so does the fight.
        for (var i = 1; i < links.length; i++) {
          expect(links[i].goldMod, greaterThan(links[i - 1].goldMod));
          expect(links[i].allTriggerEnemyIds.length,
              greaterThanOrEqualTo(links[i - 1].allTriggerEnemyIds.length));
        }
        expect(choiceTo(hub, '250').triggersCombat, isFalse);
      });

      test('$lost: a lost link turns out the pockets, and the story goes on',
          () {
        // Every link won so far is gold lost; the first fight's included.
        final first = nodes['105']!.choices.singleWhere((c) =>
            c.loseNextId == lost &&
            c.showIfFlags.single.contains(hub == '110' ? 'tables' : 'rescue'));
        final links = [
          first,
          ...nodes[hub]!.choices.where((c) => c.triggersCombat),
        ];
        final crawl = nodes[lost]!.choices;
        for (final c in crawl) {
          expect(c.nextId, '250');
          expect(c.healAmount, greaterThan(0), reason: 'a breath, after');
        }
        for (var lostAt = 0; lostAt < links.length; lostAt++) {
          final held = <String>{
            ...first.showIfFlags,
            for (final l in links.take(lostAt)) ...l.flagsToAdd,
          };
          final shown = crawl.where((c) => !c.isHiddenFor(held)).toList();
          expect(shown, hasLength(1), reason: 'lost at link $lostAt');
          final won =
              links.take(lostAt).fold<int>(0, (sum, l) => sum + l.goldMod);
          expect(shown.single.goldMod, -won, reason: 'lost at link $lostAt');
        }
      });
    }
  });

  test('the charge at Vane can be lost into the Black Hold', () {
    final house = nodes['400']!;
    final charge = house.choices.singleWhere((c) => c.triggersCombat);
    expect(charge.allTriggerEnemyIds, ['aurel_vane']);
    expect(charge.loseNextId, '400_lost');
    expect(charge.nextId, '450');
    expect(charge.flagsToAdd, contains('lysa_survived'));
    final run =
        house.choices.singleWhere((c) => c.flagsToAdd.contains('fled_house'));
    final kneel =
        house.choices.singleWhere((c) => c.flagsToAdd.contains('surrendered'));
    expect(run.alignmentMod, lessThan(0));
    expect(kneel.alignmentMod, greaterThan(0));
    for (final c in [run, kneel]) {
      expect(c.nextId, '800', reason: c.text);
      expect(c.flagsToAdd, contains('lysa_lost'), reason: c.text);
    }
    final lost = nodes['400_lost']!;
    expect(lost.description, startsWith('I lost.'));
    expect(lost.descriptionFr, startsWith('J’ai perdu.'));
    final taken = lost.choices.single;
    expect(taken.nextId, '800');
    expect(taken.flagsToAdd, containsAll(['lysa_lost', 'unfurl_lost']));
    expect(nodes['800']!.description, startsWith('Captured, then.'));
    expect(nodes['800']!.flagCallbacks.map((c) => c.flag),
        containsAll(['unfurl_lost', 'fled_house', 'surrendered']));
    expect(nodes['450']!.description, startsWith('I won'));
    expect(nodes['400']!.description, contains('Aurel Vane'));
  });

  test('the cloth is found under the trapdoor, by every road', () {
    // Nobody knew what was down there: the searchers did not find it, the
    // torturer asked about it, and only the cannonball found it.
    expect(nodes['300']!.choices.expand((c) => c.flagsToAdd),
        isNot(contains('open_hand_1')));
    expect(nodes['800']!.description, contains('never seen'));
    for (final (from, choice) in [
      ('450', 0),
      ('450', 1),
    ]) {
      expect(nodes[from]!.choices[choice].nextId, '470');
    }
    for (final id in ['823', '840', '850', '850_fed_failed', '855']) {
      for (final c in nodes[id]!.choices) {
        expect(c.nextId, isNot('891'), reason: '$id skips the trapdoor');
      }
    }
    final trapdoor = nodes['470']!;
    expect(trapdoor.description, contains('trapdoor'));
    expect(trapdoor.description, contains('Who could want'));
    for (final c in trapdoor.choices) {
      expect(c.nextId, '891');
      expect(c.flagsToAdd, containsAll(['took_bundle', 'open_hand_1']));
      expect(c.politics?.remembrance, 1, reason: c.text);
    }
  });

  test('three ways aboard the Lark, each failure with its own cost', () {
    final mate = nodes['895']!;
    expect(mate.choices.map((c) => c.checkAbility).toSet(),
        {'charisma', 'intelligence', 'dexterity'});
    for (final way in mate.choices) {
      expect(way.nextId, '960', reason: way.text);
      final failed = nodes[way.failNextId]!;
      final board = failed.choices.single;
      expect(board.nextId, '960', reason: failed.id);
      if (way.checkAbility == 'dexterity') {
        expect(board.healAmount, lessThan(0), reason: failed.id);
      } else {
        expect(board.goldMod, lessThan(0), reason: failed.id);
      }
    }
    // The lift-off reads back how the party got aboard.
    final liftOff = nodes['960']!.flagCallbacks.map((c) => c.flag).toSet();
    for (final c in [
      ...mate.choices,
      for (final w in mate.choices) ...nodes[w.failNextId]!.choices,
    ]) {
      expect(liftOff, containsAll(c.flagsToAdd), reason: c.text);
    }
  });

  test('the crash, the Waste and the White Wells end chapter 1', () {
    expect(nodes['965']!.choices.map((c) => c.nextId).toSet(), {'1100'});
    // The tear moved to the wreck; Vess to the Wells.
    final tear = choiceTo('1100', '1101');
    expect(tear.failNextId, '1101_scarred');
    expect(nodes['1101_scarred']!.choices.single.flagsToAdd,
        contains('void_marked'));
    expect(nodes['1210']!.reqFlags, ['void_marked']);
    expect(
        nodes['1210']!.choices.single.unlockQuestId, 'q_ch1_vess_in_the_dark');
    // The heat is a Constitution challenge.
    final heat = nodes['1120']!.choices.singleWhere((c) => c.hasSkillChallenge);
    expect(heat.checkAbility, 'constitution');
    expect(heat.hasSkillChallenge, isTrue);
    // The looters: fight them or slip past; a sneak gone wrong is an
    // ambush, or a run into the dark.
    final looters = nodes['1140']!.choices;
    expect(looters.where((c) => c.triggersCombat), hasLength(2));
    final slip = looters.singleWhere((c) => c.avoidFightOnSuccess);
    expect(slip.failNextId, '1140_spotted');
    final spotted = nodes['1140_spotted']!.choices;
    expect(
        spotted.singleWhere((c) => c.triggersCombat).forcedCondition, 'ambush');
    expect(spotted.map((c) => c.nextId).toSet(), {'1200'});
    // The Wells: rest, and the three ways chapter 1 ends.
    expect(nodes['1200']!.description, contains('Saltmouth'));
    for (final ending in ['1000', '1001', '1002']) {
      final next = nodes[ending]!.choices.single;
      expect(next.nextId, '2001', reason: ending);
      expect(next.grantsBannerPieceId, 'heirloom_shroud', reason: ending);
    }
  });

  test('chapter 2 is reached overland, at Saltmouth', () {
    expect(nodes['2001']!.description, startsWith('[CHAPTER 2: SALTMOUTH]'));
    for (final node in nodes.values) {
      final head = int.tryParse(node.id.split('_').first) ?? 0;
      if (head < 2000 || head >= 3000) continue;
      for (final text in [node.description, node.descriptionFr ?? '']) {
        expect(text, isNot(contains('Alster')), reason: node.id);
        expect(text, isNot(contains('Upper Tier')), reason: node.id);
        expect(text, isNot(contains('Lower City')), reason: node.id);
      }
    }
    // The Eel is bought or earned at the yard before she is rebuilt.
    final yard = nodes['2900']!;
    final buy =
        yard.choices.singleWhere((c) => c.flagsToAdd.contains('eel_bought'));
    expect(buy.pays, isTrue);
    expect(buy.goldMod, lessThan(0));
    final work =
        yard.choices.singleWhere((c) => c.flagsToAdd.contains('eel_worked'));
    expect(work.goldMod, 0);
    for (final repair in yard.choices.where((c) => c.launchesZone)) {
      expect(repair.showIfFlags, ['eel_owned'], reason: repair.text);
    }
  });
}
