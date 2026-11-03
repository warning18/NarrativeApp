// The Journey map's pins as banners (docs/proposals/journey-pins-banner.md,
// the user's pick): a way's pin is a hung banner in the colour and the icon of
// what the way is, so the map says "main quest", "shop" or "voyage" before
// anything is read. The same banner, small, is the legend's marker.
//
// A banner is drawn after the clans' hung banners: a ring and a rod across
// the top, a cloth with straight sides and a swallow-tail hem, a cream cord
// inside the edge, and the category's icon on the cloth. The colour never
// carries the meaning alone: every category has its own icon too.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journey_map.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import 'journey_glyph.dart';

/// What a way is, folded to the seven a player can learn. The order is the
/// priority: a pin that stands for several ways shows the first of them.
enum JourneyPinCat { main, side, detour, shop, travel, rest, way }

/// The category of a way, or null for the ways the map keeps as they were:
/// the fights and rolls, which are acted out in a place (cards, not pins) and
/// keep their own marks wherever the map still shows one.
JourneyPinCat? journeyPinCatOf(JourneyStepKind kind, JourneyQuestTie? tie) {
  if (kind == JourneyStepKind.ending ||
      kind == JourneyStepKind.mainQuest ||
      tie == JourneyQuestTie.main) {
    return JourneyPinCat.main;
  }
  if (tie == JourneyQuestTie.side || kind == JourneyStepKind.quest) {
    return JourneyPinCat.side;
  }
  return switch (kind) {
    JourneyStepKind.expedition => JourneyPinCat.detour,
    JourneyStepKind.shop => JourneyPinCat.shop,
    JourneyStepKind.travel => JourneyPinCat.travel,
    JourneyStepKind.rest => JourneyPinCat.rest,
    JourneyStepKind.road => JourneyPinCat.way,
    _ => null,
  };
}

extension JourneyPinCatLook on JourneyPinCat {
  IconData get icon => switch (this) {
        JourneyPinCat.main => Icons.flag_outlined,
        JourneyPinCat.side => Icons.chat_bubble_outline,
        JourneyPinCat.detour => Icons.explore_outlined,
        JourneyPinCat.shop => Icons.storefront_outlined,
        JourneyPinCat.travel => Icons.sailing_outlined,
        JourneyPinCat.rest => Icons.local_fire_department_outlined,
        JourneyPinCat.way => Icons.signpost_outlined,
      };

  /// The cloth's colour on the dark ink or the light one.
  Color colorOn(InkColors ink, {required bool dark}) => switch (this) {
        JourneyPinCat.main => ink.gold,
        JourneyPinCat.side => ink.voidColor,
        JourneyPinCat.detour => ink.ember,
        JourneyPinCat.shop => ink.tide,
        JourneyPinCat.travel =>
          dark ? const Color(0xFF6FA8E8) : const Color(0xFF2F5F9E),
        JourneyPinCat.rest => ink.heal,
        JourneyPinCat.way => ink.ash,
      };

  String get nameKey => 'journey_pin_$name';
  String get lineKey => 'journey_pin_${name}_line';
}

/// Whether [ink] is the dark ink (the map's look decides which one it has).
bool journeyInkIsDark(InkColors ink) => identical(ink, InkColors.dark);

/// A banner pin. [unknown] is a place only heard of: the cloth hollow and
/// dashed, a "?" on it. [lit] is a picked pin: a white cord and a glow.
class BannerPin extends StatelessWidget {
  const BannerPin({
    super.key,
    required this.cat,
    required this.color,
    required this.dark,
    this.icon,
    this.scale = 1,
    this.lit = false,
    this.unknown = false,
  });

  final JourneyPinCat cat;

  /// The cloth, already chosen for the map's look (a Shroud map greys all
  /// but the main quest).
  final Color color;
  final bool dark;

  /// Drawn instead of the category's icon (a padlock on a shut way).
  final IconData? icon;
  final double scale;
  final bool lit;
  final bool unknown;

  static const Size base = Size(26, 38);

  @override
  Widget build(BuildContext context) {
    final iconColor = dark ? const Color(0xFF141218) : Colors.white;
    return SizedBox(
      width: base.width * scale,
      height: base.height * scale,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(base.width * scale, base.height * scale),
            painter: _BannerPainter(color, dark, scale, lit, unknown),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 12 * scale,
            child: Center(
              child: unknown
                  ? Text('?',
                      style: TextStyle(
                          fontFamily: InkFonts.system,
                          fontSize: 15 * scale,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: color))
                  : Icon(icon ?? cat.icon, size: 14 * scale, color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  _BannerPainter(this.color, this.dark, this.scale, this.lit, this.unknown);
  final Color color;
  final bool dark;
  final double scale;
  final bool lit;
  final bool unknown;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    _paintBannerCloth(canvas, color, dark: dark, lit: lit, unknown: unknown);
  }

  @override
  bool shouldRepaint(_BannerPainter old) =>
      old.color != color ||
      old.dark != dark ||
      old.lit != lit ||
      old.unknown != unknown;
}

/// What a canvas-drawn pin needs to wear a banner: the category (its icon)
/// and the cloth's colour for the map's look.
class PinBanner {
  const PinBanner(this.cat, this.color);
  final JourneyPinCat cat;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is PinBanner && other.cat == cat && other.color == color;

  @override
  int get hashCode => Object.hash(cat, color);
}

/// The banner drawn on a canvas (the city chart's painter draws its pins
/// itself): [BannerPin.base] in size, its top left at the origin, the icon
/// on the cloth.
void paintBannerPin(Canvas canvas, PinBanner banner,
    {required bool dark, bool lit = false}) {
  _paintBannerCloth(canvas, banner.color, dark: dark, lit: lit);
  final icon = banner.cat.icon;
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: 14,
        height: 1,
        color: dark ? const Color(0xFF141218) : Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(13 - tp.width / 2, 19 - tp.height / 2));
}

/// The cloth, rod and ring of a banner in [BannerPin.base] units.
void _paintBannerCloth(Canvas canvas, Color color,
    {required bool dark, bool lit = false, bool unknown = false}) {
  const w = 26.0;
  const h = 38.0;
  final surface = dark ? const Color(0xFF141218) : const Color(0xFFFAF3E2);
  final rod = Color.lerp(color, Colors.black, 0.45)!;
  const cord = Color(0xFFEFE3C8);
  // The cloth: straight sides, a swallow-tail hem.
  final cloth = Path()
    ..moveTo(3, 9)
    ..lineTo(w - 3, 9)
    ..lineTo(w - 3, h)
    ..lineTo(w / 2, h - 8)
    ..lineTo(3, h)
    ..close();
  if (lit) {
    canvas.drawPath(
        cloth,
        Paint()
          ..color = color.withValues(alpha: 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }
  // The ring above the rod.
  canvas.drawCircle(
      const Offset(w / 2, 3.2),
      2.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = rod);
  if (unknown) {
    canvas.drawPath(cloth, Paint()..color = surface.withValues(alpha: 0.9));
    _dashed(
        canvas,
        cloth,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color);
  } else {
    canvas.drawPath(cloth, Paint()..color = color);
    // The cord, inside the edge.
    final inner = Path()
      ..moveTo(5.5, 11.5)
      ..lineTo(w - 5.5, 11.5)
      ..lineTo(w - 5.5, h - 5)
      ..lineTo(w / 2, h - 11)
      ..lineTo(5.5, h - 5)
      ..close();
    canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = cord.withValues(alpha: 0.85));
    canvas.drawPath(
        cloth,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..color = lit ? Colors.white : surface);
  }
  // The rod across the top, over the cloth.
  final bar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 6.2, w - 2, 4), const Radius.circular(1.6));
  canvas.drawRRect(bar, Paint()..color = rod);
  canvas.drawRRect(
      bar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = surface);
}

void _dashed(Canvas canvas, Path path, Paint paint) {
  for (final m in path.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      canvas.drawPath(m.extractPath(d, math.min(d + 3.2, m.length)), paint);
      d += 5.4;
    }
  }
}

/// The key button's sheet: each category with its banner, its name in its
/// colour and one line.
Future<void> showJourneyLegend(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => const JourneyLegendSheet(),
  );
}

class JourneyLegendSheet extends ConsumerWidget {
  const JourneyLegendSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('journey_legend'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(ref, 'journey_legend_title'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 10),
            for (final cat in JourneyPinCat.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  key: Key('journey_legend_${cat.name}'),
                  children: [
                    BannerPin(
                        cat: cat,
                        color: cat.colorOn(ink, dark: dark),
                        dark: dark,
                        scale: 0.9),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(ref, cat.nameKey),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cat.colorOn(ink, dark: dark),
                                  fontWeight: FontWeight.w600)),
                          Text(tr(ref, cat.lineKey),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: ink.ash)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(tr(ref, 'journey_legend_note'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
