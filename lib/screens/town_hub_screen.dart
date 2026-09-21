import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';
import 'expedition_screen.dart';
import 'shop_detail_screen.dart';

/// A light tutorial/prologue screen for the small town the player arrives
/// at in Chapter 2: a couple of already-stocked basic shops (nothing to
/// build) and the chapter's expedition zones. Deliberately separate from
/// `CampScreen` — Camp is the one persistent base the player builds from
/// scratch and keeps for the rest of the game; the town hub is what they
/// have before they have that.
class TownHubScreen extends ConsumerWidget {
  const TownHubScreen({super.key, this.chapter = 2});

  final int chapter;

  static const List<String> _starterShopIds = [
    'blind_beggar_stall',
    'weaponsmith_forge',
    'apothecary_row',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final shopsAsync = ref.watch(gameDbProvider(shopsSchema));
    final zonesAsync = ref.watch(gameDbProvider(zonesSchema));
    final shops = shopsAsync.value;
    final zones = zonesAsync.value;
    // See camp_screen.dart's own restBlocked -- same reasoning applies here.
    final restBlocked =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);

    if (shops == null || zones == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'town_hub_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chapterZoneIds = zones.entries
        .where((e) => e.value is Map<String, dynamic>)
        .where((e) =>
            ((e.value as Map<String, dynamic>)['chapter'] as num?)?.toInt() ==
            chapter)
        .map((e) => e.key)
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'town_hub_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const SizedBox(height: 16),
          Text(tr(ref, 'basic_shops_section'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final shopId in _starterShopIds)
            if (shops[shopId] is Map<String, dynamic>)
              Card(
                child: ListTile(
                  leading: ShopPixelIcon(shopId),
                  title: Text(
                      (shops[shopId] as Map<String, dynamic>)['shopName']
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
          const Divider(height: 32),
          Text(tr(ref, 'zones_section'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (chapterZoneIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(tr(ref, 'no_zones_available')),
            )
          else
            ...chapterZoneIds.map((zoneId) {
              final zone = zones[zoneId] as Map<String, dynamic>;
              final completed = session.completedZoneIds.contains(zoneId);
              return Card(
                child: ListTile(
                  leading: Icon(
                    completed ? Icons.check_circle : Icons.explore_outlined,
                    color: completed ? Colors.green : null,
                  ),
                  title: Text(zone['zoneName']?.toString() ?? zoneId),
                  subtitle: Text(zone['flavorText']?.toString() ?? ''),
                  isThreeLine: true,
                  trailing: completed
                      ? Text(tr(ref, 'zone_cleared_label'))
                      : ElevatedButton(
                          onPressed: () async {
                            ref.read(expeditionActiveProvider.notifier).state =
                                true;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExpeditionScreen(
                                    zoneId: zoneId, zone: zone),
                              ),
                            );
                            ref.read(expeditionActiveProvider.notifier).state =
                                false;
                          },
                          child: Text(tr(ref, 'begin_expedition_button')),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
