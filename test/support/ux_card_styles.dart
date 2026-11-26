// PICTURE SUPPORT (UX): mock cards in the approved per-type styles, with a
// "+1 STAT" nudge and a note line. Used only by the picture tests.
import 'package:flutter/material.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart' show InkFonts;

const _gold = Color(0xFFC9A24B);
const _violet = Color(0xFF1B1533);
const _iron = Color(0xFF454E53);
const _tan = Color(0xFFB9A27A);
const _clan = Color(0xFF3F7F6B);

enum UxShape { square, chamfer, swallow, notch }

class UxCardSpec {
  const UxCardSpec(
    this.label,
    this.kind,
    this.name,
    this.text, {
    this.vignette,
    this.icon = Icons.help_outline,
    this.stock = inkBlack,
    this.ink = inkPaper,
    this.edge = inkPaper,
    this.edgeWidth = 1.5,
    this.dashed = false,
    this.twin = false,
    this.rivets = false,
    this.shape = UxShape.square,
    this.band = inkPaper,
    this.bandInk = inkOnPaper,
    this.stripe,
    this.stamp,
    this.coin = false,
    this.back = false,
    this.needsArt = false,
    this.nudge,
    this.note,
  });
  final String label, kind, name, text;
  final String? vignette;
  final IconData icon;
  final Color stock, ink, edge, band, bandInk;
  final double edgeWidth;
  final bool dashed, twin, rivets, coin, back, needsArt;
  final UxShape shape;
  final Color? stripe;
  final String? stamp;
  final String? nudge, note;
}

const uxV = 'assets/visuals/tower_cards/';
const List<UxCardSpec> uxSpecs = [
  UxCardSpec(
    'Skill',
    'Skill',
    'Ember Lash',
    'Hit one foe for 6 fire.',
    vignette: '${uxV}skill_fire.png',
    icon: Icons.local_fire_department,
    stock: inkPaper,
    ink: inkOnPaper,
    edge: inkBlack,
    band: inkBlack,
    bandInk: inkPaper,
  ),
  UxCardSpec(
    'Die',
    'Die',
    'Ash Die',
    'A d6 with two faces of 4.',
    vignette: '${uxV}die.png',
    icon: Icons.casino,
  ),
  UxCardSpec(
    'Skill upgrade',
    'Upgrade',
    'Ember Lash II',
    'Rank 2: 9 fire.',
    vignette: '${uxV}skill_fire.png',
    icon: Icons.local_fire_department,
    stock: inkPaper,
    ink: inkOnPaper,
    edge: _gold,
    edgeWidth: 4,
    band: _gold,
    bandInk: inkBlack,
    stamp: '+1',
  ),
  UxCardSpec(
    'Spell',
    'Spell',
    'Radiant Judgment',
    'Strike all foes with light.',
    vignette: '${uxV}spell_damage.png',
    icon: Icons.auto_awesome,
    stock: _violet,
    edge: inkPaper,
    twin: true,
    shape: UxShape.chamfer,
    band: inkPaper,
  ),
  UxCardSpec(
    'Clan gift',
    'Clan gift',
    'Shadow Step',
    'The clan lends its stride.',
    vignette: '${uxV}skill_void.png',
    icon: Icons.groups,
    stock: inkDark,
    shape: UxShape.swallow,
    stripe: _clan,
    band: inkDark,
    bandInk: inkPaper,
  ),
  UxCardSpec(
    'Equipment',
    'Equipment',
    'Iron Bracers',
    '+2 armour while worn.',
    icon: Icons.shield,
    stock: _iron,
    edge: inkBlack,
    edgeWidth: 4,
    rivets: true,
    band: inkBlack,
    bandInk: inkPaper,
    needsArt: true,
  ),
  UxCardSpec(
    'Item',
    'Item',
    'Bone Salve',
    'Heal 30% of your health.',
    icon: Icons.local_pharmacy,
    stock: _tan,
    ink: inkOnPaper,
    edge: inkOnPaper,
    dashed: true,
    shape: UxShape.notch,
    band: inkOnPaper,
    bandInk: inkPaper,
    needsArt: true,
  ),
  UxCardSpec(
    'Money',
    'Coins',
    '40 coins',
    'Spend them at the next stall.',
    icon: Icons.monetization_on,
    stock: inkBlack,
    edge: _gold,
    edgeWidth: 3,
    dashed: true,
    coin: true,
    band: _gold,
    bandInk: inkBlack,
    needsArt: true,
  ),
  UxCardSpec(
    'Clan oath',
    'Oath',
    'Oath of Ash',
    'Swear to the clan: ward +1.',
    vignette: '${uxV}skill_light.png',
    icon: Icons.flag,
    stock: inkDeep,
    edge: inkRed,
    edgeWidth: 2,
    shape: UxShape.swallow,
    stripe: inkRed,
    band: inkDeep,
    bandInk: inkPaper,
  ),
  UxCardSpec(
    'Gamble (face down)',
    'Gamble',
    '',
    '',
    icon: Icons.question_mark,
    stock: inkDeep,
    edge: inkPaper,
    twin: true,
    back: true,
    needsArt: true,
  ),
];

TextStyle _d(double s, Color c) => TextStyle(
      fontFamily: InkFonts.display,
      fontSize: s,
      height: 1.05,
      color: c,
    );
TextStyle _p(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.2, color: c);

class UxShapeClipper extends CustomClipper<Path> {
  const UxShapeClipper(this.shape);
  final UxShape shape;
  @override
  Path getClip(Size s) => Path()
    ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(10)));

  @override
  bool shouldReclip(UxShapeClipper old) => old.shape != shape;
}

class UxEdgePainter extends CustomPainter {
  UxEdgePainter(this.spec);
  final UxCardSpec spec;
  @override
  void paint(Canvas canvas, Size s) {
    final path = UxShapeClipper(spec.shape).getClip(s);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = spec.edge
      ..strokeWidth = spec.edgeWidth * 2; // half is clipped
    canvas.save();
    canvas.clipPath(path);
    if (spec.dashed) {
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + 5), p);
          d += 8;
        }
      }
    } else {
      canvas.drawPath(path, p);
    }
    if (spec.twin) {
      final q = Paint()
        ..style = PaintingStyle.stroke
        ..color = spec.edge.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      canvas.drawRect(Rect.fromLTWH(5, 5, s.width - 10, s.height - 10), q);
    }
    if (spec.rivets) {
      final r = Paint()..color = inkBlack;
      final hi = Paint()..color = inkGrey;
      for (final o in [
        const Offset(7, 7),
        Offset(s.width - 7, 7),
        Offset(7, s.height - 7),
        Offset(s.width - 7, s.height - 7),
      ]) {
        canvas.drawCircle(o, 3, r);
        canvas.drawCircle(o.translate(-0.7, -0.7), 1.2, hi);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(UxEdgePainter old) => false;
}

class UxBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = inkPaper.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (double x = -s.height; x < s.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x + s.height, s.height), p);
      canvas.drawLine(Offset(x + s.height, 0), Offset(x, s.height), p);
    }
  }

  @override
  bool shouldRepaint(UxBackPainter old) => false;
}

class UxCard extends StatelessWidget {
  const UxCard(this.spec, this.width,
      {super.key, this.held = false, this.heightK = 1.95});
  final UxCardSpec spec;
  final double width;
  final bool held;
  final double heightK;

  Widget _art() {
    if (spec.vignette != null) {
      return Image.asset(
        spec.vignette!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
      );
    }
    // A drawn stand-in: marked as needing new art.
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: spec.stock == _tan ? const Color(0xFF7A6A4C) : inkDark,
        ),
        Center(
          child: spec.coin
              ? Container(
                  width: width * 0.42,
                  height: width * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold,
                    border: Border.all(color: inkBlack, width: 3),
                  ),
                  child: Icon(
                    Icons.currency_exchange,
                    size: width * 0.22,
                    color: inkBlack,
                  ),
                )
              : Icon(spec.icon, size: width * 0.4, color: inkPaper),
        ),
        Positioned(
          right: 3,
          bottom: 2,
          child: Text(
            'NEW ART',
            style: _p(
              7,
              inkPaper.withValues(alpha: 0.8),
            ).copyWith(letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = width * heightK;
    final body = spec.back
        ? Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: spec.stock),
              CustomPaint(painter: UxBackPainter()),
              Center(
                child: Container(
                  width: width * 0.5,
                  height: width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inkRed,
                    border: Border.all(color: inkPaper, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('?', style: _d(width * 0.3, inkPaper)),
                ),
              ),
            ],
          )
        : Column(
            children: [
              if (spec.stripe != null) Container(height: 5, color: spec.stripe),
              Expanded(
                flex: 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _art(),
                    Positioned(
                      left: 5,
                      top: 5,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: inkPaper,
                          borderRadius: BorderRadius.circular(
                            spec.coin ? 11 : 2,
                          ),
                        ),
                        child: Icon(spec.icon, size: 15, color: inkOnPaper),
                      ),
                    ),
                    if (spec.stamp != null)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _gold,
                            border: Border.all(color: inkBlack, width: 1.5),
                          ),
                          child: Text(spec.stamp!, style: _d(13, inkBlack)),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                color: spec.band,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                child: Text(
                  spec.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: _d(11.5, spec.bandInk),
                ),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                  child: Column(
                    children: [
                      Text(
                        spec.kind.toUpperCase(),
                        style: _p(8, spec.ink.withValues(alpha: 0.75)).copyWith(
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Text(
                          spec.text,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                          style: _p(9.5, spec.ink),
                        ),
                      ),
                      if (spec.note != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            spec.note!,
                            textAlign: TextAlign.center,
                            style: _p(8, spec.ink.withValues(alpha: 0.85)),
                          ),
                        ),
                      if (spec.nudge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: spec.ink, width: 1.2),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            spec.nudge!,
                            style: _p(
                              9.5,
                              spec.ink,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: UxShapeClipper(spec.shape),
            child: Padding(
              padding: EdgeInsets.all(spec.edgeWidth),
              child: ColoredBox(color: spec.stock, child: body),
            ),
          ),
          // The stock fills under the edge too.
          IgnorePointer(child: CustomPaint(painter: UxEdgePainter(spec))),
        ],
      ),
    );
  }
}
