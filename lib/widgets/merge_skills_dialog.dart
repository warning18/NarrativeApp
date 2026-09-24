import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// Lists every skill_merges.json recipe and lets the player fuse two
/// unlocked skills into their result — the "combine skills" half of the
/// roguelike skill rework (upgrading tiers is the other half, on the skill
/// list itself). Recipes the player can't act on yet (missing an input, or
/// already crafted) show as locked rather than being hidden, so a build in
/// progress hints at what to chase.
Future<void> showMergeSkillsDialog(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> skills,
  required Map<String, dynamic> merges,
  required List<String> unlockedSkillIds,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(tr(ref, 'craft_skill_button')),
        content: SizedBox(
          width: double.maxFinite,
          child: merges.isEmpty
              ? Text(tr(ref, 'no_merge_recipes'))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: merges.entries.map((entry) {
                      final recipe = entry.value as Map<String, dynamic>;
                      final inputs = (recipe['inputSkillIDs'] as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          const <String>[];
                      final resultId =
                          recipe['resultSkillID']?.toString() ?? entry.key;
                      final alreadyCrafted =
                          unlockedSkillIds.contains(resultId);
                      final missing = inputs
                          .where((id) => !unlockedSkillIds.contains(id))
                          .toList();
                      final ready = !alreadyCrafted && missing.isEmpty;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            alreadyCrafted
                                ? Icons.check_circle
                                : (ready
                                    ? Icons.auto_fix_high
                                    : Icons.lock_outline),
                            color: alreadyCrafted ? Colors.green : null,
                          ),
                          title: Text('${inputs.join(' + ')} → $resultId'),
                          subtitle: Text(
                            alreadyCrafted
                                ? tr(ref, 'already_crafted_label')
                                : (ready
                                    ? tr(ref, 'merge_consumes_hint')
                                    : '${tr(ref, 'requires_label')} ${missing.join(', ')}'),
                          ),
                          trailing: ready
                              ? FilledButton(
                                  onPressed: () => _confirmAndMerge(
                                    dialogContext,
                                    ref,
                                    inputs: inputs,
                                    resultId: resultId,
                                  ),
                                  child: Text(tr(ref, 'merge_button')),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr(ref, 'close_button')),
          ),
        ],
      );
    },
  );
}

Future<void> _confirmAndMerge(
  BuildContext context,
  WidgetRef ref, {
  required List<String> inputs,
  required String resultId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmContext) => AlertDialog(
      title: Text(tr(ref, 'merge_button')),
      content: Text(
          '${tr(ref, 'merge_confirm_message')} ${inputs.join(' + ')} → $resultId'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(confirmContext).pop(false),
          child: Text(tr(ref, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(confirmContext).pop(true),
          child: Text(tr(ref, 'merge_button')),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(playerSessionProvider.notifier).mergeSkills(
        inputSkillIds: inputs,
        resultSkillId: resultId,
      );
  if (!context.mounted) return;
  Navigator.of(context).pop();
}
