// QA guard (v2.8.4): a Tower fight the app is killed in counts as lost. In the
// real app, from the menu: a floor's fight is entered (the marker is saved at
// its first round, on Enter Battle) and one roll is made; the app is killed
// (the widget tree dropped, the saves kept) and opened again. The run is over
// on that floor: a defeat, its end screen with the line shown once, the run's
// save gone, the next visit at the door. Opening the app again and again does
// not undo it or show it twice. A fight card backed out of before the battle
// is entered is not a fight begun, Back is refused once it is, and a fight
// won leaves no marker: the run goes on.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  String t(String key) => trFor(AppLanguage.en, key);

  Future<void> settle(WidgetTester tester, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The app opened afresh on the saves as they are (the process killed).
  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [
          fightRandomProvider.overrideWithValue(() => Random(7)),
        ],
        child: const MyApp()));
    await settle(tester, 10);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    // The Tower's tables load as the screen opens: give them real time.
    for (var i = 0; i < 80 && f.evaluate().isEmpty; i++) {
      if (find.textContaining('Still gathering').evaluate().isEmpty) break;
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 250));
    }
    // A long page builds its lower part only as it is scrolled to.
    for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
      final lists = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      if (lists.evaluate().isEmpty) break;
      await tester.drag(lists.first, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(f, findsWidgets,
        reason: 'no "$key" on the screen: ${[
          for (final e in find.byType(Text).evaluate())
            if ((e.widget as Text).data case final String d when d.isNotEmpty) d
        ].take(30).join(' | ')}');
    await tester.ensureVisible(f.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(f.first);
    await settle(tester);
  }

  Future<void> openTower(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('menu_tower')));
    await tapKey(tester, 'menu_tower');
  }

  /// The run's save, as the Tower wrote it.
  Future<Map<String, dynamic>?> savedRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(towerRunPrefsKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  /// A floor's fight opened from the Tower's stand, past the pre-battle card.
  Future<void> enterFight(WidgetTester tester) async {
    await tapKey(tester, 'tower_fight');
    final enter = find.text(t('enter_battle_button'));
    if (enter.evaluate().isNotEmpty) {
      await tester.ensureVisible(enter);
      await tester.pump();
      await tester.tap(enter);
      await settle(tester, 10);
    }
  }

  Future<void> setup(WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    final initial = <String, Object>{
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
      towerRunPrefsKey: jsonEncode(towerStart(
        seed: 5,
        raceId: 'human',
        professionId: 'warrior',
        data: towerDataFromAssets(),
      ).toJson()),
    };
    SharedPreferences.setMockInitialValues(initial);
    // A test after another finds its saves: wipe them, put the start back.
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      for (final e in initial.entries) {
        final v = e.value;
        if (v is bool) await prefs.setBool(e.key, v);
        if (v is String) await prefs.setString(e.key, v);
      }
    });
    usePhone(tester, const Size(412, 860));
  }

  Future<void> lostOnce(WidgetTester tester) async {
    await setup(tester);
    await openApp(tester);
    await openTower(tester);
    await tapKey(tester, 'tower_continue');
    expect((await savedRun())!.containsKey('fighting'), isFalse);
    await enterFight(tester);
    await tester.tap(find.textContaining(t('roll_dice_button')).first);
    await settle(tester, 10);
    // The marker is on the disk from the first roll.
    expect((await savedRun())!['fighting'], isTrue);

    // Killed. Opened again: the Tower shows its end, with the line.
    await openApp(tester);
    await openTower(tester);
    expect(find.byType(TowerEndScreen), findsOneWidget);
    expect(find.text(t('tower_fight_left')), findsOneWidget);
    expect(await savedRun(), isNull, reason: 'the lost run stays saved');

    // Shown once: back to the door, and the run does not come back.
    await openApp(tester);
    await openTower(tester);
    expect(find.byType(TowerEndScreen), findsNothing);
    expect(find.text(t('tower_fight_left')), findsNothing);
    expect(find.byKey(const Key('tower_continue')), findsNothing,
        reason: 'the lost run can be continued');
    expect(find.byKey(const Key('tower_climb')), findsOneWidget);
    expect(await savedRun(), isNull);
  }

  Future<void> lostAgain(WidgetTester tester) async {
    await setup(tester);
    await openApp(tester);
    await openTower(tester);
    await tapKey(tester, 'tower_continue');
    await enterFight(tester);
    await tester.tap(find.textContaining(t('roll_dice_button')).first);
    await settle(tester, 10);
    // Killed before the end screen is ever seen: the app opens twice on the
    // game's menu without visiting the Tower; the loss waits for the door.
    await openApp(tester);
    await openApp(tester);
    await openTower(tester);
    expect(find.byType(TowerEndScreen), findsOneWidget);
    expect(find.text(t('tower_fight_left')), findsOneWidget);
  }

  Future<void> leftBeforeRoll(WidgetTester tester) async {
    await setup(tester);
    await openApp(tester);
    await openTower(tester);
    await tapKey(tester, 'tower_continue');
    // The fight's card is opened, the battle not entered: back out.
    await tapKey(tester, 'tower_fight');
    expect(find.text(t('enter_battle_button')), findsOneWidget,
        reason: 'the pre-battle card is not there');
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    await tester.runAsync(nav.maybePop);
    await settle(tester, 10);
    final saved = await savedRun();
    expect(saved, isNotNull);
    expect(saved!.containsKey('fighting'), isFalse,
        reason: 'a fight not entered is marked begun');

    await openApp(tester);
    await openTower(tester);
    expect(find.byType(TowerEndScreen), findsNothing);
    expect(find.byKey(const Key('tower_continue')), findsOneWidget);

    // Once the battle is entered the screen does not let go: Back is refused
    // and the marker stays (the app killed there is the first scenario).
    await tapKey(tester, 'tower_continue');
    await enterFight(tester);
    expect((await savedRun())!['fighting'], isTrue);
    final nav2 = tester.state<NavigatorState>(find.byType(Navigator).first);
    await tester.runAsync(nav2.maybePop);
    await settle(tester, 6);
    expect(find.textContaining('The fight is not over'), findsOneWidget,
        reason: 'Back left a fight begun');
    expect((await savedRun())!['fighting'], isTrue);
  }

  Future<void> wonThenKilled(WidgetTester tester) async {
    await setup(tester);
    await openApp(tester);
    await openTower(tester);
    await tapKey(tester, 'tower_continue');
    await enterFight(tester);
    final back = find.text(t('victory_return_button'));
    for (var i = 0; i < 400 && back.evaluate().isEmpty; i++) {
      final confirm = find.text(t('confirm_roll_button'));
      final roll = find.textContaining(t('roll_dice_button'));
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm.first);
      } else if (roll.evaluate().isNotEmpty) {
        await tester.tap(roll.first);
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    expect(back, findsWidgets, reason: 'floor 1 was not won');
    for (var i = 0; i < 120; i++) {
      final b = find.ancestor(
          of: back,
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      if (b.evaluate().isNotEmpty &&
          (b.evaluate().first.widget as ButtonStyleButton).enabled) {
        break;
      }
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.tap(back.first);
    await settle(tester, 20);

    // Killed on the floors' stand: nothing was left mid-fight.
    final saved = await savedRun();
    expect(saved, isNotNull);
    expect(saved!.containsKey('fighting'), isFalse);
    await openApp(tester);
    await openTower(tester);
    expect(find.byType(TowerEndScreen), findsNothing);
    expect(find.byKey(const Key('tower_continue')), findsOneWidget);
    final after = await savedRun();
    expect(after!['floorsCleared'] ?? after['floor'], isNotNull);
  }

  // One test: the Tower's tables stay loading for a second test of the file
  // (its saves outlive a run inside one), so the scenarios run in turn, each
  // on saves wiped and put back.
  testWidgets('a Tower fight the app is killed in counts as lost',
      (tester) async {
    await lostOnce(tester);
    await lostAgain(tester);
    await leftBeforeRoll(tester);
    await wonThenKilled(tester);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
