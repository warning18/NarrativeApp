import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/character_start.dart';
import '../data/element_points.dart';
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
import '../theme/stitched_ink.dart';
import '../widgets/ability_radar.dart';
import '../widgets/ability_visuals.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/immersive_notice.dart';
import 'origin_stories_screen.dart';
import '../widgets/empty_state.dart';

class RaceProfessionScreen extends ConsumerStatefulWidget {
  const RaceProfessionScreen({super.key});

  @override
  ConsumerState<RaceProfessionScreen> createState() =>
      _RaceProfessionScreenState();
}

class _RaceProfessionScreenState extends ConsumerState<RaceProfessionScreen> {
  String? _selectedRaceId;
  String? _selectedProfessionId;

  /// Which of the two the detail card below the rails tells: 0 the race, 1
  /// the profession (the one picked last), and whether its lore is open in
  /// full (v1.244).
  int _tab = 0;
  bool _loreOpen = false;

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
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
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
                  items: items,
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
          error: (error, stack) => InkErrorState(
              message: tr(ref, 'failed_to_load_professions'), detail: error),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => InkErrorState(
            message: tr(ref, 'failed_to_load_races'), detail: error),
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

    final totals =
        startingTotals(defaults: defaults, race: race, profession: profession);
    final plain = startingTotals(defaults: defaults);
    final raceOnly = startingTotals(defaults: defaults, race: race);
    // The picked tab's detail: the race until a profession is picked.
    final showProfession = _tab == 1 && profession != null;

    // The radar and the numbers stay in view above the rails (v1.244): it
    // answers each pick as it is made, so nothing has to be scrolled to.
    return Column(
      children: [
        _LiveCharacter(
          race: race,
          profession: profession,
          totals: totals,
          before: race != null && profession != null ? raceOnly : plain,
          compareWithRace: race != null && profession != null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                      _selectedRaceId =
                          raceIds[Random().nextInt(raceIds.length)];
                      _selectedProfessionId =
                          professionIds[Random().nextInt(professionIds.length)];
                      _loreOpen = false;
                    }),
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: Text(tr(ref, 'randomize_character_button')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // The five peoples in one row, the picked one told below.
              _sectionHeader(context, tr(ref, 'race_label'),
                  race == null ? tr(ref, 'pick_race_hint') : null),
              _PresetRail(
                ids: raceIds,
                folder: 'races',
                presetOf: (id) => races[id] as Map<String, dynamic>?,
                nameOf: (id) =>
                    (races[id] as Map<String, dynamic>)['raceName']
                        ?.toString() ??
                    id,
                tagOf: (id) =>
                    (races[id] as Map<String, dynamic>)['tag']?.toString() ??
                    '',
                selectedId: _selectedRaceId,
                onPick: (id) => setState(() {
                  _selectedRaceId = id;
                  _tab = 0;
                  _loreOpen = false;
                }),
              ),
              const SizedBox(height: 14),
              _sectionHeader(context, tr(ref, 'profession_label'),
                  profession == null ? tr(ref, 'pick_profession_hint') : null),
              _PresetRail(
                ids: professionIds,
                folder: 'professions',
                presetOf: (id) => professions[id] as Map<String, dynamic>?,
                nameOf: (id) =>
                    (professions[id] as Map<String, dynamic>)['professionName']
                        ?.toString() ??
                    id,
                tagOf: (id) =>
                    (professions[id] as Map<String, dynamic>)['tag']
                        ?.toString() ??
                    '',
                selectedId: _selectedProfessionId,
                onPick: (id) => setState(() {
                  _selectedProfessionId = id;
                  _tab = 1;
                  _loreOpen = false;
                }),
              ),
              const SizedBox(height: 12),
              // One detail card for the two: a switch between them, the first
              // sentence of the lore, the rest behind "more".
              if (race != null || profession != null)
                _PickedDetail(
                  race: race,
                  raceId: _selectedRaceId,
                  profession: profession,
                  professionId: _selectedProfessionId,
                  showProfession: showProfession || race == null,
                  skills: skills,
                  language: lang,
                  loreOpen: _loreOpen,
                  onTab: (i) => setState(() {
                    _tab = i;
                    _loreOpen = false;
                  }),
                  onLore: () => setState(() => _loreOpen = !_loreOpen),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (_selectedRaceId == null || _selectedProfessionId == null)
                        ? null
                        : () => _confirmStart(
                              context,
                              races[_selectedRaceId!] as Map<String, dynamic>,
                              professions[_selectedProfessionId!]
                                  as Map<String, dynamic>,
                            ),
                icon: const Icon(Icons.play_arrow),
                label: Text(tr(ref, 'start_new_game_button')),
              ),
            ),
          ),
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
    final generic =
        Icon(folder == 'races' ? raceIcon : professionIcon, size: size);
    if (file.isEmpty) return generic;
    // A preset whose picture the build does not carry (one added in the
    // Data tab) shows the generic mark rather than breaking the screen.
    return PixelIcon('assets/visuals/$folder/$file',
        size: size, fallback: generic);
  }
}

/// The presets side by side, one tile each: the mark, the name, the tag.
class _PresetRail extends StatelessWidget {
  const _PresetRail({
    required this.ids,
    required this.folder,
    required this.presetOf,
    required this.nameOf,
    required this.tagOf,
    required this.selectedId,
    required this.onPick,
  });

  final List<String> ids;
  final String folder;
  final Map<String, dynamic>? Function(String id) presetOf;
  final String Function(String id) nameOf;
  final String Function(String id) tagOf;
  final String? selectedId;
  final ValueChanged<String> onPick;

  /// The gap between two tiles.
  static const double _gap = 6;

  /// Under this much room per tile, the names are set smaller so a long
  /// one (« Enfant du Néant » on a 360 px phone) fits on its two lines.
  static const double _narrowTile = 68;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, box) {
      final tileWidth = box.hasBoundedWidth
          ? (box.maxWidth - _gap * (ids.length - 1)) / ids.length
          : double.infinity;
      // A name may take two lines (v1.209): the French ones are long for
      // five tiles across a phone, and a name cut short is no name.
      final nameStyle = theme.textTheme.labelMedium?.copyWith(
          fontSize: tileWidth < _narrowTile ? 10.5 : null,
          letterSpacing: tileWidth < _narrowTile ? 0 : null,
          height: 1.15);
      // Level tiles: the tallest name sets the rail's height.
      return IntrinsicHeight(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, id) in ids.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
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
                            folder: folder, preset: presetOf(id), size: 36),
                        const SizedBox(height: 4),
                        Text(nameOf(id),
                            key: Key('preset_name_$id'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: nameStyle?.copyWith(
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
      ));
    });
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
/// The eight abilities of [totals] by key, for the radar.
Map<String, int> _abilityMap(StartingTotals totals) => {
      'strength': totals.strength,
      'dexterity': totals.dexterity,
      'constitution': totals.constitution,
      'intelligence': totals.intelligence,
      'wisdom': totals.wisdom,
      'perception': totals.perception,
      'luck': totals.luck,
      'charisma': totals.charisma,
    };

/// What the picked race and profession add up to, always in view above the
/// rails (v1.244): the radar with the race alone dashed behind it, the name of
/// the pair, and the four numbers that matter. Nothing picked shows the plain
/// start.
class _LiveCharacter extends ConsumerWidget {
  const _LiveCharacter({
    required this.race,
    required this.profession,
    required this.totals,
    required this.before,
    required this.compareWithRace,
  });

  final Map<String, dynamic>? race;
  final Map<String, dynamic>? profession;
  final StartingTotals totals;
  final StartingTotals before;

  /// Whether [before] is the race alone (told in the legend).
  final bool compareWithRace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final both = race != null && profession != null;
    final name = [
      race?['raceName'],
      profession?['professionName'],
    ].where((n) => (n?.toString() ?? '').isNotEmpty).join(' ');
    final tags = [race?['tag'], profession?['tag']]
        .where((t) => (t?.toString() ?? '').isNotEmpty)
        .join(' · ');
    Widget stat(String label, int value) => Expanded(
          child: Column(
            children: [
              Text('$value',
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: both ? scheme.primary : scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
        child: Row(
          children: [
            // Its corner labels reach past the chart: room above and below.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AbilityRadar(
                key: const Key('start_preview_radar'),
                t: (key) => tr(ref, key),
                size: 176,
                before: _abilityMap(before),
                values: _abilityMap(totals),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name.isEmpty)
                    Text(tr(ref, 'your_character_waiting'),
                        style: theme.textTheme.bodySmall)
                  else ...[
                    Text(name,
                        key: const Key('start_preview_name'),
                        style: theme.textTheme.titleMedium),
                    if (tags.isNotEmpty)
                      Text(tags.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary, letterSpacing: 0.6)),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    stat(tr(ref, 'hp_label'), totals.maxHealth),
                    stat(tr(ref, 'damage_label'), totals.baseDamage),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    stat(tr(ref, 'arm_abbrev'), totals.baseArmor),
                    stat(tr(ref, 'gold_field_label'), totals.gold),
                  ]),
                  if (compareWithRace) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                          width: 16,
                          height: 0,
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: radarCompare, width: 2)))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${race!['raceName']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One card for the race and the profession that are picked (v1.244): a
/// switch between the two, then the first sentence of the lore (the rest
/// behind "more"), what it adds, and its starting skill.
class _PickedDetail extends ConsumerWidget {
  const _PickedDetail({
    required this.race,
    required this.raceId,
    required this.profession,
    required this.professionId,
    required this.showProfession,
    required this.skills,
    required this.language,
    required this.loreOpen,
    required this.onTab,
    required this.onLore,
  });

  final Map<String, dynamic>? race;
  final String? raceId;
  final Map<String, dynamic>? profession;
  final String? professionId;
  final bool showProfession;
  final Map<String, dynamic> skills;
  final AppLanguage language;
  final bool loreOpen;
  final ValueChanged<int> onTab;
  final VoidCallback onLore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preset = showProfession ? profession : race;
    final presetId = showProfession ? professionId : raceId;
    if (preset == null || presetId == null) return const SizedBox.shrink();
    final skillId = preset['standardSkillID']?.toString() ?? '';
    final skill = skills[skillId] as Map<String, dynamic>?;
    final (lead, rest) = leadAndRest(preset['description']?.toString() ?? '');

    Widget tab(int i, Map<String, dynamic>? p, String f, String? name) {
      final on = (i == 1) == showProfession;
      return Expanded(
        child: InkWell(
          key: Key(i == 0 ? 'detail_tab_race' : 'detail_tab_profession'),
          onTap: p == null ? null : () => onTab(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: on ? scheme.primary.withValues(alpha: 0.14) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (p != null) PresetMark(folder: f, preset: p, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name ?? '–',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: on ? scheme.primary : scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      key: Key('preset_detail_$presetId'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            tab(0, race, 'races', race?['raceName']?.toString()),
            tab(1, profession, 'professions',
                profession?['professionName']?.toString()),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: lead),
                    if (loreOpen && rest.isNotEmpty) TextSpan(text: ' $rest'),
                  ]),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.88),
                      height: 1.45),
                ),
                if (rest.isNotEmpty)
                  InkWell(
                    key: const Key('detail_lore_toggle'),
                    onTap: onLore,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${tr(ref, loreOpen ? 'lore_less' : 'lore_more')} ${loreOpen ? '▴' : '▾'}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final e
                        in presetBonuses(preset, withOffers: showProfession))
                      _BonusChip(label: tr(ref, e.key), value: e.value),
                  ],
                ),
                if (skillId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkillPixelIcon(skillId, size: 26),
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
        ],
      ),
    );
  }
}

/// A lore text told as a first sentence that leads and the rest that
/// follows, so a long description reads in two steps.
(String, String) leadAndRest(String text) {
  final trimmed = text.trim();
  final at = trimmed.indexOf(RegExp(r'[.!?]\s'));
  if (at < 0 || at + 2 >= trimmed.length) return (trimmed, '');
  return (trimmed.substring(0, at + 1), trimmed.substring(at + 2).trim());
}

/// A race or a profession on the character sheet (v1.223): its mark in a
/// frame, its name, its tag as a chip, the first sentence of its lore set
/// larger and the rest below at a readable size, and what it changes as
/// chips.
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({
    required this.cardKey,
    required this.folder,
    required this.preset,
    required this.name,
    required this.withOffers,
  });

  final Key cardKey;
  final String folder;
  final Map<String, dynamic>? preset;
  final String name;
  final bool withOffers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = preset?['tag']?.toString() ?? '';
    final (lead, rest) = leadAndRest(preset?['description']?.toString() ?? '');
    return Card(
      key: cardKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: PresetMark(folder: folder, preset: preset, size: 44),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.headlineSmall),
                      if (tag.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: scheme.primary.withValues(alpha: 0.14),
                            border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.6)),
                          ),
                          child: Text(tag.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.primary, letterSpacing: 0.8)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (lead.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(lead,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                      height: 1.45)),
            ],
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rest,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: scheme.onSurface.withValues(alpha: 0.82),
                      height: 1.6)),
            ],
            if (preset != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e
                      in presetBonuses(preset!, withOffers: withOffers))
                    _BonusChip(label: tr(ref, e.key), value: e.value),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The skill a race or a profession grants, on the character sheet: an
/// overline, its name large and its words below.
class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.label,
    required this.skillId,
    required this.name,
    required this.description,
  });

  final String label;
  final String skillId;
  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
            ),
            child: SkillPixelIcon(skillId, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.primary, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontSize: 18, color: scheme.onSurface)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          color: scheme.onSurface.withValues(alpha: 0.82),
                          height: 1.45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A number with its icon and name, as one tile of a grid; held, it tells
/// what the stat does.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.description,
    this.closeLabel = '',
  });

  final IconData icon;
  final String label;
  final String value;
  final String? description;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: InkFonts.system, color: scheme.onSurface)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                maxLines: 1,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    color: scheme.onSurface.withValues(alpha: 0.8))),
          ),
        ],
      ),
    );
    if (description == null) return tile;
    return GestureDetector(
      onLongPress: () => showDetailDialog(
        context,
        title: label,
        description: description!,
        icon: icon,
        closeLabel: closeLabel,
      ),
      child: tile,
    );
  }
}

/// Full character info, shown once a race and profession are set. Race/
/// profession can only be changed by restarting the story from the
/// beginning (Node 0), not from here. When [onStartGame] is set (right
/// after creating a brand-new character), a Continue button is shown to
/// carry on into the story; viewed later from the Character hub, it's
/// read-only.
///
/// v1.223: the identity cards lead with the first sentence of their lore,
/// the numbers that matter come first as bars and tiles (health, experience,
/// damage, armour, the eight abilities in a grid), and the counters follow
/// as one plain list.
class _CharacterSheet extends StatelessWidget {
  const _CharacterSheet({
    required this.session,
    required this.race,
    required this.profession,
    required this.skills,
    required this.items,
    required this.language,
    this.onStartGame,
  });

  final PlayerSession session;
  final Map<String, dynamic>? race;
  final Map<String, dynamic>? profession;
  final Map<String, dynamic> skills;

  /// The items table, for the elemental points the equipped ones give.
  final Map<String, dynamic> items;
  final AppLanguage language;
  final VoidCallback? onStartGame;

  /// The skill card of [preset]'s granted skill, if it has one.
  Widget _skillCard(
      BuildContext context, String label, Map<String, dynamic>? preset) {
    final skillId = preset?['standardSkillID']?.toString() ?? '';
    if (skillId.isEmpty) return const SizedBox.shrink();
    final skill = skills[skillId] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _SkillCard(
        label: label,
        skillId: skillId,
        name: grantedSkillName(skillId,
            presetId:
                (preset?['raceID'] ?? preset?['professionID'])?.toString()),
        description: skill?['description']?.toString() ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final raceName = race?['raceName']?.toString() ?? session.raceId;
    final professionName =
        profession?['professionName']?.toString() ?? session.professionId;
    String t(String key) => trFor(language, key);

    Widget section(String title, {String? hint}) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (hint != null)
                Text(hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        );

    /// A bar with its caption and numbers: health, experience.
    Widget bar(
        String label, IconData? icon, double value, String numbers, Color color,
        {String? description}) {
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Expanded(
                  child: Text(label,
                      style:
                          theme.textTheme.bodyLarge?.copyWith(fontSize: 16))),
              Text(numbers,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: description == null
            ? body
            : GestureDetector(
                onLongPress: () => showDetailDialog(
                      context,
                      title: label,
                      description: description,
                      icon: icon,
                      closeLabel: t('close_button'),
                    ),
                child: body),
      );
    }

    /// A plain counter: the label to the left, its number to the right.
    Widget row(String label, String value, {bool last = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        color: scheme.onSurface.withValues(alpha: 0.85))),
              ),
              const SizedBox(width: 12),
              Text(value,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: scheme.onSurface)),
            ],
          ),
        );

    final abilities = <(String, int)>[
      ('strength', session.strength),
      ('dexterity', session.dexterity),
      ('constitution', session.constitution),
      ('intelligence', session.intelligence),
      ('wisdom', session.wisdom),
      ('perception', session.perception),
      ('luck', session.luck),
      ('charisma', session.charisma),
    ];
    final counters = <(String, String)>[
      (t('gold_field_label'), '${session.gold}'),
      (
        t('alignment_label'),
        '${t(_alignmentKey(session.alignmentLabel))} (${session.alignmentScore})'
      ),
      (t('stat_points_label'), '${session.statPoints}'),
      (t('offers_waiting_label'), '${session.pendingOffers.length}'),
      (t('potions_label'), '${session.potionCount}'),
      (t('antidotes_label'), '${session.antidoteCount}'),
      (t('inventory_items_label'), '${session.inventoryItemIds.length}'),
      (t('equipped_items_label'), '${session.equippedItemIds.length}'),
      (t('unlocked_skills_label'), '${session.unlockedSkillIds.length}'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (session.characterName.isNotEmpty) ...[
          Text(
            session.characterName,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$raceName · $professionName',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: scheme.primary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
        ],
        _IdentityCard(
          cardKey: const Key('sheet_race_card'),
          folder: 'races',
          preset: race,
          name: raceName,
          withOffers: false,
        ),
        _skillCard(context, t('granted_skill_label'), race),
        const SizedBox(height: 14),
        _IdentityCard(
          cardKey: const Key('sheet_profession_card'),
          folder: 'professions',
          preset: profession,
          name: professionName,
          withOffers: true,
        ),
        _skillCard(context, t('granted_skill_label'), profession),
        section(t('character_sheet_title'),
            hint: t('hold_stat_for_details_hint')),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: scheme.primary.withValues(alpha: 0.14),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.6)),
                      ),
                      child: Text('${t('level_field_label')} ${session.level}',
                          key: const Key('sheet_level'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: scheme.primary)),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                bar(
                  t('health_label'),
                  Icons.favorite,
                  session.maxHealth == 0
                      ? 0
                      : session.currentHealth / session.maxHealth,
                  '${session.currentHealth} / ${session.maxHealth}',
                  Colors.red.shade400,
                  description: t('max_health_desc'),
                ),
                bar(
                  t('experience_label'),
                  Icons.trending_up,
                  session.xpToNextLevel == 0
                      ? 0
                      : session.currentXP / session.xpToNextLevel,
                  '${session.currentXP} / ${session.xpToNextLevel}',
                  scheme.primary,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.gavel,
                        label: t('base_damage_label'),
                        value: '${session.baseDamage}',
                        description: t('base_damage_desc'),
                        closeLabel: t('close_button'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.shield,
                        label: t('base_armor_label'),
                        value: '${session.baseArmor}',
                        description: t('base_armor_desc'),
                        closeLabel: t('close_button'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        section(t('abilities_label')),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: AbilityRadar(
                key: const Key('sheet_radar'),
                t: t,
                size: 320,
                values: {for (final (k, v) in abilities) k: v},
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          key: const Key('sheet_abilities'),
          children: [
            for (var r = 0; r < 2; r++) ...[
              if (r > 0) const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < 4; c++) ...[
                      if (c > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          icon: abilityIcon(abilities[r * 4 + c].$1),
                          label: t('${abilities[r * 4 + c].$1}_label'),
                          value: '${abilities[r * 4 + c].$2}',
                          description: t('${abilities[r * 4 + c].$1}_desc'),
                          closeLabel: t('close_button'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        section(t('elements_title'), hint: t('elements_hint')),
        ElementsCard(
          key: const Key('sheet_elements'),
          t: t,
          points: elementPointsFor(session.equippedItemIds, items),
        ),
        section(t('sheet_belongings_title')),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final (i, (label, value)) in counters.indexed)
                  row(label, value, last: i == counters.length - 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t('race_profession_footer_note'),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
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
