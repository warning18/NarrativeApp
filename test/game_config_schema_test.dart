// The New Game Defaults editor (v1.761). Its defaults offered 100 HP and
// 10 damage where the game ships 20 and 2, it had no field for 9 of the
// file's 16 keys, and a save wrote only the fields it showed: one save
// dropped the antidotes, the six stats, luck and perception from the
// override the game starts a new character from.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/game_config_schema.dart';
import 'package:narrative_data_app/screens/game_config_screen.dart';

Map<String, dynamic> _shipped() =>
    jsonDecode(File(gameConfigAssetPath).readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test(
      'every key of game_config.json has a field, its default the shipped '
      'value', () {
    final shipped = _shipped();
    expect([for (final f in gameConfigFields) f.key], shipped.keys.toList());
    for (final f in gameConfigFields) {
      expect(f.defaultValue, shipped[f.key], reason: f.key);
    }
  });

  testWidgets(
      'a save keeps the keys the form does not show, and a blank field '
      'saves as its default', (tester) async {
    // An override saved before v1.761, with a key the form has no field for.
    SharedPreferences.setMockInitialValues({
      gameConfigPrefsKey: json.encode({
        ..._shipped(),
        'gold': 150,
        'futureKey': 7,
      }),
    });
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GameConfigScreen())));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    Finder field(String label) => find.widgetWithText(TextField, label);
    expect(
        find.descendant(of: field('Starting Gold'), matching: find.text('150')),
        findsOneWidget);
    await tester.enterText(field('Max Health'), '');
    await tester.tap(find.byTooltip('Save'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final saved = json.decode(prefs.getString(gameConfigPrefsKey)!)
        as Map<String, dynamic>;
    expect(saved['gold'], 150);
    expect(saved['maxHealth'], 20);
    expect(saved['futureKey'], 7);
    expect(saved['antidoteCount'], 1);
    expect(saved['perception'], 1);
  });
}
