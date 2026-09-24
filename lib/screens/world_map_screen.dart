import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';

const String _pixelFont = 'PixelifySans';

/// The story's world as a pixel map, for play mode: the places the story
/// has reached, the road between them, where the story stands now, and
/// fog over the rest. Tapping a place tells what happens there.
class WorldMapPage extends ConsumerStatefulWidget {
  const WorldMapPage({super.key});

  @override
  ConsumerState<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends ConsumerState<WorldMapPage> {
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  Timer? _timer;
  bool _reduceMotion = false;
  String? _selectedId;
  int _chapterFilter = 0;
  ui.Image? _ground;
  Uint8List _fog = Uint8List(0);
  String _groundKey = '';

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
    _ground?.dispose();
    super.dispose();
  }

  /// The terrain with fog over what the story has not reached, drawn into
  /// an image once per set of reached places.
  void _prepareGround(Set<String> discovered) {
    final key = (discovered.toList()..sort()).join(',');
    if (key == _groundKey && _ground != null) return;
    _groundKey = key;
    final fog = fogMask(discovered);
    final pixels = worldMapTerrain.pixels;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < worldMapHeight; y++) {
      var runStart = 0;
      var runColor = -1;
      for (var x = 0; x <= worldMapWidth; x++) {
        var color = -1;
        if (x < worldMapWidth) {
          final i = y * worldMapWidth + x;
          color = fog[i] == 1 ? foggedColor(pixels[i]) : pixels[i];
        }
        if (color == runColor) continue;
        if (runColor != -1) {
          paint.color = Color(runColor);
          canvas.drawRect(
              Rect.fromLTWH(runStart.toDouble(), y.toDouble(),
                  (x - runStart).toDouble(), 1),
              paint);
        }
        runStart = x;
        runColor = color;
      }
    }
    final picture = recorder.endRecording();
    _ground?.dispose();
    _ground = picture.toImageSync(worldMapWidth, worldMapHeight);
    picture.dispose();
    _fog = fog;
  }

  void _tapAt(Offset position, Size size, Set<String> discovered) {
    final scale = size.width / worldMapWidth;
    final mx = position.dx / scale, my = position.dy / scale;
    Landmark? nearest;
    var best = 12.0 * 12.0;
    for (final landmark in worldMapLandmarks) {
      if (!discovered.contains(landmark.id)) continue;
      final dx = landmark.x - mx, dy = landmark.y - my;
      final d = dx * dx + dy * dy;
      if (d <= best) {
        best = d;
        nearest = landmark;
      }
    }
    if (nearest != null) setState(() => _selectedId = nearest!.id);
  }

  @override
  Widget build(BuildContext context) {
    final play = ref.watch(storyPlayProvider);
    final session = ref.watch(playerSessionProvider);
    final language = ref.watch(appLanguageProvider);
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    final visited = {...play.visitedNodeIds, play.currentNodeId};
    final here = currentLandmark(play.currentNodeId, play.history);
    final discovered = discoveredLandmarkIds(visited);
    if (here != null) discovered.add(here.id);
    if (discovered.isEmpty) discovered.add(worldMapLandmarks.first.id);
    _prepareGround(discovered);

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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    Color chapterColor(int n) =>
        dark ? mapChapter(n).dark : mapChapter(n).light;

    final map = Semantics(
      label: tr(ref, 'world_map_semantics'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0D2129),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 4),
        ),
        child: AspectRatio(
          aspectRatio: worldMapWidth / worldMapHeight,
          child: ClipRect(
            child: InteractiveViewer(
              maxScale: 6,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  key: const Key('world_map_canvas'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _tapAt(details.localPosition, box.biggest, discovered),
                  child: CustomPaint(
                    size: box.biggest,
                    painter: _WorldMapPainter(
                      frame: _frame,
                      ground: _ground!,
                      fog: _fog,
                      discovered: discovered,
                      selectedId: selected.id,
                      hereId: here?.id,
                      chapterFilter: _chapterFilter,
                      reduceMotion: _reduceMotion,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
            color: n == 0 ? theme.colorScheme.primary : chapterColor(n),
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
    final atRoadsEnd = index == worldMapLandmarks.length - 1;
    final panel = _LandmarkPanel(
      landmark: selected,
      language: language,
      chapterColor: chapterColor(selected.chapter),
      isHere: selected.id == here?.id,
      scenesRead: selected.scenes.where(visited.contains).length,
      fights: _fightsAt(selected, session, visited, enemies),
      previous: previous,
      next: next,
      atRoadsEnd: atRoadsEnd,
      onSelect: (id) => setState(() => _selectedId = id),
    );

    final hint = Text(
      tr(ref, 'world_map_hint'),
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'world_map_title'))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 165,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          map,
                          const SizedBox(height: 8),
                          hint,
                          const SizedBox(height: 10),
                          chips,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 100,
                    child: SingleChildScrollView(child: panel),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              map,
              const SizedBox(height: 8),
              hint,
              const SizedBox(height: 10),
              chips,
              const SizedBox(height: 14),
              panel,
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

class _PixelChip extends StatelessWidget {
  const _PixelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? scheme.surfaceContainerHighest : null,
            border: Border.all(
                color: selected ? color : scheme.outlineVariant, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
                fontFamily: _pixelFont, fontSize: 15, color: scheme.onSurface),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    TextStyle pixel(double size, {Color? color, FontWeight? weight}) =>
        TextStyle(
          fontFamily: _pixelFont,
          fontSize: size,
          color: color ?? scheme.onSurface,
          fontWeight: weight,
          height: 1.15,
        );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(text, style: pixel(15, color: muted)),
        );

    Widget tag(String text, {Color? border}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border.all(color: border ?? scheme.outlineVariant),
          ),
          child: Text(text, style: pixel(14)),
        );

    return Container(
      key: const Key('world_map_panel'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outlineVariant, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mapChapter(landmark.chapter).title(language),
              style: pixel(15, color: chapterColor)),
          const SizedBox(height: 4),
          Text(landmark.name(language),
              style: pixel(26, weight: FontWeight.w600)),
          if (isHere)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place, size: 18, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(tr(ref, 'world_map_here'),
                      style: pixel(15, color: scheme.primary)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            landmark.blurb(language),
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontFamily: 'serif', height: 1.5),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('world_map_back'),
                  onPressed:
                      previous == null ? null : () => onSelect(previous!.id),
                  child: Text(
                    '${tr(ref, 'world_map_back')}: '
                    '${previous?.name(language) ?? tr(ref, 'world_map_start')}',
                    textAlign: TextAlign.center,
                    style: pixel(14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('world_map_next'),
                  onPressed: next == null ? null : () => onSelect(next!.id),
                  child: Text(
                    '${tr(ref, 'world_map_next')}: '
                    '${next?.name(language) ?? (atRoadsEnd ? tr(ref, 'world_map_end') : '???')}',
                    textAlign: TextAlign.center,
                    style: pixel(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({
    required this.frame,
    required this.ground,
    required this.fog,
    required this.discovered,
    required this.selectedId,
    required this.hereId,
    required this.chapterFilter,
    required this.reduceMotion,
  }) : super(repaint: frame);

  final ValueNotifier<int> frame;
  final ui.Image ground;
  final Uint8List fog;
  final Set<String> discovered;
  final String selectedId;
  final String? hereId;
  final int chapterFilter;
  final bool reduceMotion;

  static final Paint _pixel = Paint()..isAntiAlias = false;
  static const Color _gold = Color(0xFFF2C14E);
  static const List<Color> _embers = [
    Color(0xFFE0762B),
    Color(0xFFF2C14E),
    Color(0xFF9B2A2A),
  ];

  void _dot(Canvas canvas, num x, num y, Color color,
      [num width = 1, num height = 1]) {
    _pixel.color = color;
    canvas.drawRect(
        Rect.fromLTWH(
            x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
        _pixel);
  }

  bool _clear(int x, int y) =>
      x >= 0 &&
      y >= 0 &&
      x < worldMapWidth &&
      y < worldMapHeight &&
      fog[y * worldMapWidth + x] == 0;

  bool _active(Landmark l) => chapterFilter == 0 || l.chapter == chapterFilter;

  (int, int) _spriteSize(String sprite, int scale) {
    final rows = mapSprites[sprite]!;
    return (rows.first.length * scale, rows.length * scale);
  }

  void _sprite(Canvas canvas, String name, num cx, num cy, int scale,
      {bool swap = false, double opacity = 1}) {
    final rows = mapSprites[name]!;
    final (w, h) = _spriteSize(name, scale);
    final ox = (cx - w / 2).round(), oy = (cy - h / 2).round();
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        var letter = rows[r][c];
        if (letter == '.' || letter == ' ') continue;
        if (swap) {
          if (letter == 'p') {
            letter = 'P';
          } else if (letter == 'P') {
            letter = 'p';
          }
        }
        var color = spritePalette[letter]!;
        if (opacity < 1) color = color.withValues(alpha: opacity);
        _dot(canvas, ox + c * scale, oy + r * scale, color, scale, scale);
      }
    }
  }

  /// Every pixel from [a] to [b], with its step number.
  void _line(Landmark a, Landmark b, void Function(int x, int y, int k) plot) {
    var x0 = a.x, y0 = a.y;
    final x1 = b.x, y1 = b.y;
    final dx = (x1 - x0).abs(), dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    var err = dx + dy, k = 0;
    while (true) {
      plot(x0, y0, k++);
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = reduceMotion ? 0 : frame.value;
    canvas.save();
    canvas.scale(size.width / worldMapWidth, size.height / worldMapHeight);
    const whole =
        Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0);
    canvas.drawImageRect(
        ground,
        whole,
        whole,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);

    final terrain = worldMapTerrain;
    for (final g in terrain.glints) {
      if (!_clear(g.x, g.y)) continue;
      if (reduceMotion ? g.phase < 2 : (f + g.phase) % 6 < 2) {
        _dot(canvas, g.x, g.y, const Color(0xFF4A8A93), 2, 1);
      }
    }
    for (final (x, y) in terrain.fires) {
      if (!_clear(x, y)) continue;
      _dot(canvas, x, y, _embers[(f + x + y) % 3]);
    }

    // The road between reached places, dashes moving along it.
    for (var i = 0; i < worldMapLandmarks.length - 1; i++) {
      final a = worldMapLandmarks[i], b = worldMapLandmarks[i + 1];
      if (!discovered.contains(a.id) || !discovered.contains(b.id)) continue;
      final on = (_active(a) && _active(b)) ||
          (chapterFilter != 0 &&
              (a.chapter == chapterFilter || b.chapter == chapterFilter));
      final color = Color.fromRGBO(238, 234, 226, on ? .85 : .22);
      _line(a, b, (x, y, k) {
        if ((k + f) % 4 == 0) _dot(canvas, x, y, color);
      });
    }

    // The great tear over the shore, once the shore is reached.
    if (discovered.contains('shore')) {
      _sprite(canvas, 'tear', 244, 18, 2, swap: f.isOdd);
    }
    for (final l in worldMapLandmarks) {
      if (!discovered.contains(l.id)) continue;
      _sprite(canvas, l.sprite, l.x, l.y, l.big ? 2 : 1,
          swap: l.sprite == 'tear' && f.isOdd, opacity: _active(l) ? 1 : .35);
    }

    // The chosen place: blinking gold corners.
    final selected = landmarkById(selectedId);
    if (selected != null && (reduceMotion || f % 4 < 3)) {
      final (w, h) = _spriteSize(selected.sprite, selected.big ? 2 : 1);
      final x0 = (selected.x - w / 2).round() - 2;
      final y0 = (selected.y - h / 2).round() - 2;
      final x1 = x0 + w + 3, y1 = y0 + h + 3;
      for (final (x, y) in [
        (x0, y0), (x1, y0), (x0, y1), (x1, y1), //
        (x0 + 1, y0), (x0, y0 + 1), (x1 - 1, y0), (x1, y0 + 1),
        (x0 + 1, y1), (x0, y1 - 1), (x1 - 1, y1), (x1, y1 - 1),
      ]) {
        _dot(canvas, x, y, _gold);
      }
    }

    // Where the story stands: a marker bobbing over the place.
    final here = hereId == null ? null : landmarkById(hereId!);
    if (here != null) {
      final (_, h) = _spriteSize(here.sprite, here.big ? 2 : 1);
      final top = (here.y - h / 2).round();
      final bob = f % 4 < 2 ? 0 : 1;
      _sprite(canvas, 'pin', here.x, top - 5 - bob, 1);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter old) =>
      old.ground != ground ||
      old.selectedId != selectedId ||
      old.hereId != hereId ||
      old.chapterFilter != chapterFilter ||
      old.reduceMotion != reduceMotion ||
      old.discovered.length != discovered.length;
}
