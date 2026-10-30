// The Tree tab's sky (v1.619, docs/proposals/skills-ideas.md, idea 1): each
// class branch is a constellation on one night sky, a star for each skill and
// a crown for Mastery. A star lights gold once the skill is learned; the
// ringed star is the next one, bright when its clan can offer it now; the
// lines light up to the last learned star. Under the sky a card reads the
// focused constellation's next skill: who offers it, at what standing, and
// what it does. A tap on a star opens the skill's sheet (the crown opens the
// mastery's), a tap on a constellation's name puts it in the card.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart';
import '../../data/factions.dart';
import '../../data/offers.dart' show skillIndexCapFor;
import '../../data/skill_tree.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../providers/player_session_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/pixel_banner.dart';
import 'skill_sheet.dart';
import 'skills_view_model.dart';

/// The standing a clan needs to offer the skill at each index of a branch
/// (offers.dart, [skillIndexCapFor]).
const List<StandingTier> starTierForIndex = [
  StandingTier.unknown,
  StandingTier.known,
  StandingTier.trusted,
  StandingTier.sworn,
];

/// What the sky needs to know about one class branch.
class _StarBranch {
  const _StarBranch({
    required this.branch,
    required this.clanId,
    required this.clanName,
    required this.tier,
    required this.known,
    required this.nextIndex,
    required this.offerable,
    required this.mastered,
    required this.closed,
    required this.canMaster,
  });

  final SkillBranch branch;

  /// The clan that stands behind the next skill; null for none (or a branch
  /// learned to the end).
  final String? clanId;
  final String clanName;

  /// The character's standing with [clanId].
  final StandingTier? tier;

  /// Skills learned on the branch.
  final int known;

  /// The index of the next skill to learn; -1 when the branch is learned.
  final int nextIndex;

  /// The clan can offer the next skill now: the standing reaches its depth.
  final bool offerable;

  /// The branch is the mastered one; [closed]: another one is.
  final bool mastered;
  final bool closed;
  final bool canMaster;

  int get length => branch.skillIds.length;
  bool get complete => nextIndex < 0;
  String? get nextId => complete ? null : branch.skillIds[nextIndex];
}

/// The class branches of [model] as the sky shows them, with the standing of
/// [politics] against [data]'s clans.
List<_StarBranch> _starBranchesOf({
  required SkillsModel model,
  required ClanData data,
  required PoliticsState politics,
  required AppLanguage language,
}) {
  final out = <_StarBranch>[];
  for (final branch in model.classBranches) {
    final ids = [
      for (final id in branch.skillIds)
        if (model[id] != null) id,
    ];
    final known = ids.where((id) => model[id]!.known).length;
    final nextAt = ids.indexWhere((id) => !model[id]!.known);
    String? clan;
    if (nextAt >= 0) {
      for (final sponsor in model[ids[nextAt]]!.sponsors) {
        if (data.faction(sponsor) != null) {
          clan = sponsor;
          break;
        }
      }
    }
    final tier = clan == null ? null : politics.tierOf(clan, data);
    final next = nextAt < 0 ? null : model[ids[nextAt]];
    out.add(_StarBranch(
      branch: branch,
      clanId: clan,
      clanName: clan == null ? '' : data.faction(clan)!.shortFor(language),
      tier: tier,
      known: known,
      nextIndex: nextAt,
      offerable: next != null &&
          next.status == SkillStatus.ready &&
          tier != null &&
          skillIndexCapFor(tier) >= nextAt,
      mastered: branch.id == model.masteredBranchId,
      closed: model.masteredBranchId.isNotEmpty &&
          branch.id != model.masteredBranchId,
      canMaster: model.canMaster(branch),
    ));
  }
  return out;
}

/// Where the five stars of a constellation sit in its cell (0 to 1): up to
/// four skills and the crown last.
const List<List<Offset>> _starShapes = [
  [
    Offset(0.08, 0.85),
    Offset(0.28, 0.55),
    Offset(0.50, 0.72),
    Offset(0.70, 0.34),
    Offset(0.90, 0.10)
  ],
  [
    Offset(0.10, 0.28),
    Offset(0.30, 0.74),
    Offset(0.54, 0.52),
    Offset(0.74, 0.88),
    Offset(0.92, 0.36)
  ],
  [
    Offset(0.08, 0.62),
    Offset(0.28, 0.24),
    Offset(0.50, 0.46),
    Offset(0.70, 0.12),
    Offset(0.92, 0.30)
  ],
  [
    Offset(0.10, 0.80),
    Offset(0.34, 0.58),
    Offset(0.52, 0.86),
    Offset(0.72, 0.52),
    Offset(0.90, 0.18)
  ],
];

/// The cells of a sky [width] wide for [count] constellations: two across,
/// a last odd one alone on a row across both.
class StarSky {
  const StarSky(this.cells, this.cellHeight);

  final List<Rect> cells;
  final double cellHeight;

  double get height => cells.isEmpty ? 0 : cells.last.bottom;

  factory StarSky.of(int count, double width) {
    final cellH = width < 340 ? 150.0 : 176.0;
    final cellW = width / 2;
    final cells = <Rect>[
      for (var i = 0; i < count; i++)
        i == count - 1 && count.isOdd && count > 1
            ? Rect.fromLTWH(0, (i ~/ 2) * cellH, width, cellH)
            : Rect.fromLTWH((i % 2) * cellW, (i ~/ 2) * cellH, cellW, cellH),
    ];
    return StarSky(cells, cellH);
  }

  /// The place of star [k] (0 to 4, the crown last) of constellation [i].
  Offset starAt(int i, int k) {
    final cell = cells[i];
    final shape = _starShapes[i % _starShapes.length][k];
    // A wide cell stretches the shape; its stars stay in the same order.
    return Offset(cell.left + 14 + shape.dx * (cell.width - 28),
        cell.top + 10 + shape.dy * cellHeight * 0.60);
  }
}

/// The Tree tab's body for the class branches.
class StarChart extends ConsumerStatefulWidget {
  const StarChart({super.key, required this.model});

  final SkillsModel model;

  @override
  ConsumerState<StarChart> createState() => _StarChartState();
}

class _StarChartState extends ConsumerState<StarChart> {
  String? _focus;

  /// The constellation the card reads: the one picked, else the first whose
  /// clan can offer its next skill, else the first with a next skill.
  _StarBranch _focused(List<_StarBranch> branches) {
    for (final b in branches) {
      if (b.branch.id == _focus) return b;
    }
    return branches.firstWhere((b) => b.offerable,
        orElse: () => branches.firstWhere((b) => !b.complete,
            orElse: () => branches.first));
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(playerSessionProvider.select((s) => s.politics));
    final language = ref.watch(appLanguageProvider);
    final branches = _starBranchesOf(
        model: model, data: data, politics: politics, language: language);
    if (branches.isEmpty) return const SizedBox.shrink();
    final focus = _focused(branches);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, c) {
          final sky = StarSky.of(branches.length, c.maxWidth);
          return Container(
            key: const Key('star_sky'),
            height: sky.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF12152A), Color(0xFF232647)],
              ),
            ),
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkyPainter(
                    branches: branches,
                    sky: sky,
                    focusId: focus.branch.id,
                    gold: ink.gold,
                    model: model,
                  ),
                ),
              ),
              for (var i = 0; i < branches.length; i++) ...[
                _label(branches[i], sky, i, focus, theme),
                ..._hits(branches[i], sky, i),
              ],
            ]),
          );
        }),
        const SizedBox(height: 10),
        _FocusCard(model: model, star: focus),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(tr(ref, 'star_hint'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  /// A constellation's name, its count and its clan, under its stars.
  Widget _label(
      _StarBranch b, StarSky sky, int i, _StarBranch focus, ThemeData theme) {
    final cell = sky.cells[i];
    final on = b.branch.id == focus.branch.id;
    final clan = b.clanId == null
        ? Text(
            tr(ref, b.complete ? 'star_learned_label' : 'star_no_clan_label'),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: const Color(0xFF8E8AAE)))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            ClanFlag(factionId: b.clanId!, height: 11),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${b.clanName} · ${tr(ref, 'standing_tier_${b.tier!.name}')}',
                key: Key('star_clan_${b.branch.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFB9B3CC),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]);
    return Positioned(
      left: cell.left + 6,
      top: cell.top + sky.cellHeight * 0.66,
      width: cell.width - 12,
      child: InkWell(
        key: Key('star_name_${b.branch.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _focus = b.branch.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${b.branch.name} ${b.known}/${b.length}',
                  key: Key('branch_${b.branch.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: b.mastered
                          ? const Color(0xFFF2D58A)
                          : on
                              ? const Color(0xFFF2D58A)
                              : const Color(0xFFD9D4E8),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              clan,
            ],
          ),
        ),
      ),
    );
  }

  /// The tap targets of a constellation's stars, over the painted sky.
  List<Widget> _hits(_StarBranch b, StarSky sky, int i) {
    const hit = 40.0;
    Widget target(Offset at, Key key, String label, VoidCallback onTap) =>
        Positioned(
          left: at.dx - hit / 2,
          top: at.dy - hit / 2,
          width: hit,
          height: hit,
          child: Semantics(
            button: true,
            label: label,
            child: InkWell(
              key: key,
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox.expand(),
            ),
          ),
        );
    final model = widget.model;
    return [
      for (var k = 0; k < b.length && k < 4; k++)
        target(
          sky.starAt(i, k),
          Key('tree_node_${b.branch.skillIds[k]}'),
          _starLabel(b, k),
          () {
            setState(() => _focus = b.branch.id);
            showSkillSheet(context, b.branch.skillIds[k]);
          },
        ),
      target(
        sky.starAt(i, 4),
        Key('mastery_${b.branch.id}'),
        '${b.branch.name} · ${tr(ref, 'mastery_label')}',
        () => showMasterySheet(context, ref, b.branch),
      ),
      // `model` keeps the closure honest if the model changes under a tap.
      if (model.classBranches.isEmpty) const SizedBox.shrink(),
    ];
  }

  String _starLabel(_StarBranch b, int k) {
    final language = ref.read(appLanguageProvider);
    final id = b.branch.skillIds[k];
    final state = k < b.known
        ? tr(ref, 'star_state_known')
        : k == b.nextIndex
            ? tr(ref, b.offerable ? 'star_state_offered' : 'star_state_next')
            : tr(ref, 'star_state_later');
    return '${skillDisplayName(id, language: language)}, $state';
  }
}

class _FocusCard extends ConsumerWidget {
  const _FocusCard({required this.model, required this.star});

  final SkillsModel model;
  final _StarBranch star;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final language = ref.watch(appLanguageProvider);
    final next = star.nextId == null ? null : model[star.nextId!];
    final String line;
    if (star.complete) {
      line = tr(ref, 'star_learned_all');
    } else if (star.clanId == null) {
      line = tr(ref, 'star_no_clan');
    } else if (star.offerable) {
      line = tr(ref, 'star_offer_now').replaceAll('{clan}', star.clanName);
    } else {
      line = tr(ref, 'star_waits')
          .replaceAll(
              '{tier}',
              tr(ref,
                  'standing_tier_${starTierForIndex[star.nextIndex.clamp(0, 3)].name}'))
          .replaceAll('{clan}', star.clanName)
          .replaceAll('{now}', tr(ref, 'standing_tier_${star.tier!.name}'));
    }
    final effect = next == null
        ? ''
        : skillSummary(next.record, next.fightTier, (k) => tr(ref, k));
    final lit = star.offerable;
    final title = next == null
        ? star.branch.name
        : '${star.branch.name} · ${skillDisplayName(next.id, language: language)}';
    return InkWell(
      key: const Key('star_card'),
      borderRadius: BorderRadius.circular(12),
      onTap: next == null
          ? () => showMasterySheet(context, ref, star.branch)
          : () => showSkillSheet(context, next.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: lit ? ink.gold : ink.seam, width: lit ? 1.8 : 1),
        ),
        child: Row(children: [
          if (next != null) ...[
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                border: Border.all(
                    color: lit ? ink.gold : ink.seam, width: lit ? 2.5 : 1.8),
                boxShadow: lit
                    ? [
                        BoxShadow(
                            color: ink.gold.withValues(alpha: 0.3),
                            blurRadius: 10)
                      ]
                    : null,
              ),
              child: Opacity(
                  opacity: lit ? 1 : 0.55,
                  child: SkillPixelIcon(next.id, size: 26)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(line,
                  key: const Key('star_card_line'),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: lit ? ink.gold : ink.ash,
                      fontWeight: lit ? FontWeight.w600 : null)),
              if (effect.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(effect,
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ] else if (star.branch.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(star.branch.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.branches,
    required this.sky,
    required this.focusId,
    required this.gold,
    required this.model,
  });

  final List<_StarBranch> branches;
  final StarSky sky;
  final String focusId;
  final Color gold;
  final SkillsModel model;

  @override
  void paint(Canvas canvas, Size size) {
    // A fixed scatter of faint background stars.
    final rng = math.Random(7);
    final dust = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          rng.nextDouble() * 1.1 + 0.3,
          dust);
    }
    for (var i = 0; i < branches.length; i++) {
      final b = branches[i];
      final on = b.branch.id == focusId;
      final count = math.min(b.length, 4);
      // The lines between stars: gold between two learned ones, and on to the
      // crown once the branch is learned or mastered.
      for (var k = 0; k < count; k++) {
        final to = k + 1 < count ? k + 1 : 4;
        final lit = to < 4 ? to < b.known : b.mastered || b.known >= count;
        canvas.drawLine(
            sky.starAt(i, k),
            sky.starAt(i, to),
            Paint()
              ..color = lit
                  ? gold.withValues(alpha: 0.85)
                  : const Color(0xFF8E8AAE).withValues(alpha: on ? 0.55 : 0.3)
              ..strokeWidth = lit ? 2 : 1.2);
      }
      for (var k = 0; k < count; k++) {
        final p = sky.starAt(i, k);
        if (k < b.known) {
          _learned(canvas, p, 8);
        } else if (k == b.nextIndex && b.offerable) {
          canvas.drawCircle(
              p, 14, Paint()..color = gold.withValues(alpha: .25));
          canvas.drawCircle(
              p,
              7.5,
              Paint()
                ..color = gold
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.4);
          canvas.drawCircle(p, 3, Paint()..color = const Color(0xFFFFF3CC));
        } else if (k == b.nextIndex) {
          canvas.drawCircle(
              p,
              6.5,
              Paint()
                ..color = const Color(0xFFB9B3CC)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8);
        } else {
          canvas.drawCircle(p, 3.2,
              Paint()..color = const Color(0xFF8E8AAE).withValues(alpha: 0.7));
        }
      }
      // The crown: gold once mastered, ringed once it can be taken, dim
      // otherwise (and dimmer still when another branch is mastered).
      final crown = sky.starAt(i, 4);
      if (b.mastered) {
        _learned(canvas, crown, 10);
      } else if (b.canMaster) {
        canvas.drawCircle(
            crown, 15, Paint()..color = gold.withValues(alpha: .25));
        canvas.drawCircle(
            crown,
            8,
            Paint()
              ..color = gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4);
      } else {
        canvas.drawCircle(
            crown,
            4.5,
            Paint()
              ..color = const Color(0xFF8E8AAE)
                  .withValues(alpha: b.closed ? 0.35 : 0.7));
      }
    }
  }

  void _learned(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r + 4, Paint()..color = gold.withValues(alpha: 0.22));
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final rad = i.isEven ? r : r * 0.38;
      final p = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = gold);
    canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFFFFF3CC));
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.branches != branches || old.sky != sky || old.focusId != focusId;
}
