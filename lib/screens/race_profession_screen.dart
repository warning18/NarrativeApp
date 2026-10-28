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
import '../widgets/race_profession_cards.dart';

class RaceProfessionScreen extends ConsumerStatefulWidget {
  const RaceProfessionScreen({super.key});

  @override
  ConsumerState<RaceProfessionScreen> createState() =>
      _RaceProfessionScreenState();
}

class _RaceProfessionScreenState extends ConsumerState<RaceProfessionScreen> {
  String? _selectedRaceId;
  String? _selectedProfessionId;

  /// The step shown (v1.599): 0 the peoples, 1 the callings; and whether the
  /// picked card is folded back into the list of all of them.
  int _step = 0;
  bool _listAll = false;

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
            error: (error, stack) => InkErrorState(
                message: tr(ref, 'failed_to_load_skills'), detail: error),
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
    final book = ref.watch(choiceBookProvider);
    if (book == null) return const Center(child: CircularProgressIndicator());
    final raceIds = races.keys.toList()..sort();
    final professionIds = professions.keys.toList()..sort();
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final folder =
        _step == 0 ? ChoiceBook.folderRaces : ChoiceBook.folderProfessions;
    final ids = _step == 0 ? raceIds : professionIds;
    final pickedHere = _step == 0 ? _selectedRaceId : _selectedProfessionId;
    final both = _selectedRaceId != null && _selectedProfessionId != null;
    final open = pickedHere != null && !_listAll;

    void pick(String id) => setState(() {
          if (_step == 0) {
            _selectedRaceId = id;
          } else {
            _selectedProfessionId = id;
          }
          // The card just picked opens; a tap on the open one folds it back
          // into the list of all of them.
          _listAll = pickedHere == id && !_listAll;
        });

    Widget card(String id, {bool compact = false}) => ChoiceCard(
          book: book,
          folder: folder,
          id: id,
          selected: id == pickedHere,
          compact: compact,
          onTap: () => pick(id),
        );

    final hint = Row(children: [
      Expanded(
        child: Text(tr(ref, _step == 0 ? 'rp_hint_people' : 'rp_hint_calling'),
            style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
      ),
      const SizedBox(width: 6),
      ActionChip(
        key: const Key('rp_compare'),
        avatar: Icon(Icons.compare_arrows, size: 16, color: ink.tide),
        label: Text(tr(ref, 'rp_compare')),
        visualDensity: VisualDensity.compact,
        onPressed: () => showCompareSheet(context, ref, book,
            folder: folder,
            first: pickedHere ?? ids.first,
            onPick: (id) => setState(() {
                  if (_step == 0) {
                    _selectedRaceId = id;
                  } else {
                    _selectedProfessionId = id;
                  }
                  _listAll = false;
                })),
      ),
      IconButton(
        key: const Key('rp_randomize'),
        tooltip: tr(ref, 'randomize_character_button'),
        icon: const Icon(Icons.casino_outlined),
        onPressed: () => setState(() {
          _selectedRaceId = raceIds[Random().nextInt(raceIds.length)];
          _selectedProfessionId =
              professionIds[Random().nextInt(professionIds.length)];
          _listAll = false;
        }),
      ),
    ]);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: StepSwitch(
            book: book,
            raceId: _selectedRaceId,
            professionId: _selectedProfessionId,
            step: _step,
            onStep: (i) => setState(() {
              _step = i;
              _listAll = false;
            }),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            children: [
              hint,
              const SizedBox(height: 6),
              if (open) ...[
                card(pickedHere),
                OpenChoice(book: book, folder: folder, id: pickedHere),
                for (final id in ids)
                  if (id != pickedHere) card(id, compact: true),
              ] else
                for (final id in ids) card(id),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (both)
                SummaryCard(
                    book: book,
                    raceId: _selectedRaceId!,
                    professionId: _selectedProfessionId!),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: both || pickedHere == null
                    ? FilledButton.icon(
                        onPressed: !both
                            ? null
                            : () => _confirmStart(
                                  context,
                                  races[_selectedRaceId!]
                                      as Map<String, dynamic>,
                                  professions[_selectedProfessionId!]
                                      as Map<String, dynamic>,
                                ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(tr(ref, 'start_new_game_button')),
                      )
                    : FilledButton.tonalIcon(
                        key: const Key('rp_next'),
                        onPressed: () => setState(() {
                          _step = _step == 0 ? 1 : 0;
                          _listAll = false;
                        }),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(tr(ref,
                            _step == 0 ? 'rp_next_calling' : 'rp_next_people')),
                      ),
              ),
            ]),
          ),
        ),
      ],
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

/// A race's or profession's recap as one row (v1.266): its mark, name, tag
/// and the numbers it changes as chips, and the skill it grants as a line
/// under them. A tap opens the lore (and the skill's words) in a sheet.
class _ChoiceRow extends ConsumerWidget {
  const _ChoiceRow({
    required this.cardKey,
    required this.folder,
    required this.preset,
    required this.name,
    required this.withOffers,
    required this.skills,
  });

  final Key cardKey;
  final String folder;
  final Map<String, dynamic>? preset;
  final String name;
  final bool withOffers;
  final Map<String, dynamic> skills;

  String get _skillId => preset?['standardSkillID']?.toString() ?? '';

  String get _skillName => grantedSkillName(_skillId,
      presetId: (preset?['raceID'] ?? preset?['professionID'])?.toString());

  void _read(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IdentityCard(
                  cardKey: Key('${(cardKey as ValueKey).value}_lore'),
                  folder: folder,
                  preset: preset,
                  name: name,
                  withOffers: withOffers,
                ),
                if (_skillId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SkillCard(
                    label: tr(ref, 'granted_skill_label'),
                    skillId: _skillId,
                    name: _skillName,
                    description: (skills[_skillId]
                                as Map<String, dynamic>?)?['description']
                            ?.toString() ??
                        '',
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr(ref, 'close_button')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = preset?['tag']?.toString() ?? '';
    return Card(
      key: cardKey,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _read(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: PresetMark(folder: folder, preset: preset, size: 32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(name, style: theme.textTheme.titleLarge),
                        if (tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: scheme.primary.withValues(alpha: 0.14),
                              border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.6)),
                            ),
                            child: Text(tag.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.primary, letterSpacing: 0.8)),
                          ),
                      ],
                    ),
                    if (preset != null || _skillId.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (preset != null)
                            for (final e in presetBonuses(preset!,
                                withOffers: withOffers))
                              _BonusChip(label: tr(ref, e.key), value: e.value),
                          if (_skillId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: scheme.outlineVariant),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SkillPixelIcon(_skillId, size: 14),
                                  const SizedBox(width: 4),
                                  Text(_skillName,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
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

/// Full character info, shown once a race and profession are set. Race/
/// profession can only be changed by restarting the story from the
/// beginning (Node 0), not from here. When [onStartGame] is set (right
/// after creating a brand-new character), a Continue button is shown to
/// carry on into the story; viewed later from the Character hub, it's
/// read-only.
///
/// v1.267, "the dossier": everything at first glance in about one screen --
/// the name and level, the two choices as rows, health and experience as thin
/// bars with damage and armour, the radar beside the eight numbers, the
/// elements as chips and the belongings as one line. What needs room is a tap
/// away (a choice's lore, the elements' chart, the belongings' list); what a
/// number means is a press and hold away.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ink = InkColors.of(context);
    final raceName = race?['raceName']?.toString() ?? session.raceId;
    final professionName =
        profession?['professionName']?.toString() ?? session.professionId;
    String t(String key) => trFor(language, key);

    void read(String title, String description, {IconData? icon}) =>
        showDetailDialog(
          context,
          title: title,
          description: description,
          icon: icon,
          closeLabel: t('close_button'),
        );

    /// A card with the page's seam border.
    Widget panel({required Widget child, Key? key, EdgeInsets? padding}) =>
        Material(
          key: key,
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: ink.seam),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: child),
        );

    /// A thin bar with its caption and numbers: health, experience.
    Widget bar(String label, double value, String numbers, Color color,
        {String? description}) {
      final body = Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 7,
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(numbers, style: theme.textTheme.labelMedium),
        ],
      );
      if (description == null) return body;
      return InkWell(
        onTap: () => read(label, description),
        onLongPress: () => read(label, description),
        child: body,
      );
    }

    Widget chip(IconData icon, String text, String title, String description,
            {Key? key}) =>
        InkWell(
          key: key,
          borderRadius: BorderRadius.circular(4),
          onTap: () => read(title, description, icon: icon),
          onLongPress: () => read(title, description, icon: icon),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ink.seam),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: ink.gold),
                const SizedBox(width: 5),
                Text(text, style: theme.textTheme.labelMedium),
              ],
            ),
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
    final elements = elementPointsFor(session.equippedItemIds, items);
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

    void openBelongings() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.8),
              child: ListView(
                key: const Key('sheet_belongings_list'),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(t('sheet_belongings_title'),
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  for (final (i, (label, value)) in counters.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        border: i == counters.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: ink.seam)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(label,
                                  style: theme.textTheme.bodyLarge)),
                          const SizedBox(width: 12),
                          Text(value, style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

    void openElements() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElementsCard(
                key: const Key('sheet_elements_chart'),
                t: t,
                points: elements,
              ),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Who, and how far.
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session.characterName.isNotEmpty)
                    Text(session.characterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall),
                  Text('$raceName · $professionName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: scheme.primary.withValues(alpha: 0.14),
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.6)),
              ),
              child: Text('${t('level_field_label')} ${session.level}',
                  key: const Key('sheet_level'),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: scheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ChoiceRow(
          cardKey: const Key('sheet_race_card'),
          folder: 'races',
          preset: race,
          name: raceName,
          withOffers: false,
          skills: skills,
        ),
        const SizedBox(height: 8),
        _ChoiceRow(
          cardKey: const Key('sheet_profession_card'),
          folder: 'professions',
          preset: profession,
          name: professionName,
          withOffers: true,
          skills: skills,
        ),
        const SizedBox(height: 8),
        // Health and experience as thin bars, damage and armour as chips.
        panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bar(
                t('hp_label'),
                session.maxHealth == 0
                    ? 0
                    : session.currentHealth / session.maxHealth,
                '${session.currentHealth} / ${session.maxHealth}',
                ink.blood,
                description: t('max_health_desc'),
              ),
              const SizedBox(height: 7),
              bar(
                t('xp_label'),
                session.xpToNextLevel == 0
                    ? 0
                    : session.currentXP / session.xpToNextLevel,
                '${session.currentXP} / ${session.xpToNextLevel}',
                ink.gold,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  chip(
                      Icons.gavel,
                      '${t('damage_label')} ${session.baseDamage}',
                      t('base_damage_label'),
                      t('base_damage_desc'),
                      key: const Key('sheet_damage')),
                  chip(Icons.shield, '${t('arm_abbrev')} ${session.baseArmor}',
                      t('base_armor_label'), t('base_armor_desc'),
                      key: const Key('sheet_armor')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // The shape of the eight abilities beside their numbers.
        panel(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AbilityRadar(
                key: const Key('sheet_radar'),
                t: t,
                size: 176,
                compact: true,
                values: {for (final (k, v) in abilities) k: v},
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  key: const Key('sheet_abilities'),
                  children: [
                    for (final (i, (k, v)) in abilities.indexed)
                      InkWell(
                        onTap: () => read(t('${k}_label'), t('${k}_desc'),
                            icon: abilityIcon(k)),
                        onLongPress: () => read(t('${k}_label'), t('${k}_desc'),
                            icon: abilityIcon(k)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: i == abilities.length - 1
                                ? null
                                : Border(bottom: BorderSide(color: ink.seam)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(t('${k}_label'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: ink.ash)),
                              ),
                              Text('$v', style: theme.textTheme.titleSmall),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(t('hold_stat_for_details_hint'),
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
        ),
        // The elements: a chip each, the chart a tap away.
        panel(
          key: const Key('sheet_elements'),
          child: InkWell(
            key: const Key('sheet_elements_open'),
            onTap: elements.isEmpty ? null : openElements,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t('elements_title'),
                          style: theme.textTheme.titleSmall),
                    ),
                    if (!elements.isEmpty)
                      Icon(Icons.chevron_right, size: 18, color: ink.ash),
                  ],
                ),
                const SizedBox(height: 6),
                if (elements.isEmpty)
                  Text(t('elements_empty'),
                      key: const Key('elements_empty'),
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in elementChartOrder)
                        if ((elements.damage[e] ?? 0) != 0 ||
                            (elements.resist[e] ?? 0) != 0)
                          chip(
                            Icons.local_fire_department,
                            '${t('element_name_${e.toLowerCase()}')} '
                                '${elements.damage[e] ?? 0}/${elements.resist[e] ?? 0}',
                            t('element_name_${e.toLowerCase()}'),
                            '${t('elements_damage')}: ${elements.damage[e] ?? 0}\n'
                                '${t('elements_resist')}: ${elements.resist[e] ?? 0}',
                          ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // The belongings in one line, the list a tap away.
        panel(
          key: const Key('sheet_belongings'),
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: openBelongings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t('sheet_belongings_title'),
                        style: theme.textTheme.titleSmall),
                  ),
                  for (final (icon, count) in [
                    (Icons.monetization_on, session.gold),
                    (Icons.science_outlined, session.potionCount),
                    (Icons.backpack, session.inventoryItemIds.length),
                  ]) ...[
                    Icon(icon, size: 15, color: ink.gold),
                    const SizedBox(width: 3),
                    Text('$count', style: theme.textTheme.labelMedium),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.chevron_right, size: 18, color: ink.ash),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t('race_profession_footer_note'),
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
        if (onStartGame != null) ...[
          const SizedBox(height: 14),
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
