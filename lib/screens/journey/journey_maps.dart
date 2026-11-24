// The Journey's map (Maps' code): the chart widget and its state, the
// walk and its zoom. Its painters are in journey_maps_paint.dart. Cut out
// of journey_screen.dart with no change.
part of '../journey_screen.dart';

/// The chart: the road ahead fanning out from where the party stands, one
/// step per way on, over a gentle relief. Many ways on (a town) stack in
/// rows up the map; the chapter's earlier scenes run down it below the
/// party. It opens on the party and scrolls both ways. Taking a step
/// walks the party's mark along its road while the map follows.
class _JourneyChart extends StatefulWidget {
  const _JourneyChart({
    super.key,
    required this.steps,
    required this.selected,
    required this.hereName,
    required this.youAreHere,
    required this.leadsTo,
    required this.palette,
    required this.ink,
    required this.greyed,
    required this.terrainShift,
    required this.terrainSeed,
    required this.onTap,
    this.stamp,
    this.burn = false,
    this.unroll = 0,
    this.weather = JourneyWeather.none,
    this.place,
    this.arriveFrom,
    this.townView = false,
    this.stepIds,
    this.roadLeg,
    this.roadMap,
    this.onRoadWalk,
    this.rings = const [],
    this.ringLit,
    this.onRing,
  });

  /// A way out to another place (v1.548): its world road, walked on the
  /// world chart [roadMap] builds, and the word that the walk has begun.
  final WorldLegPath? Function(_Step step)? roadLeg;
  final Widget Function(WorldLegPath path, Animation<double> clock)? roadMap;
  final VoidCallback? onRoadWalk;

  /// A hub's rings round the party's mark (v1.419, see choice_rings.dart),
  /// the one whose list is open ([ringLit]), and a tap on one.
  final List<ChoiceRing> rings;
  final String? ringLit;
  final ValueChanged<String>? onRing;

  /// Where each of [steps] stands in the scene's list of ways, when the map
  /// draws only some of them (the others are cards): the marks keep the
  /// keys of their own way.
  final List<int>? stepIds;

  /// The whole town in view (v1.350: the step between a district and the
  /// world) instead of the district's close-up; the frame glides between.
  final bool townView;

  /// The district (or room spot) the party comes from when the story set it
  /// down here along no walk: its mark travels the plan from there.
  final String? arriveFrom;

  /// The place up close, when the party stands at one the world chart
  /// knows: the ways ring the party and the ways out point where they
  /// go. Null (a detour) keeps the road going up.
  final _PlaceView? place;

  /// A place reached that the map hadn't shown: its name is stamped.
  final String? stamp;

  /// A new chapter: the map burns open from the party's mark.
  final bool burn;

  /// Changes each time the tab is opened from another: the map unrolls.
  final int unroll;

  /// The chapter's weather (see journeyWeatherFor).
  final JourneyWeather weather;

  final List<_Step> steps;
  final int? selected;
  final String hereName;

  /// "You are here", over [hereName].
  final String youAreHere;

  /// "To {place}", under a step that leads somewhere else.
  final String leadsTo;

  final ChartPalette palette;
  final InkColors ink;
  final bool greyed;

  /// Where this scene's land lies (see _JourneyViewState._terrainShift).
  final Offset terrainShift;
  final int terrainSeed;
  final void Function(int index, _Step step) onTap;

  @override
  State<_JourneyChart> createState() => _JourneyChartState();
}

/// How many Journey maps have their clock running (v1.209): one while
/// something on the map moves (a map on its way out may still hold one),
/// none once it has settled. For tests.
@visibleForTesting
final ValueNotifier<int> debugJourneyMapsTicking = ValueNotifier(0);

/// How many Journey charts have their idle glyphs breathing (tests): their
/// clock runs only while a round mark that breathes is on the chart.
@visibleForTesting
final ValueNotifier<int> debugJourneyIdleGlyphs = ValueNotifier(0);

/// How long the party takes to walk a road [length] logical pixels long
/// (v1.219): in a place, at a steady stroll (about 130 px a second, from a
/// second and a half to four and a quarter), so a long street no longer
/// flashes by; on the road up the map, the short walk it always was.
Duration journeyWalkDuration(double length, {required bool place}) => place
    ? Duration(milliseconds: (length * 7.5).round().clamp(1500, 4200))
    : const Duration(milliseconds: 950);

/// The most the place's map zooms in on a walking party.
const double journeyWalkZoom = 1.5;

/// The place's map zoom [t] of the way through a walk (v1.219): in over the
/// first fifth, held while the party strolls, out over the last fifth.
double journeyWalkZoomAt(double t) {
  final edge = math.min(t / 0.2, (1 - t) / 0.2).clamp(0.0, 1.0);
  return 1 + (journeyWalkZoom - 1) * edge * edge * (3 - 2 * edge);
}

class _JourneyChartState extends State<_JourneyChart>
    with TickerProviderStateMixin {
  static const double _stepRadius = 22;
  static const double _hereRadius = 26;
  static const double _top = 40;
  static const double _rowMin = 136;
  static const double _rowMax = 190;

  /// Room under the party's mark before the map's first screen ends: the
  /// scene just left shows there, and the road runs on down to the rest.
  static const double _hereBelow = 78;

  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  /// The beat at the party's mark when a choice done here is taken (see
  /// [playBeat]).
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Color _beatColor = Palette.white;
  IconData _beatIcon = Icons.circle;

  /// A ring spreads from the party's mark in [colour] and [icon] rises from
  /// it, for half a second; completes at once when the map is not drawn or
  /// motion is reduced.
  Future<void> playBeat(Color colour, IconData icon) async {
    if (!mounted) return;
    _beatColor = colour;
    _beatIcon = icon;
    await _beat.forward(from: 0).orCancel.catchError((_) {});
  }

  /// The party's mark travelling the plan from [_JourneyChart.arriveFrom]
  /// to where it stands (v1.246); done (1) when there is nothing to show.
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );
  bool _arrivalStarted = false;

  /// How much of the town is in view: 0 the district's close-up, 1 the
  /// whole plan (see [_JourneyChart.townView]).
  late final AnimationController _town = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.townView ? 1 : 0,
  );

  /// Out of a place and along the world chart to the next (v1.181).
  /// The marks' glyphs breathing (see journey_glyph.dart): its own small
  /// clock, so the map itself still rests when nothing moves.
  late final AnimationController _idleGlyphs = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  int? _flying;
  WorldLegPath? _flyingLeg;

  bool get _placeMode => widget.place != null;

  /// The city's plan on the map (v1.203): canvas = origin + plan * scale.
  double? _planScale;
  double _planFitted = 1;
  Offset? _planOrigin;

  RoomPlan? get _room => widget.place?.room;

  /// The plan the ways are laid on: the room when inside, else the city.
  PlacePlan? get _anchors => widget.place?.room ?? widget.place?.plan;

  /// A way's road: through the city's streets on its plan, a street out
  /// of the square in a place, the road up the map otherwise.
  Path _road(Offset from, Offset to) {
    final plan = _anchors;
    final s = _planScale, o = _planOrigin;
    if (plan != null && s != null && o != null) {
      final pts = [
        for (final p in plan.route((from - o) / s, (to - o) / s)) o + p * s,
      ];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        if (i + 1 < pts.length) {
          final mid = (pts[i] + pts[i + 1]) / 2;
          path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
        } else {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      }
      return path;
    }
    return _placeMode ? placeStreet(from, to) : _roadPath(from, to);
  }

  /// [path] less the party's mark at its start and the step's at its end.
  static Path _trimmed(Path path, double start, double end) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return path;
    final metric = metrics.first;
    if (metric.length <= start + end + 2) return path;
    return metric.extractPath(start, metric.length - end);
  }

  /// Where a way's road leaves the party and reaches its mark.
  (Offset, Offset) _roadEnds(Offset here, Offset centre, double width) {
    if (!_placeMode) {
      return (
        _roadStart(here, centre, width),
        centre.translate(0, _stepRadius),
      );
    }
    final d = centre - here;
    final unit = d.distance == 0 ? const Offset(0, -1) : d / d.distance;
    return (here + unit * _hereRadius, centre - unit * _stepRadius);
  }

  ScrollController? _scroll;
  double _openAt = 0;
  double? _viewport;
  int? _walking;

  // The last layout, for the walk.
  Offset _here = Offset.zero;
  List<Offset> _centres = const [];

  // --- Motion (see journey_fx.dart) ---------------------------------------

  /// Seconds the map has been on screen: the effects are drawn from it.
  final ValueNotifier<double> _clock = ValueNotifier(0);

  /// Ticks while something on the map is still arriving (the ways inking
  /// in, the stamp, the unroll, a burn, a rattle), for the widgets.
  final ValueNotifier<double> _phase = ValueNotifier(0);
  Ticker? _ticker;
  double _clockBase = 0;
  bool _animate = false;

  /// When the last one-off moment began, on the clock.
  double _lastEvent = 0;
  double _unrollAt = -10;
  (int, double)? _rattle;
  final List<JourneyFootprint> _footprints = [];
  (Offset, double)? _dust;
  ui.PathMetric? _walkRoad;
  double _nextPrint = 0;

  /// The share of the road between two footprints.
  double _printStep = 0.07;
  int _printSide = 1;

  @override
  void initState() {
    super.initState();
    _town.addListener(() => setState(() {}));
    _walk.addListener(_onWalk);
    _walk.addStatusListener((status) {
      if (status == AnimationStatus.completed && _walking != null) {
        final i = _walking!;
        if (i < _centres.length) _dust = (_centres[i], _clock.value);
        _wake();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only on screen, and not with the system's reduced motion.
    final animate = !MediaQuery.of(context).disableAnimations &&
        Visibility.of(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate == _animate) return;
    _animate = animate;
    if (animate) {
      _syncIdleGlyphs();
      final from = widget.arriveFrom;
      if (!_arrivalStarted &&
          from != null &&
          _anchors != null &&
          from != widget.place?.hereDistrict) {
        _arrivalStarted = true;
        _arrival.forward(from: 0);
      }
      _ticker ??= createTicker((elapsed) {
        final now = _clockBase + elapsed.inMicroseconds / 1e6;
        _clock.value = now;
        if (now - _lastEvent < 3.8) _phase.value = now;
        // Nothing left to move: the map holds this frame (v1.209).
        if (!_movingAt(now)) _rest();
      });
      _wake();
    } else {
      _syncIdleGlyphs();
      _rest();
    }
  }

  /// Whether a mark on the chart breathes: a round mark (a fight or a
  /// roll, not a banner pin) that is not locked (see the marks' build).
  bool get _hasIdleGlyphs => widget.steps.any(
        (s) => !s.locked && journeyPinCatOf(s.kind, s.questTie) == null,
      );

  /// The idle glyphs' clock runs only while the chart animates and a mark
  /// that breathes is on it: no frames asked for otherwise.
  void _syncIdleGlyphs() {
    final run = _animate && _hasIdleGlyphs;
    if (run == _idleGlyphs.isAnimating) return;
    if (run) {
      _idleGlyphs.repeat();
      debugJourneyIdleGlyphs.value++;
    } else {
      _idleGlyphs.stop();
      debugJourneyIdleGlyphs.value--;
    }
  }

  /// Whether the map still has motion to draw at [now] (v1.209): a walk
  /// or a flight under way, the ways still inking in, a new chapter
  /// burning open, a place's name stamped, the unroll, a shut way's
  /// rattle, footprints and dust still fading, or the moments after the
  /// last event (the picked road flows a while, then holds). Idle, the
  /// ticker stops: the Journey draws no frame until something moves.
  bool _movingAt(double now) =>
      _walk.isAnimating ||
      _arrival.isAnimating ||
      _flight.isAnimating ||
      _reveal < 1 ||
      (widget.burn && now < 1.4) ||
      (widget.stamp != null && now < 4.2) ||
      now - _unrollAt < 0.55 ||
      now - _lastEvent < 3.8 ||
      (_rattle != null && now - _rattle!.$2 < 0.5) ||
      (_dust != null && now - _dust!.$2 < 0.8) ||
      _footprints.any((f) => now - f.born < 1.4);

  /// Starts the clock for the next motion, when the map animates at all.
  void _wake() {
    final ticker = _ticker;
    if (!_animate || ticker == null || ticker.isActive) return;
    ticker.start();
    debugJourneyMapsTicking.value++;
  }

  /// Stops the clock where it stands; [_wake] takes it up from there.
  void _rest() {
    final ticker = _ticker;
    if (ticker == null || !ticker.isActive) return;
    _clockBase = _clock.value;
    ticker.stop();
    debugJourneyMapsTicking.value--;
  }

  @override
  void didUpdateWidget(covariant _JourneyChart old) {
    super.didUpdateWidget(old);
    if (!identical(old.steps, widget.steps)) _syncIdleGlyphs();
    if (old.townView != widget.townView) {
      final to = widget.townView ? 1.0 : 0.0;
      if (MediaQuery.of(context).disableAnimations) {
        _town.value = to;
      } else {
        _town.animateTo(to, curve: Curves.easeInOut);
      }
    }
    if (old.unroll != widget.unroll) {
      _unrollAt = _clock.value;
      _lastEvent = _clock.value;
    }
    // A new moment to draw: the road picked flows, a chapter burns open,
    // a name is stamped, the ways of a new scene ink in.
    if (old.unroll != widget.unroll ||
        old.burn != widget.burn ||
        old.stamp != widget.stamp ||
        old.selected != widget.selected ||
        old.steps.length != widget.steps.length) {
      _lastEvent = _clock.value;
      _wake();
    }
  }

  void _onWalk() {
    final road = _walkRoad;
    if (road == null || !_animate) return;
    final t = Curves.easeInOut.transform(_walk.value);
    // A footprint every little way, left and right.
    while (_nextPrint <= t && _nextPrint < 0.97) {
      final tangent = road.getTangentForOffset(road.length * _nextPrint);
      if (tangent != null) {
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        _footprints.add(
          JourneyFootprint(
            tangent.position + normal * 4.0 * _printSide.toDouble(),
            _clock.value,
            math.atan2(tangent.vector.dy, tangent.vector.dx) + math.pi / 2,
          ),
        );
        _printSide = -_printSide;
      }
      _nextPrint += _printStep;
    }
  }

  /// How far the ways have inked in (0 to 1): all of them at once with
  /// the system's reduced motion, or on a new chapter (which burns open).
  double get _reveal =>
      !_animate || widget.burn ? 1 : (_clock.value / 1.0).clamp(0.0, 1.0);

  /// Step [i]'s road drawn so far, and its mark's pop. The ways follow one
  /// another closer the more there are, so a busy town's last way is in
  /// with the rest.
  double get _stagger =>
      math.min(0.08, 0.25 / math.max(1, widget.steps.length));
  double _roadReveal(int i) =>
      ((_reveal - i * _stagger) / 0.55).clamp(0.0, 1.0);
  double _markReveal(int i) =>
      ((_reveal - 0.4 - i * _stagger) / 0.35).clamp(0.0, 1.0);

  /// Walks the party's mark along the road to step [index], the map
  /// following it and coming back to where it opened; returns how far the
  /// party went (the step's place less its own), or null when the map is
  /// taken down before the party gets there.
  /// [setOut]: a road the crossing screen plays: the flight stops once the
  /// party has left (about two seconds), and the crossing rises over the
  /// chart.
  Future<Offset?> walkTo(int index, {bool setOut = false}) async {
    if (index >= _centres.length || !widget.steps[index].moves) return null;
    _walkRoad = _road(_here, _centres[index]).computeMetrics().first;
    // Slow in a place, a stroll whatever the street's length, and the
    // footprints a stride apart.
    _walk.duration = _animate
        ? journeyWalkDuration(_walkRoad!.length, place: _placeMode)
        : const Duration(milliseconds: 950);
    _printStep = (26 / math.max(1.0, _walkRoad!.length)).clamp(0.02, 0.07);
    _nextPrint = _printStep;
    _footprints.clear();
    _dust = null;
    _lastEvent = _clock.value;
    _wake();
    setState(() => _walking = index);
    final scroll = _scroll;
    if (scroll != null &&
        scroll.hasClients &&
        (scroll.offset - _openAt).abs() > 1) {
      scroll.animateTo(
        _openAt,
        duration: _walk.duration!,
        curve: Curves.easeInOut,
      );
    }
    try {
      await _walk.forward(from: 0).orCancel;
      // A way out of the place: the map zooms out to the world chart and
      // the party walks the road to where it leads.
      final place = widget.place;
      final target =
          index < widget.steps.length ? widget.steps[index].chartTarget : null;
      if (place != null && target != null && _animate && mounted) {
        // A road with more to pass takes longer to walk.
        final stops = widget.steps[index].route?.stops.length ?? 0;
        _flight.duration = Duration(
          milliseconds: math.min(4500, 1900 + 350 * stops),
        );
        _flyingLeg = widget.roadMap == null
            ? null
            : widget.roadLeg?.call(widget.steps[index]);
        if (_flyingLeg != null) {
          _flight.duration = worldMoveDuration(_flyingLeg!);
          widget.onRoadWalk?.call();
        }
        setState(() => _flying = index);
        _wake();
        if (setOut) {
          final span = _flight.duration! * crossingSetOutAt;
          await _flight
              .animateTo(
                crossingSetOutAt,
                duration: span > crossingSetOutMax ? crossingSetOutMax : span,
                curve: Curves.easeOut,
              )
              .orCancel;
        } else {
          await _flight.forward(from: 0).orCancel;
        }
      }
    } on TickerCanceled {
      // The map went mid-walk (disposed with its scene): its walk never
      // ends, and the caller must not wait on it.
      return null;
    }
    return _centres[index] - _here;
  }

  /// The party walks back along the road it took, to its mark (the story
  /// stayed where it was: a fight fled, a shop shut), instead of snapping
  /// there (v1.245). With reduced motion it is there at once.
  Future<void> walkBack() async {
    if (!mounted) return;
    if (_walking != null && _animate) {
      try {
        if (_flying != null) {
          await _flight
              .animateBack(
                0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
              )
              .orCancel;
        }
        final span = _walk.duration ?? const Duration(milliseconds: 950);
        await _walk
            .animateBack(0, duration: span * 0.6, curve: Curves.easeInOut)
            .orCancel;
      } on TickerCanceled {
        // The map went mid-walk: nothing left to bring back.
      }
    }
    resetWalk();
  }

  /// Brings the party back to its mark (the story stayed where it was).
  void resetWalk() {
    if (!mounted) return;
    _walk.value = 0;
    _flight.value = 0;
    setState(() {
      _walking = null;
      _flying = null;
      _flyingLeg = null;
    });
  }

  @override
  void dispose() {
    _rest();
    _ticker?.dispose();
    _clock.dispose();
    _phase.dispose();
    _walk.dispose();
    _beat.dispose();
    _arrival.dispose();
    _town.dispose();
    _flight.dispose();
    if (_idleGlyphs.isAnimating) debugJourneyIdleGlyphs.value--;
    _idleGlyphs.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final palette = widget.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: palette.land,
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final rowSizes = journeyRowSizes(steps.length);
            final rows = rowSizes.length;
            late final double present;
            late final Offset here;
            late final List<Offset> centres;
            if (_placeMode) {
              // In a place: the party in the middle, its ways round it and
              // the ways out at the edge where they lead; the chapter
              // behind below.
              // A little short of the box, so the road behind peeks in at
              // the foot and says there is more below.
              // A crowded place (a busy hub's twenty ways) gets a taller
              // map, so the outer ring has room for every mark.
              present = math.max(
                box.maxHeight,
                steps.length > 16
                    ? 560
                    : steps.length > 7
                        ? 400
                        : steps.length > 3
                            ? 300
                            : 220,
              );
              final plan = _anchors;
              if (plan != null) {
                // On the city's plan (v1.203): the whole city in view, the
                // party where its district is, the steps into the other
                // districts where those are, the ways out at the edge and
                // the ways within this district close round the party.
                // Close up (v1.224): the map keeps in view the party and the
                // places its ways lead to, not the whole city.
                final districtOf = widget.place!.districtOfStep;
                final focus = journeyFocusFrame(plan.frame, [
                  plan.anchorOf(widget.place!.hereDistrict),
                  for (var i = 0; i < steps.length; i++)
                    if (steps[i].moves && districtOf[i] != null)
                      plan.anchorOf(districtOf[i]!),
                ]);
                final frame = _town.value == 0
                    ? focus
                    : Rect.lerp(focus, plan.frame, _town.value) ?? focus;
                const side = 22.0, top = 26.0, foot = 74.0;
                final s = math.min(
                  (width - 2 * side) / frame.width,
                  (present - top - foot) / frame.height,
                );
                final origin = Offset(
                  width / 2 - frame.center.dx * s,
                  top + (present - top - foot) / 2 - frame.center.dy * s,
                );
                _planScale = s;
                _planOrigin = origin;
                // The scale that fits the whole plan: the chart's detail
                // (roofs, names) reads the zoom over it.
                _planFitted = math.min(
                  (width - 2 * side) / plan.frame.width,
                  (present - top - foot) / plan.frame.height,
                );
                Offset tf(Offset p) => origin + p * s;
                here = tf(plan.anchorOf(widget.place!.hereDistrict));
                final positions = List<Offset>.filled(steps.length, here);
                // Where the party's badge and the map's button sit: no mark
                // under them.
                final obstacles = [
                  Rect.fromLTWH(0, 0, math.min(width * 0.5, 190) + 16, 84),
                  Rect.fromLTWH(width - 64, present - 64, 64, 64),
                ];
                final area = Rect.fromLTWH(0, 0, width, present).deflate(28);
                final taken = <Offset>[];
                const apart = _stepRadius * 2 + 6;
                bool clear(Offset p) =>
                    area.contains(p) &&
                    (p - here).distance >= _hereRadius + _stepRadius + 4 &&
                    !obstacles.any(
                      (o) => o.overlaps(
                        Rect.fromCircle(center: p, radius: _stepRadius),
                      ),
                    ) &&
                    taken.every((t) => (t - p).distance >= apart);
                // Spots round the party, ring on ring, the nearest first:
                // a way with no ground of its own takes the first spot that
                // is clear.
                final candidates = <Offset>[
                  for (var k = 0; k < 7; k++)
                    for (var n = 0; n < 18; n++)
                      here +
                          Offset(
                                math.cos(n * math.pi / 9 + k * math.pi / 18),
                                math.sin(n * math.pi / 9 + k * math.pi / 18),
                              ) *
                              (74 + k * 46),
                ];
                Offset spotNear(Offset wanted) {
                  Offset? best;
                  var bestD = double.infinity;
                  for (final c in candidates) {
                    if (!clear(c)) continue;
                    final d = (c - wanted).distance;
                    if (d < bestD) {
                      bestD = d;
                      best = c;
                    }
                  }
                  return best ?? wanted;
                }

                // The districts' marks first, on their buildings; then the
                // ways out at the edge; then the rest round the party.
                final later = <int>[];
                for (var i = 0; i < steps.length; i++) {
                  final district = districtOf[i];
                  if (district == null) {
                    later.add(i);
                    continue;
                  }
                  var p = tf(plan.anchorOf(district));
                  if (!clear(p)) p = spotNear(p);
                  positions[i] = p;
                  taken.add(p);
                }
                for (final i in later) {
                  // Only a journey out of the city goes to the edge; a way
                  // to another spot of this city stays by the party.
                  final bearing =
                      steps[i].chartTarget != null ? steps[i].bearing : null;
                  final wanted = bearing != null
                      ? journeyEdgeSpot(here, bearing, Size(width, present))
                      : here;
                  final p = clear(wanted) && bearing != null
                      ? wanted
                      : spotNear(wanted);
                  positions[i] = p;
                  taken.add(p);
                }
                centres = positions;
              } else {
                _planScale = null;
                _planOrigin = null;
                here = Offset(width / 2, present / 2);
                centres = journeyPlaceLayout(
                  area: Size(width, present),
                  here: here,
                  bearings: [for (final step in steps) step.bearing],
                );
              }
              _openAt = 0;
            } else {
              final needed =
                  _top + rows * _rowMin + _hereRadius * 2 + _hereBelow;
              present = math.max(box.maxHeight, needed);
              final hereY = present - _hereBelow - _hereRadius;
              here = Offset(width / 2, hereY);
              final rowGap = rows == 0
                  ? 0.0
                  : ((hereY - _top - _stepRadius) / rows).clamp(
                      _rowMin,
                      _rowMax,
                    );
              Offset centreOf(_Step step) => Offset(
                    step.slot.x * width,
                    hereY - rowGap * (step.slot.row + 1),
                  );
              centres = [for (final step in steps) centreOf(step)];
              _openAt = math.max(0, present - box.maxHeight);
              _planScale = null;
              _planOrigin = null;
            }
            _here = here;
            _centres = centres;
            // The ways' roads on the city's plan, through its streets.
            final planRoads = _anchors == null
                ? null
                : [for (final c in centres) _road(here, c)];
            final height = present;
            _scroll ??= ScrollController(initialScrollOffset: _openAt);
            // A map made taller or shorter (the scene folded or opened, a
            // step picked and its details under the map) opens on the party
            // again, the step picked kept in view.
            if (_viewport != null && _viewport != box.maxHeight) {
              var at = _openAt;
              final picked = widget.selected;
              if (picked != null && picked < centres.length) {
                final y = centres[picked].dy;
                final low = y + _stepRadius + 24 - box.maxHeight;
                at = at.clamp(low, math.max(low, y - _stepRadius - 12));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final scroll = _scroll;
                if (mounted && scroll != null && scroll.hasClients) {
                  scroll.jumpTo(at.clamp(0.0, scroll.position.maxScrollExtent));
                }
              });
            }
            _viewport = box.maxHeight;

            double labelWidth(_Step step) {
              if (_placeMode) return math.min(width * 0.34, 124);
              final n = rowSizes[step.slot.row];
              return n == 1
                  ? math.min(width * 0.7, 240)
                  : math.min(width / (n + 1) - 6, 180);
            }

            final placeStyle = TextStyle(
              fontFamily: InkFonts.prose,
              fontSize: 12.5,
              height: 1.25,
              color: palette.place,
            );
            final noteStyle = TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 11,
              height: 1.2,
              color: palette.label,
            );

            // Where each way's name goes: under its mark on the road up; in
            // a place, wherever it leaves the other marks clear (see
            // journeyLabelSpots). A crowded place names only the way picked
            // and the ways out; the rest by their marks.
            final scaler = MediaQuery.textScalerOf(context);
            final names = <Size?>[
              for (var i = 0; i < steps.length; i++)
                if (_placeMode &&
                    steps.length > 5 &&
                    widget.selected != i &&
                    steps[i].leadsTo == null)
                  null
                else if (_placeMode)
                  // In a place, as much as the words take.
                  _nameSize(
                    steps[i],
                    labelWidth(steps[i]),
                    placeStyle,
                    noteStyle,
                    scaler,
                    selected: widget.selected == i || _walking == i,
                  )
                else
                  Size(labelWidth(steps[i]), 0),
            ];
            final nameSpots = _placeMode
                ? journeyLabelSpots(
                    area: Size(width, present),
                    centres: centres,
                    radius: _stepRadius,
                    labels: names,
                    avoid: [
                      Rect.fromCircle(center: here, radius: _hereRadius),
                      // The "You are here" badge in the corner.
                      Rect.fromLTWH(8, 8, math.min(width * 0.5, 190), 56),
                    ],
                    keep: widget.selected,
                    keepAll: _anchors != null,
                  )
                : [
                    for (var i = 0; i < steps.length; i++)
                      if (names[i] case final name?)
                        Rect.fromLTWH(
                          (centres[i].dx - name.width / 2).clamp(
                            4.0,
                            math.max(4.0, width - name.width - 4),
                          ),
                          centres[i].dy + _stepRadius + 4,
                          name.width,
                          name.height,
                        )
                      else
                        null,
                  ];

            final map = SingleChildScrollView(
              controller: _scroll,
              child: SizedBox(
                width: width,
                height: height,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_walk, _arrival, _phase]),
                  builder: (context, _) {
                    // The walk: the mark goes along its road, and the map
                    // follows a little behind, so the step taken ends where
                    // the mark stood.
                    final walking = _walking;
                    final t = Curves.easeInOut.transform(_walk.value);
                    Offset? traveller;
                    var camera = Offset.zero;
                    if (walking != null && walking < centres.length) {
                      final road = _road(
                        here,
                        centres[walking],
                      ).computeMetrics();
                      final metric = road.first;
                      Offset at(double f) => metric
                          .getTangentForOffset(metric.length * f)!
                          .position;
                      traveller = at(t);
                      camera = here - at(t * t);
                    }
                    // Set down here along no walk: the mark comes by the
                    // streets from where it stood.
                    Offset? arriving;
                    final cameFrom = widget.arriveFrom;
                    final arrivalPlan = _anchors;
                    final planScale = _planScale, planOrigin = _planOrigin;
                    if (cameFrom != null &&
                        _arrival.isAnimating &&
                        traveller == null &&
                        arrivalPlan != null &&
                        planScale != null &&
                        planOrigin != null) {
                      final start = planOrigin +
                          arrivalPlan.anchorOf(cameFrom) * planScale;
                      final metric = _road(start, here).computeMetrics().first;
                      arriving = metric
                          .getTangentForOffset(
                            metric.length *
                                Curves.easeInOut.transform(_arrival.value),
                          )!
                          .position;
                    }
                    final now = _clock.value;
                    final walkingKind =
                        walking != null && walking < steps.length
                            ? steps[walking].kind
                            : null;
                    final selectedIndex = walking ?? widget.selected;
                    Path? selectedRoad;
                    if (widget.selected != null &&
                        walking == null &&
                        widget.selected! < centres.length &&
                        steps[widget.selected!].moves &&
                        !steps[widget.selected!].locked) {
                      if (planRoads != null) {
                        selectedRoad = _trimmed(
                          planRoads[widget.selected!],
                          _hereRadius,
                          _stepRadius,
                        );
                      } else {
                        final (from, to) = _roadEnds(
                          here,
                          centres[widget.selected!],
                          width,
                        );
                        selectedRoad = _road(from, to);
                      }
                    }
                    final burning = _animate && widget.burn && now < 1.4;
                    final burnT = (now / 1.3).clamp(0.0, 1.0);
                    final panned = Transform.translate(
                      offset: camera,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The land the place lies in (v1.197), faint,
                          // under its plan.
                          if (widget.place?.biome case final biome?)
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  key: const ValueKey('journey_biome'),
                                  painter: BiomeBackdropPainter(
                                    biome: biome,
                                    land: palette.land,
                                    seed: widget.place!.seed,
                                    greyed: widget.greyed,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.place?.holderColor case final tint?)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  key: const ValueKey('journey_holder_tint'),
                                  decoration: BoxDecoration(
                                    color: tint.withValues(alpha: 0.10),
                                    border: Border.all(
                                      color: tint.withValues(alpha: 0.45),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: ValueKey(
                                  _room != null
                                      ? 'journey_room'
                                      : widget.place?.plan != null
                                          ? 'journey_streets'
                                          : 'journey_ground',
                                ),
                                painter: widget.place == null
                                    ? _ReliefPainter(
                                        palette: palette,
                                        here: here,
                                        shift: widget.terrainShift,
                                        seed: widget.terrainSeed,
                                      )
                                    : _room != null && _planScale != null
                                        ? RoomPlanPainter(
                                            plan: _room!,
                                            scale: _planScale!,
                                            origin: _planOrigin!,
                                            palette: palette,
                                            ember: widget.ink.ember,
                                          )
                                        : widget.place?.chart != null &&
                                                _planScale != null
                                            ? CityChartPainter(
                                                chart: widget.place!.chart!,
                                                palette: palette,
                                                scale: _planScale!,
                                                offset: _planOrigin!,
                                                fitted: _planFitted,
                                                explored:
                                                    widget.place!.explored,
                                                hereDistrict: widget.place!
                                                        .hereDistrict.isEmpty
                                                    ? null
                                                    : widget
                                                        .place!.hereDistrict,
                                                focusDistrict: _planScale! /
                                                            _planFitted >=
                                                        cityChartDetailZoom
                                                    ? widget.place!.hereDistrict
                                                    : null,
                                              )
                                            : widget.place!.loading
                                                ? null
                                                : PlacePlanPainter(
                                                    kind: widget.place!.kind,
                                                    seed: widget.place!.seed,
                                                    here: here,
                                                    spots: centres,
                                                    palette: palette,
                                                    ember: widget.ink.ember,
                                                    glyphs:
                                                        widget.place!.glyphs,
                                                    water: widget.place!.water,
                                                  ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _JourneyPainter(
                                palette: palette,
                                here: here,
                                hereRadius: _hereRadius,
                                stepRadius: _stepRadius,
                                steps: [
                                  for (var i = 0; i < steps.length; i++)
                                    (
                                      centre: centres[i],
                                      row: steps[i].slot.row,
                                      locked: steps[i].locked,
                                      selected:
                                          widget.selected == i || walking == i,
                                      moves: steps[i].moves,
                                    ),
                                ],
                                radial: _placeMode,
                                walking: walking,
                                progress: t,
                                roads: planRoads,
                                reveals: [
                                  for (var i = 0; i < steps.length; i++)
                                    _roadReveal(i),
                                ],
                              ),
                            ),
                          ),
                          // What each step holds, the weather, the picked
                          // road flowing, footprints (see journey_fx.dart).
                          // Its own layer (v1.209): the clock's ticks
                          // redraw it alone, not the whole map.
                          if (_animate)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: JourneyFxPainter(
                                      time: _clock,
                                      steps: [
                                        for (var i = 0; i < steps.length; i++)
                                          if (_markReveal(i) >= 1)
                                            JourneyFxStep(
                                              centre: centres[i],
                                              kind: steps[i].kind,
                                              colour: _colorFor(
                                                steps[i].kind,
                                                widget.ink,
                                                palette,
                                                greyed: widget.greyed,
                                              ),
                                              locked: steps[i].locked,
                                              row: steps[i].slot.row,
                                            ),
                                      ],
                                      here: traveller ?? here,
                                      hereRadius: _hereRadius,
                                      stepRadius: _stepRadius,
                                      mark: palette.mark,
                                      fog: palette.fog,
                                      weather: widget.greyed
                                          ? JourneyWeather.none
                                          : widget.weather,
                                      weatherColour: switch (widget.weather) {
                                        JourneyWeather.rain => Palette.cyan69,
                                        JourneyWeather.snow => Palette.paper95,
                                        JourneyWeather.dust => Palette.orange60,
                                        _ => palette.place,
                                      },
                                      selectedRoad: selectedRoad,
                                      selected: walking == null &&
                                              selectedIndex != null &&
                                              selectedIndex < steps.length &&
                                              !steps[selectedIndex].locked &&
                                              _markReveal(selectedIndex) >= 1
                                          ? selectedIndex
                                          : null,
                                      footprints: _footprints,
                                      footprintColour: palette.place,
                                      dust: _dust,
                                      dice: traveller != null &&
                                              (walkingKind ==
                                                      JourneyStepKind.check ||
                                                  walkingKind ==
                                                      JourneyStepKind.challenge)
                                          ? traveller.translate(
                                              _hereRadius * 0.9,
                                              -_hereRadius -
                                                  10 +
                                                  math.sin(now * 14).abs() * -8,
                                            )
                                          : null,
                                      diceColour: widget.ink.tide,
                                      rattle: _rattle == null ||
                                              _rattle!.$1 >= centres.length
                                          ? null
                                          : (centres[_rattle!.$1], _rattle!.$2),
                                      rattleColour: widget.ink.blood,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Where the party stood, while it walks away.
                          _hereMark(
                            here,
                            faded: traveller != null || arriving != null,
                          ),
                          // A hub's rings round it, and the beat when one of
                          // its choices is taken.
                          if (widget.rings.isNotEmpty &&
                              traveller == null &&
                              arriving == null)
                            ChoiceRingsLayer(
                              here: here,
                              innerRadius: _hereRadius,
                              rings: widget.rings,
                              lit: widget.ringLit,
                              plate: palette.land,
                              onTap: (id) => widget.onRing?.call(id),
                            ),
                          // The rings' chips, over their icons but under the marks, which the
                          // taps must reach first.
                          if (widget.rings.isNotEmpty &&
                              traveller == null &&
                              arriving == null)
                            ChoiceRingsLayer(
                              chips: true,
                              here: here,
                              innerRadius: _hereRadius,
                              rings: widget.rings,
                              lit: widget.ringLit,
                              plate: palette.land,
                              onTap: (id) => widget.onRing?.call(id),
                            ),
                          ChoiceBeat(
                            animation: _beat,
                            here: here,
                            innerRadius: _hereRadius,
                            color: _beatColor,
                            icon: _beatIcon,
                          ),
                          Positioned(
                            left: _placeMode ? 8 : here.dx + _hereRadius + 10,
                            width: _placeMode
                                ? math.min(width * 0.5, 190)
                                : math.max(0, width / 2 - _hereRadius - 16),
                            top: _placeMode ? 8 : here.dy - 18,
                            child: Opacity(
                              opacity: traveller == null ? 1 : 1 - t,
                              child: DecoratedBox(
                                // In a place, a badge in the corner: the
                                // ways ring the mark itself.
                                decoration: BoxDecoration(
                                  color: _placeMode
                                      ? palette.land.withValues(alpha: 0.85)
                                      : Palette.clear,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: _placeMode
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        )
                                      : EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.youAreHere.toUpperCase(),
                                        style: noteStyle.copyWith(
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Text(
                                        widget.hereName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: InkFonts.display,
                                          fontSize: 16,
                                          height: 1.1,
                                          color: palette.place,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // The ways on: their names, then every mark over
                          // them. Only the marks take taps, so a tap on one
                          // is its own step's, whatever name lies near it.
                          for (var i = 0; i < steps.length; i++)
                            if (nameSpots[i] case final spot?)
                              _stepName(
                                i,
                                spot,
                                placeStyle,
                                noteStyle,
                                fading: walking != null && walking != i ? t : 0,
                              ),
                          for (var i = 0; i < steps.length; i++)
                            _stepMark(
                              i,
                              centres[i],
                              fading: walking != null && walking != i ? t : 0,
                            ),
                          // The party, on the road.
                          if (traveller != null)
                            Positioned(
                              key: const ValueKey('journey_traveller'),
                              left: traveller.dx - _hereRadius,
                              top: traveller.dy - _hereRadius,
                              child: _partyMark(palette),
                            ),
                          if (arriving != null)
                            Positioned(
                              key: const ValueKey('journey_arriving'),
                              left: arriving.dx - _hereRadius,
                              top: arriving.dy - _hereRadius,
                              child: _partyMark(palette),
                            ),
                          // A place the map hadn't shown: its name stamped
                          // over the mark, ink spreading under it.
                          if (widget.stamp != null && _animate && now < 4.2)
                            ..._stampMark(here, now, width),
                        ],
                      ),
                    );
                    // The city's camera (v1.219): the map zooms in on the
                    // party while it walks, keeping it toward the middle,
                    // and out again as it arrives.
                    var chart = panned as Widget;
                    if (walking != null &&
                        walking < centres.length &&
                        traveller != null &&
                        _placeMode &&
                        _animate) {
                      final z = journeyWalkZoomAt(_walk.value);
                      if (z > 1.001) {
                        final focus = traveller + camera;
                        final k = (z - 1) / (journeyWalkZoom - 1);
                        final seen = (_scroll?.hasClients ?? false)
                            ? _scroll!.offset
                            : _openAt;
                        final middle = Offset(
                          width / 2,
                          seen + box.maxHeight / 2,
                        );
                        final target = Offset.lerp(focus, middle, k)!;
                        var d = target - focus * z;
                        // Never past the map's edges.
                        d = Offset(
                          d.dx.clamp(width * (1 - z), 0.0),
                          d.dy.clamp(seen + box.maxHeight - z * height, seen),
                        );
                        chart = Transform(
                          key: const ValueKey('journey_walk_camera'),
                          transform: Matrix4.identity()
                            ..setEntry(0, 0, z)
                            ..setEntry(1, 1, z)
                            ..setEntry(0, 3, d.dx)
                            ..setEntry(1, 3, d.dy),
                          child: panned,
                        );
                      }
                    }
                    if (!burning) return chart;
                    // A new chapter: its map burns open from the mark.
                    return Stack(
                      children: [
                        ClipPath(
                          clipper: JourneyBurnClipper(t: burnT, centre: here),
                          child: chart,
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: JourneyBurnPainter(
                                t: burnT,
                                centre: here,
                                ember: widget.ink.ember,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
            // Opened from another tab, the map unrolls down from the scene
            // on a gold rod.
            final unrolled = AnimatedBuilder(
              animation: _phase,
              child: map,
              builder: (context, child) {
                final f = _animate
                    ? Curves.easeInOutCubic.transform(
                        ((_clock.value - _unrollAt) / 0.55).clamp(0.0, 1.0),
                      )
                    : 1.0;
                if (f >= 1) return child!;
                final h = box.maxHeight;
                return Stack(
                  children: [
                    ClipRect(clipper: _TopReveal(f), child: child),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (h * f - 3).clamp(0.0, h - 6),
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [palette.mark, widget.ink.gold],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
            final flying = _flying;
            final place = widget.place;
            if (flying == null ||
                place == null ||
                flying >= steps.length ||
                steps[flying].chartTarget == null) {
              return unrolled;
            }
            // On a world road: the World view walks it (v1.548); a tap lands
            // the party at once, as the transit's does.
            if (_flyingLeg case final leg?) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  widget.roadMap!(leg, _flight),
                  Positioned.fill(
                    child: GestureDetector(
                      key: const ValueKey('journey_road_skip'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _flight.stop(canceled: false);
                        _flight.value = 1;
                      },
                    ),
                  ),
                ],
              );
            }
            // On the road: the world chart, from here to where it leads.
            return Stack(
              children: [
                unrolled,
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _flight,
                    builder: (context, _) => CustomPaint(
                      key: const ValueKey('journey_flight'),
                      painter: RegionFlightPainter(
                        geography: place.geography,
                        from: place.chartHere,
                        to: steps[flying].chartTarget!,
                        marks: place.marks,
                        t: _flight.value,
                        palette: palette,
                        fromName: widget.hereName,
                        toName: steps[flying].leadsTo ?? '',
                        route: steps[flying].route,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _stampMark(Offset here, double now, double width) {
    final palette = widget.palette;
    final spread = ((now - 0.95) / 1.1).clamp(0.0, 1.0);
    // The seal that stamps it, in pixel art (v1.216): it comes down, the
    // ink flies and it dissolves, under the name that follows.
    PixelStrips.preload(const ['moment_seal']);
    return [
      if (now >= 0.9 && now < 3.2)
        Positioned(
          left: 0,
          width: width,
          top: here.dy + _hereRadius + 10 + 13 - 48,
          height: 96,
          child: IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('journey_stamp_seal'),
              painter: PixelStripPainter(
                names: const ['moment_seal'],
                progress: ((now - 0.9) / 2.3).clamp(0.0, 0.999),
                scale: 2,
              ),
            ),
          ),
        ),
      if (spread > 0 && spread < 1)
        Positioned(
          left: here.dx - 90,
          top: here.dy - 90,
          width: 180,
          height: 180,
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - spread) * 0.7,
              child: Transform.scale(
                scale: 0.3 + spread * 1.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        palette.mark.withValues(alpha: 0.5),
                        palette.mark.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _partyMark(ChartPalette palette) => Container(
        width: _hereRadius * 2,
        height: _hereRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.mark,
          border: Border.all(color: palette.land, width: 3),
          boxShadow: [
            BoxShadow(
                color: palette.mark.withValues(alpha: 0.35), blurRadius: 12),
          ],
        ),
        child: Icon(Icons.person_pin, color: palette.land, size: IconSize.s32),
      );

  Widget _hereMark(Offset here, {required bool faded}) {
    final palette = widget.palette;
    return Positioned(
      left: here.dx - _hereRadius,
      top: here.dy - _hereRadius,
      child: faded
          ? Container(
              width: _hereRadius * 2,
              height: _hereRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.mark.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            )
          : _partyMark(palette),
    );
  }

  /// One of a step's ways on, a small mark above it in the fog.
  Widget _glimpse(
    int f,
    int count,
    JourneyStepKind kind,
    ChartPalette palette,
  ) {
    final angle = count == 1 ? 0.0 : (f / (count - 1) - 0.5) * (math.pi / 2.2);
    const size = 12.0;
    final centre = Offset(
      _stepRadius + math.sin(angle) * (_stepRadius + 10),
      _stepRadius - math.cos(angle) * (_stepRadius + 10),
    );
    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      child: Icon(
        _iconFor(kind),
        size: size,
        color: palette.label.withValues(alpha: 0.75),
      ),
    );
  }

  /// How much room step [step]'s name takes on the map, at most [w] wide:
  /// its words (three lines at most) and where it leads, on their plaque.
  Size _nameSize(
    _Step step,
    double w,
    TextStyle placeStyle,
    TextStyle noteStyle,
    TextScaler scaler, {
    required bool selected,
  }) {
    Size measure(String text, TextStyle style, int lines) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: lines,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0, w - 6));
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final words = measure(
      step.label,
      placeStyle.copyWith(
        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
      ),
      3,
    );
    final to = step.leadsTo == null
        ? Size.zero
        : measure(
            widget.leadsTo.replaceAll('{place}', step.leadsTo!),
            noteStyle,
            1,
          );
    // The way's tag (a price, a check, a fight) under its words (v1.854).
    final tag = step.tag;
    final tagged = tag == null
        ? Size.zero
        : Size(measure(tag.label, noteStyle, 1).width + 16, 20);
    return Size(
      math.max(math.max(words.width, to.width), tagged.width) + 6,
      words.height + to.height + tagged.height + 2,
    );
  }

  /// Step [i]'s name on its plaque, in [spot] (see journeyLabelSpots). It
  /// takes no taps: its mark, drawn over every name, takes them.
  Widget _stepName(
    int i,
    Rect spot,
    TextStyle placeStyle,
    TextStyle noteStyle, {
    required double fading,
  }) {
    final step = widget.steps[i];
    final palette = widget.palette;
    final isSelected = widget.selected == i || _walking == i;
    // The words fade up once the mark has popped in.
    final pop = _markReveal(i);
    return Positioned(
      left: spot.left,
      top: spot.top,
      width: spot.width,
      child: IgnorePointer(
        // Said by the mark (see _stepMark).
        child: ExcludeSemantics(
          child: Opacity(
            opacity: (1 - fading * 0.7) * pop.clamp(0.0, 1.0),
            child: Column(
              children: [
                // A plaque under the words: the roads to the far steps
                // pass beneath it.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.land.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    child: Column(
                      children: [
                        Text(
                          step.label,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: placeStyle.copyWith(
                            color: palette.place.withValues(
                              alpha: step.locked ? 0.55 : 1,
                            ),
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                        if (step.leadsTo != null)
                          Text(
                            widget.leadsTo.replaceAll('{place}', step.leadsTo!),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: noteStyle,
                          ),
                        if (step.tag case final tag?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: ChoiceTagChip(
                              key: ValueKey('journey_pin_tag_$i'),
                              tag: tag,
                              locked: step.locked,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Step [i]'s mark at [centre]: the step's own tap, no wider than it.
  Widget _stepMark(int i, Offset centre, {required double fading}) {
    final step = widget.steps[i];
    final palette = widget.palette;
    final colour = step.locked
        ? palette.label
        : _colorFor(step.kind, widget.ink, palette, greyed: widget.greyed);
    final isSelected = widget.selected == i || _walking == i;
    // Most ways hang as a banner in their category's colour (see
    // journey_banner_pin.dart); fights and rolls keep their round marks.
    final cat = journeyPinCatOf(step.kind, step.questTie);
    final dark = journeyInkIsDark(widget.ink);
    final bannerColour = cat == null
        ? colour
        : step.locked
            ? palette.label
            : widget.greyed && cat != JourneyPinCat.main
                ? palette.place
                : cat.colorOn(widget.ink, dark: dark);
    // A new scene: the mark pops in once its road reaches it, and the
    // words fade up after.
    final pop = _markReveal(i);
    final popScale = pop >= 1 ? 1.0 : Curves.easeOutBack.transform(pop);
    // A shut way tapped shakes its padlock.
    final rattle = _rattle;
    final rattleAge =
        rattle != null && rattle.$1 == i ? _clock.value - rattle.$2 : 1.0;
    final shake = rattleAge < 0.45
        ? math.sin(rattleAge * 42) * 0.35 * (1 - rattleAge / 0.45)
        : 0.0;
    return Positioned(
      left: centre.dx - _stepRadius,
      top: centre.dy - _stepRadius,
      width: _stepRadius * 2,
      height: _stepRadius * 2,
      child: Opacity(
        opacity: (1 - fading * 0.7) * pop.clamp(0.0, 1.0),
        child: Semantics(
          button: true,
          selected: isSelected,
          label: step.label,
          child: GestureDetector(
            key: ValueKey('journey_step_${widget.stepIds?[i] ?? i}'),
            behavior: HitTestBehavior.opaque,
            onTap: _walking == null
                ? () {
                    if (step.locked && _animate) {
                      _rattle = (i, _clock.value);
                      _lastEvent = _clock.value;
                      _wake();
                    }
                    widget.onTap(i, step);
                  }
                : null,
            child: AnimatedScale(
              scale: (isSelected ? 1.15 : 1) * popScale,
              duration:
                  pop >= 1 ? const Duration(milliseconds: 160) : Duration.zero,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (cat != null)
                    Center(
                      child: Transform.rotate(
                        angle: shake,
                        child: BannerPin(
                          cat: cat,
                          color: bannerColour,
                          dark: dark,
                          icon: step.locked ? Icons.lock_outline : null,
                          lit: isSelected,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: _stepRadius * 2,
                      height: _stepRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colour : palette.land,
                        border: Border.all(
                          color: colour,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Transform.rotate(
                        angle: shake,
                        child: step.locked
                            ? PixelGlyph(
                                PixelGlyphs.lock,
                                size: IconSize.s16,
                                color: isSelected ? palette.land : colour,
                              )
                            // Its own layer: a breath repaints the glyph, not
                            // the chart under it.
                            : RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _idleGlyphs,
                                  builder: (context, _) => journeyIdleGlyph(
                                    glyph: step.glyph,
                                    colour: isSelected ? palette.land : colour,
                                    t: _idleGlyphs.value * 12,
                                    phase: i * 0.9,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  // Tied to a quest: a small bookmark on the mark, gold for
                  // the main quest, the place's ink for a side job.
                  if (step.questTie != null && !step.locked && cat == null)
                    Positioned(
                      key: ValueKey(
                        'journey_quest_badge_${widget.stepIds?[i] ?? i}',
                      ),
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.questTie == JourneyQuestTie.main
                              ? widget.ink.gold
                              : palette.place,
                          border: Border.all(color: palette.land, width: 1.5),
                        ),
                        child: Icon(
                          step.questTie == JourneyQuestTie.main
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: IconSize.inline,
                          color: palette.land,
                        ),
                      ),
                    ),
                  // What lies past the step, glimpsed through the fog: the
                  // kinds of its own ways on.
                  if (!step.locked && pop >= 1)
                    for (var f = 0; f < step.onwardKinds.length; f++)
                      _glimpse(
                        f,
                        step.onwardKinds.length,
                        step.onwardKinds[f],
                        palette,
                      ),
                  // What waits on the road there.
                  if (step.event != null)
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: Container(
                        key: ValueKey(
                          'journey_event_${widget.stepIds?[i] ?? i}',
                        ),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _eventColour(step.event!, widget.ink),
                          border: Border.all(color: palette.land, width: 1.5),
                        ),
                        child: Icon(
                          _eventIcon(step.event!, hazard: step.hazard),
                          size: IconSize.inline,
                          color: palette.land,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
