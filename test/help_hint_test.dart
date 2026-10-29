// The help pattern (v1.269): an ⓘ in the header replays the page's guide, and
// holding a section name tells what it is. First on the dice loadout.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/tutorial/tutorial_topics.dart';
import 'package:narrative_data_app/widgets/help_hint.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Widget app(Widget body) => ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(ColorScheme.fromSeed(
              seedColor: Colors.amber, brightness: Brightness.dark)),
          home: Scaffold(
            appBar: AppBar(actions: const [
              TourInfoButton(topic: TutorialTopic.dice),
            ]),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: HelpTitle(
                  key: Key('help'),
                  title: 'Faces',
                  help: 'Each face casts the skill it shows.'),
            ),
          ),
        ),
      );

  testWidgets('holding a section name shows its explanation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(const SizedBox()));
    expect(find.text('Each face casts the skill it shows.'), findsNothing);
    await tester.tap(find.text('Faces'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Each face casts the skill it shows.'), findsNothing,
        reason: 'a tap alone says nothing');
    await tester.longPress(find.text('Faces'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Each face casts the skill it shows.'), findsOneWidget);
  });

  testWidgets('the header ⓘ asks for the page\'s tour', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(const SizedBox()));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(HelpTitle)));
    expect(container.read(pendingTourProvider), isNull);
    await tester.tap(find.byKey(const Key('help_tour_button')));
    await tester.pump();
    expect(container.read(pendingTourProvider), TutorialTopic.dice);
  });
}
