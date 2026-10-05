// The race and profession tiles (v1.198): a preset's picture comes from
// its own record, and a picture the build does not carry (a preset added
// in the Data tab) shows the generic mark instead of breaking the first
// screen of a new game (v1.201.2).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/utils/game_icons.dart';
import 'package:narrative_data_app/utils/pixel_icons/pixel_icon.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  // The asset loads (or fails) off the frame.
  for (var i = 0; i < 4; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
}

void main() {
  testWidgets('a preset with no picture shows the generic mark',
      (tester) async {
    await _pump(tester, const PresetMark(folder: 'races', preset: {}));
    expect(find.byIcon(raceIcon), findsOneWidget);
    expect(find.byType(PixelIcon), findsNothing);
    await _pump(tester, const PresetMark(folder: 'professions', preset: null));
    expect(find.byIcon(professionIcon), findsOneWidget);
  });

  testWidgets('a preset whose picture is missing falls back to the mark',
      (tester) async {
    await _pump(
        tester,
        const PresetMark(
            folder: 'races', preset: {'visualAsset': 'no_such_race.png'}));
    expect(tester.takeException(), isNull);
    expect(find.byType(PixelIcon), findsOneWidget);
    expect(find.byIcon(raceIcon), findsOneWidget);
  });

  testWidgets('a preset whose picture exists shows it', (tester) async {
    await _pump(tester,
        const PresetMark(folder: 'races', preset: {'visualAsset': 'elf.png'}));
    expect(tester.takeException(), isNull);
    expect(find.byType(PixelIcon), findsOneWidget);
    expect(find.byIcon(raceIcon), findsNothing);
  });
}
