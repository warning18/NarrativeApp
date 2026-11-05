// The Tower's climb screens (v1.848): the floor with its ladder, a fight
// played by a fake launcher, the cards after a win (take one, or none), the
// end of a run on a loss. The real fight is wired apart; here it is a stub.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The tables, read once: a second container asking the game data again
/// waits on the first one's load, so the tests hand them over.
TowerData? _data;

Future<ProviderContainer> _open(
  WidgetTester tester, {
  TowerFightLauncher? fight,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(prefs);
  usePhone(tester, const Size(400, 1400));
  if (_data == null) {
    final first = ProviderContainer();
    _data = await tester.runAsync(() => first.read(towerDataProvider.future));
    for (var i = 0; i < 40 && _data == null; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
  }
  final container = ProviderContainer(overrides: [
    if (fight != null) towerFightLauncherProvider.overrideWithValue(fight),
    towerDataProvider.overrideWith((ref) async => _data!),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: TowerFloorScreen()),
  ));
  await _settle(tester);
  return container;
}

/// A floor that gained a level opens the main game's Level Up screen before
/// the cards; most tests go past it.
Future<void> _pastLevelUp(WidgetTester tester) async {
  final screen = find.byType(LevelUpScreen);
  if (screen.evaluate().isEmpty) return;
  Navigator.of(tester.element(screen)).pop();
  await _settle(tester);
}

const _fresh = TowerRun(
  seed: 7,
  raceId: 'human',
  professionId: 'warrior',
  health: 20,
);

void main() {
  Map<String, Object> saved(TowerRun run) =>
      {towerRunPrefsKey: jsonEncode(run.toJson())};

  testWidgets(
      'the floor shows its ladder and foes; a win offers cards, one is taken',
      (tester) async {
    await _open(tester,
        fight: (context, run, data) async =>
            TowerFightResult(won: true, healthLeft: run.health),
        prefs: saved(_fresh));
    expect(find.text('Floor 1 of 30'), findsOneWidget);
    expect(find.byKey(const Key('tower_ladder')), findsOneWidget);
    expect(find.byKey(const Key('tower_ladder_here')), findsOneWidget);
    expect(find.byKey(const Key('tower_danger_band')), findsNothing);

    await tester.tap(find.byKey(const Key('tower_fight')));
    await _settle(tester);
    expect(find.byType(LevelUpScreen), findsOneWidget,
        reason: 'floor 1 gains a level: its pick comes before the cards');
    await _pastLevelUp(tester);
    expect(find.byKey(const Key('tower_cleared')), findsOneWidget);
    expect(find.byKey(const Key('tower_card_0')), findsOneWidget);
    expect(find.byKey(const Key('tower_card_2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tower_take')));
    await _settle(tester);
    final run = (await TowerSave.open()).loadRun()!;
    expect(run.floor, 2);
    expect(run.status, TowerStatus.climbing);
    expect(run.taken.length, 1);
    expect(find.text('Floor 2 of 30'), findsOneWidget);
  });

  testWidgets('leaving all the cards earns a mark and goes on', (tester) async {
    await _open(tester,
        fight: (context, run, data) async =>
            TowerFightResult(won: true, healthLeft: run.health),
        prefs: saved(_fresh));
    await tester.tap(find.byKey(const Key('tower_fight')));
    await _settle(tester);
    await _pastLevelUp(tester);
    await tester.tap(find.byKey(const Key('tower_refuse')));
    await _settle(tester);
    final run = (await TowerSave.open()).loadRun()!;
    expect(run.floor, 2);
    expect(run.refused, {1});
  });

  testWidgets('a lost fight ends the run on the end screen', (tester) async {
    await _open(tester,
        fight: (context, run, data) async =>
            const TowerFightResult(won: false, healthLeft: 0),
        prefs: saved(_fresh));
    await tester.tap(find.byKey(const Key('tower_fight')));
    await _settle(tester);
    expect(find.byKey(const Key('tower_end_floor')), findsOneWidget);
    final save = await TowerSave.open();
    expect(save.loadRun(), isNull);
    expect(save.loadProgress().runs, 1);
  });

  testWidgets('a boss floor is marked, and a fight not begun changes nothing',
      (tester) async {
    await _open(tester,
        fight: (context, run, data) async => null,
        prefs: saved(_fresh.copyWith(floor: 10)));
    expect(find.byKey(const Key('tower_danger_band')), findsOneWidget);
    expect(find.text('FLOOR 10 · BOSS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower_fight')));
    await _settle(tester);
    expect(find.text('Floor 10 of 30'), findsOneWidget);
    expect(find.byKey(const Key('tower_fight')), findsOneWidget);
    expect((await TowerSave.open()).loadRun()?.floor, 10);
  });

  testWidgets('the real fight runs on the Tower hero, apart from the story',
      (tester) async {
    await _open(tester, prefs: saved(_fresh));
    await tester.tap(find.byKey(const Key('tower_fight')));
    for (var i = 0;
        i < 20 && find.byType(FightScreen).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FightScreen), findsOneWidget);
    // Under the fight, the session is the run's hero's, not the story's.
    final inFight =
        ProviderScope.containerOf(tester.element(find.byType(FightScreen)));
    final hero = inFight.read(playerSessionProvider);
    expect(hero.professionId, 'warrior');
    expect(hero.currentHealth, 20);
    final story = ProviderScope.containerOf(
        tester.element(find.byType(TowerFloorScreen, skipOffstage: false)));
    expect(identical(inFight, story), isFalse);
    expect(story.read(playerSessionProvider).professionId, isNot('warrior'));
    // A win comes back to the floor's cards.
    Navigator.of(tester.element(find.byType(FightScreen))).pop(true);
    await _settle(tester);
    await _pastLevelUp(tester);
    expect(find.byKey(const Key('tower_cleared')), findsOneWidget);
  });

  testWidgets(
      'the first win offers a clan\'s oath; swearing shows it on the floor',
      (tester) async {
    await _open(tester,
        fight: (context, run, data) async =>
            TowerFightResult(won: true, healthLeft: run.health),
        prefs: saved(_fresh));
    expect(find.byKey(const Key('tower_sworn')), findsOneWidget);
    expect(find.text('Unsworn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower_fight')));
    await _settle(tester);
    await _pastLevelUp(tester);
    // Core's rule: the first floor won always offers an oath.
    final offer = (await TowerSave.open()).loadRun()!.offer;
    final at = offer.indexWhere((r) => r.kind == TowerRewardKind.clanOath);
    expect(at, isNonNegative);
    expect(offer[at].kind, TowerRewardKind.clanOath);
    await tester.tap(find.byKey(Key('tower_card_$at')));
    await tester.pump();
    expect(find.text('Swear'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower_take')));
    await _settle(tester);
    final run = (await TowerSave.open()).loadRun()!;
    expect(run.clanIds, [offer[at].id]);
    expect(run.floor, 2);
    expect(find.text('Unsworn'), findsNothing);
  });
}
