// The fight's chips explain themselves on a long press, and a party member's
// health bar shows the blow the party can read (v1.426): the round, momentum,
// the condition and the goal's chips, and "−N" on the bar of the one aimed at.
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

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'skill_fight_harness.dart' show settle, gamedata, pumpUntil, shows;

Future<void> _enter(WidgetTester tester, {required int perception}) async {
  if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
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
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
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
    // The round, the momentum and the condition each answer a long press.
    await _longPress(tester, find.textContaining('Round'));
    expect(find.textContaining('the Tide rises'), findsOneWidget);
    await tester.tap(find.byType(Scaffold).first, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 3));
    await _longPress(tester, find.textContaining('Momentum'));
    expect(find.textContaining('sure critical'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await _longPress(tester, find.text('High Ground'));
    expect(find.textContaining('Tide rises'), findsNothing);
    expect(find.byType(Tooltip), findsWidgets);

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
