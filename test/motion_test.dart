// "Remove animations" (v1.870): the few animations that start in initState or
// on a change stop when the platform asks for no motion: the city chart's
// breathing and zooms, the map's sky fading in, a stat pulsing.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'package:narrative_data_app/widgets/motion.dart';

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    c.forwardOrJump(context);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

Widget _under({required bool still, required Widget child}) => MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityChart chart;

  setUpAll(() async {
    chart = await CityChart.load(rootBundle, CityChart.saltmouthStub);
  });

  testWidgets('forwardOrJump lands on the end at once when motion is off',
      (tester) async {
    await tester.pumpWidget(_under(still: true, child: const _Probe()));
    final c = (tester.state(find.byType(_Probe)) as _ProbeState).c;
    expect(c.value, 1);
    expect(c.isAnimating, isFalse);
  });

  testWidgets('and plays as always when it is on', (tester) async {
    await tester.pumpWidget(_under(still: false, child: const _Probe()));
    final c = (tester.state(find.byType(_Probe)) as _ProbeState).c;
    expect(c.isAnimating, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.value, 1);
  });

  testWidgets(
      'the city chart does not breathe with motion off, and does '
      'with it on', (tester) async {
    Widget view() => MaterialApp(
          theme: buildAppTheme(ThemeData.light()
              .colorScheme
              .copyWith(brightness: Brightness.light)),
          home:
              Scaffold(body: CityChartView(chart: chart, look: MapLook.night)),
        );
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance.transientCallbackCount, 0,
        reason: 'no ticker runs while the platform asks for no motion');

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0),
        reason: 'the breath loops otherwise');
  });
}
