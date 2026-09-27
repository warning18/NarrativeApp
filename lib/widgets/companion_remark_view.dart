import 'package:flutter/material.dart';

/// A companion's remark on what the player just did (see
/// companion_remarks.dart), opening the next scene: their name, small,
/// over their words, set off from the narration by a rule on the left.
class CompanionRemarkView extends StatelessWidget {
  const CompanionRemarkView({
    super.key,
    required this.speaker,
    required this.line,
    required this.color,
    required this.french,
    this.style,
  });

  final String speaker;
  final String line;

  /// The scene's accent: the rule and the name take it.
  final Color color;
  final bool french;

  /// The words' style; the scene's prose style in italics by default.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quoted = french ? '« $line »' : '“$line”';
    return Semantics(
      label: '$speaker: $line',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color.withValues(alpha: 0.6), width: 3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              speaker.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: color.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              quoted,
              style: (style ?? theme.textTheme.bodyLarge)
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
