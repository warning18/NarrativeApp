// The app's yes/no dialog (v1.871): a title, a line of words, Cancel on the
// left and the act on the right. The same dialog was written out by hand at
// dozens of places; this is the plain case, and the answer is a bool.
import 'package:flutter/material.dart';

/// Asks [title] / [body] (or a [content] widget) and answers true for
/// [confirm], false for [cancel] or a tap outside. The act is a filled button
/// unless [filled] is false (a quiet text button, for a reset).
Future<bool> showInkConfirm(
  BuildContext context, {
  String? title,
  String? body,
  Widget? content,
  required String cancel,
  required String confirm,
  bool filled = true,
  Key? dialogKey,
  Key? confirmKey,
}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: dialogKey,
      title: title == null ? null : Text(title),
      content: content ?? (body == null ? null : Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancel),
        ),
        if (filled)
          FilledButton(
            key: confirmKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirm),
          )
        else
          TextButton(
            key: confirmKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirm),
          ),
      ],
    ),
  );
  return yes ?? false;
}
