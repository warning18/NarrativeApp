// The Tower's floors without a fight (UX_SHOTS=<folder>), mock data on the
// floor screen's frame: the parley, the merchant's stall and the bargain, at
// 360 px in French and 412 px in English. Drawn only with UX_SHOTS.
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
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_ladder.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart';
import 'package:narrative_data_app/screens/tower/tower_peaceful_cards.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
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

  testWidgets('the peaceful floors', skip: shots == null, (tester) async {
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
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final (lang, width, tag) in [
      (AppLanguage.fr, 360.0, 'fr360'),
      (AppLanguage.en, 412.0, 'en412'),
    ]) {
      Future<void> open(int floor, Widget Function() card) async {
        SharedPreferences.setMockInitialValues({'app_language': lang.name});
        usePhone(tester, Size(width, 1100));
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
                  .schemeFor(Brightness.light)),
              home: TowerNight(
                floor: floor,
                child: Scaffold(
                  body: TowerBackdrop(
                    floor: floor,
                    child: SafeArea(
                      child: Row(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
                          child: TowerLadder(floor: floor),
                        ),
                        Expanded(
                          child: Consumer(builder: (context, ref, _) {
                            final theme = Theme.of(context);
                            final ink = InkColors.of(context);
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
                              children: [
                                Text(
                                    tr(ref, 'tower_band_${towerBandOf(floor)}')
                                        .toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(letterSpacing: 1.2)),
                                Text(
                                    tr(ref, 'tower_floor_of')
                                        .replaceAll('{n}', '$floor'),
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(color: ink.gold)),
                                Text(tr(ref, 'tower_floor_$floor'),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontStyle: FontStyle.italic)),
                                const SizedBox(height: 10),
                                card(),
                              ],
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
        await settle();
      }

      void nothing() {}
      await open(
          14,
          () => TowerParleyCard(
              ability: 'dexterity',
              dc: 12,
              modifier: 3,
              chance: .6,
              landsOn: 15,
              clanId: 'crows',
              onTalk: nothing,
              onFight: nothing));
      await shot('parley-$tag');
      await open(
          14,
          () => TowerParleyCard(
              ability: 'dexterity',
              dc: 12,
              modifier: 3,
              chance: .6,
              landsOn: 15,
              clanId: 'crows',
              oathPass: true,
              onTalk: nothing,
              onFight: nothing));
      await shot('parley-sworn-$tag');
      await open(
          11,
          () => TowerMerchantRoom(
                wallet: 7,
                clanId: 'vigil',
                stock: const [
                  TowerStallItem(
                      id: 'salve', icon: Icons.healing, price: 3, amount: 40),
                  TowerStallItem(
                      id: 'potions',
                      icon: Icons.science_outlined,
                      price: 8,
                      amount: 2,
                      affordable: false),
                ],
                onBuy: (_) {},
                onLeave: nothing,
              ));
      await shot('merchant-$tag');
      await open(
          11,
          () => TowerMerchantRoom(
                wallet: 4,
                clanId: 'vigil',
                discount: true,
                stock: const [
                  TowerStallItem(
                      id: 'salve',
                      icon: Icons.healing,
                      price: 2,
                      amount: 40,
                      bought: true),
                  TowerStallItem(
                      id: 'potions',
                      icon: Icons.science_outlined,
                      price: 2,
                      amount: 2),
                ],
                onBuy: (_) {},
                onLeave: nothing,
              ));
      await shot('merchant-sworn-$tag');
      await open(
          22,
          () => TowerBargainCard(
              maxHealthCost: 7,
              stat: 'strength',
              onAccept: nothing,
              onRefuse: nothing));
      await shot('bargain-$tag');
    }
  });
}
