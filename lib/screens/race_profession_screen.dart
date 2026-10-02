import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/character_start.dart';
import '../data/origin_stories.dart';
import '../data/random_names.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../utils/pixel_icons/pixel_icon.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/immersive_notice.dart';
import 'origin_stories_screen.dart';

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
    final racesAsync = ref.watch(localizedDbProvider(racesSchema));
    final professionsAsync = ref.watch(localizedDbProvider(professionsSchema));
    final skillsAsync = ref.watch(localizedDbProvider(skillsSchema));
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

  Widget _buildPicker(
    BuildContext context,
    Map<String, dynamic> races,
    Map<String, dynamic> professions,
    Map<String, dynamic> skills,
  ) {
    final raceIds = races.keys.toList()..sort();
    final professionIds = professions.keys.toList()..sort();
    final lang = ref.watch(appLanguageProvider);
    final defaults = ref.watch(gameConfigProvider).value ?? const {};
    final theme = Theme.of(context);
    final race = _selectedRaceId == null
        ? null
        : races[_selectedRaceId!] as Map<String, dynamic>?;
    final profession = _selectedProfessionId == null
        ? null
        : professions[_selectedProfessionId!] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(tr(ref, 'choose_who_desc'),
                  style: theme.textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedRaceId = raceIds[Random().nextInt(raceIds.length)];
                _selectedProfessionId =
                    professionIds[Random().nextInt(professionIds.length)];
              }),
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: Text(tr(ref, 'randomize_character_button')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The five peoples in one row, the picked one told below (v1.198).
        _sectionHeader(context, tr(ref, 'race_label'),
            race == null ? tr(ref, 'pick_race_hint') : null),
        _PresetRail(
          ids: raceIds,
          folder: 'races',
          nameOf: (id) =>
              (races[id] as Map<String, dynamic>)['raceName']?.toString() ?? id,
          tagOf: (id) =>
              (races[id] as Map<String, dynamic>)['tag']?.toString() ?? '',
          selectedId: _selectedRaceId,
          onPick: (id) => setState(() => _selectedRaceId = id),
        ),
        if (race != null)
          _PresetDetail(
            presetId: _selectedRaceId!,
            preset: race,
            folder: 'races',
            name: race['raceName']?.toString() ?? _selectedRaceId!,
            skills: skills,
            language: lang,
            withOffers: false,
          ),
        const SizedBox(height: 20),
        _sectionHeader(context, tr(ref, 'profession_label'),
            profession == null ? tr(ref, 'pick_profession_hint') : null),
        _PresetRail(
          ids: professionIds,
          folder: 'professions',
          nameOf: (id) =>
              (professions[id] as Map<String, dynamic>)['professionName']
                  ?.toString() ??
              id,
          tagOf: (id) =>
              (professions[id] as Map<String, dynamic>)['tag']?.toString() ??
              '',
          selectedId: _selectedProfessionId,
          onPick: (id) => setState(() => _selectedProfessionId = id),
        ),
        if (profession != null)
          _PresetDetail(
            presetId: _selectedProfessionId!,
            preset: profession,
            folder: 'professions',
            name: profession['professionName']?.toString() ??
                _selectedProfessionId!,
            skills: skills,
            language: lang,
            withOffers: true,
          ),
        const SizedBox(height: 20),
        // What the two add up to, before anything is set in stone.
        _StartPreview(
          race: race,
          profession: profession,
          defaults: defaults,
          skills: skills,
          language: lang,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
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

  Widget _sectionHeader(BuildContext context, String title, String? hint) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(hint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
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
  /// profession are already permanent from [_confirmStart] on), then opens
  /// the formative memories on their own page, applies what they add up
  /// to (alignment, abilities, the flags the story echoes), and hands off
  /// to the story. Backing out of the first memory
  /// returns here with nothing applied, so Continue simply starts again.
  Future<void> _handleContinue() async {
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NameDialog(
        initialName: ref.read(playerSessionProvider).characterName,
        raceId: _selectedRaceId,
      ),
    );
    if (name == null || !mounted) return;
    await ref.read(playerSessionProvider.notifier).setCharacterName(name);
    if (!mounted) return;
    final result = await Navigator.of(context).push<OriginResult>(
      MaterialPageRoute(
        builder: (_) => OriginStoriesScreen(
          raceId: _selectedRaceId,
          professionId: _selectedProfessionId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    await ref.read(playerSessionProvider.notifier).applyOriginMemories(
          alignmentMod: result.alignment,
          abilities: result.abilities,
          flags: result.flags,
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

/// A race's or profession's mark (`assets/visuals/{folder}/{id}.png`, see
/// `visualAsset`), or the old generic icon for a record without one.
class PresetMark extends StatelessWidget {
  const PresetMark({
    super.key,
    required this.folder,
    required this.preset,
    this.size = 36,
  });

  final String folder;
  final Map<String, dynamic>? preset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = preset?['visualAsset']?.toString() ?? '';
    if (file.isEmpty) {
      return Icon(folder == 'races' ? raceIcon : professionIcon, size: size);
    }
    return PixelIcon('assets/visuals/$folder/$file', size: size);
  }
}

/// The presets side by side, one tile each: the mark, the name, the tag.
class _PresetRail extends StatelessWidget {
  const _PresetRail({
    required this.ids,
    required this.folder,
    required this.nameOf,
    required this.tagOf,
    required this.selectedId,
    required this.onPick,
  });

  final List<String> ids;
  final String folder;
  final String Function(String id) nameOf;
  final String Function(String id) tagOf;
  final String? selectedId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, id) in ids.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Material(
              key: Key('preset_tile_$id'),
              color: id == selectedId
                  ? scheme.primaryContainer
                  : scheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: id == selectedId
                        ? scheme.primary
                        : scheme.outlineVariant,
                    width: id == selectedId ? 2 : 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onPick(id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
                  child: Column(
                    children: [
                      PresetMark(
                          folder: folder,
                          preset: {'visualAsset': '$id.png'},
                          size: 36),
                      const SizedBox(height: 4),
                      Text(nameOf(id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight:
                                  id == selectedId ? FontWeight.w700 : null)),
                      Text(tagOf(id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9.5,
                              color: id == selectedId
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A bonus as a chip: green when it gives, red when it takes.
class _BonusChip extends StatelessWidget {
  const _BonusChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = value > 0 ? Colors.green.shade400 : scheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text('${value > 0 ? '+' : ''}$value $label',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// The picked preset told in full: its lore, what it changes, and the
/// skill it grants.
class _PresetDetail extends ConsumerWidget {
  const _PresetDetail({
    required this.presetId,
    required this.preset,
    required this.folder,
    required this.name,
    required this.skills,
    required this.language,
    required this.withOffers,
  });

  final String presetId;
  final Map<String, dynamic> preset;
  final String folder;
  final String name;
  final Map<String, dynamic> skills;
  final AppLanguage language;
  final bool withOffers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final skillId = preset['standardSkillID']?.toString() ?? '';
    final skill = skills[skillId] as Map<String, dynamic>?;
    final tag = preset['tag']?.toString() ?? '';
    return Card(
      key: Key('preset_detail_$presetId'),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PresetMark(folder: folder, preset: preset, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: theme.textTheme.titleMedium),
                ),
                if (tag.isNotEmpty)
                  Text(tag.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary, letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 6),
            Text(preset['description']?.toString() ?? '',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in presetBonuses(preset, withOffers: withOffers))
                  _BonusChip(label: tr(ref, e.key), value: e.value),
              ],
            ),
            if (skillId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillPixelIcon(skillId, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '${tr(ref, 'granted_skill_label')}: '
                                '${grantedSkillName(skillId, presetId: presetId)}',
                            style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600)),
                        if ((skill?['description']?.toString() ?? '')
                            .isNotEmpty)
                          TextSpan(
                              text: ' — ${skill!['description']}',
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic)),
                      ]),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What the picked race and profession add up to at the start: the name
/// of the pair, its roles, the four numbers that matter, the abilities and
/// the two skills — before the choice is confirmed.
class _StartPreview extends ConsumerWidget {
  const _StartPreview({
    required this.race,
    required this.profession,
    required this.defaults,
    required this.skills,
    required this.language,
  });

  final Map<String, dynamic>? race;
  final Map<String, dynamic>? profession;
  final Map<String, dynamic> defaults;
  final Map<String, dynamic> skills;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final both = race != null && profession != null;
    final totals =
        startingTotals(defaults: defaults, race: race, profession: profession);
    Widget stat(IconData icon, String label, String value) => Expanded(
          child: Column(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        );
    return Card(
      key: const Key('start_preview'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: both ? scheme.primary : scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ref, 'your_character_label').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant, letterSpacing: 1)),
            const SizedBox(height: 4),
            if (!both)
              Text(tr(ref, 'your_character_waiting'),
                  style: theme.textTheme.bodySmall)
            else ...[
              Row(
                children: [
                  PresetMark(folder: 'races', preset: race, size: 32),
                  const SizedBox(width: 4),
                  PresetMark(
                      folder: 'professions', preset: profession, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${race!['raceName']} ${profession!['professionName']}',
                            key: const Key('start_preview_name'),
                            style: theme.textTheme.titleMedium),
                        Text(
                          [race!['tag'], profession!['tag']]
                              .where((t) => (t?.toString() ?? '').isNotEmpty)
                              .join(' · '),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  stat(Icons.favorite, tr(ref, 'hp_label'),
                      '${totals.maxHealth}'),
                  stat(Icons.gavel, tr(ref, 'damage_label'),
                      '${totals.baseDamage}'),
                  stat(Icons.shield, tr(ref, 'arm_abbrev'),
                      '${totals.baseArmor}'),
                  stat(Icons.toll, tr(ref, 'gold_field_label'),
                      '${totals.gold}'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${tr(ref, 'abilities_label')}:',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  for (final e in totals.abilities.entries)
                    Text('${tr(ref, e.key)} ${e.value}',
                        style: theme.textTheme.labelMedium),
                  if (totals.luck != 0)
                    Text('${tr(ref, 'luck_label')} ${totals.luck}',
                        style: theme.textTheme.labelMedium),
                  if (totals.charisma != 0)
                    Text('${tr(ref, 'charisma_label')} ${totals.charisma}',
                        style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final (preset, id) in [
                    (race!, race!['raceID']?.toString() ?? ''),
                    (
                      profession!,
                      profession!['professionID']?.toString() ?? ''
                    ),
                  ])
                    if ((preset['standardSkillID']?.toString() ?? '')
                        .isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            SkillPixelIcon(preset['standardSkillID'].toString(),
                                size: 22),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                grantedSkillName(
                                    preset['standardSkillID'].toString(),
                                    presetId: id),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(color: scheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ],
          ],
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
    final name = grantedSkillName(skillId,
        presetId: (preset?['raceID'] ?? preset?['professionID'])?.toString());
    final desc = skill?['description']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          dense: true,
          leading: SkillPixelIcon(skillId),
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

    // A row with a [description] is long-press-able: holding it shows what
    // the stat actually does, reusing the same explanations the level-up
    // screen already offers so the two never drift apart. Rows without one
    // (plain counters like gold or inventory size) stay static -- their
    // value already says everything there is to know.
    Widget statRow(String label, String value,
        {IconData? icon, String? description}) {
      final row = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: description == null
            ? row
            : InkWell(
                onLongPress: () => showDetailDialog(
                  context,
                  title: label,
                  description: description,
                  icon: icon,
                  closeLabel: t('close_button'),
                ),
                child: row,
              ),
      );
    }

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
            leading: PresetMark(folder: 'races', preset: race, size: 40),
            title: Text(raceName),
            subtitle: Text(
                '${(race?['tag']?.toString() ?? '').isEmpty ? '' : '${race!['tag']} · '}'
                '${race?['description'] ?? ''}'),
          ),
        ),
        _skillCard(context, t('granted_skill_label'), race),
        Card(
          child: ListTile(
            leading:
                PresetMark(folder: 'professions', preset: profession, size: 40),
            title: Text(professionName),
            subtitle: Text(
                '${(profession?['tag']?.toString() ?? '').isEmpty ? '' : '${profession!['tag']} · '}'
                '${profession?['description'] ?? ''}'),
          ),
        ),
        _skillCard(context, t('granted_skill_label'), profession),
        const SizedBox(height: 16),
        Text(t('character_sheet_title'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          t('hold_stat_for_details_hint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
                  icon: Icons.favorite,
                  description: t('max_health_desc'),
                ),
                statRow(t('base_damage_label'), '${session.baseDamage}',
                    icon: Icons.gavel, description: t('base_damage_desc')),
                statRow(t('base_armor_label'), '${session.baseArmor}',
                    icon: Icons.shield, description: t('base_armor_desc')),
                statRow(t('luck_label'), '${session.luck}',
                    icon: Icons.auto_awesome, description: t('luck_desc')),
                statRow(t('charisma_label'), '${session.charisma}',
                    icon: Icons.forum, description: t('charisma_desc')),
                statRow(t('strength_label'), '${session.strength}',
                    icon: Icons.fitness_center,
                    description: t('strength_desc')),
                statRow(t('dexterity_label'), '${session.dexterity}',
                    icon: Icons.directions_run,
                    description: t('dexterity_desc')),
                statRow(t('constitution_label'), '${session.constitution}',
                    icon: Icons.health_and_safety,
                    description: t('constitution_desc')),
                statRow(t('intelligence_label'), '${session.intelligence}',
                    icon: Icons.psychology,
                    description: t('intelligence_desc')),
                statRow(t('wisdom_label'), '${session.wisdom}',
                    icon: Icons.visibility, description: t('wisdom_desc')),
                statRow(t('perception_label'), '${session.perception}',
                    icon: Icons.radar, description: t('perception_desc')),
                statRow(t('gold_field_label'), '${session.gold}'),
                statRow(
                  t('alignment_label'),
                  '${t(_alignmentKey(session.alignmentLabel))} (${session.alignmentScore})',
                ),
                statRow(t('stat_points_label'), '${session.statPoints}'),
                statRow(t('offers_waiting_label'),
                    '${session.pendingOffers.length}'),
                statRow(t('potions_label'), '${session.potionCount}'),
                statRow(t('antidotes_label'), '${session.antidoteCount}'),
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

/// A required, non-dismissible dialog warning that the character is now
/// permanent for this run, and collecting the character's name. Pops with
/// the trimmed name. It owns its text controller, so the controller lives
/// until the dialog's closing animation has finished.
class _NameDialog extends ConsumerStatefulWidget {
  const _NameDialog({required this.initialName, required this.raceId});

  final String initialName;
  final String? raceId;

  @override
  ConsumerState<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends ConsumerState<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => tr(ref, key);
    return AlertDialog(
      title: Text(t('lock_character_dialog_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('lock_character_dialog_desc')),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: t('character_name_field_label'),
                hintText: t('character_name_field_hint'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.casino_outlined),
                  tooltip: t('random_name_tooltip'),
                  onPressed: () => setState(() {
                    _controller.text = randomCharacterName(widget.raceId);
                  }),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: Text(t('continue_button')),
        ),
      ],
    );
  }
}
