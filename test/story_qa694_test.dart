// Issue #694 (QA): a story choice that fights an enemy missing from the
// table (broken or edited data) is no free win: the error is reported and
// the choice isn't taken.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart';

import 'fight_qa694_harness.dart';
import 'skill_fight_harness.dart';
import 'support/pump.dart';

void main() {
  testWidgets('a story fight against a missing enemy is no free win',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(420, 1400));
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await loadApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'characterName': 'Maren',
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 10,
          'maxHealth': 200,
          'currentHealth': 200,
          'flags': ['camp_founded'],
        })));
    final story = container.read(storyDataProvider).value!;
    container.read(storyPlayProvider.notifier).jumpTo('6002_camp');
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await settle(tester);
    final from = container.read(storyPlayProvider).currentNodeId;
    final elsewhere = story.nodeFor('6010_thread')!.id;
    final choice = StoryChoice(
        text: 'Fight the nobody',
        nextId: elsewhere,
        goldMod: 50,
        flagsToAdd: const ['qa694_won'],
        triggerEnemyId: 'qa694_no_such_enemy');
    final camp = tester.element(find.byType(CampScreen));
    final taking = takeStoryChoice(camp, camp as WidgetRef, choice);
    await settle(tester);
    await tester.runAsync(() => taking);
    await settle(tester);

    final session = container.read(playerSessionProvider);
    expect(container.read(storyPlayProvider).currentNodeId, from);
    expect(session.gold, 10);
    expect(session.flags, isNot(contains('qa694_won')));
    final reported = tester.takeException();
    expect('$reported', contains('qa694_no_such_enemy'));
  });
}
