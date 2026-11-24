import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

/// Writes [content] to a temp file and hands it to the OS (share sheet / a
/// text viewer), for a real "export" rather than just a clipboard copy.
/// Falls back to telling the user what went wrong — some devices have
/// nothing registered to open a bare text file.
Future<void> exportTextToFile(
  BuildContext context,
  WidgetRef ref,
  String content,
  String filename,
) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${trFor(ref.read(appLanguageProvider), 'export_failed_prefix')}: $e')),
    );
  }
}

Future<void> copyTextToClipboard(
    BuildContext context, WidgetRef ref, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr(ref, 'transcript_copied_message'))),
  );
}
