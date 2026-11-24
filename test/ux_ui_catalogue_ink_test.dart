// A catalogue of the app's UI elements with variants, drawn in ink
// (UX_SHOTS=<folder>): four sheets, 360 wide, each element in three or four
// variants on the near-black ground, paper white, cold greys and deep red for
// what matters, Art's brush frames, skewed and torn edges. Each tile says where
// the variant belongs and whether it needs new art. Pictures only: nothing here
// ships; the table is docs/ux-shots/ui-catalogue/README.md.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_dice.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_images.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_panel_painter.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';

import 'support/fonts.dart';

// The clans' and rarities' tints, used only as thin brush edges and corners.
const _clan = Color(0xFF4A78C8);
const _rare = Color(0xFF4A78C8);
const _epic = Color(0xFF9A66C8);
const _heroic = Color(0xFFD08A2E);

TextStyle _cap(Color c, {bool bold = false}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: 9,
    height: 1.2,
    color: c,
    fontWeight: bold ? FontWeight.w700 : null);

Widget _tile(String name, String where, Widget child,
        {bool art = false, double width = 156}) =>
    SizedBox(
      width: width,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: inkBlack, border: Border.all(color: inkSlate)),
          child: width > 200
              ? SizedBox(width: width - 16, child: child)
              : FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
        const SizedBox(height: 3),
        Text('$name${art ? '  + new art' : ''}',
            style: _cap(inkPaper, bold: true)),
        Text(where, style: _cap(inkGrey)),
      ]),
    );

Widget _group(String title, List<Widget> tiles) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 16, color: inkRed),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 15,
                    letterSpacing: 1,
                    color: inkPaper)),
          ),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 12, runSpacing: 10, children: tiles),
      ]),
    );

Widget _sheet(String title, List<Widget> groups) => Container(
      width: 360,
      color: inkDeep,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InkTab(title),
        ]),
        const SizedBox(height: 12),
        ...groups,
      ]),
    );

Widget _label(String t, {Color c = inkPaper, double size = 13}) => Text(t,
    style: TextStyle(fontFamily: InkFonts.display, fontSize: size, color: c));

/// A torn strip: a rectangle with a ragged right end.
class _TornStrip extends StatelessWidget {
  const _TornStrip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _Torn(),
        child: Container(
            padding: const EdgeInsets.fromLTRB(12, 5, 20, 5),
            color: inkRed,
            child: _label(text, size: 13)),
      );
}

class _Torn extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width - 8, 0);
    const teeth = [6.0, 12.0, 4.0, 10.0, 2.0, 9.0];
    final h = s.height / teeth.length;
    for (var i = 0; i < teeth.length; i++) {
      p.lineTo(s.width - teeth[i], h * i + h * 0.5);
      p.lineTo(s.width - teeth[(i + 2) % teeth.length] / 2, h * (i + 1));
    }
    p
      ..lineTo(0, s.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(_Torn old) => false;
}

Widget _wax(IconData i,
        {double size = 44, Color c = const Color(0xFF8E141A)}) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [
          Color.lerp(c, inkPaper, 0.18)!,
          c,
          Color.lerp(c, inkBlack, 0.55)!
        ]),
        border: Border.all(color: inkBlack, width: 2),
      ),
      child: Icon(i, color: inkPaper.withValues(alpha: 0.9), size: size * 0.5),
    );

Widget _iron(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF55646A), inkSlate, inkDark]),
        border: Border.all(color: inkGrey, width: 1.5),
      ),
      child: Stack(children: [
        _label(t, size: 14),
        for (final a in const [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight
        ])
          Positioned.fill(
              child: Align(
                  alignment: a,
                  child: Container(width: 3, height: 3, color: inkBlack))),
      ]),
    );

Widget _skew(Widget child, {Color? fill, Color? line, EdgeInsets? pad}) =>
    Transform(
      transform: Matrix4.skewX(-inkSkew),
      child: Container(
        padding: pad ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: fill,
            border: line == null ? null : Border.all(color: line, width: 1.5)),
        child: Transform(transform: Matrix4.skewX(inkSkew), child: child),
      ),
    );

/// A black block with a thin brush edge in [c] (a clan) at its left and bottom.
Widget _brushEdge(Widget child, Color c, {double w = 130}) => Container(
      width: w,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
          color: inkDeep,
          border: Border(
              left: BorderSide(color: c, width: 4),
              bottom: BorderSide(color: c, width: 1.5),
              top: const BorderSide(color: inkSlate),
              right: const BorderSide(color: inkSlate))),
      child: child,
    );

/// A black block with a coloured brush corner (a rarity) at its top right.
Widget _corner(Widget child, Color c, {double w = 130}) => Stack(children: [
      Container(
          width: w,
          padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
          decoration: BoxDecoration(
              color: inkDeep, border: Border.all(color: inkSlate)),
          child: child),
      Positioned(
          right: 0,
          top: 0,
          child: ClipPath(
              clipper: _CornerClip(),
              child: Container(width: 20, height: 20, color: c))),
    ]);

class _CornerClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..close();
  @override
  bool shouldReclip(_CornerClip old) => false;
}

Widget _tag(String t,
        {Color bg = inkRed,
        Color fg = inkPaper,
        Color? line,
        bool skew = false}) =>
    skew
        ? _skew(
            Text(t,
                style: TextStyle(
                    fontFamily: InkFonts.system, fontSize: 10, color: fg)),
            fill: bg,
            line: line,
            pad: const EdgeInsets.symmetric(horizontal: 8, vertical: 2))
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration:
                BoxDecoration(color: bg, border: Border.all(color: line ?? bg)),
            child: Text(t,
                style: TextStyle(
                    fontFamily: InkFonts.system, fontSize: 10, color: fg)));

Widget _count(String t,
        {Color bg = inkRed, bool square = false, bool skew = false}) =>
    skew
        ? _skew(
            Text(t,
                style: const TextStyle(
                    fontFamily: InkFonts.prose,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: inkPaper)),
            fill: bg,
            pad: const EdgeInsets.symmetric(horizontal: 7, vertical: 1))
        : Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: square ? inkBlack : bg,
                shape: square ? BoxShape.rectangle : BoxShape.circle,
                border:
                    square ? Border.all(color: inkPaper, width: 1.5) : null),
            child: Text(t,
                style: const TextStyle(
                    fontFamily: InkFonts.prose,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: inkPaper)));

Widget _bar(double v,
    {Color c = inkRed,
    double h = 8,
    bool seg = false,
    bool skew = false,
    Color track = inkDark,
    double w = 130}) {
  Widget bar = SizedBox(
    width: w,
    height: h,
    child: seg
        ? Row(children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                  child: Container(
                      margin: const EdgeInsets.only(right: 1.5),
                      color: i < (v * 12).round() ? c : track)),
          ])
        : Stack(children: [
            Container(color: track),
            FractionallySizedBox(widthFactor: v, child: Container(color: c))
          ]),
  );
  return skew ? Transform(transform: Matrix4.skewX(-inkSkew), child: bar) : bar;
}

Widget _toggle(bool on, String style) {
  switch (style) {
    case 'plate':
      return Container(
          width: 52,
          height: 24,
          decoration: BoxDecoration(
              color: inkBlack,
              border: Border.all(color: on ? inkRed : inkSlate, width: 2)),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.all(2),
          child: Container(width: 20, color: on ? inkRed : inkSlate));
    case 'lever':
      return SizedBox(
          width: 40,
          height: 40,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Container(width: 22, height: 6, color: inkSlate),
            Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.rotationZ(on ? 0.6 : -0.6),
                child: Container(
                    width: 6, height: 32, color: on ? inkRed : inkGrey)),
          ]));
    case 'skew':
      return _skew(
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 14, height: 12, color: on ? inkPaper : inkSlate),
            const SizedBox(width: 3),
            Container(width: 14, height: 12, color: on ? inkSlate : inkRed),
          ]),
          fill: inkBlack,
          line: on ? inkPaper : inkRed,
          pad: const EdgeInsets.all(4));
    default:
      return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
              color: inkBlack, border: Border.all(color: inkPaper, width: 1.5)),
          child: on
              ? Container(margin: const EdgeInsets.all(4), color: inkRed)
              : null);
  }
}

Widget _inkDie() => SizedBox(
      width: 44,
      height: 44,
      child: Die3D(
        faces: [
          for (var i = 0; i < 6; i++)
            DieCubeFace(
                glyph: Icon(i == 0 ? Icons.casino : Icons.bolt,
                    size: 16, color: inkPaper),
                color: i == 0 ? inkRed : inkGrey),
        ],
        accent: inkGrey,
        size: 34,
        skin: inkDieSkinLit,
        still: true,
        element: 'None',
      ),
    );

Widget _row(
        {required Widget lead,
        required String title,
        String? sub,
        Widget? trail}) =>
    Row(children: [
      lead,
      const SizedBox(width: 8),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(title),
        if (sub != null) Text(sub, style: _cap(inkGrey)),
      ])),
      if (trail != null) trail,
    ]);

Widget _paperBox(String t, {double w = 130}) => SizedBox(
    width: w,
    child: InkPaperPanel(
        padding: const EdgeInsets.fromLTRB(36, 8, 14, 8),
        child: Text(t,
            style: const TextStyle(
                fontFamily: InkFonts.display,
                fontSize: 13,
                color: inkOnPaper))));

/// A nine-slice of Art's narrow ink frame (112 x 160): the brush border.
class _NineFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final img = InkImages.of(inkFrameAsset);
    if (img == null) return;
    canvas.drawImageNine(img, const Rect.fromLTRB(28, 28, 84, 132),
        Offset.zero & size, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(_NineFrame old) => false;
}

List<Widget> _sheets() {
  final buttons = _sheet('UI catalogue 1 · Buttons', [
    _group('Primary', [
      _tile(
          'Red skew (built)',
          'Tower, home menu: the one that goes on',
          InkButton(
              label: 'Fight', primary: true, onPressed: () {}, height: 34)),
      _tile(
          'Wax seal',
          'oaths, vows, clan gifts',
          art: true,
          _wax(Icons.verified_outlined)),
      _tile('Iron plate', 'forge, ship, smithing', art: true, _iron('Strike')),
      _tile('Paper frame (built)', 'menus: Load, Settings',
          _paperBox('Settings')),
    ]),
    _group('Secondary & quiet', [
      _tile('Black + paper line (built)', 'Tower secondary',
          InkButton(label: 'Take the door', onPressed: () {}, height: 32)),
      _tile('Paper slip', 'inline choices on paper screens',
          _skew(_label('Not now', c: inkOnPaper), fill: inkPaper)),
      _tile(
          'Text only',
          'dialogs, inline Skip',
          Text('Skip',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 13,
                  color: inkGrey,
                  decoration: TextDecoration.underline,
                  decorationColor: inkRed))),
      _tile('Grey plate', 'disabled, locked',
          _skew(_label('Locked', c: inkGrey), fill: inkDark, line: inkSlate)),
    ]),
    _group('Destructive & confirm', [
      _tile(
          'Blood ink',
          'Abandon, Delete',
          _skew(_label('Abandon'),
              fill: const Color(0xFF8E141A), line: inkRed)),
      _tile(
          'Hold to leave',
          'Tower: leave the run',
          art: true,
          Stack(children: [
            _skew(_label('Hold to leave', c: inkGrey),
                fill: inkBlack, line: inkRed),
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: Container(color: inkRed.withValues(alpha: 0.55)))
          ])),
      _tile(
          'Red outline',
          'secondary danger',
          _skew(_label('Delete save', c: inkRed),
              fill: inkBlack, line: inkRed)),
      _tile(
          'Two-step plate',
          'ironman, permadeath',
          art: true,
          _iron('Are you sure?')),
    ]),
    _group('Icon-only', [
      _tile(
          'Square ink (built)',
          'Tower: potion, log',
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
          _wax(Icons.flag_outlined, size: 38)),
      _tile(
          'Skewed square',
          'map, journal',
          _skew(const Icon(Icons.map_outlined, color: inkPaper, size: 20),
              fill: inkBlack, line: inkPaper, pad: const EdgeInsets.all(8))),
      _tile(
          'Paper seal',
          'close, back on paper',
          Container(
              width: 36,
              height: 36,
              decoration:
                  const BoxDecoration(color: inkPaper, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: inkOnPaper, size: 20))),
    ]),
    _group('Themed', [
      _tile(
          'Banner tab, torn',
          'chapter / section headers',
          art: true,
          const _TornStrip('Chapter 3')),
      _tile(
          '3D ink die',
          'fight: Roll Dice',
          Row(mainAxisSize: MainAxisSize.min, children: [
            _inkDie(),
            const SizedBox(width: 6),
            _label('Roll Dice', size: 15)
          ])),
      _tile('Clan brush edge', 'clan pages, gift offers',
          _brushEdge(_label('Swear'), _clan, w: 110)),
      _tile('Rarity brush corner', 'loot: Take, Equip',
          _corner(_label('Equip'), _epic, w: 110)),
    ]),
  ]);

  final chips = _sheet('UI catalogue 2 · Chips, badges, tooltips', [
    _group('Chips & tags', [
      _tile('Paper on red (built)', 'Tower: Armoured, affixes',
          const InkTag('Armoured', red: true)),
      _tile('Red on black', 'danger, curse, bleed',
          _tag('Bleeding', bg: inkBlack, fg: inkRed, line: inkRed)),
      _tile('Paper line (built)', 'Elite, plain marks', const InkTag('Elite')),
      _tile(
          'Rarity & clan',
          'loot, standing',
          Wrap(spacing: 4, children: [
            _tag('Rare', bg: inkBlack, line: _rare),
            _tag('Epic', bg: inkBlack, line: _epic),
            _tag('Heroic', bg: inkBlack, line: _heroic),
            _tag('Sworn', bg: inkBlack, line: _clan)
          ])),
    ]),
    _group('Badges & counters', [
      _tile(
          'Red round',
          'inventory, log, potions',
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.backpack_outlined, size: 30, color: inkPaper),
            Positioned(right: -8, top: -6, child: _count('3'))
          ])),
      _tile('Skewed red', 'new quest, unread', _count('12', skew: true)),
      _tile('Square paper (built)', 'Tower: tiles, dice',
          _count('0/3', square: true)),
      _tile(
          'Wax dot',
          'clan standing, gifts',
          art: true,
          _wax(Icons.add, size: 30)),
    ]),
    _group('Tooltips & popovers', [
      _tile(
          'Ink popover (built)',
          'Tower: hero / foe sheet',
          Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: inkBlack,
                  border: Border(
                      left: BorderSide(color: inkRed, width: 3),
                      top: BorderSide(color: inkSlate),
                      right: BorderSide(color: inkSlate),
                      bottom: BorderSide(color: inkSlate))),
              child: Text('29 / 29 · armour 0 · damage 4',
                  style: _cap(inkPaper)))),
      _tile('Paper note', 'help, hints on paper',
          _paperBox('Heals 40% of your health.')),
      _tile(
          'Torn scrap',
          'lore, codex, letters',
          art: true,
          ClipPath(
              clipper: _Torn(),
              child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 20, 8),
                  color: inkPaper,
                  child: const Text('“Not now is not never.”',
                      style: TextStyle(
                          fontFamily: InkFonts.prose,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          color: inkOnPaper))))),
    ]),
    _group('Digits that read (the pixel font draws 5 like S)', [
      _tile(
          'Before: pixel font',
          'today, everywhere',
          const Text('+1,5  5 / 25  15',
              style: TextStyle(
                  fontFamily: InkFonts.system, fontSize: 16, color: inkPaper))),
      _tile(
          'After: Spectral digits',
          'numbers in the prose face (code)',
          const Text('+1,5  5 / 25  15',
              style: TextStyle(
                  fontFamily: InkFonts.prose,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: inkPaper))),
    ]),
  ]);

  final cards = _sheet('UI catalogue 3 · Cards, rows, empty states', [
    _group('Cards & frames', [
      _tile(
          'Ink panel (built)',
          'Tower: all panels',
          SizedBox(
              width: 130,
              child: CustomPaint(
                  foregroundPainter: const InkPanelPainter(),
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      color: inkBlack,
                      child: Text('Oaths · Unsworn', style: _cap(inkPaper)))))),
      _tile('Wide paper frame (built)', 'text screens, offers',
          _paperBox('A gift, alone')),
      _tile(
          'Brush frame',
          'sheets, dialogs',
          art: true,
          SizedBox(
              width: 130,
              height: 56,
              child: CustomPaint(
                  painter: _NineFrame(),
                  child: Center(
                      child:
                          Text('Sworn to Compact', style: _cap(inkPaper)))))),
      _tile(
          'Clan brush edge',
          'clan pages, sworn gifts',
          _brushEdge(
              Text('The Lantern Dominion', style: _cap(inkPaper)), _clan)),
      _tile('Rarity brush corner', 'items, dice, skills',
          _corner(Text('Epic · Flame die', style: _cap(inkPaper)), _epic)),
    ]),
    _group('Dividers', [
      _tile(
          'Ink slash',
          'sections',
          SizedBox(
              width: 130, height: 10, child: CustomPaint(painter: _Slash()))),
      _tile(
          'Brush stroke',
          'chapter breaks',
          art: true,
          SizedBox(
              width: 130, height: 8, child: CustomPaint(painter: _Stroke()))),
      _tile(
          'Red ticks',
          'lists, stalls',
          SizedBox(
              width: 130,
              height: 8,
              child: Row(children: [
                for (var i = 0; i < 12; i++)
                  Expanded(
                      child: Container(
                          margin: const EdgeInsets.only(right: 3),
                          height: i % 4 == 0 ? 8 : 3,
                          color: i % 4 == 0 ? inkRed : inkSlate))
              ]))),
      _tile(
          'Hairline',
          'dense lists',
          const SizedBox(
              width: 130, child: Divider(color: inkSlate, height: 4))),
    ]),
    _group('List rows', [
      _tile(
          'Ink row (built)',
          'Tower: stall, marks',
          width: 340,
          _row(
              lead: const Icon(Icons.local_pharmacy_outlined, color: inkPaper),
              title: 'Salve',
              sub: 'Heals 40% of your health.',
              trail: _skew(_label('Buy', size: 12), fill: inkRed))),
      _tile(
          'Rarity row',
          'loot, shop, inventory',
          width: 340,
          _corner(
              w: 322,
              _row(
                  lead: const Icon(Icons.auto_awesome, size: 20, color: _epic),
                  title: 'Flame Die',
                  sub: 'Epic · d6',
                  trail: _label('120', c: inkPaper)),
              _epic)),
      _tile(
          'Paper row',
          'journal, saves',
          width: 340,
          SizedBox(
              width: 322,
              child: InkPaperPanel(
                  padding: const EdgeInsets.fromLTRB(40, 10, 16, 10),
                  child: Row(children: [
                    const Icon(Icons.folder_outlined, color: inkOnPaper),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Slot 1 · Edda · Level 7',
                            style: TextStyle(
                                fontFamily: InkFonts.display,
                                fontSize: 13,
                                color: inkOnPaper)))
                  ])))),
    ]),
    _group('Empty states', [
      _tile(
          'Ink-wash vignette',
          'journal, codex, bag',
          art: true,
          SizedBox(
              width: 130,
              height: 70,
              child: Stack(fit: StackFit.expand, children: [
                Opacity(
                    opacity: 0.5,
                    child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (r) => const RadialGradient(
                                radius: 0.8,
                                colors: [inkPaper, Color(0x00EFEDE8)])
                            .createShader(r),
                        child: Image.asset(
                            'assets/visuals/tower_ink/fight_band1_dice.png',
                            fit: BoxFit.cover))),
                Center(
                    child: Text('Nothing written yet',
                        style: TextStyle(
                            fontFamily: InkFonts.prose,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                            color: inkPaper)))
              ]))),
      _tile(
          'Red slash + line',
          'Tower: Unsworn, no dice',
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 3, height: 20, color: inkRed),
            const SizedBox(width: 6),
            Text('Unsworn',
                style: TextStyle(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    color: inkGrey))
          ])),
      _tile(
          'Quiet line',
          'lists: no saves',
          Text('No saved game yet',
              style: TextStyle(
                  fontFamily: InkFonts.prose,
                  fontStyle: FontStyle.italic,
                  color: inkGrey))),
    ]),
  ]);

  final controls = _sheet('UI catalogue 4 · Bars, toggles, tabs, headers', [
    _group('Progress & health bars', [
      _tile('Thin ink (built)', 'Tower: plates, health, XP', _bar(0.65)),
      _tile('Blood bar', 'low health, danger',
          _bar(0.22, h: 12, c: const Color(0xFFE02A32), track: inkDark)),
      _tile('Segmented', 'quests, tide, mana',
          _bar(0.6, seg: true, c: inkPaper, h: 10)),
      _tile('Skewed bar', 'boss, banner headers', _bar(0.7, skew: true, h: 10)),
    ]),
    _group('Toggles & switches', [
      _tile('Ink plate', 'settings', _toggle(true, 'plate')),
      _tile('Lever', 'ironman, permadeath', art: true, _toggle(true, 'lever')),
      _tile('Skewed switch', 'on / off pairs', _toggle(false, 'skew')),
      _tile(
          'Square check',
          'lists, options',
          Row(mainAxisSize: MainAxisSize.min, children: [
            _toggle(true, 'check'),
            const SizedBox(width: 8),
            _toggle(false, 'check')
          ])),
    ]),
    _group('Tabs', [
      _tile(
          'Skewed ink',
          'Tower: marks, calling',
          Row(mainAxisSize: MainAxisSize.min, children: [
            _skew(_label('Marks', size: 11),
                fill: inkRed,
                pad: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
            const SizedBox(width: 6),
            _skew(_label('Calling', size: 11),
                fill: inkBlack,
                line: inkPaper,
                pad: const EdgeInsets.symmetric(horizontal: 10, vertical: 4))
          ])),
      _tile(
          'Banner tabs',
          'chapters, clans',
          const Row(mainAxisSize: MainAxisSize.min, children: [
            InkTab('Items'),
            SizedBox(width: 4),
            InkTab('Gear', color: inkSlate)
          ])),
      _tile(
          'Underline slash',
          'inventory, map',
          Row(mainAxisSize: MainAxisSize.min, children: [
            Column(children: [
              _label('Items', size: 12),
              SizedBox(
                  width: 40, height: 6, child: CustomPaint(painter: _Slash()))
            ]),
            const SizedBox(width: 14),
            _label('Gear', size: 12, c: inkGrey)
          ])),
      _tile(
          'Paper folder tabs',
          'journal, codex',
          art: true,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: inkPaper,
                child: Text('Quests', style: _cap(inkOnPaper))),
            const SizedBox(width: 3),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: inkGrey,
                child: Text('Lore', style: _cap(inkOnPaper)))
          ])),
    ]),
    _group('Dialog headers', [
      _tile(
          'Ink title + red tab (built)',
          'Tower: floor, end',
          width: 340,
          Container(
              padding: const EdgeInsets.all(10),
              color: inkBlack,
              child: Row(children: [
                _label('Floor 7 of 30', size: 20),
                const Spacer(),
                Container(width: 4, height: 22, color: inkRed)
              ]))),
      _tile(
          'Paper header strip',
          'story dialogs, sheets',
          width: 340,
          SizedBox(
              width: 322,
              child: InkPaperPanel(
                  title: 'A gift, offered alone',
                  padding: const EdgeInsets.fromLTRB(40, 22, 20, 10),
                  child: Text('A level reached',
                      style: TextStyle(
                          fontFamily: InkFonts.prose,
                          fontSize: 12,
                          color: inkOnPaper))))),
      _tile(
          'Torn banner header',
          'clan, oath, boss',
          art: true,
          width: 340,
          Container(
              padding: const EdgeInsets.all(10),
              color: inkBlack,
              child: Row(children: [
                const _TornStrip('The Lantern Dominion'),
                const SizedBox(width: 8),
                Container(width: 40, height: 3, color: _clan)
              ]))),
    ]),
  ]);
  return [buttons, chips, cards, controls];
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

class _Stroke extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(
          size.width * 0.3, 0, size.width * 0.6, size.height / 2)
      ..quadraticBezierTo(
          size.width * 0.85, size.height, size.width, size.height / 2)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.7,
          size.width * 0.6, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 0.3, 0, size.height / 2);
    canvas.drawPath(p, Paint()..color = inkPaper);
  }

  @override
  bool shouldRepaint(_Stroke old) => false;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('the UI catalogue sheets, in ink', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(InkImages.preload);
    Directory(shots!).createSync(recursive: true);
    var n = 0;
    for (final sheet in _sheets()) {
      n++;
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 2600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: InkFonts.prose),
          home: Scaffold(
              backgroundColor: inkDeep,
              body: SingleChildScrollView(
                  child: RepaintBoundary(key: key, child: sheet)))));
      for (var i = 0; i < 5; i++) {
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
        File('$shots/catalogue-ink-$n.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
