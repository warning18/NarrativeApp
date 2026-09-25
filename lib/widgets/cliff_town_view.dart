import 'package:flutter/material.dart';

import '../data/cliff_town.dart';

/// The camp's town, drawn: the harbour and The Rusty Eel at the bottom,
/// the pieces of [town] stacked up between two cliffs, the sky above, and
/// a dashed outline where [preview] would go. It scrolls up from the
/// harbour; [scrollController] lets the camp bring the outline into view.
class CliffTownView extends StatelessWidget {
  const CliffTownView({
    super.key,
    required this.town,
    this.preview,
    this.previewLabel = '',
    this.highlightIndex,
    this.harborAction,
    this.scrollController,
  });

  final CliffTown town;

  /// The footprint of the piece the player is looking at, outlined where
  /// it would go.
  final TownFootprint? preview;
  final String previewLabel;

  /// The piece to mark as just built.
  final int? highlightIndex;

  /// A button over the harbour (the boat's).
  final Widget? harborAction;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final spot = preview == null ? null : town.spotFor(preview!);
    final reach = [
      town.height,
      if (spot != null) spot.$1 + preview!.height,
    ].reduce((a, b) => a > b ? a : b);
    final townUnits = townHarborHeight + (reach + 2) * townRowHeight + 140;

    return LayoutBuilder(builder: (context, constraints) {
      final scale = constraints.maxWidth / townWidth;
      // At least as tall as the box it is in: a small town has sky above.
      final unitsHigh = constraints.maxHeight.isFinite
          ? [townUnits, constraints.maxHeight / scale]
              .reduce((a, b) => a > b ? a : b)
          : townUnits;
      final height = unitsHigh * scale;
      Rect? previewRect;
      if (spot != null) {
        previewRect = Rect.fromLTWH(
          (townCliffWidth + spot.$2 * townCellWidth) * scale,
          height -
              (townHarborHeight + (spot.$1 + preview!.height) * townRowHeight) *
                  scale,
          preview!.width * townCellWidth * scale,
          preview!.height * townRowHeight * scale,
        );
      }
      return SingleChildScrollView(
        controller: scrollController,
        reverse: true,
        child: SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CliffTownPainter(
                    town: town,
                    unitsHigh: unitsHigh,
                    preview: spot == null
                        ? null
                        : TownPiece('', spot.$1, spot.$2, preview!),
                    highlightIndex: highlightIndex,
                  ),
                ),
              ),
              if (previewRect != null)
                Positioned.fromRect(
                  rect: previewRect,
                  child: IgnorePointer(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(
                            previewLabel.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'PixelifySans',
                              fontSize: 10,
                              height: 1.1,
                              color: Color(0xFFF2C14E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (harborAction != null)
                Positioned(left: 8, bottom: 8, child: harborAction!),
            ],
          ),
        ),
      );
    });
  }
}

// The town's night palette: the Stitched Ink colours, whatever the app's.
const _sky = Color(0xFF211D29);
const _cloud = Color(0xFF2A2433);
const _rock1 = Color(0xFF2B2730);
const _rock2 = Color(0xFF332E39);
const _water = Color(0xFF1F3A44);
const _wave = Color(0xFF2F5A66);
const _quay = Color(0xFF3B3743);
const _quayTop = Color(0xFF57525E);
const _mortar = Color(0xFF332F3A);
const _stone = Color(0xFF57525E);
const _wall = Color(0xFF4A4552);
const _wallDark = Color(0xFF3B3743);
const _timber = Color(0xFF221F27);
const _roof = Color(0xFF2E3340);
const _roofLight = Color(0xFF5A5463);
const _dark = Color(0xFF1A181E);
const _lit = Color(0xFFF2C14E);
const _ember = Color(0xFFE0762B);
const _tide = Color(0xFF4FB0B0);
const _void = Color(0xFFA987EA);
const _voidDeep = Color(0xFF2A2233);
const _wood = Color(0xFF4A3B2E);
const _woodDark = Color(0xFF3A2E24);
const _plank = Color(0xFF5A4530);
const _crate = Color(0xFF6B5438);
const _ash = Color(0xFFA8A194);
const _bone = Color(0xFFECE7DC);

class _CliffTownPainter extends CustomPainter {
  _CliffTownPainter({
    required this.town,
    required this.unitsHigh,
    this.preview,
    this.highlightIndex,
  });

  final CliffTown town;
  final double unitsHigh;
  final TownPiece? preview;
  final int? highlightIndex;

  late Canvas _canvas;
  double _ox = 0, _oy = 0;

  void _rect(double x, double y, double w, double h, Color color) => _canvas
      .drawRect(Rect.fromLTWH(_ox + x, _oy + y, w, h), Paint()..color = color);

  void _poly(List<double> xy, Color color) {
    final path = Path()..moveTo(_ox + xy[0], _oy + xy[1]);
    for (var i = 2; i < xy.length; i += 2) {
      path.lineTo(_ox + xy[i], _oy + xy[i + 1]);
    }
    _canvas.drawPath(path..close(), Paint()..color = color);
  }

  void _line(double x1, double y1, double x2, double y2, Color color,
          double width) =>
      _canvas.drawLine(
          Offset(_ox + x1, _oy + y1),
          Offset(_ox + x2, _oy + y2),
          Paint()
            ..color = color
            ..strokeWidth = width);

  void _outline(double x, double y, double w, double h, Color color) =>
      _canvas.drawRect(
          Rect.fromLTWH(_ox + x, _oy + y, w, h),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);

  @override
  void paint(Canvas canvas, Size size) {
    _canvas = canvas;
    final scale = size.width / townWidth;
    canvas.save();
    canvas.scale(scale);
    final h = unitsHigh;

    _ox = 0;
    _oy = 0;
    _rect(0, 0, townWidth, h, _sky);
    _rect(60, 30, 80, 5, _cloud);
    _rect(80, 25, 40, 5, _cloud);
    _rect(200, 70, 110, 5, _cloud);
    _rect(226, 65, 50, 5, _cloud);
    for (final (x, y, c) in [(120.0, 40.0, _bone), (170.0, 64.0, _ash)]) {
      _rect(x + 14, y + 8, 6, 2, c);
      _rect(x + 20, y + 6, 4, 2, c);
      _rect(x + 10, y + 6, 4, 2, c);
    }

    _cliffs(h);
    _harbor(h);

    for (final strut in town.struts) {
      _ox = townCliffWidth + strut.column * townCellWidth;
      _oy = h - townHarborHeight - strut.row * townRowHeight;
      _rect(0, 0, 62, 3, _timber);
      _line(8, 3, 20, 12, _timber, 3);
      _line(54, 3, 42, 12, _timber, 3);
    }

    for (var i = 0; i < town.pieces.length; i++) {
      final piece = town.pieces[i];
      _ox = townCliffWidth + piece.column * townCellWidth;
      _oy = h - townHarborHeight - piece.top * townRowHeight;
      _piece(piece.id);
      if (i == highlightIndex) {
        _outline(0, 0, piece.footprint.width * townCellWidth,
            piece.footprint.height * townRowHeight, _lit);
      }
    }

    final ghost = preview;
    if (ghost != null) {
      _ox = townCliffWidth + ghost.column * townCellWidth;
      _oy = h - townHarborHeight - ghost.top * townRowHeight;
      final w = ghost.footprint.width * townCellWidth;
      final gh = ghost.footprint.height * townRowHeight;
      _rect(0, 0, w, gh, _lit.withValues(alpha: 0.07));
      final dash = Paint()
        ..color = _lit
        ..strokeWidth = 1;
      for (var x = 0.0; x < w; x += 8) {
        canvas.drawLine(Offset(_ox + x, _oy), Offset(_ox + x + 4, _oy), dash);
        canvas.drawLine(
            Offset(_ox + x, _oy + gh), Offset(_ox + x + 4, _oy + gh), dash);
      }
      for (var y = 0.0; y < gh; y += 8) {
        canvas.drawLine(Offset(_ox, _oy + y), Offset(_ox, _oy + y + 4), dash);
        canvas.drawLine(
            Offset(_ox + w, _oy + y), Offset(_ox + w, _oy + y + 4), dash);
      }
    }
    canvas.restore();
  }

  void _cliffs(double h) {
    _ox = 0;
    _oy = 0;
    const jag = [
      0.0, 0.04, 0.09, 0.14, 0.20, 0.27, 0.33, 0.40, 0.47, 0.54, //
      0.61, 0.68, 0.75, 0.82, 0.90, 0.96, 1.0,
    ];
    const inL = [
      28.0,
      40,
      30,
      38,
      28,
      40,
      32,
      38,
      29,
      40,
      31,
      37,
      28,
      40,
      32,
      38,
      30
    ];
    for (final right in [false, true]) {
      final path = Path();
      final edge = right ? townWidth : 0.0;
      path.moveTo(edge, 0);
      for (var i = 0; i < jag.length; i++) {
        final x = inL[(i + (right ? 3 : 0)) % inL.length].toDouble();
        path.lineTo(right ? townWidth - x : x, jag[i] * h);
      }
      path.lineTo(edge, h);
      path.close();
      _canvas.save();
      _canvas.clipPath(path);
      _canvas.drawRect(Rect.fromLTWH(right ? townWidth - 40 : 0, 0, 40, h),
          Paint()..color = _rock1);
      for (var y = 0.0; y < h; y += 26) {
        _canvas.drawRect(Rect.fromLTWH(right ? townWidth - 40 : 0, y, 40, 8),
            Paint()..color = _rock2);
      }
      _canvas.restore();
    }
  }

  void _harbor(double h) {
    _ox = 0;
    _oy = h - townHarborHeight;
    _rect(0, 44, 390, 86, _water);
    for (final (x, y, w) in [
      (16.0, 70.0, 14.0),
      (150.0, 100.0, 18.0),
      (250.0, 116.0, 14.0),
      (320.0, 90.0, 12.0),
      (200.0, 122.0, 16.0),
      (60.0, 118.0, 12.0),
      (110.0, 84.0, 10.0),
    ]) {
      _rect(x, y, w, 2, _wave);
    }
    _rect(102, 0, 250, 44, _quay);
    _rect(102, 0, 250, 4, _quayTop);
    _rect(102, 18, 250, 2, _mortar);
    _rect(102, 32, 250, 2, _mortar);
    for (final (x, y) in [
      (140.0, 4.0),
      (200.0, 20.0),
      (270.0, 4.0),
      (320.0, 20.0)
    ]) {
      _rect(x, y, 2, 14, _mortar);
    }
    _rect(92, 10, 10, 6, _wall);
    _rect(86, 18, 16, 6, _wall);
    _rect(80, 26, 22, 6, _wall);
    _rect(30, 34, 72, 5, _wood);
    for (final x in [34.0, 64.0, 94.0]) {
      _rect(x, 39, 4, 16, _woodDark);
    }
    _rect(52, 22, 3, 12, _timber);
    _rect(49, 16, 9, 6, _lit);
    // The Rusty Eel.
    _poly([6, 58, 92, 58, 84, 74, 14, 74], const Color(0xFF5A4030));
    _rect(6, 56, 86, 3, _crate);
    _rect(44, 4, 3, 54, _timber);
    _poly([48, 8, 72, 14, 72, 50, 48, 52], _ash);
    _poly([42, 10, 22, 18, 22, 48, 42, 52], const Color(0xFF8C857A));
    _rect(16, 62, 5, 4, _lit);
  }

  void _piece(String id) {
    switch (id) {
      case 'keldas_hall':
        _rect(94, 0, 8, 10, _wall);
        _rect(96, 0, 4, 2, _ember);
        _poly([0, 16, 14, 4, 110, 4, 124, 16], _roof);
        _rect(4, 14, 116, 32, _stone);
        _rect(4, 26, 116, 1, _wall);
        _rect(4, 36, 116, 1, _wall);
        for (final x in [14.0, 30.0, 92.0]) {
          _rect(x, 19, 7, 7, _lit);
        }
        _rect(106, 19, 7, 7, _dark);
        _rect(56, 28, 14, 18, _ember);
        _rect(60, 33, 6, 13, _lit);
        _outline(58, 17, 10, 8, _lit);
      case 'barracks_annex':
        _poly([0, 14, 10, 2, 176, 2, 186, 14], _roofLight);
        _rect(10, 7, 166, 1, _wall);
        _rect(2, 12, 182, 34, _wall);
        _rect(2, 12, 182, 3, _timber);
        _rect(2, 30, 182, 2, _timber);
        for (final x in [2.0, 38.0, 74.0, 110.0, 146.0, 181.0]) {
          _rect(x, 12, 3, 34, _timber);
        }
        for (final (x, on) in [
          (16.0, true),
          (52.0, false),
          (88.0, true),
          (124.0, true),
          (160.0, false),
        ]) {
          _rect(x, 18, 8, 8, on ? _lit : _dark);
        }
        _rect(54, 34, 10, 12, _dark);
      case 'hammersmith':
        _rect(96, 0, 3, 3, _ember);
        _rect(102, 2, 2, 2, _lit);
        _rect(94, 4, 10, 16, _stone);
        _poly([4, 18, 62, 2, 120, 18], _roof);
        _rect(8, 16, 112, 30, _wallDark);
        _line(14, 20, 44, 44, _timber, 3);
        _line(44, 20, 14, 44, _timber, 3);
        _rect(100, 22, 7, 8, _lit);
        _rect(76, 28, 14, 18, _ember);
        _rect(80, 33, 6, 13, _lit);
        _rect(0, 22, 10, 2, _stone);
        _rect(0, 26, 9, 3, _ash);
        _rect(3, 29, 3, 3, _ash);
        _rect(1, 32, 7, 2, _ash);
      case 'academy':
        _poly([8, 26, 31, 0, 54, 26], _roofLight);
        _rect(28, 12, 6, 6, _tide);
        _rect(12, 24, 38, 68, _wall);
        _rect(26, 32, 10, 12, _lit);
        _rect(4, 52, 54, 3, _timber);
        _rect(26, 62, 10, 12, _tide);
        _rect(24, 80, 14, 12, _dark);
      case 'sharpweave_den':
        _poly([2, 14, 30, 0, 60, 16], _roof);
        _poly([6, 12, 58, 14, 56, 46, 8, 46], _wallDark);
        _rect(14, 20, 8, 8, _dark);
        _rect(38, 20, 8, 8, _ember);
        for (var i = 0; i < 6; i++) {
          _rect(8 + i * 8.0, 30, 8, 4, i.isEven ? _roofLight : _timber);
        }
        _rect(26, 34, 10, 12, _dark);
      case 'hearth_hall':
        _rect(86, 0, 4, 4, _ember);
        _rect(92, 1, 4, 3, _lit);
        _rect(84, 4, 14, 12, _wall);
        _poly([0, 18, 16, 6, 170, 6, 186, 18], _roof);
        _rect(4, 16, 178, 30, _stone);
        _rect(4, 16, 178, 2, _wall);
        for (final x in [14.0, 38.0, 62.0, 116.0, 140.0, 164.0]) {
          _rect(x, 23, 8, 9, _lit);
        }
        _outline(85, 22, 16, 4, _lit);
        _rect(85, 30, 16, 16, _dark);
      case 'banner_loft':
        _poly([6, 30, 62, 0, 118, 30], _roofLight);
        _rect(12, 28, 100, 64, _wall);
        _rect(52, 34, 20, 16, _dark);
        _rect(22, 38, 8, 9, _lit);
        _rect(94, 38, 8, 9, _lit);
        _rect(2, 58, 120, 3, _timber);
        for (final (x, len, c) in [
          (8.0, 23.0, _lit),
          (28.0, 19.0, _ember),
          (84.0, 23.0, _tide),
          (104.0, 17.0, _void),
        ]) {
          _poly([
            x,
            61,
            x + 12,
            61,
            x + 12,
            61 + len,
            x + 6,
            57 + len,
            x,
            61 + len
          ], c);
        }
        _rect(54, 72, 16, 20, _dark);
      case 'shroud_shrine':
        _poly([14, 40, 31, 0, 48, 40], _wallDark);
        _poly([31, 14, 27, 22, 31, 32, 35, 22], _void);
        _rect(8, 38, 46, 54, _stone);
        _rect(8, 38, 4, 54, const Color(0xFF6A6570));
        _rect(50, 38, 4, 54, const Color(0xFF6A6570));
        _poly([21, 92, 21, 74, 26, 66, 36, 66, 41, 74, 41, 92], _voidDeep);
        _poly([25, 92, 25, 75, 28, 70, 34, 70, 37, 75, 37, 92], _void);
        _rect(15, 56, 3, 5, _lit);
        _rect(44, 56, 3, 5, _lit);
      case 'add_floor':
        _poly([2, 12, 10, 4, 52, 4, 60, 12], _roof);
        _rect(4, 10, 54, 36, _wall);
        _rect(4, 10, 54, 2, _timber);
        _rect(4, 10, 2, 36, _timber);
        _rect(56, 10, 2, 36, _timber);
        _rect(4, 28, 54, 2, _timber);
        _line(6, 12, 30, 28, _timber, 2);
        _line(56, 12, 32, 28, _timber, 2);
        _rect(14, 33, 8, 8, _lit);
        _rect(40, 33, 8, 8, _dark);
      case 'add_stair':
        for (var i = 0; i < 5; i++) {
          _rect(4 + i * 10.0, 40 - i * 8.0, 14, 4, _wood);
        }
        _line(6, 44, 56, 6, _crate, 2);
        _rect(10, 10, 2, 18, _timber);
        _rect(7, 4, 8, 6, _lit);
        _rect(4, 44, 54, 2, _timber);
      case 'add_store':
        _poly([2, 14, 122, 6, 122, 14, 2, 20], const Color(0xFF3E4452));
        _rect(6, 16, 112, 30, _plank);
        for (final y in [22.0, 30.0, 38.0]) {
          _rect(6, y, 112, 1, _wood);
        }
        _rect(40, 24, 22, 22, _dark);
        _rect(74, 32, 12, 14, _crate);
        _rect(88, 36, 10, 10, _crate);
        _rect(78, 24, 10, 8, _crate);
        _rect(104, 20, 2, 16, _ash);
      case 'add_tower':
        _rect(22, 0, 18, 4, _wallDark);
        _rect(24, 4, 14, 10, _lit);
        _rect(18, 14, 26, 6, _wallDark);
        _rect(20, 20, 22, 72, _stone);
        for (final y in [40.0, 60.0, 78.0]) {
          _rect(20, y, 22, 1, _wall);
        }
        _rect(28, 46, 6, 8, _dark);
        _rect(28, 66, 6, 8, _lit);
      default:
        // A house the town does not know yet: a plain lit room.
        _rect(4, 10, 54, 36, _wall);
        _poly([2, 12, 31, 2, 60, 12], _roof);
        _rect(26, 26, 10, 10, _lit);
    }
  }

  @override
  bool shouldRepaint(_CliffTownPainter old) =>
      old.town != town ||
      old.unitsHigh != unitsHigh ||
      old.preview?.row != preview?.row ||
      old.preview?.column != preview?.column ||
      old.preview?.footprint != preview?.footprint ||
      old.highlightIndex != highlightIndex;
}
