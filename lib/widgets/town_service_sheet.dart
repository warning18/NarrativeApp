// A town's service pin tapped on its plan (wave 14): a sheet with what it
// opens (town_services.dart) -- the shops of the market or the forge, the
// bounty board, a night's rest, the port -- or a line saying there is
// nothing to do there yet (the temple has no screen).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/town_services.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../screens/port_screen.dart';
import '../screens/shop_detail_screen.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'bounty_board.dart';
import 'city_chart/city_chart_painter.dart';
import 'road_panel.dart';

/// The name of a service's kind, in the player's language.
String townServiceName(WidgetRef ref, String kind) => tr(ref, 'service_$kind');

/// Opens the sheet of [service].
Future<void> showTownServiceSheet(BuildContext context, TownService service) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _TownServiceSheet(service: service, host: context),
  );
}

class _TownServiceSheet extends ConsumerWidget {
  const _TownServiceSheet({required this.service, required this.host});

  final TownService service;

  /// The screen under the sheet: what a row opens is pushed over it.
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final shops = ref.watch(localizedDbProvider(shopsSchema)).value ??
        const <String, dynamic>{};
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ??
        const <String, dynamic>{};
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);
    void push(Widget page) {
      Navigator.of(context).pop();
      Navigator.of(host).push(MaterialPageRoute(builder: (_) => page));
    }

    Widget row(TownServiceOpen open) {
      switch (open.action) {
        case TownServiceAction.shop:
          final shop = shops[open.id] as Map<String, dynamic>?;
          return ListTile(
            key: Key('town_service_open_${open.id}'),
            leading: ShopPixelIcon(open.id),
            title: Text(shop?['shopName']?.toString() ?? open.id),
            subtitle: open.unlocked
                ? Text(shop?['shopDescription']?.toString() ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis)
                : Text(tr(ref, 'service_shop_locked')),
            trailing: open.unlocked ? const Icon(Icons.chevron_right) : null,
            enabled: open.unlocked && shop != null,
            onTap: () => push(ShopDetailScreen(shopId: open.id, shop: shop!)),
          );
        case TownServiceAction.bountyBoard:
          return ListTile(
            key: const Key('town_service_open_bounty_board'),
            leading: const Icon(Icons.assignment_outlined),
            title: Text(tr(ref, 'service_bounty_board')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(Scaffold(
              appBar: AppBar(title: Text(tr(ref, 'service_bounty_board'))),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: const [BountyBoard()],
              ),
            )),
          );
        case TownServiceAction.rest:
          return ListTile(
            key: const Key('town_service_open_rest'),
            leading: const Icon(Icons.local_fire_department_outlined),
            title: Text(tr(ref, 'rest_button')),
            subtitle: busy ? Text(tr(ref, 'rest_blocked_hint')) : null,
            enabled: !busy,
            onTap: () {
              Navigator.of(context).pop();
              restTheNight(host, ref, message: tr(ref, 'party_rested_message'));
            },
          );
        case TownServiceAction.port:
          final port = ports[open.id] as Map<String, dynamic>?;
          return ListTile(
            key: Key('town_service_open_${open.id}'),
            leading: const Icon(Icons.anchor),
            title: Text(port?['portName']?.toString() ?? open.id),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(PortScreen(portId: open.id)),
          );
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Icon(CityChartPainter.serviceIcon(service.kind),
                      color: ink.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(townServiceName(ref, service.kind),
                        key: const Key('town_service_title'),
                        style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            if (service.opens.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(tr(ref, 'service_nothing_yet'),
                    key: const Key('town_service_nothing'),
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
              )
            else
              for (final open in service.opens) row(open),
          ],
        ),
      ),
    );
  }
}
