// QA: waves 14 and the camp's roll houses (v1.481, v1.482) on a phone, with
// the app's own fonts: a town's plan with its service pins, the sheets a pin
// opens, the move over the world chart (flat and globe), and the row of roll
// powers under a choice. 360 x 740 and 320 x 568, English and French, no
// overflow (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for the pictures).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/camp_rolls.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/town_services.dart';
import 'package:narrative_data_app/data/world_leg_path.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart'
    show chartGlobeProvider;
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'package:narrative_data_app/widgets/roll_power_row.dart';
import 'package:narrative_data_app/widgets/town_service_sheet.dart';

import 'qa_smoke_harness.dart';

/// Opens a town service's sheet as soon as it is built.
class _OpenSheet extends StatefulWidget {
  const _OpenSheet(this.service);
  final TownService service;

  @override
  State<_OpenSheet> createState() => _OpenSheetState();
}

class _OpenSheetState extends State<_OpenSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? showTownServiceSheet(context, widget.service) : null);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  const here = Offset(10, 10);
  TownService service(String kind, List<TownServiceOpen> opens) =>
      TownService(CityServicePin('t_$kind', kind, here, 'wharf'), opens);

  testWidgets('the towns and the world chart read on a phone, EN and FR',
      (tester) async {
    final chart = await tester
        .runAsync(() => CityChart.load(rootBundle, CityChart.saltmouthStub));
    final wharf = chart!.districtById('wharf')!;
    final gate = chart.districtById('gate')!;
    final move = worldLegPath(chartOf(MapShape.story), 'beggar', 'candlehold');
    final clock = AnimationController(
        vsync: tester, duration: const Duration(seconds: 10))
      ..value = 0.5;
    addTearDown(clock.dispose);

    Widget worldMove() => SizedBox(
          height: 460,
          child: JourneyWorldMap(
            level: JourneyMapLevel.world,
            palette: ChartPalette.of(MapLook.night),
            here: null,
            discovered: const {},
            legs: const [],
            ahead: null,
            shopPlaces: const {},
            campPlaces: const {},
            chapterColor: (_) => Colors.amber,
            onLayers: () {},
            move: move,
            moveClock: clock,
          ),
        );

    await runSmoke(tester, [
      SmokeCase(
        'city_service_pins',
        SizedBox(
          height: 460,
          child: CityChartView(
            chart: chart,
            look: MapLook.night,
            animate: false,
            focus: 'wharf',
            services: [
              CityChartService(
                  id: 'market',
                  kind: 'market',
                  at: wharf.centre,
                  district: 'wharf'),
              CityChartService(
                  id: 'forge',
                  kind: 'forge',
                  at: wharf.centre + const Offset(30, 20),
                  district: 'wharf'),
              CityChartService(
                  id: 'temple',
                  kind: 'temple',
                  at: gate.centre,
                  district: 'gate',
                  opens: false),
            ],
            onService: (_) {},
          ),
        ),
      ),
      SmokeCase(
          'service_sheet_temple', _OpenSheet(service('temple', const []))),
      SmokeCase(
        'service_sheet_market',
        _OpenSheet(service('market', [
          (
            action: TownServiceAction.shop,
            id: 'blind_beggar_stall',
            unlocked: true
          ),
          (
            action: TownServiceAction.shop,
            id: 'black_market_docks',
            unlocked: false
          ),
          (
            action: TownServiceAction.bountyBoard,
            id: 'bounty_board',
            unlocked: true
          ),
          (action: TownServiceAction.rest, id: 'rest_night', unlocked: true),
        ])),
      ),
      SmokeCase('world_move_flat', worldMove(), bare: true),
      SmokeCase(
        'world_move_globe',
        worldMove(),
        bare: true,
        prepare: (container) =>
            container.read(chartGlobeProvider.notifier).choose(true),
      ),
      SmokeCase(
        'roll_power_row',
        Column(children: [
          RollPowerRow(
            keyPrefix: 'smoke',
            rolls: const CampRolls(reroll: 3, banish: 2, raise: 1),
            onReroll: () async {},
            onBanish: (_) async {},
            onRaise: () async {},
            canBanish: true,
            canRaise: true,
          ),
          RollPowerRow(
            keyPrefix: 'smoke2',
            rolls: const CampRolls(reroll: 12, banish: 12, raise: 12),
            onReroll: () async {},
            onBanish: (_) async {},
            onRaise: () async {},
            warnRaised: true,
          ),
        ]),
      ),
    ]);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
