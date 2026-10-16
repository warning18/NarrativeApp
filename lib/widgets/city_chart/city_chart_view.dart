// The city chart as a page the player moves in (see city_chart.dart): it
// opens on the whole city, pinches and wheels in and out, and a tap on a
// district zooms to it -- its houses grow roofs, its buildings their names
// and its ways their pins. Districts the party has not found lie under fog.
// No separate hub: the whole city is the zoomed-out view, and "Whole city"
// is the way back to it.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/map_charts.dart';
import '../../data/world_map.dart' show MapLook;
import '../journey_banner_pin.dart' show PinBanner;
import 'city_chart.dart';
import 'city_chart_painter.dart';

/// The words the view says, in the player's language (the host passes them).
class CityChartText {
  const CityChartText({
    this.wholeCity = 'Whole city',
    this.unexplored = 'Not explored yet',
    this.go = 'Go',
    this.walk = 'Walk here',
    this.here = 'You are here',
    this.zoomIn = 'Zoom in',
    this.zoomOut = 'Zoom out',
    this.waysOne = '1 way',
    this.waysMany = '{n} ways',
    this.kinds = const {
      CityWayKind.quest: 'Quest',
      CityWayKind.fight: 'Fight',
      CityWayKind.check: 'Check',
      CityWayKind.shop: 'Shop',
      CityWayKind.road: 'Road',
    },
  });

  final String wholeCity;
  final String unexplored;
  final String go;
  final String walk;
  final String here;
  final String zoomIn;
  final String zoomOut;
  final String waysOne;

  /// With {n} for the count.
  final String waysMany;
  final Map<CityWayKind, String> kinds;

  String ways(int n) => n == 1 ? waysOne : waysMany.replaceAll('{n}', '$n');
}

class CityChartView extends StatefulWidget {
  const CityChartView({
    super.key,
    required this.chart,
    required this.look,
    this.explored,
    this.hereDistrict,
    this.hereWayId,
    this.goalWayId,
    this.text = const CityChartText(),
    this.onWay,
    this.onWalk,
    this.animate = true,
    this.focus,
    this.focusToken = 0,
    this.onFocus,
    this.onPick,
    this.onPickFog,
    this.controls = true,
    this.cards = true,
    this.numbers = const {},
    this.banners = const {},
    this.bannersDark = true,
  });

  /// A number on each pin by way id (the host's list rows carry the same).
  final Map<String, int> numbers;

  /// Ways that hang as a banner (by way id) rather than a round pin.
  final Map<String, PinBanner> banners;
  final bool bannersDark;

  /// A district to open on (and to frame again whenever [focus] or
  /// [focusToken] changes); null shows the whole city. The Journey hosts the
  /// chart this way: its District and Town levels set it.
  final String? focus;
  final int focusToken;

  /// Told when the district in view changes (null: the whole city), by a
  /// tap, a pinch or the host.
  final void Function(String? districtId)? onFocus;

  /// Told when a way's pin is tapped (a host with its own sheet), and when
  /// a district not yet found is.
  final void Function(CityChartWay way)? onPick;
  final void Function(CityChartDistrict district)? onPickFog;

  /// The "Whole city" chip and the zoom buttons, and the card at the foot:
  /// off when a host has its own.
  final bool controls;
  final bool cards;

  final CityChart chart;
  final MapLook look;

  /// The ids of the districts the party has found; null for all of them.
  final Set<String>? explored;
  final String? hereDistrict;
  final String? hereWayId;

  /// The goal the player set, if any (nothing is marked on its own).
  final String? goalWayId;
  final CityChartText text;

  /// A way picked from its card.
  final void Function(CityChartWay way)? onWay;

  /// Walking to a district (free, no road): offered on the district card
  /// when the party is not in it.
  final void Function(CityChartDistrict district)? onWalk;
  final bool animate;

  @override
  State<CityChartView> createState() => _CityChartViewState();
}

class _CityChartViewState extends State<CityChartView>
    with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  // The view: canvas = _offset + plan point * _scale.
  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;
  double _fitted = 1;
  bool _placed = false;

  // A zoom under way.
  double _fromScale = 1, _toScale = 1;
  Offset _fromOffset = Offset.zero, _toOffset = Offset.zero;

  // A pinch under way.
  double _startScale = 1;
  Offset _startFocal = Offset.zero;
  Offset _startOffset = Offset.zero;

  (DateTime, Offset)? _lastTap;
  String? _focus;
  CityChartWay? _pickedWay;
  CityChartDistrict? _pickedFog;
  String? _reportedFocus;

  @override
  void didUpdateWidget(covariant CityChartView old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus || old.focusToken != widget.focusToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_placed) return;
        final d = widget.focus == null
            ? null
            : widget.chart.districtById(widget.focus!);
        if (d == null) {
          _showWhole();
        } else {
          _showDistrict(d);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _move.addListener(_tick);
    if (widget.animate) _breath.repeat();
  }

  @override
  void dispose() {
    _move.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _tick() {
    final t = Curves.easeInOutCubic.transform(_move.value);
    setState(() {
      _scale = _fromScale + (_toScale - _fromScale) * t;
      _offset = Offset.lerp(_fromOffset, _toOffset, t)!;
    });
  }

  double get _minScale => _fitted * 0.85;
  double get _maxScale => _fitted * 9;

  void _fit(Size size) {
    _size = size;
    final b = widget.chart.bounds;
    _fitted = math.min(size.width / b.width, size.height / b.height);
    if (!_placed) {
      _placed = true;
      _scale = _fitted;
      _offset = Offset((size.width - b.width * _fitted) / 2,
          (size.height - b.height * _fitted) / 2);
      final d = widget.focus == null
          ? null
          : widget.chart.districtById(widget.focus!);
      if (d != null) {
        final box = d.box;
        final scale =
            math.min(size.width / box.width, size.height / box.height);
        _scale = scale.clamp(_minScale, _maxScale);
        _offset = _clamped(
            Offset(size.width / 2, size.height * 0.5) - box.center * _scale,
            _scale);
        _focus = d.id;
      }
    }
  }

  /// Keeps the city from being dragged out of the view altogether.
  Offset _clamped(Offset o, double scale) {
    final b = widget.chart.bounds;
    final w = b.width * scale, h = b.height * scale;
    double axis(double v, double size, double content) {
      if (content <= size) return (size - content) / 2;
      return v.clamp(size - content - size * 0.25, size * 0.25);
    }

    return Offset(axis(o.dx, _size.width, w), axis(o.dy, _size.height, h));
  }

  void _animateTo(double scale, Offset offset) {
    scale = scale.clamp(_minScale, _maxScale);
    offset = _clamped(offset, scale);
    if (!widget.animate) {
      setState(() {
        _scale = scale;
        _offset = offset;
      });
      return;
    }
    _fromScale = _scale;
    _toScale = scale;
    _fromOffset = _offset;
    _toOffset = offset;
    _move.forward(from: 0);
  }

  /// Zooms about the screen point [focal] by [factor].
  void _zoomAbout(Offset focal, double factor) {
    final scale = (_scale * factor).clamp(_minScale, _maxScale);
    final plan = (focal - _offset) / _scale;
    _animateTo(scale, focal - plan * scale);
    setState(
        () => _focus = scale / _fitted >= cityChartDetailZoom ? _focus : null);
  }

  void _showWhole() {
    final b = widget.chart.bounds;
    _animateTo(
        _fitted,
        Offset((_size.width - b.width * _fitted) / 2,
            (_size.height - b.height * _fitted) / 2));
    setState(() {
      _focus = null;
      _pickedWay = null;
      _pickedFog = null;
    });
  }

  void _showDistrict(CityChartDistrict d) {
    final box = d.box;
    final scale = math.min(_size.width / box.width, _size.height / box.height);
    final c = box.center;
    // Framed a little above the middle: the district's card sits below.
    _animateTo(scale, Offset(_size.width / 2, _size.height * 0.42) - c * scale);
    setState(() {
      _focus = d.id;
      _pickedWay = null;
      _pickedFog = null;
    });
  }

  bool _known(String id) =>
      widget.explored == null || widget.explored!.contains(id);

  CityChartPainter _painter({double pulse = 0}) => CityChartPainter(
        chart: widget.chart,
        palette: ChartPalette.of(widget.look),
        scale: _scale,
        offset: _offset,
        fitted: _fitted,
        explored: widget.explored,
        hereDistrict: widget.hereDistrict,
        hereWayId: widget.hereWayId,
        goalWayId: widget.goalWayId,
        selectedWayId: _pickedWay?.id,
        focusDistrict: _focus,
        numbers: widget.numbers,
        banners: widget.banners,
        bannersDark: widget.bannersDark,
        pulse: pulse,
      );

  void _tap(Offset at) {
    final chart = widget.chart;
    final plan = (at - _offset) / _scale;
    final painter = _painter();
    // Pins first, when they are showing.
    if (painter.detailed) {
      for (final w in chart.ways) {
        final d = chart.districts[w.district];
        if (_focus != null && d.id != _focus) continue;
        if (!_known(d.id)) continue;
        final pin = _offset + painter.pinAt(w) * _scale + const Offset(0, -16);
        if ((pin - at).distance <= CityChartPainter.pinRadius + 10) {
          setState(() {
            _pickedWay = w;
            _pickedFog = null;
          });
          widget.onPick?.call(w);
          return;
        }
      }
    }
    // A district: the one whose blocks the tap is in, else the nearest.
    CityChartDistrict? hit;
    for (final d in chart.districts) {
      if (d.blocks.contains(plan)) hit = d;
    }
    if (hit == null) {
      var best = 70 / _scale;
      for (final d in chart.districts) {
        final dist = (d.centre - plan).distance;
        if (dist < best) {
          best = dist;
          hit = d;
        }
      }
    }
    if (hit == null) {
      setState(() {
        _pickedWay = null;
        _pickedFog = null;
      });
      return;
    }
    if (!_known(hit.id)) {
      setState(() {
        _pickedFog = hit;
        _pickedWay = null;
      });
      widget.onPickFog?.call(hit);
      return;
    }
    if (_focus == hit.id) {
      setState(() => _pickedWay = null);
      return;
    }
    _showDistrict(hit);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(widget.look);
    final text = widget.text;
    return LayoutBuilder(builder: (context, box) {
      _fit(Size(box.maxWidth, box.maxHeight));
      final focus = _focus == null ? null : widget.chart.districtById(_focus!);
      final zoomed = _scale / _fitted > 1.05;
      if (_focus != _reportedFocus) {
        _reportedFocus = _focus;
        final now = _focus;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFocus?.call(now);
        });
      }
      return Stack(children: [
        Positioned.fill(
          child: Listener(
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) {
                _zoomAbout(e.localPosition, e.scrollDelta.dy < 0 ? 1.25 : 0.8);
              }
            },
            child: GestureDetector(
              key: const Key('city_chart'),
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) {
                _move.stop();
                _startScale = _scale;
                _startFocal = d.localFocalPoint;
                _startOffset = _offset;
              },
              onScaleUpdate: (d) {
                final scale =
                    (_startScale * d.scale).clamp(_minScale, _maxScale);
                final plan = (_startFocal - _startOffset) / _startScale;
                setState(() {
                  _scale = scale;
                  _offset = _clamped(d.localFocalPoint - plan * scale, scale);
                  if (scale / _fitted < cityChartDetailZoom) _focus = null;
                });
              },
              onTapUp: (d) {
                // A second tap close by, soon after, zooms in further.
                final now = DateTime.now();
                final last = _lastTap;
                if (last != null &&
                    now.difference(last.$1).inMilliseconds < 300 &&
                    (last.$2 - d.localPosition).distance < 40) {
                  _lastTap = null;
                  _zoomAbout(d.localPosition, 2.0);
                  return;
                }
                _lastTap = (now, d.localPosition);
                _tap(d.localPosition);
              },
              child: AnimatedBuilder(
                animation: _breath,
                builder: (context, _) => CustomPaint(
                  painter: _painter(pulse: _breath.value),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        // The way back to the whole city, and the zoom buttons.
        if (widget.controls)
          Positioned(
            left: 12,
            top: 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: zoomed ? 1 : 0,
              child: IgnorePointer(
                ignoring: !zoomed,
                child: _chip(
                  key: const Key('city_chart_whole'),
                  palette: palette,
                  icon: Icons.zoom_out_map,
                  label: text.wholeCity,
                  onTap: _showWhole,
                ),
              ),
            ),
          ),
        if (widget.controls)
          Positioned(
            right: 12,
            top: 12,
            child: Column(children: [
              _round(
                key: const Key('city_chart_zoom_in'),
                palette: palette,
                icon: Icons.add,
                tooltip: text.zoomIn,
                onTap: () => _zoomAbout(_size.center(Offset.zero), 1.6),
              ),
              const SizedBox(height: 8),
              _round(
                key: const Key('city_chart_zoom_out'),
                palette: palette,
                icon: Icons.remove,
                tooltip: text.zoomOut,
                onTap: () => _zoomAbout(_size.center(Offset.zero), 0.625),
              ),
            ]),
          ),
        if (widget.cards &&
            (_pickedWay != null || _pickedFog != null || focus != null))
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _card(palette, text, focus),
          ),
      ]);
    });
  }

  Widget _card(
      ChartPalette palette, CityChartText text, CityChartDistrict? focus) {
    final way = _pickedWay;
    final fog = _pickedFog;
    final chart = widget.chart;
    final d = way != null ? chart.districts[way.district] : fog ?? focus!;
    final here = way != null && way.id == widget.hereWayId;
    return Container(
      key: Key(way != null
          ? 'city_chart_way_card'
          : fog != null
              ? 'city_chart_fog_card'
              : 'city_chart_district_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.fog.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.colour, width: 1.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                way != null ? way.name : (fog != null ? '?' : d.name),
                style: TextStyle(
                    color: palette.place,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                way != null
                    ? '${d.name} · ${text.kinds[way.kind]}${here ? ' · ${text.here}' : ''}'
                    : fog != null
                        ? text.unexplored
                        : text.ways(chart.waysIn(d.id).length),
                style: TextStyle(color: palette.label, fontSize: 12.5),
              ),
            ],
          ),
        ),
        if (way == null &&
            fog == null &&
            widget.onWalk != null &&
            d.id != widget.hereDistrict)
          FilledButton(
            key: const Key('city_chart_walk'),
            style: FilledButton.styleFrom(
                backgroundColor: d.colour, foregroundColor: palette.fog),
            onPressed: () => widget.onWalk!(d),
            child: Text(text.walk),
          ),
        if (way != null && widget.onWay != null && !here)
          FilledButton(
            key: const Key('city_chart_go'),
            style: FilledButton.styleFrom(
                backgroundColor: d.colour, foregroundColor: palette.fog),
            onPressed: () => widget.onWay!(way),
            child: Text(text.go),
          ),
      ]),
    );
  }

  Widget _chip({
    required Key key,
    required ChartPalette palette,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Material(
        color: palette.fog.withValues(alpha: 0.92),
        shape: StadiumBorder(side: BorderSide(color: palette.coast)),
        child: InkWell(
          key: key,
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: palette.place),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: palette.place, fontSize: 12.5)),
            ]),
          ),
        ),
      );

  Widget _round({
    required Key key,
    required ChartPalette palette,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: palette.fog.withValues(alpha: 0.92),
          shape: CircleBorder(side: BorderSide(color: palette.coast)),
          child: InkWell(
            key: key,
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 20, color: palette.place)),
          ),
        ),
      );
}
