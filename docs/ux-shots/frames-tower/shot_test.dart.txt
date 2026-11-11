// The Tower's screens on real data (UX_SHOTS=<folder>): the menu entry, the
// start screen (as it opens and with a pick), the marks and the end of a run
// (a death and a win), at 360 px in French and 412 px in English. Drawn only
// with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/main_menu_screen.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'dart:convert';
import 'package:narrative_data_app/screens/tower/tower_marks_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/pump.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the Tower screens', (tester) async {
    await tester.runAsync(_loadFonts);
    final key = GlobalKey();
    Future<void> shot(String name) async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late Uint8List bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name.png').writeAsBytesSync(bytes);
    }

    Future<void> settle() async {
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    const run = TowerRun(
      seed: 1,
      raceId: 'human',
      professionId: 'warrior',
      floor: 17,
      health: 0,
      status: TowerStatus.dead,
    );
    for (final (lang, width, tag) in [
      (AppLanguage.en, 412.0, 'en412'),
    ]) {
      Future<void> open(Widget screen,
          {Map<String, Object> prefs = const {}}) async {
        SharedPreferences.setMockInitialValues(
            {'app_language': lang.name, ...prefs});
        usePhone(tester, Size(width, 780));
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(appLanguageProvider.notifier).setLanguage(lang);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                key: UniqueKey(), // a screen pushed before is dropped
                theme: buildAppTheme(container
                    .read(appPaletteProvider)
                    .schemeFor(Brightness.light)),
                home: screen),
          ),
        ));
        await settle();
      }

      Map<String, Object> saved(TowerRun r) =>
          {'tower_run_v1': jsonEncode(r.toJson())};
      Future<void> settleLong() async {
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // A floor that gained a level opens the Level Up first: drawn once,
      // then closed so the cards behind it show.
      var levelShot = false;
      Future<void> pastLevelUp() async {
        final screen = find.byType(LevelUpScreen);
        if (screen.evaluate().isEmpty) return;
        if (!levelShot) {
          levelShot = true;
          await tester.pump(const Duration(milliseconds: 600));
          await shot('12-levelup-$tag');
        }
        Navigator.of(tester.element(screen)).pop();
        await settleLong();
      }

      // The spoils sheet of a won floor, drawn then taken: the boon or
      // oath comes after it.
      Future<void> spoils(String? name) async {
        final take = find.byKey(const Key('loot_sheet_take'));
        if (take.evaluate().isEmpty) return;
        await tester.pump(const Duration(milliseconds: 600));
        if (name != null) await shot(name);
        await tester.tap(take);
        await settleLong();
      }

      final mid =
          run.copyWith(floor: 7, health: 31, status: TowerStatus.climbing);
      Future<void> floorShot(String name, int floor, {bool won = false}) async {
        await open(const TowerFloorScreen(), prefs: {
          ...saved(mid.copyWith(floor: floor, health: 36)),
          if (won)
            'tower_marks_v1': '{"marks":5,"bestFloor":30,"runs":2,"wins":1}',
        });
        await settleLong();
        await shot(name);
      }

      await floorShot('f-wood-3', 3);
      await floorShot('f-iron-14', 14);
      await floorShot('f-silver-24', 24);
      await floorShot('f-gilt-3', 3, won: true);
      await open(const TowerStartScreen(), prefs: {
        'tower_marks_v1': '{"marks":12,"bestFloor":17,"runs":4,"wins":0}'
      });
      await shot('s-start-wood');
      await open(const TowerMarksScreen(),
          prefs: {'tower_marks_v1': '{"marks":12,"unlocked":["flame_die"]}'});
      await shot('s-marks-wood');
    }
  }, skip: shots == null);
}
