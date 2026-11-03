// The item detail sheet (inventory, shop, spoils): art on a rarity tile,
// attack and armor as bars against the item worn, elements, traits, set,
// then lore. Set UX_SHOTS=<dir> to write a picture of each case there.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/item_detail_view.dart';
import 'support/fonts.dart';

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final _shotKey = GlobalKey();

Future<void> _open(
  WidgetTester tester, {
  required String id,
  required Map<String, dynamic> items,
  Map<String, dynamic>? equipped,
  String? equippedId,
  bool isWorn = false,
  ItemSet? itemSet,
  int setWorn = 0,
  String? unmet,
  AppLanguage language = AppLanguage.en,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(brightness == Brightness.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light()),
    builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showItemDetailsSheet(
              context,
              itemId: id,
              item: items[id] as Map<String, dynamic>,
              language: language,
              equipped: equipped,
              equippedId: equippedId,
              equippedName: equipped?['itemName']?.toString(),
              priceLine: 'Cost: ${(items[id] as Map)['cost']}',
              itemSet: itemSet,
              setPiecesWorn: setWorn,
              unmetRequirement: unmet,
              isWorn: isWorn,
              actionLabel: 'Equip',
              onAction: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  // The pixel icon decodes off the frame loop.
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

void main() {
  late Map<String, dynamic> items;
  late Map<String, ItemSet> sets;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
    items = _data('items');
    sets = parseItemSets(_data('item_sets'));
  });

  testWidgets('a lance shows its attack against the one worn', (tester) async {
    final worn = {...(items['spear_t10'] as Map<String, dynamic>)}
      ..['itemName'] = 'Iron Spear'
      ..['attackDamage'] = 1;
    await _open(tester,
        id: 'spear_t10', items: items, equipped: worn, equippedId: 'spear_t10');
    expect(find.text('Skybreaker Lance'), findsOneWidget);
    expect(find.byKey(const Key('item_art')), findsOneWidget);
    expect(find.byKey(const Key('item_rarity_tag')), findsOneWidget);
    // 7 against 1: +6 beside the big number, no armor card.
    expect(find.byKey(const Key('item_hero_attackDamage')), findsOneWidget);
    expect(find.byKey(const Key('item_hero_armor')), findsNothing);
    expect(find.text('+6'), findsOneWidget);
    expect(find.textContaining('Iron Spear'), findsOneWidget);
    expect(find.byKey(const Key('item_lore')), findsOneWidget);
    expect(find.text('Equip'), findsOneWidget);
    await _shot(tester, 'item_lance');
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing worn says so; the worn item is not compared to itself',
      (tester) async {
    await _open(tester, id: 'spear_t10', items: items);
    expect(find.text('Nothing worn in this slot yet'), findsOneWidget);
    expect(find.byKey(const Key('item_hero_delta')), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await _open(tester,
        id: 'spear_t10', items: items, isWorn: true, equipped: null);
    expect(find.text('Equipped'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('armor, elements, set and an unmet requirement', (tester) async {
    final set = sets.values.firstWhere((s) => s.itemIds.any((id) =>
        (items[id] as Map?)?['armor'] != null &&
        ((items[id] as Map)['armor'] as num) > 0));
    final id = set.itemIds
        .firstWhere((id) => ((items[id] as Map?)?['armor'] as num? ?? 0) > 0);
    await _open(tester,
        id: id,
        items: items,
        itemSet: set,
        setWorn: 1,
        unmet: 'STR 12',
        language: AppLanguage.fr);
    expect(find.byKey(const Key('item_hero_armor')), findsOneWidget);
    expect(find.byKey(const Key('item_set')), findsOneWidget);
    expect(find.text('Équiper'), findsNothing); // the caller's label
    expect(find.textContaining('STR 12'), findsOneWidget);
    await _shot(tester, 'item_set_fr');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a potion has no stat cards and still reads', (tester) async {
    final id =
        items.keys.firstWhere((k) => (items[k] as Map)['itemType'] == 'Potion');
    await _open(tester, id: id, items: items, brightness: Brightness.light);
    expect(find.byKey(const Key('item_hero_attackDamage')), findsNothing);
    expect(find.byKey(const Key('item_compare_line')), findsNothing);
    await _shot(tester, 'item_potion_light');
    expect(tester.takeException(), isNull);
  });
}
