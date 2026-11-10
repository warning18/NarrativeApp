// The White Wells' way south (v1.851): scene 1200's "Go south" ways lead
// to a departure scene still at the Wells, and are ways out of the village
// (their choice's `place: "out"`), on the chart as a way out. With UX_SHOTS
// (a folder) set it saves the real screen of scene 1200 as a picture, named
// with UX_SHOT_TAG (before, after):
//   UX_SHOTS=docs/ux-shots/journey-moves UX_SHOT_TAG=after \
//     flutter test test/ux_white_wells_shot_test.dart
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
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'support/fonts.dart';
import 'support/open_game.dart' show storedCityPlans;
import 'support/pump.dart';

final _shotKey = GlobalKey();

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_SHOT_TAG'] ?? 'now';
  if (dir == null) {
    test('the White Wells picture is taken only with UX_SHOTS', () {});
    return;
  }

  for (final (scene, name, flags) in [
    // Lysa alive: "Go south with Lysa and the caravan".
    ('1200', 'white-wells-1200', ['lysa_survived']),
  ]) {
    testWidgets('scene $scene', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
      usePhone(
          tester,
          Size(double.parse(Platform.environment['SHOT_W'] ?? '412'),
              double.parse(Platform.environment['SHOT_H'] ?? '915')));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          if (Platform.environment['NO_PLANS'] != null)
            cityPlanRecordsProvider.overrideWith((ref) async => const {})
          else
            storedCityPlans,
        ],
        child: RepaintBoundary(key: _shotKey, child: const MyApp()),
      ));
      await tester.runAsync(loadAppFonts);
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
            'gold': 100,
            'flags': ['journey_first_shown', ...flags],
          })));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settleApp(tester);
      await tester.tap(find.text('Journey'));
      await settleApp(tester);
      if (Platform.environment['VIA_260'] != null) {
        container.read(storyPlayProvider.notifier).jumpTo('260');
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 6));
      }
      container.read(storyPlayProvider.notifier).jumpTo(scene);
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 6));
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(milliseconds: 700));
      if (Platform.environment['TAP'] case final label?) {
        await tester.tap(find.text(label).first);
        await tester.pump(const Duration(seconds: 2));
      }
      await tester.runAsync(() async {
        final boundary = _shotKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name-$tag.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
