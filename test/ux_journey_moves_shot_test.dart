// The Journey's moves (v1.851, the user's call): every move is a mark on the
// map, a check, fight or price shown as a tag on it; a scene's one way that
// moves with a check is the page's main button. With UX_SHOTS (a folder) set
// it saves the real screens of three scenes as pictures, named with
// UX_SHOT_TAG (before, after):
//   UX_SHOTS=docs/ux-shots/journey-moves UX_SHOT_TAG=after \
//     flutter test test/ux_journey_moves_shot_test.dart --plain-name 'scene 2015'
// One scene per run: run in one file, a scene left by the one before it
// draws the next one's map without its marks.
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
    test('the journey-moves pictures are taken only with UX_SHOTS', () {});
    return;
  }

  for (final (scene, name, flags) in [
    // Back from the casino with the woman saved: the way home that costs
    // 15 gold.
    ('125', 'go-home-125', ['casino_rescue', 'saved_woman']),
    ('2015', 'saltmouth-hub-2015', <String>[]),
    ('2005', 'salt-wagon-2005', <String>[]),
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
