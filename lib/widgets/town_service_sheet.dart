// A town's service pin tapped on its plan (wave 14): a sheet with what it
// opens (town_services.dart) -- the shops of the market or the forge, the
// bounty board, a night's rest, the port, the temple's Mending and
// blessing (temple.dart) -- or a line saying there is nothing to do there
// yet.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_remarks.dart' show RemarkKind;
import '../data/temple.dart';
import '../data/town_services.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/clans_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/moment_remark_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/temple_provider.dart';
import '../screens/port_screen.dart';
import '../screens/shop_detail_screen.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'bounty_board.dart';
import 'city_chart/city_chart_painter.dart';
import 'companion_remark_bubble.dart';
import 'road_panel.dart';
import 'sheet_kit.dart';

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
          return SheetRow(
            key: Key('town_service_open_${open.id}'),
            leading: ShopPixelIcon(open.id),
            title: shop?['shopName']?.toString() ?? open.id,
            lines: [
              if (open.unlocked)
                shop?['shopDescription']?.toString() ?? ''
              else
                tr(ref, 'service_shop_locked'),
            ],
            maxLines: open.unlocked ? 2 : null,
            trailing: open.unlocked ? const Icon(Icons.chevron_right) : null,
            enabled: open.unlocked && shop != null,
            onTap: () => push(ShopDetailScreen(shopId: open.id, shop: shop!)),
          );
        case TownServiceAction.bountyBoard:
          return SheetRow(
            key: const Key('town_service_open_bounty_board'),
            leading: const Icon(Icons.assignment_outlined),
            title: tr(ref, 'service_bounty_board'),
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
          return SheetRow(
            key: const Key('town_service_open_rest'),
            leading: const Icon(Icons.local_fire_department_outlined),
            title: tr(ref, 'rest_button'),
            lines: [if (busy) tr(ref, 'rest_blocked_hint')],
            enabled: !busy,
            onTap: () {
              Navigator.of(context).pop();
              restTheNight(host, ref, message: tr(ref, 'party_rested_message'));
            },
          );
        case TownServiceAction.port:
          final port = ports[open.id] as Map<String, dynamic>?;
          return SheetRow(
            key: Key('town_service_open_${open.id}'),
            leading: const Icon(Icons.anchor),
            title: port?['portName']?.toString() ?? open.id,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(PortScreen(portId: open.id)),
          );
        case TownServiceAction.temple:
          return _TempleRows(placeId: open.id, host: host);
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              icon: CityChartPainter.serviceIcon(service.kind),
              title: _templeName(ref, service) ??
                  townServiceName(ref, service.kind),
              titleKey: const Key('town_service_title'),
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

/// The temple's rows (temple.dart, Core's minimal hook; UX draws the real
/// sheet): Mending and the blessing at their prices, or why not; a Hunted
/// character sees the refusal instead.
class _TempleRows extends ConsumerWidget {
  const _TempleRows({required this.placeId, required this.host});

  final String placeId;
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(templeOfferProvider(placeId));
    watchMomentRemarks(ref);
    final lang = ref.watch(appLanguageProvider);
    final keeper = ref.watch(clanDataProvider).faction(offer.clanId);
    String own(String? text, String key) =>
        text == null || text.isEmpty ? tr(ref, key) : text;
    if (offer.refused) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
            own(keeper?.templeLineHuntedFor(lang), 'temple_refused_hunted'),
            key: const Key('temple_refused')),
      );
    }
    String why(TempleBlock? block, int price) => switch (block) {
          TempleBlock.busy => tr(ref, 'rest_blocked_hint'),
          TempleBlock.poor => tr(ref, 'temple_too_poor'),
          TempleBlock.mendedToday => tr(ref, 'temple_mended_today'),
          _ => tr(ref, 'temple_price').replaceAll('{gold}', '$price'),
        };
    Future<void> buy(Future<bool> Function(PlayerSessionNotifier n) act,
        String done, RemarkKind kind) async {
      final messenger = ScaffoldMessenger.maybeOf(host);
      final text = tr(ref, done);
      final bought = await act(ref.read(playerSessionProvider.notifier));
      // A companion's word on it (Core's speakUpOnMoment), over the sheet
      // while its ref still lives; then the sheet closes.
      final remark =
          bought && context.mounted ? speakUpOnMoment(ref, kind) : null;
      if (remark != null && context.mounted) {
        await showCompanionRemarks(context, ref, [remark]);
      }
      if (context.mounted) Navigator.of(context).pop();
      if (bought) messenger?.showSnackBar(SnackBar(content: Text(text)));
    }

    final data = ref.read(clanDataProvider);
    final chapter = ref.read(reachedChapterProvider);
    final keeperLine = offer.isNeutral ? '' : keeper?.templeLineFor(lang) ?? '';
    final blessingTitle =
        offer.isNeutral ? '' : keeper?.blessingNameFor(lang) ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // What the keeper says of the temple: a clan's voice under its name.
        if (keeperLine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(keeperLine,
                key: const Key('temple_keeper_line'),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ),
        if (offer.mendOffered)
          SheetRow(
            key: const Key('temple_mend'),
            leading: const Icon(Icons.healing_outlined),
            title: tr(ref, 'temple_mend_name'),
            price: offer.mendBlock == null ? offer.mendPrice : null,
            lines: [
              if (offer.mendBlock != null)
                why(offer.mendBlock, offer.mendPrice),
              tr(ref, 'temple_mend_desc'),
            ],
            enabled: offer.canMend,
            onTap: () => buy(
                (n) => n.templeMend(offer.clanId, data: data, chapter: chapter),
                'temple_mend_result',
                RemarkKind.templeMended),
          ),
        SheetRow(
          key: const Key('temple_bless'),
          leading: const Icon(Icons.auto_awesome_outlined),
          // A clan's temple gives its blessing a name, "Blessing" the small
          // label above it; the neutral shrine keeps the plain title.
          title: blessingTitle.isEmpty
              ? tr(ref, 'temple_blessing_name')
              : blessingTitle,
          label: blessingTitle.isEmpty ? null : tr(ref, 'temple_blessing_name'),
          titleKey:
              blessingTitle.isEmpty ? null : const Key('temple_bless_title'),
          price: offer.blessingBlock == null ? offer.blessingPrice : null,
          lines: [
            if (offer.blessingBlock != null)
              why(offer.blessingBlock, offer.blessingPrice),
            offer.isNeutral
                ? tr(ref, 'temple_neutral_blessing_line')
                : own(keeper?.blessingGrantsFor(lang), 'temple_blessing_desc'),
            if (offer.blessingReplaces) tr(ref, 'temple_blessed_already'),
            if (offer.blessingStanding) tr(ref, 'temple_blessing_standing'),
          ],
          enabled: offer.canBless,
          onTap: () => buy(
              (n) => n.templeBless(offer.clanId, data: data, chapter: chapter),
              'temple_blessing_result',
              RemarkKind.templeBlessed),
        ),
      ],
    );
  }
}

/// The name of the temple [service] opens: its keeper's `templeName`, or
/// the neutral shrine's; null for any other service.
String? _templeName(WidgetRef ref, TownService service) {
  final open = service.opens
      .where((o) => o.action == TownServiceAction.temple)
      .firstOrNull;
  if (open == null) return null;
  final clanId = ref.watch(templeClanProvider(open.id));
  if (clanId.isEmpty) return tr(ref, 'temple_neutral_name');
  final name = ref
      .watch(clanDataProvider)
      .faction(clanId)
      ?.templeNameFor(ref.watch(appLanguageProvider));
  return name == null || name.isEmpty ? null : name;
}
