// The Tower's stores on real data (UX_SHOTS=<folder>): the shop room after a
// boss (not sworn, sworn, after a purchase) and the bargain's alcove (offered,
// taken), at 360 px in French and 412 px in English. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_hero.dart';
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

  /// [seed]'s climb on [floor] with [floor]'s fight won: the landing (sworn
  /// to [clan] from the start when given).
  TowerRun landing(int seed, int floor, {String? clan}) {
    final start = towerStart(
            seed: seed,
            raceId: 'human',
            professionId: 'warrior',
            clanId: clan ?? '',
            events: towerPeacefulEvents,
            data: data)
        .copyWith(floor: floor);
    final run = start.copyWith(health: towerHeroOf(start, data).maxHealth);
    return towerPick(
        towerAfterFight(run, data, won: true, healthLeft: run.health),
        data,
        null);
  }

  (int, int) storeFloor(TowerEventKind kind) {
    for (var seed = 1; seed < 400; seed++) {
      for (final floor in kind == TowerEventKind.merchant
          ? const [10]
          : [
              for (var f = 2; f < 29; f++)
                if (f % 5 != 0) f
            ]) {
        if (towerStoreKindOf(landing(seed, floor)) == kind) {
          return (seed, floor);
        }
      }
    }
    throw StateError('none');
  }

  testWidgets('the stores', skip: shots == null, (tester) async {
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

    for (final (lang, width, tag, brightness) in [
      (AppLanguage.fr, 360.0, 'fr360', Brightness.light),
      (AppLanguage.en, 412.0, 'en412', Brightness.light),
      (AppLanguage.en, 412.0, 'dark-en412', Brightness.dark),
    ]) {
      Future<ProviderContainer> open(TowerRun run) async {
        SharedPreferences.setMockInitialValues({
          'app_language': lang.name,
          if (brightness == Brightness.dark) 'app_theme_mode': 'dark',
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
                theme: buildAppTheme(
                    container.read(appPaletteProvider).schemeFor(brightness)),
                home: const TowerFloorScreen()),
          ),
        ));
        await settle();
        return container;
      }

      final (ms, mf) = storeFloor(TowerEventKind.merchant);
      final shop = landing(ms, mf);
      await open(shop);
      await shot('shop-offer-$tag');
      final clan = towerStoreClanOf(shop)!;
      final sworn = landing(ms, mf, clan: clan);
      expect(towerStoreKindOf(sworn), TowerEventKind.merchant);
      await open(sworn);
      await shot('shop-sworn-$tag');
      final container = await open(sworn);
      await tester.tap(find.byKey(const Key('tower_stall_buy_salve')));
      await settle();
      await shot('shop-bought-$tag');
      expect(container.read(towerProvider).value!.run!.bought, isNotEmpty);

      final (bs, bf) = storeFloor(TowerEventKind.bargain);
      final deal = landing(bs, bf);
      await open(deal);
      await shot('bargain-offer-$tag');
      final taken = await open(deal);
      await tester.tap(find.byKey(const Key('tower_bargain_accept')));
      await settle();
      await shot('bargain-taken-$tag');
      expect(taken.read(towerProvider).value!.run!.bargains, isNotEmpty);
    }
  });
}
