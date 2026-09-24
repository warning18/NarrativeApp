import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/detail_dialog.dart';

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
        ? ref.watch(gameDbProvider(companionsSchema)).value ??
            const <String, dynamic>{}
        : const <String, dynamic>{};
    final companion = widget.allyId != null
        ? companions[widget.allyId] as Map<String, dynamic>?
        : null;
    final ally = widget.allyId != null
        ? session.recruitedAllies.firstWhere(
            (a) => a.companionId == widget.allyId,
            orElse: () =>
                AllyState(companionId: widget.allyId!, currentHealth: 0),
          )
        : null;
    final titleSuffix = widget.allyId != null
        ? ' — ${companion?['companionName']?.toString() ?? widget.allyId}'
        : '';

    return Scaffold(
      appBar: AppBar(title: Text('${tr(ref, 'dice_loadout')}$titleSuffix')),
      body: diceAsync.when(
        data: (dice) => skillsAsync.when(
          data: (skills) =>
              _buildBody(context, dice, skills, session, companion, ally),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child: Text('${tr(ref, 'failed_to_load_skills')}: $error')),
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
      _selectedDiceId =
          diceIds.contains(_selectedDiceId) ? _selectedDiceId : diceIds.first;
    } else {
      _selectedDiceId = diceIds.first;
    }
    final selectedDice = dice[_selectedDiceId] as Map<String, dynamic>;
    final faces =
        (selectedDice['faces'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final assignments = ally != null
        ? ally.diceSkillAssignments
        : session.diceSkillAssignments[_selectedDiceId] ??
            const <String, String>{};
    final unlockedSkillIds = <String>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ??
                false) ||
            (ally?.unlockedSkillIds ?? session.unlockedSkillIds)
                .contains(entry.key))
          entry.key,
    }.toList()
      ..sort();
    final language = ref.watch(appLanguageProvider);
    final totalWeight = faces.fold<double>(
        0, (sum, f) => sum + ((f['weight'] as num?)?.toDouble() ?? 1.0));

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
              items: diceIds
                  .map((id) => DropdownMenuItem(
                      value: id,
                      child: Text(
                          (dice[id] as Map<String, dynamic>?)?['diceName']
                                  ?.toString() ??
                              id)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedDiceId = value),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${tr(ref, 'die_label')}: ${dieDisplayName(_selectedDiceId ?? '')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text(tr(ref, 'skill_faces_title'),
                  style: Theme.of(context).textTheme.titleMedium),
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
                    Builder(builder: (context) {
                      final face = faces[index];
                      final open = isAssignableFace(face);
                      final assignedSkillId =
                          open ? assignments[index.toString()] : null;
                      final faceElement = face['element']?.toString() ?? 'None';
                      // A skill face with an element takes only skills of
                      // that element; a basic face takes any skill.
                      final restriction = open &&
                              face['type'] == 'Skill' &&
                              faceElement != 'None'
                          ? faceElement
                          : null;
                      void assign(String skillId) => ally != null
                          ? ref
                              .read(playerSessionProvider.notifier)
                              .assignSkillToAllyDiceFace(
                                  ally.companionId, index, skillId)
                          : ref
                              .read(playerSessionProvider.notifier)
                              .assignSkillToDiceFace(
                                  _selectedDiceId!, index, skillId);
                      void clear() => ally != null
                          ? ref
                              .read(playerSessionProvider.notifier)
                              .clearAllyDiceFaceSkill(ally.companionId, index)
                          : ref
                              .read(playerSessionProvider.notifier)
                              .clearDiceFaceSkill(_selectedDiceId!, index);
                      final skillId = faceSkillId(face, assignedSkillId);
                      return _FaceSlot(
                        face: face,
                        chance: totalWeight <= 0
                            ? 0
                            : ((face['weight'] as num?)?.toDouble() ?? 1.0) /
                                totalWeight,
                        assignedSkillId: assignedSkillId,
                        language: language,
                        locked: !open,
                        restrictionElement: restriction,
                        skills: skills,
                        onAccept: assign,
                        onClear: assignedSkillId == null ? null : clear,
                        onTap: open
                            ? () => _pickSkill(
                                  context,
                                  face: face,
                                  skills: skills,
                                  unlockedSkillIds: unlockedSkillIds,
                                  restriction: restriction,
                                  current: assignedSkillId,
                                  onPick: assign,
                                  onClear:
                                      assignedSkillId == null ? null : clear,
                                )
                            : skillId == null
                                ? null
                                : () => _showSkillDetail(context, skillId,
                                    skills[skillId] as Map<String, dynamic>?),
                      );
                    }),
                ],
              ),
              const Divider(height: 40),
              Text(tr(ref, 'your_unlocked_skills'),
                  style: Theme.of(context).textTheme.titleMedium),
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
                      label: skillDisplayName(id),
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

  /// Tap-to-pick for an open face: every usable skill (only those of the
  /// face's element when it has one), with what each does, plus a way back
  /// to the face's own action.
  void _pickSkill(
    BuildContext context, {
    required Map<String, dynamic> face,
    required Map<String, dynamic> skills,
    required List<String> unlockedSkillIds,
    required String? restriction,
    required String? current,
    required ValueChanged<String> onPick,
    required VoidCallback? onClear,
  }) {
    final lang = ref.read(appLanguageProvider);
    String t(String key) => trFor(lang, key);
    final choices = [
      for (final id in unlockedSkillIds)
        if (restriction == null ||
            (skills[id] as Map<String, dynamic>?)?['element']?.toString() ==
                restriction)
          id,
    ];
    final basic = isBasicFace(face);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(t('pick_face_skill_title'),
                    style: theme.textTheme.titleMedium),
                if (basic)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t('channeled_face_note').replaceAll('{face}',
                          t(basicFaceLabelKey(face['type']?.toString() ?? ''))),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                if (onClear != null)
                  ListTile(
                    leading: const Icon(Icons.undo),
                    title: Text(t('reset_face_button')),
                    subtitle: Text(_basicFaceSummary(face, lang)),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onClear();
                    },
                  ),
                if (choices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(t('no_skills_unlocked_hint')),
                  ),
                for (final id in choices)
                  ListTile(
                    leading: Icon(elementIcon(
                        (skills[id] as Map<String, dynamic>?)?['element']
                            ?.toString())),
                    title: Text(skillDisplayName(id)),
                    subtitle: Text(_skillSummary(
                        skills[id] as Map<String, dynamic>?, lang)),
                    selected: id == current,
                    trailing: id == current ? const Icon(Icons.check) : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onPick(id);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSkillDetail(
      BuildContext context, String skillId, Map<String, dynamic>? skill) {
    final lang = ref.read(appLanguageProvider);
    String t(String key) => trFor(lang, key);
    final element = skill?['element']?.toString();
    final cost = (skill?['cost'] as num?)?.toInt() ?? 0;
    final requiredSkillId = skill?['requiredSkillID']?.toString() ?? '';

    showDetailDialog(
      context,
      title: skillDisplayName(skillId),
      description: skill?['description']?.toString() ?? '',
      icon: elementIcon(element),
      closeLabel: t('close_button'),
      rows: [
        MapEntry(t('element_label'), element ?? t('none_label')),
        MapEntry(t('cost_label'), '$cost'),
        MapEntry(t('damage_mod_label'), '${skill?['damageMod'] ?? 0}'),
        MapEntry(t('damage_multiplier_label'),
            '${skill?['damageMultiplier'] ?? 1.0}'),
        MapEntry(t('heal_amount'), '${skill?['healAmount'] ?? 0}'),
        if (requiredSkillId.isNotEmpty)
          MapEntry(t('requires_label'), requiredSkillId),
        MapEntry(
          t('active_skill_label'),
          (skill?['isActiveSkill'] as bool? ?? true)
              ? t('yes_label')
              : t('no_label'),
        ),
      ],
    );
  }
}

/// "Attack 5 · Fire" -- what a face does without a skill on it.
String _basicFaceSummary(Map<String, dynamic> face, AppLanguage lang) {
  final type = face['type']?.toString() ?? '';
  final value = (face['value'] as num?)?.toInt() ?? 0;
  final element = face['element']?.toString() ?? 'None';
  return [
    '${trFor(lang, basicFaceLabelKey(type))}${value > 0 ? ' $value' : ''}',
    if (element != 'None') element,
  ].join(' · ');
}

/// "+6 dmg ×1.4 · Fire" -- a skill's numbers in one line.
String _skillSummary(Map<String, dynamic>? skill, AppLanguage lang) {
  final damageMod = (skill?['damageMod'] as num?)?.toInt() ?? 0;
  final multiplier = (skill?['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  final heal = (skill?['healAmount'] as num?)?.toInt() ?? 0;
  final element = skill?['element']?.toString() ?? 'None';
  final status = skill?['inflictsStatus']?.toString() ?? '';
  return [
    if (damageMod > 0 || multiplier != 1.0)
      '${trFor(lang, 'damage_word')} +$damageMod'
          '${multiplier != 1.0 ? ' ×$multiplier' : ''}',
    if (heal > 0) '${trFor(lang, 'face_heal_label')} $heal',
    if (status.isNotEmpty) status,
    if (element != 'None') element,
  ].join(' · ');
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.skillId,
    required this.label,
    this.element,
    this.onTap,
  });

  final String skillId;
  final String label;
  final String? element;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(elementIcon(element), size: 18),
        label: Text(label),
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

/// One face of the die: named after the skill it casts (or its basic
/// action), with what it does, how often it comes up, and whether it is
/// fixed, open, or set to a skill of the player's choosing. Open faces take
/// a skill by tap (a picker) or by dragging a skill chip onto them.
class _FaceSlot extends StatelessWidget {
  const _FaceSlot({
    required this.face,
    required this.chance,
    required this.assignedSkillId,
    required this.language,
    required this.onAccept,
    required this.onClear,
    required this.locked,
    required this.skills,
    this.restrictionElement,
    this.onTap,
  });

  final Map<String, dynamic> face;
  final double chance;
  final String? assignedSkillId;
  final AppLanguage language;
  final ValueChanged<String> onAccept;
  final VoidCallback? onClear;
  final bool locked;
  final Map<String, dynamic> skills;

  /// When set, only skills whose own `element` matches this may be dropped.
  final String? restrictionElement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    String t(String key) => trFor(language, key);
    final name = faceDisplayName(face,
        assignedSkillId: assignedSkillId, language: language);
    final skillId = faceSkillId(face, assignedSkillId);
    final channeled = assignedSkillId != null && isBasicFace(face);
    final detail = skillId == null
        ? _basicFaceSummary(face, language)
        : _skillSummary(skills[skillId] as Map<String, dynamic>?, language);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget content(bool isHovering, bool isInvalidHover) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isInvalidHover
                ? colorScheme.errorContainer
                : (isHovering
                    ? colorScheme.primaryContainer
                    : locked
                        ? colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)
                        : colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isInvalidHover
                  ? colorScheme.error
                  : (isHovering
                      ? colorScheme.primary
                      : assignedSkillId != null
                          ? colorScheme.primary
                          : colorScheme.outlineVariant),
              width: (isHovering || isInvalidHover) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: textTheme.titleSmall)),
                  if (locked)
                    Icon(Icons.lock_outline,
                        size: 16, color: colorScheme.outline)
                  else if (onClear != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: t('clear_assigned_skill_tooltip'),
                      visualDensity: VisualDensity.compact,
                      onPressed: onClear,
                    )
                  else
                    Icon(Icons.edit_outlined,
                        size: 16, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text(detail, style: textTheme.bodySmall),
              Text(
                '${(chance * 100).round()}% ${t('face_chance_suffix')}',
                style: textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (locked)
                Text(t('fixed_face_label'), style: textTheme.labelSmall)
              else if (channeled)
                Text(
                  t('channeled_face_badge').replaceAll('{face}',
                      t(basicFaceLabelKey(face['type']?.toString() ?? ''))),
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.primary),
                )
              else if (assignedSkillId != null)
                Text(t('custom_label'),
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.primary)),
              if (!locked && restrictionElement != null)
                Text('$restrictionElement ${t('only_suffix')}',
                    style: textTheme.labelSmall),
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
        final skillElement =
            (skills[details.data] as Map<String, dynamic>?)?['element']
                ?.toString();
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
