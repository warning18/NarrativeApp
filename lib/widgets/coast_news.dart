import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';

/// "News from the coast" (v1.195, see politics_events.dart): what the
/// clans did while the party was elsewhere. The camp says what it has not
/// shown yet ([CoastNewsChip], beside Rest, opening [CoastNewsSheet]); the
/// journal keeps all of it ([CoastNewsList]).

/// The camp's notice: "News (2)" beside Rest while news waits unread; a
/// tap opens it. Nothing when there is none, so it never pushes the
/// camp's places down.
class CoastNewsChip extends ConsumerWidget {
  const CoastNewsChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(politicsProvider).unreadNews;
    if (unread.isEmpty) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    final ink = InkColors.of(context);
    return OutlinedButton.icon(
      key: const Key('camp_coast_news'),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        side: WidgetStateProperty.all(BorderSide(color: ink.ember)),
      ),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const SafeArea(child: CoastNewsSheet()),
      ),
      icon: Icon(Icons.campaign_outlined, size: 18, color: ink.ember),
      label: Text(
          trFor(lang, 'coast_news_chip').replaceAll('{n}', '${unread.length}')),
    );
  }
}

/// The news the camp has not shown yet, the latest first, under "News
/// from the coast", and "Noted" to put it away (it stays in the journal).
class CoastNewsSheet extends ConsumerWidget {
  const CoastNewsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(politicsProvider).unreadNews.reversed.toList();
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('camp_coast_news_sheet'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trFor(lang, 'coast_news_title'),
              style: theme.textTheme.titleMedium),
          for (final news in unread)
            _NewsLine(news: news, language: lang, dated: true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('camp_coast_news_noted'),
              onPressed: () async {
                await ref
                    .read(playerSessionProvider.notifier)
                    .markCoastNewsRead();
                if (context.mounted) Navigator.of(context).maybePop();
              },
              child: Text(trFor(lang, 'coast_news_noted')),
            ),
          ),
        ],
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
