// The camp's harbour (harbour.dart, v1.283.0): the story's grant pays for
// it, the Eel sails nowhere from the camp until it stands (unless the pack
// can no longer pay, so nobody is stranded), the camp's tour points at it,
// and an old save past the camp's founding has it built on load.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/autoplay_engine.dart';
import 'package:narrative_data_app/data/camp_state.dart';
import 'package:narrative_data_app/data/harbour.dart';
import 'package:narrative_data_app/data/materials.dart';
import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';
import 'package:narrative_data_app/tutorial/tutorial_topics.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _grant = {'material_timber': 4, 'material_cut_stone': 2};

Future<WidgetRef> _ref(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  late WidgetRef ref;
  await tester.pumpWidget(ProviderScope(
    child: Consumer(builder: (context, r, _) {
      ref = r;
      return const SizedBox.shrink();
    }),
  ));
  return ref;
}

void main() {
  final houses = _table('houses');
  final harbour = houses[harborHouseId] as Map<String, dynamic>;

  test('the harbour costs only what the story grants', () {
    expect(harbour['buildCost'], 0);
    expect(materialCountsOf(harbour, 'materialCost'), _grant);
  });

  test('the camp\'s founding choice grants exactly the harbour', () {
    final story =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final founding = [
      for (final node in story.values)
        if (node is Map<String, dynamic>)
          for (final choice in (node['choices'] as List? ?? const []))
            if (((choice as Map)['flagsToAdd'] as List?)
                    ?.contains(campFoundedFlag) ??
                false)
              StoryChoice.fromJson(Map<String, dynamic>.from(choice)),
    ];
    expect(founding, hasLength(1));
    expect(founding.single.grantMaterials,
        materialCountsOf(harbour, 'materialCost'));
  });

  test('a choice\'s grantMaterials is read, written back and is an effect', () {
    final choice = StoryChoice.fromJson({
      'text': 'Take stock of the shore',
      'next_id': '3001_camp',
      'grantMaterials': _grant,
    });
    expect(choice.grantMaterials, _grant);
    expect(choice.grantsMaterials, isTrue);
    expect(choice.hasEffects, isTrue);
    expect(choice.toJson()['grantMaterials'], _grant);
    expect(debugEditorRoundTrip(choice).grantMaterials, _grant);
    final plain = StoryChoice.fromJson({'text': 'On', 'next_id': 'x'});
    expect(plain.grantsMaterials, isFalse);
    expect(plain.toJson().containsKey('grantMaterials'), isFalse);
  });

  test('a voyage waits on the harbour only while the pack can build it', () {
    final granted = [
      for (final MapEntry(key: id, value: n) in _grant.entries)
        for (var i = 0; i < n; i++) id,
    ];
    bool waits({
      List<String> flags = const [campFoundedFlag],
      List<String> built = const [],
      List<String>? inventory,
    }) =>
        voyageWaitsOnHarbour(
            flags: flags,
            builtHouseIds: built,
            gold: 0,
            inventory: inventory ?? granted,
            houses: houses);
    expect(waits(), isTrue);
    // Before the camp, the Eel sails as the story takes her.
    expect(waits(flags: const []), isFalse);
    expect(waits(built: const [harborHouseId]), isFalse);
    // The grant spent elsewhere or sold: she sails anyway, never stranded.
    expect(waits(inventory: granted.sublist(1)), isFalse);
  });

  test('an old save past the camp\'s founding has its harbour, once', () {
    final old = PlayerSession.fromJson({
      'saveVersion': materialsSaveVersion,
      'flags': [campFoundedFlag],
      'builtHouseIds': ['keldas_hall'],
    });
    expect(old.builtHouseIds, ['keldas_hall', harborHouseId]);
    expect(old.flags, contains(houseFlag(harborHouseId)));
    final again = PlayerSession.fromJson(
        jsonDecode(jsonEncode(old.toJson())) as Map<String, dynamic>);
    expect(again.builtHouseIds, old.builtHouseIds);
    expect(again.toJson()['saveVersion'], playerSessionSaveVersion);
    // Before the camp, or on the new version, it is the player's to build.
    expect(
        PlayerSession.fromJson({'saveVersion': materialsSaveVersion})
            .builtHouseIds,
        isEmpty);
    expect(
        PlayerSession.fromJson({
          'saveVersion': harbourSaveVersion,
          'flags': [campFoundedFlag],
        }).builtHouseIds,
        isEmpty);
  });

  test('the camp\'s tour starts at the harbour, in both languages', () {
    final first = TutorialTopic.camp.steps.first;
    expect(first.textKey, 'tut_camp_harbour');
    expect(first.target, 'camp.harbour');
    expect(first.optional, isTrue);
    for (final key in ['tut_camp_harbour', 'harbour_needed_to_sail']) {
      for (final lang in AppLanguage.values) {
        expect(trFor(lang, key), isNot(key), reason: '$key $lang');
      }
    }
  });

  testWidgets('the grant goes in the pack and pays for the harbour',
      (tester) async {
    final ref = await _ref(tester);
    await tester.runAsync(() async {
      final notifier = ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(
          PlayerSession.fromJson({'saveVersion': harbourSaveVersion}));
      await notifier.applyChoiceEffects(
          flagsToAdd: const [campFoundedFlag], materials: _grant);
      final granted = ref.read(playerSessionProvider);
      expect(granted.inventoryItemIds.where((id) => id == 'material_timber'),
          hasLength(4));
      expect(granted.inventoryItemIds.where((id) => id == 'material_cut_stone'),
          hasLength(2));

      // "Play to chapter" builds it as the camp's tour would.
      await buildAwaitedHarbour(ref, houses: houses);
      final after = ref.read(playerSessionProvider);
      expect(after.builtHouseIds, [harborHouseId]);
      expect(after.inventoryItemIds, isEmpty);
      expect(
          harbourAwaited(
              flags: after.flags, builtHouseIds: after.builtHouseIds),
          isFalse);
    });
  });
}
