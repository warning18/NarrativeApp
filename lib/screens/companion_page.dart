// A companion's own page (v1.606, the Companion review's version B): who they
// are and their health, the seat button (Core's rules: allyJoinState and
// setAllyInParty in party_actions.dart), how they feel about the player as a
// meter with its thresholds named (approval.dart's numbers), what they like and
// dislike, a drink to share once a chapter, and their die, skills and gear.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart' show dieDisplayName, skillDisplayName;
import '../data/approval.dart';
import '../data/companion_remarks.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/remark_provider.dart';
import '../theme/stitched_ink.dart';
import '../widgets/companion_parts.dart';
import '../widgets/companion_remark_bubble.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/inventory_parts.dart' show InventoryDieTile;
import '../widgets/party_actions.dart';
import 'dice_loadout_screen.dart';
import 'inventory_screen.dart';
import 'skills/skills_screen.dart';

class CompanionPage extends ConsumerWidget {
  const CompanionPage({super.key, required this.companionId});

  final String companionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(companionViewsProvider);
    final view = views?.where((v) => v.id == companionId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(view?.name ?? '')),
      body: view == null
          ? const Center(child: CircularProgressIndicator())
          : _CompanionBody(view: view),
    );
  }
}

class _CompanionBody extends ConsumerWidget {
  const _CompanionBody({required this.view});
  final CompanionView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    final houses =
        ref.watch(localizedDbProvider(housesSchema)).value ?? const {};
    final colour = tierColorOf(context, view.tier);
    final id = view.id;
    final join = allyJoinState(ref, session,
        companionId: id,
        companion: view.record,
        houses: houses.cast<String, dynamic>());
    final canBench = ref
        .read(playerSessionProvider.notifier)
        .canBench(id, companions.cast<String, dynamic>());
    final capacity = partyCapacityFor(session.builtHouseIds, houses);
    final requiredHouse = view.record['requiredHouseId']?.toString() ?? '';

    final effectKey = switch (view.tier) {
      ApprovalTier.devoted => 'approval_effect_devoted',
      ApprovalTier.friendly => 'approval_effect_friendly',
      ApprovalTier.wary || ApprovalTier.estranged => 'approval_effect_wary',
      ApprovalTier.neutral => null,
    };
    List<String> deeds(bool liked) => [
          for (final (field, key) in const [
            ('approvesGood', 'deed_good'),
            ('approvesEvil', 'deed_evil'),
            ('approvesProfit', 'deed_profit'),
          ])
            if (((view.record[field] as num?)?.toInt() ?? 0) *
                    (liked ? 1 : -1) >
                0)
              tr(ref, key),
        ];

    Widget chips(List<String> items, Color c, IconData icon) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in items)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  border: Border.all(color: c.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 13, color: c),
                  const SizedBox(width: 4),
                  Text(s,
                      style: theme.textTheme.labelMedium?.copyWith(color: c)),
                ]),
              ),
          ],
        );

    Widget title(String text, {String? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
          child: Row(children: [
            Expanded(
              child: Text(text.toUpperCase(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
            ),
            if (trailing != null)
              Text(trailing,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ]),
        );

    Widget tapRow(
            {required Widget leading,
            required String heading,
            required String line,
            required VoidCallback onTap,
            Key? key}) =>
        InkWell(
          key: key,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ink.seam),
            ),
            child: Row(children: [
              SizedBox(width: 44, child: Center(child: leading)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading, style: theme.textTheme.titleSmall),
                    Text(line,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ink.ash),
            ]),
          ),
        );

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    final subtitle = view.isGuideDog
        ? tr(ref, 'companion_guide_dog')
        : [view.raceName, view.professionName]
            .where((s) => s.isNotEmpty)
            .join(' ');
    final skills = view.ally.unlockedSkillIds;
    final points = view.ally.skillPoints;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        Row(children: [
          CompanionPortrait(view, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(view.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontFamily: InkFonts.display)),
                Text(subtitle,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                      child:
                          HealthBar(hp: view.hp, max: view.maxHp, height: 7)),
                  const SizedBox(width: 6),
                  Text('${view.hp}/${view.maxHp} ${tr(ref, 'hp_label')}',
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // The seat: Core's rules decide whether it can be taken or left.
        if (view.active)
          OutlinedButton(
            key: Key('party_toggle_$id'),
            onPressed: !canBench
                ? null
                : () => setAllyInParty(context, ref,
                    companionId: id,
                    active: false,
                    partyCapacity: capacity,
                    requiredHouseId: requiredHouse),
            child: Text(tr(ref, 'companion_seat_bench')),
          )
        else
          FilledButton(
            key: Key('party_toggle_$id'),
            onPressed: !join.canJoin
                ? null
                : () => setAllyInParty(context, ref,
                    companionId: id,
                    active: true,
                    partyCapacity: capacity,
                    requiredHouseId: requiredHouse),
            child: Text(tr(ref, 'companion_seat_take')),
          ),
        if (view.active && !canBench)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(tr(ref, 'companion_stays_alone'),
                key: Key('companion_stays_$id'),
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ),
        if (!view.active && join.reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(join.reason,
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ),
        title(tr(ref, 'companion_how_they_feel')),
        Row(children: [
          TierChip(view.tier, textKey: Key('approval_tier_$id')),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                effectKey == null
                    ? tr(ref, 'companion_no_bonus')
                    : tr(ref, effectKey),
                style: theme.textTheme.bodySmall?.copyWith(color: colour)),
          ),
        ]),
        const SizedBox(height: 6),
        ApprovalMeter(approval: view.approval),
        const SizedBox(height: 6),
        Text(tr(ref, 'companion_bench_note'),
            key: const Key('companion_bench_note'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: chips(deeds(true), const Color(0xFF3F8F5A),
                  Icons.thumb_up_outlined)),
          const SizedBox(width: 8),
          Expanded(
              child: chips(deeds(false), const Color(0xFFC0392B),
                  Icons.thumb_down_outlined)),
        ]),
        _DrinkButton(view: view),
        title(tr(ref, 'companion_their_die')),
        tapRow(
          key: Key('companion_die_$id'),
          leading: InventoryDieTile(dieId: view.dieId, faces: 6, size: 40),
          heading: dieDisplayName(view.dieId,
              language: fr ? AppLanguage.fr : AppLanguage.en),
          line: tr(ref, 'companion_dice_line'),
          onTap: () => open(DiceLoadoutScreen(allyId: id)),
        ),
        title(tr(ref, 'skills'),
            trailing: points > 0
                ? tr(ref, 'companion_to_learn').replaceAll('{n}', '$points')
                : null),
        InkWell(
          key: Key('companion_skills_$id'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => open(SkillsScreen(allyId: id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: skills.isEmpty
                ? Text(tr(ref, 'companion_starter_only'),
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash))
                : Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final s in skills.take(6))
                      Chip(
                        label: Text(
                            skillDisplayName(s,
                                language: fr ? AppLanguage.fr : AppLanguage.en),
                            style: theme.textTheme.labelMedium),
                        visualDensity: VisualDensity.compact,
                      ),
                  ]),
          ),
        ),
        title(tr(ref, 'ally_gear_button')),
        tapRow(
          key: Key('companion_gear_$id'),
          leading: Icon(Icons.backpack_outlined, color: ink.gold),
          heading: tr(ref, 'ally_gear_button'),
          line: tr(ref, 'companion_gear_line'),
          onTap: () => open(InventoryScreen(allyId: id)),
        ),
      ],
    );
  }
}

/// A drink to share, once a chapter (the camp's rule, moved here from the old
/// card): the companion says something back in a speech bubble.
class _DrinkButton extends ConsumerWidget {
  const _DrinkButton({required this.view});
  final CompanionView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = ref.watch(reachedChapterProvider);
    final gold = ref.watch(playerSessionProvider.select((s) => s.gold));
    // Loaded before a drink is shared, for the companion's word of thanks.
    ref.watch(remarkBookProvider);
    final cost = giftCostFor(chapter);
    final shared = view.ally.giftChapter == chapter;
    final id = view.id;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: Key('share_drink_$id'),
        onPressed: shared || gold < cost
            ? null
            : () async {
                final done = await ref
                    .read(playerSessionProvider.notifier)
                    .shareDrink(id, chapter: chapter);
                if (done && context.mounted) {
                  // They say something back (see companion_remarks.dart), in
                  // a speech bubble after the notice.
                  final said = drinkRemark(ref.read(remarkBookProvider),
                      ref.read(remarkMemoryProvider), id);
                  ref.read(remarkMemoryProvider.notifier).state = said.memory;
                  await showImmersiveNotice(context,
                      icon: Icons.local_drink,
                      message: tr(ref, 'share_drink_notice')
                          .replaceAll('{name}', view.name));
                  final remark = said.remark;
                  if (remark != null && context.mounted) {
                    await showCompanionRemarks(context, ref, [remark]);
                  }
                }
              },
        icon: const Icon(Icons.local_drink_outlined, size: 18),
        label: Text(shared
            ? tr(ref, 'share_drink_done')
            : tr(ref, 'share_drink_button').replaceAll('{cost}', '$cost')),
      ),
    );
  }
}
