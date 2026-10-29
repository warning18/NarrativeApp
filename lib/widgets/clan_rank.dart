// The clan power sign (docs/proposals/clan-power-sign.md, A "Ranking"): how
// strong a clan is as a place in the line and an arrow. A dark plate says
// "#2" and how the clan moved since the last chapter's turn (an arrow up,
// down, or a dash when it held); the clan's page ranks every clan in bars
// with the tiers and the attack line marked. Gold and a cold blue-grey,
// never the standing disc's green and red, and never on the banner itself,
// so strength is not mistaken for how the clan likes you. The numbers are
// Core's (clanPowerRankingProvider).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart';
import '../data/district_attacks.dart' show attackMinPower;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../theme/stitched_ink.dart';
import 'pixel_banner.dart';

const Color _plate = Color(0xFF14121A);
const Color _gold = Color(0xFFF2C14E);
const Color _goldDeep = Color(0xFF8A6B1E);
const Color _fall = Color(0xFF7F93B8);
const Color _attack = Color(0xFFB5683A);

/// How the plate and the bars show a clan's move: [change] places up (>0),
/// down (<0) or none.
enum RankMove { up, down, steady }

RankMove rankMoveOf(int change) => change > 0
    ? RankMove.up
    : change < 0
        ? RankMove.down
        : RankMove.steady;

/// A small arrow (up in gold, down in blue-grey) or a dash (it held).
class RankArrow extends StatelessWidget {
  const RankArrow(this.move, {super.key, this.size = 9, this.onPlate = false});

  final RankMove move;
  final double size;

  /// Drawn on the dark plate (a lighter gold) rather than on the page.
  final bool onPlate;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: Key('rank_arrow_${move.name}'),
        width: size,
        height: size,
        child: CustomPaint(painter: _ArrowPainter(move, onPlate)),
      );
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.move, this.onPlate);

  final RankMove move;
  final bool onPlate;

  @override
  void paint(Canvas canvas, Size s) {
    if (move == RankMove.steady) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(s.width * 0.15, s.height * 0.42, s.width * 0.7,
                  s.height * 0.16),
              const Radius.circular(1)),
          Paint()..color = const Color(0xFF8B8478));
      return;
    }
    final up = move == RankMove.up;
    final path = Path()
      ..moveTo(s.width / 2, up ? 0 : s.height)
      ..lineTo(s.width, up ? s.height : 0)
      ..lineTo(0, up ? s.height : 0)
      ..close();
    canvas.drawPath(
        path, Paint()..color = up ? (onPlate ? _gold : _goldDeep) : _fall);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.move != move || old.onPlate != onPlate;
}

/// "#2 ▲": a clan's place among the clans with power, and its move.
class RankPlate extends StatelessWidget {
  const RankPlate(this.rank, {super.key, this.compact = false});

  final ClanPowerRank rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final move = rankMoveOf(rank.rankChange);
    final size = compact ? 8.0 : 10.0;
    return Semantics(
      label: '${rank.rank}',
      child: Container(
        key: Key('rank_plate_${rank.clanId}'),
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 5, vertical: 2),
        decoration: BoxDecoration(
          color: _plate,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _goldDeep, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('#${rank.rank}',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: compact ? 10 : 12,
                  height: 1,
                  color: _gold)),
          SizedBox(width: compact ? 2 : 3),
          RankArrow(move, size: size, onPlate: true),
        ]),
      ),
    );
  }
}

/// [clanId]'s rank plate, or nothing for a clan with no power.
class ClanRankPlate extends ConsumerWidget {
  const ClanRankPlate({super.key, required this.clanId, this.compact = false});

  final String clanId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = _rankOf(ref.watch(clanPowerRankingProvider), clanId);
    return rank == null
        ? const SizedBox.shrink()
        : RankPlate(rank, compact: compact);
  }
}

ClanPowerRank? _rankOf(List<ClanPowerRank> ranking, String id) {
  for (final r in ranking) {
    if (r.clanId == id) return r;
  }
  return null;
}

/// Every clan with power as a bar, the strongest first, [highlight]'s row
/// framed; ticks at the tiers (25, 50, 75) and a dashed line at the power a
/// clan needs to attack. At a narrow width only the framed clan keeps its
/// name (the others are their flags).
class RankedBars extends ConsumerWidget {
  const RankedBars({super.key, required this.highlight, required this.width});

  final String highlight;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(clanPowerRankingProvider);
    final data = ref.watch(clanDataProvider);
    final lang = ref.watch(appLanguageProvider);
    final narrow = width < 360;
    final theme = Theme.of(context);
    return Column(
      key: const Key('ranked_bars'),
      children: [
        for (final r in ranking)
          _Row(
            rank: r,
            me: r.clanId == highlight,
            narrow: narrow,
            name: data.faction(r.clanId)?.shortFor(lang) ?? r.clanId,
            color: Color(data.faction(r.clanId)?.color ?? 0xFF8B8478),
            theme: theme,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.me,
    required this.narrow,
    required this.name,
    required this.color,
    required this.theme,
  });

  final ClanPowerRank rank;
  final bool me;
  final bool narrow;
  final String name;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final text = theme.textTheme.labelSmall;
    return Container(
      key: Key('ranked_row_${rank.clanId}'),
      height: 21,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: me
          ? BoxDecoration(
              color: _gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _goldDeep, width: 1),
            )
          : null,
      child: Row(children: [
        SizedBox(
          width: 18,
          child: Text('${rank.rank}',
              textAlign: TextAlign.center,
              style: text?.copyWith(
                  fontFamily: InkFonts.system,
                  color: me ? theme.colorScheme.onSurface : ink.ash)),
        ),
        ClanFlag(factionId: rank.clanId, height: 17),
        const SizedBox(width: 4),
        if (!narrow || me)
          SizedBox(
            width: narrow ? 70 : 78,
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text?.copyWith(
                    fontWeight: me ? FontWeight.w700 : FontWeight.w400)),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => CustomPaint(
              size: Size(box.maxWidth, 21),
              painter: _BarPainter(rank.power, color, ink.ash),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 22,
          child: Text('${rank.power}',
              textAlign: TextAlign.right,
              style: text?.copyWith(fontFamily: InkFonts.system)),
        ),
        const SizedBox(width: 3),
        RankArrow(rankMoveOf(rank.powerChange), size: 8),
        SizedBox(
          width: 18,
          child: Text(rank.powerChange == 0 ? '' : '${rank.powerChange.abs()}',
              textAlign: TextAlign.right,
              style: text?.copyWith(
                  fontFamily: InkFonts.system, color: ink.ash, fontSize: 9)),
        ),
      ]),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter(this.power, this.color, this.ash);

  final int power;
  final Color color;
  final Color ash;

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
    for (final t in const [risingPower, dominantPower, ascendantPower]) {
      final x = s.width * t / maxPower;
      canvas.drawLine(
          Offset(x, y0 - 2),
          Offset(x, y0 + h + 2),
          Paint()
            ..color = ash
            ..strokeWidth = 1);
    }
    // The attack line, dashed.
    final x = s.width * attackMinPower / maxPower;
    final dash = Paint()
      ..color = _attack
      ..strokeWidth = 1.2;
    for (var y = 0.0; y < s.height; y += 4) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 2), dash);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.power != power || old.color != color;
}

/// The line under the bars saying what the ticks, the dashed line and the
/// arrows mean.
class RankLegend extends ConsumerWidget {
  const RankLegend({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
        tr(ref, 'rank_legend')
            .replaceAll('{attack}', '$attackMinPower')
            .replaceAll('{rising}', '$risingPower')
            .replaceAll('{dominant}', '$dominantPower')
            .replaceAll('{ascendant}', '$ascendantPower'),
        key: const Key('rank_legend'),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: InkColors.of(context).ash),
      );
}
