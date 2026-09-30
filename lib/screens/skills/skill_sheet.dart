// One sheet per skill, wherever it is tapped (the tree, My skills, a
// companion's list): what it does and by tier, the die faces it sits on,
// and the one button that matters -- Learn, or Raise tier, with the reason
// when it is greyed. Compare and Craft hang off it for a known skill.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/combat_engine.dart';
import '../../combat/dice_faces.dart';
import '../../data/skill_tree.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../models/ally_state.dart';
import '../../providers/game_db_providers.dart';
import '../../providers/player_session_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/face_style.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/compare_dialog.dart';
import '../../widgets/immersive_notice.dart';
import '../../widgets/merge_skills_dialog.dart';
import '../../widgets/moments.dart';
import '../dice_loadout_screen.dart';
import 'skills_view_model.dart';

/// The skills of the player ([allyId] null) or a companion, from the live
/// session and tables; null while the skills table loads.
SkillsModel? watchSkillsModel(WidgetRef ref, String? allyId) {
  final skills = ref.watch(localizedDbProvider(skillsSchema)).value;
  if (skills == null) return null;
  final session = ref.watch(playerSessionProvider);
  if (allyId == null) {
    return SkillsModel.forPlayer(
      session: session,
      skills: skills,
      trees: ref.watch(localizedDbProvider(skillTreesSchema)).value ?? const {},
    );
  }
  final companions =
      ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
  final companion = companions[allyId] as Map<String, dynamic>?;
  final ally = session.recruitedAllies.firstWhere(
    (a) => a.companionId == allyId,
    orElse: () => AllyState(companionId: allyId, currentHealth: 0),
  );
  return SkillsModel.forAlly(
    skillPoints: ally.skillPoints,
    unlockedSkillIds: ally.unlockedSkillIds,
    professionId: companion?['professionId']?.toString() ?? '',
    skills: skills,
  );
}

/// "1 pt" / "3 pts".
String costLabel(WidgetRef ref, int points) => points == 1
    ? tr(ref, 'cost_pt_one')
    : tr(ref, 'cost_pt_many').replaceAll('{n}', '$points');

/// Learns [id] with points (the player's own tree cost, or one of a
/// companion's), with sparks and a notice.
Future<void> learnSkill(BuildContext context, WidgetRef ref, String id,
    {String? allyId, required int cost}) async {
  final notifier = ref.read(playerSessionProvider.notifier);
  if (allyId != null) {
    await notifier.unlockAllySkill(allyId, id);
  } else {
    await notifier.unlockSkill(id, cost: cost);
  }
  if (!context.mounted) return;
  final lang = ref.read(appLanguageProvider);
  showBurst(context,
      at: MediaQuery.sizeOf(context).center(Offset.zero),
      colour: InkColors.of(context).ember,
      count: 18);
  showImmersiveNotice(
    context,
    icon: Icons.auto_awesome,
    message: '${trFor(lang, 'unlocked_prefix')}: '
        '${skillDisplayName(id, language: lang)}',
  );
}

/// Opens the sheet for [skillId].
Future<void> showSkillSheet(BuildContext context, String skillId,
    {String? allyId}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        _SkillSheet(skillId: skillId, allyId: allyId, host: context),
  );
}

class _SkillSheet extends ConsumerWidget {
  const _SkillSheet({required this.skillId, this.allyId, required this.host});

  final String skillId;
  final String? allyId;

  /// The screen under the sheet: what learning speaks through once the
  /// sheet is closed.
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = watchSkillsModel(ref, allyId);
    final entry = model?[skillId];
    if (model == null || entry == null) return const SizedBox(height: 120);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final skill = entry.record;
    final kind = entry.kind;
    final rarity = skillRarity(skill);
    final branch = entry.branch;

    final where = [
      if (branch != null)
        tr(ref, 'skill_step_of')
            .replaceAll('{branch}', branch.name)
            .replaceAll('{i}', '${entry.index + 1}')
            .replaceAll('{n}', '${branch.skillIds.length}'),
      if (entry.known) tr(ref, 'known_label'),
    ].join(' · ');

    Widget chip(String label, Color colour, {IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: colour),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: colour),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(color: colour)),
            ),
          ]),
        );

    final table = model.isPlayer
        ? tierTable(skill)
        : const <({String key, List<String> values})>[];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SkillPixelIcon(skillId, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skillDisplayName(skillId, language: lang),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontFamily: InkFonts.display)),
                      if (where.isNotEmpty)
                        Text(where,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: ink.ash)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              chip(tr(ref, kind.labelKey), kind.color, icon: kind.icon),
              chip(
                  tr(ref, 'skill_max_faces')
                      .replaceAll('{rarity}', tr(ref, rarity.labelKey))
                      .replaceAll('{max}', '${maxFacesForSkill(skill)}'),
                  rarity.color),
            ]),
            const SizedBox(height: 10),
            Text(skill['description']?.toString() ?? '',
                style: theme.textTheme.bodyLarge),
            if (table.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(tr(ref, 'skill_by_tier').toUpperCase(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.ash, letterSpacing: 1)),
              const SizedBox(height: 6),
              _TierTable(
                rows: table,
                current: entry.known && entry.tierable ? entry.tier : null,
              ),
            ],
            if (entry.fightTier > entry.tier && entry.known) ...[
              const SizedBox(height: 6),
              Text(
                  tr(ref, 'fights_at_tier')
                      .replaceAll('{n}', '${entry.fightTier}'),
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
            ],
            if (model.isPlayer && entry.known) ...[
              const SizedBox(height: 12),
              _DiceLine(skillId: skillId),
            ],
            const SizedBox(height: 16),
            _Action(entry: entry, model: model, allyId: allyId, host: host),
            if (model.isPlayer && entry.known) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    key: const Key('skill_compare'),
                    onPressed: () => _compare(context, ref, model, entry),
                    child: Text(tr(ref, 'compare_with')),
                  ),
                  TextButton(
                    key: const Key('skill_craft'),
                    onPressed: () => openCraft(context, ref),
                    child: Text(tr(ref, 'craft_link')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _compare(BuildContext context, WidgetRef ref, SkillsModel model,
      SkillEntry entry) async {
    final lang = ref.read(appLanguageProvider);
    final others = [
      for (final id in model.knownIds)
        if (id != entry.id) id
    ];
    final otherId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(trFor(lang, 'compare_pick_title')),
        children: [
          for (final id in others)
            SimpleDialogOption(
              key: Key('compare_pick_$id'),
              onPressed: () => Navigator.of(dialogContext).pop(id),
              child: Row(children: [
                SkillPixelIcon(id, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(skillDisplayName(id, language: lang))),
              ]),
            ),
        ],
      ),
    );
    if (otherId == null || !context.mounted) return;
    final a = applySkillTier(entry.record, entry.fightTier);
    final otherEntry = model[otherId]!;
    final b = applySkillTier(otherEntry.record, otherEntry.fightTier);
    num v(Map<String, dynamic> s, String k, num fallback) =>
        (s[k] as num?) ?? fallback;
    await showCompareDialog(
      context,
      titleA: skillDisplayName(entry.id, language: lang),
      titleB: skillDisplayName(otherId, language: lang),
      closeLabel: trFor(lang, 'close_button'),
      rows: [
        for (final (key, field, fallback) in [
          ('damage_mod_label', 'damageMod', 0),
          ('damage_multiplier_label', 'damageMultiplier', 1),
          ('heal_amount', 'healAmount', 0),
        ])
          CompareRow(
            label: trFor(lang, key),
            valueA: v(a, field, fallback),
            valueB: v(b, field, fallback),
          ),
      ],
    );
  }
}

/// Opens the crafting (merge) dialog for the player's known skills.
void openCraft(BuildContext context, WidgetRef ref) {
  showMergeSkillsDialog(
    context,
    ref,
    skills: ref.read(localizedDbProvider(skillsSchema)).value ?? const {},
    merges: ref.read(localizedDbProvider(skillMergesSchema)).value ?? const {},
    unlockedSkillIds: ref.read(playerSessionProvider).unlockedSkillIds,
  );
}

/// The skill's numbers at base and each tier; [current] is highlighted.
class _TierTable extends StatelessWidget {
  const _TierTable({required this.rows, this.current});

  final List<({String key, List<String> values})> rows;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Consumer(builder: (context, ref, _) {
      Widget cell(String text, int column, {bool header = false}) {
        final here = current == column;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: here ? ink.gold.withValues(alpha: 0.14) : null,
              border: Border.all(color: here ? ink.gold : ink.seam),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: (header
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelLarge)
                  ?.copyWith(
                      color: header || (current != null && column > current!)
                          ? ink.ash
                          : null),
            ),
          ),
        );
      }

      return Column(children: [
        Row(children: [
          const SizedBox(width: 84),
          for (var t = 0; t <= maxSkillTier; t++)
            cell(t == 0 ? tr(ref, 'tier_base') : '${tr(ref, 'tier_label')} $t',
                t,
                header: true),
        ]),
        for (final row in rows)
          Row(children: [
            SizedBox(
              width: 84,
              child: Text(tr(ref, row.key),
                  maxLines: 2,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ),
            for (var t = 0; t < row.values.length; t++) cell(row.values[t], t),
          ]),
      ]);
    });
  }
}

/// Which faces of the equipped die the skill sits on, and the way to the
/// dice.
class _DiceLine extends ConsumerWidget {
  const _DiceLine({required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final dice = ref.watch(localizedDbProvider(diceSchema)).value ?? const {};
    final lang = ref.watch(appLanguageProvider);
    final dieId = session.equippedDiceId;
    final die = dieId == null ? null : dice[dieId] as Map<String, dynamic>?;
    final faces =
        (die?['faces'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final assigned = session.diceSkillAssignments[dieId] ?? const {};
    var count = 0;
    for (var i = 0; i < faces.length; i++) {
      if (faceSkillId(faces[i], assigned['$i']) == skillId) count++;
    }
    final dieName = dieId == null ? '' : dieDisplayName(dieId, language: lang);
    final text = count == 0 || dieId == null
        ? tr(ref, 'skill_not_on_die')
        : (count == 1
                ? tr(ref, 'skill_on_die_one')
                : tr(ref, 'skill_on_die_many').replaceAll('{n}', '$count'))
            .replaceAll('{die}', dieName);
    return InkWell(
      key: const Key('skill_dice_link'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const DiceLoadoutScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: ink.seam),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.casino_outlined, size: 18, color: ink.tide),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          Text('${tr(ref, 'skill_dice_link')} ›',
              style: theme.textTheme.labelMedium?.copyWith(color: ink.tide)),
        ]),
      ),
    );
  }
}

/// The sheet's one button, or why there is none.
class _Action extends ConsumerWidget {
  const _Action(
      {required this.entry,
      required this.model,
      this.allyId,
      required this.host});

  final SkillEntry entry;
  final SkillsModel model;
  final String? allyId;
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    Text note(String text) => Text(text,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(color: ink.ash));

    switch (entry.status) {
      case SkillStatus.known:
        if (!model.isPlayer) return note(tr(ref, 'known_label'));
        if (!entry.tierable) return note(tr(ref, 'skill_no_tiers_note'));
        if (entry.maxed) return note(tr(ref, 'tier_max_label'));
        final cost = entry.upgradeCost!;
        final short = cost - model.essence;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('skill_raise'),
              style: FilledButton.styleFrom(backgroundColor: ink.voidColor),
              onPressed: short > 0
                  ? null
                  : () => ref
                      .read(playerSessionProvider.notifier)
                      .upgradeSkillTier(entry.id),
              icon: const Icon(Icons.arrow_upward),
              label: Text(tr(ref, 'raise_tier_button')
                  .replaceAll('{n}', '${entry.tier + 1}')
                  .replaceAll('{cost}', '$cost')),
            ),
            if (short > 0) ...[
              const SizedBox(height: 4),
              Text(
                tr(ref, 'raise_tier_short').replaceAll('{n}', '$short'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
              ),
            ],
          ],
        );
      case SkillStatus.locked:
        final after = entry.after;
        if (after != null) {
          return note(tr(ref, 'skill_after_label')
              .replaceAll('{skill}', skillDisplayName(after, language: lang)));
        }
        final min = entry.record['requiredAlignmentMin'];
        return note('${tr(ref, 'reserved_prefix')}: '
            '${min != null ? tr(ref, 'good_aligned_label') : tr(ref, 'evil_aligned_label')}');
      case SkillStatus.ready:
        final points = entry.cost;
        final have = model.skillPoints;
        return FilledButton.icon(
          key: const Key('tree_learn'),
          onPressed: entry.affordable
              ? () {
                  Navigator.of(context).pop();
                  learnSkill(host, ref, entry.id, allyId: allyId, cost: points);
                }
              : null,
          icon: const Icon(Icons.auto_awesome),
          label: Text(have >= points
              ? (points == 1
                  ? tr(ref, 'learn_for_point')
                  : tr(ref, 'learn_for_points').replaceAll('{n}', '$points'))
              : have == 0
                  ? tr(ref, 'no_skill_points')
                  : tr(ref, 'skill_points_needed')
                      .replaceAll('{n}', '$points')),
        );
    }
  }
}

/// The sheet for a branch's mastery.
Future<void> showMasterySheet(
    BuildContext context, WidgetRef ref, SkillBranch branch) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(builder: (inner, ref, _) {
      final model = watchSkillsModel(ref, null);
      if (model == null) return const SizedBox(height: 120);
      final theme = Theme.of(inner);
      final ink = InkColors.of(inner);
      final isMastered = branch.id == model.masteredBranchId;
      final String status;
      if (isMastered) {
        status = tr(ref, 'mastery_done');
      } else if (model.masteredBranchId.isNotEmpty) {
        status = tr(ref, 'mastery_closed');
      } else if (!model.isComplete(branch)) {
        status = tr(ref, 'mastery_needs_branch');
      } else {
        status = '';
      }
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: ink.gold, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(ref, 'mastery_title')
                          .replaceAll('{branch}', branch.name),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(branch.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                tr(ref, 'mastery_body')
                    .replaceAll('{cost}', '$branchMasteryCost'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (status.isNotEmpty)
                Text(status,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(color: ink.ash))
              else
                FilledButton.icon(
                  key: const Key('tree_master'),
                  onPressed: model.canMaster(branch)
                      ? () {
                          Navigator.of(sheetContext).pop();
                          ref
                              .read(playerSessionProvider.notifier)
                              .masterBranch(branch.id, cost: branchMasteryCost);
                          showImmersiveNotice(
                            context,
                            icon: Icons.star,
                            message: tr(ref, 'mastery_gained')
                                .replaceAll('{branch}', branch.name),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.star),
                  label: Text(tr(ref, 'mastery_button')
                      .replaceAll('{cost}', '$branchMasteryCost')),
                ),
            ],
          ),
        ),
      );
    }),
  );
}
