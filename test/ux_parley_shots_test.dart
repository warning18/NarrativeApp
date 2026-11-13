// The Tower's parley on real data (UX_SHOTS=<folder>): the guardian's card and
// plate, sworn to its clan, and a talk lost, at 360 px in French and 412 px in
// English. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_peaceful_cards.dart';
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
  // A scale and a foe size to compare (UX_NPC_SCALE, UX_NPC_FOE).
  towerNpcScale =
      int.tryParse(Platform.environment['UX_NPC_SCALE'] ?? '') ?? towerNpcScale;
  towerParleyFoeSize =
      double.tryParse(Platform.environment['UX_NPC_FOE'] ?? '') ??
          towerParleyFoeSize;
  final data = towerDataFromAssets();
  TowerRun base(int seed, int floor,
          {Map<int, TowerReward> taken = const {}}) =>
      TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 40,
        events: towerPeacefulEvents,
        taken: taken,
      );
  TowerRun settled(TowerRun r) {
    for (var g = 0; g < 64 && towerPendingPicks(r) > 0; g++) {
      final t = towerTakeStatPick(r, data, 0);
      if (identical(t, r)) break;
      r = t;
    }
    return r;
  }

  (int, int) parleyFloor({bool failing = false, Set<String>? clans}) {
    for (var seed = 1; seed < 600; seed++) {
      for (var floor = 4; floor < 29; floor++) {
        final r = settled(base(seed, floor));
        if (towerEventKindOf(r) != TowerEventKind.parley) continue;
        if (clans != null && !clans.contains(towerParleyClanOf(r))) continue;
        if (!failing) return (seed, floor);
        if (towerChooseParley(r, data, true).parley ?? false) {
          return (seed, floor);
        }
      }
    }
    throw StateError('none');
  }

  testWidgets('the parley', skip: shots == null, (tester) async {
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
      Future<ProviderContainer> open(TowerRun run) async {
        SharedPreferences.setMockInitialValues({
          'app_language': lang.name,
          'tower_run_v1': jsonEncode(settled(run).toJson()),
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
        return container;
      }

      final (seed, floor) = parleyFloor();
      await open(base(seed, floor));
      await shot('parley-offer-$tag');
      // The officer's picture (Dominion, Vigil) and the floor foe's own
      // figure (the other clans).
      final (os, of) = parleyFloor(clans: {'dominion', 'vigil'});
      await open(base(os, of));
      await shot('parley-officer-$tag');
      final (ns, nf) =
          parleyFloor(clans: {'mire', 'crows', 'compact', 'penitents'});
      await open(base(ns, nf));
      await shot('parley-foe-$tag');
      final clan = towerParleyClanOf(settled(base(seed, floor)))!;
      await open(base(seed, floor,
          taken: {0: TowerReward(TowerRewardKind.clanOath, id: clan)}));
      await shot('parley-sworn-$tag');
      final (fs, ff) = parleyFloor(failing: true);
      final container = await open(base(fs, ff));
      await tester.tap(find.byKey(const Key('tower_parley_talk')));
      await settle();
      await shot('parley-failed-$tag');
      expect(container.read(towerProvider).value!.run!.parley, true);
    }
  });
}
