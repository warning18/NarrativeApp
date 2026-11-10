// The Tower's night theme (v1.900): the Tower's screens wear the dark scheme
// and the bevel panels, the rest of the game keeps its panels and its theme;
// the ladder is a stair of windows with the floor stood on marked.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/tower_ladder.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/ink_panel.dart';

Widget _app(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.light()),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets(
      'TowerNight puts its body in the dark scheme and the bevel panels',
      (tester) async {
    late Brightness seen;
    late bool bevel;
    await tester.pumpWidget(_app(TowerNight(
      child: Builder(builder: (context) {
        seen = Theme.of(context).brightness;
        bevel = TowerPanelStyle.of(context);
        return const InkPanel(child: Text('in the tower'));
      }),
    )));
    expect(seen, Brightness.dark);
    expect(bevel, isTrue);
    // The panel is drawn with the Tower's painter.
    expect(
        find.byWidgetPredicate((w) =>
            w is CustomPaint && w.foregroundPainter is BevelPanelPainter),
        findsOneWidget);
  });

  testWidgets('outside the Tower the panel and the theme are as before',
      (tester) async {
    late Brightness seen;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      seen = Theme.of(context).brightness;
      return const InkPanel(child: Text('elsewhere'));
    })));
    expect(seen, Brightness.light);
    expect(
        find.byWidgetPredicate((w) =>
            w is CustomPaint && w.foregroundPainter is BevelPanelPainter),
        findsNothing);
  });

  testWidgets('the ladder marks the floor stood on and draws 30 windows',
      (tester) async {
    await tester.pumpWidget(
        _app(const SizedBox(height: 600, child: TowerLadder(floor: 12))));
    expect(find.byKey(const Key('tower_ladder')), findsOneWidget);
    expect(find.byKey(const Key('tower_ladder_here')), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}
