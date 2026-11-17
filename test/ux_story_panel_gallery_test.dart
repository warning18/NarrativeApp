// The story panel kit on one page (UX_SHOTS=<folder>): the five frames at
// three sizes (the ornaments keep their size), a plate and its gems, and the
// three weights of a choice. Dark and light, 360 wide. Drawn only with
// UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_plates.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/story_panel.dart';

import 'support/fonts.dart';

Widget _page(BuildContext c) {
  final ink = InkColors.of(c);
  TextStyle prose(double s) =>
      TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.35);
  Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t,
            style: TextStyle(
                fontFamily: InkFonts.system, fontSize: 10, color: ink.ash)),
      );
  return Scaffold(
    body: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      children: [
        label(
            'THE FIVE FRAMES: wide, square, tall (corners and ornaments keep their size)'),
        for (final tier in CardTier.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 5,
                child: StoryFrame(
                    tier: tier,
                    band: 0.8,
                    child: Text(tier.name, style: prose(14))),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                height: 64,
                child: StoryFrame(
                    tier: tier,
                    band: 0.8,
                    padding: EdgeInsets.zero,
                    child: const SizedBox()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 54,
                height: 140,
                child: StoryFrame(
                    tier: tier,
                    band: 0.8,
                    padding: EdgeInsets.zero,
                    child: const SizedBox()),
              ),
            ]),
          ),
        label('A PLATE AND ITS GEMS'),
        StoryPlate(
          title: 'A Smuggler’s Favour',
          color: const Color(0xFFB0303F),
          trail: Text('CH 2',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 9,
                  color: storyInkOn(const Color(0xFFB0303F)))),
          child: Row(children: [
            const StoryGem('+40', Color(0xFFE8C170), label: 'GOLD', size: 30),
            const SizedBox(width: 8),
            const StoryGem('+40', Color(0xFF4F8FBA), label: 'XP', size: 30),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Bring back iron ore for the smuggler’s forge',
                    style: prose(14))),
          ]),
        ),
        label('THE THREE WEIGHTS OF A CHOICE'),
        storyWeightFrame(
            weight: ChoiceWeight.plain,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Walk the stalls before dealing with Vane',
                    style: prose(16)))),
        const SizedBox(height: 6),
        storyWeightFrame(
            weight: ChoiceWeight.weighty,
            clan: const Color(0xFFB0303F),
            child: Text('Lift what you can from an unwatched crate',
                style: prose(16))),
        const SizedBox(height: 8),
        storyWeightFrame(
            weight: ChoiceWeight.major,
            rich: CardTier.legendary,
            child: Text('Cut the taken’s names from the throne first',
                style: prose(16))),
      ],
    ),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the kit', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(StoryFrames.instance.preload);
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 1160);
    final key = GlobalKey();
    for (final dark in [true, false]) {
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(AppPalette.stitchedInk
              .schemeFor(dark ? Brightness.dark : Brightness.light)),
          home: Builder(builder: _page),
        ),
      ));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      late List<int> bytes;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/kit-${dark ? 'dark' : 'light'}.png').writeAsBytesSync(bytes);
    }
  });
}
