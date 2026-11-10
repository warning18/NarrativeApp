import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';

const _party = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'level': 8,
  'builtHouseIds': ['keldas_hall'],
  'activeAllyIds': ['kelda', 'sable'],
  'recruitedAllies': [
    {'companionId': 'kelda', 'currentHealth': 1 << 30, 'approval': 14},
    {'companionId': 'sable', 'currentHealth': 22, 'approval': 6},
    {'companionId': 'maren', 'currentHealth': 1 << 30, 'approval': 0},
  ],
};

void main() {
  final out = Platform.environment['UX_SHOTS'];
  if (out == null) {
    test('only with UX_SHOTS', () {});
    return;
  }
  final tag = Platform.environment['UX_SHOT_TAG'] ?? 'after';
  for (final (lang, w, t) in [
    (AppLanguage.en, 412.0, 'en412'),
    (AppLanguage.fr, 360.0, 'fr360'),
    (AppLanguage.en, 320.0, 'en320'),
    (AppLanguage.fr, 320.0, 'fr320')
  ]) {
    testWidgets('party $t', (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(w * 2, 1200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [
          reachedChapterProvider.overrideWithValue(8),
          campTabProvider.overrideWith((ref) => CampTab.party)
        ],
        child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(
                    AppPalette.stitchedInk.schemeFor(Brightness.light)),
                home: const Scaffold(body: CampScreen(embedded: true)))),
      ));
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(
          () => container.read(appLanguageProvider.notifier).setLanguage(lang));
      container.read(playerSessionProvider);
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson(_party)));
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        File('$out/party-$tag-$t.png').writeAsBytesSync(
            (await image.toByteData(format: ui.ImageByteFormat.png))!
                .buffer
                .asUint8List());
      });
    });
  }
}
