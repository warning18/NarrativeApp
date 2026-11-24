// The Tower's door and start screen (v1.847, docs/proposals/
// the-tower-designs.md, direction A): the marks and the best floor, a run
// to continue, and the pick of a people, a calling and a clan for a new
// one (the ones not bought yet lie locked), then Climb.
import '../../widgets/fit_title.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import '../race_profession_screen.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';
import 'tower_backdrop.dart';
import 'tower_floor_screen.dart';
import 'tower_look.dart';
import 'tower_marks_screen.dart';
import 'tower_providers.dart';

/// The Tower's door, in the Tower's night theme (its body below).
class TowerStartScreen extends StatelessWidget {
  const TowerStartScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TowerNight(child: _TowerStartBody());
}

class _TowerStartBody extends ConsumerStatefulWidget {
  const _TowerStartBody();

  @override
  ConsumerState<_TowerStartBody> createState() => _TowerStartScreenState();
}

class _TowerStartScreenState extends ConsumerState<_TowerStartBody> {
  bool _starting = false;

  String _fill(String text, Map<String, Object> values) {
    var out = text;
    values.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }

  /// The callings not yet bought lie padlocked on the creation screen, with
  /// what they cost.
  Map<String, String> _locks(Set<String> open) => {
        for (final u in towerUnlocks)
          if (u.kind == TowerUnlockKind.profession && !open.contains(u.value))
            u.value: _fill(tr(ref, 'tower_bought_with_marks'), {'n': u.cost}),
      };

  /// The main game's Race & Profession screen picks the hero; the run starts
  /// when it hands the pick back, and takes its place.
  Future<void> _create() async {
    final progress = ref.read(towerProvider).value?.progress;
    final locks = _locks(progress?.professions ?? towerStartProfessions);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TowerNight(
          child: RaceProfessionScreen(locks: locks, onChosen: _begin),
        ),
      ),
    );
  }

  Future<void> _begin(String race, String profession) async {
    if (_starting) return;
    setState(() => _starting = true);
    final data = await ref.read(towerDataProvider.future);
    await ref
        .read(towerProvider.notifier)
        .start(data: data, raceId: race, professionId: profession);
    if (!mounted) return;
    setState(() => _starting = false);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TowerFloorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final paper = theme.textTheme.apply(
      bodyColor: inkOnPaper,
      displayColor: inkOnPaper,
    );
    final state = ref.watch(towerProvider).value ?? const TowerState();
    final progress = state.progress;
    final run = state.run;
    return Scaffold(
      appBar: AppBar(title: FitTitle(tr(ref, 'tower_name'))),
      body: TowerBackdrop(
        floor: 1,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                tr(ref, 'tower_tagline'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 18),
              // The marks and the best floor, on paper (Art's wide frame).
              InkPaperPanel(
                title: tr(ref, 'tower_marks_name'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${progress.marks} ${tr(ref, 'tower_marks_name')}',
                            key: const Key('tower_marks_total'),
                            style: paper.titleMedium,
                          ),
                          Text(
                            [
                              _fill(tr(ref, 'tower_best'), {
                                'n': progress.bestFloor,
                              }),
                              _fill(tr(ref, 'tower_runs_line'), {
                                'r': progress.runs,
                                'w': progress.wins,
                              }),
                            ].join(' · '),
                            style: paper.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    InkButton(
                      buttonKey: const Key('tower_marks_button'),
                      onPaper: true,
                      label: tr(ref, 'tower_marks_button'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TowerMarksScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (run != null && !run.isOver) ...[
                const SizedBox(height: 14),
                // A run to go on with: a slanted panel of its band's plate.
                _continuePanel(run, theme),
              ],
              const SizedBox(height: 14),
              InkButton(
                buttonKey: const Key('tower_climb'),
                primary: true,
                height: 46,
                label: tr(ref, 'tower_climb'),
                onPressed: _starting ? null : _create,
              ),
              const SizedBox(height: 8),
              Text(
                tr(ref, 'tower_save_note'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // The three bands of the tower, top to bottom (v1.900).
              const SizedBox(height: 18),
              for (final band in [3, 2, 1]) _bandPane(band, theme, ink),
            ],
          ),
        ),
      ),
    );
  }

  /// The run to go on with: its band's plate in a slanted panel, the floor it
  /// stands on, and the button that goes on (red).
  Widget _continuePanel(TowerRun run, ThemeData theme) => LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          const h = 104.0;
          return InkSlantPanel(
            size: Size(w, h),
            points: [
              const Offset(8, 10),
              Offset(w - 8, 2),
              Offset(w - 8, h - 8),
              const Offset(8, h - 8),
            ],
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  towerBackdropAsset(towerBandOf(run.floor)),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
                Positioned(
                  left: 20,
                  top: 14,
                  right: 20,
                  bottom: 14,
                  child: ColoredBox(
                    color: inkBlack.withValues(alpha: 0.82),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fill(
                                  tr(ref, 'tower_floor_of'), {'n': run.floor}),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: InkFonts.display,
                                color: inkPaper,
                              ),
                            ),
                          ),
                          InkButton(
                            buttonKey: const Key('tower_continue'),
                            primary: true,
                            label: tr(ref, 'tower_continue'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TowerFloorScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  /// One band of the tower as a pane of its own picture: its name and floors.
  Widget _bandPane(int band, ThemeData theme, InkColors ink) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  towerBackdropAsset(band),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
                ColoredBox(color: Colors.black.withValues(alpha: .45)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(ref, 'tower_band_$band'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${(band - 1) * 10 + 1}\u2013${band * 10}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: ink.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
