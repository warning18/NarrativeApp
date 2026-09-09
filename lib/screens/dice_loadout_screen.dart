import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';

class DiceLoadoutScreen extends ConsumerStatefulWidget {
  const DiceLoadoutScreen({super.key});

  @override
  ConsumerState<DiceLoadoutScreen> createState() => _DiceLoadoutScreenState();
}

class _DiceLoadoutScreenState extends ConsumerState<DiceLoadoutScreen> {
  String? _selectedDiceId;

  @override
  Widget build(BuildContext context) {
    final diceAsync = ref.watch(gameDbProvider(diceSchema));
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final session = ref.watch(playerSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dice Loadout')),
      body: diceAsync.when(
        data: (dice) => skillsAsync.when(
          data: (skills) => _buildBody(context, dice, skills, session),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Failed to load skills: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load dice: $error')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    PlayerSession session,
  ) {
    final diceIds = session.ownedDiceIds.where(dice.containsKey).toList()..sort();
    if (diceIds.isEmpty) {
      return const Center(child: Text('You don\'t own any dice yet — buy or find one first.'));
    }
    _selectedDiceId = diceIds.contains(_selectedDiceId) ? _selectedDiceId : diceIds.first;
    final selectedDice = dice[_selectedDiceId] as Map<String, dynamic>;
    final faces = (selectedDice['faces'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final skillFaceIndexes = [
      for (var i = 0; i < faces.length; i++)
        if (faces[i]['type'] == 'Skill') i,
    ];
    final assignments = session.diceSkillAssignments[_selectedDiceId] ?? const <String, String>{};
    final unlockedSkillIds = <String>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ?? false) ||
            session.unlockedSkillIds.contains(entry.key))
          entry.key,
    }.toList()
      ..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _selectedDiceId,
            decoration: const InputDecoration(labelText: 'Die', border: OutlineInputBorder()),
            items: diceIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
            onChanged: (value) => setState(() => _selectedDiceId = value),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text('Skill Faces', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Drag a skill below onto a face to bind it for combat.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (skillFaceIndexes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('This die has no Skill faces to customize.'),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: skillFaceIndexes.map((index) {
                    final face = faces[index];
                    final assignedSkillId = assignments[index.toString()];
                    final defaultSkillId = face['linkedSkillID']?.toString() ?? '';
                    return _FaceSlot(
                      face: face,
                      assignedSkillId: assignedSkillId,
                      defaultSkillId: defaultSkillId,
                      onAccept: (skillId) => ref
                          .read(playerSessionProvider.notifier)
                          .assignSkillToDiceFace(_selectedDiceId!, index, skillId),
                      onClear: assignedSkillId == null
                          ? null
                          : () => ref
                              .read(playerSessionProvider.notifier)
                              .clearDiceFaceSkill(_selectedDiceId!, index),
                    );
                  }).toList(),
                ),
              const Divider(height: 40),
              Text('Your Unlocked Skills', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (unlockedSkillIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No skills unlocked yet — unlock some on the Skills screen.'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unlockedSkillIds.map((id) {
                    final skill = skills[id] as Map<String, dynamic>?;
                    return _SkillChip(
                      skillId: id,
                      element: skill?['element']?.toString(),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skillId, this.element});

  final String skillId;
  final String? element;

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      avatar: Icon(elementIcon(element), size: 18),
      label: Text(skillId),
    );
    return Draggable<String>(
      data: skillId,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: chip,
    );
  }
}

class _FaceSlot extends StatelessWidget {
  const _FaceSlot({
    required this.face,
    required this.assignedSkillId,
    required this.defaultSkillId,
    required this.onAccept,
    required this.onClear,
  });

  final Map<String, dynamic> face;
  final String? assignedSkillId;
  final String defaultSkillId;
  final ValueChanged<String> onAccept;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final faceName = face['faceName']?.toString() ?? 'Skill';
    final effectiveSkillId = assignedSkillId ?? (defaultSkillId.isNotEmpty ? defaultSkillId : null);
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovering ? colorScheme.primary : colorScheme.outline,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(faceName, style: Theme.of(context).textTheme.titleSmall),
                  ),
                  if (onClear != null)
                    InkWell(
                      onTap: onClear,
                      child: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                effectiveSkillId ?? 'Drop a skill here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: effectiveSkillId == null ? FontStyle.italic : FontStyle.normal,
                    ),
              ),
              if (assignedSkillId != null)
                Text(
                  'Custom',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colorScheme.primary),
                ),
            ],
          ),
        );
      },
    );
  }
}
