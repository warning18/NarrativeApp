import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';

/// "News from the coast" (v1.195, see politics_events.dart): what the
/// clans did while the party was elsewhere. The camp shows what it has not
/// shown yet ([CoastNewsCard]); the journal keeps all of it
/// ([CoastNewsList]).

/// News the camp's card has room for; the rest waits in the journal.
const int campNewsShown = 3;

/// The camp's notice: the news not shown yet, the latest first, and
/// "Noted" to put it away. Nothing when there is none.
class CoastNewsCard extends ConsumerWidget {
  const CoastNewsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(politicsProvider).unreadNews.reversed.toList();
    if (unread.isEmpty) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final shown = unread.take(campNewsShown).toList();
    return Card(
      key: const Key('camp_coast_news'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, size: 18, color: ink.ember),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trFor(lang, 'coast_news_title'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            for (final news in shown) _NewsLine(news: news, language: lang),
            if (unread.length > shown.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  trFor(lang, 'coast_news_more')
                      .replaceAll('{n}', '${unread.length - shown.length}'),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('camp_coast_news_noted'),
                onPressed: () => ref
                    .read(playerSessionProvider.notifier)
                    .markCoastNewsRead(),
                child: Text(trFor(lang, 'coast_news_noted')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The journal's News page: everything the coast has told, the latest
/// first, under the chapter it came in.
class CoastNewsList extends ConsumerWidget {
  const CoastNewsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(politicsProvider).news.reversed.toList();
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    if (news.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(trFor(lang, 'journal_news_empty'),
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      key: const Key('journal_news_list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(trFor(lang, 'coast_news_title'),
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final n in news)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _NewsLine(news: n, language: lang, dated: true),
            ),
          ),
      ],
    );
  }
}

/// One piece of news, in italics, with when it came ([dated]).
class _NewsLine extends StatelessWidget {
  const _NewsLine({
    required this.news,
    required this.language,
    this.dated = false,
  });

  final CoastNews news;
  final AppLanguage language;
  final bool dated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dated)
            Text(
              trFor(language, 'coast_news_when')
                  .replaceAll('{c}', '${news.chapter}')
                  .replaceAll('{d}', '${news.day}')
                  .toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          Text(
            news.textFor(language),
            style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic, fontFamily: InkFonts.prose),
          ),
        ],
      ),
    );
  }
}
