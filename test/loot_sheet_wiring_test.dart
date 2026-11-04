// The spoils sheet wired to the chest (spoils_chest_dialog.dart) and to what
// the engine says each reward changes (loot_changes.dart): the adapter's
// lines, and the dialog giving way to the sheet once the chest is open.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/loot_box.dart';
import 'package:narrative_data_app/data/loot_changes.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/loot_sheet_lines.dart';
import 'package:narrative_data_app/widgets/spoils_chest_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;
import 'support/fonts.dart';
import 'support/pump.dart';

final Map<String, dynamic> _items =
    jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('the lines', () {
    const ink = InkColors.dark;

    test('a value several rewards move runs from the first before to the last',
        () {
      final lines = lootSheetLines(
        [
          const LootRewardChanges(goldRewardId, [
            LootChange(kind: LootChangeKind.gold, before: 126, after: 144),
          ]),
          const LootRewardChanges('antidote', [
            LootChange(kind: LootChangeKind.antidotes, before: 1, after: 2),
          ]),
          const LootRewardChanges('antidote', [
            LootChange(kind: LootChangeKind.antidotes, before: 2, after: 3),
          ]),
          const LootRewardChanges('armor_leather', [
            LootChange(kind: LootChangeKind.nothing, before: 0, after: 0),
          ]),
        ],
        language: AppLanguage.en,
        ink: ink,
        items: _items,
      );
      expect(lines.map((l) => '${l.label}: ${l.before} > ${l.after}'),
          ['Gold: 126 > 144', 'Antidotes: ×1 > ×3']);
    });

    test('a charm that adds rolls a round is one line, not two', () {
      final lines = lootSheetLines(
        [
          const LootRewardChanges('charm_fourth_roll', [
            LootChange(
                kind: LootChangeKind.bagItem,
                subjectId: 'charm_fourth_roll',
                before: 0,
                after: 1),
            LootChange(kind: LootChangeKind.rollsPerRound, before: 3, after: 4),
          ]),
        ],
        language: AppLanguage.en,
        ink: ink,
        items: _items,
      );
      expect(lines.map((l) => l.label), ['Dice rolls a round']);
    });

    test('every kind of line has a label and a before and an after', () {
      for (final language in AppLanguage.values) {
        final lines = lootSheetLines(
          [
            for (final kind in LootChangeKind.values)
              LootRewardChanges('r_${kind.name}', [
                LootChange(
                    kind: kind,
                    subjectId: switch (kind) {
                      LootChangeKind.bagItem => 'charm_fourth_roll',
                      LootChangeKind.spell => 'fireball',
                      _ => null,
                    },
                    before: 1,
                    after: 2),
              ]),
          ],
          language: language,
          ink: ink,
          items: _items,
          spellName: (id) => 'Fireball',
        );
        // Everything but "nothing" is a line.
        expect(lines, hasLength(LootChangeKind.values.length - 1));
        for (final l in lines) {
          expect(l.label, isNotEmpty);
          expect(l.before, isNotEmpty);
          expect(l.after, isNotEmpty);
        }
      }
    });
  });

  group('the dialog', () {
    Future<void> open(WidgetTester tester, AppLanguage language,
        {List<String> items = const ['charm_fourth_roll', 'antidote'],
        void Function(SpoilsChoices)? onTake}) async {
      await tester.runAsync(loadAppFonts);
      usePhone(tester, const Size(360, 740));
      final session = baseSession(
          gold: 126,
          maxHealth: 100,
          currentHealth: 60,
          inventoryItemIds: ['antidote']);
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark)),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final choices = await showSpoilsChestDialog(
                  context,
                  result: LootBoxResult(
                    tier: ChestTier.silver,
                    roll: 17,
                    modifiers: const [],
                    gold: 18,
                    itemIds: items,
                    extraSlot: false,
                  ),
                  items: _items,
                  autoOpen: true,
                  language: language,
                  currentHealth: 60,
                  maxHealth: 100,
                  sheet: SpoilsSheetData(
                      session: session, gold: 18, itemIds: items),
                );
                onTake?.call(choices);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('the chest opened shows the sheet: what the loot changes',
        (tester) async {
      await open(tester, AppLanguage.en);
      expect(find.byKey(const Key('spoils_sheet')), findsOneWidget);
      expect(find.byKey(const Key('loot_sheet')), findsOneWidget);
      // Gold 126 to 144, and the antidote joins the bag.
      expect(find.byKey(const Key('loot_change_Gold')), findsOneWidget);
      expect(find.text('126'), findsOneWidget);
      expect(find.text('144'), findsOneWidget);
      expect(find.byKey(const Key('loot_change_Antidotes')), findsOneWidget);
      // The Knucklebone's rolls a round, and both rewards' texts below.
      expect(find.byKey(const Key('loot_change_Dice rolls a round')),
          findsOneWidget);
      expect(find.byKey(const Key('loot_reward_1')), findsOneWidget);
      expect(find.byKey(const Key('loot_reward_2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in French too, and Take closes with the choices',
        (tester) async {
      SpoilsChoices? got;
      await open(tester, AppLanguage.fr, onTake: (c) => got = c);
      expect(find.byKey(const Key('loot_change_Or')), findsOneWidget);
      await tester.tap(find.byKey(const Key('loot_sheet_take')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(got, isNotNull);
      expect(got!.drinkItemIds, isEmpty);
    });

    testWidgets('a potion drunk from the sheet changes health and the choices',
        (tester) async {
      SpoilsChoices? got;
      await open(tester, AppLanguage.en,
          items: const ['potion_minor'], onTake: (c) => got = c);
      expect(find.byKey(const Key('loot_change_Health')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('loot_use_1')));
      await tester.tap(find.byKey(const Key('loot_use_1')));
      await tester.pump();
      // Drunk: the health line appears, 60 to 68.
      expect(find.byKey(const Key('loot_change_Health')), findsOneWidget);
      await tester.tap(find.byKey(const Key('loot_sheet_take')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(got!.drinkItemIds, ['potion_minor']);
    });
  });
}
