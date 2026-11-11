// The Journey's world map: the story's world as a sphere under the fog. It
// opens filling its box, turned to the party; a drag turns it, a pinch or
// the + and − buttons bring it closer or show it whole. The chart's own
// controls and the calques sit over it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chart_globe.dart';
import '../data/map_charts.dart';
import '../data/region_holders.dart' show chartZoneHolders;
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
import '../theme/icon_sizes.dart';

/// The chart the Journey's world map draws: the story's world, on the
/// sphere. A move's path (worldLegPath) is laid on this chart, so the
/// walker follows its roads.
ChartGeography journeyChartOf(WidgetRef ref) => chartOf(MapShape.story);

/// For tests: how the sphere of the world map at [element] is looked at now
/// (where it is turned, how close).
@visibleForTesting
GlobeView? journeyGlobeOf(Element element) {
  final state = (element as StatefulElement).state;
  return state is _JourneyWorldMapState ? state._globe : null;
}

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

/// The sphere's zooms: the whole ball, the zoom that fills the map's box
/// (it depends on the box, see [fillFor]), the district's, and the closest,
/// past which the streets are looked at.
abstract final class JourneyWorldMapZoom {
  /// How close a move over the world is followed.
  static const double land = 2.8;

  /// The district step between the land and the streets (v1.350): the +
  /// and − buttons stop on it, so a district chart (Core's data) has its
  /// place on the ladder; until it lands it is a closer look at the land.
  static const double district = 5;
  static const double max = 8;

  /// The most the filling zoom may be: it stays a rung under the district.
  static const double fillMax = 4;

  /// The zoom at which the ball covers a box of [box] pixels, corners
  /// included: its diameter is the box's diagonal. [ballAtOne] is the ball's
  /// diameter in pixels at zoom 1.
  static double fillFor(Size box, double ballAtOne) => ballAtOne <= 0
      ? 1
      : (Offset(box.width, box.height).distance / ballAtOne)
          .clamp(1.0, fillMax);

  /// The rungs the zoom buttons climb: the whole ball, the ball filling
  /// the box ([fill]), the district, the closest (past which the streets
  /// are looked at).
  static List<double> stopsFor(double fill) => [1, fill, district, max];

  /// The rung above [zoom] (the closest at the top), or the one below.
  static double stepIn(double zoom, double fill) =>
      stopsFor(fill).firstWhere((s) => s > zoom * 1.04, orElse: () => max);
  static double stepOut(double zoom, double fill) =>
      stopsFor(fill).lastWhere((s) => s < zoom / 1.04, orElse: () => 1);
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
  /// left by the pinch, from which the ball glides out to the zoom that
  /// fills the box; null opens at that zoom at once.
  final double? enterZoom;

  @override
  ConsumerState<JourneyWorldMap> createState() => _JourneyWorldMapState();
}

class _JourneyWorldMapState extends ConsumerState<JourneyWorldMap>
    with TickerProviderStateMixin {
  /// The traveller walking the journey again (the replay).
  late final AnimationController _walk = AnimationController(vsync: this);
  List<(double, double)> _walkPath = const [];
  bool _walking = false;
  late final Listenable _repaint = Listenable.merge([
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

  /// Glides the sphere from one zoom or turn to another, so a button or a
  /// change of level never jumps (v1.201.1).
  late final AnimationController _glide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  Animation<double>? _glideRadius;
  (Animation<double>, Animation<double>)? _glideTurn;

  /// Where a running glide is headed, else the zoom as it stands: what the
  /// next press of + or − builds on, so quick taps compose.
  double? _goalZoom;
  double get _settledZoom => _glide.isAnimating && _goalZoom != null
      ? _goalZoom!
      : (_globe?.zoom ?? 1);

  /// Glides the ball to [zoom], and round to [turnTo] when given (by the
  /// short way), in one move.
  void _animateGlobe({double? zoom, GlobeView? turnTo}) {
    final g = _globe;
    if (g == null) return;
    final from = _settledZoom;
    _glide.stop();
    _goalZoom = zoom ?? from;
    CurvedAnimation curve() =>
        CurvedAnimation(parent: _glide, curve: Curves.easeOutCubic);
    _glideRadius = zoom == null
        ? null
        : Tween<double>(begin: g.radius, end: GlobeView.baseRadius * zoom)
            .animate(curve());
    if (turnTo == null) {
      _glideTurn = null;
    } else {
      var dlon = (turnTo.lon0 - g.lon0) % (2 * math.pi);
      if (dlon > math.pi) dlon -= 2 * math.pi;
      _glideTurn = (
        Tween<double>(begin: g.lon0, end: g.lon0 + dlon).animate(curve()),
        Tween<double>(begin: g.lat0, end: turnTo.lat0).animate(curve()),
      );
    }
    _glide.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _queueHandoverCheck();
    _glide.addListener(() {
      final g = _globe;
      if (g == null) return;
      final radius = _glideRadius, turn = _glideTurn;
      if (radius == null && turn == null) return;
      setState(() => _globe = g.copyWith(
          radius: radius?.value, lon0: turn?.$1.value, lat0: turn?.$2.value));
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

  /// Frames the party as it walks: the whole ball at the ends, the land's
  /// zoom on the party between; the ball turns with the party.
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
    _glide.stop();
    setState(() => _globe = _geo.globeAt(centre, zoom, _globeCentre(_box)));
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

  /// How close a move is followed.
  static const double _landZoom = JourneyWorldMapZoom.land;
  static const double _maxZoom = JourneyWorldMapZoom.max;

  /// The chart the map draws: the story world, which covers the whole of
  /// the sphere, poles and all (board 11).
  ChartGeography get _geo => chartOf(MapShape.story);

  /// The most chart units to canvas pixels the sphere is drawn at: on a big
  /// screen the ball stops growing here.
  static const double sphereMaxScale = 3.6;

  /// Chart units to canvas pixels for the sphere in [box]: the ball at the
  /// first zoom fills the box's short side (v1.350; it was a 250 px ball,
  /// small on a phone).
  double _sphereK(Size box) => math.min(
      box.shortestSide * 0.9 / (2 * GlobeView.baseRadius), sphereMaxScale);

  /// The zoom at which the ball fills [box], corners included: what the
  /// world opens at, on the party.
  double _fillZoom(Size box) => JourneyWorldMapZoom.fillFor(
      box, 2 * GlobeView.baseRadius * _sphereK(box));

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
      _walkPath = [for (final l in legs) ChartMapPainter.spotOn(_geo, l)];
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
    _frame.dispose();
    _handoverFade.dispose();
    super.dispose();
  }

  void _frameFor(Size box) {
    final geo = _geo;
    final here = widget.here;
    final focus = widget.focus;
    final on = '${widget.level.name}:${here?.id}:${focus?.id}:'
        '${box.width.round()}x${box.height.round()}';
    if (_framed == widget.level && _framedOn == on) return;
    _framed = widget.level;
    _framedOn = on;
    final centre = _globeCentre(box);
    final fill = _fillZoom(box);
    if (widget.level == JourneyMapLevel.land && here != null) {
      // Opened where the streets were left, the ball glides out to the
      // zoom that fills the box.
      final from = (widget.enterZoom ?? fill).clamp(fill, _maxZoom);
      _globe = geo.globeAt(geo.of(here), from, centre);
      if (from != fill) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateGlobe(zoom: fill);
        });
      }
    } else if (focus != null) {
      // Opened on a place asked for: framed close on it, and marked.
      _selectedId = focus.id;
      _globe = geo.globeAt(geo.of(focus), math.max(_focusZoom, fill), centre);
    } else if (here != null) {
      // The world: the ball fills the box, turned to the party.
      _globe = geo.globeAt(geo.of(here), fill, centre);
    } else {
      _globe = geo.globeAt(
          const Offset(worldMapWidth / 2, worldMapHeight / 2), 1, centre);
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
    _glide.stop();
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

  /// The + and − buttons: one rung closer, the ball turning to the party
  /// (wherever it was turned), or one rung out.
  void _globeZoom(double factor) {
    final g = _globe;
    if (g == null) return;
    final fill = _fillZoom(_box);
    final zoom = _settledZoom;
    if (factor < 1) {
      _animateGlobe(zoom: JourneyWorldMapZoom.stepOut(zoom, fill));
      return;
    }
    if (_intoPlace()) return;
    final here = widget.here;
    _animateGlobe(
        zoom: JourneyWorldMapZoom.stepIn(zoom, fill),
        turnTo: here == null || (_walking && widget.moveClock != null)
            ? null
            : _geo.globeAt(_geo.of(here), 1, g.centre));
  }

  void _globeTap(Offset position, Size box) {
    final g = _globe;
    if (g == null) return;
    final k = _sphereK(box);
    final chart = g.chartAt(position / k);
    if (chart == null) return;
    final geo = _geo;
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

  /// Past the closest zoom, the streets.
  bool _intoPlace() {
    if (widget.onZoomIn == null) return false;
    if (_settledZoom < _maxZoom - 0.01) return false;
    widget.onZoomIn!();
    return true;
  }

  /// The side of a map button: a thumb's width.
  static const double _buttonSize = 44;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final geo = _geo;
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
      _box = boxSize;
      _frameFor(boxSize);
      ChartMapPainter painter(GlobeView globe) => ChartMapPainter(
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
            zoneHolders: calque == ChartCalque.clans
                ? chartZoneHolders(geo, ref.watch(geographyProvider), politics)
                : null,
            standingOf: standings,
            shopPlaces: widget.shopPlaces,
            campPlaces: widget.campPlaces,
            townTints: townTints,
            townTintsFrom: _fadeFrom,
            townFade: _handoverFade,
            heardOf: widget.heardOf,
            goalId: widget.goalId,
            globe: globe,
            sphereScale: _sphereK(boxSize),
            // Names stop short of the button column on the right.
            labelInsetRight: _buttonSize + 12,
            zoomOf: () => globe.zoom,
            view: _repaint,
          );
      // The sphere: the whole box is its sky; a drag turns it, a pinch
      // brings it close, a tap picks a place on it.
      final globeView = _globe!.copyWith(centre: _globeCentre(boxSize));
      final sphereChart = GestureDetector(
        key: const ValueKey('journey_globe_canvas'),
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onGlobeScaleStart,
        onScaleUpdate: (d) => _onGlobeScaleUpdate(d, boxSize),
        onScaleEnd: (_) {
          _dragLast = null;
          if ((_globe?.zoom ?? 1) > _pinchStartZoom) _intoPlace();
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
                      globeView.zoom < JourneyWorldMapZoom.land,
                ),
            ],
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
                width: _buttonSize,
                height: _buttonSize,
                child: Icon(icon,
                    size: IconSize.s16,
                    color: on ? widget.palette.mark : widget.palette.place),
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: widget.palette.fog, child: sphereChart),
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
                  final g = _globe;
                  if (here == null || g == null) return;
                  // Glides back to the party (v1.201.1), no further out
                  // than the zoom that fills the box.
                  _animateGlobe(
                      zoom: math.max(g.zoom, _fillZoom(boxSize)),
                      turnTo: geo.globeAt(geo.of(here), 1, g.centre));
                }, on: _cameraFree && _walking),
                const SizedBox(height: 6),
                button(
                    'journey_zoom_in', Icons.add, tr(ref, 'world_map_zoom_in'),
                    () {
                  _takeCamera();
                  _globeZoom(1.5);
                }),
                const SizedBox(height: 6),
                button('journey_zoom_out', Icons.remove,
                    tr(ref, 'world_map_zoom_out'), () {
                  _takeCamera();
                  _globeZoom(1 / 1.5);
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
