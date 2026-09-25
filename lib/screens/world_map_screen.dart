import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/stitched_ink.dart';
import '../widgets/chart_map_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';

const String _pixelFont = 'PixelifySans';
const String _textFont = 'Spectral';

/// What the map showed last time it was opened: how far into the
/// journey, and where, so the next opening walks what came after.
const String worldMapSeenPrefsKey = 'world_map_seen';

const double _maxZoom = 6;

/// The map page's own colours, as the map was first drawn with, for a
/// dark and a light app.
class _Tokens {
  const _Tokens(
      this.bg, this.panel, this.ink, this.muted, this.line, this.accent);

  final Color bg;
  final Color panel;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;

  static const dark = _Tokens(
    Color(0xFF1A181E),
    Color(0xFF24212A),
    Color(0xFFECE7DC),
    Color(0xFFA8A194),
    Color(0xFF3B3743),
    Color(0xFFF2C14E),
  );
  static const light = _Tokens(
    Color(0xFFDEDAD2),
    Color(0xFFF1EEE8),
    Color(0xFF1F1C22),
    Color(0xFF5B564E),
    Color(0xFFC4BFB4),
    Color(0xFF8A5A00),
  );
}

String _lookName(WidgetRef ref, MapLook look) =>
    tr(ref, 'world_map_look_${look.name}');

/// The story's world as a pixel map, for play mode: the places the story
/// has reached, the road the player walked between them, the player
/// walking what they have done since the map last showed, and fog over
/// the rest. Tapping a place tells what happens there.
class WorldMapPage extends ConsumerStatefulWidget {
  const WorldMapPage({super.key});

  @override
  ConsumerState<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends ConsumerState<WorldMapPage>
    with TickerProviderStateMixin {
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  Timer? _timer;
  bool _reduceMotion = false;
  String? _selectedId;
  int _chapterFilter = 0;

  /// The geography the chart is drawn on (see map_charts.dart).
  ChartGeography _geo = chartOf(MapShape.continental);

  final TransformationController _view = TransformationController();
  late final AnimationController _zoom = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
  Animation<Matrix4>? _zoomTo;
  Offset? _doubleTapAt;

  /// The map's drawing area, in logical pixels (the child of the zoom).
  Size _mapSize = Size.zero;

  late final AnimationController _walk = AnimationController(vsync: this);
  List<(double, double)> _walkPath = const [];
  bool _walking = false;

  bool _seenLoaded = false;
  int? _seenSteps;
  String? _seenLast;
  bool _walkDecided = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final to = _zoomTo;
      if (to != null) _view.value = to.value;
    });
    _walk.addListener(_follow);
    _walk.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _walking = false);
      }
    });
    _loadSeen();
  }

  Future<void> _loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(worldMapSeenPrefsKey);
    if (raw != null) {
      try {
        final data = json.decode(raw) as Map<String, dynamic>;
        _seenSteps = (data['steps'] as num?)?.toInt();
        _seenLast = data['last']?.toString();
      } catch (_) {
        // An unreadable record only means the last leg is walked.
      }
    }
    if (mounted) setState(() => _seenLoaded = true);
  }

  Future<void> _saveSeen(List<Landmark> journey) async {
    if (journey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(worldMapSeenPrefsKey,
        json.encode({'steps': journey.length, 'last': journey.last.id}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The water glints, the embers flicker and the road's dashes move,
    // unless the device asks for less motion.
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(
          const Duration(milliseconds: 220), (_) => _frame.value++);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frame.dispose();
    _zoom.dispose();
    _walk.dispose();
    _view.dispose();
    super.dispose();
  }

  // ---- Zoom ----------------------------------------------------------

  double get _scale => _view.value.storage[0];

  /// The view [scale]× over the map, centred as near [focus] (a point on
  /// the map's drawing area) as its edges allow.
  Matrix4 _viewAt(Offset focus, double scale) {
    final w = _mapSize.width, h = _mapSize.height;
    final tx = (w / 2 - focus.dx * scale).clamp(w - w * scale, 0.0);
    final ty = (h / 2 - focus.dy * scale).clamp(h - h * scale, 0.0);
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  /// The point on the map at the middle of the view.
  Offset get _viewCentre {
    final m = _view.value.storage;
    return Offset((_mapSize.width / 2 - m[12]) / m[0],
        (_mapSize.height / 2 - m[13]) / m[0]);
  }

  void _animateView(Matrix4 target) {
    if (_reduceMotion) {
      _view.value = target;
      return;
    }
    _zoomTo = Matrix4Tween(begin: _view.value, end: target)
        .animate(CurvedAnimation(parent: _zoom, curve: Curves.easeOutCubic));
    _zoom.forward(from: 0);
  }

  void _zoomBy(double factor) {
    if (_mapSize.isEmpty) return;
    final scale = (_scale * factor).clamp(1.0, _maxZoom);
    _animateView(
        scale <= 1.001 ? Matrix4.identity() : _viewAt(_viewCentre, scale));
  }

  Offset _onMap((double, double) point) {
    final k = _mapSize.width / worldMapWidth;
    return Offset(point.$1 * k, point.$2 * k);
  }

  void _centreOn(Landmark? here) {
    if (here == null || _mapSize.isEmpty) return;
    _animateView(_viewAt(
        _onMap(ChartMapPainter.spotOn(_geo, here)), math.max(_scale, 3)));
  }

  void _doubleTap() {
    final at = _doubleTapAt;
    if (at == null || _mapSize.isEmpty) return;
    _animateView(_scale < 2.5
        ? _viewAt(at, math.min(_scale * 2.5, _maxZoom))
        : Matrix4.identity());
  }

  // ---- The traveller ---------------------------------------------------

  void _startWalk(List<Landmark> legs, Duration perLeg) {
    if (legs.length < 2) return;
    _walkPath = [for (final l in legs) ChartMapPainter.spotOn(_geo, l)];
    _walk.duration = perLeg * (legs.length - 1);
    setState(() => _walking = true);
    _walk.forward(from: 0);
  }

  void _replay(List<Landmark> journey) {
    if (journey.length < 2) return;
    final perLeg = math.min(300, 9000 ~/ (journey.length - 1));
    _startWalk(journey, Duration(milliseconds: perLeg));
  }

  /// Zoomed in, the view keeps the walking traveller in sight.
  void _follow() {
    if (!_walking || _mapSize.isEmpty || _scale <= 1.05) return;
    if (_zoom.isAnimating) return;
    _view.value = _viewAt(_onMap(pointAlong(_walkPath, _walk.value)), _scale);
  }

  void _tapAt(Offset position, Set<String> discovered) {
    if (_mapSize.isEmpty) return;
    final k = _mapSize.width / worldMapWidth;
    final mx = position.dx / k, my = position.dy / k;
    Landmark? nearest;
    var best = 12.0 * 12.0;
    for (final landmark in worldMapLandmarks) {
      if (!discovered.contains(landmark.id)) continue;
      final at = _geo.of(landmark);
      final dx = at.dx - mx, dy = at.dy - my;
      final d = dx * dx + dy * dy;
      if (d <= best) {
        best = d;
        nearest = landmark;
      }
    }
    if (nearest != null) setState(() => _selectedId = nearest!.id);
  }

  /// The next place the story goes after [here] that it has not reached.
  Landmark? _nextPlace(Landmark? here, Set<String> discovered) {
    if (here == null) return null;
    final index = worldMapLandmarks.indexOf(here);
    for (var i = index + 1; i < worldMapLandmarks.length; i++) {
      if (!discovered.contains(worldMapLandmarks[i].id)) {
        return worldMapLandmarks[i];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final play = ref.watch(storyPlayProvider);
    final session = ref.watch(playerSessionProvider);
    final language = ref.watch(appLanguageProvider);
    final look = ref.watch(mapLookProvider);
    final palette = ChartPalette.of(look);
    final shape = ref.watch(mapShapeProvider);
    _geo = chartOf(shape);
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    final visited = {...play.visitedNodeIds, play.currentNodeId};
    final here = currentLandmark(play.currentNodeId, play.history);
    final journey = journeyOf(play.history, play.currentNodeId);
    final discovered = discoveredLandmarkIds(visited);
    if (here != null) discovered.add(here.id);
    if (discovered.isEmpty) discovered.add(worldMapLandmarks.first.id);

    // On opening, the traveller walks what the story did since the map
    // last showed.
    if (_seenLoaded && !_walkDecided) {
      _walkDecided = true;
      final start =
          journeyWalkStart(journey, seenSteps: _seenSteps, seenLast: _seenLast);
      _saveSeen(journey);
      if (!_reduceMotion && start < journey.length - 1) {
        final legs = journey.sublist(start);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startWalk(legs, const Duration(milliseconds: 550));
          }
        });
      }
    }

    final reached = [
      for (final landmark in worldMapLandmarks)
        if (discovered.contains(landmark.id)) landmark,
    ];
    final selected = (_selectedId == null || !discovered.contains(_selectedId)
            ? null
            : landmarkById(_selectedId!)) ??
        here ??
        reached.first;
    final chaptersReached = {for (final l in reached) l.chapter}.toList()
      ..sort();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tokens = dark ? _Tokens.dark : _Tokens.light;
    Color chapterColor(int n) =>
        dark ? mapChapter(n).dark : mapChapter(n).light;

    Widget mapBox(double width) {
      final inner = width - 8;
      _mapSize = Size(inner, inner * worldMapHeight / worldMapWidth);
      return SizedBox(
        width: width,
        height: _mapSize.height + 8,
        child: Semantics(
          label: tr(ref, 'world_map_semantics'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.sea,
              border: Border.all(color: tokens.line, width: 4),
            ),
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _view,
                maxScale: _maxZoom,
                child: GestureDetector(
                  key: const Key('world_map_canvas'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _tapAt(details.localPosition, discovered),
                  onDoubleTapDown: (details) =>
                      _doubleTapAt = details.localPosition,
                  onDoubleTap: _doubleTap,
                  child: CustomPaint(
                    size: _mapSize,
                    painter: ChartMapPainter(
                      frame: _frame,
                      walk: _walk,
                      geography: _geo,
                      palette: palette,
                      language: language,
                      discovered: discovered,
                      legs: roadLegs(journey, discovered),
                      ahead: _nextPlace(here, discovered),
                      selectedId: selected.id,
                      here: here,
                      walking: _walking,
                      walkPath: _walkPath,
                      chapterFilter: _chapterFilter,
                      reduceMotion: _reduceMotion,
                      chapterColor: chapterColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Under the map, never over it: zoom, back to where the story stands,
    // the journey walked again, and the map's look.
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MapControls(
          tokens: tokens,
          onZoomIn: () => _zoomBy(1.6),
          onZoomOut: () => _zoomBy(1 / 1.6),
          onCentre: here == null ? null : () => _centreOn(here),
          onReplay: journey.length < 2 || _reduceMotion
              ? null
              : () => _replay(journey),
        ),
        // The three looks side by side, the one shown picked out.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            key: const Key('world_map_look'),
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tokens.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in MapLook.values)
                  Semantics(
                    button: true,
                    selected: option == look,
                    child: InkWell(
                      key: Key('world_map_look_${option.name}'),
                      onTap: () =>
                          ref.read(mapLookProvider.notifier).choose(option),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        color:
                            option == look ? tokens.line : Colors.transparent,
                        child: Text(_lookName(ref, option),
                            style: TextStyle(
                                fontFamily: _pixelFont,
                                fontSize: 14,
                                color: option == look
                                    ? tokens.ink
                                    : tokens.muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The three geographies the chart can be drawn on.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            key: const Key('world_map_shape'),
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tokens.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in MapShape.values)
                  Semantics(
                    button: true,
                    selected: option == shape,
                    child: InkWell(
                      key: Key('world_map_shape_${option.name}'),
                      onTap: () =>
                          ref.read(mapShapeProvider.notifier).choose(option),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        color:
                            option == shape ? tokens.line : Colors.transparent,
                        child: Text(tr(ref, 'world_map_shape_${option.name}'),
                            style: TextStyle(
                                fontFamily: _pixelFont,
                                fontSize: 14,
                                color: option == shape
                                    ? tokens.ink
                                    : tokens.muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final n in [0, ...chaptersReached])
          _PixelChip(
            key: Key('world_map_chip_$n'),
            label: n == 0
                ? tr(ref, 'world_map_all')
                : '${tr(ref, 'world_map_chapter_short')} $n',
            selected: _chapterFilter == n,
            color: n == 0 ? tokens.accent : chapterColor(n),
            tokens: tokens,
            onTap: () => setState(() {
              _chapterFilter = n;
              if (n != 0) {
                _selectedId = reached.firstWhere((l) => l.chapter == n).id;
              }
            }),
          ),
      ],
    );

    // Back and Next walk the road through the places reached, skipping
    // the ones the story went around (the alley or the bridge, Tern Row).
    final index = worldMapLandmarks.indexOf(selected);
    Landmark? previous;
    for (var i = index - 1; i >= 0 && previous == null; i--) {
      if (discovered.contains(worldMapLandmarks[i].id)) {
        previous = worldMapLandmarks[i];
      }
    }
    Landmark? next;
    for (var i = index + 1; i < worldMapLandmarks.length && next == null; i++) {
      if (discovered.contains(worldMapLandmarks[i].id)) {
        next = worldMapLandmarks[i];
      }
    }
    final panel = _LandmarkPanel(
      landmark: selected,
      language: language,
      tokens: tokens,
      chapterColor: chapterColor(selected.chapter),
      isHere: selected.id == here?.id,
      scenesRead: selected.scenes.where(visited.contains).length,
      fights: _fightsAt(selected, session, visited, enemies),
      previous: previous,
      next: next,
      atRoadsEnd: index == worldMapLandmarks.length - 1,
      onSelect: (id) => setState(() => _selectedId = id),
    );

    final hint = Text(
      tr(ref, 'world_map_hint'),
      style: TextStyle(
          fontFamily: _textFont,
          fontSize: 14,
          height: 1.45,
          color: tokens.muted),
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          tr(ref, 'world_map_title'),
          style: TextStyle(
              fontFamily: InkFonts.display, fontSize: 24, color: tokens.ink),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            final width = math.min((constraints.maxWidth - 48) * 0.62,
                (constraints.maxHeight - 230) * worldMapWidth / worldMapHeight);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        mapBox(width),
                        const SizedBox(height: 8),
                        controls,
                        const SizedBox(height: 8),
                        hint,
                        const SizedBox(height: 10),
                        chips,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: SingleChildScrollView(child: panel)),
                ],
              ),
            );
          }
          // On a phone the map stays put above the text, so pinching and
          // panning it never fights the page's scrolling.
          final width = math.min(constraints.maxWidth - 32,
              constraints.maxHeight * 0.55 * worldMapWidth / worldMapHeight);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Center(child: mapBox(width)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(width: width, child: controls),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    hint,
                    const SizedBox(height: 10),
                    chips,
                    const SizedBox(height: 14),
                    panel,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// What is fought at [landmark]: each foe once, with how many; a foe
  /// not beaten yet keeps its name to itself.
  List<_Fight> _fightsAt(
    Landmark landmark,
    PlayerSession session,
    Set<String> visited,
    Map<String, dynamic> enemies,
  ) {
    final counts = <String, int>{};
    for (final id in landmark.fights) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        () {
          final id = entry.key;
          if (id == '@first_ally') {
            return _Fight(
              visited.contains('7002_betrayal')
                  ? tr(ref, 'world_map_first_ally')
                  : null,
              entry.value,
            );
          }
          final beaten = (session.enemyKillCounts[id] ?? 0) > 0;
          final record = enemies[id] as Map<String, dynamic>?;
          final name = record == null ? id : '${record['enemyName'] ?? id}';
          return _Fight(beaten ? name : null, entry.value);
        }(),
    ];
  }
}

/// A foe at a landmark; [name] is null until it has been beaten.
class _Fight {
  const _Fight(this.name, this.count);
  final String? name;
  final int count;
}

/// Zoom in and out, back to where the story stands, and the whole
/// journey walked again.
class _MapControls extends ConsumerWidget {
  const _MapControls({
    required this.tokens,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCentre,
    required this.onReplay,
  });

  final _Tokens tokens;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onCentre;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget button(String key, IconData icon, String tip, VoidCallback? onTap) =>
        Tooltip(
          message: tip,
          child: Material(
            color: tokens.panel,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: tokens.line, width: 2),
            ),
            child: InkWell(
              key: Key(key),
              onTap: onTap,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(icon,
                    size: 20,
                    color: onTap == null
                        ? tokens.muted.withValues(alpha: 0.5)
                        : tokens.ink),
              ),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button('world_map_zoom_in', Icons.add, tr(ref, 'world_map_zoom_in'),
            onZoomIn),
        const SizedBox(width: 6),
        button('world_map_zoom_out', Icons.remove,
            tr(ref, 'world_map_zoom_out'), onZoomOut),
        const SizedBox(width: 6),
        button('world_map_centre', Icons.my_location,
            tr(ref, 'world_map_centre'), onCentre),
        const SizedBox(width: 6),
        button('world_map_replay', Icons.directions_walk,
            tr(ref, 'world_map_replay'), onReplay),
      ],
    );
  }
}

class _PixelChip extends StatelessWidget {
  const _PixelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final _Tokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: selected ? color : tokens.line),
          ),
          child: Text(
            label,
            style: TextStyle(
                fontFamily: _pixelFont,
                fontSize: 15,
                color: selected
                    ? (ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A1408))
                    : tokens.ink),
          ),
        ),
      ),
    );
  }
}

class _LandmarkPanel extends ConsumerWidget {
  const _LandmarkPanel({
    required this.landmark,
    required this.language,
    required this.tokens,
    required this.chapterColor,
    required this.isHere,
    required this.scenesRead,
    required this.fights,
    required this.previous,
    required this.next,
    required this.atRoadsEnd,
    required this.onSelect,
  });

  final Landmark landmark;
  final AppLanguage language;
  final _Tokens tokens;
  final Color chapterColor;
  final bool isHere;
  final int scenesRead;
  final List<_Fight> fights;

  /// The reached places before and after this one on the road.
  final Landmark? previous;
  final Landmark? next;

  /// Nothing lies further: the road ends here.
  final bool atRoadsEnd;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextStyle pixel(double size, {Color? color, FontWeight? weight}) =>
        TextStyle(
          fontFamily: _pixelFont,
          fontSize: size,
          color: color ?? tokens.ink,
          fontWeight: weight,
          height: 1.15,
        );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(text, style: pixel(15, color: tokens.muted)),
        );

    Widget tag(String text, {Color? border}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tokens.bg,
            border: Border.all(color: border ?? tokens.line),
          ),
          child: Text(text, style: pixel(14)),
        );

    Widget navButton(String key, String text, VoidCallback? onTap) => Expanded(
          child: OutlinedButton(
            key: Key(key),
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: tokens.bg,
              foregroundColor: tokens.ink,
              disabledForegroundColor: tokens.ink.withValues(alpha: 0.35),
              side: BorderSide(color: tokens.line, width: 2),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            child: Text(text, textAlign: TextAlign.center, style: pixel(14)),
          ),
        );

    return Container(
      key: const Key('world_map_panel'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: tokens.panel,
        border: Border.all(color: tokens.line, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mapChapter(landmark.chapter).title(language),
              style: pixel(15, color: chapterColor)),
          const SizedBox(height: 4),
          Text(landmark.name(language),
              style: TextStyle(
                  fontFamily: InkFonts.display,
                  fontSize: 28,
                  height: 1.1,
                  color: tokens.ink)),
          if (isHere)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place, size: 18, color: tokens.accent),
                  const SizedBox(width: 4),
                  Text(tr(ref, 'world_map_here'),
                      style: pixel(15, color: tokens.accent)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            landmark.blurb(language),
            style: TextStyle(
              fontFamily: _textFont,
              fontSize: 17,
              height: 1.6,
              color: tokens.ink,
            ),
          ),
          label('${tr(ref, 'world_map_scenes_read')}: '
              '$scenesRead / ${landmark.scenes.length}'),
          if (fights.isNotEmpty) ...[
            label(tr(ref, 'world_map_fights')),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final fight in fights)
                  tag(
                    '${fight.name ?? '???'}'
                    '${fight.count > 1 ? ' ×${fight.count}' : ''}',
                    border: const Color(0xFF9B2A2A),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              navButton(
                'world_map_back',
                '${tr(ref, 'world_map_back')}: '
                    '${previous?.name(language) ?? tr(ref, 'world_map_start')}',
                previous == null ? null : () => onSelect(previous!.id),
              ),
              const SizedBox(width: 8),
              navButton(
                'world_map_next',
                '${tr(ref, 'world_map_next')}: '
                    '${next?.name(language) ?? (atRoadsEnd ? tr(ref, 'world_map_end') : '???')}',
                next == null ? null : () => onSelect(next!.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
