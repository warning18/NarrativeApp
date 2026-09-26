import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../utils/export_utils.dart';

/// One way to take data away: what it is, the file it goes into, and how
/// to build its contents (only when asked).
class DataExportOption {
  const DataExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filename,
    required this.build,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String filename;
  final Future<String> Function() build;
}

/// A sheet of [options], each to copy to the clipboard or save as a file
/// (handed to the phone to open, save or share; see [exportTextToFile]).
Future<void> showDataExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required List<DataExportOption> options,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      Future<void> copy(DataExportOption option) async {
        final text = await option.build();
        await Clipboard.setData(ClipboardData(text: text));
        if (!sheetContext.mounted) return;
        Navigator.of(sheetContext).pop();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${option.title}: copied to the clipboard.')),
        );
      }

      Future<void> save(DataExportOption option) async {
        final text = await option.build();
        if (!sheetContext.mounted) return;
        Navigator.of(sheetContext).pop();
        if (!context.mounted) return;
        await exportTextToFile(context, ref, text, option.filename);
      }

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(title,
                    style: Theme.of(sheetContext).textTheme.titleMedium),
              ),
              for (final option in options)
                ListTile(
                  key: Key('data_export_${option.filename}'),
                  leading: Icon(option.icon),
                  title: Text(option.title),
                  subtitle: Text('${option.subtitle}\n${option.filename}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: tr(ref, 'copy_button'),
                        onPressed: () => copy(option),
                      ),
                      IconButton(
                        key: Key('data_export_save_${option.filename}'),
                        icon: const Icon(Icons.save_alt),
                        tooltip: tr(ref, 'export_button'),
                        onPressed: () => save(option),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
