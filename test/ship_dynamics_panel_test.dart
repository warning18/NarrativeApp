// v1.190 on the panel: the enemy's intent under its name (hidden by the
// fog, shown when it lifts), the bolt in the dock that pushes a room past
// its limit (the guns, and a gun a step short is ready to fire), all on a
// 360x640 phone: the dock's row with the crew, the push, the boarding and
// End turn fits, in English and in French.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

/// A Random that plays back the rolls it is given, then 0.5 for ever.
class _Rolls implements Random {
  _Rolls(this.doubles);

  final List<double> doubles;
  int _d = 0;

  @override
  double nextDouble() => _d < doubles.length ? doubles[_d++] : 0.5;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

/// The app's own fonts, so the chips and buttons take the room they take
/// on a phone.
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
}

void main() {
  testWidgets('the intent shows and hides in fog; a push readies a gun',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    await tester.runAsync(_loadFonts);
    // A 360x640 phone, as the voyage shows a battle.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    // The boarding crew's records, for the Board button.
    await tester.runAsync(() =>
        container.read(gameDbProvider(enemiesSchema).notifier).whenLoaded());

    final eel = ShipState(
      hull: 100,
      maxHull: 100,
      layers: 1,
      rooms: {for (final r in ShipRoom.values) r: const RoomState(level: 1)},
      weapons: const [
        ShipWeapon(
            id: 'ballista',
            name: 'Ballista',
            nameFr: 'Baliste',
            damage: 12,
            chargeTurns: 1),
        ShipWeapon(
            id: 'carronade',
            name: 'Carronade',
            nameFr: 'Caronade',
            damage: 22,
            chargeTurns: 2),
      ],
    );
    // A rammer with its rail open and a slow gun that never fires.
    final enemy = buildEnemyShip(const {
      'maxHull': 80,
      'rooms': {'helm': 2, 'guns': 1, 'bulwark': 0, 'hold': 1},
      'weapons': [
        {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
      ],
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        builder: (context, child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Voyage')),
          body: ShipBattlePanel(
            player: eel,
            enemy: enemy,
            shipName: 'The Rusty Eel',
            enemyName: 'Raider',
            crew: const [
              ShipCrew(
                id: 'player',
                name: 'Ada',
                strength: 3,
                dexterity: 3,
                constitution: 3,
                wisdom: 3,
                health: 50,
                maxHealth: 50,
                isPlayer: true,
              ),
            ],
            foresight: false,
            // Fog now, calm next round; then every roll 0.5.
            random: _Rolls([0.9, 0.6]),
            habit: EnemyHabit.ram,
            boarding: const BoardingProfile(crew: ['harbor_rat']),
            rules: const ShipBattleRules(seaEvents: false),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);

    String intent() => tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(const Key('ship_enemy_intent')),
            matching: find.byType(Text)))
        .single
        .data!;

    // In the fog its intent (closing in to ram) is hidden.
    expect(intent(), 'Hidden by the fog');

    // The carronade is a step short: push the guns.
    InkWell weapon(String id) =>
        tester.widget<InkWell>(find.byKey(Key('ship_weapon_$id')));
    expect(weapon('carronade').onTap, isNull);
    await tester.tap(find.byKey(const Key('ship_push_button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('ship_push_sheet')), findsOneWidget);
    expect(find.text('Strain 30%'), findsWidgets);
    await tester.tap(find.byKey(const Key('ship_push_guns')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('ship_push_sheet')), findsNothing);
    expect(weapon('carronade').onTap, isNotNull, reason: 'ready to fire');
    expect(
        tester
            .widget<IconButton>(find.byKey(const Key('ship_push_button')))
            .onPressed,
        isNull,
        reason: 'once a turn');

    // End the turn: it closes in; the fog lifts and its ram shows.
    await tester.tap(find.byKey(const Key('ship_end_turn')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(intent(), 'Coming about to ram');
    expect(tester.takeException(), isNull);

    // Side by side with its rail open, the dock holds the crew, the push,
    // the boarding and End turn, all on the phone's width.
    void dockFits() {
      expect(find.byKey(const Key('ship_board_button')), findsOneWidget);
      for (final key in [
        'ship_crew_button',
        'ship_push_button',
        'ship_board_button',
        'ship_end_turn'
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(360), reason: key);
      }
      expect(tester.takeException(), isNull);
    }

    dockFits();

    // And in French.
    container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.fr);
    await tester.pump();
    expect(intent(), 'Vire pour éperonner');
    dockFits();

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
