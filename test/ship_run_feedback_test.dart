// Running for it, told plainly (v1.184): far off, the range bracket and
// the run button say how many turns of running are still needed, and with
// the hull under 30% the dock says to run while there is time. On a
// 360x640 phone the Eel's small bow tile holds its hand and its pips
// without spilling over.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The app's own fonts, so the tiles and chips take the room they take on
/// a phone.
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

ShipCrew _hand(String id, {bool player = false}) => ShipCrew(
      id: id,
      name: id,
      strength: 3,
      dexterity: 3,
      constitution: 3,
      wisdom: 3,
      health: 50,
      maxHealth: 50,
      isPlayer: player,
    );

void main() {
  testWidgets('the turns still to run, and the warning when hull runs low',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    // A 360x640 phone, as the voyage shows a battle: its status bar, the
    // app's bottom margin, the voyage's bar.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);

    final eel = buildPlayerShip(
        ship: _data('ships')['rusty_eel'] as Map<String, dynamic>,
        parts: _data('ship_parts'),
        installedPartIds: const ['ballista', 'harpoon_rack', 'iron_plating'],
        currentHull: 20);
    await tester.pumpWidget(ProviderScope(
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
            enemy: buildEnemyShip(
                _data('enemy_ships')['void_barge'] as Map<String, dynamic>),
            shipName: 'The Rusty Eel',
            enemyName: 'Void Barge',
            enemyShipId: 'void_barge',
            // A hand at every station, the bow's bulwark among them.
            crew: [
              _hand('player', player: true),
              _hand('kelda'),
              _hand('liora'),
              _hand('grosh'),
            ],
            foresight: false,
            random: Random(4),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    // The short layout's small bow tile: the hand and the pips fit.
    expect(tester.takeException(), isNull);
    expect(
        tester.getSize(find.byKey(const Key('ship_room_eel_bulwark'))).height,
        lessThan(30));

    // Under 30% of her hull: the dock says to run.
    final hint = tester.widget<Text>(find.byKey(const Key('ship_hint')));
    expect(hint.data, contains('Hull under 30%'));

    // Far off, the bracket and the run button count the turns of running
    // still needed.
    await tester.tap(find.byKey(const Key('ship_pull_away')));
    await tester.pump();
    Text label() =>
        tester.widget<Text>(find.byKey(const Key('ship_range_label')));
    expect(label().data, 'Long range · run: 3 to go');
    final run = find.ancestor(
        of: find.byKey(const Key('ship_run_button')),
        matching: find.byType(Tooltip));
    expect(tester.widget<Tooltip>(run.first).message,
        contains('still needed to get away: 3'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
