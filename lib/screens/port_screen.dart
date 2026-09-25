import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/port_helpers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/zone_card.dart';
import 'expedition_screen.dart';
import 'shop_detail_screen.dart';

/// One port of call (a ports.json row) as its own page: the Smugglers'
/// Wharf, chapter 2's Town Hub, opened from Edit Mode's Play tab. In play
/// every other port is reached by the Rusty Eel, and the Ship tab shows
/// the one she is moored at (see ShipScreen).
class PortScreen extends ConsumerWidget {
  const PortScreen({super.key, required this.portId, this.titleKey});

  final String portId;

  /// An l10n key used as the app bar title instead of the port's own name
  /// (the Town Hub keeps the name the player already knows it by).
  final String? titleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final port = ref.watch(localizedDbProvider(portsSchema)).value?[portId]
        as Map<String, dynamic>?;
    final title = titleKey != null
        ? tr(ref, titleKey!)
        : (port == null ? portId : portNameFor(port, fr));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [PortServices(portId: portId)],
      ),
    );
  }
}

/// What a port offers the party ashore: its description, a rest, the
/// shops trading there and the expedition zones reachable from it.
class PortServices extends ConsumerWidget {
  const PortServices({super.key, required this.portId});

  final String portId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final shops = ref.watch(localizedDbProvider(shopsSchema)).value;
    final zones = ref.watch(localizedDbProvider(zonesSchema)).value;
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    final restBlocked =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);

    if (ports == null || shops == null || zones == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final port = ports[portId] as Map<String, dynamic>?;
    if (port == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(tr(ref, 'no_zones_available')),
      );
    }

    final shopIds = portShopIds(port)
        .where((id) => shops[id] is Map<String, dynamic>)
        .toList();
    final zoneIds = portZoneIds(port)
        .where((id) => zones[id] is Map<String, dynamic>)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          portDescriptionFor(port, fr),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: restBlocked ? tr(ref, 'rest_blocked_hint') : '',
          child: OutlinedButton.icon(
            onPressed: restBlocked
                ? null
                : () async {
                    await ref
                        .read(playerSessionProvider.notifier)
                        .healPartyToFull();
                    if (!context.mounted) return;
                    showImmersiveNotice(
                      context,
                      icon: Icons.local_fire_department,
                      message: tr(ref, 'party_rested_message'),
                    );
                  },
            icon: const Icon(Icons.local_fire_department_outlined),
            label: Text(tr(ref, 'rest_button')),
          ),
        ),
        if (shopIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(tr(ref, 'port_shops_section'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final shopId in shopIds)
            Card(
              child: ListTile(
                leading: ShopPixelIcon(shopId),
                title: Text((shops[shopId] as Map<String, dynamic>)['shopName']
                        ?.toString() ??
                    shopId),
                subtitle: Text(
                  (shops[shopId] as Map<String, dynamic>)['shopDescription']
                          ?.toString() ??
                      '',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShopDetailScreen(
                      shopId: shopId,
                      shop: shops[shopId] as Map<String, dynamic>,
                    ),
                  ),
                ),
              ),
            ),
        ],
        const Divider(height: 32),
        Text(tr(ref, 'zones_section'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (zoneIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(tr(ref, 'no_zones_available')),
          )
        else
          for (final zoneId in zoneIds)
            ZoneCard(
              zoneId: zoneId,
              zone: zones[zoneId] as Map<String, dynamic>,
              zones: zones,
              enemies: enemies,
              enabled: !restBlocked,
              onBegin: () => launchExpedition(
                  context, ref, zoneId, zones[zoneId] as Map<String, dynamic>),
            ),
      ],
    );
  }
}

/// Opens the expedition into [zoneId], marking one under way while it runs
/// (so rest and voyages wait for it).
Future<void> launchExpedition(BuildContext context, WidgetRef ref,
    String zoneId, Map<String, dynamic> zone) async {
  final expedition = ref.read(expeditionActiveProvider.notifier);
  expedition.state = true;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ExpeditionScreen(zoneId: zoneId, zone: zone),
    ),
  );
  expedition.state = false;
}
