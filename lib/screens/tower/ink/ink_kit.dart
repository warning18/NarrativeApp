// The Tower's ink kit (v1.1004, UX-2): the pieces its screens are drawn with.
// Art's wide brush frame as a paper panel (dark ink text on the paper), the
// slanted red title tab, the skewed button (the one that goes on is red), the
// slanted picture panel (a picture clipped to a slanted polygon with a black
// gutter and a paper hairline), and the health bar. Slants only round
// pictures: the text-heavy screens keep upright paper panels.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/stitched_ink.dart';
import 'ink_images.dart';
import 'ink_palette.dart';
import 'ink_seed.dart';
import 'ink_weather.dart';
import 'ink_worn.dart';

/// How far the brush lettering and the buttons lean.
const double inkSkew = 0.2;

/// Art's wide frame: the paper inside starts 26, 22, 24 and 22 px in from the
/// edges of its 160 x 96 sheet; drawn at [scale] of its size so the ragged
/// border is about 12 dp and the paper keeps the room.
class _WideFramePainter extends CustomPainter {
  _WideFramePainter(this.scale) : super(repaint: InkImages.loaded);

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final img = InkImages.of(inkWideFrameAsset);
    if (img == null) {
      // Until the frame is there: a paper rectangle and a hairline.
      canvas.drawRect(Offset.zero & size, Paint()..color = inkPaper);
      canvas.drawRect(
          (Offset.zero & size).deflate(0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = inkDeep);
      return;
    }
    const l = 26.0, t = 22.0, r = 24.0, b = 22.0;
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final xs = [0.0, l, iw - r, iw];
    final ys = [0.0, t, ih - b, ih];
    final dx = [0.0, l * scale, size.width - r * scale, size.width];
    final dy = [0.0, t * scale, size.height - b * scale, size.height];
    for (var j = 0; j < 3; j++) {
      for (var i = 0; i < 3; i++) {
        canvas.drawImageRect(
            img,
            Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
            Rect.fromLTRB(dx[i], dy[j], dx[i + 1], dy[j + 1]),
            p);
      }
    }
  }

  @override
  bool shouldRepaint(_WideFramePainter old) => old.scale != scale;
}

/// A paper panel in Art's wide frame. Its text is ink on paper: [child] sees
/// a theme whose text is dark. The frame's red splashes sit in two corners, so
/// the default padding keeps the content clear of them. [title] rides on a
/// slanted red tab at the top left.
class InkPaperPanel extends StatelessWidget {
  const InkPaperPanel({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(46, 20, 22, 16),
    this.seedText,
  });

  /// What the panel's look is seeded from when it has no key or title.
  final String? seedText;

  final Widget child;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.copyWith(
      textTheme:
          base.textTheme.apply(bodyColor: inkOnPaper, displayColor: inkOnPaper),
    );
    final seed = inkSeedOf(key, title ?? seedText ?? '${padding.hashCode}');
    // The title tab sits outside the piece, so the cap lies behind it.
    return Stack(clipBehavior: Clip.none, children: [
      InkWeatherPiece(
          seed: seed,
          child: InkWorn(
              seed: seed, tilt: false, chip: false, child: _body(dark, seed))),
      if (title != null)
        Positioned(
            left: -2,
            top: -10,
            child: InkTab(title!, key: const Key('ink_tab'))),
    ]);
  }

  Widget _body(ThemeData dark, InkSeed seed) {
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: CustomPaint(painter: _WideFramePainter(0.5))),
      Padding(
        padding: padding,
        child: Theme(
          data: dark,
          child: DefaultTextStyle.merge(
              style: const TextStyle(color: inkOnPaper), child: child),
        ),
      ),
    ]);
  }
}

/// A slanted red tab carrying a short title.
class InkTab extends StatelessWidget {
  const InkTab(this.text, {super.key, this.color = inkRed});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final seed = InkSeed.of(text);
    return InkWeatherPiece(
        seed: seed, child: InkWorn(seed: seed, tear: true, child: _tab(seed)));
  }

  Widget _tab(InkSeed seed) => Transform(
        transform: Matrix4.skewX(-inkSkew),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 2, 12, 3),
          color: color == inkRed ? seed.red : color,
          child: Transform(
            transform: Matrix4.skewX(inkSkew),
            child: Text(text,
                style: const TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 12.5,
                    height: 1.05,
                    color: inkPaper)),
          ),
        ),
      );
}

/// The Tower's button: a [FilledButton] (so it behaves as one) leaning like
/// the brush lettering. The one that goes on is [primary] (red); the others
/// are black with a paper line, or ink on a paper panel ([onPaper]).
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    this.buttonKey,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.onPaper = false,
    this.height = 40,
  });

  /// The key of the [FilledButton] itself, which the screens and tests read
  /// as one (the wrapper carries none).
  final Key? buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool onPaper;
  final double height;

  @override
  Widget build(BuildContext context) {
    final seed = inkSeedOf(buttonKey ?? key, label);
    final red = seed.red;
    final fill = primary ? red : (onPaper ? inkOnPaper : inkBlack);
    final line = primary ? red : (onPaper ? inkOnPaper : seed.paper);
    return InkWeatherPiece(
        seed: seed, child: InkWorn(seed: seed, child: _button(fill, line)));
  }

  Widget _button(Color fill, Color line) {
    return Transform(
      transform: Matrix4.skewX(-inkSkew),
      child: FilledButton(
        key: buttonKey,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, height),
          backgroundColor: fill,
          disabledBackgroundColor: inkDark,
          foregroundColor: inkPaper,
          disabledForegroundColor: inkGrey,
          shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: onPressed == null ? inkSlate : line, width: 1.5)),
          textStyle: const TextStyle(
              fontFamily: InkFonts.display, fontSize: 14, height: 1.05),
        ),
        child: Transform(
            transform: Matrix4.skewX(inkSkew),
            child: Text(label, textAlign: TextAlign.center)),
      ),
    );
  }
}

/// A health bar: dark track, deep red fill.
class InkBar extends StatelessWidget {
  const InkBar({super.key, required this.value, this.height = 5});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF2A2C34))),
          FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: const ColoredBox(color: inkRed, child: SizedBox.expand())),
        ]),
      );
}

/// A picture panel cut on a slant: [pts] are the polygon's corners in the
/// panel's own box; [child] shows inside, a thick black border and a thin
/// paper line round it.
/// How the Tower fight's two fighter panels are laid out (the look of each
/// panel is the same): [ordinary] the foe above and "You" under it, [elite] the
/// foe's panel a fifth taller, [boss] one and a half times taller with "You"
/// slim under it, [rival] two tall panels side by side with a slanted gutter.
enum TowerPanelLayout { ordinary, elite, boss, rival }

/// Forces a layout (pictures and tests); null lets the fight choose its own.
final ValueNotifier<TowerPanelLayout?> towerPanelLayout = ValueNotifier(null);

class InkSlantPanel extends StatelessWidget {
  const InkSlantPanel({
    super.key,
    required this.size,
    required this.points,
    required this.child,
    this.knockOn,
    this.knockWhen,
  });

  final Size size;
  final List<Offset> points;
  final Widget child;

  /// A signal that knocks the panel's snow off (a blow landing on it).
  final Listenable? knockOn;
  final bool Function()? knockWhen;

  @override
  Widget build(BuildContext context) => InkWeatherPiece(
        // The snow rests on the panel's own (slanted) top edge: its first two
        // points.
        seed: InkSeed.of('slant${points.first}${size.width.round()}'),
        edge: (points[0], points[1]),
        knockOn: knockOn,
        knockWhen: knockWhen,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(children: [
            ClipPath(
                clipper: _PolyClipper(points),
                child: SizedBox(
                    width: size.width, height: size.height, child: child)),
            IgnorePointer(
                child: CustomPaint(size: size, painter: _PolyBorder(points))),
          ]),
        ),
      );
}

class _PolyClipper extends CustomClipper<Path> {
  _PolyClipper(this.pts);

  final List<Offset> pts;

  @override
  Path getClip(Size size) => Path()..addPolygon(pts, true);

  @override
  bool shouldReclip(_PolyClipper old) => old.pts != pts;
}

class _PolyBorder extends CustomPainter {
  _PolyBorder(this.pts);

  final List<Offset> pts;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeJoin = StrokeJoin.miter
          ..color = inkBlack);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.miter
          ..color = inkPaper.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_PolyBorder old) => old.pts != pts;
}

/// A small tag in ink: paper text on a red block (a danger: an affix), or on a
/// black block with a paper line (a plain mark: an Elite).
class InkTag extends StatelessWidget {
  const InkTag(this.text, {super.key, this.red = false});

  final String text;
  final bool red;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: red ? inkRed : inkBlack,
          border: Border.all(color: red ? inkRed : inkPaper),
        ),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: inkPaper, fontWeight: FontWeight.w700)),
      );
}

/// The ink splash behind the foe aimed at: a red burst and paper speed lines
/// running to it. [x] is where the foe stands in the panel (0 to 1), [y] the
/// height of its middle.
class InkSplashPainter extends CustomPainter {
  const InkSplashPainter(this.x, this.y);

  final double x, y;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * x, y.clamp(20, size.height - 10));
    final burst = Path();
    const spikes = 11;
    for (var i = 0; i < spikes * 2; i++) {
      final a = i * 3.14159265 / spikes;
      final r = i.isEven ? 34.0 : 17.0;
      final p = c + Offset(r * _cos(a), r * 0.8 * _sin(a));
      i == 0 ? burst.moveTo(p.dx, p.dy) : burst.lineTo(p.dx, p.dy);
    }
    burst.close();
    canvas.drawPath(burst, Paint()..color = inkRed.withValues(alpha: 0.9));
    final line = Paint()
      ..color = inkPaper.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 16; i++) {
      final a = i * 6.2831853 / 16 + 0.2;
      final from = c + Offset(60 * _cos(a), 48 * _sin(a));
      final to = c + Offset(110 * _cos(a), 88 * _sin(a));
      canvas.drawLine(from, to, line);
    }
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(InkSplashPainter old) => old.x != x || old.y != y;
}
