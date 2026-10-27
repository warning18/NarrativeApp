// The Forge sheet with tabs (UX mock, nothing built): the four recipes the
// forge has today are all armour, one for each slot (head, body, legs, feet),
// so the tabs are the slots a recipe exists for, not the item types (one
// type today). The left column is the real sheet as it is now (a capture of
// showForgeSheet at the Hammersmith's forge, with three iron ore and 180
// gold in the pack); the rest is drawn with the app's own widgets
// (ItemPixelIcon, ItemStatChips) on the game's real items.
//   UX_SHOTS=docs/ux-shots flutter test test/ux_forge_mock_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/item_stats.dart';
import 'package:narrative_data_app/widgets/shop_trade_sheets.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader.addFont(Future.value(
          ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

const _phoneW = 400.0;
const _phoneH = 720.0;
const _bg = Color(0xFF0B0A0D);
const _cream = Color(0xFFEDE3C8);
const _ash = Color(0xFF9A93A6);

TextStyle _px(double size, {Color color = _cream, FontWeight? w}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, color: color, fontWeight: w);
TextStyle _serif(double size,
        {Color color = _cream,
        FontStyle style = FontStyle.normal,
        FontWeight? w}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        color: color,
        fontStyle: style,
        fontWeight: w,
        height: 1.35);

/// The four recipes of the Hammersmith's forge (items.json `craftedAt`).
class _Recipe {
  const _Recipe(this.id, this.slot, this.slotName, this.ore, this.gold);
  final String id;
  final String slot;
  final String slotName;
  final int ore;
  final int gold;
}

const _recipes = [
  _Recipe('helm_iron_cap', 'Head', 'Head', 2, 45),
  _Recipe('coat_iron_scale', 'Top', 'Body', 5, 110),
  _Recipe('greaves_iron', 'Bottom', 'Legs', 4, 75),
  _Recipe('boots_iron_shod', 'Foot', 'Feet', 3, 60),
];

// What the pack holds in the mock: three iron ore and 180 gold.
const _oreHeld = 3;
const _goldHeld = 180;

bool _canForge(_Recipe r) => _oreHeld >= r.ore && _goldHeld >= r.gold;

Widget _sheet(Widget child, {String? caption}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: _phoneW,
        height: _phoneH,
        decoration: BoxDecoration(
            color: const Color(0xFF6B655E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3A3642), width: 2)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3EAD7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFF8A8174),
                        borderRadius: BorderRadius.circular(2))),
                Expanded(child: child),
              ]),
            ),
          ),
        ]),
      ),
      if (caption != null) ...[
        const SizedBox(height: 8),
        SizedBox(
            width: _phoneW,
            child: Text(caption, style: _serif(12.5, color: _ash))),
      ],
    ]);

Widget _header(BuildContext context, {int gold = _goldHeld}) {
  final ink = InkColors.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    child: Row(children: [
      Expanded(
          child: Text('Forge', style: Theme.of(context).textTheme.titleMedium)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: ink.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(4)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.paid, size: 18, color: ink.gold),
          const SizedBox(width: 4),
          Text('$gold', style: Theme.of(context).textTheme.labelLarge),
        ]),
      ),
    ]),
  );
}

/// The tabs: "All" and one for each slot that has a recipe, a count, and a
/// gold dot where something can be forged now.
Widget _tabs(BuildContext context, String selected) {
  final ink = InkColors.of(context);
  Widget tab(String label, int n, bool ready, {bool dim = false}) {
    final on = selected == label;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Opacity(
        opacity: dim ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF3A3642) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: on ? const Color(0xFF3A3642) : const Color(0xFFB8AC96)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: _px(13,
                    color:
                        on ? const Color(0xFFEDE3C8) : const Color(0xFF3A3642),
                    w: on ? FontWeight.w600 : null)),
            const SizedBox(width: 4),
            Text('$n',
                style: _px(12,
                    color: on
                        ? const Color(0xFFE9B949)
                        : const Color(0xFF7A6F61))),
            if (ready) ...[
              const SizedBox(width: 4),
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: ink.gold, shape: BoxShape.circle)),
            ],
          ]),
        ),
      ),
    );
  }

  final anyReady = _recipes.any(_canForge);
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      tab('All', _recipes.length, anyReady),
      for (final r in _recipes) tab(r.slotName, 1, _canForge(r)),
    ]),
  );
}

Widget _needsLine(BuildContext context, _Recipe r) {
  Widget need(String text, bool ok) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            size: 14, color: ok ? Colors.green.shade700 : Colors.red.shade700),
        const SizedBox(width: 4),
        Text(text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ok ? null : Colors.red.shade800,
                fontWeight: ok ? null : FontWeight.w600)),
      ]);
  return Wrap(spacing: 12, runSpacing: 2, children: [
    need('Iron Ore $_oreHeld/${r.ore}', _oreHeld >= r.ore),
    need('${r.gold} gold', _goldHeld >= r.gold),
  ]);
}

Widget _card(BuildContext context, Map<String, dynamic> items, _Recipe r,
    {required bool big, Map<String, dynamic>? worn, bool slotTag = false}) {
  final item = items[r.id] as Map<String, dynamic>;
  final theme = Theme.of(context);
  final ok = _canForge(r);
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ItemPixelIcon(r.id, 'Armor', size: big ? 44 : 32),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['itemName'] as String,
                  style: big
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleSmall),
              if (slotTag)
                Text('${r.slotName} · ${item['rarity']}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
          FilledButton(
              onPressed: ok ? () {} : null, child: const Text('Forge')),
        ]),
        const SizedBox(height: 6),
        ItemStatChips(
            item: item,
            language: AppLanguage.en,
            equipped: worn,
            compact: true),
        const SizedBox(height: 4),
        _needsLine(context, r),
        if (big) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.casino_outlined, size: 15),
            const SizedBox(width: 5),
            Text('Rolls a d20 · dwarf +2 · Fine at 13, Masterwork at 18',
                style: theme.textTheme.bodySmall),
          ]),
        ],
      ]),
    ),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the forge mock is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the forge sheet, with tabs', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    final items =
        jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
            as Map<String, dynamic>;
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));

    // Today: the real sheet.
    tester.view.physicalSize = const Size(_phoneW, _phoneH);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final todayKey = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: todayKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  key: const Key('open_forge'),
                  onPressed: () =>
                      showForgeSheet(context, shopId: 'hammersmith_forge'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    // The session loads itself from the preferences: let it, then replace it.
    container.read(playerSessionProvider);
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'dwarf',
          'professionId': 'warrior',
          'gold': _goldHeld,
          'inventoryItemIds': [
            for (var i = 0; i < _oreHeld; i++) 'material_iron_ore'
          ],
        })));
    await _settle(tester);
    expect(container.read(playerSessionProvider).gold, _goldHeld);
    await tester.tap(find.byKey(const Key('open_forge')));
    await _settle(tester, n: 6);
    ui.Image? today;
    await tester.runAsync(() async {
      final boundary =
          todayKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      today = await boundary.toImage(pixelRatio: 1.5);
    });

    // The board.
    Widget proposedFeet(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 6),
            _tabs(context, 'Feet'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(children: [
                const Icon(Icons.hiking, size: 16, color: Color(0xFF7A6F61)),
                const SizedBox(width: 6),
                Text('Worn on your feet: nothing',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _card(context, items, _recipes[3],
                      big: true, worn: const <String, dynamic>{}),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'Iron ore comes off Inquisition soldiers, the dock overseer, wisps, the iron golem and the dead of the catacombs.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        );

    Widget proposedAll(BuildContext context) {
      final sorted = [
        ..._recipes
      ]..sort((a, b) => (_canForge(b) ? 1 : 0).compareTo(_canForge(a) ? 1 : 0));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: 6),
          _tabs(context, 'All'),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('CAN BE FORGED NOW',
                      style: _px(11, color: const Color(0xFF7A6F61))),
                ),
                for (final r in sorted.where(_canForge))
                  _card(context, items, r, big: false, slotTag: true),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: Text('NEEDS MORE',
                      style: _px(11, color: const Color(0xFF7A6F61))),
                ),
                for (final r in sorted.where((r) => !_canForge(r)))
                  _card(context, items, r, big: false, slotTag: true),
              ],
            ),
          ),
        ],
      );
    }

    Widget notes() => Container(
          width: _phoneW,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF17151B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3A3642))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What the data says', style: _px(15, w: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
                'The forge has four recipes, all Armor, one for each slot: Iron Cap (head), Iron Scale Coat (body), Iron Greaves (legs), Iron-Shod Boots (feet). Tabs by item type would be a single tab. So the tabs are the slots, and a slot appears only when a recipe for it exists.',
                style: _serif(13)),
            const SizedBox(height: 14),
            Text('The tabs', style: _px(15, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                '• All first, then Head, Body, Legs, Feet (the slot names the Character screen uses).\n• A count on each, and a gold dot where something can be forged now.\n• A slot with no recipe has no tab. When Core gives the forge weapons or charms, they come in as Weapon and Charm tabs by item type: the tab row is slots for armour, types for the rest.\n• The tab you left on is the one the sheet opens on next time.',
                style: _serif(13)),
            const SizedBox(height: 14),
            Text('A slot’s tab', style: _px(15, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                '• A line says what you wear in that slot, so the card’s stat chips show the gain or the loss against it (the compare the shop and the pack already use).\n• The card is bigger: the piece, what it needs with a tick or a cross, and the roll line (d20, the dwarf’s +2, where Fine and Masterwork start), so the odds are readable before pressing Forge.\n• The ore hint moves to the foot of a tab that lacks ore.',
                style: _serif(13)),
            const SizedBox(height: 14),
            Text('The All tab', style: _px(15, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                '• Rows as today, in two groups: what can be forged now, then what needs more (the missing part in red).\n• Each row says its slot and rarity.',
                style: _serif(13)),
            const SizedBox(height: 14),
            Text('What it needs', style: _px(15, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                'Nothing from Core: the recipes, `equipSlot` and the roll’s modifiers exist. UX builds the sheet in about a day, and the forging moment (the d20, the tier) is the next picture.',
                style: _serif(13)),
          ]),
        );

    const boardW = 4 * (_phoneW + 20) + 20;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(boardW, 900);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: _bg,
        body: RepaintBoundary(
          key: key,
          child: Container(
            width: boardW,
            height: 900,
            color: _bg,
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The Forge sheet, with tabs',
                  style: _px(22, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'The forge’s four recipes are all armour, one for each slot, so the tabs are the slots (All, Head, Body, Legs, Feet). Left: the real sheet today (three iron ore and 180 gold in the pack). The rest is drawn with the app’s own widgets on the real items. Nothing is built.',
                  style: _serif(12.5, color: _ash)),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: _phoneW,
                    height: _phoneH,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: RawImage(
                          image: today,
                          width: _phoneW,
                          height: _phoneH,
                          fit: BoxFit.fill),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: _phoneW,
                      child: Text(
                          '1. Today: one list of four cards in the order of the file, the same card for every piece.',
                          style: _serif(12.5, color: _ash))),
                ]),
                const SizedBox(width: 20),
                Builder(
                    builder: (context) => _sheet(proposedFeet(context),
                        caption:
                            '2. A slot’s tab (Feet): what is worn there, the gain against it, what it needs, the roll’s odds.')),
                const SizedBox(width: 20),
                Builder(
                    builder: (context) => _sheet(proposedAll(context),
                        caption:
                            '3. The All tab: what can be forged now first, what needs more after, with the slot on each row.')),
                const SizedBox(width: 20),
                notes(),
              ]),
            ]),
          ),
        ),
      ),
    ));
    await _settle(tester, n: 5);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/forge-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
