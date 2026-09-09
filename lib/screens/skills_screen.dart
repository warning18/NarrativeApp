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
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
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
              data: (records) => _SkillList(
                records: records,
                races: racesAsync.value ?? const {},
                professions: professionsAsync.value ?? const {},
              ),
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
  const _SkillList({required this.records, required this.races, required this.professions});

  final Map<String, dynamic> records;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;

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

    bool meetsRestriction(Map<String, dynamic> skill) {
      final raceId = skill['restrictedRaceID']?.toString() ?? '';
      if (raceId.isNotEmpty && raceId != session.raceId) return false;
      final professionId = skill['restrictedProfessionID']?.toString() ?? '';
      if (professionId.isNotEmpty && professionId != session.professionId) return false;
      return true;
    }

    String restrictionLabel(Map<String, dynamic> skill) {
      final raceId = skill['restrictedRaceID']?.toString() ?? '';
      final professionId = skill['restrictedProfessionID']?.toString() ?? '';
      if (raceId.isEmpty && professionId.isEmpty) return '';
      final race = races[raceId] as Map<String, dynamic>?;
      final profession = professions[professionId] as Map<String, dynamic>?;
      final raceName = raceId.isNotEmpty ? (race?['raceName']?.toString() ?? raceId) : null;
      final professionName = professionId.isNotEmpty
          ? (profession?['professionName']?.toString() ?? professionId)
          : null;
      return 'Reserved: ${[raceName, professionName].whereType<String>().join(' · ')}';
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
        final restrictionOk = meetsRestriction(skill);
        final restriction = restrictionLabel(skill);

        Widget trailing;
        if (available) {
          trailing = const Icon(Icons.check_circle, color: Colors.green);
        } else if (!restrictionOk) {
          trailing = const Icon(Icons.lock_outline);
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
          if (restriction.isNotEmpty) restriction,
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
