import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/people_codex.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart' show clanDataProvider;
import '../providers/geography_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart' show coastGateWorldProvider;
import '../utils/game_icons.dart' show npcKindIcon;
import '../widgets/people_widgets.dart';

/// One person's page (v1.204, see people_codex.dart): who they are (icon,
/// name, role, faction, place, the chapter they are met in), their
/// description, what they want, what passed between them and the player
/// (the `states` whose flags are held and, v1.210, whose `conditions` hold
/// on the coast), where they stand in the intrigues the story has reached
/// (v1.210, see npcIntrigueLines), then their flavor lines with a Talk
/// button that records the conversation (backing Talk-type quest
/// objectives — see quest_objectives.dart).
class NpcDetailScreen extends ConsumerWidget {
  const NpcDetailScreen({super.key, required this.npcId, required this.npc});

  final String npcId;
  final Map<String, dynamic> npc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final language = ref.watch(appLanguageProvider);
    final french = language == AppLanguage.fr;
    final geography = ref.watch(geographyProvider);
    final clanData = ref.watch(clanDataProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final npcName = npc['npcName']?.toString() ?? npcId;
    final description = npcText(npc, 'description', french);
    final role = npcText(npc, 'role', french);
    final want = npcText(npc, 'want', french);
    final place =
        npcPlaceName(geography, npc['placeId']?.toString() ?? '', language);
    final world = ref.watch(coastGateWorldProvider);
    final passed = npcStateLines(npc, session.flags, french,
        world: world, politics: session.politics);
    final intrigueLines =
        npcIntrigueLines(npc, clanData.intrigues.values, session.flags, french);
    final linesRaw = french
        ? ((npc['dialogueLines_fr'] as List?)?.isNotEmpty ?? false)
            ? npc['dialogueLines_fr'] as List
            : npc['dialogueLines'] as List? ?? const []
        : npc['dialogueLines'] as List? ?? const [];
    final lines = linesRaw.map((e) => e.toString()).toList();
    final talkedTo = session.talkedToNpcIds.contains(npcId);

    return Scaffold(
      appBar: AppBar(title: Text(npcName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                          child: Icon(npcKindIcon(npc['kind']?.toString()))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(npcName, style: theme.textTheme.titleLarge),
                            if (role.isNotEmpty)
                              Text(role,
                                  key: const Key('npc_role'),
                                  style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                NpcFactionTag(
                                    data: clanData,
                                    factionId: npc['faction']?.toString() ?? '',
                                    language: language),
                                if (place.isNotEmpty)
                                  Text(place,
                                      key: const Key('npc_place'),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: muted)),
                                Text(
                                  tr(ref, 'npc_met_in_chapter')
                                      .replaceAll('{n}', '${npcChapter(npc)}'),
                                  key: const Key('npc_met_chapter'),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                  if (want.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(tr(ref, 'npc_want_label'),
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(want,
                        key: const Key('npc_want'),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
          if (passed.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(tr(ref, 'npc_passed_between'),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final (i, line) in passed.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history_edu, size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(line,
                          key: Key('npc_state_$i'),
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
          if (intrigueLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(tr(ref, 'npc_intrigues_label'),
                key: const Key('npc_intrigues_label'),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final (i, line) in intrigueLines.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.theater_comedy, size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(npcIntrigueLineText(line, french),
                          key: Key('npc_intrigue_$i'),
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: talkedTo
                ? null
                : () async {
                    await ref
                        .read(playerSessionProvider.notifier)
                        .talkToNpc(npcId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr(ref, 'npc_talked_message'))),
                    );
                  },
            icon: Icon(talkedTo ? Icons.check : Icons.forum),
            label:
                Text(tr(ref, talkedTo ? 'npc_already_talked' : 'talk_button')),
          ),
        ],
      ),
    );
  }
}
