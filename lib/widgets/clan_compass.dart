// The clans' compass (Wave 7 D, board 16's design 2): the clans as crests on
// a ring where friends sit side by side and the blood feuds face each other.
// A focused clan's lines run to every other clan, coloured by how the two
// stand (relations.json's steps); a number on a crest says what changes for
// it. Used small in the clan offer and in the Clans screen's Standing tab.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../theme/stitched_ink.dart';
import 'clan_peek.dart';
import 'pixel_banner.dart';

/// A number on a crest: "+6", "−3", a standing.
typedef CompassBadge = ({String text, Color color});

/// The clans' order round the ring: the first stays on top, the others take
/// the order whose neighbours stand closest (a high relation step) and
/// whose opposites stand furthest apart. For six clans it tries every
/// order; for more it keeps the file's.
List<String> compassOrder(
    List<String> ids, int? Function(String, String) step) {
  if (ids.length < 3 || ids.length > 7) return ids;
  double score(List<String> order) {
    var total = 0.0;
    for (var i = 0; i < order.length; i++) {
      final next = order[(i + 1) % order.length];
      total += (step(order[i], next) ?? 4) - 4;
      if (order.length.isEven) {
        final across = order[(i + order.length ~/ 2) % order.length];
        total -= ((step(order[i], across) ?? 4) - 4) * 0.5;
      }
    }
    return total;
  }

  var best = ids;
  var bestScore = score(ids);
  void permute(List<String> rest, List<String> head) {
    if (rest.isEmpty) {
      final s = score(head);
      if (s > bestScore + 1e-9) {
        bestScore = s;
        best = List.of(head);
      }
      return;
    }
    for (var i = 0; i < rest.length; i++) {
      permute(
          [...rest.sublist(0, i), ...rest.sublist(i + 1)], [...head, rest[i]]);
    }
  }

  permute(ids.sublist(1), [ids.first]);
  return best;
}

/// Where the crests sit on a ring of [size]: the first on top, then
/// clockwise. The ring leaves room above for a number and below for a name.
List<Offset> compassPositions(Size size, int n,
    {double top = 26, double bottom = 38, double side = 34}) {
  final rx = size.width / 2 - side;
  final ry = (size.height - top - bottom) / 2;
  final cy = top + ry;
  return [
    for (var i = 0; i < n; i++)
      Offset(
        size.width / 2 + rx * math.cos(-math.pi / 2 + 2 * math.pi * i / n),
        cy + ry * math.sin(-math.pi / 2 + 2 * math.pi * i / n),
      ),
  ];
}

class ClanCompass extends StatelessWidget {
  const ClanCompass({
    super.key,
    required this.clans,
    required this.language,
    required this.relations,
    required this.stepOf,
    this.focusId,
    this.badges = const {},
    this.ringedIds = const {},
    this.onTap,
    this.height = 210,
    this.showLegend = true,
  });

  /// The clans on the ring.
  final List<Faction> clans;
  final AppLanguage language;
  final Relations relations;

  /// How two clans stand now (a step 1..7), null when they are not related.
  final int? Function(String a, String b) stepOf;

  /// The clan whose lines are drawn; none draws every pair, faintly.
  final String? focusId;

  /// A number on a crest, by clan id.
  final Map<String, CompassBadge> badges;

  /// Clans ringed in gold (the ones on offer).
  final Set<String> ringedIds;
  final ValueChanged<String>? onTap;
  final double height;
  final bool showLegend;

  Color _stepColor(int step) {
    final info = relations.stepInfo(step);
    return info == null
        ? const Color(0xFFA8A194)
        : Color(info.color | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final byId = {for (final c in clans) c.patron.id: c};
    final order = compassOrder([for (final c in clans) c.patron.id], stepOf);
    final usedSteps = <int>{};
    if (focusId != null) {
      for (final id in order) {
        final s = id == focusId ? null : stepOf(focusId!, id);
        if (s != null) usedSteps.add(s);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const Key('clan_compass'),
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ink.seam),
            gradient: RadialGradient(
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surface,
              ],
              radius: 0.8,
            ),
          ),
          child: LayoutBuilder(builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            final at = compassPositions(size, order.length);
            final pos = {for (final (i, id) in order.indexed) id: at[i]};
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LinesPainter(
                      order: order,
                      pos: pos,
                      stepOf: stepOf,
                      colorOf: _stepColor,
                      focusId: focusId,
                    ),
                  ),
                ),
                for (final id in order)
                  Positioned(
                    left: pos[id]!.dx - 30,
                    top: pos[id]!.dy - 22,
                    width: 60,
                    child: _Crest(
                      key: Key('compass_$id'),
                      faction: byId[id]!,
                      language: language,
                      focus: id == focusId,
                      ringed: ringedIds.contains(id),
                      badge: badges[id],
                      dimmed: focusId != null && id != focusId,
                      onTap: onTap == null ? null : () => onTap!(id),
                    ),
                  ),
              ],
            );
          }),
        ),
        if (showLegend && usedSteps.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              for (final s in (usedSteps.toList()..sort()).reversed)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 14, height: 3, color: _stepColor(s)),
                  const SizedBox(width: 4),
                  Text(relations.stepInfo(s)?.nameFor(language) ?? '$s',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: ink.ash, fontSize: 10)),
                ]),
            ],
          ),
        ],
      ],
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter({
    required this.order,
    required this.pos,
    required this.stepOf,
    required this.colorOf,
    required this.focusId,
  });

  final List<String> order;
  final Map<String, Offset> pos;
  final int? Function(String, String) stepOf;
  final Color Function(int) colorOf;
  final String? focusId;

  void _line(Canvas canvas, Offset a, Offset b, Color color, double width,
      bool dashed) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(a, b, paint);
      return;
    }
    final len = (b - a).distance;
    final dir = (b - a) / len;
    for (var d = 0.0; d < len; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, len), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < order.length; i++) {
      for (var j = i + 1; j < order.length; j++) {
        final a = order[i];
        final b = order[j];
        final step = stepOf(a, b);
        if (step == null) continue;
        final touches = focusId == a || focusId == b;
        if (focusId != null && !touches) continue;
        // Friends solid, foes dashed: told apart without the colour.
        _line(
          canvas,
          pos[a]!,
          pos[b]!,
          colorOf(step).withValues(alpha: focusId == null ? 0.4 : 0.95),
          focusId == null ? 1.2 : 2.2,
          step < 5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.focusId != focusId || old.pos != pos || old.order != order;
}

/// One clan on the ring: its crest (the top of its banner), its short name,
/// and the number it wears.
class _Crest extends StatelessWidget {
  const _Crest({
    super.key,
    required this.faction,
    required this.language,
    required this.focus,
    required this.ringed,
    required this.badge,
    required this.dimmed,
    required this.onTap,
  });

  final Faction faction;
  final AppLanguage language;
  final bool focus;
  final bool ringed;
  final CompassBadge? badge;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final color = Color(faction.color | 0xFF000000);
    final bannerId = clanBannerId(faction.patron.id);
    final d = focus ? 42.0 : 34.0;
    final ring = ringed ? ink.gold : color;
    final disc = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF141217),
        border: Border.all(color: ring, width: focus || ringed ? 2.5 : 1.5),
        boxShadow: focus
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 10)]
            : null,
      ),
      child: ClipOval(
        child: bannerId == null
            ? Icon(Icons.flag, size: d * 0.55, color: color)
            : Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/visuals/banners/$bannerId.png',
                  width: d,
                  height: d * 2,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  isAntiAlias: false,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => SizedBox(width: d, height: d),
                ),
              ),
      ),
    );
    return ClanPeek(
      factionId: faction.patron.id,
      child: Semantics(
        button: onTap != null,
        label: faction.shortFor(language),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: dimmed ? 0.8 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      disc,
                      if (badge != null)
                        Positioned(
                          right: 4,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141217),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badge!.color, width: 1),
                            ),
                            child: Text(badge!.text,
                                style: TextStyle(
                                    fontFamily: InkFonts.system,
                                    fontSize: 10,
                                    height: 1.1,
                                    color: badge!.color)),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(faction.shortFor(language),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
