import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../data/map_themes.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/companion_name_provider.dart';
import '../providers/github_push_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/palette_provider.dart';
import '../providers/permadeath_provider.dart';
import '../providers/settings_providers.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/update_checker.dart';
import '../providers/voice_settings_provider.dart';
import '../providers/walk_companion_provider.dart';
import '../widgets/elevenlabs_voice_settings.dart';
import 'playthrough_simulator_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;
  late final TextEditingController _githubTokenController;
  late final TextEditingController _companionNameController;
  bool _obscure = true;
  bool _obscureGithubToken = true;
  bool _checkingUpdate = false;
  bool _downloading = false;
  double? _downloadProgress;
  bool _pushingEdits = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(apiKeyProvider) ?? '');
    _githubTokenController =
        TextEditingController(text: ref.read(githubTokenProvider) ?? '');
    _companionNameController =
        TextEditingController(text: ref.read(companionNameProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    _githubTokenController.dispose();
    _companionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final mapTheme = ref.watch(mapThemeProvider);
    final palette = ref.watch(appPaletteProvider);
    final themeMode = ref.watch(themeModeProvider);
    final trembleEnabled = ref.watch(trembleEnabledProvider);
    final combatEffectsEnabled = ref.watch(combatEffectsEnabledProvider);
    final chestAutoOpen = ref.watch(chestAutoOpenProvider);
    final shipTurnTimer = ref.watch(shipTurnTimerProvider);
    final alignmentHunters = ref.watch(alignmentHuntersEnabledProvider);
    final companionAutoTarget = ref.watch(companionAutoTargetProvider);
    final permadeathEnabled = ref.watch(permadeathEnabledProvider);
    final walkCompanionEnabled = ref.watch(walkCompanionEnabledProvider);
    final tutorial = ref.watch(tutorialProvider);
    final appMode = ref.watch(appModeProvider);
    final isEditMode = appMode == AppMode.edit;
    final autoReadAloud = ref.watch(autoReadAloudProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ref, 'app_mode_section_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'app_mode_section_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppMode>(
              segments: [
                ButtonSegment(
                  value: AppMode.edit,
                  label: Text(tr(ref, 'edit_mode_label')),
                  icon: const Icon(Icons.edit_outlined),
                ),
                ButtonSegment(
                  value: AppMode.inGame,
                  label: Text(tr(ref, 'in_game_mode_label')),
                  icon: const Icon(Icons.sports_esports_outlined),
                ),
              ],
              selected: {appMode},
              onSelectionChanged: (selection) {
                ref.read(appModeProvider.notifier).setMode(selection.first);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'tutorial_setting_title')),
              subtitle: Text(tr(ref, 'tutorial_setting_desc')),
              value: tutorial.enabled,
              onChanged: (value) =>
                  ref.read(tutorialProvider.notifier).setEnabled(value),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(tutorialProvider.notifier).reset();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr(ref, 'tutorial_reset_notice'))));
                },
                icon: const Icon(Icons.replay),
                label: Text(tr(ref, 'tutorial_replay_button')),
              ),
            ),
            const SizedBox(height: 24),
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
                ButtonSegment(
                    value: AppLanguage.en,
                    label: Text('English'),
                    icon: Text('🇬🇧')),
                ButtonSegment(
                    value: AppLanguage.fr,
                    label: Text('Français'),
                    icon: Text('🇫🇷')),
              ],
              selected: {language},
              onSelectionChanged: (selection) {
                ref
                    .read(appLanguageProvider.notifier)
                    .setLanguage(selection.first);
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
            DropdownButtonFormField<MapTheme?>(
              // `value` (not `initialValue`) is needed: mapTheme is a
              // watched provider value that can change from outside this
              // dropdown (e.g. a reset elsewhere).
              // ignore: deprecated_member_use
              value: mapTheme,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(
                    value: null, child: Text(tr(ref, 'map_theme_auto_label'))),
                ...MapTheme.values.map(
                  (theme) => DropdownMenuItem(
                    value: theme,
                    child: Text(tr(ref, mapThemeLabelKey(theme))),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(mapThemeProvider.notifier).setTheme(value);
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
                  onTap: () =>
                      ref.read(appPaletteProvider.notifier).setPalette(p),
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
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
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
            const SizedBox(height: 16),
            Text(
              tr(ref, 'theme_mode_section'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(tr(ref, 'theme_mode_system')),
                  icon: const Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(tr(ref, 'theme_mode_light')),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(tr(ref, 'theme_mode_dark')),
                  icon: const Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selection.first);
              },
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
              onChanged: (value) =>
                  ref.read(trembleEnabledProvider.notifier).setEnabled(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'combat_effects_setting_title')),
              subtitle: Text(tr(ref, 'combat_effects_setting_desc')),
              value: combatEffectsEnabled,
              onChanged: (value) => ref
                  .read(combatEffectsEnabledProvider.notifier)
                  .setEnabled(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'permadeath_setting_title')),
              subtitle: Text(tr(ref, 'permadeath_setting_desc')),
              value: permadeathEnabled,
              onChanged: (value) => ref
                  .read(permadeathEnabledProvider.notifier)
                  .setEnabled(value),
            ),
            SwitchListTile(
              key: const Key('ship_turn_timer_setting'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'ship_turn_timer_setting_title')),
              subtitle: Text(tr(ref, 'ship_turn_timer_setting_desc')),
              value: shipTurnTimer,
              onChanged: (value) =>
                  ref.read(shipTurnTimerProvider.notifier).setEnabled(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'chest_auto_open_setting_title')),
              subtitle: Text(tr(ref, 'chest_auto_open_setting_desc')),
              value: chestAutoOpen,
              onChanged: (value) =>
                  ref.read(chestAutoOpenProvider.notifier).setEnabled(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'alignment_hunters_setting_title')),
              subtitle: Text(tr(ref, 'alignment_hunters_setting_desc')),
              value: alignmentHunters,
              onChanged: (value) => ref
                  .read(alignmentHuntersEnabledProvider.notifier)
                  .setEnabled(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'companion_auto_target_setting_title')),
              subtitle: Text(tr(ref, 'companion_auto_target_setting_desc')),
              value: companionAutoTarget,
              onChanged: (value) => ref
                  .read(companionAutoTargetProvider.notifier)
                  .setEnabled(value),
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'interface_section_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'walk_companion_setting_title')),
              subtitle: Text(tr(ref, 'walk_companion_setting_desc')),
              value: walkCompanionEnabled,
              onChanged: (value) => ref
                  .read(walkCompanionEnabledProvider.notifier)
                  .setEnabled(value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companionNameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(ref, 'companion_name_label'),
                hintText: tr(ref, 'companion_name_hint'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: tr(ref, 'save'),
                  onPressed: () => ref
                      .read(companionNameProvider.notifier)
                      .setName(_companionNameController.text),
                ),
              ),
              onSubmitted: (value) =>
                  ref.read(companionNameProvider.notifier).setName(value),
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'voice_section_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'voice_section_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(ref, 'auto_read_aloud_setting_title')),
              subtitle: Text(tr(ref, 'auto_read_aloud_setting_desc')),
              value: autoReadAloud,
              onChanged: (value) =>
                  ref.read(autoReadAloudProvider.notifier).setEnabled(value),
            ),
            const ElevenLabsVoiceSettingsSection(),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'updates_section'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${tr(ref, 'current_version_label')}: ${AppInfo.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  (_checkingUpdate || _downloading) ? null : _checkForUpdates,
              icon: _checkingUpdate
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update),
              label: Text(
                _checkingUpdate
                    ? tr(ref, 'checking_for_updates')
                    : tr(ref, 'check_for_updates_button'),
              ),
            ),
            if (isEditMode) ...[
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
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    tooltip: _obscure
                        ? tr(ref, 'show_api_key_tooltip')
                        : tr(ref, 'hide_api_key_tooltip'),
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
              const SizedBox(height: 24),
              Text(
                tr(ref, 'github_sync_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                tr(ref, 'github_sync_desc'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _githubTokenController,
                obscureText: _obscureGithubToken,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(ref, 'github_token_label'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureGithubToken
                        ? Icons.visibility
                        : Icons.visibility_off),
                    tooltip: _obscureGithubToken
                        ? tr(ref, 'show_token_tooltip')
                        : tr(ref, 'hide_token_tooltip'),
                    onPressed: () => setState(
                        () => _obscureGithubToken = !_obscureGithubToken),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final token = _githubTokenController.text.trim();
                        if (token.isEmpty) return;
                        await ref
                            .read(githubTokenProvider.notifier)
                            .setToken(token);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(tr(ref, 'github_token_saved'))),
                        );
                      },
                      child: Text(tr(ref, 'save')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      _githubTokenController.clear();
                      await ref.read(githubTokenProvider.notifier).clearToken();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(tr(ref, 'github_token_removed'))),
                      );
                    },
                    child: Text(tr(ref, 'clear_button')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                tr(ref, 'dev_tools_section'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PlaythroughSimulatorScreen()),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: Text(tr(ref, 'auto_playthrough_button')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pushingEdits ? null : _pushEditsToGithub,
                icon: _pushingEdits
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(tr(ref, 'push_edits_button')),
              ),
            ],
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

  Future<void> _pushEditsToGithub() async {
    final lang = ref.read(appLanguageProvider);
    final token = ref.read(githubTokenProvider);
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trFor(lang, 'set_github_token_first_message'))),
      );
      return;
    }

    final changes = await collectLocalDataEdits();
    if (!mounted) return;
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trFor(lang, 'no_local_edits_message'))),
      );
      return;
    }

    final defaultBranch = 'app-edits-${DateTime.now().millisecondsSinceEpoch}';
    final branchController = TextEditingController(text: defaultBranch);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trFor(lang, 'push_confirm_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trFor(lang, 'push_confirm_message')),
              const SizedBox(height: 8),
              ...changes.map((c) => Text('• ${c.path}')),
              const SizedBox(height: 16),
              TextField(
                controller: branchController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: trFor(lang, 'branch_name_label'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(trFor(lang, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(trFor(lang, 'push_button')),
          ),
        ],
      ),
    );
    final branchName = branchController.text.trim().isEmpty
        ? defaultBranch
        : branchController.text.trim();
    branchController.dispose();
    if (confirmed != true) return;

    setState(() => _pushingEdits = true);
    try {
      final result = await pushEditsToGitHub(
          token: token, branchName: branchName, changes: changes);
      if (!mounted) return;
      setState(() => _pushingEdits = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(trFor(lang, 'push_success_title')),
          content: SelectableText(
              '${trFor(lang, 'push_success_message')}\n\n${result.compareUrl}'),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result.compareUrl));
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(trFor(lang, 'link_copied_message'))),
                );
              },
              child: Text(trFor(lang, 'copy_link_button')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(trFor(lang, 'close_button')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pushingEdits = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${trFor(lang, 'push_failed_prefix')}: $e')),
      );
    }
  }

  String _paletteLabelKey(AppPalette palette) {
    switch (palette) {
      case AppPalette.stitchedInk:
        return 'palette_stitched_ink';
      case AppPalette.deepPurple:
        return 'palette_deep_purple';
      case AppPalette.weatheredEarth:
        return 'palette_weathered_earth';
      case AppPalette.autumnMeadow:
        return 'palette_autumn_meadow';
      case AppPalette.duskHorizon:
        return 'palette_dusk_horizon';
      case AppPalette.auroraDusk:
        return 'palette_aurora_dusk';
      case AppPalette.roseNoir:
        return 'palette_rose_noir';
      case AppPalette.mistSlate:
        return 'palette_mist_slate';
    }
  }

  Future<void> _checkForUpdates() async {
    final lang = ref.read(appLanguageProvider);
    final githubToken = ref.read(githubTokenProvider);

    // This repo is private, so an unauthenticated check always fails with
    // a 404 that otherwise just looks like a generic network error. Catch
    // that upfront with a message that actually explains what to do,
    // rather than spending a round trip to fail the same way every time.
    if (githubToken == null || githubToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trFor(lang, 'update_check_needs_token'))),
      );
      return;
    }

    setState(() => _checkingUpdate = true);
    UpdateInfo? info;
    var failed = false;
    try {
      info = await checkForUpdate(githubToken: githubToken);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trFor(lang, 'update_check_failed'))),
      );
      return;
    }
    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trFor(lang, 'up_to_date_message'))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trFor(lang, 'update_available_title')),
        content: Text(
          '${trFor(lang, 'update_available_prefix')} ${info!.version} '
          '${trFor(lang, 'update_available_suffix')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(trFor(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(trFor(lang, 'download_install_button')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _downloadAndInstall(info);
    }
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    final lang = ref.read(appLanguageProvider);
    final githubToken = ref.read(githubTokenProvider);
    setState(() {
      _downloading = true;
      _downloadProgress = null;
    });

    if (!mounted) return;
    StateSetter? dialogSetState;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          dialogSetState = setDialogState;
          return AlertDialog(
            title: Text(trFor(lang, 'downloading_label')),
            content: LinearProgressIndicator(value: _downloadProgress),
          );
        },
      ),
    );

    try {
      final path = await downloadApk(
        info,
        githubToken: githubToken,
        onProgress: (p) {
          _downloadProgress = p;
          dialogSetState?.call(() {});
        },
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final installResult = await installApk(path);
      if (!installResult.launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trFor(lang, 'install_failed'))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trFor(lang, 'download_failed'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = null;
        });
      }
    }
  }
}
