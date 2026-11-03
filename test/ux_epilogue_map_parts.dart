// The epilogue map (docs/proposals/epilogue-map.md): at the ending, the realm
// as the clans hold it. The world's coast, each town tinted by its holder
// (town_rulers.dart's real tint), the clans' roads joining towns of one
// holder, and a line for each big town saying who holds it and how it was
// taken. Mock only: the holdings are sample data until Core's
// epilogueHoldings lands; nothing here ships.
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

/// One town on the epilogue map.
class EpilogueTown {
  const EpilogueTown({
    required this.id,
    required this.name,
    required this.at,
    required this.big,
    required this.clanId,
    required this.clanName,
    required this.color,
    required this.accent,
    required this.how,
    this.number = 0,
    this.differing = 0,
  });

  final String id;
  final String name;

  /// Its place on the chart (256 x 176 units).
  final Offset at;
  final bool big;
  final String clanId;
  final String clanName;
  final Color color;
  final Color accent;

  /// How it was taken, in a few words ("by war, chapter 5").
  final String how;

  /// The number on the map and in the list (big towns only).
  final int number;

  /// Districts of the town held by someone else than the town.
  final int differing;

  bool get neutral => clanId.isEmpty;
}

class EpilogueData {
  const EpilogueData({
    required this.towns,
    required this.roads,
    required this.chart,
  });

  /// Every town, in the story's order.
  final List<EpilogueTown> towns;

  /// The roads, each a pair of town ids (consecutive towns in the story).
  final List<(String, String)> roads;
  final ChartGeography chart;

  List<EpilogueTown> get big => [
        for (final t in towns)
          if (t.big) t,
      ];

  /// The part of the chart the map shows: the towns' bounds, padded.
  Rect get view {
    var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
    for (final t in towns) {
      minX = min(minX, t.at.dx);
      minY = min(minY, t.at.dy);
      maxX = max(maxX, t.at.dx);
      maxY = max(maxY, t.at.dy);
    }
    return Rect.fromLTRB(minX - 16, minY - 14, maxX + 16, maxY + 14);
  }

  /// The holders and how many towns each holds, most first.
  List<(String, String, Color, int)> get holders {
    final counts = <String, (String, Color, int)>{};
    for (final t in towns) {
      if (t.neutral) continue;
      final c = counts[t.clanId];
      counts[t.clanId] = (t.clanName, t.color, (c?.$3 ?? 0) + 1);
    }
    return [
      for (final e in counts.entries)
        (e.key, e.value.$1, e.value.$2, e.value.$3),
    ]..sort((a, b) => b.$4.compareTo(a.$4));
  }
}

/// Whether a road is a clan's: both ends held by one clan.
bool isClanRoad(EpilogueTown a, EpilogueTown b) =>
    !a.neutral && a.clanId == b.clanId;

class EpilogueScreen extends StatelessWidget {
  const EpilogueScreen({super.key, required this.data});
  final EpilogueData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        children: [
          Text('The realm, at the end',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontFamily: InkFonts.display)),
          const SizedBox(height: 2),
          Text('Who holds what, and how.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: data.view.width / data.view.height,
              child: CustomPaint(painter: _MapPainter(data)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (id, name, color, n) in data.holders)
              Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  ClanFlag(factionId: id, height: 12),
                  const SizedBox(width: 4),
                  Text('$name $n',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
          const SizedBox(height: 14),
          Text('THE BIG TOWNS',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          for (final t in data.big) _TownRow(town: t),
          const SizedBox(height: 6),
          Text(
              'A town wears its holder’s colour. A road in a clan’s colour joins two of its towns; a grey dashed road joins towns of different holders. Villages are the small dots.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ]);
  }
}

class _TownRow extends StatelessWidget {
  const _TownRow({required this.town});
  final EpilogueTown town;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: Row(children: [
        _Dot(town: town, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(town.name, style: theme.textTheme.titleSmall),
                  if (town.differing > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ink.seam),
                      ),
                      child: Text(
                          town.differing == 1
                              ? '1 district differs'
                              : '${town.differing} districts differ',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                    ),
                  ],
                ]),
            const SizedBox(height: 2),
            if (town.neutral)
              Text('No one holds it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash))
            else
              Row(children: [
                ClanFlag(factionId: town.clanId, height: 12),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('${town.clanName} · ${town.how}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ),
              ]),
          ]),
        ),
      ]),
    );
  }
}

/// A big town's numbered disc, in its holder's colour.
class _Dot extends StatelessWidget {
  const _Dot({required this.town, required this.size});
  final EpilogueTown town;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: town.color,
          border: Border.all(color: town.accent, width: 2),
        ),
        child: Text('${town.number}',
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 2, color: Colors.black87)])),
      );
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.data);
  final EpilogueData data;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = ChartPalette.of(MapLook.night);
    final view = data.view;
    final k = size.width / view.width;
    Offset p(Offset o) => Offset((o.dx - view.left) * k, (o.dy - view.top) * k);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.sea);
    // The coast: each loop smoothed through its midpoints.
    for (final loop in data.chart.lands) {
      if (loop.length < 3) continue;
      final path = Path();
      Offset mid(Offset a, Offset b) =>
          Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final pts = [for (final o in loop) p(o)];
      path.moveTo(mid(pts.last, pts.first).dx, mid(pts.last, pts.first).dy);
      for (var i = 0; i < pts.length; i++) {
        final next = pts[(i + 1) % pts.length];
        final m = mid(pts[i], next);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = palette.land);
      canvas.drawPath(
          path,
          Paint()
            ..color = palette.coast.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    final byId = {for (final t in data.towns) t.id: t};
    // The roads: a clan's in its colour, the rest grey and dashed.
    for (final (a, b) in data.roads) {
      final ta = byId[a], tb = byId[b];
      if (ta == null || tb == null) continue;
      final from = p(ta.at), to = p(tb.at);
      if (isClanRoad(ta, tb)) {
        canvas.drawLine(
            from,
            to,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.6)
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            from,
            to,
            Paint()
              ..color = ta.color
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
      } else {
        final len = (to - from).distance;
        final dir = (to - from) / max(len, 0.001);
        for (var d = 0.0; d < len; d += 7) {
          canvas.drawLine(
              from + dir * d,
              from + dir * min(d + 3.5, len),
              Paint()
                ..color = palette.coast.withValues(alpha: 0.75)
                ..strokeWidth = 1.4);
        }
      }
    }
    // The towns, over the roads.
    for (final t in data.towns) {
      final c = p(t.at);
      final r = t.big ? 10.0 : 4.6;
      canvas.drawCircle(
          c, r + 2, Paint()..color = Colors.black.withValues(alpha: 0.55));
      canvas.drawCircle(c, r, Paint()..color = t.color);
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = t.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = t.big ? 2 : 1.4);
      if (t.big) {
        final tp = TextPainter(
          text: TextSpan(
              text: '${t.number}',
              style: const TextStyle(
                  fontFamily: InkFonts.system,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black87)])),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}
