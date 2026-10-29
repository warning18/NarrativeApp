// The forging moment (v1.593, docs/proposals/forge-mock.md, the approved
// four beats): the strike (the hammer comes down, sparks, the forge's own d20
// tumbles), it lands (the face, each modifier with its source, the total), the
// tier is read (its word in its colour, the sparks take it), and the piece
// before and after with what was spent. About four seconds; a tap goes to the
// last beat; with reduced motion only the last beat shows, the roll written
// out. The rule is Core's (forge_roll.dart): this only shows a roll that was
// already made.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/forge_roll.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'd20_roll.dart';

/// The colour of a forge tier (the odds bar, the sparks, the word).
Color forgeTierColor(ForgeTier tier) => switch (tier) {
      ForgeTier.flawed => const Color(0xFFD9625A),
      ForgeTier.sound => const Color(0xFF9A93A6),
      ForgeTier.fine => const Color(0xFF5CCB9A),
      ForgeTier.masterwork => const Color(0xFFF2C14E),
    };

const Map<ForgeTier, String> _bandLabels = {
  ForgeTier.flawed: '1–4',
  ForgeTier.sound: '5–14',
  ForgeTier.fine: '15–19',
  ForgeTier.masterwork: '20+',
};

/// The four tiers as one bar: their odds ([ranges] false) or the totals
/// they cover, [landed] the one the roll fell in.
class ForgeTierBar extends StatelessWidget {
  const ForgeTierBar(
      {super.key, required this.odds, this.landed, this.ranges = false});

  final Map<ForgeTier, double> odds;

  /// Label each band with the d20 total it covers ("15–19") instead of its
  /// odds.
  final bool ranges;

  /// The tier the roll landed in, drawn brighter with a marker under it.
  final ForgeTier? landed;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return Column(children: [
      Row(children: [
        for (final tier in ForgeTier.values)
          if ((odds[tier] ?? 0) > 0)
            Expanded(
              flex: ((odds[tier] ?? 0) * 100).round(),
              child: Container(
                key: ValueKey('forge_bar_${tier.name}'),
                height: 8,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: forgeTierColor(tier).withValues(
                      alpha: landed == null || landed == tier ? 1 : 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
      ]),
      const SizedBox(height: 3),
      Row(children: [
        for (final tier in ForgeTier.values)
          if ((odds[tier] ?? 0) > 0)
            Expanded(
              flex: ((odds[tier] ?? 0) * 100).round(),
              child: Text(
                ranges
                    ? _bandLabels[tier]!
                    : '${((odds[tier] ?? 0) * 100).round()}%',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 11,
                    color: landed == tier ? forgeTierColor(tier) : ink.ash),
              ),
            ),
      ]),
    ]);
  }
}

/// Shows the moment of [roll] having forged [itemId] ([base] the item as
/// listed), [spent] what it took, [coinLine] what a fate coin said, if any.
/// Resolves true when the player asked to forge another.
Future<bool> showForgeMoment(
  BuildContext context, {
  required ForgeRoll roll,
  required String itemId,
  required Map<String, dynamic> base,
  required String pieceName,
  required String spent,
  String coinLine = '',
  bool canForgeAnother = true,
}) async {
  final again = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF121016),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, __, ___) => ForgeMoment(
      roll: roll,
      itemId: itemId,
      base: base,
      pieceName: pieceName,
      spent: spent,
      coinLine: coinLine,
      canForgeAnother: canForgeAnother,
    ),
  );
  return again ?? false;
}

/// The seconds each beat starts at.
const List<double> forgeBeatStarts = [0, 1.15, 2.7, 4.2];

class ForgeMoment extends ConsumerStatefulWidget {
  const ForgeMoment({
    super.key,
    required this.roll,
    required this.itemId,
    required this.base,
    required this.pieceName,
    required this.spent,
    this.coinLine = '',
    this.canForgeAnother = true,
  });

  final ForgeRoll roll;
  final String itemId;
  final Map<String, dynamic> base;

  /// The piece's name with its tier prefix ("Fine Iron-Shod Boots").
  final String pieceName;
  final String spent;
  final String coinLine;
  final bool canForgeAnother;

  @override
  ConsumerState<ForgeMoment> createState() => _ForgeMomentState();
}

class _ForgeMomentState extends ConsumerState<ForgeMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (forgeBeatStarts.last * 1000).round()))
    ..addListener(() => setState(() {}));
  bool _started = false;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _still = MediaQuery.of(context).disableAnimations;
    if (_still) {
      _clock.value = 1;
    } else {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  double get _t => _clock.value * forgeBeatStarts.last;

  int get _beat {
    var b = 0;
    for (var i = 0; i < forgeBeatStarts.length; i++) {
      if (_t >= forgeBeatStarts[i]) b = i;
    }
    return b;
  }

  void _skip() {
    if (_beat < 3) _clock.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final beat = _beat;
    final roll = widget.roll;
    final tierColor = forgeTierColor(roll.tier);
    return Material(
      color: const Color(0xFF121016),
      child: SafeArea(
        child: GestureDetector(
          key: const Key('forge_moment'),
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(children: [
              if (beat < 3)
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _AnvilPainter(
                      t: _t,
                      tier: roll.tier,
                      seed: roll.face,
                      tierColor: tierColor,
                      tierAt: forgeBeatStarts[2],
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (beat) {
                    0 || 1 => _landing(context, lang, beat),
                    2 => _tierRead(context, lang, tierColor),
                    _ => _piece(context, lang, tierColor),
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _modifierRow(BuildContext context, String label, int value,
      {required double appear, bool plain = false}) {
    final ink = InkColors.of(context);
    final colour = value >= 0 ? ink.heal : ink.blood;
    return Opacity(
      opacity: appear.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset((1 - appear.clamp(0.0, 1.0)) * 18, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70, fontFamily: InkFonts.prose))),
            Text(plain ? '$value' : (value >= 0 ? '+$value' : '$value'),
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 16,
                    color: plain ? ink.gold : colour)),
          ]),
        ),
      ),
    );
  }

  // Beats 1 and 2: the die is cast, then lands and the modifiers add up.
  Widget _landing(BuildContext context, AppLanguage lang, int beat) {
    final roll = widget.roll;
    final clans = ref.watch(clanDataProvider);
    final theme = Theme.of(context);
    final landed = beat >= 1;
    final modStart = forgeBeatStarts[1] + 0.1;
    double appear(int i) => (_t - modStart - i * 0.3) / 0.3;
    return Column(
      key: const ValueKey('forge_beat_landing'),
      children: [
        D20Roll(
          key: const ValueKey('forge_d20'),
          roll: roll.face,
          rolling: !_still,
          size: 150,
        ),
        const SizedBox(height: 10),
        if (!landed)
          Text(trFor(lang, 'forge_cast'),
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                  fontFamily: InkFonts.prose)),
        if (landed) ...[
          _modifierRow(context, trFor(lang, 'forge_die'), roll.face,
              appear: appear(-1), plain: true),
          for (final (i, m) in roll.modifiers.indexed)
            _modifierRow(context, m.labelFor(lang, clans: clans), m.value,
                appear: appear(i)),
          const Divider(color: Colors.white24, height: 16),
          _modifierRow(context, trFor(lang, 'forge_total'), roll.total,
              appear: appear(roll.modifiers.length), plain: true),
          const SizedBox(height: 6),
          Opacity(
            opacity: appear(roll.modifiers.length + 1).clamp(0.0, 1.0),
            child: ForgeTierBar(
                odds: _bandsFor(), landed: roll.tier, ranges: true),
          ),
        ],
      ],
    );
  }

  /// The four bands of the d20 total as widths (1–4, 5–14, 15–19, 20+):
  /// the rule's thresholds, not the odds.
  Map<ForgeTier, double> _bandsFor() => const {
        ForgeTier.flawed: 0.2,
        ForgeTier.sound: 0.5,
        ForgeTier.fine: 0.25,
        ForgeTier.masterwork: 0.05,
      };

  // Beat 3: the tier is read.
  Widget _tierRead(BuildContext context, AppLanguage lang, Color colour) {
    final roll = widget.roll;
    final theme = Theme.of(context);
    final grow = ((_t - forgeBeatStarts[2]) / 0.5).clamp(0.0, 1.0);
    return Column(
      key: const ValueKey('forge_beat_tier'),
      children: [
        const SizedBox(height: 8),
        Transform.scale(
          scale: 0.8 + 0.2 * grow,
          child: Text(
            trFor(lang, forgeTierLabelKey(roll.tier)).toUpperCase(),
            key: const Key('forge_tier_word'),
            style: TextStyle(
              fontFamily: InkFonts.display,
              fontSize: 44,
              color: colour,
              shadows: [
                Shadow(color: colour.withValues(alpha: 0.6), blurRadius: 14)
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(trFor(lang, 'forge_effect_${roll.tier.name}'),
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.white70, fontFamily: InkFonts.prose)),
        const SizedBox(height: 14),
        ForgeTierBar(odds: _bandsFor(), landed: roll.tier, ranges: true),
        const SizedBox(height: 18),
        if (roll.tier == ForgeTier.flawed)
          Text(trFor(lang, 'forge_flaw_note'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                  fontFamily: InkFonts.prose)),
        if (widget.coinLine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(widget.coinLine.trim(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70, fontFamily: InkFonts.prose)),
          ),
      ],
    );
  }

  String _rollWritten(AppLanguage lang, ForgeRoll roll) {
    final mods = [
      for (final m in roll.modifiers)
        ' ${m.value >= 0 ? '+' : '−'} ${m.value.abs()}',
    ].join();
    return '${roll.face}$mods = ${roll.total}, '
        '${trFor(lang, forgeTierLabelKey(roll.tier))}';
  }

  // Beat 4: the piece, before and after.
  Widget _piece(BuildContext context, AppLanguage lang, Color colour) {
    final roll = widget.roll;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final change = forgedPieceBeforeAfter(widget.base, roll.tier);
    final statLabel = trFor(
        lang, change.stat == 'attackDamage' ? 'atk_abbrev' : 'arm_abbrev');
    final delta = change.after - change.before;
    final sellDelta = change.resaleBefore == 0
        ? 0
        : ((change.resaleAfter / change.resaleBefore - 1) * 100).round();
    Widget row(String label, String from, String to, String note,
        {Color? noteColour}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70, fontFamily: InkFonts.prose))),
          Text(from,
              style: const TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 15,
                  color: Colors.white54)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child:
                  Icon(Icons.arrow_right_alt, size: 18, color: Colors.white54)),
          Text(to,
              style: TextStyle(
                  fontFamily: InkFonts.system, fontSize: 17, color: colour)),
          const SizedBox(width: 8),
          Text(note,
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 12,
                  color: noteColour ?? ink.ash)),
        ]),
      );
    }

    return Column(
      key: const ValueKey('forge_beat_piece'),
      children: [
        if (_still)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_rollWritten(lang, roll),
                key: const Key('forge_roll_written'),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colour, fontFamily: InkFonts.system)),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1A21),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colour, width: 1.6),
          ),
          child: Column(children: [
            Row(children: [
              ItemPixelIcon(widget.itemId, widget.base['itemType']?.toString(),
                  size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.pieceName,
                    key: const Key('forge_piece_name'),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontFamily: InkFonts.prose)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    border: Border.all(color: colour),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(trFor(lang, forgeTierLabelKey(roll.tier)),
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 13,
                        color: colour)),
              ),
            ]),
            const SizedBox(height: 8),
            row(statLabel, '${change.before}', '${change.after}',
                delta == 0 ? '' : (delta > 0 ? '+$delta' : '$delta'),
                noteColour: delta >= 0 ? ink.heal : ink.blood),
            row(
                trFor(lang, 'forge_sells_for'),
                '${change.resaleBefore}',
                '${change.resaleAfter}',
                sellDelta == 0 ? '' : '${sellDelta > 0 ? '+' : ''}$sellDelta%'),
          ]),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
              trFor(lang, 'forge_spent').replaceAll('{list}', widget.spent),
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54, fontFamily: InkFonts.prose)),
        ),
        const Spacer(),
        FilledButton(
          key: const Key('forge_take_it'),
          onPressed: () => Navigator.of(context).pop(false),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(trFor(lang, 'forge_take_it')),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('forge_another'),
          onPressed: widget.canForgeAnother
              ? () => Navigator.of(context).pop(true)
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white30,
            side: const BorderSide(color: Colors.white38),
          ),
          child: Text(trFor(lang, 'forge_another')),
        ),
      ],
    );
  }
}

/// The anvil, the hammer that comes down once, and the sparks: orange for
/// the strike, the tier's colour (and size) when the tier is read.
class _AnvilPainter extends CustomPainter {
  _AnvilPainter({
    required this.t,
    required this.tier,
    required this.seed,
    required this.tierColor,
    required this.tierAt,
  });

  final double t;
  final ForgeTier tier;
  final int seed;
  final Color tierColor;
  final double tierAt;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final base = size.height - 14;
    final stone = Paint()..color = const Color(0xFF45414F);
    // The anvil: a foot, a waist, a face.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, base - 4), width: 150, height: 14),
            const Radius.circular(3)),
        stone);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, base - 22), width: 54, height: 24),
        Paint()..color = const Color(0xFF38343F));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, base - 42), width: 190, height: 16),
            const Radius.circular(3)),
        stone);
    // The glowing bar on it.
    final hot = Color.lerp(const Color(0xFFFF9A3D), tierColor,
        ((t - tierAt) / 0.4).clamp(0.0, 1.0))!;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx - 6, base - 54), width: 80, height: 9),
            const Radius.circular(4)),
        Paint()..color = hot);
    // The hammer: raised, down at 0.35 s, then lifting away.
    final fall = Curves.easeIn.transform((t / 0.35).clamp(0.0, 1.0));
    final lift = Curves.easeOut.transform(((t - 0.45) / 0.5).clamp(0.0, 1.0));
    final angle = -1.0 + 1.0 * fall - 0.7 * lift;
    canvas.save();
    canvas.translate(cx + 46, base - 56);
    canvas.rotate(angle);
    canvas.drawRect(const Rect.fromLTWH(0, -6, 74, 6),
        Paint()..color = const Color(0xFF7A5A3A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(62, -17, 22, 22), const Radius.circular(3)),
        Paint()..color = const Color(0xFF5E5A68));
    canvas.restore();
    // The sparks.
    void burst(double since, Color colour, double reach, int count) {
      final s = ((t - since) / 0.9).clamp(0.0, 1.0);
      if (s <= 0 || s >= 1) return;
      final rng = math.Random(seed * 31 + count);
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2
        ..color = colour.withValues(alpha: 1 - s);
      for (var i = 0; i < count; i++) {
        final a = -math.pi * (0.1 + 0.8 * rng.nextDouble());
        final r0 = reach * 0.25 * s;
        final r1 = reach *
            (0.4 + 0.6 * rng.nextDouble()) *
            Curves.easeOut.transform(s);
        final o = Offset(cx - 6, base - 58);
        canvas.drawLine(o + Offset(math.cos(a), math.sin(a)) * r0,
            o + Offset(math.cos(a), math.sin(a)) * r1, paint);
      }
    }

    burst(0.33, const Color(0xFFFF9A3D), 80, 14);
    final (reach, count) = switch (tier) {
      ForgeTier.flawed => (40.0, 8),
      ForgeTier.sound => (70.0, 14),
      ForgeTier.fine => (105.0, 28),
      ForgeTier.masterwork => (135.0, 44),
    };
    burst(tierAt, tierColor, reach, count);
  }

  @override
  bool shouldRepaint(_AnvilPainter old) => old.t != t;
}
