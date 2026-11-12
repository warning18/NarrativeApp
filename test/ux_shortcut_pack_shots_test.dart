// The shortcut card on a floor with a pack (UX_SHOTS=<folder>, UX_TAG=today|elite):
// the offer, then the floor after the stair is taken, at 412 px. Drawn only
// with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
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
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf'],
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf'],
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }
  final icons = File(
    '/root/fl/sdk/bin/cache/artifacts/material_fonts/'
    'MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'shot';
  final data = towerDataFromAssets();
  TowerRun base(int seed, int floor) => TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 40,
        events: 1,
      );
  TowerRun settled(TowerRun r) {
    for (var g = 0; g < 64 && towerPendingPicks(r) > 0; g++) {
      final t = towerTakeStatPick(r, data, 0);
      if (identical(t, r)) break;
      r = t;
    }
    return r;
  }

  /// A floor with a pack whose event is the shortcut (a late one, where the
  /// pack is large).
  (int, int) packShortcut() {
    for (var floor = 28; floor >= 8; floor--) {
      for (var seed = 1; seed < 800; seed++) {
        final r = settled(base(seed, floor));
        if (towerEventKindOf(r) != TowerEventKind.shortcut) continue;
        final f = towerFloorsFor(
          r.seed,
          data.enemies,
          events: r.events,
        )[floor - 1];
        if (f.isPack && !f.elite && f.kind == TowerFloorKind.fight) {
          return (seed, floor);
        }
      }
    }
    throw StateError('none');
  }

  testWidgets('the shortcut on a pack', skip: shots == null, (tester) async {
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
      Directory(shots!).createSync(recursive: true);
      File('$shots/$name-$tag.png').writeAsBytesSync(bytes);
    }

    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    final (seed, floor) = packShortcut();
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'tower_run_v1': jsonEncode(settled(base(seed, floor)).toJson()),
    });
    usePhone(tester, const Size(412, 1900));
    final container = ProviderContainer(
      overrides: [towerDataProvider.overrideWith((ref) async => data)],
    );
    addTearDown(container.dispose);
    await container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: buildAppTheme(
              container.read(appPaletteProvider).schemeFor(Brightness.light),
            ),
            home: const TowerFloorScreen(),
          ),
        ),
      ),
    );
    await settle();
    await shot('shortcut-offer');
    await tester.tap(find.byKey(const Key('tower_shortcut_take')));
    await settle();
    await shot('shortcut-taken');
    File('$shots/info-$tag.txt').writeAsStringSync(
      'seed $seed floor $floor foes ${towerFloorOf(container.read(towerProvider).value!.run!, data).enemyIds.length}',
    );
  });
}
