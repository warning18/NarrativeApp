import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/echoes.dart';
import '../data/journal.dart';
import '../data/world_map.dart' show landmarkOfScene;
import '../data/quest_tracking.dart';
import '../data/narration_tokens.dart';
import '../data/story_repository.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
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

/// The story so far, newest first and grouped by chapter: each scene's
/// opening line and the choice that left it. A second page, What changed,
/// lists the echoes met on the way: a later scene's line with the earlier
/// choice that earned it (see echoes.dart). A third, News (v1.195), keeps
/// the news from the coast (see coast_news.dart).
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
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr(ref, 'journal_title')),
            bottom: TabBar(tabs: [
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

/// "Previously…": the last few scenes before the current one, the active
/// quests and where the player stands -- shown once when a saved story is
/// picked up again.
Future<void> showPreviouslyDialog(
  BuildContext context, {
  required StoryData story,
  required List<String> history,
  required String currentNodeId,
  required PlayerSession session,
  required Map<String, dynamic> quests,
  required AppLanguage lang,
}) {
  final french = lang == AppLanguage.fr;
  final entries =
      storySoFar(story, history, currentNodeId, french: french).toList();
  final recent =
      entries.length <= 3 ? entries : entries.sublist(entries.length - 3);
  // Each quest in progress with the goal it waits on, the followed one
  // first.
  final followed = followedQuestIdOf(session);
  final questLines = [
    for (final id in [
      if (followed != null) followed,
      ...session.activeQuestIds.where((id) => id != followed),
    ])
      if (quests[id] is Map<String, dynamic>)
        _questLine(
            id, quests[id] as Map<String, dynamic>, session, french, lang),
  ];
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        scrollable: true,
        title: Text(trFor(lang, 'previously_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in recent) ...[
              Text(
                _personal(entry.opening, session, french),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
              if (entry.choiceText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 10),
                  child: Text(
                      '→ ${_personal(entry.choiceText!, session, french)}',
                      style: theme.textTheme.labelMedium),
                )
              else
                const SizedBox(height: 10),
            ],
            if (questLines.isNotEmpty) ...[
              Text(trFor(lang, 'previously_quests_label'),
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final line in questLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $line'),
                ),
            ],
          ],
        ),
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

/// "The Dockside Debts: Defeat the smuggler (0/1)", or the quest's name
/// with "Goal reached: turn it in" once every objective is met.
String _questLine(String id, Map<String, dynamic> quest, PlayerSession session,
    bool french, AppLanguage lang) {
  final name = (french ? (quest['questName_fr']?.toString() ?? '') : '')
      .ifEmpty(quest['questName']?.toString() ?? id);
  final goal = questGoalFor(id, quest, session);
  final text = goal.ready ? trFor(lang, 'quest_goal_ready') : goal.label;
  return text.isEmpty ? name : '$name: $text';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
