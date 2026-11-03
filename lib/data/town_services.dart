// What a town offers and what each of its service pins opens (wave 14,
// docs/proposals/journey-world-data.md): the pins stand on the town's plan
// (city_plans.json's `services`, laid by town_service_pins.dart); what they
// open comes from the story (StoryStops.servicesAt: the shops its scenes
// unlock, the ports its settlements sail from) and the game's own screens.
import 'choice_flow.dart';
import 'city_plan_record.dart';
import 'story_repository.dart' show StoryData;

/// What a service pin opens.
enum TownServiceAction {
  /// A shop: ShopDetailScreen(shopId: id), shops.json's row.
  shop,

  /// The bounty board: the BountyBoard widget (lib/widgets/bounty_board.dart,
  /// contracts.dart), id 'bounty_board'.
  bountyBoard,

  /// A night's rest: restTheNight (lib/widgets/road_panel.dart), id
  /// 'rest_night'.
  rest,

  /// A port of call: PortScreen(portId: id), ports.json's row.
  port,

  /// The temple's Mending and blessing (temple.dart, wave 15): id the
  /// place whose ruler keeps it, the pin's district (else the town).
  temple,
}

/// One thing a pin opens: the [action], its [id] (the shop or port id, or
/// the action's own), and whether it is [unlocked] now (a shop the session
/// has unlocked; the others always are).
typedef TownServiceOpen = ({
  TownServiceAction action,
  String id,
  bool unlocked,
});

/// The shops that stand at a town's forge rather than its market.
const Set<String> _forgeShopIds = {
  'weaponsmith_forge',
  'hammersmith_forge',
  'shieldwrights_hall',
};

/// One of a town's services: its pin on the plan and what it opens, in
/// order. An empty [opens] is a service with no screen yet (a market or
/// forge with no shop in this town; a harbour with no port).
class TownService {
  const TownService(this.pin, this.opens);
  final CityServicePin pin;
  final List<TownServiceOpen> opens;

  String get id => pin.id;
  String get kind => pin.kind;

  /// Whether tapping it opens something (one of [opens] is unlocked).
  bool get opensSomething => opens.any((o) => o.unlocked);
}

/// The services of the town [record] is the plan of, with what each opens:
/// the shops and ports [stops] finds at the town (none when null), a shop
/// [unlockedShopIds] holds unlocked. Only the town's own: a shop a choice
/// of one of its scenes unlocks, and the port a settlement of it names as
/// its `portId` with the shops that port lists. A `landingPortId` (where
/// the Rusty Eel puts in for a place whose port is elsewhere) is not the
/// town's, so neither it nor its shops are: [story] tells them apart
/// (without it, only the shops a choice unlocks count).
List<TownService> townServicesOf(
  CityPlanRecord record,
  StoryStops? stops, {
  StoryData? story,
  Set<String> unlockedShopIds = const {},
}) {
  final offered = stops?.servicesAt(record.cityId) ?? const <PlaceService>[];
  bool ownPort(PlaceService s) =>
      story?.nodeFor(s.nodeId)?.settlement?.portId != null;
  final shops = <String>{
    for (final s in offered)
      if (s.kind == PlaceServiceKind.shop &&
          (s.choiceIndex != null || ownPort(s)))
        s.id,
  };
  final ports = <String>{
    for (final s in offered)
      if (s.kind == PlaceServiceKind.port &&
          story?.nodeFor(s.nodeId)?.settlement?.portId == s.id)
        s.id,
  };
  TownServiceOpen shop(String id) => (
        action: TownServiceAction.shop,
        id: id,
        unlocked: unlockedShopIds.contains(id),
      );
  return [
    for (final pin in record.services)
      TownService(
          pin,
          switch (pin.kind) {
            'notice_board' => const [
                (
                  action: TownServiceAction.bountyBoard,
                  id: 'bounty_board',
                  unlocked: true
                ),
              ],
            'market' => [
                for (final id in shops)
                  if (!_forgeShopIds.contains(id)) shop(id),
              ],
            'forge' => [
                for (final id in shops)
                  if (_forgeShopIds.contains(id)) shop(id),
              ],
            'tavern' => const [
                (
                  action: TownServiceAction.rest,
                  id: 'rest_night',
                  unlocked: true
                ),
              ],
            'temple' => [
                (
                  action: TownServiceAction.temple,
                  id: pin.district.isNotEmpty ? pin.district : record.cityId,
                  unlocked: true
                ),
              ],
            'harbour' => [
                for (final id in ports)
                  (action: TownServiceAction.port, id: id, unlocked: true),
              ],
            _ => const [],
          }),
  ];
}
