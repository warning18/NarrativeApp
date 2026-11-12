// The three screens that took a painted background (UX_SHOTS=<folder>, UX_TAG
// to name the run): the life choices' header (ages 6 and 16), the character
// choice (the people, the calling) and an expedition's zone band, light and
// dark, in French at 360 px and in English at 412 px. Drawn only with
// UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/expedition_screen.dart';
import 'package:narrative_data_app/screens/origin_stories_screen.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/widgets/origin_scene_backdrop.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'shot';

  testWidgets('life choices, character choice, expedition', skip: shots == null,
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    final zones =
        jsonDecode(File('assets/gamedata/zones.json').readAsStringSync())
            as Map<String, dynamic>;

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final (lang, width, dark, name) in [
      (AppLanguage.fr, 360.0, false, 'fr360-light'),
      (AppLanguage.fr, 360.0, true, 'fr360-dark'),
      (AppLanguage.en, 412.0, false, 'en412-light'),
      (AppLanguage.en, 412.0, true, 'en412-dark'),
    ]) {
      final key = GlobalKey();
      Future<ProviderContainer> open(Widget home) async {
        SharedPreferences.resetStatic();
        SharedPreferences.setMockInitialValues({
          'app_language': lang.name,
          if (dark) 'app_theme_mode': 'dark',
        });
        usePhone(tester, Size(width, 780));
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(appLanguageProvider.notifier).setLanguage(lang);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              key: UniqueKey(),
              theme: buildAppTheme(container
                  .read(appPaletteProvider)
                  .schemeFor(dark ? Brightness.dark : Brightness.light)),
              home: home,
            ),
          ),
        ));
        await settle();
        return container;
      }

      Future<void> shot(String file) async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        late Uint8List bytes;
        await tester.runAsync(() async {
          final image = await b.toImage(pixelRatio: 2);
          bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
        });
        File('$shots/$file-$name-$tag.png').writeAsBytesSync(bytes);
      }

      // The life choices: age 6 (the sparrow) and, answering each memory the
      // first way, age 16 (the board).
      await open(Builder(
          builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OriginStoriesScreen(
                      raceId: 'dwarf',
                      professionId: 'mage',
                      random: Random(7)))),
              child: const Text('open'))));
      await tester.tap(find.text('open'));
      await settle();
      await shot('life-age6');
      // Age 16 (the board): the header alone, as the memory's page draws it
      // (the band, the page colour fading over its foot), as the page itself
      // is five answers on.
      await open(Builder(builder: (context) {
        final surface = Theme.of(context).colorScheme.surface;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 210,
            child: Stack(fit: StackFit.expand, children: [
              const OriginSceneBackdrop(memoryId: 'board'),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 0.78],
                    colors: [Colors.transparent, surface],
                  ),
                ),
              ),
            ]),
          ),
        );
      }));
      await shot('life-age16-header');

      // The character choice: the people, then the calling.
      await open(const RaceProfessionScreen());
      await shot('character-people');
      await tester.tap(find.byKey(const Key('choice_card_human')));
      await settle();
      await tester.tap(find.byKey(const Key('rp_next')));
      await settle();
      await shot('character-calling');

      // An expedition: the Lantern Docks.
      await open(ExpeditionScreen(
          zoneId: 'z_lantern_docks',
          zone: zones['z_lantern_docks'] as Map<String, dynamic>,
          random: Random(3)));
      await shot('expedition-lantern-docks');
    }
  });
}
