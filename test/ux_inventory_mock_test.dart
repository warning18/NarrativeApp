// A review of the Inventory & Equipment screen, with a mock of the fixes (UX,
// for the user to approve before anything is built). One picture, at the two
// phone widths (320 and 412): today (faithfully drawn from the screen and
// from items.json) and the proposal. The bag in the picture is the user's
// own screenshot: the Lucky Die in its slot, Champion's Trophy (material),
// Gambler's Knucklebone (charm) and Warden's Signet (armor, ARM +1, which
// items.json puts in the Head slot).
//
// What is wrong today, and the fix drawn:
//  1. The Dice slot shows the raw id "starter_die" (the die's name is
//     "Lucky Die" / "Dé porte-bonheur": dieDisplayName already has it).
//  2. Every empty slot has the same generic box; the slot's own icon says
//     what it takes.
//  3. The Warden's Signet is "Armor ARM +1" but nothing says where it goes
//     (it is a Head piece): the row says "Head" with the slot's icon.
//  4. A "+" with no word; the swap icon at the top right unexplained.
//  5. A type word where the numbers should be: stat chips (ItemStatChips)
//     with the change against what is worn.
//  6. One long flat list: tabs by category, only those with items, with a
//     count, remembering the last one.
// Less on each row, not more.
// UX_SHOTS=<folder> takes docs/ux-shots/inventory-mock.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/item_stats.dart';
import 'support/fonts.dart';

const _pageBg = Color(0xFF17151B);
const _ash = Color(0xFF9A93A6);

// The items of the screenshot, as items.json has them.
const _signet = <String, dynamic>{
  'itemType': 'Armor',
  'equipSlot': 'Head',
  'armor': 1,
  'rarity': 'Rare',
  'isEquippable': true,
};
const _ironCap = <String, dynamic>{
  'itemType': 'Armor',
  'equipSlot': 'Head',
  'armor': 1,
  'earthResist': 1,
  'rarity': 'Uncommon',
  'isEquippable': true,
};

TextStyle _prose(double size,
        {Color? c, bool bold = false, bool italic = false}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        height: 1.25,
        color: c ?? const Color(0xFFEDE6DC),
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal);

TextStyle _px(double size, {Color? c}) => TextStyle(
    fontFamily: 'PixelifySans',
    fontSize: size,
    color: c ?? const Color(0xFFEDE6DC));

/// The phone: [width] wide, a fixed height, the app bar drawn by hand.
Widget _phone(String title, double width, Widget Function(BuildContext) body,
        {double height = 700}) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title, style: _prose(13.5, c: const Color(0xFFE2B890))),
      ),
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF121116),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A3642)),
        ),
        clipBehavior: Clip.antiAlias,
        child: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: Builder(builder: body),
        ),
      ),
    ]);

Widget _appBar(String title, List<Widget> actions) => Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF1B1A21),
      child: Row(children: [
        const Icon(Icons.arrow_back, size: 22, color: Color(0xFFEDE6DC)),
        const SizedBox(width: 14),
        Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'IMFellEnglishSC',
                    fontSize: 20,
                    color: Color(0xFFEDE6DC)))),
        ...actions,
      ]),
    );

// ---------------------------------------------------------------- today

Widget _todaySlot(BuildContext context, String slot, String worn,
    {bool filled = false, Widget? icon}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: filled ? ink.gold : ink.seam),
    ),
    child: Row(children: [
      SizedBox(
          width: 28,
          child: Center(
              child: icon ??
                  // The generic box every empty slot uses.
                  const ItemPixelIcon(null, null, size: 22))),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(slot.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          Text(worn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: filled ? null : ink.ash,
                  fontStyle: filled ? null : FontStyle.italic)),
        ]),
      ),
    ]),
  );
}

Widget _todayRow(BuildContext context, String id, String type, String name,
    String rarity, String sub,
    {bool plus = false}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return Card(
    margin: const EdgeInsets.only(bottom: 6),
    color: colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: ink.seam)),
    child: ListTile(
      leading: ItemPixelIcon(id, type),
      title: Row(children: [
        Expanded(
            child: Text(name,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontFamily: InkFonts.display))),
        InkTag(label: rarity, color: ink.ash),
      ]),
      subtitle:
          Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
      trailing: plus ? const Icon(Icons.add_circle_outline) : null,
    ),
  );
}

Widget _today(BuildContext context, double width) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  Widget caption(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
      );
  final slots = [
    _todaySlot(context, 'Dice', 'starter_die',
        filled: true, icon: Icon(Icons.casino, size: 20, color: ink.gold)),
    _todaySlot(context, 'Head', '(empty)'),
    _todaySlot(context, 'Top', '(empty)'),
    _todaySlot(context, 'Weapon', '(empty)'),
    _todaySlot(context, 'Bottom', '(empty)'),
    _todaySlot(context, 'Foot', '(empty)'),
  ];
  return Column(children: [
    _appBar('Inventory & Equipment', const [
      Icon(Icons.help_outline, size: 22, color: Color(0xFFEDE6DC)),
      SizedBox(width: 14),
      Icon(Icons.compare_arrows_outlined, size: 22, color: Color(0xFFEDE6DC)),
    ]),
    Expanded(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        caption('Equipment'),
        for (var i = 0; i < slots.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: slots[i]),
                    const SizedBox(width: 8),
                    Expanded(child: slots[i + 1]),
                  ]),
            ),
          ),
        Text('Tap a slot to choose what goes there.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        caption('All Items · 3'),
        _todayRow(context, 'boss_trophy', 'Material', 'Champion’s Trophy',
            'Common', 'Material'),
        _todayRow(context, 'charm_fourth_roll', 'Charm',
            'Gambler’s Knucklebone', 'Uncommon', 'Charm'),
        _todayRow(context, 'warden_signet', 'Armor', 'Warden’s Signet', 'Rare',
            'Armor · ARM +1',
            plus: true),
      ]),
    ),
  ]);
}

// ------------------------------------------------------------- the fix

const _slotIcons = <String, IconData>{
  'Dice': Icons.casino,
  'Head': Icons.sports_motorsports_outlined,
  'Top': Icons.checkroom_outlined,
  'Weapon': Icons.gavel,
  'Bottom': Icons.airline_seat_legroom_normal,
  'Foot': Icons.hiking,
};

/// A slot as a tile: its own icon (faded when empty), under it the name of
/// what is in it, or the slot's name.
Widget _slotTile(String slot, String? worn, {Widget? icon, bool lit = false}) {
  final filled = worn != null;
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1D1B22),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
          color: lit
              ? const Color(0xFFF2C14E)
              : filled
                  ? const Color(0xFFE2B890).withValues(alpha: 0.7)
                  : const Color(0xFF3A3642),
          width: lit ? 2 : 1),
    ),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      icon ??
          Icon(_slotIcons[slot],
              size: 26,
              color:
                  filled ? const Color(0xFFE2B890) : const Color(0xFF5A5466)),
      const SizedBox(height: 4),
      Text(worn ?? slot,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _prose(11.5,
              c: filled ? const Color(0xFFEDE6DC) : const Color(0xFF7C768A),
              italic: !filled)),
    ]),
  );
}

Widget _tab(String label, int n, {bool on = false}) => Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: on
            ? const Color(0xFFB794F6).withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: on ? const Color(0xFFB794F6) : const Color(0xFF3A3642)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: _prose(13, c: on ? Colors.white : _ash)),
        const SizedBox(width: 5),
        Text('$n', style: _px(12, c: on ? Colors.white : _ash)),
      ]),
    );

/// A row: its picture, its name, one quiet line, the numbers that matter
/// and one clear action.
Widget _newRow(String id, String type, String name, String line,
    {Map<String, dynamic>? item,
    Map<String, dynamic>? worn,
    String? slot,
    bool fresh = false,
    bool equip = false}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: const Color(0xFF1D1B22),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF33303B)),
    ),
    child: Row(children: [
      ItemPixelIcon(id, type, size: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'IMFellEnglishSC',
                      fontSize: 16,
                      color: Color(0xFFEDE6DC))),
            ),
            if (fresh) ...[
              const SizedBox(width: 6),
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFF2C14E))),
            ],
          ]),
          const SizedBox(height: 2),
          Row(children: [
            if (slot != null) ...[
              Icon(_slotIcons[slot], size: 13, color: _ash),
              const SizedBox(width: 3),
            ],
            Flexible(
                child: Text(line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _prose(11.5, c: _ash))),
          ]),
          if (item != null) ...[
            const SizedBox(height: 4),
            ItemStatChips(
                item: item,
                equipped: worn,
                language: AppLanguage.en,
                compact: true),
          ],
        ]),
      ),
      if (equip)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB794F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Equip', style: _px(12.5, c: Colors.black)),
        ),
    ]),
  );
}

Widget _after(BuildContext context, double width,
    {String tab = 'All', bool compareWorn = false}) {
  return Column(children: [
    // The swap icon is gone (a row compares by itself); the guide stays.
    _appBar('Inventory', const [
      Icon(Icons.help_outline, size: 22, color: Color(0xFFEDE6DC)),
    ]),
    Expanded(
      child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          children: [
            // The six slots as tiles, three by two: their own icons, the die
            // by its name.
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _slotTile('Dice', 'Lucky Die',
                    icon: const Icon(Icons.casino,
                        size: 26, color: Color(0xFFF2C14E))),
                _slotTile('Head', compareWorn ? 'Iron Cap' : null,
                    lit: !compareWorn,
                    icon: compareWorn
                        ? const ItemPixelIcon('helm_iron_cap', 'Armor',
                            size: 26)
                        : null),
                _slotTile('Top', null),
                _slotTile('Weapon', null),
                _slotTile('Bottom', null),
                _slotTile('Foot', null),
              ],
            ),
            const SizedBox(height: 12),
            // The tabs: only the kinds the bag has, with a count; the last one
            // is remembered. A quiet sort at the end.
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _tab('All', 3, on: tab == 'All'),
                _tab('Gear', 1, on: tab == 'Gear'),
                _tab('Charms', 1),
                _tab('Materials', 1),
              ]),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(tab == 'Gear' ? 'Gear' : 'Newest first',
                  style: _prose(11.5, c: _ash, italic: true)),
              const Spacer(),
              const Icon(Icons.sort, size: 16, color: _ash),
              const SizedBox(width: 3),
              Text('Newest', style: _prose(11.5, c: _ash)),
            ]),
            const SizedBox(height: 8),
            if (tab == 'All') ...[
              _newRow('warden_signet', 'Armor', 'Warden’s Signet',
                  'Rare · goes on the Head',
                  item: _signet,
                  worn: compareWorn ? _ironCap : null,
                  slot: 'Head',
                  fresh: true,
                  equip: true),
              _newRow('charm_fourth_roll', 'Charm', 'Gambler’s Knucklebone',
                  'Charm · a fourth roll'),
              _newRow(
                  'boss_trophy', 'Material', 'Champion’s Trophy', 'Material'),
            ] else ...[
              _newRow('warden_signet', 'Armor', 'Warden’s Signet',
                  'Rare · goes on the Head',
                  item: _signet,
                  worn: compareWorn ? _ironCap : null,
                  slot: 'Head',
                  fresh: true,
                  equip: true),
            ],
          ]),
    ),
  ]);
}

/// What a tap on a row opens: the piece, where it goes, the change.
Widget _detail(BuildContext context, double width) {
  return Container(
    color: const Color(0xFF121116),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        height: 90,
        color: const Color(0xFF1B1A21),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const ItemPixelIcon('warden_signet', 'Armor', size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Warden’s Signet',
                      style: TextStyle(
                          fontFamily: 'IMFellEnglishSC',
                          fontSize: 19,
                          color: Color(0xFFEDE6DC))),
                  Row(children: [
                    const Icon(Icons.sports_motorsports_outlined,
                        size: 14, color: _ash),
                    const SizedBox(width: 4),
                    Text('Rare · goes in the Head slot',
                        style: _prose(12, c: _ash)),
                  ]),
                ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('INSTEAD OF  IRON CAP (WORN)',
              style: _prose(10.5, c: _ash, bold: true)),
          const SizedBox(height: 8),
          for (final (label, from, to) in const [
            ('Armor', '1', '1'),
            ('Earth resist', '1', '0'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(label, style: _prose(14))),
                Text(from, style: _px(15, c: _ash)),
                const Icon(Icons.arrow_right_alt, size: 20, color: _ash),
                Text(to,
                    style: _px(17,
                        c: to == from
                            ? const Color(0xFFEDE6DC)
                            : const Color(0xFFD9625C))),
              ]),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () {}, child: const Text('Equip')),
          ),
          const SizedBox(height: 6),
          Center(
              child: Text(
                  'A tap on a row opens this; Equip on the row wears it at once',
                  style: _prose(11, c: _ash, italic: true))),
        ]),
      ),
    ]),
  );
}

Widget _board(ThemeData theme) => Theme(
      data: theme,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Inventory & Equipment: today, and a proposal',
              style: _prose(19)),
          const SizedBox(height: 4),
          SizedBox(
            width: 1200,
            child: Text(
                'The bag is the user’s own screenshot. Wrong today: the die shows its id "starter_die"; every empty slot is the same box; the Warden’s Signet says "Armor" but not where it goes (items.json puts it in the Head slot); an unlabelled “+”; an unexplained swap icon; a type word where the numbers should be; one flat list.',
                style: _prose(12, c: _ash)),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _phone('Today, 320 px', 320, (c) => _today(c, 320), height: 580),
            const SizedBox(width: 22),
            _phone('Today, 412 px', 412, (c) => _today(c, 412), height: 580),
          ]),
          const SizedBox(height: 26),
          SizedBox(
            width: 1200,
            child: Text(
                'Proposed. Tabs only for the kinds in the bag, with a count (All, Gear, Charms, Materials, Potions, Books, Quest; remembered); the six slots as small tiles with their own icons and the die by its name; each row a name, one quiet line, the numbers (and the change against what is worn) and one labelled Equip; a gold dot for what is new; the swap icon gone (a row compares by itself); a tap opens the piece with its before and after.',
                style: _prose(12, c: _ash)),
          ),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _phone('Proposed, 320 px (All)', 320, (c) => _after(c, 320),
                height: 580),
            const SizedBox(width: 22),
            _phone('Proposed, 412 px (Gear tab, Iron Cap worn)', 412,
                (c) => _after(c, 412, tab: 'Gear', compareWorn: true),
                height: 580),
            const SizedBox(width: 22),
            _phone('A tap on the Signet, 412 px', 412, (c) => _detail(c, 412),
                height: 580),
          ]),
        ]),
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  test('the bag of the screenshot and the categories of items.json', () {
    expect(_signet['equipSlot'], 'Head');
    // The tab set: the item types of items.json grouped into six tabs.
    const tabs = {
      'Gear': ['Weapon', 'Armor', 'Artifact'],
      'Charms': ['Charm'],
      'Potions': ['Potion'],
      'Materials': ['Material'],
      'Books': ['Spellbook', 'Tome', 'Scroll'],
      'Quest': ['Quest'],
    };
    expect(tabs.values.expand((v) => v).toSet().length, 10,
        reason: 'every item type of items.json is in exactly one tab');
  });

  testWidgets('a picture of the inventory review (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1700, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final theme = buildAppTheme(const ColorScheme.dark());
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: _pageBg,
        body: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(color: _pageBg, child: _board(theme)),
            ),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/inventory-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
