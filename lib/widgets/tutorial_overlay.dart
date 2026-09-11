import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_sprites.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/companion_name_provider.dart';
import '../providers/tutorial_provider.dart';

final List<String> _tutorialFrames = companionFrames('Walking/north', 8);
const double _tutorialMascotSize = 192;

class _TutorialStep {
  const _TutorialStep({required this.icon, required this.titleKey, required this.bodyKey});

  final IconData icon;
  final String titleKey;
  final String bodyKey;
}

const List<_TutorialStep> _steps = [
  _TutorialStep(
    icon: Icons.waving_hand,
    titleKey: 'tutorial_step1_title',
    bodyKey: 'tutorial_step1_body',
  ),
  _TutorialStep(
    icon: Icons.menu_book,
    titleKey: 'tutorial_step2_title',
    bodyKey: 'tutorial_step2_body',
  ),
  _TutorialStep(
    icon: Icons.videogame_asset,
    titleKey: 'tutorial_step3_title',
    bodyKey: 'tutorial_step3_body',
  ),
  _TutorialStep(
    icon: Icons.favorite,
    titleKey: 'tutorial_step4_title',
    bodyKey: 'tutorial_step4_body',
  ),
  _TutorialStep(
    icon: Icons.settings,
    titleKey: 'tutorial_step5_title',
    bodyKey: 'tutorial_step5_body',
  ),
];

/// A short guided tour, hosted by the walking-companion dog, shown right
/// after a new character is created (see story_player_screen.dart) or
/// replayed on demand from Settings. Uses a near-opaque barrier so the
/// character stats bar behind it doesn't peek through distractingly.
Future<void> showTutorialOverlay(BuildContext context, WidgetRef ref) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Tutorial',
    barrierColor: Colors.black.withOpacity(0.85),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => const _TutorialDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _TutorialDialog extends ConsumerStatefulWidget {
  const _TutorialDialog();

  @override
  ConsumerState<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends ConsumerState<_TutorialDialog>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _walkController;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _walkController.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(tutorialProvider.notifier).markSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;
    final companionName = ref.watch(companionNameProvider);
    final lang = ref.watch(appLanguageProvider);
    final stepBody = _step == 0 && companionName.isNotEmpty
        ? '${trFor(lang, 'tutorial_step1_body_named_prefix')}$companionName'
            '${trFor(lang, 'tutorial_step1_body_named_suffix')}'
        : tr(ref, step.bodyKey);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _walkController,
                  builder: (context, _) {
                    final frame =
                        (_walkController.value * _tutorialFrames.length).floor() %
                            _tutorialFrames.length;
                    return Image.asset(
                      _tutorialFrames[frame],
                      width: _tutorialMascotSize,
                      height: _tutorialMascotSize,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.pets,
                        size: _tutorialMascotSize,
                        color: colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_step),
                    children: [
                      Icon(step.icon, color: colorScheme.primary, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        tr(ref, step.titleKey),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stepBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          height: 1.4,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _step ? colorScheme.primary : colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(onPressed: _finish, child: Text(tr(ref, 'tutorial_skip_button'))),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        if (isLast) {
                          _finish();
                        } else {
                          setState(() => _step++);
                        }
                      },
                      child: Text(
                        isLast ? tr(ref, 'tutorial_done_button') : tr(ref, 'tutorial_next_button'),
                      ),
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
