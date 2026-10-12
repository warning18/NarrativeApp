// A banner in the wind: the cloth of a pixel banner (pixel_banner.dart)
// blown from the left in gusts, drawn in strips two pixels high, with a ripple
// running down it and the hem fluttering. The throne room hangs one on every
// standard; the title screen flies the Void's standard the same way. Every
// cycle of the clock is the same, so it loops without a seam.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'pixel_banner.dart';

/// The banner [id] blowing in the wind on a loop of [period], with room
/// either side for the cloth to move. [phase] offsets one banner's gusts from
/// another's. It holds still when the platform asks for less motion.
class WindBanner extends StatefulWidget {
  const WindBanner({
    super.key,
    required this.id,
    this.scale = 2,
    this.phase = 0,
    this.period = const Duration(seconds: 6),
  });

  final String id;
  final int scale;
  final double phase;
  final Duration period;

  /// The room each side of the cloth, in sprite pixels, for it to blow into.
  static const int room = 12;

  @override
  State<WindBanner> createState() => _WindBannerState();
}

class _WindBannerState extends State<WindBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: widget.period);
  bool _still = false;

  @override
  void initState() {
    super.initState();
    BannerImages.of(widget.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void didUpdateWidget(WindBanner old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) BannerImages.of(widget.id);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = widget.scale.toDouble();
    return SizedBox(
      width: (pixelBannerSize.width + 2 * WindBanner.room) * sc,
      height: pixelBannerSize.height * sc,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: pixelBannerSize.width + 2 * WindBanner.room,
            height: pixelBannerSize.height,
            child: CustomPaint(
              painter: WindPainter(
                id: widget.id,
                clock: _clock,
                phase: widget.phase,
                still: _still,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A banner's sprite in the wind: drawn in strips four pixels high. The
/// wind (always from the left, in gusts) pushes the cloth to the right more
/// the lower it hangs, a ripple runs down it, and the hem flutters; the rod
/// at the top holds still. Every cycle of the clock is the same, so it loops
/// without a seam.
class WindPainter extends CustomPainter {
  WindPainter({
    required this.id,
    required this.clock,
    required this.phase,
    required this.still,
  }) : super(repaint: Listenable.merge([clock, BannerImages.loaded]));

  final String id;
  final Animation<double> clock;
  final double phase;
  final bool still;

  static const int _strip = 2;
  static const int _rod = 12;

  /// The cloth's offset (in pixels) at row [y] of a banner [h] high, at
  /// cycle position [u] (0 to 1).
  static double offsetAt(double u, double phase, int y, int h) {
    final w = 2 * math.pi * u;
    final hang = ((y - _rod) / (h - _rod)).clamp(0.0, 1.0);
    // Gusts: the wind rises and falls twice a cycle.
    final gust = 0.62 + 0.38 * math.sin(2 * w + phase);
    final push = 7.0 * gust * math.pow(hang, 1.3);
    // A ripple runs down the cloth, six times a cycle.
    final ripple =
        3.4 * gust * math.pow(hang, 1.4) * math.sin(6 * w - y * 0.085 + phase);
    // The hem flutters faster.
    final flutter =
        1.8 * gust * math.pow(hang, 3) * math.sin(11 * w - y * 0.2 + phase * 2);
    return push + ripple + flutter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final image = BannerImages.of(id);
    if (image == null) return;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final w = image.width.toDouble();
    // The banner sits in the middle of the room the wind needs.
    final left = (size.width - w) / 2;
    final u = still ? 0.0 : clock.value;
    // The cloth rides up a little as the wind lifts it.
    final gust = still ? 0.0 : 0.62 + 0.38 * math.sin(4 * math.pi * u + phase);
    final lift = 0.05 * gust;
    for (var y = 0; y < image.height; y += _strip) {
      final dx = still ? 0.0 : offsetAt(u, phase, y, image.height);
      final top = (y * (1 - lift * (y / image.height))).roundToDouble();
      final bottom = ((y + _strip) * (1 - lift * ((y + _strip) / image.height)))
          .roundToDouble();
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, y.toDouble(), w, _strip.toDouble()),
        Rect.fromLTWH(
            left + dx.roundToDouble(), top, w, math.max(1, bottom - top)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WindPainter old) =>
      old.id != id || old.phase != phase || old.still != still;
}

/// The banner sprites, loaded once and kept.
class BannerImages {
  BannerImages._();

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _asked = {};

  /// Counts the sprites in, for a painter to repaint on.
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  static ui.Image? of(String id) {
    final image = _images[id];
    if (image == null && _asked.add(id)) _load(id);
    return image;
  }

  static Future<void> _load(String id) async {
    try {
      final data = await rootBundle.load('assets/visuals/banners/$id.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[id] = frame.image;
      loaded.value++;
    } catch (_) {
      _asked.remove(id);
    }
  }
}
