import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../widgets/immersive_notice.dart';
import 'inventory_screen.dart';
import 'skills_screen.dart';

const int _basePartyCapacity = 2;

class CampScreen extends ConsumerWidget {
  const CampScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final companionsAsync = ref.watch(gameDbProvider(companionsSchema));
    final housesAsync = ref.watch(gameDbProvider(housesSchema));
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final gameConfigAsync = ref.watch(gameConfigProvider);

    final companions = companionsAsync.value;
    final houses = housesAsync.value;
    final races = racesAsync.value;
    final professions = professionsAsync.value;
    final gameConfig = gameConfigAsync.value;

    if (companions == null || houses == null || races == null || professions == null || gameConfig == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'camp_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final partyCapacity = _basePartyCapacity +
        houses.values
            .whereType<Map<String, dynamic>>()
            .where((h) => session.builtHouseIds.contains(h['houseID']?.toString() ?? ''))
            .fold<int>(0, (sum, h) => sum + ((h['partyCapacityBonus'] as num?)?.toInt() ?? 0));

    final recruitedIds = session.recruitedAllies.map((a) => a.companionId).toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'camp_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr(ref, 'roster_section'), style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${tr(ref, 'active_party_label')}: '
                '${session.activeAllyIds.length} / $partyCapacity',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(playerSessionProvider.notifier).healPartyToFull();
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
          const SizedBox(height: 12),
          if (recruitedIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(tr(ref, 'no_companions_recruited')),
            )
          else
            ...recruitedIds.map((companionId) {
              final companion = companions[companionId] as Map<String, dynamic>?;
              final ally = session.recruitedAllies.firstWhere((a) => a.companionId == companionId);
              final raceId = companion?['raceId']?.toString() ?? '';
              final professionId = companion?['professionId']?.toString() ?? '';
              final race = races[raceId] as Map<String, dynamic>? ?? const {};
              final profession = professions[professionId] as Map<String, dynamic>? ?? const {};
              final base =
                  deriveAllyBaseStats(gameConfig: gameConfig, race: race, profession: profession);
              final liveMaxHealth = scaledMaxHealth(base.maxHealth, session.level);
              final liveHealth = ally.currentHealth.clamp(0, liveMaxHealth);
              final raceName = race['raceName']?.toString() ?? raceId;
              final professionName = profession['professionName']?.toString() ?? professionId;
              final isActive = session.activeAllyIds.contains(companionId);
              final requiredHouseId = companion?['requiredHouseId']?.toString() ?? '';
              final requiredHouseBuilt =
                  requiredHouseId.isEmpty || session.builtHouseIds.contains(requiredHouseId);
              final requiredHouseName = requiredHouseId.isNotEmpty
                  ? ((houses[requiredHouseId] as Map<String, dynamic>?)?['houseName']?.toString() ??
                      requiredHouseId)
                  : null;
              final atCapacity = !isActive && session.activeAllyIds.length >= partyCapacity;
              final canActivate = !isActive && requiredHouseBuilt && !atCapacity;

              String lockReason = '';
              if (!isActive) {
                if (!requiredHouseBuilt) {
                  lockReason = '${tr(ref, 'requires_house_prefix')}: $requiredHouseName';
                } else if (atCapacity) {
                  lockReason = tr(ref, 'party_at_capacity');
                }
              }

              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: Icon(isActive ? Icons.shield : Icons.shield_outlined),
                      title: Text(companion?['companionName']?.toString() ?? companionId),
                      subtitle: Text(
                        '$raceName $professionName · $liveHealth / $liveMaxHealth '
                        '${tr(ref, 'hp_label')}'
                        '${lockReason.isNotEmpty ? '\n$lockReason' : ''}',
                      ),
                      isThreeLine: lockReason.isNotEmpty,
                      trailing: FilterChip(
                        label: Text(isActive ? tr(ref, 'active_label') : tr(ref, 'benched_label')),
                        selected: isActive,
                        onSelected: (!isActive && !canActivate)
                            ? null
                            : (_) => ref.read(playerSessionProvider.notifier).setAllyActive(
                                  companionId,
                                  !isActive,
                                  partyCapacity: partyCapacity,
                                  requiredHouseId: requiredHouseId,
                                ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InventoryScreen(allyId: companionId),
                                ),
                              ),
                              icon: const Icon(Icons.backpack_outlined),
                              label: Text(tr(ref, 'inventory_equipment')),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SkillsScreen(allyId: companionId),
                                ),
                              ),
                              icon: const Icon(Icons.auto_awesome_outlined),
                              label: Text(tr(ref, 'skills')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 32),
          Text(tr(ref, 'houses_section'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...(houses.keys.toList()..sort()).map((houseId) {
            final house = houses[houseId] as Map<String, dynamic>;
            final houseName = house['houseName']?.toString() ?? houseId;
            final description = house['description']?.toString() ?? '';
            final cost = (house['buildCost'] as num?)?.toInt() ?? 0;
            final capacityBonus = (house['partyCapacityBonus'] as num?)?.toInt() ?? 0;
            final built = session.builtHouseIds.contains(houseId);
            final affordable = session.gold >= cost;

            final statsParts = <String>[
              if (capacityBonus > 0) '+$capacityBonus ${tr(ref, 'party_capacity_label')}',
            ];

            return Card(
              child: ListTile(
                leading: Icon(built ? Icons.home : Icons.home_outlined),
                title: Text(houseName),
                subtitle: Text(
                  [
                    description,
                    if (statsParts.isNotEmpty) statsParts.join(' · '),
                  ].where((s) => s.isNotEmpty).join('\n'),
                ),
                isThreeLine: true,
                trailing: built
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        onPressed: !affordable
                            ? null
                            : () async {
                                await ref
                                    .read(playerSessionProvider.notifier)
                                    .buildHouse(houseId, cost);
                                if (!context.mounted) return;
                                showImmersiveNotice(
                                  context,
                                  icon: Icons.home,
                                  message: '${trFor(ref.read(appLanguageProvider), 'house_built_prefix')}: $houseName',
                                );
                              },
                        child: Text('${tr(ref, 'build_button')} ($cost ${tr(ref, 'gold_label')})'),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
