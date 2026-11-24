// The story side's panel kit (UX, the user's pick "the mix": quiet type for
// reading, frames for weight, plates and gems for state; docs/proposals/
// story-mix.md): a rarity frame round any box, a nameplate panel, a gem. The
// frames are Art's PixelLab card frames (assets/visuals/cards/), nine-sliced
// so a panel of any size wears one: the corners and the tier's ornaments
// (the gem on top, the crown, the leaves) keep their size and only the plain
// metal stretches. A darker `frame_<tier>_dim.png` beside a frame, when Art
// has made one, is used in its place.
//
// This file only draws. What a panel holds, and which weight a choice has
// (lib/data/story_plates.dart), stay with the screens.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/story_plates.dart';
import '../theme/palette.dart';
import '../theme/pixel_chip.dart';
import '../theme/stitched_ink.dart';
import 'clan_offer_gifts.dart' show CardTier;

// -------------------------------------------------------- the frame art ---

/// The frame art's size in art pixels, and its corner.
const int _frameWidth = 104;
const int _frameHeight = 172;
const int _corner = 12;

/// Where a tier's ornaments sit in the art (source pixels), if it has any:
/// the top and bottom edges' middle (x ranges) and the side edges' leaves
/// (y ranges, mirrored on the other side).
class _FrameOrnaments {
  const _FrameOrnaments({this.top, this.bottom, this.sides});

  final (int, int)? top;
  final (int, int)? bottom;
  final (int, int)? sides;
}

/// The ornaments of each tier's art (found by comparing each edge with its
/// plain run).
const Map<CardTier, _FrameOrnaments> _frameOrnaments = {
  CardTier.common: _FrameOrnaments(),
  CardTier.uncommon: _FrameOrnaments(),
  CardTier.rare: _FrameOrnaments(top: (45, 59)),
  CardTier.epic: _FrameOrnaments(top: (47, 57), bottom: (47, 57)),
  CardTier.legendary: _FrameOrnaments(
    top: (41, 63),
    bottom: (44, 60),
    sides: (25, 44),
  ),
};

/// The plain rows of a side edge and the plain columns of the top and bottom
/// edges, the runs that are stretched (source pixels).
const (int, int) _plainRows = (70, 100);

/// One piece of the nine-slice: a source rectangle (art pixels) drawn into a
/// destination rectangle (dp).
class FrameSlice {
  const FrameSlice(this.src, this.dst);

  final Rect src;
  final Rect dst;

  @override
  String toString() => 'FrameSlice($src -> $dst)';
}

/// The slices that dress a [size] panel in [tier]'s frame, [k] dp an art
/// pixel: four corners, the four edges (their plain runs stretched, an
/// ornament drawn at its own size when the edge is long enough to hold it
/// with a plain run of at least a corner each side), the middle left empty.
List<FrameSlice> frameSlices(CardTier tier, Size size, double k) {
  final o = _frameOrnaments[tier] ?? const _FrameOrnaments();
  const c = _corner * 1.0;
  final d = c * k;
  final w = size.width, h = size.height;
  const fw = _frameWidth * 1.0, fh = _frameHeight * 1.0;
  final slices = <FrameSlice>[];
  void add(Rect src, Rect dst) {
    if (dst.width > 0 && dst.height > 0) slices.add(FrameSlice(src, dst));
  }

  // Corners.
  add(const Rect.fromLTWH(0, 0, c, c), Rect.fromLTWH(0, 0, d, d));
  add(const Rect.fromLTWH(fw - c, 0, c, c), Rect.fromLTWH(w - d, 0, d, d));
  add(const Rect.fromLTWH(0, fh - c, c, c), Rect.fromLTWH(0, h - d, d, d));
  add(
    const Rect.fromLTWH(fw - c, fh - c, c, c),
    Rect.fromLTWH(w - d, h - d, d, d),
  );

  // A horizontal edge: [srcY] the art's band, [dstY] where it goes.
  void horizontal(double srcY, double dstY, (int, int)? ornament) {
    final innerW = w - 2 * d;
    if (innerW <= 0) return;
    // The plain run: the whole band, or its part before the ornament.
    final band = ornament == null
        ? Rect.fromLTWH(c, srcY, fw - 2 * c, c)
        : Rect.fromLTRB(c, srcY, ornament.$1.toDouble(), srcY + c);
    if (ornament != null) {
      final a = ornament.$1.toDouble(), b = ornament.$2.toDouble();
      final ow = (b - a) * k;
      // Room for the ornament and a corner's worth of plain on each side.
      if (innerW >= ow + 2 * d) {
        final mid = w / 2;
        final left = mid - ow / 2, right = mid + ow / 2;
        add(
          Rect.fromLTRB(c, srcY, a, srcY + c),
          Rect.fromLTRB(d, dstY, left, dstY + d),
        );
        add(
          Rect.fromLTRB(a, srcY, b, srcY + c),
          Rect.fromLTRB(left, dstY, right, dstY + d),
        );
        add(
          Rect.fromLTRB(b, srcY, fw - c, srcY + c),
          Rect.fromLTRB(right, dstY, w - d, dstY + d),
        );
        return;
      }
    }
    add(band, Rect.fromLTRB(d, dstY, w - d, dstY + d));
  }

  horizontal(0, 0, o.top);
  horizontal(fh - c, h - d, o.bottom);

  // A vertical edge.
  void vertical(double srcX, double dstX) {
    final innerH = h - 2 * d;
    if (innerH <= 0) return;
    add(
      Rect.fromLTRB(
        srcX,
        _plainRows.$1.toDouble(),
        srcX + c,
        _plainRows.$2.toDouble(),
      ),
      Rect.fromLTRB(dstX, d, dstX + d, h - d),
    );
    final s = o.sides;
    if (s == null) return;
    final sh = (s.$2 - s.$1) * k;
    // Both leaves fit with a corner's worth of plain between them.
    if (innerH < 2 * sh + 2 * d) return;
    final y1 = d + innerH * 0.25 - sh / 2;
    final y2 = d + innerH * 0.75 - sh / 2;
    final mirrored = fh - s.$2;
    add(
      Rect.fromLTRB(srcX, s.$1.toDouble(), srcX + c, s.$2.toDouble()),
      Rect.fromLTWH(dstX, y1, d, sh),
    );
    add(
      Rect.fromLTRB(srcX, mirrored, srcX + c, mirrored + (s.$2 - s.$1)),
      Rect.fromLTWH(dstX, y2, d, sh),
    );
  }

  vertical(0, 0);
  vertical(fw - c, w - d);
  return slices;
}

/// The five frames, decoded once. A tier's `_dim` art, when it exists, wins.
class StoryFrames {
  StoryFrames._();

  static final StoryFrames instance = StoryFrames._();

  final Map<CardTier, ui.Image> _images = {};
  Future<void>? _loading;

  /// Whether the dim art was found, per tier (for the tests).
  final Map<CardTier, bool> dim = {};

  ui.Image? imageFor(CardTier tier) => _images[tier];

  /// Loads every frame (the first call does the work; later calls wait for it).
  Future<void> preload() => _loading ??= _loadAll();

  Future<void> _loadAll() async {
    for (final tier in CardTier.values) {
      ByteData data;
      var isDim = true;
      try {
        data = await rootBundle.load(
          'assets/visuals/cards/frame_${tier.name}_dim.png',
        );
      } catch (_) {
        isDim = false;
        data = await rootBundle.load(
          'assets/visuals/cards/frame_${tier.name}.png',
        );
      }
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[tier] = (await codec.getNextFrame()).image;
      dim[tier] = isDim;
    }
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.image, this.tier, this.k);

  final ui.Image image;
  final CardTier tier;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (final s in frameSlices(tier, size, k)) {
      canvas.drawImageRect(image, s.src, s.dst, paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.image != image || old.tier != tier || old.k != k;
}

/// A rarity frame round [child]: the tier's metal at 2 dp an art pixel times
/// [band] (1 is the full band; 0.5 a thin one), the middle filled with [fill]
/// (the surface by default). The frame loads on the first build; until it is
/// there the panel shows without it.
class StoryFrame extends StatefulWidget {
  const StoryFrame({
    super.key,
    required this.child,
    this.tier = CardTier.common,
    this.fill,
    this.padding = const EdgeInsets.all(12),
    this.band = 1.0,
  });

  final Widget child;
  final CardTier tier;
  final Color? fill;

  /// Space inside the metal.
  final EdgeInsets padding;
  final double band;

  @override
  State<StoryFrame> createState() => _StoryFrameState();
}

class _StoryFrameState extends State<StoryFrame> {
  @override
  void initState() {
    super.initState();
    if (StoryFrames.instance.imageFor(widget.tier) == null) {
      StoryFrames.instance.preload().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = StoryFrames.instance.imageFor(widget.tier);
    final k = 2 * widget.band;
    return CustomPaint(
      foregroundPainter:
          image == null ? null : _FramePainter(image, widget.tier, k),
      child: ColoredBox(
        color: widget.fill ?? Theme.of(context).colorScheme.surface,
        child: Padding(
          // The metal's band (6 art pixels) and a hair, then the padding.
          padding: widget.padding + EdgeInsets.all(5.5 * k),
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- the weights ---

/// A choice's frame by its weight (lib/data/story_plates.dart): [plain] has
/// none, [weighty] the clan's accent (its rail and tint inside the quiet
/// frame), [major] the rich metal (`rich`, the gilded tier by default; a
/// banner piece asks for the gold one) with the clan's tint under it.
Widget storyWeightFrame({
  required ChoiceWeight weight,
  required Widget child,
  Color? clan,
  CardTier rich = CardTier.epic,
}) {
  switch (weight) {
    case ChoiceWeight.plain:
      return child;
    case ChoiceWeight.weighty:
      final color = clan ?? Palette.goldDark;
      return StoryFrame(
        tier: CardTier.common,
        band: 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        fill: color.withValues(alpha: 0.16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              const SizedBox(width: 8),
              Expanded(child: child),
            ],
          ),
        ),
      );
    case ChoiceWeight.major:
      return StoryFrame(
        tier: rich,
        band: 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        fill: (clan ?? Palette.goldDark).withValues(alpha: 0.14),
        child: child,
      );
  }
}

// ----------------------------------------------------- plates and gems ---

/// Black or cream, whichever reads on [c].
Color storyInkOn(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.light
        ? Palette.apolloOutline
        : Palette.apolloCream;

/// A fight block's nameplate over a pixel-cornered panel: a band in [color]
/// with a [lead] (an emblem), the [title] and a [trail], and [child] under it.
class StoryPlate extends StatelessWidget {
  const StoryPlate({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.lead,
    this.trail,
    this.frame,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 12),
  });

  final String title;
  final Color color;
  final Widget child;
  final Widget? lead;
  final Widget? trail;

  /// The panel's outline (the band's colour by default).
  final Color? frame;
  final EdgeInsets padding;

  static const double plateHeight = 22;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = storyInkOn(color);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surface,
        shape: PixelChipBorder(
          side: BorderSide(color: frame ?? color, width: 2),
          step: 3,
          steps: 3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: plateHeight,
            margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: color,
            child: Row(
              children: [
                if (lead != null) ...[lead!, const SizedBox(width: 5)],
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 15,
                        height: 1,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                if (trail != null) trail!,
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// A gem: a small pixel-cornered plate with a number and a label over it (the
/// fight blocks' armour and damage gems).
class StoryGem extends StatelessWidget {
  const StoryGem(
    this.value,
    this.color, {
    super.key,
    this.label,
    this.size = 36,
  });

  final String value;
  final Color color;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(
        color: scheme.surface,
        shape: PixelChipBorder(
          side: BorderSide(color: color, width: 1.5),
          step: 2,
          steps: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(
              label!,
              style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 8,
                height: 1.2,
                color: color,
              ),
            ),
          Text(
            value,
            style: TextStyle(
              fontFamily: InkFonts.prose,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.1,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
