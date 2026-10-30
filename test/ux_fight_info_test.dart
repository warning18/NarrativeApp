// The fight's chips explain themselves on a long press, and a party member's
// health bar shows the blow the party can read (v1.426): the round, momentum,
// the condition and the goal's chips, and "−N" on the bar of the one aimed at.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/widgets/fight_effect_icons.dart';

import 'skill_fight_harness.dart' show settle, gamedata, pumpUntil, shows;
import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> _enter(WidgetTester tester, {required int perception}) async {
  if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'info_die': {
        'diceName': 'info_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Strike',
            'type': 'Attack',
            'value': 10,
            'element': 'None'
          },
        ],
      },
    }),
  });
  usePhone(tester, const Size(600, 1600));
  await tester.pumpWidget(ProviderScope(
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: const MyApp()));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['info_die'],
        'equippedDiceId': 'info_die',
        'maxHealth': 400,
        'currentHealth': 400,
        'perception': perception,
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    'guile': 0,
    'skillMoves': <dynamic>[],
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: 'slum_thug',
                enemy: thug,
                modifiers: const EncounterModifiers(
                    forcedCondition: BattlefieldCondition.highGround,
                    forcedGoal: FightGoal.slay),
              )));
  await settle(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  await pumpUntil(tester, () => shows('Roll Dice'));
}

/// UX_SHOTS (a folder): saves the screen as it is.
Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    RenderObject? node = tester.renderObject(find.byType(FightScreen));
    while (node != null && node is! RenderRepaintBoundary) {
      node = node.parent;
    }
    final image = await (node! as RenderRepaintBoundary).toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _longPress(WidgetTester tester, Finder chip) async {
  await tester.longPress(chip);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the chips explain themselves, and a read blow shows on the bar',
      (tester) async {
    await _enter(tester, perception: 30);

    await _shot(tester, 'fight-incoming-estimate');
    // The round, the momentum and the condition each open a pop-in on a tap.
    Finder tile(String label) =>
        find.byWidgetPredicate((w) => w is FightStatusTile && w.label == label);
    Future<void> open(String label) async {
      await tester.tap(tile(label));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> close() async {
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await open('Round');
    expect(find.byKey(const Key('fight_effect_popin')), findsOneWidget);
    expect(find.textContaining('the Tide rises'), findsOneWidget);
    await close();
    await open('Momentum');
    expect(find.textContaining('sure critical'), findsOneWidget);
    await close();
    await open('High Ground');
    expect(find.textContaining('Tide rises'), findsNothing);
    expect(find.byKey(const Key('fight_effect_popin')), findsOneWidget);
    await close();

    // The foe's telegraphed blow, read in full (Perception 30), is on the
    // bar of the one it is aimed at, as "−N", and says so on a long press.
    final bar = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('incoming_'));
    expect(bar, findsOneWidget);
    final text = tester
        .widgetList<Text>(find.descendant(of: bar, matching: find.byType(Text)))
        .last
        .data!;
    expect(text, matches(RegExp(r'^−\d+$')));
    await tester.pump(const Duration(seconds: 3));
    await _longPress(tester, bar);
    expect(find.textContaining('after armor and block'), findsOneWidget);
  });
}
