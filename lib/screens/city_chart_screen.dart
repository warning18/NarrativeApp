// The city chart as a page (see widgets/city_chart): the whole city first,
// zoomed in and out with the fingers, a district tapped to open it. Opened
// from the fight lab for now, on Saltmouth's stub plan; the Journey's city
// level will open it with the game's own record, the party's district and
// the districts it has found.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/map_look_provider.dart';
import '../widgets/city_chart/city_chart.dart';
import '../widgets/city_chart/city_chart_view.dart';

class CityChartScreen extends ConsumerStatefulWidget {
  const CityChartScreen({super.key});

  @override
  ConsumerState<CityChartScreen> createState() => _CityChartScreenState();
}

class _CityChartScreenState extends ConsumerState<CityChartScreen> {
  late final Future<CityChart> _chart =
      CityChart.load(rootBundle, CityChart.saltmouthStub);
  bool _fog = false;

  CityChartText _text() => CityChartText(
        wholeCity: tr(ref, 'city_whole'),
        unexplored: tr(ref, 'city_unexplored'),
        go: tr(ref, 'city_go'),
        here: tr(ref, 'city_here'),
        zoomIn: tr(ref, 'city_zoom_in'),
        zoomOut: tr(ref, 'city_zoom_out'),
        waysOne: tr(ref, 'city_ways_one'),
        waysMany: tr(ref, 'city_ways_many'),
        kinds: {
          CityWayKind.quest: tr(ref, 'city_kind_quest'),
          CityWayKind.fight: tr(ref, 'city_kind_fight'),
          CityWayKind.check: tr(ref, 'city_kind_check'),
          CityWayKind.shop: tr(ref, 'city_kind_shop'),
          CityWayKind.road: tr(ref, 'city_kind_road'),
        },
      );

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(mapLookProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'city_chart_title')),
        actions: [
          IconButton(
            key: const Key('city_chart_fog_toggle'),
            tooltip: tr(ref, 'city_fog_toggle'),
            icon: Icon(_fog ? Icons.cloud : Icons.cloud_outlined),
            onPressed: () => setState(() => _fog = !_fog),
          ),
        ],
      ),
      body: FutureBuilder<CityChart>(
        future: _chart,
        builder: (context, snap) {
          final chart = snap.data;
          if (chart == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CityChartView(
            chart: chart,
            look: look,
            text: _text(),
            // The stub: the party stands at Tern Row's market; when the fog
            // is on, only three districts are found.
            hereDistrict: 'tern',
            explored: _fog ? const {'tern', 'wharf', 'alleys'} : null,
          );
        },
      ),
    );
  }
}
