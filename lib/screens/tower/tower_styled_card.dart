// The card of a Tower table in its type's style (v2.10.26, the user's pick):
// one rounded card for every type, told apart by its stock, name band, edge,
// badge and label, so a type reads at a glance and never by colour alone (its
// glyph and its label stay). Skill: cream with a black band. Rank-up: the
// skill's card with a gold edge, a gold band and a "+1" stamp. Die: black.
// Spell: violet with a double line. A clan's gift: slate with the clan's hue
// across the top. Gear: iron with rivets. Supplies: tan with a stitched edge.
// Purse: black with a gold stitched edge and a coin.
//
// Drawn at 122 x 201 and scaled by the fan (ClanHandFan fits any card to its
// own size), so its text keeps the same shape at every width.
import 'package:flutter/material.dart';

import '../../theme/stitched_ink.dart' show InkFonts;
import 'ink/ink_palette.dart';

/// The styles, one per kind of card on a table.
enum TowerCardStyle { skill, rankUp, die, spell, gift, gear, bundle, purse }

/// The drawn size of a card (width x height); a fan scales it.
const double towerStyledCardWidth = 122;
const double towerStyledCardHeight = 201;

class _Look {
  const _Look({
    required this.stock,
    required this.ink,
    required this.edge,
    required this.band,
    required this.bandInk,
    this.edgeWidth = 1.5,
    this.dashed = false,
    this.twin = false,
    this.rivets = false,
  });
  final Color stock, ink, edge, band, bandInk;
  final double edgeWidth;
  final bool dashed, twin, rivets;
}

_Look _lookOf(TowerCardStyle s) => switch (s) {
      TowerCardStyle.skill => const _Look(
          stock: inkPaper,
          ink: inkOnPaper,
          edge: inkBlack,
          band: inkBlack,
          bandInk: inkPaper),
      TowerCardStyle.rankUp => const _Look(
          stock: inkPaper,
          ink: inkOnPaper,
          edge: inkGold,
          edgeWidth: 4,
          band: inkGold,
          bandInk: inkBlack),
      TowerCardStyle.die => const _Look(
          stock: inkBlack,
          ink: inkPaper,
          edge: inkPaper,
          band: inkPaper,
          bandInk: inkOnPaper),
      TowerCardStyle.spell => const _Look(
          stock: inkViolet,
          ink: inkPaper,
          edge: inkPaper,
          twin: true,
          band: inkPaper,
          bandInk: inkOnPaper),
      TowerCardStyle.gift => const _Look(
          stock: inkDark,
          ink: inkPaper,
          edge: inkPaper,
          band: inkDark,
          bandInk: inkPaper),
      TowerCardStyle.gear => const _Look(
          stock: inkIron,
          ink: inkPaper,
          edge: inkBlack,
          edgeWidth: 4,
          rivets: true,
          band: inkBlack,
          bandInk: inkPaper),
      TowerCardStyle.bundle => const _Look(
          stock: inkSand,
          ink: inkOnPaper,
          edge: inkOnPaper,
          dashed: true,
          band: inkOnPaper,
          bandInk: inkPaper),
      TowerCardStyle.purse => const _Look(
          stock: inkBlack,
          ink: inkPaper,
          edge: inkGold,
          edgeWidth: 3,
          dashed: true,
          band: inkGold,
          bandInk: inkBlack),
    };

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.2, color: c);

class TowerStyledCard extends StatelessWidget {
  const TowerStyledCard({
    super.key,
    required this.style,
    required this.kind,
    required this.name,
    required this.text,
    required this.vignette,
    required this.badge,
    this.nudge,
    this.note,
    this.stamp,
    this.hue,
    this.round = false,
    this.darkBadge = false,
  });

  final TowerCardStyle style;

  /// The type's label ("Skill", "Gift · Crows", "Supplies").
  final String kind;
  final String name, text;

  /// Art's vignette (96 x 64) across the top.
  final String vignette;

  /// The glyph in the corner badge (the badge stays when colour is lost).
  final Widget badge;

  /// "+1 INT": the stat a skill raises, as a small outlined chip.
  final String? nudge;

  /// A small line under the words (a gift's standing).
  final String? note;

  /// The gold stamp of a rank-up ("+1").
  final String? stamp;

  /// A clan's hue, drawn across the top of its gift.
  final Color? hue;

  /// A round badge (a purse's coin).
  final bool round;

  /// A black badge, for pale icons (a die's, a spell's).
  final bool darkBadge;

  @override
  Widget build(BuildContext context) {
    final look = _lookOf(style);
    const radius = 10.0;
    final body = Column(children: [
      if (hue != null) Container(height: 5, color: hue),
      Expanded(
        flex: 9,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(vignette,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const ColoredBox(color: inkDark)),
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color:
                      darkBadge ? inkBlack.withValues(alpha: 0.85) : inkPaper,
                  borderRadius: BorderRadius.circular(round ? 11 : 2)),
              child: badge,
            ),
          ),
          if (stamp != null)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: inkGold,
                    border: Border.all(color: inkBlack, width: 1.5)),
                child: Text(stamp!, style: _display(13, inkBlack)),
              ),
            ),
        ]),
      ),
      Container(
        color: look.band,
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        child: Text(name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _display(11.5, look.bandInk)),
      ),
      Expanded(
        flex: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
          child: Column(children: [
            Text(kind.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _prose(8, look.ink.withValues(alpha: 0.75))
                    .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Expanded(
              child: Text(text,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: note == null ? 5 : 3,
                  style: _prose(9.5, look.ink)),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(note!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _prose(8, look.ink.withValues(alpha: 0.85))),
              ),
            if (nudge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    border: Border.all(color: look.ink, width: 1.2),
                    borderRadius: BorderRadius.circular(9)),
                child: Text(nudge!,
                    style: _prose(9.5, look.ink)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
          ]),
        ),
      ),
    ]);
    return SizedBox(
      width: towerStyledCardWidth,
      height: towerStyledCardHeight,
      child: Stack(fit: StackFit.expand, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.all(look.edgeWidth),
            child: ColoredBox(color: look.stock, child: body),
          ),
        ),
        IgnorePointer(child: CustomPaint(painter: _EdgePainter(look, radius))),
      ]),
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.look, this.radius);
  final _Look look;
  final double radius;

  @override
  void paint(Canvas canvas, Size s) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = look.edge
      ..strokeWidth = look.edgeWidth * 2; // half is clipped
    canvas.save();
    canvas.clipPath(path);
    if (look.dashed) {
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
    if (look.twin) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(5, 5, s.width - 10, s.height - 10),
              const Radius.circular(6)),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = look.edge.withValues(alpha: 0.7)
            ..strokeWidth = 1);
    }
    if (look.rivets) {
      final dark = Paint()..color = inkBlack;
      final light = Paint()..color = inkGrey;
      for (final o in [
        const Offset(7, 7),
        Offset(s.width - 7, 7),
        Offset(7, s.height - 7),
        Offset(s.width - 7, s.height - 7),
      ]) {
        canvas.drawCircle(o, 3, dark);
        canvas.drawCircle(o.translate(-0.7, -0.7), 1.2, light);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EdgePainter old) => false;
}
