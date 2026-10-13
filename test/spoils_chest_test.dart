// The loot chest tells nothing of its rarity until it is tapped (v1.267):
// no tier chip, no tier art, no fortune roll. A tap turns the tiers' colours,
// slower and slower, onto the real one; a second tap skips to it. With
// reduced motion it just opens. The rarity was rolled already: this is how
// it is shown, not what it is.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/loot_box.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/spoils_chest_dialog.dart';

LootBoxResult _result(ChestTier tier) => LootBoxResult(
      tier: tier,
      roll: 17,
      modifiers: const [FortuneModifier('fortune_luck', 3)],
      gold: 12,
      itemIds: const [],
      extraSlot: false,
      floorApplied: ChestTier.silver,
    );

Future<void> _open(WidgetTester tester, ChestTier tier,
    {bool autoOpen = false, bool reduced = false}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SpoilsChestDialog(
        result: _result(tier),
        items: const {},
        autoOpen: autoOpen,
        language: AppLanguage.en,
      ),
    ),
  ));
  await tester.pump();
}

final _chip = find.byKey(const Key('chest_tier_chip'));
final _hidden = find.byKey(const Key('chest_art_hidden'));
const _tiers = ['Wooden', 'Iron', 'Silver', 'Gold', 'Void'];

void main() {
  for (final tier in ChestTier.values) {
    testWidgets('a ${tier.name} chest shows no rarity until it is tapped',
        (tester) async {
      await _open(tester, tier);
      expect(_chip, findsNothing);
      expect(_hidden, findsOneWidget, reason: 'one neutral chest for all');
      for (final name in _tiers) {
        expect(find.text('$name Chest'), findsNothing);
      }
      expect(find.textContaining('Fortune'), findsNothing,
          reason: 'the fortune roll would tell it');
      expect(find.text('Tap the chest to open it.'), findsOneWidget);

      // Turning: still nothing told, and a hint says it can be skipped.
      await tester.tap(find.byKey(const Key('chest_art_hidden')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_chip, findsNothing);
      expect(find.text('Tap to skip'), findsOneWidget);

      // Let it run: it stops on the real rarity, then the chest opens.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 2));
      expect(_chip, findsOneWidget);
      expect(find.text('${_tiers[tier.index]} Chest'), findsOneWidget);
      expect(_hidden, findsNothing);
      expect(find.textContaining('Fortune'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a second tap skips the colours onto the real rarity',
      (tester) async {
    await _open(tester, ChestTier.gold);
    await tester.tap(find.byKey(const Key('chest_art_hidden')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_chip, findsNothing);
    await tester.tap(find.byKey(const Key('chest_art_hidden')));
    // Well short of the full run, it is told.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Gold Chest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with reduced motion it opens and tells at once', (tester) async {
    await _open(tester, ChestTier.silver, reduced: true);
    await tester.tap(find.byKey(const Key('chest_art_hidden')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Silver Chest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chest already open (auto-open) tells its rarity',
      (tester) async {
    await _open(tester, ChestTier.iron, autoOpen: true);
    expect(find.text('Iron Chest'), findsOneWidget);
    expect(_hidden, findsNothing);
  });
}
