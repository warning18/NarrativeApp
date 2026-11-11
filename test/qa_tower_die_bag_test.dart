// QA guard (v1.917 / v1.918): a die gained on a Tower floor goes to the BAG,
// shows in the floor's "Your dice" panel (new dot), and the player can put it
// in play with "Roll this die"; the choice is saved and the die in play moves.
//
// A saved run of a fixed seed is put in "choosing" with one offer, a die the
// hero does not own; the card is taken through the real offer screen, then
// the panel is used as a player does.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_dice.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';

void main() {
  testWidgets('a die gained on a floor lands in the bag and can be put in play',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final data = towerDataFromAssets();
    final start = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: data);
    final owned = {for (final d in towerDiceOf(start, data)) d.id};
    final startInPlay = towerDiceOf(start, data).firstWhere((d) => d.inPlay).id;
    final gained = ['void_die', 'iron_die', 'flame_die', 'tide_die']
        .firstWhere((id) => !owned.contains(id) && data.dice.containsKey(id));
    final run = start.copyWith(
      status: TowerStatus.choosing,
      offer: [TowerReward(TowerRewardKind.die, id: gained)],
    );
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });

    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapKey(String key) async {
      final f = find.byKey(Key(key));
      for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
        final vertical = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        if (vertical.evaluate().isEmpty) break;
        await tester.drag(vertical.first, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(f, findsWidgets, reason: 'no "$key" on the screen');
      await tester.ensureVisible(f.first);
      await tester.tap(f.first);
      await settle();
    }

    await settle(10);
    await tester.ensureVisible(find.byKey(const Key('menu_tower')));
    await tapKey('menu_tower');
    await tapKey('tower_continue');
    await settle(10);

    // the floor was cleared with a level: its Level Up comes first
    if (find.byType(LevelUpScreen).evaluate().isNotEmpty) {
      final card = find.textContaining(RegExp(
          r'^(Constitution|Strength|Dexterity|Intelligence|Wisdom|Perception|Luck|Charisma)$'));
      await tester.tap(card.first);
      await settle();
      final take = find.text('Take this pick');
      await tester.ensureVisible(take);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(take);
      await settle(10);
      await tapKey('level_up_done');
      await settle(10);
    }

    // the floor's spoils sheet (nothing in it): Take
    if (find.text('What the spoils change').evaluate().isNotEmpty) {
      await tester.tap(find.text('Take').last);
      await settle(10);
    }

    // take the die card
    await tapKey('tower_card_0');
    await tapKey('tower_take');
    await settle(10);

    // the panel: the gained die is in the bag, new, and not in play
    expect(find.byKey(const Key('tower_dice_panel')), findsOneWidget,
        reason: 'no "Your dice" panel after taking a die');
    expect(find.byKey(Key('tower_die_$gained')), findsOneWidget,
        reason: '$gained is not in the bag after taking it');
    expect(find.byKey(Key('tower_die_new_$gained')), findsOneWidget,
        reason: '$gained is not marked new');
    expect(find.byKey(Key('tower_die_$startInPlay')), findsOneWidget,
        reason: 'the die the hero started with left the bag');

    // open it, put it in play
    await tapKey('tower_die_$gained');
    expect(find.byKey(Key('tower_die_new_$gained')), findsNothing,
        reason: 'the die is still new after being opened');
    final roll = find.byKey(const Key('tower_die_roll'));
    expect((tester.widget(roll) as FilledButton).onPressed, isNotNull,
        reason: '"Roll this die" is disabled for a die not in play');
    await tapKey('tower_die_roll');

    // the choice is saved: the run's die is the gained one
    final prefs = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(prefs.getString(towerRunPrefsKey)!) as Map<String, dynamic>;
    expect(saved['die'], gained,
        reason:
            'the die put in play was not saved (run died: ${saved['die']})');
    // and the panel reads it: that die is now the one in play
    if (find.byKey(const Key('tower_die_roll')).evaluate().isEmpty) {
      await tapKey('tower_die_$gained');
    }
    expect(
        (tester.widget(find.byKey(const Key('tower_die_roll'))) as FilledButton)
            .onPressed,
        isNull,
        reason: 'the die in play still offers "Roll this die"');
  });
}
