import 'package:flutter/material.dart';

/// Shows a modal dialog with a title, an optional description, and a list
/// of label/value stat rows — used for the skill/item detail popups.
Future<void> showDetailDialog(
  BuildContext context, {
  required String title,
  String? description,
  IconData? icon,
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
          if (icon != null) ...[
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
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.key, style: Theme.of(context).textTheme.bodyMedium),
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
