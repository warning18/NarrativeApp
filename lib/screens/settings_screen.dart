import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../data/map_themes.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/palette_provider.dart';
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
    final palette = ref.watch(appPaletteProvider);
    final trembleEnabled = ref.watch(trembleEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ref, 'language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'language_coverage_note'),
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
              tr(ref, 'palette_section_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'palette_section_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppPalette.values.map((p) {
                final selected = palette == p;
                final label = tr(ref, _paletteLabelKey(p));
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ref.read(appPaletteProvider.notifier).setPalette(p),
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: p.swatch
                              .map(
                                (color) => Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (selected) ...[
                          const SizedBox(height: 2),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'combat_section_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'tremble_setting_title')),
              subtitle: Text(tr(ref, 'tremble_setting_desc')),
              value: trembleEnabled,
              onChanged: (value) => ref.read(trembleEnabledProvider.notifier).setEnabled(value),
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'gemini_api_key_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'gemini_api_key_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(ref, 'api_key_label'),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  tooltip: _obscure ? tr(ref, 'show_api_key_tooltip') : tr(ref, 'hide_api_key_tooltip'),
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
                        SnackBar(content: Text(tr(ref, 'api_key_saved'))),
                      );
                    },
                    child: Text(tr(ref, 'save')),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    _controller.clear();
                    await ref.read(apiKeyProvider.notifier).clearKey();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr(ref, 'api_key_removed'))),
                    );
                  },
                  child: Text(tr(ref, 'clear_button')),
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

  String _paletteLabelKey(AppPalette palette) {
    switch (palette) {
      case AppPalette.deepPurple:
        return 'palette_deep_purple';
      case AppPalette.weatheredEarth:
        return 'palette_weathered_earth';
      case AppPalette.autumnMeadow:
        return 'palette_autumn_meadow';
      case AppPalette.duskHorizon:
        return 'palette_dusk_horizon';
    }
  }
}
