// The training offer a level-up brings (Wave 7, see training.dart): three
// paths as cards, one tap to take one. Shown on the Level Up screen and in
// the pop-up after a fight while points are unspent; the next offer is
// drawn as soon as one is taken.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/training.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../providers/training_provider.dart';
import '../theme/stitched_ink.dart';

/// The label key of a training gain's stat.
String trainingStatLabelKey(String stat) => switch (stat) {
      'baseDamage' => 'base_damage_label',
      'baseArmor' => 'base_armor_label',
      'maxHealth' => 'max_health_label',
      _ => '${stat}_label',
    };

class TrainingPicker extends ConsumerStatefulWidget {
  const TrainingPicker({super.key});

  @override
  ConsumerState<TrainingPicker> createState() => _TrainingPickerState();
}

class _TrainingPickerState extends ConsumerState<TrainingPicker> {
  bool _busy = false;

  /// Draws the offer when points wait and none of the right size is there.
  void _ensure(Map<String, TrainingPath> paths) {
    final session = ref.read(playerSessionProvider);
    if (_busy || !trainingDue(session.statPoints)) return;
    final full = session.statPoints >= trainingFullPoints;
    final offer = session.trainingOffer;
    if (offer.isNotEmpty && offer.first.small == !full) return;
    _busy = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (mounted) {
          await ref.read(playerSessionProvider.notifier).ensureTraining(paths);
        }
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> _take(int index) async {
    if (_busy) return;
    _busy = true;
    try {
      await ref.read(playerSessionProvider.notifier).takeTraining(index);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final paths = ref.watch(trainingPathsProvider).value;
    if (paths == null || !trainingDue(session.statPoints)) {
      return const SizedBox.shrink();
    }
    _ensure(paths);
    final offer = session.trainingOffer;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final small = offer.isNotEmpty && offer.first.small;

    return Column(
      key: const Key('training_picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(ref, small ? 'training_small_title' : 'training_choose_title'),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontFamily: InkFonts.display, color: ink.gold),
        ),
        const SizedBox(height: 8),
        for (final (i, choice) in offer.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TrainingCard(
              key: Key('training_choice_$i'),
              path: paths[choice.pathId],
              choice: choice,
              fr: fr,
              onTap: () => _take(i),
            ),
          ),
      ],
    );
  }
}

class _TrainingCard extends ConsumerWidget {
  const _TrainingCard({
    super.key,
    required this.path,
    required this.choice,
    required this.fr,
    required this.onTap,
  });

  final TrainingPath? path;
  final TrainingChoice choice;
  final bool fr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final blurb = path?.blurbFor(fr) ?? '';
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: ink.seam),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(path?.nameFor(fr) ?? choice.pathId,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontFamily: InkFonts.display)),
              if (blurb.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(blurb,
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final MapEntry(:key, :value) in choice.gains.entries)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label:
                          Text('+$value ${tr(ref, trainingStatLabelKey(key))}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
