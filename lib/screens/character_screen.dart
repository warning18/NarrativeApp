import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart' show newGamePlusStep;
import '../combat/spells.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/mana_meter.dart';
import '../widgets/player_stats_bar.dart';
import 'dice_loadout_screen.dart';
import 'inventory_screen.dart';
import 'level_up_screen.dart';
import 'race_profession_screen.dart';
import 'skills_screen.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key, this.embedded = false});

  /// True as the in-game Character tab: the page without its own app bar
  /// (the game's header is above it).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final racesAsync = ref.watch(localizedDbProvider(racesSchema));
    final professionsAsync = ref.watch(localizedDbProvider(professionsSchema));
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

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PlayerStatsBar(),
        const SizedBox(height: 16),
        if (session.newGamePlusCycle > 0) const _NewGamePlusCard(),
        const _ManaSpellsCard(),
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
                MaterialPageRoute(builder: (_) => const RaceProfessionScreen()),
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
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'character'))),
      body: body,
    );
  }
}

/// The mana pool and the spells the player knows, at a glance -- the
/// numbers the battle screen's action bar will show. Tapping opens the
/// Skills screen, whose Spells section has each spell's details and where
/// the unlearned ones are sold.
/// The New Game+ cycle this save is on and what it means: tougher enemies
/// (see `newGamePlusMultiplier`) and the legacy the previous run left.
class _NewGamePlusCard extends ConsumerWidget {
  const _NewGamePlusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final cycle = session.newGamePlusCycle;
    final bonus = (newGamePlusStep * cycle * 100).round();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.replay_circle_filled_outlined,
            color: Colors.deepPurple, size: 28),
        title: Text(
            '${tr(ref, 'new_game_plus_label')} · ${tr(ref, 'new_game_plus_cycle_label')} $cycle'),
        subtitle: Text(
          '${tr(ref, 'new_game_plus_enemies_prefix')} +$bonus% '
          '${tr(ref, 'new_game_plus_enemies_suffix')}. '
          '${tr(ref, 'new_game_plus_card_desc')}',
        ),
      ),
    );
  }
}

class _ManaSpellsCard extends ConsumerWidget {
  const _ManaSpellsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final spells = parseSpells(
        ref.watch(localizedDbProvider(spellsSchema)).value ?? const {});
    final known = <SpellSpec>[
      for (final id in session.knownSpellIds)
        if (spells[id] != null) spells[id]!,
    ];
    return Card(
      child: ListTile(
        leading: const Icon(manaIcon, color: manaColor, size: 28),
        title: Row(
          children: [
            Text('${tr(ref, 'mana_label')} ${session.mana}/${session.maxMana}'),
            const SizedBox(width: 8),
            ManaMeter(mana: session.mana, maxMana: session.maxMana),
          ],
        ),
        subtitle: Text(
          known.isEmpty
              ? tr(ref, 'no_spells_hint')
              : '${tr(ref, 'spells_label')}: '
                  '${known.map((s) => s.nameFor(lang)).join(' · ')}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SkillsScreen()),
          );
        },
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
