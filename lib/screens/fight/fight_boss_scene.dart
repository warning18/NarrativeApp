// The boss scene of the Tower's fights: the boss FACES THE VIEWER (Art's south
// frame) standing whole in its tall panel, and the hero is seen FROM BEHIND
// (Art's north frame) in the strip under it, looking up at it, so the two
// panels read as one scene from top to bottom. A boss with no south frame (or a
// hero with no north frame) keeps its side view in the usual layout.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tower/ink/ink_sprites.dart';

/// The bosses and wardens with a south frame
/// (`assets/visuals/boss_south/<id>.png`, Art's hand-off): one line per id.
const Set<String> bossSouthIds = {
  'rat_matriarch',
  'dock_overseer',
  'smuggler_captain',
  'plague_hound',
  'kroll_the_branded',
  'brine_jack',
  'inquisition_legate',
  'hollow_court_zealot',
  'hollow_court_inquisitor',
  'knell_keeper',
  'horn_taker',
  'purifier_vell',
  'claimant_morrow',
  'strand_colossus',
  'glass_shepherd',
  'white_admiral',
  'tear_spawn',
  'void_manifestation',
  'inquisition_penitent',
  'void_sovereign',
};

/// The heroes with a north frame (`assets/visuals/hero_north/<name>.png`), by
/// the name `heroWalkName` gives.
const Set<String> heroNorthNames = {
  'warrior',
  'mage',
  'rogue',
  'cleric',
  'ranger',
  'dwarf',
  'orc',
};

/// The south frame of the boss [enemyId], or null (it keeps its side view).
String? bossSouthAsset(String enemyId) => bossSouthIds.contains(enemyId)
    ? 'assets/visuals/boss_south/$enemyId.png'
    : null;

/// The north frame of the hero [name], or null.
String? heroNorthAsset(String name) => heroNorthNames.contains(name)
    ? 'assets/visuals/hero_north/$name.png'
    : null;

class _Frame {
  _Frame(this.image, this.box);

  final ui.Image image;

  /// The figure's own rectangle in the image (the rest is empty).
  final Rect box;
}

/// The figure's rectangle in each frame, worked out once (the image itself
/// comes from [InkSprites], which keeps and recolours it).
final Map<String, Rect> _boxes = {};

Future<_Frame> _frameOf(String asset) async {
  final image = await InkSprites.of(asset);
  final known = _boxes[asset];
  if (known != null) return _Frame(image, known);
  final data = (await image.toByteData())!.buffer.asUint8List();
  var minX = image.width, minY = image.height, maxX = -1, maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (data[(y * image.width + x) * 4 + 3] > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final box = maxX < 0
      ? Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble())
      : Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX + 1.0, maxY + 1.0);
  _boxes[asset] = box;
  return _Frame(image, box);
}

/// One figure of the scene, [height] tall, standing on the bottom edge of its
/// box, centred. Never takes a touch.
class BossSceneFigure extends StatelessWidget {
  const BossSceneFigure({super.key, required this.asset, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: FutureBuilder<_Frame>(
          future: _frameOf(asset),
          builder: (context, snap) {
            final f = snap.data;
            if (f == null) return SizedBox(height: height);
            final w = height * f.box.width / f.box.height;
            return SizedBox(
              width: w,
              height: height,
              child: CustomPaint(painter: _FigurePainter(f)),
            );
          },
        ),
      );
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.frame);

  final _Frame frame;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
        frame.image,
        frame.box,
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_FigurePainter old) => old.frame != frame;
}
