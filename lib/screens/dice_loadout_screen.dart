import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart' show applySkillTier;
import '../combat/dice_faces.dart';
import '../combat/face_choice.dart';
import '../combat/face_keywords.dart';
import '../combat/face_smithing.dart';
import '../data/skill_tree.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/app_mode_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/face_style.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/face_skill_sheet.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/die_3d.dart';
import '../widgets/die_skins.dart';
import '../widgets/help_hint.dart';
import '../widgets/interactive_die.dart';
import 'skills/die_slot_ring.dart';
import '../widgets/moments.dart';
import '../widgets/empty_state.dart';

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

  /// The face of the die the player has turned to (v1.241), by its index.
  int _faceSel = 0;
  String? _selDieFor;

  @override
  Widget build(BuildContext context) {
    final diceAsync = ref.watch(localizedDbProvider(diceSchema));
    final skillsAsync = ref.watch(localizedDbProvider(skillsSchema));
    final session = ref.watch(playerSessionProvider);
    final companions = widget.allyId != null
        ? ref.watch(localizedDbProvider(companionsSchema)).value ??
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
      appBar: AppBar(
        title: Text('${tr(ref, 'dice_loadout')}$titleSuffix'),
        actions: const [TourInfoButton(topic: TutorialTopic.dice)],
      ),
      body: TutorialTrigger(
        topic: TutorialTopic.dice,
        child: diceAsync.when(
          data: (dice) => skillsAsync.when(
            data: (skills) =>
                _buildBody(context, dice, skills, session, companion, ally),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => InkErrorState(
                message: tr(ref, 'failed_to_load_skills'), detail: error),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => InkErrorState(
              message: tr(ref, 'failed_to_load_dice'), detail: error),
        ),
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
      return InkEmptyState(message: tr(ref, 'own_no_dice'));
    }
    if (ally == null) {
      _selectedDiceId =
          diceIds.contains(_selectedDiceId) ? _selectedDiceId : diceIds.first;
    } else {
      _selectedDiceId = diceIds.first;
    }
    if (_selDieFor != _selectedDiceId) {
      _selDieFor = _selectedDiceId;
      _faceSel = 0;
    }
    final selectedDice = dice[_selectedDiceId] as Map<String, dynamic>;
    // The die as the Hammersmith left it (see face_smithing.dart), an
    // ally's apart from the player's own copy of the same die.
    final faces = smithedFaces(
        (selectedDice['faces'] as List?)?.cast<Map<String, dynamic>>() ??
            const [],
        session.upgradesOfDie(_selectedDiceId, companionId: ally?.companionId));
    final assignments = ally != null
        ? ally.diceSkillAssignments
        : session.diceSkillAssignments[_selectedDiceId] ??
            const <String, String>{};
    // A skill takes no more faces than its rarity allows: the picks past
    // that (a save from before the limits) do their face's own action.
    final limited = limitedFaceAssignments(faces, assignments, skills);
    // A companion's faces take their own class's skills and their die's
    // kit only (see allySkillIds); the player's, anything they know.
    final allyOwn = ally == null
        ? null
        : allySkillIds(skills,
                professionId: companion?['professionId']?.toString() ?? '',
                known: ally.unlockedSkillIds)
            .toSet();
    final unlockedSkillIds = <String>{
      for (final entry in skills.entries)
        if (!isEnemyOnlySkill(entry.value as Map<String, dynamic>?) &&
            (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ??
                    false) ||
                (ally?.unlockedSkillIds ?? session.unlockedSkillIds)
                    .contains(entry.key)) &&
            (allyOwn == null ||
                allyOwn.contains(entry.key) ||
                (entry.value as Map<String, dynamic>)['isUnlocked'] == true))
          entry.key,
    }.toList()
      ..sort();
    final language = ref.watch(appLanguageProvider);
    final totalWeight = faces.fold<double>(
        0, (sum, f) => sum + ((f['weight'] as num?)?.toDouble() ?? 1.0));

    // What a face allows, from its index: shared by its slot and the cube.
    String? restrictionOf(int index) {
      final face = faces[index];
      final element = face['element']?.toString() ?? 'None';
      // A skill face with an element takes only skills of that element; a
      // basic face takes any skill.
      return isAssignableFace(face) &&
              face['type'] == 'Skill' &&
              !isSignatureFace(face) &&
              element != 'None'
          ? element
          : null;
    }

    void assignTo(int index, String skillId) => ally != null
        ? ref
            .read(playerSessionProvider.notifier)
            .assignSkillToAllyDiceFace(ally.companionId, index, skillId)
        : ref
            .read(playerSessionProvider.notifier)
            .assignSkillToDiceFace(_selectedDiceId!, index, skillId);
    void clearAt(int index) => ally != null
        ? ref
            .read(playerSessionProvider.notifier)
            .clearAllyDiceFaceSkill(ally.companionId, index)
        : ref
            .read(playerSessionProvider.notifier)
            .clearDiceFaceSkill(_selectedDiceId!, index);

    bool dropOk(int index, String skillId) {
      if (!isAssignableFace(faces[index])) return false;
      if (!canSetSkillOnFace(skillId, index, faces, assignments, skills)) {
        return false;
      }
      final restriction = restrictionOf(index);
      return restriction == null ||
          (skills[skillId] as Map<String, dynamic>?)?['element']?.toString() ==
              restriction;
    }

    // A tap on a face picks it (the cube turns to it); a double tap, on its
    // slot or on the cube, chooses its skill (v1.242).
    void selectFace(int index) => setState(() => _faceSel = index);
    void pickFace(int index) {
      setState(() => _faceSel = index);
      final face = faces[index];
      final open = isAssignableFace(face);
      final picked = open ? assignments[index.toString()] : null;
      final over = picked != null && limited[index.toString()] != picked;
      final assigned = over ? null : picked;
      final skillId = faceSkillId(face, assigned);
      if (open) {
        _pickSkill(
          context,
          face: face,
          faceIndex: index,
          faces: faces,
          assignments: assignments,
          skills: skills,
          unlockedSkillIds: unlockedSkillIds,
          restriction: restrictionOf(index),
          current: assigned,
          onPick: (id) => assignTo(index, id),
          onClear: picked == null ? null : () => clearAt(index),
        );
      } else if (skillId != null) {
        _showSkillDetail(
            context, skillId, skills[skillId] as Map<String, dynamic>?);
      }
    }

    return Column(
      children: [
        // The die as a cube the player turns (v1.241) beside what its picked
        // face does, and the owned dice as small cubes to choose from.
        TutorialTarget(
          id: 'dice.choice',
          child: Column(
            children: [
              if (ally == null && diceIds.length > 1)
                _DieRail(
                  ids: diceIds,
                  selected: _selectedDiceId!,
                  dice: dice,
                  session: session,
                  skills: skills,
                  language: language,
                  onPick: (id) => setState(() => _selectedDiceId = id),
                ),
              _DieStage(
                dieId: _selectedDiceId!,
                language: language,
                faces: faces,
                assignments: limited,
                skills: skills,
                selected: _faceSel.clamp(0, faces.length - 1),
                showOdds: ref.watch(appModeProvider) == AppMode.edit,
                totalWeight: totalWeight,
                still: MediaQuery.of(context).disableAnimations,
                onSelect: (i) => setState(() => _faceSel = i),
                onActivate: pickFace,
                picks: assignments,
                accepts: (i, id) => dropOk(i, id),
                onDrop: (i, id) => assignTo(i, id),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Hold the name for how faces work and the limits (they were
              // two paragraphs here).
              Align(
                alignment: Alignment.centerLeft,
                child: HelpTitle(
                  key: const Key('faces_help'),
                  title: tr(ref, 'skill_faces_title'),
                  help:
                      '${tr(ref, 'drag_skill_hint')}\n\n${tr(ref, 'skill_faces_limit_hint')}',
                ),
              ),
              const SizedBox(height: 8),
              FaceColorLegend(language: language),
              const SizedBox(height: 12),
              TutorialTarget(
                id: 'dice.faces',
                // One slot per face, in a ring as the faces go round the die.
                child: DieSlotRing(
                  count: faces.length,
                  center: _RingCenter(
                    faceCount: faces.length,
                    withSkill: [
                      for (var i = 0; i < faces.length; i++)
                        if (faceSkillId(faces[i], limited[i.toString()]) !=
                            null)
                          i,
                    ].length,
                    language: language,
                  ),
                  slot: (index, side, compact) => Builder(builder: (context) {
                    final face = faces[index];
                    final open = isAssignableFace(face);
                    final pickedSkillId =
                        open ? assignments[index.toString()] : null;
                    final overLimit = pickedSkillId != null &&
                        limited[index.toString()] != pickedSkillId;
                    final assignedSkillId = overLimit ? null : pickedSkillId;
                    // A skill set on the face snaps into place.
                    return SnapIn(
                      snapKey: assignedSkillId ?? '',
                      child: _FaceSlot(
                        key: Key('face_slot_$index'),
                        face: face,
                        chance: totalWeight <= 0
                            ? 0
                            : ((face['weight'] as num?)?.toDouble() ?? 1.0) /
                                totalWeight,
                        showOdds: ref.watch(appModeProvider) == AppMode.edit,
                        picked: index == _faceSel,
                        assignedSkillId: assignedSkillId,
                        overLimitSkillId: overLimit ? pickedSkillId : null,
                        language: language,
                        locked: !open,
                        restrictionElement: restrictionOf(index),
                        skills: skills,
                        accepts: (id) => canSetSkillOnFace(
                            id, index, faces, assignments, skills),
                        onAccept: (id) {
                          setState(() => _faceSel = index);
                          assignTo(index, id);
                        },
                        onClear:
                            pickedSkillId == null ? null : () => clearAt(index),
                        onTap: () => selectFace(index),
                        onPick: open ? () => pickFace(index) : null,
                        compact: compact,
                        side: side,
                      ),
                    );
                  }),
                ),
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
                TutorialTarget(
                  id: 'dice.skills',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: unlockedSkillIds.map((id) {
                      final skill = skills[id] as Map<String, dynamic>?;
                      final onDie =
                          facesCastingSkill(id, faces, assignments, skills);
                      final name = skillDisplayName(id,
                          language: ref.watch(appLanguageProvider));
                      return _SkillChip(
                        skillId: id,
                        label: onDie == 0
                            ? name
                            : '$name · $onDie/${maxFacesForSkill(skill, faceCount: faces.length)}',
                        rarity: skillRarity(skill),
                        kind: skillKind(skill),
                        element: skill?['element']?.toString(),
                        onTap: () => _showSkillDetail(context, id, skill),
                      );
                    }).toList(),
                  ),
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
    required int faceIndex,
    required List<Map<String, dynamic>> faces,
    required Map<String, String> assignments,
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
    // What each skill does to this face is the fight's own rule (Core's
    // faceSkillChoice): the skills at the tier the player fights them at,
    // the damage the party deals. An ally's faces use the player's damage
    // here (the fight's perks and signs are not replayed).
    final session = ref.read(playerSessionProvider);
    final items = ref.read(localizedDbProvider(itemsSchema)).value ?? const {};
    final scaling = equipmentScalingBonusFor(session.equippedItemIds, items,
        strength: session.strength,
        dexterity: session.dexterity,
        constitution: session.constitution,
        intelligence: session.intelligence);
    final baseDamage = session.baseDamage +
        equipmentBonusFor(session.equippedItemIds, items, 'attackDamage') +
        scaling.damageBonus;
    final tiered = <String, dynamic>{
      for (final e in skills.entries)
        e.key: applySkillTier(
            e.value as Map<String, dynamic>, session.skillTiers[e.key] ?? 0),
    };
    final options = [
      for (final id in choices)
        () {
          final skill = skills[id] as Map<String, dynamic>?;
          final rarity = skillRarity(skill);
          final choice = faceSkillChoice(
            faces: faces,
            assignments: assignments,
            faceIndex: faceIndex,
            candidateId: id,
            skills: tiered,
            baseDamage: baseDamage,
          );
          // At its limit a skill can't take one more face; the face's own
          // pick stays choosable.
          final allowed =
              choice.allowed || choice.block == FaceChoiceBlock.alreadyThere;
          return FaceSkillOption(
            id: id,
            name: skillDisplayName(id, language: lang),
            icon: skillKind(skill).icon,
            iconColour: skillKind(skill).color,
            rarityLabel: t(rarity.labelKey),
            rarityColour: rarity.color,
            change: _faceChangeOf(choice, lang),
            limitLine: (allowed
                    ? t('skill_faces_count').replaceAll('{n}',
                        '${choice.usedFaces + (choice.block == FaceChoiceBlock.alreadyThere ? 1 : 0)}')
                    : t('skill_faces_full'))
                .replaceAll('{rarity}', t(rarity.labelKey))
                .replaceAll('{max}', '${choice.maxFaces}'),
            allowed: allowed,
          );
        }(),
    ];
    showFaceSkillSheet(
      context,
      nowLine: t('face_now_line')
          .replaceAll('{n}', '${faceIndex + 1}')
          .replaceAll('{face}', _basicFaceSummary(face, lang)),
      note: basic
          ? t('channeled_face_note').replaceAll(
              '{face}', t(basicFaceLabelKey(face['type']?.toString() ?? '')))
          : null,
      options: options,
      currentId: current,
      onSet: onPick,
      onClear: onClear,
      clearSubtitle: _basicFaceSummary(face, lang),
    );
  }

  void _showSkillDetail(
      BuildContext context, String skillId, Map<String, dynamic>? skill) {
    final lang = ref.read(appLanguageProvider);
    String t(String key) => trFor(lang, key);
    final element = skill?['element']?.toString();
    final cost = (skill?['cost'] as num?)?.toInt() ?? 0;
    final requiredSkillId = skill?['requiredSkillID']?.toString() ?? '';
    final rarity = skillRarity(skill);

    showDetailDialog(
      context,
      title: skillDisplayName(skillId, language: ref.read(appLanguageProvider)),
      description: skill?['description']?.toString() ?? '',
      icon: elementIcon(element),
      closeLabel: t('close_button'),
      rows: [
        MapEntry(t('element_label'), element ?? t('none_label')),
        MapEntry(
            t('skill_rarity_label'),
            t('skill_max_faces')
                .replaceAll('{rarity}', t(rarity.labelKey))
                .replaceAll('{max}', '${maxFacesForSkill(skill)}')),
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

/// "Attack 7", "Mana +2", "Attack 5 · Heal 3": what a face does when it
/// lands, in words.
String _outputText(FaceOutput o, AppLanguage lang) {
  String t(String key) => trFor(lang, key);
  final parts = [
    if (o.damage > 0) '${t('face_attack_label')} ${o.damage}',
    if (o.heal > 0) '${t('face_heal_label')} ${o.heal}',
    if (o.block > 0) '${t('face_guard_label')} ${o.block}',
    if (o.mana > 0) '${t('face_mana_label')} +${o.mana}',
    if (o.status != null) o.status!,
  ];
  return parts.isEmpty ? t('miss_label') : parts.join(' · ');
}

/// [choice] (Core's compare of a face with and without a skill) as the
/// sheet's before → after: a change of kind when the face stops doing what
/// it did (an attack that gives mana, say), else a gain or a loss in what
/// it does.
FaceChange _faceChangeOf(FaceSkillChoice choice, AppLanguage lang) {
  Set<String> shape(FaceOutput o) => {
        if (o.damage > 0) 'damage',
        if (o.heal > 0) 'heal',
        if (o.block > 0) 'block',
        if (o.mana > 0) 'mana',
        if (o.status != null) 'status',
      };
  int total(FaceOutput o) => o.damage + o.heal + o.block + o.mana;
  final b = choice.before, a = choice.after;
  final sameShape =
      shape(b).length == shape(a).length && shape(b).containsAll(shape(a));
  final kind = !sameShape
      ? FaceChangeKind.kind
      : switch (choice.effect) {
          FaceChoiceEffect.gain => FaceChangeKind.gain,
          FaceChoiceEffect.loss => FaceChangeKind.loss,
          FaceChoiceEffect.same => FaceChangeKind.same,
        };
  return FaceChange(
    before: _outputText(b, lang),
    after: _outputText(a, lang),
    kind: kind,
    delta: kind == FaceChangeKind.gain || kind == FaceChangeKind.loss
        ? total(a) - total(b)
        : null,
  );
}

/// "+6 dmg ×1.4 · Fire" -- a skill's numbers in one line.
String _skillSummary(Map<String, dynamic>? skill, AppLanguage lang) {
  final damageMod = (skill?['damageMod'] as num?)?.toInt() ?? 0;
  final multiplier = (skill?['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  final heal = (skill?['healAmount'] as num?)?.toInt() ?? 0;
  final element = skill?['element']?.toString() ?? 'None';
  final status = skill?['inflictsStatus']?.toString() ?? '';
  final manaGain = (skill?['manaGain'] as num?)?.toInt() ?? 0;
  return [
    if (manaGain > 0)
      '${trFor(lang, 'mana_label')} +$manaGain'
    else if (damageMod > 0 || multiplier != 1.0)
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
    required this.kind,
    required this.rarity,
    this.element,
    this.onTap,
  });

  final String skillId;
  final String label;

  /// How rare the skill is: the chip's outline.
  final SkillRarity rarity;

  /// What the skill does, for its colour (see FaceKind).
  final FaceKind kind;
  final String? element;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(kind.icon, size: 18, color: kind.color),
        label: Text(label),
        backgroundColor: kind.color.withValues(alpha: 0.12),
        side: BorderSide(color: rarity.color, width: 1.5),
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

/// One face of the die as a square of a fixed size (v1.242), so a long name
/// or a long line of text never stretches or crowds it: the skill's icon (or
/// the face's own), its name on two lines at most, a mark for what can be done
/// with it. What it does, in full, is told beside the cube. A tap picks the
/// face (the cube turns to it); a double tap, or its pencil, chooses its
/// skill; a skill chip dragged onto it goes on it.
/// The middle of the ring: the die's size ("d8") and how many of its faces
/// hold a skill.
class _RingCenter extends StatelessWidget {
  const _RingCenter({
    required this.faceCount,
    required this.withSkill,
    required this.language,
  });

  final int faceCount;
  final int withSkill;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('die_ring_center'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('d$faceCount',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, height: 1)),
        const SizedBox(height: 4),
        Text(
          trFor(language, 'die_ring_skill_faces')
              .replaceAll('{n}', '$withSkill')
              .replaceAll('{max}', '$faceCount'),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FaceSlot extends StatelessWidget {
  const _FaceSlot({
    super.key,
    required this.face,
    required this.chance,
    required this.showOdds,
    required this.picked,
    required this.assignedSkillId,
    required this.language,
    required this.onAccept,
    required this.onClear,
    required this.locked,
    required this.skills,
    required this.accepts,
    this.overLimitSkillId,
    this.restrictionElement,
    this.onTap,
    this.onPick,
    this.compact = false,
    this.side = ringSlotMax,
  });

  final Map<String, dynamic> face;
  final double chance;

  /// A small slot (a d12 or a d20 on a phone): no name, a smaller icon. The
  /// die card above names the picked face.
  final bool compact;

  /// How wide the slot is: what it shows keeps inside its circle.
  final double side;

  /// Whether its odds are told: in Edit Mode only (v1.241); a player rolls
  /// the die without being shown the numbers.
  final bool showOdds;

  /// The face the die on the screen is turned to.
  final bool picked;
  final String? assignedSkillId;

  /// A pick past its skill's limit (a save from before the limits): marked,
  /// and the face does its own action.
  final String? overLimitSkillId;

  /// Whether a dragged skill may go on this face (its rarity's limit).
  final bool Function(String skillId) accepts;
  final AppLanguage language;
  final ValueChanged<String> onAccept;
  final VoidCallback? onClear;
  final bool locked;
  final Map<String, dynamic> skills;

  /// When set, only skills whose own `element` matches this may be dropped.
  final String? restrictionElement;

  /// A tap: the face becomes the picked one.
  final VoidCallback? onTap;

  /// A double tap, or the pencil: choose its skill.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final name = faceDisplayName(face,
        assignedSkillId: assignedSkillId, language: language);
    final skillId = faceSkillId(face, assignedSkillId);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // The face wears the colour of what it does (see FaceKind): red hits,
    // steel guards, pink heals, blue mana, status colours for poison,
    // stun and weaken.
    final kind = skillId == null
        ? faceKind(face['type']?.toString() ?? '')
        : skillKind(skills[skillId] as Map<String, dynamic>?);
    final value = (face['value'] as num?)?.toInt() ?? 0;

    Widget content(bool isHovering, bool isInvalidHover) {
      final border = isInvalidHover
          ? colorScheme.error
          : (isHovering || picked
              ? colorScheme.primary
              : kind.color.withValues(alpha: locked ? 0.45 : 0.9));
      return GestureDetector(
        onTap: onTap,
        onDoubleTap: onPick,
        // A round token on the die's ring; what it shows sits in the square
        // the circle holds.
        child: Container(
          padding: EdgeInsets.all(compact ? side * 0.12 : side * 0.15),
          decoration: BoxDecoration(
            color: isInvalidHover
                ? colorScheme.errorContainer
                : (isHovering
                    ? colorScheme.primaryContainer
                    : kind.color.withValues(alpha: locked ? 0.08 : 0.14)),
            shape: BoxShape.circle,
            border: Border.all(
              color: border,
              width: (isHovering || isInvalidHover || picked) ? 2.4 : 1,
            ),
          ),
          child: Stack(
            children: [
              // The face: its skill's icon, or its own kind over its value.
              Align(
                alignment:
                    compact ? Alignment.center : const Alignment(0, -0.35),
                child: skillId != null
                    ? SkillPixelIcon(skillId, size: compact ? 24 : 34)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(kind.icon,
                              size: compact
                                  ? (value > 0 ? 16 : 22)
                                  : (value > 0 ? 22 : 30),
                              color: kind.color),
                          if (value > 0)
                            Text('$value',
                                style: textTheme.titleSmall?.copyWith(
                                    color: kind.color,
                                    fontWeight: FontWeight.bold,
                                    height: 1)),
                        ],
                      ),
              ),
              // Its name, on one line.
              if (!compact)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(height: 1.1),
                  ),
                ),
              // What can be done: a lock for a fixed face, a cross to clear
              // a skill, a pencil to choose one (on a small slot, the die
              // card's button chooses).
              Align(
                alignment: Alignment.topRight,
                child: locked
                    ? Icon(Icons.lock_outline,
                        size: compact ? 11 : 15, color: colorScheme.outline)
                    : compact
                        ? const SizedBox.shrink()
                        : onClear != null
                            ? InkResponse(
                                onTap: onClear,
                                radius: 16,
                                child: Tooltip(
                                  message: trFor(
                                      language, 'clear_assigned_skill_tooltip'),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              )
                            : InkResponse(
                                onTap: onPick,
                                radius: 16,
                                child: Icon(Icons.edit_outlined,
                                    size: 16, color: colorScheme.primary),
                              ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: overLimitSkillId != null
                    ? Tooltip(
                        message:
                            '${skillDisplayName(overLimitSkillId!, language: language)}: '
                            '${trFor(language, 'face_over_limit_label')}',
                        child: Icon(Icons.warning_amber_rounded,
                            size: compact ? 11 : 16, color: colorScheme.error),
                      )
                    : showOdds && !compact
                        ? Text('${(chance * 100).round()}%',
                            style: textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant))
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    if (locked) return content(false, false);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (!accepts(details.data)) return false;
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

/// A face of a die as a side of its cube: a skill on it as its own pixel icon
/// on a pale plaque ringed in what the skill does (the way the fight draws a
/// skill face), any other face its type's icon over its value.
DieCubeFace _cubeSide(Map<String, dynamic> face, String? assigned,
    Map<String, dynamic> skills, double size) {
  final skillId = faceSkillId(face, assigned);
  final skill =
      skillId == null ? null : skills[skillId] as Map<String, dynamic>?;
  final kind = skillId == null
      ? faceKind(face['type']?.toString() ?? '')
      : skillKind(skill);
  if (skillId != null) {
    return DieCubeFace(
      color: kind.color,
      glyph: Container(
        width: size * 0.72,
        height: size * 0.72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEFE6D2).withValues(alpha: 0.92),
          border: Border.all(color: kind.color, width: size * 0.04 + 0.6),
        ),
        child: SkillPixelIcon(skillId, size: size * 0.55),
      ),
    );
  }
  final value = (face['value'] as num?)?.toInt() ?? 0;
  return DieCubeFace(
    color: kind.color,
    glyph: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(kind.icon,
            size: value > 0 ? size * 0.4 : size * 0.52, color: kind.color),
        if (value > 0)
          Text('$value',
              style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  color: kind.color)),
      ],
    ),
  );
}

/// The six sides of a die: its faces from [first], repeated when it has fewer
/// than six.
List<DieCubeFace> _cubeSides(List<Map<String, dynamic>> faces,
    Map<String, String> assignments, Map<String, dynamic> skills, double size,
    {int first = 0}) {
  return [
    for (var slot = 0; slot < 6; slot++)
      () {
        final index = faces.length >= 6 ? first + slot : slot % faces.length;
        return _cubeSide(
            faces[index], assignments[index.toString()], skills, size);
      }(),
  ];
}

/// The dice a player owns, as small cubes to pick from.
class _DieRail extends StatelessWidget {
  const _DieRail({
    required this.ids,
    required this.selected,
    required this.dice,
    required this.session,
    required this.skills,
    required this.language,
    required this.onPick,
  });

  final List<String> ids;
  final String selected;
  final Map<String, dynamic> dice;
  final PlayerSession session;
  final Map<String, dynamic> skills;
  final AppLanguage language;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                key: Key('die_pick_$id'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => onPick(id),
                child: Container(
                  width: 72,
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: id == selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: id == selected ? 2 : 1),
                    color: id == selected
                        ? scheme.primary.withValues(alpha: 0.10)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Die3D(
                          faces: _cubeSides(
                              smithedFaces(
                                  (dice[id]['faces'] as List)
                                      .cast<Map<String, dynamic>>(),
                                  session.upgradesOfDie(id)),
                              session.diceSkillAssignments[id] ??
                                  const <String, String>{},
                              skills,
                              26),
                          accent: dieSkinOf(id).edge,
                          size: 26,
                          still: true,
                          skin: dieSkinOf(id),
                        ),
                      ),
                      Text(
                        dieDisplayName(id, language: language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The die the player is setting, as a cube to turn, beside the face it
/// stands on. A skill chip dragged onto the cube goes on that face.
/// The height of the die card at the top of the loadout: the cube's 150 px
/// and a little air, whatever the picked face has to say.
const double _stageCardHeight = 176;

class _DieStage extends StatelessWidget {
  const _DieStage({
    required this.dieId,
    required this.language,
    required this.faces,
    required this.assignments,
    required this.picks,
    required this.skills,
    required this.selected,
    required this.showOdds,
    required this.totalWeight,
    required this.still,
    required this.onSelect,
    required this.onActivate,
    required this.accepts,
    required this.onDrop,
  });

  final String dieId;
  final AppLanguage language;
  final List<Map<String, dynamic>> faces;
  final Map<String, String> assignments;

  /// What the player picked for each face, before the skill limits.
  final Map<String, String> picks;
  final Map<String, dynamic> skills;

  /// The face index the die is turned to.
  final int selected;
  final bool showOdds;
  final double totalWeight;
  final bool still;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onActivate;
  final bool Function(int index, String skillId) accepts;
  final void Function(int index, String skillId) onDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = faces.length;
    // A die of seven faces shows six at a time: the window slides to keep the
    // picked one on the cube.
    final first = n > 6 ? (selected - 5).clamp(0, n - 6) : 0;
    int slotOf(int index) => n >= 6 ? (index - first).clamp(0, 5) : index;
    int indexOf(int slot) => n >= 6 ? first + slot : slot % n;
    final face = faces[selected];
    final assigned = assignments[selected.toString()];
    final skillId = faceSkillId(face, assigned);
    final name =
        faceDisplayName(face, assignedSkillId: assigned, language: language);
    final open = isAssignableFace(face);
    final picked = open ? picks[selected.toString()] : null;
    final overSkill = picked != null && assigned != picked ? picked : null;
    final element = face['element']?.toString() ?? 'None';
    final restriction =
        face['type'] == 'Skill' && !isSignatureFace(face) && element != 'None'
            ? element
            : null;
    String t(String key) => trFor(language, key);
    final weight = (face['weight'] as num?)?.toDouble() ?? 1.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
        // One height for every face: the card used to grow and shrink as the
        // picked face changed, pushing the squares below up and down. The
        // text scrolls inside it when a face has more to say.
        child: SizedBox(
          height: _stageCardHeight,
          child: Row(
            children: [
              DragTarget<String>(
                onWillAcceptWithDetails: (d) => accepts(selected, d.data),
                onAcceptWithDetails: (d) => onDrop(selected, d.data),
                builder: (context, candidate, rejected) => SizedBox(
                  width: 150,
                  height: 150,
                  child: Center(
                    child: InteractiveDie(
                      size: 78,
                      still: still,
                      skin: dieSkinOf(dieId),
                      faces: _cubeSides(faces, assignments, skills, 78,
                          first: first),
                      selected: slotOf(selected),
                      onSelect: (slot) => onSelect(indexOf(slot)),
                      onActivate: (slot) => onActivate(indexOf(slot)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('die_stage_text'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dieDisplayName(dieId, language: language),
                                style: theme.textTheme.titleMedium),
                            Text(dieSkinOf(dieId).material,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(name,
                                key: const Key('die_face_name'),
                                style: theme.textTheme.titleSmall),
                            Text(
                              skillId == null
                                  ? _basicFaceSummary(face, language)
                                  : _skillSummary(
                                      skills[skillId] as Map<String, dynamic>?,
                                      language),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (showOdds && totalWeight > 0)
                              Text(
                                '${(weight / totalWeight * 100).round()}% ${t('face_chance_suffix')}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            // Its rule words, named in full (a tap on a badge used to).
                            for (final k in faceKeywordsOf(face))
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                        text: '${t(keywordLabelKey(k))}: ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    TextSpan(text: t(keywordDescriptionKey(k))),
                                  ]),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            // What kind of face it is, in full: this panel grows with
                            // the text, so the squares below never have to.
                            if (!open)
                              Text(t('fixed_face_label'),
                                  style: theme.textTheme.labelSmall)
                            else if (assigned != null && isBasicFace(face))
                              Text(
                                t('channeled_face_badge').replaceAll(
                                    '{face}',
                                    t(basicFaceLabelKey(
                                        face['type']?.toString() ?? ''))),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.tertiary),
                              )
                            else if (assigned != null)
                              Text(t('custom_label'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.tertiary)),
                            if (overSkill != null)
                              Text(
                                '${skillDisplayName(overSkill, language: language)}: '
                                '${t('face_over_limit_label')}',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                            if (open && restriction != null)
                              Text('$restriction ${t('only_suffix')}',
                                  style: theme.textTheme.labelSmall),
                            const SizedBox(height: 6),
                            Text(
                              open
                                  ? t('die_turn_hint_open')
                                  : t('die_turn_hint'),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Always in sight, under the text that scrolls.
                    if (open)
                      TextButton.icon(
                        key: const Key('die_pick_skill'),
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft),
                        onPressed: () => onActivate(selected),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(t('pick_face_skill_title')),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
