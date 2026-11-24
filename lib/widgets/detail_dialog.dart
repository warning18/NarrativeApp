import 'package:flutter/material.dart';

/// Shows a modal dialog with a title, an optional description, an
/// optional muted [note] under it (an item's provenance, v1.204), and a
/// list of label/value stat rows — used for the skill/item detail popups.
Future<void> showDetailDialog(
  BuildContext context, {
  required String title,
  String? description,
  String? note,
  IconData? icon,
  Widget? leading,
  List<MapEntry<String, String>> rows = const [],
  String closeLabel = 'Close',
  String? extraActionLabel,
  VoidCallback? onExtraAction,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null && description.isNotEmpty) ...[
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'serif',
                        height: 1.55,
                        letterSpacing: 0.1,
                      ),
                ),
                const SizedBox(height: 16),
              ],
              if (note != null && note.isNotEmpty) ...[
                Text(
                  note,
                  key: const Key('detail_note'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.key,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        row.value,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeLabel),
        ),
        if (extraActionLabel != null && onExtraAction != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onExtraAction();
            },
            child: Text(extraActionLabel),
          ),
      ],
    ),
  );
}
