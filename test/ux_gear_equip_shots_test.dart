// PICTURES (UX_SHOTS=<folder>): the Tower's gear cards and the Equip step. The
// card shows the gear's own picture and a comparison with the piece worn in its
// slot (green better, red worse, "empty slot"); after Confirm an "Equip?" step
// puts the new piece beside the worn one (two layouts). Mocks over real
// components and the game's items; not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_styled_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/item_icons.dart';

import 'support/fonts.dart';

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

typedef _Item = ({
  String id,
  String name,
  String slot,
  int damage,
  int armour,
  String rarity
});

final _items = towerDataFromAssets().items;
_Item? _item(String? id) {
  if (id == null) return null;
  final m = _items[id] as Map;
  return (
    id: id,
    name: '${m['itemName']}',
    slot: '${m['equipSlot']}',
    damage: (m['attackDamage'] as num).toInt(),
    armour: (m['armor'] as num).toInt(),
    rarity: '${m['rarity']}',
  );
}

String _sign(int d) => d == 0 ? '' : (d > 0 ? '+$d' : '−${-d}');

/// The comparison of [now] with [worn] (null: the slot is empty).
List<TowerCompareLine> _compare(_Item now, _Item? worn) {
  final rows = <TowerCompareLine>[];
  void row(String label, int to, int from) {
    if (to == 0 && from == 0) return;
    rows.add(TowerCompareLine(
        label: label,
        from: worn == null ? '–' : '$from',
        to: '$to',
        delta: _sign(to - from),
        better: to == from ? null : to > from));
  }

  row('DMG', now.damage, worn?.damage ?? 0);
  row('ARM', now.armour, worn?.armour ?? 0);
  return rows;
}

Widget _icon(String id, double size) => Image.asset(ItemIcons.pathFor(id),
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none);

/// A gear card: the piece's own picture, its name, its slot, the comparison.
Widget _gearCard(_Item now, _Item? worn) => SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.gear,
        kind: 'Gear · ${now.slot}',
        name: now.name,
        text: '',
        vignette: 'assets/none.png',
        art: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: inkBlack.withValues(alpha: 0.5),
                border: Border.all(color: inkGrey),
                borderRadius: BorderRadius.circular(6)),
            child: _icon(now.id, 48)),
        compare: _compare(now, worn),
        note: worn == null ? 'Empty slot' : null,
        badge: const Icon(Icons.shield, size: 16, color: inkOnPaper),
      ),
    );

Widget _fit(Widget c, double w) =>
    SizedBox(width: w, height: w * 201 / 122, child: FittedBox(child: c));

/// A piece as a small tile (the Equip step): picture, name, its stats.
Widget _tile(String caption, _Item? it, {bool lost = false}) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(color: inkPaper, width: 1.5),
          borderRadius: BorderRadius.circular(8)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(caption.toUpperCase(),
            style: _p(9.5, inkGrey, w: FontWeight.w800)),
        const SizedBox(height: 6),
        if (it == null)
          Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: inkSlate),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('—', style: _d(20, inkGrey)))
        else
          Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: inkGrey),
                  borderRadius: BorderRadius.circular(6)),
              child: _icon(it.id, 48)),
        const SizedBox(height: 6),
        Text(it?.name ?? 'Empty slot',
            textAlign: TextAlign.center, style: _d(13, inkPaper)),
        if (it != null) ...[
          Text(it.slot, style: _p(10, inkGrey)),
          const SizedBox(height: 4),
          if (it.damage > 0)
            Text('Damage ${it.damage}', style: _p(12, inkPaper)),
          if (it.armour > 0)
            Text('Armour ${it.armour}', style: _p(12, inkPaper)),
          if (lost)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('lost if you equip',
                  style: _p(10, inkLess, w: FontWeight.w700)),
            ),
        ],
      ]),
    );

Widget _buttons(String yes, String no) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: inkRed,
              foregroundColor: inkPaper,
              minimumSize: const Size.fromHeight(48)),
          onPressed: () {},
          child: Text(yes)),
      TextButton(
          onPressed: () {},
          child: Text(no, style: _p(14, inkGold, w: FontWeight.w700))),
    ]);

Widget _deltaChip(String label, int d) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          border: Border.all(color: d >= 0 ? inkMore : inkLess, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      child: Text('$label ${_sign(d)}',
          style: _p(11.5, d >= 0 ? inkMore : inkLess, w: FontWeight.w800)),
    );

Widget _frame(Widget body, {required String title}) => TowerBackdrop(
      floor: 3,
      child: Container(
        color: inkBlack.withValues(alpha: 0.55),
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _d(22, inkPaper)),
          const SizedBox(height: 10),
          Expanded(child: body),
        ]),
      ),
    );

class _Frames {
  static final blade = _item('bloodthorn_blade')!;
  static final sword = _item('sword_001')!;
  static final mantle = _item('archon_mantle')!;
  static final jerkin = _item('armor_leather')!;
  static final boots = _item('boots_iron_shod')!;

  /// 1: the table, three gear cards with their comparison.
  static Widget table(double w) {
    final cw = (w - 32 - 16) / 3;
    return _frame(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose one reward', style: _p(13, inkGrey)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _fit(_gearCard(blade, sword), cw),
            _fit(_gearCard(jerkin, mantle), cw),
            _fit(_gearCard(boots, null), cw),
          ]),
          const SizedBox(height: 14),
          Text(
              'Green is better than what you wear, red is worse. Take one, then choose whether to equip it.',
              style: _p(12, inkGrey)),
          const Spacer(),
          _buttons('Take', 'Not now (+1 mark)'),
        ]),
        title: 'Floor 3 cleared');
  }

  /// 1b: the card held, large, as on the confirm sheet.
  static Widget confirm() => _frame(
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: _fit(_gearCard(blade, sword), 216)),
        const SizedBox(height: 14),
        Center(child: _deltaChip('Damage', 1)),
        const SizedBox(height: 8),
        Text('Worn now: Iron Sword. You choose next whether to equip it.',
            textAlign: TextAlign.center, style: _p(12, inkGrey)),
        const Spacer(),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: () {}, child: const Text('Change'))),
          const SizedBox(width: 10),
          Expanded(
              child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: inkRed, foregroundColor: inkPaper),
                  onPressed: () {},
                  child: const Text('Confirm'))),
        ]),
      ]),
      title: 'Take this piece?');

  /// 2: Equip? version 1, the two pieces side by side with an arrow.
  static Widget equipSideBySide() => _frame(
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            'Your Iron Sword is lost if you equip it: the Tower has no inventory.',
            style: _p(12.5, inkGrey)),
        const SizedBox(height: 14),
        IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _tile('Worn', sword, lost: true)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: inkPaper, size: 24)),
          Expanded(child: _tile('New', blade)),
        ])),
        const SizedBox(height: 14),
        Center(child: _deltaChip('Damage', 1)),
        const Spacer(),
        _buttons('Equip the Bloodthorn Blade', 'Keep mine'),
      ]),
      title: 'Equip?');

  /// 3: Equip? version 2, one comparison table, the better value in colour.
  static Widget equipTable() {
    Widget cell(String t,
            {Color c = inkPaper,
            bool bold = false,
            TextAlign a = TextAlign.center}) =>
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(t,
                textAlign: a,
                style: _p(13, c, w: bold ? FontWeight.w800 : null)));
    return _frame(
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: inkBlack,
                border: Border.all(color: inkPaper, width: 1.5),
                borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Row(children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(
                    child: Column(children: [
                  _icon(sword.id, 40),
                  Text('Worn', style: _p(10, inkGrey, w: FontWeight.w800)),
                  Text(sword.name,
                      textAlign: TextAlign.center, style: _d(11.5, inkPaper)),
                ])),
                Expanded(
                    child: Column(children: [
                  _icon(blade.id, 40),
                  Text('New', style: _p(10, inkGrey, w: FontWeight.w800)),
                  Text(blade.name,
                      textAlign: TextAlign.center, style: _d(11.5, inkPaper)),
                ])),
              ]),
              const Divider(color: inkSlate),
              Row(children: [
                Expanded(flex: 2, child: cell('Damage', a: TextAlign.left)),
                Expanded(child: cell('${sword.damage}')),
                Expanded(
                    child: cell('${blade.damage}  ${_sign(1)}',
                        c: inkMore, bold: true)),
              ]),
              Row(children: [
                Expanded(flex: 2, child: cell('Armour', a: TextAlign.left)),
                Expanded(child: cell('–', c: inkGrey)),
                Expanded(child: cell('–', c: inkGrey)),
              ]),
              Row(children: [
                Expanded(flex: 2, child: cell('Rarity', a: TextAlign.left)),
                Expanded(child: cell(sword.rarity)),
                Expanded(child: cell(blade.rarity)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Equipping replaces the Iron Sword for good.',
              textAlign: TextAlign.center, style: _p(12, inkGrey)),
          const Spacer(),
          _buttons('Equip', 'Keep mine'),
        ]),
        title: 'Equip?');
  }

  /// 4: an empty slot: nothing is lost.
  static Widget equipEmpty() => _frame(
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Nothing is worn on your feet: nothing is lost.',
            style: _p(12.5, inkGrey)),
        const SizedBox(height: 14),
        IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _tile('Worn', null)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: inkPaper, size: 24)),
          Expanded(child: _tile('New', boots)),
        ])),
        const SizedBox(height: 14),
        Center(child: _deltaChip('Armour', 1)),
        const Spacer(),
        _buttons('Equip the Iron-Shod Boots', 'Leave them'),
      ]),
      title: 'Equip?');
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    testWidgets('gear at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width * 5 + 32, 780);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      Widget frame(Widget f) => SizedBox(width: width, height: 780, child: f);
      await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
              home: Scaffold(
                  body: Row(children: [
                frame(_Frames.table(width)),
                const SizedBox(width: 8),
                frame(_Frames.confirm()),
                const SizedBox(width: 8),
                frame(_Frames.equipSideBySide()),
                const SizedBox(width: 8),
                frame(_Frames.equipTable()),
                const SizedBox(width: 8),
                frame(_Frames.equipEmpty()),
              ]))),
        ),
      ));
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/gear-${width.toInt()}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
