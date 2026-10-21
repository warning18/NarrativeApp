// QA: wave 15's town tints (v1.495) on a phone, with the app's own fonts: the
// Journey in a town its clan rules (Emberwick, Candlehold), a town of mixed
// rule (Saltmouth) and one nobody rules (the cove camp): the district view
// with its "Held by" line and the plan's washes, the town view, and the
// world chart with its ruled towns' halos. 360 x 740 and 320 x 568, English
// and French, no overflow (SMOKE_SHOTS=<folder> for the pictures).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart'
    show chartGlobeProvider;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

import 'qa_smoke_harness.dart';

/// The scene to stand in, and what rules its town.
const _towns = [
  ('3100', 'emberwick_compact'),
  ('7500', 'candlehold_dominion'),
  ('2005', 'saltmouth_mixed'),
  ('3001', _coveCamp),
  ('1200', 'white_wells_nobody'),
];

const _coveCamp = 'cove_camp_nobody';

final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 6 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  testWidgets('the town tints read on a phone, EN and FR', (tester) async {
    final shots = Platform.environment['SMOKE_SHOTS'];
    final failures = <String>[];
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = smokeSizes.first;

    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(key: boundary, child: const MyApp())));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(chartGlobeProvider.notifier).choose(false));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);

    Future<void> check(String label) async {
      if (overflows.isNotEmpty) {
        failures.add('$label: ${overflows.toSet().join('; ')}');
      }
      overflows.clear();
      if (shots == null) return;
      final bytes = await tester.runAsync(() async {
        final object = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await object.toImage();
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      Directory(shots).createSync(recursive: true);
      File('$shots/tints_$label.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    Future<void> closeCards() async {
      for (var i = 0; i < 3; i++) {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    var onJourney = false;
    for (final size in smokeSizes) {
      tester.view.physicalSize = size;
      for (final french in [false, true]) {
        final where = '${size.width.toInt()}_${french ? 'fr' : 'en'}';
        await tester.runAsync(() => container
            .read(appLanguageProvider.notifier)
            .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
        final play = container.read(storyPlayProvider.notifier);
        var first = true;
        for (final (node, name) in _towns) {
          play.jumpTo(node);
          await _settle(tester);
          if (!onJourney) {
            await tester.tap(find.text(trFor(
                french ? AppLanguage.fr : AppLanguage.en, 'nav_journey')));
            onJourney = true;
            await _settle(tester);
            await tester.pump(const Duration(seconds: 6));
          } else {
            await tester.pump(const Duration(seconds: 1));
          }
          await closeCards();
          await _settle(tester);
          // The district, with its "Held by" line under the plan.
          await tester.tap(find.byKey(const Key('journey_tab_district')));
          await tester.pump(const Duration(milliseconds: 600));
          // The cove camp is a place of its own, not a town: no "Held by" line;
          // White Wells, a town nobody holds, says so.
          if (name != _coveCamp) {
            expect(find.byKey(const ValueKey('journey_city_ruler')),
                findsOneWidget,
                reason: '$where $name: the Held by line');
          }
          await check('${name}_district_$where');
          // The cove camp is a place, not a town: no Town tab, no line.
          // The whole town.
          await tester.tap(find.byKey(const Key('journey_tab_town')));
          await tester.pump(const Duration(milliseconds: 600));
          final line = find.byKey(const ValueKey('journey_city_ruler'));
          if (name == _coveCamp) {
            // A single place with no town view: its Town tab is greyed.
            expect(line, findsNothing, reason: '$where $name');
          } else {
            expect(line, findsOneWidget,
                reason: '$where $name: the Held by line in the town view');
          }
          await check('${name}_town_$where');
          if (first) {
            // The world chart, its ruled towns haloed.
            await tester.tap(find.byKey(const Key('journey_tab_world')));
            await tester.pump(const Duration(seconds: 2));
            // Closer in, where the towns' halos can be seen.
            for (var i = 0; i < 3; i++) {
              await tester.tap(find.byIcon(Icons.add).first);
              await tester.pump(const Duration(milliseconds: 500));
            }
            await tester.pump(const Duration(seconds: 1));
            await check('world_$where');
            first = false;
          }
        }
      }
    }
    FlutterError.onError = previous;
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
