// Pixel art out of a painter (v1.228): a drawing is made small (one art
// pixel is several screen pixels), its soft edges are cut hard, and it is
// stretched back with nearest-neighbour scaling, so the ships read as the
// skill effects do (see pixel_vfx.dart): flat tones, hard edges, one pixel
// size.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Anything drawn at or over this much is solid, under it gone: thin lines
/// survive as one art pixel, a soft shadow does not.
const double pixelAlphaCut = 0.3;

const ColorFilter _cut = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 9, -9 * 255 * pixelAlphaCut,
]);

/// Draws [draw] on [canvas] as pixel art: on a grid of [pixel]-sized art
/// pixels, with [margin] screen pixels of room around [size] for what is
/// drawn beyond the box (a wake, a wing). Where the picture cannot be made
/// small, it is drawn smooth.
void paintPixelated(
  Canvas canvas,
  Size size,
  double pixel,
  void Function(Canvas canvas, Size size) draw, {
  double margin = 100,
}) {
  final cols = ((size.width + margin * 2) / pixel).ceil();
  final rows = ((size.height + margin * 2) / pixel).ceil();
  ui.Picture? picture;
  ui.Image? image;
  try {
    final recorder = ui.PictureRecorder();
    final small = Canvas(recorder);
    small.scale(1 / pixel);
    small.translate(margin, margin);
    draw(small, size);
    picture = recorder.endRecording();
    image = picture.toImageSync(cols, rows);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, cols.toDouble(), rows.toDouble()),
      Rect.fromLTWH(-margin, -margin, cols * pixel, rows * pixel),
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..colorFilter = _cut,
    );
  } catch (_) {
    draw(canvas, size);
  } finally {
    image?.dispose();
    picture?.dispose();
  }
}
