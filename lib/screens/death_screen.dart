import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_aftermath.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/save_game_provider.dart';

/// Shown after a permadeath loss, once the player's session has already
/// been reset (inventory cleared, story restarted to node 0). Purely a
/// confirmation/summary screen — tapping through just closes it, revealing
/// the already-reset app underneath.
class DeathScreen extends ConsumerStatefulWidget {
  const DeathScreen({
    super.key,
    required this.lostItemIds,
    required this.xpEarned,
    required this.nodesVisited,
    required this.skillsLost,
    this.killerName = '',
    this.narrationSeed = 0,
  });

  /// Who landed the last blow, for the written death above the tally.
  final String killerName;
  final int narrationSeed;

  final List<String> lostItemIds;
  final int xpEarned;
  final int nodesVisited;

  /// How many unlocked skills the reset wiped back to class basics.
  final int skillsLost;

  @override
  ConsumerState<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends ConsumerState<DeathScreen> {
  @override
  void initState() {
    super.initState();
    // Ironman: a permadeath death takes the manual saves with it, so
    // turning permadeath off afterwards brings no checkpoint back.
    ref.read(savedGamesProvider.notifier).deleteAll();
  }

  String get killerName => widget.killerName;
  int get narrationSeed => widget.narrationSeed;
  List<String> get lostItemIds => widget.lostItemIds;
  int get xpEarned => widget.xpEarned;
  int get nodesVisited => widget.nodesVisited;
  int get skillsLost => widget.skillsLost;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dangerous,
                      color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    tr(ref, 'you_died_title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    deathNarrationFor(
                      killerName,
                      french: ref.watch(appLanguageProvider) == AppLanguage.fr,
                      seed: narrationSeed,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(ref, 'you_died_message'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white10,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatLine(
                            label: tr(ref, 'nodes_visited_label'),
                            value: '$nodesVisited',
                          ),
                          _StatLine(
                            label: tr(ref, 'xp_earned_label'),
                            value: '$xpEarned',
                          ),
                          _StatLine(
                            label: tr(ref, 'items_lost_label'),
                            value: '${lostItemIds.length}',
                          ),
                          _StatLine(
                            label: tr(ref, 'skills_reset_label'),
                            value: '$skillsLost',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr(ref, 'return_to_start_button')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
