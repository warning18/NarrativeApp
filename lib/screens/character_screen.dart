import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../widgets/player_stats_bar.dart';
import 'dice_loadout_screen.dart';
import 'inventory_screen.dart';
import 'level_up_screen.dart';
import 'race_profession_screen.dart';
import 'skills_screen.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;

    String subtitle = tr(ref, 'char_not_set');
    final races = racesAsync.value;
    final professions = professionsAsync.value;
    if (session.raceId.isNotEmpty && session.professionId.isNotEmpty) {
      final race = races?[session.raceId] as Map<String, dynamic>?;
      final profession =
          professions?[session.professionId] as Map<String, dynamic>?;
      final raceName = race?['raceName']?.toString() ?? session.raceId;
      final professionName =
          profession?['professionName']?.toString() ?? session.professionId;
      subtitle = '$raceName $professionName';
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'character'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PlayerStatsBar(),
          const SizedBox(height: 16),
          if (session.bannerPiecesCollected.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: Text(tr(ref, 'banner_pieces_title')),
                subtitle: Text(
                  session.bannerPiecesCollected.map((id) {
                    final key = 'banner_piece_$id';
                    final label = tr(ref, key);
                    return label == key ? id : label;
                  }).join(' · '),
                ),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(tr(ref, 'race_profession_title')),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const RaceProfessionScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backpack),
              title: Text(tr(ref, 'inventory_equipment')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(tr(ref, 'skills')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SkillsScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up),
              title: Text(tr(ref, 'level_up')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LevelUpScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.casino),
              title: Text(tr(ref, 'dice_loadout')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiceLoadoutScreen()),
                );
              },
            ),
          ),
          if (isEditMode) ...[
            const SizedBox(height: 16),
            const _DebugStatsEditor(),
          ],
        ],
      ),
    );
  }
}

/// Edit-mode-only panel that lets stats be overwritten directly for
/// testing (e.g. jumping straight to low HP to check a death flow, or high
/// gold to check a shop) instead of having to replay to reach that state.
class _DebugStatsEditor extends ConsumerStatefulWidget {
  const _DebugStatsEditor();

  @override
  ConsumerState<_DebugStatsEditor> createState() => _DebugStatsEditorState();
}

class _DebugStatsEditorState extends ConsumerState<_DebugStatsEditor> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final session = ref.read(playerSessionProvider);
    _controllers = {
      'level': TextEditingController(text: '${session.level}'),
      'currentXP': TextEditingController(text: '${session.currentXP}'),
      'gold': TextEditingController(text: '${session.gold}'),
      'alignmentScore':
          TextEditingController(text: '${session.alignmentScore}'),
      'currentHealth': TextEditingController(text: '${session.currentHealth}'),
      'maxHealth': TextEditingController(text: '${session.maxHealth}'),
      'baseDamage': TextEditingController(text: '${session.baseDamage}'),
      'baseArmor': TextEditingController(text: '${session.baseArmor}'),
      'luck': TextEditingController(text: '${session.luck}'),
      'charisma': TextEditingController(text: '${session.charisma}'),
      'strength': TextEditingController(text: '${session.strength}'),
      'dexterity': TextEditingController(text: '${session.dexterity}'),
      'constitution': TextEditingController(text: '${session.constitution}'),
      'intelligence': TextEditingController(text: '${session.intelligence}'),
      'wisdom': TextEditingController(text: '${session.wisdom}'),
      'perception': TextEditingController(text: '${session.perception}'),
      'potionCount': TextEditingController(text: '${session.potionCount}'),
      'antidoteCount': TextEditingController(text: '${session.antidoteCount}'),
      'mana': TextEditingController(text: '${session.mana}'),
      'statPoints': TextEditingController(text: '${session.statPoints}'),
      'skillPoints': TextEditingController(text: '${session.skillPoints}'),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String labelKey) {
    return SizedBox(
      width: 140,
      child: TextField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: tr(ref, labelKey),
          isDense: true,
        ),
      ),
    );
  }

  void _apply() {
    int? parse(String key) => int.tryParse(_controllers[key]!.text.trim());
    ref.read(playerSessionProvider.notifier).debugSetStats(
          level: parse('level'),
          currentXP: parse('currentXP'),
          gold: parse('gold'),
          alignmentScore: parse('alignmentScore'),
          currentHealth: parse('currentHealth'),
          maxHealth: parse('maxHealth'),
          baseDamage: parse('baseDamage'),
          baseArmor: parse('baseArmor'),
          luck: parse('luck'),
          charisma: parse('charisma'),
          strength: parse('strength'),
          dexterity: parse('dexterity'),
          constitution: parse('constitution'),
          intelligence: parse('intelligence'),
          wisdom: parse('wisdom'),
          perception: parse('perception'),
          potionCount: parse('potionCount'),
          antidoteCount: parse('antidoteCount'),
          mana: parse('mana'),
          statPoints: parse('statPoints'),
          skillPoints: parse('skillPoints'),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(ref, 'stats_updated_message'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(ref, 'debug_stats_section_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              tr(ref, 'debug_stats_section_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _field('level', 'level_field_label'),
                _field('currentXP', 'current_xp_label'),
                _field('gold', 'gold_label'),
                _field('alignmentScore', 'alignment_score_label'),
                _field('currentHealth', 'current_hp_label'),
                _field('maxHealth', 'max_hp_label'),
                _field('baseDamage', 'damage_label'),
                _field('baseArmor', 'armor_label'),
                _field('luck', 'luck_label'),
                _field('charisma', 'charisma_label'),
                _field('strength', 'strength_label'),
                _field('dexterity', 'dexterity_label'),
                _field('constitution', 'constitution_label'),
                _field('intelligence', 'intelligence_label'),
                _field('wisdom', 'wisdom_label'),
                _field('perception', 'perception_label'),
                _field('potionCount', 'potion_count_label'),
                _field('antidoteCount', 'antidote_count_label'),
                _field('mana', 'mana_label'),
                _field('statPoints', 'stat_points_label'),
                _field('skillPoints', 'skill_points_label'),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _apply,
                child: Text(tr(ref, 'apply_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
