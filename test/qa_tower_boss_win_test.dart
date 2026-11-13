// QA guard for #949 (found by the Tower playthrough of main 1.906): winning a
// warden or boss floor of the Tower, through the REAL fight launcher, lets the
// player leave the fight. Before the fix the story's clans' offer ("A boss
// beaten: the clans come to you with an offer") spun in a dialog for ever and
// "Victory! Return" stayed disabled, so no run could pass floor 5.
//
// Every foe has 1 health so the climb to floor 5 is quick: floors 1 to 4 are
// played through the screens as a player does (fight, Level Up, spoils, the
// oaths), then the warden of floor 5 falls and Return must work.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';

void main() {
  testWidgets('a Tower warden won through the real launcher lets you leave',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final foes =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    // A saved run of a fixed seed (the creation screen deals a random one):
    // the same floors, foes and cards every time.
    final run = towerStart(
        seed: 5,
        raceId: 'human',
        professionId: 'warrior',
        data: towerDataFromAssets());
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
      'gamedb_enemies': jsonEncode({
        for (final e in foes.entries)
          e.key: {...(e.value as Map<String, dynamic>), 'maxHealth': 1},
      }),
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

    bool has(String key) => find.byKey(Key(key)).evaluate().isNotEmpty;
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
      // A list estimates what it has not laid out yet: the first scroll can
      // stop short of the real end, so it is asked once more.
      await tester.pump();
      await tester.ensureVisible(f.first);
      await tester.tap(f.first);
      await settle();
    }

    await settle(10);
    await tester.ensureVisible(find.byKey(const Key('menu_tower')));
    await tapKey('menu_tower');
    await tapKey('tower_continue');
    await settle(10);

    var floor = 0;
    var wardenWon = false;
    for (var step = 0; step < 300 && !wardenWon; step++) {
      if (has('tower_fight')) {
        floor++;
        await tapKey('tower_fight');
        await settle(10);
        final enter = find.text('Enter Battle');
        if (enter.evaluate().isNotEmpty) {
          await tester.ensureVisible(enter);
          await tester.pump();
          await tester.tap(enter);
          await settle(10);
        }
        String onScreen() => [
              for (final e in find.byType(Text).evaluate())
                if ((e.widget as Text).data case final String t
                    when t.isNotEmpty)
                  t
            ].take(40).join(' | ');
        for (var i = 0; i < 300; i++) {
          final back = find.text('Victory! Return');
          if (back.evaluate().isNotEmpty) break;
          // The fight's screen loads its foes in the background: on a slow
          // runner "Enter Battle" can come after the first look, so it is
          // answered whenever it is on the screen, not only once.
          final enter = find.text('Enter Battle');
          final confirm = find.text('Confirm');
          final roll = find.textContaining('Roll Dice');
          if (enter.evaluate().isNotEmpty) {
            await tester.ensureVisible(enter);
            await tester.pump();
            await tester.tap(enter);
          } else if (confirm.evaluate().isNotEmpty) {
            await tester.tap(confirm.first);
          } else if (roll.evaluate().isNotEmpty) {
            await tester.tap(roll.first);
          }
          await tester.pump(const Duration(milliseconds: 400));
          // Real time for what loads in the background (not the fake clock).
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
        }
        // The Return button must come, and must work, within a few seconds.
        final back = find.text('Victory! Return');
        expect(back, findsOneWidget,
            reason: 'floor $floor: no Return button after 300 rounds'
                '${find.text('Face what comes').evaluate().isNotEmpty ? ' (the hero was beaten)' : ''}'
                '. On screen: ${onScreen()}');
        final button = find.ancestor(
            of: back,
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
        var ready = false;
        for (var i = 0; i < 60 && !ready; i++) {
          // A hunter among the foes asks the story's question first (spare
          // it or finish it): answer, as a player does.
          if (has('mercy_finish')) {
            await tester.tap(find.byKey(const Key('mercy_finish')));
            await settle(8);
          }
          ready = (tester.widget(button.first) as ButtonStyleButton).enabled;
          if (!ready) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 250)));
            await tester.pump(const Duration(milliseconds: 250));
          }
        }
        expect(ready, isTrue,
            reason: 'floor $floor: "Victory! Return" never became enabled: '
                'the fight cannot be left (#949). Dialogs: ${{
              for (final e in find
                  .byWidgetPredicate((w) =>
                      '${w.runtimeType}'.contains('Dialog') ||
                      '${w.runtimeType}'.contains('Sheet') ||
                      '${w.runtimeType}'.contains('Loading'))
                  .evaluate())
                '${e.widget.runtimeType}'
            }}. On screen: ${[
              for (final e in find.byType(Text).evaluate())
                if ((e.widget as Text).data case final String t
                    when t.isNotEmpty)
                  t
            ].take(40).join(' | ')}');
        await tester.tap(back.first);
        for (var i = 0;
            i < 60 && find.text('Victory! Return').evaluate().isNotEmpty;
            i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)));
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(find.text('Victory! Return'), findsNothing,
            reason:
                'floor $floor: the fight is still on screen after Return (#949)');
        await settle(6);
        if (floor == 5) wardenWon = true;
        continue;
      }
      if (find.byType(LevelUpScreen).evaluate().isNotEmpty) {
        final take = find.text('Take this pick');
        if (take.evaluate().isNotEmpty) {
          final card = find.textContaining(RegExp(
              r'^(Constitution|Strength|Dexterity|Intelligence|Wisdom|Perception|Luck|Charisma)$'));
          if (card.evaluate().isNotEmpty) await tester.tap(card.first);
          await settle();
          await tester.ensureVisible(take);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.tap(take);
          await settle(10);
        }
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await settle(10);
        continue;
      }
      if (find.text('What the spoils change').evaluate().isNotEmpty) {
        await tester.tap(find.text('Take'));
        await settle(10);
        continue;
      }
      if (has('tower_take') || has('tower_refuse')) {
        await tapKey(has('tower_take') ? 'tower_take' : 'tower_refuse');
        continue;
      }
      fail('stuck on an unknown screen at step $step (floor $floor)');
    }
    expect(wardenWon, isTrue, reason: 'floor 5 was never won');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
