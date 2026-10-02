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
import 'chart_map_painter.dart';

/// How far out the Journey's map is looked at.
enum JourneyMapLevel { place, land, world }

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

  @override
  ConsumerState<JourneyWorldMap> createState() => _JourneyWorldMapState();
}

class _JourneyWorldMapState extends ConsumerState<JourneyWorldMap> {
  final TransformationController _view = TransformationController();
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
  static const double _landZoom = 2.8;
  static const double _maxZoom = 8;

  @override
  void dispose() {
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
    final at = _onMap(chart);
    _view.value = _matrix(
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
      _look(geo.of(here), _landZoom, box);
      _globe = GlobeView.at(geo.of(here), _landZoom, centre);
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
    setState(() => _globe = g.copyWith(
        radius: GlobeView.baseRadius * (g.zoom * factor).clamp(1.0, _maxZoom)));
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
    setState(() => _selectedId = nearest!.id);
    widget.onSelect?.call(nearest);
  }

  void _zoom(double factor, Size box) {
    final centre = Offset(box.width / 2, box.height / 2);
    final target = (_scale * factor).clamp(1.0, _maxZoom);
    final inverse = Matrix4.inverted(_view.value);
    final at = MatrixUtils.transformPoint(inverse, centre);
    setState(() => _view.value = _matrix(
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
    setState(() => _selectedId = nearest!.id);
    widget.onSelect?.call(nearest);
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
          );
      // The sphere: the whole box is its sky; a drag turns it, a pinch
      // brings it close, a tap picks a place on it.
      final globeView = _globe?.copyWith(centre: _globeCentre(boxSize));
      final sphereChart = GestureDetector(
        key: const ValueKey('journey_globe_canvas'),
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onGlobeScaleStart,
        onScaleUpdate: (d) => _onGlobeScaleUpdate(d, boxSize),
        onScaleEnd: (_) => _dragLast = null,
        onTapUp: (d) => _globeTap(d.localPosition, boxSize),
        child: CustomPaint(size: boxSize, painter: painter(globeView)),
      );
      final chart = InteractiveViewer(
        key: const ValueKey('journey_world_viewer'),
        transformationController: _view,
        minScale: 1,
        maxScale: _maxZoom,
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
              child: CustomPaint(size: _size, painter: painter(null)),
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
                  setState(() {
                    _look(geo.of(here), math.max(_scale, _landZoom), boxSize);
                    _globe = GlobeView.at(
                        geo.of(here),
                        math.max(_globe?.zoom ?? 1, _landZoom),
                        _globeCentre(boxSize));
                  });
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
