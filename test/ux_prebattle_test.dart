// The fight's slots, dice board and kept row (combat redesign A''): three
// equal slots a side, a head and icons for each fighter, a tap on a die to
// pick it (its line to the target shows) and a second to keep it, a double
// tap on the kept row to put it back, the keep final after a new roll, and
// the pop-in of an effect icon.
import 'dart:convert';

import 'dart:math';

import 'package:flutter/material.dart';
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
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

import 'package:narrative_data_app/widgets/head_avatar.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';
import 'support/fonts.dart';
import 'skill_fight_harness.dart'
    show gamedata, pumpUntil, settle, shows, tapWhenEnabled;
import 'support/pump.dart';

bool _dark = false;
Future<void> _enter(WidgetTester tester,
    {List<SideLayer>? land,
    double w = 412,
    String id = 'slum_thug',
    List<String> more = const []}) async {
  SharedPreferences.setMockInitialValues({
    // The dice thrown at 4x: the tests wait a quarter of the throw (the
    // default speed is proven by dice_speed_test).
    'combat_dice_speed': 'quad',
    if (_dark) 'app_theme_mode': 'dark',
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
  usePhone(tester, Size(w, 860));
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
        'ownedDiceIds': ['board_die'],
        'equippedDiceId': 'board_die',
        'maxHealth': 400,
        'currentHealth': 400,
      })));
  final thug = {
    ...gamedata('enemies.json')[id] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': <dynamic>[],
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: id,
                landLayers: land,
                enemy: thug,
                additionalEnemyIds: more,
                additionalEnemies: {
                  for (final m in more)
                    m: {
                      ...gamedata('enemies.json')[m] as Map<String, dynamic>,
                      'maxHealth': 900,
                      'skillMoves': <dynamic>[]
                    }
                },
                modifiers: const EncounterModifiers(
                    forcedCondition: BattlefieldCondition.highGround,
                    forcedGoal: FightGoal.slay),
              )));
  await settle(tester);
  Future<void> until(bool Function() f, [int n = 150]) async {
    for (var i = 0; i < n && !f(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await until(() => shows('Enter Battle'));
  for (var i = 0; i < 12; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(FightSpriteImages.reset);
  testWidgets(
      'the setup page: the fighters stand and Enter Battle is at the bottom',
      (tester) async {
    await loadAppFonts();
    await _enter(tester, w: 412, id: 'den_bouncer');
    expect(find.byKey(const Key('fight_figures')), findsOneWidget);
    expect(find.byKey(const Key('fight_figure_hero')), findsOneWidget);
    expect(find.byKey(const Key('fight_figure_den_bouncer')), findsOneWidget);
    final button = tester.getRect(find.text('Enter Battle'));
    expect(button.bottom, greaterThan(860 - 120),
        reason: 'Enter Battle sits at the bottom of the page');
    final figures = tester.getRect(find.byKey(const Key('fight_figures')));
    expect(figures.bottom, lessThan(button.top),
        reason: 'the fighters are above the button');
    // the enemy's portrait is its sprite, cropped
    expect(find.byKey(const Key('head_sprite_den_bouncer')), findsOneWidget);
  });

  testWidgets('a head is cropped from a sprite: a square inside its frame',
      (tester) async {
    for (final set in [
      roninSprite,
      enemyFightSprite('rat_matriarch')!,
      enemyFightSprite('den_bouncer')!,
      enemyFightSprite('plague_hound')!
    ]) {
      await tester.runAsync(() => FightSpriteImages.load(set));
      FightSpriteImages.headOf(set);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      final r = FightSpriteImages.headOf(set);
      expect(r, isNotNull, reason: set.id);
      expect(r!.width, closeTo(r.height, 0.01), reason: '${set.id} is square');
      expect(r.width, greaterThan(6), reason: set.id);
      expect(r.width, lessThanOrEqualTo(set.frameWidth.toDouble() + 2),
          reason: set.id);
      expect(r.top, greaterThanOrEqualTo(-1.01), reason: set.id);
    }
  });
}
