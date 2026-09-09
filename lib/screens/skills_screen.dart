import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final session = ref.watch(playerSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skill Points: ${session.skillPoints}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: skillsAsync.when(
              data: (records) => _SkillList(records: records),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Failed to load skills: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillList extends ConsumerWidget {
  const _SkillList({required this.records});

  final Map<String, dynamic> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return const Center(child: Text('No skills defined yet.'));
    }
    final session = ref.watch(playerSessionProvider);
    final keys = records.keys.toList()..sort();

    bool isAvailable(String id) {
      final skill = records[id] as Map<String, dynamic>?;
      final globallyUnlocked = skill?['isUnlocked'] as bool? ?? false;
      return globallyUnlocked || session.unlockedSkillIds.contains(id);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: keys.map((id) {
        final skill = records[id] as Map<String, dynamic>;
        final element = skill['element']?.toString();
        final description = skill['description']?.toString() ?? '';
        final cost = (skill['cost'] as num?)?.toInt() ?? 0;
        final requiredSkillId = skill['requiredSkillID']?.toString() ?? '';
        final available = isAvailable(id);
        final prereqMet = requiredSkillId.isEmpty || isAvailable(requiredSkillId);

        Widget trailing;
        if (available) {
          trailing = const Icon(Icons.check_circle, color: Colors.green);
        } else {
          trailing = ElevatedButton(
            onPressed: (session.skillPoints > 0 && prereqMet)
                ? () async {
                    await ref.read(playerSessionProvider.notifier).unlockSkill(id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unlocked: $id')),
                    );
                  }
                : null,
            child: const Text('Unlock'),
          );
        }

        final subtitleParts = <String>[
          if (description.isNotEmpty) description,
          if (requiredSkillId.isNotEmpty) 'Requires: $requiredSkillId',
          'Cost: $cost',
        ];

        return Card(
          child: ListTile(
            leading: Icon(elementIcon(element)),
            title: Text(id),
            subtitle: Text(subtitleParts.join(' · ')),
            isThreeLine: description.isNotEmpty,
            trailing: trailing,
          ),
        );
      }).toList(),
    );
  }
}
