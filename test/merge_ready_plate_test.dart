// "A merge is ready" (v1.990): the plate at the top of the player's Skills
// list while a recipe can be crafted, its two ways on (the Skillwright built,
// not built), and the dot on the Camp tab while the party is at the camp.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_state.dart' show CampPresence;
import 'package:narrative_data_app/gamedata/db_schema.dart'
    show housesSchema, skillMergesSchema, skillsSchema;
import 'package:narrative_data_app/providers/camp_presence_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart'
    show gameDbProvider;
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/tab_badges_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';

import 'support/open_game.dart';
import 'support/pump.dart';

Map<String, dynamic> _hero({
  List<String> skills = const ['fireball', 'shadow_step'],
  bool built = false,
  int gold = 0,
}) =>
    {
      'raceId': 'human',
      'professionId': 'warrior',
      'gold': gold,
      'flags': ['feat_skills'],
      'unlockedSkillIds': skills,
      if (built) 'builtHouseIds': ['skillwright'],
    };

/// The tables the plate and the dot read, loaded before the screen is asked.
Future<void> _loaded(WidgetTester tester, ProviderContainer container) async {
  for (final schema in [skillMergesSchema, skillsSchema, housesSchema]) {
    await tester.runAsync(
        () => container.read(gameDbProvider(schema).notifier).whenLoaded());
  }
  await settleApp(tester);
}

Future<ProviderContainer> _openSkills(WidgetTester tester,
    {required Map<String, dynamic> session}) async {
  usePhone(tester, const Size(360, 900));
  final container = await openGame(tester, session: session, overrides: [
    campPresenceProvider.overrideWith((ref) => CampPresence.atCamp),
  ]);
  tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute<void>(
          builder: (_) => const SkillsScreen(initialTab: 1)));
  for (var i = 0; i < 4; i++) {
    await settleApp(tester);
  }
  return container;
}

void main() {
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
  });

  testWidgets('a merge ready and no Skillwright: the cost and the way to camp',
      (tester) async {
    final container = await _openSkills(tester, session: _hero());
    expect(find.byKey(const Key('merge_ready_plate')), findsOneWidget);
    expect(find.text('A merge is ready'), findsOneWidget);
    expect(
        find.textContaining('Fireball and Shadow Step become'), findsOneWidget);
    expect(find.byKey(const Key('merge_ready_unbuilt')), findsOneWidget);
    expect(find.byKey(const Key('merge_ready_craft')), findsNothing);
    // The way to the camp leaves the page and lands on the Camp tab.
    await tester.tap(find.byKey(const Key('merge_ready_go_camp')));
    await settleApp(tester);
    expect(find.byType(SkillsScreen), findsNothing);
    expect(container.read(homeTabIndexProvider), 2);
  });

  testWidgets('a merge ready and the Skillwright up: Craft opens the bench',
      (tester) async {
    await _openSkills(tester, session: _hero(built: true));
    expect(find.byKey(const Key('merge_ready_plate')), findsOneWidget);
    expect(find.byKey(const Key('merge_ready_unbuilt')), findsNothing);
    await tester.tap(find.byKey(const Key('merge_ready_craft')));
    await settleApp(tester);
    expect(find.byKey(const Key('craft_tile_fireball')), findsOneWidget);
  });

  testWidgets('with only one of the two skills there is no plate',
      (tester) async {
    await _openSkills(tester, session: _hero(skills: ['fireball']));
    expect(find.byKey(const Key('merge_ready_plate')), findsNothing);
  });

  testWidgets('the Camp tab wears a dot for a ready merge, at the camp',
      (tester) async {
    final container = await openGame(tester, session: _hero(), overrides: [
      campPresenceProvider.overrideWith((ref) => CampPresence.atCamp),
    ]);
    await _loaded(tester, container);
    final badges = container.read(tabBadgesProvider);
    expect(badges.camp, isTrue);
    expect(badges.campMerge, isTrue);
  });

  testWidgets('no dot without a ready merge', (tester) async {
    final none = await openGame(tester,
        session: _hero(skills: ['fireball']),
        overrides: [
          campPresenceProvider.overrideWith((ref) => CampPresence.atCamp),
        ]);
    await _loaded(tester, none);
    // (A house the purse covers may still light the dot: only the merge's
    // reason is under test.)
    expect(none.read(tabBadgesProvider).campMerge, isFalse);
  });
}
