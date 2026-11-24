// A catalogue of the app's UI elements with variants (UX_SHOTS=<folder>):
// four sheets, 360 wide, each element in three or four variants, each tile
// saying where it belongs and whether it needs new PixelLab art. Pictures
// only: nothing here ships; the table is docs/ux-shots/ui-catalogue/README.md.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_images.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

const _cream = Color(0xFFF4EBD9);
const _creamLine = Color(0xFFCFC4AE);
const _ink = Color(0xFF1B1710);
const _gold = Color(0xFF8A5A00);

TextStyle _cap(Color c) =>
    TextStyle(fontFamily: InkFonts.system, fontSize: 9, height: 1.2, color: c);

/// One variant: a tile on the story's cream or on the Tower's ink, its name,
/// where it belongs, and a mark when it needs new art.
Widget _tile(String name, String where, Widget child,
    {bool ink = false, bool art = false, double width = 156}) {
  final fg = ink ? inkPaper : _ink;
  return SizedBox(
    width: width,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ink ? inkBlack : _cream,
          border: Border.all(color: ink ? inkSlate : _creamLine),
        ),
        child: width > 200
            ? SizedBox(width: width - 16, child: child)
            : FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
      const SizedBox(height: 3),
      Text('$name${art ? '  + new art' : ''}',
          style: _cap(_ink).copyWith(fontWeight: FontWeight.w700)),
      Text(where, style: _cap(const Color(0xFF6B6356))),
      if (ink) const SizedBox.shrink(),
      Opacity(opacity: 0, child: Text('', style: _cap(fg))),
    ]),
  );
}

Widget _group(String title, List<Widget> tiles) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontFamily: InkFonts.display,
                fontSize: 15,
                letterSpacing: 1,
                color: _ink)),
        const Divider(color: _creamLine, height: 8),
        Wrap(spacing: 12, runSpacing: 10, children: tiles),
      ]),
    );

Widget _sheet(String title, List<Widget> groups) => Container(
      width: 360,
      color: const Color(0xFFEFE6D2),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontFamily: InkFonts.display, fontSize: 22, color: _ink)),
        const SizedBox(height: 10),
        ...groups,
      ]),
    );

Widget _waxSeal(Color c, IconData i) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [
          Color.lerp(c, Colors.white, 0.25)!,
          c,
          Color.lerp(c, Colors.black, 0.4)!
        ]),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      child: Icon(i, color: Colors.white.withValues(alpha: 0.9), size: 22),
    );

Widget _ironPlate(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF3B3743),
        border: Border.all(color: const Color(0xFF8E8A94), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 2))
        ],
      ),
      child: Stack(children: [
        Text(t,
            style: const TextStyle(
                fontFamily: InkFonts.display,
                fontSize: 14,
                color: Palette.apolloCream)),
      ]),
    );

Widget _dieButton(String t) => Row(mainAxisSize: MainAxisSize.min, children: [
      Transform.rotate(
        angle: 0.3,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: _ink,
              border: Border.all(color: const Color(0xFFF2C14E), width: 2)),
          child: const Icon(Icons.casino, size: 18, color: Color(0xFFF2C14E)),
        ),
      ),
      const SizedBox(width: 8),
      Text(t,
          style: const TextStyle(
              fontFamily: InkFonts.display, fontSize: 15, color: _ink)),
    ]);

Widget _btn(String t,
        {Color bg = _gold,
        Color fg = Colors.white,
        Color? line,
        IconData? icon}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: ShapeDecoration(
          color: bg,
          shape:
              PixelChipBorder(side: BorderSide(color: line ?? bg, width: 1.5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5)
        ],
        Text(t,
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.w700)),
      ]),
    );

Widget _tag(String t, Color c, {bool fill = false, bool ink = false}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: ShapeDecoration(
          color: fill ? c : c.withValues(alpha: 0.14),
          shape: PixelChipBorder(side: BorderSide(color: c))),
      child: Text(t,
          style: TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 10,
              color: fill ? Colors.white : (ink ? inkPaper : c))),
    );

Widget _bar(double v, Color c,
        {Color track = const Color(0xFFD9CFB8),
        double h = 10,
        bool round = false,
        bool segmented = false}) =>
    SizedBox(
      width: 130,
      height: h,
      child: segmented
          ? Row(children: [
              for (var i = 0; i < 10; i++)
                Expanded(
                    child: Container(
                        margin: const EdgeInsets.only(right: 1.5),
                        color: i < (v * 10).round() ? c : track)),
            ])
          : ClipRRect(
              borderRadius: BorderRadius.circular(round ? h / 2 : 0),
              child: Stack(children: [
                Container(color: track),
                FractionallySizedBox(
                    widthFactor: v, child: Container(color: c)),
              ])),
    );

Widget _switch(bool on,
    {required Color onC,
    Color offC = const Color(0xFF8E8A94),
    String style = 'pill'}) {
  switch (style) {
    case 'plate':
      return Container(
          width: 52,
          height: 24,
          decoration: BoxDecoration(
              color: _ink,
              border: Border.all(color: on ? onC : offC, width: 2)),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.all(2),
          child: Container(width: 20, color: on ? onC : offC));
    case 'lever':
      return Transform.rotate(
          angle: on ? 0.5 : -0.5,
          child: Container(
              width: 8,
              height: 34,
              decoration: BoxDecoration(
                  color: on ? onC : offC, border: Border.all(color: _ink))));
    default:
      return Container(
          width: 46,
          height: 24,
          decoration: BoxDecoration(
              color: on ? onC : offC.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12)),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.all(3),
          child: Container(
              width: 18,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle)));
  }
}

Widget _badge(String t, Color c, {String shape = 'circle'}) => Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: shape == 'circle'
          ? BoxDecoration(color: c, shape: BoxShape.circle)
          : shape == 'square'
              ? BoxDecoration(
                  color: inkBlack, border: Border.all(color: c, width: 1.5))
              : ShapeDecoration(color: c, shape: const PixelChipBorder()),
      child: Text(t,
          style: TextStyle(
              fontFamily: InkFonts.prose,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: shape == 'square' ? inkPaper : Colors.white)),
    );

Widget _row(
    {required Widget lead,
    required String title,
    String? sub,
    Widget? trail,
    bool ink = false}) {
  final fg = ink ? inkPaper : _ink;
  return Row(children: [
    lead,
    const SizedBox(width: 8),
    Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style:
              TextStyle(fontFamily: InkFonts.display, fontSize: 13, color: fg)),
      if (sub != null)
        Text(sub, style: _cap(ink ? inkGrey : const Color(0xFF6B6356))),
    ])),
    if (trail != null) trail,
  ]);
}

List<Widget> _sheets() {
  // 1. Buttons.
  final buttons = _sheet('UI catalogue 1 · Buttons', [
    _group('Primary', [
      _tile('Gilt block', 'story: the one that goes on',
          _btn('Accept', icon: Icons.check)),
      _tile(
          'Ink skew (built)',
          'Tower, home menu',
          ink: true,
          InkButton(
              label: 'Fight', primary: true, onPressed: () {}, height: 36)),
      _tile(
          'Wax seal',
          'oaths, vows, clan gifts',
          art: true,
          _waxSeal(const Color(0xFFA5302A), Icons.verified_outlined)),
      _tile(
          'Iron plate',
          'forge, ship, smithing',
          art: true,
          _ironPlate('Strike')),
    ]),
    _group('Secondary & quiet', [
      _tile('Outlined', 'story: Not now, Back',
          _btn('Not now', bg: Colors.transparent, fg: _gold, line: _gold)),
      _tile(
          'Paper frame (built)',
          'menus, ink screens',
          ink: true,
          SizedBox(
              width: 140,
              child: InkPaperPanel(
                  padding: const EdgeInsets.fromLTRB(40, 8, 14, 8),
                  child: const Text('Settings',
                      style: TextStyle(
                          fontFamily: InkFonts.display,
                          fontSize: 15,
                          color: inkOnPaper))))),
      _tile(
          'Text only',
          'dialogs, inline "Skip"',
          Text('Skip',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 13,
                  color: _gold,
                  decoration: TextDecoration.underline))),
      _tile(
          'Black + paper line',
          'Tower secondary',
          ink: true,
          InkButton(label: 'Take the door', onPressed: () {}, height: 34)),
    ]),
    _group('Destructive & confirm', [
      _tile(
          'Blood outline',
          'story: Abandon, Delete',
          _btn('Abandon',
              bg: Colors.transparent,
              fg: Palette.bloodLight,
              line: Palette.bloodLight,
              icon: Icons.warning_amber)),
      _tile(
          'Blood block',
          'story: final confirm',
          _btn('Delete save',
              bg: Palette.bloodLight, icon: Icons.delete_outline)),
      _tile(
          'Red skew + hold',
          'Tower: leave the run',
          ink: true,
          art: true,
          InkButton(
              label: 'Hold to leave',
              primary: true,
              onPressed: () {},
              height: 34)),
      _tile(
          'Two-step plate',
          'ironman, permadeath',
          art: true,
          _ironPlate('Are you sure?')),
    ]),
    _group('Icon-only', [
      _tile(
          'Round gilt',
          'story: close, map, log',
          Container(
              width: 38,
              height: 38,
              decoration:
                  const BoxDecoration(color: _gold, shape: BoxShape.circle),
              child: const Icon(Icons.map_outlined,
                  color: Colors.white, size: 20))),
      _tile(
          'Square ink',
          'Tower: potion, log',
          ink: true,
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: inkBlack, border: Border.all(color: inkPaper)),
              child: const Icon(Icons.local_drink_outlined,
                  color: inkPaper, size: 20))),
      _tile(
          'Wax round',
          'clan, oath marks',
          art: true,
          _waxSeal(const Color(0xFF3B6A9A), Icons.flag_outlined)),
      _tile('Bare icon', 'toolbars, app bar',
          const Icon(Icons.settings_outlined, color: _ink, size: 26)),
    ]),
    _group('Themed', [
      _tile(
          'Banner tab',
          'chapter / section headers',
          ink: true,
          const InkTab('Chapter 3')),
      _tile('Die-shaped roll', 'fight: Roll Dice', _dieButton('Roll Dice')),
      _tile(
          'Clan-coloured',
          'clan pages, gift offers',
          _btn('Swear',
              bg: const Color(0xFF3060B0),
              icon: Icons.local_fire_department_outlined)),
      _tile('Rarity glow', 'loot: Take, Equip',
          _btn('Equip', bg: const Color(0xFF8E4FB0), icon: Icons.auto_awesome)),
    ]),
  ]);

  // 2. Chips, tags, badges, counters, tooltips.
  final chips = _sheet('UI catalogue 2 · Chips, badges, tooltips', [
    _group('Chips & tags', [
      _tile('Pixel chip', 'story: status, "Sworn"',
          _tag('Sworn', const Color(0xFF3060B0))),
      _tile(
          'Rarity chip',
          'loot: Rare / Epic / Heroic',
          Wrap(spacing: 4, children: [
            _tag('Rare', const Color(0xFF3060B0)),
            _tag('Epic', const Color(0xFF8E4FB0)),
            _tag('Heroic', const Color(0xFFC07818))
          ])),
      _tile(
          'Ink tag (built)',
          'Tower: Armoured, Elite',
          ink: true,
          Wrap(spacing: 4, children: const [
            InkTag('Armoured', red: true),
            InkTag('Elite')
          ])),
      _tile(
          'Weakness mark',
          'fight: ×3 / ×½',
          ink: true,
          Wrap(spacing: 4, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                    color: inkBlack,
                    border: Border.all(color: inkRed, width: 1.5)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.local_fire_department, size: 11, color: inkPaper),
                  Text(' ×3', style: TextStyle(fontSize: 10, color: inkPaper)),
                ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                    color: inkBlack, border: Border.all(color: inkSlate)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.ac_unit, size: 11, color: inkGrey),
                  Text(' ×½', style: TextStyle(fontSize: 10, color: inkGrey)),
                ]))
          ])),
    ]),
    _group('Badges & counters', [
      _tile(
          'Round count',
          'inventory, log, potions',
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.backpack_outlined, size: 30, color: _ink),
            Positioned(
                right: -8, top: -6, child: _badge('3', Palette.bloodLight))
          ])),
      _tile('Pixel counter', 'story: new quest, unread',
          _badge('12', _gold, shape: 'pixel')),
      _tile(
          'Square ink (built)',
          'Tower: dice, tiles',
          ink: true,
          _badge('0/3', inkPaper, shape: 'square')),
      _tile(
          'Wax dot',
          'clan standing, gifts',
          art: true,
          _waxSeal(const Color(0xFF3D7A2C), Icons.add)),
    ]),
    _group('Tooltips & popovers', [
      _tile(
          'Cream card',
          'story: icon help',
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _cream, border: Border.all(color: _ink, width: 1.5)),
              child: Text('Heals 40% of your health.', style: _cap(_ink)))),
      _tile(
          'Ink popover',
          'Tower: hero / foe sheet',
          ink: true,
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: inkBlack,
                  border: Border(
                      left: BorderSide(color: inkRed, width: 3),
                      top: const BorderSide(color: inkSlate),
                      right: const BorderSide(color: inkSlate),
                      bottom: const BorderSide(color: inkSlate))),
              child: Text('29 / 29 · armour 0 · damage 4',
                  style: _cap(inkPaper)))),
      _tile(
          'Scroll note',
          'lore, codex, letters',
          art: true,
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFE6D6B2),
                  border: Border.all(color: const Color(0xFF8A5A00))),
              child: Text('“Not now is not never.”',
                  style: TextStyle(
                      fontFamily: InkFonts.prose,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: _ink)))),
    ]),
    _group('Digits that read (the pixel font draws 5 like S)', [
      _tile(
          'Before: pixel font',
          'today, everywhere',
          Text('+1,5  5 / 25  15',
              style: TextStyle(
                  fontFamily: InkFonts.system, fontSize: 16, color: _ink))),
      _tile(
          'After: Spectral digits',
          'same text, numerals in the prose face',
          Text('+1,5  5 / 25  15',
              style: TextStyle(
                  fontFamily: InkFonts.prose,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _ink))),
    ]),
  ]);

  // 3. Cards, frames, dividers, list rows, empty states.
  final cards = _sheet('UI catalogue 3 · Cards, rows, empty states', [
    _group('Cards & frames', [
      _tile(
          'Cream card',
          'story: events, offers',
          Container(
              width: 130,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _cream,
                  border: Border.all(color: _creamLine),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('A gift, offered alone', style: _cap(_ink))),
          width: 156),
      _tile(
          'Clan-tinted',
          'clan pages, sworn gifts',
          Container(
              width: 130,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFD6DDE6),
                  border: Border.all(color: const Color(0xFF3060B0), width: 2)),
              child: Text('The Lantern Dominion', style: _cap(_ink)))),
      _tile(
          'Rarity frame',
          'items, dice, skills',
          Container(
              width: 130,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _cream,
                  border: Border.all(color: const Color(0xFF8E4FB0), width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x558E4FB0), blurRadius: 8)
                  ]),
              child: Text('Epic · Flame die', style: _cap(_ink)))),
      _tile(
          'Ink panel (built)',
          'Tower: all panels',
          ink: true,
          SizedBox(
              width: 130,
              child: CustomPaint(
                  foregroundPainter: const _Bar(),
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      color: inkBlack,
                      child: Text('Oaths · Unsworn', style: _cap(inkPaper)))))),
    ]),
    _group('Dividers', [
      _tile('Hairline', 'lists, sheets',
          const SizedBox(width: 130, child: Divider(color: _creamLine))),
      _tile(
          'Stitched',
          'story cards',
          SizedBox(
              width: 130, height: 8, child: CustomPaint(painter: _Dash(_ink)))),
      _tile(
          'Ink slash',
          'Tower sections',
          ink: true,
          SizedBox(
              width: 130, height: 10, child: CustomPaint(painter: _Slash()))),
      _tile(
          'Flourish',
          'chapter breaks, lore',
          art: true,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 2, color: _gold),
            const Icon(Icons.spa_outlined, size: 18, color: _gold),
            Container(width: 40, height: 2, color: _gold),
          ])),
    ]),
    _group('List rows', [
      _tile(
          'Story row',
          'inventory, journal',
          width: 340,
          _row(
              lead: const Icon(Icons.shield_outlined, color: _ink),
              title: 'Iron Shield',
              sub: 'Armour +2 · Common',
              trail: _tag('Equipped', const Color(0xFF3D7A2C)))),
      _tile(
          'Rarity row',
          'loot, shop',
          width: 340,
          _row(
              lead: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF8E4FB0), width: 2)),
                  child: const Icon(Icons.auto_awesome,
                      size: 16, color: Color(0xFF8E4FB0))),
              title: 'Flame Die',
              sub: 'Epic · d6',
              trail: const Text('120',
                  style: TextStyle(
                      fontFamily: InkFonts.prose,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _gold)))),
      _tile(
          'Ink row',
          'Tower: stall, marks',
          ink: true,
          width: 340,
          _row(
              ink: true,
              lead: const Icon(Icons.local_pharmacy_outlined, color: inkPaper),
              title: 'Salve',
              sub: 'Heals 40% of your health.',
              trail: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: inkRed,
                  child: const Text('Buy',
                      style: TextStyle(color: inkPaper, fontSize: 12))))),
    ]),
    _group('Empty states', [
      _tile(
          'Quiet line',
          'story lists: no saves',
          Text('No saved game yet',
              style: TextStyle(
                  fontFamily: InkFonts.prose,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF6B6356)))),
      _tile(
          'Illustrated',
          'journal, codex, bag',
          art: true,
          Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.menu_book_outlined, size: 30, color: _gold),
            Text('Nothing written yet',
                style: TextStyle(fontSize: 10, color: _ink))
          ])),
      _tile(
          'Ink empty',
          'Tower: Unsworn, no dice',
          ink: true,
          Text('Unsworn',
              style: TextStyle(
                  fontFamily: InkFonts.prose,
                  fontStyle: FontStyle.italic,
                  color: inkGrey))),
    ]),
  ]);

  // 4. Bars, toggles, tabs, dialog headers.
  final controls = _sheet('UI catalogue 4 · Bars, toggles, tabs, headers', [
    _group('Progress & health bars', [
      _tile('Round green', 'story: health, XP',
          _bar(0.7, Palette.healLight, round: true)),
      _tile('Segmented', 'quests, tide, mana',
          _bar(0.6, const Color(0xFF226565), segmented: true)),
      _tile(
          'Ink thin (built)',
          'Tower: plates',
          ink: true,
          _bar(0.65, inkRed, track: inkDark, h: 8)),
      _tile('Blood warning', 'low health, danger',
          _bar(0.2, Palette.bloodLight, h: 12)),
    ]),
    _group('Toggles & switches', [
      _tile('Pill', 'settings (today)', _switch(true, onC: Palette.healLight)),
      _tile(
          'Plate',
          'ink screens',
          ink: true,
          _switch(true, onC: inkRed, style: 'plate')),
      _tile(
          'Lever',
          'ironman, permadeath',
          art: true,
          _switch(true, onC: Palette.bloodLight, style: 'lever')),
      _tile('Pill off', 'every theme', _switch(false, onC: Palette.healLight)),
    ]),
    _group('Tabs', [
      _tile(
          'Underline',
          'story: inventory, map',
          Row(mainAxisSize: MainAxisSize.min, children: [
            Column(children: [
              Text('Items', style: _cap(_ink)),
              Container(width: 36, height: 2, color: _gold)
            ]),
            const SizedBox(width: 14),
            Text('Gear', style: _cap(const Color(0xFF6B6356)))
          ])),
      _tile(
          'Banner tabs',
          'chapters, clans',
          ink: true,
          Row(mainAxisSize: MainAxisSize.min, children: const [
            InkTab('Items'),
            SizedBox(width: 4),
            InkTab('Gear', color: inkSlate)
          ])),
      _tile(
          'Skewed ink',
          'Tower: marks, calling',
          ink: true,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Transform(
                transform: Matrix4.skewX(-0.2),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    color: inkRed,
                    child: const Text('Marks',
                        style: TextStyle(color: inkPaper, fontSize: 11)))),
            const SizedBox(width: 6),
            Transform(
                transform: Matrix4.skewX(-0.2),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration:
                        BoxDecoration(border: Border.all(color: inkPaper)),
                    child: const Text('Calling',
                        style: TextStyle(color: inkPaper, fontSize: 11))))
          ])),
      _tile(
          'Folder tabs',
          'journal, codex',
          art: true,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                    color: Color(0xFFE6D6B2),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(6))),
                child: Text('Quests', style: _cap(_ink))),
            const SizedBox(width: 3),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                    color: Color(0xFFCFC4AE),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(6))),
                child: Text('Lore', style: _cap(_ink)))
          ])),
    ]),
    _group('Dialog headers', [
      _tile(
          'Cream header',
          'story dialogs, sheets',
          width: 340,
          Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFDDD0B3),
              child: _row(
                  lead: const Icon(Icons.groups, color: _gold),
                  title: 'A gift, offered alone',
                  sub: 'A level reached'))),
      _tile(
          'Banner header',
          'clan, oath, boss',
          width: 340,
          art: true,
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF1B2A44),
                  border: Border(
                      bottom: BorderSide(color: Palette.goldDark, width: 3))),
              child: _row(
                  ink: true,
                  lead: const Icon(Icons.flag, color: Palette.goldDark),
                  title: 'The Lantern Dominion',
                  sub: 'Sworn'))),
      _tile(
          'Ink title',
          'Tower: floor, end',
          ink: true,
          width: 340,
          Container(
              padding: const EdgeInsets.all(10),
              color: inkBlack,
              child: Row(children: [
                const Text('Floor 7 of 30',
                    style: TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 20,
                        color: inkPaper)),
                const Spacer(),
                Container(width: 4, height: 22, color: inkRed)
              ]))),
    ]),
  ]);
  return [buttons, chips, cards, controls];
}

class _Bar extends CustomPainter {
  const _Bar();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = inkSlate);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, 3, size.height), Paint()..color = inkPaper);
  }

  @override
  bool shouldRepaint(_Bar old) => false;
}

class _Dash extends CustomPainter {
  const _Dash(this.c);
  final Color c;
  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, 4),
          Offset(x + 4, 4),
          Paint()
            ..color = c
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_Dash old) => false;
}

class _Slash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, 0),
        Paint()
          ..color = inkRed
          ..strokeWidth = 2);
    canvas.drawLine(
        Offset(0, size.height - 4),
        Offset(size.width - 6, 0),
        Paint()
          ..color = inkPaper
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_Slash old) => false;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('the UI catalogue sheets', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(InkImages.preload);
    Directory(shots!).createSync(recursive: true);
    var n = 0;
    for (final sheet in _sheets()) {
      n++;
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 2200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: InkFonts.prose),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: RepaintBoundary(key: key, child: sheet)))));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: 'sheet $n');
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/catalogue-$n.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
