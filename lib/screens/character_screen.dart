import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart' show newGamePlusStep;
import '../combat/spells.dart';
import '../data/alignment_events.dart' show alignmentThreshold;
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../utils/game_icons.dart';
import '../widgets/mana_meter.dart';
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
        _CharacterHeader(subtitle: subtitle),
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

/// The top of the character sheet: who the character is, their level
/// and experience, health, mana and gold, where their alignment stands
/// between Evil and Good, any points waiting, and the eight abilities.
class _CharacterHeader extends ConsumerWidget {
  const _CharacterHeader({required this.subtitle});

  /// Race and profession.
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final name = session.characterName.isNotEmpty
        ? session.characterName
        : tr(ref, 'character');
    final xpFraction = session.xpToNextLevel <= 0
        ? 0.0
        : (session.currentXP / session.xpToNextLevel).clamp(0.0, 1.0);

    Widget vital(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ink.seam),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                Text(value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );

    final abilities = <(String, int)>[
      ('strength_label', session.strength),
      ('dexterity_label', session.dexterity),
      ('constitution_label', session.constitution),
      ('intelligence_label', session.intelligence),
      ('wisdom_label', session.wisdom),
      ('charisma_label', session.charisma),
      ('luck_label', session.luck),
      ('perception_label', session.perception),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ink.gold, width: 2),
              ),
              child: Text(
                name.characters.first.toUpperCase(),
                style:
                    theme.textTheme.headlineMedium?.copyWith(color: ink.gold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall),
                  Text(subtitle,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${tr(ref, 'level_abbrev')} ${session.level}',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: ink.gold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: xpFraction,
                          minHeight: 5,
                          color: ink.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                          '${tr(ref, 'xp_label')} ${session.currentXP}/${session.xpToNextLevel}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            vital(tr(ref, 'hp_label'),
                '${session.currentHealth}/${session.maxHealth}', ink.blood),
            const SizedBox(width: 8),
            vital(tr(ref, 'mana_label'), '${session.mana}/${session.maxMana}',
                manaColor),
            const SizedBox(width: 8),
            vital(tr(ref, 'gold_label'), '${session.gold}', ink.gold),
          ],
        ),
        const SizedBox(height: 14),
        _AlignmentBar(score: session.alignmentScore),
        // Stat points are spent on Level Up, skill points on Skills: a
        // button for each kind waiting.
        for (final (count, labelKey, key, screen) in [
          (
            session.statPoints,
            'level_up',
            'character_level_up',
            const LevelUpScreen() as Widget
          ),
          (
            session.skillPoints,
            'skills',
            'character_skills',
            const SkillsScreen() as Widget
          ),
        ])
          if (count > 0) ...[
            const SizedBox(height: 10),
            FilledButton(
              key: Key(key),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => screen),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                          '$count ${tr(ref, key == 'character_skills' ? 'skill_points_label' : 'stat_points_label')}')),
                  Text(tr(ref, labelKey)),
                ],
              ),
            ),
          ],
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            for (final (key, value) in abilities)
              Tooltip(
                message: tr(ref, key),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ink.seam),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr(ref, key.replaceFirst('_label', '_abbr')),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash),
                      ),
                      Text('$value',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontFamily: InkFonts.system)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Where the alignment score stands: a bar from Evil to Good with marks
/// at the thresholds that make the character one or the other.
class _AlignmentBar extends ConsumerWidget {
  const _AlignmentBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    const span = alignmentThreshold * 2;
    final position = ((score + span) / (span * 2)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ink.seam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr(ref, 'alignment_label').toUpperCase(),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              ),
              Text(score > 0 ? '+$score' : '$score',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: ink.voidColor)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 5,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: ink.voidColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 5,
                    width: w / 4,
                    child: Container(
                        height: 8, color: ink.blood.withValues(alpha: 0.45)),
                  ),
                  Positioned(
                    right: 0,
                    top: 5,
                    width: w / 4,
                    child: Container(
                        height: 8, color: ink.gold.withValues(alpha: 0.45)),
                  ),
                  Positioned(
                    left: w * position - 2,
                    top: 0,
                    child: Container(
                      width: 4,
                      height: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${tr(ref, 'alignment_evil')} ≤ −$alignmentThreshold',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              const Spacer(),
              Text('0',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              const Spacer(),
              Text('${tr(ref, 'alignment_good')} ≥ +$alignmentThreshold',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ],
          ),
        ],
      ),
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
