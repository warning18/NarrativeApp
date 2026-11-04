// loadClanData and loadOfferTables parsed their tables again on every call
// (13 callers, about 2 ms for the clans alone). They now keep the last
// result while the tables are the same objects; an edit in the Data tab
// replaces a table, so the next call parses afresh (v1.761, N6 of
// docs/proposals/core-improvements-2.md).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/offers_provider.dart';

void main() {
  testWidgets('the same tables give the same parse; an edit a fresh one',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox.shrink();
      }),
    ));
    await tester.runAsync(() async {
      // dice.json is read as it stands (not waited for): let it load first.
      await ref.read(gameDbProvider(diceSchema).notifier).whenLoaded();
      final clans = await loadClanData(ref);
      expect(clans.factions, isNotEmpty);
      expect(identical(await loadClanData(ref), clans), isTrue);
      final offers = await loadOfferTables(ref);
      expect(identical(await loadOfferTables(ref), offers), isTrue);
      expect(identical(offers.data, clans), isTrue);

      // An edit of a clan table: both are parsed again, with the edit.
      final titles = ref.read(gameDbProvider(titlesSchema)).value!;
      final id = titles.keys.first;
      await ref.read(gameDbProvider(titlesSchema).notifier).upsertRecord(id, {
        ...(titles[id] as Map<String, dynamic>),
        'name': 'Edited title',
      });
      final edited = await loadClanData(ref);
      expect(identical(edited, clans), isFalse);
      expect(identical((await loadOfferTables(ref)).data, edited), isTrue);
    });
  });

  test('sameTables compares by identity, in order', () {
    final a = <String, dynamic>{'x': 1};
    final b = <String, dynamic>{'x': 1};
    expect(sameTables([a, b], [a, b]), isTrue);
    expect(sameTables([a, b], [b, a]), isFalse);
    final c = <String, dynamic>{'x': 1};
    expect(sameTables([a], [c]), isFalse);
    expect(sameTables([a], [a, b]), isFalse);
  });
}
