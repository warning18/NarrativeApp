// The Journey's world map (v1.199): the whole chart under the fog, zoomed
// and dragged any way with a pinch, framed on the party's land or on the
// world, with the chart's own controls and the calques over it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chart_globe.dart';
import '../data/map_charts.dart';
import '../data/world_leg_path.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/landmark_towns_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/geography_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/town_rulers_provider.dart';
import 'chart_map_painter.dart';
import 'chart_weather.dart';
import 'journey_place.dart' show RegionFlightPainter;
import 'town_handover.dart';

/// The chart the Journey's world map draws now: the story's world on the
/// sphere, else the shape picked in the map's look. A move's path
/// (worldLegPath) is laid on this chart, so the walker follows its roads.
ChartGeography journeyChartOf(WidgetRef ref) => ref.read(chartGlobeProvider)
    ? chartOf(MapShape.story)
    : chartOf(ref.read(mapShapeProvider));

/// Scales the time a move takes: 1 in the app; the tests shorten it so a
/// walk over the world chart does not make each wait longer.
double worldMoveTimeScale = 1;

/// How long a move over the world chart takes: slower than the Journey's
/// own short walks (a tap skips it), longer for a longer road.
Duration worldMoveDuration(WorldLegPath path) => Duration(
    milliseconds: ((4200 + 45 * path.length).round().clamp(6000, 13000) *
            worldMoveTimeScale)
        .round());

/// The walk's pace over a move's clock: the party stands while the camera
/// closes in and again as it pulls back out.
class _MoveWalkCurve extends Curve {
  const _MoveWalkCurve();
  @override
  double transformInternal(double t) => RegionFlightPainter.walkAt(t);
}

/// A road's corners rounded as the chart's painter rounds them (two Chaikin
/// passes), the ends kept, so the walker takes the bends and does not cut
/// them.
List<Offset> smoothedWalkPoints(List<Offset> points) {
  var pts = points;
  for (var pass = 0; pass < 2 && pts.length > 2; pass++) {
    final next = <Offset>[pts.first];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      next
        ..add(Offset.lerp(a, b, 0.25)!)
        ..add(Offset.lerp(a, b, 0.75)!);
    }
    next.add(pts.last);
    pts = next;
  }
  return pts;
}

/// How far out the Journey's map is looked at.
enum JourneyMapLevel { place, land, world }

/// The chart's zooms the Journey hands over at: the land level's, and the
/// closest, past which the streets are looked at.
abstract final class JourneyWorldMapZoom {
  static const double land = 2.8;

  /// The district step between the land and the streets (v1.350): the +
  /// and − buttons stop on it, so a district chart (Core's data) has its
  /// place on the ladder; until it lands it is a closer look at the land.
  static const double district = 5;
  static const double max = 8;

  /// The rungs the zoom buttons climb: the whole world, the land, the
  /// district, the closest (past which the streets are looked at).
  static const List<double> stops = [1, land, district, max];

  /// The rung above [zoom] (the closest at the top), or the one below.
  static double stepIn(double zoom) =>
      stops.firstWhere((s) => s > zoom * 1.04, orElse: () => max);
  static double stepOut(double zoom) =>
      stops.lastWhere((s) => s < zoom / 1.04, orElse: () => 1);
}

class JourneyWorldMap extends ConsumerStatefulWidget {
  const JourneyWorldMap({
    super.key,
    required this.level,
    required this.palette,
    required this.here,
    required this.discovered,
    required this.legs,
    required this.ahead,
    required this.shopPlaces,
    required this.campPlaces,
    required this.chapterColor,
    required this.onLayers,
    this.onSelect,
    this.onZoomIn,
    this.enterZoom,
    this.onFullMap,
    this.focus,
    this.heardOf = const {},
    this.goalId,
    this.chapterFilter = 0,
    this.replayLegs,
    this.replayToken = 0,
    this.fog = ChartFog.uncharted,
    this.move,
    this.moveClock,
  });

  /// A move to show (wave 14): the party walks (or sails) this path over the
  /// chart while the camera closes in on it and follows, then pulls back out.
  /// [moveClock] (0 to 1) is the move's time; whoever owns it (the Journey's
  /// transit) also reads it for the words over the map and skips it on a tap.
  final WorldLegPath? move;
  final Animation<double>? moveClock;

  /// The "Full map" button among the chart's controls (board 8): shown
  /// only when the Journey gives a way to open the full-screen map.
  final VoidCallback? onFullMap;

  /// Places only heard of, drawn as a "?" and tappable (the full map's
  /// sheet), and the one marked as the goal.
  final Set<String> heardOf;
  final String? goalId;

  /// One chapter picked out (0: all): its places and roads in full, the
  /// rest dimmed (the chapter chips of the full map).
  final int chapterFilter;

  /// The places to walk again (the journey so far) when [replayToken]
  /// changes: the traveller crosses the chart along the road they took.
  final List<Landmark>? replayLegs;
  final int replayToken;

  /// A place the world level opens on, marked, instead of the party's
  /// (the full map opened from the camp's "On the map").
  final Landmark? focus;

  /// The fog over what the story has not reached; none in Edit Mode
  /// (v1.209), which sees the world whole.
  final ChartFog fog;

  final JourneyMapLevel level;
  final ChartPalette palette;
  final Landmark? here;
  final Set<String> discovered;
  final List<(Landmark, Landmark)> legs;
  final Landmark? ahead;
  final Set<String> shopPlaces;
  final Set<String> campPlaces;
  final Color Function(int chapter) chapterColor;
  final VoidCallback onLayers;

  /// A reached place tapped on the chart.
  final ValueChanged<Landmark>? onSelect;

  /// Zoomed in past the chart's closest on the party's own place, or that
  /// place tapped: the streets are looked at again (v1.201).
  final VoidCallback? onZoomIn;

  /// The zoom the land level opens at (v1.201.1): where the streets were
  /// left by the pinch, from which the chart glides out to the land's
  /// own zoom; null opens at the land's zoom at once.
  final double? enterZoom;

  @override
  ConsumerState<JourneyWorldMap> createState() => _JourneyWorldMapState();
}

class _JourneyWorldMapState extends ConsumerState<JourneyWorldMap>
    with TickerProviderStateMixin {
  final TransformationController _view = TransformationController();

  /// The fog fading in as the chart opens (v1.208).
  late final AnimationController _reveal = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420))
    ..forward();

  /// The traveller walking the journey again (the replay).
  late final AnimationController _walk = AnimationController(vsync: this);
  List<(double, double)> _walkPath = const [];
  bool _walking = false;
  late final Listenable _repaint = Listenable.merge([
    _view,
    _reveal,
    _walk,
    _handoverFade,
    if (widget.moveClock != null) widget.moveClock!,
  ]);

  /// A town that changed hands since the player last looked (wave 16): its
  /// tint passes from the old ruler's colour over a second ([_handoverFade],
  /// 0 to 1; a town not in [_fadeFrom] does not fade), and a toast says so.
  late final AnimationController _handoverFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400), value: 1);
  Map<String, ({Color fill, Color accent})?> _fadeFrom = const {};

  /// Compares who rules each town with who ruled it when the world chart was
  /// last looked at (the save's seenTownRulers); the first look, an old save
  /// and a session not yet read just write down the present.
  bool _handoverQueued = false;

  /// Looks after the frame, never inside a listener: writing the save while
  /// the providers are still notifying would rebuild them twice in a frame.
  void _queueHandoverCheck() {
    if (_handoverQueued) return;
    _handoverQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handoverQueued = false;
      _watchHandovers();
    });
  }

  void _watchHandovers() {
    if (!mounted) return;
    final notifier = ref.read(playerSessionProvider.notifier);
    final rulers = ref.read(townRulersProvider);
    if (!notifier.isLoaded || rulers.isEmpty) return;
    final changed =
        townHandovers(ref.read(playerSessionProvider).seenTownRulers, rulers);
    notifier.markTownRulersSeen(townRulerIds(rulers));
    if (changed.isEmpty) return;
    final recent = ref.read(recentHandoversProvider.notifier);
    recent.state = withRecentHandovers(recent.state, changed);
    final factions = ref.read(factionsProvider);
    final colours = {
      for (final e in factions.entries) e.key: e.value.color,
    };
    final changedTowns = {for (final h in changed) h.townId: h};
    final from = <String, ({Color fill, Color accent})?>{};
    for (final e in ref.read(landmarkRulersProvider).entries) {
      final handover = changedTowns[e.value.placeId];
      if (handover == null) continue;
      final old = handoverFromColours(handover, colours);
      from[e.key] = old == null
          ? null
          : (fill: Color(old.fill), accent: Color(old.accent));
    }
    final language = ref.read(appLanguageProvider);
    final geography = ref.read(geographyProvider);
    String townName(String id) =>
        geography.places[id]?.nameFor(language == AppLanguage.fr) ?? id;
    final text = changed.length == 1
        ? changed.single.toClan.isEmpty
            ? trFor(language, 'town_handover_none')
                .replaceAll('{town}', townName(changed.single.townId))
            : trFor(language, 'town_handover_to')
                .replaceAll(
                    '{clan}',
                    factions[changed.single.toClan]?.shortFor(language) ??
                        changed.single.toClan)
                .replaceAll('{town}', townName(changed.single.townId))
        : trFor(language, 'town_handover_many')
            .replaceAll('{n}', '${changed.length}');
    setState(() => _fadeFrom = from);
    if (MediaQuery.of(context).disableAnimations) {
      _handoverFade.value = 1;
    } else {
      _handoverFade.forward(from: 0);
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(key: const Key('town_handover_toast'), content: Text(text)));
  }

  /// The move's walk over its clock, and the box the camera frames it in.
  Animation<double>? _moveWalk;
  Size _box = Size.zero;

  /// Glides the chart (or the sphere) from one zoom to another, so a
  /// button or a change of level never jumps (v1.201.1).
  late final AnimationController _glide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  Animation<Matrix4>? _glideView;
  Animation<double>? _glideRadius;
  (Animation<double>, Animation<double>)? _glideTurn;

  /// Where a running glide is headed, else the view as it stands: what
  /// the next zoom or recentre builds on, so quick taps compose.
  Matrix4? _goalView;
  Matrix4 get _settled =>
      _glide.isAnimating && _goalView != null ? _goalView! : _view.value;
  double get _settledScale => _settled.getMaxScaleOnAxis();

  void _animateTo(Matrix4 target) {
    _glide.stop();
    _glideRadius = null;
    _glideTurn = null;
    _goalView = target;
    _glideView = Matrix4Tween(begin: _view.value.clone(), end: target)
        .animate(CurvedAnimation(parent: _glide, curve: Curves.easeOutCubic));
    _glide.forward(from: 0);
  }

  void _animateRadius(double target) {
    final g = _globe;
    if (g == null) return;
    _glide.stop();
    _glideView = null;
    _glideTurn = null;
    _glideRadius = Tween<double>(begin: g.radius, end: target)
        .animate(CurvedAnimation(parent: _glide, curve: Curves.easeOutCubic));
    _glide.forward(from: 0);
  }

  void _poleTurn(ChartGeography geo, {required bool north}) {
    final g = _globe;
    if (g == null) return;
    _animateTurn(g.toPole(north: north));
  }

  /// Turns the sphere to [target]'s longitude and latitude, gliding (the
  /// pole buttons).
  void _animateTurn(GlobeView target) {
    final g = _globe;
    if (g == null) return;
    _glide.stop();
    _glideView = null;
    _glideRadius = null;
    CurvedAnimation curve() =>
        CurvedAnimation(parent: _glide, curve: Curves.easeInOutCubic);
    _glideTurn = (
      Tween<double>(begin: g.lon0, end: target.lon0).animate(curve()),
      Tween<double>(begin: g.lat0, end: target.lat0).animate(curve()),
    );
    _glide.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _queueHandoverCheck();
    _glide.addListener(() {
      final view = _glideView;
      if (view != null) _view.value = view.value;
      final radius = _glideRadius;
      final g = _globe;
      if (radius != null && g != null) {
        setState(() => _globe = g.copyWith(radius: radius.value));
      }
      final turn = _glideTurn;
      if (turn != null && g != null) {
        setState(() =>
            _globe = g.copyWith(lon0: turn.$1.value, lat0: turn.$2.value));
      }
    });
    final move = widget.move, clock = widget.moveClock;
    if (move != null && clock != null) {
      _walkPath = [
        for (final p in smoothedWalkPoints(move.points)) (p.dx, p.dy),
      ];
      _walking = true;
      _moveWalk = clock.drive(CurveTween(curve: const _MoveWalkCurve()));
      clock
        ..addListener(_followMove)
        ..addStatusListener(_moveStatus);
    }
  }

  void _moveStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && _walking) {
      setState(() => _walking = false);
    }
  }

  /// How much the camera is on the party at [t] of the move: it closes in
  /// over the first of the move, follows, and pulls out for the last.
  static double _cameraAt(double t) =>
      Curves.easeInOut.transform(math.min(1.0, math.min(t, 1 - t) / 0.18));

  /// The player took the camera during the move (a drag, a pinch, a zoom
  /// button): it stays theirs until they tap the recentre button.
  bool _cameraFree = false;

  void _takeCamera() {
    if (_walking && widget.moveClock != null && !_cameraFree) {
      setState(() => _cameraFree = true);
    }
  }

  /// Frames the party as it walks: the whole chart at the ends, the land's
  /// zoom on the party between. The sphere turns to the party instead of
  /// sliding.
  void _followMove() {
    final clock = widget.moveClock;
    if (clock == null ||
        _cameraFree ||
        _box == Size.zero ||
        _walkPath.length < 2) {
      return;
    }
    final w = _cameraAt(clock.value);
    final (x, y) =
        pointAlong(_walkPath, RegionFlightPainter.walkAt(clock.value));
    const middle = Offset(worldMapWidth / 2, worldMapHeight / 2);
    final centre = Offset.lerp(middle, Offset(x, y), w)!;
    final zoom = 1 + (_landZoom - 1) * w;
    if (ref.read(chartGlobeProvider)) {
      final geo = _geoOf(true);
      setState(() => _globe = geo.globeAt(centre, zoom, _globeCentre(_box)));
      return;
    }
    _glide.stop();
    _view.value = _framing(centre, zoom, _box);
  }

  final ValueNotifier<int> _frame = ValueNotifier(0);
  JourneyMapLevel? _framed;
  String? _framedOn;
  String? _selectedId;

  /// The sphere (v1.200): where it is turned to and how close, kept
  /// across builds; framed afresh when the level or the place changes.
  GlobeView? _globe;
  double _pinchStartZoom = 1;
  Offset? _dragLast;

  /// How far in the land level looks.
  static const double _landZoom = JourneyWorldMapZoom.land;
  static const double _maxZoom = JourneyWorldMapZoom.max;

  /// The chart the map draws: the flat map keeps the look's own chart
  /// (A, B or C, a band of the globe); the sphere wears the story world,
  /// which covers the whole of it, poles and all (board 11).
  ChartGeography _geoOf(bool sphere) =>
      sphere ? chartOf(MapShape.story) : chartOf(ref.read(mapShapeProvider));

  /// The most chart units to canvas pixels the sphere is drawn at: on a big
  /// screen the ball stops growing here.
  static const double sphereMaxScale = 3.6;

  /// Chart units to canvas pixels for the sphere in [box]: the ball at the
  /// first zoom fills the box's short side (v1.350; it was a 250 px ball,
  /// small on a phone).
  double _sphereK(Size box) => math.min(
      box.shortestSide * 0.9 / (2 * GlobeView.baseRadius), sphereMaxScale);

  /// How close a place asked for is framed.
  static const double _focusZoom = 2.4;

  @override
  void didUpdateWidget(JourneyWorldMap old) {
    super.didUpdateWidget(old);
    final legs = widget.replayLegs;
    if (widget.replayToken != old.replayToken &&
        legs != null &&
        legs.length >= 2 &&
        !MediaQuery.of(context).disableAnimations) {
      final geo = _geoOf(ref.read(chartGlobeProvider));
      _walkPath = [for (final l in legs) ChartMapPainter.spotOn(geo, l)];
      final perLeg = math.min(300, 9000 ~/ (legs.length - 1));
      _walk.duration = Duration(milliseconds: perLeg * (legs.length - 1));
      setState(() => _walking = true);
      _walk.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _walking = false);
      });
    }
  }

  @override
  void dispose() {
    widget.moveClock
      ?..removeListener(_followMove)
      ..removeStatusListener(_moveStatus);
    _walk.dispose();
    _glide.dispose();
    _view.dispose();
    _frame.dispose();
    _reveal.dispose();
    _handoverFade.dispose();
    super.dispose();
  }

  double get _scale => _view.value.getMaxScaleOnAxis();

  static Matrix4 _matrix(double scale, double tx, double ty) =>
      Matrix4.identity()
        ..setEntry(0, 0, scale)
        ..setEntry(1, 1, scale)
        ..setEntry(0, 3, tx)
        ..setEntry(1, 3, ty);

  /// The chart's size in the box's width.
  Size _size = Size.zero;

  /// How tall the viewer's child is: the box at least, the chart centred
  /// in it when the box is taller.
  double _childHeight = 0;

  /// Where [chart] (in the chart's units) lies on the viewer's child.
  Offset _onMap(Offset chart) =>
      chart * (_size.width / worldMapWidth) +
      Offset(0, math.max(0, (_childHeight - _size.height) / 2));

  /// Frames [chart] (in the chart's units) at [scale] in the box.
  void _look(Offset chart, double scale, Size box) {
    _glide.stop();
    _view.value = _framing(chart, scale, box);
  }

  /// The matrix that frames [chart] at [scale] in the box.
  Matrix4 _framing(Offset chart, double scale, Size box) {
    final at = _onMap(chart);
    return _matrix(
        scale, box.width / 2 - at.dx * scale, box.height / 2 - at.dy * scale);
  }

  void _frameFor(Size box) {
    final geo = _geoOf(ref.read(chartGlobeProvider));
    final here = widget.here;
    final focus = widget.focus;
    // The sphere and the flat chart are different charts (the sphere wears
    // the story world): turning from one to the other frames afresh.
    final on = '${widget.level.name}:${here?.id}:${focus?.id}:'
        '${box.width.round()}:${ref.read(chartGlobeProvider)}';
    if (_framed == widget.level && _framedOn == on) return;
    _framed = widget.level;
    _framedOn = on;
    final centre = _globeCentre(box);
    if (widget.level == JourneyMapLevel.land && here != null) {
      // Opened where the streets were left, the chart glides out to the
      // land's own zoom.
      final from = (widget.enterZoom ?? _landZoom).clamp(_landZoom, _maxZoom);
      // Only the view shown glides; the other waits at the land's zoom.
      final sphere = ref.read(chartGlobeProvider);
      _look(geo.of(here), sphere ? _landZoom : from, box);
      _globe = geo.globeAt(geo.of(here), sphere ? from : _landZoom, centre);
      if (from != _landZoom) {
        final at = _onMap(geo.of(here));
        final target = _matrix(_landZoom, box.width / 2 - at.dx * _landZoom,
            box.height / 2 - at.dy * _landZoom);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (sphere) {
            _animateRadius(GlobeView.baseRadius * _landZoom);
          } else {
            _animateTo(target);
          }
        });
      }
    } else if (focus != null) {
      // Opened on a place asked for: framed close on it, and marked.
      _selectedId = focus.id;
      _look(geo.of(focus), _focusZoom, box);
      _globe = geo.globeAt(geo.of(focus), _focusZoom, centre);
    } else {
      _view.value = Matrix4.identity();
      _globe = geo.globeAt(
          here == null
              ? const Offset(worldMapWidth / 2, worldMapHeight / 2)
              : geo.of(here),
          1,
          centre);
    }
  }

  /// The globe's centre in the chart's units: the middle of the box.
  Offset _globeCentre(Size box) {
    final k = _sphereK(box);
    return Offset(box.width / k / 2, box.height / k / 2);
  }

  /// A pinch or drag on the sphere: it turns, or comes closer.
  void _onGlobeScaleStart(ScaleStartDetails d) {
    _takeCamera();
    _pinchStartZoom = _globe?.zoom ?? 1;
    _dragLast = d.focalPoint;
  }

  void _onGlobeScaleUpdate(ScaleUpdateDetails d, Size box) {
    final g = _globe;
    if (g == null) return;
    final k = _sphereK(box);
    var next = g;
    if (d.pointerCount > 1) {
      next = next.copyWith(
          radius: GlobeView.baseRadius *
              (_pinchStartZoom * d.scale).clamp(1.0, _maxZoom));
    }
    final last = _dragLast;
    if (last != null) {
      final delta = (d.focalPoint - last) / k;
      next = next.turned(-delta.dx / next.radius, delta.dy / next.radius);
    }
    _dragLast = d.focalPoint;
    setState(() => _globe = next);
  }

  void _globeZoom(double factor) {
    final g = _globe;
    if (g == null) return;
    if (factor > 1 && _intoPlace(Size.zero, sphere: true)) return;
    _animateRadius(GlobeView.baseRadius *
        (factor > 1
                ? JourneyWorldMapZoom.stepIn(g.zoom)
                : JourneyWorldMapZoom.stepOut(g.zoom))
            .clamp(1.0, _maxZoom));
  }

  void _globeTap(Offset position, Size box) {
    final g = _globe;
    if (g == null) return;
    final k = _sphereK(box);
    final chart = g.chartAt(position / k);
    if (chart == null) return;
    final geo = _geoOf(ref.read(chartGlobeProvider));
    Landmark? nearest;
    final reach = 22 / (k * g.zoom);
    var best = reach * reach;
    for (final landmark in worldMapLandmarks) {
      if (!widget.discovered.contains(landmark.id) &&
          !widget.heardOf.contains(landmark.id)) {
        continue;
      }
      final d = (geo.of(landmark) - chart).distanceSquared;
      if (d <= best) {
        best = d;
        nearest = landmark;
      }
    }
    if (nearest == null) return;
    if (nearest.id == widget.here?.id && widget.onZoomIn != null) {
      widget.onZoomIn!();
      return;
    }
    setState(() => _selectedId = nearest!.id);
    widget.onSelect?.call(nearest);
  }

  /// Whether the party's place is within the box at the current view.
  bool _hereShown(Size box) {
    final here = widget.here;
    if (here == null) return false;
    final geo = _geoOf(ref.read(chartGlobeProvider));
    final at = MatrixUtils.transformPoint(_settled, _onMap(geo.of(here)));
    return at.dx >= 0 &&
        at.dy >= 0 &&
        at.dx <= box.width &&
        at.dy <= box.height;
  }

  /// Past the closest zoom with the party's place in view, the streets.
  bool _intoPlace(Size box, {required bool sphere}) {
    if (widget.onZoomIn == null) return false;
    final atMax = sphere
        ? (_globe?.zoom ?? 1) >= _maxZoom - 0.01
        : _settledScale >= _maxZoom - 0.01;
    if (!atMax) return false;
    if (!sphere && !_hereShown(box)) return false;
    widget.onZoomIn!();
    return true;
  }

  void _zoom(double factor, Size box) {
    if (factor > 1 && _intoPlace(box, sphere: false)) return;
    final centre = Offset(box.width / 2, box.height / 2);
    final target = (factor > 1
            ? JourneyWorldMapZoom.stepIn(_settledScale)
            : JourneyWorldMapZoom.stepOut(_settledScale))
        .clamp(1.0, _maxZoom);
    final inverse = Matrix4.inverted(_settled);
    final at = MatrixUtils.transformPoint(inverse, centre);
    _animateTo(_matrix(
        target, centre.dx - at.dx * target, centre.dy - at.dy * target));
  }

  void _tapAt(Offset position) {
    final geo = _geoOf(ref.read(chartGlobeProvider));
    final k = _size.width / worldMapWidth;
    final at = Offset(position.dx / k, position.dy / k);
    // The tap is on the chart itself (the GestureDetector wraps it).
    Landmark? nearest;
    // A marker is hit within 22 px of it on the screen (44 across), however
    // close the chart is looked at.
    final reach = 22 / (k * _scale);
    var best = reach * reach;
    for (final landmark in worldMapLandmarks) {
      if (!widget.discovered.contains(landmark.id) &&
          !widget.heardOf.contains(landmark.id)) {
        continue;
      }
      final d = (geo.of(landmark) - at).distanceSquared;
      if (d <= best) {
        best = d;
        nearest = landmark;
      }
    }
    if (nearest == null) return;
    if (nearest.id == widget.here?.id && widget.onZoomIn != null) {
      widget.onZoomIn!();
      return;
    }
    setState(() => _selectedId = nearest!.id);
    widget.onSelect?.call(nearest);
  }

  /// A pinch that ends at the closest zoom on the party's place.
  double _pinchFrom = 1;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final sphere = ref.watch(chartGlobeProvider);
    final geo = _geoOf(sphere);
    final calque = ref.watch(chartCalqueProvider);
    final factions = ref.watch(factionsProvider);
    final politics = ref.watch(politicsProvider);
    final clanData = ref.watch(clanDataProvider);
    final clanColours = {
      for (final e in factions.entries) e.key: Color(e.value.patron.color),
    };
    final standings = {
      for (final id in factions.keys) id: politics.standingOf(id, clanData),
    };
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final theme = Theme.of(context);
    // The weather over the chart (v1.204), on its own layer.
    final weatherOn = ref.watch(chartWeatherProvider);
    final weatherWorldOnly = ref.watch(chartWeatherWorldOnlyProvider);
    final day = ref.watch(playerSessionProvider.select((s) => s.day));
    // The first look, a session read late, or a town changing hands while
    // the chart is up: see who rules what against what was seen.
    ref.listen(townRulersProvider, (_, __) => _queueHandoverCheck());
    ref.listen(playerSessionProvider.select((s) => s.seenTownRulers),
        (_, __) => _queueHandoverCheck());
    // The ruling clan's tint under each town (wave 15).
    final townTints = {
      for (final e in ref.watch(landmarkRulersProvider).entries)
        e.key: (fill: Color(e.value.color), accent: Color(e.value.accent)),
    };
    return LayoutBuilder(builder: (context, box) {
      final boxSize = Size(box.maxWidth, box.maxHeight);
      // The chart fills the box's width; a tall box shows sea above and
      // below it, a wide one is scrolled.
      _size = Size(box.maxWidth, box.maxWidth * worldMapHeight / worldMapWidth);
      _childHeight = math.max(box.maxHeight, _size.height);
      _box = boxSize;
      _frameFor(boxSize);
      ChartMapPainter painter(GlobeView? globe) => ChartMapPainter(
            frame: _frame,
            walk: _moveWalk ?? _walk,
            geography: geo,
            palette: widget.palette,
            language: language,
            discovered: widget.discovered,
            legs: widget.legs,
            ahead: widget.ahead,
            selectedId: _selectedId ?? '',
            here: widget.here,
            walking: _walking,
            walkPath: _walkPath,
            chapterFilter: widget.chapterFilter,
            reduceMotion: true,
            chapterColor:
                calque == ChartCalque.chapters || calque == ChartCalque.none
                    ? widget.chapterColor
                    : (_) => widget.palette.road,
            fog: widget.fog,
            calque: calque,
            clanColours: clanColours,
            standingOf: standings,
            shopPlaces: widget.shopPlaces,
            campPlaces: widget.campPlaces,
            townTints: townTints,
            townTintsFrom: _fadeFrom,
            townFade: _handoverFade,
            heardOf: widget.heardOf,
            goalId: widget.goalId,
            globe: globe,
            sphereScale: globe == null ? null : _sphereK(boxSize),
            zoomOf: () => globe?.zoom ?? _scale,
            fogOf: () => _reveal.value,
            view: _repaint,
          );
      // The sphere: the whole box is its sky; a drag turns it, a pinch
      // brings it close, a tap picks a place on it.
      final globeView = _globe?.copyWith(centre: _globeCentre(boxSize));
      final sphereChart = GestureDetector(
        key: const ValueKey('journey_globe_canvas'),
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onGlobeScaleStart,
        onScaleUpdate: (d) => _onGlobeScaleUpdate(d, boxSize),
        onScaleEnd: (_) {
          _dragLast = null;
          if ((_globe?.zoom ?? 1) > _pinchStartZoom) {
            _intoPlace(boxSize, sphere: true);
          }
        },
        onTapUp: (d) => _globeTap(d.localPosition, boxSize),
        child: SizedBox(
          width: boxSize.width,
          height: boxSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: painter(globeView)),
              if (weatherOn)
                ChartWeather(
                  size: boxSize,
                  geography: geo,
                  palette: widget.palette,
                  day: day,
                  globe: globeView,
                  sphereScale: _sphereK(boxSize),
                  showOf: () =>
                      !weatherWorldOnly ||
                      (globeView?.zoom ?? 1) < JourneyWorldMapZoom.land,
                ),
            ],
          ),
        ),
      );
      final chart = InteractiveViewer(
        key: const ValueKey('journey_world_viewer'),
        transformationController: _view,
        minScale: 1,
        maxScale: _maxZoom,
        onInteractionStart: (_) {
          _takeCamera();
          _glide.stop();
          _pinchFrom = _scale;
        },
        onInteractionEnd: (_) {
          if (_scale > _pinchFrom) _intoPlace(boxSize, sphere: false);
        },
        boundaryMargin: EdgeInsets.symmetric(
            horizontal: box.maxWidth, vertical: box.maxHeight),
        child: SizedBox(
          width: box.maxWidth,
          height: math.max(box.maxHeight, _size.height),
          child: Center(
            child: GestureDetector(
              key: const ValueKey('journey_world_canvas'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _tapAt(details.localPosition),
              child: SizedBox(
                width: _size.width,
                height: _size.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: painter(null)),
                    if (weatherOn)
                      ChartWeather(
                        size: _size,
                        geography: geo,
                        palette: widget.palette,
                        day: day,
                        showOf: () =>
                            !weatherWorldOnly ||
                            _scale < JourneyWorldMapZoom.land,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      Widget button(String key, IconData icon, String tip, VoidCallback? onTap,
          {bool on = false}) {
        return Tooltip(
          message: tip,
          child: Material(
            color: widget.palette.land.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: on ? widget.palette.mark : widget.palette.coast,
                  width: 2),
            ),
            child: InkWell(
              key: Key(key),
              onTap: onTap,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(icon,
                    size: 20,
                    color: on ? widget.palette.mark : widget.palette.place),
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
                color: sphere ? widget.palette.fog : widget.palette.sea,
                child: sphere ? sphereChart : chart),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Column(
              children: [
                button('journey_layers', Icons.layers_outlined,
                    tr(ref, 'journey_calques'), widget.onLayers,
                    on: calque != ChartCalque.none),
                const SizedBox(height: 6),
                if (widget.onFullMap != null) ...[
                  button('journey_full_map', Icons.fullscreen,
                      tr(ref, 'map_full_open'), widget.onFullMap),
                  const SizedBox(height: 6),
                ],
                button('journey_recentre', Icons.my_location,
                    tr(ref, 'journey_recentre'), () {
                  // Mid-move, the button gives the camera back to the party.
                  if (_cameraFree && _walking) {
                    setState(() => _cameraFree = false);
                    _followMove();
                    return;
                  }
                  final here = widget.here;
                  if (here == null) return;
                  // Glides back to the party (v1.201.1).
                  if (sphere) {
                    setState(() => _globe = geo.globeAt(
                        geo.of(here),
                        math.max(_globe?.zoom ?? 1, _landZoom),
                        _globeCentre(boxSize)));
                  } else {
                    _animateTo(_framing(geo.of(here),
                        math.max(_settledScale, _landZoom), boxSize));
                  }
                }, on: _cameraFree && _walking),
                const SizedBox(height: 6),
                // The poles (board 11): the sphere turns right over either,
                // and the view comes round past the seam.
                if (sphere && geo.wholeSphere) ...[
                  button('journey_pole_north', Icons.keyboard_double_arrow_up,
                      tr(ref, 'world_map_pole_north'), () {
                    _takeCamera();
                    _poleTurn(geo, north: true);
                  }),
                  const SizedBox(height: 6),
                  button('journey_pole_south', Icons.keyboard_double_arrow_down,
                      tr(ref, 'world_map_pole_south'), () {
                    _takeCamera();
                    _poleTurn(geo, north: false);
                  }),
                  const SizedBox(height: 6),
                ],
                button(
                    'journey_zoom_in', Icons.add, tr(ref, 'world_map_zoom_in'),
                    () {
                  _takeCamera();
                  sphere ? _globeZoom(1.5) : _zoom(1.5, boxSize);
                }),
                const SizedBox(height: 6),
                button('journey_zoom_out', Icons.remove,
                    tr(ref, 'world_map_zoom_out'), () {
                  _takeCamera();
                  sphere ? _globeZoom(1 / 1.5) : _zoom(1 / 1.5, boxSize);
                }),
              ],
            ),
          ),
          if (calque == ChartCalque.clans)
            Positioned(
              left: 8,
              bottom: 8,
              child: _ClanLegend(
                  colours: clanColours,
                  names: {
                    for (final e in factions.entries)
                      e.key: language == AppLanguage.fr
                          ? e.value.shortFr
                          : e.value.short,
                  },
                  palette: widget.palette,
                  theme: theme,
                  contested: tr(ref, 'calque_contested'),
                  reduceMotion: reduceMotion),
            ),
        ],
      );
    });
  }
}

class _ClanLegend extends StatelessWidget {
  const _ClanLegend({
    required this.colours,
    required this.names,
    required this.palette,
    required this.theme,
    required this.contested,
    required this.reduceMotion,
  });

  final Map<String, Color> colours;
  final Map<String, String> names;
  final ChartPalette palette;
  final ThemeData theme;
  final String contested;
  final bool reduceMotion;

  static const _shown = [
    'dominion', 'crows', 'compact', 'mire', 'penitents', 'vigil', //
  ];

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(color: palette.place);
    return Container(
      key: const ValueKey('journey_clan_legend'),
      width: 236,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.land.withValues(alpha: 0.9),
        border: Border.all(color: palette.coast),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final id in _shown)
            if (colours[id] case final colour?)
              _swatch(colour, names[id] ?? id, style),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    colours['compact'] ?? palette.label,
                    colours['dominion'] ?? palette.label,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(contested, style: style),
          ]),
        ],
      ),
    );
  }

  Widget _swatch(Color colour, String name, TextStyle? style) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(name, style: style),
      ]);
}
