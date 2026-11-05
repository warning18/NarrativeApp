// A sketch of the Tower on the main game's own screens (UX_SHOTS=<folder>):
// the character creation (race and profession) as the Tower's first screen,
// and a won floor's reward on the spoils sheet and the level-up screen, with
// the Tower's ladder beside them. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_ladder.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/loot_sheet.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the Tower on the main game screens', (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(412, 780));
    final key = GlobalKey();
    Future<void> shot(String name) async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late List<int> bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name.png').writeAsBytesSync(bytes);
    }

    Future<ProviderContainer> open(Widget home) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(
                container.read(appPaletteProvider).schemeFor(Brightness.light)),
            home: home,
          ),
        ),
      ));
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      return container;
    }

    // The main game's character creation.
    await open(const RaceProfessionScreen());
    await shot('a1-creation-peoples');
    await tester.tap(find.byKey(const Key('choice_card_human')));
    await tester.pump(const Duration(milliseconds: 600));
    await shot('a2-creation-open');
    await tester.tap(find.byKey(const Key('rp_next')));
    await tester.pump(const Duration(seconds: 1));
    await shot('a2b-creation-callings');
    await tester.ensureVisible(find.byKey(const Key('choice_card_mage')));
    await tester.tap(find.byKey(const Key('choice_card_mage')));
    await tester.pump(const Duration(milliseconds: 600));
    await shot('a3-creation-summary');

    // A won floor's spoils on the main game's sheet, the ladder beside it.
    Widget sheet() => LootSheet(
          language: AppLanguage.en,
          title: 'Floor 7 cleared',
          chestAsset: 'assets/icons/chests/silver_open.png',
          tierLabel: 'Silver chest',
          changes: const [
            LootSheetLine(
                label: 'Dice',
                before: '1 reroll / round',
                after: '2 rerolls / round',
                icon: ItemPixelIcon('charm_fourth_roll', 'Charm', size: 28)),
            LootSheetLine(
                label: 'Bag',
                before: 'Antidote x1',
                after: 'Antidote x2',
                icon: ItemPixelIcon('antidote', 'Potion', size: 28),
                tone: Color(0xFF7DBE6A)),
          ],
          rewards: const [
            LootReward(
                id: 'charm_fourth_roll',
                name: "Gambler's Knucklebone",
                text:
                    'Burned at the start of a fight: one extra reroll each round of that fight.',
                icon: ItemPixelIcon('charm_fourth_roll', 'Charm', size: 28),
                canUseNow: true),
            LootReward(
                id: 'antidote',
                name: 'Antidote',
                text: 'Drunk to cure poison and afflictions.',
                icon: ItemPixelIcon('antidote', 'Potion', size: 28),
                canUseNow: true),
          ],
          useNow: const {},
          onUseNow: (_, __) {},
          onTake: () {},
        );
    await open(Scaffold(
      appBar: AppBar(title: const Text('The Ashen Tower')),
      body: Row(children: [
        const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 4, 8),
            child: TowerLadder(floor: 7)),
        Expanded(child: sheet()),
      ]),
    ));
    await shot('b1-spoils-with-ladder');

    // The level-up screen after a floor that levelled the hero.
    final container = await open(const LevelUpScreen());
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(const {
          'raceId': 'human',
          'professionId': 'warrior',
          'level': 8,
          'statPoints': 1,
        })));
    await tester.pump(const Duration(milliseconds: 600));
    await shot('b2-level-up');
  }, skip: shots == null);
}
