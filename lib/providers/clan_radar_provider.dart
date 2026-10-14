import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_radar.dart';
import 'clans_provider.dart';
import 'signs_provider.dart';

/// [factionId]'s radar (clan_radar.dart) as it stands: its gifts'
/// orientation on five axes, and its live steps with the other clans.
/// For the clan gift popin and the clan tab (Wave 7 D).
final clanRadarProvider =
    Provider.family<ClanRadar, String>((ref, factionId) => clanRadarOf(
          factionId,
          data: ref.watch(clanDataProvider),
          signs: ref.watch(signDefsProvider),
          relationSteps: ref.watch(politicsProvider).relationSteps,
        ));
