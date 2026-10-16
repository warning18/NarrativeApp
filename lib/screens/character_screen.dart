import '../widgets/feature_unlock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/game_icons.dart';
import '../data/offers.dart' show OfferSource;
import '../widgets/offer_dialog.dart';
import '../widgets/perk_list.dart';
import '../widgets/pixel_banner.dart';
import '../widgets/sign_widgets.dart';
import '../widgets/skills_radar_card.dart';
import '../widgets/title_widgets.dart';
import '../widgets/mana_meter.dart';
import 'dice_loadout_screen.dart';
import 'inventory_screen.dart';
import 'level_up_screen.dart';
import 'race_profession_screen.dart';
import 'skills/skills_screen.dart';

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

    final clansOpen = isFeatureUnlocked(ref, GameFeature.clans.id);
    final tab = clansOpen ? ref.watch(_characterTabProvider) : 0;
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CharacterHeader(subtitle: subtitle),
        const SizedBox(height: 12),
        const _CharacterTabs(),
        const SizedBox(height: 12),
        switch (tab) {
          1 => const _GiftsTab(),
          2 => _PagesTab(subtitle: subtitle, isEditMode: isEditMode),
          _ => const _OverviewTab(),
        },
      ],
    );
    final triggered = TutorialTrigger(
        topic: TutorialTopic.character,
        ready: session.raceId.isNotEmpty,
        child: body);
    if (embedded) return triggered;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'character'))),
      body: triggered,
    );
  }
}

/// The top of the character sheet: who the character is, their level and
/// experience, health, mana and gold, and any points waiting. Under it, three
/// tabs (v1.267): Overview, Gifts, Pages.
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TutorialTarget(
          id: 'character.header',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ink.gold, width: 2),
                    ),
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: ink.gold),
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
                        // The title worn (see offers.dart's titles), with
                        // the race and profession.
                        Text.rich(
                          TextSpan(children: [
                            if (activeTitleName(ref) case final title
                                when title.isNotEmpty)
                              TextSpan(
                                text: title,
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: ink.gold,
                                    fontStyle: FontStyle.italic),
                              ),
                            if (activeTitleName(ref).isNotEmpty)
                              TextSpan(
                                  text: ' · ',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: ink.ash)),
                            TextSpan(
                                text: subtitle,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: ink.ash)),
                          ]),
                          key: const Key('character_title'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  vital(
                      tr(ref, 'hp_label'),
                      '${session.currentHealth}/${session.maxHealth}',
                      ink.blood),
                  const SizedBox(width: 8),
                  vital(tr(ref, 'mana_label'),
                      '${session.mana}/${session.maxMana}', manaColor),
                  const SizedBox(width: 8),
                  vital(tr(ref, 'gold_label'), '${session.gold}', ink.gold),
                ],
              ),
            ],
          ),
        ),
        // Stat points are spent on Level Up: a button while some wait.
        if (session.statPoints > 0) ...[
          const SizedBox(height: 10),
          FilledButton(
            key: const Key('character_level_up'),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LevelUpScreen()),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        key: const Key('character_stat_points'),
                        statPointsText(ref, session.statPoints))),
                Text(tr(ref, 'level_up')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Which tab the Character page is on (kept for the session).
final _characterTabProvider = StateProvider<int>((ref) => 0);

/// The three tabs under the header (v1.267): Overview (the abilities as a
/// radar, the skills known, the alignment), Gifts (titles, perks, signs, the
/// offer waiting) and Pages (mana and the links).
class _CharacterTabs extends ConsumerWidget {
  const _CharacterTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_characterTabProvider);
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final gifts = session.heldTitleIds.length +
        session.perkRanks.values.where((r) => r > 0).length +
        session.heldSigns.length;
    final waiting = session.pendingOffers.length;

    Widget segment(int index, String key, String label, {Widget? after}) {
      final on = tab == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: InkWell(
            key: Key('character_tab_$key'),
            onTap: () {
              if (index == 1) acknowledgeOnOpen(ref, GameFeature.clans);
              ref.read(_characterTabProvider.notifier).state = index;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              color: on ? theme.colorScheme.primaryContainer : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: on ? ink.gold : ink.ash)),
                  ),
                  if (after != null) ...[const SizedBox(width: 5), after],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return TutorialTarget(
      id: 'character.pages',
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: ink.seam),
        ),
        child: Row(
          children: [
            segment(0, 'overview', tr(ref, 'tab_overview')),
            if (isFeatureUnlocked(ref, GameFeature.clans.id))
              segment(
                1,
                'gifts',
                tr(ref, 'tab_gifts'),
                after: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UnlockDot(feature: GameFeature.clans),
                    if (waiting > 0)
                      Semantics(
                        label: tr(ref, 'gifts_waiting_label'),
                        child: Container(
                          key: const Key('character_gifts_dot'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: ink.blood, shape: BoxShape.circle),
                        ),
                      )
                    else if (gifts > 0)
                      Text('$gifts',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.gold)),
                  ],
                ),
              ),
            segment(2, 'pages', tr(ref, 'tab_pages')),
          ],
        ),
      ),
    );
  }
}

/// Overview: the eight abilities as a radar, the skills known, and where the
/// alignment stands.
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignment =
        ref.watch(playerSessionProvider.select((s) => s.alignmentScore));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TutorialTarget(
          id: 'character.abilities',
          child: SkillsRadarCard(),
        ),
        const SizedBox(height: 10),
        TutorialTarget(
          id: 'character.alignment',
          child: _AlignmentBar(score: alignment),
        ),
      ],
    );
  }
}

/// Gifts: the titles as chips, the perks, the signs, and the clans' offer
/// waiting.
class _GiftsTab extends ConsumerWidget {
  const _GiftsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final waiting = session.pendingOffers.length;
    final perks = session.perkRanks.values.where((r) => r > 0).length;

    Widget card(Key key, Widget child) => Material(
          key: key,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: ink.seam),
          ),
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The clans' offers (see offers.dart): the one waiting, if any.
        Material(
          key: const Key('character_offers'),
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: waiting > 0 ? ink.gold : ink.seam),
          ),
          // Where offers come from, for a press and hold on the row.
          child: Tooltip(
            message: tr(ref, 'offers_where_from'),
            child: InkWell(
              key: const Key('offer_open'),
              borderRadius: BorderRadius.circular(4),
              onTap: waiting > 0
                  ? () => showOfferIfWaiting(context, ref, sayWhenNone: true)
                  : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Icon(Icons.diversity_3,
                        size: 18, color: waiting > 0 ? ink.gold : ink.ash),
                    const SizedBox(width: 8),
                    Text(tr(ref, 'offers_section'),
                        style: theme.textTheme.titleSmall),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        waiting > 0
                            ? '${tr(ref, 'offer_open_button')} · '
                                '${tr(ref, 'offer_pending').replaceAll('{n}', '$waiting')}'
                            : tr(ref, 'offers_row_none'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: waiting > 0 ? ink.gold : ink.ash),
                      ),
                    ),
                    if (waiting > 0)
                      Icon(Icons.chevron_right, size: 20, color: ink.ash),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Titles (see offers.dart): chips, the one worn in gold.
        card(const Key('character_titles'), const TitleChips()),
        const SizedBox(height: 8),
        // Perk ranks (see perks.dart): the Wayfarer's gifts.
        card(
          const Key('character_perks'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(tr(ref, 'perk_section'),
                      style: theme.textTheme.titleSmall),
                  if (perks > 0) ...[
                    const SizedBox(width: 8),
                    Text('$perks',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              const PerkList(compact: true),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Signs (see signs.dart): the patrons' boons for this life.
        card(const Key('character_signs'), const SignsSection()),
      ],
    );
  }
}

/// Pages: mana and spells, the Shroud, a New Game+ cycle, and the links.
class _PagesTab extends ConsumerWidget {
  const _PagesTab({required this.subtitle, required this.isEditMode});

  final String subtitle;
  final bool isEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    Widget tile(IconData icon, String label, Widget page,
            {String? note, GameFeature? feature}) =>
        _PageTile(
            icon: icon, label: label, note: note, page: page, feature: feature);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (session.newGamePlusCycle > 0) const _NewGamePlusCard(),
        const _ManaSpellsCard(),
        if (session.bannerPiecesCollected.isNotEmpty &&
            isFeatureUnlocked(ref, GameFeature.inventory.id))
          const _ShroudCard(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: tile(Icons.backpack, tr(ref, 'tile_inventory'),
                    const InventoryScreen(),
                    feature: GameFeature.inventory),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(Icons.casino, tr(ref, 'tile_dice'),
                    const DiceLoadoutScreen(),
                    feature: GameFeature.inventory),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: tile(Icons.trending_up, tr(ref, 'level_up'),
                    const LevelUpScreen()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                    Icons.badge_outlined,
                    tr(ref, 'race_profession_title'),
                    const RaceProfessionScreen(),
                    note: subtitle),
              ),
            ],
          ),
        ),
        if (isEditMode) ...[
          const SizedBox(height: 16),
          const _DebugStatsEditor(),
        ],
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        key: const Key('character_mana'),
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
            MaterialPageRoute(
                builder: (_) => const SkillsScreen(initialTab: 2)),
          );
        },
      ),
    );
  }
}

/// A page's tile on the Character tab: its icon and name, and what it holds
/// in a line when that helps.
class _PageTile extends ConsumerWidget {
  const _PageTile({
    required this.icon,
    required this.label,
    required this.page,
    this.note,
    this.feature,
  });

  final IconData icon;
  final String label;
  final String? note;
  final Widget page;

  /// The ladder feature that opens this page, when it is on the ladder.
  final GameFeature? feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    if (feature != null && !isFeatureUnlocked(ref, feature!.id)) {
      return FeatureLockedTile(feature: feature!, title: label);
    }
    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: ink.seam),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (feature != null) acknowledgeOnOpen(ref, feature!);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ink.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium),
                    if (note != null && note!.isNotEmpty)
                      Text(note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                  ],
                ),
              ),
              if (feature != null) UnlockDot(feature: feature!),
            ],
          ),
        ),
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _apply,
                  child: Text(tr(ref, 'apply_button')),
                ),
                // Offers (see offers.dart), to test one without playing to
                // the next level: one now, or one more waiting.
                OutlinedButton(
                  key: const Key('debug_offer_now'),
                  onPressed: () async {
                    await ref
                        .read(playerSessionProvider.notifier)
                        .grantOffer(OfferSource.edit);
                    if (context.mounted) {
                      await showOfferIfWaiting(context, ref, sayWhenNone: true);
                    }
                  },
                  child: Text(tr(ref, 'debug_offer_now')),
                ),
                OutlinedButton(
                  key: const Key('debug_offer_plus'),
                  onPressed: () => ref
                      .read(playerSessionProvider.notifier)
                      .grantOffer(OfferSource.edit),
                  child: Text(tr(ref, 'debug_offer_plus')),
                ),
                OutlinedButton(
                  key: const Key('debug_titan_blood'),
                  onPressed: () => ref
                      .read(playerSessionProvider.notifier)
                      .grantTitanBlood(1),
                  child: Text(tr(ref, 'debug_titan_blood')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The Shroud, in its six banners: each recovered piece in colour, the
/// others a dark silhouette waiting to be found.
class _ShroudCard extends ConsumerWidget {
  const _ShroudCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collected =
        ref.watch(playerSessionProvider.select((s) => s.bannerPiecesCollected));
    final found = collected.toSet();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tr(ref, 'banner_pieces_title'),
                      style: theme.textTheme.titleMedium),
                ),
                Text('${found.length} / ${shroudPieceIds.length}',
                    style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final id in shroudPieceIds)
                  _ShroudPiece(id: id, found: found.contains(id)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShroudPiece extends ConsumerWidget {
  const _ShroudPiece({required this.id, required this.found});

  final String id;
  final bool found;

  /// Each banner at 40 x 80, small enough for six in a row; its name is a
  /// tap (or a hold) away.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label =
        found ? tr(ref, 'banner_piece_$id') : tr(ref, 'banner_piece_unfound');
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        triggerMode: TooltipTriggerMode.tap,
        child: ExcludeSemantics(
          child: SizedBox(
            key: Key('shroud_piece_$id'),
            width: 40,
            height: 80,
            child:
                FittedBox(child: PixelBanner(id: id, scale: 1, found: found)),
          ),
        ),
      ),
    );
  }
}

/// "1 Stat Point", "2 Stat Points" ("0 Point de statistique" in French, which
/// keeps the singular for none).
String statPointsText(WidgetRef ref, int n) {
  final one = n == 1 || (n == 0 && ref.read(appLanguageProvider).name == 'fr');
  return '$n ${tr(ref, one ? 'stat_point_label_one' : 'stat_points_label')}';
}
