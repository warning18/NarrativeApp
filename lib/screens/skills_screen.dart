import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/compare_dialog.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/immersive_notice.dart';

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

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _firstCompareId = null;
    });
  }

  void _onCompareTap(BuildContext context, Map<String, dynamic> records, String skillId) {
    if (_firstCompareId == null) {
      setState(() => _firstCompareId = skillId);
      return;
    }
    if (_firstCompareId == skillId) return;
    final firstId = _firstCompareId!;
    final skillA = records[firstId] as Map<String, dynamic>?;
    final skillB = records[skillId] as Map<String, dynamic>?;
    final lang = ref.read(appLanguageProvider);
    num v(Map<String, dynamic>? skill, String key) => (skill?[key] as num?) ?? 0;
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

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final companions = ref.watch(gameDbProvider(companionsSchema)).value ?? const {};
    final session = ref.watch(playerSessionProvider);

    final companion =
        widget.allyId != null ? companions[widget.allyId] as Map<String, dynamic>? : null;
    final ally = widget.allyId != null
        ? session.recruitedAllies.firstWhere(
            (a) => a.companionId == widget.allyId,
            orElse: () => AllyState(companionId: widget.allyId!, currentHealth: 0),
          )
        : null;

    final raceId = ally != null ? (companion?['raceId']?.toString() ?? '') : session.raceId;
    final professionId =
        ally != null ? (companion?['professionId']?.toString() ?? '') : session.professionId;
    final skillPoints = ally?.skillPoints ?? session.skillPoints;
    final unlockedSkillIds = ally?.unlockedSkillIds ?? session.unlockedSkillIds;
    final titleSuffix =
        widget.allyId != null ? ' — ${companion?['companionName']?.toString() ?? widget.allyId}' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'skills')}$titleSuffix'),
        actions: [
          IconButton(
            icon: Icon(_compareMode ? Icons.compare_arrows : Icons.compare_arrows_outlined),
            tooltip: tr(ref, 'compare_button'),
            onPressed: _toggleCompareMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr(ref, 'skill_points_label')}: $skillPoints',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (_compareMode)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _firstCompareId == null
                    ? tr(ref, 'compare_hint_skills')
                    : tr(ref, 'compare_first_selected'),
              ),
            ),
          Expanded(
            child: skillsAsync.when(
              data: (records) => _SkillList(
                records: records,
                races: racesAsync.value ?? const {},
                professions: professionsAsync.value ?? const {},
                raceId: raceId,
                professionId: professionId,
                skillPoints: skillPoints,
                unlockedSkillIds: unlockedSkillIds,
                onUnlock: widget.allyId != null
                    ? (id) => ref
                        .read(playerSessionProvider.notifier)
                        .unlockAllySkill(widget.allyId!, id)
                    : (id) => ref.read(playerSessionProvider.notifier).unlockSkill(id),
                compareMode: _compareMode,
                firstCompareId: _firstCompareId,
                onCompareTap: (id) => _onCompareTap(context, records, id),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('${tr(ref, 'failed_to_load_skills')}: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillList extends ConsumerWidget {
  const _SkillList({
    required this.records,
    required this.races,
    required this.professions,
    required this.raceId,
    required this.professionId,
    required this.skillPoints,
    required this.unlockedSkillIds,
    required this.onUnlock,
    required this.compareMode,
    required this.firstCompareId,
    required this.onCompareTap,
  });

  final Map<String, dynamic> records;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;

  /// Whose restrictions/unlock state this list reflects — the player's own
  /// by default, or a companion's when [SkillsScreen.allyId] is set.
  final String raceId;
  final String professionId;
  final int skillPoints;
  final List<String> unlockedSkillIds;
  final ValueChanged<String> onUnlock;

  final bool compareMode;
  final String? firstCompareId;
  final ValueChanged<String> onCompareTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Center(child: Text(tr(ref, 'no_skills_defined')));
    }
    final keys = records.keys.toList()..sort();

    bool isAvailable(String id) {
      final skill = records[id] as Map<String, dynamic>?;
      final globallyUnlocked = skill?['isUnlocked'] as bool? ?? false;
      return globallyUnlocked || unlockedSkillIds.contains(id);
    }

    bool meetsRestriction(Map<String, dynamic> skill) {
      final restrictedRaceId = skill['restrictedRaceID']?.toString() ?? '';
      if (restrictedRaceId.isNotEmpty && restrictedRaceId != raceId) return false;
      final restrictedProfessionId = skill['restrictedProfessionID']?.toString() ?? '';
      if (restrictedProfessionId.isNotEmpty && restrictedProfessionId != professionId) {
        return false;
      }
      return true;
    }

    String restrictionLabel(Map<String, dynamic> skill) {
      final restrictedRaceId = skill['restrictedRaceID']?.toString() ?? '';
      final restrictedProfessionId = skill['restrictedProfessionID']?.toString() ?? '';
      if (restrictedRaceId.isEmpty && restrictedProfessionId.isEmpty) return '';
      final race = races[restrictedRaceId] as Map<String, dynamic>?;
      final profession = professions[restrictedProfessionId] as Map<String, dynamic>?;
      final raceName =
          restrictedRaceId.isNotEmpty ? (race?['raceName']?.toString() ?? restrictedRaceId) : null;
      final professionName = restrictedProfessionId.isNotEmpty
          ? (profession?['professionName']?.toString() ?? restrictedProfessionId)
          : null;
      return '${tr(ref, 'reserved_prefix')}: ${[raceName, professionName].whereType<String>().join(' · ')}';
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

        Widget? trailing;
        if (compareMode) {
          trailing = null;
        } else if (available) {
          trailing = const Icon(Icons.check_circle, color: Colors.green);
        } else if (!restrictionOk) {
          trailing = const Icon(Icons.lock_outline);
        } else {
          trailing = ElevatedButton(
            onPressed: (skillPoints > 0 && prereqMet)
                ? () async {
                    onUnlock(id);
                    if (!context.mounted) return;
                    final unlockedPrefix =
                        trFor(ref.read(appLanguageProvider), 'unlocked_prefix');
                    showImmersiveNotice(
                      context,
                      icon: Icons.auto_awesome,
                      message: '$unlockedPrefix: $id',
                    );
                  }
                : null,
            child: Text(tr(ref, 'unlock_button')),
          );
        }

        final subtitleParts = <String>[
          if (description.isNotEmpty) description,
          if (requiredSkillId.isNotEmpty) '${tr(ref, 'requires_label')} $requiredSkillId',
          if (restriction.isNotEmpty) restriction,
          '${tr(ref, 'cost_label')}: $cost',
        ];

        return Card(
          color: firstCompareId == id ? Theme.of(context).colorScheme.tertiaryContainer : null,
          child: ListTile(
            leading: Icon(elementIcon(element)),
            title: Text(id),
            subtitle: Text(subtitleParts.join(' · ')),
            isThreeLine: description.isNotEmpty,
            trailing: trailing,
            onTap: compareMode
                ? () => onCompareTap(id)
                : () => showDetailDialog(
                      context,
                      title: id,
                      description: description,
                      icon: elementIcon(element),
                      closeLabel: tr(ref, 'close_button'),
                      rows: [
                        MapEntry(tr(ref, 'element_label'), element ?? tr(ref, 'none_label')),
                        MapEntry(tr(ref, 'cost_label'), '$cost'),
                        MapEntry(tr(ref, 'damage_mod_label'), '${skill['damageMod'] ?? 0}'),
                        MapEntry(
                          tr(ref, 'damage_multiplier_label'),
                          '${skill['damageMultiplier'] ?? 1.0}',
                        ),
                        MapEntry(tr(ref, 'heal_amount'), '${skill['healAmount'] ?? 0}'),
                        if (requiredSkillId.isNotEmpty)
                          MapEntry(tr(ref, 'requires_label'), requiredSkillId),
                        if (restriction.isNotEmpty)
                          MapEntry(tr(ref, 'restriction_label'), restriction),
                        MapEntry(
                          tr(ref, 'active_skill_label'),
                          (skill['isActiveSkill'] as bool? ?? true)
                              ? tr(ref, 'yes_label')
                              : tr(ref, 'no_label'),
                        ),
                        MapEntry(
                          tr(ref, 'status_label'),
                          available ? tr(ref, 'unlocked_prefix') : tr(ref, 'status_locked'),
                        ),
                      ],
                    ),
          ),
        );
      }).toList(),
    );
  }
}
