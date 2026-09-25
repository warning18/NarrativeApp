// The chapter's main quest is shut until the camp opens it: in the story
// view too (Edit Mode shows the camp's scene as a story page), where it
// reads "Not yet" until the chapter is explored, its quests done and its
// town visited.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
      'the story view keeps the main quest shut until the camp opens it',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    // Edit Mode shows the camp's scene as a story page, choices and all.
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    final notifier = container.read(playerSessionProvider.notifier);
    final play = container.read(storyPlayProvider.notifier);
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'flags': [campFoundedFlag, placeFoundFlag('3005')],
        })));
    play.jumpTo('3005');
    await _settle(tester);
    play.jumpTo('3001_camp');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    const shut = 'Not yet: the camp shows what this chapter still asks.';
    expect(find.text(shut, skipOffstage: false), findsOneWidget);

    // Explored and with two of the chapter's quests done, the way opens.
    await tester.runAsync(() => notifier.loadSession(container
            .read(playerSessionProvider)
            .copyWith(completedZoneIds: const [
          'z_cinder_row',
          'z_scaffold_yards'
        ], completedQuestIds: const [
          'q_ch3_ashen_oath',
          'q_ch3_void_relic',
        ], flags: [
          ...container.read(playerSessionProvider).flags,
          'hub_3005_oath',
          'hub_3005_wisp',
          'hub_3005_acolyte',
          'hub_3005_relic',
          'hub_3005_golem',
          'hub_3005_stalker',
        ])));
    await _settle(tester);
    expect(find.text(shut, skipOffstage: false), findsNothing);
    expect(find.text('Walk inland and climb the Spire', skipOffstage: false),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
