// Pixel animations (v1.216): sprite strips drawn by tool/gen_pixel_fx.py,
// one row of square frames each in assets/visuals/pixel_fx/, shown at an
// integer scale with hard edges. Used for the dice's landings, the stamp
// of a place found, the camp's fire and a chest bursting open.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The strips, loaded once and kept; painters read them as they come in.
class PixelStrips {
  PixelStrips._();

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _asked = {};

  /// Counts the strips in, for a painter to repaint on.
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  /// The strip [name] (its file's name under assets/visuals/pixel_fx/), or
  /// null while it loads.
  static ui.Image? of(String name) {
    final image = _images[name];
    if (image == null && _asked.add(name)) _load(name);
    return image;
  }

  /// Starts loading [names] so they are there when wanted.
  static void preload(Iterable<String> names) {
    for (final name in names) {
      of(name);
    }
  }

  /// Whether every one of [names] is loaded.
  static bool ready(Iterable<String> names) =>
      names.every((name) => of(name) != null);

  static Future<void> _load(String name) async {
    try {
      final data = await rootBundle.load('assets/visuals/pixel_fx/$name.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[name] = frame.image;
      loaded.value++;
    } catch (_) {
      // No strip: nothing is drawn for it.
      _asked.remove(name);
    }
  }
}

/// Draws frame [progress] (0 to 1 through the strip) of each of [names],
/// one over another, centred, [scale] times bigger, pixels left square.
class PixelStripPainter extends CustomPainter {
  PixelStripPainter({
    required this.names,
    required this.progress,
    this.scale = 3,
    this.opacity = 1,
  }) : super(repaint: PixelStrips.loaded);

  final List<String> names;
  final double progress;
  final double scale;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..color = Colors.white.withValues(alpha: opacity);
    for (final name in names) {
      final image = PixelStrips.of(name);
      if (image == null) continue;
      final side = image.height.toDouble();
      final frames = (image.width / side).round();
      final i = (progress * frames).floor().clamp(0, frames - 1);
      final dst = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: side * scale,
          height: side * scale);
      canvas.drawImageRect(
          image, Rect.fromLTWH(i * side, 0, side, side), dst, paint);
    }
  }

  @override
  bool shouldRepaint(PixelStripPainter old) =>
      old.progress != progress ||
      old.scale != scale ||
      old.opacity != opacity ||
      !listEquals(old.names, names);
}

/// A pixel strip that plays by itself: once (then [onDone]) or looping. With
/// reduced motion it shows its [restFrame] and plays nothing.
class PixelSprite extends StatefulWidget {
  const PixelSprite({
    super.key,
    required this.name,
    required this.frames,
    required this.frameSize,
    this.scale = 3,
    this.fps = 10,
    this.loop = false,
    this.restFrame = 0,
    this.onDone,
  });

  final String name;

  /// How many frames the strip holds, and the side of one in pixels.
  final int frames;
  final int frameSize;
  final double scale;
  final double fps;
  final bool loop;

  /// The frame shown with reduced motion, and the strip's at-rest look.
  final int restFrame;
  final VoidCallback? onDone;

  @override
  State<PixelSprite> createState() => _PixelSpriteState();
}

class _PixelSpriteState extends State<PixelSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration:
        Duration(milliseconds: (widget.frames * 1000 / widget.fps).round()),
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    PixelStrips.preload([widget.name]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      if (!widget.loop) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => widget.onDone?.call());
      }
      return;
    }
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward().whenComplete(() => widget.onDone?.call());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = still
            ? (widget.restFrame + 0.5) / widget.frames
            : _controller.value;
        if (still && !widget.loop) return const SizedBox.shrink();
        return CustomPaint(
          key: ValueKey('pixel_${widget.name}'),
          size: Size.square(widget.frameSize * widget.scale),
          painter: PixelStripPainter(
              names: [widget.name], progress: progress, scale: widget.scale),
        );
      },
    );
  }
}
