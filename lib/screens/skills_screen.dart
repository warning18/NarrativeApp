import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../combat/dice_faces.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
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

  /// The Spells section that heads the player's skill list: the mana pool,
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
      const SizedBox(height: 16),
      Text(tr(ref, 'skills'), style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
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
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final companions =
        ref.watch(gameDbProvider(companionsSchema)).value ?? const {};
    final merges =
        ref.watch(gameDbProvider(skillMergesSchema)).value ?? const {};
    final session = ref.watch(playerSessionProvider);
    final isPlayer = widget.allyId == null;
    // Spells are the player's alone (companions cast nothing), so the
    // Spells section only ever heads the player's own list.
    final spellSection = isPlayer
        ? _buildSpellSection(
            session,
            parseSpells(
                ref.watch(gameDbProvider(spellsSchema)).value ?? const {}),
            ref.watch(gameDbProvider(itemsSchema)).value ?? const {},
            ref.watch(gameDbProvider(shopsSchema)).value ?? const {},
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'skills')}$titleSuffix'),
        actions: [
          if (isPlayer)
            IconButton(
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
          IconButton(
            icon: Icon(_compareMode
                ? Icons.compare_arrows
                : Icons.compare_arrows_outlined),
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
                if (isPlayer)
                  Text(
                    '${tr(ref, 'skill_essence_label')}: ${session.skillEssence}',
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
                alignmentScore: session.alignmentScore,
                skillPoints: skillPoints,
                unlockedSkillIds: unlockedSkillIds,
                onUnlock: widget.allyId != null
                    ? (id) => ref
                        .read(playerSessionProvider.notifier)
                        .unlockAllySkill(widget.allyId!, id)
                    : (id) => ref
                        .read(playerSessionProvider.notifier)
                        .unlockSkill(id),
                skillEssence: isPlayer ? session.skillEssence : null,
                skillTiers: isPlayer ? session.skillTiers : null,
                onUpgradeTier: isPlayer
                    ? (id) => ref
                        .read(playerSessionProvider.notifier)
                        .upgradeSkillTier(id)
                    : null,
                compareMode: _compareMode,
                firstCompareId: _firstCompareId,
                onCompareTap: (id) => _onCompareTap(context, records, id),
                leadingChildren: spellSection,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                  child: Text('${tr(ref, 'failed_to_load_skills')}: $error')),
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
    required this.alignmentScore,
    required this.skillPoints,
    required this.unlockedSkillIds,
    required this.onUnlock,
    this.skillEssence,
    this.skillTiers,
    this.onUpgradeTier,
    required this.compareMode,
    required this.firstCompareId,
    required this.onCompareTap,
    this.leadingChildren = const [],
  });

  /// Widgets that head the list before the skill cards -- the player's
  /// Spells section (see `_SkillsScreenState._buildSpellSection`), or
  /// nothing for a companion.
  final List<Widget> leadingChildren;

  final Map<String, dynamic> records;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;

  /// Whose restrictions/unlock state this list reflects — the player's own
  /// by default, or a companion's when [SkillsScreen.allyId] is set.
  final String raceId;
  final String professionId;

  /// Always the player's own alignment, even when browsing a companion's
  /// skill list — allies don't track a separate alignment, and a skill
  /// gated on it (e.g. [requiredAlignmentMin]) reads as "your reputation
  /// opened this up for the whole party," not the ally's own conduct.
  final int alignmentScore;
  final int skillPoints;
  final List<String> unlockedSkillIds;
  final ValueChanged<String> onUnlock;

  /// Non-null only for the player's own list (never a companion's) — see
  /// [PlayerSession.skillEssence]/[PlayerSession.skillTiers]. Null suppresses
  /// the tier/upgrade UI entirely rather than showing it in a meaningless
  /// always-empty state for an ally.
  final int? skillEssence;
  final Map<String, int>? skillTiers;
  final ValueChanged<String>? onUpgradeTier;

  final bool compareMode;
  final String? firstCompareId;
  final ValueChanged<String> onCompareTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Center(child: Text(tr(ref, 'no_skills_defined')));
    }
    // A boss's own moves stay the boss's: never listed for the party.
    final keys = records.keys
        .where((id) => !isEnemyOnlySkill(records[id] as Map<String, dynamic>?))
        .toList()
      ..sort();

    bool isAvailable(String id) {
      final skill = records[id] as Map<String, dynamic>?;
      final globallyUnlocked = skill?['isUnlocked'] as bool? ?? false;
      return globallyUnlocked || unlockedSkillIds.contains(id);
    }

    bool meetsRestriction(Map<String, dynamic> skill) {
      final restrictedRaceId = skill['restrictedRaceID']?.toString() ?? '';
      if (restrictedRaceId.isNotEmpty && restrictedRaceId != raceId) {
        return false;
      }
      final restrictedProfessionId =
          skill['restrictedProfessionID']?.toString() ?? '';
      if (restrictedProfessionId.isNotEmpty &&
          restrictedProfessionId != professionId) {
        return false;
      }
      final requiredAlignmentMin =
          (skill['requiredAlignmentMin'] as num?)?.toInt();
      if (requiredAlignmentMin != null &&
          alignmentScore < requiredAlignmentMin) {
        return false;
      }
      final requiredAlignmentMax =
          (skill['requiredAlignmentMax'] as num?)?.toInt();
      if (requiredAlignmentMax != null &&
          alignmentScore > requiredAlignmentMax) {
        return false;
      }
      return true;
    }

    String restrictionLabel(Map<String, dynamic> skill) {
      final restrictedRaceId = skill['restrictedRaceID']?.toString() ?? '';
      final restrictedProfessionId =
          skill['restrictedProfessionID']?.toString() ?? '';
      final requiredAlignmentMin =
          (skill['requiredAlignmentMin'] as num?)?.toInt();
      final requiredAlignmentMax =
          (skill['requiredAlignmentMax'] as num?)?.toInt();
      if (restrictedRaceId.isEmpty &&
          restrictedProfessionId.isEmpty &&
          requiredAlignmentMin == null &&
          requiredAlignmentMax == null) {
        return '';
      }
      final race = races[restrictedRaceId] as Map<String, dynamic>?;
      final profession =
          professions[restrictedProfessionId] as Map<String, dynamic>?;
      final raceName = restrictedRaceId.isNotEmpty
          ? (race?['raceName']?.toString() ?? restrictedRaceId)
          : null;
      final professionName = restrictedProfessionId.isNotEmpty
          ? (profession?['professionName']?.toString() ??
              restrictedProfessionId)
          : null;
      final alignmentLabel = requiredAlignmentMin != null
          ? tr(ref, 'good_aligned_label')
          : requiredAlignmentMax != null
              ? tr(ref, 'evil_aligned_label')
              : null;
      return '${tr(ref, 'reserved_prefix')}: ${[
        raceName,
        professionName,
        alignmentLabel,
      ].whereType<String>().join(' · ')}';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...leadingChildren,
        ...keys.map((id) {
          final skill = records[id] as Map<String, dynamic>;
          final element = skill['element']?.toString();
          final description = skill['description']?.toString() ?? '';
          final cost = (skill['cost'] as num?)?.toInt() ?? 0;
          final requiredSkillId = skill['requiredSkillID']?.toString() ?? '';
          final available = isAvailable(id);
          final prereqMet =
              requiredSkillId.isEmpty || isAvailable(requiredSkillId);
          final restrictionOk = meetsRestriction(skill);
          final restriction = restrictionLabel(skill);
          final mergeOnly = skill['unlockedViaMergeOnly'] as bool? ?? false;
          final tier = skillTiers?[id] ?? 0;

          Widget? trailing;
          if (compareMode) {
            trailing = null;
          } else if (available) {
            final upgradeCallback = onUpgradeTier;
            if (skillTiers != null && upgradeCallback != null) {
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
                  const SizedBox(height: 4),
                  maxed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : OutlinedButton(
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
          } else if (!restrictionOk) {
            trailing = const Icon(Icons.lock_outline);
          } else if (mergeOnly) {
            trailing = Icon(Icons.auto_fix_high,
                color: Theme.of(context).colorScheme.outline);
          } else {
            trailing = ElevatedButton(
              onPressed: (skillPoints > 0 && prereqMet)
                  ? () async {
                      onUnlock(id);
                      if (!context.mounted) return;
                      final unlockedPrefix = trFor(
                          ref.read(appLanguageProvider), 'unlocked_prefix');
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

          final skillAlignment = skill['alignment']?.toString() ?? '';
          final subtitleParts = <String>[
            if (description.isNotEmpty) description,
            if (requiredSkillId.isNotEmpty)
              '${tr(ref, 'requires_label')} $requiredSkillId',
            if (restriction.isNotEmpty) restriction,
            if (skillAlignment.isNotEmpty)
              '${tr(ref, 'aligned_gear_label')}: '
                  '${skillAlignment == 'Good' ? tr(ref, 'alignment_good') : tr(ref, 'alignment_evil')}'
                  ' (${tr(ref, 'aligned_skill_note')})',
            if (mergeOnly && !available)
              tr(ref, 'merge_only_hint')
            else
              '${tr(ref, 'cost_label')}: $cost',
          ];

          return Card(
            color: firstCompareId == id
                ? Theme.of(context).colorScheme.tertiaryContainer
                : null,
            child: ListTile(
              leading: SkillPixelIcon(id),
              title: Text(skillDisplayName(id)),
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
                          MapEntry(tr(ref, 'cost_label'), '$cost'),
                          MapEntry(tr(ref, 'damage_mod_label'),
                              '${skill['damageMod'] ?? 0}'),
                          MapEntry(
                            tr(ref, 'damage_multiplier_label'),
                            '${skill['damageMultiplier'] ?? 1.0}',
                          ),
                          MapEntry(tr(ref, 'heal_amount'),
                              '${skill['healAmount'] ?? 0}'),
                          if (requiredSkillId.isNotEmpty)
                            MapEntry(
                                tr(ref, 'requires_label'), requiredSkillId),
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
                            available
                                ? tr(ref, 'unlocked_prefix')
                                : tr(ref, 'status_locked'),
                          ),
                        ],
                      ),
            ),
          );
        }),
      ],
    );
  }
}
