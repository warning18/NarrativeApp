// Pictures of the district view as places (v1.586), drawn only with UX_SHOTS (a
// folder): UX_SHOTS=docs/ux-shots flutter test test/ux_places_build_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

import 'district_places_steps.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the district pictures are drawn only with UX_SHOTS', () {});
    return;
  }

  final scene = Platform.environment['UX_SCENE'] ?? '2015_informant';
  testWidgets('the district as places, step by step', (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));
    final key = GlobalKey();

    await tester.pumpWidget(
        ProviderScope(child: RepaintBoundary(key: key, child: const MyApp())));
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
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settleApp(tester);
    container.read(storyPlayProvider.notifier).jumpTo(scene);
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 6));
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/places-build-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await shot('1-map');
    final view = tester.widget<CityChartView>(find.byType(CityChartView));
    final district = container.read(partyDistrictProvider);
    final pin = view.chart.ways
        .firstWhere((w) => view.chart.districts[w.district].id == district);
    view.onPick!(pin);
    await tester.pump(const Duration(milliseconds: 300));
    await shot('2-card');
    view.onPick!(pin);
    await tester.pump();
    await raisePlaces(tester);
    await shot('3-list');
    await tester.tap(find.byKey(const Key('place_card_go')).evaluate().isEmpty
        ? find.byKey(const Key('places_handle'))
        : find.byKey(const Key('place_card_go')));
    await tester.pump(const Duration(milliseconds: 400));
    await goToPlace(tester, row: placeRows.last);
    await shot('4-at-place');
  });
}
