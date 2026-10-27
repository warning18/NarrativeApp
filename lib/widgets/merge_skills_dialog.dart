import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/skill_craft.dart';
import '../gamedata/db_schema.dart' show skillMergesSchema;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart' show localizedDbProvider;
import '../providers/player_session_provider.dart';
import '../screens/skills/dice_weave_card.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';

/// The Skillwright's bench: every skill_merges.json recipe as two skills
/// becoming a third, each drawn with its icon and its real name, the ones
/// the character knows and the ones still missing told apart. A recipe that
/// can be done wears a Merge button; one already done is marked. Both inputs
/// are lost for good, so Merge asks first, with the same picture.
Future<void> showMergeSkillsDialog(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> skills,
  required Map<String, dynamic> merges,
  required List<String> unlockedSkillIds,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _CraftSheet(merges: merges),
  );
}

class _CraftSheet extends ConsumerWidget {
  const _CraftSheet({required this.merges});

  final Map<String, dynamic> merges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final known = ref.watch(
        playerSessionProvider.select((s) => s.unlockedSkillIds.toList()));
    // The table may still be loading when the bench opens: wait for it.
    final live = ref.watch(localizedDbProvider(skillMergesSchema));
    final recipes = craftRecipesFor(
        merges: live.value ?? merges, unlockedSkillIds: known, language: lang);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(ref, 'craft_skill_button'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 2),
            Text(tr(ref, 'craft_sheet_intro'),
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            const SizedBox(height: 12),
            Flexible(
              child: recipes.isEmpty
                  ? Text(live.isLoading ? '' : tr(ref, 'no_merge_recipes'))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final recipe in recipes)
                          CraftRecipeCard(
                            key: Key('craft_${recipe.id}'),
                            recipe: recipe,
                            language: lang,
                            onMerge: () => _confirmAndMerge(context, ref,
                                recipe: recipe, language: lang),
                          ),
                        // Two d8s recut into the tally die (Core).
                        const DiceWeaveCard(),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(ref, 'close_button')),
            ),
          ],
        ),
      ),
    );
  }
}

/// One recipe: the two inputs, an arrow, the result, and what to do about
/// it. Known inputs wear a check; missing ones are greyed with their name.
class CraftRecipeCard extends StatelessWidget {
  const CraftRecipeCard({
    super.key,
    required this.recipe,
    required this.language,
    this.onMerge,
  });

  final CraftRecipe recipe;
  final AppLanguage language;
  final VoidCallback? onMerge;

  @override
  Widget build(BuildContext context) {
    String t(String key) => trFor(language, key);
    final ink = InkColors.of(context);
    final missingIds = {for (final s in recipe.missing) s.id};
    final color = recipe.crafted
        ? ink.heal
        : recipe.ready
            ? ink.gold
            : ink.seam;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: recipe.ready ? ink.gold.withValues(alpha: 0.07) : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: recipe.ready ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, skill) in recipe.inputs.indexed) ...[
                if (i > 0) _Sign('+', ink.ash),
                Expanded(
                  child: _SkillTile(
                    skill: skill,
                    state: recipe.crafted
                        ? _TileState.spent
                        : missingIds.contains(skill.id)
                            ? _TileState.missing
                            : _TileState.known,
                    knownTag: t('craft_known_tag'),
                    missingTag: t('craft_missing_tag'),
                  ),
                ),
              ],
              _Sign(null, recipe.ready ? ink.gold : ink.ash),
              Expanded(
                child: _SkillTile(
                  skill: recipe.result,
                  state: recipe.crafted ? _TileState.result : _TileState.future,
                  knownTag: t('already_crafted_label'),
                  missingTag: '',
                ),
              ),
            ],
          ),
          if (recipe.ready && onMerge != null) ...[
            const SizedBox(height: 10),
            FilledButton(
              key: Key('merge_${recipe.id}'),
              onPressed: onMerge,
              child: Text(t('merge_button')),
            ),
          ],
        ],
      ),
    );
  }
}

enum _TileState { known, missing, future, result, spent }

class _Sign extends StatelessWidget {
  const _Sign(this.text, this.color);

  /// null draws the arrow (the pixel face has no arrow glyph).
  final String? text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: SizedBox(
          width: 22,
          child: text == null
              ? Icon(Icons.arrow_forward, size: 20, color: color)
              : Text(text!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: InkFonts.system, fontSize: 20, color: color)),
        ),
      );
}

/// A skill's icon on a framed tile with its name under it and, in the
/// corner, whether the character has it.
class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.skill,
    required this.state,
    required this.knownTag,
    required this.missingTag,
  });

  final CraftSkill skill;
  final _TileState state;
  final String knownTag;
  final String missingTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final missing = state == _TileState.missing;
    final future = state == _TileState.future;
    final accent = switch (state) {
      _TileState.known => ink.heal,
      _TileState.result => ink.heal,
      _TileState.missing => ink.ember,
      _ => ink.ash,
    };
    final icon = SkillPixelIcon(skill.id, size: 44);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: Key('craft_tile_${skill.id}'),
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: accent.withValues(alpha: 0.10),
                border: Border.all(
                    color: accent.withValues(alpha: missing ? 0.6 : 0.9),
                    width: 1.5),
              ),
              child: missing || future
                  ? Opacity(opacity: missing ? 0.35 : 0.55, child: icon)
                  : icon,
            ),
            if (state == _TileState.known || state == _TileState.result)
              Positioned(
                right: -5,
                top: -5,
                child: Icon(Icons.check_circle, size: 18, color: ink.heal),
              ),
            if (missing)
              Positioned(
                right: -5,
                top: -5,
                child: Icon(Icons.lock_outline, size: 18, color: ink.ember),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(skill.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
                // A long word (Détermination) shrinks rather than breaks.
                fontSize: skill.name
                            .split(' ')
                            .fold(0, (m, w) => w.length > m ? w.length : m) >
                        11
                    ? 10
                    : 12,
                color: missing ? ink.ash : null,
                height: 1.15)),
        if (state == _TileState.missing && missingTag.isNotEmpty)
          Text(missingTag,
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ember)),
        if (state == _TileState.result)
          Text(knownTag,
              style: theme.textTheme.labelSmall?.copyWith(color: ink.heal)),
      ],
    );
  }
}

Future<void> _confirmAndMerge(
  BuildContext context,
  WidgetRef ref, {
  required CraftRecipe recipe,
  required AppLanguage language,
}) async {
  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmContext) => AlertDialog(
      title: Text(recipe.result.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(trFor(language, 'merge_confirm_message'),
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          CraftRecipeCard(recipe: recipe, language: language),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(confirmContext).pop(false),
          child: Text(trFor(language, 'cancel')),
        ),
        FilledButton(
          key: const Key('merge_confirm'),
          onPressed: () => Navigator.of(confirmContext).pop(true),
          child: Text(trFor(language, 'merge_button')),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(playerSessionProvider.notifier).mergeSkills(
    inputSkillIds: [for (final s in recipe.inputs) s.id],
    resultSkillId: recipe.result.id,
  );
}
