// The reward card (v1.369): every kind of reward on the one card, a header
// in the source's colour, a row each, the notes apart, one button.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/reward_card.dart';
import 'package:narrative_data_app/widgets/reward_cards.dart';
import 'support/fonts.dart';

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _host(Widget Function(BuildContext) build) => MaterialApp(
      theme: buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark)),
      home: Scaffold(
        body: RepaintBoundary(
          key: _shotKey,
          child: Builder(builder: build),
        ),
      ),
    );

RewardCardData _quest(BuildContext context,
    {bool swapped = true, bool banner = false}) {
  const ink = InkColors.dark;
  return questRewardCard(
    context,
    lang: AppLanguage.en,
    ink: ink,
    questName: 'The High Warden\u2019s Fall',
    chapter: 1,
    gold: 255,
    xp: 200,
    xpBefore: 340,
    xpAfter: 540,
    xpNeeded: 600,
    level: 7,
    leveledUp: false,
    banner: banner,
    found: [
      rewardItemLine(context,
          itemId: 'mystic_wand',
          item: const {
            'itemName': 'Mystic Wand',
            'rarity': 'Rare',
            'attackBonus': 4,
          },
          lang: AppLanguage.en),
    ],
    notes: [
      if (swapped)
        const RewardNote(
            'The Huntsman Die is made for another class: you took its price in gold instead.',
            chip: '+40 G'),
    ],
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
  });

  testWidgets('quest complete: header, a row each, the note, the button',
      (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var done = 0;
    await tester.pumpWidget(_host((context) => Center(
          child: RewardCard(data: _quest(context), onDone: () => done++),
        )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('QUEST COMPLETE \u00b7 CHAPTER 1'), findsOneWidget);
    expect(find.text('The High Warden\u2019s Fall'), findsOneWidget);
    expect(find.byKey(const Key('reward_gold')), findsOneWidget);
    expect(find.text('+255'), findsOneWidget);
    expect(find.byKey(const Key('reward_xp')), findsOneWidget);
    expect(find.text('340 \u2192 540 / 600 XP \u00b7 level 7'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byKey(const Key('reward_bar')))
            .value,
        closeTo(0.9, 1e-9));
    expect(find.byKey(const Key('reward_item_mystic_wand')), findsOneWidget);
    expect(find.text('Rare'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.textContaining('made for another class'), findsOneWidget);
    expect(find.byKey(const Key('reward_note_chip')), findsOneWidget);
    expect(find.text('+40 G'), findsOneWidget);
    await _shot(tester, 'reward_quest_card');
    await tester.tap(find.byKey(const Key('reward_button')));
    expect(done, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level reached fills the bar and says so', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host((context) => Center(
          child: RewardCard(
              data: questRewardCard(context,
                  lang: AppLanguage.fr,
                  ink: InkColors.dark,
                  questName: 'La chute',
                  chapter: 3,
                  gold: 0,
                  xp: 200,
                  xpBefore: 550,
                  xpAfter: 150,
                  xpNeeded: 800,
                  level: 8,
                  leveledUp: true,
                  banner: false),
              onDone: () {}),
        )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('reward_gold')), findsNothing,
        reason: 'no gold, no row');
    expect(find.text('Niveau sup\u00e9rieur\u00a0! Vous \u00eates niveau 8'),
        findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byKey(const Key('reward_bar')))
            .value,
        1);
    expect(find.text('QU\u00caTE ACCOMPLIE \u00b7 CHAPITRE 3'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('with reduced motion the rows are simply there', (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _host((context) => Center(
            child: RewardCard(data: _quest(context), onDone: () {}),
          )),
    ));
    await tester.pump();
    expect(
        tester
            .widget<FadeTransition>(find
                .ancestor(
                    of: find.byKey(const Key('reward_item_mystic_wand')),
                    matching: find.byType(FadeTransition))
                .first)
            .opacity
            .value,
        1);
  });

  testWidgets('showRewardCard waits for its button', (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext host;
    await tester.pumpWidget(_host((context) {
      host = context;
      return const SizedBox();
    }));
    var closed = false;
    unawaited(showRewardCard(host, _quest(host)).then((_) => closed = true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('reward_card')), findsOneWidget);
    expect(closed, isFalse);
    await tester.tap(find.byKey(const Key('reward_button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(closed, isTrue);
    expect(find.byKey(const Key('reward_card')), findsNothing);
  });

  testWidgets(
      'quest complete, banner-led: the chapter\u2019s art and two counters',
      (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host((context) => Center(
          child: RewardCard(data: _quest(context, banner: true), onDone: () {}),
        )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('reward_hero')), findsOneWidget);
    expect(
        tester.widget<Image>(find.byKey(const Key('reward_hero'))).image,
        isA<AssetImage>().having((a) => a.assetName, 'asset',
            'assets/visuals/chapters/chapter_1.png'));
    expect(find.text('QUEST COMPLETE \u00b7 CHAPTER 1'), findsOneWidget);
    // Gold and XP are counters, not rows; no bar.
    expect(find.byKey(const Key('reward_gold')), findsOneWidget);
    expect(find.text('+255'), findsOneWidget);
    expect(find.text('+200'), findsOneWidget);
    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.byKey(const Key('reward_bar')), findsNothing);
    // The rest is as on card A.
    expect(find.byKey(const Key('reward_item_mystic_wand')), findsOneWidget);
    expect(find.byKey(const Key('reward_note_chip')), findsOneWidget);
    await _shot(tester, 'reward_quest_banner');
    expect(tester.takeException(), isNull);
  });

  test('every chapter has its art strip', () {
    for (var chapter = 0; chapter <= 9; chapter++) {
      expect(File(chapterArtPath(chapter)).existsSync(), isTrue,
          reason: 'chapter $chapter');
    }
    expect(chapterArtPath(0), chapterArtPath(1));
    expect(chapterArtPath(9), chapterArtPath(8));
  });
}
