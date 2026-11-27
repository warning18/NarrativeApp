// QA guard (user bug, v2.10.27): in the Tower, going back to the menu and
// pressing Continue climb rolled the floor's check again ("You catch yourself
// at floor 2 / You roll 14, total 16 against 10", the tread hazard): every
// resume re-rolled it, so a failed check could be retried. A check is rolled
// once, when the floor is entered, and its result belongs to the run.
//
// Engine: for every kind of floor event, over many seeds, a run mid-floor
// after its event is saved, loaded and read again several times: nothing in
// it moves (the check's result, health, coins, potions, the floor, the
// items), and reading it as a card changes nothing either. App: the same run
// is put in the real app; Tower, Continue and Back to the menu five times: the
// card says the same roll every time and the saved run is byte for byte the
// one that was put there.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'dart:math';

import 'support/pump.dart';

void main() {
  // These test the rule as it rolls when the run moves on (the event modal off).
  setUp(() => towerEventModalOverride = false);
  tearDown(() => towerEventModalOverride = null);
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();

  /// Runs as the app saves them just after an event's result: the bot's
  /// climbs on the app's rules, every state a pick leaves with a result of
  /// [kind] on it (the check rolled, the rival met...), up to [count].
  List<TowerRun> afterEvent(TowerEventKind kind, int count) {
    final found = <TowerRun>[];
    for (var seed = 1; seed <= 120 && found.length < count; seed++) {
      playTowerRun(
          seed: seed,
          data: data,
          progress: towerAllUnlocked,
          events: towerEventsLive,
          rules: towerRulesLive,
          choice: (run) {
            final index = towerBotChoice(run, clans: data.clans);
            final post =
                towerPick(run, data, index, hero: towerHeroOf(run, data));
            if (found.length < count &&
                post.status == TowerStatus.climbing &&
                post.lastEvent?.kind == kind &&
                post.lastEvent?.from == run.floor) {
              found.add(post);
            }
            return index;
          });
    }
    return found;
  }

  TowerRun reload(TowerRun run) =>
      TowerRun.fromJson(jsonDecode(jsonEncode(run.toJson())));

  test('a check, a rival, a shortcut: reloading a run never moves it', () {
    var checked = 0;
    for (final kind in [
      TowerEventKind.test,
      TowerEventKind.rival,
      TowerEventKind.shortcut,
    ]) {
      final runs = afterEvent(kind, 12);
      for (final run in runs) {
        final before = jsonEncode(run.toJson());
        var read = run;
        for (var i = 0; i < 5; i++) {
          read = reload(read);
          expect(jsonEncode(read.toJson()), before,
              reason:
                  'seed ${run.seed} floor ${run.floor} ($kind), load ${i + 1}');
          // Reading the run as its card does moves nothing.
          towerEventOf(read, data);
          expect(jsonEncode(read.toJson()), before,
              reason:
                  'seed ${run.seed} floor ${run.floor} ($kind), card ${i + 1}');
        }
        checked++;
      }
      if (kind == TowerEventKind.test) {
        expect(runs.length, greaterThanOrEqualTo(8), reason: 'too few checks');
      }
    }
    expect(checked, greaterThan(10));
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('Continue climb after a check shows the same roll, every time',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // A run that has just failed or passed a check.
    final checks = afterEvent(TowerEventKind.test, 1);
    expect(checks, isNotEmpty, reason: 'no check on the bot\'s climbs');
    final run = checks.first;
    final before = jsonEncode(run.toJson());
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: before,
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
    });
    usePhone(tester, const Size(412, 860));

    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapKey(String key) async {
      final f = find.byKey(Key(key));
      for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
        final lists = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        if (lists.evaluate().isEmpty) break;
        await tester.drag(lists.first, const Offset(0, -200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(f, findsWidgets, reason: 'no "$key" on the screen');
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await settle();
    }

    Future<String> saved() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getString(towerRunPrefsKey) ?? '';
    }

    String rollText() => [
          for (final e in find.byType(Text).evaluate())
            if ((e.widget as Text).data case final String t
                when t.contains('You roll') ||
                    t.contains(' + ') && t.contains('='))
              t
        ].join(' | ');

    await tester.pumpWidget(ProviderScope(overrides: [
      fightRandomProvider.overrideWithValue(() => Random(7)),
    ], child: const MyApp()));
    await settle(10);
    String? firstRoll;
    for (var i = 0; i < 5; i++) {
      await tapKey('menu_tower');
      // Continue, and watch the card from its first frame: a result already
      // rolled is shown landed, its die never tumbling through other numbers
      // (it looked like the roll was made again).
      final go = find.byKey(const Key('tower_continue'));
      await tester.ensureVisible(go.first);
      await tester.pump();
      await tester.tap(go.first);
      final shown = <String>[];
      for (var f = 0; f < 60; f++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 40));
        final die = find.byKey(const Key('tower_event_d20'));
        if (die.evaluate().isNotEmpty) {
          shown.add([
            for (final e in find
                .descendant(of: die, matching: find.byType(Text))
                .evaluate())
              (e.widget as Text).data ?? ''
          ].join());
        }
      }
      expect(shown, isNotEmpty, reason: 'resume ${i + 1}: no d20 on the card');
      expect(shown.toSet(), {'${run.lastEvent!.roll}'},
          reason: 'resume ${i + 1}: the die tumbled through ${shown.toSet()} '
              'before landing on ${run.lastEvent!.roll}: the roll looks made '
              'again');
      final text = rollText();
      firstRoll ??= text;
      expect(text, isNotEmpty, reason: 'resume ${i + 1}: no roll on the card');
      expect(text, firstRoll, reason: 'resume ${i + 1} shows another roll');
      expect(await saved(), before,
          reason: 'resume ${i + 1} changed the saved run');
      // Back to the menu.
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await settle();
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await settle();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
