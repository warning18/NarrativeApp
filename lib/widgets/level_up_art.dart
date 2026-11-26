// The Level Up screen's art (v2.10.19): Art's painted plate behind the hero
// (shrine, anvil, yard: one per level, level % 3, so the screen is the same
// when it is reopened), the red ribbon with "Level N" drawn in code, the
// hero's south frame standing in the plate, and Art's eight stat symbols.
// Under it, the stats area: the ability radar with the symbols at its
// corners, the hero's shape, the pick ghosted over it in red dashes.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/tower/ink/ink_palette.dart';
import '../theme/stitched_ink.dart' show InkFonts;
import 'ability_radar.dart' show abilityAbbrevKey, abilityRadarOrder;

const List<String> _plates = ['shrine', 'anvil', 'yard'];

/// The plate of a level: [level] % 3.
String levelUpPlateAsset(int level) =>
    'assets/visuals/levelup/plate_${_plates[level % 3]}.png';

const Set<String> _heroes = {
  'warrior',
  'mage',
  'rogue',
  'cleric',
  'ranger',
  'dwarf',
  'orc',
};

/// The hero's south frame, or the warrior's when the hero has none yet.
String levelUpHeroAsset(String walkName) =>
    'assets/visuals/levelup/hero_${_heroes.contains(walkName) ? walkName : 'warrior'}.png';

/// Art's symbol of an ability (its key, as in [abilityRadarOrder]).
String levelUpStatAsset(String ability) {
  final id = switch (ability) {
    'strength' => 'str',
    'dexterity' => 'dex',
    'constitution' => 'con',
    'intelligence' => 'int',
    'wisdom' => 'wis',
    'perception' => 'per',
    'luck' => 'luck',
    _ => 'cha',
  };
  return 'assets/visuals/levelup/stat_$id.png';
}

/// A symbol drawn crisp at [size] (the files are 24 px).
class LevelUpSymbol extends StatelessWidget {
  const LevelUpSymbol(this.ability, {super.key, this.size = 24});

  final String ability;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        levelUpStatAsset(ability),
        width: size,
        height: size,
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        gaplessPlayback: true,
      );
}

TextStyle _digits(double size, Color color, {FontWeight? weight}) => TextStyle(
      fontFamily: InkFonts.prose,
      fontSize: size,
      height: 1.1,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.liningFigures()],
    );

/// The top of the screen: the plate, the ribbon, the hero (Art's layout: a
/// 180 x 320 plate scaled to the width, the ribbon at y 12, the hero 48 px
/// drawn at 2x with its feet near y 192, centred at x 90; cut at y 214).
class LevelUpStage extends StatelessWidget {
  const LevelUpStage({
    super.key,
    required this.level,
    required this.heroName,
    required this.levelLabel,
  });

  final int level;

  /// The hero's walk name ([heroWalkName]).
  final String heroName;

  /// "Level" in the language.
  final String levelLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final k = w / 180;
          return SizedBox(
            width: w,
            height: 214 * k,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: w,
                    height: 320 * k,
                    child: Image.asset(
                      levelUpPlateAsset(level),
                      key: const Key('level_up_plate'),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                    ),
                  ),
                  Positioned(
                    left: 6 * k,
                    top: 12 * k,
                    width: 168 * k,
                    height: 27 * k,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/visuals/levelup/ribbon.png',
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            isAntiAlias: false,
                          ),
                        ),
                        Text.rich(
                          key: const Key('level_up_ribbon'),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$levelLabel ',
                                style: TextStyle(
                                  fontFamily: InkFonts.display,
                                  fontSize: 15 * k,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '$level',
                                style: _digits(
                                  15 * k,
                                  Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 42 * k,
                    top: 96 * k,
                    width: 96 * k,
                    height: 96 * k,
                    child: Image.asset(
                      levelUpHeroAsset(heroName),
                      key: const Key('level_up_hero'),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

/// The value of an ability as the stats area shows it, a minus sign that
/// reads (an en dash is too faint at this size).
String levelUpValueText(int v) => v < 0 ? '−${-v}' : '$v';

/// The stats area: [before] the hero's eight abilities now, [after] with the
/// pick over them (null while none is chosen). [label] is an ability's short
/// name in the language.
class LevelUpStatsArea extends StatelessWidget {
  const LevelUpStatsArea({
    super.key,
    required this.before,
    required this.after,
    required this.label,
    this.dark = false,
    this.compact = false,
  });

  final Map<String, int> before;
  final Map<String, int>? after;
  final String Function(String ability) label;

  /// Smaller: the symbols and values round a compact shape, no names.
  final bool compact;

  /// Drawn for a black ground (paper lines and numbers) instead of paper.
  final bool dark;

  @override
  Widget build(BuildContext context) => _Radar(
      before: before, after: after, label: label, dark: dark, compact: compact);
}

/// The radar: Art's symbols at the eight corners with their numbers, a
/// filled shape, the pick ghosted in red dashes over it, rings every four
/// points with the first at -2 and the zero ring heavier.
class _Radar extends StatelessWidget {
  const _Radar({
    required this.before,
    required this.after,
    required this.label,
    this.dark = false,
    this.compact = false,
  });

  final Map<String, int> before;
  final Map<String, int>? after;
  final String Function(String) label;
  final bool dark;
  final bool compact;

  static const double _lo = -4;
  static const List<int> _rings = [-2, 0, 4, 8, 12];

  @override
  Widget build(BuildContext context) {
    final top = [12, ...before.values, ...?after?.values].reduce(math.max);
    final hi = (top + 1).toDouble();
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, compact ? 230.0 : 330.0);
        final r = side / 2 - (compact ? 36 : 50);
        final extra = compact ? 16.0 : 40.0;
        final centre = compact
            ? Offset(side / 2, side / 2 + 8)
            : Offset(side / 2, side / 2 + 4);
        Offset corner(int i, double radius) {
          final a = -math.pi / 2 + i * 2 * math.pi / 8;
          return centre + Offset(math.cos(a), math.sin(a)) * radius;
        }

        return Center(
          child: SizedBox(
            key: const Key('stat_pick_radar'),
            width: side,
            height: side + extra,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RadarPainter(
                      before: [
                        for (final k in abilityRadarOrder) before[k] ?? 0,
                      ],
                      after: after == null
                          ? null
                          : [for (final k in abilityRadarOrder) after![k] ?? 0],
                      radius: r,
                      hi: hi,
                      dark: dark,
                    ),
                  ),
                ),
                for (final (i, k) in abilityRadarOrder.indexed)
                  Positioned(
                    left: corner(i, r + (compact ? 22 : 30)).dx - 24,
                    top: corner(i, r + (compact ? 22 : 30)).dy -
                        (compact ? 19 : 25),
                    width: 48,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LevelUpSymbol(k, size: compact ? 20 : 24),
                        Text(
                          after != null && (after![k] ?? 0) != (before[k] ?? 0)
                              ? '${levelUpValueText(before[k] ?? 0)}→${levelUpValueText(after![k] ?? 0)}'
                              : levelUpValueText(before[k] ?? 0),
                          style: _digits(
                            compact ? 11 : 13,
                            after != null &&
                                    (after![k] ?? 0) != (before[k] ?? 0)
                                ? (dark ? inkRed : inkRedDeep)
                                : (dark ? inkPaper : inkDeep),
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (!compact)
                          Text(
                            label(k),
                            style: TextStyle(
                              fontFamily: InkFonts.system,
                              fontSize: 10,
                              height: 1,
                              color: dark ? inkGrey : inkSlate,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.before,
    required this.after,
    required this.radius,
    required this.hi,
    this.dark = false,
  });

  final List<int> before;
  final List<int>? after;
  final double radius;
  final double hi;
  final bool dark;

  double _r(num v) =>
      ((v - _Radar._lo) / (hi - _Radar._lo)).clamp(0.02, 1.0) * radius;

  Path _shape(Offset c, List<int> values) {
    final p = Path();
    for (var i = 0; i < values.length; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 8;
      final o = c + Offset(math.cos(a), math.sin(a)) * _r(values[i]);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    // The rings: the first at -2, the zero ring heavier.
    for (final ring in _Radar._rings) {
      line
        ..color = ring == 0
            ? (dark ? inkPaper : inkDeep)
            : (dark ? inkGrey : inkSlate).withValues(alpha: 0.45)
        ..strokeWidth = ring == 0 ? 2 : 1;
      canvas.drawPath(_shape(c, List.filled(8, ring)), line);
      final tp = TextPainter(
        text: TextSpan(
          text: ring < 0 ? '−${-ring}' : '$ring',
          style: _digits(10, dark ? inkGrey : inkSlate),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c + Offset(3, -_r(ring) - tp.height + 1));
    }
    line
      ..color = (dark ? inkGrey : inkSlate).withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 8;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * radius, line);
    }
    // The hero's shape.
    final shape = _shape(c, before);
    canvas.drawPath(
      shape,
      Paint()
        ..color =
            (dark ? inkGrey : inkSlate).withValues(alpha: dark ? 0.35 : 0.5)
        ..isAntiAlias = false,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = dark ? inkPaper : inkDeep
        ..isAntiAlias = false,
    );
    // The pick, ghosted in red dashes.
    final next = after;
    if (next != null) {
      final ghost = _shape(c, next);
      canvas.drawPath(
        ghost,
        Paint()
          ..color = inkRed.withValues(alpha: 0.14)
          ..isAntiAlias = false,
      );
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = inkRed
        ..isAntiAlias = false;
      for (final m in ghost.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), dash);
          d += 10;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.before != before ||
      old.after != after ||
      old.radius != radius ||
      old.hi != hi ||
      old.dark != dark;
}

/// The short name of an ability is the app's own string; this lists its key
/// for callers (see [abilityAbbrevKey]).
String levelUpLabelKey(String ability) => abilityAbbrevKey(ability);
