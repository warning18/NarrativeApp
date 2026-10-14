import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/politics_events.dart' show politicsHint;
import '../data/turn_in_choices.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/combat_settings_provider.dart'
    show politicsHintsEnabledProvider;

/// Asks how the player settles [quest] (see turn_in_choices.dart): each
/// choice with the gold and alignment it brings, and (v1.204) the muted
/// line of what it moves among the clans. Returns the one picked, or null
/// when the player backs out (the quest stays open).
Future<TurnInChoice?> showTurnInChoiceDialog(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> quest,
  required List<TurnInChoice> choices,
}) {
  final questGold = (quest['rewardGold'] as num?)?.toInt() ?? 0;
  final questAlignment = (quest['alignmentChange'] as num?)?.toInt() ?? 0;
  String signed(int n) => n > 0 ? '+$n' : '$n';
  final hintsOn = ref.read(politicsHintsEnabledProvider);
  final clanData = ref.read(clanDataProvider);
  final language = ref.read(appLanguageProvider);
  final politics = ref.read(politicsProvider);
  String hintOf(TurnInChoice choice) => !hintsOn || !choice.hasPolitics
      ? ''
      : politicsHint(choice.politics, clanData, language, politics: politics);
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
                      if (hintOf(choice).isNotEmpty)
                        Opacity(
                          opacity: 0.7,
                          child: Row(
                            children: [
                              const Icon(Icons.flag_outlined, size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  hintOf(choice),
                                  key: Key('turn_in_politics_hint_$i'),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
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
