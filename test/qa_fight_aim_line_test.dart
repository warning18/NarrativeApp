// QA guard (the user's hand test of v1.8xx, docs/feedback/
// fight-aim-line-under-interface.jpg): the fight board's aim line, the curve
// from a picked die to its target, is drawn under the party and enemy cards:
// it stops at the dice tray's top edge, so the target's end of it is never
// seen. Held here by looking at the pixels, not at how it is built: with a
// die picked, the aim colour is on the screen
//   * on the dice tray (the control: the colour is right and the line is
//     drawn),
//   * above the tray, on the free ground between it and the cards, where it
//     was cut off, and
//   * just under the target's card, where it comes up to the card's edge
//     (v1.824 ends it on the card's edge).
// At 360 and 412 px wide. The Attack die's line is orange (0xFFE0752B, in
// FightBoardView's aim line); the cards' own borders are the same orange, so
// only the ground under the card is counted.
import 'dart:convert';
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

import 'skill_fight_harness.dart'
    show gamedata, pumpUntil, settle, shows, tapWhenEnabled;
import 'support/pump.dart';

/// The orange of an Attack die's aim line (fight_board_view.dart).
const _aim = Color(0xFFE0752B);

Future<void> _enter(WidgetTester tester, GlobalKey boundary, Size size) async {
  SharedPreferences.setMockInitialValues({
    'combat_dice_speed': 'quad',
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'board_die': {
        'diceName': 'board_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Strike',
            'type': 'Attack',
            'value': 4,
            'element': 'None'
          },
        ],
      },
    }),
  });
  usePhone(tester, size);
  await tester.pumpWidget(ProviderScope(
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: RepaintBoundary(key: boundary, child: const MyApp())));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['board_die'],
        'equippedDiceId': 'board_die',
        'maxHealth': 400,
        'currentHealth': 400,
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
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
  // The pre-battle page is shown the first time in a run of the tests; a
  // second fight in the same file opens straight on the board.
  final enter = find.text('Enter Battle');
  if (enter.evaluate().isNotEmpty) {
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
  }
  await settle(tester);
  await pumpUntil(tester, () => shows('Roll Dice'));
}

/// How many pixels of [rect] (logical pixels of the window) are exactly
/// [color], read from the screen picture of [boundary].
Future<int> _count(
    WidgetTester tester, GlobalKey boundary, Rect rect, Color color) async {
  final bytes = await tester.runAsync(() async {
    final object =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await object.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (data!, image.width);
  });
  final (data, width) = bytes!;
  final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  var n = 0;
  for (var y = rect.top.floor(); y < rect.bottom.ceil(); y++) {
    for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
      final i = (y * width + x) * 4;
      if (i < 0 || i + 3 >= rgba.length) continue;
      if (rgba[i] == r && rgba[i + 1] == g && rgba[i + 2] == b) n++;
    }
  }
  return n;
}

void main() {
  // One fight, looked at in both widths (the window is resized under it): a
  // second fight opened in the same test file does not reach the board.
  testWidgets('the aim line is drawn over the cards, to its target',
      (tester) async {
    final boundary = GlobalKey();
    await _enter(tester, boundary, const Size(412, 860));
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await settle(tester);
    // A tap picks the die: its line to the target.
    await tester.tap(find.byKey(const ValueKey('die_tile_player')));
    await settle(tester);
    expect(find.byKey(const Key('fight_aim_line')), findsOneWidget);

    for (final size in const [Size(412, 860), Size(360, 780)]) {
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('fight_aim_line')), findsOneWidget,
          reason: 'at $size');

      // The control: on the dice tray the line is on the screen.
      final tray = tester.getRect(find.byKey(const Key('fight_board_skin')));
      final onTray = await _count(tester, boundary, tray, _aim);
      expect(onTray, greaterThan(20),
          reason: 'the aim colour is on the dice tray at $size '
              '(the line is drawn)');

      // The line carries on over what is above the tray: it comes up out of
      // the tray, across the free ground under the cards, to the target's
      // card (it ends on the card's edge). The cards' own borders are the
      // same orange, so only the ground under the card is looked at.
      final enemy = find
          .byWidgetPredicate((w) => '${w.key}'.startsWith("[<'enemy_slot_"));
      expect(enemy, findsOneWidget);
      final card = tester.getRect(enemy);
      final ground = Rect.fromLTRB(0, card.bottom + 3, size.width, tray.top);
      final onGround = await _count(tester, boundary, ground, _aim);
      expect(onGround, greaterThan(40),
          reason: 'the aim line is on the screen above the dice tray at '
              '$size ($onGround pixels of the aim colour in $ground), not '
              "cut off at the tray's top edge");
      final nearCard = Rect.fromLTRB(
          card.left, card.bottom + 3, card.right, card.bottom + 16);
      final atCard = await _count(tester, boundary, nearCard, _aim);
      expect(atCard, greaterThan(4),
          reason: 'the aim line reaches the target card at $size '
              '($atCard pixels in $nearCard)');
    }
    expect(tester.takeException(), isNull);
  });
}
