import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../data/throne.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_politics.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import 'clan_widgets.dart';
import 'sign_widgets.dart';
import 'throne_widgets.dart';

/// Edit Mode's Clans & Politics, its Throne tab (v1.196, see throne.dart):
/// a card per faction with its climb -- its House, its clan quest steps
/// (set with − and +), the claim and the Throne -- and buttons to make it
/// the claim, crown it or have it pledge; then "Muster now", the Host as
/// it would come ("Host preview") and "Undo the climb".
class ThroneEditTab extends ConsumerWidget {
  const ThroneEditTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final session = ref.watch(playerSessionProvider);
    final politics = session.politics;
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    if (data.factions.isEmpty) {
      return Center(child: Text(tr(ref, 'clans_none')));
    }
    final climbers = [...data.clans, ...data.lost];
    final others = [...data.tribes, ...data.otherworld];
    final preview = hostFor(
        politics: politics,
        data: data,
        signPatrons: session.signPatronsThisLife);
    final notifier = ref.read(playerSessionProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final done = trFor(lang, 'throne_edit_done');

    Future<void> apply(StoryPolitics politics) async {
      await applyThroneEditNow(ref, politics);
      messenger.showSnackBar(
          SnackBar(content: Text(done), duration: const Duration(seconds: 1)));
    }

    Widget tag(String key, Color colour) => Text(
          trFor(lang, key),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: colour, fontWeight: FontWeight.w700),
        );

    Widget card(Faction faction, {required bool climbs}) {
      final id = faction.id;
      final climb = climbFor(id, politics, session.flags, data);
      final gold = standingTierTextColor(context, StandingTier.sworn);
      return Card(
        key: Key('throne_card_$id'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  faction.isLost
                      ? LostClanEmblem(
                          faction: faction,
                          stage: openHandStageFrom(session.flags),
                          size: 26)
                      : PatronEmblem(patron: faction.patron, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(faction.nameFor(lang),
                        style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (politics.throneWinner == id)
                    tag('throne_edit_crowned', gold),
                  if (politics.claim == id) tag('throne_edit_claimed', gold),
                  if (politics.hasPledged(id))
                    tag('throne_edit_pledged', theme.colorScheme.primary),
                ],
              ),
              if (climbs) ...[
                const SizedBox(height: 4),
                ClimbRungs(climb: climb, data: data, language: lang),
              ],
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                children: [
                  if (climbs && !faction.isLost) ...[
                    IconButton(
                      key: Key('throne_step_down_$id'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 18),
                      tooltip: trFor(lang, 'throne_edit_steps')
                          .replaceAll('{n}', '${climb.steps}'),
                      onPressed: climb.steps <= 0
                          ? null
                          : () => notifier.setClanStepsForEdit(
                              id, climb.steps - 1,
                              data: data),
                    ),
                    Text(
                      trFor(lang, 'throne_edit_steps')
                          .replaceAll('{n}', '${climb.steps}'),
                      key: Key('throne_steps_$id'),
                      style: theme.textTheme.labelMedium,
                    ),
                    IconButton(
                      key: Key('throne_step_up_$id'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: trFor(lang, 'throne_edit_steps')
                          .replaceAll('{n}', '${climb.steps}'),
                      onPressed: climb.steps >= clanQuestSteps
                          ? null
                          : () => notifier.setClanStepsForEdit(
                              id, climb.steps + 1,
                              data: data),
                    ),
                  ],
                  if (climbs)
                    TextButton(
                      key: Key('throne_claim_$id'),
                      onPressed: politics.claim == id
                          ? null
                          : () => apply(StoryPolitics(claim: id)),
                      child: Text(trFor(lang, 'throne_edit_claim')),
                    ),
                  if (climbs)
                    TextButton(
                      key: Key('throne_crown_$id'),
                      onPressed: politics.throneWinner == id
                          ? null
                          : () => apply(StoryPolitics(throneWinner: id)),
                      child: Text(trFor(lang, 'throne_edit_crown')),
                    ),
                  if (!faction.isLost)
                    TextButton(
                      key: Key('throne_pledge_$id'),
                      onPressed: politics.hasPledged(id)
                          ? null
                          : () => apply(StoryPolitics(pledges: [id])),
                      child: Text(trFor(lang, 'throne_edit_pledge')),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    String name(String id) =>
        data.faction(id)?.shortFor(lang) ??
        data.subclan(id)?.nameFor(lang) ??
        id;
    final colon = lang == AppLanguage.fr ? ' :' : ':';

    return ListView(
      key: const Key('clans_throne_list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(trFor(lang, 'throne_edit_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        for (final faction in climbers) card(faction, climbs: true),
        for (final faction in others) card(faction, climbs: false),
        const SizedBox(height: 8),
        Card(
          key: const Key('throne_host_preview'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trFor(lang, 'throne_edit_preview'),
                    style: theme.textTheme.titleSmall),
                Text(
                  '${trFor(lang, 'host_banner')}$colon '
                  '${preview.banner.isEmpty ? '–' : name(preview.banner)}',
                  key: const Key('throne_preview_banner'),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${trFor(lang, 'host_allies')}$colon '
                  '${preview.allies.isEmpty ? '–' : preview.allies.map(name).join(', ')}',
                  key: const Key('throne_preview_allies'),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${trFor(lang, 'host_houses')}$colon '
                  '${preview.houses.isEmpty ? '–' : preview.houses.map(name).join(', ')}',
                  key: const Key('throne_preview_houses'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('throne_muster'),
              icon: const Icon(Icons.groups_2_outlined),
              label: Text(trFor(lang, 'throne_edit_muster')),
              onPressed: () async {
                await applyThroneEditNow(
                    ref, const StoryPolitics(muster: true));
                if (context.mounted) await showHostSheet(context);
              },
            ),
            OutlinedButton.icon(
              key: const Key('throne_preview'),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(trFor(lang, 'throne_edit_preview')),
              onPressed: () => showHostSheet(context, preview: true),
            ),
            OutlinedButton.icon(
              key: const Key('throne_clear'),
              icon: const Icon(Icons.restart_alt),
              label: Text(trFor(lang, 'throne_edit_clear')),
              onPressed: () async {
                await notifier.clearThroneForEdit(data: data);
                messenger.showSnackBar(SnackBar(
                    content: Text(done), duration: const Duration(seconds: 1)));
              },
            ),
          ],
        ),
      ],
    );
  }
}
