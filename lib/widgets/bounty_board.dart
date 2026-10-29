import 'dart:async';
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
import '../theme/stitched_ink.dart';

/// The notice board (see contracts.dart), a board you read (v1.561): three
/// contracts pinned on wood as parchment notes, slightly tilted, each with a
/// stamp-ring for its kind, its goal, how far along it is, its pay as chips,
/// and a wax seal that is the Claim: flat and grey while the note is open,
/// red and glowing once it is met. A claimed note is stamped PAID and drops
/// off; a new board's notes pin up one after another. A fresh board goes up
/// by itself once the last one is claimed or the chapter turns. The camp and
/// the towns' notice boards both show it.
class BountyBoard extends ConsumerStatefulWidget {
  const BountyBoard({super.key});

  @override
  ConsumerState<BountyBoard> createState() => _BountyBoardState();
}

class _BountyBoardState extends ConsumerState<BountyBoard>
    with SingleTickerProviderStateMixin {
  /// The notes pin up one after another: 0 to 1 over the board.
  late final AnimationController _pinUp = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  /// The board the notes last pinned up for (its first note's id).
  String? _pinnedFor;

  /// Notes just claimed, kept on the board a moment under their PAID stamp:
  /// the contract and where it stood.
  final Map<String, ({Contract contract, int index})> _paid = {};

  bool get _still => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _postIfNeeded());
  }

  @override
  void dispose() {
    _pinUp.dispose();
    super.dispose();
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
        beastTracked: session.seaBeasts.values.any((b) => b.tracked),
      ),
    );
    await ref
        .read(playerSessionProvider.notifier)
        .postContractBoard(board, chapter: chapter);
  }

  Future<void> _claim(Contract contract) async {
    final index = ref.read(playerSessionProvider).contracts.indexOf(contract);
    if (!_still && index >= 0) {
      setState(() => _paid[contract.id] = (contract: contract, index: index));
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _paid.remove(contract.id));
      });
    }
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
        ContractKind.beastFought => Icons.set_meal,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final contracts = session.contracts;
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    if (contracts.isEmpty && _paid.isEmpty) {
      return Text(tr(ref, 'contracts_posting'),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    // A new board pins its notes up one after another.
    final boardKey = contracts.isEmpty ? null : contracts.first.id;
    if (boardKey != null && boardKey != _pinnedFor) {
      _pinnedFor = boardKey;
      final still = _still;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (still) {
          _pinUp.value = 1;
        } else {
          _pinUp.forward(from: 0);
        }
      });
    }
    // The notes on the board, the ones just paid back where they hung.
    final notes = <({Contract contract, bool paid})>[
      for (final c in contracts) (contract: c, paid: false),
    ];
    final paid = _paid.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final p in paid) {
      notes.insert(
          min(p.index, notes.length), (contract: p.contract, paid: true));
    }
    final waiting = contracts.where((c) => c.done).length;
    final header = (waiting > 0
            ? tr(ref, 'board_header_claim')
            : tr(ref, 'board_header_open'))
        .replaceAll('{n}', '${session.contractsChapter}')
        .replaceAll('{k}', waiting > 0 ? '$waiting' : '${contracts.length}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(header,
              key: const Key('board_header'),
              style: theme.textTheme.labelLarge?.copyWith(
                  color: waiting > 0 ? _sealRed : ink.ash, letterSpacing: 0.4)),
        ),
        _Wood(
          child: Column(
            children: [
              for (final (i, note) in notes.indexed)
                AnimatedBuilder(
                  animation: _pinUp,
                  builder: (context, child) {
                    // Note i lands in its own slice of the pin-up.
                    final start = i * 0.2;
                    final t = ((_pinUp.value - start) / 0.4).clamp(0.0, 1.0);
                    final e = Curves.easeOutBack.transform(t);
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(
                          offset: Offset(0, -14 * (1 - e)), child: child),
                    );
                  },
                  child: _NoteSlot(
                    key: Key('contract_${note.contract.id}'),
                    tilt: i.isEven ? -0.012 : 0.01,
                    paid: note.paid,
                    still: _still,
                    child: _Note(
                      contract: note.contract,
                      goal: _goal(note.contract, enemies),
                      icon: _icon(note.contract.kind),
                      gold: '+${note.contract.rewardGold}',
                      essence: '+${note.contract.rewardEssence}',
                      progressText: tr(ref, 'contract_progress_of')
                          .replaceAll('{a}', '${note.contract.progress}')
                          .replaceAll('{b}', '${note.contract.required}'),
                      claimLabel: tr(ref, 'contract_claim'),
                      goldLabel: tr(ref, 'gold_label'),
                      essenceLabel: tr(ref, 'contract_essence_label'),
                      onClaim: note.paid || !note.contract.done
                          ? null
                          : () => _claim(note.contract),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(tr(ref, 'contracts_hint'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

/// The wax of a met contract's seal.
const Color _sealRed = Color(0xFFC0392B);
const Color _parchment = Color(0xFFEADFC2);
const Color _noteInk = Color(0xFF2B2118);
const Color _noteBrown = Color(0xFF7A5B3A);

/// The board's wood: planks with a dark frame.
class _Wood extends StatelessWidget {
  const _Wood({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5B4128),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF33231A), width: 4),
        ),
        child: CustomPaint(
          painter: _PlankPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
            child: child,
          ),
        ),
      );
}

class _PlankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final seam = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 2;
    final grain = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    // Horizontal planks, about 60 px each, with a little grain.
    for (var y = 60.0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
      canvas.drawLine(Offset(0, y + 2), Offset(size.width, y + 2), grain);
    }
    for (var y = 20.0; y < size.height; y += 60) {
      canvas.drawLine(
          Offset(size.width * 0.1, y), Offset(size.width * 0.55, y), grain);
      canvas.drawLine(Offset(size.width * 0.45, y + 24),
          Offset(size.width * 0.9, y + 24), grain);
    }
  }

  @override
  bool shouldRepaint(_PlankPainter old) => false;
}

/// A note's place on the board: tilted a hair; a paid note is stamped PAID
/// and drops off.
class _NoteSlot extends StatefulWidget {
  const _NoteSlot({
    super.key,
    required this.tilt,
    required this.paid,
    required this.still,
    required this.child,
  });

  final double tilt;
  final bool paid;
  final bool still;
  final Widget child;

  @override
  State<_NoteSlot> createState() => _NoteSlotState();
}

class _NoteSlotState extends State<_NoteSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void initState() {
    super.initState();
    if (widget.paid && !widget.still) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // The stamp lands in the first third; the note drops in the last.
        final stamp = Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
        final drop = Curves.easeIn.transform(((t - 0.6) / 0.4).clamp(0.0, 1.0));
        return Opacity(
          opacity: 1 - drop,
          child: Transform.translate(
            offset: Offset(0, 40 * drop),
            child: Transform.rotate(
              angle: widget.tilt,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    child!,
                    if (widget.paid)
                      Positioned.fill(
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.22,
                            child: Transform.scale(
                              scale: 1.8 - 0.8 * stamp,
                              child: Opacity(
                                opacity: stamp.clamp(0.0, 1.0),
                                child: const _PaidStamp(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _PaidStamp extends ConsumerWidget {
  const _PaidStamp();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        key: const Key('contract_paid_stamp'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: _sealRed, width: 3),
          borderRadius: BorderRadius.circular(4),
          color: _parchment.withValues(alpha: 0.6),
        ),
        child: Text(tr(ref, 'contract_paid'),
            style: const TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 30,
                height: 1.1,
                letterSpacing: 3,
                color: _sealRed)),
      );
}

/// One parchment note: a nail, a stamp-ring for its kind, the goal, how far
/// along, the pay, the wax seal.
class _Note extends StatelessWidget {
  const _Note({
    required this.contract,
    required this.goal,
    required this.icon,
    required this.gold,
    required this.essence,
    required this.progressText,
    required this.claimLabel,
    required this.goldLabel,
    required this.essenceLabel,
    required this.onClaim,
  });

  final Contract contract;
  final String goal;
  final IconData icon;
  final String gold;
  final String essence;
  final String progressText;
  final String claimLabel;
  final String goldLabel;
  final String essenceLabel;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = contract.done;
    final ring = done ? _sealRed : _noteBrown;
    Widget chip(IconData i, String text, String label) => Semantics(
          label: '$text $label',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _noteBrown.withValues(alpha: 0.7)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(i, size: 13, color: _noteBrown),
              const SizedBox(width: 3),
              Text(text,
                  style: const TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 12,
                      height: 1.1,
                      color: _noteInk)),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 8, 10),
      decoration: BoxDecoration(
        color: _parchment,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 4, offset: Offset(1, 3)),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        // The nail.
        const Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
              child:
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF3A3A3F))),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // The kind, as a stamp ring.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring.withValues(alpha: 0.85), width: 2),
            ),
            child: Icon(icon, size: 21, color: ring),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: _noteInk, fontSize: 16, height: 1.25)),
                const SizedBox(height: 6),
                Row(children: [
                  // How far along, as pips.
                  for (var k = 0; k < contract.required && k < 12; k++)
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            k < contract.progress ? ring : Colors.transparent,
                        border: Border.all(color: ring, width: 1.5),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(progressText,
                      style: const TextStyle(
                          fontFamily: InkFonts.system,
                          fontSize: 12,
                          color: _noteInk)),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  chip(Icons.monetization_on_outlined, gold, goldLabel),
                  chip(Icons.auto_awesome, essence, essenceLabel),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _Seal(
              key: Key('contract_claim_${contract.id}'),
              label: claimLabel,
              onTap: onClaim),
        ]),
      ]),
    );
  }
}

/// The wax seal that is the Claim: grey and flat while the note is open, red
/// and glowing once it is met.
class _Seal extends StatelessWidget {
  const _Seal({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: SizedBox(
          width: 58,
          height: 64,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? _sealRed : const Color(0xFFA79C86),
                border: Border.all(
                    color:
                        on ? const Color(0xFF8E2A1F) : const Color(0xFF8D8269),
                    width: 2),
                boxShadow: on
                    ? [
                        BoxShadow(
                            color: _sealRed.withValues(alpha: 0.55),
                            blurRadius: 10,
                            spreadRadius: 1),
                      ]
                    : null,
              ),
              child: Icon(on ? Icons.check : Icons.hourglass_empty,
                  size: 20, color: on ? _parchment : const Color(0xFF6F664F)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 10,
                    color: on ? _sealRed : const Color(0xFF6F664F))),
          ]),
        ),
      ),
    );
  }
}
