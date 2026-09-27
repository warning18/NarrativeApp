import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/turn_in_choices.dart';
import '../l10n/app_strings.dart';

/// Asks how the player settles [quest] (see turn_in_choices.dart): each
/// choice with the gold and alignment it brings. Returns the one picked,
/// or null when the player backs out (the quest stays open).
Future<TurnInChoice?> showTurnInChoiceDialog(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> quest,
  required List<TurnInChoice> choices,
}) {
  final questGold = (quest['rewardGold'] as num?)?.toInt() ?? 0;
  final questAlignment = (quest['alignmentChange'] as num?)?.toInt() ?? 0;
  String signed(int n) => n > 0 ? '+$n' : '$n';
  return showDialog<TurnInChoice>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(quest['questName']?.toString() ?? ''),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr(ref, 'turn_in_choice_title'),
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              for (final (i, choice) in choices.indexed) ...[
                OutlinedButton(
                  key: Key('turn_in_choice_$i'),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(choice),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(choice.text, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${choice.goldFor(questGold)} '
                              '${tr(ref, 'gold_label')}',
                          if (choice.alignmentFor(questAlignment) != 0)
                            '${tr(ref, 'alignment_label')} '
                                '${signed(choice.alignmentFor(questAlignment))}',
                        ].join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(ref, 'cancel')),
          ),
        ],
      );
    },
  );
}
