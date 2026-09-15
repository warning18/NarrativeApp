import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/detail_dialog.dart';

/// A face's signature skill (non-empty `linkedSkillID`, other than the
/// universal `heavy_attack` filler every die carries) is the die's fixed
/// identity move and can't be reassigned. Faces with no linkedSkillID, or
/// with the generic `heavy_attack`, are open slots the player can fill
/// with any of their unlocked skills (subject to the face's element, if
/// it has one other than "None").
bool _isFixedSkillFace(Map<String, dynamic> face) {
  if (face['type'] != 'Skill') return false;
  final linked = face['linkedSkillID']?.toString() ?? '';
  return linked.isNotEmpty && linked != 'heavy_attack';
}

class DiceLoadoutScreen extends ConsumerStatefulWidget {
  const DiceLoadoutScreen({super.key, this.allyId});

  /// When set, this screen manages the named companion's signature die
  /// instead of the player's own dice collection — same screen, pointed at
  /// that companion's own [AllyState.diceSkillAssignments] and
  /// [AllyState.unlockedSkillIds] instead of [PlayerSession]'s.
  final String? allyId;

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
    final companions = widget.allyId != null
        ? ref.watch(gameDbProvider(companionsSchema)).value ?? const <String, dynamic>{}
        : const <String, dynamic>{};
    final companion =
        widget.allyId != null ? companions[widget.allyId] as Map<String, dynamic>? : null;
    final ally = widget.allyId != null
        ? session.recruitedAllies.firstWhere(
            (a) => a.companionId == widget.allyId,
            orElse: () => AllyState(companionId: widget.allyId!, currentHealth: 0),
          )
        : null;
    final titleSuffix =
        widget.allyId != null ? ' — ${companion?['companionName']?.toString() ?? widget.allyId}' : '';

    return Scaffold(
      appBar: AppBar(title: Text('${tr(ref, 'dice_loadout')}$titleSuffix')),
      body: diceAsync.when(
        data: (dice) => skillsAsync.when(
          data: (skills) => _buildBody(context, dice, skills, session, companion, ally),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('${tr(ref, 'failed_to_load_skills')}: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_dice')}: $error')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    PlayerSession session,
    Map<String, dynamic>? companion,
    AllyState? ally,
  ) {
    // An ally has exactly one die (their fixed signature die, never
    // player-swappable) — no dropdown needed, unlike the player's own
    // collection of owned dice.
    final diceIds = ally != null
        ? [companion?['signatureDiceId']?.toString() ?? '']
        : (session.ownedDiceIds.where(dice.containsKey).toList()..sort());
    if (diceIds.isEmpty || !dice.containsKey(diceIds.first)) {
      return Center(child: Text(tr(ref, 'own_no_dice')));
    }
    if (ally == null) {
      _selectedDiceId = diceIds.contains(_selectedDiceId) ? _selectedDiceId : diceIds.first;
    } else {
      _selectedDiceId = diceIds.first;
    }
    final selectedDice = dice[_selectedDiceId] as Map<String, dynamic>;
    final faces = (selectedDice['faces'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final assignments = ally != null
        ? ally.diceSkillAssignments
        : session.diceSkillAssignments[_selectedDiceId] ?? const <String, String>{};
    final unlockedSkillIds = <String>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ?? false) ||
            (ally?.unlockedSkillIds ?? session.unlockedSkillIds).contains(entry.key))
          entry.key,
    }.toList()
      ..sort();
    final language = ref.watch(appLanguageProvider);

    return Column(
      children: [
        if (ally == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              // `value` (not `initialValue`) is needed here: this field must
              // stay reactive to _selectedDiceId, not just seed from it once.
              // ignore: deprecated_member_use
              value: _selectedDiceId,
              decoration: InputDecoration(
                labelText: tr(ref, 'die_label'),
                border: const OutlineInputBorder(),
              ),
              items: diceIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
              onChanged: (value) => setState(() => _selectedDiceId = value),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${tr(ref, 'die_label')}: ${_selectedDiceId ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text(tr(ref, 'skill_faces_title'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                tr(ref, 'drag_skill_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < faces.length; index++)
                    if (faces[index]['type'] == 'Skill')
                      Builder(builder: (context) {
                        final face = faces[index];
                        final assignedSkillId = assignments[index.toString()];
                        final defaultSkillId = face['linkedSkillID']?.toString() ?? '';
                        final locked = _isFixedSkillFace(face);
                        final faceElement = face['element']?.toString() ?? 'None';
                        return _FaceSlot(
                          face: face,
                          assignedSkillId: assignedSkillId,
                          defaultSkillId: defaultSkillId,
                          language: language,
                          locked: locked,
                          restrictionElement: faceElement != 'None' ? faceElement : null,
                          skills: skills,
                          onAccept: (skillId) => ally != null
                              ? ref
                                  .read(playerSessionProvider.notifier)
                                  .assignSkillToAllyDiceFace(ally.companionId, index, skillId)
                              : ref
                                  .read(playerSessionProvider.notifier)
                                  .assignSkillToDiceFace(_selectedDiceId!, index, skillId),
                          onClear: (locked || assignedSkillId == null)
                              ? null
                              : () => ally != null
                                  ? ref
                                      .read(playerSessionProvider.notifier)
                                      .clearAllyDiceFaceSkill(ally.companionId, index)
                                  : ref
                                      .read(playerSessionProvider.notifier)
                                      .clearDiceFaceSkill(_selectedDiceId!, index),
                          onShowDetail: (skillId) => _showSkillDetail(context, skillId, skills[skillId] as Map<String, dynamic>?),
                        );
                      })
                    else
                      _StaticFaceCard(face: faces[index]),
                ],
              ),
              const Divider(height: 40),
              Text(tr(ref, 'your_unlocked_skills'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (unlockedSkillIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(tr(ref, 'no_skills_unlocked_hint')),
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
                      onTap: () => _showSkillDetail(context, id, skill),
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

  void _showSkillDetail(BuildContext context, String skillId, Map<String, dynamic>? skill) {
    final lang = ref.read(appLanguageProvider);
    String t(String key) => trFor(lang, key);
    final element = skill?['element']?.toString();
    final cost = (skill?['cost'] as num?)?.toInt() ?? 0;
    final requiredSkillId = skill?['requiredSkillID']?.toString() ?? '';

    showDetailDialog(
      context,
      title: skillId,
      description: skill?['description']?.toString() ?? '',
      icon: elementIcon(element),
      closeLabel: t('close_button'),
      rows: [
        MapEntry(t('element_label'), element ?? t('none_label')),
        MapEntry(t('cost_label'), '$cost'),
        MapEntry(t('damage_mod_label'), '${skill?['damageMod'] ?? 0}'),
        MapEntry(t('damage_multiplier_label'), '${skill?['damageMultiplier'] ?? 1.0}'),
        MapEntry(t('heal_amount'), '${skill?['healAmount'] ?? 0}'),
        if (requiredSkillId.isNotEmpty) MapEntry(t('requires_label'), requiredSkillId),
        MapEntry(
          t('active_skill_label'),
          (skill?['isActiveSkill'] as bool? ?? true) ? t('yes_label') : t('no_label'),
        ),
      ],
    );
  }
}

class _StaticFaceCard extends StatelessWidget {
  const _StaticFaceCard({required this.face});

  final Map<String, dynamic> face;

  @override
  Widget build(BuildContext context) {
    final faceName = face['faceName']?.toString() ?? '';
    final type = face['type']?.toString() ?? '';
    final value = (face['value'] as num?)?.toInt() ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(faceName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text('$type · $value', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skillId, this.element, this.onTap});

  final String skillId;
  final String? element;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(elementIcon(element), size: 18),
        label: Text(skillId),
      ),
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
    required this.language,
    required this.onAccept,
    required this.onClear,
    required this.locked,
    required this.skills,
    this.restrictionElement,
    this.onShowDetail,
  });

  final Map<String, dynamic> face;
  final String? assignedSkillId;
  final String defaultSkillId;
  final AppLanguage language;
  final ValueChanged<String> onAccept;
  final VoidCallback? onClear;
  final bool locked;
  final Map<String, dynamic> skills;

  /// When set, only skills whose own `element` matches this may be dropped.
  final String? restrictionElement;
  final ValueChanged<String>? onShowDetail;

  @override
  Widget build(BuildContext context) {
    final faceName = face['faceName']?.toString() ?? trFor(language, 'skill_singular');
    final effectiveSkillId = assignedSkillId ?? (defaultSkillId.isNotEmpty ? defaultSkillId : null);
    final colorScheme = Theme.of(context).colorScheme;

    Widget content(bool isHovering, bool isInvalidHover) {
      return GestureDetector(
        onTap: effectiveSkillId != null && onShowDetail != null
            ? () => onShowDetail!(effectiveSkillId)
            : null,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isInvalidHover
                ? colorScheme.errorContainer
                : (isHovering ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isInvalidHover
                  ? colorScheme.error
                  : (isHovering ? colorScheme.primary : colorScheme.outline),
              width: (isHovering || isInvalidHover) ? 2 : 1,
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
                  if (locked)
                    Icon(Icons.lock_outline, size: 16, color: colorScheme.outline)
                  else if (onClear != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: trFor(language, 'clear_assigned_skill_tooltip'),
                      visualDensity: VisualDensity.compact,
                      onPressed: onClear,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                effectiveSkillId ?? trFor(language, 'drop_skill_here'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: effectiveSkillId == null ? FontStyle.italic : FontStyle.normal,
                    ),
              ),
              if (locked)
                Text(
                  trFor(language, 'fixed_face_label'),
                  style: Theme.of(context).textTheme.labelSmall,
                )
              else if (assignedSkillId != null)
                Text(
                  trFor(language, 'custom_label'),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: colorScheme.primary),
                ),
              if (!locked && restrictionElement != null)
                Text(
                  '$restrictionElement ${trFor(language, 'only_suffix')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      );
    }

    if (locked) return content(false, false);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final restriction = restrictionElement;
        if (restriction == null) return true;
        final skillElement = (skills[details.data] as Map<String, dynamic>?)?['element']?.toString();
        return skillElement == restriction;
      },
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isInvalidHover = rejectedData.isNotEmpty && candidateData.isEmpty;
        return content(isHovering, isInvalidHover);
      },
    );
  }
}
