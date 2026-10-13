// The travel-history map (v1.268): the world chart, as far as the party knows
// it. The places been to, numbered in the order they were reached and joined
// by the road taken; the places heard of but not reached, as a "?"; the
// party's own place ringed. A pinch zooms and a drag pans, as on the
// Journey's chart; a tap on a place tells the screen which one (and whether
// it was been to or only heard of), so a later camp can travel there.
//
// The view takes everything it shows as plain values (the geography, the ids
// reached in order, the ids known, where the party is), so it does not care
// whether they come from the story's journey or from the travel state Core
// keeps; and it draws every name itself, one clear of the next, so a crowded
// land stays readable (see [placeTravelLabels]).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../theme/stitched_ink.dart';
import 'chart_map_painter.dart';

/// What a place is to the party.
enum TravelPlaceState {
  /// Been to: its name, and its place in the order reached.
  visited,

  /// Heard of, not reached: a "?".
  known,
}

/// The names of the places that fit, each beside its mark and clear of the
/// others, in the order [requests] come (the ones that matter most first): a
/// name tries the right of its mark, then the left, then above, then below,
/// and is left out when none is free. Everything is in screen pixels.
class TravelLabelRequest {
  const TravelLabelRequest(this.id, this.mark, this.size);

  final String id;

  /// The mark's centre.
  final Offset mark;

  /// The name's box.
  final Size size;
}

Map<String, Rect> placeTravelLabels(
  List<TravelLabelRequest> requests, {
  required Rect bounds,
  double markRadius = 6,
  double gap = 3,

  /// Other marks a name must keep clear of (the "?" of the places heard of).
  List<Offset> obstacles = const [],
}) {
  final marks = [
    for (final r in requests)
      Rect.fromCircle(center: r.mark, radius: markRadius),
    for (final o in obstacles) Rect.fromCircle(center: o, radius: markRadius),
  ];
  final placed = <String, Rect>{};
  for (final r in requests) {
    final w = r.size.width;
    final h = r.size.height;
    final spot = [
      Rect.fromLTWH(r.mark.dx + markRadius + gap, r.mark.dy - h / 2, w, h),
      Rect.fromLTWH(r.mark.dx - markRadius - gap - w, r.mark.dy - h / 2, w, h),
      Rect.fromLTWH(r.mark.dx - w / 2, r.mark.dy - markRadius - gap - h, w, h),
      Rect.fromLTWH(r.mark.dx - w / 2, r.mark.dy + markRadius + gap, w, h),
    ];
    for (final box in spot) {
      if (!bounds.contains(box.topLeft) || !bounds.contains(box.bottomRight)) {
        continue;
      }
      if (placed.values.any((o) => o.overlaps(box.inflate(1)))) continue;
      if (marks.any((m) => m.overlaps(box))) continue;
      placed[r.id] = box;
      break;
    }
  }
  return placed;
}

class TravelMapView extends StatefulWidget {
  const TravelMapView({
    super.key,
    required this.geography,
    required this.palette,
    required this.language,
    required this.visited,
    required this.nameOf,
    this.known = const {},
    this.here,
    this.fog = ChartFog.uncharted,
    this.onTapPlace,
    this.maxZoom = 6,
  });

  final ChartGeography geography;
  final ChartPalette palette;
  final AppLanguage language;

  /// The ids of the places been to, in the order reached (a place gone back to
  /// appears again: the road runs through it twice, its number is the first).
  final List<String> visited;

  /// The ids of the places heard of and not reached.
  final Set<String> known;

  /// Where the party stands.
  final String? here;

  /// How the land the party has not seen is hidden.
  final ChartFog fog;

  /// The name of the place [id], in the language.
  final String Function(String id) nameOf;

  /// A place tapped, with what it is to the party.
  final void Function(String id, TravelPlaceState state)? onTapPlace;
  final double maxZoom;

  @override
  State<TravelMapView> createState() => _TravelMapViewState();
}

class _TravelMapViewState extends State<TravelMapView> {
  final TransformationController _view = TransformationController();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  static const _still = AlwaysStoppedAnimation<double>(0);

  Size _chart = Size.zero;

  /// The chart opens framed on the road taken (once).
  bool _framed = false;

  double get _zoom => _view.value.getMaxScaleOnAxis();

  @override
  void dispose() {
    _view.dispose();
    _frame.dispose();
    super.dispose();
  }

  /// Each place's first visit, in order: its number on the chart.
  Map<String, int> get _order {
    final order = <String, int>{};
    for (final id in widget.visited) {
      order.putIfAbsent(id, () => order.length + 1);
    }
    return order;
  }

  Offset _px(String id) {
    final at = widget.geography.places[id] ??
        const Offset(worldMapWidth / 2, worldMapHeight / 2);
    return Offset(at.dx * _chart.width / worldMapWidth,
        at.dy * _chart.height / worldMapHeight);
  }

  void _zoomBy(double factor, Size box) {
    final centre = Offset(box.width / 2, box.height / 2);
    final inverse = Matrix4.inverted(_view.value);
    final at = MatrixUtils.transformPoint(inverse, centre);
    final next = (_zoom * factor).clamp(1.0, widget.maxZoom);
    _view.value = Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..scaleByDouble(next, next, 1, 1)
      ..translateByDouble(-at.dx, -at.dy, 0, 1);
  }

  /// The chart at [scale], with the party's place in the middle of the box.
  void _centreOnHere(Size box, {double scale = 2.5}) {
    final here = widget.here;
    if (here == null) return;
    // The chart sits in the middle of a taller box.
    final childHeight = math.max(box.height, _chart.height);
    final at = _px(here) + Offset(0, (childHeight - _chart.height) / 2);
    final s = scale.clamp(1.0, widget.maxZoom);
    _view.value = Matrix4.identity()
      ..translateByDouble(box.width / 2, box.height / 2, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-at.dx, -at.dy, 0, 1);
  }

  /// The chart at the zoom and place that bring the whole of the road taken
  /// (and the places heard of) into the box, with room round it.
  void _frameJourney(Size box) {
    final ids = [
      ...widget.visited,
      ...widget.known,
      if (widget.here != null) widget.here!,
    ].where(widget.geography.places.containsKey).toList();
    if (ids.length < 2) return;
    final childHeight = math.max(box.height, _chart.height);
    final lift = Offset(0, (childHeight - _chart.height) / 2);
    var rect = Rect.fromPoints(_px(ids.first) + lift, _px(ids.first) + lift);
    for (final id in ids) {
      rect = rect
          .expandToInclude(Rect.fromCircle(center: _px(id) + lift, radius: 1));
    }
    rect = rect.inflate(math.max(24, 0.12 * math.max(rect.width, rect.height)));
    final s = math
        .min(box.width / rect.width, box.height / rect.height)
        .clamp(1.0, widget.maxZoom);
    final c = rect.center;
    _view.value = Matrix4.identity()
      ..translateByDouble(box.width / 2, box.height / 2, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }

  void _tap(Offset local) {
    final onTap = widget.onTapPlace;
    if (onTap == null) return;
    final reach = 16 / _zoom;
    String? best;
    var bestDistance = reach;
    TravelPlaceState? state;
    for (final id in [...widget.visited.toSet(), ...widget.known]) {
      final d = (_px(id) - local).distance;
      if (d <= bestDistance) {
        bestDistance = d;
        best = id;
        state = widget.visited.contains(id)
            ? TravelPlaceState.visited
            : TravelPlaceState.known;
      }
    }
    if (best != null && state != null) onTap(best, state);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(builder: (context, box) {
      final boxSize = Size(box.maxWidth, box.maxHeight);
      _chart =
          Size(box.maxWidth, box.maxWidth * worldMapHeight / worldMapWidth);
      final order = _order;
      if (!_framed) {
        _framed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _frameJourney(boxSize);
        });
      }
      final base = ChartMapPainter(
        frame: _frame,
        walk: _still,
        geography: widget.geography,
        palette: widget.palette,
        language: widget.language,
        discovered: const {},
        legs: const [],
        ahead: null,
        selectedId: '',
        here: null,
        walking: false,
        walkPath: const [],
        chapterFilter: 0,
        reduceMotion: reduceMotion,
        chapterColor: (_) => widget.palette.road,
        fog: widget.fog,
        zoomOf: () => _zoom,
        view: _view,
      );
      Widget button(Key key, IconData icon, String tip, VoidCallback onTap) =>
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              color: widget.palette.sea.withValues(alpha: 0.85),
              shape:
                  CircleBorder(side: BorderSide(color: widget.palette.coast)),
              child: IconButton(
                key: key,
                tooltip: tip,
                icon: Icon(icon, color: widget.palette.place),
                onPressed: onTap,
              ),
            ),
          );
      return ColoredBox(
          color: widget.palette.sea,
          child: Stack(
            children: [
              InteractiveViewer(
                key: const Key('travel_map_viewer'),
                transformationController: _view,
                minScale: 1,
                maxScale: widget.maxZoom,
                boundaryMargin: EdgeInsets.symmetric(
                    horizontal: box.maxWidth / 2, vertical: box.maxHeight / 2),
                child: SizedBox(
                  width: box.maxWidth,
                  height: math.max(box.maxHeight, _chart.height),
                  child: Center(
                    child: GestureDetector(
                      key: const Key('travel_map_canvas'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _tap(d.localPosition),
                      child: SizedBox(
                        width: _chart.width,
                        height: _chart.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(painter: base),
                            CustomPaint(
                              key: const Key('travel_map_overlay'),
                              painter: _TravelPainter(
                                view: _view,
                                chart: _chart,
                                palette: widget.palette,
                                language: widget.language,
                                geography: widget.geography,
                                visited: widget.visited,
                                order: order,
                                known: widget.known,
                                here: widget.here,
                                nameOf: widget.nameOf,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  children: [
                    if (widget.here != null)
                      button(const Key('travel_map_here'), Icons.my_location,
                          'Here', () => _centreOnHere(boxSize)),
                    button(const Key('travel_map_zoom_in'), Icons.add, '+',
                        () => _zoomBy(1.6, boxSize)),
                    button(const Key('travel_map_zoom_out'), Icons.remove, '−',
                        () => _zoomBy(1 / 1.6, boxSize)),
                  ],
                ),
              ),
            ],
          ));
    });
  }
}

/// The road taken, the marks and the names, over the chart.
class _TravelPainter extends CustomPainter {
  _TravelPainter({
    required this.view,
    required this.chart,
    required this.palette,
    required this.language,
    required this.geography,
    required this.visited,
    required this.order,
    required this.known,
    required this.here,
    required this.nameOf,
  }) : super(repaint: view);

  final TransformationController view;
  final Size chart;
  final ChartPalette palette;
  final AppLanguage language;
  final ChartGeography geography;
  final List<String> visited;
  final Map<String, int> order;
  final Set<String> known;
  final String? here;
  final String Function(String id) nameOf;

  Offset _px(String id) {
    final at = geography.places[id] ??
        const Offset(worldMapWidth / 2, worldMapHeight / 2);
    return Offset(at.dx * chart.width / worldMapWidth,
        at.dy * chart.height / worldMapHeight);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final z = view.value.getMaxScaleOnAxis();
    double u(double screen) => screen / z;

    // The road, leg by leg in the order taken: a gentle bow so a road gone
    // back along does not hide under itself, an arrow at the middle.
    final roadPaint = Paint()
      ..color = palette.road.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u(2)
      ..strokeCap = StrokeCap.round;
    final arrowPaint = Paint()..color = palette.road;
    final seen = <String>{};
    for (var i = 0; i + 1 < visited.length; i++) {
      final a = _px(visited[i]);
      final b = _px(visited[i + 1]);
      if (a == b) continue;
      final key = '${visited[i]}>${visited[i + 1]}';
      final again = !seen.add(key);
      final mid = Offset.lerp(a, b, 0.5)!;
      final along = (b - a);
      final normal = Offset(-along.dy, along.dx) / along.distance;
      final bow = normal * (along.distance * (again ? -0.16 : 0.08));
      final control = mid + bow;
      canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy),
          roadPaint);
      // The arrow where the curve is at its middle, pointing the way on.
      final at = Offset.lerp(
          Offset.lerp(a, control, 0.5)!, Offset.lerp(control, b, 0.5)!, 0.5)!;
      final tangent =
          (Offset.lerp(control, b, 0.5)! - Offset.lerp(a, control, 0.5)!);
      final angle = math.atan2(tangent.dy, tangent.dx);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      canvas.drawPath(
          Path()
            ..moveTo(u(4), 0)
            ..lineTo(-u(3), -u(3))
            ..lineTo(-u(3), u(3))
            ..close(),
          arrowPaint);
      canvas.restore();
    }

    // The marks.
    final ids = order.keys.toList();
    final markRadius = u(z >= 2.2 ? 7 : 4);
    for (final id in ids) {
      final at = _px(id);
      canvas.drawCircle(at, markRadius + u(1.5), Paint()..color = palette.sea);
      canvas.drawCircle(at, markRadius, Paint()..color = palette.road);
      if (z >= 2.2) {
        final number = _text('${order[id]}', 9, const Color(0xFF14110A), true);
        canvas.save();
        canvas.translate(at.dx, at.dy);
        canvas.scale(1 / z);
        number.paint(canvas, Offset(-number.width / 2, -number.height / 2));
        canvas.restore();
      }
    }
    final unknown = Paint()
      ..color = palette.label
      ..style = PaintingStyle.stroke
      ..strokeWidth = u(1.4);
    for (final id in known) {
      if (order.containsKey(id)) continue;
      final at = _px(id);
      canvas.drawCircle(at, u(6), Paint()..color = palette.sea);
      canvas.drawCircle(at, u(6), unknown);
      final q = _text('?', 9, palette.label, true);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(1 / z);
      q.paint(canvas, Offset(-q.width / 2, -q.height / 2));
      canvas.restore();
    }
    // Where the party is: a ring round its mark.
    if (here != null && geography.places.containsKey(here)) {
      final at = _px(here!);
      canvas.drawCircle(
          at,
          u(11),
          Paint()
            ..color = palette.mark
            ..style = PaintingStyle.stroke
            ..strokeWidth = u(2));
    }

    // The names of the places been to, each clear of the next. The latest
    // reached and the party's own place come first.
    final names = <String>[
      if (here != null && order.containsKey(here)) here!,
      for (final id in ids.reversed)
        if (id != here) id,
    ];
    final requests = <TravelLabelRequest>[];
    final painters = <String, TextPainter>{};
    for (final id in names) {
      final tp = _text(nameOf(id), 10.5, palette.place, id == here);
      painters[id] = tp;
      // Screen pixels: the chart is scaled by z on screen.
      requests.add(
          TravelLabelRequest(id, _px(id) * z, Size(tp.width + 2, tp.height)));
    }
    final bounds = Rect.fromLTWH(0, 0, chart.width * z, chart.height * z);
    final placed = placeTravelLabels(requests,
        bounds: bounds,
        markRadius: z >= 2.2 ? 8 : 5,
        obstacles: [
          for (final id in known)
            if (!order.containsKey(id)) _px(id) * z,
        ]);
    for (final entry in placed.entries) {
      final box = entry.value;
      canvas.save();
      canvas.scale(1 / z);
      // A backing so a name reads over the coast.
      canvas.drawRRect(
          RRect.fromRectAndRadius(box.inflate(1), const Radius.circular(2)),
          Paint()..color = palette.sea.withValues(alpha: 0.55));
      painters[entry.key]!.paint(canvas, box.topLeft + const Offset(1, 0));
      canvas.restore();
    }
  }

  TextPainter _text(String text, double size, Color color, bool bold) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: InkFonts.prose,
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @override
  bool shouldRepaint(_TravelPainter old) =>
      old.visited != visited ||
      old.known != known ||
      old.here != here ||
      old.geography != geography ||
      old.palette != palette ||
      old.language != language ||
      old.chart != chart;
}
