// The camp's town view: a tap on a built building tells what it is and what
// it gives (v1.269), and the Shroud card is one row of six small banners.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:narrative_data_app/data/cliff_town.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('a tap on a built building shows its name and what it gives',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final houses =
        json.decode(File('assets/gamedata/houses.json').readAsStringSync())
            as Map<String, dynamic>;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampTownSection(
              houses: houses,
              shops: const {},
              zones: const {},
              achievements: const {},
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(CampTownSection)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'gold': 0,
          'builtHouseIds': ['hammersmith'],
        })));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Where the smithy stands on the screen: the town is laid out from the
    // bottom of its box, a harbour deep.
    final town = CliffTown.build(const ['hammersmith']);
    final piece = town.pieces.single;
    final box = tester.getRect(find.byKey(const Key('cliff_town')));
    final scale = box.width / townWidth;
    final at = Offset(
      box.left +
          (townCliffWidth +
                  (piece.column + piece.footprint.width / 2) * townCellWidth) *
              scale,
      box.bottom -
          (townHarborHeight + (piece.row + piece.footprint.height / 2) * 46) *
              scale,
    );
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('town_piece_info')), findsOneWidget);
    expect(find.text('Hammersmith'), findsWidgets);
  });
}
