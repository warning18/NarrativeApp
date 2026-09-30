import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/contracts.dart';
import '../data/sub_node_engine.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';

/// The camp's bounty board (see contracts.dart): three contracts, how far
/// along each is, and a Claim for the ones met. A fresh board goes up by
/// itself once the last one is claimed or the chapter turns.
class BountyBoard extends ConsumerStatefulWidget {
  const BountyBoard({super.key});

  @override
  ConsumerState<BountyBoard> createState() => _BountyBoardState();
}

class _BountyBoardState extends ConsumerState<BountyBoard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _postIfNeeded());
  }

  Future<void> _postIfNeeded() async {
    if (!mounted) return;
    final session = ref.read(playerSessionProvider);
    final chapter = ref.read(reachedChapterProvider);
    if (!boardNeedsPosting(
      contracts: session.contracts,
      postedChapter: session.contractsChapter,
      chapter: chapter,
    )) {
      return;
    }
    final enemies = await loadedGameDb(ref, enemiesSchema);
    if (!mounted) return;
    final huntPool = SubNodeEngine.filterPackPool(
      enemies: enemies,
      enemyPool: SubNodeEngine.filterEnemyPool(
          enemies: enemies, unlockedEnemyIds: const [], chapter: chapter),
    ).toSet().toList()
      ..sort();
    final board = repostBoard(
      session.contracts,
      rollContracts(
        chapter: chapter,
        huntPool: huntPool,
        random: Random(),
        boardNumber: session.contractBoards + 1,
        sea: session.builtHouseIds.contains(harborHouseId),
      ),
    );
    await ref
        .read(playerSessionProvider.notifier)
        .postContractBoard(board, chapter: chapter);
  }

  Future<void> _claim(Contract contract) async {
    await ref.read(playerSessionProvider.notifier).claimContract(contract.id);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text('${tr(ref, 'contract_claimed')} '
          '${_rewardLine(contract)}'),
    ));
    await _postIfNeeded();
  }

  String _rewardLine(Contract contract) =>
      '+${contract.rewardGold} ${tr(ref, 'gold_label')} · '
      '+${contract.rewardEssence} ${tr(ref, 'contract_essence_label')}';

  String _goal(Contract contract, Map<String, dynamic> enemies) {
    final template = tr(ref, 'contract_${contract.kind.name}');
    final enemyName =
        (enemies[contract.targetEnemyId] as Map<String, dynamic>?)?['enemyName']
                ?.toString() ??
            contract.targetEnemyId;
    return template
        .replaceAll('{n}', '${contract.required}')
        .replaceAll('{enemy}', enemyName);
  }

  IconData _icon(ContractKind kind) => switch (kind) {
        ContractKind.hunt => Icons.pets,
        ContractKind.packs => Icons.groups,
        ContractKind.flawless => Icons.shield_moon,
        ContractKind.breaker => Icons.sync_problem,
        ContractKind.weakness => Icons.local_fire_department,
        ContractKind.marked => Icons.star,
        ContractKind.sinkShips => Icons.sailing,
        ContractKind.takeShip => Icons.anchor,
        ContractKind.keelIntact => Icons.shield_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contracts = ref.watch(playerSessionProvider).contracts;
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    if (contracts.isEmpty) {
      return Text(tr(ref, 'contracts_posting'),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final contract in contracts)
          Card(
            key: Key('contract_${contract.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Icon(_icon(contract.kind),
                      color: contract.done
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_goal(contract, enemies),
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: contract.progress / contract.required,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${contract.progress}/${contract.required}',
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_rewardLine(contract),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    key: Key('contract_claim_${contract.id}'),
                    onPressed: contract.done ? () => _claim(contract) : null,
                    child: Text(tr(ref, 'contract_claim')),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(tr(ref, 'contracts_hint'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
