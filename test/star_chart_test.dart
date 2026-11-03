// The Tree tab's sky (v1.619): each class branch a constellation, a star for
// each skill and a crown for Mastery; the card under it reads the focused
// constellation's next skill, who offers it and at what standing. The layout
// is pure and tested alone; the screen is read at a phone's width for a
// warrior (four constellations) and a mage (five, the last across the row).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/screens/skills/star_chart.dart';
import 'support/pump.dart';

String _line(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('star_card_line'))).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the sky\'s layout', () {
    test('four constellations are two by two, in cells of the sky\'s width',
        () {
      final sky = StarSky.of(4, 412);
      expect(sky.cells, hasLength(4));
      expect(sky.cells[0], const Rect.fromLTWH(0, 0, 206, 176));
      expect(sky.cells[1], const Rect.fromLTWH(206, 0, 206, 176));
      expect(sky.cells[3], const Rect.fromLTWH(206, 176, 206, 176));
      expect(sky.height, 352);
    });

    test('a fifth one has the last row to itself, across both cells', () {
      final sky = StarSky.of(5, 412);
      expect(sky.cells[4], const Rect.fromLTWH(0, 352, 412, 176));
      expect(sky.height, 528);
      // Its stars stay inside it, in the order the shape draws them.
      for (var k = 0; k < 5; k++) {
        expect(sky.cells[4].contains(sky.starAt(4, k)), isTrue, reason: '$k');
      }
      // A single constellation is a cell of its own, not a wide one.
      expect(StarSky.of(1, 412).cells.single.width, 206);
    });

    test('at 320 px the cells are lower, and every star is in its cell', () {
      final sky = StarSky.of(5, 296);
      expect(sky.cellHeight, 150);
      for (var i = 0; i < 5; i++) {
        for (var k = 0; k < 5; k++) {
          expect(sky.cells[i].contains(sky.starAt(i, k)), isTrue,
              reason: 'constellation $i, star $k');
        }
      }
    });

    test('the standing a clan needs grows with the skill\'s depth', () {
      expect(starTierForIndex.map((t) => t.name),
          ['unknown', 'known', 'trusted', 'sworn']);
    });
  });

  testWidgets('the sky reads the standing: offered now, waiting, a tap opens',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(420, 1800));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SkillsScreen()),
    ));
    await settleApp(tester);
    Future<void> load(Map<String, dynamic> session) async {
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson(session)));
      await settleApp(tester);
    }

    // A new warrior: four constellations, the Dominion Wary (the story's
    // nemesis) and the rest Unknown, so the first clan to offer is read in
    // the card: the Compact, for Bulwark.
    await load({'raceId': 'human', 'professionId': 'warrior'});
    expect(find.byKey(const Key('star_sky')), findsOneWidget);
    for (final id in [
      'warrior_bulwark',
      'warrior_vanguard',
      'warrior_warlord',
    ]) {
      expect(find.byKey(Key('branch_$id')), findsOneWidget, reason: id);
    }
    expect(_line(tester), contains('can offer it now'));
    expect(
        tester
            .widget<Text>(find.byKey(const Key('star_clan_warrior_vanguard')))
            .data,
        'Dominion · Wary');

    // A tap on a constellation's name puts it in the card.
    await tester.tap(find.byKey(const Key('star_name_warrior_vanguard')));
    await tester.pump();
    expect(
        find.descendant(
            of: find.byKey(const Key('star_card')),
            matching: find.textContaining('Power Strike')),
        findsOneWidget);

    // Mid game: two Bulwark skills learned, the Compact friendly: the third
    // waits for "Trusted", and the card says so.
    await load({
      'raceId': 'human',
      'professionId': 'warrior',
      'level': 12,
      'unlockedSkillIds': ['warrior_shield_bash', 'bulwark_stance'],
      'politics': {
        'standings': {'compact': 14},
      },
    });
    await tester.tap(find.byKey(const Key('star_name_warrior_bulwark')));
    await tester.pump();
    expect(_line(tester), contains('Waits for “Trusted” with Compact'));
    expect(_line(tester), contains('Friendly'));
    expect(
        tester
            .widget<Text>(find.byKey(const Key('star_count_warrior_bulwark')))
            .data,
        contains('2/4'));

    // A star opens its skill's sheet, the crown the mastery's.
    await tester.tap(find.byKey(const Key('tree_node_bulwark_stance')));
    await settleApp(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('mastery_warrior_bulwark')));
    await settleApp(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await settleApp(tester);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
