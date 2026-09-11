import 'package:flutter/material.dart';

/// Shows a themed, centered notification card in place of the default
/// Material SnackBar — matches the story reader's parchment/serif
/// presentation instead of a flat Android bottom toast, so player-facing
/// feedback (purchases, quest updates, skill unlocks, level-ups) feels part
/// of the game rather than a system notification. Auto-dismisses after
/// [duration], or immediately on tapping outside the card.
Future<void> showImmersiveNotice(
  BuildContext context, {
  required String message,
  IconData icon = Icons.auto_awesome,
  Duration duration = const Duration(milliseconds: 2200),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: message,
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ImmersiveNoticeContent(
        message: message,
        icon: icon,
        // Give the player time to notice and tap the action button when
        // there is one, instead of it vanishing under the default toast
        // duration.
        duration: actionLabel != null ? const Duration(seconds: 5) : duration,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ImmersiveNoticeContent extends StatefulWidget {
  const _ImmersiveNoticeContent({
    required this.message,
    required this.icon,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ImmersiveNoticeContent> createState() => _ImmersiveNoticeContentState();
}

class _ImmersiveNoticeContentState extends State<_ImmersiveNoticeContent> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: colorScheme.primary, size: 32),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    height: 1.4,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      widget.onAction!();
                      Navigator.of(context).maybePop();
                    },
                    child: Text(widget.actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
