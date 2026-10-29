// The fight's entrance and finish (wave 16, UX): a boss or a named foe is
// announced by a card that slides in and goes by itself (a tap ends it, and
// reduced motion shows none); a won fight tallies its spoils in a strip,
// the gold and the XP counting up and the items dropping in. UX_SHOTS=<folder>
// takes a picture of each.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/widgets/fight_entrance.dart';
import 'package:narrative_data_app/widgets/fight_spoils_strip.dart';
import 'support/pump.dart';

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

Widget _entrance({bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const Scaffold(
          body: FightEntrance(
            enemyId: 'rat_matriarch',
            name: 'Rat Matriarch',
            line: 'A rat grown vast on plague and spoiled grain.',
            boss: true,
            child: Center(child: Text('the setup')),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the line is the first sentence, cut when long', () {
    expect(entranceLine('A tough. He hits hard.'), 'A tough.');
    expect(entranceLine('  No stop here '), 'No stop here');
    expect(entranceLine(''), '');
    final long = entranceLine('${'word ' * 40}end.', max: 30);
    expect(long.length, lessThanOrEqualTo(30));
    expect(long, endsWith('…'));
  });

  testWidgets('the card shows the foe, then goes by itself', (tester) async {
    await tester.pumpWidget(_entrance());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Rat Matriarch'), findsOneWidget);
    expect(find.byKey(const Key('fight_entrance_line')), findsOneWidget);
    expect(find.text('the setup'), findsOneWidget);
    await tester.pump(fightEntranceTime);
    await tester.pump();
    expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
    expect(find.text('the setup'), findsOneWidget);
  });

  testWidgets('a tap on the card ends it', (tester) async {
    await tester.pumpWidget(_entrance());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('fight_entrance_card')));
    await tester.pump();
    expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
    await tester.pump(fightEntranceTime);
  });

  testWidgets('no card with reduced motion, or when not asked', (tester) async {
    await tester.pumpWidget(_entrance(reduced: true));
    await tester.pump();
    expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
    expect(find.text('the setup'), findsOneWidget);
  });

  testWidgets('the spoils count up and the items drop in', (tester) async {
    const spoils = FightSpoils(gold: 120, xp: 45, items: [
      SpoilItem('potion_minor', 'Potion', 'Minor Potion'),
      SpoilItem('thug_knuckle_wrap', 'Armor', 'Knuckle Wrap'),
    ]);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: FightSpoilsStrip(spoils: spoils, goldLabel: 'Gold'))));
    expect(find.text('+0 Gold'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    final mid = find.byKey(const Key('fight_spoils_gold'));
    final midText = tester.widget<Text>(mid).data ?? '';
    expect(midText, isNot('+0 Gold'));
    expect(midText, isNot('+120 Gold'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('+120 Gold'), findsOneWidget);
    expect(find.text('+45 XP'), findsOneWidget);
    expect(find.byTooltip('Minor Potion'), findsOneWidget);
    expect(find.byTooltip('Knuckle Wrap'), findsOneWidget);
  });

  testWidgets('with reduced motion the spoils are whole at once',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
                body: FightSpoilsStrip(
                    spoils: FightSpoils(gold: 9, xp: 3), goldLabel: 'Gold')))));
    expect(find.text('+9 Gold'), findsOneWidget);
    expect(find.text('+3 XP'), findsOneWidget);
  });

  testWidgets('an empty haul draws nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: FightSpoilsStrip(
                spoils: FightSpoils(gold: 0, xp: 0), goldLabel: 'Gold'))));
    expect(find.byKey(const Key('fight_spoils_strip')), findsNothing);
  });

  group('in the fight', () {
    Future<NavigatorState> start(WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      usePhone(tester, const Size(390, 844));
      await tester.pumpWidget(ProviderScope(
          overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
          child: const MyApp()));
      await settleApp(tester);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': ['starter_die'],
            'equippedDiceId': 'starter_die',
            'gold': 100,
            'level': 5,
          })));
      return tester.state<NavigatorState>(find.byType(Navigator).first);
    }

    testWidgets('a boss opens on its card, an ordinary foe does not',
        (tester) async {
      final navigator = await start(tester);
      navigator.push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
              enemyId: 'rat_matriarch', enemy: _enemy('rat_matriarch'))));
      await settleApp(tester);
      expect(find.byKey(const Key('fight_entrance_card')), findsOneWidget);
      expect(find.byKey(const Key('fight_entrance_name')), findsOneWidget);
      await tester.pump(fightEntranceTime);
      await tester.pump();
      expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
      navigator.pop();
      await settleApp(tester);

      navigator.push(MaterialPageRoute<bool>(
          builder: (_) =>
              FightScreen(enemyId: 'harbor_rat', enemy: _enemy('harbor_rat'))));
      await settleApp(tester);
      expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
      await tester.tap(find.text('Enter Battle'));
      await settleApp(tester);
      expect(find.byKey(const Key('fight_spoils_strip')), findsNothing);
      await tester.tap(find.byTooltip('Win this fight (edit mode)'));
      await settleApp(tester);
      for (var i = 0;
          i < 80 &&
              find.byKey(const Key('fight_spoils_strip')).evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('Take').evaluate().isNotEmpty &&
            tester
                    .widget<FilledButton>(
                        find.widgetWithText(FilledButton, 'Take'))
                    .onPressed !=
                null) {
          await tester.tap(find.text('Take'));
          await settleApp(tester);
        }
      }
      expect(find.byKey(const Key('fight_spoils_strip')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  testWidgets('pictures of the card and the strip (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Column(children: [
            SizedBox(
                height: 330,
                child: Stack(children: [
                  const Positioned.fill(
                      child: ColoredBox(color: Colors.black12)),
                  FightEntrance(
                    enemyId: 'rat_matriarch',
                    name: 'Rat Matriarch',
                    line: entranceLine(
                        _enemy('rat_matriarch')['description'] as String),
                    boss: true,
                    child: const SizedBox.expand(),
                  ),
                ])),
            const SizedBox(height: 12),
            const FightSpoilsStrip(
                spoils: FightSpoils(gold: 120, xp: 45, items: [
                  SpoilItem('potion_minor', 'Potion', 'Minor Potion'),
                  SpoilItem('thug_knuckle_wrap', 'Armor', 'Knuckle Wrap'),
                  SpoilItem('material_timber', 'Material', 'Timber'),
                ]),
                goldLabel: 'Gold'),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/fight-entrance-finish.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.pump(const Duration(seconds: 3));
  });
}
