// Warding the road in the app (wave 16, UX): the Banish power opens "Ward
// the road" when a clan hunts you (even with no card to banish), the sheet
// wards for 3, 6 or 9 roads against the charges, and the Journey's mark
// reads the ward until it runs out.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/data/map_charts.dart' show ChartPalette;
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/roll_power_row.dart';
import 'package:narrative_data_app/widgets/ward_mark.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  // The Compact is the nemesis: it hunts sworn or not.
  final hunted = updateNemesis(
      setStandingValue(PoliticsState.empty, 'compact', -40, 'edit', data: data)
          .state,
      data,
      chapter: 3);

  Future<ProviderContainer> open(WidgetTester tester,
      {PoliticsState? politics, int charges = 3}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      for (final schema in [
        factionsSchema,
        subclansSchema,
        relationsSchema,
        titlesSchema,
      ]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
      await notifier.loadSession(PlayerSession.fromJson({
        ...baseSession(builtHouseIds: const ['warding_cairn']).toJson(),
        'banishCharges': charges,
      }).copyWith(politics: politics ?? hunted));
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Column(children: [
              RollPowerRow(
                keyPrefix: 't',
                rolls: ref.watch(campRollsProvider),
                onReroll: () async {},
                onBanish: (_) async {},
                onRaise: () async {},
              ),
              WardMark(palette: ChartPalette.of(MapLook.night)),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump();
    return container;
  }

  testWidgets(
      'with a hunter, Banish wards the road with no card picked; the charges '
      'pay and the mark reads', (tester) async {
    final container = await open(tester);
    await tester.tap(find.byKey(const Key('t_roll_banish')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ward_sheet_title')), findsOneWidget);
    // Three charges: all three lengths can be paid.
    for (final roads in [3, 6, 9]) {
      expect(find.byKey(Key('ward_option_$roads')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('ward_option_6')));
    // The save is written in real time; then the sheet closes and the toast
    // shows, before its few seconds are over.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final s = container.read(playerSessionProvider);
    expect(s.banishCharges, 1);
    expect(roadWardsOfSession(container), [('compact', 6)]);
    expect(find.byKey(const Key('ward_set_toast')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_ward_mark')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('journey_ward_mark')))
            .data,
        contains('6'));
  });

  testWidgets('what the charges cannot pay stands dim; no hunter, no ward',
      (tester) async {
    final container = await open(tester, charges: 1);
    await tester.tap(find.byKey(const Key('t_roll_banish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ward_option_9')));
    await tester.pumpAndSettle();
    // Nine roads cost 3: nothing was spent, the sheet is still up.
    expect(container.read(playerSessionProvider).banishCharges, 1);
    expect(find.byKey(const Key('ward_sheet_title')), findsOneWidget);
    expect(roadWardsOfSession(container), isEmpty);
  });

  testWidgets('nobody hunting: Banish needs a card, as before', (tester) async {
    await open(tester, politics: PoliticsState.empty);
    final button = tester.widget<InkWell>(find
        .descendant(
            of: find.byKey(const Key('t_roll_banish')),
            matching: find.byType(InkWell))
        .first);
    expect(button.onTap, isNull);
  });
}

List<(String, int)> roadWardsOfSession(ProviderContainer c) => [
      for (final w in c.read(roadWardsProvider)) (w.clanId, w.roadsLeft),
    ];
