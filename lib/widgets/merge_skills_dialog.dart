import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/skill_craft.dart';
import '../l10n/app_locale.dart';
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
                    children: [
                      for (final recipe in craftRecipesFor(
                        merges: merges,
                        unlockedSkillIds: unlockedSkillIds,
                        language: ref.read(appLanguageProvider),
                      ))
                        Card(
                          child: ListTile(
                            leading: Icon(
                              recipe.crafted
                                  ? Icons.check_circle
                                  : (recipe.ready
                                      ? Icons.auto_fix_high
                                      : Icons.lock_outline),
                              color: recipe.crafted ? Colors.green : null,
                            ),
                            title: Text(
                                '${recipe.inputs.map((s) => s.name).join(' + ')} → ${recipe.result.name}'),
                            subtitle: Text(
                              recipe.crafted
                                  ? tr(ref, 'already_crafted_label')
                                  : (recipe.ready
                                      ? tr(ref, 'merge_consumes_hint')
                                      : '${tr(ref, 'requires_label')} ${recipe.missing.map((s) => s.name).join(', ')}'),
                            ),
                            trailing: recipe.ready
                                ? FilledButton(
                                    onPressed: () => _confirmAndMerge(
                                      dialogContext,
                                      ref,
                                      recipe: recipe,
                                    ),
                                    child: Text(tr(ref, 'merge_button')),
                                  )
                                : null,
                          ),
                        ),
                    ],
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
  required CraftRecipe recipe,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmContext) => AlertDialog(
      title: Text(tr(ref, 'merge_button')),
      content: Text(
          '${tr(ref, 'merge_confirm_message')} ${recipe.inputs.map((s) => s.name).join(' + ')} → ${recipe.result.name}'),
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
    inputSkillIds: [for (final s in recipe.inputs) s.id],
    resultSkillId: recipe.result.id,
  );
  if (!context.mounted) return;
  Navigator.of(context).pop();
}
