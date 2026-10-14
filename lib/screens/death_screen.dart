import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_aftermath.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/save_game_provider.dart';
import '../widgets/moments.dart';

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
    this.signsLost = 0,
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

  /// How many signs the life carried (see signs.dart): a death takes them
  /// all, and the patrons keep only their favour.
  final int signsLost;

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
          // Scrolls when the last words run long on a short phone.
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The dark falls first, then the title bleeds in and
                  // the last words are written after it.
                  const RiseIn(
                    child: Icon(Icons.dangerous,
                        color: Colors.redAccent, size: 64),
                  ),
                  const SizedBox(height: 16),
                  RiseIn(
                    delay: const Duration(milliseconds: 350),
                    child: Text(
                      tr(ref, 'you_died_title'),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Color(0xAAFF1744), blurRadius: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RiseIn(
                    delay: const Duration(milliseconds: 800),
                    child: Text(
                      deathNarrationFor(
                        killerName,
                        french:
                            ref.watch(appLanguageProvider) == AppLanguage.fr,
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
                          if (widget.signsLost > 0)
                            _StatLine(
                              label: tr(ref, 'signs_lost_label'),
                              value: '${widget.signsLost}',
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
