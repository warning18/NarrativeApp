import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../data/map_themes.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/map_theme_provider.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(apiKeyProvider) ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final mapTheme = ref.watch(mapThemeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Language',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Applies to navigation, the full story (reader and map), and the Legend. '
              'Game data tables, field names, and IDs stay in English.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(value: AppLanguage.en, label: Text('English'), icon: Text('🇬🇧')),
                ButtonSegment(value: AppLanguage.fr, label: Text('Français'), icon: Text('🇫🇷')),
              ],
              selected: {language},
              onSelectionChanged: (selection) {
                ref.read(appLanguageProvider.notifier).setLanguage(selection.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'map_theme_section'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'map_theme_description'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MapTheme>(
              value: mapTheme,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: MapTheme.values
                  .map(
                    (theme) => DropdownMenuItem(
                      value: theme,
                      child: Text(tr(ref, mapThemeLabelKey(theme))),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) ref.read(mapThemeProvider.notifier).setTheme(value);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Gemini API Key',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Used by the AI Generator tab to create new story beats. '
              'Stored only on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'API key',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final key = _controller.text.trim();
                      if (key.isEmpty) return;
                      await ref.read(apiKeyProvider.notifier).setKey(key);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API key saved.')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    _controller.clear();
                    await ref.read(apiKeyProvider.notifier).clearKey();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API key removed.')),
                    );
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                AppInfo.displayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
