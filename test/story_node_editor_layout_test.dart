// The story node editor's destination dropdowns hold the longest node id of
// the story on a phone (v1.852): before, the "Destination node" field
// overflowed by 22 px at 412 px, because the dropdown did not take the
// width it was given and its text did not shorten.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';

class _Repository extends StoryRepository {
  _Repository(this.story);

  final StoryData story;

  @override
  Future<StoryData> load() async => story;
}

void main() {
  testWidgets('a long node id fits the destination fields at 412 px',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final longest = raw.keys.reduce((a, b) => a.length >= b.length ? a : b);
    final node = StoryNode.fromJson('probe', {
      'description': 'd',
      'choices': [
        {
          'text': 'Go',
          'next_id': longest,
          'hasAbilityCheck': true,
          'failNextId': longest,
          'loseNextId': longest,
        },
      ],
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storyRepositoryProvider.overrideWithValue(_Repository(story)),
      ],
      child: MaterialApp(home: StoryNodeEditorScreen(node: node)),
    ));
    await tester.pumpAndSettle();
    // The advanced options hold the fail and lose destinations.
    final advanced = find.text('Advanced options');
    await tester.scrollUntilVisible(advanced, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(find.text(longest), findsWidgets);
    // An overflow is thrown as an exception while the frames are drawn.
    expect(tester.takeException(), isNull);
  });
}
