import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/permadeath_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/save_game_provider.dart';
import '../providers/story_providers.dart';
import 'immersive_notice.dart';

/// Opens the save slots, to save into one ([saving]) or load one. True
/// once a slot has been loaded.
Future<bool?> showSaveSlotsSheet(BuildContext context, {required bool saving}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => SaveSlotsSheet(saving: saving),
  );
}

/// The [saveSlotCount] manual saves, each with its character, level,
/// cycle, chapter and time. Saving over a filled slot asks first. With
/// permadeath on the run is ironman: nothing can be loaded, and a death
/// deletes every save (see DeathScreen).
class SaveSlotsSheet extends ConsumerWidget {
  const SaveSlotsSheet({super.key, required this.saving});

  final bool saving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(savedGamesProvider);
    final ironman = ref.watch(permadeathEnabledProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ref,
                  saving ? 'save_slots_save_title' : 'save_slots_load_title'),
              style: theme.textTheme.titleMedium,
            ),
            if (ironman) ...[
              const SizedBox(height: 8),
              Text(tr(ref, 'ironman_note'), style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            for (var slot = 1; slot <= saveSlotCount; slot++)
              _SlotTile(
                slot: slot,
                summary: slots[slot - 1],
                lang: lang,
                enabled: saving || (!ironman && slots[slot - 1] != null),
                onTap: () => saving
                    ? _save(context, ref, slot, slots[slot - 1] != null)
                    : _load(context, ref, slot),
                onDelete: slots[slot - 1] == null
                    ? null
                    : () => ref.read(savedGamesProvider.notifier).delete(slot),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
      BuildContext context, WidgetRef ref, int slot, bool filled) async {
    final lang = ref.read(appLanguageProvider);
    if (filled) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(trFor(lang, 'save_slot_overwrite_title')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(trFor(lang, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(trFor(lang, 'save_slot_overwrite_button')),
            ),
          ],
        ),
      );
      if (overwrite != true) return;
    }
    final playState = ref.read(storyPlayProvider);
    await ref.read(savedGamesProvider.notifier).save(
          slot: slot,
          session: ref.read(playerSessionProvider),
          currentNodeId: playState.currentNodeId,
          history: playState.history,
        );
    if (!context.mounted) return;
    Navigator.pop(context);
    showImmersiveNotice(context,
        icon: Icons.save, message: trFor(lang, 'game_saved_message'));
  }

  Future<void> _load(BuildContext context, WidgetRef ref, int slot) async {
    final lang = ref.read(appLanguageProvider);
    final saved = await ref.read(savedGamesProvider.notifier).load(slot);
    if (!context.mounted) return;
    if (saved == null) {
      showImmersiveNotice(context,
          icon: Icons.error_outline,
          message: trFor(lang, 'save_slot_unreadable'));
      return;
    }
    await ref.read(playerSessionProvider.notifier).loadSession(saved.session);
    ref
        .read(storyPlayProvider.notifier)
        .loadState(saved.currentNodeId, saved.history);
    if (!context.mounted) return;
    Navigator.pop(context, true);
    showImmersiveNotice(context,
        icon: Icons.folder_open, message: trFor(lang, 'game_loaded_message'));
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.summary,
    required this.lang,
    required this.enabled,
    required this.onTap,
    required this.onDelete,
  });

  final int slot;
  final SaveSlotSummary? summary;
  final AppLanguage lang;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final String title;
    final String subtitle;
    if (s == null) {
      title = '${trFor(lang, 'save_slot_label')} $slot';
      subtitle = trFor(lang, 'save_slot_empty');
    } else {
      final name = s.characterName.isNotEmpty
          ? s.characterName
          : [s.raceId, s.professionId].where((p) => p.isNotEmpty).join(' ');
      title = '${trFor(lang, 'save_slot_label')} $slot · $name';
      final chapter = chapterOfNode(s.nodeId);
      subtitle = [
        '${trFor(lang, 'level_abbrev')} ${s.level}',
        if (s.cycle > 0) 'NG+${s.cycle}',
        chapter == 0
            ? trFor(lang, 'chapter_band_prologue')
            : '${trFor(lang, 'chapter_label')} $chapter',
        if (s.savedAt != null) _when(s.savedAt!),
      ].join(' · ');
    }
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(s == null ? Icons.inbox_outlined : Icons.bookmark),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        onTap: enabled ? onTap : null,
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: trFor(lang, 'save_slot_delete_tooltip'),
                onPressed: onDelete,
              ),
      ),
    );
  }

  static String _when(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)} '
        '${two(at.hour)}:${two(at.minute)}';
  }
}
