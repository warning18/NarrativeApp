// Places only heard of (heard_of.dart, docs/proposals/heard-of-places.md):
// "Set out" there, or by the expedition that finds a village not found
// yet (the user's decision), else "Mark as goal" with the reason; on the
// real story, zones and ports.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/heard_of.dart';
import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final raw = _json(StoryRepository.assetPath);
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final zones = _json('assets/gamedata/zones.json');
  final ports = _json('assets/gamedata/ports.json');

  HeardOfPlace heard(
    String id, {
    required Set<String> visited,
    int chapter = 3,
    List<String> flags = const [campFoundedFlag],
    bool harbour = false,
  }) =>
      heardOfPlacesOf(
        history: TravelHistory(
          stops: const [],
          legs: const [],
          visited: visited,
          heardOf: {id},
          currentId: null,
          travelTargets: const {},
        ),
        story: story,
        chapter: chapter,
        flags: flags,
        harbourBuilt: harbour,
        zones: zones,
        ports: ports,
      )[id]!;

  test('a landmark with no place scene is the story\'s to reach', () {
    final sleeper = heard('sleeper', visited: {'crash'}, chapter: 1);
    expect(sleeper.action, HeardOfAction.markGoal);
    expect(sleeper.reason, HeardOfReason.storyOnly);
    expect(sleeper.roadIds, ['crash_sleeper']);
  });

  test('before the camp, nothing is set out for', () {
    final quarter = heard('quarter', visited: {'camp'}, flags: const []);
    expect(quarter.reason, HeardOfReason.noCamp);
  });

  test('a village not found is set out for by the expedition that finds it',
      () {
    final quarter = heard('quarter', visited: {'camp'});
    expect(quarter.setsOut, isTrue);
    expect(quarter.byExpedition, isTrue);
    expect(quarter.expeditionId, 'z_cinder_row');
    expect(quarter.expeditionPortId, 'port_ashen_landing');
    expect(quarter.placeNodeId, '3005');
  });

  test('an expedition still shut makes it a goal, saying what it waits on', () {
    final emberwick = heard('emberwick', visited: {'quarter'});
    expect(emberwick.reason, HeardOfReason.needsExpedition);
    expect(emberwick.expeditionId, 'z_scaffold_yards');
    expect(emberwick.waitsOnFlags, ['cinder_row_cleared']);
  });

  test('once found, Set out travels straight there', () {
    final emberwick = heard('emberwick',
        visited: {'quarter'}, flags: [campFoundedFlag, placeFoundFlag('3100')]);
    expect(emberwick.setsOut, isTrue);
    expect(emberwick.byExpedition, isFalse);
    expect(emberwick.placeNodeId, '3100');
  });

  test('a later chapter\'s place waits for it', () {
    final kindly = heard('kindly', visited: {'camp'});
    expect(kindly.reason, HeardOfReason.laterChapter);
    expect(kindly.chapter, 4);
  });

  test('an expedition from another port waits on the harbour', () {
    final waiting = heard('kindly',
        visited: {'camp'},
        chapter: 4,
        flags: [campFoundedFlag, 'ossuary_galleries_cleared']);
    expect(waiting.reason, HeardOfReason.needsHarbour);
    expect(waiting.expeditionPortId, 'port_drowned_stair');
    final sailing = heard('kindly',
        visited: {'camp'},
        chapter: 4,
        harbour: true,
        flags: [campFoundedFlag, 'ossuary_galleries_cleared']);
    expect(sailing.byExpedition, isTrue);
    expect(sailing.expeditionId, 'z_changeling_fen');
  });

  test('one map goal at a time, gone once reached', () {
    var flags = withMapGoal(const ['camp_founded'], 'spire');
    expect(mapGoalIn(flags, {}), 'spire');
    flags = withMapGoal(flags, 'court');
    expect(flags.where((f) => f.startsWith(mapGoalPrefix)), ['map_goal:court']);
    expect(mapGoalIn(flags, {'court'}), isNull);
    expect(withMapGoal(flags, null), ['camp_founded']);
  });

  test('every reason and the warning have their words in both languages', () {
    for (final key in [
      for (final reason in HeardOfReason.values) 'heard_reason_${reason.name}',
      'heard_setout_warning',
    ]) {
      for (final lang in AppLanguage.values) {
        expect(trFor(lang, key), isNot(key), reason: '$key $lang');
      }
    }
  });
}
