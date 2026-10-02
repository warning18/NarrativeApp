import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/echoes.dart';
import '../data/journal.dart';
import '../data/world_map.dart' show landmarkOfScene;
import '../data/narration_tokens.dart';
import '../data/story_repository.dart';
import '../data/story_state.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/clan_widgets.dart' show standingTierColor;
import '../widgets/coast_news.dart';

/// [entry]'s opening line with the reader's name and people filled in.
String _personal(String text, PlayerSession session, bool french) =>
    personalizeNarration(
      text,
      name: session.characterName,
      raceId: session.raceId,
      professionId: session.professionId,
      french: french,
    );

String _chapterTitle(int chapter, AppLanguage lang) => chapter == 0
    ? trFor(lang, 'chapter_band_prologue')
    : '${trFor(lang, 'chapter_label')} $chapter';

/// The story so far. Its first page, Now (v1.199), is the state of the
/// story in one reading: where the party stands, what is happening, the
/// threads open, who is along and how the clans stand, and the earlier
/// choices that still matter (see story_state.dart). Then Scenes, newest
/// first and grouped by chapter: each scene's opening line and the choice
/// that left it; What changed, the echoes met on the way (see
/// echoes.dart); and News (v1.195), the news from the coast.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyDataProvider).value;
    final playState = ref.watch(storyPlayProvider);
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final french = lang == AppLanguage.fr;
    final theme = Theme.of(context);

    final entries = story == null
        ? const <JournalEntry>[]
        : storySoFar(story, playState.history, playState.currentNodeId,
                french: french)
            .reversed
            .toList();

    final children = <Widget>[];
    int? lastChapter;
    for (final entry in entries) {
      if (entry.chapter != lastChapter) {
        lastChapter = entry.chapter;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(_chapterTitle(entry.chapter, lang),
              style: theme.textTheme.titleMedium),
        ));
      }
      children.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _personal(entry.opening, session, french),
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic, fontFamily: 'serif'),
              ),
              if (entry.choiceText != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.subdirectory_arrow_right,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _personal(entry.choiceText!, session, french),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ] else if (entry.nodeId == playState.currentNodeId) ...[
                const SizedBox(height: 6),
                Text(trFor(lang, 'journal_you_are_here'),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
              ],
            ],
          ),
        ),
      ));
    }

    return TutorialTrigger(
      topic: TutorialTopic.journal,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr(ref, 'journal_title')),
            bottom: TabBar(tabs: [
              Tab(
                  key: const ValueKey('journal_now_tab'),
                  text: tr(ref, 'sofar_now')),
              Tab(text: tr(ref, 'journal_story_tab')),
              Tab(
                  key: const ValueKey('journal_changed_tab'),
                  text: tr(ref, 'journal_changed_title')),
              Tab(
                  key: const ValueKey('journal_news_tab'),
                  text: tr(ref, 'journal_news_tab')),
            ]),
          ),
          body: TabBarView(children: [
            const StorySoFarPage(),
            entries.isEmpty
                ? Center(child: Text(tr(ref, 'journal_empty')))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: children,
                  ),
            const _WhatChanged(),
            const CoastNewsList(),
          ]),
        ),
      ),
    );
  }
}

/// The state of the story in one reading (see storySoFarProvider).
class StorySoFarPage extends ConsumerWidget {
  const StorySoFarPage({super.key, this.compact = false});

  /// In the Previously… dialog: the last scenes and the threads only.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = readStorySoFar(ref);
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final french = lang == AppLanguage.fr;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final prose = theme.textTheme.bodyMedium
        ?.copyWith(fontFamily: InkFonts.prose, height: 1.45);
    Widget heading(String key, Color colour) => Padding(
          padding: EdgeInsets.only(top: compact ? 10 : 14, bottom: 6),
          child: Text(tr(ref, key).toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(letterSpacing: 1.4, color: colour)),
        );
    Widget card(Widget child, {Key? key}) => Card(
          key: key,
          margin: EdgeInsets.zero,
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        );
    final children = <Widget>[
      if (!compact) ...[
        heading('sofar_where', ink.gold),
        card(
          key: const ValueKey('sofar_where'),
          Row(
            children: [
              Icon(Icons.map_outlined, color: ink.tide),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.placeName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontFamily: InkFonts.display)),
                    if (state.placeSub.isNotEmpty)
                      Text(state.placeSub,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                  ],
                ),
              ),
            ],
          ),
        ),
        heading('sofar_now', ink.voidColor),
        card(
          key: const ValueKey('sofar_now'),
          Text(state.now, style: prose),
        ),
      ] else ...[
        for (final entry in state.recent) ...[
          Text(
            _personal(entry.opening, session, french),
            style: prose?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (entry.choiceText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Text('→ ${_personal(entry.choiceText!, session, french)}',
                  style: theme.textTheme.labelMedium),
            )
          else
            const SizedBox(height: 10),
        ],
      ],
      heading('sofar_threads', ink.gold),
      if (state.threads.isEmpty)
        card(Text(tr(ref, 'sofar_threads_none'), style: prose))
      else
        card(
          key: const ValueKey('sofar_threads'),
          Column(
            children: [
              for (final thread in state.threads)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          thread.main
                              ? Icons.flag_outlined
                              : Icons.chat_bubble_outline,
                          size: 16,
                          color: thread.main ? ink.gold : ink.tide),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            thread.goal.isEmpty
                                ? thread.name
                                : '${thread.name} — ${thread.goal}',
                            style: prose),
                      ),
                      if (thread.main || thread.followed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            tr(
                                    ref,
                                    thread.main
                                        ? 'sofar_main'
                                        : 'sofar_followed')
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: thread.main ? ink.gold : ink.tide,
                                letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      if (!compact) ...[
        heading('sofar_company', ink.heal),
        card(
          key: const ValueKey('sofar_company'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (state.party.isEmpty && state.standings.isEmpty)
                Text(tr(ref, 'sofar_alone'), style: prose),
              for (final name in state.party) _chip(name, ink.heal),
              for (final standing in state.standings)
                _chip(
                    '${standing.name} · ${tr(ref, 'standing_tier_${standing.tier.name}')}',
                    standingTierColor(standing.tier)),
            ],
          ),
        ),
        if (state.echoes.isNotEmpty) ...[
          heading('sofar_matters', ink.ember),
          card(
            key: const ValueKey('sofar_matters'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final echo in state.echoes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history, size: 16, color: ink.ember),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: echo.cause,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                TextSpan(text: ' — ${echo.line}'),
                              ]),
                              style: prose),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ];
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
    return ListView(
      key: const ValueKey('sofar_page'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            tr(ref, 'sofar_day_chapter')
                    .replaceAll('{day}', '${state.day}')
                    .replaceAll('{chapter}', '${state.chapter}') +
                (state.chapterTitle.isEmpty ? '' : ' · ${state.chapterTitle}'),
            style: theme.textTheme.labelMedium?.copyWith(color: ink.ash),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _chip(String text, Color colour) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: colour),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text,
            style: TextStyle(
                fontFamily: InkFonts.system, fontSize: 11.5, color: colour)),
      );
}

/// The echoes read so far, the latest first: where, the choice that
/// earned each, and the line it earned.
class _WhatChanged extends ConsumerWidget {
  const _WhatChanged();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyDataProvider).value;
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final french = lang == AppLanguage.fr;
    final theme = Theme.of(context);
    final echoes = story == null
        ? const <({String nodeId, String line, String cause})>[]
        : [
            for (final key in session.seenEchoKeys.reversed)
              if (echoForKey(story, key, french: french) case final echo?) echo,
          ];
    if (echoes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(tr(ref, 'journal_changed_empty'),
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final echo in echoes)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (landmarkOfScene(echo.nodeId) case final place?)
                    Text(place.name(lang).toUpperCase(),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tr(ref, 'echo_because').replaceAll('{choice}',
                              _personal(echo.cause, session, french)),
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _personal(echo.line, session, french),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontFamily: InkFonts.prose),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Previously…": the last few scenes before the current one and the
/// threads open (the story so far's own reading, see StorySoFarPage) --
/// shown once when a saved story is picked up again.
Future<void> showPreviouslyDialog(
  BuildContext context, {
  required StoryData story,
  required List<String> history,
  required String currentNodeId,
  required PlayerSession session,
  required Map<String, dynamic> quests,
  required AppLanguage lang,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        scrollable: true,
        title: Text(trFor(lang, 'previously_title')),
        content: const StorySoFarPage(compact: true),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(trFor(lang, 'previously_continue_button')),
          ),
        ],
      );
    },
  );
}
