// The training offer a level-up brings (Wave 7, see training.dart): three
// paths as cards, one tap to take one. Shown on the Level Up screen and in
// the pop-up after a fight while points are unspent; the next offer is
// drawn as soon as one is taken. A card is picked, then taken with the
// button under the cards (as a clan's gift is): a path is for good.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/training.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../providers/training_provider.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart' show ItemPixelIcon;

/// The label key of a training gain's stat.
String trainingStatLabelKey(String stat) => switch (stat) {
      'baseDamage' => 'base_damage_label',
      'baseArmor' => 'base_armor_label',
      'maxHealth' => 'max_health_label',
      _ => '${stat}_label',
    };

/// What a stat is worth to the eye: attack burns, defence and health run
/// cool, the mind goes violet, the quick are green, the social gold.
Color trainingStatColor(String stat, InkColors ink) => switch (stat) {
      'baseDamage' || 'strength' => ink.ember,
      'baseArmor' || 'maxHealth' || 'constitution' => ink.tide,
      'intelligence' || 'wisdom' => ink.voidColor,
      'dexterity' || 'perception' || 'luck' => ink.heal,
      _ => ink.gold,
    };

/// A path's colour: that of the stat it raises most (by points).
Color trainingPathColor(Map<String, int> gains, InkColors ink) {
  var best = 'strength';
  var bestPoints = -1;
  for (final MapEntry(:key, :value) in gains.entries) {
    final points = value ~/ trainingUnitOf(key);
    if (points > bestPoints) {
      best = key;
      bestPoints = points;
    }
  }
  return trainingStatColor(best, ink);
}

/// The pixel art of a path (training_paths.json's `icon`): the item of the
/// game that stands for it, drawn the way the pack shows it.
String trainingPathItem(String icon) => switch (icon) {
      'fist' || 'knuckles' => 'thug_knuckle_wrap',
      'blade' => 'dagger_t1',
      'shield' => 'shield_t3',
      'tower' => 'shield_t4',
      'book' => 'spellbook_ember_wave',
      'sun' => 'spellbook_sanctified_ground',
      'feather' => 'spellbook_smoke_veil',
      'bow' => 'spellbook_arrow_volley',
      'scroll' => 'scroll_fireball',
      _ => 'tome_of_insight',
    };

/// The stat's value on [s] now (the gains' "before").
int trainingStatNow(PlayerSession s, String stat) => switch (stat) {
      'baseDamage' => s.baseDamage,
      'baseArmor' => s.baseArmor,
      'maxHealth' => s.maxHealth,
      'strength' => s.strength,
      'dexterity' => s.dexterity,
      'constitution' => s.constitution,
      'intelligence' => s.intelligence,
      'wisdom' => s.wisdom,
      'perception' => s.perception,
      'luck' => s.luck,
      'charisma' => s.charisma,
      _ => 0,
    };

class TrainingPicker extends ConsumerStatefulWidget {
  const TrainingPicker({super.key});

  @override
  ConsumerState<TrainingPicker> createState() => _TrainingPickerState();
}

class _TrainingPickerState extends ConsumerState<TrainingPicker> {
  bool _busy = false;

  /// The card picked, not yet taken.
  int? _selected;

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
      if (mounted) setState(() => _selected = null);
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
    final picked =
        _selected != null && _selected! < offer.length ? _selected : null;

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
              session: session,
              fr: fr,
              selected: picked == i,
              dimmed: picked != null && picked != i,
              onTap: () => setState(() => _selected = i),
            ),
          ),
        if (offer.isNotEmpty) ...[
          const SizedBox(height: 2),
          FilledButton(
            key: const Key('training_take'),
            onPressed: picked == null ? null : () => _take(picked),
            child: Text(tr(ref, 'training_take_button')),
          ),
        ],
      ],
    );
  }
}

class _TrainingCard extends ConsumerWidget {
  const _TrainingCard({
    super.key,
    required this.path,
    required this.choice,
    required this.session,
    required this.fr,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final TrainingPath? path;
  final TrainingChoice choice;
  final PlayerSession session;
  final bool fr;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final blurb = path?.blurbFor(fr) ?? '';
    final accent = trainingPathColor(choice.gains, ink);
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.10)
            : theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
              color: selected ? accent : ink.seam, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: Key('training_icon_${choice.pathId}'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent, width: 1.5),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.32),
                            accent.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ItemPixelIcon(
                          trainingPathItem(path?.icon ?? ''), null,
                          size: 34),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(path?.nameFor(fr) ?? choice.pathId,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontFamily: InkFonts.display)),
                          if (blurb.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(blurb,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: ink.ash)),
                          ],
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 22, color: accent),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final MapEntry(:key, :value) in choice.gains.entries)
                      _GainTile(
                        key: Key('training_gain_${choice.pathId}_$key'),
                        label: tr(ref, trainingStatLabelKey(key)),
                        gain: value,
                        before: trainingStatNow(session, key),
                        color: trainingStatColor(key, ink),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One gain: the stat, the big "+n", and where the stat goes.
class _GainTile extends StatelessWidget {
  const _GainTile({
    super.key,
    required this.label,
    required this.gain,
    required this.before,
    required this.color,
  });

  final String label;
  final int gain;
  final int before;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('+$gain',
                  style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 20,
                      height: 1.2,
                      color: color)),
              const SizedBox(width: 6),
              Text('$before',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              Icon(Icons.arrow_right_alt, size: 14, color: ink.ash),
              Text('${before + gain}',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ],
          ),
        ],
      ),
    );
  }
}
