// The city chart as a page (see widgets/city_chart): the whole city first,
// zoomed in and out with the fingers, a district tapped to open it, the
// districts the party has not found under fog, the party's mark where it
// stands. Opened from the Journey in a city (the plan is Core's record,
// city_plans.json, the ways the scene's own); a way picked from its card
// comes back to the Journey as the choice to take, and "Walk here" moves
// the party to another district for free. Without a city (the fight lab's
// preview) it shows Saltmouth's stub plan.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/city_districts.dart';
import '../data/journey_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/city_provider.dart';
import '../providers/geography_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/story_providers.dart';
import '../providers/day_phase_provider.dart';
import '../providers/town_rulers_provider.dart';
import '../widgets/city_chart/city_chart.dart';
import '../widgets/city_chart/city_chart_view.dart';

CityWayKind _wayKindOf(JourneyStepKind kind) => switch (kind) {
      JourneyStepKind.fight => CityWayKind.fight,
      JourneyStepKind.check || JourneyStepKind.challenge => CityWayKind.check,
      JourneyStepKind.shop => CityWayKind.shop,
      JourneyStepKind.quest || JourneyStepKind.mainQuest => CityWayKind.quest,
      _ => CityWayKind.road,
    };

class CityChartScreen extends ConsumerStatefulWidget {
  /// [preview]: Saltmouth's stub plan, with no story behind it.
  const CityChartScreen({super.key, this.preview = false});

  final bool preview;

  @override
  ConsumerState<CityChartScreen> createState() => _CityChartScreenState();
}

class _CityChartScreenState extends ConsumerState<CityChartScreen> {
  late final Future<CityChart> _stub =
      CityChart.load(rootBundle, CityChart.saltmouthStub);
  bool _fog = false;

  // The chart of the story's city, kept while what it is made of holds.
  CityChart? _chart;
  String _chartKey = '';

  CityChartText _text() => CityChartText(
        wholeCity: tr(ref, 'city_whole'),
        unexplored: tr(ref, 'city_unexplored'),
        go: tr(ref, 'city_go'),
        walk: tr(ref, 'city_walk'),
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

  /// The chart of the city the story is in, or null while it loads or when
  /// the story is not in a city with a plan.
  ({CityChart chart, List<StoryChoice> choices})? _live() {
    final city = ref.watch(currentCityProvider);
    final record = ref.watch(cityPlanRecordsProvider).value?[city];
    final story = ref.watch(storyDataProvider).value;
    if (city == null || record == null || story == null) return null;
    final play = ref.watch(storyPlayProvider);
    final node = story.nodeFor(play.currentNodeId);
    if (node == null) return null;
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final geo = ref.watch(geographyProvider);
    final session = ref.watch(playerSessionProvider);
    final gate = ref.watch(coastGateWorldProvider);
    final districts = wayDistricts(geo, story, node);
    final choices = <StoryChoice>[];
    final inputs = <CityWayInput>[];
    for (final (i, c) in node.choices.indexed) {
      if (choiceHiddenFor(c, session, gate)) continue;
      final district = districts[i];
      if (district == null || !record.districts.containsKey(district)) continue;
      choices.add(c);
      inputs.add(CityWayInput(
        id: '${choices.length - 1}',
        districtId: district,
        kind: _wayKindOf(journeyStepKindOf(c)),
        name: c.textFor(french),
        sceneId: c.nextId,
      ));
    }
    final key = [
      city,
      play.currentNodeId,
      french,
      for (final w in inputs) '${w.districtId}:${w.sceneId}',
    ].join('|');
    if (key != _chartKey || _chart == null) {
      _chartKey = key;
      _chart = CityChart.fromRecord(
        record,
        districtNames: {
          for (final d in districtsOfCity(geo, city)) d.id: d.nameFor(french),
        },
        ways: inputs,
        french: french,
        name: geo.locationOf(city)?.nameFor(french) ?? '',
      );
    }
    return (chart: _chart!, choices: choices);
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(mapLookProvider);
    final live = widget.preview ? null : _live();
    final title = live?.chart.name.isNotEmpty == true
        ? live!.chart.name
        : tr(ref, 'city_chart_title');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.preview)
            IconButton(
              key: const Key('city_chart_fog_toggle'),
              tooltip: tr(ref, 'city_fog_toggle'),
              icon: Icon(_fog ? Icons.cloud : Icons.cloud_outlined),
              onPressed: () => setState(() => _fog = !_fog),
            ),
        ],
      ),
      body: widget.preview
          ? FutureBuilder<CityChart>(
              future: _stub,
              builder: (context, snap) {
                final chart = snap.data;
                if (chart == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return CityChartView(
                  chart: chart,
                  look: look,
                  text: _text(),
                  hereDistrict: 'tern',
                  explored: _fog ? const {'tern', 'wharf', 'alleys'} : null,
                );
              },
            )
          : live == null
              ? const Center(child: CircularProgressIndicator())
              : CityChartView(
                  chart: live.chart,
                  look: look,
                  text: _text(),
                  hereDistrict: ref.watch(partyDistrictProvider),
                  explored: ref.watch(foundDistrictsProvider),
                  rulers: cityChartRulersOf(
                      live.chart, ref.watch(townRulersProvider)),
                  locked: ref.watch(lockedDistrictsProvider),
                  phase: ref.watch(dayPhaseProvider),
                  onWay: (way) {
                    final i = int.tryParse(way.id);
                    if (i != null && i < live.choices.length) {
                      Navigator.of(context).pop(live.choices[i]);
                    }
                  },
                  onWalk: (d) => walkToDistrict(ref, d.id),
                ),
    );
  }
}
