import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feature_unlocks.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/player_session_provider.dart';
import '../widgets/offer_dialog.dart';
import 'quest_autopilot.dart' show questsSettling;

/// The clans' offers are never left for later: whenever one waits and the
/// home screen is on top (nothing over it, no fight, no quest being
/// settled), the offer dialog opens on its own and stays until a gift is
/// taken, then the next follows until none waits. This covers what no
/// other screen opens: offers from a chapter, a quest, an intrigue, a
/// Tome, those still waiting from an older save at launch, and those that
/// waited on the feature ladder until the clans came. In play only (Edit
/// Mode leaves them to the editor), and not before the clans' feature is
/// open. An offer nobody can come to (drawOffer is null) is not retried
/// until the number waiting changes: it never blocks the player.
class OfferAutopilot extends ConsumerStatefulWidget {
  const OfferAutopilot({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfferAutopilot> createState() => _OfferAutopilotState();
}

class _OfferAutopilotState extends ConsumerState<OfferAutopilot> {
  /// A check is scheduled for after this frame.
  bool _scheduled = false;

  /// The number waiting when none could be drawn: not tried again until it
  /// changes.
  int? _noneAt;

  bool _due() {
    if (!mounted) return false;
    if (ref.read(appModeProvider) != AppMode.inGame) return false;
    if (ref.read(combatActiveProvider) || questsSettling) return false;
    final notifier = ref.read(playerSessionProvider.notifier);
    if (!notifier.isLoaded) return false;
    final session = ref.read(playerSessionProvider);
    if (session.characterName.isEmpty) return false;
    final waiting = session.pendingOffers.length;
    if (waiting == 0 || waiting == _noneAt) return false;
    if (!session.featureOpen(GameFeature.clans)) return false;
    if (!(ModalRoute.isCurrentOf(context) ?? true)) return false;
    return !offerOpenOn(Navigator.of(context, rootNavigator: true));
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _open();
    });
  }

  Future<void> _open() async {
    if (!_due()) return;
    final waiting = ref.read(playerSessionProvider).pendingOffers.length;
    final drawn = await showOfferIfWaiting(context, ref);
    if (!mounted) return;
    if (!drawn) {
      _noneAt = waiting;
      return;
    }
    // Taken: the next, if one still waits.
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt when the home screen comes back on top (a page or a dialog
    // over it closed), when the offers waiting change, when the clans
    // open, and when a fight ends or the mode changes.
    final current = ModalRoute.isCurrentOf(context) ?? true;
    final waiting =
        ref.watch(playerSessionProvider.select((s) => s.pendingOffers.length));
    final clansOpen = ref.watch(
        playerSessionProvider.select((s) => s.featureOpen(GameFeature.clans)));
    final inGame = ref.watch(appModeProvider) == AppMode.inGame;
    final fighting = ref.watch(combatActiveProvider);
    if (waiting != _noneAt) _noneAt = null;
    if (current && waiting > 0 && clansOpen && inGame && !fighting) {
      _schedule();
    }
    return widget.child;
  }
}
