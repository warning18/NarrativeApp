// The Tower's cards as tarot cards (v2.3, UX-2, the user's pick B): a painted
// vignette over a paper name band and the words on black, a red seal for the
// rarity (a skill's; a die or a spell has a plain black seal). On a narrow
// offer or a big text setting the same card is a row (C: a paper title band
// over a black body with the icon), so no text falls under a readable size.
//
// Slots for what Core has not defined yet are left clean: [tag] (a "new
// synergy" mark, over the vignette's corner) and [footer] (a price, under the
// words). Nothing draws in them today.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/stitched_ink.dart';
import 'ink/ink_palette.dart';
import 'tower_card_art.dart';

/// Art's frame is drawn at 1/1.5 of its pixels (an 11 px border becomes
/// about 7), and the content stays inside it.
const double _frameScale = 1.5;
const double _frameInset = 6;
const double _footerBand = 24;

/// The narrowest a tarot card is drawn, in logical pixels; narrower, or with
/// text bigger than [towerTarotMaxTextScale], the offer is rows.
const double towerTarotMinWidth = 88;
const double towerTarotMaxTextScale = 1.15;

/// How the cards of an offer [width] wide lie, with [textScale]: tarot cards
/// in a row, or rows.
bool towerTarotFits(double width, double textScale,
        {int count = 3, double gap = 8}) =>
    textScale <= towerTarotMaxTextScale &&
    (width - gap * (count - 1)) / count >= towerTarotMinWidth;

/// The wax seal: Art's blank seal with [rarity] 0 to 4 pips (1 to 5) drawn over
/// it in paper colour, so they read at this size (null: a plain black seal,
/// no pips). A seal whose picture is missing is drawn as a red disc.
class TowerSeal extends StatelessWidget {
  const TowerSeal({super.key, this.rarity, this.size = 24});

  final int? rarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final disc = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rarity == null ? inkBlack : inkRed,
        border: Border.all(color: inkPaper, width: 1.5),
      ),
      child: const SizedBox.expand(),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(fit: StackFit.expand, children: [
        if (rarity == null)
          disc
        else
          Image.asset(towerCardSealBlank,
              width: size,
              height: size,
              filterQuality: FilterQuality.none,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => disc),
        CustomPaint(painter: _PipsPainter((rarity ?? -1) + 1)),
      ]),
    );
  }
}

class _PipsPainter extends CustomPainter {
  _PipsPainter(this.n);
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    if (n <= 0) return;
    final c = size.center(Offset.zero);
    final paint = Paint()..color = inkPaper;
    final r = size.width * 0.07 + 0.6;
    if (n == 1) {
      canvas.drawCircle(c, r * 1.3, paint);
      return;
    }
    final ring = size.width * 0.24;
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * ring, r, paint);
    }
  }

  @override
  bool shouldRepaint(_PipsPainter old) => old.n != n;
}

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.2, color: c);

/// The picture in a card's corner or frame: an asset, or [fallback].
Widget towerCardPicture(String? asset, double size, {Widget? fallback}) =>
    asset == null
        ? (fallback ?? SizedBox(width: size, height: size))
        : Image.asset(asset,
            width: size,
            height: size,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                fallback ?? SizedBox(width: size, height: size));

/// One card as a tarot card, [width] wide (its height follows).
class TowerTarotCard extends StatelessWidget {
  const TowerTarotCard({
    super.key,
    required this.width,
    required this.kind,
    required this.name,
    required this.text,
    required this.vignette,
    required this.icon,
    this.rarity,
    this.held = false,
    this.dim = false,
    this.onTap,
    this.tag,
    this.footer,
    this.nameKey,
  });

  final double width;
  final String kind, name, text;
  final String vignette;
  final Widget icon;
  final int? rarity;
  final bool held, dim;
  final VoidCallback? onTap;
  final Widget? tag, footer;
  final Key? nameKey;

  @override
  Widget build(BuildContext context) {
    // A footer (a price, a standing) takes its own band under the words.
    final height = width * 1.75 + (footer != null ? _footerBand : 0);
    Widget card = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(
              color: held ? inkRed : inkPaper.withValues(alpha: dim ? 0.55 : 1),
              width: held ? 3 : 1.5),
        ),
        child: Stack(fit: StackFit.expand, children: [
          // The content sits inside the frame's border.
          Padding(
              padding: const EdgeInsets.all(_frameInset),
              child: Column(children: [
                Expanded(
                  flex: 9,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(vignette,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: inkDark)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            inkBlack.withValues(alpha: 0.25),
                            inkBlack.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      top: 5,
                      child: Container(
                          padding: const EdgeInsets.all(3),
                          color: inkBlack.withValues(alpha: 0.85),
                          child: icon),
                    ),
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Text(kind.toUpperCase(),
                          style: _prose(8, inkPaper).copyWith(
                              letterSpacing: 0.6, fontWeight: FontWeight.w700)),
                    ),
                    Positioned(
                        left: 5, bottom: 5, child: TowerSeal(rarity: rarity)),
                    if (tag != null)
                      Positioned(right: 4, bottom: 6, child: tag!),
                  ]),
                ),
                Container(
                  color: inkPaper,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
                  child: Text(name,
                      key: nameKey,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _display(12, inkOnPaper)),
                ),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
                    // The words at a readable size, cut by whole lines with an
                    // ellipsis (never a half line); the card in hand shows all of
                    // them under the row.
                    child: LayoutBuilder(builder: (context, box) {
                      final style = _prose(9.5, inkPaper);
                      // One line's real height (the font's own), for whole lines.
                      final probe = TextPainter(
                        text: TextSpan(text: 'Ag', style: style),
                        textDirection: TextDirection.ltr,
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout();
                      final line = probe.height;
                      probe.dispose();
                      final lines = math.max(1, (box.maxHeight / line).floor());
                      return Text(text,
                          maxLines: lines,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: style);
                    }),
                  ),
                ),
                if (footer != null)
                  SizedBox(
                      width: double.infinity,
                      child: FittedBox(fit: BoxFit.scaleDown, child: footer)),
              ])),
          // Art's frame over the card: its corner curls and thin border (a
          // nine-slice, so it fits any card; a missing picture draws nothing).
          IgnorePointer(
            child: Image.asset(towerCardFrame,
                scale: _frameScale,
                fit: BoxFit.fill,
                centerSlice: const Rect.fromLTRB(12, 12, 100, 148),
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ]),
      ),
    );
    if (dim) card = Opacity(opacity: 0.72, child: card);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, held ? -6 : 0, 0),
        decoration: BoxDecoration(boxShadow: [
          if (held)
            const BoxShadow(
                color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 6)),
        ]),
        child: card,
      ),
    );
  }
}

/// One card as a row (the fallback): a paper title band over a black body
/// with the icon and the words, the rarity as a stripe on the left edge.
class TowerRowCard extends StatelessWidget {
  const TowerRowCard({
    super.key,
    required this.kind,
    required this.name,
    required this.text,
    required this.icon,
    this.rarity,
    this.held = false,
    this.dim = false,
    this.onTap,
    this.tag,
    this.footer,
    this.nameKey,
  });

  final String kind, name, text;
  final Widget icon;
  final int? rarity;
  final bool held, dim;
  final VoidCallback? onTap;
  final Widget? tag, footer;
  final Key? nameKey;

  @override
  Widget build(BuildContext context) {
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: inkBlack,
        border: Border.all(
            color: held ? inkRed : inkPaper.withValues(alpha: 0.7),
            width: held ? 2.5 : 1),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: rarity == null ? inkSlate : inkRed),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: inkPaper,
                    padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
                    child: Row(children: [
                      Expanded(
                          child: Text(name,
                              key: nameKey,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: _display(15.5, inkOnPaper))),
                      const SizedBox(width: 6),
                      TowerSeal(rarity: rarity, size: 20),
                      const SizedBox(width: 6),
                      Text(kind.toUpperCase(),
                          style: _prose(9, inkSlate).copyWith(
                              letterSpacing: 1, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            color: inkDark,
                            alignment: Alignment.center,
                            child: icon,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(text, style: _prose(11.5, inkPaper)),
                                  if (tag != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: tag),
                                  if (footer != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: footer),
                                ]),
                          ),
                        ]),
                  ),
                ]),
          ),
        ]),
      ),
    );
    if (dim) card = Opacity(opacity: 0.72, child: card);
    return GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}
