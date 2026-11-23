// An intrigue's stages come in order: no politics event moves a plot to a
// stage before its chapter, or past the stage before it. The plot card
// shows every stage below the one reached, so a jump shows a stage the
// player never met (the Broken Charter's Turn in chapter 2, before its
// Hook in chapter 3, found in Narrative's review).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/politics_events.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
    intrigues: _table('intrigues'),
  );
  final events = parsePoliticsEvents(_table('politics_events'));

  test('an event moves a plot only after the stage before, in its chapter', () {
    final problems = <String>[];
    var checked = 0;
    for (final event in events.values) {
      for (final variant in event.variants) {
        for (final step in variant.effects.intrigues) {
          final stage = step.stage;
          if (stage == null || stage < 2) continue;
          checked++;
          final intrigue = data.intrigues[step.id];
          final stageChapter =
              intrigue == null || stage > intrigue.stages.length
                  ? null
                  : int.tryParse(intrigue.stages[stage - 1].chapter.trim());
          if (event.triggers.isEmpty) {
            problems.add('${event.id}: no trigger');
          }
          for (final trigger in event.triggers) {
            if (stageChapter != null && (trigger.chapter ?? 0) < stageChapter) {
              problems.add(
                '${event.id}: ${step.id} stage $stage is chapter '
                '$stageChapter, the trigger allows ${trigger.chapter}',
              );
            }
            final before = [
              for (var n = stage - 1; n <= intrigueStageNames.length; n++)
                intrigueStageFlag(step.id, n),
            ];
            if (!trigger.flags.any(before.contains)) {
              problems.add(
                '${event.id}: ${step.id} stage $stage does not '
                'wait for stage ${stage - 1}',
              );
            }
          }
        }
      }
    }
    expect(checked, greaterThan(0), reason: 'no event sets a stage any more');
    expect(problems, isEmpty);
  });

  test('the coal stops only after the Hook, in chapter 4', () {
    CoastChange run(int chapter, List<String> flags) => runDueEvents(
          politics: PoliticsState.empty,
          flags: flags,
          world: CoastWorld(data: data, events: events, chapter: chapter),
        );
    const clue = 'intrigue_broken_charter_stage_1';
    const hook = 'intrigue_broken_charter_stage_2';

    expect(run(2, const [clue]).fired, isNot(contains('coal_stops')));
    expect(run(4, const [clue]).fired, isNot(contains('coal_stops')));

    final turned = run(4, const [clue, hook]);
    expect(turned.fired, contains('coal_stops'));
    expect(intrigueStageFrom(turned.flags, 'broken_charter'), 3);
  });
}
