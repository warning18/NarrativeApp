// The road on screen (v1.187): a main quest the Eel sails to lands the
// party where the quest starts, with no road walked after the voyage, and
// a payment on the road (a shrine's offering) waits for a purse that holds
// it, on the button and when taken from elsewhere.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a main quest by sea lands; an offering waits for the purse',
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
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'characterName': 'Maren',
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 0,
          'maxHealth': 200,
          'currentHealth': 100,
          'day': 30,
          'watch': 1,
          'provisions': 5,
          'flags': ['camp_founded'],
          'enemyKillCounts': <String, dynamic>{},
        })));
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('6002_camp');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    PlayerSession session() => container.read(playerSessionProvider);
    int clock() => session().day * 4 + session().watch;

    // 1. "Sail for the Black Reliquary": the voyage (its days at sea) has
    // brought the party there. The quest's scene opens: no ration, no
    // watch, nothing met on a road, no detour.
    expect(find.byType(CampScreen), findsOneWidget);
    final camp = tester.element(find.byType(CampScreen));
    final sail = container
        .read(storyDataProvider)
        .value!
        .nodeFor('6002_camp')!
        .choices
        .single;
    expect(sail.travels, isTrue);
    final before = clock();
    final taking =
        takeStoryChoice(camp, camp as WidgetRef, sail, travelled: true);
    await _settle(tester);
    await tester.runAsync(() => taking);
    await _settle(tester);
    final landed = container.read(storyPlayProvider);
    expect(landed.currentNodeId, '6010_thread');
    expect(landed.isInExcursion, isFalse);
    expect(clock(), before);
    expect(session().provisions, 5);
    expect(container.read(pendingRoadNoteProvider), isNull);

    // 2. A wayside shrine with nothing in the purse: kneeling is free, the
    // offering shut, saying why.
    container.read(homeTabIndexProvider.notifier).state = 0;
    play.startExcursion(
        roadEventChain(RoadEventKind.shrine,
            chapter: 5, enemyPool: const [], seed: 3),
        '6010_thread',
        origin: 'The road to the chapel');
    await _settle(tester);
    expect(find.byType(StoryPlayerScreen), findsOneWidget);
    final shut = find.textContaining('not enough gold (0 in the purse)');
    expect(shut, findsOneWidget);
    ElevatedButton button(Finder label) => tester.widget<ElevatedButton>(
        find.ancestor(of: label, matching: find.byType(ElevatedButton)));
    expect(button(shut).onPressed, isNull);
    expect(button(find.text('Kneel a while')).onPressed, isNotNull);

    // Taken from anywhere else (the Journey's step), it still waits: no
    // double heal and no alignment for nothing.
    final offering = container
        .read(storyPlayProvider)
        .activeExcursionNode!
        .choices
        .firstWhere((c) => c.goldMod < 0);
    final story = tester.element(find.byType(StoryPlayerScreen));
    final paying = takeStoryChoice(story, story as WidgetRef, offering);
    await _settle(tester);
    await tester.runAsync(() => paying);
    expect(session().currentHealth, 100);
    expect(session().alignmentScore, 0);
    expect(container.read(storyPlayProvider).isInExcursion, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    // With the gold, the offering opens.
    await tester.runAsync(() =>
        notifier.loadSession(session().copyWith(gold: offering.goldMod.abs())));
    await _settle(tester);
    expect(find.textContaining('not enough gold'), findsNothing);
    expect(
        button(find.textContaining('Leave an offering')).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
