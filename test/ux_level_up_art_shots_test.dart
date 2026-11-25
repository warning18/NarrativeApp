// PICTURES (UX_SHOTS=<folder>): the Level Up screen made like the rest of the
// art: Art's painted plate behind the hero (the three plates rotate by
// level % 3), the red ribbon with "Level N", the hero's south frame, Art's
// eight stat symbols, ink panels, a bar per stat and the before to after of
// the pick's numbers. A mock in the Ink palette with the real PixelLab files
// (docs/ux-shots/level-up-art/src), not the app's screen: the numbers are a
// warrior's in the Tower at level 4.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';

import 'support/fonts.dart';

const _src = 'docs/ux-shots/level-up-art/src';
const _lining = [FontFeature.liningFigures()];

TextStyle _t(double size,
        {Color color = inkPaper,
        String family = 'Spectral',
        FontWeight? weight}) =>
    TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 1.15,
        color: color,
        fontWeight: weight,
        fontFeatures: _lining);

typedef _Stat = ({String id, String abbr, String name, int value});
const _stats = <_Stat>[
  (id: 'str', abbr: 'STR', name: 'Strength', value: 1),
  (id: 'dex', abbr: 'DEX', name: 'Dexterity', value: 10),
  (id: 'con', abbr: 'CON', name: 'Constitution', value: -2),
  (id: 'int', abbr: 'INT', name: 'Intelligence', value: 3),
  (id: 'wis', abbr: 'WIS', name: 'Wisdom', value: -1),
  (id: 'per', abbr: 'PER', name: 'Perception', value: 1),
  (id: 'luck', abbr: 'LUCK', name: 'Luck', value: 2),
  (id: 'cha', abbr: 'CHA', name: 'Charisma', value: 0),
];

/// The three offers: the stat, and the rows of statPickPreview (label, before,
/// after); no rows: "No effect in the Tower".
typedef _Offer = ({int stat, List<(String, String, String)> rows});
const _offers = <_Offer>[
  (stat: 3, rows: []),
  (stat: 1, rows: [('Damage', '8', '9'), ('Dodge', '25%', '27%')]),
  (stat: 7, rows: []),
];

final _imgs = <String, ui.Image>{};

Widget _px(String file, {double? w, double? h, BoxFit fit = BoxFit.fill}) =>
    SizedBox(
        width: w,
        height: h,
        child: RawImage(
            image: _imgs[file],
            fit: fit,
            filterQuality: FilterQuality.none,
            isAntiAlias: false));

/// The top: the plate, the ribbon, the hero standing, as Art laid them out
/// (plate 180 x 320 scaled to the width; the hero 48 px at 2x, feet at y 190,
/// centred at x 90).
Widget _stage(String plate, int level, double w) {
  final k = w / 180;
  return SizedBox(
    width: w,
    height: 214 * k,
    child: ClipRect(
      child: Stack(children: [
        Positioned(
            left: 0, top: 0, width: w, height: 320 * k, child: _px(plate)),
        Positioned(
          left: 6 * k,
          top: 12 * k,
          width: 168 * k,
          height: 27 * k,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: _px('levelup_header_ribbon.png')),
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: 'Level ', style: _t(15 * k, family: 'IMFellEnglishSC')),
              TextSpan(
                  text: '$level', style: _t(15 * k, weight: FontWeight.w700)),
            ])),
          ]),
        ),
        Positioned(
            left: (90 - 48) * k,
            top: (192 - 96) * k,
            width: 96 * k,
            height: 96 * k,
            child: _px('warrior_south.png')),
      ]),
    ),
  );
}

Widget _symbol(String id, {double size = 24, double scale = 1}) =>
    _px('${id}_24.png', w: size * scale, h: size * scale);

/// An offer card: the symbol, the gain, the before to after rows or the plain
/// "No effect in the Tower". Not greyed when it is not the one picked.
Widget _card(int i, int selected, double width) {
  final o = _offers[i];
  final s = _stats[o.stat];
  final sel = i == selected;
  return Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
    decoration: BoxDecoration(
      color: inkPaper,
      border: Border.all(color: sel ? inkRed : inkDeep, width: sel ? 3 : 2),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      _symbol(s.id, scale: 1.5),
      const SizedBox(height: 4),
      Text('+1 ${s.abbr}',
          style: _t(18, color: inkDeep, family: 'PixelifySans')),
      Text(s.name, style: _t(11, color: inkSlate)),
      const SizedBox(height: 6),
      Container(height: 1, color: inkSlate.withValues(alpha: 0.4)),
      const SizedBox(height: 6),
      if (o.rows.isEmpty)
        Text('No effect in the Tower',
            textAlign: TextAlign.center, style: _t(11.5, color: inkSlate))
      else
        for (final r in o.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Column(children: [
              Text(r.$1, style: _t(10.5, color: inkSlate)),
              Text.rich(TextSpan(children: [
                TextSpan(text: r.$2, style: _t(15, color: inkDeep)),
                TextSpan(text: ' → ', style: _t(13, color: inkSlate)),
                TextSpan(
                    text: r.$3,
                    style: _t(15, color: inkRedDeep, weight: FontWeight.w700)),
              ])),
            ]),
          ),
      if (sel)
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: const Icon(Icons.check_circle, size: 16, color: inkRed)),
    ]),
  );
}

/// A bar per stat on the paper: symbol, name, the value, the pick in red.
Widget _bars(int selected) {
  const lo = -3, hi = 12;
  return Column(children: [
    for (var i = 0; i < _stats.length; i++)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          _symbol(_stats[i].id),
          const SizedBox(width: 8),
          SizedBox(
              width: 38,
              child: Text(_stats[i].abbr,
                  style: _t(13, color: inkDeep, family: 'PixelifySans'))),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              double x(num v) => (v - lo) / (hi - lo) * c.maxWidth;
              final v = _stats[i].value;
              final pick = _offers.any((o) => o.stat == i) && i == selected;
              return SizedBox(
                height: 14,
                child: Stack(children: [
                  Positioned.fill(
                      child:
                          Container(color: inkSlate.withValues(alpha: 0.18))),
                  Positioned(
                      left: x(0),
                      top: 0,
                      bottom: 0,
                      width: 1.5,
                      child: Container(color: inkDeep)),
                  Positioned(
                    left: x(v < 0 ? v : 0),
                    width: (x(v) - x(0)).abs().clamp(1.5, 400.0),
                    top: 2,
                    bottom: 2,
                    child: Container(color: inkDeep),
                  ),
                  if (pick)
                    Positioned(
                        left: x(v),
                        width: x(v + 1) - x(v),
                        top: 2,
                        bottom: 2,
                        child: Container(color: inkRed)),
                ]),
              );
            }),
          ),
          SizedBox(
            width: 52,
            child: Text(
                i == selected
                    ? '${_stats[i].value} → ${_stats[i].value + 1}'
                    : '${_stats[i].value}',
                textAlign: TextAlign.right,
                style: _t(14,
                    color: i == selected ? inkRedDeep : inkDeep,
                    weight: i == selected ? FontWeight.w700 : null)),
          ),
        ]),
      ),
  ]);
}

Widget _screen(String plate, int level, double w) {
  const selected = 1;
  final cardW = (w - 16 - 20 - 6 - 12) / 3;
  return Container(
    width: w,
    color: inkBlack,
    child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stage(plate, level, w),
          Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: inkPaper, border: Border.all(color: inkDeep, width: 3)),
            child: Column(children: [
              Row(children: [
                Text('Choose one',
                    style: _t(16, color: inkDeep, family: 'IMFellEnglishSC')),
                const Spacer(),
                Text('2 picks left', style: _t(12, color: inkSlate)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < 3; i++) _card(i, selected, cardW),
              ]),
              const SizedBox(height: 12),
              Container(height: 1.5, color: inkDeep),
              const SizedBox(height: 8),
              _bars(selected),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(8, 10, 8, 14),
            height: 52,
            alignment: Alignment.center,
            color: inkRed,
            child:
                Text('Take this pick', style: _t(17, family: 'PixelifySans')),
          ),
        ]),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  for (final (plate, level) in [
    ('levelup_plate_shrine.png', 3),
    ('levelup_plate_anvil.png', 4),
    ('levelup_plate_yard.png', 5),
  ]) {
    for (final w in [412.0, 360.0]) {
      testWidgets('level up $plate $w', skip: shots == null, (t) async {
        await t.runAsync(loadAppFonts);
        await t.runAsync(() async {
          for (final f in Directory(_src).listSync().whereType<File>()) {
            final codec = await ui.instantiateImageCodec(f.readAsBytesSync());
            _imgs[f.path.split('/').last] = (await codec.getNextFrame()).image;
          }
        });
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(w, 1500);
        addTearDown(t.view.reset);
        final key = GlobalKey();
        await t.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Material(
              color: inkBlack,
              child: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                      key: key, child: _screen(plate, level, w)))),
        ));
        await t.pump();
        await t.pump();
        await t.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory(shots!).createSync(recursive: true);
          File('$shots/level-up-${plate.split('_').last.split('.').first}-${w.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        expect(t.takeException(), isNull);
      });
    }
  }
}
