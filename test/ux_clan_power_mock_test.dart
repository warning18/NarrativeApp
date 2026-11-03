// The clan power sign, three other ways (UX mock): the user finds the banner
// filling itself (v1.576) unclear, so today's cloth is drawn as the
// reference with what is unclear about it, then three different ways to show
// how strong a clan is (A. ranking, B. torches, C. skyline) on the four places
// where a clan's power shows, at 412 and 320 px. Nothing is built.
// UX_SHOTS=<folder> takes the pictures (docs/ux-shots/clan-power/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'ux_clan_power_parts.dart';
import 'ux_clan_power_scenes.dart';
import 'support/fonts.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  test('every clan is ranked and the attack line is where Core put it', () {
    final ranked = byStrength();
    expect(ranked.first.id, 'dominion');
    expect(ranked.last.id, 'kindly');
    expect(rankOf(clanById('crows')), 2);
    expect(attackPower, 10);
    expect(tierName(60), 'Dominant');
    expect(sampleClans.every((c) => c.power >= attackPower), isTrue);
  });

  testWidgets('the boards (UX_SHOTS)', (tester) async {
    if (shots == null || shots.isEmpty) return;
    await tester.runAsync(loadAppFonts);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 2600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Directory(shots).createSync(recursive: true);
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));

    Future<void> shoot(String file, Widget Function(BuildContext) build) async {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: Material(
              color: const Color(0xFF17151B),
              child: Builder(builder: build),
            ),
          ),
        ),
      ));
      await _settle(tester);
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull, reason: file);
    }

    await shoot('compare.png', compareBoard);
    await shoot(
        'idea-a-ranking.png',
        (c) => board(
            c,
            Idea.ranking,
            'A. Ranking: a place in the line, and an arrow',
            'Strength is a position and a number: each clan wears its rank among the clans and an arrow for how it moved since the last chapter; a clan\'s page ranks all the clans in bars with the tiers and the attack line marked. Neutral gold and blue-grey, never the standing\'s green and red.'));
    await shoot(
        'idea-b-torches.png',
        (c) => board(c, Idea.torches, 'B. Torches: how many are lit',
            'Four torches, one for each 25 power, lit as far as the power has reached them; a clan too weak to attack (under 10) has only an ember. The torches sit beside the banner, never on it, so the banner keeps its colours and the standing disc keeps its corner.'));
    await shoot(
        'idea-c-skyline.png',
        (c) => board(c, Idea.skyline, 'C. Skyline: the stronger, the taller',
            'Banners stand on one ground line as tall as the clan is strong, the strongest first, so a list of clans is a skyline you read at once; a gold edge is what a clan gained since the last chapter, a dashed outline what it lost. In a district the banner planted at the seat is as tall as its clan.'));
  });
}
