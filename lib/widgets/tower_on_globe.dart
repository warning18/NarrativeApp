// The Tower on the world's ball (Maps, held prototype): a small sphere of
// the story's world, in the grey of the Shroud look so it sits in the
// Tower's ink, turned to where the Ashen Tower stands, with a red mark.
// For the Tower's start page: the mode has a place in the world.
//
// WHERE IT STANDS IS NOT WRITTEN ANYWHERE YET. This draft puts it at the
// Ashen Quarter (the name it shares); the place is Narrative's to say.
import 'package:flutter/material.dart';

import '../data/chart_globe.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../screens/tower/ink/ink_palette.dart';
import 'chart_map_painter.dart';

/// The landmark the Tower is drawn at (see the note above).
const String towerLandmarkId = 'quarter';

class TowerOnGlobe extends StatefulWidget {
  const TowerOnGlobe({super.key, required this.language, this.size = 150});

  final AppLanguage language;

  final double size;

  @override
  State<TowerOnGlobe> createState() => _TowerOnGlobeState();
}

class _TowerOnGlobeState extends State<TowerOnGlobe> {
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chart = chartOf(MapShape.story);
    // The Tower's ink: black sea, slate land, a paper coast.
    const palette = ChartPalette(
      sea: inkBlack,
      seaLine: inkDeep,
      land: inkSlate,
      coast: inkPaper,
      river: inkDark,
      fog: inkBlack,
      label: inkGrey,
      landName: inkPaper,
      place: inkPaper,
      road: inkPaper,
      ahead: inkGrey,
      mark: inkRed,
      voidColor: inkRed,
      roofs: inkDark,
    );
    final at = chart.of(worldMapLandmarks.firstWhere(
        (l) => l.id == towerLandmarkId,
        orElse: () => worldMapLandmarks.first));
    final size = widget.size;
    // The whole ball in the box, as the World draws it.
    final k = size * 0.9 / (2 * GlobeView.baseRadius);
    final centre = Offset(size / k / 2, size / k / 2);
    // Close enough for its land to read, the whole ball still in the box.
    final globe = chart.globeAt(at, 1.0, centre);
    return SizedBox(
      key: const Key('tower_on_globe'),
      width: size,
      height: size,
      child: RepaintBoundary(
        child: Stack(fit: StackFit.expand, children: [
          // The world in grey: its trees and peaks are drawn in colour,
          // and the Tower's pages are black, white and red.
          ClipOval(
              child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.33, 0.59, 0.11, 0, 18, //
              0.33, 0.59, 0.11, 0, 18, //
              0.33, 0.59, 0.11, 0, 18, //
              0, 0, 0, 1, 0, //
            ]),
            child: CustomPaint(
              painter: ChartMapPainter(
                frame: _frame,
                walk: const AlwaysStoppedAnimation<double>(0),
                geography: chart,
                palette: palette,
                language: widget.language,
                discovered: const {},
                legs: const [],
                ahead: null,
                selectedId: '',
                here: null,
                walking: false,
                walkPath: const [],
                chapterFilter: 0,
                reduceMotion: true,
                chapterColor: (_) => palette.road,
                fog: ChartFog.none,
                names: false,
                globe: globe,
                sphereScale: k,
                zoomOf: () => 1,
              ),
            ),
          )),
          CustomPaint(painter: _TowerMark(at: globe.clamp(at) * k)),
        ]),
      ),
    );
  }
}

/// The Tower's mark on the ball: a red keep in a red ring, edged in paper
/// so it reads on land and on sea. No name: the page's title says it.
class _TowerMark extends CustomPainter {
  const _TowerMark({required this.at});

  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 9.0, h = 18.0;
    final base = at + const Offset(-w / 2, -h + 3);
    canvas.drawCircle(
        at + const Offset(0, -h / 2 + 3),
        17,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = inkRed);
    // The keep, hard-edged: a paper edge, then the red shaft and merlons.
    canvas.drawRect(Rect.fromLTWH(base.dx - 1.5, base.dy + 3, w + 3, h - 1.5),
        Paint()..color = inkPaper);
    canvas.drawRect(Rect.fromLTWH(base.dx, base.dy + 4.5, w, h - 4.5),
        Paint()..color = inkRed);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(base.dx - 1.5 + i * 4.5, base.dy, 3, 4.5),
          Paint()..color = inkPaper);
      canvas.drawRect(
          Rect.fromLTWH(base.dx - 0.5 + i * 4.5, base.dy + 1, 1.5, 3.5),
          Paint()..color = inkRed);
    }
  }

  @override
  bool shouldRepaint(_TowerMark old) => old.at != at;
}
