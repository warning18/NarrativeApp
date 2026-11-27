// PICTURES (UX_SHOTS=<folder>): the gear card's ONE step: the replace question.
// (old header:) the Tower's gear cards and the Equip step. The
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

/// A "Replace" step: worn piece beside the new one, the change, three buttons.
Widget _replace(
    {required String title,
    required String line,
    required _Item? worn,
    required _Item now,
    required String yes,
    required String no}) {
  final chips = <Widget>[];
  void chip(String label, int to, int from) {
    if (to == 0 && from == 0) return;
    chips.add(_deltaChip(label, to - from));
  }

  chip('Damage', now.damage, worn?.damage ?? 0);
  chip('Armour', now.armour, worn?.armour ?? 0);
  return _frame(
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(line, style: _p(12.5, inkGrey)),
        const SizedBox(height: 14),
        IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _tile('Worn', worn)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: inkPaper, size: 24)),
          Expanded(child: _tile('New', now)),
        ])),
        const SizedBox(height: 14),
        Center(child: Wrap(spacing: 8, children: chips)),
        const Spacer(),
        _buttons(yes, no),
        TextButton(
            onPressed: () {},
            child: Text('Change', style: _p(13, inkGrey, w: FontWeight.w700))),
      ]),
      title: title);
}

class _Frames {
  static final blade = _item('bloodthorn_blade')!;
  static final sword = _item('sword_001')!;
  static final boots = _item('boots_iron_shod')!;

  static Widget replace() => _replace(
      title: 'Replace your Iron Sword?',
      line: 'The Bloodthorn Blade takes the place of your Iron Sword.',
      worn: sword,
      now: blade,
      yes: 'Replace',
      no: 'Keep mine');

  static Widget empty() => _replace(
      title: 'Equip the Iron-Shod Boots?',
      line: 'Nothing is worn on your feet.',
      worn: null,
      now: boots,
      yes: 'Equip',
      no: 'Leave them');
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    testWidgets('replace step at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width * 2 + 8, 700);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      Widget frame(Widget f) => SizedBox(width: width, height: 700, child: f);
      await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
              home: Scaffold(
                  body: Row(children: [
                frame(_Frames.replace()),
                const SizedBox(width: 8),
                frame(_Frames.empty()),
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
        File('$shots/replace-${width.toInt()}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
