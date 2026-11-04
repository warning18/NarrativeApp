// The spoils sheet (loot_sheet.dart, design C): the chest and its rarity, what
// the spoils change, each reward's text and its "Use right away" switch, one
// Take button. Real fonts, the narrowest and the widest phone, French and
// English; no text under 11 px. With UX_SHOTS (a folder) set it saves the
// sheet as pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart' show buildAppTheme;
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/loot_sheet.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

Widget _sheet(AppLanguage language,
    {Set<String> useNow = const {},
    void Function(String, bool)? onUse,
    VoidCallback? onTake}) {
  final fr = language == AppLanguage.fr;
  String t(String f, String e) => fr ? f : e;
  return LootSheet(
    language: language,
    title: t('Butin', 'Spoils'),
    chestAsset: 'assets/icons/chests/silver_open.png',
    tierLabel: t("Coffre d'argent", 'Silver chest'),
    changes: [
      LootChange(
          label: t('Or', 'Gold'),
          before: '126',
          after: '144',
          icon: Icon(Icons.monetization_on,
              size: 28, color: Colors.amber.shade700),
          tone: const Color(0xFFF2A93B)),
      LootChange(
          label: t('Dés', 'Dice'),
          before: t('1 relance / tour', '1 reroll / round'),
          after: t('2 relances / tour', '2 rerolls / round'),
          icon: const ItemPixelIcon('charm_fourth_roll', 'Charm', size: 28)),
      LootChange(
          label: t('Sac', 'Bag'),
          before: 'Antidote ×1',
          after: 'Antidote ×2',
          icon: const ItemPixelIcon('antidote', 'Potion', size: 28),
          tone: const Color(0xFF7DBE6A)),
    ],
    rewards: [
      LootReward(
          id: 'charm_fourth_roll',
          name: t('Osselet du joueur', "Gambler's Knucklebone"),
          text: t(
              "Consumé au début d'un combat : une relance supplémentaire à chaque tour de ce combat.",
              'Burned at the start of a fight: one extra reroll each round of that fight.'),
          icon: const ItemPixelIcon('charm_fourth_roll', 'Charm', size: 28),
          canUseNow: true),
      LootReward(
          id: 'antidote',
          name: 'Antidote',
          text: t('Se boit pour guérir le poison et les afflictions.',
              'Drunk to cure poison and afflictions.'),
          icon: const ItemPixelIcon('antidote', 'Potion', size: 28),
          canUseNow: true),
    ],
    useNow: useNow,
    onUseNow: onUse ?? (_, __) {},
    onTake: onTake ?? () {},
  );
}

Future<void> _pump(WidgetTester tester, Widget sheet, double width) async {
  usePhone(tester, Size(width, 780));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark)),
    home: Scaffold(
        backgroundColor: Colors.black54,
        body: Padding(padding: const EdgeInsets.only(top: 56), child: sheet)),
  ));
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  for (final width in [360.0, 412.0]) {
    for (final language in AppLanguage.values) {
      testWidgets('lays out at ${width.round()} px in ${language.name}',
          (tester) async {
        await tester.runAsync(loadAppFonts);
        await _pump(tester, _sheet(language), width);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('loot_sheet')), findsOneWidget);
        expect(find.byKey(const Key('loot_change_${'Gold'}')),
            language == AppLanguage.en ? findsOneWidget : findsNothing);
        expect(find.byKey(const Key('loot_reward_antidote')), findsOneWidget);
        expect(find.byKey(const Key('loot_sheet_take')), findsOneWidget);
        // The Take button stays on screen under the list.
        final take = tester.getRect(find.byKey(const Key('loot_sheet_take')));
        expect(take.bottom, lessThanOrEqualTo(780));
        expect(take.width, greaterThan(width - 40));
        // No text under 11 px.
        for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
          final size = (w.text as TextSpan).style?.fontSize;
          if (size != null && w.text.toPlainText().trim().length > 1) {
            expect(size, greaterThanOrEqualTo(11),
                reason: w.text.toPlainText());
          }
        }
      });
    }
  }

  testWidgets('a switch uses a reward right away; Take is pressed',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    final seen = <String, bool>{};
    var taken = 0;
    await _pump(
        tester,
        _sheet(AppLanguage.en,
            onUse: (id, on) => seen[id] = on, onTake: () => taken++),
        360);
    await tester.ensureVisible(find.byKey(const Key('loot_use_antidote')));
    await tester.tap(find.byKey(const Key('loot_use_antidote')));
    await tester.pump();
    expect(seen, {'antidote': true});
    await tester.tap(find.byKey(const Key('loot_sheet_take')));
    expect(taken, 1);
  });

  final dir = Platform.environment['UX_SHOTS'];
  if (dir != null) {
    testWidgets('the sheet as pictures', (tester) async {
      await tester.runAsync(loadAppFonts);
      Directory(dir).createSync(recursive: true);
      for (final width in [360.0, 412.0]) {
        for (final language in AppLanguage.values) {
          final key = GlobalKey();
          usePhone(tester, Size(width, 780));
          await tester.pumpWidget(MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(
                AppPalette.stitchedInk.schemeFor(Brightness.dark)),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                  backgroundColor: const Color(0xFF14131A),
                  body: Padding(
                      padding: const EdgeInsets.only(top: 56),
                      child: _sheet(language, useNow: {'antidote'}))),
            ),
          ));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() async {
            final b = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await b.toImage(pixelRatio: 1);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$dir/loot-sheet-${width.round()}-${language.name}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
      }
    });
  }
}
