// An earlier choice's line in a scene (echoes.dart): in play it reads as
// ordinary prose, with no caption, clock icon or side rule; in Edit Mode
// (the story node editor's preview) it keeps the caption naming the choice.
// The typewriter writes a third slower than it did (story_text.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/echoes.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart';
import 'package:narrative_data_app/widgets/story_text.dart';

const _echo = SceneEcho(
  nodeId: '5004_altar',
  flag: 'court_fled',
  line: 'You still hear the court door slam behind you.',
  cause: 'Confront them',
);

class _Mode extends AppModeNotifier {
  _Mode(AppMode mode) {
    state = mode;
  }
}

Future<void> _show(WidgetTester tester, AppMode mode) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [
      appModeProvider.overrideWith((ref) => _Mode(mode)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: EchoLine(
          key: ValueKey('echo_5004_altar|court_fled'),
          echo: _echo,
          caption: 'Because you chose “Confront them”',
          colour: Colors.amber,
          style: TextStyle(fontSize: 17),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('in play the echoed line is plain prose, with no label',
      (tester) async {
    await _show(tester, AppMode.inGame);
    expect(find.byType(StoryText), findsOneWidget);
    expect(find.textContaining('court door slam', findRichText: true),
        findsOneWidget);
    expect(find.text('Because you chose “Confront them”'), findsNothing);
    expect(find.byIcon(Icons.history), findsNothing);
    // No side rule: nothing in it is decorated.
    expect(
        find.descendant(
            of: find.byType(EchoLine), matching: find.byType(DecoratedBox)),
        findsNothing);
  });

  testWidgets('in Edit Mode the preview keeps the label, icon and rule',
      (tester) async {
    await _show(tester, AppMode.edit);
    expect(find.text('Because you chose “Confront them”'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.textContaining('court door slam', findRichText: true),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(EchoLine), matching: find.byType(DecoratedBox)),
        findsOneWidget);
  });

  test('the text writes itself out about a third slower', () {
    // 175 characters a second, kept between 0.6 s and 6 s.
    expect(storyTypeDuration(175), const Duration(seconds: 1));
    expect(storyTypeDuration(350), const Duration(seconds: 2));
    expect(storyTypeDuration(10), const Duration(milliseconds: 600));
    expect(storyTypeDuration(5000), const Duration(seconds: 6));
    // Was 260 a second: the same text takes 1.5 times as long.
    expect(storyTypeDuration(260).inMilliseconds / 1000,
        closeTo(260 / 175, 0.001));
  });
}
