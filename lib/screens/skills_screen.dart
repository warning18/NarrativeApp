import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../combat/dice_faces.dart';
import '../data/skill_access.dart';
import '../data/skill_tree.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/face_style.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../utils/spell_preview.dart';
import '../widgets/compare_dialog.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/mana_meter.dart';
import '../widgets/merge_skills_dialog.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key, this.allyId});

  /// When set, this screen manages the named companion's learnable-skill
  /// pool instead of the player's own — same screen, pointed at that
  /// companion's own race/profession restrictions and [AllyState] instead
  /// of [PlayerSession] directly.
  final String? allyId;

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  bool _compareMode = false;
  String? _firstCompareId;

  /// The player's skills as a tree (their branches) or as a list with
  /// filters.
  bool _treeView = true;
  _KindFilter _kindFilter = _KindFilter.all;
  _StateFilter _stateFilter = _StateFilter.all;

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _firstCompareId = null;
    });
  }

  void _onCompareTap(
      BuildContext context, Map<String, dynamic> records, String skillId) {
    if (_firstCompareId == null) {
      setState(() => _firstCompareId = skillId);
      return;
    }
    if (_firstCompareId == skillId) return;
    final firstId = _firstCompareId!;
    final skillA = records[firstId] as Map<String, dynamic>?;
    final skillB = records[skillId] as Map<String, dynamic>?;
    final lang = ref.read(appLanguageProvider);
    num v(Map<String, dynamic>? skill, String key) =>
        (skill?[key] as num?) ?? 0;
    showCompareDialog(
      context,
      titleA: firstId,
      titleB: skillId,
      closeLabel: trFor(lang, 'close_button'),
      rows: [
        CompareRow(
          label: trFor(lang, 'cost_label'),
          valueA: v(skillA, 'cost'),
          valueB: v(skillB, 'cost'),
          higherIsBetter: false,
        ),
        CompareRow(
          label: trFor(lang, 'damage_mod_label'),
          valueA: v(skillA, 'damageMod'),
          valueB: v(skillB, 'damageMod'),
        ),
        CompareRow(
          label: trFor(lang, 'damage_multiplier_label'),
          valueA: v(skillA, 'damageMultiplier'),
          valueB: v(skillB, 'damageMultiplier'),
        ),
        CompareRow(
          label: trFor(lang, 'heal_amount'),
          valueA: v(skillA, 'healAmount'),
          valueB: v(skillB, 'healAmount'),
        ),
      ],
    );
    setState(() {
      _compareMode = false;
      _firstCompareId = null;
    });
  }

  /// The Spells section under the player's skills (tree or list): the
  /// mana pool,
  /// then one card per spell the profession can ever cast -- known ones
  /// first with the numbers they would land right now, the rest greyed out
  /// with the shop that sells their spellbook.
  List<Widget> _buildSpellSection(
    PlayerSession session,
    Map<String, SpellSpec> spells,
    Map<String, dynamic> items,
    Map<String, dynamic> shops,
  ) {
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final list = spellsForProfession(
        spells, session.professionId, session.knownSpellIds);
    return [
      Row(
        children: [
          Expanded(
            child: Text(tr(ref, 'spells_label'),
                style: theme.textTheme.titleMedium),
          ),
          const Icon(manaIcon, size: 18, color: manaColor),
          const SizedBox(width: 4),
          Text(
            '${session.mana}/${session.maxMana}',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: manaColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          ManaMeter(mana: session.mana, maxMana: session.maxMana),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '${tr(ref, 'mana_pool_desc')} ${tr(ref, 'mana_faces_note')} '
        '${tr(ref, 'cast_in_battle_hint')}',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      Text(
        tr(ref, 'wisdom_mana_bonus_line')
            .replaceAll('{n}', '${wisdomManaBonusFor(session.wisdom)}')
            .replaceAll('{wis}', '${session.wisdom}'),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: manaColor, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      if (list.isEmpty)
        Card(
          child: ListTile(
            leading: const Icon(manaIcon, color: manaColor),
            title: Text(tr(ref, 'no_spells_hint')),
          ),
        ),
      for (final spell in list)
        _buildSpellCard(spell, session, items, shops, lang),
    ];
  }

  Widget _buildSpellCard(
    SpellSpec spell,
    PlayerSession session,
    Map<String, dynamic> items,
    Map<String, dynamic> shops,
    AppLanguage lang,
  ) {
    final known = session.knownSpellIds.contains(spell.id);
    final preview = previewSpellFor(spell, session, items);
    final color = spellEffectColor(spell.effect);
    final shopNames = spellbookShopsFor(spell.id, items, shops)
        .map((id) =>
            (shops[id] as Map<String, dynamic>?)?['shopName']?.toString() ?? id)
        .join(', ');
    final whereLine = known
        ? null
        : shopNames.isEmpty
            ? tr(ref, 'spellbook_not_sold')
            : '${tr(ref, 'spellbook_sold_at_prefix')} $shopNames';
    final status = preview.status;
    final statusLine = status == null
        ? null
        : switch (status.type) {
            StatusEffectType.poison =>
              '${tr(ref, 'status_poison_label')} ${status.magnitude} x ${status.remainingTurns}',
            StatusEffectType.stun =>
              '${tr(ref, 'status_stun_label')} ${status.remainingTurns}',
            StatusEffectType.weaken =>
              '${tr(ref, 'status_weaken_label')} ${status.magnitude}% x ${status.remainingTurns}',
          };
    final numbers = [
      '${spell.manaCost} ${tr(ref, 'mana_label')}',
      '${tr(ref, spellEffectLabelKey(spell.effect))}'
          '${preview.amount > 0 ? ' ${preview.amount}' : ''}',
      tr(ref, spellTargetLabelKey(spell.target)),
      if (spell.element != 'None') spell.element,
      if (statusLine != null) statusLine,
    ].join(' · ');
    final name = spell.nameFor(lang);
    final description = spell.descriptionFor(lang);
    final leading = CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(spellEffectIcon(spell.effect), color: color),
    );
    return Opacity(
      opacity: known ? 1 : 0.6,
      child: Card(
        child: ListTile(
          leading: leading,
          title: Text(name),
          subtitle: Text([
            description,
            numbers,
            if (whereLine != null) whereLine,
          ].join('\n')),
          isThreeLine: true,
          trailing: known
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.lock_outline),
          onTap: () => showDetailDialog(
            context,
            title: name,
            description: description,
            leading:
                Icon(spellEffectIcon(spell.effect), color: color, size: 24),
            closeLabel: tr(ref, 'close_button'),
            rows: [
              MapEntry(tr(ref, 'cost_label'),
                  '${spell.manaCost} ${tr(ref, 'mana_label')}'),
              MapEntry(tr(ref, 'effect_label'),
                  tr(ref, spellEffectLabelKey(spell.effect))),
              if (preview.amount > 0)
                MapEntry(tr(ref, 'right_now_label'), '${preview.amount}'),
              MapEntry(tr(ref, 'target_label'),
                  tr(ref, spellTargetLabelKey(spell.target))),
              MapEntry(
                  tr(ref, 'element_label'),
                  spell.element == 'None'
                      ? tr(ref, 'none_label')
                      : spell.element),
              if (statusLine != null)
                MapEntry(tr(ref, 'status_label'), statusLine),
              MapEntry(
                tr(ref, 'status_label'),
                known ? tr(ref, 'known_label') : tr(ref, 'not_learned_label'),
              ),
              if (whereLine != null)
                MapEntry(
                    tr(ref, 'where_to_learn_label'),
                    shopNames.isEmpty
                        ? tr(ref, 'spellbook_not_sold')
                        : shopNames),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(localizedDbProvider(skillsSchema));
    final racesAsync = ref.watch(localizedDbProvider(racesSchema));
    final professionsAsync = ref.watch(localizedDbProvider(professionsSchema));
    final treesAsync = ref.watch(localizedDbProvider(skillTreesSchema));
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    final merges =
        ref.watch(localizedDbProvider(skillMergesSchema)).value ?? const {};
    final session = ref.watch(playerSessionProvider);
    final isPlayer = widget.allyId == null;
    // Spells are the player's alone (companions cast nothing), so the
    // Spells section only ever heads the player's own list.
    final spellSection = isPlayer
        ? _buildSpellSection(
            session,
            parseSpells(
                ref.watch(localizedDbProvider(spellsSchema)).value ?? const {}),
            ref.watch(localizedDbProvider(itemsSchema)).value ?? const {},
            ref.watch(localizedDbProvider(shopsSchema)).value ?? const {},
          )
        : const <Widget>[];

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

    final raceId = ally != null
        ? (companion?['raceId']?.toString() ?? '')
        : session.raceId;
    final professionId = ally != null
        ? (companion?['professionId']?.toString() ?? '')
        : session.professionId;
    final skillPoints = ally?.skillPoints ?? session.skillPoints;
    final unlockedSkillIds = ally?.unlockedSkillIds ?? session.unlockedSkillIds;
    final titleSuffix = widget.allyId != null
        ? ' — ${companion?['companionName']?.toString() ?? widget.allyId}'
        : '';
    final theme = Theme.of(context);

    Widget content(Map<String, dynamic> records) {
      final known = <String>{
        ...unlockedSkillIds,
        for (final entry in records.entries)
          if ((entry.value as Map<String, dynamic>)['isUnlocked'] == true)
            entry.key,
      };
      // The player's skills cost their place on their branch (the deeper
      // the dearer); a companion's, one point each.
      int pointCost(String id) => ally != null
          ? 1
          : skillPointCostOf(
              id,
              skillBranchesFor(treesAsync.value ?? const {},
                  raceId: raceId, professionId: professionId));
      void unlock(String id) => ally != null
          ? ref
              .read(playerSessionProvider.notifier)
              .unlockAllySkill(widget.allyId!, id)
          : ref
              .read(playerSessionProvider.notifier)
              .unlockSkill(id, cost: pointCost(id));

      if (ally != null) {
        // A companion keeps it simple: their own class's skills, in any
        // order, one point each (see allySkillIds).
        final keys = allySkillIds(records,
            professionId: professionId, known: unlockedSkillIds)
          ..sort((a, b) {
            final k = (known.contains(a) ? 0 : 1) - (known.contains(b) ? 0 : 1);
            return k != 0 ? k : a.compareTo(b);
          });
        return _SkillList(
          records: records,
          keys: keys,
          known: known,
          races: racesAsync.value ?? const {},
          professions: professionsAsync.value ?? const {},
          alignmentScore: session.alignmentScore,
          skillPoints: skillPoints,
          unlockedSkillIds: unlockedSkillIds,
          canLearn: (id) => !known.contains(id),
          lockNote: (_) => null,
          onUnlock: unlock,
          compareMode: _compareMode,
          firstCompareId: _firstCompareId,
          onCompareTap: (id) => _onCompareTap(context, records, id),
          leadingChildren: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tr(ref, 'ally_skills_note').replaceAll(
                    '{class}',
                    ((professionsAsync.value ?? const {})[professionId]
                                as Map<String, dynamic>?)?['professionName']
                            ?.toString() ??
                        professionId),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        );
      }

      final branches = skillBranchesFor(treesAsync.value ?? const {},
          raceId: raceId, professionId: professionId);
      bool canLearn(String id) => canLearnWithPoints(id,
          branches: branches,
          known: known,
          skills: records,
          alignmentScore: session.alignmentScore);
      String? lockNote(String id) {
        final place = branchPlaceOf(id, branches);
        if (place == null || place.index == 0 || known.contains(id)) {
          return null;
        }
        final before = place.branch.skillIds[place.index - 1];
        if (known.contains(before)) return null;
        return tr(ref, 'skill_after_label').replaceAll('{skill}',
            skillDisplayName(before, language: ref.read(appLanguageProvider)));
      }

      if (_treeView) {
        return _SkillTreeView(
          records: records,
          branches: branches,
          known: known,
          skillPoints: skillPoints,
          masteredBranchId: session.masteredBranchId,
          skillTiers: session.skillTiers,
          skillEssence: session.skillEssence,
          canLearn: canLearn,
          pointCost: pointCost,
          onUnlock: unlock,
          trailingChildren: spellSection,
        );
      }

      // The list: the tree's skills, what the character already knows,
      // the skills their reputation opens and the ones only a recipe
      // gives -- filtered by what they do and whether they are known.
      final onTree = {for (final b in branches) ...b.skillIds};
      final listed = <String>{
        ...onTree,
        for (final id in known)
          if (records[id] is Map<String, dynamic> &&
              !isEnemyOnlySkill(records[id] as Map<String, dynamic>))
            id,
        for (final id in skillIdsForCharacter(records, merges,
            raceId: raceId, professionId: professionId))
          if (isReputationSkill(records[id] as Map<String, dynamic>?) ||
              (records[id] as Map<String, dynamic>)['unlockedViaMergeOnly'] ==
                  true)
            id,
      };
      bool passes(String id) {
        final skill = records[id] as Map<String, dynamic>?;
        final kind = skillKind(skill);
        final kindOk = switch (_kindFilter) {
          _KindFilter.all => true,
          _KindFilter.attack => kind == FaceKind.attack,
          _KindFilter.heal => kind == FaceKind.heal,
          _KindFilter.mana => kind == FaceKind.mana,
          _KindFilter.status => kind == FaceKind.poison ||
              kind == FaceKind.stun ||
              kind == FaceKind.weaken,
        };
        final stateOk = switch (_stateFilter) {
          _StateFilter.all => true,
          _StateFilter.known => known.contains(id),
          _StateFilter.learnable => canLearn(id),
        };
        return kindOk && stateOk;
      }

      final keys = listed.where(passes).toList()
        ..sort((a, b) {
          final k = (known.contains(a) ? 0 : 1) - (known.contains(b) ? 0 : 1);
          return k != 0 ? k : a.compareTo(b);
        });
      return _SkillList(
        records: records,
        keys: keys,
        known: known,
        races: racesAsync.value ?? const {},
        professions: professionsAsync.value ?? const {},
        alignmentScore: session.alignmentScore,
        skillPoints: skillPoints,
        unlockedSkillIds: unlockedSkillIds,
        canLearn: canLearn,
        lockNote: lockNote,
        pointCost: pointCost,
        onUnlock: unlock,
        skillEssence: session.skillEssence,
        skillTiers: effectiveSkillTiers(session.skillTiers,
            treesAsync.value ?? const {}, session.masteredBranchId),
        onUpgradeTier: (id) =>
            ref.read(playerSessionProvider.notifier).upgradeSkillTier(id),
        compareMode: _compareMode,
        firstCompareId: _firstCompareId,
        onCompareTap: (id) => _onCompareTap(context, records, id),
        leadingChildren: [_buildFilters()],
        trailingChildren: spellSection,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'skills')}$titleSuffix'),
        actions: [
          if (isPlayer)
            TutorialTarget(
              id: 'skills.craft',
              child: IconButton(
                icon: const Icon(Icons.auto_fix_high),
                tooltip: tr(ref, 'craft_skill_button'),
                onPressed: () => showMergeSkillsDialog(
                  context,
                  ref,
                  skills: skillsAsync.value ?? const {},
                  merges: merges,
                  unlockedSkillIds: session.unlockedSkillIds,
                ),
              ),
            ),
          if (!isPlayer || !_treeView)
            TutorialTarget(
              id: 'skills.compare',
              child: IconButton(
                icon: Icon(_compareMode
                    ? Icons.compare_arrows
                    : Icons.compare_arrows_outlined),
                tooltip: tr(ref, 'compare_button'),
                onPressed: _toggleCompareMode,
              ),
            ),
        ],
      ),
      body: TutorialTrigger(
        topic: TutorialTopic.skills,
        child: Column(
          children: [
            TutorialTarget(
              id: 'skills.points',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                // Wraps, so both counts fit a phone in French too.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${tr(ref, 'skill_points_label')}: $skillPoints',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (isPlayer)
                      Text(
                        '${tr(ref, 'skill_essence_label')}: ${session.skillEssence}',
                        style: theme.textTheme.titleMedium,
                      ),
                  ],
                ),
              ),
            ),
            if (isPlayer)
              TutorialTarget(
                id: 'skills.views',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.account_tree_outlined),
                        label: Text(tr(ref, 'skill_tree_view')),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.filter_list),
                        label: Text(tr(ref, 'skill_list_view')),
                      ),
                    ],
                    selected: {_treeView},
                    onSelectionChanged: (selection) => setState(() {
                      _treeView = selection.first;
                      _compareMode = false;
                      _firstCompareId = null;
                    }),
                  ),
                ),
              ),
            if (_compareMode)
              Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _firstCompareId == null
                      ? tr(ref, 'compare_hint_skills')
                      : tr(ref, 'compare_first_selected'),
                ),
              ),
            Expanded(
              child: TutorialTarget(
                id: 'skills.list',
                child: skillsAsync.when(
                  data: (records) => records.isEmpty
                      ? Center(child: Text(tr(ref, 'no_skills_defined')))
                      : content(records),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                      child:
                          Text('${tr(ref, 'failed_to_load_skills')}: $error')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the list shows: skills by what they do, and by whether they are
  /// known or can be learned now.
  Widget _buildFilters() {
    ChoiceChip chip<T>(T value, T selected, String label, IconData? icon,
            Color? color, void Function(T) onPick) =>
        ChoiceChip(
          key: Key('skill_filter_$value'),
          avatar: icon == null ? null : Icon(icon, size: 16, color: color),
          label: Text(label),
          selected: value == selected,
          onSelected: (_) => setState(() => onPick(value)),
          visualDensity: VisualDensity.compact,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (value, key, kind) in [
                (_KindFilter.all, 'skill_filter_all', null),
                (_KindFilter.attack, 'filter_attack', FaceKind.attack),
                (_KindFilter.heal, 'filter_heal', FaceKind.heal),
                (_KindFilter.mana, 'filter_mana', FaceKind.mana),
                (_KindFilter.status, 'filter_status', FaceKind.poison),
              ])
                chip<_KindFilter>(value, _kindFilter, tr(ref, key), kind?.icon,
                    kind?.color, (v) => _kindFilter = v),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (value, key) in [
                (_StateFilter.all, 'skill_filter_all'),
                (_StateFilter.known, 'filter_known'),
                (_StateFilter.learnable, 'filter_learnable'),
              ])
                chip<_StateFilter>(value, _stateFilter, tr(ref, key), null,
                    null, (v) => _stateFilter = v),
            ],
          ),
        ],
      ),
    );
  }
}

enum _KindFilter { all, attack, heal, mana, status }

enum _StateFilter { all, known, learnable }

class _SkillList extends ConsumerWidget {
  const _SkillList({
    required this.records,
    required this.keys,
    required this.known,
    required this.races,
    required this.professions,
    required this.alignmentScore,
    required this.skillPoints,
    required this.unlockedSkillIds,
    required this.canLearn,
    required this.lockNote,
    required this.onUnlock,
    this.pointCost,
    this.skillEssence,
    this.skillTiers,
    this.onUpgradeTier,
    required this.compareMode,
    required this.firstCompareId,
    required this.onCompareTap,
    this.leadingChildren = const [],
    this.trailingChildren = const [],
  });

  /// Widgets that head the list before the skill cards -- the player's
  /// filters, or a companion's note.
  final List<Widget> leadingChildren;

  /// Under the skill cards: the player's Spells section.
  final List<Widget> trailingChildren;

  final Map<String, dynamic> records;

  /// The skills shown, in order.
  final List<String> keys;

  /// What the character knows (learned, or everyone's from the start).
  final Set<String> known;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;

  /// Always the player's own alignment, even when browsing a companion's
  /// skill list — allies don't track a separate alignment.
  final int alignmentScore;
  final int skillPoints;
  final List<String> unlockedSkillIds;

  /// Whether a point can go on the skill now (the next on its branch, a
  /// reputation skill the character's standing allows, a companion's own
  /// class skill).
  final bool Function(String id) canLearn;

  /// Why a skill of the tree waits ("After Power Strike"), or null.
  final String? Function(String id) lockNote;
  final ValueChanged<String> onUnlock;

  /// Skill points a skill costs to learn (its place on its branch); one
  /// when null (a companion's).
  final int Function(String id)? pointCost;

  /// Non-null only for the player's own list (never a companion's) — see
  /// [PlayerSession.skillEssence]/[PlayerSession.skillTiers]. Null suppresses
  /// the tier/upgrade UI entirely.
  final int? skillEssence;
  final Map<String, int>? skillTiers;
  final ValueChanged<String>? onUpgradeTier;

  final bool compareMode;
  final String? firstCompareId;
  final ValueChanged<String> onCompareTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String reputationLabel(Map<String, dynamic> skill) {
      final min = (skill['requiredAlignmentMin'] as num?)?.toInt();
      final max = (skill['requiredAlignmentMax'] as num?)?.toInt();
      if (min == null && max == null) return '';
      return '${tr(ref, 'reserved_prefix')}: '
          '${min != null ? tr(ref, 'good_aligned_label') : tr(ref, 'evil_aligned_label')}';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        ...leadingChildren,
        if (keys.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(tr(ref, 'filter_nothing'))),
          ),
        ...keys.map((id) {
          final skill = records[id] as Map<String, dynamic>;
          final element = skill['element']?.toString();
          final description = skill['description']?.toString() ?? '';
          final points = pointCost?.call(id) ?? 1;
          final available = known.contains(id);
          final learnable = canLearn(id);
          final note = lockNote(id);
          final restriction = reputationLabel(skill);
          final mergeOnly = skill['unlockedViaMergeOnly'] as bool? ?? false;
          final tier = skillTiers?[id] ?? 0;

          Widget? trailing;
          if (compareMode) {
            trailing = null;
          } else if (available) {
            final upgradeCallback = onUpgradeTier;
            // Only a skill the character learned can be upgraded (Heavy
            // Blow, everyone's basic strike, has no tiers).
            if (skillTiers != null &&
                upgradeCallback != null &&
                unlockedSkillIds.contains(id)) {
              final essence = skillEssence ?? 0;
              final maxed = tier >= maxSkillTier;
              final upgradeCost = skillTierUpgradeCost(tier);
              trailing = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tr(ref, 'tier_label')} $tier/$maxSkillTier',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  maxed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : OutlinedButton(
                          // Compact, so tier and button fit the row.
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: essence >= upgradeCost
                              ? () => upgradeCallback(id)
                              : null,
                          child: Text(
                              '${tr(ref, 'upgrade_button')} ($upgradeCost)'),
                        ),
                ],
              );
            } else {
              trailing = const Icon(Icons.check_circle, color: Colors.green);
            }
          } else if (mergeOnly) {
            trailing = Icon(Icons.auto_fix_high,
                color: Theme.of(context).colorScheme.outline);
          } else if (!learnable) {
            trailing = const Icon(Icons.lock_outline);
          } else {
            trailing = ElevatedButton(
              key: Key('learn_$id'),
              onPressed: skillPoints >= points
                  ? () => _learnWithNotice(context, ref, id, onUnlock)
                  : null,
              child: Text(tr(ref, 'unlock_button')),
            );
          }

          final skillAlignment = skill['alignment']?.toString() ?? '';
          final subtitleParts = <String>[
            if (description.isNotEmpty) description,
            if (note != null) note,
            if (restriction.isNotEmpty) restriction,
            if (skillAlignment.isNotEmpty)
              '${tr(ref, 'aligned_gear_label')}: '
                  '${skillAlignment == 'Good' ? tr(ref, 'alignment_good') : tr(ref, 'alignment_evil')}'
                  ' (${tr(ref, 'aligned_skill_note')})',
            if (mergeOnly && !available)
              tr(ref, 'merge_only_hint')
            else if (!available)
              skillPointCostLabel(ref, points),
          ];

          final kind = skillKind(skill);
          return Card(
            color: firstCompareId == id
                ? Theme.of(context).colorScheme.tertiaryContainer
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                  color: firstCompareId == id
                      ? Theme.of(context).colorScheme.tertiary
                      : kind.color.withValues(alpha: 0.55)),
            ),
            child: ListTile(
              leading: SkillPixelIcon(id),
              title: Row(
                children: [
                  Flexible(
                    child: Text(skillDisplayName(id,
                        language: ref.watch(appLanguageProvider))),
                  ),
                  const SizedBox(width: 6),
                  Icon(kind.icon, size: 14, color: kind.color),
                ],
              ),
              subtitle: Text(subtitleParts.join(' · ')),
              isThreeLine: description.isNotEmpty,
              trailing: trailing,
              onTap: compareMode
                  ? () => onCompareTap(id)
                  : () => showDetailDialog(
                        context,
                        title: id,
                        description: description,
                        leading: SkillPixelIcon(id, size: 24),
                        closeLabel: tr(ref, 'close_button'),
                        rows: [
                          MapEntry(tr(ref, 'element_label'),
                              element ?? tr(ref, 'none_label')),
                          MapEntry(
                              tr(ref, 'skill_rarity_label'),
                              tr(ref, 'skill_max_faces')
                                  .replaceAll('{rarity}',
                                      tr(ref, skillRarity(skill).labelKey))
                                  .replaceAll(
                                      '{max}', '${maxFacesForSkill(skill)}')),
                          MapEntry(tr(ref, 'damage_mod_label'),
                              '${skill['damageMod'] ?? 0}'),
                          MapEntry(
                            tr(ref, 'damage_multiplier_label'),
                            '${skill['damageMultiplier'] ?? 1.0}',
                          ),
                          MapEntry(tr(ref, 'heal_amount'),
                              '${skill['healAmount'] ?? 0}'),
                          if (note != null)
                            MapEntry(tr(ref, 'requires_label'), note),
                          if (restriction.isNotEmpty)
                            MapEntry(tr(ref, 'restriction_label'), restriction),
                          MapEntry(
                            tr(ref, 'status_label'),
                            available
                                ? tr(ref, 'unlocked_prefix')
                                : tr(ref, 'status_locked'),
                          ),
                        ],
                      ),
            ),
          );
        }),
        if (trailingChildren.isNotEmpty) ...[
          const Divider(height: 32),
          ...trailingChildren,
        ],
      ],
    );
  }
}

void _learnWithNotice(BuildContext context, WidgetRef ref, String id,
    ValueChanged<String> onUnlock) {
  onUnlock(id);
  if (!context.mounted) return;
  final lang = ref.read(appLanguageProvider);
  showImmersiveNotice(
    context,
    icon: Icons.auto_awesome,
    message: '${trFor(lang, 'unlocked_prefix')}: '
        '${skillDisplayName(id, language: lang)}',
  );
}

/// The skill tree: the class's branches side by side, each learned from
/// the top down and crowned by its mastery (one per character), then the
/// race's heritage across the bottom. Tapping a skill says what it does
/// and learns it.
class _SkillTreeView extends ConsumerWidget {
  const _SkillTreeView({
    required this.records,
    required this.branches,
    required this.known,
    required this.skillPoints,
    required this.masteredBranchId,
    required this.skillTiers,
    required this.skillEssence,
    required this.canLearn,
    required this.pointCost,
    required this.onUnlock,
    this.trailingChildren = const [],
  });

  final Map<String, dynamic> records;
  final List<SkillBranch> branches;

  /// Skill points a skill costs to learn: its place on its branch.
  final int Function(String id) pointCost;
  final Set<String> known;
  final int skillPoints;
  final String masteredBranchId;
  final Map<String, int> skillTiers;
  final int skillEssence;
  final bool Function(String id) canLearn;
  final ValueChanged<String> onUnlock;

  /// Under the tree: the player's Spells section.
  final List<Widget> trailingChildren;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classBranches = branches.where((b) => !b.heritage).toList();
    final heritage = branches.where((b) => b.heritage).toList();
    final mastered = classBranches
        .where((b) => b.id == masteredBranchId)
        .map((b) => b.name)
        .firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          mastered == null
              ? tr(ref, 'skill_tree_intro')
              : tr(ref, 'skill_tree_mastered').replaceAll('{branch}', mastered),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (classBranches.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final branch in classBranches)
                Expanded(child: _branchColumn(context, ref, branch)),
            ],
          ),
        for (final branch in heritage) ...[
          const SizedBox(height: 20),
          Text(branch.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < branch.skillIds.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 23),
                    child: SizedBox(
                      width: 16,
                      child: Divider(
                        thickness: 2,
                        color: known.contains(branch.skillIds[i])
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                Expanded(child: _node(context, ref, branch, i)),
              ],
            ],
          ),
        ],
        if (trailingChildren.isNotEmpty) ...[
          const Divider(height: 32),
          ...trailingChildren,
        ],
      ],
    );
  }

  Widget _branchColumn(
      BuildContext context, WidgetRef ref, SkillBranch branch) {
    final theme = Theme.of(context);
    final isMastered = branch.id == masteredBranchId;
    return Column(
      children: [
        Tooltip(
          message: branch.description,
          child: Text(
            branch.name,
            key: Key('branch_${branch.id}'),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: isMastered ? Colors.amber.shade800 : null),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < branch.skillIds.length; i++) ...[
          if (i > 0) _connector(context, known.contains(branch.skillIds[i])),
          _node(context, ref, branch, i),
        ],
        _connector(context, isMastered),
        _masteryNode(context, ref, branch),
      ],
    );
  }

  Widget _connector(BuildContext context, bool lit) => Container(
        width: 2,
        height: 14,
        color: lit
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
      );

  Widget _node(
      BuildContext context, WidgetRef ref, SkillBranch branch, int index) {
    final id = branch.skillIds[index];
    final skill = records[id] as Map<String, dynamic>?;
    final kind = skillKind(skill);
    final state = skillNodeState(branch, index, known);
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final isKnown = state == SkillNodeState.known;
    final points = pointCost(id);
    final ready = state == SkillNodeState.learnable && skillPoints >= points;
    return InkWell(
      key: Key('tree_node_$id'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showSkillSheet(context, ref, branch, index),
      child: Opacity(
        opacity: state == SkillNodeState.locked ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isKnown
                          ? kind.color.withValues(alpha: 0.18)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isKnown || ready
                            ? kind.color
                            : theme.colorScheme.outlineVariant,
                        width: isKnown ? 2.5 : 1.5,
                      ),
                    ),
                    child: SkillPixelIcon(id, size: 28),
                  ),
                  // What a skill not yet known costs, when more than one.
                  if (!isKnown && points > 1)
                    Positioned(
                      left: -4,
                      top: -4,
                      child: Container(
                        key: Key('tree_cost_$id'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$points',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isKnown)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                    )
                  else if (ready)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Icon(Icons.add_circle,
                          size: 16, color: theme.colorScheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                skillDisplayName(id, language: lang),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _masteryNode(BuildContext context, WidgetRef ref, SkillBranch branch) {
    final theme = Theme.of(context);
    final isMastered = branch.id == masteredBranchId;
    final closed = masteredBranchId.isNotEmpty && !isMastered;
    final ready = canMasterBranch(branch,
        known: known,
        masteredBranchId: masteredBranchId,
        skillPoints: skillPoints);
    final color = isMastered || ready
        ? Colors.amber.shade700
        : theme.colorScheme.outlineVariant;
    return InkWell(
      key: Key('mastery_${branch.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showMasterySheet(context, ref, branch),
      child: Opacity(
        opacity: closed ? 0.4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMastered
                      ? Colors.amber.withValues(alpha: 0.25)
                      : theme.colorScheme.surface,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  closed ? Icons.block : Icons.star,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr(ref, 'mastery_label'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSkillSheet(
      BuildContext context, WidgetRef ref, SkillBranch branch, int index) {
    final id = branch.skillIds[index];
    final skill = records[id] as Map<String, dynamic>? ?? const {};
    final kind = skillKind(skill);
    final lang = ref.read(appLanguageProvider);
    final state = skillNodeState(branch, index, known);
    final tier = skillTiers[id] ?? 0;
    final numbers = [
      if (((skill['damageMod'] as num?) ?? 0) > 0)
        '${tr(ref, 'damage_mod_label')} +${skill['damageMod']}',
      if (((skill['damageMultiplier'] as num?) ?? 1) != 1)
        '×${skill['damageMultiplier']}',
      if (((skill['healAmount'] as num?) ?? 0) > 0)
        '${tr(ref, 'heal_amount')} ${skill['healAmount']}',
      if (((skill['manaGain'] as num?) ?? 0) > 0)
        '${tr(ref, 'mana_label')} +${skill['manaGain']}',
      if ((skill['element']?.toString() ?? 'None') != 'None')
        skill['element'].toString(),
    ].join(' · ');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final points = pointCost(id);
        final learnable = canLearn(id) && skillPoints >= points;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SkillPixelIcon(id, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(skillDisplayName(id, language: lang),
                          style: theme.textTheme.titleLarge),
                    ),
                    Icon(kind.icon, color: kind.color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${branch.name} · ${index + 1}/${branch.skillIds.length}',
                  style: theme.textTheme.labelMedium,
                ),
                // How many faces of a die it may take.
                Text(
                  tr(ref, 'skill_max_faces')
                      .replaceAll(
                          '{rarity}', tr(ref, skillRarity(skill).labelKey))
                      .replaceAll('{max}', '${maxFacesForSkill(skill)}'),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: skillRarity(skill).color),
                ),
                const SizedBox(height: 8),
                Text(skill['description']?.toString() ?? '',
                    style: theme.textTheme.bodyMedium),
                if (numbers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(numbers,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: kind.color)),
                ],
                const SizedBox(height: 16),
                if (state == SkillNodeState.known)
                  Text(
                    '${tr(ref, 'known_label')} · ${tr(ref, 'tier_label')} $tier/$maxSkillTier',
                    style: theme.textTheme.titleSmall,
                  )
                else if (state == SkillNodeState.locked)
                  Text(
                    tr(ref, 'skill_after_label').replaceAll(
                        '{skill}',
                        skillDisplayName(branch.skillIds[index - 1],
                            language: lang)),
                    style: theme.textTheme.titleSmall,
                  )
                else
                  FilledButton.icon(
                    key: const Key('tree_learn'),
                    onPressed: learnable
                        ? () {
                            Navigator.of(sheetContext).pop();
                            _learnWithNotice(context, ref, id, onUnlock);
                          }
                        : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(skillPoints >= points
                        ? (points == 1
                            ? tr(ref, 'learn_for_point')
                            : tr(ref, 'learn_for_points')
                                .replaceAll('{n}', '$points'))
                        : skillPoints == 0
                            ? tr(ref, 'no_skill_points')
                            : tr(ref, 'skill_points_needed')
                                .replaceAll('{n}', '$points')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMasterySheet(
      BuildContext context, WidgetRef ref, SkillBranch branch) {
    final isMastered = branch.id == masteredBranchId;
    final ready = canMasterBranch(branch,
        known: known,
        masteredBranchId: masteredBranchId,
        skillPoints: skillPoints);
    final String status;
    if (isMastered) {
      status = tr(ref, 'mastery_done');
    } else if (masteredBranchId.isNotEmpty) {
      status = tr(ref, 'mastery_closed');
    } else if (!branchComplete(branch, known)) {
      status = tr(ref, 'mastery_needs_branch');
    } else {
      status = '';
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(ref, 'mastery_title')
                            .replaceAll('{branch}', branch.name),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(branch.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  tr(ref, 'mastery_body')
                      .replaceAll('{cost}', '$branchMasteryCost'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (status.isNotEmpty)
                  Text(status, style: theme.textTheme.titleSmall)
                else
                  FilledButton.icon(
                    key: const Key('tree_master'),
                    onPressed: ready
                        ? () {
                            Navigator.of(sheetContext).pop();
                            ref
                                .read(playerSessionProvider.notifier)
                                .masterBranch(branch.id,
                                    cost: branchMasteryCost);
                            showImmersiveNotice(
                              context,
                              icon: Icons.star,
                              message: tr(ref, 'mastery_gained')
                                  .replaceAll('{branch}', branch.name),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.star),
                    label: Text(tr(ref, 'mastery_button')
                        .replaceAll('{cost}', '$branchMasteryCost')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "1 skill point" / "3 skill points": what learning a skill costs.
String skillPointCostLabel(WidgetRef ref, int points) => points == 1
    ? tr(ref, 'skill_point_cost_one')
    : tr(ref, 'skill_point_cost_many').replaceAll('{n}', '$points');
