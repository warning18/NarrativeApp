// v2.5.0 screens (UX): the Void Banner's wide slot once a banner is owned, a
// chapter's goals card, the fight's goal lines, and the chapter chest's
// screen (which hands over to the usual spoils sheet and marks the chest
// given).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/widgets/chapter_chest_dialog.dart';
import 'package:narrative_data_app/widgets/chapter_goals_card.dart';
import 'package:narrative_data_app/widgets/spoils_chest_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<ProviderContainer> _mount(
  WidgetTester tester,
  Widget home, {
  Map<String, List<String>> goals = const {},
  List<int> given = const [],
  List<String> bag = const [],
  List<String> worn = const [],
  List<String>? dice,
  String? die,
  Map<String, Object> prefs = const {},
  AppLanguage language = AppLanguage.en,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(appLanguageProvider);
  final notifier = container.read(playerSessionProvider.notifier);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
        inventoryItemIds: bag,
        equippedItemIds: worn,
        ownedDiceIds: dice ?? const ['starter_die'],
        equippedDiceId: die ?? 'starter_die',
        chapterGoalsMet: goals,
        chapterChestsGiven: given,
      )));
  if (language != AppLanguage.en) {
    container.read(appLanguageProvider.notifier).state = language;
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
        home: home is InventoryScreen ? home : Scaffold(body: home)),
  ));
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);

  group('the Banner slot', () {
    testWidgets('no tile until a banner is owned', (tester) async {
      await _mount(tester, const InventoryScreen());
      expect(find.byKey(const Key('slot_Head')), findsOneWidget);
      expect(find.byKey(const Key('slot_Banner')), findsNothing);
    });

    testWidgets('owned, it has a wide tile of its own under the grid',
        (tester) async {
      await _mount(tester, const InventoryScreen(), bag: ['void_banner']);
      // ignore: avoid_print
      print(
          'DBG gathering=${find.textContaining('Still gathering').evaluate().length} head=${find.byKey(const Key('slot_Head')).evaluate().length} texts=${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).take(8).toList()}');
      final banner = find.byKey(const Key('slot_Banner'));
      expect(banner, findsOneWidget);
      final grid = tester.getRect(find.byKey(const Key('slot_Foot')));
      final tile = tester.getRect(banner);
      expect(tile.top, greaterThan(grid.bottom - 1), reason: 'under the grid');
      expect(tile.width, greaterThan(grid.width * 2.5), reason: 'wide');
    });

    testWidgets('worn, it names what is worn', (tester) async {
      await _mount(tester, const InventoryScreen(),
          bag: ['void_banner'], worn: ['void_banner']);
      expect(find.textContaining('Void Banner'), findsWidgets);
    });
  });

  group('the goals', () {
    testWidgets('the card ticks what is met and counts it', (tester) async {
      await _mount(tester, const ChapterGoalsCard(chapter: 5), goals: {
        '5': ['rounds', 'weakness'],
      });
      final counts =
          tester.widget<Text>(find.byKey(const Key('chapter_goals_count')));
      expect(counts.data, '2/3');
      expect(
          tester
              .widget<GoalTick>(find.byKey(const Key('goal_tick_rounds')))
              .met,
          isTrue);
      expect(
          tester
              .widget<GoalTick>(find.byKey(const Key('goal_tick_no_potion')))
              .met,
          isFalse);
    });

    testWidgets('a chapter without goals shows nothing', (tester) async {
      await _mount(tester, const ChapterGoalsCard(chapter: 2));
      expect(find.byKey(const Key('chapter_goals_2')), findsNothing);
    });

    testWidgets('the fight names the goals it can settle', (tester) async {
      await _mount(tester,
          const ChapterGoalSetupLine(chapter: 7, enemyIds: ['slum_thug']));
      expect(find.byKey(const Key('chapter_goal_setup_7')), findsOneWidget);
      expect(find.textContaining('first try'), findsNothing,
          reason: 'the first-try goal is only for its boss');
      await _mount(
          tester,
          const ChapterGoalSetupLine(
              chapter: 7, enemyIds: ['claimant_tallis']));
      expect(find.textContaining('first try'), findsOneWidget);
    });

    testWidgets('once the chapter chest is given, the fight says nothing',
        (tester) async {
      await _mount(tester,
          const ChapterGoalSetupLine(chapter: 5, enemyIds: ['slum_thug']),
          given: [5]);
      expect(find.byKey(const Key('chapter_goal_setup_5')), findsNothing);
    });
  });

  group('the chapter chest', () {
    testWidgets('its tier is the goals met; Open claims it once',
        (tester) async {
      late WidgetRef ref0;
      final container = await _mount(
        tester,
        Consumer(builder: (context, ref, _) {
          ref0 = ref;
          return FilledButton(
              key: const Key('go'),
              onPressed: () => showChapterChest(context, ref, 5),
              child: const Text('go'));
        }),
        goals: {
          '5': ['rounds', 'weakness'],
        },
      );
      await tester.tap(find.byKey(const Key('go')));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('chapter_chest_dialog')), findsOneWidget);
      expect(find.byKey(const Key('chapter_chest_silver')), findsOneWidget,
          reason: 'two goals of three: Silver');
      expect(container.read(playerSessionProvider).chapterChestsGiven, isEmpty);
      await tester.tap(find.byKey(const Key('chapter_chest_open')));
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(container.read(playerSessionProvider).chapterChestsGiven, [5],
          reason: 'given once, when opened');
      expect(find.byType(SpoilsChestDialog), findsOneWidget,
          reason: 'the usual spoils sheet');
      expect(ref0, isNotNull);
    });
  });
}
