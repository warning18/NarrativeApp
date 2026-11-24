// QA: the late game on screen (v2.7.0) on a phone with the app's own fonts:
// the chapter goals card for each goal chapter (none met, all met), the
// Inventory with the Void Banner owned and worn (its wide tile) and without,
// and the chapter chest screen at each of its four tiers. 360 x 740 and
// 320 x 568, English and French, at 1.3x text, no overflow (qa_smoke_harness.dart;
// SMOKE_SHOTS=<folder> for the pictures).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chapter_goals.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/widgets/chapter_chest_dialog.dart';
import 'package:narrative_data_app/widgets/chapter_goals_card.dart';

import 'qa_smoke_harness.dart';

PlayerSession _session(Map<String, dynamic> more) => PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'ownedDiceIds': ['starter_die'],
      'equippedDiceId': 'starter_die',
      ...more,
    });

/// Every chapter's goals, all met (or none).
Map<String, List<String>> _met(int goalsMet) => {
      for (final MapEntry(:key, :value) in chapterGoalTable.entries)
        '$key': [for (final g in value.take(goalsMet)) g.id],
    };

/// A button that opens the chest of [chapter] the way the story does.
class _OpenChest extends ConsumerWidget {
  const _OpenChest(this.chapter);
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton(
        key: const Key('qa_open_chest'),
        onPressed: () => showChapterChest(context, ref, chapter),
        child: const Text('open'),
      );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  testWidgets('the late game reads on a phone, EN and FR, at 1.3x text',
      (tester) async {
    // The big-text setting is the hard case: no overflow here is none at 1x.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await runSmoke(tester, [
      SmokeCase(
        'goals_none',
        Column(children: [
          for (final c in chapterGoalTable.keys) ChapterGoalsCard(chapter: c),
        ]),
        session: _session({'chapterGoalsMet': _met(0)}),
      ),
      SmokeCase(
        'goals_all',
        Column(children: [
          for (final c in chapterGoalTable.keys) ChapterGoalsCard(chapter: c),
        ]),
        session: _session({'chapterGoalsMet': _met(3)}),
      ),
      SmokeCase(
        'inventory_banner_owned',
        const InventoryScreen(),
        bare: true,
        session: _session({
          'inventoryItemIds': ['void_banner', 'armor_leather'],
        }),
      ),
      SmokeCase(
        'inventory_banner_worn',
        const InventoryScreen(),
        bare: true,
        session: _session({
          'inventoryItemIds': ['void_banner', 'armor_leather'],
          'equippedItemIds': ['void_banner', 'armor_leather'],
        }),
      ),
      SmokeCase(
        'inventory_no_banner',
        const InventoryScreen(),
        bare: true,
        session: _session({
          'inventoryItemIds': ['armor_leather'],
        }),
      ),
      for (var met = 0; met <= 3; met++)
        SmokeCase(
          'chest_$met',
          const _OpenChest(5),
          session: _session({'chapterGoalsMet': _met(met)}),
          act: (tester) async {
            await tester.tap(find.byKey(const Key('qa_open_chest')));
          },
        ),
    ]);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
