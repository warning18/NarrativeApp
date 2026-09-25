import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../combat/combat_engine.dart' show newGamePlusStep;
import '../data/chapter_grid_layout.dart';
import '../data/story_repository.dart';
import '../models/story_node.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/finished_story_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/permadeath_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/save_game_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../widgets/save_slots_sheet.dart';
import 'home_shell.dart';
import 'settings_screen.dart';

/// Opens the game (HomeShell) over the menu in [mode], on the Story tab.
Future<void> enterGame(
    BuildContext context, WidgetRef ref, AppMode mode) async {
  await ref.read(appModeProvider.notifier).setMode(mode);
  ref.read(homeTabIndexProvider.notifier).state = 0;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: gameRouteName),
      builder: (_) => const HomeShell(),
    ),
  );
}

/// The title screen: Continue (when a story is under way), New Game, New
/// Game+ (once a story has been finished), Load, Settings and Edit Mode.
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  /// What the last look for an already finished story saw (see
  /// [_countStoryAlreadyFinished]), so it runs again only when the game or
  /// the saves change.
  String? _lastFinishedCheck;

  /// Stories finished before the menu kept count (before 1.134) still
  /// offer New Game+: a game standing on an ending counts, the one in
  /// progress first, else the most recently saved one. Only while nothing
  /// is recorded, and never over a real record.
  Future<void> _countStoryAlreadyFinished() async {
    final finished = ref.read(finishedStoryProvider.notifier);
    await finished.ready;
    if (!mounted || ref.read(finishedStoryProvider).any) return;
    final StoryData story;
    try {
      story = await ref.read(storyDataProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    bool isEnding(String nodeId) {
      final node = story.nodeFor(nodeId);
      return node != null && isStoryEnding(node);
    }

    final session = ref.read(playerSessionProvider);
    final play = ref.read(storyPlayProvider);
    if (session.raceId.isNotEmpty && isEnding(play.currentNodeId)) {
      await finished.backfill(session, play.currentNodeId);
      return;
    }
    final endedSlots = ref
        .read(savedGamesProvider)
        .whereType<SaveSlotSummary>()
        .where((slot) => isEnding(slot.nodeId))
        .toList()
      ..sort((a, b) =>
          (b.savedAt ?? DateTime(0)).compareTo(a.savedAt ?? DateTime(0)));
    for (final slot in endedSlots) {
      final saved = await ref.read(savedGamesProvider.notifier).load(slot.slot);
      if (!mounted) return;
      if (saved == null || saved.session.raceId.isEmpty) continue;
      await finished.backfill(saved.session, saved.currentNodeId);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final story = ref.watch(storyPlayProvider);
    final finished = ref.watch(finishedStoryProvider);
    final slots = ref.watch(savedGamesProvider);
    final hasSave = slots.any((slot) => slot != null);
    if (finished.loaded && !finished.any) {
      final check = [
        session.raceId,
        story.currentNodeId,
        for (final slot in slots) '${slot?.nodeId}@${slot?.savedAt}',
      ].join('|');
      if (check != _lastFinishedCheck) {
        _lastFinishedCheck = check;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _countStoryAlreadyFinished());
      }
    }
    final ironman = ref.watch(permadeathEnabledProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inProgress = hasGameInProgress(session, story);

    final chapter = chapterOfNode(story.currentNodeId);
    final continueDetail = [
      if (session.characterName.isNotEmpty) session.characterName,
      if (session.raceId.isNotEmpty)
        '${tr(ref, 'level_abbrev')} ${session.level}',
      chapter == 0
          ? tr(ref, 'chapter_band_prologue')
          : '${tr(ref, 'chapter_label')} $chapter',
      if (session.newGamePlusCycle > 0)
        '${tr(ref, 'new_game_plus_label')} ${session.newGamePlusCycle}',
    ].join(' · ');

    Widget item({
      required Key key,
      required IconData icon,
      required String label,
      String? detail,
      VoidCallback? onPressed,
      bool primary = false,
    }) {
      final child = Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: primary ? FontWeight.w600 : null,
                        color: primary ? scheme.onPrimary : null)),
                if (detail != null && detail.isNotEmpty)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primary
                          ? scheme.onPrimary.withValues(alpha: 0.85)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
      final style = ButtonStyle(
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: primary
            ? FilledButton(
                key: key, onPressed: onPressed, style: style, child: child)
            : OutlinedButton(
                key: key,
                onPressed: onPressed,
                style: style.copyWith(
                  backgroundColor:
                      WidgetStatePropertyAll(scheme.surfaceContainer),
                ),
                child: child),
      );
    }

    return Scaffold(
      body: ColoredBox(
        color: scheme.surface,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Text(lang == AppLanguage.fr ? '🇫🇷' : '🇬🇧'),
                  tooltip: tr(ref, 'language'),
                  onPressed: () => ref
                      .read(appLanguageProvider.notifier)
                      .setLanguage(lang == AppLanguage.fr
                          ? AppLanguage.en
                          : AppLanguage.fr),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full size where the screen has room for it,
                        // small on a short one so the menu stays in view.
                        Center(
                          child: _BannerMark(
                            size: MediaQuery.sizeOf(context).height >= 760
                                ? 150
                                : 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(ref, 'menu_title'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            height: 1,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(ref, 'menu_subtitle'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (inProgress)
                          item(
                            key: const Key('menu_continue'),
                            icon: Icons.play_arrow_rounded,
                            label: tr(ref, 'menu_continue'),
                            detail: continueDetail,
                            primary: true,
                            onPressed: () =>
                                enterGame(context, ref, AppMode.inGame),
                          ),
                        item(
                          key: const Key('menu_new_game'),
                          icon: Icons.add_circle_outline,
                          label: tr(ref, 'menu_new_game'),
                          primary: !inProgress,
                          onPressed: () =>
                              _newGame(context, ref, confirm: inProgress),
                        ),
                        if (finished.any)
                          item(
                            key: const Key('menu_new_game_plus'),
                            icon: Icons.replay_circle_filled_outlined,
                            label: tr(ref, 'new_game_plus_button'),
                            detail:
                                '${tr(ref, 'new_game_plus_cycle_label')} ${finished.lastRun!.newGamePlusCycle + 1}',
                            onPressed: () => _newGamePlus(context, ref),
                          ),
                        item(
                          key: const Key('menu_load'),
                          icon: Icons.folder_open_outlined,
                          label: tr(ref, 'menu_load'),
                          detail: ironman
                              ? tr(ref, 'ironman_load_tooltip')
                              : (hasSave ? null : tr(ref, 'menu_no_saves')),
                          onPressed: !hasSave || ironman
                              ? null
                              : () async {
                                  final loaded = await showSaveSlotsSheet(
                                      context,
                                      saving: false);
                                  if (loaded == true && context.mounted) {
                                    await enterGame(
                                        context, ref, AppMode.inGame);
                                  }
                                },
                        ),
                        item(
                          key: const Key('menu_settings'),
                          icon: Icons.settings_outlined,
                          label: tr(ref, 'settings'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                        ),
                        item(
                          key: const Key('menu_edit_mode'),
                          icon: Icons.edit_note,
                          label: tr(ref, 'menu_edit_mode'),
                          detail: tr(ref, 'menu_edit_mode_desc'),
                          onPressed: () =>
                              enterGame(context, ref, AppMode.edit),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'v${AppInfo.version}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A fresh story from character creation. Over a story under way it
  /// asks first: the story's own autosave is replaced (the save slots are
  /// kept).
  Future<void> _newGame(BuildContext context, WidgetRef ref,
      {required bool confirm}) async {
    if (confirm) {
      final lang = ref.read(appLanguageProvider);
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(trFor(lang, 'menu_new_game')),
          content: Text(trFor(lang, 'menu_new_game_confirm_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(trFor(lang, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(trFor(lang, 'menu_new_game')),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref
        .read(playerSessionProvider.notifier)
        .resetSession(keepLegacy: false);
    ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
    if (!context.mounted) return;
    await enterGame(context, ref, AppMode.inGame);
  }

  /// The next cycle of the last finished story: its legacy (a share of
  /// its gold, its dice and spells) is banked, enemies grow tougher, and
  /// the story starts over at character creation.
  Future<void> _newGamePlus(BuildContext context, WidgetRef ref) async {
    final finished = ref.read(finishedStoryProvider).lastRun;
    if (finished == null) return;
    final lang = ref.read(appLanguageProvider);
    final nextCycle = finished.newGamePlusCycle + 1;
    final bonus = (newGamePlusStep * nextCycle * 100).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${trFor(lang, 'new_game_plus_button')} · '
            '${trFor(lang, 'new_game_plus_cycle_label')} $nextCycle'),
        content: Text(
          '${trFor(lang, 'new_game_plus_desc')}\n\n'
          '${trFor(lang, 'new_game_plus_enemies_prefix')} +$bonus% '
          '${trFor(lang, 'new_game_plus_enemies_suffix')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(trFor(lang, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(trFor(lang, 'new_game_plus_confirm')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final notifier = ref.read(playerSessionProvider.notifier);
    await notifier.loadSession(finished);
    await notifier.beginNewGamePlus();
    ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
    if (!context.mounted) return;
    await enterGame(context, ref, AppMode.inGame);
  }
}

/// The title's mark: a tattered banner on its pole, a seam stitched along
/// its edge and the tear's Void sigil sewn in the middle.
class _BannerMark extends StatelessWidget {
  const _BannerMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = InkColors.of(context);
    return SizedBox(
      width: size * 220 / 250,
      height: size,
      child: CustomPaint(
        painter: _BannerPainter(
          cloth: scheme.surfaceContainer,
          edge: scheme.onSurfaceVariant,
          pole: scheme.outline,
          seam: ink.seam,
          sigil: ink.voidColor,
          thread: ink.gold,
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  const _BannerPainter({
    required this.cloth,
    required this.edge,
    required this.pole,
    required this.seam,
    required this.sigil,
    required this.thread,
  });

  final Color cloth;
  final Color edge;
  final Color pole;
  final Color seam;
  final Color sigil;
  final Color thread;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 220 x 250 grid, scaled to fit.
    canvas.scale(size.width / 220, size.height / 250);
    final stroke = Paint()..style = PaintingStyle.stroke;

    canvas.drawLine(
        const Offset(30, 10),
        const Offset(30, 240),
        stroke
          ..color = pole
          ..strokeWidth = 3);
    canvas.drawCircle(const Offset(30, 8), 5, Paint()..color = pole);

    final banner = Path()
      ..moveTo(33, 20)
      ..lineTo(196, 20)
      ..lineTo(186, 52)
      ..lineTo(198, 86)
      ..lineTo(180, 110)
      ..lineTo(194, 142)
      ..lineTo(170, 150)
      ..lineTo(176, 176)
      ..lineTo(150, 168)
      ..lineTo(128, 188)
      ..lineTo(112, 170)
      ..lineTo(86, 196)
      ..lineTo(70, 172)
      ..lineTo(48, 186)
      ..lineTo(33, 178)
      ..close();
    canvas.drawPath(banner, Paint()..color = cloth);
    canvas.drawPath(
        banner,
        stroke
          ..color = edge
          ..strokeWidth = 1.5);

    // The stitched seam just inside the top and right edges.
    final seamPaint = Paint()
      ..color = seam
      ..strokeWidth = 1;
    const seamPoints = [
      Offset(40, 28),
      Offset(186, 28),
      Offset(178, 54),
      Offset(188, 84),
      Offset(172, 108),
      Offset(184, 136),
    ];
    for (var i = 0; i < seamPoints.length - 1; i++) {
      _dashed(canvas, seamPoints[i], seamPoints[i + 1], seamPaint, 4, 4);
    }

    // The Void's sigil: a torn eye, and the gold thread that holds it.
    final eye = Path()
      ..moveTo(112, 70)
      ..cubicTo(98, 96, 104, 124, 116, 140)
      ..cubicTo(126, 118, 134, 96, 112, 70)
      ..close();
    canvas.drawPath(
        eye,
        stroke
          ..color = sigil
          ..strokeWidth = 2);
    _dashed(
        canvas,
        const Offset(112, 84),
        const Offset(114, 128),
        Paint()
          ..color = sigil
          ..strokeWidth = 1.5,
        3,
        3);
    canvas.drawLine(
        const Offset(86, 104),
        const Offset(138, 104),
        Paint()
          ..color = thread
          ..strokeWidth = 1.5);
  }

  void _dashed(
      Canvas canvas, Offset a, Offset b, Paint paint, double dash, double gap) {
    final delta = b - a;
    final length = delta.distance;
    if (length == 0) return;
    final dir = delta / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      final end = (d + dash).clamp(0.0, length);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
    }
  }

  @override
  bool shouldRepaint(_BannerPainter old) =>
      old.cloth != cloth ||
      old.edge != edge ||
      old.pole != pole ||
      old.seam != seam ||
      old.sigil != sigil ||
      old.thread != thread;
}
