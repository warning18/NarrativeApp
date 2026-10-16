// A zone cleared (v1.450, the reward card of docs/proposals/reward-popups.md):
// what the zone paid is a row each (gold, the item with its rarity, the
// materials, a die, an ally), what changed the outcome is a note, and the
// button takes the party back to town.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/reward_card.dart';
import 'package:narrative_data_app/widgets/reward_cards.dart';

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
  for (final (name, width, lang) in [
    ('english 360', 360.0, AppLanguage.en),
    ('french 320', 320.0, AppLanguage.fr),
  ]) {
    testWidgets('the cleared zone is a reward card ($name)', (tester) async {
      if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var done = 0;
      late RewardCardData data;
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
        home: Scaffold(
          body: Builder(builder: (context) {
            final ink = InkColors.of(context);
            data = zoneClearedCard(
              lang: lang,
              kind: lang == AppLanguage.fr ? 'Zone nettoyée' : 'Zone cleared',
              title: lang == AppLanguage.fr ? 'Les Salines' : 'The Salt Pans',
              chapter: 2,
              lines: [
                RewardLine(
                  key: const Key('reward_gold'),
                  icon: Icon(Icons.paid, size: 30, color: ink.gold),
                  accent: ink.gold,
                  title: lang == AppLanguage.fr ? 'Or' : 'Gold',
                  sub: lang == AppLanguage.fr
                      ? 'La récompense de la zone'
                      : 'The zone’s reward',
                  value: '+120',
                ),
                rewardItemLine(context,
                    itemId: 'dagger_t1',
                    item: const {
                      'itemName': 'Salt-Crow Dagger',
                      'rarity': 'Rare',
                    },
                    lang: lang),
                RewardLine(
                  key: const Key('reward_die_d6'),
                  icon: Icon(Icons.casino, size: 28, color: ink.tide),
                  accent: ink.tide,
                  title: 'Huntsman Die',
                  sub: lang == AppLanguage.fr
                      ? 'Un dé pour votre main'
                      : 'A die for your hand',
                  value: lang == AppLanguage.fr ? 'NOUVEAU' : 'NEW',
                ),
              ],
              notes: [
                RewardNote(lang == AppLanguage.fr
                    ? 'Le chargement est arrivé : 4 caisses sur 5.'
                    : 'The cargo arrived: 4 crates of 5.'),
              ],
            );
            return RepaintBoundary(
              key: const Key('shot'),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: RewardCard(
                    key: const Key('zone_reward_card'),
                    data: data,
                    onDone: () => done++,
                  ),
                ),
              ),
            );
          }),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(const Key('zone_reward_card')), findsOneWidget);
      expect(find.byKey(const Key('reward_gold')), findsOneWidget);
      expect(find.byKey(const Key('reward_item_dagger_t1')), findsOneWidget);
      expect(find.byKey(const Key('reward_die_d6')), findsOneWidget);
      expect(find.text('+120'), findsOneWidget);
      // Its header says what, and which chapter; the colour is the chapter's.
      expect(
          data.kind,
          lang == AppLanguage.fr
              ? 'Zone nettoyée · Chapitre 2'
              : 'Zone cleared · Chapter 2');
      expect(data.accent, rewardChapterColour(2));
      // One button, back to town.
      expect(data.button,
          lang == AppLanguage.fr ? 'Retourner en ville' : 'Return to Town');
      await _save(tester, 'zone-cleared-${lang.name}');
      await tester.tap(find.text(data.button));
      expect(done, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
