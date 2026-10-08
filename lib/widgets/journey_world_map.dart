// The Journey's world map (v1.199): the whole chart under the fog, zoomed
// and dragged any way with a pinch, framed on the party's land or on the
// world, with the chart's own controls and the calques over it.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chart_globe.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import 'chart_map_painter.dart';
import 'chart_weather.dart';

/// How far out the Journey's map is looked at.
enum JourneyMapLevel { place, land, world }

/// The chart's zooms the Journey hands over at: the land level's, and the
/// closest, past which the streets are looked at.
abstract final class JourneyWorldMapZoom {
  static const double land = 2.8;
  static const double max = 8;
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
  });

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
    with SingleTickerProviderStateMixin {
  final TransformationController _view = TransformationController();

  /// Glides the chart (or the sphere) from one zoom to another, so a
  /// button or a change of level never jumps (v1.201.1).
  late final AnimationController _glide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  Animation<Matrix4>? _glideView;
  Animation<double>? _glideRadius;

  /// Where a running glide is headed, else the view as it stands: what
  /// the next zoom or recentre builds on, so quick taps compose.
  Matrix4? _goalView;
  Matrix4 get _settled =>
      _glide.isAnimating && _goalView != null ? _goalView! : _view.value;
  double get _settledScale => _settled.getMaxScaleOnAxis();

  void _animateTo(Matrix4 target) {
    _glide.stop();
    _glideRadius = null;
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
    _glideRadius = Tween<double>(begin: g.radius, end: target)
        .animate(CurvedAnimation(parent: _glide, curve: Curves.easeOutCubic));
    _glide.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _glide.addListener(() {
      final view = _glideView;
      if (view != null) _view.value = view.value;
      final radius = _glideRadius;
      final g = _globe;
      if (radius != null && g != null) {
        setState(() => _globe = g.copyWith(radius: radius.value));
      }
    });
  }

  final ValueNotifier<int> _frame = ValueNotifier(0);
  static const _still = AlwaysStoppedAnimation<double>(0);
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

  @override
  void dispose() {
    _glide.dispose();
    _view.dispose();
    _frame.dispose();
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
    final geo = chartOf(ref.read(mapShapeProvider));
    final here = widget.here;
    final on = '${widget.level.name}:${here?.id}:${box.width.round()}';
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
      _globe = GlobeView.at(geo.of(here), sphere ? from : _landZoom, centre);
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
    } else {
      _view.value = Matrix4.identity();
      _globe = GlobeView.at(
          here == null
              ? const Offset(worldMapWidth / 2, worldMapHeight / 2)
              : geo.of(here),
          1,
          centre);
    }
  }

  /// The globe's centre in the chart's units: the middle of the box.
  Offset _globeCentre(Size box) {
    final k = box.width / worldMapWidth;
    return Offset(worldMapWidth / 2, box.height / k / 2);
  }

  /// A pinch or drag on the sphere: it turns, or comes closer.
  void _onGlobeScaleStart(ScaleStartDetails d) {
    _pinchStartZoom = _globe?.zoom ?? 1;
    _dragLast = d.focalPoint;
  }

  void _onGlobeScaleUpdate(ScaleUpdateDetails d, Size box) {
    final g = _globe;
    if (g == null) return;
    final k = box.width / worldMapWidth;
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
    _animateRadius(
        GlobeView.baseRadius * (g.zoom * factor).clamp(1.0, _maxZoom));
  }

  void _globeTap(Offset position, Size box) {
    final g = _globe;
    if (g == null) return;
    final k = box.width / worldMapWidth;
    final chart = g.chartAt(position / k);
    if (chart == null) return;
    final geo = chartOf(ref.read(mapShapeProvider));
    Landmark? nearest;
    var best = 12.0 * 12.0 / (g.zoom * g.zoom);
    for (final landmark in worldMapLandmarks) {
      if (!widget.discovered.contains(landmark.id)) continue;
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
    final geo = chartOf(ref.read(mapShapeProvider));
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
    final target = (_settledScale * factor).clamp(1.0, _maxZoom);
    final inverse = Matrix4.inverted(_settled);
    final at = MatrixUtils.transformPoint(inverse, centre);
    _animateTo(_matrix(
        target, centre.dx - at.dx * target, centre.dy - at.dy * target));
  }

  void _tapAt(Offset position) {
    final geo = chartOf(ref.read(mapShapeProvider));
    final k = _size.width / worldMapWidth;
    final at = Offset(position.dx / k, position.dy / k);
    // The tap is on the chart itself (the GestureDetector wraps it).
    Landmark? nearest;
    var best = 12.0 * 12.0;
    for (final landmark in worldMapLandmarks) {
      if (!widget.discovered.contains(landmark.id)) continue;
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

  /// The part of the flat chart in the box, in chart units: what the
  /// weather is painted over.
  Rect _visibleChart(Size box) {
    const whole =
        Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0);
    final inverse = Matrix4.tryInvert(_view.value);
    if (inverse == null) return whole;
    final r = MatrixUtils.transformRect(inverse, Offset.zero & box);
    final dy = (_childHeight - _size.height) / 2;
    final k = _size.width / worldMapWidth;
    return Rect.fromLTRB(
        r.left / k, (r.top - dy) / k, r.right / k, (r.bottom - dy) / k);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final geo = chartOf(ref.watch(mapShapeProvider));
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
    final sphere = ref.watch(chartGlobeProvider);
    // The weather over the chart (v1.204), on its own layer.
    final weatherOn = ref.watch(chartWeatherProvider);
    final day = ref.watch(playerSessionProvider.select((s) => s.day));
    return LayoutBuilder(builder: (context, box) {
      final boxSize = Size(box.maxWidth, box.maxHeight);
      // The chart fills the box's width; a tall box shows sea above and
      // below it, a wide one is scrolled.
      _size = Size(box.maxWidth, box.maxWidth * worldMapHeight / worldMapWidth);
      _childHeight = math.max(box.maxHeight, _size.height);
      _frameFor(boxSize);
      ChartMapPainter painter(GlobeView? globe) => ChartMapPainter(
            frame: _frame,
            walk: _still,
            geography: geo,
            palette: widget.palette,
            language: language,
            discovered: widget.discovered,
            legs: widget.legs,
            ahead: widget.ahead,
            selectedId: _selectedId ?? '',
            here: widget.here,
            walking: false,
            walkPath: const [],
            chapterFilter: 0,
            reduceMotion: true,
            chapterColor:
                calque == ChartCalque.chapters || calque == ChartCalque.none
                    ? widget.chapterColor
                    : (_) => widget.palette.road,
            fog: ChartFog.uncharted,
            calque: calque,
            clanColours: clanColours,
            standingOf: standings,
            shopPlaces: widget.shopPlaces,
            campPlaces: widget.campPlaces,
            globe: globe,
            zoomOf: () => globe?.zoom ?? _scale,
            view: _view,
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
                  zoomOf: () => globeView?.zoom ?? 1,
                  still: reduceMotion,
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
                        zoomOf: () => _scale,
                        visibleOf: () => _visibleChart(boxSize),
                        still: reduceMotion,
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
                button('journey_recentre', Icons.my_location,
                    tr(ref, 'journey_recentre'), () {
                  final here = widget.here;
                  if (here == null) return;
                  // Glides back to the party (v1.201.1).
                  if (sphere) {
                    setState(() => _globe = GlobeView.at(
                        geo.of(here),
                        math.max(_globe?.zoom ?? 1, _landZoom),
                        _globeCentre(boxSize)));
                  } else {
                    _animateTo(_framing(geo.of(here),
                        math.max(_settledScale, _landZoom), boxSize));
                  }
                }),
                const SizedBox(height: 6),
                button(
                    'journey_zoom_in',
                    Icons.add,
                    tr(ref, 'world_map_zoom_in'),
                    () => sphere ? _globeZoom(1.5) : _zoom(1.5, boxSize)),
                const SizedBox(height: 6),
                button(
                    'journey_zoom_out',
                    Icons.remove,
                    tr(ref, 'world_map_zoom_out'),
                    () =>
                        sphere ? _globeZoom(1 / 1.5) : _zoom(1 / 1.5, boxSize)),
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
