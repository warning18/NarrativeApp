import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// A simple conversation view for one NPC: their description plus a short
/// set of flavor lines, with a Talk button that records the conversation
/// (backing Talk-type quest objectives — see quest_objectives.dart).
class NpcDetailScreen extends ConsumerWidget {
  const NpcDetailScreen({super.key, required this.npcId, required this.npc});

  final String npcId;
  final Map<String, dynamic> npc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final npcName = npc['npcName']?.toString() ?? npcId;
    final description = french
        ? ((npc['description_fr']?.toString().isNotEmpty ?? false)
            ? npc['description_fr'].toString()
            : npc['description']?.toString() ?? '')
        : npc['description']?.toString() ?? '';
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
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          npcName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    line,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
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
