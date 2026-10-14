import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/tutorial_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/tutorial_topics.dart';

/// A section name that explains itself: a small ⓘ after it, and the
/// explanation shown while the name is held. It stands in for the long
/// paragraph that used to sit under the title.
class HelpTitle extends StatelessWidget {
  const HelpTitle({super.key, required this.title, required this.help});

  final String title;
  final String help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Tooltip(
      message: help,
      triggerMode: TooltipTriggerMode.longPress,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 12),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurface),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ink.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(title, style: theme.textTheme.titleMedium)),
          const SizedBox(width: 6),
          ExcludeSemantics(
              child: Icon(Icons.info_outline, size: 15, color: ink.ash)),
        ],
      ),
    );
  }
}

/// The ⓘ of a page's header: it plays the page's guide tour again, where
/// the page already hosts its [TutorialTrigger].
class TourInfoButton extends ConsumerWidget {
  const TourInfoButton({super.key, required this.topic});

  final TutorialTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      key: const Key('help_tour_button'),
      icon: const Icon(Icons.info_outline),
      tooltip: tr(ref, 'help_replay_guide'),
      onPressed: () => ref.read(pendingTourProvider.notifier).state = topic,
    );
  }
}
