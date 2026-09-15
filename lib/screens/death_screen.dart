import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';

/// Shown after a permadeath loss, once the player's session has already
/// been reset (inventory cleared, story restarted to node 0). Purely a
/// confirmation/summary screen — tapping through just closes it, revealing
/// the already-reset app underneath.
class DeathScreen extends ConsumerWidget {
  const DeathScreen({
    super.key,
    required this.lostItemIds,
    required this.xpEarned,
    required this.nodesVisited,
  });

  final List<String> lostItemIds;
  final int xpEarned;
  final int nodesVisited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
