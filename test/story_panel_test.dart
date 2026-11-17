// The story panel kit (lib/widgets/story_panel.dart): the nine-slice keeps the
// corners and a tier's ornaments at their size, the frame loads and wraps its
// child, the plate and the gem read, and a choice's weight picks its frame.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_plates.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/story_panel.dart';

void main() {
  const k = 2.0;

  test('the four corners keep their size, whatever the panel', () {
    for (final tier in CardTier.values) {
      final slices = frameSlices(tier, const Size(300, 120), k);
      final corners =
          slices.where((s) => s.src.width == 12 && s.src.height == 12);
      expect(corners.length, 4, reason: tier.name);
      for (final c in corners) {
        expect(c.dst.width, 12 * k);
        expect(c.dst.height, 12 * k);
      }
    }
  });

  test(
      'an ornament keeps its size on a wide panel, and is left out of a narrow one',
      () {
    // The gem on top of the rare frame: 14 art pixels.
    final wide = frameSlices(CardTier.rare, const Size(300, 120), k);
    final gem = wide
        .where((s) => s.src.left == 45 && s.src.right == 59 && s.src.top == 0);
    expect(gem.length, 1);
    expect(gem.single.dst.width, 14 * k);
    expect(gem.single.dst.center.dx, 150);
    final narrow = frameSlices(CardTier.rare, const Size(60, 120), k);
    expect(narrow.where((s) => s.src.left == 45 && s.src.right == 59), isEmpty);
    // A tier with no ornament is one stretched run per edge.
    final plain = frameSlices(CardTier.common, const Size(300, 120), k);
    expect(plain.where((s) => s.src.top == 0 && s.src.width > 12).length, 1);
  });

  test('the legendary leaves sit on a tall panel only', () {
    bool leaves(Size size) => frameSlices(CardTier.legendary, size, k)
        .any((s) => s.src.top == 25 && s.src.bottom == 44);
    expect(leaves(const Size(300, 260)), isTrue);
    expect(leaves(const Size(300, 80)), isFalse);
  });

  test('the slices stay inside the panel and the edges meet the corners', () {
    for (final tier in CardTier.values) {
      for (final size in const [Size(300, 260), Size(120, 70), Size(52, 52)]) {
        final slices = frameSlices(tier, size, k);
        for (final s in slices) {
          expect(s.dst.left, greaterThanOrEqualTo(-0.001),
              reason: '$tier $size');
          expect(s.dst.top, greaterThanOrEqualTo(-0.001));
          expect(s.dst.right, lessThanOrEqualTo(size.width + 0.001));
          expect(s.dst.bottom, lessThanOrEqualTo(size.height + 0.001));
        }
      }
    }
  });

  testWidgets('a frame loads, wraps its child and shows the plate and the gem',
      (tester) async {
    await tester.runAsync(StoryFrames.instance.preload);
    expect(StoryFrames.instance.imageFor(CardTier.rare)?.width, 104);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 280,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              StoryFrame(tier: CardTier.rare, child: Text('Framed words')),
              SizedBox(height: 8),
              StoryPlate(
                  title: 'The Salt Crows',
                  color: Color(0xFFB0303F),
                  child: Text('Plate words')),
              SizedBox(height: 8),
              StoryGem('+6', Color(0xFFE8C170), label: 'GOLD'),
            ]),
          ),
        ),
      ),
    ));
    expect(find.text('Framed words'), findsOneWidget);
    expect(find.text('The Salt Crows'), findsOneWidget);
    expect(find.text('Plate words'), findsOneWidget);
    expect(find.text('+6'), findsOneWidget);
    expect(find.text('GOLD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a weight picks the frame: none, the clan accent, the rich metal',
      (tester) async {
    await tester.runAsync(StoryFrames.instance.preload);
    Widget of(ChoiceWeight w) => MaterialApp(
          home: Scaffold(
            body: storyWeightFrame(
                weight: w,
                clan: const Color(0xFF2F62B5),
                child: const Text('words')),
          ),
        );
    await tester.pumpWidget(of(ChoiceWeight.plain));
    expect(find.byType(StoryFrame), findsNothing);
    await tester.pumpWidget(of(ChoiceWeight.weighty));
    expect(tester.widget<StoryFrame>(find.byType(StoryFrame)).tier,
        CardTier.common);
    await tester.pumpWidget(of(ChoiceWeight.major));
    expect(
        tester.widget<StoryFrame>(find.byType(StoryFrame)).tier, CardTier.epic);
    expect(tester.takeException(), isNull);
  });
}
