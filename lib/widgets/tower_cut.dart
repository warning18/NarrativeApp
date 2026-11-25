// The Tower in cross-section (Maps, held prototype): the whole height on
// one drawing, in the Tower's ink. Each floor is a storey with a window:
// lit where the floor was won, struck through where it was passed without
// a fight (a stair, a rival beaten fast, a guardian talked past), dark
// ahead. The wardens (5, 15, 25) have two windows, the bosses (10, 20, 30)
// a red frame. The run's last jump is drawn beside the wall, the highest
// floor reached is flagged when the run stands under it, and a red mark
// says where the run is, or where it ended.
//
// [TowerCutView] is read off a run; it invents nothing: a run keeps its
// floor, its highest floor, the floors whose spoils it took and its last
// event, and that is all that is drawn.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/tower/tower_run.dart';
import '../data/tower/tower_tables.dart';
import '../screens/tower/ink/ink_palette.dart';
import '../theme/stitched_ink.dart' show InkFonts;

/// What the cut shows of a run.
class TowerCutView {
  const TowerCutView({
    required this.floor,
    required this.highest,
    required this.won,
    required this.status,
    this.jump,
  });

  factory TowerCutView.of(TowerRun run) {
    final last = run.lastEvent;
    return TowerCutView(
      floor: run.floor,
      highest: math.max(run.floor, run.crest),
      won: {...run.spoils.keys, ...run.taken.keys, ...run.refused},
      status: run.status,
      jump: last != null && (last.to < last.from || last.to > last.from + 1)
          ? (last.from, last.to)
          : null,
    );
  }

  /// The floor the run stands on, or ended on.
  final int floor;

  /// The highest floor reached (the floor itself unless the run fell).
  final int highest;

  /// The floors won: a fight fought and its chest opened.
  final Set<int> won;
  final TowerStatus status;

  /// The last event's move when it was not one step up: a stair or a
  /// rival's skip (up), a fall (down).
  final (int, int)? jump;

  bool get over => status != TowerStatus.climbing;

  /// A floor under the highest reached that was not won: passed.
  bool passed(int n) => n < highest && !won.contains(n) && n != floor;
}

/// The cut. [onPaper] draws it in ink on a paper panel (the end screen);
/// otherwise in paper on the Tower's night. [compact] is the small one: no
/// floor numbers but the bosses', no band names.
class TowerCut extends StatelessWidget {
  const TowerCut({
    super.key,
    required this.view,
    this.rowHeight = 38,
    this.compact = false,
    this.onPaper = false,
    this.bands = const [],
    this.highestLabel = '',
  });

  final TowerCutView view;
  final double rowHeight;
  final bool compact;
  final bool onPaper;

  /// The three bands' names, bottom first.
  final List<String> bands;
  final String highestLabel;

  /// The drawing's height for [rowHeight].
  static double heightFor(double rowHeight, {bool compact = false}) =>
      rowHeight * towerTop + (compact ? rowHeight * 2 : rowHeight * 1.4);

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(double.infinity, heightFor(rowHeight, compact: compact)),
        painter: TowerCutPainter(
          view: view,
          rowHeight: rowHeight,
          compact: compact,
          onPaper: onPaper,
          bands: bands,
          highestLabel: highestLabel,
        ),
      );
}

class TowerCutPainter extends CustomPainter {
  const TowerCutPainter({
    required this.view,
    required this.rowHeight,
    required this.compact,
    required this.onPaper,
    required this.bands,
    required this.highestLabel,
  });

  final TowerCutView view;
  final double rowHeight;
  final bool compact;
  final bool onPaper;
  final List<String> bands;
  final String highestLabel;

  Color get _line => onPaper ? inkOnPaper : inkPaper;
  Color get _ground => onPaper ? inkPaper : inkBlack;
  Color get _dim => onPaper ? inkGrey : inkSlate;

  /// The top of floor [n]'s storey.
  double _top(int n, double roof) => roof + (towerTop - n) * rowHeight;

  /// The wall's left and right at floor [n]: the Tower narrows band by band.
  (double, double) _wall(int n, double left, double right) {
    final band = (n - 1) ~/ 10; // 0 at the foot
    final inset = (right - left) * 0.06 * band;
    return (left + inset, right - inset);
  }

  TextPainter _text(String s, double size, Color c,
          {String family = InkFonts.system, FontWeight? weight}) =>
      TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(
                fontFamily: family,
                fontSize: size,
                color: c,
                fontWeight: weight,
                height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final rh = rowHeight;
    final roof = compact ? rh * 1.4 : rh * 1.1;
    final numbers = compact ? rh * 2.6 : 34.0;
    final left = numbers + (compact ? 2 : 10);
    final right = compact ? size.width - rh * 1.6 : size.width * 0.6;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1 : 1.5
      ..color = _line;

    // The battlements over the crown.
    final (cl, cr) = _wall(towerTop, left, right);
    final merlon = (cr - cl) / 7;
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
          Rect.fromLTWH(
              cl + i * 2 * merlon, roof - rh * 0.45, merlon, rh * 0.45),
          Paint()..color = _line);
    }

    for (var n = towerTop; n >= 1; n--) {
      final top = _top(n, roof);
      final (l, r) = _wall(n, left, right);
      final storey = Rect.fromLTRB(l, top, r, top + rh);
      final boss = n % 10 == 0, warden = n % 10 == 5;
      final here = n == view.floor;
      final won = view.won.contains(n) && !here;
      final passed = view.passed(n);
      final ahead = n > view.highest || (!won && !passed && !here);

      canvas.drawRect(storey, Paint()..color = _ground);
      canvas.drawRect(storey, stroke);
      if (boss) {
        canvas.drawRect(
            storey.deflate(compact ? 1 : 2.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = compact ? 1 : 2.5
              ..color = inkRed);
      }

      if (compact) {
        // Small: a storey won is filled, one passed half filled, the
        // run's own red; no windows.
        final inner = storey.deflate(1);
        if (here) {
          canvas.drawRect(inner, Paint()..color = inkRed);
        } else if (won) {
          canvas.drawRect(inner, Paint()..color = _line);
        } else if (passed) {
          canvas.drawRect(
              Rect.fromLTRB(
                  inner.left, inner.top, inner.center.dx, inner.bottom),
              Paint()..color = _line);
        }
        if (boss) {
          final tp = _text('$n', rh * 1.5, inkRed);
          tp.paint(canvas,
              Offset(numbers - tp.width - 3, storey.center.dy - tp.height / 2));
        }
        continue;
      }
      // The windows: one, two for a warden, three for a boss.
      final count = boss ? 3 : (warden ? 2 : 1);
      final ww = compact ? rh * 0.55 : math.min(16.0, rh * 0.42);
      final wh = rh * (compact ? 0.5 : 0.52);
      final gap = ww * 0.9;
      final total = count * ww + (count - 1) * gap;
      for (var i = 0; i < count; i++) {
        final x = storey.center.dx - total / 2 + i * (ww + gap);
        final w = Rect.fromLTWH(x, storey.center.dy - wh / 2, ww, wh);
        if (here) {
          canvas.drawRect(w, Paint()..color = inkRed);
        } else if (won) {
          canvas.drawRect(w, Paint()..color = _line);
        } else if (passed) {
          canvas.drawRect(w, stroke);
          canvas.drawLine(w.bottomLeft, w.topRight, stroke);
        } else {
          canvas.drawRect(
              w,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = ahead ? _dim : _line);
        }
      }

      // Its number: every floor on the page, the bosses' only when small.
      if (!compact || boss) {
        final tp = _text('$n', compact ? rh * 1.5 : 13,
            here || boss ? inkRed : (n <= view.highest ? _line : _dim));
        tp.paint(
            canvas,
            Offset(numbers - tp.width - (compact ? 3 : 4),
                storey.center.dy - tp.height / 2));
      }

      // Where a run died: a red cross beside its storey. (Where the run
      // stands is the red window and the red number; the legend says so.)
      if (here && !compact && view.status == TowerStatus.dead) {
        final c = Offset(r + 16, storey.center.dy);
        final x = Paint()
          ..color = inkRed
          ..strokeWidth = 2.5;
        canvas.drawLine(c + const Offset(-6, -6), c + const Offset(6, 6), x);
        canvas.drawLine(c + const Offset(-6, 6), c + const Offset(6, -6), x);
      }
      // The highest floor reached, when the run stands under it.
      if (n == view.highest && view.highest > view.floor) {
        final y = top;
        canvas.drawLine(
            Offset(r, y),
            Offset(r + (compact ? rh : 18), y),
            Paint()
              ..color = _line
              ..strokeWidth = compact ? 1 : 1.5);
        if (!compact) {
          final tp = _text(highestLabel, 12, _line);
          tp.paint(canvas, Offset(r + 22, y - tp.height / 2));
        }
      }
    }

    // The last jump, beside the wall: up in paper, down in red.
    if (view.jump case (final from, final to)) {
      final up = to > from;
      final y0 = _top(from, roof) + rh / 2, y1 = _top(to, roof) + rh / 2;
      final (_, r0) = _wall(math.min(from, to), left, right);
      final x = r0 + (compact ? rh * 0.5 : 6);
      final reach =
          compact ? rh * 0.9 : math.min(30.0, (y1 - y0).abs() / 2 + 8);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.2 : 2
        ..color = up ? _line : inkRed;
      canvas.drawPath(
          Path()
            ..moveTo(x, y0)
            ..cubicTo(x + reach, y0, x + reach, y1, x, y1),
          p);
      final a = compact ? 3.0 : 5.0;
      canvas.drawPath(
          Path()
            ..moveTo(x - 1, y1)
            ..lineTo(x + a, y1 - a)
            ..lineTo(x + a, y1 + a)
            ..close(),
          Paint()..color = up ? _line : inkRed);
    }

    // The three bands, named beside the wall.
    if (!compact && bands.length == 3) {
      final x = size.width * 0.6 + 44;
      for (var b = 0; b < 3; b++) {
        final top = _top(b * 10 + 10, roof),
            bottom = _top(b * 10 + 1, roof) + rh;
        canvas.drawLine(
            Offset(x, top + 4),
            Offset(x, bottom - 4),
            Paint()
              ..color = _dim
              ..strokeWidth = 1.5);
        final words = bands[b].toUpperCase().split(' ');
        var y = (top + bottom) / 2 - words.length * 9;
        // Clear of the "highest reached" flag when it falls on these rows.
        if (view.highest > view.floor) {
          final flag = _top(view.highest, roof);
          if (flag > y - 14 && flag < y + words.length * 18 + 14) {
            y = flag + 16;
          }
        }
        for (final word in words) {
          final tp = _text(word, 12, _line, family: InkFonts.system);
          tp.paint(canvas, Offset(x + 8, y));
          y += 18;
        }
      }
    }
  }

  @override
  bool shouldRepaint(TowerCutPainter old) =>
      old.view.floor != view.floor ||
      old.view.highest != view.highest ||
      old.view.won.length != view.won.length ||
      old.view.status != view.status ||
      old.view.jump != view.jump ||
      old.rowHeight != rowHeight ||
      old.onPaper != onPaper;
}
