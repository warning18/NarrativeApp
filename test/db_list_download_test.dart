// A collection's own Download sheet (records as JSON or CSV, its texts in
// English and French), on a screen as narrow as a phone's.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/screens/game_db_list_screen.dart';

void main() {
  testWidgets('a collection downloads on its own, and fits a phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // A phone's width: the collection's filter must not push the search
    // box off the row, whatever its label.
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: GameDbListScreen(schema: enemyShipsSchema)),
    ));
    for (var i = 0;
        i < 10 && find.text('raider_skiff').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(find.text('raider_skiff'), findsOneWidget);

    await tester.tap(find.byKey(const Key('db_download')));
    await tester.pumpAndSettle();
    expect(find.text('Records (JSON)'), findsOneWidget);
    expect(find.text('Records (CSV)'), findsOneWidget);
    expect(find.text('Texts (CSV)'), findsOneWidget);
    expect(find.textContaining('enemy_ships_texts.csv'), findsOneWidget);
  });
}
