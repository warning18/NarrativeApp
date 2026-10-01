import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../data/offers.dart' show OfferSource;
import '../data/politics_events.dart';
import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/offers_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/signs_provider.dart';
import '../widgets/clan_widgets.dart';
import '../widgets/offer_dialog.dart';
import '../widgets/sign_widgets.dart';
import '../widgets/throne_edit_tab.dart';

/// Edit Mode's "Clans & Politics" (v1.193, see factions.dart), from the
/// top bar's scales: four tabs.
/// - **Standing:** a card per faction (the clans, the tribes, the Choir and
///   the Pit) with a slider to set it and squares to mark the sub-clans,
///   the Choir-Pit alignment with the vows and pacts held, and a reset;
///   the lost clan (the Open Hand, v1.195) with its remembrance stage to
///   set and its banner.
/// - **Politics:** the clans' relations table, as it stands or as it stood
///   at an earlier chapter, the politics events (v1.195: fired or not, and
///   "Fire now"), and the coast's history.
/// - **Evolution:** each clan's standing over the log, then the log (the
///   events' news among it, under `event:<id>`).
/// - **Intrigues:** the eight plots, the stage each has reached, and their
///   outcomes.
/// - **Throne** (v1.196, see throne.dart): each faction's climb (its
///   House, its clan steps, the claim, the Throne) with buttons to set
///   it, pledges, and "Muster now" with a preview of the Host.
class ClansPoliticsScreen extends ConsumerWidget {
  const ClansPoliticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'clans_title')),
          bottom: TabBar(
            // Five tabs scroll on a narrow phone rather than squeeze.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            tabs: [
              Tab(
                  key: const Key('clans_tab_standing'),
                  text: tr(ref, 'clans_tab_standing')),
              Tab(
                  key: const Key('clans_tab_politics'),
                  text: tr(ref, 'clans_tab_politics')),
              Tab(
                  key: const Key('clans_tab_evolution'),
                  text: tr(ref, 'clans_tab_evolution')),
              Tab(
                  key: const Key('clans_tab_intrigues'),
                  text: tr(ref, 'clans_tab_intrigues')),
              Tab(
                  key: const Key('clans_tab_throne'),
                  text: tr(ref, 'clans_tab_throne')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StandingTab(),
            _PoliticsTab(),
            _EvolutionTab(),
            _IntriguesTab(),
            ThroneEditTab(),
          ],
        ),
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1),
      ),
    );

// --- Standing ---------------------------------------------------------------

class _StandingTab extends ConsumerWidget {
  const _StandingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final theme = Theme.of(context);
    if (data.factions.isEmpty) {
      return Center(child: Text(tr(ref, 'clans_none')));
    }
    return ListView(
      key: const Key('clans_standing_list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(tr(ref, 'clans_edit_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        for (final faction in data.clans)
          FactionStandingCard(faction: faction, editable: true),
        if (data.tribes.isNotEmpty) ...[
          _sectionLabel(context, tr(ref, 'clans_tribes_label')),
          for (final faction in data.tribes)
            FactionStandingCard(faction: faction, editable: true),
        ],
        if (data.lost.isNotEmpty) ...[
          _sectionLabel(context, tr(ref, 'patron_kind_lost')),
          for (final faction in data.lost)
            LostClanCard(faction: faction, editable: true),
        ],
        _sectionLabel(context, tr(ref, 'clans_alignment_title')),
        const _OtherworldPanel(),
        for (final faction in data.otherworld)
          FactionStandingCard(faction: faction, editable: true),
        const SizedBox(height: 12),
        // Edit Mode: an offer from the clans now, or one more waiting (see
        // offers.dart), and the coast as the story opens.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('clans_offer_now'),
              icon: const Icon(Icons.diversity_3),
              label: Text(tr(ref, 'debug_offer_now')),
              onPressed: () async {
                await ref
                    .read(playerSessionProvider.notifier)
                    .grantOffer(OfferSource.edit);
                if (context.mounted) {
                  await showOfferIfWaiting(context, ref, sayWhenNone: true);
                }
              },
            ),
            OutlinedButton.icon(
              key: const Key('clans_offer_plus'),
              icon: const Icon(Icons.add),
              label: Text(tr(ref, 'debug_offer_plus')),
              onPressed: () => ref
                  .read(playerSessionProvider.notifier)
                  .grantOffer(OfferSource.edit),
            ),
            OutlinedButton.icon(
              key: const Key('clans_reset'),
              icon: const Icon(Icons.restart_alt),
              label: Text(tr(ref, 'reset')),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final done = tr(ref, 'clans_reset_done');
                await ref
                    .read(playerSessionProvider.notifier)
                    .resetPolitics(data: ref.read(clanDataProvider));
                messenger.showSnackBar(SnackBar(content: Text(done)));
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The alignment between the Pit and the Choir, where each starts to
/// come, and what is held of theirs: vows (and those silent), pacts (and
/// those still binding), and which of the two has claimed this life.
class _OtherworldPanel extends ConsumerWidget {
  const _OtherworldPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final patrons = ref.watch(patronsProvider);
    final signs = ref.watch(signDefsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final choir = patrons[choirPatronId];
    final pit = patrons[pitPatronId];
    final alignment = session.alignmentScore;
    final vows = [
      for (final h in session.heldSigns)
        if (signs[h.signId]?.patronId == choirPatronId) h,
    ];
    final silent =
        vows.where((h) => vowSilent(signs[h.signId]!, alignment)).length;
    final pacts = [
      for (final h in session.heldSigns)
        if (signs[h.signId]?.patronId == pitPatronId) h,
    ];
    final binding = pacts.where((h) => h.pactPending).length;
    final claim = otherworldClaimOf(session.signPatronsThisLife, patrons);
    final choirFloor = choir?.minAlignment ?? 10;
    final pitCeiling = pit?.maxAlignment ?? -10;
    final span = max(30, max(choirFloor.abs(), pitCeiling.abs()) * 3);
    double at(int score) => ((score + span) / (span * 2)).clamp(0.0, 1.0);
    final small = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      key: const Key('clans_otherworld'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PatronEmblem(patron: pit, size: 24),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${pit?.nameFor(lang) ?? ''} ≤ ${formatStanding(pitCeiling)}',
                    style: small,
                  ),
                ),
                Text(
                  '${tr(ref, 'alignment_label')} ${formatStanding(alignment)}',
                  style: theme.textTheme.labelLarge,
                ),
                Expanded(
                  child: Text(
                    '${choir?.nameFor(lang) ?? ''} ≥ ${formatStanding(choirFloor)}',
                    style: small,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 6),
                PatronEmblem(patron: choir, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              return SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: 5,
                      bottom: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(colors: [
                            Color(pit?.color ?? 0xFFA94BB4),
                            theme.colorScheme.surfaceContainerHighest,
                            Color(choir?.color ?? 0xFFAD8A10),
                          ]),
                        ),
                      ),
                    ),
                    for (final mark in [pitCeiling, 0, choirFloor])
                      Positioned(
                        left: w * at(mark) - 0.5,
                        top: 3,
                        bottom: 3,
                        child: Container(
                            width: 1, color: theme.colorScheme.outline),
                      ),
                    Positioned(
                      left: (w * at(alignment) - 2).clamp(0, w - 4),
                      top: 0,
                      bottom: 0,
                      child: Container(
                          width: 4, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Text(
              tr(ref, 'clans_vows_state')
                  .replaceAll('{n}', '${vows.length}')
                  .replaceAll('{s}', '$silent'),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              tr(ref, 'clans_pacts_state')
                  .replaceAll('{n}', '${pacts.length}')
                  .replaceAll('{r}', '$binding'),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              claim == null
                  ? tr(ref, 'clans_otherworld_open')
                  : tr(ref, 'clans_otherworld_claim').replaceAll(
                      '{name}', patrons[claim]?.nameFor(lang) ?? claim),
              style: small,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Politics ---------------------------------------------------------------

class _PoliticsTab extends ConsumerStatefulWidget {
  const _PoliticsTab();

  @override
  ConsumerState<_PoliticsTab> createState() => _PoliticsTabState();
}

class _PoliticsTabState extends ConsumerState<_PoliticsTab> {
  /// The chapter the table shows; null for now.
  int? _chapter;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(politicsProvider);
    final lang = ref.watch(appLanguageProvider);
    final reached = ref.watch(reachedChapterProvider);
    final theme = Theme.of(context);
    final latest = [
      max(1, reached),
      ...politics.relationSnapshots.keys,
    ].reduce(max);
    // Up to the story's last chapter (chapters.json), or the latest the
    // relations moved in.
    final storyEnd = ref
        .watch(chapterLoopsProvider)
        .fold<int>(1, (most, loop) => max(most, loop.chapter));
    final last = max(storyEnd, latest);
    final chapter = (_chapter ?? last).clamp(1, last);
    final now = chapter >= latest;
    final steps = now
        ? {
            ...data.relations.baseSteps,
            ...politics.relationSteps,
          }
        : relationsAtChapter(politics, chapter, data);
    return ListView(
      key: const Key('clans_politics_list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Text(
          now
              ? tr(ref, 'clans_chapter_now')
              : tr(ref, 'clans_chapter_label').replaceAll('{n}', '$chapter'),
          key: const Key('clans_chapter_label'),
          style: theme.textTheme.titleSmall,
        ),
        Slider(
          key: const Key('clans_chapter_slider'),
          min: 1,
          max: last.toDouble(),
          divisions: last - 1,
          value: chapter.toDouble(),
          label: '$chapter',
          onChanged: (v) => setState(() => _chapter = v.round()),
        ),
        _RelationsMatrix(steps: steps, data: data, language: lang),
        const SizedBox(height: 4),
        Text(tr(ref, 'clans_matrix_hint'),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        _sectionLabel(context, tr(ref, 'clans_history_title')),
        for (final event in data.relations.history)
          _HistoryRow(event: event, language: lang),
        _sectionLabel(context, tr(ref, 'clans_events_title')),
        const _EventsList(),
      ],
    );
  }
}

/// The clans' relations, a row and a column per clan, each cell the step's
/// word in its colour. Scrolls sideways when the phone is too narrow.
class _RelationsMatrix extends ConsumerWidget {
  const _RelationsMatrix({
    required this.steps,
    required this.data,
    required this.language,
  });

  final Map<String, int> steps;
  final ClanData data;
  final AppLanguage language;

  static const double _cell = 60;
  static const double _header = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clans = data.clans;
    final theme = Theme.of(context);
    Widget head(Faction f) => SizedBox(
          width: _cell,
          height: _header,
          child: Center(
            child: Tooltip(
              message: f.nameFor(language),
              child: PatronEmblem(patron: f.patron, size: 26),
            ),
          ),
        );
    Widget cell(Faction a, Faction b) {
      if (a.id == b.id) {
        return SizedBox(
          width: _cell,
          height: 44,
          child: Center(
              child: Text('—',
                  style: TextStyle(color: theme.colorScheme.outline))),
        );
      }
      final step = steps[relationKey(a.id, b.id)];
      final info = step == null ? null : data.relations.stepInfo(step);
      final color = Color(info?.color ?? 0xFFA8A194);
      return Padding(
        padding: const EdgeInsets.all(1.5),
        child: InkWell(
          key: Key('relation_cell_${a.id}_${b.id}'),
          onTap: () => _showPair(context, ref, a, b),
          child: Container(
            width: _cell - 3,
            height: 41,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color.withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              info?.nameFor(language) ?? (step == null ? '·' : '$step'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('clans_matrix'),
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const SizedBox(width: _header, height: _header),
            for (final f in clans) head(f),
          ]),
          for (final a in clans)
            Row(children: [
              SizedBox(
                width: _header,
                height: 44,
                child: Center(
                  child: Tooltip(
                    message: a.nameFor(language),
                    child: PatronEmblem(patron: a.patron, size: 26),
                  ),
                ),
              ),
              for (final b in clans) cell(a, b),
            ]),
        ],
      ),
    );
  }

  /// The pair's step, why they stand there, how they moved, and Edit
  /// Mode's shift by a step.
  Future<void> _showPair(
      BuildContext context, WidgetRef ref, Faction a, Faction b) async {
    final lang = language;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(builder: (context, ref, _) {
        final politics = ref.watch(politicsProvider);
        final step = politics.relationStep(a.id, b.id, data);
        final info = step == null ? null : data.relations.stepInfo(step);
        final reason = data.relations.pair(a.id, b.id)?.reasonFor(lang) ?? '';
        final moves = [
          for (final e in politics.relationsLog)
            if (e.key == relationKey(a.id, b.id)) e,
        ];
        String stepName(int s) =>
            data.relations.stepInfo(s)?.nameFor(lang) ?? '$s';
        final theme = Theme.of(context);
        final notifier = ref.read(playerSessionProvider.notifier);
        // Logged at the chapter reached, or the latest one a pair moved
        // in: the snapshots replay in order.
        Future<void> shift(int by) => notifier.shiftRelation(a.id, b.id, by,
            data: data,
            cause: 'edit',
            chapter: [
              max(1, ref.read(reachedChapterProvider)),
              ...politics.relationSnapshots.keys,
            ].reduce(max));
        return AlertDialog(
          title: Text(trFor(lang, 'clans_pair_title')
              .replaceAll('{a}', a.nameFor(lang))
              .replaceAll('{b}', b.nameFor(lang))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info?.nameFor(lang) ?? '—',
                  key: const Key('relation_dialog_step'),
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: Color(info?.color ?? 0xFFA8A194),
                      fontWeight: FontWeight.w700),
                ),
                if (reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(reason,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  ),
                for (final e in moves.reversed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      trFor(lang, 'clans_pair_moved')
                          .replaceAll('{c}', '${e.chapter}')
                          .replaceAll('{d}', '${e.day}')
                          .replaceAll('{from}', stepName(e.from))
                          .replaceAll('{to}', stepName(e.to))
                          .replaceAll(
                              '{cause}', standingCauseLabel(e.cause, lang)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('relation_shift_down'),
              onPressed: step == null || step <= minRelationStep
                  ? null
                  : () => shift(-1),
              child: Text(trFor(lang, 'clans_shift_down')),
            ),
            TextButton(
              key: const Key('relation_shift_up'),
              onPressed: step == null || step >= maxRelationStep
                  ? null
                  : () => shift(1),
              child: Text(trFor(lang, 'clans_shift_up')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(trFor(lang, 'close_button')),
            ),
          ],
        );
      }),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.event, required this.language});

  final HistoryEvent event;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 76,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: Text(event.yearFor(language),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          Container(width: 2, color: theme.colorScheme.outlineVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.nameFor(language),
                      style: theme.textTheme.titleSmall),
                  if (event.textFor(language).isNotEmpty)
                    Text(event.textFor(language),
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Evolution --------------------------------------------------------------

class _EvolutionTab extends ConsumerWidget {
  const _EvolutionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(politicsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final clans = data.clans;
    final ids = [for (final c in clans) c.id];
    final history = standingHistory(politics, data, ids);
    final moving = [
      for (final e in politics.standingLog)
        if (e.deltas.isNotEmpty) e,
    ];
    final ticks = [
      trFor(lang, 'clans_chart_start'),
      for (final e in moving)
        trFor(lang, 'clans_chart_tick')
            .replaceAll('{c}', '${e.chapter}')
            .replaceAll('{d}', '${e.day}'),
    ];
    String name(String id) => data.faction(id)?.nameFor(lang) ?? id;
    String sub(String id) => data.subclan(id)?.nameFor(lang) ?? id;
    // An offer's cause names its gift (see offers.dart's offerCause).
    final tables = ref.watch(offerTablesProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final events = ref.watch(politicsEventsProvider);
    String? describe(String kind, String detail) => switch (kind) {
          'offer' => offerGiftLabel(detail,
              tables: tables, localizedItems: items, lang: lang),
          // An event's line names it (v1.195).
          'event' => eventCauseName(detail, events, lang),
          // The claim given up names its faction (v1.196).
          'renounce' => name(detail),
          _ => null,
        };

    return ListView(
      key: const Key('clans_evolution_list'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            key: const Key('clans_chart'),
            painter: _StandingChartPainter(
              history: history,
              lines: [
                for (final c in clans) (id: c.id, color: Color(c.color)),
              ],
              ticks: ticks,
              labelStyle: theme.textTheme.labelSmall!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
              axis: theme.colorScheme.outlineVariant,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final c in clans)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: Color(c.color)),
                  const SizedBox(width: 4),
                  Text(c.nameFor(lang), style: theme.textTheme.labelSmall),
                ],
              ),
          ],
        ),
        _sectionLabel(context, tr(ref, 'clans_log_title')),
        if (politics.standingLog.isEmpty)
          Text(tr(ref, 'clans_evolution_empty'),
              style: theme.textTheme.bodySmall),
        for (final e in politics.standingLog.reversed)
          _LogTile(
            entry: e,
            language: lang,
            factionName: name,
            subclanName: sub,
            describe: describe,
          ),
        if (politics.relationsLog.isNotEmpty) ...[
          _sectionLabel(context, tr(ref, 'clans_relations_log_title')),
          for (final e in politics.relationsLog.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${name(e.a)} – ${name(e.b)}'
                '${lang == AppLanguage.fr ? '\u00a0:' : ':'} '
                '${data.relations.stepInfo(e.from)?.nameFor(lang) ?? e.from} → '
                '${data.relations.stepInfo(e.to)?.nameFor(lang) ?? e.to} · '
                '${standingCauseLabel(e.cause, lang, describe: describe)} · '
                '${trFor(lang, 'clans_log_when').replaceAll('{c}', '${e.chapter}').replaceAll('{d}', '${e.day}')}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }
}

/// One line of the standing log: its cause and when, then the faction's
/// own change, the ripple's, a mark set, or the banner changing hands.
class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.entry,
    required this.language,
    required this.factionName,
    required this.subclanName,
    this.describe,
  });

  final StandingLogEntry entry;
  final AppLanguage language;
  final String Function(String id) factionName;
  final String Function(String id) subclanName;

  /// Names a cause's detail (an offer's gift), see standingCauseLabel.
  final String? Function(String kind, String detail)? describe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = language;
    Widget delta(String id, double d, {bool main = false}) => Text(
          '${factionName(id)} ${formatStandingDelta(d, language: lang)}',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: main ? FontWeight.w700 : null,
            color: readableOn(context,
                d > 0 ? standingTierColor(StandingTier.trusted) : clanFoeColor),
          ),
        );
    final colon = lang == AppLanguage.fr ? '\u00a0:' : ':';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    standingCauseLabel(entry.cause, lang, describe: describe),
                    style: theme.textTheme.bodyMedium),
              ),
              Text(
                trFor(lang, 'clans_log_when')
                    .replaceAll('{c}', '${entry.chapter}')
                    .replaceAll('{d}', '${entry.day}'),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              if (entry.deltas.containsKey(entry.factionId))
                delta(entry.factionId, entry.mainDelta, main: true),
              // The climb's lines that move no standing (v1.196): a
              // pledge, the crown, the muster name their faction.
              if (entry.deltas.isEmpty &&
                  entry.subclanId.isEmpty &&
                  entry.factionId.isNotEmpty)
                Text(factionName(entry.factionId),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              for (final e in entry.rippleDeltas.entries) delta(e.key, e.value),
              if (entry.subclanId.isNotEmpty && entry.mark != null)
                Text(
                  '${subclanName(entry.subclanId)}$colon '
                  '${trFor(lang, subclanMarkKey(entry.mark!))}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: entry.mark == SubclanMark.foe
                          ? readableOn(context, clanFoeColor)
                          : null),
                ),
              if (entry.swore.isNotEmpty)
                Text(
                  trFor(lang, 'clans_log_swore')
                      .replaceAll('{name}', factionName(entry.swore)),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: standingTierTextColor(context, StandingTier.sworn),
                      fontWeight: FontWeight.w700),
                ),
              if (entry.released.isNotEmpty)
                Text(
                  trFor(lang, 'clans_log_released')
                      .replaceAll('{name}', factionName(entry.released)),
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
          // An event's news (v1.195).
          if (entry.noteFor(lang).isNotEmpty)
            Text(
              entry.noteFor(lang),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

/// The politics events (v1.195, see politics_events.dart): each with when
/// it fires by itself, whether it has fired (when, and the variant it
/// took), and "Fire now".
class _EventsList extends ConsumerWidget {
  const _EventsList();

  String _trigger(PoliticsEvent event, AppLanguage lang) {
    if (event.triggers.isEmpty) return trFor(lang, 'clans_event_by_story');
    String one(EventTrigger t) => [
          if (t.chapter != null)
            trFor(lang, 'clans_event_trigger_chapter')
                .replaceAll('{n}', '${t.chapter}'),
          if (t.day != null)
            trFor(lang, 'clans_event_trigger_day')
                .replaceAll('{n}', '${t.day}'),
          for (final f in t.flags)
            trFor(lang, 'clans_event_trigger_flag').replaceAll('{f}', f),
        ].join(', ');
    return event.triggers.map(one).join(' ${trFor(lang, 'clans_event_or')} ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(politicsEventsProvider);
    final politics = ref.watch(politicsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return Text(tr(ref, 'clans_events_none'),
          style: theme.textTheme.bodySmall);
    }
    return Column(
      key: const Key('clans_events_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in events.values)
          Card(
            key: Key('politics_event_${event.id}'),
            margin: const EdgeInsets.symmetric(vertical: 3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.nameFor(lang),
                            style: theme.textTheme.titleSmall),
                        Text(
                          _trigger(event, lang),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          switch (politics.firedEvents[event.id]) {
                            final fired? => trFor(lang, 'clans_event_fired')
                                .replaceAll('{c}', '${fired.chapter}')
                                .replaceAll('{d}', '${fired.day}')
                                .replaceAll('{v}', '${fired.variant + 1}'),
                            null => trFor(lang, 'clans_event_waiting'),
                          },
                          key: Key('politics_event_state_${event.id}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: politics.hasFired(event.id)
                                  ? standingTierTextColor(
                                      context, StandingTier.sworn)
                                  : null,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: Key('politics_event_fire_${event.id}'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final done = trFor(lang, 'clans_event_fired_notice')
                          .replaceAll('{name}', event.nameFor(lang));
                      await fireCoastEventNow(ref, event.id);
                      messenger.showSnackBar(SnackBar(content: Text(done)));
                    },
                    child: Text(trFor(lang, 'clans_event_fire_now')),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Each clan's standing over the log: x the entries in order (labelled by
/// chapter and day), y -100..+100 over the tiers' bands.
class _StandingChartPainter extends CustomPainter {
  _StandingChartPainter({
    required this.history,
    required this.lines,
    required this.ticks,
    required this.labelStyle,
    required this.axis,
  });

  final List<Map<String, double>> history;
  final List<({String id, Color color})> lines;
  final List<String> ticks;
  final TextStyle labelStyle;
  final Color axis;

  static const double _left = 30;
  static const double _bottom = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final chart =
        Rect.fromLTRB(_left, 4, size.width - 4, size.height - _bottom);
    double y(num v) =>
        chart.bottom -
        (v.clamp(minStanding, maxStanding) - minStanding) /
            (maxStanding - minStanding) *
            chart.height;
    for (final tier in StandingTier.values) {
      final info = standingTiers[tier]!;
      final top = y(min(maxStanding, info.max + 0.5));
      final bottom = y(max(minStanding, info.min - 0.5));
      canvas.drawRect(Rect.fromLTRB(chart.left, top, chart.right, bottom),
          Paint()..color = Color(info.color).withValues(alpha: 0.12));
    }
    final axisPaint = Paint()
      ..color = axis
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(chart.left, y(0)), Offset(chart.right, y(0)), axisPaint);
    canvas.drawLine(chart.topLeft, chart.bottomLeft, axisPaint);
    for (final v in [100, 0, -100]) {
      _text(canvas, formatStanding(v), Offset(0, y(v) - 6),
          maxWidth: _left - 4);
    }
    final n = history.length;
    double x(int i) =>
        n <= 1 ? chart.center.dx : chart.left + chart.width * i / (n - 1);
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final v = history[i][line.id];
        if (v == null) continue;
        final p = Offset(x(i), y(v));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawCircle(p, 2.2, Paint()..color = line.color);
      }
      canvas.drawPath(path, paint);
    }
    // A few x labels, never crowding: the first, the last, and evenly
    // some between.
    final labels = min(n, ticks.length);
    if (labels == 0) return;
    final room = max(2, (chart.width / 60).floor());
    final shown = <int>{
      0,
      labels - 1,
      if (labels > 2)
        for (var k = 1; k < room - 1; k++)
          ((labels - 1) * k / (room - 1)).round(),
    };
    for (final i in shown) {
      final left = (x(i) - 28).clamp(0.0, max(0.0, size.width - 56)).toDouble();
      _text(canvas, ticks[i], Offset(left, chart.bottom + 3),
          maxWidth: 56, center: true);
    }
  }

  void _text(Canvas canvas, String text, Offset at,
      {required double maxWidth, bool center = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle.copyWith(fontSize: 9)),
      textDirection: TextDirection.ltr,
      textAlign: center ? TextAlign.center : TextAlign.right,
      maxLines: 1,
      ellipsis: '…',
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_StandingChartPainter old) =>
      old.history != history || old.ticks != ticks || old.axis != axis;
}

// --- Intrigues --------------------------------------------------------------

class _IntriguesTab extends ConsumerWidget {
  const _IntriguesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
    final lang = ref.watch(appLanguageProvider);
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    String companionName(String id) {
      final name = (companions[id] as Map?)?['companionName']?.toString();
      if (name != null && name.isNotEmpty) return name;
      return id.isEmpty ? id : '${id[0].toUpperCase()}${id.substring(1)}';
    }

    if (data.intrigues.isEmpty) {
      return Center(child: Text(tr(ref, 'clans_none')));
    }
    return ListView(
      key: const Key('clans_intrigues_list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        for (final intrigue in data.intrigues.values)
          _IntrigueCard(
            intrigue: intrigue,
            data: data,
            stage: intrigueStageFrom(flags, intrigue.id),
            outcome: intrigueOutcomeFrom(flags, intrigue.id),
            language: lang,
            companionName: companionName,
          ),
      ],
    );
  }
}

class _IntrigueCard extends StatelessWidget {
  const _IntrigueCard({
    required this.intrigue,
    required this.data,
    required this.stage,
    required this.outcome,
    required this.language,
    required this.companionName,
  });

  final Intrigue intrigue;
  final ClanData data;
  final String Function(String id) companionName;

  /// 1..6, 0 when not started.
  final int stage;
  final int? outcome;
  final AppLanguage language;

  String _effectText(IntrigueEffect e) {
    final lang = language;
    final colon = lang == AppLanguage.fr ? '\u00a0:' : ':';
    if (e.factionId.isNotEmpty && e.delta != 0) {
      final condition = e.conditionFor(lang);
      return '${data.faction(e.factionId)?.nameFor(lang) ?? e.factionId} '
          '${formatStandingDelta(e.delta, language: lang)}'
          '${condition.isEmpty ? '' : ' ($condition)'}';
    }
    if (e.subclanId.isNotEmpty && e.mark != null) {
      return '${data.subclan(e.subclanId)?.nameFor(lang) ?? e.subclanId}$colon '
          '${trFor(lang, subclanMarkKey(e.mark!))}';
    }
    if (e.companionId.isNotEmpty) {
      final name = companionName(e.companionId);
      final key = 'intrigue_companion_${e.change}';
      final line = trFor(lang, key);
      return line == key
          ? '$name$colon ${e.change}'
          : line.replaceAll('{name}', name);
    }
    if (e.titleId.isNotEmpty) {
      return trFor(lang, 'intrigue_title_effect').replaceAll(
          '{name}', data.titles[e.titleId]?.nameFor(lang) ?? e.titleId);
    }
    if (e.noteFor(lang).isNotEmpty) return e.noteFor(lang);
    return [
      for (final entry in e.raw.entries)
        if (!entry.key.endsWith('_fr')) '${entry.key}$colon ${entry.value}',
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = language;
    final goldFill = standingTierColor(StandingTier.sworn);
    final gold = standingTierTextColor(context, StandingTier.sworn);
    final stageName = stage >= 1 && stage <= intrigue.stages.length
        ? trFor(lang, intrigue.stages[stage - 1].key)
        : stage >= 1
            ? trFor(lang,
                'intrigue_stage_${intrigueStageNames[stage - 1].toLowerCase()}')
            : '';
    return Card(
      key: Key('intrigue_${intrigue.id}'),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(intrigue.nameFor(lang), style: theme.textTheme.titleSmall),
            if (intrigue.premiseFor(lang).isNotEmpty)
              Text(intrigue.premiseFor(lang),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final id in intrigue.factionIds)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Color(data.faction(id)?.color ?? 0xFF888888)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PatronEmblem(
                            patron: data.faction(id)?.patron, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(data.faction(id)?.nameFor(lang) ?? id,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (intrigue.subclanIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final id in intrigue.subclanIds)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          color: Color(data.subclan(id)?.color ?? 0xFF888888),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(data.subclan(id)?.nameFor(lang) ?? id,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              stage == 0
                  ? trFor(lang, 'clans_intrigue_not_started')
                  : trFor(lang, 'clans_intrigue_stage')
                      .replaceAll('{n}', '$stage')
                      .replaceAll('{stage}', stageName),
              key: Key('intrigue_stage_${intrigue.id}'),
              style: theme.textTheme.labelLarge?.copyWith(
                  color:
                      stage == 0 ? theme.colorScheme.onSurfaceVariant : gold),
            ),
            for (var i = 0; i < intrigue.stages.length; i++)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: i + 1 == stage
                        ? goldFill
                        : theme.colorScheme.outlineVariant,
                    width: i + 1 == stage ? 2 : 1,
                  ),
                  color:
                      i + 1 == stage ? goldFill.withValues(alpha: 0.14) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        trFor(lang, intrigue.stages[i].key),
                        if (intrigue.stages[i].chapter.isNotEmpty)
                          trFor(lang, 'clans_intrigue_chapter')
                              .replaceAll('{c}', intrigue.stages[i].chapter),
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: i + 1 > stage && stage != 0
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    Text(intrigue.stages[i].textFor(lang),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: i + 1 > stage
                                ? theme.colorScheme.onSurfaceVariant
                                : null)),
                  ],
                ),
              ),
            if (intrigue.outcomes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(trFor(lang, 'clans_intrigue_outcomes').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1)),
              for (var i = 0; i < intrigue.outcomes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: intrigue.outcomes[i].nameFor(lang),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: outcome == i ? gold : null),
                      ),
                      if (outcome == i)
                        TextSpan(
                            text: ' (${trFor(lang, 'clans_intrigue_chosen')})',
                            style: TextStyle(color: gold)),
                      if (intrigue.outcomes[i].effects.isNotEmpty)
                        TextSpan(
                            text:
                                ' · ${intrigue.outcomes[i].effects.map(_effectText).where((t) => t.isNotEmpty).join(' · ')}'),
                    ]),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
