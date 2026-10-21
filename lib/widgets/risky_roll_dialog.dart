// The die of a risky gift (wave 15, docs/proposals/risky-gifts.md): once the
// card is taken, the d20 that was rolled with the draw tumbles in front of
// the player and lands on its number, with the Luck bonus added, the edge
// turning gold for the gift or red for a price; then the result card tells
// what it cost. The die is the Skill Challenge's (d20_roll.dart).
import 'package:flutter/material.dart';

import '../data/risky_gifts.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import 'd20_roll.dart';

/// The odds of a risky card as a bar: the gift's share, then the price's,
/// each with its percentage. [luck] is the character's Luck (see
/// riskyOddsFor); the text line of the card says the same in words.
class RiskyOddsBar extends StatelessWidget {
  const RiskyOddsBar({super.key, required this.luck, this.height = 8});

  final int luck;
  final double height;

  @override
  Widget build(BuildContext context) {
    final odds = riskyOddsFor(luck);
    final ink = InkColors.of(context);
    return ClipRRect(
      key: const Key('risky_odds_bar'),
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
                flex: odds.gift,
                child: ColoredBox(color: ink.gold, child: const SizedBox())),
            Expanded(
                flex: odds.price,
                child: ColoredBox(
                    color: Theme.of(context).colorScheme.error,
                    child: const SizedBox())),
          ],
        ),
      ),
    );
  }
}

/// Rolls the die of a risky gift: [roll] (1 to 20, the one saved with the
/// card) lands, [luck] adds its bonus, and [won] says whether the gift or a
/// price came of it. Closes when the player goes on.
Future<void> showRiskyRoll(
  BuildContext context, {
  required int roll,
  required int luck,
  required bool won,
  required AppLanguage lang,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RiskyRollDialog(
        roll: roll,
        bonus: riskyLuckBonus(luck),
        won: won,
        lang: lang,
      ),
    );

class _RiskyRollDialog extends StatefulWidget {
  const _RiskyRollDialog({
    required this.roll,
    required this.bonus,
    required this.won,
    required this.lang,
  });

  final int roll;
  final int bonus;
  final bool won;
  final AppLanguage lang;

  @override
  State<_RiskyRollDialog> createState() => _RiskyRollDialogState();
}

class _RiskyRollDialogState extends State<_RiskyRollDialog> {
  bool _landed = false;

  bool get _reduced => WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  @override
  void initState() {
    super.initState();
    // With animations off the die is set down at once.
    _landed = _reduced;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = widget.lang;
    final colour = widget.won ? ink.gold : theme.colorScheme.error;
    return AlertDialog(
      key: const Key('risky_roll_dialog'),
      title: Text(trFor(lang, 'offer_risky_roll_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          D20Roll(
            key: const Key('risky_roll_die'),
            roll: widget.roll,
            success: widget.won,
            rolling: !_reduced,
            size: 130,
            onLanded: () {
              if (mounted) setState(() => _landed = true);
            },
          ),
          const SizedBox(height: 10),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _landed ? 1 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.bonus > 0
                      ? trFor(lang, 'offer_risky_roll_sum')
                          .replaceAll('{roll}', '${widget.roll}')
                          .replaceAll('{bonus}', '${widget.bonus}')
                          .replaceAll(
                              '{total}', '${widget.roll + widget.bonus}')
                      : '${widget.roll}',
                  key: const Key('risky_roll_sum'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  trFor(
                      lang,
                      widget.won
                          ? 'offer_risky_roll_gift'
                          : 'offer_risky_roll_price'),
                  key: const Key('risky_roll_verdict'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colour, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          key: const Key('risky_roll_continue'),
          onPressed: _landed ? () => Navigator.of(context).pop() : null,
          child: Text(trFor(lang, 'tut_next')),
        ),
      ],
    );
  }
}
