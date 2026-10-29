// The drawing of the clan power sign mock (ux_clan_power_mock_test.dart):
// today's power cloth as the reference and three other ways to show how
// strong a clan is, each on the four places where a clan's power shows (the
// clan list, a clan's page, the clan banner chip, the district view), built
// from the real banners and the real standing disc over sample strengths.
// Mock only; nothing here ships.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/widgets/clan_glance.dart' show PowerCloth;
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/standing_sign.dart';

const Color ink = Color(0xFF14121A);
const Color gold = Color(0xFFF2C14E);
const Color goldDeep = Color(0xFF8A6B1E);
const Color fallBlue = Color(0xFF7F93B8);
const Color ash = Color(0xFF8B8478);

/// A clan with a sample strength: [power] now, [prev] at the last chapter's
/// turn, and how it stands with the player.
class SampleClan {
  const SampleClan(
      this.id, this.name, this.color, this.power, this.prev, this.standing);

  final String id;
  final String name;
  final Color color;
  final int power;
  final int prev;
  final StandingTier standing;

  int get delta => power - prev;
}

/// The clans that have a power, in the order of the clan list (not of
/// strength). The numbers are the clans' starting powers moved a little, as
/// a chapter or two would move them.
const List<SampleClan> sampleClans = [
  SampleClan(
      'dominion', 'Dominion', Color(0xFF2F62B5), 60, 57, StandingTier.wary),
  SampleClan(
      'vigil', 'Vigil', Color(0xFF8A8F98), 30, 34, StandingTier.friendly),
  SampleClan(
      'compact', 'Compact', Color(0xFFB86B3C), 40, 39, StandingTier.trusted),
  SampleClan('mire', 'Mire', Color(0xFF3F8F5A), 25, 25, StandingTier.unknown),
  SampleClan('crows', 'Crows', Color(0xFFB0303F), 45, 40, StandingTier.hostile),
  SampleClan(
      'penitents', 'Penitents', Color(0xFFCBB68E), 25, 27, StandingTier.known),
  SampleClan(
      'giants', 'Giants', Color(0xFF6F8796), 20, 20, StandingTier.unknown),
  SampleClan('oni', 'Oni', Color(0xFFD9661F), 15, 13, StandingTier.unfriendly),
  SampleClan(
      'tidekin', 'Tide-Kin', Color(0xFF1C8FA0), 15, 15, StandingTier.unknown),
  SampleClan(
      'kindly', 'Kindly Ones', Color(0xFF869A2A), 10, 13, StandingTier.known),
];

/// The clans from the strongest down (ties keep the list's order).
List<SampleClan> byStrength() {
  final all = [...sampleClans];
  all.sort((a, b) => b.power.compareTo(a.power));
  return all;
}

int rankOf(SampleClan c) => byStrength().indexOf(c) + 1;

SampleClan clanById(String id) => sampleClans.firstWhere((c) => c.id == id);

/// A clan with this much power can attack (wave 18).
const int attackPower = 10;

const List<String> tierNames = ['Minor', 'Rising', 'Dominant', 'Ascendant'];

String tierName(int power) => tierNames[powerTierFor(power).index];

enum Idea { cloth, ranking, torches, skyline }

// ---------------------------------------------------------------- pieces

TextStyle px(double size, {Color? c}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, height: 1, color: c ?? ink);

/// A small arrow for how the power moved since the last chapter: up in gold,
/// down in a cold blue, a dash when it held. (No green or red: those belong
/// to the standing.)
class Trend extends StatelessWidget {
  const Trend(this.delta, {super.key, this.size = 10, this.onDark = false});

  final int delta;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _TrendPainter(delta, onDark)),
      );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.delta, this.onDark);

  final int delta;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size s) {
    if (delta == 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(s.width * 0.15, s.height * 0.42, s.width * 0.7,
                  s.height * 0.16),
              const Radius.circular(1)),
          Paint()..color = ash);
      return;
    }
    final up = delta > 0;
    final p = Path()
      ..moveTo(s.width / 2, up ? 0 : s.height)
      ..lineTo(s.width, up ? s.height : 0)
      ..lineTo(0, up ? s.height : 0)
      ..close();
    canvas.drawPath(p, Paint()..color = up ? goldDeepOrGold(onDark) : fallBlue);
  }

  Color goldDeepOrGold(bool dark) => dark ? gold : goldDeep;

  @override
  bool shouldRepaint(_TrendPainter old) => old.delta != delta;
}

/// "+3" / "-4" / "0" in the pixel face.
String signed(int d) => d > 0 ? '+$d' : (d < 0 ? '−${-d}' : '0');

/// A dark plate with [child], the sign's own ground so it reads on any
/// panel and is never mistaken for the banner or the standing disc.
class Plate extends StatelessWidget {
  const Plate({super.key, required this.child, this.pad = 3});

  final Widget child;
  final double pad;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: pad + 1, vertical: pad),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: goldDeep, width: 1),
        ),
        child: child,
      );
}

// --------------------------------------------------------------- torches

/// Four torches, one for each 25 power. A torch is lit as far as the power
/// has reached it: full for 25, a part-flame for the part. Under 10 power
/// the first torch is only an ember (the clan cannot attack yet).
class Torches extends StatelessWidget {
  const Torches(this.power, {super.key, this.height = 20, this.onDark = false});

  final int power;
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: height * 0.55 * 4,
        height: height,
        child: CustomPaint(painter: _TorchesPainter(power, onDark)),
      );
}

class _TorchesPainter extends CustomPainter {
  const _TorchesPainter(this.power, this.onDark);

  final int power;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size s) {
    final cell = s.width / 4;
    final stickColor =
        onDark ? const Color(0xFF8A7A5A) : const Color(0xFF5B4A33);
    for (var k = 0; k < 4; k++) {
      final f = ((power - 25 * k) / 25).clamp(0.0, 1.0);
      final cx = cell * (k + 0.5);
      final top = s.height * 0.42;
      // The stick.
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - cell * 0.09, top, cell * 0.18, s.height - top),
              const Radius.circular(1)),
          Paint()
            ..color = f > 0 ? stickColor : stickColor.withValues(alpha: 0.5));
      // The head: a small cup.
      canvas.drawRect(
          Rect.fromLTWH(cx - cell * 0.18, top - s.height * 0.05, cell * 0.36,
              s.height * 0.1),
          Paint()..color = stickColor);
      final emberOnly = k == 0 && power < attackPower;
      if (f <= 0) continue;
      if (emberOnly) {
        canvas.drawCircle(Offset(cx, top - s.height * 0.1), cell * 0.12,
            Paint()..color = const Color(0xFFB5683A));
        continue;
      }
      // The flame, as tall as the torch is lit.
      final h = s.height * 0.5 * (0.35 + 0.65 * f);
      final w = cell * 0.34 * (0.6 + 0.4 * f);
      final base = top - s.height * 0.05;
      final outer = Path()
        ..moveTo(cx, base)
        ..quadraticBezierTo(cx - w, base - h * 0.45, cx - w * 0.25, base - h)
        ..quadraticBezierTo(
            cx + w * 0.1, base - h * 0.62, cx + w * 0.4, base - h * 0.78)
        ..quadraticBezierTo(cx + w * 1.1, base - h * 0.3, cx, base)
        ..close();
      canvas.drawPath(
          outer, Paint()..color = f >= 1 ? gold : const Color(0xFFE79A3C));
      canvas.drawPath(
          Path()
            ..moveTo(cx, base)
            ..quadraticBezierTo(
                cx - w * 0.35, base - h * 0.3, cx, base - h * 0.62)
            ..quadraticBezierTo(cx + w * 0.35, base - h * 0.3, cx, base),
          Paint()..color = const Color(0xFFFFF0B0));
    }
  }

  @override
  bool shouldRepaint(_TorchesPainter old) =>
      old.power != power || old.onDark != onDark;
}

// --------------------------------------------------------------- skyline

/// All the clans' banners standing in a row on one ground line, each as high
/// as its power, the strongest first; [highlight] named and underlined, a
/// ghost where it stood at the last chapter's turn (a lighter extension for
/// what it gained, a dashed outline for what it lost); dotted lines at the
/// tiers and a dashed one at the attack line.
class Skyline extends StatelessWidget {
  const Skyline({
    super.key,
    required this.width,
    required this.height,
    this.highlight,
    this.names = false,
    this.lines = true,
  });

  final double width;
  final double height;
  final String? highlight;
  final bool names;
  final bool lines;

  /// The height of a banner standing for [power] in a skyline [height] high.
  static double heightOf(int power, double height) =>
      height * (0.2 + 0.8 * power / 75).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final clans = byStrength();
    final slot = width / clans.length;
    // A banner is half as wide as it is tall: the tallest must fit its slot.
    final top = math.min(height, slot * 2 - 2);
    final ground = names ? 16.0 : 6.0;
    return SizedBox(
      width: width,
      height: top + 12 + ground,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (lines)
            Positioned.fill(
              bottom: ground,
              child: CustomPaint(painter: _TierLines(top)),
            ),
          for (var i = 0; i < clans.length; i++)
            _flag(clans[i], i, slot, top, ground),
        ],
      ),
    );
  }

  Widget _flag(SampleClan c, int i, double slot, double top, double ground) {
    final isMe = c.id == highlight;
    final h = heightOf(c.power, top);
    final hPrev = heightOf(c.prev, top);
    final tall = math.max(h, hPrev);
    return Positioned(
      left: slot * i,
      width: slot,
      bottom: ground,
      height: tall + 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Where it stood at the last turn, when it has lost: a dashed outline.
          if (c.delta < 0)
            Positioned(
              bottom: 0,
              width: hPrev / 2 + 2,
              height: hPrev,
              child: const CustomPaint(painter: _Dashed(fallBlue)),
            ),
          // What it gained: a gold bar up the flag's side from the old height.
          if (c.delta > 0)
            Positioned(
              bottom: hPrev,
              left: slot / 2 + h / 4 + 1,
              width: 2,
              height: h - hPrev,
              child: Container(color: gold),
            ),
          Positioned(bottom: 0, child: ClanFlag(factionId: c.id, height: h)),
          if (isMe)
            Positioned(
              bottom: -4,
              left: 1,
              right: 1,
              child: Container(height: 2, color: goldDeep),
            ),
          if (c.delta != 0)
            Positioned(
              bottom: tall + 1,
              child: Trend(c.delta, size: 8),
            ),
        ],
      ),
    );
  }
}

class _TierLines extends CustomPainter {
  const _TierLines(this.height);

  final double height;

  @override
  void paint(Canvas canvas, Size s) {
    for (final (p, strong) in const [
      (25, false),
      (50, false),
      (75, false),
      (attackPower, true),
    ]) {
      final y = s.height - Skyline.heightOf(p, height);
      final paint = Paint()
        ..color =
            (strong ? const Color(0xFFB5683A) : ash).withValues(alpha: 0.55)
        ..strokeWidth = 1;
      var x = 0.0;
      final dash = strong ? 6.0 : 2.0;
      while (x < s.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
        x += dash * 2;
      }
    }
  }

  @override
  bool shouldRepaint(_TierLines old) => old.height != height;
}

class _Dashed extends CustomPainter {
  const _Dashed(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 3.0;
    final path = Path();
    for (var x = 0.0; x < s.width; x += dash * 2) {
      path.moveTo(x, 0);
      path.lineTo(math.min(x + dash, s.width), 0);
    }
    for (var x = 0.0; x < s.width; x += dash * 2) {
      path.moveTo(x, s.height);
      path.lineTo(math.min(x + dash, s.width), s.height);
    }
    for (var y = 0.0; y < s.height; y += dash * 2) {
      path.moveTo(0, y);
      path.lineTo(0, math.min(y + dash, s.height));
      path.moveTo(s.width, y);
      path.lineTo(s.width, math.min(y + dash, s.height));
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_Dashed old) => false;
}

// ----------------------------------------------------------------- ranking

/// The ranked bars of every clan: strongest first, this clan's row framed;
/// ticks where the tiers begin and a dashed line at the attack power; each
/// row's power and how it moved. At a narrow width only the framed clan
/// keeps its name (the others are their flags).
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.highlight, required this.width});

  final String highlight;
  final double width;

  @override
  Widget build(BuildContext context) {
    final clans = byStrength();
    final narrow = width < 360;
    final theme = Theme.of(context);
    return Column(
      key: const Key('ranked_bars'),
      children: [
        for (var i = 0; i < clans.length; i++)
          _row(context, clans[i], i + 1, narrow, theme),
      ],
    );
  }

  Widget _row(BuildContext context, SampleClan c, int rank, bool narrow,
      ThemeData theme) {
    final me = c.id == highlight;
    return Container(
      height: 21,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: me
          ? BoxDecoration(
              color: gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: goldDeep, width: 1),
            )
          : null,
      child: Row(children: [
        SizedBox(
          width: 16,
          child: Text('$rank',
              textAlign: TextAlign.center, style: px(11, c: me ? ink : ash)),
        ),
        ClanFlag(factionId: c.id, height: 17),
        const SizedBox(width: 4),
        if (!narrow || me)
          SizedBox(
            width: narrow ? 70 : 78,
            child: Text(c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: me ? FontWeight.w700 : FontWeight.w400)),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            return CustomPaint(
              size: Size(box.maxWidth, 21),
              painter: _BarPainter(c.power, c.color),
            );
          }),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          child: Text('${c.power}',
              textAlign: TextAlign.right, style: px(11, c: ink)),
        ),
        const SizedBox(width: 3),
        Trend(c.delta, size: 8),
        SizedBox(
          width: 17,
          child: Text(c.delta == 0 ? '' : '${c.delta.abs()}',
              textAlign: TextAlign.right, style: px(9, c: ash)),
        ),
      ]),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter(this.power, this.color);

  final int power;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final y0 = s.height * 0.3;
    final h = s.height * 0.4;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, y0, s.width, h), const Radius.circular(2)),
        Paint()..color = ash.withValues(alpha: 0.22));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, y0, s.width * power / maxPower, h),
            const Radius.circular(2)),
        Paint()..color = color);
    for (final t in const [25, 50, 75]) {
      canvas.drawLine(
          Offset(s.width * t / maxPower, y0 - 2),
          Offset(s.width * t / maxPower, y0 + h + 2),
          Paint()
            ..color = ash
            ..strokeWidth = 1);
    }
    // The attack line.
    final x = s.width * attackPower / maxPower;
    final dash = Paint()
      ..color = const Color(0xFFB5683A)
      ..strokeWidth = 1.2;
    for (var y = 0.0; y < s.height; y += 4) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 2, s.height)), dash);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.power != power;
}

// --------------------------------------------------------- today's cloth

/// Today's banner: the real power cloth.
Widget clothFlag(SampleClan c, double h) => PowerCloth(
      tier: powerTierFor(c.power),
      child: ClanFlag(factionId: c.id, height: h),
    );

/// A clan's banner with the standing disc at its corner, as the lists and
/// cards show it, plus (for the reference) the cloth.
Widget bannerWithDisc(SampleClan c, double h,
    {bool cloth = false, double disc = 22}) {
  final flag = cloth ? clothFlag(c, h) : ClanFlag(factionId: c.id, height: h);
  return SizedBox(
    width: h / 2 + disc * 0.2,
    height: h,
    child: Stack(clipBehavior: Clip.none, children: [
      flag,
      Positioned(
        right: -disc * 0.2,
        top: -disc * 0.2,
        child: StandingSign(c.standing, size: disc),
      ),
    ]),
  );
}
