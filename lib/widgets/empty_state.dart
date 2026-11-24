// Empty and error states (v1.255): where a list has nothing to show, or a
// file would not load, the companion dog sits on the page beside the
// message instead of the screen going blank. The dog is the same pixel
// sprite the story screen idles with (assets/visuals/companion/).
import 'package:flutter/material.dart';

import '../data/companion_sprites.dart';

const String _sittingDog =
    '$companionAssetsRoot/Sitting_down/rotations/south.png';

/// A page with nothing on it: the companion, the [message], and under it an
/// optional [hint] and [action].
class InkEmptyState extends StatelessWidget {
  const InkEmptyState({
    super.key,
    required this.message,
    this.hint,
    this.action,
    this.error = false,
  });

  final String message;
  final String? hint;
  final Widget? action;

  /// Tints the message as a failure (see [InkErrorState]).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Image.asset(
                  _sittingDog,
                  key: const ValueKey('empty_state_dog'),
                  width: 128,
                  height: 128,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  isAntiAlias: false,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 128),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                key: const ValueKey('empty_state_message'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: error ? scheme.error : scheme.onSurface,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 6),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A file or record that would not load: the companion, the [message] in the
/// error colour and the [detail] (the exception) small under it.
class InkErrorState extends StatelessWidget {
  const InkErrorState({
    super.key,
    required this.message,
    this.detail,
    this.action,
  });

  final String message;
  final Object? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => InkEmptyState(
        message: message,
        hint: detail?.toString(),
        action: action,
        error: true,
      );
}
