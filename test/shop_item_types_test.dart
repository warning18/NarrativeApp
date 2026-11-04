// A shop page in French shows the item types in French ("Arme", "Armure"),
// on the filter chips and on each item's line, at 320 px; no raw English
// type is left. (Potion and Tome read the same in both languages.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/shop_detail_screen.dart';

import 'qa_smoke_harness.dart';

const _english = [
  'Weapon',
  'Armor',
  'Spellbook',
  'Material',
  'Artifact',
  'Charm',
  'Scroll',
  'Quest',
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final shops =
      jsonDecode(File('assets/gamedata/shops.json').readAsStringSync())
          as Map<String, dynamic>;

  testWidgets('every shop page shows French item types, none in English',
      (tester) async {
    final raw = <String>[];
    await runSmoke(
      tester,
      [
        for (final id in shops.keys)
          SmokeCase(
            'shop_types_$id',
            ShopDetailScreen(
                shopId: id, shop: shops[id] as Map<String, dynamic>),
            session: PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'level': 12,
              'gold': 900,
            }),
            prepare: (c) async {
              for (final s in [shopsSchema, itemsSchema]) {
                await c.read(gameDbProvider(s).notifier).whenLoaded();
              }
            },
            bare: true,
            after: (tester) async {
              final container = ProviderScope.containerOf(
                  tester.element(find.byType(ShopDetailScreen)));
              if (container.read(appLanguageProvider) != AppLanguage.fr) return;
              for (final w in tester.widgetList<Text>(find.byType(Text))) {
                final t = w.data ?? w.textSpan?.toPlainText() ?? '';
                final first = t.split(' · ').first.trim();
                if (_english.contains(first)) raw.add('$id: "$t"');
              }
            },
          ),
      ],
      sizes: const [Size(320, 568)],
    );
    expect(raw, isEmpty, reason: 'English item types in French:\n$raw');
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('the French names are the ones Narrative worded', () {
    const fr = {
      'item_type_weapon': 'Arme',
      'item_type_armor': 'Armure',
      'item_type_spellbook': 'Grimoire',
      'item_type_material': 'Matériau',
      'item_type_artifact': 'Artefact',
      'item_type_charm': 'Talisman',
      'item_type_scroll': 'Parchemin',
      'item_type_quest': 'Objet de quête',
      'item_type_quest_short': 'Quête',
    };
    // Read through the public lookup that callbacks use.
    fr.forEach((k, v) => expect(trFor(AppLanguage.fr, k), v));
  });
}
