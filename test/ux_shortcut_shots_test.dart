// The Tower's shortcut on real data (UX_SHOTS=<folder>): the offer, the stair
// taken, the won fight's cards with the way up, and the landing, at 360 px in
// French and 412 px in English. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'dart:convert';
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
  final icons = File('/root/fl/sdk/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final data = towerDataFromAssets();
  TowerRun base(int seed, int floor) => TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 40,
        events: 1,
      );
  // The first shortcut floors: one a lone foe (made an Elite), one a pack.
  (int, int) pick({required bool pack}) {
    for (var seed = 1; seed < 400; seed++) {
      for (var floor = 3; floor < 27; floor++) {
        final r = base(seed, floor);
        if (towerEventKindOf(r) != TowerEventKind.shortcut) continue;
        final plain = towerFloorOf(r, data);
        if (plain.isPack == pack && !plain.elite) return (seed, floor);
      }
    }
    throw StateError('none');
  }

  testWidgets('the shortcut', skip: shots == null, (tester) async {
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
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final (lang, width, tag) in [
      (AppLanguage.fr, 360.0, 'fr360'),
      (AppLanguage.en, 412.0, 'en412'),
    ]) {
      Future<void> open(TowerRun run) async {
        SharedPreferences.setMockInitialValues({
          'app_language': lang.name,
          'tower_run_v1': jsonEncode(run.toJson()),
        });
        usePhone(tester, Size(width, 1500));
        final container = ProviderContainer(overrides: [
          towerDataProvider.overrideWith((ref) async => data),
        ]);
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
                    .schemeFor(Brightness.light)),
                home: const TowerFloorScreen()),
          ),
        ));
        await settle();
      }

      for (final (name, pack) in [('lone', false), ('pack', true)]) {
        final (seed, floor) = pick(pack: pack);
        final run = base(seed, floor);
        await open(run);
        await shot('shortcut-offer-$name-$tag');
        await tester.tap(find.byKey(const Key('tower_shortcut_take')));
        await settle();
        await shot('shortcut-taken-$name-$tag');
        if (pack) continue;
        // The fight won: the floor's cards, with the way up above them.
        final won = towerAfterFight(run.copyWith(shortcut: true), data,
            won: true, healthLeft: 30);
        await open(won);
        // A level gained opens its pick first: closed, so the cards show.
        final levelUp = find.byType(LevelUpScreen);
        if (levelUp.evaluate().isNotEmpty) {
          Navigator.of(tester.element(levelUp)).pop();
          await settle();
        }
        if (find.byType(FilledButton).evaluate().isNotEmpty) {
          await tester.tap(find.byType(FilledButton).last);
          await settle();
        }
        await shot('shortcut-won-$tag');
        // Landed: the result line, the rail arrow.
        final landed = towerPick(won, data, null);
        await open(landed);
        await shot('shortcut-landed-$tag');
      }
    }
  });
}
