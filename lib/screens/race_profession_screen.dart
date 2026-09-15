import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/origin_stories.dart';
import '../data/random_names.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/immersive_notice.dart';

/// Formats a skill id like "human_resolve" into "Human Resolve" — skills
/// have no separate display-name field, only an id (matches how
/// skills_screen.dart shows them).
String _formatSkillName(String id) => id
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

class RaceProfessionScreen extends ConsumerStatefulWidget {
  const RaceProfessionScreen({super.key});

  @override
  ConsumerState<RaceProfessionScreen> createState() =>
      _RaceProfessionScreenState();
}

class _RaceProfessionScreenState extends ConsumerState<RaceProfessionScreen> {
  String? _selectedRaceId;
  String? _selectedProfessionId;

  // Set once a brand-new character has just been confirmed in this screen
  // instance, so the character sheet below shows a "Continue" button that
  // starts the game — as opposed to viewing an already-created character's
  // sheet from the Character hub, where there's nothing to "start".
  bool _justCreated = false;

  @override
  Widget build(BuildContext context) {
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final session = ref.watch(playerSessionProvider);
    _selectedRaceId ??= session.raceId.isNotEmpty ? session.raceId : null;
    _selectedProfessionId ??=
        session.professionId.isNotEmpty ? session.professionId : null;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'race_profession_title'))),
      body: racesAsync.when(
        data: (races) => professionsAsync.when(
          data: (professions) => skillsAsync.when(
            data: (skills) {
              if (session.raceId.isNotEmpty &&
                  session.professionId.isNotEmpty) {
                return _CharacterSheet(
                  session: session,
                  race: races[session.raceId] as Map<String, dynamic>?,
                  profession: professions[session.professionId]
                      as Map<String, dynamic>?,
                  skills: skills,
                  language: ref.watch(appLanguageProvider),
                  onStartGame: _justCreated ? _handleContinue : null,
                );
              }
              return _buildPicker(context, races, professions, skills);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
                child: Text('${tr(ref, 'failed_to_load_skills')}: $error')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child: Text('${tr(ref, 'failed_to_load_professions')}: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_races')}: $error')),
      ),
    );
  }

  /// The race/profession's granted skill, formatted as
  /// "Starting Skill: Human Resolve — Draw on human tenacity...", or null
  /// if the preset grants none.
  String? _skillLine(Map<String, dynamic> preset, Map<String, dynamic> skills) {
    final skillId = preset['standardSkillID']?.toString() ?? '';
    if (skillId.isEmpty) return null;
    final skill = skills[skillId] as Map<String, dynamic>?;
    final name = _formatSkillName(skillId);
    final desc = skill?['description']?.toString() ?? '';
    final prefix = '${tr(ref, 'granted_skill_label')}: $name';
    return desc.isNotEmpty ? '$prefix — $desc' : prefix;
  }

  Widget _buildPicker(
    BuildContext context,
    Map<String, dynamic> races,
    Map<String, dynamic> professions,
    Map<String, dynamic> skills,
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
        Text(tr(ref, 'race_label'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...raceIds.map((id) {
          final race = races[id] as Map<String, dynamic>;
          return _PresetCard(
            icon: raceIcon,
            title: race['raceName']?.toString() ?? id,
            description: race['description']?.toString() ?? '',
            bonusLine: _bonusLine(race, showSkillPoints: false),
            skillLine: _skillLine(race, skills),
            selected: _selectedRaceId == id,
            onTap: () => setState(() => _selectedRaceId = id),
          );
        }),
        const SizedBox(height: 24),
        Text(tr(ref, 'profession_label'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...professionIds.map((id) {
          final profession = professions[id] as Map<String, dynamic>;
          return _PresetCard(
            icon: professionIcon,
            title: profession['professionName']?.toString() ?? id,
            description: profession['description']?.toString() ?? '',
            bonusLine: _bonusLine(profession, showSkillPoints: true),
            skillLine: _skillLine(profession, skills),
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

  String _bonusLine(Map<String, dynamic> preset,
      {required bool showSkillPoints}) {
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
      if (showSkillPoints && skillPoints > 0)
        '+$skillPoints ${tr(ref, 'skill_pt_bonus_label')}',
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
    if (!mounted) return;
    // Let the screen rebuild into the character sheet (now that race/
    // profession are set) instead of popping straight back to the story —
    // the player reviews their starting stats first, then taps Continue.
    setState(() => _justCreated = true);
  }

  /// Runs the rest of character creation once the player taps Continue on
  /// the character sheet: locks the character in with a name (race and
  /// profession are already permanent from [_confirmStart] on), then walks
  /// through the five origin-story prompts before finally handing off to
  /// the story.
  Future<void> _handleContinue() async {
    final name = await _showLockInDialog();
    if (name == null || !mounted) return;
    await ref.read(playerSessionProvider.notifier).setCharacterName(name);
    if (!mounted) return;
    await _runOriginStories();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// A required, non-dismissible dialog warning that the character is now
  /// permanent for this run, and collecting the character's name. Returns
  /// the trimmed name, or null if the widget was unmounted mid-dialog.
  Future<String?> _showLockInDialog() async {
    final lang = ref.read(appLanguageProvider);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(trFor(lang, 'lock_character_dialog_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trFor(lang, 'lock_character_dialog_desc')),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: trFor(lang, 'character_name_field_label'),
                  hintText: trFor(lang, 'character_name_field_hint'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.casino_outlined),
                    tooltip: trFor(lang, 'random_name_tooltip'),
                    onPressed: () => setDialogState(() {
                      controller.text = randomCharacterName(_selectedRaceId);
                    }),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty)
                    Navigator.pop(dialogContext, value.trim());
                },
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(trFor(lang, 'begin_story_button')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return name;
  }

  /// Walks through the five formative-memory prompts in order, applying
  /// each choice's alignment effect immediately. Non-dismissible and
  /// unskippable — a choice must be tapped to advance.
  Future<void> _runOriginStories() async {
    for (var index = 0; index < originStoryPrompts.length; index++) {
      if (!mounted) return;
      final prompt = originPromptForSlot(index, _selectedProfessionId);
      final choice = await showDialog<OriginChoice>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(ref, prompt.titleKey)),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${index + 1} / ${originStoryPrompts.length}',
                    style: Theme.of(dialogContext).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(ref, prompt.descriptionKey),
                    style:
                        Theme.of(dialogContext).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'serif',
                              height: 1.6,
                              letterSpacing: 0.1,
                            ),
                  ),
                  const SizedBox(height: 20),
                  for (final choice in prompt.choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, choice),
                        child: Text(tr(ref, choice.textKey),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      if (choice != null) {
        await ref
            .read(playerSessionProvider.notifier)
            .applyChoiceEffects(alignmentMod: choice.alignmentMod);
      }
    }
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.bonusLine,
    this.skillLine,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String bonusLine;

  /// The race/profession's granted starting skill, already formatted with
  /// name and description — null if it grants none.
  final String? skillLine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onContainer = selected ? colorScheme.onPrimaryContainer : null;
    return Card(
      color: selected ? colorScheme.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: onContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: onContainer),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: onContainer),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      bonusLine,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: onContainer),
                    ),
                    if (skillLine != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              skillLine!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: onContainer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full character info, shown once a race and profession are set. Race/
/// profession can only be changed by restarting the story from the
/// beginning (Node 0), not from here. When [onStartGame] is set (right
/// after creating a brand-new character), a Continue button is shown to
/// carry on into the story; viewed later from the Character hub, it's
/// read-only.
class _CharacterSheet extends StatelessWidget {
  const _CharacterSheet({
    required this.session,
    required this.race,
    required this.profession,
    required this.skills,
    required this.language,
    this.onStartGame,
  });

  final PlayerSession session;
  final Map<String, dynamic>? race;
  final Map<String, dynamic>? profession;
  final Map<String, dynamic> skills;
  final AppLanguage language;
  final VoidCallback? onStartGame;

  /// A card naming [preset]'s granted skill (if any), shown right under
  /// its race/profession card so the connection is obvious.
  Widget _skillCard(
      BuildContext context, String label, Map<String, dynamic>? preset) {
    final skillId = preset?['standardSkillID']?.toString() ?? '';
    if (skillId.isEmpty) return const SizedBox.shrink();
    final skill = skills[skillId] as Map<String, dynamic>?;
    final name = _formatSkillName(skillId);
    final desc = skill?['description']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.auto_awesome),
          title: Text('$label: $name'),
          subtitle: desc.isNotEmpty ? Text(desc) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raceName = race?['raceName']?.toString() ?? session.raceId;
    final professionName =
        profession?['professionName']?.toString() ?? session.professionId;
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
        if (session.characterName.isNotEmpty) ...[
          Text(
            session.characterName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: ListTile(
            leading: const Icon(raceIcon),
            title: Text(raceName),
            subtitle: Text(race?['description']?.toString() ?? ''),
          ),
        ),
        _skillCard(context, t('granted_skill_label'), race),
        Card(
          child: ListTile(
            leading: const Icon(professionIcon),
            title: Text(professionName),
            subtitle: Text(profession?['description']?.toString() ?? ''),
          ),
        ),
        _skillCard(context, t('granted_skill_label'), profession),
        const SizedBox(height: 16),
        Text(t('character_sheet_title'),
            style: Theme.of(context).textTheme.titleMedium),
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
                statRow(t('inventory_items_label'),
                    '${session.inventoryItemIds.length}'),
                statRow(t('equipped_items_label'),
                    '${session.equippedItemIds.length}'),
                statRow(t('unlocked_skills_label'),
                    '${session.unlockedSkillIds.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t('race_profession_footer_note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (onStartGame != null) ...[
          const SizedBox(height: 20),
          FilledButton(
              onPressed: onStartGame, child: Text(t('continue_button'))),
        ],
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
