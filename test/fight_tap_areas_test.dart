// The top strip's tiles have a taller tap area (v1.778): the 8 px above and
// the 6 px below the strip are inside each tile's box, so a tap a little
// off still lands, and nothing is moved (a picture of the fight at 360 and
// 320 px is pixel for pixel what it was).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/widgets/fight_effect_icons.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the strip tiles reach 8 px above and 6 px below, nothing moves',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(360, 740));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    final thug =
        (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>)['slum_thug'];
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
        MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                enemyId: 'slum_thug', enemy: thug as Map<String, dynamic>)));
    await _settle(tester);
    await tester.ensureVisible(find.text('Enter Battle'));
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);

    // The tile's box: 38 wide (32 and 6 apart), 51 tall (8 + 32 + 5 + 6).
    final tile = find.byType(FightStatusTile).first;
    final box = tester.getRect(tile);
    expect(box.size, const Size(38, 51));
    // Its look is where it was: the 32 px square starts 8 px into the box,
    // and the cards start right under the box (they used to start 11 px under
    // the square: 5 of its own padding and the strip's 6).
    final square = find.descendant(
        of: tile,
        matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 32 && w.height == 32));
    expect(tester.getRect(square.first).top, box.top + 8);
    final cards = tester.getRect(find
        .byWidgetPredicate((w) =>
            w.key is ValueKey &&
            (w.key as ValueKey).value.toString().startsWith('party_slot_'))
        .first);
    expect(cards.top, greaterThan(box.bottom - 1));
    expect(cards.top - tester.getRect(square.first).bottom, 11);

    // The log button has the same reach.
    expect(tester.getSize(find.byKey(const Key('fight_log_button'))),
        const Size(32, 51));

    // A tap above the square, inside the box, opens its pop-in.
    await tester.tapAt(Offset(box.center.dx - 8, box.top + 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('fight_effect_popin')), findsOneWidget);
    // The pop-in sits where it did: 11 px under the square (5 of the tile's
    // own padding and 6), not under the taller box.
    final popin = tester.getRect(find.byKey(const Key('fight_effect_popin')));
    expect(popin.top, closeTo(tester.getRect(square.first).bottom + 11, 0.5));
  });
}
