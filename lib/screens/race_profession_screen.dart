import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/immersive_notice.dart';

class RaceProfessionScreen extends ConsumerStatefulWidget {
  const RaceProfessionScreen({super.key});

  @override
  ConsumerState<RaceProfessionScreen> createState() => _RaceProfessionScreenState();
}

class _RaceProfessionScreenState extends ConsumerState<RaceProfessionScreen> {
  String? _selectedRaceId;
  String? _selectedProfessionId;

  @override
  Widget build(BuildContext context) {
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final session = ref.watch(playerSessionProvider);
    _selectedRaceId ??= session.raceId.isNotEmpty ? session.raceId : null;
    _selectedProfessionId ??= session.professionId.isNotEmpty ? session.professionId : null;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'race_profession_title'))),
      body: racesAsync.when(
        data: (races) => professionsAsync.when(
          data: (professions) {
            if (session.raceId.isNotEmpty && session.professionId.isNotEmpty) {
              return _CharacterSheet(
                session: session,
                race: races[session.raceId] as Map<String, dynamic>?,
                profession: professions[session.professionId] as Map<String, dynamic>?,
                language: ref.watch(appLanguageProvider),
              );
            }
            return _buildPicker(context, races, professions);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('${tr(ref, 'failed_to_load_professions')}: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_races')}: $error')),
      ),
    );
  }

  Widget _buildPicker(
    BuildContext context,
    Map<String, dynamic> races,
    Map<String, dynamic> professions,
  ) {
    final raceIds = races.keys.toList()..sort();
    final professionIds = professions.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tr(ref, 'choose_who_desc'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(tr(ref, 'race_label'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...raceIds.map((id) {
          final race = races[id] as Map<String, dynamic>;
          return _PresetCard(
            icon: raceIcon,
            title: race['raceName']?.toString() ?? id,
            description: race['description']?.toString() ?? '',
            bonusLine: _bonusLine(race, showSkillPoints: false),
            selected: _selectedRaceId == id,
            onTap: () => setState(() => _selectedRaceId = id),
          );
        }),
        const SizedBox(height: 24),
        Text(tr(ref, 'profession_label'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...professionIds.map((id) {
          final profession = professions[id] as Map<String, dynamic>;
          return _PresetCard(
            icon: professionIcon,
            title: profession['professionName']?.toString() ?? id,
            description: profession['description']?.toString() ?? '',
            bonusLine: _bonusLine(profession, showSkillPoints: true),
            selected: _selectedProfessionId == id,
            onTap: () => setState(() => _selectedProfessionId = id),
          );
        }),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: (_selectedRaceId == null || _selectedProfessionId == null)
              ? null
              : () => _confirmStart(
                    context,
                    races[_selectedRaceId!] as Map<String, dynamic>,
                    professions[_selectedProfessionId!] as Map<String, dynamic>,
                  ),
          icon: const Icon(Icons.play_arrow),
          label: Text(tr(ref, 'start_new_game_button')),
        ),
      ],
    );
  }

  String _bonusLine(Map<String, dynamic> preset, {required bool showSkillPoints}) {
    final health = (preset['bonusMaxHealth'] as num?)?.toInt() ?? 0;
    final damage = (preset['bonusBaseDamage'] as num?)?.toInt() ?? 0;
    final armor = (preset['bonusBaseArmor'] as num?)?.toInt() ?? 0;
    final gold = (preset['startingGoldBonus'] as num?)?.toInt() ?? 0;
    final skillPoints = (preset['startingSkillPoints'] as num?)?.toInt() ?? 0;
    final parts = <String>[
      '${health >= 0 ? '+' : ''}$health ${tr(ref, 'hp_label')}',
      '${damage >= 0 ? '+' : ''}$damage ${tr(ref, 'damage_label')}',
      '${armor >= 0 ? '+' : ''}$armor ${tr(ref, 'arm_abbrev')}',
      '${gold >= 0 ? '+' : ''}$gold ${tr(ref, 'gold_field_label')}',
      if (showSkillPoints && skillPoints > 0) '+$skillPoints ${tr(ref, 'skill_pt_bonus_label')}',
    ];
    return parts.join(' · ');
  }

  Future<void> _confirmStart(
    BuildContext context,
    Map<String, dynamic> race,
    Map<String, dynamic> profession,
  ) async {
    final lang = ref.read(appLanguageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trFor(lang, 'start_new_game_dialog_title')),
        content: Text(
          '${trFor(lang, 'start_new_game_dialog_prefix')} ${race['raceName']} '
          '${profession['professionName']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(trFor(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(trFor(lang, 'start_button')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(playerSessionProvider.notifier).startNewGame(
          raceId: _selectedRaceId!,
          race: race,
          professionId: _selectedProfessionId!,
          profession: profession,
        );
    if (!context.mounted) return;
    await showImmersiveNotice(
      context,
      icon: Icons.person,
      message: '${trFor(lang, 'new_character_prefix')}: ${race['raceName']} '
          '${profession['professionName']}',
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.bonusLine,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String bonusLine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          description.isNotEmpty ? '$description\n$bonusLine' : bonusLine,
        ),
        isThreeLine: description.isNotEmpty,
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}

/// Read-only full character info, shown once a race and profession are set.
/// Race/profession can only be changed by restarting the story from the
/// beginning (Node 0), not from here.
class _CharacterSheet extends StatelessWidget {
  const _CharacterSheet({
    required this.session,
    required this.race,
    required this.profession,
    required this.language,
  });

  final PlayerSession session;
  final Map<String, dynamic>? race;
  final Map<String, dynamic>? profession;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final raceName = race?['raceName']?.toString() ?? session.raceId;
    final professionName = profession?['professionName']?.toString() ?? session.professionId;
    String t(String key) => trFor(language, key);

    Widget statRow(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(raceIcon),
            title: Text(raceName),
            subtitle: Text(race?['description']?.toString() ?? ''),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(professionIcon),
            title: Text(professionName),
            subtitle: Text(profession?['description']?.toString() ?? ''),
          ),
        ),
        const SizedBox(height: 16),
        Text(t('character_sheet_title'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                statRow(t('level_field_label'), '${session.level}'),
                statRow(
                  t('experience_label'),
                  '${session.currentXP} / ${session.xpToNextLevel}',
                ),
                statRow(
                  t('health_label'),
                  '${session.currentHealth} / ${session.maxHealth}',
                ),
                statRow(t('base_damage_label'), '${session.baseDamage}'),
                statRow(t('base_armor_label'), '${session.baseArmor}'),
                statRow(t('gold_field_label'), '${session.gold}'),
                statRow(
                  t('alignment_label'),
                  '${t(_alignmentKey(session.alignmentLabel))} (${session.alignmentScore})',
                ),
                statRow(t('stat_points_label'), '${session.statPoints}'),
                statRow(t('skill_points_label'), '${session.skillPoints}'),
                statRow(t('potions_label'), '${session.potionCount}'),
                statRow(t('inventory_items_label'), '${session.inventoryItemIds.length}'),
                statRow(t('equipped_items_label'), '${session.equippedItemIds.length}'),
                statRow(t('unlocked_skills_label'), '${session.unlockedSkillIds.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t('race_profession_footer_note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _alignmentKey(String raw) {
    switch (raw) {
      case 'Good':
        return 'alignment_good';
      case 'Evil':
        return 'alignment_evil';
      default:
        return 'alignment_neutral';
    }
  }
}
