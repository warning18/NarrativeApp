// The climb's keys in the story and the data (v1.196), checked against
// the clan data: a claim, a pledge or a crown names a faction (a claim or
// a crown one that can head the coast), a choice's politics gate is
// written with known keys about known factions and sub-clans, a last
// battle starts a fight, and a throne title names its faction. Whatever
// the story holds, so it checks the content the chapters bring too.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/throne.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _json('assets/gamedata/factions.json'),
    subclans: _json('assets/gamedata/subclans.json'),
    relations: _json('assets/gamedata/relations.json'),
    titles: _json('assets/gamedata/titles.json'),
  );
  final dag = _json('assets/Cleaned_Narrative_DAG.json');
  final nodes = {
    for (final e in dag.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  };
  final events =
      parsePoliticsEvents(_json('assets/gamedata/politics_events.json'));

  bool heads(String id) {
    final faction = data.faction(id);
    return faction != null && (faction.isClan || faction.isLost);
  }

  void checkPolitics(StoryPolitics? p, String where) {
    if (p == null) return;
    if (p.claim.isNotEmpty) {
      expect(heads(p.claim), isTrue, reason: '$where: claim ${p.claim}');
    }
    if (p.throneWinner.isNotEmpty) {
      expect(heads(p.throneWinner), isTrue,
          reason: '$where: throneWinner ${p.throneWinner}');
    }
    for (final id in p.pledges) {
      expect(data.factions, contains(id), reason: '$where: pledge $id');
    }
  }

  void checkGate(Map<String, dynamic> gate, String where) {
    for (final key in gate.keys) {
      expect(EventConditions.keys, contains(key), reason: '$where: $key');
    }
    final conditions = EventConditions.fromJson(gate);
    for (final id in [...conditions.claim, ...conditions.throneWinner]) {
      if (id == 'any' || id == 'none') continue;
      expect(heads(id), isTrue, reason: '$where: $id');
    }
    for (final e in conditions.rungAtLeast.entries) {
      expect(heads(e.key), isTrue, reason: '$where: rung of ${e.key}');
      expect(e.value, inInclusiveRange(1, rungThrone), reason: where);
    }
    for (final id in [
      ...conditions.standingAtLeast.keys,
      ...conditions.standingAtMost.keys,
    ]) {
      expect(data.factions, contains(id), reason: '$where: standing of $id');
    }
    for (final id in conditions.marks.keys) {
      expect(data.subclans, contains(id), reason: '$where: mark of $id');
    }
    for (final pair in [
      ...conditions.relationAtLeast.keys,
      ...conditions.relationAtMost.keys,
    ]) {
      for (final id in pair.split('|')) {
        expect(data.factions, contains(id.trim()), reason: '$where: $pair');
      }
    }
    // It must hold for someone: a gate nothing can open is a dead choice.
    expect(
        conditions.claim.toSet().containsAll(['any', 'none']) &&
            conditions.claim.length == 2,
        isFalse,
        reason: where);
  }

  test('the story\'s claims, pledges, crowns and gates name the coast', () {
    for (final node in nodes.values) {
      checkPolitics(node.politicsOnEnter, '${node.id} on entry');
      for (var i = 0; i < node.choices.length; i++) {
        final choice = node.choices[i];
        final where = '${node.id} choice $i';
        checkPolitics(choice.politics, where);
        if (choice.politicsIf.isNotEmpty) checkGate(choice.politicsIf, where);
        if (choice.hostFight) {
          expect(choice.triggersCombat || choice.launchesZone, isTrue,
              reason: '$where: a last battle with no fight');
        }
      }
    }
    expect(nodes, isNotEmpty);
  });

  test('the events\' variants read and do the climb with known factions', () {
    for (final event in events.values) {
      for (var i = 0; i < event.variants.length; i++) {
        final variant = event.variants[i];
        final where = '${event.id} variant $i';
        checkPolitics(variant.effects, where);
        final c = variant.conditions;
        for (final id in [...c.claim, ...c.throneWinner]) {
          if (id == 'any' || id == 'none') continue;
          expect(heads(id), isTrue, reason: '$where: $id');
        }
        for (final id in c.rungAtLeast.keys) {
          expect(heads(id), isTrue, reason: '$where: rung of $id');
        }
      }
    }
  });

  test('a throne title names a faction that can take the Throne', () {
    for (final title in data.titles.values) {
      if (!title.source.startsWith('throne:')) continue;
      final id = title.source.substring('throne:'.length);
      expect(heads(id), isTrue, reason: title.id);
      expect(title.nameFr, isNotEmpty, reason: title.id);
      expect(throneTitlesOf(id, data), contains(title));
    }
  });
}
