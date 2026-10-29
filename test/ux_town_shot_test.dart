// The Town view of wave 18 (v1.572) as the app draws it: Saltmouth with a
// district shut, holders' flags, influence, and a district that changed
// hands. With UX_SHOTS (a folder) set it saves the real screen as pictures.
//   UX_SHOTS=docs/ux-shots flutter test test/ux_town_shot_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/district_influence.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) {
    test('the Town view picture is taken only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the Town view, shut and held', (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 1000));

    final data = ClanData.fromTables(
      factions: _table('factions'),
      subclans: _table('subclans'),
      relations: _table('relations'),
      titles: _table('titles'),
    );
    final geo = Geography.parse(
        geography: _table('geography'), biomes: _table('biomes'));
    // The Dominion's quests in the yard (not yet enough) and in Card Row
    // (enough: it changed hands); the Crows push a little in the yard too.
    var politics = PoliticsState.empty;
    var flags = <String>[];
    void push(String district, String clan, int times) {
      for (var i = 0; i < times; i++) {
        final r = addInfluence(politics, district, clan, sideQuestInfluence,
            flags: flags, data: data, geography: geo);
        politics = r.state;
        flags = r.flags;
      }
    }

    push('saltmouth_yard', 'dominion', 1);
    push('saltmouth_yard', 'crows', 1);
    push('saltmouth_wharf', 'compact', 1);
    push('saltmouth_card_row', 'dominion', 3);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          // Tern Row's quest is done; the Alleys' is not.
          'completedQuestIds': ['q_ch2_terns_toll'],
          'flags': flags,
          'politics': politics.toJson(),
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settleApp(tester);
    container.read(storyPlayProvider.notifier).jumpTo('2021');
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.byKey(const Key('journey_tab_town')),
        warnIfMissed: false);
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 2));

    Future<void> save(String name) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find
          .descendant(
              of: find.byType(MaterialApp),
              matching: find.byType(RepaintBoundary))
          .first);
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await save('town-view-1');
    final list = find.byKey(const ValueKey('journey_city_list'));
    tester
        .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)))
        .position
        .jumpTo(1000);
    await tester.pump(const Duration(milliseconds: 300));
    await save('town-view-2');
    // A tap on the shut district opens its sheet (not in the picture: the
    // sheet is drawn on the route's overlay).
    tester
        .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)))
        .position
        .jumpTo(0);
    await tester.pump(const Duration(milliseconds: 300));
    final shut = find.byKey(
        const ValueKey('journey_city_district_saltmouth_lantern_alleys'));
    await tester.ensureVisible(shut);
    await tester.tap(shut);
    await tester.pump(const Duration(milliseconds: 600));
    expect(
        find.byKey(const Key('district_locked_sheet_saltmouth_lantern_alleys')),
        findsOneWidget);
  });
}
