import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync =
        ref.watch(localizedDbProvider(achievementsSchema));
    final session = ref.watch(playerSessionProvider);

    return TutorialTrigger(
      topic: TutorialTopic.achievements,
      child: Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'achievements_title'))),
        body: achievementsAsync.when(
          data: (records) {
            final keys = records.keys.toList()..sort();
            final unlockedCount = keys
                .where((id) => session.unlockedAchievementIds.contains(id))
                .length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${tr(ref, 'achievements_progress_label')}: $unlockedCount / ${keys.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...keys.map((id) {
                  final record = records[id] as Map<String, dynamic>;
                  final name = record['achievementName']?.toString() ?? id;
                  final description = record['description']?.toString() ?? '';
                  final unlocked = session.unlockedAchievementIds.contains(id);
                  final colorScheme = Theme.of(context).colorScheme;
                  return Card(
                    color: unlocked ? colorScheme.primaryContainer : null,
                    child: ListTile(
                      leading: Icon(
                        unlocked
                            ? Icons.emoji_events
                            : Icons.emoji_events_outlined,
                        color: unlocked
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      title: Text(
                        name,
                        style: unlocked
                            ? null
                            : TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      subtitle: Text(description),
                      trailing: unlocked
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child: Text('${tr(ref, 'failed_to_load_achievements')}: $error')),
        ),
      ),
    );
  }
}
