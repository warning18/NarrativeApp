// Three new ideas for the Skills tab, none of them a tree
// (docs/proposals/skills-ideas.md): a star chart, a hand and the clans' decks,
// and a paper doll. All three read the real skills model, the real standing
// with each clan and the real icons. Mock only; nothing here ships.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narrative_data_app/combat/dice_faces.dart'
    show skillDisplayName;
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_view_model.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'ux_skills_combined_parts.dart';
import 'ux_skills_mock_parts.dart';
import 'ux_skills_styles_parts.dart';

/// What the player needs to read about one branch, from the real model.
class _B {
  _B(this.branch, this.standing, this.model, this.data) {
    nextIndex = branch.skillIds.indexWhere((id) => model[id]?.known != true);
  }

  final SkillBranch branch;
  final ({String? clan, StandingTier tier, int cap}) standing;
  final SkillsModel model;
  final ClanData data;
  late final int nextIndex;

  int get known => model.knownOn(branch);
  int get length => branch.skillIds.length;
  bool get complete => nextIndex < 0;
  String? get nextId => complete ? null : branch.skillIds[nextIndex];

  /// The clan can offer the next skill now.
  bool get offerable => !complete && standing.cap >= nextIndex;

  String get clanName => standing.clan == null
      ? 'no clan'
      : data.faction(standing.clan!)?.shortFor(AppLanguage.en) ??
          standing.clan!;

  Color clanColour(Color fallback) {
    final f = standing.clan == null ? null : data.faction(standing.clan!);
    return f == null ? fallback : Color(f.color);
  }

  /// "The Compact can offer it now" or what it waits for.
  String get nextLine {
    if (complete) return 'Every skill of this branch is yours.';
    if (standing.clan == null) return 'No clan stands behind this branch.';
    if (offerable) return '$clanName can offer it now.';
    return 'Waits for "${standingNeeded[nextIndex].toLowerCase()}" with '
        '$clanName (you are ${standingWord(standing.tier).toLowerCase()}).';
  }
}

List<_B> _branches(WidgetRef ref, SkillsModel model) {
  final session = ref.watch(playerSessionProvider);
  final data = ref.watch(clanDataProvider);
  return [
    for (final b in model.classBranches)
      _B(b, standingOnBranch(model, b, session, data), model, data),
  ];
}

String _nameOf(String id) => skillDisplayName(id, language: AppLanguage.en);

/// A flag and the standing with it, one line.
Widget _clanLine(BuildContext context, _B b,
    {Color? colour, double flag = 12, int maxLines = 1}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  final style = theme.textTheme.labelSmall
      ?.copyWith(color: colour ?? ink.gold, fontWeight: FontWeight.w600);
  if (b.standing.clan == null) {
    return Text('no clan', style: style?.copyWith(color: ink.ash));
  }
  return Row(mainAxisSize: MainAxisSize.min, children: [
    ClanFlag(factionId: b.standing.clan!, height: flag),
    const SizedBox(width: 4),
    Flexible(
      child: Text('${b.clanName} · ${standingWord(b.standing.tier)}',
          maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style),
    ),
  ]);
}

// ---------------------------------------------------------------------------
// 1. The star chart: each branch a constellation.
// ---------------------------------------------------------------------------

/// Where the five stars of a constellation sit, in its cell (0 to 1): four
/// skills and the crown (Mastery).
const List<List<Offset>> _sky = [
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

class StarChart extends ConsumerWidget {
  const StarChart({super.key, required this.focus, required this.tabCounts});
  final int focus;
  final int tabCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final bs = _branches(ref, model);
      if (bs.isEmpty) return const SizedBox.shrink();
      final f = bs[focus.clamp(0, bs.length - 1)];
      final next = f.nextId == null ? null : model[f.nextId!];
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        tabsRow(context, tabCounts, false),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final cellW = w / 2;
            final cellH = w < 340 ? 150.0 : 176.0;
            return Container(
              height: cellH * 2,
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
                        branches: bs,
                        focus: focus,
                        cellW: cellW,
                        cellH: cellH,
                        gold: ink.gold),
                  ),
                ),
                for (var i = 0; i < bs.length; i++)
                  Positioned(
                    left: (i % 2) * cellW + 10,
                    top: (i ~/ 2) * cellH + cellH * 0.66,
                    width: cellW - 20,
                    child: _SkyLabel(branch: bs[i], on: i == focus),
                  ),
              ]),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: f.offerable ? ink.gold : ink.seam,
                  width: f.offerable ? 1.8 : 1),
            ),
            child: Row(children: [
              if (next != null) RingIcon(next, size: 46, lit: f.offerable),
              if (next != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          next == null
                              ? f.branch.name
                              : '${f.branch.name} · ${_nameOf(next.id)}',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(f.nextLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: f.offerable ? ink.gold : ink.ash,
                              fontWeight:
                                  f.offerable ? FontWeight.w600 : null)),
                      if (next != null) ...[
                        const SizedBox(height: 2),
                        Text(effectOf(next),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: ink.ash)),
                      ],
                    ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
              'Each branch is a constellation: a star for each skill, the crown for Mastery. A star lights when you learn the skill; the ringed one is the next, bright when its clan can offer it now. Tap a constellation to read its next star.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ]);
    });
  }
}

class _SkyLabel extends StatelessWidget {
  const _SkyLabel({required this.branch, required this.on});
  final _B branch;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${branch.branch.name} ${branch.known}/${branch.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: on ? const Color(0xFFF2D58A) : const Color(0xFFD9D4E8),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
              style: const TextStyle(color: Color(0xFFB9B3CC)),
              child: _clanLine(context, branch,
                  colour: const Color(0xFFB9B3CC), flag: 11)),
        ]);
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.branches,
    required this.focus,
    required this.cellW,
    required this.cellH,
    required this.gold,
  });

  final List<_B> branches;
  final int focus;
  final double cellW;
  final double cellH;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    // A fixed scatter of faint background stars.
    final rng = Random(7);
    final dust = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          rng.nextDouble() * 1.1 + 0.3,
          dust);
    }
    for (var i = 0; i < branches.length && i < _sky.length; i++) {
      final b = branches[i];
      final ox = (i % 2) * cellW;
      final oy = (i ~/ 2) * cellH;
      final h = cellH * 0.60;
      Offset at(int k) => Offset(
          ox + 14 + _sky[i][k].dx * (cellW - 28), oy + 10 + _sky[i][k].dy * h);
      final on = i == focus;
      // The lines between the stars: bright up to the last known one.
      for (var k = 0; k < 4; k++) {
        final lit = k + 1 < b.known;
        canvas.drawLine(
            at(k),
            at(k + 1),
            Paint()
              ..color = lit
                  ? gold.withValues(alpha: 0.85)
                  : const Color(0xFF8E8AAE).withValues(alpha: on ? 0.55 : 0.3)
              ..strokeWidth = lit ? 2 : 1.2);
      }
      for (var k = 0; k < 5; k++) {
        final p = at(k);
        final crown = k == 4;
        final known = crown ? b.complete : k < b.known;
        final next = !crown && k == b.nextIndex;
        if (known) {
          canvas.drawCircle(p, crown ? 15 : 12,
              Paint()..color = gold.withValues(alpha: 0.22));
          _sparkle(canvas, p, crown ? 10 : 8, gold);
        } else if (next && b.offerable) {
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
        } else if (next) {
          canvas.drawCircle(
              p,
              6.5,
              Paint()
                ..color = const Color(0xFFB9B3CC)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8);
        } else {
          canvas.drawCircle(p, crown ? 4.5 : 3.2,
              Paint()..color = const Color(0xFF8E8AAE).withValues(alpha: 0.7));
        }
      }
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final rad = i.isEven ? r : r * 0.38;
      final p = c + Offset(cos(a) * rad, sin(a) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour);
    canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFFFFF3CC));
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}

// ---------------------------------------------------------------------------
// 2. A hand, and the clans' decks.
// ---------------------------------------------------------------------------

class HandAndDecks extends ConsumerWidget {
  const HandAndDecks({super.key, required this.tabCounts});
  final int tabCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final bs = _branches(ref, model);
      final hand = <SkillEntry>[
        for (final b in bs)
          for (final id in b.branch.skillIds)
            if (model[id]?.known == true) model[id]!,
      ];
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        tabsRow(context, tabCounts, false),
        const SizedBox(height: 12),
        _Heading('Your hand · ${hand.length}'),
        const SizedBox(height: 6),
        SizedBox(
          height: 96,
          child: hand.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ink.seam),
                    ),
                    alignment: Alignment.center,
                    child: Text('Empty. The clans deal your first card.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: ink.ash, fontStyle: FontStyle.italic)),
                  ),
                )
              : LayoutBuilder(builder: (context, c) {
                  const cardW = 64.0;
                  final avail = c.maxWidth - 24;
                  final step = hand.length <= 1
                      ? 0.0
                      : min(cardW + 6, (avail - cardW) / (hand.length - 1));
                  final total = cardW + step * (hand.length - 1);
                  final start = (c.maxWidth - total) / 2;
                  return Stack(children: [
                    for (var i = 0; i < hand.length; i++)
                      Positioned(
                        left: start + i * step,
                        top: 8 + (i - (hand.length - 1) / 2).abs() * 2,
                        child: Transform.rotate(
                          angle: (i - (hand.length - 1) / 2) * 0.07,
                          child: _Card(entry: hand[i], width: cardW),
                        ),
                      ),
                  ]);
                }),
        ),
        const SizedBox(height: 12),
        const _Heading('The clans’ decks'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(builder: (context, c) {
            final four = c.maxWidth >= 380;
            final cols = four ? 4 : 2;
            const gap = 10.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(spacing: gap, runSpacing: 14, children: [
              for (final b in bs) SizedBox(width: w, child: _Deck(branch: b)),
            ]);
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Text(
              'Each clan keeps a deck: the skills it can still teach, one card turned up when it can deal it now, the rest face down with the standing they wait for. Your hand is what you know.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ]);
    });
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: InkColors.of(context).ash, letterSpacing: 1.2)),
      );
}

/// A face-up card: the icon over the name.
class _Card extends StatelessWidget {
  const _Card({required this.entry, required this.width, this.lit = false});
  final SkillEntry entry;
  final double width;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final h = width * 1.4;
    return Container(
      width: width,
      height: h,
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4E4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: entry.known || lit ? ink.gold : ink.seam,
            width: entry.known || lit ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: (lit ? ink.gold : Colors.black).withValues(alpha: 0.22),
              blurRadius: lit ? 10 : 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        SkillPixelIcon(entry.id, size: width * 0.5),
        const Spacer(),
        Text(_nameOf(entry.id),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF3A2E1E),
                height: 1.05,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// A deck: cards left, the top one up when its clan can deal it, else down.
class _Deck extends ConsumerWidget {
  const _Deck({required this.branch});
  final _B branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final b = branch;
    final left = b.length - b.known;
    final cardW = (MediaQuery.sizeOf(context).width < 340) ? 76.0 : 70.0;
    final cardH = cardW * 1.4;
    final colour = b.clanColour(ink.seam);
    final top = b.nextId == null ? null : b.model[b.nextId!];
    Widget back() => Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFBF4E4), width: 3),
          ),
        );
    return Column(children: [
      SizedBox(
        height: cardH + 14,
        width: cardW + 14,
        child: Stack(children: [
          if (left >= 3)
            Positioned(
                left: 0, top: 0, child: Opacity(opacity: .5, child: back())),
          if (left >= 2)
            Positioned(
                left: 7, top: 7, child: Opacity(opacity: .75, child: back())),
          Positioned(
            left: left >= 3 ? 14 : (left == 2 ? 7 : 0),
            top: left >= 3 ? 14 : (left == 2 ? 7 : 0),
            child: left == 0 || top == null
                ? Container(
                    width: cardW,
                    height: cardH,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ink.seam),
                    ),
                    child: Text('empty',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                  )
                : b.offerable
                    ? _Card(entry: top, width: cardW, lit: true)
                    : Stack(alignment: Alignment.center, children: [
                        back(),
                        if (b.standing.clan != null)
                          ClanFlag(factionId: b.standing.clan!, height: 30),
                        Positioned(
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xCC1E1B24),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.lock_outline,
                                  size: 10, color: Color(0xFFEDE6DC)),
                              const SizedBox(width: 2),
                              Text(
                                  b.standing.clan == null
                                      ? '—'
                                      : standingNeeded[b.nextIndex],
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFEDE6DC),
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ]),
          ),
          if (left > 0)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: ink.gold,
                child: Text('$left',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 4),
      Text(b.branch.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      _clanLine(context, b, flag: 11),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 3. The paper doll: the branches hang on the body.
// ---------------------------------------------------------------------------

/// Where each of the four branches hangs: its fraction of the doll's area,
/// the body part the string runs to (also fractions) and the slot's name.
const List<({Offset at, Offset part, String slot})> _slots = [
  (at: Offset(0.14, 0.40), part: Offset(0.37, 0.43), slot: 'Off hand'),
  (at: Offset(0.86, 0.40), part: Offset(0.63, 0.43), slot: 'Sword hand'),
  (at: Offset(0.14, 0.07), part: Offset(0.46, 0.12), slot: 'Head'),
  (at: Offset(0.86, 0.72), part: Offset(0.56, 0.80), slot: 'Feet'),
];

class PaperDoll extends ConsumerWidget {
  const PaperDoll({super.key, required this.tabCounts});
  final int tabCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final bs = _branches(ref, model);
      final ready = [
        for (final b in bs)
          if (b.offerable) b
      ];
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        tabsRow(context, tabCounts, false),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final h = w < 340 ? 470.0 : 440.0;
            final socket = w < 340 ? 46.0 : 54.0;
            final labelWidth = w < 340 ? 92.0 : 118.0;
            Offset px(Offset f) => Offset(f.dx * w, f.dy * h);
            return SizedBox(
              height: h,
              child: Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DollPainter(
                        slots: _slots,
                        line: ink.seam,
                        body: ink.ash.withValues(alpha: 0.35),
                        outline: ink.ash.withValues(alpha: 0.7)),
                  ),
                ),
                for (var i = 0; i < bs.length && i < _slots.length; i++)
                  Positioned(
                    left: px(_slots[i].at).dx - labelWidth / 2,
                    top: px(_slots[i].at).dy - socket / 2,
                    width: labelWidth,
                    child: _Socket(
                        branch: bs[i], slot: _slots[i].slot, size: socket),
                  ),
              ]),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: ready.isEmpty ? ink.seam : ink.gold,
                  width: ready.isEmpty ? 1 : 1.8),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ready.isEmpty ? 'Nothing to take yet' : 'Ready to be taught',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              if (ready.isEmpty)
                Text(
                    'Every next skill waits for a higher standing with its clan.',
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash))
              else
                for (final b in ready)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      SkillPixelIcon(b.nextId!, size: 22),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            '${_nameOf(b.nextId!)} · ${b.clanName} can offer it now',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall),
                      ),
                    ]),
                  ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
              'Each branch hangs on a part of the body: the socket shows the deepest skill you know there, and its beads the four steps. A socket glows when its clan can offer the next skill now.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ]);
    });
  }
}

class _Socket extends ConsumerWidget {
  const _Socket({
    required this.branch,
    required this.slot,
    required this.size,
  });
  final _B branch;
  final String slot;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final b = branch;
    // The deepest known skill, else the next one, dim.
    final deepest = b.known > 0 ? b.branch.skillIds[b.known - 1] : b.nextId;
    final entry = deepest == null ? null : b.model[deepest];
    final socket = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        border: Border.all(
            color: b.offerable
                ? ink.gold
                : b.known > 0
                    ? ink.gold.withValues(alpha: 0.8)
                    : ink.seam,
            width: b.offerable ? 3 : 2),
        boxShadow: b.offerable
            ? [
                BoxShadow(
                    color: ink.gold.withValues(alpha: 0.5), blurRadius: 14)
              ]
            : null,
      ),
      child: entry == null
          ? Icon(Icons.lock_outline, color: ink.ash, size: size * 0.4)
          : Opacity(
              opacity: b.known > 0 || b.offerable ? 1 : 0.4,
              child: SkillPixelIcon(entry.id, size: size * 0.6)),
    );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      socket,
      const SizedBox(height: 3),
      Text(slot.toUpperCase(),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: ink.ash, letterSpacing: 0.8, fontSize: 9)),
      Text(b.branch.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      _clanLine(context, b, flag: 11),
      Text(b.standing.clan == null ? '' : standingWord(b.standing.tier),
          style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
      const SizedBox(height: 2),
      Beads(model: b.model, branch: b.branch),
    ]);
  }
}

class _DollPainter extends CustomPainter {
  _DollPainter({
    required this.slots,
    required this.line,
    required this.body,
    required this.outline,
  });

  final List<({Offset at, Offset part, String slot})> slots;
  final Color line;
  final Color body;
  final Color outline;

  @override
  void paint(Canvas canvas, Size s) {
    Offset p(double x, double y) => Offset(x * s.width, y * s.height);
    final fill = Paint()..color = body;
    final edge = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // The strings from the sockets to the body.
    for (final slot in slots) {
      canvas.drawLine(
          p(slot.at.dx, slot.at.dy),
          p(slot.part.dx, slot.part.dy),
          Paint()
            ..color = line
            ..strokeWidth = 1.6);
    }
    final centre = s.width / 2;
    final shapes = <Rect>[
      // torso
      Rect.fromCenter(
          center: Offset(centre, s.height * 0.40),
          width: s.width * 0.20,
          height: s.height * 0.26),
    ];
    for (final r in shapes) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(14)), fill);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(14)), edge);
    }
    // head
    canvas.drawCircle(Offset(centre, s.height * 0.13), s.width * 0.06, fill);
    canvas.drawCircle(Offset(centre, s.height * 0.13), s.width * 0.06, edge);
    // arms and legs as thick rounded strokes
    final limb = Paint()
      ..color = body
      ..strokeWidth = s.width * 0.055
      ..strokeCap = StrokeCap.round;
    final limbEdge = Paint()
      ..color = outline
      ..strokeWidth = s.width * 0.055 + 3
      ..strokeCap = StrokeCap.round;
    void bone(Offset a, Offset b) {
      canvas.drawLine(a, b, limbEdge);
    }

    void boneFill(Offset a, Offset b) {
      canvas.drawLine(a, b, limb);
    }

    final bones = [
      (p(0.41, 0.31), p(0.32, 0.46)),
      (p(0.59, 0.31), p(0.68, 0.46)),
      (p(0.46, 0.52), p(0.44, 0.82)),
      (p(0.54, 0.52), p(0.56, 0.82)),
    ];
    for (final b in bones) {
      bone(b.$1, b.$2);
    }
    for (final b in bones) {
      boneFill(b.$1, b.$2);
    }
    // the sockets' anchors on the body
    for (final slot in slots) {
      canvas.drawCircle(
          p(slot.part.dx, slot.part.dy), 3.5, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_DollPainter old) => false;
}
